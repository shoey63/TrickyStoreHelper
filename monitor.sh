#!/system/bin/sh
# monitor.sh

MODDIR=${0%/*}
HELPER_FOLDER="$MODDIR/helper"

TS_FOLDER="/data/adb/tricky_store"
TARGET_FILE="$TS_FOLDER/target.txt"

EXCLUDE_FILE="$HELPER_FOLDER/exclude.txt"
FORCE_FILE="$HELPER_FOLDER/force.txt"
CONFIG_FILE="$HELPER_FOLDER/config.txt"
LOG_FILE="$HELPER_FOLDER/TSHelper.log"

log_print() { echo "$(date '+%T') Monitor: $1" >> "$LOG_FILE"; }

sleep 5
# Wait until package database stops changing
SNAP1=$(pm list packages | wc -l)
sleep 2
SNAP2=$(pm list packages | wc -l)

if [ "$SNAP1" != "$SNAP2" ]; then
    sleep 3
fi

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
    tr -d '\r' < "$EXCLUDE_FILE" \
| sed 's/[ \t]*#.*$//' \
| sed 's/^[ \t]*//;s/[ \t]*$//' \
| grep -v '^$' \
> "$CLEAN_EXCLUDE"
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
            
            # --- FIX: Check force.txt for suffixes (! or ?) ---
            FORCED_ENTRY=""
            if [ -f "$FORCE_FILE" ]; then
                # Find line starting with package name (e.g., com.app!)
                FORCED_ENTRY=$(grep "^$pkg" "$FORCE_FILE" 2>/dev/null | head -n 1)
            fi

            if [ -n "$FORCED_ENTRY" ]; then
                echo "$FORCED_ENTRY" >> "$RESULTS_FILE"
            else
                echo "$pkg" >> "$RESULTS_FILE"
            fi
            # --------------------------------------------------

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

   HEADER="🔎 Newly installed apps (Review) 🔎"

# --- Add header only if missing ---
if ! grep -F -q "$HEADER" "$TARGET_FILE"; then
    # Ensure exactly one blank separator before header
    last_line=$(tail -n 1 "$TARGET_FILE" 2>/dev/null)

    if [ -n "$last_line" ]; then
        echo "" >> "$TARGET_FILE"
    fi

    echo "$HEADER" >> "$TARGET_FILE"
fi

# --- Append new apps directly (no extra blank lines) ---
    cat "$RESULTS_FILE" >> "$TARGET_FILE"

    clean_log=$(echo "$NEW_APPS" | tr '\n' ' ')
    log_print "Added: $clean_log"

    log_print "-> Restarting services..."
    killall com.google.android.gms.unstable >/dev/null 2>&1
    killall com.android.vending >/dev/null 2>&1
    log_print "   ✅ Services restarted"
fi
