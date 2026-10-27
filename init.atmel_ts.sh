#!/system/bin/sh

# Stock ramdisk script waited 2 seconds, then wrote these names. Wait for the
# node instead, so a slow probe still gets the factory firmware and config.
# update_fw and update_cfg take a filename. request_firmware loads it from
# firmware_class.path=/system/etc/firmware.

# Stock plugin "ac enable 1" turned on T15. The factory OBP_RAW leaves
# T15 CTRL at 0, so BACK / HOME / APP_SWITCH never report until ENABLE
# and RPTEN are set. Walk the object table so this survives address
# changes across config revisions.
enable_t15() {
    mem=/sys/bus/i2c/devices/12-004a/mem_access
    [ -r "$mem" ] || return 0
    nobj=$(dd if="$mem" bs=1 skip=6 count=1 2>/dev/null | od -An -tu1)
    nobj=$(echo "$nobj" | tr -d ' ')
    off=7
    i=0
    while [ "$i" -lt "$nobj" ]; do
        typ=$(dd if="$mem" bs=1 skip=$off count=1 2>/dev/null | od -An -tu1)
        typ=$(echo "$typ" | tr -d ' ')
        start=$(dd if="$mem" bs=1 skip=$((off + 1)) count=2 2>/dev/null | od -An -tu2)
        start=$(echo "$start" | tr -d ' ')
        if [ "$typ" = "15" ]; then
            # CTRL = ENABLE | RPTEN | ADAPTTHREN
            printf '\007' | dd of="$mem" bs=1 seek="$start" count=1 conv=notrunc 2>/dev/null
            return 0
        fi
        off=$((off + 6))
        i=$((i + 1))
    done
}

hold_t15() {
    i=0
    while [ "$i" -lt 8 ]; do
        enable_t15
        ctrl=$(grep -A 1 "^T15" /sys/bus/i2c/devices/12-004a/object 2>/dev/null | sed -n 's/.*: *0*\([0-9a-fA-F]*\) .*/\1/p' | head -n 1)
        [ "$ctrl" = "7" ] && return 0
        sleep 1
        i=$((i + 1))
    done
}

if [ "$1" = "keys-only" ]; then
    hold_t15
    exit 0
fi

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

# update_cfg can finish applying the raw object table after this
# process already wrote CTRL. Retry until T15 stays enabled.
hold_t15
