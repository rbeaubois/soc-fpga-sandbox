//  source code from (https://harmoninstruments.com/posts/uio.html)

#ifndef __UIO_H__
#define __UIO_H__

#include <cstdint>
#include <cstddef>

typedef enum {
    OK,
    ERROR,
    TIMEOUT
}uio_status;

class UIO {
    private:
        int _fd;

    public:
        explicit UIO(const char *fn, bool from_uio_dev_name);
        ~UIO();
        int unmask_interrupt();
        int wait_interrupt(int timeout_ms);
        friend class UIO_mmap;
};

class UIO_mmap {
private:
    size_t _size;
    void *_ptr;

public:
    UIO_mmap(const UIO &u, int index, size_t size);
    ~UIO_mmap();
    size_t size() const { return _size; }
    void *get_ptr() const { return _ptr; }
};
#endif