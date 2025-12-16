#!/system/bin/sh
#
# action.sh - TrickyStoreHelper (Final Stream Edition)
#
MODDIR=${0%/*}

# --- 1. Setup & Config ---
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"
LOG_FILE="$TS_HELPER/TSHelper.log"
TARGET_FILE="$TS_FOLDER/target.txt"

# Ensure Helper folder exists
mkdir -p "$TS_HELPER"
touch "$EXCLUDE_FILE" "$FORCE_FILE" "$LOG_FILE"

# UI Functions
ui_print() { echo "$1"; echo "$(date '+%T') UI: $1" >> "$LOG_FILE"; }

ui_print " "
ui_print "========================================================"
ui_print "               ⭐ TrickyStore Helper ⭐"
ui_print "========================================================"
ui_print " "
sleep 0.7

if [ ! -d "$TS_FOLDER" ]; then
    ui_print "!! FATAL: TrickyStore not installed."
    exit 1
fi

# Load Config
grep_conf() { grep "^$1=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2; }

# Defaults
VERBOSE=${CUSTOM_LOGLEVEL:-3}
FORCE_LEAF="false"; FORCE_CERT="false"; USE_DEF_EXCL="true"

[ -f "$CONFIG_FILE" ] && {
    FORCE_LEAF=$(grep_conf "FORCE_LEAF_HACK")
    FORCE_CERT=$(grep_conf "FORCE_CERT_GEN")
    USE_DEF_EXCL=$(grep_conf "USE_DEFAULT_EXCLUSIONS")
}

# Conflict Resolution
if [ "$FORCE_LEAF" = "true" ] && [ "$FORCE_CERT" = "true" ]; then
        echo ""
        echo "🚨🚨🚨  WARNING — INVALID CONFIGURATION DETECTED  🚨🚨🚨"
     sleep .5   
        echo ""
        echo "Both FORCE_LEAF_HACK and FORCE_CERT_GEN are TRUE in:"
        echo "    $CONFIG_FILE"
        echo ""
     sleep .5
        echo "This run will proceed with both flags set to"  
        echo "FALSE in memory only.To make a permanent change,"
        echo "edit the file above and set at least one flag to false."
        echo ""
        echo "-------------------------------------------------------------"
        echo ""
    FORCE_LEAF="false"; FORCE_CERT="false"
    sleep 1
fi

# Determine Suffix
SUFFIX=""
[ "$FORCE_LEAF" = "true" ] && SUFFIX="?"
[ "$FORCE_CERT" = "true" ] && SUFFIX="!"

# --- 2. The Stream Processor ---

ui_print "-> Generating and processing list..."
sleep 0.5

# 1. Define the input stream generator
generate_stream() {
    # A. List installed packages
    if [ "$USE_DEF_EXCL" = "true" ]; then
        pm list packages -3 | cut -d: -f2
        # Inject criticals
        echo "com.google.android.gms"
        echo "com.android.vending"
    else
        pm list packages | cut -d: -f2
    fi
    
    # B. Append force list (strip CR just in case)
    tr -d '\r' < "$FORCE_FILE"
}

# 2. Run the Pipeline
#    TARGET_FILE passed as var; AWK writes to it internally.
#    STDOUT is free for UI stats.

generate_stream | sort -u | awk \
    -v suffix="$SUFFIX" \
    -v excl_file="$EXCLUDE_FILE" \
    -v force_file="$FORCE_FILE" \
    -v target_file="$TARGET_FILE" \
    '
    function clean(s) { gsub(/\r/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

    BEGIN {
        cnt_excl_file=0; cnt_force_file=0; 
        cnt_tagged=0; cnt_removed=0;
        is_global="false";
    }

    # 1. Load Exclusions
    FILENAME == excl_file {
        val = clean($0);
        if (val != "") { excludes[val]=1; cnt_excl_file++; }
        next
    }

    # 2. Load Force List
    FILENAME == force_file {
        val = clean($0);
        if (val != "") { forced[val]=1; cnt_force_file++; }
        next
    }

    # 3. Check Global Mode
    FNR == 1 && FILENAME == "-" {
        if (cnt_force_file == 0 && suffix != "") is_global="true";
    }

    # 4. Process the Stream (Standard Input)
    FILENAME == "-" {
        pkg = clean($0);
        if (pkg == "") next;

        # Skip Exclusions
        if (pkg in excludes) {
            cnt_removed++;
            next;
        }

        # Apply Tags
        if (is_global == "true") {
            print pkg suffix > target_file
            cnt_tagged++
        } 
        else if (pkg in forced) {
            print pkg suffix > target_file
            cnt_tagged++
        } 
        else {
            print pkg > target_file
        }
    }

    # 5. Print Detailed UI Stats to STDOUT
    END {
        tag_disp = (suffix == "" ? "None" : suffix)
        
        print "   * Active Mode: " tag_disp
        print "   * Forced Apps: " cnt_tagged " (from " cnt_force_file " entries)"
        print "   * Excluded:    " cnt_removed " (from " cnt_excl_file " entries)"
        
        if (is_global == "true") {
            print "   * Global:      Applied to ALL"
        }
    }
' "$EXCLUDE_FILE" "$FORCE_FILE" - 

sleep 0.5

# --- 3. Finalize ---

ui_print "-----------------------------------------"
ui_print "-> Restarting services..."
sleep 0.5

killall com.google.android.gms.unstable 2>/dev/null
killall com.android.vending 2>/dev/null

sleep 1

ui_print "-----------------------------------------"
ui_print "-> Success! Package list generated.✅"
ui_print "-> Review $TARGET_FILE"
ui_print "*****************************************"

# Only pause if NOT running during boot (checked via argument $1)
if [ "$1" != "boot" ]; then
    # Detect KSU/APatch/Magisk to pause for user readability
    if [ -n "$KSU" ] || [ -n "$APATCH" ] || [ ! -f "/data/adb/magisk.db" ]; then
        ui_print " "
        ui_print "Closing in 10 seconds..."
        sleep 6
        ui_print "exiting..."
        sleep 2
        ui_print "✅"
        sleep 2
    fi
fi

exit 0
