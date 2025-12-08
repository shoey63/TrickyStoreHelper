#!/system/bin/sh
MODDIR="${0%/*}"
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
LOG_FILE="$TS_HELPER/helper.log"

# Ensure helper folder & log exist
[ -d "$TS_HELPER" ] || mkdir -p "$TS_HELPER" 2>/dev/null || true
[ -f "$LOG_FILE" ] || : > "$LOG_FILE" 2>/dev/null

printf "%s [%s] %s\n" "$(date '+%F %T')" "I" "action.sh started" >> "$LOG_FILE"

# Detect Magisk (KernelSU/APatch do NOT have this file)
MAGISK_ENV=0
[ -f /data/adb/magisk.db ] && MAGISK_ENV=1

# Run helper.sh in UI mode
/system/bin/sh "$MODDIR/helper.sh" --ui
RET=$?

# Magisk closes UI instantly unless we keep shell open.
if [ "$MAGISK_ENV" = 1 ]; then
    echo ""
    echo "---------------------------------------"
    echo "Magisk detected — keeping window open."
    echo "Type 'exit' to close."
    # Give Magisk an interactive shell
    exec sh -i
fi

exit $RET
