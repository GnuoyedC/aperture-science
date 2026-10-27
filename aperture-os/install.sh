#!/usr/bin/env bash
# Aperture OS – Full installation (main repo)
#
#   ./install.sh                    install all components (nothing is activated)
#   ./install.sh --activate         install + activate Aperture OS (backs up the configuration first)
#   ./install.sh --activate --fonts additionally set Inter / JetBrains Mono as KDE fonts
#   ./install.sh --rollback [DIR]   restore a saved KDE configuration (default: latest backup)
#   ./install.sh --uninstall        remove all components and reset to Breeze/default
#
# Options when installing:
#   --no-dotfiles   do not link kitty / starship / fastfetch
#   --no-phpstorm   do not install the PhpStorm plugin
#   --no-session    do not touch the Turret login/shutdown sounds
#
# What does NOT happen: icons and the active cursor stay (Aperture cursor: cursors/install.sh --activate),
# panels and widgets stay. Kvantum is only used for Dolphin.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
CONFIGS=(kdeglobals kwinrc plasmarc ksplashrc kscreenlockerrc breezerc kcminputrc plasmashellrc
         plasma-org.kde.plasma.desktop-appletsrc)

ACTIVATE=0 FONTS=0 DOTFILES=1 PHPSTORM=1 SESSION=1 MODE=install ROLLBACK_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --activate) ACTIVATE=1 ;;
        --fonts) FONTS=1 ;;
        --no-dotfiles) DOTFILES=0 ;;
        --no-phpstorm) PHPSTORM=0 ;;
        --no-session) SESSION=0 ;;
        --uninstall) MODE=uninstall ;;
        --rollback) MODE=rollback; [[ -n "${2:-}" && "${2:-}" != --* ]] && { ROLLBACK_DIR="$2"; shift; } ;;
        -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

step() { printf '\n\033[38;2;255;120;0m◉\033[0m %s\n' "$*"; }
need() { [[ -x "$ROOT/$1/install.sh" ]] || { echo "Component missing: $1" >&2; return 1; }; }
run() { local c=$1; shift; need "$c" && (cd "$ROOT/$c" && ./install.sh "$@"); }

backup() {
    local dir
    dir="$STATE/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dir"
    for f in "${CONFIGS[@]}"; do [[ -e "$CFG/$f" ]] && cp -a "$CFG/$f" "$dir/"; done
    echo "Configuration backed up: $dir"
}

rollback() {
    local dir="${ROLLBACK_DIR:-$(ls -1dt "$STATE"/backup-* 2>/dev/null | head -1)}"
    [[ -d "$dir" ]] || { echo "No backup found." >&2; exit 1; }
    step "Rollback from $dir"
    systemctl --user stop plasma-plasmashell.service || true
    for f in "${CONFIGS[@]}"; do
        if [[ -e "$dir/$f" ]]; then cp -a "$dir/$f" "$CFG/$f"; echo "  $f"; fi
    done
    systemctl --user start plasma-plasmashell.service
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    echo "Done. Log out and back in once for a complete result."
}

install_all() {
    step "Installing components"
    run colors
    run plasma-style
    run aurorae
    run splash
    run lockscreen
    run wallpaper
    run globaltheme
    run widgets
    run launcher
    if [[ $SESSION == 1 ]]; then run sounds; else run sounds --no-session; fi
    run cursors
    run kvantum
    run kate
    run guard                                      # Plasma update guard (lock/logout screen)
    if [[ $PHPSTORM == 1 ]]; then run phpstorm; fi
    if [[ $DOTFILES == 1 ]]; then (cd "$ROOT/dotfiles" && ./install.sh); fi
    step "Fonts (Inter, JetBrains Mono)"
    "$ROOT/tools/fonts.sh"
}

activate() {
    backup
    step "Activating Aperture OS"
    run globaltheme --activate
    run wallpaper --activate
    run sounds --activate --no-session
    run lockscreen --activate                      # takes effect after re-login
    run kate --activate
    if ls /usr/lib/*/qt6/plugins/styles/libkvantum.so >/dev/null 2>&1; then
        run kvantum --activate                     # transparent Dolphin (Dolphin only)
    else
        echo "Kvantum not installed – Dolphin stays Breeze (sudo apt install qt6-style-kvantum)."
    fi
    kwriteconfig6 --file breezerc --group Style --key MenuOpacity 92   # slightly transparent context menus
    # KWin blur: turns the transparent surfaces into "tinted glass" (panel, popups, kitty, Dolphin)
    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
    kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 6
    kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 2
    dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:2 int32:0 || true
    if [[ $FONTS == 1 ]]; then "$ROOT/tools/fonts.sh" --apply; fi
    dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:1 int32:0 || true
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    step "Done"
    echo "Icons, cursor, panels and widgets are unchanged."
    echo "Lock screen and fonts only take full effect after logging in again."
    echo "Optional: globaltheme/install.sh --apply-layout · wallpaper/install.sh --animated ·"
    echo "          cursors/install.sh --activate"
}

uninstall_all() {
    backup
    step "Removing Aperture OS"
    (cd /tmp && plasma-apply-lookandfeel -a org.kde.breezedark.desktop) || true
    run lockscreen --uninstall || true
    for c in guard kate kvantum globaltheme wallpaper splash aurorae plasma-style colors launcher widgets cursors; do run "$c" --uninstall || true; done
    if [[ $SESSION == 1 ]]; then run sounds --uninstall --no-session || true; fi
    run phpstorm --uninstall || true
    (cd "$ROOT/dotfiles" && ./install.sh --uninstall) || true
    "$ROOT/tools/fonts.sh" --uninstall || true
    kwriteconfig6 --file breezerc --group Style --key MenuOpacity --delete
    echo
    echo "Removed. Icons/cursor were never changed. The Turret sounds stay active"
    echo "(remove: sounds/install.sh --uninstall). Previous settings: ./install.sh --rollback"
}

case $MODE in
    install)
        install_all
        if [[ $ACTIVATE == 1 ]]; then activate; else echo -e "\nInstalled. Activate: ./install.sh --activate"; fi ;;
    rollback) rollback ;;
    uninstall) uninstall_all ;;
esac
