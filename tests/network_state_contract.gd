extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("NETWORK_STATE_FAIL missing_world")
        get_tree().quit(1)
        return
    var state: Dictionary = world._network_build_player_state()
    var world_state: Dictionary = world._network_build_world_state()
    var entity_state: Array = world._network_build_entity_snapshot()
    for required_key in ["position", "health", "hunger", "thirst", "energy", "inventory"]:
        if not state.has(required_key):
            print("NETWORK_STATE_FAIL missing_player_key=%s" % required_key)
            get_tree().quit(1)
            return
    for required_key in ["weather_state", "world_time", "dimension_mode", "astral_oxygen", "astral_radiation"]:
        if not world_state.has(required_key):
            print("NETWORK_STATE_FAIL missing_world_key=%s" % required_key)
            get_tree().quit(1)
            return
    if entity_state.is_empty():
        print("NETWORK_STATE_FAIL no_entities")
        get_tree().quit(1)
        return
    var target := _find_air_cell()
    if target == Vector3i(-1, -1, -1):
        print("NETWORK_STATE_FAIL no_air_cell")
        get_tree().quit(1)
        return
    var peer_inventory: Dictionary = {world.FURNITURE_CRATE: 1}
    var accepted: bool = world._network_apply_block_edit(target, world.FURNITURE_CRATE, world.AIR, 2, world.FURNITURE_CRATE, peer_inventory)
    var rejected_duplicate: bool = not world._network_apply_block_edit(target, world.FURNITURE_CRATE, world.AIR, 2, world.FURNITURE_CRATE, peer_inventory)
    if not accepted or not rejected_duplicate or world._get_stored_block(target) != world.FURNITURE_CRATE:
        print("NETWORK_STATE_FAIL transaction accepted=%s rejected_duplicate=%s target=%s new=%d source=%d expected=%d actual=%d source_count=%d" % [accepted, rejected_duplicate, target, world.FURNITURE_CRATE, world.FURNITURE_CRATE, world.AIR, world._get_stored_block(target), int(peer_inventory.get(world.FURNITURE_CRATE, 0))])
        get_tree().quit(1)
        return
    print("NETWORK_STATE_PASS entities=%d edit_cell=%s weather=%s" % [entity_state.size(), target, world_state["weather_state"]])
    get_tree().quit(0)

func _find_air_cell() -> Vector3i:
    for x in range(world.WORLD_SIZE_X):
        for y in range(1, world.WORLD_SIZE_Y - 1):
            for z in range(world.WORLD_SIZE_Z):
                var cell := Vector3i(x, y, z)
                if world._get_stored_block(cell) == world.AIR:
                    return cell
    return Vector3i(-1, -1, -1)
