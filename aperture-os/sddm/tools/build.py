#!/usr/bin/env python3
"""Sync the SDDM theme with the Aperture OS design tokens.

- theme.conf: colour and font keys are rewritten from tokens.json
- assets/fonts: Inter, JetBrains Mono and Barlow Semi Condensed are bundled,
  because SDDM runs as its own user and cannot see ~/.local/share/fonts.
  Main.qml registers them with FontLoader.

Usage: tools/build.py [--fonts DIR]   (default DIR: ~/.local/share/fonts/aperture-os)
"""
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
T = json.loads((ROOT / "tokens.json").read_text())
C, F = T["color"], T["font"]
FONT_SRC = Path(sys.argv[sys.argv.index("--fonts") + 1]) if "--fonts" in sys.argv \
    else Path.home() / ".local/share/fonts/aperture-os"

KEYS = {
    "colorBase": C["background"],
    "colorPanel": C["surface"],
    "colorField": C["background"],
    "colorLine": C["border"],
    "colorText": C["text"],
    "colorMuted": C["textMuted"],
    "colorOrange": C["orange"],
    "colorOrangeBright": C["orangeBright"],
    "colorBlue": C["blue"],
    "colorBlueBright": C["blueBright"],
    "colorError": C["error"],
    "colorButtonText": C["onAccent"],
    "fontFamily": F["ui"],
    "monoFamily": F["mono"],
    "displayFamily": F["display"],
}
FONTS = ["Inter-Regular.ttf", "Inter-Medium.ttf", "Inter-SemiBold.ttf",
         "JetBrainsMono-Regular.ttf", "JetBrainsMono-Bold.ttf",
         "BarlowSemiCondensed-Medium.ttf", "BarlowSemiCondensed-SemiBold.ttf"]


def main():
    conf = ROOT / "theme.conf"
    text = conf.read_text()
    for key, value in KEYS.items():
        if re.search(r"^%s=" % key, text, re.M):
            text = re.sub(r"^%s=.*$" % key, "%s=%s" % (key, value), text, flags=re.M)
        else:  # new key: append after the typography block marker or at the end
            text = text.replace("monoFamily=", "%s=%s\nmonoFamily=" % (key, value), 1) \
                if key == "displayFamily" else text + "%s=%s\n" % (key, value)
    conf.write_text(text)

    dest = ROOT / "assets/fonts"
    dest.mkdir(parents=True, exist_ok=True)
    for name in FONTS:
        src = FONT_SRC / name
        if src.exists():
            shutil.copy2(src, dest / name)
        elif not (dest / name).exists():
            print("warning: font missing:", src, "(run tools/fonts.sh in the main repo)")
    print("theme.conf + assets/fonts synced")


if __name__ == "__main__":
    main()
