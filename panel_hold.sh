#!/system/bin/sh
# Unblank primary panel once after composer opens fb0 during early boot.
# Do not loop after boot_completed, otherwise lockscreen sleep backlight is
# forced back on every few seconds.
sleep 8
if [ "$(getprop sys.boot_completed)" != "1" ]; then
    echo 0 > /sys/class/graphics/fb0/blank
    if [ "$(cat /sys/class/leds/lcd-backlight/brightness 2>/dev/null)" = "0" ]; then
        echo 180 > /sys/class/leds/lcd-backlight/brightness
    fi
fi
