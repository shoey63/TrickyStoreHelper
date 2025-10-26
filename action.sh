#!/system/bin/sh
# TrickyStore Helper Action Button
# by shoey63 (based on osm0sis template)

MODPATH="${0%/*}"
TS_DIR="/data/adb/tricky_store"
TARGET_FILE="$TS_DIR/target.txt"
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

# --- Summary Section ---
echo ""
echo "✅ Update complete!"
echo "📊 Summary:"
echo "--------------------------------"

if [ -f "$TARGET_FILE" ]; then
    UPDATED_TIME=$(date -r "$TARGET_FILE" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    [ -z "$UPDATED_TIME" ] && UPDATED_TIME="(timestamp unavailable)"
    echo "Updated: $UPDATED_TIME"
    echo "📁 File: $TARGET_FILE"
    echo ""

    # Count totals
    TOTAL=$(grep -v '^#' "$TARGET_FILE" | grep -v '^$' | wc -l)
    FORCE_COUNT=0
    SYSTEM_COUNT=0
    USER_COUNT=0

    # Determine which FORCE option is active
    FORCE_TYPE="none"
    [ -f "$CONFIG_FILE" ] && FORCE_TYPE=$(grep -E 'FORCE_(LEAF_HACK|CERT_GEN)=true' "$CONFIG_FILE" | head -n 1 | cut -d= -f1)

    # Count forced packages
    case "$FORCE_TYPE" in
        FORCE_LEAF_HACK) FORCE_COUNT=$(grep -c '\?$' "$TARGET_FILE") ;;
        FORCE_CERT_GEN)  FORCE_COUNT=$(grep -c '!$' "$TARGET_FILE") ;;
    esac

    # Identify system vs user apps
    SYSTEM_COUNT=$(grep -E '^(com\.google\.android\.gms|com\.android\.vending)' "$TARGET_FILE" | wc -l)
    USER_COUNT=$((TOTAL - SYSTEM_COUNT))

    echo "- Force mode:      ${FORCE_TYPE:-none}"
    echo "- User apps:       $USER_COUNT"
    echo "- System apps:     $SYSTEM_COUNT"
    echo "- Forced entries:  $FORCE_COUNT"
    echo "- Total entries:   $TOTAL"
else
    echo "⚠️  target.txt not found!"
fi

echo "--------------------------------"
echo ""
echo "You can now open /data/adb/tricky_store/target.txt to confirm the new target list."
echo ""

# Optional delay for KernelSU/APatch auto-close
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && \
   [ "$KSU_NEXT" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo "Closing dialog in 10 seconds..."
    sleep 10
fi
