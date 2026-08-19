extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("WATER_INPUT_PERF_FAIL missing_world")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    var required_actions := ["move_left", "move_right", "move_forward", "move_back", "jump"]
    for action_name in required_actions:
        if not InputMap.has_action(action_name) or InputMap.action_get_events(action_name).is_empty():
            print("WATER_INPUT_PERF_FAIL missing_action=%s" % action_name)
            get_tree().quit(1)
            return
    var water_rules_ok: bool = not world._should_draw_face(world.WATER, world.WATER) and world._should_draw_face(world.WATER, world.AIR) and world._should_draw_face(world.STONE, world.WATER)
    if not water_rules_ok:
        print("WATER_INPUT_PERF_FAIL water_face_rules")
        get_tree().quit(1)
        return
    world._rebuild_world_mesh(true)
    if world.last_mesh_rebuild_cells <= 0 or world.last_mesh_rebuild_ms < 0.0 or world.max_mesh_rebuild_ms < world.last_mesh_rebuild_ms:
        print("WATER_INPUT_PERF_FAIL rebuild_metrics cells=%d last_ms=%.3f max_ms=%.3f" % [world.last_mesh_rebuild_cells, world.last_mesh_rebuild_ms, world.max_mesh_rebuild_ms])
        get_tree().quit(1)
        return
    print("WATER_INPUT_PERF_PASS actions=%d water_internal_faces_culled=true cells=%d last_ms=%.3f" % [required_actions.size(), world.last_mesh_rebuild_cells, world.last_mesh_rebuild_ms])
    get_tree().quit(0)

