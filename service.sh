#!/system/bin/sh
MODDIR="${0%/*}"
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
LOG_FILE="$TS_HELPER/helper.log"

# Ensure helper folder & log exist
[ -d "$TS_HELPER" ] || mkdir -p "$TS_HELPER" 2>/dev/null || true
[ -f "$LOG_FILE" ] || : > "$LOG_FILE" 2>/dev/null

printf "%s [%s] %s\n" "$(date '+%F %T')" "I" "service.sh started" >> "$LOG_FILE"

# Wait for boot_completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Fix perms on scripts if needed
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    CUR=$(stat -c "%a" "$f" 2>/dev/null)
    if [ "$CUR" != "755" ]; then
        chmod 755 "$f" 2>/dev/null || true
        printf "%s [%s] %s\n" "$(date '+%F %T')" "I" "fixed perms: $f" >> "$LOG_FILE"
    fi
done

# Run helper silently (no --ui)
# helper.sh will log everything and neutralize true/true in-memory only
/system/bin/sh "$MODDIR/helper.sh"
RET=$?

printf "%s [%s] %s\n" "$(date '+%F %T')" "I" "service.sh finished helper.sh (exit $RET)" >> "$LOG_FILE"
exit 0
