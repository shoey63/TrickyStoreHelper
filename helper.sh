#!/system/bin/sh
# helper.sh — TrickyStore Helper (UI mode with --ui, silent otherwise)
MODDIR="${0%/*}"

# Paths
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
TARGET_FILE="$TS_FOLDER/target.txt"
LOG_FILE="$TS_HELPER/helper.log"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"

# --------------------------------------------------------------------
# Logging helper (LEVEL MESSAGE) — append-only
# --------------------------------------------------------------------
log() {
    LEVEL="$1"; shift
    MESSAGE="$*"
    printf "%s [%s] %s\n" "$(date '+%F %T')" "$LEVEL" "$MESSAGE" >> "$LOG_FILE"
}

# --------------------------------------------------------------------
# UI-print helper: logs always, prints only when UI_MODE=true
# --------------------------------------------------------------------
ui_print() {
    LEVEL="$1"; shift
    MSG="$*"
    log "$LEVEL" "$MSG"
    if [ "$UI_MODE" = "true" ]; then
        printf "%s\n" "$MSG"
    fi
}

# --------------------------------------------------------------------
# Determine UI mode: helper.sh --ui  => UI_MODE=true; else silent
# --------------------------------------------------------------------
UI_MODE="false"
if [ "$1" = "--ui" ]; then
    UI_MODE="true"
fi

# Ensure helper folder exists
if [ ! -d "$TS_HELPER" ]; then
    mkdir -p "$TS_HELPER" 2>/dev/null || true
fi

# Ensure log file exists (create if missing)
[ -f "$LOG_FILE" ] || : > "$LOG_FILE" 2>/dev/null

log "I" "helper.sh started (UI_MODE=$UI_MODE)"

# --------------------------------------------------------------------
# Fatal only if the main TS_FOLDER doesn't exist
# --------------------------------------------------------------------
if [ ! -d "$TS_FOLDER" ]; then
    log "F" "TrickyStore folder missing: $TS_FOLDER — abort."
    if [ "$UI_MODE" = "true" ]; then
        echo "FATAL: TrickyStore folder missing at $TS_FOLDER"
        sleep 2
    fi
    exit 1
fi

# --------------------------------------------------------------------
# Read config (whitespace tolerant)
# --------------------------------------------------------------------
ORIG_FORCE_LEAF_HACK=""
ORIG_FORCE_CERT_GEN=""
FORCE_LEAF_HACK="false"
FORCE_CERT_GEN="false"
USE_DEFAULT_EXCLUSIONS="true"

if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        L="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$L" in
            ''|\#*) continue ;;
        esac
        key="$(echo "$L" | sed 's/[[:space:]]*=.*$//')"
        val="$(echo "$L" | sed 's/^.*=[[:space:]]*//')"
        key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        val="$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$key" in
            FORCE_LEAF_HACK) ORIG_FORCE_LEAF_HACK="$val"; FORCE_LEAF_HACK="$val" ;;
            FORCE_CERT_GEN)  ORIG_FORCE_CERT_GEN="$val";  FORCE_CERT_GEN="$val"  ;;
            USE_DEFAULT_EXCLUSIONS) USE_DEFAULT_EXCLUSIONS="$val" ;;
        esac
    done < "$CONFIG_FILE"
fi

[ -z "$FORCE_LEAF_HACK" ] && FORCE_LEAF_HACK="false"
[ -z "$FORCE_CERT_GEN" ] && FORCE_CERT_GEN="false"
[ -z "$USE_DEFAULT_EXCLUSIONS" ] && USE_DEFAULT_EXCLUSIONS="true"

# --------------------------------------------------------------------
# If both flags true: neutralize in-memory only, log + UI warning
# --------------------------------------------------------------------
if [ "$FORCE_LEAF_HACK" = "true" ] && [ "$FORCE_CERT_GEN" = "true" ]; then
    # keep original strings for display
    ORIG1="$FORCE_LEAF_HACK"
    ORIG2="$FORCE_CERT_GEN"
    FORCE_LEAF_HACK="false"
    FORCE_CERT_GEN="false"
    log "W" "Config anomaly: FORCE_LEAF_HACK=true & FORCE_CERT_GEN=true detected. Neutralized in-memory for this run."
    if [ "$UI_MODE" = "true" ]; then
        echo ""
        echo "🚨🚨🚨  WARNING — UNSAFE CONFIGURATION DETECTED  🚨🚨🚨"
        echo ""
        echo "Both FORCE_LEAF_HACK and FORCE_CERT_GEN are TRUE in:"
        echo "    $CONFIG_FILE"
        echo ""
        echo "This run will proceed with both flags set to FALSE in memory only."
        echo "To make a permanent change, edit the file above and set one flag to false."
        echo ""
        echo "-------------------------------------------------------------"
        echo ""
        sleep 2
    fi
fi

log "I" "Config: FORCE_LEAF_HACK=${FORCE_LEAF_HACK} (orig=${ORIG_FORCE_LEAF_HACK:-n/a}) FORCE_CERT_GEN=${FORCE_CERT_GEN} (orig=${ORIG_FORCE_CERT_GEN:-n/a}) USE_DEFAULT_EXCLUSIONS=${USE_DEFAULT_EXCLUSIONS}"

# --------------------------------------------------------------------
# Count force/exclude entries for UI
# --------------------------------------------------------------------
FORCE_COUNT=0
EXCLUDE_COUNT=0
if [ -f "$FORCE_FILE" ]; then
    FORCE_COUNT=$(grep -v '^$' "$FORCE_FILE" 2>/dev/null | wc -l 2>/dev/null || echo 0)
fi
if [ -f "$EXCLUDE_FILE" ]; then
    EXCLUDE_COUNT=$(grep -v '^$' "$EXCLUDE_FILE" 2>/dev/null | wc -l 2>/dev/null || echo 0)
fi

# --------------------------------------------------------------------
# UI Header (UI_MODE only) — plain newlines (no ANSI escapes)
# --------------------------------------------------------------------
if [ "$UI_MODE" = "true" ]; then
    echo
    echo
    echo
    echo "======================================="
    echo "        ⭐ TrickyStore Helper ⭐"
    echo "======================================="
    echo ""
    sleep 0.2
    echo "📄 Loaded configuration:"
    printf " • %-25s %s\n" "FORCE_LEAF_HACK:" "$FORCE_LEAF_HACK"
    if [ -n "$ORIG_FORCE_LEAF_HACK" ] && [ "$ORIG_FORCE_LEAF_HACK" != "$FORCE_LEAF_HACK" ]; then
        printf "   (temporarily changed from: %s)\n" "$ORIG_FORCE_LEAF_HACK"
    fi
    printf " • %-25s %s\n" "FORCE_CERT_GEN:" "$FORCE_CERT_GEN"
    if [ -n "$ORIG_FORCE_CERT_GEN" ] && [ "$ORIG_FORCE_CERT_GEN" != "$FORCE_CERT_GEN" ]; then
        printf "   (temporarily changed from: %s)\n" "$ORIG_FORCE_CERT_GEN"
    fi
    printf " • %-25s %s\n" "USE_DEFAULT_EXCLUSIONS:" "$USE_DEFAULT_EXCLUSIONS"
    printf " • %-25s %s\n" "FORCE.TXT entries:" "$FORCE_COUNT"
    printf " • %-25s %s\n" "EXCLUDE.TXT entries:" "$EXCLUDE_COUNT"
    echo ""
    echo "---------------------------------------"
    echo "▶️  Preparing to build target.txt..."
    echo ""
    sleep 0.5
fi

# --------------------------------------------------------------------
# Ensure target file exists (create if missing) — user must always have it
# --------------------------------------------------------------------
if [ ! -f "$TARGET_FILE" ]; then
    : > "$TARGET_FILE" 2>/dev/null || touch "$TARGET_FILE" 2>/dev/null || true
    ui_print "I" "Created missing target file: $TARGET_FILE"
fi

# --------------------------------------------------------------------
# Generate base target list
# --------------------------------------------------------------------
if [ "$USE_DEFAULT_EXCLUSIONS" = "true" ]; then
    ui_print "I" "Generating target.txt: user apps + Play Store + Play Services"
    {
        pm list packages -3 2>/dev/null
        pm list packages com.android.vending 2>/dev/null
        pm list packages com.google.android.gms 2>/dev/null
    } | cut -d: -f2 | sed '/^$/d' | sort -u > "$TARGET_FILE"
else
    ui_print "I" "Generating target.txt: all packages"
    pm list packages 2>/dev/null | cut -d: -f2 | sed '/^$/d' | sort -u > "$TARGET_FILE"
fi

# --------------------------------------------------------------------
# FORCE INCLUDE: restore original working behaviour (Option 1)
# - Cache the system package list once (portable POSIX)
# - Iterate force.txt lines and add the package to target.txt
#   if it's installed on the system and not already present
# - This respects Option 1: forced packages included even if they are system apps
# --------------------------------------------------------------------
if [ -f "$FORCE_FILE" ]; then
    # Cache all installed packages once
    ALL_SYSTEM_PACKAGES="$(pm list packages 2>/dev/null | cut -d: -f2 || true)"

    # read force.txt lines safely
    while IFS= read -r fline || [ -n "$fline" ]; do
        fpkg="$(echo "$fline" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$fpkg" in
            ''|\#*) continue ;;
        esac

        # Check existence using cached package list (works across boot/UI contexts)
        echo "$ALL_SYSTEM_PACKAGES" | grep -xqF "$fpkg"
        FOUND=$?

        if [ "$FOUND" -eq 0 ]; then
            # package is installed — add if missing
            if ! grep -xqF "$fpkg" "$TARGET_FILE" 2>/dev/null; then
                echo "$fpkg" >> "$TARGET_FILE"
                log "I" "FORCE_INCLUDE: Added system app '$fpkg' from force.txt"
                if [ "$UI_MODE" = "true" ]; then
                    printf "FORCE_INCLUDE: Added %s\n" "$fpkg"
                fi
            else
                log "D" "FORCE_INCLUDE: $fpkg already present in target.txt"
            fi
        else
            # Not found in pm list — depending on user preference Option 1 still allows forced inclusion.
            # We will still add it (Option 1), but log that pm did not list it.
            if ! grep -xqF "$fpkg" "$TARGET_FILE" 2>/dev/null; then
                echo "$fpkg" >> "$TARGET_FILE"
                log "W" "FORCE_INCLUDE: $fpkg not listed by pm, but force.txt requested it — added anyway"
                if [ "$UI_MODE" = "true" ]; then
                    printf "FORCE_INCLUDE (pm-not-listed): %s (added)\n" "$fpkg"
                fi
            else
                log "D" "FORCE_INCLUDE (pm-not-listed): $fpkg already present"
            fi
        fi
    done < "$FORCE_FILE"

    # Re-sort and uniq
    sort -u "$TARGET_FILE" -o "$TARGET_FILE" 2>/dev/null || true
fi

# --------------------------------------------------------------------
# Apply exclusions from exclude.txt (if present)
# --------------------------------------------------------------------
if [ -f "$EXCLUDE_FILE" ]; then
    tmp="$(mktemp /data/local/tmp/tshelper.excl.XXXX 2>/dev/null || echo /data/local/tmp/tshelper.excl.tmp)"
    cp "$TARGET_FILE" "$tmp" 2>/dev/null || true
    while IFS= read -r xline || [ -n "$xline" ]; do
        xpkg="$(echo "$xline" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$xpkg" in
            ''|\#*) continue ;;
        esac
        sed -i "/^$(printf '%s' "$xpkg" | sed 's/[][\/.^$*]/\\&/g')$/d" "$tmp" 2>/dev/null || true
        ui_print "I" "Excluded package: $xpkg"
    done < "$EXCLUDE_FILE"
    mv "$tmp" "$TARGET_FILE" 2>/dev/null || true
fi

# --------------------------------------------------------------------
# Apply force tagging: when force.txt entries present tag those entries
# otherwise apply globally if a global flag is set
# --------------------------------------------------------------------
if [ -f "$FORCE_FILE" ] && [ -s "$FORCE_FILE" ]; then
    # For each forced package, append ? or ! (or both) as appropriate
    while IFS= read -r fline || [ -n "$fline" ]; do
        fpkg="$(echo "$fline" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        case "$fpkg" in
            ''|\#*) continue ;;
        esac

        tmp="$(mktemp /data/local/tmp/tshelper.tag.XXXX 2>/dev/null || echo /data/local/tmp/tshelper.tag.tmp)"
        while IFS= read -r l || [ -n "$l" ]; do
            if [ "$l" = "$fpkg" ] || [ "$l" = "${fpkg}?" ] || [ "$l" = "${fpkg}!" ] || echo "$l" | grep -q "^${fpkg}[?!]$"; then
                out="$l"
                # strip existing suffixes before appending desired ones
                base="$(echo "$l" | sed 's/[?!]$//')"
                out="$base"
                if [ "$FORCE_LEAF_HACK" = "true" ]; then out="${out}?" ; fi
                if [ "$FORCE_CERT_GEN" = "true" ]; then out="${out}!" ; fi
                printf "%s\n" "$out" >> "$tmp"
            else
                printf "%s\n" "$l" >> "$tmp"
            fi
        done < "$TARGET_FILE"
        mv "$tmp" "$TARGET_FILE" 2>/dev/null || true
    done < "$FORCE_FILE"
else
    # no force file entries -> apply globally if flags set
    if [ "$FORCE_LEAF_HACK" = "true" ]; then
        tmp="$(mktemp /data/local/tmp/tshelper.all.XXXX 2>/dev/null || echo /data/local/tmp/tshelper.all.tmp)"
        while IFS= read -r l || [ -n "$l" ]; do
            printf "%s?\n" "$l" >> "$tmp"
        done < "$TARGET_FILE"
        mv "$tmp" "$TARGET_FILE" 2>/dev/null || true
    elif [ "$FORCE_CERT_GEN" = "true" ]; then
        tmp="$(mktemp /data/local/tmp/tshelper.all2.XXXX 2>/dev/null || echo /data/local/tmp/tshelper.all2.tmp)"
        while IFS= read -r l || [ -n "$l" ]; do
            printf "%s!\n" "$l" >> "$tmp"
        done < "$TARGET_FILE"
        mv "$tmp" "$TARGET_FILE" 2>/dev/null || true
    fi
fi

# --------------------------------------------------------------------
# Final cleanup: remove empty lines and sort unique
# --------------------------------------------------------------------
if [ -f "$TARGET_FILE" ]; then
    sed -i '/^$/d' "$TARGET_FILE" 2>/dev/null || true
    sort -u "$TARGET_FILE" -o "$TARGET_FILE" 2>/dev/null || true
fi

ui_print "I" "target.txt generated: $(wc -l < "$TARGET_FILE" 2>/dev/null || echo 0) packages"

# --------------------------------------------------------------------
# Kill Play services (UI only)
# --------------------------------------------------------------------
if [ "$UI_MODE" = "true" ]; then
    ui_print "I" "Restarting Play services to apply changes..."
    am force-stop com.google.android.gms >/dev/null 2>&1 || true
    sleep 0.3
    am force-stop com.android.vending >/dev/null 2>&1 || true
    sleep 0.3
    ui_print "I" "Play services stopped; they will restart automatically."
fi

# --------------------------------------------------------------------
# Auto-close for KernelSU / APatch (UI only)
# --------------------------------------------------------------------
if [ "$UI_MODE" = "true" ] && ( [ "$KSU" = "true" ] || [ "$APATCH" = "true" ] ) \
   && [ "$KSU_NEXT" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    ui_print "I" "📴 Closing dialog in 10 seconds..."
    sleep 10
fi

ui_print "I" "helper.sh finished"
exit 0
