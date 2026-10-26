# Board facts for G0215D. Platform defaults come from msm8996-common.

-include device/xiaomi/msm8996-common/BoardConfigCommon.mk

DEVICE_PATH := device/gree/g0215d

TARGET_OTA_ASSERT_DEVICE := G0215D,g0215d

TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt

# Common uses the Mi 5 cache and userdata sizes, and declares an 832 MiB
# vendor partition this phone does not have. Sizes below were checked against
# the running device. Vendor is created in a later repartition.
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_USERDATAIMAGE_PARTITION_SIZE := 59212771328
BOARD_VENDORIMAGE_PARTITION_SIZE :=
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE :=

# Common points this at a Xiaomi touchpanel node. This phone has no such node.
TARGET_TAP_TO_WAKE_NODE :=

# Kernel source and defconfig stay with msm8996-common
# (kernel/xiaomi/msm8996, vendor/xiaomi/mi8996_defconfig).
# Its cmdline already uses cma=32M, which matches the running boot image.
# The bootloader appends the NT35597 split_dsi panel selector.
