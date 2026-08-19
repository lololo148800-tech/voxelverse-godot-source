extends Node

var world: Node

func _wait_frames(count: int) -> void:
    for _frame in range(count):
        await get_tree().process_frame

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    await _wait_frames(8)
    if world == null:
        print("NEW_CAPTURE_FAIL world_missing")
        get_tree().quit(1)
        return
    if world.has_method("_close_guide"):
        world._close_guide()
        world.guide_open = false
    var capture_player := world.get_node_or_null("Player")
    if capture_player != null:
        capture_player.rotation.y = 0.72
        capture_player.yaw = 0.72
        capture_player.camera.rotation.x = -0.14
    await _wait_frames(5)
    var gameplay_image := get_viewport().get_texture().get_image()
    if gameplay_image == null or gameplay_image.is_empty():
        print("NEW_CAPTURE_FAIL gameplay_empty")
        get_tree().quit(1)
        return
    gameplay_image.save_png("build/visual_preview_new_angle.png")
    print("NEW_CAPTURE_GAMEPLAY_PASS size=%dx%d file=build/visual_preview_new_angle.png" % [gameplay_image.get_width(), gameplay_image.get_height()])
    world.inventory_open = true
    world.guide_open = false
    world.settings_open = false
    world.storage_open = false
    world._update_hud()
    await _wait_frames(5)
    var inventory_image := get_viewport().get_texture().get_image()
    if inventory_image == null or inventory_image.is_empty():
        print("NEW_CAPTURE_FAIL inventory_empty")
        get_tree().quit(1)
        return
    inventory_image.save_png("build/visual_preview_inventory_new.png")
    print("NEW_CAPTURE_INVENTORY_PASS size=%dx%d file=build/visual_preview_inventory_new.png" % [inventory_image.get_width(), inventory_image.get_height()])
    get_tree().quit(0)
