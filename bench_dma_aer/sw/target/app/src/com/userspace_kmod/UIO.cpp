//  source code from (https://harmoninstruments.com/posts/uio.html)

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <cstdlib>
#include <cstdint>
#include <poll.h>
#include <errno.h>
#include <stdexcept>
#include <iostream>
#include <fstream>
#include <string>
#include <dirent.h>
#include <cstring>
#include "../../utility/CustomPrint.h"
#include "UIO.h"

UIO::UIO(const char *fn, bool from_uio_dev_name) {
    int r = EXIT_FAILURE;
    if (!from_uio_dev_name){
        _fd = open(fn, O_RDWR);
        if (_fd < 0)
            throw std::runtime_error("failed to open UIO device");
        r = EXIT_SUCCESS;
    }
    else{
        std::string path = "/sys/class/uio/";
        std::string uio_dev_name(fn);
        
        DIR* dir = opendir(path.c_str());
        if (!dir)
            throw std::runtime_error("Failed to open directory" + path);

        struct dirent* entry;
        while ((entry = readdir(dir)) != nullptr) {
            // Only process directories that look like uioX (i.e., uio0, uio1, ...)
            if (strncmp(entry->d_name, "uio", 3) == 0) {
                std::string uio_name  = entry->d_name; // Get the uioX name
                std::string name_path = path + uio_name + "/name"; // Abs path to uioX name
                std::string dev_name  = "/dev/" + uio_name;
                
                // Read name from uioX file
                std::ifstream name_file(name_path);
                if (!name_file)
                    throw std::runtime_error("Failed to open " + name_path);
                std::string name;
                std::getline(name_file, name);
                
                // Check if the name matches the word
                if (name == uio_dev_name){
                    _fd = open(dev_name.c_str(), O_RDWR);
                    if (_fd < 0)
                        throw std::runtime_error("failed to open UIO device");
                    r = EXIT_SUCCESS;
                }
            }
        }
        closedir(dir);
    }
    statusPrint(r, "Mapping UIO device " + std::string(fn));
}

UIO::~UIO() { close(_fd); }

int UIO::unmask_interrupt() {
    int r = uio_status::OK;
    uint32_t unmask = 1;
    ssize_t rv = write(_fd, &unmask, sizeof(unmask));
    if (rv != (ssize_t)sizeof(unmask)) {
        r = ERROR;
    }
    return r;
}

int UIO::wait_interrupt(int timeout_ms) {
    int r = uio_status::OK;

    // wait for the interrupt
    struct pollfd pfd = {.fd = _fd, .events = POLLIN};
    int rv = poll(&pfd, 1, timeout_ms);
    // clear the interrupt
    if (rv >= 1) {
        uint32_t info;
        read(_fd, &info, sizeof(info));
    } else if (rv == 0) { // timeout
        r = uio_status::TIMEOUT;
    } else {
        r = uio_status::ERROR;
    }
    return r;
}

UIO_mmap::UIO_mmap(const UIO &u, int index, size_t size) : _size(size) {
    _ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED,
        u._fd, index * getpagesize());
    if (_ptr == MAP_FAILED) {
        perror("UIO_mmap");
        std::runtime_error("UIO_mmap construction failed");
    }
}

UIO_mmap::~UIO_mmap() { munmap(_ptr, _size); }