/*
 * libperipheral_client replacement for the Gree G0215D (MSM8996).
 *
 * QCRIL registers as a client of the "modem" peripheral and expects:
 *   1. pm_client_register()   - returns a handle and the current state
 *   2. pm_client_connect()    - votes for the peripheral to be powered
 *   3. a notifier callback    - EVENT_PERIPH_GOING_ONLINE / IS_ONLINE
 *
 * pm-service does that by opening /dev/subsys_<peripheral>; the kernel
 * (subsystem_restart) loads the firmware on the first open and powers the
 * subsystem down on the last close. The same is done here directly, and the
 * descriptor is kept open for the life of the process.
 *
 * The notifier is called from a worker thread. Nothing is ever powered off
 * again, so the going-offline events never occur and the acknowledge call is
 * a no-op.
 */
#define LOG_TAG "libperipheral_client"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <log/log.h>

enum pm_event {
    EVENT_PERIPH_GOING_OFFLINE = 0,
    EVENT_PERIPH_IS_OFFLINE,
    EVENT_PERIPH_GOING_ONLINE,
    EVENT_PERIPH_IS_ONLINE,
    EVENT_PERIPH_NOT_SUPPORTED,
};

typedef void (*pm_client_notifier)(void* client_data, enum pm_event event);

struct pm_client {
    pm_client_notifier notifier;
    void* client_data;
    char peripheral[32];
    char client[32];
    int fd;
    bool connected;
};

static void* connect_thread(void* arg) {
    pm_client* c = static_cast<pm_client*>(arg);
    char path[64];
    snprintf(path, sizeof(path), "/dev/subsys_%s", c->peripheral);

    if (c->notifier) c->notifier(c->client_data, EVENT_PERIPH_GOING_ONLINE);

    // Blocks until the firmware is loaded and the subsystem is up.
    c->fd = open(path, O_RDONLY);
    if (c->fd < 0) {
        ALOGE("%s: open(%s) failed: %s", c->client, path, strerror(errno));
        if (c->notifier) c->notifier(c->client_data, EVENT_PERIPH_IS_OFFLINE);
        return nullptr;
    }
    ALOGI("%s: %s is online", c->client, c->peripheral);
    if (c->notifier) c->notifier(c->client_data, EVENT_PERIPH_IS_ONLINE);
    return nullptr;
}

extern "C" {

int pm_client_register(pm_client_notifier notifier, void* client_data, const char* peripheral,
                       const char* client, enum pm_event* state, void** handle) {
    if (!peripheral || !client || !handle) return -1;
    pm_client* c = static_cast<pm_client*>(calloc(1, sizeof(*c)));
    if (!c) return -1;
    c->notifier = notifier;
    c->client_data = client_data;
    c->fd = -1;
    strlcpy(c->peripheral, peripheral, sizeof(c->peripheral));
    strlcpy(c->client, client, sizeof(c->client));
    if (state) *state = EVENT_PERIPH_IS_OFFLINE;
    *handle = c;
    ALOGI("%s registered for %s", c->client, c->peripheral);
    return 0;
}

int pm_client_connect(void* handle) {
    pm_client* c = static_cast<pm_client*>(handle);
    if (!c) return -1;
    if (c->connected) return 0;
    c->connected = true;
    pthread_t t;
    if (pthread_create(&t, nullptr, connect_thread, c) != 0) {
        c->connected = false;
        return -1;
    }
    pthread_detach(t);
    return 0;
}

int pm_client_disconnect(void* /*handle*/) {
    // The peripheral stays powered.
    return 0;
}

int pm_client_unregister(void* /*handle*/) {
    return 0;
}

int pm_client_event_acknowledge(void* /*handle*/, enum pm_event /*event*/) {
    return 0;
}

}  // extern "C"

/*
 * libril-qc-qmi-1.so, built for Android 6, still imports this libmedia
 * symbol. It was removed later and the callback is only used for audio
 * server death notifications, so it is provided here as a no-op. The
 * library is a dependency of QCRIL, so the symbol resolves.
 */
namespace android {
class AudioSystem {
public:
    static void setErrorCallback(void (*cb)(int));
};
void AudioSystem::setErrorCallback(void (*)(int)) {}
}  // namespace android
