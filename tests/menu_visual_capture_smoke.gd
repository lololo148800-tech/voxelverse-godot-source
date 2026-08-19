extends Node

func _ready() -> void:
    for _frame in range(5):
        await get_tree().process_frame
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        print("MENU_VISUAL_CAPTURE_FAIL empty_image")
        get_tree().quit(1)
        return
    image.save_png("build/menu_preview.png")
    print("MENU_VISUAL_CAPTURE_PASS size=%dx%d" % [image.get_width(), image.get_height()])
    get_tree().quit(0)
