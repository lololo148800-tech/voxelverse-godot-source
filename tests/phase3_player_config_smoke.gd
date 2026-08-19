extends Node

var world: Node
var old_config_text := ""
var old_save_text := ""
var had_config := false
var had_save := false
const CONFIG_PATH := "user://ashen_frontier_world_config.json"
const SAVE_PATH := "user://voxelverse_slot_1.json"

func _init() -> void:
    had_config = FileAccess.file_exists(CONFIG_PATH)
    had_save = FileAccess.file_exists(SAVE_PATH)
    if had_config:
        var old_config := FileAccess.open(CONFIG_PATH, FileAccess.READ)
        old_config_text = old_config.get_as_text() if old_config != null else ""
        if old_config != null:
            old_config.close()
    if had_save:
        var old_save := FileAccess.open(SAVE_PATH, FileAccess.READ)
        old_save_text = old_save.get_as_text() if old_save != null else ""
        if old_save != null:
            old_save.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    var config := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
    if config != null:
        config.store_string(JSON.stringify({"seed":7777,"world_name":"QA Config Frontier","difficulty":"Железное правило","mode":"Выживание","hardcore":true,"anomalies":false,"autosave":false,"biome_rarity":"rich","simulation_distance":"Короткая","mob_spawns":false,"structures":false,"caves":false,"pvp":true,"day_night_speed":2.0,"backup_slots":5,"subtitles":false,"touch_layout":"Большие зоны","hud_layout":"Сжатый HUD","camera_sway":false,"avatar_profile":{"style":"Инженер","palette":"Мятный свет","mark":"Звёздный узел"}}))
        config.close()

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("PHASE3_CONFIG_SMOKE_FAIL missing_world")
        _finish(1)
        return
    var checks_ok: bool = world.world_name == "QA Config Frontier" and world.seed_value == 7777 and world.hardcore_mode and not world.anomalies_enabled and not world.autosave_enabled and world.biome_rarity_mode == "rich" and world.max_stream_chunks_runtime == 9 and not world.mob_spawn_enabled and not world.structures_enabled and not world.caves_enabled and world.pvp_enabled and is_equal_approx(world.day_night_speed, 2.0) and world.backup_slots == 5 and not world.subtitles_enabled and world.touch_layout == "Большие зоны" and world.hud_layout == "Сжатый HUD" and not world.camera_sway_enabled and world.avatar_profile["style"] == "Инженер" and world.avatar_profile["palette"] == "Мятный свет" and world.avatar_profile["mark"] == "Звёздный узел" and world.player.avatar_profile["style"] == "Инженер"
    if not checks_ok:
        print("PHASE3_CONFIG_SMOKE_FAIL fields name=%s seed=%d hardcore=%s mobs=%s structures=%s caves=%s stream=%d" % [world.world_name, world.seed_value, world.hardcore_mode, world.mob_spawn_enabled, world.structures_enabled, world.caves_enabled, world.max_stream_chunks_runtime])
        _finish(1)
        return
    if not world.mobs.is_empty() or not world.structure_loot.is_empty() or world.player == null or not world.player.hardcore:
        print("PHASE3_CONFIG_SMOKE_FAIL runtime mobs=%d loot=%d player=%s" % [world.mobs.size(), world.structure_loot.size(), world.player != null])
        _finish(1)
        return
    world._save_world()
    var saved := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var saved_data: Variant = JSON.parse_string(saved.get_as_text()) if saved != null else null
    if saved != null:
        saved.close()
    var saved_avatar: Variant = saved_data.get("avatar_profile", {}) if saved_data is Dictionary else {}
    if not saved_data is Dictionary or str(saved_data.get("world_name", "")) != "QA Config Frontier" or int(saved_data.get("backup_slots", 0)) != 5 or not bool(saved_data.get("pvp", false)) or not saved_avatar is Dictionary or str(saved_avatar.get("style", "")) != "Инженер":
        print("PHASE3_CONFIG_SMOKE_FAIL save_fields")
        _finish(1)
        return
    print("PHASE3_PLAYER_CONFIG_PASS world=%s seed=%d hardcore=true stream=%d mobs=0 structures=0 caves=0" % [world.world_name, world.seed_value, world.max_stream_chunks_runtime])
    _finish(0)

func _finish(exit_code: int) -> void:
    if is_instance_valid(world):
        var player_node: Node = world.player
        if is_instance_valid(player_node):
            player_node.free()
        var body: Node = world.world_body
        var mesh: MeshInstance3D = world.world_mesh_instance as MeshInstance3D
        if is_instance_valid(body):
            body.free()
        if is_instance_valid(mesh):
            mesh.mesh = null
            mesh.material_override = null
            mesh.free()
        world.free()
    await get_tree().physics_frame
    await get_tree().process_frame
    _restore_file(CONFIG_PATH, had_config, old_config_text)
    _restore_file(SAVE_PATH, had_save, old_save_text)
    get_tree().quit(exit_code)

func _restore_file(path: String, existed: bool, text: String) -> void:
    if existed:
        var file := FileAccess.open(path, FileAccess.WRITE)
        if file != null:
            file.store_string(text)
            file.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
