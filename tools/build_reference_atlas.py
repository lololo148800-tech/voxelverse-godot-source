from PIL import Image, ImageDraw
import json
from pathlib import Path

ROOT = Path('/home/ubuntu/local_voxel_source')
OUT = ROOT / 'assets' / 'textures' / 'voxel_atlas.png'
W, H = 128, 64
img = Image.new('RGB', (W, H), (22, 30, 28))
draw = ImageDraw.Draw(img)


def shade(c, amount):
    return tuple(max(0, min(255, int(v * amount))) for v in c)


def noise_value(x, y, salt):
    return ((x * 37 + y * 67 + salt * 19 + (x + 3) * (y + 5) * 11) % 29) - 14


def tile(tx, ty, base, salt, mode='solid'):
    atlas_x = tx % 8
    atlas_y = ty + tx // 8
    if atlas_y >= 4:
        return
    x0, y0 = atlas_x * 16, atlas_y * 16
    for y in range(16):
        for x in range(16):
            jitter = noise_value(x, y, salt)
            c = tuple(max(0, min(255, v + jitter)) for v in base)
            if mode == 'leaves':
                if (x * 5 + y * 3 + salt) % 6 == 0:
                    c = shade(c, 0.62)
                elif (x * 7 + y * 11 + salt) % 9 == 0:
                    c = shade(c, 1.24)
                elif (x + y + salt) % 13 == 0:
                    c = shade(c, 0.78)
            elif mode == 'water':
                c = shade(c, 0.82 + ((y % 5) * 0.06))
            elif mode == 'dirt':
                if (x * 7 + y * 13 + salt) % 17 == 0:
                    c = shade(c, 0.68)
                elif (x * 11 + y * 5 + salt) % 19 == 0:
                    c = shade(c, 1.20)
            elif mode == 'stone':
                if (x * 9 + y * 7 + salt) % 15 == 0:
                    c = shade(c, 0.72)
            img.putpixel((x0 + x, y0 + y), c)
    if mode == 'grass':
        for x, y in [(1, 4), (4, 11), (6, 2), (8, 8), (11, 5), (14, 12), (15, 2), (3, 15), (12, 15)]:
            draw.line((x0 + x, y0 + y, x0 + x + (1 if (x + y) % 2 else -1), y0 + y - 4), fill=shade(base, 1.34), width=1)
        for x, y in [(2, 7), (5, 14), (9, 4), (13, 9), (15, 14)]:
            draw.point((x0 + x, y0 + y), fill=shade(base, 0.54))
    elif mode == 'wood':
        for x in [3, 8, 13]:
            draw.line((x0 + x, y0 + 1, x0 + x, y0 + 15), fill=shade(base, 0.62), width=1)
        draw.line((x0 + 1, y0 + 5, x0 + 14, y0 + 5), fill=shade(base, 1.17), width=1)
    elif mode == 'leaves':
        for p in [(1, 2), (5, 5), (11, 1), (14, 6), (3, 12), (9, 10), (13, 14)]:
            draw.rectangle((x0 + p[0], y0 + p[1], x0 + p[0] + 1, y0 + p[1] + 1), fill=shade(base, 1.34))
        for p in [(3, 1), (8, 4), (12, 9), (6, 14)]:
            draw.line((x0 + p[0], y0 + p[1], x0 + p[0] + 2, y0 + p[1] + 3), fill=shade(base, 0.52), width=1)
    elif mode == 'water':
        for y in [2, 6, 10, 14]:
            draw.line((x0 + 1, y0 + y, x0 + 5, y0 + y + 1), fill=shade(base, 1.34), width=1)
            draw.line((x0 + 9, y0 + y, x0 + 14, y0 + y - 1), fill=shade(base, 1.18), width=1)
    elif mode == 'dirt':
        for p in [(2, 3), (11, 4), (6, 9), (14, 12), (3, 14)]:
            draw.rectangle((x0 + p[0], y0 + p[1], x0 + p[0] + 1, y0 + p[1] + 1), fill=shade(base, 0.52))
    elif mode == 'stone':
        for p in [(2, 5), (8, 2), (13, 7), (5, 12), (14, 14)]:
            draw.point((x0 + p[0], y0 + p[1]), fill=shade(base, 0.56))


def ore_tile(tx, ty, base, salt):
    tile(tx, ty, (76, 78, 76), salt, 'solid')
    atlas_x = tx % 8
    atlas_y = ty + tx // 8
    if atlas_y >= 4:
        return
    x0, y0 = atlas_x * 16, atlas_y * 16
    for x, y in [(3, 4), (11, 5), (7, 11), (13, 13)]:
        color = tuple(max(0, min(255, v + noise_value(x, y, salt))) for v in base)
        draw.rectangle((x0 + x, y0 + y, x0 + x + 2, y0 + y + 2), fill=color)
        draw.point((x0 + x + 1, y0 + y - 1), fill=shade(color, 1.25))

# Base registry tiles used by _texture_tile_for_block.
tile(0, 0, (78, 145, 72), 1, 'grass')
tile(1, 0, (110, 72, 46), 2, 'dirt')
tile(2, 0, (128, 135, 132), 3, 'stone')
tile(3, 0, (139, 91, 48), 4, 'wood')
tile(4, 0, (36, 92, 43), 5, 'leaves')
tile(5, 0, (190, 157, 88), 6)
tile(6, 0, (218, 224, 216), 7)
for mark_x, mark_y in [(3, 3), (10, 6), (5, 10), (13, 13)]:
    draw.rectangle((6 * 16 + mark_x, mark_y, 6 * 16 + mark_x + 2, mark_y + 1), fill=(64, 68, 64))
tile(7, 0, (74, 181, 196), 8)
tile(8, 0, (105, 93, 89), 9)
tile(9, 0, (68, 139, 88), 10, 'leaves')
tile(0, 1, (209, 167, 78), 11)
tile(1, 1, (158, 117, 76), 12)
tile(2, 1, (63, 144, 201), 13, 'water')
tile(3, 1, (190, 78, 55), 14)
tile(4, 1, (68, 84, 130), 15)
tile(5, 1, (78, 200, 226), 16)
tile(6, 1, (147, 111, 198), 17)
tile(7, 1, (221, 161, 81), 18)
tile(0, 2, (86, 152, 205), 19)
tile(1, 2, (154, 109, 79), 20)
tile(2, 2, (111, 58, 89), 21)
tile(3, 2, (82, 55, 93), 22)
tile(4, 2, (109, 75, 65), 23)
tile(5, 2, (201, 105, 201), 24)
tile(6, 2, (152, 171, 196), 25)
tile(7, 2, (185, 93, 213), 26)
tile(0, 3, (76, 162, 189), 27)
tile(1, 3, (182, 221, 236), 28)
tile(2, 3, (68, 54, 82), 29)
tile(3, 3, (153, 93, 48), 30)
tile(4, 3, (217, 100, 59), 31)
tile(5, 3, (96, 205, 224), 32)
tile(6, 3, (240, 212, 103), 33)
tile(7, 3, (196, 116, 71), 34)

# Keep ore tile columns 16..65 exactly where the engine expects them.
ores_path = ROOT / 'data' / 'ores.json'
ore_entries = json.loads(ores_path.read_text(encoding='utf-8'))
for index, entry in enumerate(ore_entries[:50]):
    tx = 16 + (index % 16)
    ty = 0
    raw = str(entry.get('color', '9aa0a0')).lstrip('#')
    try:
        base = tuple(int(raw[i:i + 2], 16) for i in (0, 2, 4))
    except Exception:
        base = (150, 160, 160)
    ore_tile(tx, ty, base, 100 + index)

img.save(OUT, optimize=True)
print(f'WROTE {OUT} {img.size[0]}x{img.size[1]}')
