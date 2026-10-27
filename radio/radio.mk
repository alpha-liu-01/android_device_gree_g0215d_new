# Gree G0215D telephony: the stock 64-bit Android 6 Qualcomm modem stack.
# Daemons, QMI/QCRIL libraries and the data configs come unchanged from the
# stock system image; the 18.1 rild/libril loads libril-qc-qmi-1.so.

RADIO_PATH := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

PRODUCT_PACKAGES += \
    libperipheral_client

PRODUCT_COPY_FILES += \
    $(foreach f,$(notdir $(wildcard $(RADIO_PATH)/bin/*)),$(RADIO_PATH)/bin/$(f):$(TARGET_COPY_OUT_VENDOR)/bin/$(f)) \
    $(foreach f,$(notdir $(wildcard $(RADIO_PATH)/lib64/*.so)),$(RADIO_PATH)/lib64/$(f):$(TARGET_COPY_OUT_VENDOR)/lib64/$(f)) \
    $(foreach f,$(notdir $(wildcard $(RADIO_PATH)/etc/data/*.xml)),$(RADIO_PATH)/etc/data/$(f):$(TARGET_COPY_OUT_SYSTEM)/etc/data/$(f)) \
    $(RADIO_PATH)/etc/sec_config:$(TARGET_COPY_OUT_SYSTEM)/etc/sec_config \
    $(RADIO_PATH)/qcril.db:$(TARGET_COPY_OUT_VENDOR)/qcril.db \
    $(RADIO_PATH)/init.gree.radio.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.gree.radio.sh \
    $(RADIO_PATH)/vendor.gree.radio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vendor.gree.radio.rc

# dsds, LTE/WCDMA/GSM. 22,22 of the stock image selects TD-SCDMA, which
# Canadian carriers do not use.
PRODUCT_PROPERTY_OVERRIDES += \
    rild.libpath=/vendor/lib64/libril-qc-qmi-1.so \
    ril.subscription.types=NV,RUIM \
    ro.telephony.default_network=9,9 \
    persist.radio.multisim.config=dsds \
    persist.rild.nitz_plmn= \
    persist.rild.nitz_long_ons_0= \
    persist.rild.nitz_long_ons_1= \
    persist.rild.nitz_short_ons_0= \
    persist.rild.nitz_short_ons_1= \
    persist.radio.apm_sim_not_pwdn=1 \
    persist.radio.sib16_support=1 \
    persist.radio.custom_ecc=1 \
    persist.radio.relay_oprt_change=1 \
    persist.radio.mt_sms_ack=20 \
    persist.radio.calls.on.ims=0 \
    persist.radio.jbims=0 \
    persist.radio.csvt.enabled=false \
    persist.radio.rat_on=combine \
    persist.timed.enable=true \
    persist.cne.feature=1 \
    persist.net.doxlat=false \
    ro.use_data_netmgrd=true \
    persist.data.netmgrd.qos.enable=true \
    persist.rmnet.data.enable=true \
    persist.data.wda.enable=true \
    persist.data.df.dl_mode=5 \
    persist.data.df.ul_mode=5 \
    persist.data.df.agg.dl_pkt=10 \
    persist.data.df.agg.dl_size=4096 \
    persist.data.df.mux_count=8 \
    persist.data.df.iwlan_mux=9 \
    persist.data.df.dev_name=rmnet_usb0 \
    persist.sys.ssr.restart_level=related
