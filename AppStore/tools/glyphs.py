"""Text to SVG path outlines in SF Pro (the system variable font), so icon layers
don't depend on fonts being available wherever the SVG is rendered."""
from functools import lru_cache

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

SF = "/System/Library/Fonts/SFNS.ttf"


@lru_cache(maxsize=None)
def _font(weight, opsz):
    return instantiateVariableFont(TTFont(SF), {"wght": weight, "opsz": opsz, "wdth": 100, "GRAD": 400})


def text_path(s, size, weight=700, x=0.0, y=0.0, anchor="start", tracking=0.0, opsz=96):
    """Path data for `s` with its baseline at y; anchor is start, middle or end.
    tracking is extra space between letters, in px."""
    font = _font(weight, opsz)
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    upm = font["head"].unitsPerEm
    k = size / upm
    names = [cmap[ord(c)] for c in s]
    width = sum(hmtx[n][0] * k for n in names) + tracking * (len(names) - 1)
    pen_x = x - {"start": 0, "middle": width / 2, "end": width}[anchor]
    out = SVGPathPen(gs)
    for n in names:
        # Font units are y-up; flip and scale into SVG space at the baseline.
        gs[n].draw(TransformPen(out, (k, 0, 0, -k, pen_x, y)))
        pen_x += hmtx[n][0] * k + tracking
    return out.getCommands()


def ink_box(s, size, weight=700, opsz=96, tracking=0.0):
    """Left, top, right, bottom of the drawn ink relative to origin/baseline."""
    from fontTools.pens.boundsPen import BoundsPen
    font = _font(weight, opsz)
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    k = size / font["head"].unitsPerEm
    pen = BoundsPen(gs)
    x = 0
    for c in s:
        n = cmap[ord(c)]
        gs[n].draw(TransformPen(pen, (k, 0, 0, -k, x, 0)))
        x += hmtx[n][0] * k + tracking
    return pen.bounds
