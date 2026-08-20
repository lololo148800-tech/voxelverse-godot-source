# Visual reference gap notes — 2026-08-20

## Compared files

- Current Godot capture: `build/visual_preview.png`, 1640×720.
- Reference contact sheet: `/home/ubuntu/reference_screens/contact_sheet.jpg`, 1640×7560.

## Confirmed current strengths

The current capture already has a bright outdoor forest/river composition, a centered crosshair, a bottom hotbar, heart icons at upper left, food indicators at upper right, and translucent mobile controls. The v2 atlas is visibly active in the world.

## Highest-impact visual gaps to address

1. The current camera is very close to large leaf blocks and the foreground fills too much of the frame. The references show a more readable play space with a wider, calmer field of view and a clear horizon/sky band.
2. The current world is very dark and high-contrast under the canopy. The references are brighter and flatter, with clearer green grass, readable trunks, and less crushed shadow detail.
3. The current HUD controls are oversized and heavy: the left joystick panel, right touch buttons, and hotbar occupy more visual mass than the references. Reduce opacity and scale while preserving touch hit areas.
4. The hotbar is too low-contrast and iconography is currently abstract/placeholder-like. It needs clearer square slots, stronger selection outline, and more recognizable item silhouettes using the existing original atlas/icons.
5. The river is readable, but the surface is a solid blue slab with a strong opaque edge. Match the references more closely with a lighter transparent blue, subtle wave motion, and a clean shoreline without making water breakable.
6. The terrain composition needs more layered variation visible at play height: grass, dirt path, trunks, leaf canopy, and small plants should be balanced instead of repeating dark leaf faces.
7. The top-center buttons and tiny upper-right food marks are visually inconsistent with the reference HUD. They should be simplified, aligned, and kept subordinate to gameplay.

## Safe visual pass priorities

1. Tune camera FOV/height and starting view to show more sky and playable terrain.
2. Tune environment/world lighting and color grading without changing physics.
3. Reduce HUD visual weight, improve hotbar slot/icon contrast, and keep mobile hitboxes unchanged.
4. Tune water shader tint/alpha/wave strength.
5. Add or expose a small number of clearly visible vegetation/terrain variations using existing original assets.
6. Re-run visual capture, focused tests, full regression, and only then build a new APK.

## Constraints

- Keep original VoxelVerse assets and v2 texture pack; do not copy third-party game assets.
- Do not remove HP, hunger, water physics, touch controls, audio, or survival mechanics.
- Do not claim screenshot parity until a new capture visibly verifies the changes.

## Second capture result

The new capture after camera/light/water/HUD and green palette changes shows a wider horizon, more sky, brighter grass and leaves, a lighter transparent river, and a less visually heavy hotbar/left control panel. The original gameplay systems remain visible: HP hearts, hunger marks, crosshair, touch controls, water surface, and hotbar.

The remaining stylistic gap is mainly asset/content-specific: the reference set contains more varied, open terrain and less dominant tree canopy. This pass intentionally avoids replacing original v2 textures or changing world physics. The next acceptance gate is regression and performance, followed by APK build.
