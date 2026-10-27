#!/usr/bin/env python3
"""Generates assets/aperture-logo.svg: an eight-bladed camera-iris emblem.

Each blade is bounded by two neighbouring tangent lines of the inner hole
(shifted apart by half the gap width) and the outer circle. Re-run this script
to tweak blade count, hole size or gap width.
"""
import math
from pathlib import Path

BLADES = 8
R_OUT = 48.0     # outer radius (viewBox is 100x100, centre 50/50)
R_IN = 17.0      # radius of the inner hole (tangent circle)
GAP = 4.2        # width of the gaps between blades
FILL = "#D9E1E8"
CX = CY = 50.0


def line(i, shift):
    """Tangent line i as (normal, offset): points p with n.p == offset."""
    a = 2 * math.pi * i / BLADES
    n = (math.cos(a), math.sin(a))
    return n, R_IN + shift


def intersect(l1, l2):
    (a1, b1), c1 = l1
    (a2, b2), c2 = l2
    det = a1 * b2 - a2 * b1
    return ((c1 * b2 - c2 * b1) / det, (a1 * c2 - a2 * c1) / det)


def circle_hit(l, direction_sign):
    """Intersection of line l with the outer circle, picking one side."""
    (nx, ny), c = l
    d = (-ny, nx)
    base = (nx * c, ny * c)
    t = math.sqrt(R_OUT ** 2 - c ** 2) * direction_sign
    return (base[0] + d[0] * t, base[1] + d[1] * t)


def blade(i):
    # Blade i sits between tangent line i and tangent line i + 1. Shifting the
    # lines along their normals (towards the blade) opens the gaps.
    la = line(i, -GAP / 2)
    lb = line(i + 1, GAP / 2)
    # Rotate the "outer" side of each line so the blades form a pinwheel.
    v = intersect(la, lb)
    oa = circle_hit(la, +1)
    ob = circle_hit(lb, +1)
    pts = [v, oa]
    return pts, ob


def fmt(p):
    return f"{CX + p[0]:.3f},{CY + p[1]:.3f}"


paths = []
for i in range(BLADES):
    (v, oa), ob = blade(i)
    paths.append(
        f'<path d="M{fmt(v)} L{fmt(oa)} A{R_OUT},{R_OUT} 0 0 1 {fmt(ob)} Z"/>'
    )

svg = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="512" height="512">\n'
    f'  <g fill="{FILL}">\n    ' + "\n    ".join(paths) + "\n  </g>\n</svg>\n"
)
out = Path(__file__).resolve().parent.parent / "assets" / "aperture-logo.svg"
out.write_text(svg)
print("wrote", out)
