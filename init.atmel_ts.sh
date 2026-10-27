#!/system/bin/sh

# Stock ramdisk script waited 2 seconds, then wrote these names. Wait for the
# node instead, so a slow probe still gets the factory firmware and config.
# update_fw and update_cfg take a filename. request_firmware loads it from
# firmware_class.path=/system/etc/firmware.
i=0
while [ ! -e /sys/bus/i2c/devices/12-004a/update_fw ]; do
    i=$((i + 1))
    if [ "$i" -gt 30 ]; then
        exit 1
    fi
    sleep 1
done

cd /sys/bus/i2c/devices/12-004a || exit 1
# Do not rewrite the application here. An interrupted update_fw leaves the
# chip in the bootloader with APP_CRC_FAIL, and this kernel has no
# atmel,fw_version so probe then fails and recovery has no touch.
# The chip is already Family 164 / Variant 47 / V4.0.05.
echo "Gree2_4005_V2.06_20170223.raw" > update_cfg
sleep 1

# This kernel records plugin writes and does not run the stock atmel_stand
# engine. The config itself is applied by update_cfg above.
echo "ac enable 1" > plugin
echo "pl enable 20" > plugin
