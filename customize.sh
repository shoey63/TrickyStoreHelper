#!/system/bin/sh
# customize.sh — Installer-time setup for TrickyStore Helper

TS_FOLDER="/data/adb/tricky_store"
TS_MODULE_FOLDER="/data/adb/modules/tricky_store"

# Abort if TrickyStore core is missing
if [ ! -d "$TS_FOLDER" ] || [ ! -d "$TS_MODULE_FOLDER" ]; then
    abort "- TrickyStore not detected.
Please install TrickyStore **before** installing this helper."
fi

# Paths inside helper folder
TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"
OLD_FORCE_FILE="$TS_FOLDER/force.txt"

ui_print "• Preparing TrickyStore Helper..."

# --------------------------------------------------------------------
# Clean up old remnants
# --------------------------------------------------------------------
if [ -f "$TS_FOLDER/helper-log.txt" ]; then
    ui_print "  - Removing legacy helper-log.txt"
    rm -f "$TS_FOLDER/helper-log.txt"
fi

# --------------------------------------------------------------------
# Create helper folder if missing
# --------------------------------------------------------------------
if [ ! -d "$TS_HELPER" ]; then
    ui_print "  - Creating helper folder..."
    mkdir -p "$TS_HELPER"
fi

# --------------------------------------------------------------------
# Create default config if missing
# --------------------------------------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
    ui_print "  - Creating default config.txt"
    {
        echo "FORCE_LEAF_HACK=false"
        echo "FORCE_CERT_GEN=false"
        echo "USE_DEFAULT_EXCLUSIONS=true"
    } > "$CONFIG_FILE"
fi

# --------------------------------------------------------------------
# Create exclude.txt if missing
# --------------------------------------------------------------------
if [ ! -f "$EXCLUDE_FILE" ]; then
    ui_print "  - Creating empty exclude.txt"
    : > "$EXCLUDE_FILE"
fi

# --------------------------------------------------------------------
# Migrate old force.txt from module root → helper folder
# --------------------------------------------------------------------
if [ -f "$OLD_FORCE_FILE" ]; then
    ui_print "  - Migrating old force.txt to helper folder"
    mv -f "$OLD_FORCE_FILE" "$FORCE_FILE"
fi

# Ensure force.txt exists
if [ ! -f "$FORCE_FILE" ]; then
    ui_print "  - Creating empty force.txt"
    : > "$FORCE_FILE"
fi

ui_print "✓ TrickyStore Helper prepared successfully"
