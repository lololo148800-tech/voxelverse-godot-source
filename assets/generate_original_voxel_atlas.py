from pathlib import Path
from PIL import Image
import json

SOURCE_DIR = Path('/home/ubuntu/texture_stage/textures/original_voxel_blocks_4views')
ATLAS_PATH = Path('/home/ubuntu/local_voxel_source/assets/textures/voxel_atlas.png')
MANIFEST_PATH = Path('/home/ubuntu/local_voxel_source/assets/textures/original_voxel_atlas_manifest.json')
TILE_SIZE = 16
ATLAS_COLUMNS = 16
ATLAS_ROWS = 16

files = sorted(SOURCE_DIR.glob('*.png'))
if len(files) != 200:
    raise RuntimeError(f'expected 200 source textures, found {len(files)}')

atlas = Image.new('RGBA', (ATLAS_COLUMNS * TILE_SIZE, ATLAS_ROWS * TILE_SIZE), (0, 0, 0, 0))
manifest = {
    'source_count': len(files),
    'tile_size': TILE_SIZE,
    'columns': ATLAS_COLUMNS,
    'rows': ATLAS_ROWS,
    'crop': 'top_left_cube_view_alpha_bbox',
    'tiles': [],
}

for index, source in enumerate(files):
    with Image.open(source) as image:
        rgba = image.convert('RGBA')
        # The supplied files are four-view cube boards. The top-left quadrant is
        # one clean, consistently framed view; crop its non-transparent object.
        quadrant = rgba.crop((0, 0, rgba.width // 2, rgba.height // 2))
        bbox = quadrant.getchannel('A').getbbox()
        if bbox is None:
            bbox = (0, 0, quadrant.width, quadrant.height)
        cropped = quadrant.crop(bbox)
        cropped.thumbnail((TILE_SIZE - 2, TILE_SIZE - 2), Image.Resampling.LANCZOS)
        tile = Image.new('RGBA', (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
        offset = ((TILE_SIZE - cropped.width) // 2, (TILE_SIZE - cropped.height) // 2)
        tile.alpha_composite(cropped, offset)
    x = (index % ATLAS_COLUMNS) * TILE_SIZE
    y = (index // ATLAS_COLUMNS) * TILE_SIZE
    atlas.alpha_composite(tile, (x, y))
    manifest['tiles'].append({
        'source_id': index + 1,
        'source_file': source.name,
        'tile_x': index % ATLAS_COLUMNS,
        'tile_y': index // ATLAS_COLUMNS,
    })

ATLAS_PATH.parent.mkdir(parents=True, exist_ok=True)
atlas.save(ATLAS_PATH, format='PNG', optimize=False)
MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'WROTE {ATLAS_PATH} size={atlas.size} sources={len(files)}')
print(f'WROTE {MANIFEST_PATH}')
