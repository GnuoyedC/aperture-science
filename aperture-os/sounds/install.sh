#!/usr/bin/env bash
# Aperture OS – Sounds: System sound theme "aperture-os" + session sounds (Turret).
#
#   ./install.sh                 install theme + session sounds (idempotent, activates nothing)
#   ./install.sh --activate      additionally set the sound theme in kdeglobals [Sound] Theme
#   ./install.sh --no-session    only the sound theme (do not touch the session sounds)
#   ./install.sh --session-only  only the session sounds
#   ./install.sh --uninstall     remove own files, restore the previous sound theme,
#                                disable the session units (with --no-session: session stays)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_ID=aperture-os
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
THEME_DST="$DATA/sounds/$THEME_ID"
PREV_FILE="$STATE/sound-theme.prev"

# Session sounds: target paths are fixed because the units reference them via %h.
UNIT_DIR="$CONF/systemd/user"
BIN_DIR="$HOME/.local/bin"
SESSION_SND_DIR="$HOME/.local/share/turret-sounds"
UNITS=(turret-sounds.service turret-shutdown-watch.service)

do_theme=1 do_session=1 activate=0 uninstall=0
for a in "$@"; do
    case "$a" in
        --activate)     activate=1 ;;
        --no-session)   do_session=0 ;;
        --session-only) do_theme=0 ;;
        --uninstall)    uninstall=1 ;;
        -h|--help)      sed -n '2,10p' "$0"; exit 0 ;;
        *) echo "Unknown option: $a" >&2; exit 2 ;;
    esac
done

kw() { command -v kwriteconfig6 >/dev/null && echo kwriteconfig6 || echo kwriteconfig5; }
kr() { command -v kreadconfig6  >/dev/null && echo kreadconfig6  || echo kreadconfig5; }

# copy_if_changed <src> <dst> <mode>  -> echo "changed" if copied
copy_if_changed() {
    if [[ -f "$2" ]] && cmp -s "$1" "$2"; then return 0; fi
    install -D -m "$3" "$1" "$2"
    echo "  updated: $2" >&2
    echo changed
}

install_theme() {
    echo "Sound theme → $THEME_DST"
    mkdir -p "$THEME_DST/stereo"
    install -m 644 "$SRC/aperture-os/index.theme" "$THEME_DST/index.theme"
    # remove orphaned own files (e.g. renamed events)
    find "$THEME_DST/stereo" -maxdepth 1 -name '*.oga' -type f | while read -r f; do
        [[ -f "$SRC/aperture-os/stereo/$(basename "$f")" ]] || rm -f "$f"
    done
    install -m 644 "$SRC"/aperture-os/stereo/*.oga "$THEME_DST/stereo/"
    echo "  $(ls "$THEME_DST/stereo" | wc -l) sounds installed"
}

activate_theme() {
    local cur; cur="$($(kr) --file kdeglobals --group Sound --key Theme 2>/dev/null || true)"
    mkdir -p "$STATE"
    if [[ "$cur" != "$THEME_ID" && ! -f "$PREV_FILE" ]]; then
        # Empty content = key was not set (Plasma default "ocean")
        printf '%s\n' "$cur" > "$PREV_FILE"
        echo "  previous sound theme backed up: '${cur:-<default>}' → $PREV_FILE"
    fi
    "$(kw)" --file kdeglobals --group Sound --key Theme "$THEME_ID"
    echo "Sound theme activated: kdeglobals [Sound] Theme=$THEME_ID"
    echo "  (running applications may only pick it up after re-login)"
}

restore_theme() {
    local cur; cur="$($(kr) --file kdeglobals --group Sound --key Theme 2>/dev/null || true)"
    if [[ -f "$PREV_FILE" ]]; then
        local prev; prev="$(head -n1 "$PREV_FILE")"
        if [[ "$cur" == "$THEME_ID" ]]; then
            if [[ -n "$prev" ]]; then "$(kw)" --file kdeglobals --group Sound --key Theme "$prev"
            else "$(kw)" --file kdeglobals --group Sound --key Theme --delete; fi
            echo "Sound theme restored: '${prev:-<default>}'"
        fi
        rm -f "$PREV_FILE"
        rmdir "$STATE" 2>/dev/null || true
    elif [[ "$cur" == "$THEME_ID" ]]; then
        "$(kw)" --file kdeglobals --group Sound --key Theme --delete
        echo "Sound theme reset to Plasma default"
    fi
}

install_session() {
    echo "session sounds (Turret) → $UNIT_DIR, $BIN_DIR, $SESSION_SND_DIR"
    local changed=""
    changed+=$(copy_if_changed "$SRC/session/sounds/deploy_2.wav"   "$SESSION_SND_DIR/deploy_2.wav"   644)
    changed+=$(copy_if_changed "$SRC/session/sounds/disabled_4.wav" "$SESSION_SND_DIR/disabled_4.wav" 644)
    changed+=$(copy_if_changed "$SRC/session/sounds/still_there.wav" "$SESSION_SND_DIR/still_there.wav" 644)
    changed+=$(copy_if_changed "$SRC/session/bin/turret-shutdown-watch" "$BIN_DIR/turret-shutdown-watch" 755)
    local u
    for u in "${UNITS[@]}"; do
        changed+=$(copy_if_changed "$SRC/session/systemd/$u" "$UNIT_DIR/$u" 644)
    done
    [[ -z "$changed" ]] && echo "  all files already up to date"
    if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user daemon-reload
        for u in "${UNITS[@]}"; do
            # only enable, NEVER start/stop/restart: stopping turret-sounds.service
            # plays the shutdown sound. New versions take effect at the next login.
            if [[ "$(systemctl --user is-enabled "$u" 2>/dev/null || true)" != enabled ]]; then
                systemctl --user enable "$u"
            fi
            printf '  %-32s %s / %s\n' "$u" "$(systemctl --user is-enabled "$u" 2>/dev/null || true)" \
                "$(systemctl --user is-active "$u" 2>/dev/null || true)"
        done
        if [[ -n "$changed" ]]; then echo "  Note: changed units will be used from the next login."; fi
    else
        echo "  (no systemd user manager reachable – please enable the units later with 'systemctl --user enable ${UNITS[*]}')"
    fi
}

uninstall_session() {
    echo "Removing session sounds"
    if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user disable "${UNITS[@]}" 2>/dev/null || true
        # The watcher can be stopped silently; do NOT stop turret-sounds.service
        # (it would play the shutdown sound) – it ends with the session.
        systemctl --user stop turret-shutdown-watch.service 2>/dev/null || true
    fi
    local u
    for u in "${UNITS[@]}"; do rm -f "$UNIT_DIR/$u"; done
    rm -f "$BIN_DIR/turret-shutdown-watch" "$SESSION_SND_DIR/deploy_2.wav" "$SESSION_SND_DIR/disabled_4.wav" "$SESSION_SND_DIR/still_there.wav"
    rmdir "$SESSION_SND_DIR" 2>/dev/null || true
    command -v systemctl >/dev/null && systemctl --user daemon-reload 2>/dev/null || true
}

if (( uninstall )); then
    if (( do_theme )); then
        restore_theme
        rm -rf "$THEME_DST"
        echo "Sound theme removed: $THEME_DST"
    fi
    (( do_session )) && uninstall_session
    exit 0
fi

(( do_theme )) && install_theme
(( do_session )) && install_session
(( activate && do_theme )) && activate_theme
exit 0
