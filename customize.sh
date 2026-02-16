#!/system/bin/sh
# customize.sh — Installer-time setup for TrickyStore Helper

# ------------------------------------------------------------------------------
# Setup Variables
# ------------------------------------------------------------------------------

MODID=trickystorehelper
TS_FOLDER="/data/adb/tricky_store"
TS_MODULES="/data/adb/modules/tricky_store"

# $MODPATH is the temporary extraction folder
HELPER_DIR="$MODPATH/helper"

CONFIG_FILE="$HELPER_DIR/config.txt"
EXCLUDE_FILE="$HELPER_DIR/exclude.txt"
FORCE_FILE="$HELPER_DIR/force.txt"

# Flag: Default to FRESH install unless we find old files to restore
FRESH_INSTALL=true

# ------------------------------------------------------------------------------
# 1. Dependency Check
# ------------------------------------------------------------------------------

if [ ! -d "$TS_FOLDER" ] || [ ! -d "$TS_MODULES" ]; then
    abort "- ❌ TrickyStore not detected. Please install TrickyStore first."
fi

# Ensure the directory exists immediately (Safe for empty zips)
mkdir -p "$HELPER_DIR"

ui_print "- Preparing TrickyStore Helper..."

# ------------------------------------------------------------------------------
# 2. RESTORE / MIGRATION (Priority 1: Legacy -> Priority 2: Existing)
# ------------------------------------------------------------------------------

OLD_HELPER="/data/adb/tricky_store/helper"
LIVE_HELPER="/data/adb/modules/$MODID/helper"

if [ -d "$OLD_HELPER" ] && [ "$(ls -A "$OLD_HELPER" 2>/dev/null)" ]; then
    ui_print "  - Migrating legacy helper folder..."
    cp -af "$OLD_HELPER"/. "$HELPER_DIR"/
    rm -rf "$OLD_HELPER"
elif [ -d "$LIVE_HELPER" ] && [ "$(ls -A "$LIVE_HELPER" 2>/dev/null)" ]; then
    ui_print "  - Restoring existing helper config..."
    cp -af "$LIVE_HELPER"/. "$HELPER_DIR"/
fi

# ------------------------------------------------------------------------------
# 3. SEEDING & REPAIR (Ensures files are valid)
# ------------------------------------------------------------------------------

# --- Exclude List (User Choice) ---
# Only create if physically MISSING. If it exists but is empty, leave it be.
if [ ! -f "$EXCLUDE_FILE" ]; then
    ui_print "    * Creating new exclude.txt..."
    {
        echo "# TrickyStore Helper — Exclusion List"
        echo "# User apps are excluded by default."
        echo ""
        pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2 | sort
    } > "$EXCLUDE_FILE"
fi

# --- Force List (Requirement) ---
# Create if missing OR empty.
if [ ! -s "$FORCE_FILE" ]; then
    ui_print "    * Seeding force.txt..."
    cat <<EOF > "$FORCE_FILE"
# TrickyStore Helper — Forced packages
com.google.android.gms
com.android.vending
EOF
fi

# --- Config File (Requirement) ---
# Create if missing OR empty.
if [ ! -s "$CONFIG_FILE" ]; then
    ui_print "    * Seeding config.txt..."
    cat <<EOF > "$CONFIG_FILE"
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
RUN_ON_BOOT=true
EOF
fi

# ------------------------------------------------------------------------------
# 4. Final Permissions
# ------------------------------------------------------------------------------

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/monitor.sh" 0 0 0755

ui_print "- ✅ Setup complete!"
