#!/usr/bin/env python3
"""Render an SVG launcher icon to a 40x40 PNG in the fenix 5X 64-colour palette.

Usage: tools/render-icon.py [in.svg] [out.png] [size]
Defaults: resources/drawables/launcher_icon.svg -> resources/drawables/launcher_icon.png, 40.
Needs rsvg-convert (Debian/Ubuntu/Mint: sudo apt install librsvg2-bin) and Pillow.
The SVG is rendered at 8x, downscaled, then every pixel is snapped to the
device palette (each channel 00/55/AA/FF) so the PNG shows exactly what the
watch draws. Pixels under 50% coverage become fully transparent.
"""
import io, subprocess, sys
from PIL import Image

src = sys.argv[1] if len(sys.argv) > 1 else "resources/drawables/launcher_icon.svg"
dst = sys.argv[2] if len(sys.argv) > 2 else "resources/drawables/launcher_icon.png"
size = int(sys.argv[3]) if len(sys.argv) > 3 else 40

big = subprocess.run(["rsvg-convert", "-w", str(size * 8), "-h", str(size * 8), src],
                     check=True, capture_output=True).stdout
img = Image.open(io.BytesIO(big)).convert("RGBA").resize((size, size), Image.LANCZOS)

snap = lambda v: min((0, 85, 170, 255), key=lambda p: abs(p - v))
out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
for y in range(size):
    for x in range(size):
        r, g, b, a = img.getpixel((x, y))
        if a < 128:
            continue
        # colour as it looks over the black watch background
        f = a / 255
        out.putpixel((x, y), (snap(r * f), snap(g * f), snap(b * f), 255))
out.save(dst, optimize=True)
print(f"{src} -> {dst} ({size}x{size})")
