#!/usr/bin/env bash
# Regenerate lockscreen/preview.jpg: shows the lock screen in test mode and grabs the active window.
# Needs a running Plasma Wayland session, spectacle and python3-pil. The screenshot shows
# your own user name/avatar - check it before committing.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp --suffix=.png)"
"$HERE/install.sh" --preview >/dev/null 2>&1 &
sleep 6
spectacle -b -n -a -o "$TMP" >/dev/null 2>&1
pkill -f 'kscreenlocker_greet --testing' || true
python3 -I - "$TMP" "$HERE/preview.jpg" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB"); im.thumbnail((1920, 1080)); im.save(sys.argv[2], quality=88)
PY
rm -f "$TMP"; echo "Wrote $HERE/preview.jpg"
