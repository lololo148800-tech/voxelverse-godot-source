extends Node

func _ready() -> void:
    await get_tree().process_frame
    var world := get_node_or_null("VoxelWorld")
    if world == null:
        print("WHISPER_VALLEY_FAIL world_missing")
        get_tree().quit(1)
        return
    var found := false
    var pursuit := ""
    var cooldown := 0.0
    for entry_variant in world.horror_definitions:
        var entry: Dictionary = entry_variant
        if str(entry.get("id", "")) == "whisper_valley_presence":
            found = true
            pursuit = str(entry.get("pursuit_kind", ""))
            cooldown = float(entry.get("cooldown", 0.0))
            break
    var safe := found and pursuit == "WhisperEntity" and cooldown > 0.0
    print("WHISPER_VALLEY_PASS enabled=%s pursuit=%s cooldown=%.1f" % [safe, pursuit, cooldown])
    get_tree().quit(0 if safe else 1)
