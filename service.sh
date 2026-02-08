#!/system/bin/sh
# service.sh - TrickyStore Helper Daemon & Control Panel

MODDIR=${0%/*}

TS_FOLDER="/data/adb/tricky_store"

# Must match customize.sh / action.sh
HELPER_DIR="$MODDIR/helper"

LOCK_DIR="/dev/ts_helper_lock"
CONFIG_FILE="$HELPER_DIR/config.txt"
LOG_FILE="$HELPER_DIR/TSHelper.log"
PID_FILE="/dev/ts_helper_supervisor.pid"

MONITOR_SCRIPT="$MODDIR/monitor.sh"
PKG_FILE="/data/system/packages.list"

# Ensure helper/log exists early (safe on boot)
mkdir -p "$HELPER_DIR"
touch "$LOG_FILE"

# ==============================================================================
#  FUNCTIONS
# ==============================================================================

get_pids() {
    # 1. RAM PID file (manual mode reliability)
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

    # 2. Fallback: search process tree
    CHILD_PID=$(pgrep -f "inotifyd.*monitor.sh" | head -n 1)
    PARENT_PID=""
    if [ -n "$CHILD_PID" ] && [ -f "/proc/$CHILD_PID/stat" ]; then
        PARENT_PID=$(cut -d ' ' -f 4 "/proc/$CHILD_PID/stat")
    fi
}

start_daemon_logic() {
    local SOURCE=$1
    echo "$(date '+%T') UI: 🛡️ Live Monitor Service starting ($SOURCE)..." >> "$LOG_FILE"

    pkill -f "inotifyd.*monitor.sh" 2>/dev/null

    while true; do
        if command -v inotifyd >/dev/null 2>&1; then
            inotifyd "$MONITOR_SCRIPT" "$PKG_FILE:ycdn"
            sleep 5
        else
