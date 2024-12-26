/*
*! @title      Axi DMA using proxy driver
*! @file       AxiDma.cpp
*! @author     Romain Beaubois
*! @date       08 Nov 2022
*! @copyright
*! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! 
*! @details
*! > **08 Nov 2022** : file creation (RB)
*/

#include "AxiDma.h"

// #define DEBUG_PROBE_FWRITE

static volatile int stop = 0;
static volatile int end_recv_spikes = 0;

//   █████  ██   ██ ██     ██████  ███    ███  █████  
//  ██   ██  ██ ██  ██     ██   ██ ████  ████ ██   ██ 
//  ███████   ███   ██     ██   ██ ██ ████ ██ ███████ 
//  ██   ██  ██ ██  ██     ██   ██ ██  ██  ██ ██   ██ 
//  ██   ██ ██   ██ ██     ██████  ██      ██ ██   ██ 
//                                                    
//                                                    
AxiDma::AxiDma(struct sw_config swconfig){
    int r;

	// Open the file descriptors for each rx channel and map the kernel driver memory into user space
	for (int i = 0; i < RX_CHANNEL_COUNT; i++) {
		// Generate channel file name
		string fpath_rx_channel = "/dev/" + _rx_channel_names[i];

		// Open file
		_rx_channels[i].fd = open(fpath_rx_channel.c_str(), O_RDWR);
		r = (_rx_channels[i].fd < 1) ? EXIT_FAILURE : EXIT_SUCCESS;
		statusPrint(r, "Open DMA proxy device file " + string(fpath_rx_channel));
		if(r==EXIT_FAILURE)
			exit(EXIT_FAILURE);
		
		// Map memory
		_rx_channels[i].buf_ptr = (struct channel_buffer *)mmap(NULL, sizeof(struct channel_buffer) * RX_BUFFER_COUNT,
										PROT_READ | PROT_WRITE, MAP_SHARED, _rx_channels[i].fd, 0);
		r = (_rx_channels[i].buf_ptr == MAP_FAILED) ? EXIT_FAILURE : EXIT_SUCCESS;
		statusPrint(r, "Map " + string(fpath_rx_channel));
		if(r==EXIT_FAILURE)
			exit(EXIT_FAILURE);

		// Initiaze buffers
		for(size_t buffer_id = 0; buffer_id < RX_BUFFER_COUNT; buffer_id++){
			unsigned int* dma_buffer = (unsigned int*)(&_rx_channels[i].buf_ptr[buffer_id].buffer);
			memset(dma_buffer, 0, BUFFER_SIZE/sizeof(unsigned int));
		}
	}
}

int AxiDma::monitoring(struct sw_config swconfig){
	thread_args rx_th_args[RX_CHANNEL_COUNT];

	string fpath_save_recv_spk	= swconfig.dirpath_save_stream + "recv_spk.csv";
	
	/**** Thread arguments ****/
	// Spikes
	rx_th_args[TH_ID_RECV_SPIKES].th_name				= (char*)_rx_channel_names[TH_ID_RECV_SPIKES].c_str();
	rx_th_args[TH_ID_RECV_SPIKES].chan_ptr				= &_rx_channels[TH_ID_RECV_SPIKES];
	rx_th_args[TH_ID_RECV_SPIKES].send					= false;
	rx_th_args[TH_ID_RECV_SPIKES].save					= swconfig.en_save_stream_pl_to_ps;
	rx_th_args[TH_ID_RECV_SPIKES].save_path				= (char*)fpath_save_recv_spk.c_str();

	/**** Start threads ****/
	_rx_channels[TH_ID_RECV_SPIKES].t	= thread(&AxiDma::recvSpikesThread,	this, &rx_th_args[TH_ID_RECV_SPIKES]);

	/**** Do the thing ****/
	sleep(swconfig.run_time_s);
	end_recv_spikes = 1;

	/**** Join ****/
	_rx_channels[TH_ID_RECV_SPIKES].t.join();

	/**** Clean ****/
	munmap(_rx_channels[TH_ID_RECV_SPIKES].buf_ptr, sizeof(struct channel_buffer));
	close(_rx_channels[TH_ID_RECV_SPIKES].fd);

	return EXIT_SUCCESS;
}

//                                                               
//  ██████  ███████  ██████ ██    ██     ███████ ██████  ██   ██ 
//  ██   ██ ██      ██      ██    ██     ██      ██   ██ ██  ██  
//  ██████  █████   ██      ██    ██     ███████ ██████  █████   
//  ██   ██ ██      ██       ██  ██           ██ ██      ██  ██  
//  ██   ██ ███████  ██████   ████       ███████ ██      ██   ██ 
//                                                               
void AxiDma::recvSpikesThread(void* args){
	// Parse thread arguments
	struct thread_args* args_struct = (struct thread_args*)(args);
	struct channel* channel_ptr = args_struct->chan_ptr;
	bool save					= args_struct->save;
	bool send					= args_struct->send;
	char* th_name				= args_struct->th_name;
	char* save_path				= args_struct->save_path;
    int r;

	// Internal variables
	constexpr int PACKET_SIZE  = 32;
	uint32_t val_regw_status   = 0;
	int nb_buffer_for_transfer = 0;
	int transfer_size		   = PACKET_SIZE+1;
	int transfer_size_bytes	   = transfer_size*sizeof(unsigned int);
	int in_progress_count	   = 0;
    int buffer_id			   = 0;
	int rx_counter			   = 0;
	int buf_cnt				   = 0;

	// Calculate number of buffer required to perform the required transfer size
	if (transfer_size_bytes > BUFFER_SIZE){
		transfer_size_bytes		= BUFFER_SIZE;
		nb_buffer_for_transfer	= transfer_size_bytes/BUFFER_SIZE;
	}
	else{
		nb_buffer_for_transfer = 1;
	}

	// Initialize AXI GPIO to get status of events ready and initiate a transfer
	UIO uio_intr = UIO("top", true);
	uio_intr.unmask_interrupt();

	// Open file to save data
	ofstream fout (save_path);
	if (save){
		r = (fout.is_open()) ? EXIT_SUCCESS : EXIT_FAILURE;
		if (r == EXIT_FAILURE){
			infoPrint(0, "OOF! Failed opening saving file for rx channel spikes");
			exit(EXIT_FAILURE);
		}
		infoPrint(0, "Open save file: " + string(save_path));
	}

	// /!\ hypothesis: for now transfers always are smaller than buffer size
	// need to add extra handling of buffer of larger size
	while(!end_recv_spikes){
		rx_counter			= 0;
		in_progress_count	= 0;

		// Wait for interrupt: meaning events available
		do{
			r = uio_intr.wait_interrupt(1000);
			if (r == uio_status::TIMEOUT){
				statusPrint(EXIT_FAILURE, "UIO interrupt recvSpikes: timeout");
				exit(EXIT_FAILURE);
			}
			else if (r == uio_status::ERROR){
				statusPrint(EXIT_FAILURE, "UIO interrupt recvSpikes: error");
				exit(EXIT_FAILURE);
			}
		} while (r != uio_status::OK);
		uio_intr.unmask_interrupt();
		statusPrint(EXIT_SUCCESS, "UIO interrupt recvSpikes: catched");
		
		// One buffer per transfer but buffer are circular for next transfer
		/* Initiate DMA transfer 
			(1) Initiate DMA transfer through driver
			(2) Wait for transfer to complete
			(3) Stop/rearm data stream from PL to DMA
		*/
		// (1) Initiate DMA transfer through driver
		channel_ptr->buf_ptr[buffer_id].length = transfer_size_bytes;
		ioctl(channel_ptr->fd, START_XFER, &buffer_id);

		// (2) Wait for transfer to complete
		ioctl(channel_ptr->fd, FINISH_XFER, &buffer_id);
		int status = channel_ptr->buf_ptr[buffer_id].status;
		r = (status != channel_buffer::proxy_status::PROXY_NO_ERROR) ? EXIT_FAILURE : EXIT_SUCCESS;

		// (3) Error handling
		switch (status){
			case channel_buffer::proxy_status::PROXY_NO_ERROR:
				break;
			case channel_buffer::proxy_status::PROXY_BUSY:
				statusPrint(EXIT_FAILURE, "DMA - recv spikes: busy");
				break;
			case channel_buffer::proxy_status::PROXY_TIMEOUT:
				statusPrint(EXIT_FAILURE, "DMA - recv spikes: timeout");
				break;
			case channel_buffer::proxy_status::PROXY_ERROR:
				statusPrint(EXIT_FAILURE, "DMA - recv spikes: error");
				break;
			default:
				break;
		}

		if(r==EXIT_FAILURE)
			break;

		// Access current DMA buffer containing data transfered
		unsigned int *buffer = (unsigned int*)(&channel_ptr->buf_ptr[buffer_id].buffer);

		// Local saving
		if(save){
			const bool bin_fmt_save = false;

			#ifdef DEBUG_PROBE_FWRITE
				uint64_t tstart = get_posix_clock_time_usec();
			#endif

			if (bin_fmt_save){
			    fout.write(reinterpret_cast<char*>(buffer), transfer_size * sizeof(unsigned int));
				// fwrite(buffer, transfer_size_bytes/sizeof(unsigned int), sizeof(unsigned int),  fout);
			}
			else{
				fout << "Buffer id: " << buf_cnt << " - " << "Transfer size: " << transfer_size << endl;
				for (int j = 0; j < transfer_size_bytes/sizeof(unsigned int); j++)
					fout << buffer[j] << ';';
				fout << endl << endl;
			}

			#ifdef DEBUG_PROBE_FWRITE
				uint64_t tstop = get_posix_clock_time_usec();
				printf("Elapsed time: %lu µs\n", tstop-tstart);
			#endif
		}

		// Forwarding
		if(send){
			// TODO: ZMQ sending
		}

		/* Flip to next buffer treating them as a circular list, and possibly skipping some
		* to show the results when prefetching is not happening
		*/
		buffer_id += BUFFER_INCREMENT;
		buffer_id %= RX_BUFFER_COUNT;
		buf_cnt++;

		// If stop required, graciously exit after all transfers done
		if (stop == 1)
			break;		
	}

	fout.close();
}