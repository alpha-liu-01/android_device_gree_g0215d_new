LOCAL_PATH := $(call my-dir)

# kernel.mk ignores a prebuilt recovery kernel while TARGET_NO_KERNEL is set.
# The image header still needs the running 4.4 Image.gz-dtb.
ifeq ($(TARGET_NO_KERNEL),true)
ifneq ($(TARGET_PREBUILT_RECOVERY_KERNEL),)
$(PRODUCT_OUT)/recovery_kernel: $(TARGET_PREBUILT_RECOVERY_KERNEL)
	mkdir -p $(dir $@)
	cp -f $< $@
endif
endif
