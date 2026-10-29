/*
 * Consumer IR HAL for the Gree G0215D Raon blaster.
 *
 * The stock framework packed ConsumerIrManager.transmit into the Raon
 * packet format and wrote it to /dev/remote_ctrl_dev. This HAL does that
 * packing so the platform Consumer IR service can stay unmodified.
 */

#define LOG_TAG "ConsumerIrHal"

#include <errno.h>
#include <fcntl.h>
#include <malloc.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include <log/log.h>
#include <hardware/consumerir.h>
#include <hardware/hardware.h>

#define RAON_DEV "/dev/remote_ctrl_dev"
#define RAON_UNIT 250

static const int raon_carriers[] = {
    30000, 33000, 36000, 38000, 40000, 56000
};

static const consumerir_freq_range_t consumerir_freqs[] = {
    {.min = 30000, .max = 30000},
    {.min = 33000, .max = 33000},
    {.min = 36000, .max = 36000},
    {.min = 38000, .max = 38000},
    {.min = 40000, .max = 40000},
    {.min = 56000, .max = 56000},
};

struct raon_ir {
    struct consumerir_device dev;
    int fd;
};

static int raon_ensure_open(struct raon_ir *ir)
{
    if (ir->fd >= 0)
        return 0;
    ir->fd = open(RAON_DEV, O_RDWR | O_CLOEXEC);
    if (ir->fd < 0) {
        ALOGE("open %s failed: %s", RAON_DEV, strerror(errno));
        return -errno;
    }
    return 0;
}

static int raon_write_all(int fd, const uint8_t *buf, size_t len)
{
    size_t off = 0;

    while (off < len) {
        ssize_t n = write(fd, buf + off, len - off);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return -errno;
        }
        if (n == 0)
            return -EIO;
        off += n;
    }
    return 0;
}

static int raon_snap_carrier(int freq)
{
    int best = raon_carriers[0];
    int best_delta = freq > best ? freq - best : best - freq;
    size_t i;

    for (i = 1; i < sizeof(raon_carriers) / sizeof(raon_carriers[0]); i++) {
        int delta = freq > raon_carriers[i] ? freq - raon_carriers[i]
                                            : raon_carriers[i] - freq;
        if (delta < best_delta) {
            best = raon_carriers[i];
            best_delta = delta;
        }
    }
    return best;
}

static int consumerir_transmit(struct consumerir_device *dev, int carrier_freq,
        const int pattern[], int pattern_len)
{
    struct raon_ir *ir = (struct raon_ir *)dev;
    int pkt_len = pattern_len * 2 + 4;
    uint8_t *pkt;
    int src = 0;
    int left;
    int pkt_no = 0;
    int num = 0;
    int ret;
    int64_t total_us = 0;

    if (pattern_len <= 0 || carrier_freq <= 0)
        return -EINVAL;
    ret = raon_ensure_open(ir);
    if (ret)
        return ret;

    /*
     * The blaster plays each duration as a count of carrier cycles.
     * Consumer IR patterns are microseconds, so 9000 at 38 kHz has to
     * become 342 or the frame is stretched about twenty-five times and
     * the TV never sees a real code.
     */
    carrier_freq = raon_snap_carrier(carrier_freq);
    pkt = malloc(pkt_len);
    if (!pkt)
        return -ENOMEM;
    pkt[0] = 0;
    pkt[1] = (carrier_freq >> 16) & 0xff;
    pkt[2] = (carrier_freq >> 8) & 0xff;
    pkt[3] = carrier_freq & 0xff;
    for (int i = 0; i < pattern_len; i++) {
        int64_t cycles;

        if (pattern[i] > 0)
            total_us += pattern[i];
        cycles = (int64_t)pattern[i] * carrier_freq / 1000000;
        if (cycles < 1)
            cycles = 1;
        if (cycles > 65535)
            cycles = 65535;
        pkt[4 + i * 2] = (cycles >> 8) & 0xff;
        pkt[4 + i * 2 + 1] = cycles & 0xff;
    }
    ALOGI("carrier %d Hz, %d pulses, %lld us, first %d cycles",
          carrier_freq, pattern_len, (long long)total_us,
          pattern_len > 0 ? (pkt[4] << 8 | pkt[5]) : 0);

    left = pkt_len;
    while (left > 0) {
        uint8_t unit[RAON_UNIT + 4];
        int chksum;
        int i;

        num = left > RAON_UNIT ? RAON_UNIT : left;
        unit[0] = pkt_no;
        unit[1] = num + 2;
        memcpy(unit + 2, pkt + src, num);
        chksum = pkt_no;
        for (i = 1; i < num + 2; i++)
            chksum += unit[i];
        unit[num + 2] = (chksum >> 8) & 0xff;
        unit[num + 3] = chksum & 0xff;
        ret = raon_write_all(ir->fd, unit, num + 4);
        if (ret)
            break;
        left -= num;
        src += num;
        pkt_no++;
    }
    if (!ret && num == RAON_UNIT) {
        uint8_t tail[4] = { pkt_no, 2, 0, (uint8_t)(pkt_no + 2) };
        ret = raon_write_all(ir->fd, tail, sizeof(tail));
    }
    free(pkt);
    /*
     * The chip NACKs for the whole burst. A second transfer in that
     * window makes the controller abort the code. Wait it out here so
     * the next press starts on an idle chip.
     */
    if (!ret && total_us > 0) {
        if (total_us > 2000000)
            total_us = 2000000;
        usleep(total_us + 80000);
    }
    return ret;
}

static int consumerir_get_num_carrier_freqs(struct consumerir_device *dev)
{
    (void)dev;
    return sizeof(consumerir_freqs) / sizeof(consumerir_freqs[0]);
}

static int consumerir_get_carrier_freqs(struct consumerir_device *dev,
        size_t len, consumerir_freq_range_t *ranges)
{
    size_t n = sizeof(consumerir_freqs) / sizeof(consumerir_freqs[0]);

    (void)dev;

    if (len < n)
        n = len;
    memcpy(ranges, consumerir_freqs, n * sizeof(consumerir_freq_range_t));
    return n;
}

static int consumerir_close(hw_device_t *dev)
{
    struct raon_ir *ir = (struct raon_ir *)dev;

    if (ir->fd >= 0)
        close(ir->fd);
    free(ir);
    return 0;
}

static int consumerir_open(const hw_module_t *module, const char *name,
        hw_device_t **device)
{
    struct raon_ir *ir;

    if (strcmp(name, CONSUMERIR_TRANSMITTER) != 0)
        return -EINVAL;
    ir = calloc(1, sizeof(*ir));
    if (!ir)
        return -ENOMEM;
    ir->fd = -1;
    ir->dev.common.tag = HARDWARE_DEVICE_TAG;
    ir->dev.common.version = 0;
    ir->dev.common.module = (struct hw_module_t *)module;
    ir->dev.common.close = consumerir_close;
    ir->dev.transmit = consumerir_transmit;
    ir->dev.get_num_carrier_freqs = consumerir_get_num_carrier_freqs;
    ir->dev.get_carrier_freqs = consumerir_get_carrier_freqs;
    *device = (hw_device_t *)ir;
    return 0;
}

static struct hw_module_methods_t consumerir_module_methods = {
    .open = consumerir_open,
};

consumerir_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = CONSUMERIR_MODULE_API_VERSION_1_0,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = CONSUMERIR_HARDWARE_MODULE_ID,
        .name = "G0215D Raon IR",
        .author = "G0215D",
        .methods = &consumerir_module_methods,
    },
};
