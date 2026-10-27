#!/usr/bin/env bash
# Aperture OS – Kate / KWrite editor color scheme "Aperture OS" (KSyntaxHighlighting theme)
#   ./install.sh               install the theme
#   ./install.sh --activate    install and select in Kate + KWrite (restart Kate afterwards)
#   ./install.sh --uninstall   remove, Kate/KWrite back to automatic selection
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/org.kde.syntax-highlighting/themes"
GROUP="KTextEditor Renderer"
case "${1:-}" in
    ""|--activate)
        mkdir -p "$DEST"
        install -m644 "$HERE/aperture-os.theme" "$DEST/aperture-os.theme"
        echo "Kate theme installed: $DEST/aperture-os.theme"
        if [[ "${1:-}" == --activate ]]; then
            for rc in katerc kwriterc; do
                kwriteconfig6 --file "$rc" --group "$GROUP" --key "Auto Color Theme Selection" false
                kwriteconfig6 --file "$rc" --group "$GROUP" --key "Color Theme" "Aperture OS"
            done
            echo "Activated for Kate and KWrite (restart a running Kate once)."
        fi
        ;;
    --uninstall)
        for rc in katerc kwriterc; do
            if [[ "$(kreadconfig6 --file "$rc" --group "$GROUP" --key "Color Theme")" == "Aperture OS" ]]; then
                kwriteconfig6 --file "$rc" --group "$GROUP" --key "Color Theme" --delete
                kwriteconfig6 --file "$rc" --group "$GROUP" --key "Auto Color Theme Selection" --delete
            fi
        done
        rm -f "$DEST/aperture-os.theme"
        echo "Kate theme removed."
        ;;
    *) sed -n '2,5p' "$0"; exit 2 ;;
esac
