from pathlib import Path
from PIL import Image
import json

ROOT = Path('/home/ubuntu/voxelverse_textures')
REF = ROOT / 'style_reference.png'
OUT = ROOT / 'textures'
MAP = ROOT / 'atlas_map.json'

# The reference is a preserved 10×10 contact sheet in the same order as the 100 IDs.
# Transparent/animated-material fallbacks remain from the procedural source pack because
# an opaque style board cannot preserve alpha semantics.
TRANSPARENT_OR_SHADER_TILES = {
    'ICE', 'GLASS', 'GLASS_TINTED', 'WATER_STILL', 'LAVA_STILL', 'SLIME', 'HONEY', 'COBWEB'
}

with open(ROOT / 'validation.json', 'r', encoding='utf-8') as f:
    previous = json.load(f)
ordered = [entry['name'] for entry in previous['tiles']]

ref = Image.open(REF).convert('RGB')
if ref.size != (1920, 1920):
    raise RuntimeError(f'Expected 1920x1920 style reference, got {ref.size}')
cell = 192
for index, name in enumerate(ordered):
    if name in TRANSPARENT_OR_SHADER_TILES:
        continue
    col = index % 10
    row = index // 10
    crop = ref.crop((col * cell, row * cell, (col + 1) * cell, (row + 1) * cell))
    # Keep the reference's chunky material cues, remove accidental photographic color depth,
    # and reduce without anti-aliasing to the exact game tile size.
    crop = crop.resize((16, 16), Image.Resampling.NEAREST).convert('RGB')
    crop = crop.quantize(colors=6, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGBA')
    crop.save(OUT / f'{name}.png', 'PNG', optimize=False)

print(f'Applied style reference to {100 - len(TRANSPARENT_OR_SHADER_TILES)} opaque tiles; preserved {len(TRANSPARENT_OR_SHADER_TILES)} alpha/shader tiles.')
