#!/system/bin/sh
#
# service.sh - Boot logic for TrickyStoreHelper
#
MODDIR=${0%/*}

# 1. Wait for Boot Completion
# (Ensures the system is stable before we run our logic)
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# 2. Conditional Permission Fix
# (Makes scripts executable for terminal use, only if they aren't already)
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod 755 "$f"
    fi
done

# 3. Run action.sh in "boot" mode
# (Passes 'boot' arg so the UI sleep delay is skipped)
sh "$MODDIR/action.sh" boot
