#!/system/bin/sh
# Move plaintext directories aside so Android can put an fscrypt policy on an
# empty directory, then copy the files back. A rename into an encrypted
# directory does not encrypt existing extents, so the copy has to create new
# files. Staging stays under /data until the copy finishes.

STAGE=/data/fbe-staging
POLICY=/system/bin/fbe-policy

note() {
    echo "fbe-migrate: $*" >> /data/fbe-migrate.log
    echo "fbe-migrate: $*" > /dev/kmsg
}

is_encrypted() {
    [ -d "$1" ] || return 1
    status=$("$POLICY" status "$1") || return 1
    [ "$status" = encrypted ]
}

park_dir() {
    src=$1
    name=$2
    [ -d "$src" ] || return 0
    [ -e "$STAGE/$name" ] && return 0
    if is_encrypted "$src"; then
        return 0
    fi
    if [ -z "$(/system/bin/ls -A "$src")" ]; then
        return 0
    fi
    /system/bin/mkdir -p "$STAGE"
    /system/bin/mv "$src" "$STAGE/$name"
    note "parked $src"
}

park_contents() {
    src=$1
    name=$2
    [ -d "$src" ] || return 0
    [ -d "$STAGE/$name" ] && return 0
    if is_encrypted "$src"; then
        return 0
    fi
    if [ -z "$(/system/bin/ls -A "$src")" ]; then
        return 0
    fi
    /system/bin/mkdir -p "$STAGE/$name"
    /system/bin/ls -A "$src" | while IFS= read -r entry; do
        /system/bin/mv "$src/$entry" "$STAGE/$name/"
    done
    note "parked contents of $src"
}

restore_dir() {
    name=$1
    dest=$2
    src="$STAGE/$name"
    [ -d "$src" ] || return 0
    /system/bin/mkdir -p "$dest"
    if ! /system/bin/cp -a "$src"/. "$dest"/; then
        note "restore failed: $dest"
        return 1
    fi
    /system/bin/rm -rf "$src"
    note "restored $dest"
}

device_early="bootchart misc local vendor app-private app-ephemeral app-asec app-lib app property tombstones dalvik-cache ota ota_package resource-cache drm mediadrm anr nfc backup ss system"
device_late="cache incremental"

case "$1" in
prepare-device)
    for name in bootchart misc local vendor app-private app-ephemeral app-asec app-lib app property tombstones dalvik-cache ota ota_package resource-cache drm mediadrm anr nfc backup ss cache incremental adbroot ssh; do
        park_dir "/data/$name" "$name"
    done
    ;;
restore-one)
    restore_dir "$2" "/data/$2"
    ;;
prepare-system)
    park_dir /data/system system
    ;;
restore-device-early)
    for name in $device_early; do
        restore_dir "$name" "/data/$name"
    done
    ;;
restore-device-late)
    for name in $device_late; do
        restore_dir "$name" "/data/$name"
    done
    ;;
prepare-user-de)
    park_dir /data/system_de/0 system_de_0
    park_dir /data/misc_de/0 misc_de_0
    park_dir /data/vendor_de/0 vendor_de_0
    park_dir /data/user_de/0 user_de_0
    ;;
restore-user-de)
    restore_dir system_de_0 /data/system_de/0
    restore_dir misc_de_0 /data/misc_de/0
    restore_dir vendor_de_0 /data/vendor_de/0
    restore_dir user_de_0 /data/user_de/0
    ;;
prepare-ce)
    park_dir /data/system_ce/0 system_ce_0
    park_dir /data/misc_ce/0 misc_ce_0
    park_dir /data/vendor_ce/0 vendor_ce_0
    park_dir /data/media/0 media_0
    park_contents /data/data data
    ;;
restore-ce)
    restore_dir system_ce_0 /data/system_ce/0
    restore_dir misc_ce_0 /data/misc_ce/0
    restore_dir vendor_ce_0 /data/vendor_ce/0
    restore_dir media_0 /data/media/0
    restore_dir data /data/data
    if [ -d /data/fbe-staging ] && [ -z "$(ls -A /data/fbe-staging)" ]; then
        rmdir /data/fbe-staging
    fi
    restorecon -R /data/system_ce/0 /data/misc_ce/0 /data/vendor_ce/0 /data/media/0 /data/data
    note "ce restore done"
    ;;
*)
    note "unknown phase $1"
    exit 1
    ;;
esac
sync
note "phase $1 done"
