#!/system/bin/sh
# TrickyStore Helper Script (Fork by Shoey63, originally by Captain_Throwback)
# Builds /data/adb/tricky_store/target.txt at boot or on manual run.

MODDIR=${0%/*}
SCRIPTNAME="TSHelper"

# Paths
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"
SYSTEM_FILE="$TS_HELPER/system.txt"
LOG_FILE="$TS_HELPER/$SCRIPTNAME.log"
TARGET_FILE="$TS_FOLDER/target.txt"

# Verify base folder
if [ ! -d "$TS_FOLDER" ]; then
    log -p "F" -t "$SCRIPTNAME" "TrickyStore folder missing."
    echo "FATAL: TrickyStore folder not found."
    exit 1
fi

# Logging helper
log_print() {
    local level="$1" msg="$2"
    local tag=""
    case "$level" in
        1) tag="F";;
        2) tag="E";;
        3) tag="W";;
        4) tag="I";;
        5) tag="D";;
        6) tag="V";;
        *) tag="I";;
    esac
    log -p "$tag" -t "$SCRIPTNAME" "$msg"
    echo "$(date '+%m-%d %T.%3N') $tag $SCRIPTNAME: $msg" >>"$LOG_FILE"
}

# Reset log each run
rm -f "$LOG_FILE"

# Load config flags
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
FORCE_LEAF_HACK=${FORCE_LEAF_HACK:-false}
FORCE_CERT_GEN=${FORCE_CERT_GEN:-false}
CUSTOM_LOGLEVEL=${CUSTOM_LOGLEVEL:-4}

__VERBOSE="$CUSTOM_LOGLEVEL"

log_print 4 "Starting $SCRIPTNAME..."
log_print 5 "FORCE_LEAF_HACK=$FORCE_LEAF_HACK, FORCE_CERT_GEN=$FORCE_CERT_GEN"

# Safety check
if $FORCE_LEAF_HACK && $FORCE_CERT_GEN; then
    log_print 1 "Leaf hack and cert gen both true — exiting."
    exit 2
fi

# Build base list: user apps only
pm list packages -3 | cut -d ":" -f 2 | sort >"$TARGET_FILE"
log_print 5 "Added user apps to target.txt"

# Add system packages from system.txt
if [ -f "$SYSTEM_FILE" ]; then
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && echo "$pkg" >>"$TARGET_FILE"
    done <"$SYSTEM_FILE"
    log_print 4 "Added system.txt entries to target.txt"
fi

# Remove duplicates
sort -u -o "$TARGET_FILE" "$TARGET_FILE"

# Apply exclusions
if [ -f "$EXCLUDE_FILE" ]; then
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && sed -i "/^$pkg$/d" "$TARGET_FILE"
    done <"$EXCLUDE_FILE"
    log_print 4 "Applied exclude.txt rules"
fi

# Apply force markers
if [ -f "$FORCE_FILE" ]; then
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        if $FORCE_LEAF_HACK; then
            sed -i "s/^$pkg\$/$pkg?/" "$TARGET_FILE"
        elif $FORCE_CERT_GEN; then
            sed -i "s/^$pkg\$/$pkg!/" "$TARGET_FILE"
        fi
    done <"$FORCE_FILE"
    log_print 4 "Applied force.txt markers"
fi

# Restart Play Store and GMS (optional, so TrickyStore picks up immediately)
killall -v com.google.android.gms.unstable 2>/dev/null
killall -v com.android.vending 2>/dev/null
log_print 4 "Killed GMS & Play Store processes to reload TrickyStore."

log_print 4 "$SCRIPTNAME complete."
exit 0
