#!/usr/bin/env bash
# Aperture OS – Kvantum-Theme "ApertureOS" (transparent Dolphin)
#
#   ./install.sh               install the theme to ~/.config/Kvantum/ApertureOS
#   ./install.sh --activate    select the theme in Kvantum and switch ONLY Dolphin to Kvantum
#                              (all other programs stay on Breeze)
#   ./install.sh --global      Kvantum for ALL Qt/KDE programs (instead of Breeze) – optional
#   ./install.sh --uninstall   remove the Dolphin switch, remove the theme, reset the Kvantum selection
#
# Requirement: sudo apt install qt6-style-kvantum
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
KV="$CFG/Kvantum"
APP="$DATA/applications/org.kde.dolphin.desktop"
SVC="$DATA/dbus-1/services/org.kde.dolphin.FileManager1.service"
MARK="X-Aperture-OS=kvantum"

need_kvantum() {
    ls /usr/lib/*/qt6/plugins/styles/libkvantum.so >/dev/null 2>&1 ||
        { echo "Kvantum missing: sudo apt install qt6-style-kvantum" >&2; exit 1; }
}

install_theme() {
    mkdir -p "$KV"
    rm -rf "$KV/ApertureOS"
    cp -r "$HERE/ApertureOS" "$KV/ApertureOS"
    echo "Kvantum theme installed: $KV/ApertureOS"
}

select_theme() {
    mkdir -p "$STATE"
    if [[ -f "$KV/kvantum.kvconfig" && ! -e "$STATE/kvantum.kvconfig.prev" ]]; then
        cp -a "$KV/kvantum.kvconfig" "$STATE/kvantum.kvconfig.prev"
    fi
    kwriteconfig6 --file "$KV/kvantum.kvconfig" --group General --key theme ApertureOS
}

dolphin_only() {
    # Per-application style: KDE apps read [KDE] widgetStyle from their own config
    # (dolphinrc) before kdeglobals. Works for every way Dolphin is started
    # (launcher, task manager, "show in folder", session restore).
    kwriteconfig6 --file dolphinrc --group KDE --key widgetStyle kvantum
    # remove launcher overrides from older versions of this script
    grep -q "$MARK" "$APP" 2>/dev/null && rm -f "$APP"
    grep -q "$MARK" "$SVC" 2>/dev/null && rm -f "$SVC"
    kbuildsycoca6 >/dev/null 2>&1 || true
    echo "Dolphin will use Kvantum from the next start (please close running Dolphin windows)."
}

undo_dolphin() {
    if [[ "$(kreadconfig6 --file dolphinrc --group KDE --key widgetStyle)" == kvantum ]]; then
        kwriteconfig6 --file dolphinrc --group KDE --key widgetStyle --delete
    fi
    grep -q "$MARK" "$APP" 2>/dev/null && rm -f "$APP"
    grep -q "$MARK" "$SVC" 2>/dev/null && rm -f "$SVC"
    kbuildsycoca6 >/dev/null 2>&1 || true
}

case "${1:-}" in
    "") install_theme ;;
    --activate) need_kvantum; install_theme; select_theme; dolphin_only ;;
    --global)
        need_kvantum; install_theme; select_theme
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
        echo "Kvantum is now the global application style (to revert: System Settings → Application Style → Breeze)."
        ;;
    --uninstall)
        undo_dolphin
        if [[ "$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle)" == kvantum ]]; then
            kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
        fi
        if [[ -e "$STATE/kvantum.kvconfig.prev" ]]; then
            mv "$STATE/kvantum.kvconfig.prev" "$KV/kvantum.kvconfig"
        elif [[ -f "$KV/kvantum.kvconfig" ]]; then
            kwriteconfig6 --file "$KV/kvantum.kvconfig" --group General --key theme --delete
        fi
        rm -rf "$KV/ApertureOS"
        echo "Kvantum theme removed, Dolphin uses Breeze again."
        ;;
    *) sed -n '2,11p' "$0"; exit 2 ;;
esac
