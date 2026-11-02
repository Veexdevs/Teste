#!/usr/bin/env python3
"""Gera o icon 1024x1024 do SENTINELA sem dependencias externas.

Desenho: fundo verde-oliva escuro, anel tactico, retangulo de mira e
marcadores de canto. E usado como icon de Windows, macOS, iOS e Android.
"""
import math
import os
import struct
import zlib

SIZE = 1024
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "icon.png")


def blend(px, color, alpha):
    if alpha <= 0.0:
        return px
    a = min(1.0, alpha)
    return tuple(int(round(px[i] * (1.0 - a) + color[i] * a)) for i in range(3))


def make():
    buf = [[(11, 16, 13) for _ in range(SIZE)] for _ in range(SIZE)]
    # fundo com gradiente vertical e granulado deterministico
    for y in range(SIZE):
        for x in range(SIZE):
            t = y / SIZE
            grain = ((x * 73 + y * 151) % 17) * 0.35
            buf[y][x] = (
                int(11 + 9 * t + grain),
                int(17 + 13 * t + grain),
                int(14 + 8 * t + grain),
            )
    tan = (214, 208, 168)
    olive = (128, 152, 104)
    dark = (18, 26, 20)

    def disc(cx, cy, r, color, soft=2.0):
        for y in range(max(0, int(cy - r - 3)), min(SIZE, int(cy + r + 4))):
            for x in range(max(0, int(cx - r - 3)), min(SIZE, int(cx + r + 4))):
                d = math.hypot(x - cx, y - cy)
                a = max(0.0, min(1.0, (r + soft - d) / (soft * 2.0)))
                buf[y][x] = blend(buf[y][x], color, a)

    def ring(cx, cy, r, thickness, color):
        for y in range(max(0, int(cy - r - thickness)), min(SIZE, int(cy + r + thickness + 1))):
            for x in range(max(0, int(cx - r - thickness)), min(SIZE, int(cx + r + thickness + 1))):
                d = math.hypot(x - cx, y - cy)
                a = max(0.0, min(1.0, (thickness * 0.5 + 1.2 - abs(d - r)) / 2.2))
                buf[y][x] = blend(buf[y][x], color, a)

    def rect(x0, y0, x1, y1, color):
        for y in range(max(0, y0), min(SIZE, y1)):
            for x in range(max(0, x0), min(SIZE, x1)):
                buf[y][x] = color

    c = SIZE // 2
    # anel exterior e interior
    ring(c, c, 342, 26, tan)
    ring(c, c, 300, 7, olive)
    disc(c, c, 26, tan, 1.0)
    disc(c, c, 9, dark, 1.0)
    # retangulo de mira
    rect(c - 250, c - 3, c - 55, c + 3, tan)
    rect(c + 55, c - 3, c + 250, c + 3, tan)
    rect(c - 3, c - 250, c + 3, c - 55, tan)
    rect(c - 3, c + 55, c + 3, c + 250, tan)
    # marcas de graduacao
    for i in range(-4, 5):
        if i == 0:
            continue
        off = i * 52
        rect(c - 4, c + off - 14, c + 4, c + off + 14, olive)
        rect(c + off - 14, c - 4, c + off + 14, c + 4, olive)
    # cantoneiras militares
    for sx in (-1, 1):
        for sy in (-1, 1):
            x = c + sx * 400
            y = c + sy * 400
            rect(x - 34 if sx < 0 else x, y - 4, x + 34 if sx < 0 else x + 34, y + 4, olive)
            rect(x - 4, y - 34 if sy < 0 else y, x + 4, y + 34 if sy < 0 else y + 34, olive)
    # barra inferior com "S" estilizado (tres segmentos)
    rect(c - 70, c + 330, c + 70, c + 344, tan)
    rect(c - 70, c + 330, c - 56, c + 400, tan)
    rect(c - 70, c + 386, c + 70, c + 400, tan)
    rect(c + 56, c + 386, c + 70, c + 462, tan)
    rect(c - 70, c + 448, c + 70, c + 462, tan)
    return buf


def png(path, pixels):
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b in row:
            raw += bytes((r, g, b, 255))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    png(OUT, make())
    print("gerado", OUT, os.path.getsize(OUT), "bytes")
