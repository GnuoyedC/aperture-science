#!/usr/bin/env python3
"""Aperture-cursors builder.

Draws every cursor procedurally with Pillow (supersampled, then box-filtered
down for clean antialiasing) and writes Xcursor files directly - no inkscape,
rsvg-convert or xcursorgen required.

    python3 tools/build.py            # build theme + preview.png
    python3 tools/build.py --no-preview

Reads colours and motion settings only from ../tokens.json.
Requires: Python 3.8+, Pillow (python3-pil).
"""

import json
import math
import os
import shutil
import struct
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME_DIR = os.path.join(ROOT, "Aperture-cursors")
CURSOR_DIR = os.path.join(THEME_DIR, "cursors")

with open(os.path.join(ROOT, "tokens.json"), encoding="utf-8") as fh:
    TOKENS = json.load(fh)

C = TOKENS["color"]
MOTION = TOKENS.get("motion", {})

# Nominal sizes written into every cursor file.  libXcursor / KWin pick the
# closest one for the configured cursor size (24 is the Plasma default).
SIZES = [24, 32, 36, 48, 64, 72, 96]
SS = 8            # supersampling factor
GRID = 32.0       # design grid: every cursor is designed on a 32x32 unit grid
OUTLINE = 1.45    # light outline width in grid units
WAIT_FRAMES = 1 if MOTION.get("reduceMotion") else 12
WAIT_DELAY = 70   # ms per frame -> ~0.84 s per revolution


def rgb(hexstr):
    h = hexstr.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


BODY = rgb(C["surface"])
EDGE = rgb(C["text"])
DARK = rgb(C["background"])
ORANGE = rgb(C["orange"])
ORANGE_DIM = rgb(C["orangeDim"])
BLUE = rgb(C["blue"])
BLUE_BRIGHT = rgb(C["blueBright"])
LINE = rgb(C["borderStrong"])
ERROR = rgb(C["error"])


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


# --------------------------------------------------------------------------
# Geometry helpers (all coordinates in grid units)
# --------------------------------------------------------------------------

def rot(pts, deg, cx=16.0, cy=16.0):
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa,
             cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def xform(pts, scale=1.0, dx=0.0, dy=0.0, ox=0.0, oy=0.0):
    return [(ox + (x - ox) * scale + dx, oy + (y - oy) * scale + dy) for x, y in pts]


class Pen:
    """Draws onto supersampled L masks using grid units."""

    def __init__(self, size):
        self.size = size
        self.px = size * SS
        self.k = self.px / GRID

    def new(self):
        return Image.new("L", (self.px, self.px), 0)

    def _p(self, pts):
        return [(x * self.k, y * self.k) for x, y in pts]

    def poly(self, m, pts, fill=255):
        ImageDraw.Draw(m).polygon(self._p(pts), fill=fill)
        return m

    def circle(self, m, cx, cy, r, fill=255):
        k = self.k
        ImageDraw.Draw(m).ellipse([(cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k], fill=fill)
        return m

    def rrect(self, m, x0, y0, x1, y1, r, fill=255):
        k = self.k
        ImageDraw.Draw(m).rounded_rectangle([x0 * k, y0 * k, x1 * k, y1 * k], radius=r * k, fill=fill)
        return m

    def line(self, m, p0, p1, w, fill=255, caps=True):
        k = self.k
        ImageDraw.Draw(m).line([(p0[0] * k, p0[1] * k), (p1[0] * k, p1[1] * k)], fill=fill, width=max(1, round(w * k)))
        if caps:
            self.circle(m, p0[0], p0[1], w / 2, fill)
            self.circle(m, p1[0], p1[1], w / 2, fill)
        return m

    def ring_sector(self, m, cx, cy, r0, r1, a0, a1, skew=0.0, fill=255, steps=24):
        """Annulus sector a0..a1 (degrees, 0 = east, clockwise on screen).
        `skew` shifts the inner edge angularly (iris blade look)."""
        pts = []
        for i in range(steps + 1):
            a = math.radians(a0 + (a1 - a0) * i / steps)
            pts.append((cx + r1 * math.cos(a), cy + r1 * math.sin(a)))
        for i in range(steps, -1, -1):
            a = math.radians(a0 + skew + (a1 - a0) * i / steps)
            pts.append((cx + r0 * math.cos(a), cy + r0 * math.sin(a)))
        return self.poly(m, pts, fill)

    def tapered_arc(self, m, cx, cy, r, a0, a1, w, taper=0.35, fill=255, steps=64):
        """Arc stroke whose ends taper to a point (Portal crosshair brackets)."""
        outer, inner = [], []
        for i in range(steps + 1):
            t = i / steps
            edge = min(t, 1 - t) / taper
            h = w / 2 * min(1.0, 0.25 + 0.75 * math.sin(min(1.0, edge) * math.pi / 2))
            a = math.radians(a0 + (a1 - a0) * t)
            outer.append((cx + (r + h) * math.cos(a), cy + (r + h) * math.sin(a)))
            inner.append((cx + (r - h) * math.cos(a), cy + (r - h) * math.sin(a)))
        return self.poly(m, outer + inner[::-1], fill)


def union(*ms):
    out = ms[0]
    for m in ms[1:]:
        out = ImageChops.lighter(out, m)
    return out


def subtract(a, b):
    return ImageChops.subtract(a, b)


def intersect(a, b):
    return ImageChops.multiply(a, b)


def dilate(pen, m, units):
    """Round dilation via gaussian blur + threshold (exact enough at 8x SS)."""
    if units <= 0:
        return m
    sigma = units * pen.k / 2.05
    b = m.filter(ImageFilter.GaussianBlur(sigma))
    return b.point(lambda v: 255 if v > 5 else 0)


def shift(m, dx, dy):
    """Translate without wrap-around (ImageChops.offset wraps)."""
    out = Image.new(m.mode, m.size, 0)
    out.paste(m, (round(dx), round(dy)))
    return out


# --------------------------------------------------------------------------
# Compositing
# --------------------------------------------------------------------------

class Sprite:
    def __init__(self, pen, sil, body=BODY, edge=EDGE, outline=OUTLINE, shadow=True):
        self.pen = pen
        self.sil = sil
        self.body = body
        self.edge = edge
        self.outline = outline
        self.shadow = shadow
        self.layers = []          # (mask, rgb)

    def add(self, mask, color, clip=True):
        if clip:
            mask = intersect(mask, self.sil)
        self.layers.append((mask, color))
        return self

    def render(self):
        pen = self.pen
        img = Image.new("RGBA", (pen.px, pen.px), (0, 0, 0, 0))
        out = dilate(pen, self.sil, self.outline)
        if self.shadow:
            sh = shift(out, 0.35 * pen.k, 0.7 * pen.k)
            sh = sh.filter(ImageFilter.GaussianBlur(0.9 * pen.k))
            sh = sh.point(lambda v: v * 0.32)
            img.paste((0, 0, 0, 255), (0, 0), sh)
        # paste() replaces RGBA, so composite layers with alpha_composite.
        for mask, col in [(out, self.edge), (self.sil, self.body)] + self.layers:
            layer = Image.new("RGBA", img.size, col + (0,))
            layer.putalpha(mask)
            img = Image.alpha_composite(img, layer)
        return img


def downsample(img, size):
    """Supersampled RGBA -> premultiplied RGBa at nominal size (box filter = exact coverage)."""
    return img.convert("RGBa").resize((size, size), Image.Resampling.BOX)


# --------------------------------------------------------------------------
# Cursor shapes
# --------------------------------------------------------------------------

ARROW = [(4.0, 2.6), (4.0, 24.6), (9.4, 19.6), (12.9, 27.6), (16.6, 26.0),
         (13.1, 18.4), (20.4, 18.4)]
ARROW_HOT = (4.0, 2.6)


def arrow_layers(pen, scale=1.0):
    """Default arrow: dark body, light outline, orange accent wedge along the spine."""
    pts = xform(ARROW, scale, ox=4.0, oy=2.6)
    sil = pen.poly(pen.new(), pts)
    accent = pen.poly(pen.new(), xform([(5.7, 7.3), (5.7, 17.8), (11.4, 13.6)], scale, ox=4.0, oy=2.6))
    return sil, [(accent, ORANGE)]


def make_arrow(pen):
    sil, acc = arrow_layers(pen)
    s = Sprite(pen, sil)
    for m, c in acc:
        s.add(m, c)
    return s.render(), ARROW_HOT


def iris_masks(pen, cx, cy, r_out, r_in, angle, blades=8, gap=7.0, skew=24.0):
    ms = []
    span = 360.0 / blades
    for i in range(blades):
        a0 = angle + i * span
        ms.append(pen.ring_sector(pen.new(), cx, cy, r_in, r_out, a0, a0 + span - gap, skew=skew))
    return ms


def blade_colors(n):
    # head bright orange, then fading through dim orange into the steel line colour
    # Calm: only the leading blades are orange, the rest is steel.
    steel = mix(LINE, BODY, 0.25)
    tail = [ORANGE, mix(ORANGE, ORANGE_DIM, 0.55), mix(ORANGE_DIM, steel, 0.45)]
    return (tail + [steel] * n)[:n]


def add_iris(sprite, pen, cx, cy, r, angle, small=False):
    if small:
        blades = iris_masks(pen, cx, cy, r * 0.80, r * 0.42, angle, blades=8, gap=10.0, skew=14.0)
    else:
        blades = iris_masks(pen, cx, cy, r * 0.84, r * 0.34, angle, blades=8, gap=6.5, skew=26.0)
    # reverse so the brightest blade leads in rotation direction (clockwise)
    for m, col in zip(blades[::-1], blade_colors(len(blades))):
        sprite.add(m, col)


def make_wait(pen, frame):
    cx = cy = 16.0
    r = 12.2
    sil = pen.circle(pen.new(), cx, cy, r)
    s = Sprite(pen, sil)
    add_iris(s, pen, cx, cy, r, -90 + frame * 360.0 / WAIT_FRAMES)
    return s.render(), (16, 16)


def make_progress(pen, frame):
    sil, acc = arrow_layers(pen, scale=0.86)
    cx, cy, r = 22.4, 22.4, 7.3
    disc = pen.circle(pen.new(), cx, cy, r)
    s = Sprite(pen, union(sil, disc))
    for m, c in acc:
        s.add(m, c)
    # thin light separator between arrow and badge
    sep = subtract(pen.circle(pen.new(), cx, cy, r + 0.9), disc)
    s.add(sep, EDGE)
    add_iris(s, pen, cx, cy, r, -90 + frame * 360.0 / WAIT_FRAMES, small=True)
    return s.render(), ARROW_HOT


def make_help(pen):
    sil, acc = arrow_layers(pen, scale=0.86)
    cx, cy, r = 22.4, 22.4, 7.3
    disc = pen.circle(pen.new(), cx, cy, r)
    s = Sprite(pen, union(sil, disc))
    for m, c in acc:
        s.add(m, c)
    sep = subtract(pen.circle(pen.new(), cx, cy, r + 0.9), disc)
    s.add(sep, EDGE)
    # question mark (blue = information)
    q = pen.new()
    k = pen.k
    qr = 2.55
    qcx, qcy = cx, cy - 1.75
    w = 1.75
    ImageDraw.Draw(q).arc([(qcx - qr) * k, (qcy - qr) * k, (qcx + qr) * k, (qcy + qr) * k],
                          start=170, end=410, fill=255, width=round(w * k))
    end_a = math.radians(410)
    ex = qcx + (qr - w / 2) * math.cos(end_a)
    ey = qcy + (qr - w / 2) * math.sin(end_a)
    pen.circle(q, qcx + (qr - w / 2) * math.cos(math.radians(170)), qcy + (qr - w / 2) * math.sin(math.radians(170)), w / 2)
    pen.line(q, (ex, ey), (cx, cy + 1.6), w)
    pen.circle(q, cx, cy + 4.45, 1.05)
    s.add(q, BLUE_BRIGHT)
    return s.render(), ARROW_HOT


def make_text(pen):
    sil = union(
        pen.rrect(pen.new(), 14.9, 4.8, 17.1, 27.2, 0.3),
        pen.rrect(pen.new(), 11.4, 3.4, 20.6, 5.6, 0.6),
        pen.rrect(pen.new(), 11.4, 26.4, 20.6, 28.6, 0.6),
    )
    # orange caret tick, slightly wider than the stem (part of the silhouette)
    tick = pen.rrect(pen.new(), 13.6, 14.7, 18.4, 17.3, 0.4)
    s = Sprite(pen, union(sil, tick))
    s.add(tick, ORANGE)
    return s.render(), (16, 16)


def make_crosshair(pen):
    cx = cy = 16.0
    r, w = 9.6, 2.9
    left = pen.tapered_arc(pen.new(), cx, cy, r, 112, 248, w)
    right = pen.tapered_arc(pen.new(), cx, cy, r, -68, 68, w)
    dot = pen.circle(pen.new(), cx, cy, 1.25)
    sil = union(left, right, dot)
    s = Sprite(pen, sil, body=DARK, edge=DARK, outline=1.1, shadow=False)
    s.add(left, BLUE)
    s.add(right, ORANGE)
    s.add(dot, EDGE)
    return s.render(), (16, 16)


def double_arrow(pen, angle, accent=True):
    # vertical template centred at (16,16), rotated by `angle`
    hw, head_w, tip, base = 1.5, 5.6, 13.0, 6.4
    shaft = [(16 - hw, 16 - base), (16 + hw, 16 - base), (16 + hw, 16 + base), (16 - hw, 16 + base)]
    up = [(16, 16 - tip), (16 + head_w, 16 - base + 0.2), (16 - head_w, 16 - base + 0.2)]
    dn = [(16, 16 + tip), (16 - head_w, 16 + base - 0.2), (16 + head_w, 16 + base - 0.2)]
    sil = union(pen.poly(pen.new(), rot(shaft, angle)),
                pen.poly(pen.new(), rot(up, angle)),
                pen.poly(pen.new(), rot(dn, angle)))
    s = Sprite(pen, sil)
    if accent:
        bar = [(16 - 3.0, 16 - 0.8), (16 + 3.0, 16 - 0.8), (16 + 3.0, 16 + 0.8), (16 - 3.0, 16 + 0.8)]
        bar_m = pen.poly(pen.new(), rot(bar, angle))
        s.sil = union(s.sil, bar_m)
        s.add(bar_m, ORANGE)
    return s.render(), (16, 16)


def make_move(pen):
    hw, head_w, tip, base = 1.3, 4.3, 13.0, 8.4
    parts = []
    for a in (0, 90, 180, 270):
        shaft = [(16 - hw, 16 - base + 0.5), (16 + hw, 16 - base + 0.5), (16 + hw, 16), (16 - hw, 16)]
        head = [(16, 16 - tip), (16 + head_w, 16 - base), (16 - head_w, 16 - base)]
        parts.append(pen.poly(pen.new(), rot(shaft, a)))
        parts.append(pen.poly(pen.new(), rot(head, a)))
    hub = pen.poly(pen.new(), rot([(13.6, 13.6), (18.4, 13.6), (18.4, 18.4), (13.6, 18.4)], 45))
    sil = union(*parts, hub)
    s = Sprite(pen, sil)
    s.add(pen.poly(pen.new(), rot([(14.6, 14.6), (17.4, 14.6), (17.4, 17.4), (14.6, 17.4)], 45)), ORANGE)
    return s.render(), (16, 16)


def make_not_allowed(pen):
    cx = cy = 16.0
    ro, ri = 10.6, 7.6
    ring = subtract(pen.circle(pen.new(), cx, cy, ro), pen.circle(pen.new(), cx, cy, ri))
    slash = pen.poly(pen.new(), rot([(16 - 1.55, 16 - ri - 0.5), (16 + 1.55, 16 - ri - 0.5),
                                     (16 + 1.55, 16 + ri + 0.5), (16 - 1.55, 16 + ri + 0.5)], -45))
    sil = union(ring, slash)
    # dark inner disc behind the sign keeps it readable on any background
    disc = pen.circle(pen.new(), cx, cy, ri)
    s = Sprite(pen, union(sil, disc))
    s.add(sil, ERROR)
    return s.render(), (16, 16)


def _hand(pen, kind):
    """kind: pointer | open | grab.  Returns (sprite, hotspot)."""
    m = []
    lines = []
    if kind == "pointer":
        m.append(pen.rrect(pen.new(), 9.6, 1.8, 13.9, 19.0, 2.15))       # index
        m.append(pen.rrect(pen.new(), 13.4, 10.4, 17.4, 20.0, 1.9))      # middle (folded)
        m.append(pen.rrect(pen.new(), 16.9, 11.6, 20.8, 20.6, 1.85))     # ring
        m.append(pen.rrect(pen.new(), 20.3, 13.0, 23.9, 21.2, 1.75))     # pinky
        m.append(pen.rrect(pen.new(), 9.6, 15.0, 23.9, 26.8, 3.6))       # palm
        m.append(pen.line(pen.new(), (10.6, 22.2), (5.2, 15.6), 3.7))    # thumb
        m.append(pen.rrect(pen.new(), 11.4, 24.0, 22.2, 29.6, 1.0))      # cuff
        lines = [((13.65, 11.6), (13.65, 17.6)), ((17.15, 12.6), (17.15, 18.2)), ((20.55, 14.2), (20.55, 18.8))]
        cuff = pen.rrect(pen.new(), 11.4, 26.6, 22.2, 29.6, 1.0)
        hot = (11.7, 1.9)
    elif kind == "open":
        m.append(pen.rrect(pen.new(), 9.2, 5.2, 13.0, 18.0, 1.9))
        m.append(pen.rrect(pen.new(), 12.6, 3.2, 16.6, 18.0, 2.0))
        m.append(pen.rrect(pen.new(), 16.2, 4.2, 20.1, 18.0, 1.95))
        m.append(pen.rrect(pen.new(), 19.7, 7.2, 23.3, 19.0, 1.8))
        m.append(pen.rrect(pen.new(), 9.2, 14.6, 23.3, 26.6, 3.6))
        m.append(pen.line(pen.new(), (10.4, 21.8), (4.8, 14.6), 3.7))
        m.append(pen.rrect(pen.new(), 10.9, 24.0, 21.6, 29.6, 1.0))
        lines = [((12.8, 8.0), (12.8, 16.4)), ((16.4, 7.0), (16.4, 16.4)), ((19.9, 9.4), (19.9, 16.8))]
        cuff = pen.rrect(pen.new(), 10.9, 26.6, 21.6, 29.6, 1.0)
        hot = (16, 15)
    else:  # grab / closed
        m.append(pen.rrect(pen.new(), 9.2, 10.0, 13.0, 18.6, 1.9))
        m.append(pen.rrect(pen.new(), 12.6, 9.0, 16.6, 18.6, 2.0))
        m.append(pen.rrect(pen.new(), 16.2, 9.6, 20.1, 18.6, 1.95))
        m.append(pen.rrect(pen.new(), 19.7, 11.0, 23.3, 19.4, 1.8))
        m.append(pen.rrect(pen.new(), 9.2, 14.6, 23.3, 26.6, 3.6))
        m.append(pen.line(pen.new(), (10.4, 21.8), (7.2, 16.8), 3.7))
        m.append(pen.rrect(pen.new(), 10.9, 24.0, 21.6, 29.6, 1.0))
        lines = [((12.8, 11.6), (12.8, 16.6)), ((16.4, 11.0), (16.4, 16.6)), ((19.9, 12.6), (19.9, 17.0))]
        cuff = pen.rrect(pen.new(), 10.9, 26.6, 21.6, 29.6, 1.0)
        hot = (16, 17)
    s = Sprite(pen, union(*m))
    for p0, p1 in lines:
        s.add(pen.line(pen.new(), p0, p1, 0.75), EDGE)
    # orange cuff = Aperture test-subject glove band
    s.add(cuff, ORANGE)
    s.add(pen.rrect(pen.new(), 9.0, 25.7, 25.0, 26.6, 0), EDGE)
    return s.render(), hot


def make_pointer(pen):
    return _hand(pen, "pointer")


def make_openhand(pen):
    return _hand(pen, "open")


def make_grabbing(pen):
    return _hand(pen, "grab")


# --------------------------------------------------------------------------
# Cursor table and aliases
# --------------------------------------------------------------------------

CURSORS = {
    # file name: (maker, animated)
    "default":     (make_arrow, False),
    "pointer":     (make_pointer, False),
    "text":        (make_text, False),
    "wait":        (make_wait, True),
    "progress":    (make_progress, True),
    "crosshair":   (make_crosshair, False),
    "help":        (make_help, False),
    "not-allowed": (make_not_allowed, False),
    "move":        (make_move, False),
    "ns-resize":   (lambda p: double_arrow(p, 0), False),
    "ew-resize":   (lambda p: double_arrow(p, 90), False),
    "nwse-resize": (lambda p: double_arrow(p, -45), False),
    "nesw-resize": (lambda p: double_arrow(p, 45), False),
    "grab":        (make_openhand, False),
    "grabbing":    (make_grabbing, False),
}

ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "left-arrow"],
    "pointer": ["hand", "hand1", "hand2", "pointing_hand",
                "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"],
    "text": ["xterm", "ibeam"],
    "wait": ["watch"],
    "progress": ["left_ptr_watch", "half-busy",
                 "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd",
                 "3ecb610c1bf2410f44200f48c40d3599"],
    "crosshair": ["cross", "tcross", "cross_reverse", "diamond_cross"],
    "not-allowed": ["forbidden", "crossed_circle", "circle", "no-drop", "dnd-no-drop",
                    "03b6e0fcb3499374a867c041f52298f0"],
    "help": ["question_arrow", "whats_this", "left_ptr_help",
             "5c6cd98b3f3ebcb1f9c7f1c204630408", "d9ce0ab605698f320427677b458ad60b"],
    "move": ["fleur", "all-scroll", "size_all", "dnd-move",
             "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f",
             "fcf21c00b30f7e3f83fe0dfd12e71cff"],
    "ns-resize": ["n-resize", "s-resize", "row-resize", "sb_v_double_arrow", "v_double_arrow",
                  "size_ver", "size-ver", "top_side", "bottom_side", "split_v",
                  "00008160000006810000408080010102", "2870a09082c103050810ffdffffe0204"],
    "ew-resize": ["e-resize", "w-resize", "col-resize", "sb_h_double_arrow", "h_double_arrow",
                  "size_hor", "size-hor", "left_side", "right_side", "split_h",
                  "028006030e0e7ebffc7f7070c0600140", "14fef782d02440884392942c11205230"],
    "nwse-resize": ["nw-resize", "se-resize", "size_fdiag", "size-fdiag", "bd_double_arrow",
                    "top_left_corner", "bottom_right_corner",
                    "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["ne-resize", "sw-resize", "size_bdiag", "size-bdiag", "fd_double_arrow",
                    "top_right_corner", "bottom_left_corner",
                    "fcf1c3c7cd4491d801f1e1c78f100000"],
    "grab": ["openhand", "9141b49c8149039304290b508d208c40", "5aca4d189052212118709018842178c0"],
    "grabbing": ["closedhand", "dnd-none", "208530c400c041818281048008011002"],
}


# --------------------------------------------------------------------------
# Xcursor writer
# --------------------------------------------------------------------------

XCURSOR_MAGIC = b"Xcur"
XCURSOR_FILE_HEADER_LEN = 16
XCURSOR_FILE_VERSION = 0x00010000
XCURSOR_IMAGE_TYPE = 0xFFFD0002
XCURSOR_IMAGE_VERSION = 1
XCURSOR_IMAGE_HEADER_LEN = 36


def premul_to_argb_le(img):
    """RGBa (premultiplied, bytes R,G,B,a) -> little-endian ARGB32 bytes (B,G,R,A)."""
    r, g, b, a = img.split()
    return Image.merge("RGBa", (b, g, r, a)).tobytes()


def write_xcursor(path, images):
    """images: list of (nominal, width, height, xhot, yhot, delay, pixel_bytes)."""
    n = len(images)
    toc_len = 12 * n
    pos = XCURSOR_FILE_HEADER_LEN + toc_len
    header = struct.pack("<4sIII", XCURSOR_MAGIC, XCURSOR_FILE_HEADER_LEN, XCURSOR_FILE_VERSION, n)
    toc = b""
    chunks = b""
    for nominal, w, h, xh, yh, delay, pix in images:
        assert len(pix) == w * h * 4
        toc += struct.pack("<III", XCURSOR_IMAGE_TYPE, nominal, pos)
        chunk = struct.pack("<IIIIIIIII", XCURSOR_IMAGE_HEADER_LEN, XCURSOR_IMAGE_TYPE, nominal,
                            XCURSOR_IMAGE_VERSION, w, h, xh, yh, delay) + pix
        chunks += chunk
        pos += len(chunk)
    with open(path, "wb") as fh:
        fh.write(header + toc + chunks)


def build_cursor(name, maker, animated):
    images = []
    previews = {}
    frames = WAIT_FRAMES if animated else 1
    for size in SIZES:
        pen = Pen(size)
        for f in range(frames):
            big, hot = maker(pen, f) if animated else maker(pen)
            small = downsample(big, size)
            k = size / GRID
            xh = min(size - 1, max(0, int(round(hot[0] * k - 0.01))))
            yh = min(size - 1, max(0, int(round(hot[1] * k - 0.01))))
            delay = WAIT_DELAY if frames > 1 else 0
            images.append((size, size, size, xh, yh, delay, premul_to_argb_le(small)))
            previews.setdefault(size, []).append((small.convert("RGBA"), (xh, yh)))
    write_xcursor(os.path.join(CURSOR_DIR, name), images)
    return previews


def write_index_theme():
    with open(os.path.join(THEME_DIR, "index.theme"), "w", encoding="utf-8") as fh:
        fh.write("[Icon Theme]\n"
                 "Name=Aperture Cursors\n"
                 "Comment=Aperture OS cursor theme - Aperture Laboratories inspired (optional)\n"
                 "Inherits=breeze_cursors\n")


def write_aliases():
    for target, names in ALIASES.items():
        for n in names:
            if n in CURSORS:
                continue
            p = os.path.join(CURSOR_DIR, n)
            if os.path.lexists(p):
                os.remove(p)
            os.symlink(target, p)


# --------------------------------------------------------------------------
# Preview
# --------------------------------------------------------------------------

def render_preview(all_previews, path):
    order = list(CURSORS.keys())
    sizes = [24, 32, 48]
    cell = 64
    label_h = 14
    pad = 12
    strips = [(rgb(C["background"]), rgb(C["textMuted"])), ((0xEE, 0xF1, 0xF3), (0x56, 0x66, 0x6F))]
    width = pad * 2 + cell * len(order)
    row_h = cell
    strip_h = label_h + row_h * len(sizes) + pad
    height = pad + strip_h * len(strips) + 3 * row_h // 2 + pad
    img = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    d = ImageDraw.Draw(img)
    y = pad
    for bg, fg in strips:
        d.rectangle([0, y - pad, width, y + strip_h], fill=bg + (255,))
        for i, name in enumerate(order):
            label = name if len(name) <= 10 else name[:9] + "."
            d.text((pad + i * cell + 2, y), label, fill=fg + (255,))
        for j, size in enumerate(sizes):
            for i, name in enumerate(order):
                cur, _ = all_previews[name][size][0]
                x0 = pad + i * cell + (cell - size) // 2
                y0 = y + label_h + j * row_h + (row_h - size) // 2
                img.alpha_composite(cur, (x0, y0))
        y += strip_h + pad
    # animation strip: all wait frames at 48 on dark and light halves
    frames = all_previews["wait"][48]
    half = width // 2
    d.rectangle([0, y - pad, half, height], fill=strips[0][0] + (255,))
    d.rectangle([half, y - pad, width, height], fill=strips[1][0] + (255,))
    for i, (fr, _) in enumerate(frames[:12]):
        step = (half - 2 * pad) // max(1, len(frames))
        img.alpha_composite(fr, (pad + i * step, y))
        img.alpha_composite(fr, (half + pad + i * step, y))
    img.convert("RGB").save(path)


def main():
    if os.path.isdir(CURSOR_DIR):
        shutil.rmtree(CURSOR_DIR)
    os.makedirs(CURSOR_DIR)
    write_index_theme()
    all_previews = {}
    for name, (maker, animated) in CURSORS.items():
        all_previews[name] = build_cursor(name, maker, animated)
        print(f"  built {name}")
    write_aliases()
    if "--no-preview" not in sys.argv:
        render_preview(all_previews, os.path.join(ROOT, "preview.png"))
        print("  wrote preview.png")
    print(f"Done: {len(CURSORS)} cursors, {sum(len(v) for v in ALIASES.values())} aliases -> {THEME_DIR}")


if __name__ == "__main__":
    main()
