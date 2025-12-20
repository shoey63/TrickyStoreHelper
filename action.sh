#!/system/bin/sh
#
# action.sh - TrickyStoreHelper (Final Clean)
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

# Ensure Helper folder exists
mkdir -p "$TS_HELPER"
touch "$EXCLUDE_FILE" "$FORCE_FILE" "$LOG_FILE"

# UI Functions
ui_print() { echo "$1"; echo "$(date '+%T') UI: $1" >> "$LOG_FILE"; }

ui_print " "
ui_print "*****************************************"
ui_print "* TrickyStore Helper - Stream Mode    *"
ui_print "*****************************************"
ui_print " "
sleep_ui 0.5

if [ ! -d "$TS_FOLDER" ]; then
    ui_print "!! FATAL: TrickyStore not installed."
    exit 1
fi

# Load Config
grep_conf() { grep "^$1=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2; }

# Defaults
FORCE_LEAF="false"; FORCE_CERT="false"; USE_DEF_EXCL="true"

[ -f "$CONFIG_FILE" ] && {
    FORCE_LEAF=$(grep_conf "FORCE_LEAF_HACK")
    FORCE_CERT=$(grep_conf "FORCE_CERT_GEN")
    USE_DEF_EXCL=$(grep_conf "USE_DEFAULT_EXCLUSIONS")
}

# Conflict Resolution
if [ "$FORCE_LEAF" = "true" ] && [ "$FORCE_CERT" = "true" ]; then
    ui_print "!! WARN: Config conflict. Hacks disabled."
    FORCE_LEAF="false"; FORCE_CERT="false"
    sleep_ui 1
fi

# Determine Suffix
SUFFIX=""
[ "$FORCE_LEAF" = "true" ] && SUFFIX="?"
[ "$FORCE_CERT" = "true" ] && SUFFIX="!"

# --- 2. The Stream Processor ---

ui_print "-> Generating and processing list..."
sleep_ui 0.5

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
' "$EXCLUDE_FILE" "$FORCE_FILE" - 

sleep_ui 0.5

# --- 3. Finalize ---

ui_print "-----------------------------------------"
ui_print "-> Restarting services..."
sleep_ui 0.5

killall com.google.android.gms.unstable 2>/dev/null
killall com.android.vending 2>/dev/null

sleep_ui 1

ui_print "-----------------------------------------"
ui_print "-> Success! Package list generated."
ui_print "-> Review $TARGET_FILE"
ui_print "*****************************************"

# --- Smart Exit Logic ---

# Magisk Check: Exit immediately if Magisk SU is running.
case "$(su -v 2>/dev/null)" in
    *MAGISK*|*magisk*)
        exit 0
        ;;
esac

# Fallback: Pause for KernelSU, APatch, and others.
ui_print " "
ui_print "Closing in 10 seconds..."
        sleep_ui 6
        ui_print "exiting..."
        sleep_ui 2
        ui_print "✅"
        sleep_ui 2
        
exit 0
