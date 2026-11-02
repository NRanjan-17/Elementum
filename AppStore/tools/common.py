"""Shared tokens and helpers for the Elementum icon, previews and header.

Colours are chosen in OKLCH (perceptually even steps) and written out as sRGB hex.
Images are written as SVG and rasterised by headless Chrome from that same SVG.
"""
import base64
import math
import subprocess
from pathlib import Path

TOOLS = Path(__file__).parent
OUT = TOOLS.parent
ASSETS = TOOLS / "assets"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
FONT = "-apple-system, 'SF Pro Display', 'Helvetica Neue', sans-serif"


def oklch(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    rgb = (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
           -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
           -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)

    def enc(c):
        c = min(max(c, 0.0), 1.0)
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return "#" + "".join(f"{round(enc(c) * 255):02x}" for c in rgb)


def luminance(hexc):
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (int(hexc[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# The app colours its four periodic-table blocks with the system blue, green,
# orange and purple (ElementModel.swift). These are those hues, matched in
# lightness so no block shouts louder than another.
BLOCK = {
    "s": oklch(0.64, 0.19, 255),   # blue
    "p": oklch(0.72, 0.19, 148),   # green
    "d": oklch(0.75, 0.17, 60),    # orange
    "f": oklch(0.60, 0.20, 300),   # purple
}

T = {
    "canvas": oklch(0.985, 0.004, 250), "canvas2": oklch(0.955, 0.010, 250),
    "ink": oklch(0.24, 0.05, 262), "ink2": oklch(0.50, 0.035, 262),
    "accent": oklch(0.50, 0.17, 258),
    "navy": oklch(0.28, 0.10, 264), "navy2": oklch(0.17, 0.07, 268),
    "shadow": oklch(0.28, 0.06, 262),
    # Pale tints of the block hues for glows; chroma kept low so the
    # screenshots stay the loudest thing on each slide.
    "glow-s": oklch(0.88, 0.07, 255), "glow-p": oklch(0.90, 0.08, 148),
    "glow-d": oklch(0.91, 0.08, 65), "glow-f": oklch(0.88, 0.07, 300),
}

_cache = {}


def data_uri(path):
    path = Path(path)
    if path not in _cache:
        _cache[path] = "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()
    return _cache[path]


def text(x, y, s, size, weight, fill, anchor="middle", spacing=0):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size:.1f}" '
            f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" '
            f'letter-spacing="{spacing:.2f}">{s}</text>')


def render(doc, path, w, h):
    """Write path.svg and rasterise it to path.png at exactly w x h."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = path.with_suffix(".svg")
    svg.write_text(doc)
    png = path.with_suffix(".png")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--default-background-color=00000000",
                    f"--window-size={w},{h}", f"--screenshot={png}", svg.as_uri()],
                   check=True, capture_output=True)
    print(png.relative_to(OUT))
    return png
