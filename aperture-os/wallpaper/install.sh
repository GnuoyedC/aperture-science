#!/usr/bin/env bash
# Aperture OS - Wallpaper
#   ./install.sh                 install image wallpapers + animated plugin
#   ./install.sh --activate      set the test chamber as image on all desktops + lock screen
#   ./install.sh --animated [motif]  set the animated plugin "aperture-os.chamber" on all desktops
#                                (motif: chamber|core|research|laboratories|portals|overgrown)
#   ./install.sh --lockscreen [motif]  set the lock screen background (default: laboratories)
#   ./install.sh --toggle        animation of the animated wallpaper on/off (image stays)
#   ./install.sh --static        back to the static image wallpaper
#   ./install.sh --frame N ZOOM X Y [mirror]  image crop for Plasma screen N (animated plugin)
#   ./install.sh --uninstall     remove files (switch the active wallpaper first); also removes the old German package IDs
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
IMG="$DATA/wallpapers/ApertureTestChamber"
URL="file://$IMG/"
# Image wallpaper packages: default (ApertureTestChamber) + alternatives
PACKAGES=(ApertureTestChamber ApertureCoreMaintenanceHall ApertureResearchComplex ApertureLaboratories AperturePortalChamber ApertureOvergrown)
LAPTOP_SCREEN=1   # Plasma screen of the laptop (as with --laptop)
# Package IDs from before the English rename; removed on --uninstall and on install (migration)
OLD_PACKAGES=(ApertureKernwartungshalle ApertureForschungskomplex ApertureLaboratorien ApertureTestkammerPortale ApertureVerwuchert)
# motif_id <short-name> -> package/scene ID
motif_id() {
    case "$1" in
        chamber) echo chamber ;;
        core) echo ApertureCoreMaintenanceHall ;;
        research) echo ApertureResearchComplex ;;
        laboratories) echo ApertureLaboratories ;;
        portals) echo AperturePortalChamber ;;
        overgrown) echo ApertureOvergrown ;;
        *) echo "Unknown motif: $1 (chamber|core|research|laboratories|portals|overgrown)" >&2; return 1 ;;
    esac
}
set_lockscreen() { # set_lockscreen <package-id>
    local url="file://$DATA/wallpapers/$1/"
    local G=(--file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General)
    kwriteconfig6 "${G[@]}" --key Image "$url"
    kwriteconfig6 "${G[@]}" --key PreviewImage "$url"
}
install_files() {
    local pkg
    mkdir -p "$DATA/wallpapers"
    for pkg in "${OLD_PACKAGES[@]}"; do rm -rf "$DATA/wallpapers/$pkg"; done
    for pkg in "${PACKAGES[@]}"; do
        rm -rf "$DATA/wallpapers/$pkg"; cp -r "$HERE/$pkg" "$DATA/wallpapers/$pkg"
    done
    if kpackagetool6 -t Plasma/Wallpaper -s aperture-os.chamber >/dev/null 2>&1; then
        kpackagetool6 -t Plasma/Wallpaper -u "$HERE/aperture-os.chamber" >/dev/null
    else
        kpackagetool6 -t Plasma/Wallpaper -i "$HERE/aperture-os.chamber" >/dev/null
    fi
    echo "Wallpaper installed: ${#PACKAGES[@]} image packages in $DATA/wallpapers + plugin aperture-os.chamber"
}
set_plugin() { # set_plugin <plugin> <js config lines>
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
for (const d of desktops()) { d.wallpaperPlugin = '$1'; d.currentConfigGroup = ['Wallpaper', '$1', 'General']; $2 }"
}
case "${1:-}" in
    "") install_files ;;
    --activate)
        install_files
        set_plugin org.kde.image "d.writeConfig('Image', '$URL');"
        G=(--file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General)
        kwriteconfig6 "${G[@]}" --key Image "$URL"
        kwriteconfig6 "${G[@]}" --key PreviewImage "$URL"
        echo "Test chamber set as desktop and lock screen background."
        ;;
    --lockscreen)
        pkg="$(motif_id "${2:-laboratories}")" || exit 2
        [[ "$pkg" != chamber ]] || pkg=ApertureTestChamber
        install_files
        set_lockscreen "$pkg"
        echo "Lock screen background: $pkg"
        ;;
    --setup)
        install_files
        main="$(motif_id chamber)"; laptop="$(motif_id portals)"
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
for (const d of desktops()) {
  const scene = d.screen === $LAPTOP_SCREEN ? '$laptop' : '$main';
  d.wallpaperPlugin = 'aperture-os.chamber';
  d.currentConfigGroup = ['Wallpaper', 'aperture-os.chamber', 'General'];
  d.writeConfig('Scene', scene); d.writeConfig('Image', '');
  d.writeConfig('Zoom', 1); d.writeConfig('FocusX', 0.5); d.writeConfig('FocusY', 0.5); d.writeConfig('Mirror', false);
}"
        set_lockscreen ApertureLaboratories
        echo "Main screen: test chamber · screen $LAPTOP_SCREEN (laptop): portal chamber · lock screen: laboratories"
        ;;
    --animated)
        install_files
        scene="$(motif_id "${2:-chamber}")" || exit 2
        set_plugin aperture-os.chamber "d.writeConfig('Scene', '$scene'); d.writeConfig('Image', '');"
        echo "Animated wallpaper active ($scene) (settings: right-click → Configure Desktop and Wallpaper)."
        ;;
    --static)
        set_plugin org.kde.image "d.writeConfig('Image', '$URL');"
        echo "Static test chamber wallpaper active."
        ;;
    --toggle)
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
let state = null;
for (const d of desktops()) {
  if (d.wallpaperPlugin !== 'aperture-os.chamber') continue;
  d.currentConfigGroup = ['Wallpaper', 'aperture-os.chamber', 'General'];
  if (state === null) state = !(d.readConfig('Animate', true) === true || d.readConfig('Animate', true) === 'true');
  d.writeConfig('Animate', state);
}
print(state === null ? 'Animated wallpaper is not active (run ./install.sh --animated first)'
                     : 'Animation ' + (state ? 'ON' : 'OFF'));"
        echo
        ;;
    --laptop) exec "$0" --frame 1 1.25 0.0 0.45 ;;
    --frame)
        [[ $# -ge 5 ]] || { sed -n "2,14p" "$0"; exit 2; }
        mirror=false
        if [[ "${6:-}" == mirror ]]; then mirror=true; fi
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
let done = false;
for (const d of desktops()) {
  if (d.screen !== $2 || d.wallpaperPlugin !== 'aperture-os.chamber') continue;
  d.currentConfigGroup = ['Wallpaper', 'aperture-os.chamber', 'General'];
  d.writeConfig('Zoom', $3); d.writeConfig('FocusX', $4); d.writeConfig('FocusY', $5);
  d.writeConfig('Mirror', $mirror);
  done = true;
}
print(done ? 'Screen $2: zoom $3, crop $4/$5, mirrored $mirror'
           : 'Screen $2 has no animated Aperture wallpaper (run ./install.sh --animated first)');"
        echo
        ;;
    --uninstall)
        kpackagetool6 -t Plasma/Wallpaper -r aperture-os.chamber >/dev/null 2>&1 || true
        for pkg in "${PACKAGES[@]}" "${OLD_PACKAGES[@]}"; do rm -rf "$DATA/wallpapers/$pkg"; done
        echo "Wallpaper removed."
        ;;
    *) sed -n "2,14p" "$0"; exit 2 ;;
esac
