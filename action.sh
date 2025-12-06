#!/system/bin/sh
MODDIR="${0%/*}"
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
LOG_FILE="$TS_HELPER/helper.log"

# Ensure helper folder & log exist
[ -d "$TS_HELPER" ] || mkdir -p "$TS_HELPER" 2>/dev/null || true
[ -f "$LOG_FILE" ] || : > "$LOG_FILE" 2>/dev/null

printf "%s [%s] %s\n" "$(date '+%F %T')" "I" "action.sh started" >> "$LOG_FILE"

# call helper in UI mode
/system/bin/sh "$MODDIR/helper.sh" --ui
RET=$?

exit $RET
