#!/usr/bin/env bash
# Aperture OS – Distribute design tokens and rebuild all generated files.
#
#   tools/build-all.sh            sync tokens + build everything
#   tools/build-all.sh --install  then run ./install.sh (installs, activates nothing)
#
# Flow: design/tokens.json -> <component>/tokens.json -> <component>/tools/build.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOKENS="$ROOT/design/tokens.json"
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$TOKENS"

COMPONENTS=(colors plasma-style aurorae lockscreen splash wallpaper globaltheme widgets launcher sounds cursors phpstorm kvantum sddm kate plymouth)
for c in "${COMPONENTS[@]}"; do
    [[ -d "$ROOT/$c" ]] || { echo "skipping $c (missing)"; continue; }
    cp "$TOKENS" "$ROOT/$c/tokens.json"
done
echo "tokens.json -> ${#COMPONENTS[@]} components"

build() { [[ -f "$ROOT/$1/tools/build.py" ]] && { echo "build $1"; python3 "$ROOT/$1/tools/build.py" >/dev/null; }; return 0; }
build colors
cp "$ROOT/colors/ApertureOS.colors" "$ROOT/plasma-style/ApertureOS.colors"
build plasma-style
build aurorae
build lockscreen
build splash
"$ROOT/globaltheme/tools/sync-splash.sh" >/dev/null && echo "sync splash -> globaltheme"
build widgets
build launcher
python3 "$ROOT/tools/build-l10n.py"
if python3 -c "import PIL" 2>/dev/null; then build cursors; build plymouth; else echo "skipping cursors, plymouth (Pillow missing)"; fi
build phpstorm
if [[ -d /usr/share/Kvantum/KvFlat ]]; then build kvantum; else echo "skipping kvantum (KvFlat missing)"; fi
build sddm
build kate
python3 "$ROOT/tools/build-dotfiles.py" >/dev/null && echo "build dotfiles"
echo "done."
[[ "${1:-}" == --install ]] && "$ROOT/install.sh"
exit 0
