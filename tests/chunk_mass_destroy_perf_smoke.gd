extends Node

func _make_interior_cells(world: Node, key: Vector2i) -> Array[Vector3i]:
    var cells: Array[Vector3i] = []
    for local_z in range(2, 6):
        for local_x in range(2, 6):
            cells.append(Vector3i(key.x * world.CHUNK_SIZE + local_x, 6, key.y * world.CHUNK_SIZE + local_z))
    return cells

func _find_adjacent_loaded_pair(world: Node) -> Array[Vector2i]:
    for key_variant in world.loaded_chunk_keys.keys():
        var key: Vector2i = key_variant
        for candidate in [Vector2i(key.x + 1, key.y), Vector2i(key.x, key.y + 1)]:
            if world.loaded_chunk_keys.has(candidate):
                return [key, candidate]
    return []

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("CHUNK_MASS_PERF_FAIL missing_world")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    if world.loaded_chunk_keys.size() < 2:
        print("CHUNK_MASS_PERF_FAIL too_few_loaded_chunks=%d" % world.loaded_chunk_keys.size())
        get_tree().quit(1)
        return

    world._rebuild_world_mesh(true)
    world.mesh_rebuild_cooldown = 0.0
    world.dirty_chunk_keys.clear()
    world.mesh_rebuild_count = 0
    world.dirty_chunk_rebuild_count = 0

    var first_key: Vector2i = world.loaded_chunk_keys.keys()[0]
    var interior_cells: Array[Vector3i] = _make_interior_cells(world, first_key)
    var start_single_usec: int = Time.get_ticks_usec()
    for cell in interior_cells:
        world._set_runtime_block(cell, world.AIR)
    var pending_single: int = world.dirty_chunk_keys.size()
    world.mesh_rebuild_cooldown = 0.0
    var single_before_rebuilds: int = world.mesh_rebuild_count
    world._rebuild_world_mesh()
    var single_elapsed_ms: float = float(Time.get_ticks_usec() - start_single_usec) / 1000.0
    var single_rebuild_delta: int = world.mesh_rebuild_count - single_before_rebuilds
    var single_dirty_chunks: int = world.last_dirty_chunk_count
    var single_dirty_delta: int = world.dirty_chunk_rebuild_count
    if pending_single != 1 or single_rebuild_delta != 1 or single_dirty_chunks != 1 or single_dirty_delta != 1:
        print("CHUNK_MASS_PERF_FAIL single pending=%d rebuild_delta=%d dirty_chunks=%d dirty_delta=%d" % [pending_single, single_rebuild_delta, single_dirty_chunks, single_dirty_delta])
        get_tree().quit(1)
        return

    var pair: Array[Vector2i] = _find_adjacent_loaded_pair(world)
    if pair.size() != 2:
        print("CHUNK_MASS_PERF_FAIL no_adjacent_pair")
        get_tree().quit(1)
        return
    var left_key: Vector2i = pair[0]
    var right_key: Vector2i = pair[1]
    var boundary_a := Vector3i(left_key.x * world.CHUNK_SIZE + world.CHUNK_SIZE - 1, 6, left_key.y * world.CHUNK_SIZE + 3)
    var boundary_b: Vector3i
    if right_key.x != left_key.x:
        boundary_b = Vector3i(right_key.x * world.CHUNK_SIZE, 6, right_key.y * world.CHUNK_SIZE + 3)
    else:
        boundary_b = Vector3i(right_key.x * world.CHUNK_SIZE + 3, 6, right_key.y * world.CHUNK_SIZE)
    world.dirty_chunk_keys.clear()
    world.mesh_rebuild_cooldown = 0.0
    var start_boundary_usec: int = Time.get_ticks_usec()
    world._set_runtime_block(boundary_a, world.STONE)
    world._set_runtime_block(boundary_b, world.STONE)
    world._set_runtime_block(boundary_a, world.AIR)
    world._set_runtime_block(boundary_b, world.AIR)
    var pending_boundary: int = world.dirty_chunk_keys.size()
    world.mesh_rebuild_cooldown = 0.0
    var boundary_before_rebuilds: int = world.mesh_rebuild_count
    world._rebuild_world_mesh()
    var boundary_elapsed_ms: float = float(Time.get_ticks_usec() - start_boundary_usec) / 1000.0
    var boundary_rebuild_delta: int = world.mesh_rebuild_count - boundary_before_rebuilds
    var boundary_dirty_chunks: int = world.last_dirty_chunk_count
    var boundary_dirty_delta: int = world.dirty_chunk_rebuild_count - single_dirty_delta
    if pending_boundary < 2 or boundary_rebuild_delta != 1 or boundary_dirty_chunks < 2 or boundary_dirty_delta < 2:
        print("CHUNK_MASS_PERF_FAIL boundary pending=%d rebuild_delta=%d dirty_chunks=%d dirty_delta=%d" % [pending_boundary, boundary_rebuild_delta, boundary_dirty_chunks, boundary_dirty_delta])
        get_tree().quit(1)
        return

    print("CHUNK_MASS_PERF_PASS single_cells=%d single_pending=%d single_dirty=%d single_rebuilds=%d single_ms=%.3f boundary_pending=%d boundary_dirty=%d boundary_rebuilds=%d boundary_ms=%.3f total_dirty=%d" % [interior_cells.size(), pending_single, single_dirty_chunks, single_rebuild_delta, single_elapsed_ms, pending_boundary, boundary_dirty_chunks, boundary_rebuild_delta, boundary_elapsed_ms, world.dirty_chunk_rebuild_count])
    get_tree().quit(0)

