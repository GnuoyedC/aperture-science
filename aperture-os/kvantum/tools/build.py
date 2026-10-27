#!/usr/bin/env python3
"""Build the "ApertureOS" Kvantum theme from tokens.json.

Base: KvFlat (flat, Breeze-like dark theme shipped with Kvantum, GPL).
Every colour in its SVG and kvconfig is remapped onto the Aperture palette:
  neutral greys  -> background / surface / border / text tokens (by lightness)
  blue accents   -> orange family (orange = interaction / focus / selection)
Translucency: window background at alpha.window (+ KWin blur), Dolphin's view
transparent, menus nearly opaque. Text always stays fully opaque.

Usage: tools/build.py [--base /usr/share/Kvantum/KvFlat]
Output: ../ApertureOS/{ApertureOS.kvconfig, ApertureOS.svg}
"""
import colorsys
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
T = json.loads((ROOT / "tokens.json").read_text())
C, A = T["color"], T["alpha"]
BASE = Path(sys.argv[sys.argv.index("--base") + 1]) if "--base" in sys.argv else Path("/usr/share/Kvantum/KvFlat")
OUT = ROOT / "ApertureOS"

NAMED = {"white": "#ffffff", "black": "#000000"}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def remap(hexcol):
    """Map one source colour onto the Aperture palette."""
    r, g, b = rgb(hexcol)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if s > 0.35 and 0.45 < h < 0.75:          # blue accent -> orange family
        if l > 0.62:
            return C["orangeBright"]
        if l > 0.42:
            return C["orange"]
        return C["orangeDim"]
    if s > 0.35 and (h < 0.05 or h > 0.92):   # red stays red
        return C["error"]
    v = max(r, g, b) * 255                    # neutral grey ladder
    for limit, token in ((0x22, "background"), (0x30, "surface"), (0x3e, "surfaceElevated"),
                         (0x4f, "surfaceHover"), (0x66, "border"), (0x7f, "borderStrong"),
                         (0xb0, "textMuted")):
        if v <= limit:
            return C[token]
    return C["text"]


SELECTION = "#4A2D14"         # orange tinted selection: calm for all-day use, text stays light (10:1)
SELECTION_PRESSED = "#5C3815"


def recolor(text):
    text = re.sub(r"#[0-9a-fA-F]{6}\b", lambda m: remap(m.group(0)), text)

    # Item views (Dolphin files, places, lists): tinted selection + orange signal bar
    # on the left, like the Plasma Style - instead of a solid orange block.
    def item(m):
        el, state, part = m.group(0), m.group(1), m.group(2) or ""
        if part in ("-left", "-topleft", "-bottomleft"):
            col = C["orange"]
        else:
            col = SELECTION if state == "toggled" else SELECTION_PRESSED
        return re.sub(r"fill:#[0-9A-Fa-f]{6}", "fill:" + col, el)

    return re.sub(r'<[a-z]+[^>]*id="(?:itemview|menuitem)-(toggled|pressed)(-[a-z]+)?"[^>]*>', item, text)


GENERAL = {
    "author": "Quatzler (based on KvFlat by Tsu Jan)",
    "comment": "Aperture OS - tinted safety glass, flat, orange focus",
    "composite": "true",
    "translucent_windows": "true",
    "blurring": "true",
    "popup_blurring": "true",
    "reduce_window_opacity": str(round((1 - A["window"]) * 100)),
    "reduce_menu_opacity": str(round((1 - A["menu"]) * 100)),
    "menu_blur_radius": "2",
    "tooltip_blur_radius": "2",
    "menu_shadow_depth": "4",
    "tooltip_shadow_depth": "4",
    "animate_states": "true",
    "no_inactiveness": "true",
    "dark_titlebar": "true",
    # keep heavy media / IDE windows opaque even if someone runs them with Kvantum
    "opaque": "kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,smplayer,dragon,digikam,"
              "VirtualBox,VirtualBoxVM,QtCreator,krita,obs",
}

COLORS = {
    "window.color": C["surface"],
    "base.color": C["background"],
    "alt.base.color": C["surface"],
    "button.color": C["surfaceElevated"],
    "light.color": C["surfaceHover"],
    "mid.light.color": C["surfaceElevated"],
    "dark.color": C["background"],
    "mid.color": C["border"],
    "highlight.color": C["orange"],
    "inactive.highlight.color": C["orangeDim"],
    "text.color": C["text"],
    "window.text.color": C["text"],
    "button.text.color": C["text"],
    "disabled.text.color": C["textDisabled"],
    "tooltip.text.color": C["text"],
    "highlight.text.color": C["onAccent"],
    "link.color": C["blue"],
    "link.visited.color": C["blueBright"],
    "progress.indicator.text.color": C["onAccent"],
}

HACKS = {
    "respect_darkness": "true",
    "transparent_ktitle_label": "true",
    "transparent_dolphin_view": "true",
    "blur_translucent": "true",
    "transparent_menutitle": "true",
    "kcapacitybar_as_progressbar": "true",
    "iconless_pushbutton": "false",
    "tint_on_mouseover": "0",
}


def build_kvconfig(src):
    sections, order, cur = {}, [], None
    for line in src.splitlines():
        m = re.match(r"^\[(.+)\]\s*$", line)
        if m:
            cur = m.group(1)
            order.append(cur)
            sections[cur] = []
        elif cur is not None and line.strip():
            sections[cur].append(line)

    def kv(lines):
        d = {}
        for ln in lines:
            if "=" in ln:
                k, v = ln.split("=", 1)
                d[k.strip()] = v.strip()
        return d

    out = ["# Generated by kvantum/tools/build.py from tokens.json - do not edit by hand."]
    for name in order:
        d = kv(sections[name])
        if name == "%General":
            d.update(GENERAL)
        elif name == "GeneralColors":
            d = dict(COLORS)
        elif name == "Hacks":
            d.update(HACKS)
        else:
            for k, v in list(d.items()):
                if k.endswith(".color") and k != "text.shadow.color":
                    v = NAMED.get(v.lower(), v)
                    if re.fullmatch(r"#[0-9a-fA-F]{6}", v):
                        d[k] = remap(v)
            # focused text in item views / menus sits on orange -> dark text
            if name in ("ItemView", "MenuItem", "MenuBarItem"):
                # selection / hover is a dark orange tint -> light text (>= 10:1)
                for state in ("focus", "toggle", "press"):
                    d["text.%s.color" % state] = C["text"]
        out.append("")
        out.append("[%s]" % name)
        out += ["%s=%s" % kv_ for kv_ in d.items()]
    return "\n".join(out) + "\n"


def main():
    svg = (BASE / (BASE.name + ".svg")).read_text()
    cfg = (BASE / (BASE.name + ".kvconfig")).read_text()
    OUT.mkdir(exist_ok=True)
    (OUT / "ApertureOS.svg").write_text(
        "<!-- Generated by kvantum/tools/build.py from KvFlat + tokens.json -->\n" + recolor(svg)
        if not svg.startswith("<?xml") else recolor(svg))
    (OUT / "ApertureOS.kvconfig").write_text(build_kvconfig(cfg))
    print("built", OUT)


if __name__ == "__main__":
    main()
