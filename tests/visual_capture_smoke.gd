extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    for _frame in range(4):
        await get_tree().process_frame
    if world != null and world.has_method("_close_guide"):
        world._close_guide()
        world.guide_open = false
        world._update_hud()
    for _frame in range(2):
        await get_tree().process_frame
    var capture_player := world.get_node_or_null("Player") if world != null else null
    if capture_player != null:
        print("VISUAL_SPAWN pos=%s biome=%s" % [str(capture_player.global_position), str(world.call("_player_biome"))])
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        print("VISUAL_CAPTURE_FAIL empty_image")
        get_tree().quit(1)
        return
    image.save_png("build/visual_preview.png")
    print("VISUAL_CAPTURE_PASS size=%dx%d" % [image.get_width(), image.get_height()])
    get_tree().quit(0)
