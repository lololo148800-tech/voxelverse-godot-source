# VoxelVerse texture import settings for Godot 4.3

Apply these settings to `textures/*.png` and `voxelverse_atlas.png` in the Godot FileSystem dock:

| Setting | Value |
|---|---|
| Import > Compress > Mode | Lossless or disabled for pixel-art source textures |
| Import > Process > Size Limit | 0 |
| Import > Process > Fix Alpha Border | Off unless a particular transparent asset needs it |
| Import > Mipmaps > Generate | Off |
| Import > Filter > Use Nearest Mipmap Filter | Off |
| Canvas Items > Texture > Filter | Nearest |
| Canvas Items > Texture > Repeat | Enabled only when using a repeating tile material |

For project-wide defaults, set the project texture filter to **Nearest** in **Project Settings → Rendering → Textures → Default Filters → Use Nearest Mipmap Filter** and set the default texture filter to Nearest. For the atlas, use the coordinates in `atlas_map.json`; each tile is exactly 16×16 pixels in a 16×16-cell, 256×256 PNG.

No `voxel_world.gd` or `BlockType` enum was present in the supplied workspace, so the filenames use the uppercase IDs exactly as provided in the task specification. If the project enum uses lowercase names, rename the files or add a mapping layer rather than changing atlas coordinates.
