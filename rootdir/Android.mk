LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),g0215d)

# fstab.qcom mounts modem, dsp and bluetooth under /vendor, and /vendor is
# part of system on this device. The mount points must exist in the image.
G0215D_VENDOR_MOUNT_POINTS := $(addprefix $(TARGET_OUT_VENDOR)/,firmware_mnt dsp bt_firmware)

$(G0215D_VENDOR_MOUNT_POINTS):
	@mkdir -p $@

ALL_DEFAULT_INSTALLED_MODULES += $(G0215D_VENDOR_MOUNT_POINTS)

# tftp_server serves the modem's files from /system/rfs (symlinks into
# /persist, /data and the modem firmware partition).
G0215D_RFS := $(TARGET_OUT)/rfs

$(G0215D_RFS): $(LOCAL_PATH)/../radio/mkrfs.sh
	@echo "Install: $@"
	@sh $< $@

ALL_DEFAULT_INSTALLED_MODULES += $(G0215D_RFS)

endif
