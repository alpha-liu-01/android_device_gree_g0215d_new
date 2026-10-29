# Device was launched with M
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_m.mk)

# 1440x2560 at 640 dpi. Physical keys, no software navigation bar.
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi
TARGET_SCREEN_HEIGHT := 2560
TARGET_SCREEN_WIDTH := 1440

# 4 GB profile from phone-xhdpi-4096-dalvik-heap.mk, with heapgrowthlimit
# raised for the 1440x2560 framebuffer. heapsize stays 512m.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=256m \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heaptargetutilization=0.6 \
    dalvik.vm.heapminfree=8m \
    dalvik.vm.heapmaxfree=16m \
    ro.sf.lcd_density=640 \
    qemu.hw.mainkeys=1 \
    ro.opengles.version=196610 \
    ro.hardware.egl=adreno \
    ro.hardware.vulkan=msm8996 \
    ro.sf.hwrotation=180 \
    persist.panel.inversemounted=180 \
    ro.surface_flinger.primary_display_orientation=ORIENTATION_180 \
    sys.usb.controller=6a00000.dwc3 \
    sys.usb.configfs=1 \
    wifi.interface=wlan0 \
    vendor.qcom.bluetooth.soc=rome \
    ro.bt.bdaddr_path=/vendor/etc/bluetooth/bdaddr \
    ro.vendor.rfkilldisabled=0 \
    persist.camera.HAL3.enabled=1 \
    persist.camera.preview.ubwc=0 \
    persist.camera.video.ubwc=0

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.adb.secure=0 \
    persist.sys.usb.config=mtp,adb

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

$(call inherit-product, $(LOCAL_PATH)/radio/radio.mk)
$(call inherit-product, $(LOCAL_PATH)/sensors/sensors.mk)

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# CAF IMS client. The jars satisfy the OnePlus ims.apk uses-library lines.
PRODUCT_PACKAGES += \
    ims \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-utils \
    qti_telephony_utils.xml \
    qti-telephony-hidl-wrapper \
    qti_telephony_hidl_wrapper.xml \
    privapp_whitelist_org_codeaurora_ims

# Display, GPU, Audio, Lights, Wi-Fi, Health, Keymaster
PRODUCT_PACKAGES += \
    fbe-policy \
    gralloc.msm8996 \
    hwcomposer.msm8996 \
    memtrack.msm8996 \
    libdisplayconfig \
    libqdMetaData \
    libqdMetaData.system \
    libtinyxml \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.configstore@1.0-service \
    libEGL_swiftshader \
    libGLESv1_CM_swiftshader \
    libGLESv2_swiftshader \
    android.hardware.keymaster@4.0-service \
    android.hardware.ir@1.0-service \
    android.hardware.ir@1.0-impl \
    consumerir.qcom \
    android.hardware.gatekeeper@1.0-service.software \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl \
    android.hardware.audio.service \
    libc2dcolorconvert \
    libhypv_intercept \
    libmm-omxcore \
    libOmxCore \
    libOmxVdec \
    libOmxVenc \
    libstagefrighthw \
    libOmxAacEnc \
    adsprpcd \
    libfrp \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    audio.primary.msm8996 \
    audio.r_submix.default \
    audio.usb.default \
    android.hardware.bluetooth.audio@2.0-impl \
    audio.bluetooth.default \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service \
    android.hardware.usb@1.0-service.gree \
    android.hardware.vibrator@1.0-impl \
    android.hardware.vibrator@1.0-service \
    vibrator.default \
    libbt-vendor \
    wcnss_filter \
    libacdbloader \
    libaudio-resampler \
    libqcompostprocbundle \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libvolumelistener \
    tinycap \
    tinymix \
    tinyplay \
    fmroute \
    fmtune \
    android.hardware.light@2.0-service \
    lights.msm8996 \
    android.hardware.camera.provider@2.4-service \
    android.hardware.camera.provider@2.4-impl \
    camera.device@1.0-impl \
    camera.device@3.2-impl \
    camera.device@3.3-impl \
    camera.device@3.4-impl \
    camera.device@3.5-impl \
    libshim_camera \
    libshim_mutex \
    libshim_metadata \
    libgu2 \
    android.hardware.wifi@1.0-service \
    libwifi-hal-ctrl \
    libwpa_client \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf \
    android.hardware.gnss@1.0-impl.legacy \
    android.hardware.gnss@1.0-service.legacy \
    libgps.utils \
    libloc_core \
    libloc_eng \
    gps.default \
    android.hardware.biometrics.fingerprint@2.0-service \
    android.hardware.nfc@1.2-service \
    NfcNci \
    Tag

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/public.libraries.txt:$(TARGET_COPY_OUT_VENDOR)/etc/public.libraries.txt \
    $(LOCAL_PATH)/nfc/libnfc-nci.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci.conf \
    $(LOCAL_PATH)/nfc/libnfc-nxp.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nxp.conf \
    $(LOCAL_PATH)/nfc/libpn547_fw.so:$(TARGET_COPY_OUT_VENDOR)/firmware/libpn547_fw.so \
    $(LOCAL_PATH)/nfc/libpn547_fw.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libpn547_fw.so \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom \
    $(LOCAL_PATH)/rootdir/fbe-migrate.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/fbe-migrate.sh \
    $(LOCAL_PATH)/rootdir/etc/fstab.ramdisk:$(TARGET_COPY_OUT_RAMDISK)/fstab.qcom \
    $(LOCAL_PATH)/rootdir/etc/ueventd.qcom.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/mixer_paths_tasha.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_tasha.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    $(LOCAL_PATH)/bluetooth/bdaddr:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth/bdaddr \
    $(LOCAL_PATH)/media/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    $(LOCAL_PATH)/media/mediacodec-arm.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    $(LOCAL_PATH)/media/libOmxAacDec.so:$(TARGET_COPY_OUT_VENDOR)/lib/libOmxAacDec.so \
    $(LOCAL_PATH)/media/lib/libadsprpc.so:$(TARGET_COPY_OUT_VENDOR)/lib/libadsprpc.so \
    $(LOCAL_PATH)/media/lib/libadsp_default_listener.so:$(TARGET_COPY_OUT_VENDOR)/lib/libadsp_default_listener.so \
    $(LOCAL_PATH)/media/lib64/libadsprpc.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libadsprpc.so \
    $(LOCAL_PATH)/media/lib64/libadsp_default_listener.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libadsp_default_listener.so \
    $(LOCAL_PATH)/firmware/tfa98xx.cnt:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/tfa98xx.cnt \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Bluetooth_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Bluetooth_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_General_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_General_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Global_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Global_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Handset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Handset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Hdmi_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Hdmi_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Headset_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Headset_cal.acdb \
    $(LOCAL_PATH)/audio/acdbdata/MTP/MTP_Speaker_cal.acdb:$(TARGET_COPY_OUT_SYSTEM)/etc/acdbdata/MTP/MTP_Speaker_cal.acdb \
    $(LOCAL_PATH)/audio/lib/libacdb-fts.so:$(TARGET_COPY_OUT_VENDOR)/lib/libacdb-fts.so \
    $(LOCAL_PATH)/audio/lib/libacdbrtac.so:$(TARGET_COPY_OUT_VENDOR)/lib/libacdbrtac.so \
    $(LOCAL_PATH)/audio/lib/libadiertac.so:$(TARGET_COPY_OUT_VENDOR)/lib/libadiertac.so \
    $(LOCAL_PATH)/audio/lib/libaudcal.so:$(TARGET_COPY_OUT_VENDOR)/lib/libaudcal.so \
    $(LOCAL_PATH)/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl \
    $(LOCAL_PATH)/keylayout/tiny4412-key.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/tiny4412-key.kl \
    $(LOCAL_PATH)/camera/msm8996_camera_G0215D.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/camera/msm8996_camera_G0215D.xml \
    $(LOCAL_PATH)/camera/etc/s5k3p3_chromatix.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/camera/s5k3p3_chromatix.xml \
    $(LOCAL_PATH)/camera/etc/ov8858_chromatix.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/camera/ov8858_chromatix.xml \
    $(LOCAL_PATH)/camera/bin/mm-qcamera-daemon:$(TARGET_COPY_OUT_VENDOR)/bin/mm-qcamera-daemon \
    $(LOCAL_PATH)/camera/gree-camera.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/gree-camera.rc \
    $(LOCAL_PATH)/camera/lib/hw/camera.msm8996.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/camera.msm8996.so \
    $(foreach lib,$(wildcard $(LOCAL_PATH)/camera/lib/*.so),$(lib):$(TARGET_COPY_OUT_VENDOR)/lib/$(notdir $(lib))) \
    $(foreach lib,$(wildcard $(LOCAL_PATH)/camera/vendor/lib/*.so),$(lib):$(TARGET_COPY_OUT_VENDOR)/lib/$(notdir $(lib))) \
    $(LOCAL_PATH)/firmware/cpp_firmware_v1_10_0.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/cpp_firmware_v1_10_0.fw \
    $(LOCAL_PATH)/firmware/A4_2F_4.0_05.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/A4_2F_4.0_05.fw \
    $(LOCAL_PATH)/firmware/Gree2_4005_V2.06_20170223.raw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/Gree2_4005_V2.06_20170223.raw \
    $(LOCAL_PATH)/firmware/a530_gpmu.fw2:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_gpmu.fw2 \
    $(LOCAL_PATH)/firmware/a530_pfp.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_pfp.fw \
    $(LOCAL_PATH)/firmware/a530_pm4.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_pm4.fw \
    $(LOCAL_PATH)/firmware/a530v1_pfp.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530v1_pfp.fw \
    $(LOCAL_PATH)/firmware/a530v1_pm4.fw:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530v1_pm4.fw \
    $(LOCAL_PATH)/firmware/a530v2_seq.fw2:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530v2_seq.fw2 \
    $(LOCAL_PATH)/firmware/a530v3_gpmu.fw2:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530v3_gpmu.fw2 \
    $(LOCAL_PATH)/firmware/a530v3_seq.fw2:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530v3_seq.fw2 \
    $(LOCAL_PATH)/firmware/a530_zap.b00:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_zap.b00 \
    $(LOCAL_PATH)/firmware/a530_zap.b01:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_zap.b01 \
    $(LOCAL_PATH)/firmware/a530_zap.b02:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_zap.b02 \
    $(LOCAL_PATH)/firmware/a530_zap.elf:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_zap.elf \
    $(LOCAL_PATH)/firmware/a530_zap.mdt:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/a530_zap.mdt \
    $(LOCAL_PATH)/firmware/qwlan30.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/qwlan30.bin \
    $(LOCAL_PATH)/firmware/otp30.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/otp30.bin \
    $(LOCAL_PATH)/firmware/bdwlan30.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/bdwlan30.bin \
    $(LOCAL_PATH)/firmware/utf30.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/utf30.bin \
    $(LOCAL_PATH)/firmware/data.msc:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/data.msc \
    $(LOCAL_PATH)/wifi/WCNSS_cfg.dat:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/wlan/qca_cld/WCNSS_cfg.dat \
    $(LOCAL_PATH)/wifi/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini \
    $(LOCAL_PATH)/wifi/wlan_mac.bin:$(TARGET_COPY_OUT_SYSTEM)/etc/firmware/wlan/qca_cld/wlan_mac.bin \
    $(LOCAL_PATH)/wifi/WCNSS_qcom_cfg.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/WCNSS_qcom_cfg.ini \
    $(LOCAL_PATH)/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/init.atmel_ts.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/init.atmel_ts.sh \
    $(LOCAL_PATH)/panel_hold.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/panel_hold.sh \
    $(LOCAL_PATH)/init.gree.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/init.gree.rc \
    $(LOCAL_PATH)/gps/gps.conf:$(TARGET_COPY_OUT_VENDOR)/etc/gps.conf \
    $(LOCAL_PATH)/gps/libloc_api_v02.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libloc_api_v02.so \
    $(LOCAL_PATH)/fingerprint/gx_fpd:$(TARGET_COPY_OUT_VENDOR)/bin/gx_fpd \
    $(LOCAL_PATH)/fingerprint/libfphal.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libfphal.so \
    $(LOCAL_PATH)/fingerprint/libfpalgorithm.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libfpalgorithm.so \
    $(LOCAL_PATH)/fingerprint/libfp_client.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libfp_client.so \
    $(LOCAL_PATH)/fingerprint/libfpservice.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libfpservice.so \
    $(LOCAL_PATH)/fingerprint/fingerprint.default.so:$(TARGET_COPY_OUT_VENDOR)/lib64/hw/fingerprint.qcom.so \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.output.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.output.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml \
    frameworks/native/data/etc/android.hardware.consumerir.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.consumerir.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.ambient_temperature.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.ambient_temperature.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.hifi_sensors.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hifi_sensors.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.relative_humidity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.relative_humidity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_0_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_0_3.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \
    $(LOCAL_PATH)/gpu/lib/egl/eglSubDriverAndroid.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/eglSubDriverAndroid.so \
    $(LOCAL_PATH)/gpu/lib/egl/libEGL_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libEGL_adreno.so \
    $(LOCAL_PATH)/gpu/lib/egl/libGLESv1_CM_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libGLESv1_CM_adreno.so \
    $(LOCAL_PATH)/gpu/lib/egl/libGLESv2_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libGLESv2_adreno.so \
    $(LOCAL_PATH)/gpu/lib/egl/libq3dtools_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libq3dtools_adreno.so \
    $(LOCAL_PATH)/gpu/lib/egl/libq3dtools_esx.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libq3dtools_esx.so \
    $(LOCAL_PATH)/gpu/lib/egl/libQTapGLES.so:$(TARGET_COPY_OUT_VENDOR)/lib/egl/libQTapGLES.so \
    $(LOCAL_PATH)/gpu/lib/hw/vulkan.msm8996.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/vulkan.msm8996.so \
    $(LOCAL_PATH)/gpu/lib/libadreno_utils.so:$(TARGET_COPY_OUT_VENDOR)/lib/libadreno_utils.so \
    $(LOCAL_PATH)/gpu/lib/libbccQTI.so:$(TARGET_COPY_OUT_VENDOR)/lib/libbccQTI.so \
    $(LOCAL_PATH)/gpu/lib/libC2D2.so:$(TARGET_COPY_OUT_VENDOR)/lib/libC2D2.so \
    $(LOCAL_PATH)/gpu/lib/libc2d30_bltlib.so:$(TARGET_COPY_OUT_VENDOR)/lib/libc2d30_bltlib.so \
    $(LOCAL_PATH)/gpu/lib/libCB.so:$(TARGET_COPY_OUT_VENDOR)/lib/libCB.so \
    $(LOCAL_PATH)/gpu/lib/libdiag.so:$(TARGET_COPY_OUT_VENDOR)/lib/libdiag.so \
    $(LOCAL_PATH)/gpu/lib/libgsl.so:$(TARGET_COPY_OUT_VENDOR)/lib/libgsl.so \
    $(LOCAL_PATH)/gpu/lib/libhdr_tm.so:$(TARGET_COPY_OUT_VENDOR)/lib/libhdr_tm.so \
    $(LOCAL_PATH)/gpu/lib/libllvm-glnext.so:$(TARGET_COPY_OUT_VENDOR)/lib/libllvm-glnext.so \
    $(LOCAL_PATH)/gpu/lib/libllvm-qcom.so:$(TARGET_COPY_OUT_VENDOR)/lib/libllvm-qcom.so \
    $(LOCAL_PATH)/gpu/lib/libOpenCL.so:$(TARGET_COPY_OUT_VENDOR)/lib/libOpenCL.so \
    $(LOCAL_PATH)/gpu/lib/librs_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/librs_adreno.so \
    $(LOCAL_PATH)/gpu/lib/librs_adreno_sha1.so:$(TARGET_COPY_OUT_VENDOR)/lib/librs_adreno_sha1.so \
    $(LOCAL_PATH)/gpu/lib/libRSDriver_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib/libRSDriver_adreno.so \
    $(LOCAL_PATH)/gpu/lib/libscalar.so:$(TARGET_COPY_OUT_VENDOR)/lib/libscalar.so \
    $(LOCAL_PATH)/gpu/lib/libsdm-color.so:$(TARGET_COPY_OUT_VENDOR)/lib/libsdm-color.so \
    $(LOCAL_PATH)/gpu/lib/libsdm-diag.so:$(TARGET_COPY_OUT_VENDOR)/lib/libsdm-diag.so \
    $(LOCAL_PATH)/gpu/lib/libsdmextension.so:$(TARGET_COPY_OUT_VENDOR)/lib/libsdmextension.so \
    $(LOCAL_PATH)/gpu/lib/libtinyxml2_1.so:$(TARGET_COPY_OUT_VENDOR)/lib/libtinyxml2_1.so \
    $(LOCAL_PATH)/gpu/lib64/egl/eglSubDriverAndroid.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/eglSubDriverAndroid.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libEGL_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libEGL_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libGLESv1_CM_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libGLESv1_CM_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libGLESv2_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libGLESv2_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libq3dtools_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libq3dtools_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libq3dtools_esx.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libq3dtools_esx.so \
    $(LOCAL_PATH)/gpu/lib64/egl/libQTapGLES.so:$(TARGET_COPY_OUT_VENDOR)/lib64/egl/libQTapGLES.so \
    $(LOCAL_PATH)/gpu/lib64/hw/vulkan.msm8996.so:$(TARGET_COPY_OUT_VENDOR)/lib64/hw/vulkan.msm8996.so \
    $(LOCAL_PATH)/gpu/lib64/libadreno_utils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libadreno_utils.so \
    $(LOCAL_PATH)/gpu/lib64/libbccQTI.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libbccQTI.so \
    $(LOCAL_PATH)/gpu/lib64/libC2D2.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libC2D2.so \
    $(LOCAL_PATH)/gpu/lib64/libc2d30_bltlib.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libc2d30_bltlib.so \
    $(LOCAL_PATH)/gpu/lib64/libCB.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libCB.so \
    $(LOCAL_PATH)/gpu/lib64/libdiag.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libdiag.so \
    $(LOCAL_PATH)/gpu/lib64/libgsl.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libgsl.so \
    $(LOCAL_PATH)/gpu/lib64/libhdr_tm.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libhdr_tm.so \
    $(LOCAL_PATH)/gpu/lib64/libllvm-glnext.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libllvm-glnext.so \
    $(LOCAL_PATH)/gpu/lib64/libllvm-qcom.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libllvm-qcom.so \
    $(LOCAL_PATH)/gpu/lib64/libOpenCL.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libOpenCL.so \
    $(LOCAL_PATH)/gpu/lib64/librs_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/librs_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/librs_adreno_sha1.so:$(TARGET_COPY_OUT_VENDOR)/lib64/librs_adreno_sha1.so \
    $(LOCAL_PATH)/gpu/lib64/libRSDriver_adreno.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libRSDriver_adreno.so \
    $(LOCAL_PATH)/gpu/lib64/libscalar.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libscalar.so \
    $(LOCAL_PATH)/gpu/lib64/libsdm-color.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libsdm-color.so \
    $(LOCAL_PATH)/gpu/lib64/libsdm-diag.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libsdm-diag.so \
    $(LOCAL_PATH)/gpu/lib64/libsdm-disp-vndapis.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libsdm-disp-vndapis.so \
    $(LOCAL_PATH)/gpu/lib64/libsdmextension.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libsdmextension.so \
    $(LOCAL_PATH)/gpu/lib64/libtinyxml2_1.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libtinyxml2_1.so
