/* android_setsocknetwork for the IMS data path.
 * The CAF imsdatadaemon and lib-imsdpl need this SONAME; this image has no
 * libandroid_net.so. The mark layout matches netd Fwmark: netId in the low
 * 16 bits, explicitlySelected at bit 16. */
typedef unsigned long long u64;
int setsockopt(int fd, int level, int optname, const void *optval, unsigned long optlen);

int android_setsocknetwork(u64 network, int fd) {
    unsigned int netid;
    unsigned int mark;

    if (fd < 0)
        return -1;
    netid = (unsigned int)((network >> 32) & 0xffffu);
    if (netid == 0 && network != 0 && (unsigned int)network != 0xcafed00du)
        netid = (unsigned int)(network & 0xffffu);
    mark = netid & 0xffffu;
    if (netid != 0)
        mark |= 1u << 16;
    if (setsockopt(fd, 1 /* SOL_SOCKET */, 36 /* SO_MARK */, &mark, sizeof(mark)) < 0)
        return -1;
    return 0;
}
