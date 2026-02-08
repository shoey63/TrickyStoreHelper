#!/system/bin/sh
# customize.sh — Installer-time setup for TrickyStore Helper

# --- Variables ---
TS_FOLDER="/data/adb/tricky_store"
TS_MODULES="/data/adb/modules/tricky_store"

# Module-local helper directory
HELPER_DIR="$MODPATH/helper"

# Live module path (for config preservation on upgrade)
MODID="${MODPATH##*/}"
LIVE_HELPER="/data/adb/modules/$MODID/helper"

# --- 1. Dependency Check ---
# Abort if TrickyStore or its module directory is missing
if [ ! -d "$TS_FOLDER" ] || [ ! -d "$TS_MODULES" ]; then
    abort "- ❌ TrickyStore not detected. Please install TrickyStore first."
fi

ui_print "- Preparing TrickyStore Helper..."

# --- 2. Restore existing helper config (upgrade-safe) ---
if [ -d "$LIVE_HELPER" ] && \
   [ "$(find "$LIVE_HELPER" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    ui_print "  - Preserving existing helper config"
    rm -rf "$HELPER_DIR"
    mkdir -p "$HELPER_DIR"
    cp -a "$LIVE_HELPER"/. "$HELPER_DIR"/
fi

# --- 3. Directory Setup ---
mkdir -p "$HELPER_DIR"

CONFIG_FILE="$HELPER_DIR/config.txt"
EXCLUDE_FILE="$HELPER_DIR/exclude.txt"
FORCE_FILE="$HELPER_DIR/force.txt"

# --- 4. Config Generation ---
# Create default config only if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    ui_print "  - Creating default config.txt"
    cat <<EOF > "$CONFIG_FILE"
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
RUN_ON_BOOT=true
EOF
fi

# --- 5A. Seed exclude.txt with all user apps (opt-in model) ---
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

# --- 5B. Seed force.txt with core packages ---
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
