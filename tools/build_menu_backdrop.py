from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import math

out = Path('/home/ubuntu/local_voxel_source/assets/ui_standard/assets/ui/menu_backdrop.png')
w, h = 1640, 720
img = Image.new('RGB', (w, h), (20, 34, 31))
d = ImageDraw.Draw(img)
# Cool daylight sky gradient.
for y in range(h):
    t = y / h
    if t < 0.62:
        q = t / 0.62
        c = (int(122 - 28*q), int(165 - 24*q), int(181 - 28*q))
    else:
        q = (t - 0.62) / 0.38
        c = (int(94 - 28*q), int(115 - 38*q), int(90 - 30*q))
    d.line((0, y, w, y), fill=c)
# Distant hills.
d.polygon([(0,430),(160,335),(320,390),(510,285),(700,375),(860,300),(1040,365),(1210,255),(1410,350),(1640,280),(1640,720),(0,720)], fill=(39,67,51))
d.polygon([(0,505),(230,420),(410,460),(620,390),(840,470),(1050,390),(1250,460),(1460,380),(1640,440),(1640,720),(0,720)], fill=(27,48,38))
# Original voxel-like tree silhouettes around the edges, leaving the center open.
def tree(x, base, scale, color):
    trunk_w = int(22*scale)
    d.rectangle((x-trunk_w//2, base-int(145*scale), x+trunk_w//2, base), fill=(67,48,34))
    for ox, oy, rw, rh in [(-55,-150,95,72), (15,-165,110,82), (-5,-105,130,75), (-80,-85,98,62)]:
        box=(int(x+ox*scale-rw*scale/2), int(base+oy*scale-rh*scale/2), int(x+ox*scale+rw*scale/2), int(base+oy*scale+rh*scale/2))
        d.rectangle(box, fill=color)
for args in [(75,590,1.45,(23,57,38)),(250,610,1.15,(29,70,43)),(430,600,0.85,(36,80,47)),(1220,600,1.0,(28,66,42)),(1400,620,1.25,(22,56,37)),(1580,590,1.5,(19,51,35))]:
    tree(*args)
# Blocky cloud accents.
for x,y,s in [(260,110,1.0),(380,150,0.7),(1260,120,0.9),(1390,170,0.6)]:
    for ox,oy,r in [(0,0,38),(42,8,29),(76,18,22)]:
        d.rectangle((x+int(ox*s), y+int(oy*s), x+int((ox+r)*s), y+int((oy+r*0.55)*s)), fill=(195,216,218))
# Dark translucent vignette and central light.
vignette = Image.new('RGBA',(w,h),(0,0,0,0))
vd=ImageDraw.Draw(vignette)
vd.rectangle((0,0,w,h),fill=(7,16,14,80))
vd.rectangle((360,70,1280,650),fill=(255,255,255,16))
vignette=vignette.filter(ImageFilter.GaussianBlur(18))
img=Image.alpha_composite(img.convert('RGBA'),vignette).convert('RGB')
out.parent.mkdir(parents=True,exist_ok=True)
img.save(out,optimize=True)
print(f'WROTE {out} {w}x{h}')
