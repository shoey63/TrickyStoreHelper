#!/system/bin/sh
#
# service.sh - Boot logic for TrickyStoreHelper
#
MODDIR=${0%/*}
LOCK_DIR="/dev/ts_helper_lock"

# --- 1. Atomic Double-Execution Prevention ---
# We use 'mkdir' because it is atomic. 
# If two processes run this line at the exact same time, only ONE will succeed.
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

# --- 2. Wait for Boot Completion ---
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# --- 3. Permission Fix ---
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod 755 "$f"
    fi
done

# --- 4. Run action.sh ---
sh "$MODDIR/action.sh" boot
