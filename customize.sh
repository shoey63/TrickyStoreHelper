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
EOF
fi

# --- 4. File Initialization ---
# Create empty exclude.txt if missing
[ ! -f "$TS_HELPER/exclude.txt" ] && touch "$TS_HELPER/exclude.txt"

# Create empty force.txt if missing
[ ! -f "$TS_HELPER/force.txt" ] && touch "$TS_HELPER/force.txt"

ui_print "- ✅ Setup complete!"
