#!/system/bin/sh

MODDIR=${0%/*}
CONFIG_FILE="/data/adb/tricky_store/helper/config.txt"

# Wait for boot_completed (safe loop)
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Fix permissions
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    CUR=$(stat -c "%a" "$f" 2>/dev/null)
    [ "$CUR" != "755" ] && chmod 755 "$f"
done

# -------------------------------------------------------------------
# CONFIG SAFETY FIX
# If both flags are true, force-reset to false/false
# -------------------------------------------------------------------
if [ -f "$CONFIG_FILE" ]; then
    FORCE_LEAF_HACK=$(grep '^FORCE_LEAF_HACK=' "$CONFIG_FILE" | cut -d '=' -f 2)
    FORCE_CERT_GEN=$(grep '^FORCE_CERT_GEN=' "$CONFIG_FILE" | cut -d '=' -f 2)

    if [ "$FORCE_LEAF_HACK" = "true" ] && [ "$FORCE_CERT_GEN" = "true" ]; then
        # Automatically repair config to prevent helper abort
        sed -i 's/^FORCE_LEAF_HACK=.*/FORCE_LEAF_HACK=false/' "$CONFIG_FILE"
        sed -i 's/^FORCE_CERT_GEN=.*/FORCE_CERT_GEN=false/' "$CONFIG_FILE"

        echo "[TSHelper] Auto-fixed invalid config at boot." \
            >> /data/adb/tricky_store/helper/bootlog.txt
    fi
fi

# -------------------------------------------------------------------
# Run helper script
# -------------------------------------------------------------------
/system/bin/sh "$MODDIR/helper.sh"
