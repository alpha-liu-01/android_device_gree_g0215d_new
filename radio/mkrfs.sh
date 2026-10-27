#!/bin/sh
# Builds /system/rfs for tftp_server. The modem asks for files by a path that
# tftp_server maps below /system/rfs/<msm|mdm|apq>/<mpss|adsp|...>/. In the
# stock image all of these are symlinks into /persist, /data and /firmware.
# Only the msm (MSM8996) trees are used here.
dest="$1"
rm -rf "$dest"
for sub in mpss adsp; do
    d="$dest/msm/$sub"
    mkdir -p "$d/readonly"
    ln -s /vendor/firmware_mnt "$d/readonly/firmware"
    ln -s /persist/hlos_rfs/shared "$d/hlos"
    ln -s /persist/rfs/shared "$d/shared"
    ln -s "/persist/rfs/msm/$sub" "$d/readwrite"
done
ln -s /data/tombstones/modem "$dest/msm/mpss/ramdumps"
ln -s /data/tombstones/lpass "$dest/msm/adsp/ramdumps"
