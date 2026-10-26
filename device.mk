# Board facts for G0215D. Platform packages come from msm8996-common.

# Inherit from msm8996-common
$(call inherit-product, device/xiaomi/msm8996-common/msm8996.mk)

# Common is the Mi 5 1080p xxhdpi panel. This phone is 1440x2560 at 640 dpi.
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi
TARGET_SCREEN_HEIGHT := 2560
TARGET_SCREEN_WIDTH := 1440

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# HALO mixer and platform info. Speaker paths use SLIMBUS, not QUAT_MI2S.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/mixer_paths_tasha.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_tasha.xml

# Common ships a Mi 5 gpio-keys.kl. This phone's file maps key 59 to GREE_KEY.
PRODUCT_COPY_FILES := $(filter-out %/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl,$(PRODUCT_COPY_FILES))

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl \
    $(LOCAL_PATH)/keylayout/tiny4412-key.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/tiny4412-key.kl

# The Gree sensor library opens this exact path and filename.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/camera/msm8996_camera_G0215D.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/camera/msm8996_camera_G0215D.xml

# Common already packages android.hardware.light-service.lineage. It binds
# lcd-backlight, button-backlight, and red/green/blue, and scales to
# max_brightness. Do not also build the Android 6 lights.msm8996 module.

# Goodix node and data dir. The daemon binary stays out of this tree.
# Raon IR HAL. This is not Consumer IR.
PRODUCT_PACKAGES += \
    init.gree.rc \
    ueventd.gree.rc \
    remoteir.default
