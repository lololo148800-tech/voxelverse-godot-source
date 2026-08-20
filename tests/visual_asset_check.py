from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "assets/textures/voxelverse_texture_pack_v2/voxelverse_atlas.png"
WORLD = ROOT / "core/voxel_world.gd"
SURFACE_SHADER = ROOT / "shaders/surface_sky.gdshader"

if not ATLAS.is_file():
    raise SystemExit("VISUAL_ASSET_FAIL missing_atlas")
with Image.open(ATLAS) as image:
    if image.size != (256, 256) or image.mode not in {"RGB", "RGBA"}:
        raise SystemExit(f"VISUAL_ASSET_FAIL atlas={image.size}/{image.mode}")
world_text = WORLD.read_text(encoding="utf-8")
for required in ["VOXEL_ATLAS_PATH", "Mesh.ARRAY_TEX_UV", "_texture_tile_for_block", "surface_sky", "ScrollContainer", "_create_compact_hud", "compact_hp_bar", "compact_mana_bar", "compact_selection_label.visible = false", "compact_hotbar_label.visible = false", "compact_mana_label.visible = false", "hud_backdrop.visible = false", "status_label.visible = false", "MobileOverlayScript", "MobileVoxelControls", "_author_starter_clearing", "_try_echo_copy"]:
    if required not in world_text:
        raise SystemExit(f"VISUAL_ASSET_FAIL missing_hook={required}")
if 'content.text = "' not in world_text:
    raise SystemExit("VISUAL_ASSET_FAIL missing_guide")
player_text = (ROOT / "core/voxel_player.gd").read_text(encoding="utf-8")
if "action_surface" not in player_text or "touch_jump" not in player_text:
    raise SystemExit("VISUAL_ASSET_FAIL mobile_actions")
if not (ROOT / "core/mobile_overlay.gd").is_file():
    raise SystemExit("VISUAL_ASSET_FAIL missing_mobile_overlay")
source_dir = ROOT / "assets/textures/voxelverse_texture_pack_v2/textures"
source_count = len(list(source_dir.glob("*.png"))) if source_dir.is_dir() else 0
if source_count != 100:
    raise SystemExit(f"VISUAL_ASSET_FAIL v2_textures={source_count}")
if not (ROOT / "assets/textures/voxelverse_texture_pack_v2/atlas_map.json").is_file():
    raise SystemExit("VISUAL_ASSET_FAIL missing_v2_atlas_map")
if SURFACE_SHADER.read_text(encoding="utf-8").count("shader_type sky;") != 1:
    raise SystemExit("VISUAL_ASSET_FAIL surface_shader")
print("VISUAL_ASSET_PASS atlas=256x256 v2_tiles=100 uv_mapping=true surface_sky=true guide_scroll=true compact_hud=true textless_gameplay_hud=true mobile_overlay=true mobile_actions=true starter_clearing=true echo_copy=true legacy_text_wall_hidden=true")
