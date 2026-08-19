extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("CHUNK_DIRTY_FAIL missing_world")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    var loaded_count: int = world.loaded_chunk_keys.size()
    var mesh_count: int = world.chunk_mesh_instances.size()
    var water_mesh_count: int = world.chunk_water_mesh_instances.size()
    var collision_count: int = world.chunk_collision_bodies.size()
    if loaded_count <= 0 or mesh_count != loaded_count or water_mesh_count != loaded_count or collision_count != loaded_count:
        print("CHUNK_DIRTY_FAIL initial loaded=%d mesh=%d water=%d collision=%d" % [loaded_count, mesh_count, water_mesh_count, collision_count])
        get_tree().quit(1)
        return

    var boundary_key := Vector2i(-999, -999)
    var neighbor_key := Vector2i(-999, -999)
    for key_variant in world.loaded_chunk_keys.keys():
        var key: Vector2i = key_variant
        var candidate := Vector2i(key.x + 1, key.y)
        if world.loaded_chunk_keys.has(candidate):
            boundary_key = key
            neighbor_key = candidate
            break
        candidate = Vector2i(key.x, key.y + 1)
        if world.loaded_chunk_keys.has(candidate):
            boundary_key = key
            neighbor_key = candidate
            break
    if boundary_key.x < 0:
        print("CHUNK_DIRTY_FAIL no_adjacent_loaded_chunks")
        get_tree().quit(1)
        return

    var cell := Vector3i(boundary_key.x * world.CHUNK_SIZE + world.CHUNK_SIZE - 1, 6, boundary_key.y * world.CHUNK_SIZE + 3)
    var original: int = world._get_stored_block(cell)
    world._set_runtime_block(cell, world.STONE)
    world._rebuild_world_mesh(true)
    var boundary_rebuild_ok: bool = world.last_dirty_chunk_count >= 2 and world.dirty_chunk_rebuild_count >= loaded_count
    var neighbor_render_ok: bool = world.chunk_mesh_instances.has(neighbor_key) and world.chunk_collision_bodies.has(neighbor_key)
    world._set_runtime_block(cell, original)
    world._rebuild_world_mesh(true)
    if not boundary_rebuild_ok or not neighbor_render_ok:
        print("CHUNK_DIRTY_FAIL boundary=%s neighbor=%s dirty=%d total=%d" % [boundary_rebuild_ok, neighbor_render_ok, world.last_dirty_chunk_count, world.dirty_chunk_rebuild_count])
        get_tree().quit(1)
        return
    print("CHUNK_DIRTY_PASS loaded=%d mesh=%d dirty_boundary=%d neighbor=%s" % [loaded_count, world.chunk_mesh_instances.size(), world.last_dirty_chunk_count, str(neighbor_key)])
    get_tree().quit(0)

