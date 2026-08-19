extends Node

func _ready() -> void:
    for _frame in range(5):
        await get_tree().process_frame
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("MOBILE_UI_PERF_FAIL world_missing")
        get_tree().quit(1)
        return
    var started_usec := Time.get_ticks_usec()
    for _call_index in range(600):
        world._update_hud()
    var elapsed_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
    var cached_overlay := world.has_method("_update_hud") and world.get("_last_overlay_signature") != null
    var passed := elapsed_ms < 5000.0 and cached_overlay
    print("MOBILE_UI_PERF_PASS calls=600 elapsed_ms=%.2f cached_overlay=%s" % [elapsed_ms, cached_overlay])
    get_tree().quit(0 if passed else 1)
