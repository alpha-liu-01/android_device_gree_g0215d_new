#!/vendor/bin/sh
# QCRIL keeps its settings in /data/misc/radio/qcril.db. Seed it from the
# prebuilt copy once, like the stock init.qcom.sh did.
if [ -f /vendor/qcril.db -a ! -f /data/misc/radio/qcril.db ]; then
    cp /vendor/qcril.db /data/misc/radio/qcril.db
    chown radio.radio /data/misc/radio/qcril.db
    chmod 0660 /data/misc/radio/qcril.db
    restorecon /data/misc/radio/qcril.db
fi
echo 1 > /data/misc/radio/db_check_done
chown radio.radio /data/misc/radio/db_check_done
