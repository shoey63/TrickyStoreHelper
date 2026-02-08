#!/system/bin/sh
# customize.sh — Installer-time setup for TrickyStore Helper

# ------------------------------------------------------------------------------
# Setup Variables
# CRITICAL: Do NOT define MODPATH manually. Trust the Manager.
# ------------------------------------------------------------------------------

MODID=trickystorehelper
LIVE_PATH="/data/adb/modules/$MODID"

TS_FOLDER="/data/adb/tricky_store"
TS_MODULES="/data/adb/modules/tricky_store"

HELPER_DIR="$MODPATH/helper"

# ------------------------------------------------------------------------------
# 1. Dependency Check
# ------------------------------------------------------------------------------

if [ ! -d "$TS_FOLDER" ] || [ ! -d "$TS_MODULES" ]; then
    abort "- ❌ TrickyStore not detected. Please install TrickyStore first."
fi

ui_print "- Preparing TrickyStore Helper..."

# ------------------------------------------------------------------------------
# 2. CONFIG RESTORATION (EXACT preserved logic)
# ------------------------------------------------------------------------------

if [ -d "$LIVE_PATH/helper" ] && [ "$(ls -A "$LIVE_PATH/helper")" ]; then
    ui_print "  - Preserving existing helper folder"

    # A. Delete packaged defaults
    rm -rf "$MODPATH/helper"

    # B. Copy user's helper folder
    cp -af "$LIVE_PATH/helper" "$MODPATH/"
fi

# ------------------------------------------------------------------------------
# 3. Directory Setup
# ------------------------------------------------------------------------------

mkdir -p "$HELPER_DIR"

CONFIG_FILE="$HELPER_DIR/config.txt"
EXCLUDE_FILE="$HELPER_DIR/exclude.txt"
FORCE_FILE="$HELPER_DIR/force.txt"

# ------------------------------------------------------------------------------
# 4. Config Generation (only if missing)
# ------------------------------------------------------------------------------

if [ ! -f "$CONFIG_FILE" ]; then
    ui_print "  - Creating default config.txt"
    cat <<EOF > "$CONFIG_FILE"
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
RUN_ON_BOOT=true
EOF
fi

# ------------------------------------------------------------------------------
# 5A. Seed exclude.txt (opt-in model)
# ------------------------------------------------------------------------------

if [ ! -f "$EXCLUDE_FILE" ]; then
    ui_print "  - Generating exclude.txt (opt-in app list)"

    {
        echo "# TrickyStore Helper — Exclusion List"
        echo "# All user apps are excluded by default."
        echo "# Newly installed apps are automatically added."
        echo "# Comment out apps you want included in target.txt"
        echo ""
        pm list packages -3 2>/dev/null \
            | grep '^package:' \
            | cut -d: -f2 \
            | sort
    } > "$EXCLUDE_FILE"
fi

# ------------------------------------------------------------------------------
# 5B. Seed force.txt
# ------------------------------------------------------------------------------

if [ ! -f "$FORCE_FILE" ]; then
    ui_print "  - Seeding force.txt with core packages"

    cat <<EOF > "$FORCE_FILE"
# TrickyStore Helper — Forced packages
# Add ? or ! suffixes as desired
# Comment out to remove from target.txt

com.google.android.gms
com.android.vending
EOF
fi

ui_print "- ✅ Setup complete!"
