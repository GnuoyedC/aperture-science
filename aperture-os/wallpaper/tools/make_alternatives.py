#!/usr/bin/env python3
"""Build wallpaper packages (1920x1080, 2560x1440, 3840x2160) from Images/*.png next to ApertureTestChamber.

Lanczos upscaling, light sharpening, fine grain against banding.
Usage: python3 tools/make_alternatives.py
"""
import json
import numpy as np
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SIZES = [(1920, 1080), (2560, 1440), (3840, 2160)]
ALTERNATIVES = {  # source file -> (package id, display name)
    "Aperture Core Maintenance Hall.png": ("ApertureCoreMaintenanceHall", "Aperture Core Maintenance Hall"),
    "Aperture Research Complex in the Storm.png": ("ApertureResearchComplex", "Aperture Research Complex in the Storm"),
    "Aperture Laboratories Test Chamber 01.png": ("ApertureLaboratories", "Aperture Laboratories"),
    "Aperture Portal Chamber.png": ("AperturePortalChamber", "Aperture Portal Chamber"),
    "Overgrown Aperture Test Chamber with AI Core.png": ("ApertureOvergrown", "Aperture Overgrown"),
}
rng = np.random.default_rng(7)

for src, (pid, name) in ALTERNATIVES.items():
    img = Image.open(ROOT / "Images" / src).convert("RGB")
    out = ROOT / pid / "contents" / "images"
    out.mkdir(parents=True, exist_ok=True)
    for w, h in SIZES:
        big = img.resize((w, h), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=1.6, percent=60, threshold=2))
        arr = np.asarray(big, dtype=np.float32) + rng.normal(0, 1.4, (h, w, 1))
        Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(out / f"{w}x{h}.jpg", quality=92, optimize=True, progressive=True)
    meta = {"KPlugin": {"Authors": [{"Name": "Quatzler"}], "Id": pid, "License": "Private use only", "Name": name}}
    (ROOT / pid / "metadata.json").write_text(json.dumps(meta, indent=4, ensure_ascii=False) + "\n")
    print(pid)
