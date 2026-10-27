#!/usr/bin/env bash
# Aperture OS – Window decoration (Aurorae) "aperture-os"
#   ./install.sh               install
#   ./install.sh --activate    install and activate (incl. border size "Normal" = 1 px line)
#   ./install.sh --uninstall   remove (if active: back to Breeze)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/aurorae/themes/aperture-os"
GROUP=org.kde.kdecoration2
reload() { qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true; }
case "${1:-}" in
    ""|--activate)
        rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
        cp -r "$HERE/aperture-os" "$DEST"
        echo "Window decoration installed: $DEST"
        if [[ "${1:-}" == --activate ]]; then
            kwriteconfig6 --file kwinrc --group $GROUP --key library org.kde.kwin.aurorae.v2
            kwriteconfig6 --file kwinrc --group $GROUP --key theme __aurorae__svg__aperture-os
            kwriteconfig6 --file kwinrc --group $GROUP --key BorderSize Normal
            kwriteconfig6 --file kwinrc --group $GROUP --key BorderSizeAuto false
            reload
            echo "activated."
        fi
        ;;
    --uninstall)
        if [[ "$(kreadconfig6 --file kwinrc --group $GROUP --key theme)" == __aurorae__svg__aperture-os ]]; then
            kwriteconfig6 --file kwinrc --group $GROUP --key library org.kde.breeze
            kwriteconfig6 --file kwinrc --group $GROUP --key theme Breeze
            reload
        fi
        rm -rf "$DEST"
        echo "Window decoration removed."
        ;;
    *) sed -n '2,5p' "$0"; exit 2 ;;
esac
