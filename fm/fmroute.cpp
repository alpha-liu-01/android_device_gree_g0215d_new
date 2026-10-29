#include <media/AudioSystem.h>
#include <media/AudioTrack.h>
#include <binder/ProcessState.h>
#include <utils/String8.h>

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/*
 * Starts or stops the CAF FM loopback.
 * Headphones: fmroute 1048580
 * Headset:    fmroute 1048584
 * Off:        fmroute 4
 * Manual:     fmroute volume 0.2
 * Listen:     fmroute listen
 *
 * listen follows the media-volume curve and holds a silent music track
 * so the volume keys adjust STREAM_MUSIC. AudioFlinger copies that gain
 * onto the FM loopback.
 *
 * 0x100000 is AUDIO_DEVICE_OUT_FM. The HAL strips that bit and routes
 * the rest (4 = wired headphone, 8 = wired headset).
 */

static float current_music_amplitude(void)
{
	const audio_devices_t devices[] = {
		AUDIO_DEVICE_OUT_WIRED_HEADPHONE,
		AUDIO_DEVICE_OUT_WIRED_HEADSET,
		AUDIO_DEVICE_OUT_SPEAKER,
	};
	unsigned i;

	for (i = 0; i < sizeof(devices) / sizeof(devices[0]); i++) {
		int index = -1;
		float db, amp;

		if (android::AudioSystem::getStreamVolumeIndex(
				AUDIO_STREAM_MUSIC, &index, devices[i]) != android::OK)
			continue;
		if (index < 0)
			continue;
		db = android::AudioSystem::getStreamVolumeDB(
				AUDIO_STREAM_MUSIC, index, devices[i]);
		/* Same dB-to-amplitude conversion as the Qualcomm FM app. */
		amp = expf(db * 0.115129f);
		if (amp < 0.f)
			amp = 0.f;
		if (amp > 1.f)
			amp = 1.f;
		printf("music index %d device %#x -> %.1f dB, gain %.4f\n",
			index, devices[i], db, amp);
		return amp;
	}
	return 0.02f;
}

static int listen(void)
{
	android::String8 on("handle_fm=1048580");
	float amp = current_music_amplitude();
	android::String8 vol = android::String8::format("fm_volume=%f", amp);
	android::status_t st;
	android::sp<android::AudioTrack> track;
	int16_t zeros[960];

	android::ProcessState::self()->startThreadPool();

	st = android::AudioSystem::setParameters(on);
	printf("%s -> %d\n", on.string(), st);
	st = android::AudioSystem::setParameters(vol);
	printf("%s -> %d\n", vol.string(), st);

	track = new android::AudioTrack(AUDIO_STREAM_MUSIC, 48000,
			AUDIO_FORMAT_PCM_16_BIT, AUDIO_CHANNEL_OUT_STEREO);
	st = track->initCheck();
	if (st != android::OK) {
		fprintf(stderr, "AudioTrack init %d\n", st);
		return 1;
	}
	track->start();
	memset(zeros, 0, sizeof(zeros));
	for (;;) {
		ssize_t n = track->write(zeros, sizeof(zeros));
		if (n < 0)
			usleep(20000);
	}
}

int main(int argc, char **argv)
{
	android::String8 params;

	if (argc == 2 && !strcmp(argv[1], "listen"))
		return listen();

	if (argc == 3 && !strcmp(argv[1], "volume"))
		params = android::String8::format("fm_volume=%s", argv[2]);
	else if (argc == 2)
		params = android::String8::format("handle_fm=%s", argv[1]);
	else {
		fprintf(stderr, "usage: %s <handle_fm>|volume <0..1>|listen\n",
			argv[0]);
		return 1;
	}

	android::status_t st = android::AudioSystem::setParameters(params);
	printf("%s -> %d\n", params.string(), st);
	return st == android::OK ? 0 : 1;
}
