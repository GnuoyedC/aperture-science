#!/usr/bin/env bash
# Install the optional Aperture-Dark userChrome/userContent styling into every
# Firefox profile found (regular, Flatpak and Snap installs).
#   ./install-chrome.sh             install
#   ./install-chrome.sh --uninstall remove the files again
# Close Firefox first. Existing userChrome.css / userContent.css are backed up.
set -euo pipefail
cd "$(dirname "$0")"

PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
FILES=(userChrome.css userContent.css aperture-newtab.svg)
ROOTS=("$HOME/.mozilla/firefox" "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox")

found=0
for root in "${ROOTS[@]}"; do
  [ -f "$root/profiles.ini" ] || continue
  while IFS= read -r rel; do
    case "$rel" in /*) prof="$rel" ;; *) prof="$root/$rel" ;; esac
    [ -d "$prof" ] || continue
    found=1
    if [ "${1:-}" = "--uninstall" ]; then
      for f in "${FILES[@]}"; do rm -f "$prof/chrome/$f"; done
      for f in userChrome.css userContent.css; do
        [ -f "$prof/chrome/$f.before-aperture" ] && mv "$prof/chrome/$f.before-aperture" "$prof/chrome/$f"
      done
      echo "Removed from $prof"
      continue
    fi
    mkdir -p "$prof/chrome"
    for f in userChrome.css userContent.css; do
      if [ -f "$prof/chrome/$f" ] && ! grep -q "Aperture-Dark" "$prof/chrome/$f"; then
        cp "$prof/chrome/$f" "$prof/chrome/$f.before-aperture"
      fi
    done
    cp "${FILES[@]/#/chrome/}" "$prof/chrome/"
    grep -qsF "$PREF" "$prof/user.js" || echo "$PREF" >> "$prof/user.js"
    echo "Installed into $prof"
  done < <(sed -n 's/^Path=//p' "$root/profiles.ini")
done

[ "$found" = 1 ] || { echo "No Firefox profiles found. Start Firefox once, then re-run." >&2; exit 1; }
echo "Restart Firefox to see the changes."
