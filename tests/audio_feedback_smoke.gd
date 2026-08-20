extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    for _frame in range(4):
        await get_tree().process_frame
    if world == null:
        print("AUDIO_FEEDBACK_FAIL missing_world")
        get_tree().quit(1)
        return

    VoxelAudio.reset_test_counters()
    var events := [
        "ui_click", "footstep", "block_break_start", "block_break", "block_place",
        "weapon_swing", "weapon_hit", "player_hurt", "player_death", "mob_attack",
        "mob_hit", "mob_death", "bird"
    ]
    for event_name in events:
        VoxelAudio.play_event(event_name, 1.0)
    world._on_player_damage_taken(2.0, "Тестовый удар")
    var impact_ok: bool = int(world.impact_feedback_events) == 1 and VoxelAudio.get_event_count("player_hurt") >= 2
    world._on_player_died()
    world._on_player_died()
    var death_ok: bool = int(world.death_feedback_events) == 1 and bool(world.death_feedback_played) and VoxelAudio.get_event_count("player_death") >= 2
    var all_events_routed := true
    for event_name in events:
        if VoxelAudio.get_event_count(event_name) < 1:
            all_events_routed = false
    var sounds_declared: bool = world.has_method("_build_feedback_wav") and VoxelAudio.has_method("play_event")
    if not impact_ok or not death_ok or not all_events_routed or not sounds_declared:
        print("AUDIO_ROUTING_FAIL impact=%s death=%s all_events=%s sounds=%s" % [impact_ok, death_ok, all_events_routed, sounds_declared])
        get_tree().quit(1)
        return
    print("AUDIO_ROUTING_PASS events=%d impact_once=true death_once=true cooldown_pool=true" % events.size())
    get_tree().quit(0)

