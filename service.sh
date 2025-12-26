#!/system/bin/sh
#
# service.sh - Boot logic for TrickyStoreHelper
#
MODDIR=${0%/*}
LOCK_DIR="/dev/ts_helper_lock"
CONFIG_FILE="/data/adb/tricky_store/helper/config.txt"
LOG_FILE="/data/adb/tricky_store/helper/TSHelper.log"

# --- 1. Atomic Lock ---
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

# --- 2. Permissions ---
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod 755 "$f"
    fi
done

# --- 3. Wait for Boot ---
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# --- 4. Run Action (Config Check) ---
RUN_ON_BOOT="true"
if [ -f "$CONFIG_FILE" ]; then
    VAL=$(grep "^RUN_ON_BOOT=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    if [ "$VAL" = "false" ] || [ "$VAL" = "0" ]; then
        RUN_ON_BOOT="false"
    fi
fi

if [ "$RUN_ON_BOOT" = "true" ]; then
    sh "$MODDIR/action.sh" boot
else
    echo "$(date '+%T') UI: ℹ️ Boot execution skipped (RUN_ON_BOOT=false)." >> "$LOG_FILE"
fi

# --- 5. Start Live Monitor (Keep-Alive Loop) ---
# Kill old instances
pkill -f "inotifyd.*monitor.sh" 2>/dev/null

# We spawn a background subshell that lives forever
(
    # Log startup
    echo "$(date '+%T') UI: 🛡️ Live Monitor Service starting..." >> "$LOG_FILE"
    
    # Infinite Loop
    while true; do
        
        # Verify binary exists
        if command -v inotifyd >/dev/null 2>&1; then
            
            # Run inotifyd (Blocking)
            # It will sit here until packages.list is modified/rotated.
            # When rotation happens, it exits.
            inotifyd "$MODDIR/monitor.sh" /data/system/packages.list:y:c:d:n
            
            # Note: 
            # :y = IN_MOVE_SELF (File moved/rotated)
            # :c = IN_CLOSE_WRITE (File saved)
            # :d = IN_DELETE_SELF (File deleted)
            # :n = IN_CREATE (New file created)
            
            # If we reach here, inotifyd exited (file rotated or error).
            # We wait 5 seconds for the new file to settle, then loop restarts.
            sleep 5
            
        else
            echo "$(date '+%T') UI: ⚠️ Error: 'inotifyd' not found. Retrying in 30s..." >> "$LOG_FILE"
            sleep 30
        fi
        
    done

) &

# Detach cleanly
exit 0
