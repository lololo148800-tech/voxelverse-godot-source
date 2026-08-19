extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("TELEMETRY_SMOKE_FAIL missing_world")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    if not is_instance_valid(world.telemetry_panel) or not is_instance_valid(world.telemetry_label) or not is_instance_valid(world.telemetry_button):
        print("TELEMETRY_SMOKE_FAIL missing_nodes")
        get_tree().quit(1)
        return
    if world.telemetry_panel.visible or world.telemetry_enabled:
        print("TELEMETRY_SMOKE_FAIL initial_state")
        get_tree().quit(1)
        return
    world._toggle_telemetry()
    await get_tree().process_frame
    world._update_telemetry()
    var text: String = str(world.telemetry_label.text)
    var content_ok: bool = text.contains("FPS:") and text.contains("rebuild last/max:") and text.contains("dirty total/last:") and text.contains("loaded:")
    if not world.telemetry_enabled or not world.telemetry_panel.visible or not content_ok:
        print("TELEMETRY_SMOKE_FAIL enabled=%s visible=%s content=%s text=%s" % [world.telemetry_enabled, world.telemetry_panel.visible, content_ok, text.replace("\n", " | ")])
        get_tree().quit(1)
        return
    world._toggle_telemetry()
    if world.telemetry_enabled or world.telemetry_panel.visible:
        print("TELEMETRY_SMOKE_FAIL disable_state")
        get_tree().quit(1)
        return
    print("TELEMETRY_SMOKE_PASS toggle=true fps=true rebuild=true dirty=true loaded=true")
    get_tree().quit(0)

