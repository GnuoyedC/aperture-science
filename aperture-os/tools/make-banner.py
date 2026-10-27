#!/usr/bin/env python3
"""Render docs/banner.png (README title image) from the wallpaper, the fastfetch logo and the bundled fonts.
Needs python3-pil."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
W, H = 1600, 440
ORANGE, BLUE, TEXT, MUTED = "#FF7800", "#00AEEF", "#D9E3E8", "#81939E"
FONTS = ROOT / "sddm/assets/fonts"


def logo(size):
    return Image.open(ROOT / "dotfiles/fastfetch/aperture-logo.png").convert("RGBA").resize((size, size), Image.LANCZOS)


def spaced(draw, xy, text, font, fill, spacing):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=font, fill=fill)
        x += draw.textlength(ch, font=font) + spacing
    return x


bg = Image.open(ROOT / "wallpaper/ApertureTestChamber/contents/images/2560x1440.jpg").convert("RGB")
bg = bg.resize((W, int(W * bg.height / bg.width)))
bg = bg.crop((0, (bg.height - H) // 2, W, (bg.height - H) // 2 + H)).filter(ImageFilter.GaussianBlur(5))
shade = Image.new("RGB", (W, H), "#070B0F")
mask = Image.linear_gradient("L").rotate(90).resize((W, H))  # dark left -> transparent right
img = Image.composite(shade, bg, mask.point(lambda v: int(255 - v * 0.45)))
img = Image.blend(img, shade, 0.35).convert("RGBA")

d = ImageDraw.Draw(img)
lg = logo(260)
img.alpha_composite(lg, (110, (H - 260) // 2))
title = ImageFont.truetype(str(FONTS / "BarlowSemiCondensed-SemiBold.ttf"), 128)
sub = ImageFont.truetype(str(FONTS / "JetBrainsMono-Regular.ttf"), 26)
tag = ImageFont.truetype(str(FONTS / "Inter-Medium.ttf"), 28)
x = 440
spaced(d, (x, 112), "APERTURE OS", title, TEXT, 10)
d.rectangle((x, 268, x + 120, 272), fill=ORANGE)
spaced(d, (x, 292), "TEST CHAMBER 01  ·  KDE PLASMA 6 DESIGN SYSTEM", sub, BLUE, 5)
d.text((x, 340), "Aperture provides the environment. KDE provides the functionality.", font=tag, fill=MUTED)
img.convert("RGB").save(ROOT / "docs/banner.png", optimize=True)
print("wrote docs/banner.png")
