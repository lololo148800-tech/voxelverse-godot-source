extends Node

func _ready() -> void:
    var world := get_node("VoxelWorld")
    for _frame in range(24):
        await get_tree().process_frame
    var player = world.player
    if player == null:
        print("REFERENCE_PHYSICS_BIOME_FAIL player_missing")
        get_tree().quit(1)
        return
    var gravity_active := absf(float(player.GRAVITY) - 18.0) < 0.01 and absf(float(player.JUMP_SPEED) - 6.5) < 0.01
    var has_controller: bool = player is CharacterBody3D and player.has_method("move_and_slide") and player.has_method("touch_jump")
    var biome_names: Array[String] = []
    for x in range(0, 64, 7):
        for z in range(0, 64, 7):
            var biome := str(world._biome_for(x, z))
            if not biome_names.has(biome):
                biome_names.append(biome)
    var ten_biomes := biome_names.size() >= 10
    var safe_spawn := str(world._player_biome()).length() > 0
    var physics_ok: bool = gravity_active and has_controller and safe_spawn
    print("REFERENCE_PHYSICS_BIOME_PASS physics=%s gravity=%.1f jump=%.1f sampled_biomes=%d biome_names=%s" % [physics_ok, player.GRAVITY, player.JUMP_SPEED, biome_names.size(), ",".join(biome_names)])
    get_tree().quit(0 if physics_ok and ten_biomes else 1)
