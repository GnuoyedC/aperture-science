#!/usr/bin/env bash
# Aperture OS – Color scheme "ApertureOS"
#   ./install.sh               install
#   ./install.sh --activate    install and activate
#   ./install.sh --uninstall   remove (if active: back to BreezeDark)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
case "${1:-}" in
    ""|--activate)
        mkdir -p "$DEST"
        install -m644 "$HERE/ApertureOS.colors" "$DEST/ApertureOS.colors"
        echo "Color scheme installed: $DEST/ApertureOS.colors"
        if [[ "${1:-}" == --activate ]]; then plasma-apply-colorscheme ApertureOS; fi
        ;;
    --uninstall)
        if [[ "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)" == ApertureOS ]]; then
            plasma-apply-colorscheme BreezeDark || true
        fi
        rm -f "$DEST/ApertureOS.colors"
        echo "Color scheme removed."
        ;;
    *) sed -n '2,5p' "$0"; exit 2 ;;
esac
