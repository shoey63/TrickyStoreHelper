#!/system/bin/sh
# service.sh - TrickyStore Helper (Boot Logic + Control Panel)

MODDIR=${0%/*}
LOCK_DIR="/dev/ts_helper_lock"
CONFIG_FILE="/data/adb/tricky_store/helper/config.txt"
LOG_FILE="/data/adb/tricky_store/helper/TSHelper.log"
MONITOR_SCRIPT="$MODDIR/monitor.sh"
PKG_FILE="/data/system/packages.list"

# ==============================================================================
#  FUNCTIONS
# ==============================================================================

# Find the specific PID of the Watcher (Child) and the Supervisor Loop (Parent)
get_pids() {
    CHILD_PID=$(pgrep -f "inotifyd.*monitor.sh" | head -n 1)
    PARENT_PID=""
    if [ -n "$CHILD_PID" ] && [ -f "/proc/$CHILD_PID/stat" ]; then
        PARENT_PID=$(cut -d ' ' -f 4 "/proc/$CHILD_PID/stat")
    fi
}

# The actual logic that runs the infinite loop
start_daemon_logic() {
    local SOURCE=$1
    echo "$(date '+%T') UI: 🛡️ Live Monitor Service starting ($SOURCE)..." >> "$LOG_FILE"
    
    # Run the Keep-Alive Loop
    while true; do
        if command -v inotifyd >/dev/null 2>&1; then
            # Blocking watcher
            inotifyd "$MONITOR_SCRIPT" "$PKG_FILE:y:c:d:n"
            sleep 5
        else
            echo "$(date '+%T') UI: ⚠️ Error: inotifyd not found. Retrying..." >> "$LOG_FILE"
            sleep 30
        fi
    done
}

stop_daemon() {
    get_pids
    if [ -n "$PARENT_PID" ]; then
        kill -9 "$PARENT_PID" 2>/dev/null
    fi
    if [ -n "$CHILD_PID" ]; then
        kill -9 "$CHILD_PID" 2>/dev/null
    fi
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

    if [ -n "$CHILD_PID" ]; then
        echo " STATUS:  🟢 RUNNING"
        echo " Watcher: $CHILD_PID"
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
                # Launch in background, detached
                ( start_daemon_logic "Manual" ) >/dev/null 2>&1 & 
                echo " ✅ Service started in background."
                echo "$(date '+%T') UI: 🎮 Manual Start initiated." >> "$LOG_FILE"
                ;;
            *) echo " No changes made." ;;
        esac
    fi
    
    # Exit immediately so we don't run the Boot Logic below
    exit 0
fi

# ==============================================================================
#  MODE 2: BOOT AUTOMATION (Magisk / KernelSU)
# ==============================================================================

# 1. Atomic Lock (Prevent double execution on boot)
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

# 2. Fix Permissions
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] && [ ! -x "$f" ] && chmod 755 "$f"
done

# 3. Wait for Boot Completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# 4. Check Config & Run Action (Generator)
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

# 5. Start Live Monitor (Daemon)
# Kill any stale instances first
stop_daemon

# Launch the loop in background
( start_daemon_logic "Boot" ) &

exit 0
