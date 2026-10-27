# SSC sensors. SLPI firmware is already on the modem partition; these are the
# stock Android 6 userspace pieces plus the HIDL wrapper.

# inherit-product expands PRODUCT_COPY_FILES after every Android.mk has
# overwritten LOCAL_PATH, so keep a private path.
SENSORS_PATH := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

PRODUCT_PACKAGES += \
    sensors.qcom \
    libsensor1 \
    libsensor_reg \
    sensors.ssc \
    sensors.qcom.multihal \
    liblocationservice \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service

PRODUCT_COPY_FILES += \
    $(SENSORS_PATH)/etc/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf \
    $(SENSORS_PATH)/init.gree.sensors.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.gree.sensors.sh
