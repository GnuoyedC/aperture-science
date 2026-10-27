#!/usr/bin/env bash
# Aperture OS – install the Plasma update guard
#   ./install.sh               install script + systemd units and enable them
#   ./install.sh --uninstall   remove
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/aperture-os/guard"
BIN="$HOME/.local/bin/aperture-plasma-guard"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
case "${1:-}" in
    "")
        mkdir -p "$DATA" "$(dirname "$BIN")" "$UNITS"
        install -m755 "$HERE/aperture-plasma-guard" "$DATA/aperture-plasma-guard"
        install -m644 "$HERE/baseline.sha256" "$DATA/baseline.sha256"
        ln -sfn "$DATA/aperture-plasma-guard" "$BIN"
        install -m644 "$HERE"/systemd/aperture-plasma-guard.{service,timer} "$UNITS/"
        # systemd .path units cannot use variables and the greeter location differs per
        # distro/arch, so the unit is generated from the template at install time.
        GREETER="$("$DATA/aperture-plasma-guard" --print-greeter)" ||
            { echo "kscreenlocker_greet not found - is kscreenlocker installed?" >&2; exit 1; }
        sed -e '/^# /d' -e "s|@GREETER@|$GREETER|" "$HERE/systemd/aperture-plasma-guard.path.in" > "$UNITS/aperture-plasma-guard.path"
        chmod 644 "$UNITS/aperture-plasma-guard.path"
        systemctl --user daemon-reload
        systemctl --user disable aperture-plasma-guard.service >/dev/null 2>&1 || true
        systemctl --user enable --now aperture-plasma-guard.timer aperture-plasma-guard.path >/dev/null
        echo "Update guard active: runs at every login and after Plasma updates (watching $GREETER)."
        "$BIN" --status || true
        ;;
    --uninstall)
        systemctl --user disable --now aperture-plasma-guard.path aperture-plasma-guard.timer aperture-plasma-guard.service 2>/dev/null || true
        rm -f "$UNITS"/aperture-plasma-guard.{service,path,timer} "$BIN"
        rm -rf "$DATA"
        systemctl --user daemon-reload
        echo "Update guard removed."
        ;;
    *) sed -n '2,4p' "$0"; exit 2 ;;
esac
