"""Elementum app icon: the app's element cell, white, with "El" as the symbol.

    python3 icon.py

Writes, in AppStore/icon/:
  elementum-icon.svg / -1024.png   flat master (square, opaque; iOS rounds the corners)
  elementum-icon-rounded.png       how it looks on the home screen
  layers/*.svg                     the Liquid Glass layers on their own
and rebuilds the app's Icon Composer file, Elementum/Resources/Elementum.icon,
from those layers (light: navy and magenta on white; dark: white symbol, magenta accents).

All lettering is SF Pro converted to outlines, so the SVGs render the same
in Icon Composer, Xcode and a browser.
"""
import json
import shutil
from pathlib import Path

from common import OUT, render
from glyphs import ink_box, text_path
from palette import oklch

S = 1024
C = S / 2
APP_ICON = OUT.parent / "Elementum" / "Resources" / "Elementum.icon"

INK = oklch(0.26, 0.08, 265)     # navy, the app's dark text tone
ACCENT = oklch(0.55, 0.20, 350)  # magenta from the Periodic Table card, for the number and name


def symbol():
    # "El" centred on the tile by its drawn ink (with the same tracking it's
    # drawn with), not by its advance width or baseline.
    size, tracking = 500, -14
    l, b, r, t = ink_box("El", size, 700, tracking=tracking)
    x = C - (l + r) / 2
    y = C - (b + t) / 2
    return text_path("El", size, 700, x, y, tracking=tracking)


def number():
    return text_path("1", 120, 600, 170, 268)


def name():
    return text_path("Elementum", 92, 600, C, 862, anchor="middle", tracking=1)


LAYERS = {"symbol": (symbol, INK), "number": (number, ACCENT), "name": (name, ACCENT)}


def layer_svg(d, fill):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'<path d="{d}" fill="{fill}"/></svg>')


def flat(rounded=False):
    clip = f'<clipPath id="sq"><rect width="{S}" height="{S}" rx="{S * 0.2237}"/></clipPath>' if rounded else ""
    g = ' clip-path="url(#sq)"' if rounded else ""
    paths = "".join(f'<path d="{fn()}" fill="{fill}"/>' for fn, fill in LAYERS.values())
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'<defs>{clip}</defs><g{g}><rect width="{S}" height="{S}" fill="#fff"/>{paths}</g></svg>')


def icon_json():
    dark_white = [{"appearance": "dark", "value": "system-light"}]
    return {
        "color-space-for-untagged-svg-colors": "display-p3",
        "fill": {"solid": "srgb:1.00000,1.00000,1.00000,1.00000"},
        "fill-specializations": [
            {"value": {"solid": "srgb:1.00000,1.00000,1.00000,1.00000"}},
            {"appearance": "dark", "value": "automatic"},
        ],
        "groups": [
            {   # The symbol is the hero: it gets the glass, specular edge and a soft shadow.
                "layers": [{"image-name": "symbol.svg", "name": "Symbol", "glass": True,
                            "fill-specializations": dark_white}],
                "shadow": {"kind": "neutral", "opacity": 0.5},
                "specular": True,
                "translucency": {"enabled": True, "value": 0.25},
            },
            {   # Atomic number and name sit flatter, like the small print on a cell.
                "layers": [
                    # The magenta accent stays in dark mode too; it reads on the dark fill.
                    {"image-name": "number.svg", "name": "Number", "glass": False},
                    {"image-name": "name.svg", "name": "Name", "glass": False},
                ],
                "shadow": {"kind": "neutral", "opacity": 0.2},
                "specular": False,
                "translucency": {"enabled": False, "value": 0},
            },
        ],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }


if __name__ == "__main__":
    out = OUT / "icon"
    if out.exists():
        shutil.rmtree(out)
    (out / "layers").mkdir(parents=True)
    for key, (fn, fill) in LAYERS.items():
        (out / "layers" / f"{key}.svg").write_text(layer_svg(fn(), fill))
    render(flat(), out / "elementum-icon-1024", S, S)          # also writes elementum-icon-1024.svg
    (out / "elementum-icon-1024.svg").rename(out / "elementum-icon.svg")
    render(flat(rounded=True), out / "elementum-icon-rounded", S, S)
    (out / "elementum-icon-rounded.svg").unlink()

    # The app's Icon Composer document.
    if APP_ICON.exists():
        shutil.rmtree(APP_ICON)
    (APP_ICON / "Assets").mkdir(parents=True)
    for key in LAYERS:
        shutil.copy(out / "layers" / f"{key}.svg", APP_ICON / "Assets" / f"{key}.svg")
    (APP_ICON / "icon.json").write_text(json.dumps(icon_json(), indent=2))
    shutil.copytree(APP_ICON, out / "Elementum.icon")
    print("wrote", APP_ICON.relative_to(OUT.parent), "and icon/Elementum.icon")
