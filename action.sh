#!/system/bin/sh
# TrickyStore Helper Action Button (accurate system/user/forced counts)
# by shoey63

MODPATH="${0%/*}"
TS_DIR="/data/adb/tricky_store"
TARGET_FILE="$TS_DIR/target.txt"
SYSTEM_FILE="$TS_DIR/helper/system.txt"
CONFIG_FILE="$TS_DIR/helper/config.txt"

echo ""
echo "* TrickyStore Helper *"
echo "-----------------------"
echo "Starting update..."
sleep 0.5

echo "• Running helper.sh..."
sh "$MODPATH/helper.sh" -m > /dev/null 2>&1
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "❌ Failed to update target.txt"
    exit 1
fi

sleep 0.5
echo "• Restarting Play Store & GMS..."
killall -v com.google.android.gms.unstable 2>/dev/null
killall -v com.android.vending 2>/dev/null
sleep 0.5

echo ""
echo "🔍 Analyzing target.txt..."
sleep 0.8

echo ""
echo "✅ Update complete!"
echo "📊 Summary:"
echo "--------------------------------"

if [ -f "$TARGET_FILE" ]; then
    # timestamp
    UPDATED_TIME=$(date -r "$TARGET_FILE" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    [ -z "$UPDATED_TIME" ] && UPDATED_TIME="(timestamp unavailable)"
    echo "Updated: $UPDATED_TIME"
    echo "📁 File: $TARGET_FILE"
    echo ""

    # Prepare sanitized target (strip trailing ? or ! from package names for matching)
    TMP_TARGET="${TMPDIR:-/data/local/tmp}/ts_target.$$"
    sed 's/[?!]$//' "$TARGET_FILE" | grep -v '^#' | grep -v '^[[:space:]]*$' > "$TMP_TARGET"

    # Count totals (based on sanitized target)
    TOTAL=$(wc -l < "$TMP_TARGET" 2>/dev/null || echo 0)

    # Prepare system list (if present), normalized
    TMP_SYSTEM="${TMPDIR:-/data/local/tmp}/ts_system.$$"
    if [ -f "$SYSTEM_FILE" ]; then
        # remove comments/blank lines
        grep -v '^#' "$SYSTEM_FILE" | grep -v '^[[:space:]]*$' > "$TMP_SYSTEM" 2>/dev/null || : 
    else
        # if no system file use default two entries (backwards compatible)
        printf "com.google.android.gms\ncom.android.vending\n" > "$TMP_SYSTEM"
    fi

    # If system list empty, ensure a zero-length file doesn't break grep -Fxf
    [ -s "$TMP_SYSTEM" ] || : 

    # Count system apps by exact match (compare sanitized target to system list)
    # Use grep -F -x -f to match fixed strings, exact lines
    if [ -s "$TMP_SYSTEM" ]; then
        SYSTEM_COUNT=$(grep -F -x -f "$TMP_SYSTEM" "$TMP_TARGET" | wc -l)
    else
        SYSTEM_COUNT=0
    fi

    # User apps are the rest
    USER_COUNT=$((TOTAL - SYSTEM_COUNT))
    if [ "$USER_COUNT" -lt 0 ]; then USER_COUNT=0; fi

    # Determine force type and count forced entries (count trailing ? or ! in original file)
    FORCE_TYPE="none"
    if [ -f "$CONFIG_FILE" ]; then
        FORCE_TYPE=$(grep -E 'FORCE_(LEAF_HACK|CERT_GEN)=true' "$CONFIG_FILE" | head -n 1 | cut -d= -f1)
    fi

    if [ "$FORCE_TYPE" = "FORCE_LEAF_HACK" ]; then
        FORCE_COUNT=$(grep -c '\?$' "$TARGET_FILE" 2>/dev/null || echo 0)
    elif [ "$FORCE_TYPE" = "FORCE_CERT_GEN" ]; then
        FORCE_COUNT=$(grep -c '!$' "$TARGET_FILE" 2>/dev/null || echo 0)
    else
        FORCE_COUNT=$(grep -c '[?!]$' "$TARGET_FILE" 2>/dev/null || echo 0)
    fi

    echo "- Force mode:      ${FORCE_TYPE:-none}"
    echo "- User apps:       $USER_COUNT"
    echo "- System apps:     $SYSTEM_COUNT"
    echo "- Forced entries:  $FORCE_COUNT"
    echo "- Total entries:   $TOTAL"

    # cleanup temp files
    rm -f "$TMP_TARGET" "$TMP_SYSTEM" 2>/dev/null || true
else
    echo "⚠️  target.txt not found!"
fi

echo "--------------------------------"
echo ""
echo "You can now open /data/adb/tricky_store/target.txt to confirm the new target list."
echo ""

# Optional countdown delay for KernelSU/APatch auto-close (10s)
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && \
   [ "$KSU_NEXT" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo
    echo "Closing dialog in 10 seconds..."
    sleep 1
    for i in 9 8 7 6 5 4 3 2 1; do
        printf "                   %d ...\n" "$i"
        sleep 1
    done
    echo "                   ✅"
    echo
fi
