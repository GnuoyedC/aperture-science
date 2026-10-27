#!/usr/bin/env python3
"""Cut light overlays for the animated wallpaper out of the built-in photo.

Instead of drawing vector shapes over the photo, the animation brightens the
photo's own light sources: this script extracts their pixels, brightens them
and adds a soft halo. The plugin then only changes the opacity of these PNGs.

  ring/NN.png    upper orange ring of the central cylinder, cut into angular
                 sectors (light runs along the ring sector by sector)
  corridor.png   light shaft + lit corridor below the core (slow swell)
  doorway.png    lit doorway behind the companion cube (left)

Writes contents/images/overlays/* and contents/ui/Overlays.qml (rects in
image-relative coordinates). Needs Pillow; output is checked in.
Usage: tools/make_overlays.py
"""
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PKG = ROOT / "aperture-os.chamber" / "contents"
SRC = PKG / "images" / "chamber.jpg"
OUT = PKG / "images" / "overlays"

# upper ring ellipse (measured on the photo, image-relative)
RING = dict(cx=0.520, cy=0.223, rx=0.087, ry=0.051, rmin=0.72, rmax=1.20)
RING_BOX = (0.40, 0.14, 0.64, 0.30)
SECTOR_DEG = 15
CORRIDOR_BOX = (0.69, 0.25, 0.87, 0.66)
DOORWAY_BOX = (0.112, 0.455, 0.262, 0.775)
DOORWAY_EXCLUDE = [(0.0, 0.575, 0.150, 1.0)]   # the companion cube


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def lit_layer(crop, mask, gain, lift, halo_rgb, halo_radius, halo_alpha):
    """Brightened copy of the masked pixels over a soft halo, as RGBA."""
    w, h = crop.size
    bright = crop.point(lambda v: v)  # copy
    r, g, b = bright.split()
    r = r.point(lambda v: min(255, int(v * gain + lift[0])))
    g = g.point(lambda v: min(255, int(v * gain + lift[1])))
    b = b.point(lambda v: min(255, int(v * gain + lift[2])))
    bright = Image.merge("RGB", (r, g, b))
    core = bright.convert("RGBA")
    core.putalpha(mask)
    halo_mask = mask.filter(ImageFilter.GaussianBlur(halo_radius)).point(lambda v: int(v * halo_alpha))
    halo = Image.new("RGBA", (w, h), halo_rgb + (0,))
    halo.putalpha(halo_mask)
    return Image.alpha_composite(halo, core)


def bbox_px(box, W, H, pad=0):
    return (max(0, int(box[0] * W) - pad), max(0, int(box[1] * H) - pad),
            min(W, int(box[2] * W) + pad), min(H, int(box[3] * H) + pad))


def ring_sectors(im):
    W, H = im.size
    x0, y0, x1, y1 = bbox_px(RING_BOX, W, H)
    crop = im.crop((x0, y0, x1, y1))
    px = crop.load()
    w, h = crop.size
    n = 360 // SECTOR_DEG
    masks = [Image.new("L", (w, h), 0) for _ in range(n)]
    mpx = [m.load() for m in masks]
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            orange = smoothstep(40, 90, r - g) * smoothstep(110, 170, r) * (1 - smoothstep(90, 140, b))
            if orange <= 0:
                continue
            nx = ((x0 + x) / W - RING["cx"]) / RING["rx"]
            ny = ((y0 + y) / H - RING["cy"]) / RING["ry"]
            rad = math.hypot(nx, ny)
            if not RING["rmin"] <= rad <= RING["rmax"]:
                continue
            ang = math.degrees(math.atan2(ny, nx)) % 360   # clockwise, y down; 270 = top
            mpx[int(ang // SECTOR_DEG) % n][x, y] = int(255 * orange)
    sectors = []
    for i, m in enumerate(masks):
        m = m.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
        layer = lit_layer(crop, m, 1.45, (70, 30, 0), (255, 154, 61), 7, 0.55)
        box = layer.getbbox()
        if not box or m.getextrema()[1] < 40:
            continue
        bx0, by0, bx1, by1 = box
        layer.crop(box).save(OUT / "ring" / f"{i:02d}.png", optimize=True)
        sectors.append(dict(src=f"overlays/ring/{i:02d}.png", angle=(i + 0.5) * SECTOR_DEG,
                            x=(x0 + bx0) / W, y=(y0 + by0) / H, w=(bx1 - bx0) / W, h=(by1 - by0) / H))
    return sectors


def light_region(im, name, box, exclude=()):
    """Bright pixels inside `box` (minus `exclude` rects), edges faded out."""
    W, H = im.size
    x0, y0, x1, y1 = bbox_px(box, W, H)
    crop = im.crop((x0, y0, x1, y1))
    lum = crop.convert("L")
    mask = lum.point(lambda v: int(255 * smoothstep(95, 190, v)))
    # fade out towards the box edges so nothing ends in a hard line
    w, h = crop.size
    edge = Image.new("L", (w, h), 0)
    e = edge.load()
    for y in range(h):
        for x in range(w):
            d = min(x, w - 1 - x, y, h - 1 - y) / (0.12 * min(w, h))
            e[x, y] = int(255 * smoothstep(0, 1, d))
    mask = ImageChops.multiply(mask, edge)
    if exclude:
        cut = Image.new("L", (w, h), 255)
        for ex in exclude:
            ex0, ey0, ex1, ey1 = bbox_px(ex, W, H)
            cut.paste(0, (ex0 - x0, ey0 - y0, ex1 - x0, ey1 - y0))
        cut = cut.filter(ImageFilter.GaussianBlur(4))
        mask = ImageChops.multiply(mask, cut)
    layer = lit_layer(crop, mask, 1.35, (8, 18, 30), (92, 205, 247), 18, 0.45)
    layer.save(OUT / f"{name}.png", optimize=True)
    return dict(src=f"overlays/{name}.png", x=x0 / W, y=y0 / H, w=w / W, h=h / H)


def qml(sectors, corr, door):
    def rect(d):
        return f'x: {d["x"]:.5f}, y: {d["y"]:.5f}, w: {d["w"]:.5f}, h: {d["h"]:.5f}'
    lines = [
        "// GENERATED by tools/make_overlays.py - do not edit.",
        "import QtQuick",
        "",
        "// Light overlays cut from images/chamber.jpg (image-relative rects).",
        "QtObject {",
        "    readonly property var ring: [",
    ]
    lines += [f'        {{ src: "../images/{s["src"]}", angle: {s["angle"]:.1f}, {rect(s)} }},' for s in sectors]
    lines += [
        "    ]",
        f'    readonly property var corridor: ({{ src: "../images/{corr["src"]}", {rect(corr)} }})',
        f'    readonly property var doorway: ({{ src: "../images/{door["src"]}", {rect(door)} }})',
        "}",
        "",
    ]
    (PKG / "ui" / "Overlays.qml").write_text("\n".join(lines), encoding="utf-8")


def main():
    im = Image.open(SRC).convert("RGB")
    (OUT / "ring").mkdir(parents=True, exist_ok=True)
    for old in (OUT / "ring").glob("*.png"):
        old.unlink()
    sectors = ring_sectors(im)
    corr = light_region(im, "corridor", CORRIDOR_BOX)
    door = light_region(im, "doorway", DOORWAY_BOX, DOORWAY_EXCLUDE)
    qml(sectors, corr, door)
    print(f"ring: {len(sectors)} Sektoren, corridor + doorway -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
