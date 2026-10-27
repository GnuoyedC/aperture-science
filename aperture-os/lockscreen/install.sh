#!/usr/bin/env bash
# Aperture OS – lock screen "Aperture Security System"
#
# In Plasma 6.6 the lock screen belongs to the shell package (no longer to the global theme).
# This repo ships a slim shell package "aperture-os.shell" that contains ONLY the lock
# screen and falls back to org.kde.plasma.desktop for everything else.
#
#   ./install.sh               install the package (does not change the running system)
#   ./install.sh --preview     show the lock screen in test mode (exits after 20 s;
#                              moving the mouse shows the login field)
#   ./install.sh --activate [--now]    switch the shell to aperture-os.shell; the panel configuration
#                                      is shared via symlink (no copy). --now restarts plasmashell.
#   ./install.sh --deactivate [--now]  back to the default shell
#   ./install.sh --uninstall   deactivate + remove the package
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
DEST="$DATA/plasma/shells/aperture-os.shell"
# find_libexec <name>: locate a KDE libexec helper on any distro/arch (Debian/Ubuntu multiarch,
# Fedora /usr/libexec or /usr/lib64/libexec, Arch /usr/lib, ...). Same logic as guard/aperture-plasma-guard.
find_libexec() {
    local name=$1 d m qt p
    local -a dirs=()
    for qt in qtpaths6 qtpaths-qt6 qtpaths; do
        command -v "$qt" >/dev/null 2>&1 || continue
        for p in QT_INSTALL_LIBEXECS QT_INSTALL_LIBS; do
            d="$("$qt" --query "$p" 2>/dev/null)" || continue
            [[ -n "$d" ]] && dirs+=("$d" "$d/libexec" "$(dirname "$d")/libexec")
        done
        break
    done
    if m="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null)" && [[ -n "$m" ]]; then
        dirs+=("/usr/lib/$m/libexec" "/usr/lib/$m")
    fi
    dirs+=(/usr/libexec /usr/lib64/libexec /usr/lib/libexec /usr/lib/kf6 /usr/lib64 /usr/lib)
    for d in "${dirs[@]}"; do
        [[ -x "$d/$name" && ! -d "$d/$name" ]] && { echo "$d/$name"; return 0; }
    done
    d="$(find /usr/lib* /usr/libexec -maxdepth 4 -name "$name" -type f -perm -u+x 2>/dev/null | head -1)"
    [[ -n "$d" ]] && { echo "$d"; return 0; }
    return 1
}
STD_RC="$CFG/plasma-org.kde.plasma.desktop-appletsrc"
APT_RC="$CFG/plasma-aperture-os.shell-appletsrc"

install_files() {
    rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
    cp -r "$HERE/aperture-os.shell" "$DEST"
    echo "Lock screen package installed: $DEST"
}
current() { kreadconfig6 --file plasmashellrc --group Shell --key ShellPackage; }

case "${1:-}" in
    "") install_files ;;
    --preview)
        install_files >/dev/null
        GREETER="$(find_libexec kscreenlocker_greet)" || { echo "kscreenlocker_greet not found" >&2; exit 1; }
        "$GREETER" --testing --shell aperture-os.shell & pid=$!
        sleep 20; kill -9 "$pid" 2>/dev/null || true
        ;;
    --activate)
        install_files
        mkdir -p "$STATE"
        cp -a "$STD_RC" "$STATE/appletsrc-before-lockscreen-$(date +%Y%m%d-%H%M%S)"
        # Share ONE panel configuration between both shell names: KConfig follows
        # symlinks when saving, so panels/widgets can never diverge.
        if [[ -e "$APT_RC" && ! -L "$APT_RC" ]]; then
            mv "$APT_RC" "$STATE/plasma-aperture-os.shell-appletsrc.orphan-$(date +%s)"
        fi
        ln -sfn "$(basename "$STD_RC")" "$APT_RC"
        kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage aperture-os.shell
        if [[ "${2:-}" == --now ]]; then
            systemctl --user restart plasma-plasmashell.service
            echo "Activated, plasmashell restarted."
        else
            echo "Activated. Takes effect after a plasmashell restart or re-login."
        fi
        echo "Undo: ./install.sh --deactivate"
        ;;
    --deactivate)
        if [[ "$(current)" == aperture-os.shell ]]; then
            kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage --delete
            [[ -L "$APT_RC" ]] && rm "$APT_RC"
            if [[ "${2:-}" == --now ]]; then systemctl --user restart plasma-plasmashell.service; fi
            echo "Default shell restored (takes effect after a plasmashell restart / re-login)."
        else
            echo "aperture-os.shell is not active."
        fi
        ;;
    --uninstall)
        "$0" --deactivate
        rm -rf "$DEST"
        echo "Lock screen package removed."
        ;;
    *) sed -n '2,14p' "$0"; exit 2 ;;
esac
