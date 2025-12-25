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

# Detect Boot Mode immediately
IS_BOOT="false"
[ "$1" = "boot" ] && IS_BOOT="true"

# Smart Sleep Function: Skips delays if running on boot
sleep_ui() {
    [ "$IS_BOOT" = "true" ] && return
    sleep "$1"
}

# Ensure Tricky Store is installed
if [ ! -d "$TS_FOLDER" ]; then
    echo " " 
    echo " ❌FATAL❌: TrickyStore folder not found at:" 
    echo " "
    echo "  $TS_FOLDER" 
    echo " "
    echo " 🚨Please install TrickyStore first.🚨"
    echo " "
    echo " Closing in 5 seconds..."
    sleep 7
    exit 1
fi

# Ensure Helper folder exists
mkdir -p "$TS_HELPER"
touch "$EXCLUDE_FILE" "$FORCE_FILE" "$LOG_FILE"

# UI Functions
ui_print() { echo "$1"; echo "$(date '+%T') UI: $1" >> "$LOG_FILE"; }

# 1.1 Log Boot Mode if active
if [ "$IS_BOOT" = "true" ]; then
    echo "$(date '+%T') UI: 🚀 Boot mode detected. Sleep commands disabled." >> "$LOG_FILE"
fi

echo " "
echo "================================================"
ui_print "           ⭐ TrickyStore Helper ⭐"
echo "================================================"
echo " "
sleep_ui 0.5

# Load Config (Improved to strip all whitespace)
grep_conf() { 
    grep "^$1=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]'
}

# Defaults
FORCE_LEAF="false"; FORCE_CERT="false"; USE_DEF_EXCL="true"

[ -f "$CONFIG_FILE" ] && {
    FORCE_LEAF=$(grep_conf "FORCE_LEAF_HACK")
    FORCE_CERT=$(grep_conf "FORCE_CERT_GEN")
    USE_DEF_EXCL=$(grep_conf "USE_DEFAULT_EXCLUSIONS")
}

# Conflict Resolution
if [ "$FORCE_LEAF" = "true" ] && [ "$FORCE_CERT" = "true" ]; then
    echo " "
    ui_print "🚨  WARNING - INVALID CONFIGURATION DETECTED  🚨"
    echo " "
    sleep_ui 0.7
    ui_print "Both FORCE_LEAF_HACK and FORCE_CERT_GEN are TRUE"
    ui_print "  in: $CONFIG_FILE"
    echo " "
    sleep_ui 0.7
    ui_print "This run will proceed with both flags set to"  
    ui_print "FALSE in memory only."
    echo " " 
    sleep_ui 0.7
    ui_print "You must set at least one flag to FALSE"
    echo " "
    echo "------------------------------------------------"
    FORCE_LEAF="false"; FORCE_CERT="false"
    sleep_ui 1
fi

# Determine Suffix
SUFFIX=""
[ "$FORCE_LEAF" = "true" ] && SUFFIX="?"
[ "$FORCE_CERT" = "true" ] && SUFFIX="!"

# --- 2. The Stream Processor ---

ui_print "-> Generating and processing list..."
sleep_ui 0.7

# 1. Define the input stream generator (Now with Pollution Filter)
generate_stream() {
    # A. List installed packages
    # We explicitly filter for lines starting with 'package:' to ignore APatch errors
    if [ "$USE_DEF_EXCL" = "true" ]; then
        pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2
        # Inject criticals
        echo "com.google.android.gms"
        echo "com.android.vending"
    else
        pm list packages 2>/dev/null | grep '^package:' | cut -d: -f2
    fi
    
    # B. Append force list (strip CR just in case)
    tr -d '\r' < "$FORCE_FILE"
}

# 2. Run the Pipeline
generate_stream | sort -u | awk \
    -v suffix="$SUFFIX" \
    -v excl_file="$EXCLUDE_FILE" \
    -v force_file="$FORCE_FILE" \
    -v target_file="$TARGET_FILE" \
    '
    function clean(s) { gsub(/\r/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

    BEGIN {
        cnt_excl_file=0; cnt_force_file=0; 
        cnt_tagged=0; cnt_removed=0; cnt_total=0;
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

    # 4. Process the Stream
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
        cnt_total++;
    }

    # 5. Print Detailed UI Stats
    END {
        if (suffix == "?") {
            print "   * Active Mode: LEAF_HACK (? applied to " cnt_tagged " apps)"
        } else if (suffix == "!") {
            print "   * Active Mode: CERT_GEN (! applied to " cnt_tagged " apps)"
        } else {
            print "   * Active Mode: None"
        }

        print "   * Forced Apps: " cnt_force_file
        print "   * Excluded:    " cnt_removed
        print "   * Total Packages: " cnt_total
    }
' "$EXCLUDE_FILE" "$FORCE_FILE" - | while read -r line; do ui_print "$line"; done

sleep_ui 0.7

# --- 3. Finalize ---
echo "------------------------------------------------"
ui_print "-> Restarting services..."
sleep_ui 0.7

# Restart GMS Unstable (DroidGuard)
if killall com.google.android.gms.unstable >/dev/null 2>&1; then
    ui_print "   ✅  DroidGuard (GMS) restarted"
else
    ui_print "   ℹ️  DroidGuard (GMS) was not running"
fi

# Restart Play Store
if killall com.android.vending >/dev/null 2>&1; then
    ui_print "   ✅  Play Store restarted"
else
    ui_print "   ℹ️  Play Store was not running"
fi

sleep_ui 1
echo "------------------------------------------------"
ui_print "-> Success! Package list generated."
ui_print "-> Review $TARGET_FILE"
echo "************************************************"

# --- Smart Exit Logic ---

# Magisk Check: Exit immediately if Magisk SU is running.
case "$(su -v 2>/dev/null)" in
    *MAGISK*|*magisk*)
        exit 0
        ;;
esac

# Fallback: Pause for KernelSU, APatch, and others.
echo " "
echo "Closing in 10 seconds..."
sleep_ui 6
echo " "
echo "exiting..."
sleep_ui 2
echo " "
echo "✅"
sleep_ui 2

exit 0
