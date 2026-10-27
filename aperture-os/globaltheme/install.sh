#!/usr/bin/env bash
# Aperture OS – Global Theme (Look-and-Feel "aperture-os")
#   ./install.sh                 install package + Aperture icon
#   ./install.sh --activate      apply the Global Theme (colors, Plasma Style, windows, splash).
#                                Icons and cursor stay unchanged, as do panels/widgets.
#   ./install.sh --apply-layout  OPTIONAL: apply the Aperture panel layout (replaces the panels!
#                                backs up plasma-org.kde.plasma.desktop-appletsrc first)
#   ./install.sh --restore-layout  restore the latest panel backup
#   ./install.sh --uninstall     remove package + icon (select another Global Theme first)
#
# Requires the other components (colors, plasma-style, aurorae, splash, wallpaper) –
# the main repo script ../install.sh installs everything in the right order.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
DEST="$DATA/plasma/look-and-feel/aperture-os"
ICONS="$DATA/icons/hicolor/scalable/apps"
APPLETSRC="$CFG/plasma-org.kde.plasma.desktop-appletsrc"

install_files() {
    [[ -d "$HERE/../splash/aperture-os.splash" ]] && "$HERE/tools/sync-splash.sh" >/dev/null
    rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")" "$ICONS"
    cp -r "$HERE/aperture-os" "$DEST"
    install -m644 "$HERE"/icons/*.svg "$ICONS/"
    echo "Global Theme installed: $DEST"
}

case "${1:-}" in
    "") install_files ;;
    --activate)
        install_files
        (cd /tmp && plasma-apply-lookandfeel -a aperture-os)
        echo "Global Theme active."
        ;;
    --apply-layout)
        mkdir -p "$STATE"
        bak="$STATE/appletsrc-$(date +%Y%m%d-%H%M%S)"
        cp -a "$APPLETSRC" "$bak"
        cp -a "$CFG/plasmashellrc" "$bak.plasmashellrc" 2>/dev/null || true
        echo "Panel configuration backed up: $bak"
        out="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$HERE/layouts/aperture-panel-layout.js")")"
        echo "$out"
        # "translucent" cannot be set via scripting -> plasmashellrc, takes effect after restarting plasmashell
        for id in $(grep -o 'panel [0-9]*' <<<"$out" | awk '{print $2}'); do
            kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
        done
        echo "Aperture panel applied. Translucent after: systemctl --user restart plasma-plasmashell"
        echo "Undo: ./install.sh --restore-layout"
        ;;
    --restore-layout)
        bak=""   # newest appletsrc backup (without the .plasmashellrc companions)
        for f in "$STATE"/appletsrc-*; do
            [[ -e "$f" && "$f" != *.plasmashellrc ]] || continue
            if [[ -z "$bak" || "$f" -nt "$bak" ]]; then bak="$f"; fi
        done
        [[ -n "$bak" ]] || { echo "no backup found" >&2; exit 1; }
        echo "restoring $bak (plasmashell will be restarted)"
        systemctl --user stop plasma-plasmashell.service
        cp -a "$bak" "$APPLETSRC"
        [[ -e "$bak.plasmashellrc" ]] && cp -a "$bak.plasmashellrc" "$CFG/plasmashellrc"
        systemctl --user start plasma-plasmashell.service
        ;;
    --uninstall)
        if [[ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" == aperture-os ]]; then
            echo "Note: aperture-os is still active – please select another Global Theme in System Settings first." >&2
        fi
        rm -rf "$DEST"
        rm -f "$ICONS/aperture-os.svg" "$ICONS/aperture-os-light.svg"
        echo "Global Theme removed."
        ;;
    *) sed -n '2,12p' "$0"; exit 2 ;;
esac
