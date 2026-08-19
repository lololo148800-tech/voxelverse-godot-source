extends Node

func _wait_frames(count: int) -> void:
    for _frame in range(count):
        await get_tree().process_frame

func _capture(menu: Node, page: String, path: String, tag: String) -> bool:
    menu.call("_show_page", page)
    await _wait_frames(3)
    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        print("NEW_MENU_CAPTURE_FAIL %s empty_image" % tag)
        return false
    image.save_png(path)
    print("NEW_MENU_CAPTURE_PASS %s size=%dx%d file=%s" % [tag, image.get_width(), image.get_height(), path])
    return true

func _ready() -> void:
    await _wait_frames(5)
    var menu := get_node_or_null("MainMenu")
    if menu == null:
        print("NEW_MENU_CAPTURE_FAIL menu_missing")
        get_tree().quit(1)
        return
    var home_ok := await _capture(menu, "home", "build/home_reference_new.png", "home")
    var main_ok := await _capture(menu, "expeditions", "build/menu_reference_new.png", "main")
    var forge_ok := await _capture(menu, "forge", "build/world_creation_reference_new.png", "forge")
    var wardrobe_ok := await _capture(menu, "loadout", "build/wardrobe_reference_new.png", "wardrobe")
    var online_ok := await _capture(menu, "online", "build/online_voice_reference_new.png", "online_voice")
    var generated_seed := int(menu.get("generated_seed_value"))
    var seed_ok := generated_seed > 0
    print("NEW_MENU_CAPTURE_SUMMARY home=%s main=%s forge=%s wardrobe=%s online=%s generated_seed=%d seed_ok=%s" % [home_ok, main_ok, forge_ok, wardrobe_ok, online_ok, generated_seed, seed_ok])
    get_tree().quit(0 if home_ok and main_ok and forge_ok and wardrobe_ok and online_ok and seed_ok else 1)
