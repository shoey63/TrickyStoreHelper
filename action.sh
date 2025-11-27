#!/system/bin/sh
# action.sh - Run helper.sh from the module action button (Magisk / KernelSU / Apatch)
#
# Place this file at the module root. When the module "Action" button is pressed
# this script will run helper.sh so TrickyStore target.txt is regenerated.

MODDIR=${0%/*}
SCRIPTNAME="action.sh"
HELPER_PATH="$MODDIR/helper.sh"

echo "[$SCRIPTNAME] Starting TrickyStore helper..."

if [ ! -f "$HELPER_PATH" ]; then
    echo "[$SCRIPTNAME] ERROR: helper.sh not found at $HELPER_PATH"
    exit 1
fi

# Ensure helper is executable (so $0 inside helper.sh is the helper path)
if [ ! -x "$HELPER_PATH" ]; then
    chmod 0755 "$HELPER_PATH" 2>/dev/null || true
fi

# Execute helper.sh directly so its internal MODDIR calculation works
# Use exec so the helper's exit code becomes ours. If exec fails, fall back to sh.
exec "$HELPER_PATH" || {
    echo "[$SCRIPTNAME] exec failed, falling back to sh..."
    sh "$HELPER_PATH"
    exit $?
}