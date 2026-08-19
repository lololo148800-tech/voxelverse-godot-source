extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("SURVIVAL_HOTBAR_FAIL missing_world")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    world.world_mode = "Выживание"
    world.player.set_creative_mode(false)
    world.inventory[world.GRASS] = 1
    world.inventory[world.DIRT] = 0
    world.inventory[world.STONE] = 0
    world.inventory[world.WOOD] = 0
    world.inventory[world.SAND] = 0
    world.inventory[world.SNOW] = 0
    world.inventory[world.CRYSTAL] = 0
    world.inventory[world.GLOW] = 0
    var owned: Array[int] = world.get_hotbar_items()
    if owned != [world.GRASS]:
        print("SURVIVAL_HOTBAR_FAIL owned=%s" % [owned])
        get_tree().quit(1)
        return
    world.selected_block = world.GRASS
    world.target_cell = Vector3i(20, 8, 20)
    world.target_normal = Vector3.UP
    world.target_valid = true
    world._set_runtime_block(Vector3i(20, 8, 20), world.AIR)
    world._place_target()
    var placed: bool = world._get_block(Vector3i(20, 9, 20)) == world.GRASS
    var consumed := int(world.inventory.get(world.GRASS, 0)) == 0
    if not placed or not consumed:
        print("SURVIVAL_HOTBAR_FAIL placed=%s consumed=%s" % [placed, consumed])
        get_tree().quit(1)
        return
    world.world_mode = "Творческий тест"
    world.player.set_creative_mode(true)
    world.inventory[world.DIRT] = 0
    world.selected_block = world.DIRT
    world._set_runtime_block(Vector3i(22, 8, 22), world.AIR)
    world.target_cell = Vector3i(22, 8, 22)
    world.target_normal = Vector3.UP
    world.target_valid = true
    world._place_target()
    var creative_placed: bool = world._get_block(Vector3i(22, 9, 22)) == world.DIRT
    if not creative_placed:
        print("SURVIVAL_HOTBAR_FAIL creative_placed=%s" % creative_placed)
        get_tree().quit(1)
        return
    print("SURVIVAL_HOTBAR_PASS owned_only=true consumed_on_place=true creative_unlimited=true")
    get_tree().quit(0)
