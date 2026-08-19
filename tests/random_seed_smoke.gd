extends Node

func _ready() -> void:
    for _frame in range(3):
        await get_tree().process_frame
    var menu := get_node_or_null("MainMenu")
    if menu == null:
        print("RANDOM_SEED_FAIL menu_missing")
        get_tree().quit(1)
        return
    menu.call("_show_page", "forge")
    await get_tree().process_frame
    var first_seed := int(menu.get("generated_seed_value"))
    menu.call("_show_page", "expeditions")
    await get_tree().process_frame
    menu.call("_show_page", "forge")
    await get_tree().process_frame
    var second_seed := int(menu.get("generated_seed_value"))
    var passed := first_seed > 0 and second_seed > 0 and first_seed != second_seed
    print("RANDOM_SEED_PASS first=%d second=%d different=%s" % [first_seed, second_seed, first_seed != second_seed])
    get_tree().quit(0 if passed else 1)
