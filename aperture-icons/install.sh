#!/usr/bin/env bash
# Install the Aperture icon theme.
#   ./install.sh               install for the current user (~/.local/share/icons)
#   ./install.sh --system      install for all users (/usr/share/icons, uses sudo)
#   ./install.sh --apply       also switch the running desktop to Aperture
#   ./install.sh --dark        use Aperture-Dark (for dark desktops) instead of Aperture
#   ./install.sh --uninstall   remove it again (combine with --system / --dark as needed)
set -euo pipefail
cd "$(dirname "$0")"

NAME=Aperture
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
APPLY=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --system) DEST=/usr/share/icons ;;
    --dark) NAME=Aperture-Dark ;;
    --apply) APPLY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

SUDO=""
if [ "$DEST" = /usr/share/icons ] && [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
fi

if [ "$UNINSTALL" = 1 ]; then
  $SUDO rm -rf "${DEST:?}/$NAME"
  echo "Removed $DEST/$NAME"
  exit 0
fi

if [ ! -f "$NAME/index.theme" ]; then
  echo "No $NAME/ folder here. Run 'python3 build.py' (or build_dark.py) first." >&2
  exit 1
fi

$SUDO mkdir -p "$DEST"
$SUDO rm -rf "${DEST:?}/$NAME"
$SUDO cp -a "$NAME" "$DEST/"
for cache_tool in gtk-update-icon-cache gtk4-update-icon-cache; do
  if command -v "$cache_tool" >/dev/null 2>&1; then
    $SUDO "$cache_tool" -f -q "$DEST/$NAME" 2>/dev/null && break
  fi
done
echo "Installed to $DEST/$NAME"

apply_kde() {
  for bin in plasma-changeicons /usr/lib/plasma-changeicons /usr/libexec/plasma-changeicons \
             /usr/lib/x86_64-linux-gnu/libexec/plasma-changeicons /usr/lib64/libexec/plasma-changeicons; do
    if command -v "$bin" >/dev/null 2>&1; then
      "$bin" "$NAME"
      return
    fi
  done
  for kw in kwriteconfig6 kwriteconfig5; do
    if command -v "$kw" >/dev/null 2>&1; then
      "$kw" --file kdeglobals --group Icons --key Theme "$NAME"
      echo "Set in kdeglobals; log out and back in to see it everywhere."
      return
    fi
  done
  echo "Pick Aperture in System Settings > Colors & Themes > Icons."
}

if [ "$APPLY" = 1 ]; then
  case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*) apply_kde ;;
    *Cinnamon*) gsettings set org.cinnamon.desktop.interface icon-theme "$NAME" ;;
    *MATE*) gsettings set org.mate.interface icon-theme "$NAME" ;;
    *XFCE*) xfconf-query -c xsettings -p /Net/IconThemeName -s "$NAME" ;;
    *GNOME*|*Unity*|*Budgie*|*Pantheon*|*COSMIC*) gsettings set org.gnome.desktop.interface icon-theme "$NAME" ;;
    *)
      if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface icon-theme "$NAME"
      else
        echo "Unknown desktop '${XDG_CURRENT_DESKTOP:-}'. Select Aperture in your appearance settings."
      fi ;;
  esac
  echo "Applied."
else
  echo "Select it in your desktop's appearance settings, or re-run with --apply."
fi
