#!/system/bin/sh
# Runs TrickyStore Helper after boot with permission check.

MODDIR=${0%/*}
LOGFILE="/data/adb/tricky_store/helper/TSHelper.log"

# Wait until boot is complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

log_print() {
    echo "$(date '+%m-%d %T.%3N') service.sh: $1" >>"$LOGFILE"
}

log_print "Boot completed — verifying permissions..."

# Only fix incorrect permissions once per boot
find "$MODDIR" -type f -name "*.sh" | while read -r shfile; do
    perms=$(stat -c "%a" "$shfile" 2>/dev/null)
    if [ "$perms" != "755" ]; then
        chmod 755 "$shfile"
        log_print "Fixed permissions: $(basename "$shfile")"
    fi
done

# Run helper script
/system/bin/sh "$MODDIR/helper.sh" &
log_print "Helper script executed."
