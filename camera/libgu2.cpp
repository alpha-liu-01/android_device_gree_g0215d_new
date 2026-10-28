/*
 * camera.msm8996.so was built against Android 6's DisplayEventReceiver.
 *
 * Its vsync callback reserves 28 bytes and reads the timestamp at offset 8.
 * Android 11's Event is 40 bytes: a 64-bit display id sits at offset 8 and
 * the timestamp moved to offset 16. getEvents therefore writes past the
 * saved registers and the looper dies in pollInner.
 *
 * The HAL lists this library in place of libgui.so. Symbols it does not
 * define fall through to the real libgui.
 */

#include <dlfcn.h>
#include <stdint.h>
#include <sys/types.h>

namespace android {

class DisplayEventReceiver {
public:
    struct Event {
        uint32_t type;
        uint32_t id;
        int64_t timestamp;
    };

    ssize_t getEvents(Event* events, size_t count);
};

ssize_t DisplayEventReceiver::getEvents(Event* events, size_t count) {
    using real_fn = ssize_t (*)(DisplayEventReceiver*, void*, size_t);
    static real_fn real = 0;
    /* Android 11 Event: type, pad, displayId, timestamp, count, pad, expected. */
    struct NewEvent {
        uint32_t type;
        uint32_t pad0;
        uint64_t display_id;
        int64_t timestamp;
        uint32_t vsync_count;
        uint32_t pad1;
        int64_t expected;
    };
    NewEvent fresh;

    if (real == 0) {
        void* gui = dlopen("libgui.so", RTLD_NOLOAD);
        if (gui == 0)
            gui = dlopen("libgui.so", RTLD_NOW);
        if (gui != 0)
            real = (real_fn)dlsym(
                    gui, "_ZN7android20DisplayEventReceiver9getEventsEPNS0_5EventEj");
    }
    if (real == 0 || events == 0 || count == 0)
        return -1;

    /* The only caller passes count 1 into a 28-byte slot. */
    ssize_t got = real(this, &fresh, 1);
    if (got <= 0)
        return got;
    events->type = fresh.type;
    events->id = 0;
    events->timestamp = fresh.timestamp;
    return 1;
}

}  // namespace android

/*
 * Android 6 android::Parcel is 52 bytes on 32-bit ARM; Android 11 is 60 bytes.
 * camera.msm8996.so allocates two Parcels 52 bytes apart on the stack in
 * QCameraUtils::sendSingleParam and in closeCamera, so constructing the second
 * Parcel corrupts the first and saved registers. Stub the three Parcel methods
 * imported by the HAL and return nullptr from IQService::asInterface so
 * display.qservice transactions become harmless no-ops.
 */
extern "C" void _ZN8qService9IQService11asInterfaceERKN7android2spINS1_7IBinderEEE(
        void** out, const void* /*obj*/) {
    if (out != 0)
        *out = 0;
}

extern "C" void* _ZN7android6ParcelC1Ev(void* self) {
    return self;
}

extern "C" void* _ZN7android6ParcelD1Ev(void* self) {
    return self;
}

extern "C" int _ZN7android6Parcel10writeInt32Ei(void* /*self*/, int /*val*/) {
    return 0;
}


