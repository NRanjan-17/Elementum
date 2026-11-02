"""Elementum App Store screenshots (iPhone 6.9", iPhone 6.5", iPad 13") and header.

    python3 icon.py      # first: the award slide and header use the chosen icon
    python3 previews.py

Look: Elementum's own colours. Each slide takes the gradient of one of the app's
Home cards (Periodic Table gold-pink, S blue, P green, D red-orange, F purple),
interpolated in OKLCH, with white type and a large faint element symbol behind
the device, like the app's element cells. Layout rules follow lookap's
"Wellness App Animated Onboarding" by Adrian (@adriankuleszo,
https://x.com/adriankuleszo/status/2103537542859747555): devices without an
outline stroke, generous space, one idea per slide. Glows follow lookap's
material rule: a radial gradient fading to transparent, never a solid disc.
"""
from common import ASSETS, FONT, OUT, contrast, data_uri, render, text
from palette import GRADIENTS, gradient_stops, oklch, top_colour

ICON = OUT / "icon" / "elementum-icon-1024.png"
PHONE_AR = 3908 / 1941   # framed iPhone PNGs, transparent margin included
IPAD_AR = 1876 / 1336
WHITE = "#ffffff"


def defs(s, grad):
    deep = oklch(*[GRADIENTS[grad][0][0] * 0.55, GRADIENTS[grad][0][1], GRADIENTS[grad][0][2]])
    return f"""<defs>
  <linearGradient id="bg" x1="0" y1="0" x2=".25" y2="1">{gradient_stops(GRADIENTS[grad])}</linearGradient>
  <radialGradient id="halo"><stop offset="0" stop-color="#fff" stop-opacity=".30"/>
    <stop offset=".55" stop-color="#fff" stop-opacity=".10"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
  <filter id="drop" x="-30%" y="-30%" width="160%" height="160%">
    <feDropShadow dx="0" dy="{40 * s:.1f}" stdDeviation="{46 * s:.1f}" flood-color="{deep}" flood-opacity=".45"/>
  </filter>
</defs>"""


def svg(w, h, body, s, grad):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'{defs(s, grad)}<rect width="{w}" height="{h}" fill="url(#bg)"/>{body}</svg>')


def halo(cx, cy, rx, ry):
    return f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="url(#halo)"/>'


def watermark(sym, cx, cy, size):
    """A giant faint element symbol, the app's cell typography at poster scale."""
    return (f'<text x="{cx:.1f}" y="{cy:.1f}" font-family="{FONT}" font-size="{size:.1f}" font-weight="800" '
            f'fill="#fff" fill-opacity=".09" text-anchor="middle" letter-spacing="{-0.04 * size:.1f}">{sym}</text>')


def aspect(name):
    """Height / width of a framed screenshot, read from its PNG header."""
    import struct
    with open(ASSETS / f"{name}.png", "rb") as f:
        f.read(16)
        w, h = struct.unpack(">II", f.read(8))
    return h / w


def device(name, x, y, w, ar=None, rotate=0):
    h = w * aspect(name)   # each frame's own proportions; `ar` is kept for old call sites
    rot = f' transform="rotate({rotate} {x + w / 2:.1f} {y + h / 2:.1f})"' if rotate else ""
    return (f'<image href="{data_uri(ASSETS / (name + ".png"))}" x="{x:.1f}" y="{y:.1f}" '
            f'width="{w:.1f}" height="{h:.1f}" filter="url(#drop)"{rot}/>')


def heading(cx, top, s, eyebrow, l1, l2, size=112):
    eb = text(cx, top, eyebrow.upper(), 36 * s, 650, WHITE, spacing=6 * s).replace("<text ", '<text fill-opacity=".85" ')
    return "".join([
        eb,
        text(cx, top + 150 * s, l1, size * s, 700, WHITE, spacing=-0.028 * size * s),
        text(cx, top + 150 * s + size * 1.06 * s, l2, size * s, 700, WHITE, spacing=-0.028 * size * s),
    ])


def icon_tile(cx, y, size):
    return (f'<clipPath id="ic{int(y)}"><rect x="{cx - size / 2:.1f}" y="{y:.1f}" width="{size:.1f}" height="{size:.1f}" rx="{size * 0.2237:.1f}"/></clipPath>'
            f'<image href="{data_uri(ICON)}" x="{cx - size / 2:.1f}" y="{y:.1f}" width="{size:.1f}" height="{size:.1f}" '
            f'clip-path="url(#ic{int(y)})" filter="url(#drop)"/>')


def award(cx, top, s):
    icon = 220 * s
    return "".join([
        icon_tile(cx, top, icon),
        text(cx, top + icon + 130 * s, "SWIFT STUDENT CHALLENGE", 38 * s, 650, WHITE, spacing=6 * s)
        .replace("<text ", '<text fill-opacity=".85" '),
        text(cx, top + icon + 265 * s, "2025 Winner", 112 * s, 700, WHITE, spacing=-3 * s),
    ])


# ---------------------------------------------------------------- iPhone
# (file, eyebrow, line 1, line 2, screenshot, gradient, watermark symbol)
PHONE_SLIDES = [
    ("1-home", "Elementum", "Chemistry,", "made simple.", "phone-home-new", "hero", "El"),
    ("2-periodic-table", "Periodic table", "Every element,", "one tap away.", "phone-table", "s", "H"),
    ("3-element-details", "Element details", "Know each element", "inside out.", "phone-detail", "p", "Be"),
    ("4-combine", "Combine", "Mix elements.", "See the reaction.", "phone-combine", "f", "O"),
    ("5-finder", "Finder", "Search by name,", "symbol or number.", "phone-finder", "d", "Cu"),
]


def phone_slide(W, H, eyebrow, l1, l2, shot, grad, sym):
    s = W / 1320
    cx = W / 2
    pw = 1000 * s
    ph = pw * aspect(shot)
    top = H - ph - 140 * s
    return svg(W, H, "".join([
        watermark(sym, cx, top + ph * 0.62, 1500 * s),
        halo(cx, top + ph * 0.45, 760 * s, 1000 * s),
        heading(cx, 205 * s, s, eyebrow, l1, l2),
        device(shot, cx - pw / 2, top, pw, PHONE_AR),
    ]), s, grad)


def phone_award(W, H):
    s = W / 1320
    cx = W / 2
    pw = 660 * s
    return svg(W, H, "".join([
        halo(cx, H * 0.66, 800 * s, 900 * s),
        award(cx, 230 * s, s),
        device("phone-home-new", cx - pw * 0.86, H * 0.35, pw, PHONE_AR, rotate=-6),
        device("phone-table", cx - pw * 0.14, H * 0.375, pw, PHONE_AR, rotate=6),
    ]), s, "hero")


# ---------------------------------------------------------------- iPad

IPAD_SLIDES = [
    ("1-home", "Elementum", "Chemistry,", "made simple.", "ipad-home", "hero", "El"),
    ("2-combine", "Combine", "Mix elements.", "See the reaction.", "ipad-combine", "f", "O"),
    ("3-finder", "Finder", "Find any element", "in seconds.", "ipad-finder", "p", "Cu"),
]


def ipad_slide(W, H, eyebrow, l1, l2, shot, grad, sym):
    s = W / 2064
    cx = W / 2
    iw = 1540 * s
    ih = iw * IPAD_AR
    top = H - ih - 40 * s
    return svg(W, H, "".join([
        watermark(sym, cx, top + ih * 0.66, 1900 * s),
        halo(cx, top + ih * 0.5, 1100 * s, 1100 * s),
        heading(cx, 175 * s, s, eyebrow, l1, l2, size=104),
        device(shot, cx - iw / 2, top, iw, IPAD_AR),
    ]), s, grad)


def ipad_award(W, H):
    s = W / 2064
    cx = W / 2
    iw = 1240 * s
    pw = 560 * s
    return svg(W, H, "".join([
        halo(cx, H * 0.70, 1200 * s, 900 * s),
        award(cx, 170 * s, s),
        device("ipad-home", cx - iw * 0.66, H * 0.39, iw, IPAD_AR),
        device("phone-table", cx + iw * 0.30, H * 0.45, pw, PHONE_AR),
    ]), s, "hero")


# ---------------------------------------------------------------- header

def header(W, H):
    # Designed at 3840x1646; scaled to the tighter side and centred vertically.
    s = min(H / 1646, W / 3840)
    oy = (H - 1646 * s) / 2
    cx = W * 0.70
    pw = 600 * s
    icon = 300 * s
    ix = W * 0.085
    block = icon + 70 * s + 150 * s + 50 * s + 64 * s
    iy = H / 2 - block / 2
    return svg(W, H, "".join([
        halo(cx, H * 0.5, 1300 * s, 1000 * s),
        device("phone-table", cx - pw * 1.45, oy + 280 * s, pw, PHONE_AR, rotate=-8),
        device("phone-combine", cx + pw * 0.45, oy + 280 * s, pw, PHONE_AR, rotate=8),
        device("phone-home-new", cx - pw * 1.08 / 2, oy + 130 * s, pw * 1.08, PHONE_AR),
        f'<clipPath id="hic"><rect x="{ix:.1f}" y="{iy:.1f}" width="{icon:.1f}" height="{icon:.1f}" rx="{icon * 0.2237:.1f}"/></clipPath>',
        f'<image href="{data_uri(ICON)}" x="{ix:.1f}" y="{iy:.1f}" width="{icon:.1f}" height="{icon:.1f}" clip-path="url(#hic)" filter="url(#drop)"/>',
        text(ix - 6 * s, iy + icon + 70 * s + 128 * s, "Elementum", 160 * s, 700, WHITE, "start", -4.5 * s),
        text(ix, iy + icon + 70 * s + 150 * s + 50 * s + 52 * s, "Chemistry, made simple.",
             64 * s, 500, WHITE, "start", -0.6 * s).replace("<text ", '<text fill-opacity=".9" '),
    ]), s, "hero")


if __name__ == "__main__":
    for g in GRADIENTS:
        print(f"white on top of '{g}': {contrast(WHITE, top_colour(g)):.1f}:1")
    for folder, (W, H) in (("iphone-6.9in", (1320, 2868)), ("iphone-6.5in", (1242, 2688))):
        for name, *rest in PHONE_SLIDES:
            render(phone_slide(W, H, *rest), OUT / folder / name, W, H)
        render(phone_award(W, H), OUT / folder / "6-award", W, H)
    W, H = 2064, 2752
    for name, *rest in IPAD_SLIDES:
        render(ipad_slide(W, H, *rest), OUT / "ipad-13in" / name, W, H)
    render(ipad_award(W, H), OUT / "ipad-13in" / "4-award", W, H)
    for W, H in ((3840, 1646), (5244, 2950)):
        render(header(W, H), OUT / "header" / f"header-{W}x{H}", W, H)
