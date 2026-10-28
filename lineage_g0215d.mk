# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from the G0215D board. This makefile does not pull in
# device/xiaomi/msm8996-common. That inherit stays in the device git
# for the repartitioned layout.
$(call inherit-product, device/gree/g0215d/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_g0215d
PRODUCT_DEVICE := g0215d
PRODUCT_BRAND := Gree
PRODUCT_MODEL := G0215D
PRODUCT_MANUFACTURER := Gree

# TARGET_NO_KERNEL skips the recovery image unless the product asks for it.
# The prebuilt 4.4 kernel is copied by recovery/Android.mk.
PRODUCT_BUILD_RECOVERY_IMAGE := true
