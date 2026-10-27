#!/usr/bin/env python3
"""Parse every Xcursor file of Aperture-cursors and sanity-check it (stdlib only).

Checks: magic/header, TOC, image chunk headers, pixel data length, hotspot
inside the image, premultiplied alpha (r,g,b <= a), animation delays and that
every symlink resolves.  Exit code 1 on any error.
"""

import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURSOR_DIR = os.path.join(ROOT, "Aperture-cursors", "cursors")
IMAGE_TYPE = 0xFFFD0002


def parse(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic, hlen, version, ntoc = struct.unpack_from("<4sIII", data, 0)
    assert magic == b"Xcur", "bad magic"
    assert hlen == 16, f"header length {hlen}"
    assert version == 0x10000, f"version {version:#x}"
    images = []
    for i in range(ntoc):
        typ, subtype, pos = struct.unpack_from("<III", data, hlen + 12 * i)
        assert typ == IMAGE_TYPE, f"toc[{i}] type {typ:#x}"
        chlen, ctype, csub, cver, w, h, xh, yh, delay = struct.unpack_from("<9I", data, pos)
        assert (chlen, ctype, csub, cver) == (36, IMAGE_TYPE, subtype, 1), f"chunk header {i}"
        assert 0 < w <= 0x7FFF and 0 < h <= 0x7FFF
        assert xh < w and yh < h, f"hotspot ({xh},{yh}) outside {w}x{h}"
        pix = data[pos + 36: pos + 36 + w * h * 4]
        assert len(pix) == w * h * 4, "truncated pixels"
        # bytes are B,G,R,A (little-endian ARGB32), premultiplied
        for j in range(0, len(pix), 4):
            b, g, r, a = pix[j:j + 4]
            if r > a or g > a or b > a:
                raise AssertionError(f"not premultiplied at pixel {j // 4}")
        opaque = sum(1 for j in range(3, len(pix), 4) if pix[j] > 0)
        assert opaque > 0, "empty image"
        images.append((subtype, w, h, xh, yh, delay))
    return images


def main():
    errors = 0
    files = sorted(os.listdir(CURSOR_DIR))
    real = [f for f in files if not os.path.islink(os.path.join(CURSOR_DIR, f))]
    links = [f for f in files if os.path.islink(os.path.join(CURSOR_DIR, f))]
    for name in real:
        try:
            imgs = parse(os.path.join(CURSOR_DIR, name))
        except AssertionError as exc:
            print(f"FAIL {name}: {exc}")
            errors += 1
            continue
        sizes = {}
        for sub, w, h, xh, yh, delay in imgs:
            sizes.setdefault(sub, []).append((w, h, xh, yh, delay))
        desc = []
        for sub, frames in sorted(sizes.items()):
            w, h, xh, yh, delay = frames[0]
            if len(frames) > 1 and any(f[4] == 0 for f in frames):
                print(f"FAIL {name}: animated size {sub} has zero delay")
                errors += 1
            desc.append(f"{sub}:{w}x{h}@{xh},{yh}" + (f"x{len(frames)}f/{delay}ms" if len(frames) > 1 else ""))
        print(f"ok   {name:12s} " + " ".join(desc))
    for name in links:
        if not os.path.exists(os.path.join(CURSOR_DIR, name)):
            print(f"FAIL dangling link {name}")
            errors += 1
    print(f"{len(real)} cursor files, {len(links)} aliases, {errors} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
