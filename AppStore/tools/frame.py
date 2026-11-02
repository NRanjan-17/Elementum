"""Put a raw iPhone screenshot into a vector iPhone frame that matches the dark
bezels of the other screenshots, so a fresh capture can join the set.

    python3 frame.py assets/screen-home-new.png assets/phone-home-new.png
"""
import sys
from pathlib import Path

from common import data_uri, render

# iPhone Pro proportions, relative to the screen width p: ~6pt titanium band,
# ~9pt black border, Dynamic Island 108x35pt sitting 14pt from the top.
TI, BK, RAD = 0.0149, 0.0224, 0.137
MARGIN = 0.012   # room for the side buttons


def framed(src, sw, sh):
    p = sw
    ti, bk, r = p * TI, p * BK, p * RAD
    m = p * MARGIN
    fw, fh = p + 2 * (ti + bk), sh + 2 * (ti + bk)
    W, H = fw + 2 * m, fh + 2 * m
    x, y = m, m
    sx, sy = x + ti + bk, y + ti + bk

    def button(side, top, length):
        bx = x - p * 0.0075 if side == "l" else x + fw - p * 0.001
        return (f'<rect x="{bx:.1f}" y="{sy + p * top:.1f}" width="{p * 0.0085:.1f}" height="{p * length:.1f}" '
                f'rx="{p * 0.004:.1f}" fill="url(#btn)"/>')

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" height="{H:.0f}" viewBox="0 0 {W:.1f} {H:.1f}">
<defs>
  <linearGradient id="ti" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#5a5a5e"/><stop offset=".25" stop-color="#2c2c2e"/>
    <stop offset=".5" stop-color="#1c1c1e"/><stop offset=".75" stop-color="#2c2c2e"/><stop offset="1" stop-color="#5a5a5e"/>
  </linearGradient>
  <linearGradient id="btn" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#1c1c1e"/><stop offset=".6" stop-color="#4a4a4e"/><stop offset="1" stop-color="#2c2c2e"/>
  </linearGradient>
  <clipPath id="scr"><rect x="{sx:.1f}" y="{sy:.1f}" width="{p:.1f}" height="{sh:.1f}" rx="{r:.1f}"/></clipPath>
</defs>
{button('l', 0.476, 0.102)}{button('l', 0.657, 0.167)}{button('l', 0.871, 0.164)}{button('r', 0.717, 0.264)}
<rect x="{x:.1f}" y="{y:.1f}" width="{fw:.1f}" height="{fh:.1f}" rx="{r + bk + ti:.1f}" fill="url(#ti)"/>
<rect x="{x + p * 0.002:.1f}" y="{y + p * 0.002:.1f}" width="{fw - p * 0.004:.1f}" height="{fh - p * 0.004:.1f}"
      rx="{r + bk + ti - p * 0.002:.1f}" fill="none" stroke="#fff" stroke-opacity=".18" stroke-width="{p * 0.002:.2f}"/>
<rect x="{x + ti:.1f}" y="{y + ti:.1f}" width="{fw - 2 * ti:.1f}" height="{fh - 2 * ti:.1f}" rx="{r + bk:.1f}" fill="#000"/>
<image href="{data_uri(src)}" x="{sx:.1f}" y="{sy:.1f}" width="{p:.1f}" height="{sh:.1f}" clip-path="url(#scr)"/>
<rect x="{sx + p * (0.5 - 0.1343):.1f}" y="{sy + p * 0.0348:.1f}" width="{p * 0.2687:.1f}" height="{p * 0.0871:.1f}"
      rx="{p * 0.0436:.1f}" fill="#000"/>
</svg>"""
    return svg, round(W), round(H)


if __name__ == "__main__":
    import struct
    src, dst = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    with open(src, "rb") as f:
        f.read(16)
        sw, sh = struct.unpack(">II", f.read(8))
    doc, W, H = framed(src, sw, sh)
    render(doc, dst.with_suffix(""), W, H)
    dst.with_suffix(".svg").unlink()
