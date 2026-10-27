#!/usr/bin/env bash
# Aperture OS – Plymouth boot screen "aperture-os" (system-wide, needs sudo)
#   sudo ./install.sh               install only (/usr/share/plymouth/themes/aperture-os)
#   sudo ./install.sh --test        test on a text console (TTY) without activating
#   sudo ./install.sh --activate    install, activate, rebuild the initramfs
#   sudo ./install.sh --deactivate  restore the previous theme, rebuild the initramfs
#   sudo ./install.sh --uninstall   deactivate (if active) and remove the theme
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME=aperture-os
THEMES=/usr/share/plymouth/themes
DEST="$THEMES/$NAME"
CONF=/etc/plymouth/plymouthd.conf
STATE=/var/lib/aperture-os/plymouth
# Plugin dir: ask plymouth; fall back to the Debian multiarch dir, then to a search (Fedora/Arch: /usr/lib[64]/plymouth)
PLUGIN_DIR="$(plymouth --get-splash-plugin-path 2>/dev/null || true)"
if [[ -z "$PLUGIN_DIR" || ! -f "$PLUGIN_DIR/script.so" ]]; then
    _m="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || true)"
    for _d in ${_m:+/usr/lib/$_m/plymouth} /usr/lib64/plymouth /usr/lib/plymouth /usr/libexec/plymouth; do
        [[ -f "$_d/script.so" ]] && { PLUGIN_DIR="$_d"; break; }
    done
    [[ -n "$PLUGIN_DIR" && -f "$PLUGIN_DIR/script.so" ]] ||
        PLUGIN_DIR="$(dirname "$(find /usr/lib* -maxdepth 4 -name script.so -path '*plymouth*' 2>/dev/null | head -1)")"
fi

die() { echo "Error: $*" >&2; exit 1; }
need_root() { [[ $EUID -eq 0 ]] || die "please run with sudo"; }
conf_theme() { sed -n 's/^Theme *= *//p' "$CONF" 2>/dev/null | head -1; }
alt_value() { update-alternatives --query default.plymouth 2>/dev/null | sed -n 's/^Value: //p'; }
alt_status() { update-alternatives --query default.plymouth 2>/dev/null | sed -n 's/^Status: //p'; }

set_conf_theme() {
    if grep -q '^Theme *=' "$CONF" 2>/dev/null; then
        sed -i "s|^Theme *=.*|Theme=$1|" "$CONF"
    elif grep -q '^\[Daemon\]' "$CONF" 2>/dev/null; then
        sed -i "/^\[Daemon\]/a Theme=$1" "$CONF"
    else
        printf '[Daemon]\nTheme=%s\n' "$1" >> "$CONF"
    fi
}

install_files() {
    [[ -f "$PLUGIN_DIR/script.so" ]] || die "Plymouth plugin script.so missing ($PLUGIN_DIR)"
    grep -q SetDisplayPasswordFunction "$HERE/$NAME/$NAME.script" || die "Script has no password prompt support - aborted"
    rm -rf "$DEST"
    install -d -m 755 "$DEST"
    install -m 644 "$HERE/$NAME/"*.png "$HERE/$NAME/$NAME.script" "$HERE/$NAME/$NAME.plymouth" "$DEST/"
    rm -f "$DEST"/preview*.png
    echo "installed: $DEST"
}

# Only initramfs-tools (Debian/Ubuntu) is supported automatically. Dracut (Fedora/Arch/openSUSE) and
# mkinitcpio (Arch) are detected and reported; the rebuild command is printed instead of guessed.
rebuild_initramfs() {
    if command -v update-initramfs >/dev/null 2>&1; then
        echo "rebuilding initramfs (update-initramfs -u, newest kernel) ..."
        update-initramfs -u
        echo "Older kernels keep their previous initramfs (fallback via GRUB -> Advanced options)."
    elif command -v dracut >/dev/null 2>&1; then
        echo "WARNING: dracut system - not rebuilt automatically. Run: sudo dracut --force   (needs the dracut plymouth module)"
    elif command -v mkinitcpio >/dev/null 2>&1; then
        echo "WARNING: mkinitcpio system - not rebuilt automatically. Add the 'plymouth' hook, then run: sudo mkinitcpio -P"
    else
        echo "WARNING: no known initramfs tool found - rebuild the initramfs manually."
    fi
}

activate() {
    install -d -m 755 "$STATE"
    # first activation: back up the original state (never overwritten)
    if [[ ! -f "$STATE/plymouthd.conf.orig" ]]; then
        if [[ -f "$CONF" ]]; then cp -a "$CONF" "$STATE/plymouthd.conf.orig"; else : > "$STATE/plymouthd.conf.orig"; fi
        printf '%s\n%s\n' "$(alt_status)" "$(alt_value)" > "$STATE/alternative.orig"
        echo "backed up: $STATE (previous theme: $(conf_theme), default.plymouth: $(alt_value))"
    fi
    update-alternatives --install "$THEMES/default.plymouth" default.plymouth "$DEST/$NAME.plymouth" 100
    update-alternatives --set default.plymouth "$DEST/$NAME.plymouth"
    install -d -m 755 "$(dirname "$CONF")"
    set_conf_theme "$NAME"
    rebuild_initramfs
    echo "active. Boot emergency: press 'e' in GRUB and remove 'splash' from the linux line."
}

deactivate() {
    local status value
    if [[ -f "$STATE/plymouthd.conf.orig" ]]; then
        if [[ -s "$STATE/plymouthd.conf.orig" ]]; then cp -a "$STATE/plymouthd.conf.orig" "$CONF"; else rm -f "$CONF"; fi
        status="$(sed -n 1p "$STATE/alternative.orig")"; value="$(sed -n 2p "$STATE/alternative.orig")"
        if [[ "$status" == manual && -n "$value" && -f "$value" ]]; then
            update-alternatives --set default.plymouth "$value"
        else
            update-alternatives --auto default.plymouth
        fi
    else
        echo "no backup found - setting default.plymouth to automatic"
        if [[ "$(conf_theme)" == "$NAME" ]]; then sed -i '/^Theme *=/d' "$CONF"; fi
        update-alternatives --auto default.plymouth
    fi
    update-alternatives --remove default.plymouth "$DEST/$NAME.plymouth" 2>/dev/null || true
    rebuild_initramfs
    echo "deactivated. Theme now: $(conf_theme) / default.plymouth: $(alt_value)"
}

run_test() {
    # sudo-rs always runs in its own pty, so `tty` is useless: read the active console from sysfs
    # and abort if a graphical session runs on it
    local vt t s
    vt="$(cat /sys/class/tty/tty0/active 2>/dev/null || true)"
    [[ "$vt" =~ ^tty[0-9]+$ ]] || die "cannot determine the active console"
    t="/dev/$vt"
    for s in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
        if [[ "$(loginctl show-session "$s" -p VTNr --value)" == "${vt#tty}" ]] &&
           [[ "$(loginctl show-session "$s" -p Type --value)" =~ ^(wayland|x11|mir)$ ]]; then
            die "only on a text console (Ctrl+Alt+F3, log in, then sudo $0 --test) - $vt is the graphical session"
        fi
    done
    if plymouth --ping 2>/dev/null; then die "plymouthd is already running"; fi
    install_files
    # debug aid only in the installed copy; --activate / ./install.sh install without it again
    sed -i 's/^global.debug = 0;/global.debug = 1;/' "$DEST/$NAME.script"
    # set the theme in plymouthd.conf for the test only, then restore the original file
    local backup; backup="$(mktemp)"
    if [[ -f "$CONF" ]]; then cp -a "$CONF" "$backup"; else rm -f "$backup"; fi
    trap 'plymouth quit 2>/dev/null || true; if [[ -f "'"$backup"'" ]]; then cp -a "'"$backup"'" "'"$CONF"'"; rm -f "'"$backup"'"; else rm -f "'"$CONF"'"; fi' EXIT
    set_conf_theme "$NAME"
    local log=/var/log/aperture-plymouth-test.log
    rm -f "$log"
    plymouthd --mode=boot --tty="$t" --debug --debug-file="$log"
    plymouth show-splash
    for p in 0.1 0.3 0.5; do plymouth update --status="test-$p"; sleep 1.5; done
    plymouth display-message --text="Aperture OS test message"
    sleep 2
    echo "Password field: type any text (discarded), Enter."
    plymouth ask-for-password --prompt="Please unlock disk test:" --command=/bin/true || true
    plymouth display-message --text="cryptsetup: ERROR: test: cryptsetup failed, bad password or options?"
    sleep 2
    plymouth hide-message --text="cryptsetup: ERROR: test: cryptsetup failed, bad password or options?"
    sleep 3
    plymouth quit
    sleep 1
    echo "Test finished. Back to the session: Ctrl+Alt+F1 or F2."
    echo "Script messages (empty = no errors):"
    grep -iE "script|error" "$log" | grep -viE "debug output|loading|ply-boot-splash" | tail -20 || true
    echo "full log: $log"
    install_files >/dev/null   # again without the debug aid
}

case "${1:-}" in
    "") need_root; install_files ;;
    --activate) need_root; install_files; activate ;;
    --deactivate) need_root; deactivate ;;
    --test) need_root; run_test ;;
    --uninstall)
        need_root
        if [[ "$(alt_value)" == "$DEST/$NAME.plymouth" || "$(conf_theme)" == "$NAME" ]]; then deactivate; fi
        rm -rf "$DEST"
        echo "removed: $DEST"
        ;;
    *) sed -n '2,7p' "$0"; exit 2 ;;
esac
