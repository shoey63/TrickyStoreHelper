#!/system/bin/sh
# service.sh - TrickyStore Helper Daemon & Control Panel

MODDIR=${0%/*}
TS_FOLDER="/data/adb/tricky_store"
HELPER_DIR="$TS_FOLDER/helper"
LOCK_DIR="/dev/ts_helper_lock"
CONFIG_FILE="$HELPER_DIR/config.txt"
LOG_FILE="$HELPER_DIR/TSHelper.log"
PID_FILE="/dev/ts_helper_supervisor.pid"
MONITOR_SCRIPT="$MODDIR/monitor.sh"
PKG_FILE="/data/system/packages.list"

# ==============================================================================
#  FUNCTIONS
# ==============================================================================

get_pids() {
    # 1. Check RAM PID file (Manual Mode Reliability)
    if [ -f "$PID_FILE" ]; then
        READ_PID=$(cat "$PID_FILE")
        if [ -d "/proc/$READ_PID" ]; then
            PARENT_PID=$READ_PID
            # Find child watcher
            CHILD_PID=$(pgrep -P "$PARENT_PID" -f "inotifyd" | head -n 1)
            return
        else
            rm -f "$PID_FILE" # Stale file
        fi
    fi

    # 2. Fallback: Search process tree (Boot Mode Compatibility)
    CHILD_PID=$(pgrep -f "inotifyd.*monitor.sh" | head -n 1)
    PARENT_PID=""
    if [ -n "$CHILD_PID" ] && [ -f "/proc/$CHILD_PID/stat" ]; then
        PARENT_PID=$(cut -d ' ' -f 4 "/proc/$CHILD_PID/stat")
    fi
}

start_daemon_logic() {
    local SOURCE=$1
    echo "$(date '+%T') UI: 🛡️ Live Monitor Service starting ($SOURCE)..." >> "$LOG_FILE"
    
    # Kill old instances to be safe
    pkill -f "inotifyd.*monitor.sh" 2>/dev/null
    
    # Infinite Loop
    while true; do
        if command -v inotifyd >/dev/null 2>&1; then
            # The Blocking Watcher
            # FIX: Removed colons. y=Move, c=CloseWrite, d=Delete, n=Create
            inotifyd "$MONITOR_SCRIPT" "$PKG_FILE:ycdn"
            
            # If we reach here, inotifyd exited (file rotated or error).
            sleep 5
        else
            echo "$(date '+%T') UI: ⚠️ Error: 'inotifyd' not found. Retrying in 30s..." >> "$LOG_FILE"
            sleep 30
        fi
    done
}

stop_daemon() {
    get_pids
    [ -n "$PARENT_PID" ] && kill -9 "$PARENT_PID" 2>/dev/null
    [ -n "$CHILD_PID" ] && kill -9 "$CHILD_PID" 2>/dev/null
    rm -f "$PID_FILE"
}

# ==============================================================================
#  MODE 1: INTERACTIVE CONTROL PANEL (Termux / ADB)
# ==============================================================================
if [ -t 0 ]; then
    clear
    echo "========================================"
    echo "   TrickyStore Helper - Control Panel   "
    echo "========================================"

    get_pids

    if [ -n "$CHILD_PID" ] || [ -n "$PARENT_PID" ]; then
        echo " STATUS:  🟢 RUNNING"
        echo " Watcher: ${CHILD_PID:-Waiting...}"
        echo " Loop:    $PARENT_PID"
        echo "========================================"
        printf " Do you want to STOP the service? (y/n): "
        read -r CHOICE
        case "$CHOICE" in
            y|Y) 
                stop_daemon 
                echo " 🛑 Service stopped."
                echo "$(date '+%T') UI: 🛑 Service stopped manually." >> "$LOG_FILE"
                ;;
            *) echo " No changes made." ;;
        esac
    else
        echo " STATUS:  🔴 STOPPED"
        echo "========================================"
        printf " Do you want to START the service? (y/n): "
        read -r CHOICE
        case "$CHOICE" in
            y|Y)
               echo "$(date '+%T') UI: 🎮 Manual Start initiated." >> "$LOG_FILE"
            
            # Launch detached background process
            (
                trap '' HUP
                start_daemon_logic "Manual" >> "$LOG_FILE" 2>&1
            ) < /dev/null > /dev/null 2>&1 &
            
            # Save PID to RAM for the menu to find later
            echo $! > "$PID_FILE"
            
            echo " ✅ Service started in background."
            ;;
            *) echo " No changes made." ;;
        esac
    fi
    exit 0
fi

# ==============================================================================
#  MODE 2: BOOT AUTOMATION (Magisk / KernelSU/Apatch)
# ==============================================================================

# 1. Atomic Boot Lock
! mkdir "$LOCK_DIR" 2>/dev/null && exit 0

# 2. Permissions
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod 755 "$f"
    fi
done

# 3. Wait for Boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done

# 4. Check Config & Generate
RUN_ON_BOOT="true"
if [ -f "$CONFIG_FILE" ]; then
    VAL=$(grep "^RUN_ON_BOOT=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    [ "$VAL" = "false" ] || [ "$VAL" = "0" ] && RUN_ON_BOOT="false"
fi

if [ "$RUN_ON_BOOT" = "true" ]; then
    sh "$MODDIR/action.sh" boot
else
    echo "$(date '+%T') UI: ℹ️ Boot execution skipped (RUN_ON_BOOT=false)." >> "$LOG_FILE"
fi

# 5. Start Daemon
stop_daemon
( start_daemon_logic "Boot" ) &

exit 0
