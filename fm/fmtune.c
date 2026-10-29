#include <errno.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

/* radio-silabs private controls, same numbers as the Qualcomm FM app. */
#define V4L2_CID_PRV_BASE 0x08000000
#define V4L2_CID_PRV_STATE (V4L2_CID_PRV_BASE + 4)
#define V4L2_CID_PRV_ANTENNA (V4L2_CID_PRV_BASE + 18)
#define FM_OFF 0
#define FM_RECV 1

static int xioctl(int fd, unsigned long req, void *arg)
{
	int r;

	do {
		r = ioctl(fd, req, arg);
	} while (r < 0 && errno == EINTR);
	return r;
}

static int s_ctrl(int fd, __u32 id, __s32 value)
{
	struct v4l2_control c;

	memset(&c, 0, sizeof(c));
	c.id = id;
	c.value = value;
	if (xioctl(fd, VIDIOC_S_CTRL, &c) < 0) {
		fprintf(stderr, "S_CTRL id %#x val %d: %s\n", id, value,
			strerror(errno));
		return -1;
	}
	return 0;
}

static int tune_khz(int fd, unsigned khz)
{
	struct v4l2_frequency f;

	memset(&f, 0, sizeof(f));
	f.tuner = 0;
	f.type = V4L2_TUNER_RADIO;
	/* Driver divides by 16, then by 10 kHz, before the chip command. */
	f.frequency = khz * 16;
	if (xioctl(fd, VIDIOC_S_FREQUENCY, &f) < 0) {
		fprintf(stderr, "S_FREQUENCY %u kHz: %s\n", khz, strerror(errno));
		return -1;
	}
	return 0;
}

static int read_freq(int fd)
{
	struct v4l2_frequency f;

	memset(&f, 0, sizeof(f));
	f.tuner = 0;
	f.type = V4L2_TUNER_RADIO;
	if (xioctl(fd, VIDIOC_G_FREQUENCY, &f) < 0) {
		fprintf(stderr, "G_FREQUENCY: %s\n", strerror(errno));
		return -1;
	}
	printf("tuned %u kHz (raw %u)\n", f.frequency / 16, f.frequency);
	fflush(stdout);
	return 0;
}

static int read_rssi(int fd)
{
	struct v4l2_tuner t;

	memset(&t, 0, sizeof(t));
	if (xioctl(fd, VIDIOC_G_TUNER, &t) < 0) {
		fprintf(stderr, "G_TUNER: %s\n", strerror(errno));
		return -1;
	}
	printf("rssi %d\n", t.signal);
	fflush(stdout);
	return t.signal;
}

int main(int argc, char **argv)
{
	int fd;
	unsigned khz = 91500;

	int scan = 0;

	if (argc > 1) {
		if (!strcmp(argv[1], "off")) {
			fd = open("/dev/radio0", O_RDWR);
			if (fd < 0) {
				perror("open");
				return 1;
			}
			s_ctrl(fd, V4L2_CID_PRV_STATE, FM_OFF);
			close(fd);
			return 0;
		}
		if (!strcmp(argv[1], "scan")) {
			scan = 1;
		} else
		khz = (unsigned)strtoul(argv[1], NULL, 10);
		if (!scan && (khz < 76000 || khz > 108000)) {
			fprintf(stderr, "usage: %s [khz|off]\n", argv[0]);
			return 1;
		}
	}

	fd = open("/dev/radio0", O_RDWR);
	if (fd < 0) {
		perror("open /dev/radio0");
		return 1;
	}
	if (s_ctrl(fd, V4L2_CID_PRV_STATE, FM_RECV) < 0)
		return 1;
	/* RX_HARD_MUTE 0 unmutes both channels. */
	if (s_ctrl(fd, V4L2_CID_AUDIO_MUTE, 0) < 0)
		return 1;
	/* Antenna input 0 is the live pin. Input 1 reads zero. */

	if (scan) {
		unsigned f, rssi, best = 99100, best_rssi = 0;

		for (f = 87500; f <= 107900; f += 200) {
			int level;

			if (tune_khz(fd, f) < 0)
				return 1;
			usleep(250000);
			level = read_rssi(fd);
			if (level < 0)
				return 1;
			rssi = (unsigned)level;
			printf("%u %u\n", f, rssi);
			fflush(stdout);
			if (rssi > best_rssi) {
				best_rssi = rssi;
				best = f;
			}
		}
		printf("best %u rssi %u\n", best, best_rssi);
		fflush(stdout);
		tune_khz(fd, best);
	} else {
		if (tune_khz(fd, khz) < 0)
			return 1;
		sleep(1);
		read_freq(fd);
		read_rssi(fd);
	}
	/* Leave the device open so the chip stays powered. */
	printf("holding /dev/radio0 open\n");
	fflush(stdout);
	for (;;)
		sleep(3600);
}
