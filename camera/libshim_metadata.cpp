/*
 * camera.msm8996.so was built against Android 6's CameraMetadata, which
 * is 8 bytes: a buffer pointer and a lock flag, with no vtable.
 * Android 11 adds a Parcelable vtable, so the lock flag sits in the
 * next stack slot the HAL uses for something else. update() then
 * refuses every tag and release() returns a null buffer.
 *
 * This library is named in the HAL's DT_NEEDED in place of
 * libcamera_client.so. It keeps the Android 6 object layout and
 * forwards every other libcamera_client symbol through its own
 * DT_NEEDED on the real library.
 */
#include <system/camera_metadata.h>
#include <utils/Errors.h>
#include <utils/String8.h>

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace android {

class CameraMetadata {
    camera_metadata_t* mBuffer;
    mutable bool mLocked;
    uint8_t mPad[3];

    status_t ensure(size_t extra_entries, size_t extra_data);
    status_t updateImpl(uint32_t tag, const void* data, size_t data_count);

public:
    CameraMetadata();
    CameraMetadata(const CameraMetadata& other);
    ~CameraMetadata();

    CameraMetadata& operator=(const CameraMetadata& other);
    CameraMetadata& operator=(const camera_metadata_t* buffer);

    camera_metadata_t* release();
    void clear();
    size_t entryCount() const;
    bool exists(uint32_t tag) const;

    status_t update(uint32_t tag, const uint8_t* data, size_t data_count);
    status_t update(uint32_t tag, const int32_t* data, size_t data_count);
    status_t update(uint32_t tag, const float* data, size_t data_count);
    status_t update(uint32_t tag, const int64_t* data, size_t data_count);
    status_t update(uint32_t tag, const double* data, size_t data_count);
    status_t update(uint32_t tag, const camera_metadata_rational_t* data,
                    size_t data_count);
    status_t update(uint32_t tag, const String8& string);
    status_t append(const CameraMetadata& other);

    camera_metadata_entry_t find(uint32_t tag);
    camera_metadata_ro_entry_t find(uint32_t tag) const;
};

static_assert(sizeof(CameraMetadata) == 8, "HAL CameraMetadata is 8 bytes");

CameraMetadata::CameraMetadata() : mBuffer(nullptr), mLocked(false) {}

CameraMetadata::CameraMetadata(const CameraMetadata& other) : mLocked(false) {
    mBuffer = other.mBuffer ? clone_camera_metadata(other.mBuffer) : nullptr;
}

CameraMetadata::~CameraMetadata() {
    if (mBuffer)
        free_camera_metadata(mBuffer);
}

CameraMetadata& CameraMetadata::operator=(const CameraMetadata& other) {
    if (this == &other)
        return *this;
    camera_metadata_t* copy =
        other.mBuffer ? clone_camera_metadata(other.mBuffer) : nullptr;
    if (mBuffer)
        free_camera_metadata(mBuffer);
    mBuffer = copy;
    mLocked = false;
    return *this;
}

CameraMetadata& CameraMetadata::operator=(const camera_metadata_t* buffer) {
    if (buffer != mBuffer) {
        camera_metadata_t* copy = buffer ? clone_camera_metadata(buffer) : nullptr;
        if (mBuffer)
            free_camera_metadata(mBuffer);
        mBuffer = copy;
    }
    return *this;
}

camera_metadata_t* CameraMetadata::release() {
    camera_metadata_t* out = mBuffer;
    mBuffer = nullptr;
    mLocked = false;
    return out;
}

void CameraMetadata::clear() {
    if (mBuffer) {
        free_camera_metadata(mBuffer);
        mBuffer = nullptr;
    }
    mLocked = false;
}

size_t CameraMetadata::entryCount() const {
    return mBuffer ? get_camera_metadata_entry_count(mBuffer) : 0;
}

bool CameraMetadata::exists(uint32_t tag) const {
    camera_metadata_ro_entry_t entry;
    return mBuffer && find_camera_metadata_ro_entry(mBuffer, tag, &entry) == 0;
}

status_t CameraMetadata::ensure(size_t extra_entries, size_t extra_data) {
    if (mBuffer == nullptr) {
        mBuffer = allocate_camera_metadata(512, 32 * 1024);
        if (mBuffer == nullptr)
            return NO_MEMORY;
    }
    if (get_camera_metadata_entry_count(mBuffer) + extra_entries <=
            get_camera_metadata_entry_capacity(mBuffer) &&
        get_camera_metadata_data_count(mBuffer) + extra_data <=
            get_camera_metadata_data_capacity(mBuffer))
        return OK;

    size_t entries =
        get_camera_metadata_entry_capacity(mBuffer) * 2 + extra_entries;
    size_t data = get_camera_metadata_data_capacity(mBuffer) * 2 + extra_data;
    camera_metadata_t* grown = allocate_camera_metadata(entries, data);
    if (grown == nullptr)
        return NO_MEMORY;
    if (append_camera_metadata(grown, mBuffer) != 0) {
        free_camera_metadata(grown);
        return NO_MEMORY;
    }
    free_camera_metadata(mBuffer);
    mBuffer = grown;
    return OK;
}

status_t CameraMetadata::updateImpl(uint32_t tag, const void* data,
                                    size_t data_count) {
    if (mLocked)
        return INVALID_OPERATION;
    int type = get_camera_metadata_tag_type(tag);
    if (type == -1)
        return BAD_VALUE;
    size_t data_size =
        calculate_camera_metadata_entry_data_size(type, data_count);
    status_t res = ensure(1, data_size);
    if (res != OK)
        return res;
    camera_metadata_entry_t entry;
    res = find_camera_metadata_entry(mBuffer, tag, &entry);
    if (res == NAME_NOT_FOUND)
        res = add_camera_metadata_entry(mBuffer, tag, data, data_count);
    else if (res == OK)
        res = update_camera_metadata_entry(mBuffer, entry.index, data,
                                           data_count, nullptr);
    return res;
}

status_t CameraMetadata::update(uint32_t tag, const uint8_t* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag, const int32_t* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag, const float* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag, const int64_t* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag, const double* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag,
                                const camera_metadata_rational_t* data,
                                size_t data_count) {
    return updateImpl(tag, data, data_count);
}
status_t CameraMetadata::update(uint32_t tag, const String8& string) {
    return updateImpl(tag, string.string(), string.size() + 1);
}

status_t CameraMetadata::append(const CameraMetadata& other) {
    if (other.mBuffer == nullptr)
        return OK;
    status_t res = ensure(get_camera_metadata_entry_count(other.mBuffer),
                          get_camera_metadata_data_count(other.mBuffer));
    if (res != OK)
        return res;
    return append_camera_metadata(mBuffer, other.mBuffer);
}

camera_metadata_entry_t CameraMetadata::find(uint32_t tag) {
    camera_metadata_entry_t entry;
    memset(&entry, 0, sizeof(entry));
    if (mBuffer)
        find_camera_metadata_entry(mBuffer, tag, &entry);
    return entry;
}

camera_metadata_ro_entry_t CameraMetadata::find(uint32_t tag) const {
    camera_metadata_ro_entry_t entry;
    memset(&entry, 0, sizeof(entry));
    if (mBuffer)
        find_camera_metadata_ro_entry(mBuffer, tag, &entry);
    return entry;
}

}  // namespace android
