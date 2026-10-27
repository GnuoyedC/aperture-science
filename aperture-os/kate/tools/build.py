#!/usr/bin/env python3
"""Build the "Aperture OS" KSyntaxHighlighting theme (Kate, KWrite, KDevelop,
Kate-based editors) from tokens.json.

The syntax palette is the same as the PhpStorm editor scheme (phpstorm/tools/build.py),
so code looks identical in both editors: keywords orange, types/functions blue,
strings green, numbers/constants amber, comments grey. Every syntax colour is lifted
until it reaches >= 4.5:1 contrast on the editor background.

Usage: tools/build.py   -> ../aperture-os.theme
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MIN_CONTRAST = 4.5


# --- colour helpers (identical to phpstorm/tools/build.py) -----------------------------
def rgb(h):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def hexc(c):
    return "#%02X%02X%02X" % tuple(max(0, min(255, round(v))) for v in c)


def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return hexc(tuple(ca[i] + (cb[i] - ca[i]) * t for i in range(3)))


def lum(c):
    def ch(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(c)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def lift(fg, bg, toward, minimum=MIN_CONTRAST):
    t, c = 0.0, fg
    while contrast(c, bg) < minimum and t < 1.0:
        t += 0.02
        c = mix(fg, toward, t)
    return c


# --- tokens -------------------------------------------------------------------------------
tokens = json.loads((ROOT / "tokens.json").read_text())
T = tokens["color"]
BG, SURF, ELEV, HOVER = T["background"], T["surface"], T["surfaceElevated"], T["surfaceHover"]
BORDER, BORDER_S = T["border"], T["borderStrong"]
TEXT, MUTED, DISABLED = T["text"], T["textMuted"], T["textDisabled"]
ORANGE, ORANGE_B, ORANGE_D = T["orange"], T["orangeBright"], T["orangeDim"]
BLUE, BLUE_B, BLUE_D = T["blue"], T["blueBright"], T["blueDim"]
OK, WARN, ERR = T["success"], T["warning"], T["error"]

EDITOR_BG = SURF


def syn(c):
    return lift(c, EDITOR_BG, TEXT)


P = {  # same derivation as PhpStorm
    "fg": TEXT,
    "punct": syn(mix(TEXT, MUTED, 0.45)),
    "keyword": syn(mix(ORANGE, TEXT, 0.12)),
    "keywordSoft": syn(mix(ORANGE_B, TEXT, 0.30)),
    "type": syn(BLUE_B),
    "funcDecl": syn(mix(BLUE, TEXT, 0.15)),
    "funcCall": syn(mix(BLUE_B, TEXT, 0.40)),
    "field": syn(mix(TEXT, BLUE_B, 0.28)),
    "var": syn(mix(TEXT, BLUE_B, 0.10)),
    "param": syn(mix(TEXT, ORANGE_B, 0.32)),
    "string": syn(mix(OK, TEXT, 0.22)),
    "escape": syn(mix(OK, TEXT, 0.55)),
    "number": syn(mix(WARN, TEXT, 0.10)),
    "constant": syn(mix(WARN, ORANGE_B, 0.30)),
    "comment": syn(MUTED),
    "docComment": syn(mix(MUTED, OK, 0.18)),
    "docTag": syn(mix(MUTED, ORANGE_B, 0.45)),
    "metadata": syn(mix(MUTED, BLUE_B, 0.45)),
    "tag": syn(mix(ORANGE_B, TEXT, 0.20)),
    "attr": syn(mix(BLUE_B, TEXT, 0.45)),
    "error": syn(ERR),
    "warning": syn(WARN),
    "info": syn(BLUE_B),
}
SEL = mix(EDITOR_BG, ORANGE, 0.24)          # muted orange selection, text stays readable


def style(color, sel=None, **flags):
    s = {"text-color": color, "selected-text-color": sel or color}
    s.update({k: True for k, v in flags.items() if v})
    return s


TEXT_STYLES = {
    "Normal": style(P["fg"]),
    "Keyword": style(P["keyword"], bold=True),
    "Function": style(P["funcCall"]),
    "Variable": style(P["var"]),
    "ControlFlow": style(P["keyword"], bold=True),
    "Operator": style(P["punct"]),
    "BuiltIn": style(P["keywordSoft"]),
    "Extension": style(P["type"]),
    "Preprocessor": style(P["metadata"]),
    "Attribute": style(P["attr"]),
    "Char": style(P["escape"]),
    "SpecialChar": style(P["escape"]),
    "String": style(P["string"]),
    "VerbatimString": style(P["string"]),
    "SpecialString": style(P["escape"]),
    "Import": style(P["tag"]),
    "DataType": style(P["type"]),
    "DecVal": style(P["number"]),
    "BaseN": style(P["number"]),
    "Float": style(P["number"]),
    "Constant": style(P["constant"]),
    "Comment": style(P["comment"], italic=True),
    "Documentation": style(P["docComment"], italic=True),
    "Annotation": style(P["metadata"]),
    "CommentVar": style(P["docTag"]),
    "RegionMarker": style(P["metadata"]),
    "Information": style(P["info"]),
    "Warning": style(P["warning"]),
    "Alert": style(T["onAccent"], bold=True),
    "Others": style(P["field"]),
    "Error": style(P["error"], underline=True),
}
TEXT_STYLES["RegionMarker"] = {"text-color": P["metadata"], "selected-text-color": P["metadata"],
                               "background-color": mix(EDITOR_BG, BLUE_D, 0.25)}
TEXT_STYLES["Alert"] = {"text-color": T["onAccent"], "selected-text-color": T["onAccent"],
                        "background-color": WARN, "bold": True}

EDITOR = {
    "BackgroundColor": EDITOR_BG,
    "CodeFolding": mix(EDITOR_BG, BLUE_D, 0.30),
    "BracketMatching": mix(EDITOR_BG, BLUE_D, 0.40),
    "CurrentLine": mix(EDITOR_BG, HOVER, 0.55),
    "IconBorder": EDITOR_BG,
    "IndentationLine": mix(EDITOR_BG, BORDER, 0.55),
    "LineNumbers": lift(mix(DISABLED, MUTED, 0.25), EDITOR_BG, MUTED, 3.0),
    "CurrentLineNumber": mix(ORANGE_B, TEXT, 0.35),
    "MarkBookmark": BLUE,
    "MarkBreakpointActive": ERR,
    "MarkBreakpointReached": WARN,
    "MarkBreakpointDisabled": mix(ERR, EDITOR_BG, 0.5),
    "MarkExecution": BLUE_B,
    "MarkWarning": WARN,
    "MarkError": ERR,
    "ModifiedLines": WARN,
    "SavedLines": OK,
    "ReplaceHighlight": mix(EDITOR_BG, OK, 0.30),
    "SearchHighlight": mix(EDITOR_BG, WARN, 0.30),
    "TextSelection": SEL,
    "Separator": BORDER,
    "SpellChecking": ERR,
    "TabMarker": mix(EDITOR_BG, BORDER, 0.80),
    "TemplateBackground": mix(EDITOR_BG, ORANGE_D, 0.10),
    "TemplatePlaceholder": mix(EDITOR_BG, ORANGE_D, 0.30),
    "TemplateFocusedPlaceholder": mix(EDITOR_BG, ORANGE, 0.40),
    "TemplateReadOnlyPlaceholder": mix(EDITOR_BG, HOVER, 1.0),
    "WordWrapMarker": mix(EDITOR_BG, BORDER, 0.60),
}


def main():
    # contrast gate: every foreground on the editor background and on the selection
    for name, st in TEXT_STYLES.items():
        if "background-color" in st:
            continue
        c1 = contrast(st["text-color"], EDITOR_BG)
        c2 = contrast(st["text-color"], SEL)
        if c1 < MIN_CONTRAST or c2 < 3.0:
            raise SystemExit("contrast too low for %s: %.2f / %.2f on selection" % (name, c1, c2))
    theme = {
        "metadata": {
            "name": "Aperture OS",
            "revision": 1,
            "license": "MIT",
            "copyright": ["SPDX-FileCopyrightText: 2026 Quatzler"],
        },
        "text-styles": TEXT_STYLES,
        "editor-colors": EDITOR,
        "custom-styles": {},
    }
    out = ROOT / "aperture-os.theme"
    out.write_text(json.dumps(theme, indent=4) + "\n")
    print("wrote", out)


if __name__ == "__main__":
    main()
