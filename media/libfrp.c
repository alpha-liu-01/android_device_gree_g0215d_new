#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>

/*
 * Gree's Android 6 libadsprpc.so opens /dev/adsprpc-smd and immediately issues
 * FASTRPC_IOCTL_INIT without calling FASTRPC_IOCTL_GETINFO first. On the 4.4
 * kernel, fastrpc_device_open() initializes fl->cid = -1 and requires userspace
 * to select the domain via FASTRPC_IOCTL_GETINFO (0xc0045208) before INIT.
 * Without it, FASTRPC_IOCTL_INIT fails with -ENOTTY / -ECHRNG and adsprpcd
 * cannot attach to the ADSP to serve HeaacDecoderModule.so.1 from /dsp.
 *
 * In libadsprpc.so (32/64-bit), the unused DT_NEEDED entry "libc++.so" is
 * replaced with "libfrp.so" and the UND open symbol points to that string.
 */
#define FASTRPC_IOCTL_GETINFO 0xc0045208U
#define ADSP_DOMAIN_ID 0U

int fastrpc_open(const char *pathname, int flags, ...) __asm__("libfrp.so");

__attribute__((visibility("default")))
int fastrpc_open(const char *pathname, int flags, ...) {
    int fd = open(pathname, flags, 0);
    if (fd >= 0 && pathname && strstr(pathname, "adsprpc-smd")) {
        unsigned int info = ADSP_DOMAIN_ID;
        ioctl(fd, (int)FASTRPC_IOCTL_GETINFO, &info);
    }
    return fd;
}
