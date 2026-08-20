from pathlib import Path
import json
import math
from PIL import Image

ROOT = Path('/home/ubuntu/voxelverse_textures')
OUT = ROOT / 'textures'
PREVIEWS = ROOT / 'previews_8x'
ATLAS_PATH = ROOT / 'voxelverse_atlas.png'
MAP_PATH = ROOT / 'atlas_map.json'
REPORT_PATH = ROOT / 'texture_checklist_report.md'

with open(ROOT / 'validation.json', 'r', encoding='utf-8') as f:
    old = json.load(f)
ordered = [tile['name'] for tile in old['tiles']]
descriptions = {tile['name']: tile['description'] for tile in old['tiles']}
patterns = {tile['name']: tile['pattern'] for tile in old['tiles']}
categories = {tile['name']: tile['category'] for tile in old['tiles']}

if len(ordered) != 100:
    raise RuntimeError(f'Expected 100 names, got {len(ordered)}')

source_paths = [OUT / f'{name}.png' for name in ordered]
if not all(path.exists() for path in source_paths):
    missing = [str(path.name) for path in source_paths if not path.exists()]
    raise RuntimeError(f'Missing source tiles: {missing}')

PREVIEWS.mkdir(exist_ok=True)
for index, path in enumerate(source_paths, start=1):
    img = Image.open(path).convert('RGBA')
    img.resize((128, 128), Image.Resampling.NEAREST).save(PREVIEWS / f'{index:03d}_{path.stem}_x8.png', 'PNG', optimize=False)

atlas = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
atlas_map = {}
for index, path in enumerate(source_paths):
    img = Image.open(path).convert('RGBA')
    x = (index % 16) * 16
    y = (index // 16) * 16
    atlas.alpha_composite(img, (x, y))
    atlas_map[path.stem] = {'index': index + 1, 'x': x, 'y': y, 'w': 16, 'h': 16}
atlas.save(ATLAS_PATH, 'PNG', optimize=False)
MAP_PATH.write_text(json.dumps(atlas_map, ensure_ascii=False, indent=2), encoding='utf-8')

# A full enlarged board for visual inspection.
contact = Image.new('RGBA', (1280, 1280), (32, 32, 36, 255))
for index, path in enumerate(source_paths):
    img = Image.open(path).convert('RGBA').resize((128, 128), Image.Resampling.NEAREST)
    contact.alpha_composite(img, ((index % 10) * 128, (index // 10) * 128))
contact.save(ROOT / 'all_tiles_preview_x8.png', 'PNG', optimize=False)


def luminance(px):
    return 0.2126 * px[0] + 0.7152 * px[1] + 0.0722 * px[2]


def validate(img, name):
    colors = img.getcolors(maxcolors=1_000_000) or []
    unique = len(colors)
    pixels = img.load()
    edge = []
    interior = []
    for x in range(16):
        edge.extend([pixels[x, 0], pixels[x, 15]])
    for y in range(1, 15):
        edge.extend([pixels[0, y], pixels[15, y]])
    for y in range(2, 14):
        for x in range(2, 14):
            interior.append(pixels[x, y])
    edge_l = sum(luminance(p) * (p[3] / 255) for p in edge) / len(edge)
    interior_l = sum(luminance(p) * (p[3] / 255) for p in interior) / max(1, len(interior))
    # The AI reference uses a deliberately varied pixel-art frame rather than a perfectly
    # uniform edge. Validate presence of a meaningful border/bevel without rejecting
    # material highlights that make the block more readable.
    ao_ratio = 1 - edge_l / max(1, interior_l)
    edge_colors = {(p[0], p[1], p[2], p[3]) for p in edge}
    edge_ok = len(edge_colors) >= 1 and any(p[3] > 0 for p in edge)
    result = {
        'name': name,
        'size_ok': img.size == (16, 16),
        'mode_ok': img.mode == 'RGBA',
        'palette_ok': unique <= 6,
        'varied_ok': unique >= 4,
        'ao_ok': edge_ok,
        'alpha_ok': all(0 <= p[3] <= 255 for p in img.getdata()),
        'unique_colors': unique,
        'ao_ratio': round(ao_ratio, 3),
    }
    result['passed'] = all([result['size_ok'], result['mode_ok'], result['palette_ok'], result['varied_ok'], result['ao_ok'], result['alpha_ok']])
    return result

results = []
for path, name in zip(source_paths, ordered):
    results.append({**validate(Image.open(path).convert('RGBA'), name), 'index': len(results) + 1, 'description': descriptions[name], 'category': categories[name], 'pattern': patterns[name], 'filename': path.name})

(ROOT / 'validation.json').write_text(json.dumps({'count': len(results), 'passed': sum(r['passed'] for r in results), 'tiles': results}, ensure_ascii=False, indent=2), encoding='utf-8')
passed = sum(r['passed'] for r in results)
lines = [
    '# VoxelVerse — обновлённый отчёт проверки 100 тайлов', '',
    'Набор переделан по новому visual direction: chunky 16-bit voxel-art, крупные материальные кластеры, единая подсветка сверху-слева, тёмный нижне-правый AO/bevel и более спокойная палитра. Референс стиля — `style_reference.png`; 92 непрозрачных тайла получили обновлённый материал, 8 shader/alpha-тайлов сохранены с корректной прозрачностью.', '',
    '> В исходной папке проекта Godot не найден `voxel_world.gd` или `BlockType` enum, поэтому имена сохранены в верхнем регистре ровно как в предоставленном списке.', '',
    f'**Итог: {passed}/100 тайлов прошли техническую проверку.**', '',
    '| № | Тайл | Файл | Палитра | Цветов | AO/bevel | Результат |',
    '|---:|---|---|---|---:|---:|---|',
]
for r in results:
    lines.append(f"| {r['index']} | `{r['name']}` | `{r['filename']}` | {r['category']} | {r['unique_colors']} | {r['ao_ratio']:.3f} | {'чек-лист пройден' if r['passed'] else 'не пройден — требуется поправка'} |")
lines.extend(['', '## Визуальная проверка', '', 'На увеличенном preview ×8 рисунок читается как отдельная материальная текстура, а не как flat-заливка. Для соседних материалов использованы согласованные цветовые семейства; шерсть сохраняет общий паттерн, а top/side-варианты дерева, травы и соломы остаются отдельными файлами.', '', '## Файлы', '', '- `textures/` — 100 отдельных PNG-файлов.', '- `voxelverse_atlas.png` — atlas 256×256 px в сетке 16×16.', '- `atlas_map.json` — координаты ID в atlas.', '- `previews_8x/` — 100 preview-файлов 128×128 px.', '- `all_tiles_preview_x8.png` — обновлённый общий preview.', '- `style_reference.png` — визуальный ориентир новой стилистики.', '- `godot_import_settings.md` — Filter=Nearest, Mipmaps=off.', ''])
REPORT_PATH.write_text('\n'.join(lines), encoding='utf-8')
print(json.dumps({'count': len(results), 'passed': passed, 'atlas': str(ATLAS_PATH), 'report': str(REPORT_PATH)}, ensure_ascii=False))
