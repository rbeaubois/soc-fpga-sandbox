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
static volatile int end_send_spikes = 0;

//   █████  ██   ██ ██     ██████  ███    ███  █████  
//  ██   ██  ██ ██  ██     ██   ██ ████  ████ ██   ██ 
//  ███████   ███   ██     ██   ██ ██ ████ ██ ███████ 
//  ██   ██  ██ ██  ██     ██   ██ ██  ██  ██ ██   ██ 
//  ██   ██ ██   ██ ██     ██████  ██      ██ ██   ██ 
//                                                    
//                                                    
AxiDma::AxiDma(struct sw_config swconfig){
    int r;

	// Open the file descriptors for each tx channel and map the kernel driver memory into user space
	for (int i = 0; i < TX_CHANNEL_COUNT; i++) {
		// Generate channel file name
		string fpath_tx_channel = "/dev/" + _tx_channel_names[i];

		// Open file
		_tx_channels[i].fd = open(fpath_tx_channel.c_str(), O_RDWR);
		r = (_tx_channels[i].fd < 1) ? EXIT_FAILURE : EXIT_SUCCESS;
		statusPrint(r, "Open DMA proxy device file " + fpath_tx_channel);
		if(r==EXIT_FAILURE)
			exit(EXIT_FAILURE);
		
		// Map memory
		_tx_channels[i].buf_ptr = (struct channel_buffer *)mmap(NULL, sizeof(struct channel_buffer) * TX_BUFFER_COUNT,
										PROT_READ | PROT_WRITE, MAP_SHARED, _tx_channels[i].fd, 0);
		r = (_tx_channels[i].buf_ptr == MAP_FAILED) ? EXIT_FAILURE : EXIT_SUCCESS;
		statusPrint(r, "Map " + string(fpath_tx_channel));
		if(r==EXIT_FAILURE)
			exit(EXIT_FAILURE);

		// Initiaze buffers
		for(size_t buffer_id = 0; buffer_id < TX_BUFFER_COUNT; buffer_id++){
			unsigned int* dma_buffer = (unsigned int*)(&_tx_channels[i].buf_ptr[buffer_id].buffer);
			memset(dma_buffer, 0, BUFFER_SIZE/sizeof(unsigned int));
		}
	}


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
	thread_args tx_th_args[TX_CHANNEL_COUNT];

	string fpath_save_recv_spk	= swconfig.dirpath_save_stream + "recv_spk.csv";
	string fpath_save_send_spk	= swconfig.dirpath_save_stream + "send_spk.csv";
	
	/**** Thread arguments ****/
	// Spikes
	rx_th_args[TH_ID_RECV_SPIKES].th_name				= (char*)_rx_channel_names[TH_ID_RECV_SPIKES].c_str();
	rx_th_args[TH_ID_RECV_SPIKES].chan_ptr				= &_rx_channels[TH_ID_RECV_SPIKES];
	rx_th_args[TH_ID_RECV_SPIKES].send					= false;
	rx_th_args[TH_ID_RECV_SPIKES].save					= swconfig.en_save_stream_pl_to_ps;
	rx_th_args[TH_ID_RECV_SPIKES].save_path				= (char*)fpath_save_recv_spk.c_str();

	// External stimulation
	tx_th_args[TH_ID_SEND_SPIKES].th_name				= (char*)_tx_channel_names[TH_ID_SEND_SPIKES].c_str();
	tx_th_args[TH_ID_SEND_SPIKES].chan_ptr				= &_tx_channels[TH_ID_SEND_SPIKES];
	tx_th_args[TH_ID_SEND_SPIKES].send					= false;
	tx_th_args[TH_ID_SEND_SPIKES].save					= swconfig.en_save_stream_ps_to_pl;
	tx_th_args[TH_ID_SEND_SPIKES].save_path				= (char*)fpath_save_send_spk.c_str();

	/**** Start threads ****/
	_rx_channels[TH_ID_RECV_SPIKES].t	= thread(&AxiDma::recvSpikesThread,	this, &rx_th_args[TH_ID_RECV_SPIKES]);
	_tx_channels[TH_ID_SEND_SPIKES].t	= thread(&AxiDma::sendSpikesThread, this, &tx_th_args[TH_ID_SEND_SPIKES]);

	/**** Do the thing ****/
	sleep(swconfig.run_time_s);
	end_recv_spikes = 1;
	end_send_spikes = 1;

	/**** Join ****/
	_rx_channels[TH_ID_RECV_SPIKES].t.join();
	_tx_channels[TH_ID_SEND_SPIKES].t.join();

	/**** Clean ****/
	munmap(_rx_channels[TH_ID_RECV_SPIKES].buf_ptr, sizeof(struct channel_buffer));
	close(_rx_channels[TH_ID_RECV_SPIKES].fd);
	
	munmap(_tx_channels[TH_ID_SEND_SPIKES].buf_ptr, sizeof(struct channel_buffer));
	close(_tx_channels[TH_ID_SEND_SPIKES].fd);

	return EXIT_SUCCESS;
}

//                                                                
//  ███████ ███████ ███    ██ ██████      ███████ ██████  ██   ██ 
//  ██      ██      ████   ██ ██   ██     ██      ██   ██ ██  ██  
//  ███████ █████   ██ ██  ██ ██   ██     ███████ ██████  █████   
//       ██ ██      ██  ██ ██ ██   ██          ██ ██      ██  ██  
//  ███████ ███████ ██   ████ ██████      ███████ ██      ██   ██ 
//                                                                
#define NB_FRAMES	  3
#define CHUNK_SIZE  512
void AxiDma::sendSpikesThread(void* args){
	// Thread parameters
	struct thread_args* args_struct = (struct thread_args*)(args);
	struct channel* channel_ptr = args_struct->chan_ptr;
	bool save			= args_struct->save;
	bool send			= args_struct->send;
	char* th_name		= args_struct->th_name;
	char* save_path		= args_struct->save_path;

    int r;
    int buffer_id = 0;
	int buf_cnt	  = 0;

	// Open file to save data
	ofstream fout (save_path);
	if(save){
		r = (fout.is_open()) ? EXIT_SUCCESS : EXIT_FAILURE;
		if (r == EXIT_FAILURE){
			infoPrint(0, "OOF! Failed opening saving file for dma tx data");
			exit(EXIT_FAILURE);
		}
		infoPrint(0, "Open save file: " + string(save_path));
	}

	// Generate dummy data
	const int transfer_size_bytes = CHUNK_SIZE*sizeof(unsigned int);
	const unsigned int dummy_spk_stream[8] = {6666, 6,  10,  11,  12,  13,  14,  15};
	unsigned int buf_send_spikes[CHUNK_SIZE];

	// Random tstamp, spikes, nb etc....
	for (size_t j = 0; j < CHUNK_SIZE/8; j++){
		for (size_t k = 0; k < 8; k++){
			buf_send_spikes[j*8 + k] = dummy_spk_stream[k];
		}
	}

	// Initialize custom AXI probe
	AxiProbeUioIntr axi_probe_free_slots_to_pl = AxiProbeUioIntr("axi_gpio_free_slots_to_pl", OFFSET_AXI_FREE_SLOTS_TO_PL, RANGE_AXI_FREE_SLOTS_TO_PL);
	axi_probe_free_slots_to_pl.unmask_pl_interrupt();
	axi_probe_free_slots_to_pl.clear_flag_write_to_pl(); // deassert valid write
	
	// Start all buffers being sent
	while(!stop){
		if (end_send_spikes == 1 || buf_cnt >= NB_FRAMES)
			break;

		if (transfer_size_bytes > BUFFER_SIZE){
			statusPrint(EXIT_FAILURE, "Transfer size of ext stim larger than DMA buffer");
		}

		// Save zmq data
		if(save){
			// Timing assessment
			#ifdef DEBUG_PROBE_FWRITE
				uint64_t tstart = get_posix_clock_time_usec();
			#endif

			// Save as binary (faster)
			// fwrite(buffer, transfer_size_bytes/sizeof(unsigned int), sizeof(unsigned int),  f);

			// Save as csv alike for debug (way slower)
			fout << "Buffer id: " << buf_cnt << endl;
			for (size_t j = 0; j < transfer_size_bytes/sizeof(unsigned int); j++){
				fout << buf_send_spikes[j] << ';';
			}
			fout << endl << endl;
			
			#ifdef DEBUG_PROBE_FWRITE
				uint64_t tstop = get_posix_clock_time_usec();
				printf("Elapsed time: %lu µs\n", tstop-tstart);
			#endif
		}

		// Wait for space in FIFO
		do{
			r = axi_probe_free_slots_to_pl.wait_pl_interrupt(1000);
			if (r == uio_status::TIMEOUT)
				statusPrint(EXIT_FAILURE, "UIO interrupt sendSpikes: timeout");
			else if (r == uio_status::ERROR)
				statusPrint(EXIT_FAILURE, "UIO interrupt sendSpikes: error");
		} while (r != uio_status::OK);
		statusPrint(EXIT_SUCCESS, "UIO interrupt sendSpikes: catched");

		// Read number of free slots
		uint32_t pl_free_slots = axi_probe_free_slots_to_pl.read_from_pl();
		std::cout << "Free slots in PL: " << pl_free_slots << std::endl;

		// Extra security to confirm PL read correct size and valid stream
		axi_probe_free_slots_to_pl.write_to_pl(pl_free_slots); // write transfer size for PL checks
		axi_probe_free_slots_to_pl.set_flag_write_to_pl(); // valid write

		// Pointer to current buffer
		unsigned int* dma_buffer = (unsigned int*)(&channel_ptr->buf_ptr[buffer_id].buffer);
		memcpy(dma_buffer, buf_send_spikes, sizeof(unsigned int) * CHUNK_SIZE);

		// DMA sending
		channel_ptr->buf_ptr[buffer_id].length = transfer_size_bytes; // transfer length (in bytes)
		ioctl(channel_ptr->fd, START_XFER,  &buffer_id); // start transfer
		ioctl(channel_ptr->fd, FINISH_XFER, &buffer_id); // wait for transfer end
		axi_probe_free_slots_to_pl.unmask_pl_interrupt();
		axi_probe_free_slots_to_pl.clear_flag_write_to_pl(); // deassert valid write

        r = (channel_ptr->buf_ptr[buffer_id].status != channel_buffer::proxy_status::PROXY_NO_ERROR) ? EXIT_FAILURE : EXIT_SUCCESS;
		if (r == EXIT_SUCCESS){
			statusPrint(r, "Send spikes");
		}

		// Circular list of buffer
		buffer_id += BUFFER_INCREMENT;
		buffer_id %= TX_BUFFER_COUNT;
		buf_cnt++;
	}

	if (save){
		fout.close();
	}
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
	uint32_t val_regw_status   = 0;
	int nb_buffer_for_transfer = 0;
	int transfer_size		   = 0;
	int transfer_size_bytes	   = 0;
	int in_progress_count	   = 0;
    int buffer_id			   = 0;
	int rx_counter			   = 0;
	int buf_cnt				   = 0;

	// Initialize AXI GPIO to get status of events ready and initiate a transfer
	AxiProbeUioIntr axi_probe_ready_ev_to_ps = AxiProbeUioIntr("axi_gpio_ready_ev_to_ps", OFFSET_AXI_READY_EV_TO_PS, RANGE_AXI_READY_EV_TO_PS);
	axi_probe_ready_ev_to_ps.unmask_pl_interrupt();

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
			r = axi_probe_ready_ev_to_ps.wait_pl_interrupt(1000);
			if (r == uio_status::TIMEOUT){
				statusPrint(EXIT_FAILURE, "UIO interrupt recvSpikes: timeout");
				exit(EXIT_FAILURE);
			}
			else if (r == uio_status::ERROR){
				statusPrint(EXIT_FAILURE, "UIO interrupt recvSpikes: error");
				exit(EXIT_FAILURE);
			}
		} while (r != uio_status::OK);
		axi_probe_ready_ev_to_ps.unmask_pl_interrupt();
		statusPrint(EXIT_SUCCESS, "UIO interrupt recvSpikes: catched");
		
		// Get the number of events available to read
		transfer_size		= axi_probe_ready_ev_to_ps.read_from_pl();
		transfer_size_bytes = transfer_size * sizeof(unsigned int);
		std::cout << "Starting transfer of size: " << transfer_size;
		std::cout << " (" << transfer_size_bytes << " bytes)" << std::endl;

		// Calculate number of buffer required to perform the required transfer size
		if (transfer_size_bytes > BUFFER_SIZE){
			transfer_size_bytes		= BUFFER_SIZE;
			nb_buffer_for_transfer	= transfer_size_bytes/BUFFER_SIZE;
		}
		else{
			nb_buffer_for_transfer = 1;
		}
		
		// One buffer per transfer but buffer are circular for next transfer
		/* Initiate DMA transfer 
			(1) Initiate DMA transfer through driver
			(2) Start data stream from PL to DMA
			(3) Wait for transfer to complete
			(4) Stop/rearm data stream from PL to DMA
			(5) Error handling
		*/
		// (1) Initiate DMA transfer through driver
		channel_ptr->buf_ptr[buffer_id].length = transfer_size_bytes;
		ioctl(channel_ptr->fd, START_XFER, &buffer_id);
		
		// (2) Start data stream from PL to DMA
		axi_probe_ready_ev_to_ps.write_to_pl(transfer_size);
		axi_probe_ready_ev_to_ps.set_flag_write_to_pl();

		// (3) Wait for transfer to complete
		ioctl(channel_ptr->fd, FINISH_XFER, &buffer_id);
		int status = channel_ptr->buf_ptr[buffer_id].status;
		r = (status != channel_buffer::proxy_status::PROXY_NO_ERROR) ? EXIT_FAILURE : EXIT_SUCCESS;

		// (4) Stop/rearm data stream from PL to DMA
		axi_probe_ready_ev_to_ps.clear_flag_write_to_pl();

		// (5) Error handling
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