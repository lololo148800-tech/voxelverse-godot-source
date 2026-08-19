from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math

root = Path('/home/ubuntu/local_voxel_source/build/reference_pack/files')
out = Path('/home/ubuntu/local_voxel_source/build/reference_pack/reference_contact_sheet.jpg')
images = []
for path in sorted(root.rglob('*')):
    if not path.is_file() or path.suffix.lower() not in {'.png', '.jpg', '.jpeg', '.webp'}:
        continue
    try:
        with Image.open(path) as im:
            im.load()
            images.append((path, im.convert('RGB').copy(), im.size))
    except Exception:
        continue
thumb_w, thumb_h = 180, 118
label_h = 26
cols = 5
rows = max(1, math.ceil(len(images) / cols))
sheet = Image.new('RGB', (cols * thumb_w, rows * (thumb_h + label_h)), (230, 230, 230))
draw = ImageDraw.Draw(sheet)
for index, (path, im, size) in enumerate(images):
    x = (index % cols) * thumb_w
    y = (index // cols) * (thumb_h + label_h)
    im.thumbnail((thumb_w - 8, thumb_h - 8), Image.Resampling.LANCZOS)
    px = x + (thumb_w - im.width) // 2
    py = y + (thumb_h - im.height) // 2
    sheet.paste(im, (px, py))
    name = path.name
    if len(name) > 24:
        name = name[:21] + '...'
    draw.rectangle((x, y + thumb_h, x + thumb_w, y + thumb_h + label_h), fill=(40, 40, 40))
    draw.text((x + 3, y + thumb_h + 5), f'{index+1}: {name}', fill=(255, 255, 255))
sheet.save(out, quality=90)
print(f'images={len(images)}')
print(f'contact_sheet={out}')
for index, (path, _im, size) in enumerate(images, 1):
    print(f'{index}\t{path}\t{size[0]}x{size[1]}')
