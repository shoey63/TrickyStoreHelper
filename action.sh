#!/system/bin/sh
MODDIR="${0%/*}"

TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"

CONFIG_FILE="$TS_HELPER/config.txt"
FORCE_FILE="$TS_HELPER/force.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"

# Correct location of helper.sh — always inside the module
HELPER_SH="$MODDIR/helper.sh"
TARGET_FILE="$TS_FOLDER/target.txt"

SCRIPTNAME="TrickyStore Helper"

#--------------------------------------------------------------------
#  Read config values
#--------------------------------------------------------------------
get_conf() {
    grep "^$1=" "$CONFIG_FILE" 2>/dev/null | cut -d '=' -f 2
}

FORCE_LEAF_HACK=$(get_conf FORCE_LEAF_HACK)
FORCE_CERT_GEN=$(get_conf FORCE_CERT_GEN)
USE_DEFAULT_EXCLUSIONS=$(get_conf USE_DEFAULT_EXCLUSIONS)

[ -z "$FORCE_LEAF_HACK" ] && FORCE_LEAF_HACK="false"
[ -z "$FORCE_CERT_GEN" ] && FORCE_CERT_GEN="false"
[ -z "$USE_DEFAULT_EXCLUSIONS" ] && USE_DEFAULT_EXCLUSIONS="true"

#--------------------------------------------------------------------
# Count entries in force/exclude files
#--------------------------------------------------------------------
FORCE_COUNT=0
EXCLUDE_COUNT=0

[ -f "$FORCE_FILE" ] && FORCE_COUNT=$(grep -v '^$' "$FORCE_FILE" | wc -l)
[ -f "$EXCLUDE_FILE" ] && EXCLUDE_COUNT=$(grep -v '^$' "$EXCLUDE_FILE" | wc -l)

#--------------------------------------------------------------------
# Header
#--------------------------------------------------------------------
clear
echo "======================================="
echo "        ⭐ TrickyStore Helper ⭐"
echo "======================================="
echo ""
sleep 0.7

echo "📄 Loaded configuration:"
sleep 0.5
echo " • FORCE_LEAF_HACK:         $FORCE_LEAF_HACK"
sleep 0.2
echo " • FORCE_CERT_GEN:          $FORCE_CERT_GEN"
sleep 0.2
echo " • USE_DEFAULT_EXCLUSIONS:  $USE_DEFAULT_EXCLUSIONS"
sleep 0.2
echo " • FORCE.TXT entries:       $FORCE_COUNT"
sleep 0.2
echo " • EXCLUDE.TXT entries:     $EXCLUDE_COUNT"
sleep 1.2

echo ""
echo "---------------------------------------"
echo "▶️  Preparing to run helper.sh..."
sleep 1.2

#--------------------------------------------------------------------
# Validate helper.sh
#--------------------------------------------------------------------
if [ ! -f "$HELPER_SH" ]; then
    echo "❌ ERROR: helper.sh not found!"
    echo "Expected at: $HELPER_SH"
    sleep 3
    exit 1
fi

#--------------------------------------------------------------------
# Run Helper Script (CORRECT shell!)
#--------------------------------------------------------------------
echo "⚙️  Running helper.sh..."
/system/bin/sh "$HELPER_SH"
RET=$?

if [ "$RET" != "0" ]; then
    echo ""
    echo "❌ helper.sh FAILED (exit code $RET)"
    echo "⚠️ FORCE flags must not be both set to true"
    echo "Check: /data/adb/tricky_store/helper/config.txt"
    sleep 4
    exit $RET
fi

echo "✔️ helper.sh completed successfully"
sleep 1

#--------------------------------------------------------------------
# Restart services to immediately apply target.txt changes
#--------------------------------------------------------------------
echo ""
echo "🔄 Applying changes..."
sleep 0.7

echo " • Killing Google Play services..."
am force-stop com.google.android.gms >/dev/null 2>&1
sleep 0.8

echo " • Killing Google Play Store..."
am force-stop com.android.vending >/dev/null 2>&1
sleep 0.8

echo " • They will restart automatically."
sleep 1.2

#--------------------------------------------------------------------
# Final summary
#--------------------------------------------------------------------
NEW_COUNT=$(wc -l < "$TARGET_FILE")

echo ""
echo "---------------------------------------"
echo "✅  Update complete!"
sleep 0.4
echo "📊  Target list updated:"
echo " • File: target.txt"
echo " • Total packages: $NEW_COUNT"
sleep 1

#--------------------------------------------------------------------
# Auto-close for KernelSU / APatch
#--------------------------------------------------------------------
if [ "$KSU" = "true" -o "$APATCH" = "true" ] \
   && [ "$KSU_NEXT" != "true" ] \
   && [ "$WKSU" != "true" ] \
   && [ "$MMRL" != "true" ]; then

    echo ""
    echo "📴 Closing dialog in 10 seconds..."
    sleep 10
fi

echo ""
echo "Exiting..."
sleep 2
exit 0
