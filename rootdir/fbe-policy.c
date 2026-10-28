#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/fs.h>

/*
 * This 4.4 kernel reports an unencrypted directory as ENOENT.
 * ENODATA is the newer errno. Both mean the directory has no policy.
 */
static int policy_status(const char *path) {
    struct fscrypt_policy policy;
    int fd = open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "open %s: %s\n", path, strerror(errno));
        return 1;
    }
    memset(&policy, 0, sizeof(policy));
    if (ioctl(fd, FS_IOC_GET_ENCRYPTION_POLICY, &policy) == 0) {
        printf("encrypted\n");
        close(fd);
        return 0;
    }
    if (errno == ENOENT || errno == ENODATA || errno == ENOTTY) {
        printf("plain\n");
        close(fd);
        return 0;
    }
    fprintf(stderr, "ioctl %s: %s\n", path, strerror(errno));
    close(fd);
    return 1;
}

static int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int parse_desc(const char *hex, unsigned char desc[8]) {
    size_t i;
    if (strlen(hex) != 16) return -1;
    for (i = 0; i < 8; i++) {
        int hi = hex_nibble(hex[i * 2]);
        int lo = hex_nibble(hex[i * 2 + 1]);
        if (hi < 0 || lo < 0) return -1;
        desc[i] = (unsigned char)((hi << 4) | lo);
    }
    return 0;
}

static void desc_to_hex(const unsigned char desc[8], char out[17]) {
    static const char *digits = "0123456789abcdef";
    size_t i;
    for (i = 0; i < 8; i++) {
        out[i * 2] = digits[desc[i] >> 4];
        out[i * 2 + 1] = digits[desc[i] & 0xf];
    }
    out[16] = '\0';
}

static int read_desc_file(const char *path, char out[17]) {
    unsigned char desc[8];
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return -1;
    if (read(fd, desc, 8) != 8) {
        close(fd);
        return -1;
    }
    close(fd);
    desc_to_hex(desc, out);
    return 0;
}

/* v1 policy: version byte is 0, contents AES-256-XTS, names AES-256-CTS, pad 4. */
static int policy_apply(const char *path, const char *hex) {
    struct fscrypt_policy policy;
    int fd = open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "open %s: %s\n", path, strerror(errno));
        return 1;
    }
    memset(&policy, 0, sizeof(policy));
    if (parse_desc(hex, (unsigned char *)policy.master_key_descriptor) != 0) {
        fprintf(stderr, "bad descriptor\n");
        close(fd);
        return 1;
    }
    policy.version = 0;
    policy.contents_encryption_mode = FS_ENCRYPTION_MODE_AES_256_XTS;
    policy.filenames_encryption_mode = FS_ENCRYPTION_MODE_AES_256_CTS;
    policy.flags = 0;
    if (ioctl(fd, FS_IOC_SET_ENCRYPTION_POLICY, &policy) != 0) {
        fprintf(stderr, "set policy %s: %s\n", path, strerror(errno));
        close(fd);
        return 1;
    }
    close(fd);
    return 0;
}

/* Print the user-0 CE descriptor. It is the ext4 logon key added after the
 * device key and the per-boot key, so it has the higher serial. */
static int print_ce_desc(void) {
    char device_ref[17], per_boot_ref[17];
    char best[17];
    unsigned long best_serial = 0;
    int found = 0;
    FILE *keys;
    char line[512];

    if (read_desc_file("/data/unencrypted/ref", device_ref) != 0) return 1;
    if (read_desc_file("/data/unencrypted/per_boot_ref", per_boot_ref) != 0) return 1;
    keys = fopen("/proc/keys", "r");
    if (!keys) return 1;
    while (fgets(line, sizeof(line), keys)) {
        unsigned long serial;
        char *mark;
        char desc[17];
        size_t i;
        if (sscanf(line, "%lx", &serial) != 1) continue;
        mark = strstr(line, "ext4:");
        if (!mark) continue;
        mark += 5;
        for (i = 0; i < 16 && isxdigit((unsigned char)mark[i]); i++) {
            desc[i] = (char)tolower((unsigned char)mark[i]);
        }
        desc[i] = '\0';
        if (i != 16) continue;
        if (strcmp(desc, device_ref) == 0 || strcmp(desc, per_boot_ref) == 0) continue;
        if (!found || serial > best_serial) {
            best_serial = serial;
            memcpy(best, desc, 17);
            found = 1;
        }
    }
    fclose(keys);
    if (!found) return 1;
    printf("%s\n", best);
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 3 && strcmp(argv[1], "status") == 0) {
        return policy_status(argv[2]);
    }
    if (argc == 4 && strcmp(argv[1], "apply") == 0) {
        return policy_apply(argv[2], argv[3]);
    }
    if (argc == 2 && strcmp(argv[1], "ce-desc") == 0) {
        return print_ce_desc();
    }
    fprintf(stderr, "usage: fbe-policy status PATH | apply PATH DESC | ce-desc\n");
    return 2;
}
