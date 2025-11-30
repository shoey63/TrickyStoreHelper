#!/system/bin/sh
# action.sh - Run helper.sh from the module action button (Magisk / KernelSU / Apatch)
#
# Place this file at the module root. When the module "Action" button is pressed
# this script will run helper.sh so TrickyStore target.txt is regenerated.
#
# This version keeps the UI/dialog open after helper.sh completes by waiting
# a configurable number of seconds (HOLD_SECONDS) so KernelSU doesn't instantly
# close the dialogue and the user can read the output. It also attempts to
# restart Play services / Play Store (kill) to refresh Play Integrity state.

MODDIR=${0%/*}
SCRIPTNAME="action.sh"
HELPER_PATH="$MODDIR/helper.sh"

# Seconds to hold the dialog open AFTER helper.sh finishes; override by exporting HOLD_SECONDS
HOLD_SECONDS=${HOLD_SECONDS:-5}

echo "[$SCRIPTNAME] Starting TrickyStore helper..."
echo "[$SCRIPTNAME] Module directory: $MODDIR"
echo "[$SCRIPTNAME] Helper path: $HELPER_PATH"
echo "[$SCRIPTNAME] Will hold dialog for ${HOLD_SECONDS}s after helper completes (set HOLD_SECONDS to override)"

if [ ! -f "$HELPER_PATH" ]; then
    echo "[$SCRIPTNAME] ERROR: helper.sh not found at $HELPER_PATH"
    exit 1
fi

# Ensure helper is executable (so $0 inside helper.sh is the helper path)
if [ ! -x "$HELPER_PATH" ]; then
    echo "[$SCRIPTNAME] helper.sh is not executable. Attempting chmod 0755..."
    if chmod 0755 "$HELPER_PATH" 2>/dev/null; then
        echo "[$SCRIPTNAME] chmod succeeded."
    else
        echo "[$SCRIPTNAME] chmod failed or not permitted; will attempt to run with sh fallback."
    fi
fi

# Run helper.sh. Do NOT exec here because we want to hold the dialog open afterwards.
if [ -x "$HELPER_PATH" ]; then
    echo "[$SCRIPTNAME] Executing helper directly: $HELPER_PATH"
    "$HELPER_PATH" "$@"
    rc=$?
else
    echo "[$SCRIPTNAME] Executing helper via sh fallback: sh $HELPER_PATH"
    sh "$HELPER_PATH" "$@"
    rc=$?
fi

# Attempt to restart key Play services so Play Integrity state is refreshed.
# These are best-effort; failures are non-fatal.
echo "[$SCRIPTNAME] Attempting to restart Play services / Play Store to refresh Play Integrity..."
if su -c "killall -v com.google.android.gms.unstable" >/dev/null 2>&1; then
    echo "[$SCRIPTNAME] Requested restart of com.google.android.gms.unstable (Play Services unstable)."
else
    echo "[$SCRIPTNAME] Could not kill com.google.android.gms.unstable (may not be present or su not available)."
fi

if su -c "killall -v com.android.vending" >/dev/null 2>&1; then
    echo "[$SCRIPTNAME] Requested restart of com.android.vending (Play Store)."
else
    echo "[$SCRIPTNAME] Could not kill com.android.vending (may not be present or su not available)."
fi

# Summarize helper result
if [ "$rc" -eq 0 ]; then
    echo "[$SCRIPTNAME] helper.sh completed successfully (exit code 0)."
else
    echo "[$SCRIPTNAME] helper.sh exited with code $rc."
fi

# If HOLD_SECONDS is greater than zero, keep the dialog open for that many seconds.
# Allow user to dismiss early with Ctrl+C.
if [ "${HOLD_SECONDS:-0}" -gt 0 ] 2>/dev/null; then
    trap 'echo "\n['"$SCRIPTNAME"'] Dismissed by user."; exit $rc' INT
    i=$HOLD_SECONDS
    echo "[$SCRIPTNAME] Dialog will close automatically in ${HOLD_SECONDS}s. Press Ctrl+C to close immediately."
    while [ "$i" -gt 0 ]; do
        printf "\r[%s] Closing in %d second(s)... " "$SCRIPTNAME" "$i"
        sleep 1
        i=$((i - 1))
    done
    printf "\n"
fi

exit $rc
