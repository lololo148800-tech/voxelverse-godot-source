from pathlib import Path
from PIL import Image, ImageDraw
import math, shutil

root = Path('/home/ubuntu/local_voxel_source/build/reference_pack/files')
all_images = []
for path in sorted(root.rglob('*')):
    if path.is_file() and path.suffix.lower() in {'.png', '.jpg', '.jpeg', '.webp'}:
        try:
            with Image.open(path) as im:
                im.load()
                all_images.append((path, im.copy().convert('RGB')))
        except Exception:
            pass
start, end = 80, 110
selected = all_images[start-1:end]
out_dir = Path('/home/ubuntu/local_voxel_source/build/reference_pack/selected_80_110')
out_dir.mkdir(parents=True, exist_ok=True)
manifest = out_dir / 'manifest.tsv'
thumb_w, thumb_h, label_h = 400, 176, 24
cols = 3
rows = max(1, math.ceil(len(selected) / cols))
sheet = Image.new('RGB', (cols * thumb_w, rows * (thumb_h + label_h)), (225, 225, 225))
draw = ImageDraw.Draw(sheet)
with manifest.open('w', encoding='utf-8') as mf:
    for offset, (src, im) in enumerate(selected):
        index = start + offset
        dst = out_dir / f'reference_{index:03d}.png'
        shutil.copy2(src, dst)
        mf.write(f'{index}\t{dst}\t{src}\n')
        im.thumbnail((thumb_w - 8, thumb_h - 8), Image.Resampling.LANCZOS)
        x = (offset % cols) * thumb_w
        y = (offset // cols) * (thumb_h + label_h)
        sheet.paste(im, (x + (thumb_w-im.width)//2, y + (thumb_h-im.height)//2))
        draw.rectangle((x, y + thumb_h, x + thumb_w, y + thumb_h + label_h), fill=(35,35,35))
        draw.text((x + 4, y + thumb_h + 4), f'{index}: {src.name}', fill=(255,255,255))
sheet_path = out_dir / 'range_80_110.jpg'
sheet.save(sheet_path, quality=92)
print(f'count={len(selected)}')
print(f'sheet={sheet_path}')
print(f'manifest={manifest}')
