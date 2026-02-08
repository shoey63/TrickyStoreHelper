#!/system/bin/sh
# service.sh - TrickyStore Helper Daemon & Control Panel

MODDIR=${0%/*}

TS_FOLDER="/data/adb/tricky_store"
HELPER_DIR="$MODDIR/helper"

CONFIG_FILE="$HELPER_DIR/config.txt"
LOG_FILE="$HELPER_DIR/TSHelper.log"

LOCK_DIR="/dev/ts_helper_lock"
PID_FILE="/dev/ts_helper_supervisor.pid"

MONITOR_SCRIPT="$MODDIR/monitor.sh"
PKG_FILE="/data/system/packages.list"

# --- Ensure helper exists (migration safety) ---
mkdir -p "$HELPER_DIR"
touch "$LOG_FILE"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

log_ui() {
    echo "$(date '+%T') UI: $1" >> "$LOG_FILE"
}

get_pids() {
    if [ -f "$PID_FILE" ]; then
        READ_PID=$(cat "$PID_FILE")
        if [ -d "/proc/$READ_PID" ]; then
            PARENT_PID=$READ_PID
            CHILD_PID=$(pgrep -P "$PARENT_PID" -f "inotifyd" | head -n 1)
            return
        else
            rm -f "$PID_FILE"
        fi
    fi

    CHILD_PID=$(pgrep -f "inotifyd.*monitor.sh" | head -n 1)
    PARENT_PID=""
    if [ -n "$CHILD_PID" ] && [ -f "/proc/$CHILD_PID/stat" ]; then
        PARENT_PID=$(cut -d ' ' -f 4 "/proc/$CHILD_PID/stat")
    fi
}

start_daemon_logic() {
    local SOURCE=$1
    log_ui "🛡️ Live Monitor Service starting ($SOURCE)..."

    pkill -f "inotifyd.*monitor.sh" 2>/dev/null

    while true; do
        if command -v inotifyd >/dev/null 2>&1; then
            inotifyd "$MONITOR_SCRIPT" "$PKG_FILE:ycdn"
            sleep 5
        else
            log_ui "⚠️ 'inotifyd' not found. Retrying in 30s..."
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
# INTERACTIVE MODE
# ==============================================================================

if [ -t 0 ]; then
    clear
    echo "TrickyStore Helper Control Panel"
    echo "--------------------------------"

    get_pids

    if [ -n "$CHILD_PID" ] || [ -n "$PARENT_PID" ]; then
        echo "STATUS: RUNNING"
        printf "Stop service? (y/n): "
        read -r CHOICE
        [ "$CHOICE" = "y" ] && stop_daemon && log_ui "🛑 Service stopped manually."
    else
        echo "STATUS: STOPPED"
        printf "Start service? (y/n): "
        read -r CHOICE
        if [ "$CHOICE" = "y" ]; then
            log_ui "🎮 Manual start initiated."
            (
                trap '' HUP
                start_daemon_logic "Manual"
            ) &
            echo $! > "$PID_FILE"
        fi
    fi
    exit 0
fi

# ==============================================================================
# BOOT MODE
# ==============================================================================

! mkdir "$LOCK_DIR" 2>/dev/null && exit 0

for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] && chmod 755 "$f"
done

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done

RUN_ON_BOOT="true"
if [ -f "$CONFIG_FILE" ]; then
    VAL=$(grep "^RUN_ON_BOOT=" "$CONFIG_FILE" | cut -d= -f2 | tr -d '[:space:]')
    [ "$VAL" = "false" ] && RUN_ON_BOOT="false"
fi

if [ "$RUN_ON_BOOT" = "true" ]; then
    sh "$MODDIR/action.sh" boot
else
    log_ui "ℹ️ Boot execution skipped."
fi

stop_daemon
( start_daemon_logic "Boot" ) &

exit 0
