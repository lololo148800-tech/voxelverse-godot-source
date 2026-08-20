extends Node

func _ready() -> void:
    var world := get_node_or_null("VoxelWorld")
    if world == null or not is_instance_valid(world.player):
        print("VISUAL_CORRECTION_FAIL missing_world_or_player")
        get_tree().quit(1)
        return
    await get_tree().process_frame
    var overlay: Control = world.mobile_overlay
    if not is_instance_valid(overlay):
        print("VISUAL_CORRECTION_FAIL missing_mobile_overlay")
        get_tree().quit(1)
        return
    overlay.set_survival_values(10.0, 20.0, 5.0, 20.0, 8.0, 20.0, 4.0, 20.0)
    var bars_ok: bool = is_equal_approx(overlay.health_ratio, 0.5) and is_equal_approx(overlay.hunger_ratio, 0.25) and is_equal_approx(overlay.thirst_ratio, 0.4) and is_equal_approx(overlay.energy_ratio, 0.2)

    var water_cell := Vector3i(16, 8, 16)
    world._set_runtime_block(water_cell, world.WATER)
    world.player.position = Vector3(16.5, 8.1, 16.5)
    var water_state_ok: bool = world.player._is_in_water()
    world.target_cell = water_cell
    world.target_valid = true
    world.break_active = false
    world._begin_block_break()
    var water_not_breakable: bool = not world.break_active and world._get_block(water_cell) == world.WATER

    world.player.spawn_protection_timer = 0.0
    var health_before: float = world.player.health
    world.player.take_damage(3.0, "Тестовый удар")
    var damage_feedback_ok: bool = world.feedback_label.visible and str(world.feedback_label.text).contains("-3.0 HP") and world.player.health < health_before
    world.player.take_damage(999.0, "Тестовая смерть")
    var death_feedback_ok: bool = world.player.dead and world.feedback_label.visible and str(world.feedback_label.text).contains("Ты погиб")

    if not bars_ok or not water_state_ok or not water_not_breakable or not damage_feedback_ok or not death_feedback_ok:
        print("VISUAL_CORRECTION_FAIL bars=%s water_state=%s water_break=%s damage=%s death=%s" % [bars_ok, water_state_ok, water_not_breakable, damage_feedback_ok, death_feedback_ok])
        get_tree().quit(1)
        return
    print("VISUAL_CORRECTION_PASS bars=true water_buoyancy=true water_not_breakable=true damage_flash=true death_feedback=true")
    get_tree().quit(0)

