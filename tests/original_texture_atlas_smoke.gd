extends Node

func _ready() -> void:
    var atlas := load("res://assets/textures/voxelverse_texture_pack_v2/voxelverse_atlas.png") as Texture2D
    var atlas_ok: bool = is_instance_valid(atlas) and atlas.get_width() == 256 and atlas.get_height() == 256
    var source_count := 0
    var source_dir := DirAccess.open("res://assets/textures/voxelverse_texture_pack_v2/textures")
    if source_dir != null:
        source_dir.list_dir_begin()
        while true:
            var entry := source_dir.get_next()
            if entry.is_empty():
                break
            if not source_dir.current_is_dir() and entry.to_lower().ends_with(".png"):
                source_count += 1
        source_dir.list_dir_end()
    var source_ok: bool = source_count == 100
    var world := get_node_or_null("VoxelWorld")
    var mapping_ok := false
    if world != null:
        mapping_ok = true
        for block_id in [1, 2, 3, 4, 5, 7, 8, 10, 17, 26, 35, 50, 51, 56, 105]:
            var tile: Vector2i = world._texture_tile_for_block(block_id, 0)
            if tile.x < 0 or tile.x >= 16 or tile.y < 0 or tile.y >= 16:
                mapping_ok = false
                break
    if not atlas_ok or not source_ok or not mapping_ok:
        print("ORIGINAL_TEXTURE_ATLAS_FAIL atlas=%s sources=%d mapping=%s" % [atlas_ok, source_count, mapping_ok])
        get_tree().quit(1)
        return
    print("ORIGINAL_TEXTURE_ATLAS_PASS atlas=256x256 v2_tiles=100 mapping_bounds=true")
    get_tree().quit(0)

