#!/usr/bin/env python3
"""Aperture OS - PhpStorm theme builder.

Reads ../tokens.json (and nothing else) and generates:
  resources/aperture-os.theme.json   UI theme (parent: "Islands Dark")
  resources/ApertureOS.icls          editor color scheme (parent: Darcula)
  resources/META-INF/plugin.xml      plugin descriptor
  dist/aperture-os-theme.jar         installable plugin (plain zip)

Python standard library only. Every colour is a token or a mix of tokens.
The build fails if a syntax colour drops below WCAG 4.5:1 on the editor
background (colours are lifted towards `text` automatically first).
"""
from __future__ import annotations

import json
import sys
import zipfile
from pathlib import Path
from xml.dom import minidom
from xml.sax.saxutils import quoteattr

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "resources"
DIST = ROOT / "dist"

THEME_NAME = "Aperture OS"
SCHEME_NAME = "Aperture OS"
PLUGIN_ID = "aperture-os.phpstorm-theme"
THEME_ID = "aperture-os.islands-dark"
SCHEME_ID = "aperture-os.scheme"
# Paths *inside the jar* (jar root == resources/). The IDE appends ".xml"
# to bundledColorScheme paths, so the .icls is packed as ApertureOS.xml.
JAR_SCHEME_BASE = "ApertureOS"
JAR_THEME_PATH = "aperture-os.theme.json"

MIN_CONTRAST = 4.5

# --------------------------------------------------------------------------
# colour helpers
# --------------------------------------------------------------------------


def rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def hexc(c: tuple[int, int, int]) -> str:
    return "#%02X%02X%02X" % tuple(max(0, min(255, round(v))) for v in c)


def mix(a: str, b: str, t: float) -> str:
    """t=0 -> a, t=1 -> b"""
    ca, cb = rgb(a), rgb(b)
    return hexc(tuple(ca[i] + (cb[i] - ca[i]) * t for i in range(3)))


def alpha(c: str, a: float) -> str:
    return "#%s%02X" % (c.lstrip("#")[:6].upper(), round(a * 255))


def lum(c: str) -> float:
    def ch(v: int) -> float:
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = rgb(c)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a: str, b: str) -> float:
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def lift(fg: str, bg: str, toward: str, minimum: float = MIN_CONTRAST) -> str:
    """Mix fg towards `toward` until contrast(fg, bg) >= minimum."""
    t = 0.0
    c = fg
    while contrast(c, bg) < minimum and t < 1.0:
        t += 0.02
        c = mix(fg, toward, t)
    return c


def x(c: str) -> str:
    """icls colour format: RRGGBB without '#'"""
    return c.lstrip("#")[:6].upper()


# --------------------------------------------------------------------------
# tokens
# --------------------------------------------------------------------------

tokens = json.loads((ROOT / "tokens.json").read_text(encoding="utf-8"))
T = tokens["color"]
G = tokens["geometry"]

BG = T["background"]
SURF = T["surface"]
ELEV = T["surfaceElevated"]
HOVER = T["surfaceHover"]
BORDER = T["border"]
BORDER_S = T["borderStrong"]
TEXT = T["text"]
MUTED = T["textMuted"]
DISABLED = T["textDisabled"]
ORANGE, ORANGE_B, ORANGE_D = T["orange"], T["orangeBright"], T["orangeDim"]
BLUE, BLUE_B, BLUE_D = T["blue"], T["blueBright"], T["blueDim"]
OK, WARN, ERR = T["success"], T["warning"], T["error"]
ON_ACCENT = T["onAccent"]

# Editor background: "surface" - one step lighter than the desktop
# background, calmer for 8h sessions than near-black.
EDITOR_BG = SURF
CONSOLE_BG = SURF

# --------------------------------------------------------------------------
# palette (derived)
# --------------------------------------------------------------------------


def syn(c: str) -> str:
    return lift(c, EDITOR_BG, TEXT)


P = {
    "fg": TEXT,
    "fgSoft": mix(TEXT, MUTED, 0.12),
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
    "link": syn(BLUE_B),
    "error": syn(ERR),
    "warning": syn(WARN),
    "success": syn(OK),
}

# backgrounds (editor)
B = {
    "caretRow": mix(EDITOR_BG, HOVER, 0.55),
    "selection": mix(EDITOR_BG, ORANGE, 0.24),   # muted orange tint
    "gutter": EDITOR_BG,
    "lineNo": lift(mix(DISABLED, MUTED, 0.25), EDITOR_BG, MUTED, 3.0),
    "lineNoCaret": mix(ORANGE_B, TEXT, 0.35),
    "indent": mix(EDITOR_BG, BORDER, 0.45),
    "indentSel": mix(EDITOR_BG, BORDER_S, 0.85),
    "whitespace": mix(EDITOR_BG, BORDER, 0.80),
    "rightMargin": mix(EDITOR_BG, BORDER, 0.60),
    "readUsage": mix(EDITOR_BG, BLUE_D, 0.32),
    "writeUsage": mix(EDITOR_BG, ORANGE_D, 0.32),
    "searchResult": mix(EDITOR_BG, BLUE_D, 0.45),
    "textSearch": mix(EDITOR_BG, WARN, 0.30),
    "matchedBrace": mix(EDITOR_BG, BLUE_D, 0.40),
    "folded": mix(EDITOR_BG, HOVER, 1.0),
    "popup": ELEV,
    "hint": mix(EDITOR_BG, ELEV, 1.0),
    "errorHint": mix(EDITOR_BG, ERR, 0.18),
    "inlay": mix(EDITOR_BG, HOVER, 0.9),
    "injected": mix(EDITOR_BG, BLUE_D, 0.08),
    "template": mix(EDITOR_BG, ORANGE_D, 0.06),
    "diffAdd": mix(EDITOR_BG, OK, 0.14),
    "diffDel": mix(EDITOR_BG, ERR, 0.14),
    "diffMod": mix(EDITOR_BG, BLUE, 0.14),
    "diffConflict": mix(EDITOR_BG, WARN, 0.16),
    "executionPoint": mix(EDITOR_BG, BLUE_D, 0.55),
    "breakpoint": mix(EDITOR_BG, ERR, 0.22),
    "notTopFrame": mix(EDITOR_BG, BLUE_D, 0.28),
}

# --------------------------------------------------------------------------
# console / ANSI (Aperture palette)
# --------------------------------------------------------------------------


def con(c: str) -> str:
    return lift(c, CONSOLE_BG, TEXT)


ANSI = {
    "BLACK": con(DISABLED),
    "RED": con(ERR),
    "GREEN": con(OK),
    "YELLOW": con(WARN),
    "BLUE": con(BLUE),
    "MAGENTA": con(ORANGE),            # Aperture: magenta -> signal orange
    "CYAN": con(BLUE_B),
    "GRAY": con(mix(TEXT, MUTED, 0.35)),   # "white" (normal)
    "DARKGRAY": con(MUTED),                # bright black
    "RED_BRIGHT": con(mix(ERR, TEXT, 0.30)),
    "GREEN_BRIGHT": con(mix(OK, TEXT, 0.30)),
    "YELLOW_BRIGHT": con(mix(WARN, TEXT, 0.30)),
    "BLUE_BRIGHT": con(BLUE_B),
    "MAGENTA_BRIGHT": con(ORANGE_B),
    "CYAN_BRIGHT": con(mix(BLUE_B, TEXT, 0.35)),
    "WHITE": con(TEXT),                    # bright white
}

# --------------------------------------------------------------------------
# UI theme
# --------------------------------------------------------------------------


def ramp(anchors: list[tuple[int, str]]) -> dict[int, str]:
    """piecewise-linear ramp over steps 10..160"""
    out = {}
    for step in range(10, 161, 10):
        for (s0, c0), (s1, c1) in zip(anchors, anchors[1:]):
            if s0 <= step <= s1:
                out[step] = mix(c0, c1, (step - s0) / (s1 - s0) if s1 > s0 else 0)
                break
    return out


def hue_ramp(dim: str, base: str, bright: str) -> dict[int, str]:
    return ramp([
        (10, mix(BG, dim, 0.14)),
        (40, mix(BG, dim, 0.42)),
        (60, mix(BG, dim, 0.75)),
        (80, dim),
        (90, base),
        (110, bright),
        (160, mix(bright, TEXT, 0.85)),
    ])


gray = ramp([
    (10, BG), (20, SURF), (30, ELEV), (40, HOVER), (50, BORDER),
    (60, BORDER_S), (70, DISABLED), (90, MUTED), (130, TEXT),
    (160, mix(TEXT, "#FFFFFF", 0.7)),
])

colors: dict[str, str] = {}
for name, r in {
    "gray": gray,
    "blue": hue_ramp(BLUE_D, BLUE, BLUE_B),
    "orange": hue_ramp(ORANGE_D, ORANGE, ORANGE_B),
    "green": hue_ramp(mix(OK, BG, 0.40), OK, mix(OK, TEXT, 0.35)),
    "red": hue_ramp(mix(ERR, BG, 0.40), ERR, mix(ERR, TEXT, 0.35)),
    "yellow": hue_ramp(mix(WARN, BG, 0.40), WARN, mix(WARN, TEXT, 0.35)),
}.items():
    for step in sorted(r, reverse=True):
        colors[f"{name}-{step}"] = r[step]

SEL_UI = mix(SURF, ORANGE, 0.26)          # list/tree selection (focused)
SEL_UI_MUTED = mix(SURF, ORANGE, 0.16)
SEL_UI_INACTIVE = mix(SURF, HOVER, 1.0)

colors.update({
    # Aperture names (for readability of the theme file)
    "ap-background": BG,
    "ap-surface": SURF,
    "ap-elevated": ELEV,
    "ap-hover": HOVER,
    "ap-border": BORDER,
    "ap-border-strong": BORDER_S,
    "ap-text": TEXT,
    "ap-text-muted": MUTED,
    "ap-text-disabled": DISABLED,
    "ap-orange": ORANGE,
    "ap-orange-bright": ORANGE_B,
    "ap-orange-dim": ORANGE_D,
    "ap-blue": BLUE,
    "ap-blue-bright": BLUE_B,
    "ap-blue-dim": BLUE_D,
    "ap-success": OK,
    "ap-warning": WARN,
    "ap-error": ERR,
    "ap-on-accent": ON_ACCENT,
    "ap-selection": SEL_UI,
    "ap-selection-muted": SEL_UI_MUTED,
    "ap-selection-inactive": SEL_UI_INACTIVE,

    # Islands Dark semantic palette overrides
    "transparent": alpha(BG, 0),
    "text-default": TEXT,
    "text-muted": MUTED,
    "text-secondary": mix(MUTED, DISABLED, 0.3),
    "text-disabled": DISABLED,
    "text-over-accent": ON_ACCENT,
    "text-over-accent-inverted": TEXT,
    "text-link": BLUE_B,
    "text-error": mix(ERR, TEXT, 0.15),
    "text-warning": WARN,
    "text-success": OK,
    "editor-text": TEXT,
    "layer-0-bg": SURF,
    "layer-0-border": BORDER,
    "layer-0-bg-inline": ELEV,
    "layer-0-border-inline": BORDER,
    "layer-1-bg": ELEV,
    "layer-1-border": BORDER,
    "layer-1-bg-inline": HOVER,
    "layer-1-border-inline": BORDER_S,
    "layer-2-bg": HOVER,
    "layer-2-bg-inline": mix(HOVER, BORDER, 0.4),
    "layer-2-border": BORDER_S,
    "layer-2-border-inline": BORDER_S,
    "accent-brand-bg": ORANGE,
    "accent-brand-border": ORANGE,
    "accent-brand-bg-secondary": mix(SURF, ORANGE_D, 0.40),
    "accent-brand-border-secondary": ORANGE_D,
    "accent-error-bg": ERR,
    "accent-error-border": ERR,
    "accent-error-bg-secondary": mix(SURF, ERR, 0.20),
    "accent-error-border-secondary": mix(SURF, ERR, 0.55),
    "accent-warning-bg": WARN,
    "accent-warning-border": WARN,
    "accent-warning-bg-secondary": mix(SURF, WARN, 0.18),
    "accent-warning-border-secondary": mix(SURF, WARN, 0.50),
    "accent-success-bg": OK,
    "accent-success-border": OK,
    "accent-success-bg-secondary": mix(SURF, OK, 0.18),
    "accent-success-border-secondary": mix(SURF, OK, 0.50),
    "accent-neutral-bg": MUTED,
    "dialog-bg": SURF,
    "dialog-bg-inline": ELEV,
    "dialog-border": BORDER,
    "popup-bg": ELEV,
    "popup-bg-inline": ELEV,
    "popup-border": BORDER,
    "popup-border-inline": BORDER,
    "editor-bg": EDITOR_BG,
    "editor-bg-inline": ELEV,
    "editor-border": BORDER,
    "editor-border-inline": BORDER,
    "editor-border-alt": BORDER,
    "tool-window-bg": SURF,
    "tool-window-bg-inline": ELEV,
    "tool-window-bg-alt": SURF,
    "tool-window-border": BORDER,
    "tool-window-border-inline": BORDER,
    "main-window-bg": BG,
    "main-window-bg-alt": BG,
    "main-window-border": BORDER,
    "control-bg": SURF,
    "control-bg-disabled": SURF,
    "control-bg-raised": ELEV,
    "control-border": BORDER,
    "control-border-disabled": mix(SURF, BORDER, 0.5),
    "control-border-raised": BORDER_S,
    "control-border-over-accent": alpha(ON_ACCENT, 0.35),
    "control-bg-small": BORDER,
    "control-bg-small-disabled": HOVER,
    "control-border-small": BORDER_S,
    "control-brand-bg": ORANGE,
    "control-brand-border": ORANGE,
    "toolbar-bg-hovered": HOVER,
    "toolbar-bg-pressed": mix(HOVER, BORDER, 0.5),
    "toolbar-border": BORDER,
    "toolbar-selected-bg": SEL_UI,
    "toolbar-selected-bg-hovered": mix(SURF, ORANGE, 0.34),
    "toolbar-selected-bg-active": ORANGE_D,
    "toolbar-run-bg": mix(SURF, OK, 0.55),
    "toolbar-run-bg-hovered": mix(SURF, OK, 0.70),
    "toolbar-stop-bg": mix(SURF, ERR, 0.55),
    "toolbar-stop-bg-hovered": mix(SURF, ERR, 0.70),
    "feedback-bg": ELEV,
    "feedback-border": BORDER,
    "feedback-bg-inline": SURF,
    "feedback-brand-bg": mix(SURF, BLUE_D, 0.30),
    "feedback-brand-border": BLUE_D,
    "feedback-success-bg": mix(SURF, OK, 0.16),
    "feedback-success-border": mix(SURF, OK, 0.50),
    "feedback-warning-bg": mix(SURF, WARN, 0.16),
    "feedback-warning-border": mix(SURF, WARN, 0.50),
    "feedback-error-bg": mix(SURF, ERR, 0.18),
    "feedback-error-border": mix(SURF, ERR, 0.55),
    "selection-bg-active": SEL_UI,
    "selection-bg-active-muted": SEL_UI_MUTED,
    "selection-bg-inactive": SEL_UI_INACTIVE,
    "selection-bg-hovered": alpha(HOVER, 0.85),
    "tab-selected-bg-active": mix(SURF, ORANGE, 0.12),
    "tab-selected-bg-inactive": HOVER,
    "tab-selected-border-active": ORANGE,
    "tab-selected-border-inactive": BORDER_S,
    "tab-bg-hovered": HOVER,
    "got-it-bg": BLUE_D,
    "got-it-border": BLUE_D,
    "got-it-text-link": mix(BLUE_B, TEXT, 0.5),
    "inlay-bg": HOVER,
    "inlay-border": BORDER,
    "toggle-off-bg": BG,
    "toggle-button-bg": MUTED,
    "toggle-border": BORDER_S,
    "editor-floating-toolbar-bg": HOVER,
    "popup-completion-match-text": ORANGE_B,
    "presentation-assistant-bg": BLUE_D,
    "search-match-bg": mix(SURF, WARN, 0.55),
    "tree-indent-guide-border": mix(SURF, BORDER, 0.6),
    "icon-default-stroke": mix(TEXT, MUTED, 0.3),
    "icon-over-accent": ON_ACCENT,
    "icon-green-stroke": OK,
})

R = G["radiusWindow"] * 2   # Swing arcs are diameters
RC = G["radiusControl"] * 2

ui = {
    "*": {
        "foreground": "text-default",
        "background": "tool-window-bg",
        "borderColor": "ap-border",
        "selectionBackground": "ap-selection",
        "selectionForeground": "text-default",
        "selectionInactiveBackground": "ap-selection-inactive",
        "selectionInactiveForeground": "text-default",
        "lightSelectionBackground": "ap-selection-muted",
        "hoverBackground": "ap-hover",
        "focusColor": "ap-orange",
        "underlineColor": "ap-orange",
        "infoForeground": "ap-text-muted",
        "disabledText": "ap-text-disabled",
        "disabledForeground": "ap-text-disabled",
        "separatorColor": "ap-border",
        "modifiedItemForeground": "ap-blue-bright",
    },
    "Islands": 1,
    "Island": {
        "arc": R + 2,
        "arc.compact": R,
        "borderColor": "ap-background",
    },
    "MainWindow.background": "ap-background",
    "MainToolbar": {"background": "ap-background", "inactiveBackground": "ap-background"},
    "StatusBar": {"background": "ap-background"},
    "ToolWindow": {
        "background": "ap-surface",
        "Stripe": {"background": "ap-background"},
        "Button": {"selectedBackground": "ap-orange-dim", "selectedForeground": "ap-on-accent"},
        "Header": {"inactiveBackground": "ap-surface"},
    },
    "Component": {
        "arc": RC * 2,
        "arc.compact": RC * 2,
        "focusColor": "ap-orange",
        "focusedBorderColor": "ap-orange",
        "borderColor": "ap-border",
        "errorFocusColor": "ap-error",
        "warningFocusColor": "ap-warning",
    },
    "Button": {
        "arc": RC * 2,
        "startBorderColor": "ap-border-strong",
        "endBorderColor": "ap-border-strong",
        "focusedBorderColor": "ap-orange",
        "default": {
            "foreground": "ap-on-accent",
            "startBackground": "ap-orange",
            "endBackground": "ap-orange",
            "startBorderColor": "ap-orange",
            "endBorderColor": "ap-orange",
            "focusedBorderColor": "ap-orange-bright",
        },
    },
    "EditorTabs": {
        "background": "editor-bg",
        "underlinedBorderColor": "ap-orange",
        "underlinedTabBackground": "tab-selected-bg-active",
        "inactiveUnderlinedTabBorderColor": "ap-border-strong",
        "underlineHeight": G["accentWidth"],
        "underlineArc": 0,
        "hoverBackground": "ap-hover",
        "underTabsBorderColor": "ap-border",
    },
    "DefaultTabs": {
        "underlineColor": "ap-orange",
        "inactiveUnderlineColor": "ap-border-strong",
        "underlineHeight": G["accentWidth"],
    },
    "TabbedPane": {"underlineColor": "ap-orange", "focusColor": "tab-selected-bg-active"},
    "Link": {
        "activeForeground": "ap-blue-bright",
        "hoverForeground": "ap-blue-bright",
        "pressedForeground": "ap-blue-bright",
        "visitedForeground": "ap-blue-bright",
        "secondaryForeground": "ap-blue",
    },
    "List": {"selectionBackground": "ap-selection", "selectionInactiveBackground": "ap-selection-inactive"},
    "Tree": {"selectionBackground": "ap-selection", "selectionInactiveBackground": "ap-selection-inactive"},
    "Table": {"selectionBackground": "ap-selection", "selectionInactiveBackground": "ap-selection-inactive"},
    "Popup": {"background": "ap-elevated", "borderColor": "ap-border", "inactiveBorderColor": "ap-border"},
    "PopupMenu.background": "ap-elevated",
    "ProgressBar": {
        "progressColor": "ap-orange",
        "indeterminateStartColor": "ap-orange-dim",
        "indeterminateEndColor": "ap-orange",
        "passedColor": "ap-success",
        "failedColor": "ap-error",
        "trackColor": "ap-border",
    },
    "ScrollBar": {
        "thumbColor": alpha(BORDER_S, 0.55),
        "hoverThumbColor": alpha(MUTED, 0.65),
        "thumbBorderColor": alpha(BORDER_S, 0.0),
        "hoverThumbBorderColor": alpha(MUTED, 0.0),
        "Transparent": {
            "thumbColor": alpha(BORDER_S, 0.55),
            "hoverThumbColor": alpha(MUTED, 0.65),
            "thumbBorderColor": alpha(BORDER_S, 0.0),
            "hoverThumbBorderColor": alpha(MUTED, 0.0),
        },
    },
    "SearchMatch": {"startBackground": "search-match-bg", "endBackground": "search-match-bg"},
    "ToolTip": {"background": "ap-elevated", "borderColor": "ap-border-strong", "foreground": "ap-text"},
    "Notification": {"background": "ap-elevated", "borderColor": "ap-border-strong"},
    "Banner": {
        "infoBackground": "feedback-brand-bg",
        "infoBorderColor": "feedback-brand-border",
        "errorBackground": "feedback-error-bg",
        "errorBorderColor": "feedback-error-border",
        "warningBackground": "feedback-warning-bg",
        "warningBorderColor": "feedback-warning-border",
        "successBackground": "feedback-success-bg",
        "successBorderColor": "feedback-success-border",
    },
    "Label": {"errorForeground": "text-error", "warningForeground": "ap-warning", "successForeground": "ap-success"},
    "Counter": {"background": "ap-orange", "foreground": "ap-on-accent"},
    "DragAndDrop": {"borderColor": "ap-orange", "rowBackground": alpha(ORANGE, 0.15)},
    "FileColor": {
        "Yellow": mix(SURF, WARN, 0.12),
        "Green": mix(SURF, OK, 0.12),
        "Orange": mix(SURF, ORANGE, 0.14),
        "Rose": mix(SURF, ERR, 0.12),
        "Blue": mix(SURF, BLUE, 0.12),
        "Gray": HOVER,
    },
    "VersionControl": {
        "GitGreen": "ap-success",
        "GitLog.localBranchIconColor": "ap-orange",
        "GitLog.remoteBranchIconColor": "ap-blue",
        "GitLog.tagIconColor": "ap-text-muted",
        "RefLabel.foreground": "ap-text",
    },
    "Debugger": {
        "Variables": {
            "valueForeground": P["string"],
            "changedValueForeground": "ap-orange-bright",
            "modifyingValueForeground": "ap-orange-bright",
            "typeForeground": "ap-text-muted",
            "errorMessageForeground": "ap-error",
            "exceptionForeground": "ap-error",
        }
    },
    "MainWindow.Tab": {"background": "ap-background", "selectedBackground": "ap-surface"},
    "Separator.separatorColor": "ap-border",
    "OnePixelDivider.background": "ap-border",
    "Borders": {"color": "ap-border", "ContrastBorderColor": "ap-border"},
    "TextField": {"background": "ap-surface"},
    "ComboBox": {"background": "ap-elevated", "nonEditableBackground": "ap-elevated"},
    "CompletionPopup": {
        "selectionBackground": "ap-selection",
        "selectionInactiveBackground": "ap-selection-inactive",
        "matchForeground": "ap-orange-bright",
    },
    "SearchEverywhere": {"SearchField.background": "ap-elevated"},
    "GotItTooltip": {"background": "ap-blue-dim", "borderColor": "ap-blue-dim"},
}

theme = {
    "name": THEME_NAME,
    "dark": True,
    "author": "Aperture OS",
    "parentTheme": "Islands Dark",
    "editorScheme": "/" + JAR_SCHEME_BASE + ".xml",
    "colors": colors,
    "ui": ui,
}

# --------------------------------------------------------------------------
# editor color scheme (.icls)
# --------------------------------------------------------------------------

scheme_colors = {
    "CARET_COLOR": ORANGE,
    "CARET_ROW_COLOR": B["caretRow"],
    "SELECTION_BACKGROUND": B["selection"],
    "SELECTION_FOREGROUND": None,
    "GUTTER_BACKGROUND": B["gutter"],
    "LINE_NUMBERS_COLOR": B["lineNo"],
    "LINE_NUMBER_ON_CARET_ROW_COLOR": B["lineNoCaret"],
    "INDENT_GUIDE": B["indent"],
    "VISUAL_INDENT_GUIDE": B["indent"],
    "SELECTED_INDENT_GUIDE": B["indentSel"],
    "MATCHED_BRACES_INDENT_GUIDE_COLOR": B["indentSel"],
    "WHITESPACES": B["whitespace"],
    "WHITESPACES_MODIFIED_LINES_COLOR": mix(B["whitespace"], BLUE_D, 0.4),
    "RIGHT_MARGIN_COLOR": B["rightMargin"],
    "METHOD_SEPARATORS_COLOR": B["rightMargin"],
    "TEARLINE_COLOR": B["rightMargin"],
    "SELECTED_TEARLINE_COLOR": BORDER_S,
    "SOFT_WRAP_SIGN_COLOR": DISABLED,
    "FOLDED_TEXT_BORDER_COLOR": BORDER,
    "CONSOLE_BACKGROUND_KEY": CONSOLE_BG,
    "DOCUMENTATION_COLOR": ELEV,
    "LOOKUP_COLOR": ELEV,
    "INFORMATION_HINT": ELEV,
    "QUESTION_HINT": ELEV,
    "ERROR_HINT": B["errorHint"],
    "HINT_BORDER": BORDER,
    "NOTIFICATION_BACKGROUND": ELEV,
    "PROMOTION_PANE": ELEV,
    "RECENT_LOCATIONS_SELECTION": HOVER,
    "DIFF_SEPARATORS_BACKGROUND": ELEV,
    "DOC_COMMENT_GUIDE": mix(EDITOR_BG, P["docComment"], 0.35),
    "DOC_COMMENT_LINK": BLUE_B,
    "ADDED_LINES_COLOR": mix(OK, EDITOR_BG, 0.25),
    "MODIFIED_LINES_COLOR": mix(BLUE, EDITOR_BG, 0.25),
    "DELETED_LINES_COLOR": mix(ERR, EDITOR_BG, 0.25),
    "IGNORED_ADDED_LINES_BORDER_COLOR": mix(OK, EDITOR_BG, 0.45),
    "IGNORED_MODIFIED_LINES_BORDER_COLOR": mix(BLUE, EDITOR_BG, 0.45),
    "IGNORED_DELETED_LINES_BORDER_COLOR": mix(ERR, EDITOR_BG, 0.45),
    "ANNOTATIONS_COLOR": MUTED,
    "ANNOTATIONS_LAST_COMMIT_COLOR": TEXT,
    "VCS_ANNOTATIONS_COLOR_1": mix(EDITOR_BG, ORANGE_D, 0.40),
    "VCS_ANNOTATIONS_COLOR_2": mix(EDITOR_BG, ORANGE_D, 0.30),
    "VCS_ANNOTATIONS_COLOR_3": mix(EDITOR_BG, ORANGE_D, 0.20),
    "VCS_ANNOTATIONS_COLOR_4": mix(EDITOR_BG, ORANGE_D, 0.12),
    "VCS_ANNOTATIONS_COLOR_5": mix(EDITOR_BG, ORANGE_D, 0.06),
    "FILESTATUS_ADDED": OK,
    "FILESTATUS_COPIED": OK,
    "FILESTATUS_MODIFIED": BLUE_B,
    "FILESTATUS_NOT_CHANGED_IMMEDIATE": BLUE_B,
    "FILESTATUS_NOT_CHANGED_RECURSIVE": mix(BLUE_B, MUTED, 0.4),
    "FILESTATUS_RENAMED": mix(BLUE_B, TEXT, 0.3),
    "FILESTATUS_DELETED": MUTED,
    "FILESTATUS_IDEA_FILESTATUS_DELETED_FROM_FILE_SYSTEM": MUTED,
    "FILESTATUS_UNKNOWN": mix(ERR, TEXT, 0.25),
    "FILESTATUS_IDEA_FILESTATUS_IGNORED": mix(WARN, MUTED, 0.55),
    "FILESTATUS_MERGED": mix(ORANGE_B, TEXT, 0.2),
    "FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_CONFLICTS": ERR,
    "FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_BOTH_CONFLICTS": ERR,
    "FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_PROPERTY_CONFLICTS": ERR,
    "FILESTATUS_SWITCHED": mix(ORANGE_B, TEXT, 0.2),
    "FILESTATUS_HIJACKED": WARN,
    "FILESTATUS_OBSOLETE": WARN,
    "FILESTATUS_SUPPRESSED": MUTED,
    "INLINE_REFACTORING_SETTINGS_DEFAULT": ELEV,
    "INLINE_REFACTORING_SETTINGS_FOCUSED": HOVER,
    "INLINE_REFACTORING_SETTINGS_HOVERED": HOVER,
}

# attributes: name -> dict(fg, bg, font, effect, effect_color, stripe, base)
BOLD, ITALIC = 1, 2
UNDERLINE, WAVE, STRIKE, BOXED, BOLD_UNDERLINE, DOTTED = 1, 2, 3, 0, 4, 5


def a(fg=None, bg=None, font=None, effect=None, ec=None, stripe=None, base=None):
    return {"fg": fg, "bg": bg, "font": font, "effect": effect, "ec": ec, "stripe": stripe, "base": base}


attrs: dict[str, dict] = {
    # ---- general
    "TEXT": a(TEXT, EDITOR_BG),
    "DEFAULT_IDENTIFIER": a(TEXT),
    "DEFAULT_KEYWORD": a(P["keyword"]),
    "DEFAULT_NUMBER": a(P["number"]),
    "DEFAULT_STRING": a(P["string"]),
    "DEFAULT_VALID_STRING_ESCAPE": a(P["escape"], font=BOLD),
    "DEFAULT_INVALID_STRING_ESCAPE": a(P["error"], effect=WAVE, ec=ERR),
    "DEFAULT_LINE_COMMENT": a(P["comment"], font=ITALIC),
    "DEFAULT_BLOCK_COMMENT": a(P["comment"], font=ITALIC),
    "DEFAULT_DOC_COMMENT": a(P["docComment"], font=ITALIC),
    "DEFAULT_DOC_COMMENT_TAG": a(P["docTag"], font=ITALIC),
    "DEFAULT_DOC_COMMENT_TAG_VALUE": a(P["docComment"], font=ITALIC),
    "DEFAULT_DOC_MARKUP": a(P["docComment"]),
    "DEFAULT_OPERATION_SIGN": a(P["punct"]),
    "DEFAULT_BRACES": a(P["punct"]),
    "DEFAULT_BRACKETS": a(P["punct"]),
    "DEFAULT_PARENTHS": a(P["punct"]),
    "DEFAULT_COMMA": a(P["punct"]),
    "DEFAULT_SEMICOLON": a(P["punct"]),
    "DEFAULT_DOT": a(P["punct"]),
    "DEFAULT_CONSTANT": a(P["constant"]),
    "DEFAULT_PREDEFINED_SYMBOL": a(P["keywordSoft"]),
    "DEFAULT_LABEL": a(P["keywordSoft"]),
    "DEFAULT_CLASS_NAME": a(P["type"]),
    "DEFAULT_CLASS_REFERENCE": a(P["type"]),
    "DEFAULT_INTERFACE_NAME": a(P["type"], font=ITALIC),
    "DEFAULT_FUNCTION_DECLARATION": a(P["funcDecl"]),
    "DEFAULT_FUNCTION_CALL": a(P["funcCall"]),
    "DEFAULT_INSTANCE_METHOD": a(P["funcCall"]),
    "DEFAULT_STATIC_METHOD": a(P["funcCall"], font=ITALIC),
    "DEFAULT_INSTANCE_FIELD": a(P["field"]),
    "DEFAULT_STATIC_FIELD": a(P["field"], font=ITALIC),
    "DEFAULT_LOCAL_VARIABLE": a(P["var"]),
    "DEFAULT_GLOBAL_VARIABLE": a(P["var"], font=ITALIC),
    "DEFAULT_PARAMETER": a(P["param"]),
    "DEFAULT_REASSIGNED_LOCAL_VARIABLE": a(P["var"], effect=UNDERLINE, ec=BORDER_S),
    "DEFAULT_REASSIGNED_PARAMETER": a(P["param"], effect=UNDERLINE, ec=BORDER_S),
    "DEFAULT_METADATA": a(P["metadata"]),
    "DEFAULT_TAG": a(P["tag"]),
    "DEFAULT_ATTRIBUTE": a(P["attr"]),
    "DEFAULT_ENTITY": a(P["escape"]),
    "DEFAULT_TEMPLATE_LANGUAGE_COLOR": a(bg=B["template"]),
    "DEFAULT_HIGHLIGHTED_REFERENCE": a(effect=UNDERLINE, ec=BLUE_B),
    "TYPE_PARAMETER_NAME_ATTRIBUTES": a(P["type"], font=ITALIC),
    "ANNOTATION_NAME_ATTRIBUTES": a(P["metadata"]),
    "ANNOTATION_ATTRIBUTE_NAME_ATTRIBUTES": a(P["attr"]),
    "INJECTED_LANGUAGE_FRAGMENT": a(bg=B["injected"]),
    "TODO_DEFAULT_ATTRIBUTES": a(P["warning"], font=BOLD | ITALIC, stripe=WARN),
    "CUSTOM_KEYWORD1_ATTRIBUTES": a(P["keyword"]),
    "CUSTOM_KEYWORD2_ATTRIBUTES": a(P["type"]),
    "CUSTOM_KEYWORD3_ATTRIBUTES": a(P["funcCall"]),
    "CUSTOM_KEYWORD4_ATTRIBUTES": a(P["constant"]),
    "CUSTOM_STRING_ATTRIBUTES": a(P["string"]),
    "CUSTOM_NUMBER_ATTRIBUTES": a(P["number"]),
    "CUSTOM_LINE_COMMENT_ATTRIBUTES": a(P["comment"], font=ITALIC),
    "CUSTOM_MULTI_LINE_COMMENT_ATTRIBUTES": a(P["comment"], font=ITALIC),
    "CUSTOM_VALID_STRING_ESCAPE_ATTRIBUTES": a(P["escape"]),
    "CUSTOM_INVALID_STRING_ESCAPE_ATTRIBUTES": a(P["error"], effect=WAVE, ec=ERR),

    # ---- editor feedback
    "ERRORS_ATTRIBUTES": a(effect=WAVE, ec=ERR, stripe=ERR),
    "WRONG_REFERENCES_ATTRIBUTES": a(P["error"], effect=WAVE, ec=ERR, stripe=ERR),
    "BAD_CHARACTER": a(effect=WAVE, ec=ERR, stripe=ERR),
    "RUNTIME_ERROR": a(effect=WAVE, ec=ERR, stripe=ERR),
    "WARNING_ATTRIBUTES": a(effect=WAVE, ec=WARN, stripe=WARN),
    "GENERIC_SERVER_ERROR_OR_WARNING": a(effect=WAVE, ec=WARN, stripe=WARN),
    "WEAK_WARNING_ATTRIBUTES": a(effect=WAVE, ec=mix(WARN, EDITOR_BG, 0.45), stripe=mix(WARN, EDITOR_BG, 0.45)),
    "INFO_ATTRIBUTES": a(effect=UNDERLINE, ec=mix(MUTED, EDITOR_BG, 0.3), stripe=MUTED),
    "INFORMATION_ATTRIBUTES": a(),
    "TYPO": a(effect=WAVE, ec=mix(OK, EDITOR_BG, 0.35)),
    "TEXT_STYLE_ERROR": a(effect=WAVE, ec=mix(BLUE_B, EDITOR_BG, 0.3)),
    "TEXT_STYLE_WARNING": a(effect=WAVE, ec=mix(BLUE_B, EDITOR_BG, 0.5)),
    "TEXT_STYLE_SUGGESTION": a(effect=UNDERLINE, ec=mix(BLUE_B, EDITOR_BG, 0.5)),
    "DEPRECATED_ATTRIBUTES": a(effect=STRIKE, ec=MUTED),
    "MARKED_FOR_REMOVAL_ATTRIBUTES": a(effect=STRIKE, ec=ERR),
    "NOT_USED_ELEMENT_ATTRIBUTES": a(lift(mix(MUTED, DISABLED, 0.3), EDITOR_BG, TEXT, 3.5)),
    "UNMATCHED_BRACE_ATTRIBUTES": a(bg=B["errorHint"], effect=WAVE, ec=ERR),
    "MATCHED_BRACE_ATTRIBUTES": a(bg=B["matchedBrace"], font=BOLD),
    "MATCHED_TAG_NAME": a(bg=B["matchedBrace"]),
    "IDENTIFIER_UNDER_CARET_ATTRIBUTES": a(bg=B["readUsage"], stripe=BLUE_D),
    "WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES": a(bg=B["writeUsage"], stripe=ORANGE_D),
    "SEARCH_RESULT_ATTRIBUTES": a(bg=B["searchResult"], stripe=BLUE),
    "WRITE_SEARCH_RESULT_ATTRIBUTES": a(bg=B["writeUsage"], stripe=ORANGE),
    "TEXT_SEARCH_RESULT_ATTRIBUTES": a(bg=B["textSearch"], stripe=WARN),
    "FOLDED_TEXT_ATTRIBUTES": a(MUTED, B["folded"]),
    "HYPERLINK_ATTRIBUTES": a(P["link"], effect=UNDERLINE, ec=BLUE_B),
    "FOLLOWED_HYPERLINK_ATTRIBUTES": a(mix(BLUE_B, MUTED, 0.3), effect=UNDERLINE, ec=mix(BLUE_B, MUTED, 0.3)),
    "INACTIVE_HYPERLINK_ATTRIBUTES": a(effect=UNDERLINE, ec=MUTED),
    "CTRL_CLICKABLE": a(P["link"], effect=UNDERLINE, ec=BLUE_B),
    "LIVE_TEMPLATE_ATTRIBUTES": a(effect=BOXED, ec=ORANGE),
    "LIVE_TEMPLATE_INACTIVE_SEGMENT": a(effect=BOXED, ec=BORDER_S),
    "TEMPLATE_VARIABLE_ATTRIBUTES": a(P["constant"]),
    "BOOKMARKS_ATTRIBUTES": a(stripe=BLUE_B),
    "BREAKPOINT_ATTRIBUTES": a(bg=B["breakpoint"], stripe=ERR),
    "EXECUTIONPOINT_ATTRIBUTES": a(bg=B["executionPoint"], stripe=BLUE),
    "NOT_TOP_FRAME_ATTRIBUTES": a(bg=B["notTopFrame"]),
    "DEBUGGER_INLINED_VALUES": a(lift(MUTED, EDITOR_BG, TEXT), font=ITALIC),
    "DEBUGGER_INLINED_VALUES_MODIFIED": a(ORANGE_B, font=ITALIC),
    "DEBUGGER_INLINED_VALUES_EXECUTION_LINE": a(mix(BLUE_B, TEXT, 0.5), font=ITALIC),
    "INLAY_DEFAULT": a(lift(MUTED, B["inlay"], TEXT), B["inlay"]),
    "INLAY_TEXT_WITHOUT_BACKGROUND": a(lift(MUTED, EDITOR_BG, TEXT)),
    "INLINE_PARAMETER_HINT": a(lift(MUTED, B["inlay"], TEXT), B["inlay"]),
    "INLINE_PARAMETER_HINT_HIGHLIGHTED": a(TEXT, mix(B["inlay"], BORDER, 0.5)),
    "INLINE_PARAMETER_HINT_CURRENT": a(TEXT, mix(EDITOR_BG, ORANGE_D, 0.35)),
    "CODE_LENS_BORDER_COLOR": a(ec=BORDER),
    "BREADCRUMBS_DEFAULT": a(MUTED),
    "BREADCRUMBS_HOVERED": a(TEXT, HOVER),
    "BREADCRUMBS_CURRENT": a(TEXT, HOVER),
    "BREADCRUMBS_INACTIVE": a(DISABLED),
    "DOC_CODE_BLOCK": a(TEXT, ELEV, ec=BORDER),
    "DOC_CODE_INLINE": a(TEXT, HOVER),
    "DOC_TIPS_SHORTCUT": a(TEXT, HOVER, ec=BORDER),
    "LINE_FULL_COVERAGE": a(OK, font=BOLD),
    "LINE_PARTIAL_COVERAGE": a(WARN, font=BOLD),
    "LINE_NONE_COVERAGE": a(ERR, font=BOLD),

    # ---- diff / VCS
    "DIFF_INSERTED": a(bg=B["diffAdd"], stripe=OK),
    "DIFF_DELETED": a(bg=B["diffDel"], stripe=ERR),
    "DIFF_MODIFIED": a(bg=B["diffMod"], stripe=BLUE),
    "DIFF_CONFLICT": a(bg=B["diffConflict"], stripe=WARN),
    "DELETED_TEXT_ATTRIBUTES": a(MUTED, effect=STRIKE, ec=MUTED),

    # ---- console
    "CONSOLE_NORMAL_OUTPUT": a(con(TEXT)),
    "CONSOLE_ERROR_OUTPUT": a(con(ERR)),
    "CONSOLE_SYSTEM_OUTPUT": a(con(MUTED)),
    "CONSOLE_USER_INPUT": a(con(OK), font=ITALIC),
    "CONSOLE_RANGE_TO_EXECUTE": a(effect=BOXED, ec=OK),
    "LOG_ERROR_OUTPUT": a(con(ERR)),
    "LOG_WARNING_OUTPUT": a(con(WARN)),
    "LOG_INFO_OUTPUT": a(con(TEXT)),
    "LOG_VERBOSE_OUTPUT": a(con(MUTED)),
    "LOG_DEBUG_OUTPUT": a(con(MUTED)),
    "LOG_EXPIRED_ENTRY": a(con(DISABLED)),

    # ---- PHP
    "PHP_KEYWORD": a(P["keyword"]),
    "PHP_VAR": a(P["var"]),
    "PHP_THIS_VAR": a(P["keywordSoft"]),
    "PHP_VAR_VAR": a(P["var"], font=BOLD),
    "PHP_PARAMETER": a(P["param"]),
    "PHP_NAMED_ARGUMENT": a(P["param"], font=ITALIC),
    "PHP_CLASS": a(P["type"]),
    "PHP_INTERFACE": a(P["type"], font=ITALIC),
    "PHP_CONSTANT": a(P["constant"]),
    "PHP_FUNCTION": a(P["funcDecl"]),
    "PHP_FUNCTION_CALL": a(P["funcCall"]),
    "PHP_INSTANCE_METHOD": a(P["funcCall"]),
    "PHP_STATIC_METHOD": a(P["funcCall"], font=ITALIC),
    "PHP_INSTANCE_FIELD": a(P["field"]),
    "PHP_STATIC_FIELD": a(P["field"], font=ITALIC),
    "PHP_PRIMITIVE_TYPE_HINT": a(P["keywordSoft"]),
    "PHP_ATTRIBUTE": a(P["metadata"]),
    "PHP_PREDEFINED SYMBOL": a(P["keywordSoft"]),
    "PHP_TAG": a(P["keyword"], font=BOLD),
    "PHP_STRING": a(P["string"]),
    "PHP_HEREDOC_CONTENT": a(P["string"]),
    "PHP_HEREDOC_ID": a(P["keywordSoft"]),
    "PHP_EXEC_COMMAND_ID": a(P["string"], font=BOLD),
    "PHP_NUMBER": a(P["number"]),
    "PHP_COMMENT": a(P["comment"], font=ITALIC),
    "PHP_DOC_COMMENT_ID": a(P["docComment"], font=ITALIC),
    "PHP_DOC_TAG": a(P["docTag"], font=ITALIC),
    "PHP_DOC_PARAMETER": a(P["param"], font=ITALIC),
    "PHP_DOC_IDENTIFIER": a(P["type"], font=ITALIC),
    "PHP_MARKUP_ID": a(P["docComment"]),
    "PHP_ESCAPE_SEQUENCE": a(P["escape"], font=BOLD),
    "PHP_INVALID_ESCAPE_SEQUENCE": a(P["error"], effect=WAVE, ec=ERR),
    "PHP_OPERATION_SIGN": a(P["punct"]),
    "PHP_CONCATENATION": a(P["keywordSoft"]),
    "PHP_SCRIPTING_BACKGROUND": a(bg=EDITOR_BG),
    "PHP_ALIAS_REFERENCE": a(P["type"], font=ITALIC),

    # ---- JS / TS
    "JS.KEYWORD": a(P["keyword"]),
    "JS.LOCAL_VARIABLE": a(P["var"]),
    "JS.GLOBAL_VARIABLE": a(P["var"], font=ITALIC),
    "JS.PARAMETER": a(P["param"]),
    "JS.INSTANCE_MEMBER_FUNCTION": a(P["funcCall"]),
    "JS.STATIC_MEMBER_FUNCTION": a(P["funcCall"], font=ITALIC),
    "JS.GLOBAL_FUNCTION": a(P["funcDecl"]),
    "JS.INSTANCE_MEMBER_VARIABLE": a(P["field"]),
    "JS.STATIC_MEMBER_VARIABLE": a(P["field"], font=ITALIC),
    "JS.REGEXP": a(P["escape"]),
    "JS.JSX_CLIENT_COMPONENT": a(P["type"]),
    "JS.JSX_SERVER_COMPONENT": a(P["type"], font=ITALIC),
    "TS.TYPE_PARAMETER": a(P["type"], font=ITALIC),
    "TS.TYPE_GUARD": a(P["keywordSoft"]),
    "TS.PRIMITIVE.TYPES": a(P["keywordSoft"]),

    # ---- HTML / XML
    "HTML_TAG": a(P["punct"]),
    "HTML_TAG_NAME": a(P["tag"]),
    "HTML_CUSTOM_TAG_NAME": a(P["type"]),
    "HTML_ATTRIBUTE_NAME": a(P["attr"]),
    "HTML_ATTRIBUTE_VALUE": a(P["string"]),
    "HTML_ENTITY_REFERENCE": a(P["escape"]),
    "HTML_COMMENT": a(P["comment"], font=ITALIC),
    "XML_TAG": a(P["punct"]),
    "XML_TAG_NAME": a(P["tag"]),
    "XML_CUSTOM_TAG_NAME": a(P["type"]),
    "XML_ATTRIBUTE_NAME": a(P["attr"]),
    "XML_ATTRIBUTE_VALUE": a(P["string"]),
    "XML_ENTITY_REFERENCE": a(P["escape"]),
    "XML_PROLOGUE": a(P["comment"]),
    "XML_COMMENT": a(P["comment"], font=ITALIC),

    # ---- CSS / SCSS / LESS
    "CSS.TAG_NAME": a(P["tag"]),
    "CSS.IDENT": a(P["type"]),
    "CSS.CLASS_NAME": a(P["type"]),
    "CSS.ID_SELECTOR": a(P["funcDecl"]),
    "CSS.PSEUDO": a(P["keywordSoft"]),
    "CSS.PROPERTY_NAME": a(P["field"]),
    "CSS.PROPERTY_VALUE": a(TEXT),
    "CSS.KEYWORD": a(P["keyword"]),
    "CSS.FUNCTION": a(P["funcCall"]),
    "CSS.NUMBER": a(P["number"]),
    "CSS.COLOR": a(P["number"]),
    "CSS.STRING": a(P["string"]),
    "CSS.URL": a(P["link"], effect=UNDERLINE, ec=mix(BLUE_B, EDITOR_BG, 0.5)),
    "CSS.IMPORTANT": a(P["keyword"], font=BOLD),
    "CSS.UNICODE.RANGE": a(P["number"]),
    "SASS_VARIABLE": a(P["param"]),
    "SASS_MIXIN": a(P["funcDecl"]),
    "SASS_DIRECTIVE": a(P["keyword"]),
    "LESS_VARIABLE": a(P["param"]),
    "SCSS_VARIABLE": a(P["param"]),

    # ---- Twig
    "TWIG_KEYWORD": a(P["keyword"]),
    "TWIG_IDENTIFIER": a(P["var"]),
    "TWIG_STRING": a(P["string"]),
    "TWIG_NUMBER": a(P["number"]),
    "TWIG_COMMENT": a(P["comment"], font=ITALIC),
    "TWIG_OPERATION_SIGN": a(P["punct"]),
    "TWIG_BRACKETS": a(P["keywordSoft"]),
    "TWIG_BAD_CHARACTER": a(effect=WAVE, ec=ERR),
    "TWIG_BACKGROUND": a(bg=B["template"]),

    # ---- JSON / YAML / properties
    "JSON.PROPERTY_KEY": a(P["field"]),
    "JSON.STRING": a(P["string"]),
    "JSON.NUMBER": a(P["number"]),
    "JSON.KEYWORD": a(P["keyword"]),
    "JSON.BRACES": a(P["punct"]),
    "JSON.BRACKETS": a(P["punct"]),
    "JSON.COLON": a(P["punct"]),
    "JSON.COMMA": a(P["punct"]),
    "JSON.VALID_ESCAPE": a(P["escape"]),
    "JSON.INVALID_ESCAPE": a(P["error"], effect=WAVE, ec=ERR),
    "JSON.LINE_COMMENT": a(P["comment"], font=ITALIC),
    "JSON.BLOCK_COMMENT": a(P["comment"], font=ITALIC),
    "JSON.PARAMETER": a(P["param"]),
    "YAML_SCALAR_KEY": a(P["field"]),
    "YAML_SCALAR_VALUE": a(TEXT),
    "YAML_SCALAR_STRING": a(P["string"]),
    "YAML_SCALAR_DSTRING": a(P["string"]),
    "YAML_SCALAR_LIST": a(TEXT),
    "YAML_TEXT": a(TEXT),
    "YAML_SIGN": a(P["punct"]),
    "YAML_ANCHOR": a(P["constant"]),
    "YAML_COMMENT": a(P["comment"], font=ITALIC),
    "PROPERTIES.KEY": a(P["field"]),
    "PROPERTIES.VALUE": a(P["string"]),
    "PROPERTIES.LINE_COMMENT": a(P["comment"], font=ITALIC),
    "PROPERTIES.VALID_STRING_ESCAPE": a(P["escape"]),
    "PROPERTIES.INVALID_STRING_ESCAPE": a(P["error"], effect=WAVE, ec=ERR),
    "PROPERTIES.KEY_VALUE_SEPARATOR": a(P["punct"]),
    "DOTENV.KEY": a(P["field"]),
    "DOTENV.VALUE": a(P["string"]),

    # ---- Markdown
    "MARKDOWN_HEADER_LEVEL_1": a(P["keyword"], font=BOLD),
    "MARKDOWN_HEADER_LEVEL_2": a(P["keyword"], font=BOLD),
    "MARKDOWN_HEADER_LEVEL_3": a(P["keywordSoft"], font=BOLD),
    "MARKDOWN_HEADER_LEVEL_4": a(P["keywordSoft"]),
    "MARKDOWN_HEADER_LEVEL_5": a(P["keywordSoft"]),
    "MARKDOWN_HEADER_LEVEL_6": a(P["keywordSoft"]),
    "MARKDOWN_HEADER_MARKER": a(P["docTag"]),
    "MARKDOWN_BOLD": a(TEXT, font=BOLD),
    "MARKDOWN_ITALIC": a(TEXT, font=ITALIC),
    "MARKDOWN_STRIKE_THROUGH": a(MUTED, effect=STRIKE, ec=MUTED),
    "MARKDOWN_CODE_SPAN": a(P["string"], B["inlay"]),
    "MARKDOWN_CODE_BLOCK": a(P["string"]),
    "MARKDOWN_CODE_FENCE": a(P["string"]),
    "MARKDOWN_CODE_FENCE_MARKER": a(P["punct"]),
    "MARKDOWN_CODE_FENCE_LANGUAGE": a(P["metadata"]),
    "MARKDOWN_BLOCK_QUOTE": a(P["docComment"], font=ITALIC),
    "MARKDOWN_BLOCK_QUOTE_MARKER": a(P["keyword"]),
    "MARKDOWN_LIST_MARKER": a(P["keyword"]),
    "MARKDOWN_HRULE": a(P["punct"]),
    "MARKDOWN_TABLE_SEPARATOR": a(P["punct"]),
    "MARKDOWN_LINK_TEXT": a(P["link"], effect=UNDERLINE, ec=BLUE_B),
    "MARKDOWN_LINK_DESTINATION": a(P["attr"]),
    "MARKDOWN_LINK_LABEL": a(P["attr"]),
    "MARKDOWN_LINK_TITLE": a(P["string"]),
    "MARKDOWN_AUTO_LINK": a(P["link"], effect=UNDERLINE, ec=BLUE_B),
    "MARKDOWN_EXPLICIT_LINK": a(P["link"]),
    "MARKDOWN_REFERENCE_LINK": a(P["link"]),
    "MARKDOWN_IMAGE": a(P["attr"]),
    "MARKDOWN_COMMENT": a(P["comment"], font=ITALIC),
    "MARKDOWN_HTML_BLOCK": a(P["comment"]),
    "MARKDOWN_INLINE_HTML": a(P["tag"]),

    # ---- Regexp / SQL / Shell (commonly met in PHP projects)
    "REGEXP.CHAR_CLASS": a(P["type"]),
    "REGEXP.META": a(P["keyword"]),
    "REGEXP.ESC_CHARACTER": a(P["escape"]),
    "REGEXP.BRACES": a(P["punct"]),
    "REGEXP.BRACKETS": a(P["punct"]),
    "REGEXP.PARENTHS": a(P["punct"]),
    "SQL_KEYWORD": a(P["keyword"]),
    "SQL_TABLE": a(P["type"]),
    "SQL_COLUMN": a(P["field"]),
    "SQL_STRING": a(P["string"]),
    "SQL_NUMBER": a(P["number"]),
    "SQL_PARAMETER": a(P["param"]),
    "SQL_COMMENT": a(P["comment"], font=ITALIC),
    "SQL_PROCEDURE": a(P["funcCall"]),
    "BASH.KEYWORD": a(P["keyword"]),
    "BASH.STRING": a(P["string"]),
    "BASH.STRING2": a(P["string"]),
    "BASH.VAR_USE": a(P["param"]),
    "BASH.VAR_DEF": a(P["param"]),
    "BASH.INTERNAL_COMMAND": a(P["funcCall"]),
    "BASH.EXTERNAL_COMMAND": a(P["funcCall"]),
    "BASH.NUMBER": a(P["number"]),
    "BASH.SHEBANG": a(P["comment"], font=ITALIC),
}

for k, v in ANSI.items():
    attrs[f"CONSOLE_{k}_OUTPUT"] = a(v)


# --------------------------------------------------------------------------
# validation: contrast
# --------------------------------------------------------------------------

def check_contrast() -> list[str]:
    problems = []
    for name, at in attrs.items():
        fg = at["fg"]
        if not fg or name in ("NOT_USED_ELEMENT_ATTRIBUTES", "BREADCRUMBS_INACTIVE",
                              "DELETED_TEXT_ATTRIBUTES", "FOLDED_TEXT_ATTRIBUTES",
                              "BREADCRUMBS_DEFAULT", "LOG_EXPIRED_ENTRY"):
            continue
        bg = at["bg"] or (CONSOLE_BG if name.startswith(("CONSOLE_", "LOG_")) else EDITOR_BG)
        r = contrast(fg, bg)
        if r < MIN_CONTRAST:
            problems.append(f"{name}: {fg} on {bg} = {r:.2f}")
    # plain text on selection / caret row / search highlights
    for bgname in ("selection", "caretRow", "readUsage", "writeUsage", "searchResult",
                   "textSearch", "diffAdd", "diffDel", "diffMod", "diffConflict"):
        r = contrast(TEXT, B[bgname])
        if r < MIN_CONTRAST:
            problems.append(f"text on {bgname}: {r:.2f}")
    return problems


# --------------------------------------------------------------------------
# writers
# --------------------------------------------------------------------------

def build_icls() -> str:
    out = [f'<scheme name={quoteattr(SCHEME_NAME)} version="142" parent_scheme="Darcula">']
    out.append("  <metaInfo>")
    out.append('    <property name="ide">PhpStorm</property>')
    out.append(f'    <property name="ideVersion">2026.2</property>')
    out.append('    <property name="originalScheme">Aperture OS</property>')
    out.append("  </metaInfo>")
    out.append("  <colors>")
    for k in sorted(scheme_colors):
        v = scheme_colors[k]
        out.append(f'    <option name={quoteattr(k)} value="{x(v) if v else ""}" />')
    out.append("  </colors>")
    out.append("  <attributes>")
    for k in sorted(attrs):
        at = attrs[k]
        if at["base"]:
            out.append(f'    <option name={quoteattr(k)} baseAttributes={quoteattr(at["base"])} />')
            continue
        out.append(f"    <option name={quoteattr(k)}>")
        out.append("      <value>")
        if at["fg"]:
            out.append(f'        <option name="FOREGROUND" value="{x(at["fg"])}" />')
        if at["bg"]:
            out.append(f'        <option name="BACKGROUND" value="{x(at["bg"])}" />')
        if at["font"]:
            out.append(f'        <option name="FONT_TYPE" value="{at["font"]}" />')
        if at["ec"]:
            out.append(f'        <option name="EFFECT_COLOR" value="{x(at["ec"])}" />')
        if at["effect"] is not None:
            out.append(f'        <option name="EFFECT_TYPE" value="{at["effect"]}" />')
        if at["stripe"]:
            out.append(f'        <option name="ERROR_STRIPE_COLOR" value="{x(at["stripe"])}" />')
        out.append("      </value>")
        out.append("    </option>")
    out.append("  </attributes>")
    out.append("</scheme>")
    return "\n".join(out) + "\n"


def build_plugin_xml() -> str:
    version = tokens.get("version", "1.0.0")
    return f"""<idea-plugin>
  <id>{PLUGIN_ID}</id>
  <name>Aperture OS Theme</name>
  <version>{version}</version>
  <vendor>Aperture OS</vendor>
  <description><![CDATA[
    <p>Aperture OS: calm industrial test-chamber UI theme and editor color scheme.</p>
    <p>Orange = interaction/focus, blue = information. Generated from design tokens.</p>
  ]]></description>
  <idea-version since-build="253"/>
  <depends>com.intellij.modules.platform</depends>
  <extensions defaultExtensionNs="com.intellij">
    <themeProvider id="{THEME_ID}" path="/{JAR_THEME_PATH}" targetUi="islands"/>
    <bundledColorScheme id="{SCHEME_ID}" path="/{JAR_SCHEME_BASE}"/>
  </extensions>
</idea-plugin>
"""


def main() -> int:
    problems = check_contrast()
    if problems:
        print("contrast check FAILED (< %.1f:1):" % MIN_CONTRAST, file=sys.stderr)
        for p in problems:
            print("  " + p, file=sys.stderr)
        return 1

    (RES / "META-INF").mkdir(parents=True, exist_ok=True)
    DIST.mkdir(parents=True, exist_ok=True)

    theme_json = json.dumps(theme, indent=2, ensure_ascii=False) + "\n"
    icls = build_icls()
    plugin_xml = build_plugin_xml()

    # validate
    json.loads(theme_json)
    minidom.parseString(icls)
    minidom.parseString(plugin_xml)

    (RES / "aperture-os.theme.json").write_text(theme_json, encoding="utf-8")
    (RES / "ApertureOS.icls").write_text(icls, encoding="utf-8")
    (RES / "META-INF" / "plugin.xml").write_text(plugin_xml, encoding="utf-8")

    jar = DIST / "aperture-os-theme.jar"
    # fixed timestamp -> reproducible jar
    def add(zf: zipfile.ZipFile, name: str, data: str) -> None:
        info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        zf.writestr(info, data.encode("utf-8"))

    with zipfile.ZipFile(jar, "w") as zf:
        add(zf, "META-INF/MANIFEST.MF", "Manifest-Version: 1.0\r\nCreated-By: aperture-os tools/build.py\r\n\r\n")
        add(zf, "META-INF/plugin.xml", plugin_xml)
        add(zf, JAR_THEME_PATH, theme_json)
        add(zf, JAR_SCHEME_BASE + ".xml", icls)

    # report
    print(f"theme   -> {RES / 'aperture-os.theme.json'}")
    print(f"scheme  -> {RES / 'ApertureOS.icls'}  ({len(attrs)} attributes)")
    print(f"plugin  -> {RES / 'META-INF' / 'plugin.xml'}")
    print(f"jar     -> {jar}")
    print(f"editor background {EDITOR_BG}; syntax contrast:")
    for k in sorted(P):
        print(f"  {k:12s} {P[k]}  {contrast(P[k], EDITOR_BG):5.2f}:1")
    print(f"  selection bg {B['selection']}  text {contrast(TEXT, B['selection']):.2f}:1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
