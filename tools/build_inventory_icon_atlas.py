from PIL import Image, ImageDraw
from pathlib import Path

out = Path('/home/ubuntu/local_voxel_source/assets/ui_standard/assets/ui/inventory_icon_atlas.png')
W, H, TILE = 256, 128, 32
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
colors = [(73,151,68,255),(124,83,48,255),(137,145,148,255),(151,91,46,255),(49,125,60,255),(204,171,94,255),(222,229,228,255),(56,151,204,255),(219,177,52,255),(229,48,36,255),(222,157,70,255),(181,190,195,255),(202,211,218,255),(190,133,62,255),(238,192,77,255),(124,78,201,255),(77,187,212,255),(174,103,204,255),(72,163,102,255),(166,116,71,255),(194,142,72,255),(164,94,53,255),(97,201,212,255),(142,104,216,255),(88,160,97,255),(201,102,61,255),(220,204,88,255),(174,124,83,255),(100,175,215,255),(213,212,219,255),(124,98,70,255),(120,178,104,255)]

def tile(i, kind):
    tx, ty = i % 8, i // 8
    x0, y0 = tx*TILE, ty*TILE
    # neutral frame keeps every icon readable on blue/green item cards
    d.rectangle((x0+3,y0+3,x0+28,y0+28), fill=(10,18,16,110), outline=(212,226,210,120), width=1)
    c = colors[i % len(colors)]
    cx, cy = x0+16, y0+16
    if kind == 'block':
        d.rectangle((x0+8,y0+8,x0+24,y0+24), fill=c, outline=(20,35,25,255), width=2)
        for p in [(10,10),(20,12),(14,21)]: d.rectangle((x0+p[0],y0+p[1],x0+p[0]+2,y0+p[1]+2), fill=(255,255,255,100))
    elif kind == 'ore':
        d.ellipse((x0+9,y0+9,x0+23,y0+23), fill=c, outline=(30,35,25,255), width=2)
        d.ellipse((x0+13,y0+13,x0+18,y0+18), fill=(235,239,180,220))
    elif kind == 'tool':
        d.line((x0+8,y0+24,x0+23,y0+9), fill=(164,106,59,255), width=4)
        d.line((x0+12,y0+10,x0+23,y0+6), fill=c, width=4)
        d.line((x0+18,y0+7,x0+25,y0+13), fill=c, width=3)
    elif kind == 'food':
        d.ellipse((x0+9,y0+9,x0+22,y0+23), fill=c, outline=(92,38,27,255), width=2)
        d.line((cx+3,cy-7,cx+8,cy-13), fill=(88,123,57,255), width=2)
    elif kind == 'crystal':
        d.polygon([(cx,y0+7),(x0+24,cy),(cx,y0+25),(x0+8,cy)], fill=c, outline=(28,39,55,255))
        d.line((cx, y0+9, cx, y0+22), fill=(245,247,255,180), width=1)
    elif kind == 'magic':
        d.polygon([(cx,y0+7),(x0+20,cy),(cx,y0+25),(x0+12,cy)], fill=c, outline=(240,235,255,240))
        d.ellipse((x0+12,y0+12,x0+20,y0+20), outline=(255,255,255,190), width=1)
    elif kind == 'furniture':
        d.rectangle((x0+8,y0+10,x0+24,y0+22), fill=c, outline=(37,33,24,255), width=2)
        d.line((x0+10,y0+22,x0+10,y0+26), fill=(115,76,41,255), width=2)
        d.line((x0+22,y0+22,x0+22,y0+26), fill=(115,76,41,255), width=2)
    elif kind == 'rail':
        d.line((x0+8,y0+9,x0+24,y0+9), fill=c, width=3)
        d.line((x0+8,y0+23,x0+24,y0+23), fill=c, width=3)
        for x in [10,15,20,24]: d.line((x0+x,y0+9,x0+x,y0+23), fill=(205,181,92,255), width=2)
    else:
        d.ellipse((x0+10,y0+10,x0+22,y0+22), fill=c, outline=(25,35,28,255), width=2)

kinds = ['block','block','block','block','block','block','block','block','ore','food','food','tool','tool','furniture','furniture','crystal','magic','magic','block','furniture','furniture','furniture','rail','magic','block','block','ore','ore','ore','ore','ore','block']
for i, kind in enumerate(kinds): tile(i, kind)
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out, optimize=True)
print(f'WROTE {out} {W}x{H}')
