# Start the SSC daemon, load SLPI, then start the sensors HAL.
# sensors.qcom must be serving /persist/sensors/sns.reg before SLPI boots,
# or SMGR never publishes the sensor services. The HAL reads that list
# once, so it has to start after SLPI is ONLINE.

setprop ctl.start sensors

i=0
while [ "$i" -lt 50 ]; do
    pid=$(pidof sensors.qcom)
    if [ -n "$pid" ] && ls -l /proc/$pid/fd 2>/dev/null | grep -q sns.reg; then
        break
    fi
    i=$((i + 1))
    sleep 0.1
done

# Write 1 only. Writing 0 unloads SLPI and, with restart_level RELATED,
# takes the whole phone down.
echo 1 > /sys/kernel/boot_slpi/boot

i=0
while [ "$i" -lt 50 ]; do
    state=$(cat /sys/bus/msm_subsys/devices/subsys4/state 2>/dev/null)
    if [ "$state" = "ONLINE" ]; then
        break
    fi
    i=$((i + 1))
    sleep 0.1
done

# The daemon spends about two seconds timing out QCCI probes for sensor
# services this phone does not have. A request from the HAL in that
# window returns EBUSY and the HAL keeps an empty list. Wait it out.
echo "sensors-boot: slpi online, waiting" > /dev/kmsg
sleep 3
echo "sensors-boot: starting hal" > /dev/kmsg
setprop ctl.start vendor.sensors-hal-1-0
