#!/usr/bin/env python3
"""Build the Aperture OS Plymouth theme from tokens.json.

Writes into aperture-os/ (checked in, so the theme installs without building):
- iris-0..N.png   the Aperture logo, rotated in small steps (8 blades -> 45 deg period)
- *.png           every fixed text as an image: the initramfs only ships the Ubuntu font
- entry/bullet/rail images for the password prompt and the progress line
- aperture-os.script    from src/aperture-os.script.in (colours, sizes, reduceMotion)
- aperture-os.plymouth
- preview.png, preview-password.png (for the README; not used at boot)

Needs Pillow (python3-pil). Fonts: ~/.local/share/fonts/aperture-os, then ../sddm/assets/fonts.
Without fonts the existing text images are kept (warning only).

Usage: tools/build.py [--fonts DIR]
"""
import json
import math
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("build.py: Pillow fehlt (sudo apt install python3-pil)")

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "aperture-os"
T = json.loads((ROOT / "tokens.json").read_text())
C = T["color"]
REDUCE_MOTION = bool(T["motion"].get("reduceMotion", False))
THEME_DIR = "/usr/share/plymouth/themes/aperture-os"

FONT_DIRS = [Path(sys.argv[sys.argv.index("--fonts") + 1])] if "--fonts" in sys.argv else []
FONT_DIRS += [Path.home() / ".local/share/fonts/aperture-os", ROOT.parent / "sddm/assets/fonts"]

# Layout (logical px, scale 1). The script places everything relative to the window centre.
IRIS_SIZE = 112
IRIS_FRAMES = 30            # 45 deg / 30 = 1.5 deg per frame
RAIL_WIDTH = 420
ENTRY_W, ENTRY_H = 360, 40
SS = 4                      # supersampling for the logo

# Logo geometry: identical to widgets/shared/aperture-logo.template.svg (viewBox 0..100, arc r=48)
LOGO_PATHS = [
    ((64.900, 62.111), (64.900, 95.629), (32.367, 94.644)),
    ((51.972, 69.100), (28.271, 92.800), (5.964, 69.100)),
    ((37.889, 64.900), (4.371, 64.900), (5.356, 32.367)),
    ((30.900, 51.972), (7.200, 28.271), (30.900, 5.964)),
    ((35.100, 37.889), (35.100, 4.371), (67.633, 5.356)),
    ((48.028, 30.900), (71.729, 7.200), (94.036, 30.900)),
    ((62.111, 35.100), (95.629, 35.100), (94.644, 67.633)),
    ((69.100, 48.028), (92.800, 71.729), (69.100, 94.036)),
]


def rgb(hexcol):
    h = hexcol.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgbf(hexcol):
    return ", ".join(f"{v / 255:.4f}" for v in rgb(hexcol))


def blade_polygon(p_m, p_l, p_end, angle):
    """Polygon of one blade: M -> L -> arc (sweep 1, r 48 around 50,50) -> Z, rotated."""
    a0 = math.atan2(p_l[1] - 50, p_l[0] - 50)
    a1 = math.atan2(p_end[1] - 50, p_end[0] - 50)
    if a1 < a0:
        a1 += 2 * math.pi
    pts = [p_m, p_l]
    steps = 24
    for i in range(1, steps + 1):
        a = a0 + (a1 - a0) * i / steps
        pts.append((50 + 48 * math.cos(a), 50 + 48 * math.sin(a)))
    ca, sa = math.cos(angle), math.sin(angle)
    return [(50 + (x - 50) * ca - (y - 50) * sa, 50 + (x - 50) * sa + (y - 50) * ca) for x, y in pts]


def render_iris(angle_deg, size, color):
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = big / 100.0
    for p in LOGO_PATHS:
        poly = blade_polygon(*p, math.radians(angle_deg))
        d.polygon([(x * k, y * k) for x, y in poly], fill=color + (255,))
    return img.resize((size, size), Image.LANCZOS)


def find_font(name):
    for d in FONT_DIRS:
        f = d / name
        if f.is_file():
            return f
    return None


def render_text(text, font_file, px, color, tracking=0):
    """Text with letter spacing (Pillow has none): glyph by glyph, tight box, transparent."""
    font = ImageFont.truetype(str(font_file), px)
    asc, desc = font.getmetrics()
    width = sum(font.getlength(ch) for ch in text) + tracking * (len(text) - 1)
    img = Image.new("RGBA", (math.ceil(width) + 2, asc + desc + 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = 1.0
    for ch in text:
        d.text((x, 1), ch, font=font, fill=color + (255,))
        x += font.getlength(ch) + tracking
    return img


def box(w, h, fill, border, radius=2):
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle(
        (0, 0, w * SS - 1, h * SS - 1), radius=radius * SS,
        fill=fill + (255,), outline=border + (255,), width=SS)
    return img.resize((w, h), Image.LANCZOS)


def solid(w, h, color):
    return Image.new("RGBA", (w, h), color + (255,))


def main():
    OUT.mkdir(exist_ok=True)
    for old in OUT.glob("iris-*.png"):
        old.unlink()
    for i in range(IRIS_FRAMES):
        render_iris(45.0 * i / IRIS_FRAMES, IRIS_SIZE, rgb(C["text"])).save(OUT / f"iris-{i}.png", optimize=True)

    images = {
        "rail-track.png": solid(RAIL_WIDTH, 2, rgb(C["border"])),
        "rail-fill.png": solid(RAIL_WIDTH, 2, rgb(C["orange"])),
        "entry.png": box(ENTRY_W, ENTRY_H, rgb(C["surface"]), rgb(C["orange"])),
        "bullet.png": solid(8, 8, rgb(C["orange"])),
        "caret.png": solid(2, 18, rgb(C["orange"])),
    }
    for name, img in images.items():
        img.save(OUT / name, optimize=True)

    barlow = find_font("BarlowSemiCondensed-SemiBold.ttf")
    mono = find_font("JetBrainsMono-Regular.ttf")
    mono_bold = find_font("JetBrainsMono-Bold.ttf")
    texts = {
        "title.png": ("APERTURE LABORATORIES", barlow, 30, C["text"], 4),
        "subtitle.png": ("AUTOMATED TESTING FACILITY", mono, 12, C["textMuted"], 3),
        "status-boot.png": ("INITIALIZING", mono, 14, C["textMuted"], 3),
        "status-shutdown.png": ("SHUTTING DOWN", mono, 14, C["textMuted"], 3),
        "status-reboot.png": ("RESTARTING", mono, 14, C["textMuted"], 3),
        "status-updates.png": ("INSTALLING UPDATES - DO NOT POWER OFF", mono, 14, C["textMuted"], 3),
        "status-firmware.png": ("UPDATING FIRMWARE - DO NOT POWER OFF", mono, 14, C["textMuted"], 3),
        "cursor.png": ("_", mono_bold, 14, C["orange"], 0),
        "lock-title.png": ("SECURITY CLEARANCE REQUIRED", barlow, 22, C["text"], 3),
        "lock-hint.png": ("ENCRYPTED STORAGE  //  ENTER PASSPHRASE", mono, 11, C["textMuted"], 2),
    }
    if all((barlow, mono, mono_bold)):
        for name, (text, font, px, col, tr) in texts.items():
            render_text(text, font, px, rgb(col), tr).save(OUT / name, optimize=True)
    else:
        print("WARNUNG: Schriften fehlen – vorhandene Text-Bilder bleiben unverändert", file=sys.stderr)

    subst = {
        "BG": rgbf(C["background"]),
        "TEXT": rgbf(C["text"]),
        "MUTED": rgbf(C["textMuted"]),
        "ERROR": rgbf(C["error"]),
        "IRIS_FRAMES": str(IRIS_FRAMES),
        "REDUCE_MOTION": "1" if REDUCE_MOTION else "0",
    }
    script = (ROOT / "src/aperture-os.script.in").read_text()
    script = re.sub(r"@([A-Z_]+)@", lambda m: subst[m.group(1)], script)
    (OUT / "aperture-os.script").write_text(script)

    (OUT / "aperture-os.plymouth").write_text(
        "[Plymouth Theme]\n"
        "Name=Aperture OS\n"
        "Description=Aperture Laboratories boot screen (rotating iris, progress line, LUKS prompt)\n"
        "ModuleName=script\n\n"
        "[script]\n"
        f"ImageDir={THEME_DIR}\n"
        f"ScriptFile={THEME_DIR}/aperture-os.script\n")

    write_previews()
    print(f"plymouth: {IRIS_FRAMES} Iris-Frames, {len(images) + len(texts)} Bilder, Script -> {OUT}")


def write_previews():
    """Approximate boot and password screens (same offsets as the script) for the README."""
    W, H = 1280, 720
    load = lambda n: Image.open(OUT / n).convert("RGBA")

    def column(password):
        img = Image.new("RGBA", (W, H), rgb(C["background"]) + (255,))
        cx = W // 2
        y = int(H * 0.40) - IRIS_SIZE // 2
        for name, gap in (("iris-0.png", 26), ("title.png", 6), ("subtitle.png", 34)):
            im = load(name)
            img.alpha_composite(im, (cx - im.width // 2, y))
            y += im.height + gap
        if not password:
            track, fill = load("rail-track.png"), load("rail-fill.png")
            img.alpha_composite(track, (cx - track.width // 2, y))
            img.alpha_composite(fill.crop((0, 0, int(track.width * 0.62), 2)), (cx - track.width // 2, y))
            y += 2 + 18
            st, cur = load("status-boot.png"), load("cursor.png")
            img.alpha_composite(st, (cx - st.width // 2, y))
            img.alpha_composite(cur, (cx + st.width // 2 + 6, y))
        else:
            lt = load("lock-title.png")
            img.alpha_composite(lt, (cx - lt.width // 2, y))
            y += lt.height + 12
            ubuntu = Path("/usr/share/fonts/truetype/ubuntu/Ubuntu[wdth,wght].ttf")
            if ubuntu.is_file():   # stand-in for the cryptsetup prompt (Image.Text at boot)
                pr = render_text("Please unlock disk luks-root:", ubuntu, 16, rgb(C["textMuted"]))
                img.alpha_composite(pr, (cx - pr.width // 2, y))
            y += 22 + 10
            entry, bullet, caret = load("entry.png"), load("bullet.png"), load("caret.png")
            ex = cx - entry.width // 2
            img.alpha_composite(entry, (ex, y))
            for i in range(9):
                img.alpha_composite(bullet, (ex + 16 + i * 14, y + (entry.height - 8) // 2))
            img.alpha_composite(caret, (ex + 16 + 9 * 14, y + (entry.height - 18) // 2))
            y += entry.height + 12
            hint = load("lock-hint.png")
            img.alpha_composite(hint, (cx - hint.width // 2, y))
        return img.convert("RGB")

    column(False).save(OUT / "preview.png", optimize=True)
    column(True).save(OUT / "preview-password.png", optimize=True)


if __name__ == "__main__":
    main()
