#!/system/bin/sh
# TrickyStore Helper - service.sh

MODDIR="${0%/*}"
HELPER="$MODDIR/helper.sh"

#──────────────────────────────
# Fix permissions only if needed
#──────────────────────────────
for f in "$MODDIR"/*.sh; do
    [ -f "$f" ] || continue
    CUR=$(stat -c "%a" "$f" 2>/dev/null)
    if [ "$CUR" != "755" ]; then
        chmod 755 "$f"
    fi
done

#──────────────────────────────
# Run helper at boot
#──────────────────────────────
sh "$HELPER" boot &
