extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    for _frame in range(5):
        await get_tree().process_frame
    if world == null:
        print("INVENTORY_VISUAL_CAPTURE_FAIL missing_world")
        get_tree().quit(1)
        return
    world._close_guide()
    world.guide_open = false
    world.inventory_open = true
    world._update_hud()
    for _frame in range(3):
        await get_tree().process_frame
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        print("INVENTORY_VISUAL_CAPTURE_FAIL empty_image")
        get_tree().quit(1)
        return
    image.save_png("build/inventory_visual_preview.png")
    print("INVENTORY_VISUAL_CAPTURE_PASS size=%dx%d" % [image.get_width(), image.get_height()])
    get_tree().quit(0)
