LOCAL_PATH := $(call my-dir)

# hardware/qcom/Android.mk skips hardware/qcom/gps when
# BOARD_USES_QCOM_HARDWARE is set, so pull the msm8996 HAL in directly.
include $(TOP)/hardware/qcom/gps/msm8996/Android.mk
