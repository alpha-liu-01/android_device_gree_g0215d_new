# Inherit from the G0215D board
$(call inherit-product, device/gree/g0215d/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_g0215d
PRODUCT_DEVICE := g0215d
PRODUCT_BRAND := Gree
PRODUCT_MODEL := G0215D
PRODUCT_MANUFACTURER := Gree
