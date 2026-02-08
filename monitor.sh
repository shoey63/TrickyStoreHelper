#!/system/bin/sh
# monitor.sh - Smart Differential Updater (uses pm list)

MODDIR=${0%/*}

TS_FOLDER="/data/adb/tricky_store"

# Module-local helper (aligned with customize/action/service)
HELPER_FOLDER="$MODDIR/helper"

TARGET_FILE="$TS_FOLDER/target.txt"
EXCLUDE_FILE="$HELPER_FOLDER/exclude.txt"
CONFIG_FILE="$HELPER_FOLDER/config.txt"
LOG_FILE="$HELPER_FOLDER/TSHelper.log"

# Ensure helper/log exist (safe on boot)
mkdir -p "$HELPER_FOLDER"
touch "$LOG_FILE"

# UI Logger
log_print() { echo "$(date '+%T') Monitor: $1" >> "$LOG_FILE"; }

# --- 1. Settle Down ---
sleep 5

# Check requirements
[ -f "$TARGET_FILE" ] || exit 0

# --- 2. Setup Unique Temp Files ---
PID=$$
CLEAN_TARGET="/dev/ts_mon_target_${PID}.tmp"
CLEAN_EXCLUDE="/dev/ts_mon_exclude_${PID}.tmp"
RESULTS_FILE="/dev/ts_mon_results_${PID}.tmp"

# --- 3. Auto Cleanup ---
trap 'rm -f "$CLEAN_TARGET" "$CLEAN_EXCLUDE" "$RESULTS_FILE"; exit' EXIT HUP INT TERM

# --- 4. Load Configuration ---
USE_DEF_EXCL="true"
if [ -f "$CONFIG_FILE" ]; then
    VAL=$(grep "^USE_DEFAULT_EXCLUSIONS=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    [ "$VAL" = "false" ] && USE_DEF_EXCL="false"
fi

# --- 5. Prepare Memory Lists ---
# Clean target: strip CR, whitespace, suffix markers
tr -d '\r' < "$TARGET_FILE" | sed 's/[ \t]*[?!]*[ \t]*$//' > "$CLEAN_TARGET"

# Clean exclude
if [ -f "$EXCLUDE_FILE" ]; then
    tr -d '\r' < "$EXCLUDE_FILE" | sed 's/^[ \t]*//;s/[ \t]*$//' > "$CLEAN_EXCLUDE"
else
    : > "$CLEAN_EXCLUDE"
fi

# --- 6. Generate Candidate Stream ---
generate_candidates() {
    if [ "$USE_DEF_EXCL" = "true" ]; then
        pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2
        echo "com.google.android.gms"
        echo "com.android.vending"
    else
        pm list packages 2>/dev/null | grep '^package:' | cut -d: -f2
    fi
}

# --- 7. Compare & Filter ---
: > "$RESULTS_FILE"

generate_candidates | sort -u | while read -r pkg; do
    if ! grep -F -x -q "$pkg" "$CLEAN_TARGET"; then
        if ! grep -F -x -q "$pkg" "$CLEAN_EXCLUDE"; then
            echo "$pkg" >> "$RESULTS_FILE"
        fi
    fi
done

# --- 8. Results ---
cnt=0
NEW_APPS=""

if [ -s "$RESULTS_FILE" ]; then
    NEW_APPS=$(cat "$RESULTS_FILE")
    cnt=$(wc -l < "$RESULTS_FILE")
fi

# --- 9. Action ---
if [ "$cnt" -gt 0 ]; then

    if [ "$cnt" -gt 50 ]; then
        log_print "⚠️ Safety: Detected $cnt new apps. Aborting to prevent duplication."
        exit 1
    fi

    log_print "Detected $cnt new app(s). Appending..."

    echo "$NEW_APPS" >> "$TARGET_FILE"

    clean_log=$(echo "$NEW_APPS" | tr '\n' ' ')
    log_print "Added: $clean_log"

    log_print "-> Restarting services..."
    killall com.google.android.gms.unstable >/dev/null 2>&1
    killall com.android.vending >/dev/null 2>&1
    log_print "   ✅ Services restarted"
fi
