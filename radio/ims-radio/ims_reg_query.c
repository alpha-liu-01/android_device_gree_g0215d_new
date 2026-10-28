/* Read-only IMSA registration query. Does not send IMSS sets. */
extern long syscall(long n, long a, long b, long c, long d, long e, long f);
extern int printf(const char *fmt, ...);
extern int fflush(void *f);
extern void *stdout;

typedef void *qmi_client_type;
typedef void *qmi_idl_service_object_type;

extern qmi_idl_service_object_type imsa_get_service_object_internal_v01(int, int, int);
extern int qmi_client_init_instance(qmi_idl_service_object_type, int, void *, void *,
                                    void *, unsigned, qmi_client_type *);
extern int qmi_client_send_msg_sync(qmi_client_type, unsigned, void *, unsigned,
                                    void *, unsigned, unsigned);

int main(void) {
    unsigned char os[256];
    unsigned char buf[288];
    qmi_client_type handle = 0;
    int i;
    int init_rc = -1;
    int msg_rc = -1;

    for (i = 0; i < 256; i++) os[i] = 0;
    for (i = 0; i < 288; i++) buf[i] = 0;

    qmi_idl_service_object_type imsa = imsa_get_service_object_internal_v01(1, 0x14, 6);
    if (imsa)
        init_rc = qmi_client_init_instance(imsa, 0, 0, 0, os, 4000, &handle);
    if (init_rc == 0)
        msg_rc = qmi_client_send_msg_sync(handle, 0x20, 0, 0, buf, 288, 4000);

    printf("init=%d msg=%d valid=%u status=%u bytes=", init_rc, msg_rc, buf[8], buf[9]);
    for (i = 8; i < 16; i++) printf("%02x", buf[i]);
    printf("\n");
    fflush(stdout);
    syscall(94, (init_rc || msg_rc) ? 1 : 0, 0, 0, 0, 0, 0);
    return 0;
}
