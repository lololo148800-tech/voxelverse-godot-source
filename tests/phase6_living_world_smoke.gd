extends Node

const SAVE_PATH := "user://voxelverse_slot_1.json"
var world: Node
var had_save := false
var old_save_text := ""

func _ready() -> void:
    had_save = FileAccess.file_exists(SAVE_PATH)
    if had_save:
        var old_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if old_file != null:
            old_save_text = old_file.get_as_text()
            old_file.close()
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("PHASE6_SMOKE_FAIL missing_world")
        _finish(1)
        return
    if world.npc_definitions.size() < 3 or world.quest_definitions.size() < 6 or world.horror_definitions.size() < 3 or world.boss_arena_definitions.size() < 2:
        print("PHASE6_SMOKE_FAIL definitions npc=%d quests=%d horror=%d arenas=%d" % [world.npc_definitions.size(), world.quest_definitions.size(), world.horror_definitions.size(), world.boss_arena_definitions.size()])
        _finish(1)
        return
    var first_npc := world.npcs[0] as VoxelNpc if not world.npcs.is_empty() else null
    if first_npc == null or first_npc.get_shop_inventory().is_empty() or first_npc.schedule.is_empty():
        print("PHASE6_SMOKE_FAIL npc_runtime")
        _finish(1)
        return

    world.player.set_creative_mode(false)
    world.player.dead = false
    world.player.spawn_protection_timer = 0.0
    world.player.position = first_npc.global_position
    world.inventory[world.FIBER] = 2
    world.inventory[world.FOOD] = 0
    world._interact_nearby_npc()
    var dialogue_ok: bool = world.npc_talks > 0 and int(world.npc_talk_counts.get(first_npc.definition_id, 0)) > 0
    world._trade_nearby_npc()
    var trade_ok: bool = int(world.inventory.get(world.FIBER, 0)) == 0 and int(world.inventory.get(world.FOOD, 0)) == 1 and int(world.npc_reputation.get(first_npc.definition_id, 0)) >= 2
    if not dialogue_ok or not trade_ok:
        print("PHASE6_SMOKE_FAIL npc dialogue=%s trade=%s talks=%d fiber=%d food=%d" % [dialogue_ok, trade_ok, world.npc_talks, int(world.inventory.get(world.FIBER, 0)), int(world.inventory.get(world.FOOD, 0))])
        _finish(1)
        return

    world.quest_completed["first_breakthrough"] = false
    world.quest_progress["first_breakthrough"] = 0
    world.blocks_broken = 3
    world.inventory[world.FIBER] = 0
    world._update_data_quests()
    var quest_ok: bool = bool(world.quest_completed.get("first_breakthrough", false)) and bool(world.quest_flags.get("route_started", false)) and int(world.inventory.get(world.FIBER, 0)) == 2
    if not quest_ok:
        print("PHASE6_SMOKE_FAIL quest completed=%s flags=%s fiber=%d" % [world.quest_completed.get("first_breakthrough", false), world.quest_flags.get("route_started", false), int(world.inventory.get(world.FIBER, 0))])
        _finish(1)
        return

    var echo_cell := _find_biome("Пустошь Эха")
    if echo_cell == Vector3i(-1, -1, -1):
        print("PHASE6_SMOKE_FAIL echo_biome_missing")
        _finish(1)
        return
    world.player.position = Vector3(echo_cell) + Vector3(0.5, 1.0, 0.5)
    world.horror_last_biome = "previous_biome"
    world.horror_last_dimension = world.dimension_mode
    world.horror_last_weather = world.weather_state
    world._update_horror_encounters(0.1)
    var horror_ok: bool = world.player.fear_level > 0.0 and float(world.active_horror_cooldowns.get("echo_threshold", 0.0)) > 0.0
    if not horror_ok:
        print("PHASE6_SMOKE_FAIL horror fear=%.1f cooldown=%.1f" % [world.player.fear_level, float(world.active_horror_cooldowns.get("echo_threshold", 0.0))])
        _finish(1)
        return

    var arena_ok := false
    if is_instance_valid(world.boss):
        world.boss_arena_phase = 0
        world.boss.health = world.boss.max_health * 0.5
        world._update_boss_arena()
        arena_ok = world.boss_arena_phase >= 1
    if not arena_ok:
        print("PHASE6_SMOKE_FAIL arena phase=%d" % world.boss_arena_phase)
        _finish(1)
        return

    world._save_world()
    var saved_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var saved_variant: Variant = JSON.parse_string(saved_file.get_as_text()) if saved_file != null else null
    if saved_file != null:
        saved_file.close()
    var persistence_ok: bool = saved_variant is Dictionary and saved_variant.has("quest_completed") and saved_variant.has("npc_reputation") and saved_variant.has("active_horror_cooldowns") and saved_variant.has("boss_arena_phase")
    if not persistence_ok:
        print("PHASE6_SMOKE_FAIL persistence")
        _finish(1)
        return

    print("PHASE6_LIVING_WORLD_PASS npc=3+ dialogue=true trade=true quests=6 persistence=true horror=true arena_phase=%d" % world.boss_arena_phase)
    _finish(0)

func _find_biome(target_name: String) -> Vector3i:
    for x in range(world.WORLD_SIZE_X):
        for z in range(world.WORLD_SIZE_Z):
            if world._biome_for(x, z) == target_name:
                var y: int = int(world._highest_solid_y(x, z)) + 1
                return Vector3i(x, clampi(y, 1, world.WORLD_SIZE_Y - 2), z)
    return Vector3i(-1, -1, -1)

func _finish(exit_code: int) -> void:
    if had_save:
        var restore_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if restore_file != null:
            restore_file.store_string(old_save_text)
            restore_file.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    await get_tree().physics_frame
    await get_tree().process_frame
    get_tree().quit(exit_code)
