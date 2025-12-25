#!/system/bin/sh
#
# service.sh - Boot logic for TrickyStoreHelper
#
MODDIR=${0%/*}
LOCK_DIR="/dev/ts_helper_lock"
CONFIG_FILE="/data/adb/tricky_store/helper/config.txt"
LOG_FILE="/data/adb/tricky_store/helper/TSHelper.log"

# --- 1. Atomic Double-Execution Prevention ---
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

# --- 2. Permission Fix ---
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod 755 "$f"
    fi
done
echo "$(date '+%T') UI: Executable permissions verified" >> "$LOG_FILE"

# --- 2. Check Boot Config ---
# Default to "true" (run on boot) if the variable is missing
RUN_ON_BOOT="true"

if [ -f "$CONFIG_FILE" ]; then
    # Read value, strip whitespace (handles spaces, tabs, newlines)
    VAL=$(grep "^RUN_ON_BOOT=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    
    # Check for "false" or "0" to disable
    if [ "$VAL" = "false" ] || [ "$VAL" = "0" ]; then
        RUN_ON_BOOT="false"
    fi
fi

# Exit if disabled
if [ "$RUN_ON_BOOT" = "false" ]; then
    # Log the skip so you aren't wondering why it didn't run
    echo "$(date '+%T') UI: ℹ️ Boot execution skipped (RUN_ON_BOOT=false)." >> "$LOG_FILE"
    exit 0
fi



# --- 4. Wait for Boot Completion ---
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# --- 5. Run action.sh ---
sh "$MODDIR/action.sh" boot
