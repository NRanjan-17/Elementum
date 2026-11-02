"""Elementum's palette, taken from the app itself rather than a generic scheme.

Hues come from the gradient cards on the Home screen (sampled from the iPad
screenshot): Periodic Table gold #cc9e51 -> pink #ca4999, S Group blue #054b90 ->
navy #000d57, P Group green #719d44, D Group red-orange #cb4b1c, F Group purple
#6b3ebf -> #4c2896. Lightness is set in OKLCH so white type passes contrast
where it sits (the top of each slide).
"""
from common import oklch

# Each gradient is a list of OKLCH stops, top -> bottom (or top-left -> bottom-right).
HERO = [(0.80, 0.13, 78), (0.68, 0.17, 30), (0.58, 0.21, 355)]          # Periodic Table card
GRADIENTS = {
    "hero":   [(0.56, 0.21, 352), (0.64, 0.18, 20), (0.76, 0.14, 70)],  # pink top (text) -> gold
    "s":      [(0.27, 0.11, 264), (0.40, 0.15, 258), (0.55, 0.16, 245)],  # navy -> blue
    "p":      [(0.42, 0.11, 145), (0.55, 0.15, 138), (0.72, 0.17, 128)],  # deep green -> lime
    "d":      [(0.50, 0.18, 35), (0.60, 0.18, 45), (0.74, 0.15, 65)],      # red-orange -> amber
    "f":      [(0.36, 0.17, 292), (0.47, 0.20, 298), (0.60, 0.20, 310)],  # violet -> orchid
}
BLOCK_CELL = {
    "s": oklch(0.64, 0.17, 252), "p": oklch(0.72, 0.18, 140),
    "d": oklch(0.70, 0.17, 50), "f": oklch(0.58, 0.20, 298),
}


def lerp_oklch(a, b, t):
    dh = (b[2] - a[2] + 180) % 360 - 180      # shortest way round the hue wheel
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, (a[2] + dh * t) % 360)


def gradient_stops(stops, steps=12):
    """SVG <stop>s sampled along an OKLCH path, so midpoints stay vivid."""
    out = []
    n = len(stops) - 1
    for i in range(steps + 1):
        t = i / steps
        seg = min(int(t * n), n - 1)
        local = t * n - seg
        out.append(f'<stop offset="{t:.3f}" stop-color="{oklch(*lerp_oklch(stops[seg], stops[seg + 1], local))}"/>')
    return "".join(out)


def top_colour(name):
    return oklch(*GRADIENTS[name][0])
