#!/system/bin/sh
# customize.sh — Installer-time setup for TrickyStore Helper

# --- Variables ---
TS_FOLDER="/data/adb/tricky_store"
TS_MODULES="/data/adb/modules/tricky_store"
TS_HELPER="$TS_FOLDER/helper"

# --- 1. Dependency Check ---
# Abort if TrickyStore or its module directory is missing
if [ ! -d "$TS_FOLDER" ] || [ ! -d "$TS_MODULES" ]; then
    abort "- ❌ TrickyStore not detected. Please install TrickyStore first."
fi

ui_print "- Preparing TrickyStore Helper..."

# --- 2. Directory Setup ---
# Ensure helper directory exists
mkdir -p "$TS_HELPER"

# --- 3. Config Generation ---
# Create default config only if it doesn't exist
if [ ! -f "$TS_HELPER/config.txt" ]; then
    ui_print "  - Creating default config.txt"
    cat <<EOF > "$TS_HELPER/config.txt"
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
RUN_ON_BOOT=true
EOF
fi

# --- 4. File Initialization ---

EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"

# --- 4A. Seed exclude.txt with all user apps (opt-in model) ---
if [ ! -f "$EXCLUDE_FILE" ]; then
    ui_print "  - Generating exclude.txt (opt-in app list)"

    {
        echo "# TrickyStore Helper — Exclusion List"
        echo "# All user apps are excluded by default."
        echo "# Comment out apps you want included in target.txt"
        echo "#"
        pm list packages -3 2>/dev/null \
            | grep '^package:' \
            | cut -d: -f2 \
            | sort
    } > "$EXCLUDE_FILE"
fi

# --- 4B. Seed force.txt with core packages ---
if [ ! -f "$FORCE_FILE" ]; then
    ui_print "  - Seeding force.txt with core packages"

    cat <<EOF > "$FORCE_FILE"
# TrickyStore Helper — Forced packages
# Add ? or ! suffixes as desired

com.google.android.gms
com.android.vending
EOF
fi

ui_print "- ✅ Setup complete!"
