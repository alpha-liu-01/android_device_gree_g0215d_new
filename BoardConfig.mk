# G0215D on Lineage 18.1. No separate vendor partition.
# Do not inherit device/xiaomi/msm8996-common or device/oppo/common.

DEVICE_PATH := device/gree/g0215d

TARGET_OTA_ASSERT_DEVICE := G0215D,g0215d

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := msm8996
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := msm8996
TARGET_BOARD_PLATFORM_GPU := qcom-adreno530

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := kryo

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := kryo

TARGET_USES_64_BIT_BINDER := true

# Kernel image is the phase 2 Image.gz-dtb, packed in a later step.
# This tree does not compile kernel/oneplus/msm8996 or kernel/xiaomi/msm8996.
TARGET_NO_KERNEL := true
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_CMDLINE := console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 cma=32M@0-0xffffffff androidboot.selinux=permissive firmware_class.path=/system/etc/firmware androidboot.boot_devices=soc/624000.ufshc

# Partitions. system is the whole 3 GiB. vendor files stay inside it.
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
BOARD_USERDATAIMAGE_PARTITION_SIZE := 59212771328
BOARD_FLASH_BLOCK_SIZE := 262144
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_HAS_LARGE_FILESYSTEM := true

# QCOM
BOARD_USES_QCOM_HARDWARE := true
BOARD_USES_ADRENO := true
TARGET_USES_HWC2 := true
TARGET_USES_GRALLOC1 := true
TARGET_USES_ION := true
TARGET_USES_OVERLAY := true
TARGET_USES_C2D_COMPOSITION := true
USE_OPENGL_RENDERER := true
MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024
OVERRIDE_RS_DRIVER := libRSDriver_adreno.so
MAX_VIRTUAL_DISPLAY_DIMENSION := 4096
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
TARGET_PROVIDES_LIBLIGHT := true

# GPS. hardware/qcom/gps/msm8996 builds gps.default, libloc_core and
# libgps.utils. The 2016 libloc_api_v02.so talks to the modem over QMI.
BOARD_VENDOR_QCOM_GPS_LOC_API_HARDWARE := default
BOARD_VENDOR_QCOM_LOC_PDK_FEATURE_SET := true

# Audio. CAF msm8996 HAL; it reads kernel uapi headers from
# $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr (see docs, step 7C).
BOARD_USES_ALSA_AUDIO := true
USE_XML_AUDIO_POLICY_CONF := 1
AUDIO_USE_LL_AS_PRIMARY_OUTPUT := true
# Also needed for the HAL to build: with no sound trigger, listen or
# device arbitration, audio_extn/utils.c has an unused parameter (-Werror).
BOARD_SUPPORTS_SOUND_TRIGGER := true
# QCRIL tells the HAL which voice session a call uses ("call_state=2;vsid=
# 0x11C05000", VoiceMMode1). Without this the HAL ignores that parameter and
# opens the legacy CS-Voice session instead (step 7F, voice audio).
AUDIO_FEATURE_ENABLED_MULTI_VOICE_SESSIONS := true
# Si4705 digital audio is a tertiary-MI2S loopback. The HAL only opens
# that path when this flag compiles audio_extn/fm.c.
AUDIO_FEATURE_ENABLED_FM_POWER_OPT := true
# ADSP loads codec modules (HeaacDecoderModule.so.1, etc.) from /dsp via adsprpcd.
BOARD_ROOT_EXTRA_SYMLINKS += /vendor/dsp:/dsp

# Bluetooth. QCA6174 "Rome" 3.2 on /dev/ttyHS0. libbt-vendor comes from
# hardware/qcom-caf/bt and downloads btfw32.tlv / btnv32.bin from
# /bt_firmware/image. The root is the system image, so the symlink to
# /vendor/bt_firmware goes there.
# Gree's old wcnss_filter keeps the unprefixed wc_transport.* properties.
# No libbtnv: its blob is 32-bit only; the stack's own address is used.
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true
BOARD_HAS_QCA_BT_ROME := true
QCOM_BT_USE_OLD_WCNSS_FILTER := true
BOARD_ROOT_EXTRA_SYMLINKS += /vendor/bt_firmware:/bt_firmware

# Telephony. Gree's 64-bit Android 6 QCRIL (libril-qc-qmi-1.so) is loaded by
# the 18.1 rild. Dual SIM there is one rild per SIM (rild, rild -c 2), each
# with its own RIL_Env, so libril must keep the single-slot 3-argument
# callbacks: no SIM_COUNT=2. Old MNC encoding of that era.
# The modem daemons (rmt_storage, tftp_server) use /persist and
# /dev/block/bootdevice, which the stock image provided.
# /persist is a real directory, not a symlink. sensors.qcom compares the
# path with realpath() and rejects a symlink to /mnt/vendor/persist.
# init.gree.rc bind-mounts the partition there after mount_all.
TARGET_USES_OLD_MNC_FORMAT := true
BOARD_ROOT_EXTRA_FOLDERS += persist
BOARD_ROOT_EXTRA_SYMLINKS += /vendor/firmware_mnt:/firmware

# VINTF
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml

# Wifi (QCA6174 PCIe / qcacld-2.0)
BOARD_HAS_QCOM_WLAN := true
BOARD_HAS_QCOM_WLAN_SDK := true
BOARD_WLAN_DEVICE := qcwcn
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
HOSTAPD_VERSION := VER_0_8_X
WIFI_AVOID_IFACE_RESET_MAC_CHANGE := true
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_P2P := "p2p"
WIFI_DRIVER_FW_PATH_PARAM := "/sys/module/wlan/parameters/fwpath"
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# TWRP 3.7.0_11, built from TeamWin's android-11 branch in the 18.1 tree.
# The kernel is the one already running in boot-fp8; this tree does not rebuild it.
# Decryption target for the next step is file-based ext4 crypto, policy v1
# (legacy session keyring). The 4.4 kernel has EXT4_ENCRYPTION and does not
# implement FS_IOC_ADD_ENCRYPTION_KEY, metadata encryption, or the old ICE
# full-disk mapping. Footer encryption stays out of this fstab.
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
TARGET_PREBUILT_RECOVERY_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
RECOVERY_SDCARD_ON_DATA := true
TW_DEVICE_VERSION := g0215d
TW_THEME := portrait_hdpi
# The panel is mounted 180 degrees. SurfaceFlinger rotates Android; TWRP rotates
# its own framebuffer the same way. Touch is already in that upright space, so
# flipping X or Y turns the pointer upside down.
TW_ROTATION := 180
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 180
TW_NO_SCREEN_BLANK := true
# Dim-to-5 then brightness 0 is the phase-2 failure: the picture goes away and
# a dropped touch never brings it back.
TW_NO_SCREEN_TIMEOUT := true
# A zero touch-major is not a finger-up on this controller.
TW_IGNORE_MAJOR_AXIS_0 := true
TW_INCLUDE_CRYPTO := true
TW_USE_FSCRYPT_POLICY := 1
# Software keymaster 4.0 unwraps the FBE keys. The ramdisk had the client
# libraries only, so hwservicemanager never found a service to start.
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT)/lib64/libkeymaster4.so \
    $(TARGET_OUT)/lib64/libpuresoftkeymasterdevice.so
# /vendor in the ramdisk is a symlink to /system/vendor, and that symlink is
# absolute, so the usual vendor/bin/hw relink writes onto the host. Copy
# straight into system/vendor while the ramdisk is packed.
BOARD_RECOVERY_IMAGE_PREPARE = mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/system/vendor/bin/hw && cp -f $(TARGET_OUT)/vendor/bin/hw/android.hardware.keymaster@4.0-service $(TARGET_OUT)/vendor/bin/hw/android.hardware.gatekeeper@1.0-service.software $(TARGET_RECOVERY_ROOT_OUT)/system/vendor/bin/hw/
TW_EXCLUDE_APEX := true
TW_EXCLUDE_MTP := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_TWRPAPP := true

# Soong reads these through VendorConfig("makeVarsPlugin"). BoardConfig
# variables are not visible to the theme and graphics defaults otherwise.
SOONG_CONFIG_NAMESPACES += makeVarsPlugin
SOONG_CONFIG_makeVarsPlugin += \
    TW_THEME \
    TW_ROTATION \
    TARGET_RECOVERY_PIXEL_FORMAT \
    TW_USE_FSCRYPT_POLICY \
    TW_INCLUDE_CRYPTO \
    TW_NO_SCREEN_BLANK \
    TW_NO_SCREEN_TIMEOUT \
    TW_IGNORE_MAJOR_AXIS_0 \
    TW_EXCLUDE_NANO
SOONG_CONFIG_makeVarsPlugin_TW_THEME := portrait_hdpi
SOONG_CONFIG_makeVarsPlugin_TW_ROTATION := 180
SOONG_CONFIG_makeVarsPlugin_TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
SOONG_CONFIG_makeVarsPlugin_TW_USE_FSCRYPT_POLICY := 1
SOONG_CONFIG_makeVarsPlugin_TW_INCLUDE_CRYPTO := true
SOONG_CONFIG_makeVarsPlugin_TW_NO_SCREEN_BLANK := true
SOONG_CONFIG_makeVarsPlugin_TW_NO_SCREEN_TIMEOUT := true
SOONG_CONFIG_makeVarsPlugin_TW_IGNORE_MAJOR_AXIS_0 := true
SOONG_CONFIG_makeVarsPlugin_TW_EXCLUDE_NANO := true

# SELinux
include device/qcom/sepolicy-legacy-um/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
