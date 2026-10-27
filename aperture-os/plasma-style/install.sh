#!/usr/bin/env bash
# Aperture OS – Plasma Style "aperture-os" (Panel, Popups, Widgets, Tooltips, Task bar)
#   ./install.sh               install
#   ./install.sh --activate    install and activate
#   ./install.sh --uninstall   remove (if active: back to Breeze "default")
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme/aperture-os"
case "${1:-}" in
    ""|--activate)
        rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
        cp -r "$HERE/aperture-os" "$DEST"
        echo "Plasma Style installed: $DEST"
        if [[ "${1:-}" == --activate ]]; then plasma-apply-desktoptheme aperture-os; fi
        ;;
    --uninstall)
        if [[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" == aperture-os ]]; then
            plasma-apply-desktoptheme default || true
        fi
        rm -rf "$DEST"
        echo "Plasma Style removed."
        ;;
    *) sed -n '2,5p' "$0"; exit 2 ;;
esac
