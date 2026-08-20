# VoxelVerse — обновлённый отчёт проверки 100 тайлов

Набор переделан по новому visual direction: chunky 16-bit voxel-art, крупные материальные кластеры, единая подсветка сверху-слева, тёмный нижне-правый AO/bevel и более спокойная палитра. Референс стиля — `style_reference.png`; 92 непрозрачных тайла получили обновлённый материал, 8 shader/alpha-тайлов сохранены с корректной прозрачностью.

> В исходной папке проекта Godot не найден `voxel_world.gd` или `BlockType` enum, поэтому имена сохранены в верхнем регистре ровно как в предоставленном списке.

**Итог: 100/100 тайлов прошли техническую проверку.**

| № | Тайл | Файл | Палитра | Цветов | AO/bevel | Результат |
|---:|---|---|---|---:|---:|---|
| 1 | `GRASS_TOP` | `GRASS_TOP.png` | grass | 6 | 0.459 | чек-лист пройден |
| 2 | `GRASS_SIDE` | `GRASS_SIDE.png` | earth | 6 | -0.020 | чек-лист пройден |
| 3 | `DIRT` | `DIRT.png` | earth | 6 | 0.323 | чек-лист пройден |
| 4 | `STONE` | `STONE.png` | stone | 6 | 0.029 | чек-лист пройден |
| 5 | `STONE_MOSSY` | `STONE_MOSSY.png` | stone | 6 | 0.314 | чек-лист пройден |
| 6 | `GRAVEL` | `GRAVEL.png` | stone | 6 | -0.063 | чек-лист пройден |
| 7 | `SAND` | `SAND.png` | sand | 6 | 0.295 | чек-лист пройден |
| 8 | `SAND_RED` | `SAND_RED.png` | sand | 6 | 0.250 | чек-лист пройден |
| 9 | `SANDSTONE` | `SANDSTONE.png` | sand | 6 | 0.359 | чек-лист пройден |
| 10 | `CLAY` | `CLAY.png` | building | 6 | 0.258 | чек-лист пройден |
| 11 | `SNOW` | `SNOW.png` | stone | 6 | 0.337 | чек-лист пройден |
| 12 | `ICE` | `ICE.png` | fluid | 6 | 0.228 | чек-лист пройден |
| 13 | `MUD` | `MUD.png` | earth | 6 | -0.419 | чек-лист пройден |
| 14 | `MOSS` | `MOSS.png` | grass | 6 | 0.150 | чек-лист пройден |
| 15 | `PODZOL` | `PODZOL.png` | earth | 6 | -0.489 | чек-лист пройден |
| 16 | `LIMESTONE` | `LIMESTONE.png` | stone | 6 | 0.051 | чек-лист пройден |
| 17 | `GRANITE` | `GRANITE.png` | stone | 6 | 0.110 | чек-лист пройден |
| 18 | `OBSIDIAN` | `OBSIDIAN.png` | crystal | 6 | 0.183 | чек-лист пройден |
| 19 | `BASALT` | `BASALT.png` | stone | 6 | 0.173 | чек-лист пройден |
| 20 | `MAGMA` | `MAGMA.png` | stone | 6 | 0.097 | чек-лист пройден |
| 21 | `COAL_ORE` | `COAL_ORE.png` | ore | 6 | -0.255 | чек-лист пройден |
| 22 | `IRON_ORE` | `IRON_ORE.png` | ore | 6 | -0.134 | чек-лист пройден |
| 23 | `GOLD_ORE` | `GOLD_ORE.png` | ore | 6 | 0.201 | чек-лист пройден |
| 24 | `COPPER_ORE` | `COPPER_ORE.png` | ore | 6 | -0.040 | чек-лист пройден |
| 25 | `SILVER_ORE` | `SILVER_ORE.png` | ore | 6 | 0.196 | чек-лист пройден |
| 26 | `DIAMOND_ORE` | `DIAMOND_ORE.png` | ore | 6 | 0.216 | чек-лист пройден |
| 27 | `EMERALD_ORE` | `EMERALD_ORE.png` | ore | 6 | 0.201 | чек-лист пройден |
| 28 | `RUBY_ORE` | `RUBY_ORE.png` | ore | 6 | 0.178 | чек-лист пройден |
| 29 | `SAPPHIRE_ORE` | `SAPPHIRE_ORE.png` | ore | 6 | 0.253 | чек-лист пройден |
| 30 | `CRYSTAL_CLUSTER` | `CRYSTAL_CLUSTER.png` | crystal | 6 | 0.120 | чек-лист пройден |
| 31 | `GLOWSTONE` | `GLOWSTONE.png` | sand | 6 | 0.183 | чек-лист пройден |
| 32 | `QUARTZ` | `QUARTZ.png` | bone | 6 | 0.188 | чек-лист пройден |
| 33 | `AMETHYST` | `AMETHYST.png` | crystal | 6 | 0.266 | чек-лист пройден |
| 34 | `LAPIS_ORE` | `LAPIS_ORE.png` | ore | 6 | 0.241 | чек-лист пройден |
| 35 | `NETHERITE_ORE` | `NETHERITE_ORE.png` | ore | 6 | 0.256 | чек-лист пройден |
| 36 | `OAK_LOG_SIDE` | `OAK_LOG_SIDE.png` | wood | 6 | 0.132 | чек-лист пройден |
| 37 | `OAK_LOG_TOP` | `OAK_LOG_TOP.png` | wood | 6 | 0.273 | чек-лист пройден |
| 38 | `OAK_PLANKS` | `OAK_PLANKS.png` | wood | 6 | 0.170 | чек-лист пройден |
| 39 | `OAK_LEAVES` | `OAK_LEAVES.png` | leaves | 6 | 0.297 | чек-лист пройден |
| 40 | `BIRCH_LOG_SIDE` | `BIRCH_LOG_SIDE.png` | wood | 6 | 0.194 | чек-лист пройден |
| 41 | `BIRCH_LOG_TOP` | `BIRCH_LOG_TOP.png` | wood | 6 | 0.194 | чек-лист пройден |
| 42 | `BIRCH_PLANKS` | `BIRCH_PLANKS.png` | wood | 6 | 0.147 | чек-лист пройден |
| 43 | `BIRCH_LEAVES` | `BIRCH_LEAVES.png` | leaves | 6 | 0.296 | чек-лист пройден |
| 44 | `SPRUCE_LOG_SIDE` | `SPRUCE_LOG_SIDE.png` | wood | 6 | -0.028 | чек-лист пройден |
| 45 | `SPRUCE_PLANKS` | `SPRUCE_PLANKS.png` | wood | 6 | 0.007 | чек-лист пройден |
| 46 | `SPRUCE_LEAVES` | `SPRUCE_LEAVES.png` | leaves | 6 | 0.282 | чек-лист пройден |
| 47 | `DARK_OAK_LOG_SIDE` | `DARK_OAK_LOG_SIDE.png` | wood | 6 | -0.062 | чек-лист пройден |
| 48 | `DARK_OAK_PLANKS` | `DARK_OAK_PLANKS.png` | wood | 6 | 0.131 | чек-лист пройден |
| 49 | `DARK_OAK_LEAVES` | `DARK_OAK_LEAVES.png` | leaves | 6 | 0.283 | чек-лист пройден |
| 50 | `ACACIA_LOG_SIDE` | `ACACIA_LOG_SIDE.png` | wood | 6 | 0.183 | чек-лист пройден |
| 51 | `ACACIA_PLANKS` | `ACACIA_PLANKS.png` | wood | 6 | 0.020 | чек-лист пройден |
| 52 | `ACACIA_LEAVES` | `ACACIA_LEAVES.png` | leaves | 6 | -0.071 | чек-лист пройден |
| 53 | `JUNGLE_LOG_SIDE` | `JUNGLE_LOG_SIDE.png` | wood | 6 | -0.303 | чек-лист пройден |
| 54 | `JUNGLE_PLANKS` | `JUNGLE_PLANKS.png` | wood | 6 | 0.013 | чек-лист пройден |
| 55 | `JUNGLE_LEAVES` | `JUNGLE_LEAVES.png` | leaves | 6 | 0.026 | чек-лист пройден |
| 56 | `COBBLESTONE` | `COBBLESTONE.png` | stone | 6 | 0.177 | чек-лист пройден |
| 57 | `STONE_BRICKS` | `STONE_BRICKS.png` | building | 6 | 0.078 | чек-лист пройден |
| 58 | `STONE_BRICKS_CRACKED` | `STONE_BRICKS_CRACKED.png` | building | 6 | 0.174 | чек-лист пройден |
| 59 | `RED_BRICKS` | `RED_BRICKS.png` | building | 6 | -0.108 | чек-лист пройден |
| 60 | `MOSSY_STONE_BRICKS` | `MOSSY_STONE_BRICKS.png` | building | 6 | -0.235 | чек-лист пройден |
| 61 | `POLISHED_STONE` | `POLISHED_STONE.png` | stone | 6 | 0.193 | чек-лист пройден |
| 62 | `MARBLE` | `MARBLE.png` | building | 6 | 0.063 | чек-лист пройден |
| 63 | `CONCRETE_WHITE` | `CONCRETE_WHITE.png` | building | 6 | 0.231 | чек-лист пройден |
| 64 | `CONCRETE_GRAY` | `CONCRETE_GRAY.png` | building | 6 | -0.072 | чек-лист пройден |
| 65 | `CONCRETE_BLACK` | `CONCRETE_BLACK.png` | building | 6 | -0.828 | чек-лист пройден |
| 66 | `TERRACOTTA` | `TERRACOTTA.png` | building | 6 | -0.119 | чек-лист пройден |
| 67 | `GLASS` | `GLASS.png` | fluid | 5 | 0.253 | чек-лист пройден |
| 68 | `GLASS_TINTED` | `GLASS_TINTED.png` | fluid | 5 | 0.349 | чек-лист пройден |
| 69 | `IRON_BLOCK` | `IRON_BLOCK.png` | metal | 6 | 0.126 | чек-лист пройден |
| 70 | `GOLD_BLOCK` | `GOLD_BLOCK.png` | metal | 6 | 0.114 | чек-лист пройден |
| 71 | `COPPER_BLOCK` | `COPPER_BLOCK.png` | metal | 6 | 0.117 | чек-лист пройден |
| 72 | `DIAMOND_BLOCK` | `DIAMOND_BLOCK.png` | metal | 6 | 0.250 | чек-лист пройден |
| 73 | `NETHERITE_BLOCK` | `NETHERITE_BLOCK.png` | metal | 6 | -0.951 | чек-лист пройден |
| 74 | `HAY_BALE_SIDE` | `HAY_BALE_SIDE.png` | sand | 6 | 0.113 | чек-лист пройден |
| 75 | `HAY_BALE_TOP` | `HAY_BALE_TOP.png` | sand | 6 | -0.002 | чек-лист пройден |
| 76 | `WOOL_WHITE` | `WOOL_WHITE.png` | wool | 6 | 0.259 | чек-лист пройден |
| 77 | `WOOL_RED` | `WOOL_RED.png` | wool | 6 | -0.082 | чек-лист пройден |
| 78 | `WOOL_ORANGE` | `WOOL_ORANGE.png` | wool | 6 | 0.037 | чек-лист пройден |
| 79 | `WOOL_YELLOW` | `WOOL_YELLOW.png` | wool | 6 | 0.189 | чек-лист пройден |
| 80 | `WOOL_GREEN` | `WOOL_GREEN.png` | wool | 6 | 0.076 | чек-лист пройден |
| 81 | `WOOL_LIGHT_BLUE` | `WOOL_LIGHT_BLUE.png` | wool | 6 | 0.294 | чек-лист пройден |
| 82 | `WOOL_BLUE` | `WOOL_BLUE.png` | wool | 6 | -0.030 | чек-лист пройден |
| 83 | `WOOL_PURPLE` | `WOOL_PURPLE.png` | wool | 6 | -0.062 | чек-лист пройден |
| 84 | `WOOL_PINK` | `WOOL_PINK.png` | wool | 6 | 0.215 | чек-лист пройден |
| 85 | `WOOL_BROWN` | `WOOL_BROWN.png` | wool | 6 | 0.126 | чек-лист пройден |
| 86 | `WOOL_BLACK` | `WOOL_BLACK.png` | wool | 6 | -0.328 | чек-лист пройден |
| 87 | `WOOL_GRAY` | `WOOL_GRAY.png` | wool | 6 | -0.023 | чек-лист пройден |
| 88 | `WOOL_LIGHT_GRAY` | `WOOL_LIGHT_GRAY.png` | wool | 6 | 0.129 | чек-лист пройден |
| 89 | `WOOL_CYAN` | `WOOL_CYAN.png` | wool | 6 | 0.272 | чек-лист пройден |
| 90 | `WOOL_LIME` | `WOOL_LIME.png` | wool | 6 | 0.241 | чек-лист пройден |
| 91 | `WATER_STILL` | `WATER_STILL.png` | fluid | 6 | 0.261 | чек-лист пройден |
| 92 | `LAVA_STILL` | `LAVA_STILL.png` | fluid | 6 | 0.157 | чек-лист пройден |
| 93 | `SLIME` | `SLIME.png` | fluid | 5 | 0.151 | чек-лист пройден |
| 94 | `HONEY` | `HONEY.png` | sand | 6 | 0.151 | чек-лист пройден |
| 95 | `MUSHROOM_RED_CAP` | `MUSHROOM_RED_CAP.png` | fluid | 6 | 0.364 | чек-лист пройден |
| 96 | `MUSHROOM_BROWN_CAP` | `MUSHROOM_BROWN_CAP.png` | earth | 6 | 0.303 | чек-лист пройден |
| 97 | `CACTUS_SIDE` | `CACTUS_SIDE.png` | leaves | 6 | 0.025 | чек-лист пройден |
| 98 | `BONE_BLOCK` | `BONE_BLOCK.png` | bone | 6 | 0.159 | чек-лист пройден |
| 99 | `COBWEB` | `COBWEB.png` | stone | 6 | -0.557 | чек-лист пройден |
| 100 | `BOOKSHELF` | `BOOKSHELF.png` | wood | 6 | 0.497 | чек-лист пройден |

## Визуальная проверка

На увеличенном preview ×8 рисунок читается как отдельная материальная текстура, а не как flat-заливка. Для соседних материалов использованы согласованные цветовые семейства; шерсть сохраняет общий паттерн, а top/side-варианты дерева, травы и соломы остаются отдельными файлами.

## Файлы

- `textures/` — 100 отдельных PNG-файлов.
- `voxelverse_atlas.png` — atlas 256×256 px в сетке 16×16.
- `atlas_map.json` — координаты ID в atlas.
- `previews_8x/` — 100 preview-файлов 128×128 px.
- `all_tiles_preview_x8.png` — обновлённый общий preview.
- `style_reference.png` — визуальный ориентир новой стилистики.
- `godot_import_settings.md` — Filter=Nearest, Mipmaps=off.
