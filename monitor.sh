#!/system/bin/sh
# monitor.sh - Smart Differential Updater (uses pm list)

TS_FOLDER="/data/adb/tricky_store"
HELPER_FOLDER="$TS_FOLDER/helper"
TARGET_FILE="$TS_FOLDER/target.txt"
EXCLUDE_FILE="$HELPER_FOLDER/exclude.txt"
CONFIG_FILE="$HELPER_FOLDER/config.txt"
LOG_FILE="$HELPER_FOLDER/TSHelper.log"

# UI Logger
log_print() { echo "$(date '+%T') Monitor: $1" >> "$LOG_FILE"; }

# --- 1. Settle Down ---
# Wait for the Package Manager to finish its install/uninstall transaction.
sleep 5

# Check requirements
[ -f "$TARGET_FILE" ] || exit 0

# --- 2. Setup Unique Temp Files ---
PID=$$
CLEAN_TARGET="/dev/ts_mon_target_${PID}.tmp"
CLEAN_EXCLUDE="/dev/ts_mon_exclude_${PID}.tmp"
RESULTS_FILE="/dev/ts_mon_results_${PID}.tmp"

# --- 3. The Trap (Auto-Cleanup) ---
# Ensures temp files are deleted when script finishes or exits
trap 'rm -f "$CLEAN_TARGET" "$CLEAN_EXCLUDE" "$RESULTS_FILE"; exit' EXIT HUP INT TERM

# --- 4. Load Configuration ---
USE_DEF_EXCL="true" 
if [ -f "$CONFIG_FILE" ]; then
    VAL=$(grep "^USE_DEFAULT_EXCLUSIONS=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    if [ "$VAL" = "false" ]; then USE_DEF_EXCL="false"; fi
fi

# --- 5. Prepare Memory Lists ---
# Clean Target: Strip \r, spaces, and suffixes (? or !)
tr -d '\r' < "$TARGET_FILE" | sed 's/[ \t]*[?!]*[ \t]*$//' > "$CLEAN_TARGET"

# Clean Exclude: Strip \r and spaces
if [ -f "$EXCLUDE_FILE" ]; then
    tr -d '\r' < "$EXCLUDE_FILE" | sed 's/^[ \t]*//;s/[ \t]*$//' > "$CLEAN_EXCLUDE"
else
    touch "$CLEAN_EXCLUDE"
fi

# --- 6. Generate Candidate Stream ---
generate_candidates() {
    if [ "$USE_DEF_EXCL" = "true" ]; then
        # User Apps Only (-3 flag)
        pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2
        # Always check GMS and Play Store
        echo "com.google.android.gms"
        echo "com.android.vending"
    else
        # All Apps (System + User)
        pm list packages 2>/dev/null | grep '^package:' | cut -d: -f2
    fi
}

# --- 7. Compare & Filter ---
: > "$RESULTS_FILE" # Create empty result file

# We stream the candidates into a loop to check against our clean lists
generate_candidates | sort -u | while read -r pkg; do
    # CHECK 1: Is it already in target.txt?
    if ! grep -F -x -q "$pkg" "$CLEAN_TARGET"; then
        # CHECK 2: Is it in exclude.txt?
        if ! grep -F -x -q "$pkg" "$CLEAN_EXCLUDE"; then
             echo "$pkg" >> "$RESULTS_FILE"
        fi
    fi
done

# Read Results
cnt=0
NEW_APPS=""
if [ -s "$RESULTS_FILE" ]; then
    NEW_APPS=$(cat "$RESULTS_FILE")
    cnt=$(wc -l < "$RESULTS_FILE")
fi

# --- 8. Action & Restart Logic ---
if [ "$cnt" -gt 0 ]; then
    
    # Safety: If >50 apps appear new, assume something is wrong.
    if [ "$cnt" -gt 50 ]; then
        log_print "⚠️ Safety: Detected $cnt new apps. Aborting to prevent duplication."
        exit 1
    fi

    log_print "Detected $cnt new app(s). Appending..."
    
    # Append
    echo "$NEW_APPS" >> "$TARGET_FILE"
    
    # Log (Flatten new apps to single line for clean log)
    clean_log=$(echo "$NEW_APPS" | tr '\n' ' ')
    log_print "Added: $clean_log"

    # Restart Services
    log_print "-> Restarting services..."
    killall com.google.android.gms.unstable >/dev/null 2>&1
    killall com.android.vending >/dev/null 2>&1
    log_print "   ✅ Services restarted"
fi
