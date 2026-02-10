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
# 2. RESTORE / MIGRATION
# ------------------------------------------------------------------------------

OLD_HELPER="/data/adb/tricky_store/helper"
LIVE_HELPER="/data/adb/modules/$MODID/helper"

# Check 1: Migrate legacy folder (files outside module)
if [ -d "$OLD_HELPER" ] && [ "$(ls -A "$OLD_HELPER" 2>/dev/null)" ]; then
    ui_print "  - Migrating legacy helper folder"
    cp -af "$OLD_HELPER"/. "$HELPER_DIR"/
    rm -rf "$OLD_HELPER"
    FRESH_INSTALL=false

# Check 2: Upgrade existing module (files inside module)
elif [ -d "$LIVE_HELPER" ] && [ "$(ls -A "$LIVE_HELPER" 2>/dev/null)" ]; then
    ui_print "  - Restoring existing helper config"
    cp -af "$LIVE_HELPER"/. "$HELPER_DIR"/
    FRESH_INSTALL=false
fi

# ------------------------------------------------------------------------------
# 3. SEEDING (Only runs on Fresh Install)
# ------------------------------------------------------------------------------

if [ "$FRESH_INSTALL" = "true" ]; then
    ui_print "  - Fresh install detected: Seeding defaults"

    # --- Seed exclude.txt ---
    # We overwrite whatever is in the zip (even if empty)
    ui_print "    * Generating exclusion list..."
    {
        echo "# TrickyStore Helper — Exclusion List"
        echo "# All user apps are excluded by default."
        echo "# Newly installed apps are automatically added."
        echo "# Comment out apps you want included in target.txt"
        echo ""
        # Capture all 3rd party (User) apps
        pm list packages -3 2>/dev/null \
            | grep '^package:' \
            | cut -d: -f2 \
            | sort
    } > "$EXCLUDE_FILE"

    # --- Seed force.txt ---
    ui_print "    * Seeding force list..."
    cat <<EOF > "$FORCE_FILE"
# TrickyStore Helper — Forced packages
# Add ? or ! suffixes as desired
# Comment out to remove from target.txt

com.google.android.gms
com.android.vending
EOF

    # --- Ensure Config Exists ---
    # We overwrite/create this to ensure variables match current version
    [ ! -f "$CONFIG_FILE" ] && cat <<EOF > "$CONFIG_FILE"
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
RUN_ON_BOOT=true
EOF

else
    ui_print "  - Skipping generation (Config preserved)"
fi

# ------------------------------------------------------------------------------
# 4. Final Permissions
# ------------------------------------------------------------------------------

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/monitor.sh" 0 0 0755

ui_print "- ✅ Setup complete!"
