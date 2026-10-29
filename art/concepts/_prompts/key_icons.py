"""Icone: dallo sfondo verde piatto (#00FF00) di Codex al PNG 512x512 trasparente.

Uso: uv run --no-project --with pillow --with numpy python art/concepts/_prompts/key_icons.py <cartella_raw> <cartella_uscita>
Toglie solo il verde collegato ai bordi (il verde dentro l'icona resta), pulisce l'alone verde sui bordi,
ritaglia, centra con un margine e ridimensiona a 512x512.
"""

import os
import sys

import numpy as np
from PIL import Image

SIZE = 512
MARGIN = 0.05  # margine su ogni lato, in frazione del lato


def key(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # quanto un pixel è "verde chroma": verde molto più alto di rosso e blu
    green = g - np.maximum(r, b)
    candidate = green > 40
    # solo il verde collegato ai bordi è sfondo
    bg = np.zeros_like(candidate)
    bg[0, :], bg[-1, :], bg[:, 0], bg[:, -1] = candidate[0, :], candidate[-1, :], candidate[:, 0], candidate[:, -1]
    while True:
        grown = bg.copy()
        grown[1:, :] |= bg[:-1, :]
        grown[:-1, :] |= bg[1:, :]
        grown[:, 1:] |= bg[:, :-1]
        grown[:, :-1] |= bg[:, 1:]
        grown &= candidate
        if (grown == bg).all():
            break
        bg = grown
    # bordo morbido: i pixel di confine prendono un'alpha proporzionale a quanto sono poco verdi
    near = bg.copy()
    for _ in range(2):
        n = near.copy()
        n[1:, :] |= near[:-1, :]
        n[:-1, :] |= near[1:, :]
        n[:, 1:] |= near[:, :-1]
        n[:, :-1] |= near[:, 1:]
        near = n
    alpha = np.ones_like(g)
    alpha[bg] = 0
    edge = near & ~bg
    alpha[edge] = np.clip(1 - (green[edge] - 10) / 120, 0, 1)
    # despill: il verde dei bordi non supera il massimo tra rosso e blu
    spill = edge | (alpha < 1)
    g2 = g.copy()
    g2[spill] = np.minimum(g[spill], np.maximum(r[spill], b[spill]))
    out = np.dstack([r, g2, b, alpha * 255]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def fit(img):
    box = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    img = img.crop(box)
    side = max(img.size)
    inner = round(SIZE * (1 - 2 * MARGIN))
    scale = inner / side
    img = img.convert("RGBa").resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))),
                                     Image.LANCZOS).convert("RGBA")
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2), img)
    return canvas


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    for name in sorted(os.listdir(src)):
        if name.lower().endswith(".png"):
            fit(key(os.path.join(src, name))).save(os.path.join(dst, name), optimize=True)
            print("ok", name)


if __name__ == "__main__":
    main()
