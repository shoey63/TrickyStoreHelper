#!/system/bin/sh
# Installation-time setup for TrickyStore Helper

TS_FOLDER="/data/adb/tricky_store"
TS_MODULE_FOLDER="/data/adb/modules/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"
SYSTEM_FILE="$TS_HELPER/system.txt"

# Abort if TrickyStore not installed
{ [ -d "$TS_FOLDER" ] && [ -d "$TS_MODULE_FOLDER" ]; } || abort "- Please install TrickyStore before installing this module."

# Clean up any leftover logs
rm -f "$TS_FOLDER/helper-log.txt"

# Prepare helper directory
mkdir -p "$TS_HELPER"

# Create config if missing
if [ ! -f "$CONFIG_FILE" ]; then
    {
        echo "FORCE_LEAF_HACK=false"
        echo "FORCE_CERT_GEN=false"
        echo "# CUSTOM_LOGLEVEL can be added manually if needed"
    } >"$CONFIG_FILE"
fi

# Create exclude/force/system lists if missing
[ -f "$EXCLUDE_FILE" ] || touch "$EXCLUDE_FILE"
[ -f "$FORCE_FILE" ] || touch "$FORCE_FILE"

# Create default system.txt with GMS + Play Store
if [ ! -f "$SYSTEM_FILE" ]; then
    {
        echo "com.google.android.gms"
        echo "com.android.vending"
    } >"$SYSTEM_FILE"
fi
