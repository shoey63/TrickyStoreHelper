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

# Log Boot Mode if active
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
    sleep_ui 3
fi

# Determine Suffix
SUFFIX=""
[ "$FORCE_LEAF" = "true" ] && SUFFIX="?"
[ "$FORCE_CERT" = "true" ] && SUFFIX="!"

# --- 2. The Stream Processor ---

ui_print "-> Generating and processing list..."
sleep_ui 0.7

# A. Define the input stream generator
generate_stream() {
    # Installed packages only
    if [ "$USE_DEF_EXCL" = "true" ]; then
        pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2
    else
        pm list packages 2>/dev/null | grep '^package:' | cut -d: -f2
    fi
}

# B. Run the Pipeline
: > "$TARGET_FILE"

generate_stream | awk \
-v suffix="$SUFFIX" \
-v excl_file="$EXCLUDE_FILE" \
-v force_file="$FORCE_FILE" \
-v target_file="$TARGET_FILE" \
-v log_file="/data/adb/tricky_store/helper/TSHelper.log" \
'
function clean(s,   suffix, base, rest) {
    gsub(/\r/, "", s)

    # match package name only
    if (!match(s, /^[ \t]*[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+/))
        return ""

    base = substr(s, RSTART, RLENGTH)
    rest = substr(s, RLENGTH + 1)

    suffix = ""

    # optional space + suffix
    if (match(rest, /^[ \t]*[?!]/))
        suffix = substr(rest, RSTART + RLENGTH - 1, 1)

    sub(/[. \t]+$/, "", base)

    return base suffix
}

function valid_pkg(s) {
    return (s ~ /^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$/)
}


BEGIN {
    cnt_excl=0
    cnt_total=0
    cnt_tagged=0
    dup_forced=0
    global_mode = (suffix != "")

    # --- Load exclusions ---
    while ((getline line < excl_file) > 0) {
        if (line ~ /^[ \t]*#/) continue
        val = clean(line)
        if (val != "") excludes[val]=1
    }
    close(excl_file)

    # --- Phase 1: FORCE.TXT (absolute priority) ---
    while ((getline line < force_file) > 0) {
        raw = clean(line)
        if (raw == "") continue

        pkg = raw
        if (raw ~ /[?!]$/)
            pkg = substr(raw, 1, length(raw)-1)

        if (!valid_pkg(pkg)) continue

        # duplicate detection
        if (pkg in seen) {
            dup_forced++
            dup_list[pkg]++
            continue
        }

        print raw >> target_file

        seen[pkg]=1
        forced[pkg]=1

        if (raw ~ /[?!]$/) cnt_tagged++
        cnt_total++
    }
    close(force_file)

    print "🛠️ End of Forced List 🛠️" >> target_file
    print "" >> target_file
    print "🔎 Discovered Apps 🔎" >> target_file
}

# --- Phase 2: discovered packages ---
{
    raw = clean($0)
    if (raw == "") next

    pkg = raw
    if (raw ~ /[?!]$/)
        pkg = substr(raw, 1, length(raw)-1)

    if (!valid_pkg(pkg)) next
    if (pkg in seen) next

    if (pkg in excludes) {
        cnt_excl++
        next
    }

    if (global_mode) {
        print pkg suffix >> target_file
        cnt_tagged++
    } else {
        print pkg >> target_file
    }

    seen[pkg]=1
    cnt_total++
}

END {
    if (dup_forced > 0) {
        msg = "⚠️ Duplicate forced entries detected: " dup_forced
        print msg

        for (p in dup_list) {
            warn = "   - " p
            print warn
        }
    }

    if (suffix == "?")
        print "   * Active Mode: GLOBAL LEAF_HACK"
    else if (suffix == "!")
        print "   * Active Mode: GLOBAL CERT_GEN"
    else
        print "   * Active Mode: MANUAL"

    print "   * Excluded: " cnt_excl
    print "   * Tagged:   " cnt_tagged
    print "   * Total:    " cnt_total
}
' | while read -r line; do
    ui_print "$line"
done
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
ui_print "-> Success! Package list generated ✅"
ui_print "-> Review $TARGET_FILE"
echo "************************************************"
ui_print "Finished!"
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
