extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    for _frame in range(8):
        await get_tree().process_frame
    if world == null:
        print("MOBILE_WORLD_CAPTURE_FAIL world_missing")
        get_tree().quit(1)
        return
    if world.has_method("_close_guide"):
        world._close_guide()
        world.guide_open = false
        world._update_hud()
    var player := world.get_node_or_null("Player")
    if player == null or player.camera == null:
        print("MOBILE_WORLD_CAPTURE_FAIL player_or_camera_missing")
        get_tree().quit(1)
        return
    var variants := [
        [0.0, "a"],
        [1.05, "b"],
        [2.10, "c"],
        [-1.05, "d"]
    ]
    var accepted_image = null
    for variant in variants:
        player.rotation.y = float(variant[0])
        player.camera.rotation.x = -0.18
        player.camera.current = true
        for _frame in range(5):
            await get_tree().process_frame
        var image := get_viewport().get_texture().get_image()
        if image == null or image.is_empty():
            print("MOBILE_WORLD_CAPTURE_FAIL empty_image variant=%s" % variant[1])
            get_tree().quit(1)
            return
        image.save_png("build/mobile_world_candidate_%s.png" % variant[1])
        if variant[1] == "b":
            accepted_image = image
        print("MOBILE_WORLD_CANDIDATE_PASS variant=%s size=%dx%d" % [variant[1], image.get_width(), image.get_height()])
    # Candidate B is the accepted deterministic forest/river framing for the reference capture.
    var final_image = accepted_image if accepted_image != null else get_viewport().get_texture().get_image()
    final_image.save_png("build/mobile_world_reference_new.png")
    print("MOBILE_WORLD_CAPTURE_PASS size=%dx%d candidates=4" % [final_image.get_width(), final_image.get_height()])
    get_tree().quit(0)
