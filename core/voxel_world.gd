class_name VoxelWorld
extends Node3D

const VoxelPlayerScript = preload("res://core/voxel_player.gd")
const VoxelMobScript = preload("res://core/voxel_mob.gd")
const VoxelPickupScript = preload("res://core/voxel_pickup.gd")
const VoxelBossScript = preload("res://core/voxel_boss.gd")
const VoxelNpcScript = preload("res://core/voxel_npc.gd")
const VoxelProjectileScript = preload("res://core/voxel_projectile.gd")
const AstralSkyShader = preload("res://shaders/astral_sky.gdshader")
const MobileOverlayScript: GDScript = preload("res://core/mobile_overlay.gd")
const SurfaceSkyShader = preload("res://shaders/surface_sky.gdshader")
const WaterSurfaceShader = preload("res://shaders/water_surface.gdshader")
const RECIPE_DATA_PATH := "res://data/recipes.json"
const SPELL_DATA_PATH := "res://data/spells.json"
const BIOME_DATA_PATH := "res://data/biomes.json"
const MOB_DATA_PATH := "res://data/mobs.json"
const STRUCTURE_DATA_PATH := "res://data/structures.json"
const NPC_DATA_PATH := "res://data/npcs.json"
const QUEST_DATA_PATH := "res://data/quests.json"
const HORROR_DATA_PATH := "res://data/horror_encounters.json"
const BOSS_ARENA_DATA_PATH := "res://data/boss_arenas.json"
const VOXEL_ATLAS_PATH := "res://assets/textures/voxel_atlas.png"

const WORLD_SIZE_X: int = 64
const WORLD_SIZE_Y: int = 16
const WORLD_SIZE_Z: int = 64
const CHUNK_SIZE: int = 8
const MAX_STREAM_CHUNKS: int = 25
const MAX_REACH: float = 6.0

const AIR: int = 0
const GRASS: int = 1
const DIRT: int = 2
const STONE: int = 3
const WOOD: int = 4
const LEAVES: int = 5
const GLOW: int = 6
const SAND: int = 7
const SNOW: int = 8
const CRYSTAL: int = 9
const ASH: int = 10
const FOOD: int = 11
const ARMOR: int = 12
const FIBER: int = 13
const ECHO_SHARD: int = 14
const SALT_CRYSTAL: int = 15
const ECHO_LANTERN: int = 16
const MOSS: int = 17
const SALT_CRUST: int = 18
const EMBER: int = 19
const CHEST: int = 20
const STOVE: int = 21
const COOKED_FOOD: int = 22
const BOLT: int = 23
const TRAP: int = 24
const DEEP_CRYSTAL: int = 25
const IRON_ORE: int = 26
const GOLD_ORE: int = 27
const DIAMOND_ORE: int = 28
const COPPER_ORE: int = 29
const COAL_ORE: int = 30
const PLANKS: int = 31
const STICK: int = 32
const WORKBENCH: int = 33
const FURNACE: int = 34
const COSMIC_STONE: int = 35
const STAR_DUST: int = 36
const ASTRAL_CRYSTAL: int = 37
const ASTRAL_SCRAP: int = 38
const WHISPER_SOIL: int = 39
const WHISPER_BARK: int = 40
const WHISPER_SHARD: int = 41
const ASTRAL_METAL: int = 42
const COSMIC_ICE: int = 43
const VOID_SHARD: int = 44
const ANTIMATTER: int = 45
const NEBULA_GAS: int = 46
const FURNITURE_CRATE: int = 47
const FURNITURE_TABLE: int = 48
const FURNITURE_LAMP: int = 49
const WATER: int = 50
const ASH_FLUID: int = 51
const ARCANE_CRYSTAL: int = 52
const ARCANE_CONDUIT: int = 53
const AUTOMATION_FORGE: int = 54
const CARGO_RAIL: int = 55
const ORE_BLOCK_BASE: int = 56
const ORE_BLOCK_COUNT: int = 50
const ORE_RAW_BASE: int = 256
const ORE_INGOT_BASE: int = 306
const MAX_BLOCK_ID: int = ORE_BLOCK_BASE + ORE_BLOCK_COUNT - 1
const MAX_CONTENT_ID: int = ORE_INGOT_BASE + ORE_BLOCK_COUNT - 1

const TAG_LOGS := "logs"
const TAG_ORES := "ores"
const TAG_FOOD := "food"
const TAG_TOOLS := "tools"

const BIOME_MEADOW := "Лазурные луга"
const BIOME_DUNES := "Стеклянные барханы"
const BIOME_FROST := "Инейные уступы"
const BIOME_RIFT := "Кристальный разлом"
const BIOME_ECHO := "Пустошь Эха"
const BIOME_FEN := "Мшистая заводь"
const BIOME_SALT := "Зеркальные солончаки"
const BIOME_EMBER := "Эмберовый уступ"
const BIOME_ASTRAL := "Астральный Простор"
const BIOME_WHISPER := "Долина Шёпота"

var blocks: Dictionary = {}
var birch_bark_cells: Dictionary = {}
var structure_loot: Dictionary = {}
var claimed_structure_loot: Dictionary = {}
var chunk_storage: Dictionary = {}
var loaded_chunk_keys: Dictionary = {}
var dirty_chunk_keys: Dictionary = {}
var stream_center: Vector2i = Vector2i(-999, -999)
var stream_tick: float = 0.0
var hud_tick: float = 0.0
var max_stream_chunks_runtime: int = MAX_STREAM_CHUNKS
var mesh_rebuild_cooldown: float = 0.0
var mesh_rebuild_deferred: bool = false
var mesh_rebuild_count: int = 0
var fluid_tick: float = 0.0
var fluid_depth: Dictionary = {}
var automation_tick: float = 0.0
var automation_jobs: Dictionary = {}
var transport_tick: float = 0.0
var transport_path: Array[Vector3i] = []
var transport_progress: float = 0.0
var transport_direction: int = 1
var transport_delivery_count: int = 0
var spell_definitions: Dictionary = {}
var active_spell_effects: Dictionary = {}
var external_biome_definitions: Dictionary = {}
var external_mob_definitions: Dictionary = {}
var npc_definitions: Dictionary = {}
var quest_definitions: Array[Dictionary] = []
var horror_definitions: Array[Dictionary] = []
var boss_arena_definitions: Dictionary = {}
var ore_definitions: Dictionary = {}
var ore_raw_definitions: Dictionary = {}
var ore_ingot_definitions: Dictionary = {}
var structure_definitions: Array[Dictionary] = []
var materials: Dictionary = {}
var voxel_atlas_texture: Texture2D
var player: VoxelPlayer
var mobs: Array[Node3D] = []
var pickups: Array[Node3D] = []
var projectiles: Array[Node3D] = []
var traps: Array[Vector3i] = []
var combat_rng := RandomNumberGenerator.new()
var combat_cooldown: float = 0.0
var boss: VoxelBoss
var boss_defeated: bool = false
var npcs: Array[Node3D] = []
var npc_talks: int = 0
var npc_talk_counts: Dictionary = {}
var npc_reputation: Dictionary = {}
var quest_progress: Dictionary = {}
var quest_completed: Dictionary = {}
var quest_flags: Dictionary = {}
var mob_defeat_counts: Dictionary = {}
var boss_defeat_counts: Dictionary = {}
var active_horror_cooldowns: Dictionary = {}
var horror_last_biome: String = ""
var horror_last_dimension: String = ""
var horror_last_weather: String = ""
var boss_arena_phase: int = 0
var boss_last_phase_health: float = 1.0
var arena_reward_granted: bool = false
var outpost_origin := Vector3i(46, 0, 38)
var dungeon_origin := Vector3i(50, 0, 50)
var mob_simulation_radius: float = 26.0
var world_mesh_instance: Node3D
var water_mesh_instance: MeshInstance3D
var world_body: Node3D
var chunk_mesh_root: Node3D
var chunk_water_mesh_root: Node3D
var chunk_collision_root: Node3D
var chunk_mesh_instances: Dictionary = {}
var chunk_water_mesh_instances: Dictionary = {}
var chunk_collision_bodies: Dictionary = {}
var chunk_world_material: StandardMaterial3D
var chunk_water_material: ShaderMaterial
var dirty_chunk_rebuild_count: int = 0
var last_dirty_chunk_count: int = 0
var last_mesh_rebuild_ms: float = 0.0
var max_mesh_rebuild_ms: float = 0.0
var last_mesh_rebuild_cells: int = 0
var starter_grass_visual_a: MultiMeshInstance3D
var starter_grass_visual_b: MultiMeshInstance3D
var target_cell: Vector3i = Vector3i.ZERO
var target_normal: Vector3 = Vector3.UP
var target_valid: bool = false
var break_active: bool = false
var break_progress: float = 0.0
var break_cell: Vector3i = Vector3i.ZERO
var break_block_type: int = AIR
var break_progress_bar: ProgressBar
var selected_block: int = DIRT
var hotbar: Array[int] = [GRASS, DIRT, STONE, WOOD, SAND, SNOW, CRYSTAL, GLOW]
var inventory: Dictionary = {GRASS: 32, DIRT: 64, STONE: 24, WOOD: 12, LEAVES: 8, GLOW: 4, SAND: 32, SNOW: 24, CRYSTAL: 8, ASH: 16, FOOD: 6, ARMOR: 0, FIBER: 0, ECHO_SHARD: 0, SALT_CRYSTAL: 0, ECHO_LANTERN: 0, MOSS: 0, SALT_CRUST: 0, EMBER: 0, CHEST: 0, STOVE: 0, COOKED_FOOD: 0, BOLT: 8, TRAP: 0, DEEP_CRYSTAL: 0, COSMIC_STONE: 0, STAR_DUST: 0, ASTRAL_CRYSTAL: 0, ASTRAL_SCRAP: 0, WHISPER_SOIL: 0, WHISPER_BARK: 0, WHISPER_SHARD: 0, ASTRAL_METAL: 0, COSMIC_ICE: 0, VOID_SHARD: 0, ANTIMATTER: 0, NEBULA_GAS: 0, FURNITURE_CRATE: 0, FURNITURE_TABLE: 0, FURNITURE_LAMP: 0, WATER: 0, ASH_FLUID: 0, ARCANE_CRYSTAL: 0, ARCANE_CONDUIT: 0, AUTOMATION_FORGE: 0, CARGO_RAIL: 0}
var inventory_open: bool = false
var inventory_revision: int = 0
var _last_inventory_signature: String = ""
var _last_storage_signature: String = ""
var _last_overlay_signature: String = ""
var storage_open: bool = false
var storage_panel: Panel
var storage_title: Label
var storage_slots: Array[Button] = []
var storage_item_ids: Array[int] = []
var storage_inventory: Dictionary = {}
var active_chest: Vector3i = Vector3i.ZERO
var blocks_broken: int = 0
var mobs_defeated: int = 0
var quest_stage: int = 0
var achievements: Dictionary = {
	"first_block": false,
	"first_mob": false,
	"first_craft": false,
	"deep_miner": false,
	"boss_slayer": false
}
var status_label: Label
var command_input: LineEdit
var target_label: Label
var hotbar_label: Label
var crosshair_label: Label
var inventory_label: Label
var inventory_search: LineEdit
var inventory_category_select: OptionButton
var inventory_panel: Panel
var inventory_title: Label
var inventory_grid: GridContainer
var inventory_icon_atlas: Texture2D
var inventory_slots: Array[Button] = []
var inventory_item_ids: Array[int] = []
var armor_button: Button
var guide_panel: Panel
var settings_panel: Panel
var guide_open: bool = false
var settings_open: bool = false
var biome_label: Label
var quest_label: Label
var rules_label: Label
var health_label: Label
var hunger_label: Label
var death_label: Label
var thirst_label: Label
var energy_label: Label
var boss_label: Label
var weather_label: Label
var npc_label: Label
var dimension_label: Label
var storage_hint_label: Label
var ranged_hint_label: Label
var compact_panel: Panel
var telemetry_button: Button
var telemetry_panel: Panel
var telemetry_label: Label
var telemetry_enabled: bool = false
var telemetry_update_timer: float = 0.0
var telemetry_frame_accum: float = 0.0
var telemetry_frame_samples: int = 0
var mobile_overlay: Control
var compact_hp_bar: ProgressBar
var compact_hunger_bar: ProgressBar
var compact_thirst_bar: ProgressBar
var compact_energy_bar: ProgressBar
var compact_mana_bar: ProgressBar
var compact_selection_label: Label
var compact_mana_label: Label
var compact_hotbar_label: Label
var world_environment: WorldEnvironment
var astral_sky: Sky
var surface_sky: Sky
var sun_light: DirectionalLight3D
var renderer_profile: String = "Сбалансированный"
var shaders_enabled: bool = true
var world_distance_profile: String = "Средняя"
var network_online: bool = false
var network_world_state_received: bool = false
var world_time: float = 0.25
var day_night_enabled: bool = true
var dimension_mode: String = "surface"
var astral_oxygen: float = 100.0
var astral_radiation: float = 0.0
var astral_hazard_timer: float = 0.0
var weather_state: String = "clear"
var weather_timer: float = 35.0
var weather_hazard_timer: float = 0.0
var echo_active: bool = false
var echo_time: float = 0.0
var echo_copy_timer: float = 0.0
var echo_copy_count: int = 0
var echo_whisper_timer: float = 6.0
var seed_value: int = 2048
var terrain_continent_noise: FastNoiseLite
var terrain_ridge_noise: FastNoiseLite
var biome_warp_noise: FastNoiseLite
var world_name: String = "Пепельный Рубеж"
var world_mode: String = "Выживание"
var anomalies_enabled: bool = true
var autosave_enabled: bool = true
var biome_rarity_mode: String = "standard"
var mob_spawn_enabled: bool = true
var structures_enabled: bool = true
var caves_enabled: bool = true
var pvp_enabled: bool = false
var day_night_speed: float = 1.0
var backup_slots: int = 2
var subtitles_enabled: bool = true
var touch_layout: String = "Карманный экран"
var hud_layout: String = "Полный HUD"
var camera_sway_enabled: bool = true
var avatar_profile: Dictionary = {"style": "Разведчик", "palette": "Пепельная медь", "mark": "Сигил Рубежа"}
var generated_message: String = ""
var difficulty_mode: String = "standard"
var hardcore_mode: bool = false
var pending_player_state: Dictionary = {}
var equipped_tool: int = 0
var tool_durability: Array[int] = [96, 64]
var tool_max_durability: Array[int] = [96, 64]
var tool_names: Array[String] = ["Каменная кирка", "Соляной резак"]
var armor_owned: int = 0

var recipes: Array[Dictionary] = [
	{"output": WORKBENCH, "count": 1, "input": {WOOD: 4}},
	{"output": PLANKS, "count": 4, "input": {WOOD: 1}},
	{"output": STICK, "count": 4, "input": {PLANKS: 2}},
	{"output": GLOW, "count": 1, "input": {STONE: 2, WOOD: 1}},
	{"output": STOVE, "count": 1, "input": {STONE: 8}},
	{"output": CHEST, "count": 1, "input": {PLANKS: 8}},
	{"output": COOKED_FOOD, "count": 1, "input": {FOOD: 1}, "station": STOVE},
	{"output": ARMOR, "count": 1, "input": {SALT_CRYSTAL: 4, IRON_ORE: 2}, "station": WORKBENCH},
	{"output": BOLT, "count": 4, "input": {IRON_ORE: 1, STICK: 1}, "station": WORKBENCH},
	{"output": TRAP, "count": 1, "input": {STONE: 4, IRON_ORE: 1}, "station": WORKBENCH},
	{"output": ECHO_LANTERN, "count": 1, "input": {ECHO_SHARD: 2, GLOW: 1}, "station": WORKBENCH},
	{"output": DEEP_CRYSTAL, "count": 1, "input": {CRYSTAL: 4, ECHO_SHARD: 1}, "station": STOVE}
]

func _ready() -> void:
    _load_world_config()
    _load_renderer_settings()
    _load_ore_definitions()
    _load_recipe_definitions()
    _append_ore_recipes()
    _load_spell_definitions()
    _load_biome_definitions()
    _load_mob_definitions()
    _load_npc_definitions()
    _load_quest_definitions()
    _load_horror_definitions()
    _load_boss_arena_definitions()
    _load_structure_definitions()
    _setup_environment()
    voxel_atlas_texture = load(VOXEL_ATLAS_PATH) as Texture2D
    _generate_world()
    _load_world()
    _prepare_chunk_storage_from_blocks()
    if storage_inventory.is_empty():
        _init_storage_inventory()
    guide_open = not FileAccess.file_exists("user://voxelverse_guide_seen.flag")
    _setup_player()
    _place_player_at_safe_spawn()
    _stream_world_around_player(true)
    _setup_starter_grass_visuals()
    NetworkAuthority.bind_world(self)
    network_online = NetworkSession.is_online()
    _spawn_mobs()
    _spawn_boss()
    _spawn_npcs()
    _setup_hud()
    generated_message = "Мир создан: %dx%dx%d блоков" % [WORLD_SIZE_X, WORLD_SIZE_Y, WORLD_SIZE_Z]
    _update_hud()

func _place_player_at_safe_spawn() -> void:
    if not is_instance_valid(player):
        return
    var best_position := Vector3(16.5, 8.05, 28.5)
    var found := false
    var spawn_x_order: Array[int] = [16, 20, 24, 12, 28, 8, 32, 4, 36, 40, 44, 48, 52, 56]
    var spawn_z_order: Array[int] = [28, 30, 26, 24, 22, 20, 18, 16, 14, 12, 10, 8, 32, 34, 36, 40, 44, 48, 52, 56]
    for x in spawn_x_order:
        for z in spawn_z_order:
            for y in range(WORLD_SIZE_Y - 3, 1, -1):
                var ground := _get_stored_block(Vector3i(x, y, z))
                if ground == AIR or ground == WATER or ground == ASH_FLUID:
                    continue
                if _get_stored_block(Vector3i(x, y + 1, z)) != AIR or _get_stored_block(Vector3i(x, y + 2, z)) != AIR:
                    continue
                var clear := true
                for ox in range(-1, 2):
                    for oz in range(-1, 2):
                        if _get_stored_block(Vector3i(x + ox, y + 1, z + oz)) != AIR:
                            clear = false
                var inside_playable_core := x >= WORLD_SIZE_X / 4 and x <= (WORLD_SIZE_X * 3) / 4 and z >= WORLD_SIZE_Z / 4 and z <= (WORLD_SIZE_Z * 3) / 4
                var safe_biome := _is_starter_meadow_cell(x, z) or _is_safe_start_biome(_biome_for(x, z))
                if clear and inside_playable_core and safe_biome and ground in [GRASS, SAND, SNOW, MOSS, ASH, DIRT]:
                    best_position = Vector3(x + 0.5, y + 1.05, z + 0.5)
                    found = true
                    break
            if found:
                break
        if found:
            break
    player.position = best_position
    player.respawn_position = best_position

func _is_safe_start_biome(biome: String) -> bool:
    if biome == BIOME_MEADOW:
        return true
    if not external_biome_definitions.has(biome):
        return false
    var definition: Dictionary = external_biome_definitions[biome]
    var hazard := str(definition.get("hazard", "none"))
    var surface_block := int(definition.get("surface_block", GRASS))
    return hazard == "none" and surface_block in [GRASS, WOOD, PLANKS]

func _process(delta: float) -> void:
    mesh_rebuild_cooldown = maxf(0.0, mesh_rebuild_cooldown - delta)
    if mesh_rebuild_deferred and mesh_rebuild_cooldown <= 0.0:
        mesh_rebuild_deferred = false
        _rebuild_world_mesh(true)
    _update_target()
    combat_cooldown = maxf(0.0, combat_cooldown - delta)
    _update_block_break(delta)
    stream_tick += delta
    if stream_tick >= 0.5:
        stream_tick = 0.0
        _stream_world_around_player()

    _update_day_night(delta)
    _update_echo_biome(delta)
    _update_special_biomes(delta)
    _update_weather(delta)
    _update_horror_encounters(delta)
    _cleanup_mobs()
    _cleanup_pickups()
    _cleanup_projectiles()
    _update_fluid_simulation(delta)
    _update_automation(delta)
    _update_transport(delta)
    _update_spell_effects(delta)
    _update_traps()
    _update_mob_activation()
    _update_quests()
    _update_boss_arena()
    hud_tick += delta
    if hud_tick >= 0.1:
        hud_tick = 0.0
        _update_hud()
    if telemetry_enabled:
        telemetry_update_timer += delta
        telemetry_frame_accum += delta
        telemetry_frame_samples += 1
        if telemetry_update_timer >= 0.25:
            telemetry_update_timer = 0.0
            _update_telemetry()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _begin_block_break()
            else:
                _end_block_break()
        elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
            _place_target()
    elif event is InputEventKey and not event.pressed and event.keycode == KEY_Q:
        _end_block_break()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode >= KEY_1 and event.keycode <= KEY_8:
            var available_hotbar := get_hotbar_items()
            var slot_index: int = event.keycode - KEY_1
            if slot_index < available_hotbar.size():
                selected_block = available_hotbar[slot_index]
        elif event.keycode == KEY_Q:
            _begin_block_break()
        elif event.keycode == KEY_X:
            _attack_nearby_mob()
        elif event.keycode == KEY_V:
            _fire_ranged_tool()
        elif event.keycode == KEY_T:
            _interact_nearby_npc()
        elif event.keycode == KEY_Y:
            _trade_nearby_npc()
        elif event.keycode == KEY_R:
            _place_target()
        elif event.keycode == KEY_I:
            inventory_open = not inventory_open
            guide_open = false
            settings_open = false
            storage_open = false
        elif event.keycode == KEY_O:
            _toggle_storage_nearby()
        elif event.keycode == KEY_G:
            _toggle_guide()
        elif event.keycode == KEY_J:
            _toggle_settings()
        elif event.keycode == KEY_SLASH:
            _toggle_command_bar()
        elif event.keycode == KEY_C:
            _craft_recipe(3) # GLOW
        elif event.keycode == KEY_B:
            _craft_recipe(7) # ARMOR
        elif event.keycode == KEY_M:
            _craft_recipe(8) # BOLT
        elif event.keycode == KEY_P:
            _craft_recipe(5) # CHEST
        elif event.keycode == KEY_A:
            _craft_recipe(9) # TRAP
        elif event.keycode == KEY_U:
            _craft_recipe(2) # STICK
        elif event.keycode == KEY_Z:
            _craft_recipe(4) # STOVE
        elif event.keycode == KEY_N:
            _toggle_armor()
        elif event.keycode == KEY_E:
            _eat_food()
        elif event.keycode == KEY_F:
            _cycle_difficulty()
        elif event.keycode == KEY_H:
            _toggle_hardcore()
        elif event.keycode == KEY_K:
            _toggle_day_night()
        elif event.keycode == KEY_L:
            _cycle_weather()
        elif event.keycode == KEY_Y:
            _toggle_dimension()
        elif event.keycode == KEY_ENTER and is_instance_valid(player) and player.dead:
            _respawn_player()
        elif event.keycode == KEY_F4:
            _cast_spell("ember_lance")
        elif event.keycode == KEY_F5:
            _save_world()
        elif event.keycode == KEY_F9:
            _load_world()
            _rebuild_world_mesh()
        elif event.keycode == KEY_F10:
            _toggle_telemetry()

func get_hotbar_items() -> Array[int]:
    if world_mode == "Творческий тест" or not is_instance_valid(player) or player.creative_mode:
        return hotbar.duplicate()
    var owned: Array[int] = []
    for item_id in hotbar:
        if int(inventory.get(item_id, 0)) > 0:
            owned.append(item_id)
    return owned

func _setup_environment() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.background_color = Color("87ceeb")
    surface_sky = Sky.new()
    var surface_material := ShaderMaterial.new()
    surface_material.shader = SurfaceSkyShader
    surface_sky.sky_material = surface_material
    environment.sky = surface_sky
    astral_sky = Sky.new()
    var astral_material := ShaderMaterial.new()
    astral_material.shader = AstralSkyShader
    astral_sky.sky_material = astral_material
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("e4f1d8")
    environment.ambient_light_energy = 1.52
    environment.fog_enabled = false
    environment.fog_light_color = Color("c8e6c9")
    environment.fog_light_energy = 0.38
    environment.fog_density = 0.003
    environment.fog_sky_affect = 0.14
    environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    world_environment = WorldEnvironment.new()
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
    sun.light_color = Color("fff9e5")
    sun.light_energy = 1.65
    sun.shadow_enabled = true
    sun_light = sun
    add_child(sun)
    _apply_renderer_profile()

func _apply_renderer_profile() -> void:
    if world_environment == null or sun_light == null:
        return
    var environment := world_environment.environment
    var applied_profile := renderer_profile
    if applied_profile == "Авто качество":
        applied_profile = "Слабый маяк" if OS.has_feature("mobile") else "Сбалансированный"
    match world_distance_profile:
        "Короткая": mob_simulation_radius = 16.0
        "Дальняя": mob_simulation_radius = 34.0
        "Экспедиционная": mob_simulation_radius = 44.0
        _ : mob_simulation_radius = 26.0
    match applied_profile:
        "Слабый маяк":
            environment.fog_density = 0.0045
            environment.fog_sky_affect = 0.12
            environment.ambient_light_energy = 1.02
            sun_light.shadow_enabled = false
        "Дальний обзор":
            environment.fog_density = 0.0028
            environment.fog_sky_affect = 0.16
            environment.ambient_light_energy = 1.10
            sun_light.shadow_enabled = true
            sun_light.shadow_bias = 0.06
        "Кинематографичный":
            environment.fog_density = 0.0022
            environment.fog_sky_affect = 0.18
            environment.ambient_light_energy = 1.00
            sun_light.shadow_enabled = true
            sun_light.shadow_bias = 0.04
        _:
            environment.fog_density = 0.0035
            environment.fog_sky_affect = 0.15
            environment.ambient_light_energy = 1.06
            sun_light.shadow_enabled = true
            sun_light.shadow_bias = 0.05

func _chunk_key_for_cell(cell: Vector3i) -> Vector2i:
    return Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.z) / CHUNK_SIZE))

func _chunk_key_in_bounds(key: Vector2i) -> bool:
    return key.x >= 0 and key.y >= 0 and key.x < ceili(float(WORLD_SIZE_X) / CHUNK_SIZE) and key.y < ceili(float(WORLD_SIZE_Z) / CHUNK_SIZE)

func _chunk_radius() -> int:
    if OS.has_feature("mobile"):
        return 1
    match world_distance_profile:
        "Короткая": return 1
        "Дальняя": return 2
        "Экспедиционная": return 2
    return 1

func _ensure_chunk(key: Vector2i) -> Dictionary:
    if not chunk_storage.has(key):
        chunk_storage[key] = {}
    return chunk_storage[key]

func _prepare_chunk_storage_from_blocks() -> void:
    loaded_chunk_keys.clear()
    dirty_chunk_keys.clear()
    chunk_mesh_instances.clear()
    chunk_water_mesh_instances.clear()
    chunk_collision_bodies.clear()
    if not chunk_storage.is_empty():
        blocks.clear()
        stream_center = Vector2i(-999, -999)
        return
    chunk_storage.clear()
    for cell_variant in blocks.keys():
        var cell: Vector3i = cell_variant
        var block_type := int(blocks[cell])
        if block_type == AIR:
            continue
        var key := _chunk_key_for_cell(cell)
        var chunk := _ensure_chunk(key)
        chunk[cell] = block_type
    stream_center = Vector2i(-999, -999)

func _get_stored_block(cell: Vector3i) -> int:
    if not _inside_world(cell):
        return AIR
    if blocks.has(cell):
        return int(blocks[cell])
    var chunk_key := _chunk_key_for_cell(cell)
    var chunk: Dictionary = chunk_storage.get(chunk_key, {})
    return int(chunk.get(cell, AIR))

func _mark_chunk_dirty(key: Vector2i) -> void:
    if _chunk_key_in_bounds(key) and loaded_chunk_keys.has(key):
        dirty_chunk_keys[key] = true

func _mark_cell_chunk_and_neighbors_dirty(cell: Vector3i) -> void:
    var chunk_key := _chunk_key_for_cell(cell)
    _mark_chunk_dirty(chunk_key)
    for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK, Vector3i.UP, Vector3i.DOWN]:
        _mark_chunk_dirty(_chunk_key_for_cell(cell + offset))

func _set_runtime_block(cell: Vector3i, block_type: int) -> void:
    if not _inside_world(cell):
        return
    var chunk_key := _chunk_key_for_cell(cell)
    var chunk := _ensure_chunk(chunk_key)
    if block_type == AIR:
        chunk.erase(cell)
        blocks.erase(cell)
    else:
        chunk[cell] = block_type
        if loaded_chunk_keys.has(chunk_key):
            blocks[cell] = block_type
    _mark_cell_chunk_and_neighbors_dirty(cell)
    if block_type == WATER or block_type == ASH_FLUID:
        if not fluid_depth.has(cell):
            fluid_depth[cell] = 0
    else:
        fluid_depth.erase(cell)

func _update_fluid_simulation(delta: float) -> void:
    fluid_tick += delta
    if fluid_tick < 0.4:
        return
    fluid_tick = 0.0
    var frontier: Array[Vector3i] = []
    for cell_variant in blocks.keys():
        if frontier.size() >= 48:
            break
        var cell: Vector3i = cell_variant
        var block_type := _get_stored_block(cell)
        if block_type == WATER or block_type == ASH_FLUID:
            frontier.append(cell)
    var changed := false
    var budget := 64
    for cell in frontier:
        if budget <= 0:
            break
        var block_type := _get_stored_block(cell)
        var depth := int(fluid_depth.get(cell, 0))
        if depth >= 4:
            continue
        var down := cell + Vector3i.DOWN
        if _get_stored_block(down) == AIR:
            _set_fluid_cell(down, block_type, depth + 1)
            budget -= 1
            changed = true
            continue
        for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
            if budget <= 0:
                break
            var side: Vector3i = cell + offset
            if _get_stored_block(side) == AIR:
                _set_fluid_cell(side, block_type, depth + 1)
                budget -= 1
                changed = true
    if changed:
        _rebuild_world_mesh()

func _set_fluid_cell(cell: Vector3i, block_type: int, depth: int) -> void:
    if not _inside_world(cell) or _get_stored_block(cell) != AIR:
        return
    fluid_depth[cell] = clampi(depth, 0, 4)
    _set_runtime_block(cell, block_type)

func _update_automation(delta: float) -> void:
    automation_tick += delta
    if automation_tick < 0.5:
        return
    automation_tick = 0.0
    var forge_count := 0
    for cell_variant in blocks.keys():
        if forge_count >= 16:
            break
        var cell: Vector3i = cell_variant
        if _get_stored_block(cell) != AUTOMATION_FORGE:
            continue
        forge_count += 1
        if not automation_jobs.has(cell) and _consume_forge_inputs():
            automation_jobs[cell] = 2.5
            generated_message = "Автоматическая кузница начала цикл"
    var completed_jobs: Array[Vector3i] = []
    for job_key_variant in automation_jobs.keys():
        var job_cell: Vector3i = job_key_variant
        var remaining := float(automation_jobs[job_cell]) - 0.5
        if remaining > 0.0:
            automation_jobs[job_cell] = remaining
        else:
            completed_jobs.append(job_cell)
    for job_cell in completed_jobs:
        automation_jobs.erase(job_cell)
        inventory[ARCANE_CRYSTAL] = int(inventory.get(ARCANE_CRYSTAL, 0)) + 1
        generated_message = "Кузница завершила цикл: +1 арканный кристалл"
    _refresh_inventory_panel()

func _consume_forge_inputs() -> bool:
    var deep_count := int(inventory.get(DEEP_CRYSTAL, 0))
    var dust_count := int(inventory.get(STAR_DUST, 0))
    if deep_count <= 0 or dust_count <= 0:
        return false
    inventory[DEEP_CRYSTAL] = deep_count - 1
    inventory[STAR_DUST] = dust_count - 1
    return true

func _update_transport(delta: float) -> void:
    transport_tick += delta
    if transport_path.is_empty():
        transport_path = _find_rail_path()
        transport_progress = 0.0
        transport_direction = 1
    if transport_path.size() < 2 or transport_tick < 0.25:
        return
    transport_tick = 0.0
    transport_progress += float(transport_direction) * delta * 0.9
    var last_index := transport_path.size() - 1
    if transport_progress >= float(last_index):
        transport_progress = float(last_index)
        transport_direction = -1
        _transport_deliver(transport_path[last_index])
    elif transport_progress <= 0.0:
        transport_progress = 0.0
        transport_direction = 1
        _transport_deliver(transport_path[0])

func _find_rail_path() -> Array[Vector3i]:
    var start := Vector3i(-1, -1, -1)
    for cell_variant in blocks.keys():
        var cell: Vector3i = cell_variant
        if _get_stored_block(cell) == CARGO_RAIL:
            start = cell
            break
    if start.x < 0:
        return []
    var queue: Array[Vector3i] = [start]
    var parent: Dictionary = {start: start}
    var cursor := 0
    while cursor < queue.size() and queue.size() < 64:
        var current := queue[cursor]
        cursor += 1
        for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
            var next: Vector3i = current + offset
            if _get_stored_block(next) == CARGO_RAIL and not parent.has(next):
                parent[next] = current
                queue.append(next)
    var endpoint := queue[queue.size() - 1]
    if endpoint == start:
        return []
    var path: Array[Vector3i] = []
    var current := endpoint
    while true:
        path.push_front(current)
        if current == start:
            break
        current = parent[current]
    return path

func _transport_deliver(endpoint: Vector3i) -> void:
    var has_chest := false
    for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK, Vector3i.UP, Vector3i.DOWN]:
        if _get_stored_block(endpoint + offset) == CHEST:
            has_chest = true
            break
    if not has_chest:
        return
    for item_id in [ASTRAL_METAL, ASTRAL_SCRAP, STAR_DUST, ARCANE_CRYSTAL]:
        var amount := int(inventory.get(item_id, 0))
        if amount <= 0:
            continue
        inventory[item_id] = amount - 1
        storage_inventory[item_id] = int(storage_inventory.get(item_id, 0)) + 1
        transport_delivery_count += 1
        generated_message = "Грузовой вагон доставил %s в сундук" % _name_for_block(item_id)
        return

func _update_spell_effects(delta: float) -> void:
    for effect_variant in active_spell_effects.keys():
        var effect_name := str(effect_variant)
        var remaining := float(active_spell_effects[effect_variant]) - delta
        if remaining <= 0.0:
            active_spell_effects.erase(effect_name)
        else:
            active_spell_effects[effect_name] = remaining

func _cast_spell(spell_id: String = "ember_lance") -> bool:
    if not is_instance_valid(player):
        return false
    var definition: Dictionary = spell_definitions.get(spell_id, {})
    if definition.is_empty():
        generated_message = "Заклинание не найдено в data/spells.json"
        return false
    var cost := float(definition.get("mana_cost", 0.0))
    var cooldown := float(definition.get("cooldown", 0.0))
    var effect := str(definition.get("effect", ""))
    var power := float(definition.get("power", 1.0))
    var reagent_id := int(definition.get("reagent_id", -1))
    var reagent_count := maxi(0, int(definition.get("reagent_count", 0)))
    if not _consume_spell_reagent(reagent_id, reagent_count):
        generated_message = "Не хватает реагента для школы %s" % str(definition.get("school", "unknown"))
        return false
    if effect == "damage_nearest":
        var target := _nearest_spell_target()
        if target == null:
            _refund_spell_reagent(reagent_id, reagent_count)
            generated_message = "Нет цели в радиусе заклинания"
            return false
        if not player.spend_mana(cost, cooldown):
            _refund_spell_reagent(reagent_id, reagent_count)
            generated_message = "Недостаточно маны или заклинание ещё перезаряжается"
            return false
        target.take_damage(power)
        active_spell_effects[spell_id] = float(definition.get("status_duration", 0.0))
        generated_message = "Сотворено: %s" % str(definition.get("name", spell_id))
        return true
    if not player.spend_mana(cost, cooldown):
        _refund_spell_reagent(reagent_id, reagent_count)
        generated_message = "Недостаточно маны или заклинание ещё перезаряжается"
        return false
    if effect == "heal_and_focus":
        player.heal(power)
        active_spell_effects[spell_id] = float(definition.get("status_duration", 0.0))
        generated_message = "Сотворено: %s · восстановление" % str(definition.get("name", spell_id))
        return true
    if effect == "grant_barrier":
        player.grant_barrier(power)
        active_spell_effects[spell_id] = float(definition.get("status_duration", 0.0))
        generated_message = "Сотворено: %s · защитный барьер" % str(definition.get("name", spell_id))
        return true
    if effect == "blink_forward":
        var destination := Vector3i(floori(player.position.x + player.get_view_direction().x * 3.0), floori(player.position.y), floori(player.position.z + player.get_view_direction().z * 3.0))
        if _inside_world(destination) and _get_stored_block(destination) == AIR and _get_stored_block(destination + Vector3i.DOWN) != AIR:
            player.position = Vector3(destination) + Vector3(0.5, 0.1, 0.5)
            generated_message = "Сотворено: %s" % str(definition.get("name", spell_id))
            return true
        player.restore_mana(cost)
        player.spell_cooldown = 0.0
        _refund_spell_reagent(reagent_id, reagent_count)
        generated_message = "Прыжок не удался: впереди нет безопасной точки"
        return false
    _refund_spell_reagent(reagent_id, reagent_count)
    return false

func _consume_spell_reagent(reagent_id: int, reagent_count: int) -> bool:
    if reagent_count <= 0 or (is_instance_valid(player) and player.creative_mode):
        return true
    if reagent_id < 0:
        return false
    var source_count := int(inventory.get(reagent_id, 0))
    if source_count < reagent_count:
        return false
    inventory[reagent_id] = source_count - reagent_count
    _refresh_inventory_panel()
    return true

func _refund_spell_reagent(reagent_id: int, reagent_count: int) -> void:
    if reagent_id >= 0 and reagent_count > 0 and not (is_instance_valid(player) and player.creative_mode):
        inventory[reagent_id] = int(inventory.get(reagent_id, 0)) + reagent_count
        _refresh_inventory_panel()

func _nearest_spell_target() -> VoxelMob:
    var nearest: VoxelMob
    var nearest_distance := 10.0
    for mob_variant in mobs:
        var mob := mob_variant as VoxelMob
        if not is_instance_valid(mob):
            continue
        var distance := player.global_position.distance_to(mob.global_position)
        if distance <= nearest_distance:
            nearest_distance = distance
            nearest = mob
    return nearest

func _stream_world_around_player(force: bool = false) -> void:
    if not is_instance_valid(player):
        return
    var center := Vector2i(clampi(floori(player.position.x) / CHUNK_SIZE, 0, ceili(float(WORLD_SIZE_X) / CHUNK_SIZE) - 1), clampi(floori(player.position.z) / CHUNK_SIZE, 0, ceili(float(WORLD_SIZE_Z) / CHUNK_SIZE) - 1))
    if not force and center == stream_center:
        return
    stream_center = center
    var radius := _chunk_radius()
    var desired: Dictionary = {}
    for cx in range(center.x - radius, center.x + radius + 1):
        for cz in range(center.y - radius, center.y + radius + 1):
            var key := Vector2i(cx, cz)
            if _chunk_key_in_bounds(key) and desired.size() < max_stream_chunks_runtime:
                desired[key] = true
    for loaded_key_variant in loaded_chunk_keys.keys():
        var loaded_key: Vector2i = loaded_key_variant
        if not desired.has(loaded_key):
            var loaded_chunk: Dictionary = chunk_storage.get(loaded_key, {})
            for cell_variant in loaded_chunk.keys():
                blocks.erase(cell_variant)
            _remove_chunk_render(loaded_key)
            dirty_chunk_keys.erase(loaded_key)
            loaded_chunk_keys.erase(loaded_key)
    for desired_key_variant in desired.keys():
        var desired_key: Vector2i = desired_key_variant
        if loaded_chunk_keys.has(desired_key):
            continue
        var desired_chunk: Dictionary = chunk_storage.get(desired_key, {})
        for cell_variant in desired_chunk.keys():
            blocks[cell_variant] = int(desired_chunk[cell_variant])
        loaded_chunk_keys[desired_key] = true
        dirty_chunk_keys[desired_key] = true
    for loaded_key_variant in loaded_chunk_keys.keys():
        dirty_chunk_keys[loaded_key_variant] = true
    _rebuild_world_mesh()
    generated_message = "Чанки: %d загружено / %d сохранено" % [loaded_chunk_keys.size(), chunk_storage.size()]

func _generate_world() -> void:
    blocks.clear()
    birch_bark_cells.clear()
    structure_loot.clear()
    claimed_structure_loot.clear()
    var noise := FastNoiseLite.new()
    noise.seed = seed_value
    noise.frequency = 0.05
    var detail_noise := FastNoiseLite.new()
    detail_noise.seed = seed_value * 31 + 97
    detail_noise.frequency = 0.13
    terrain_continent_noise = FastNoiseLite.new()
    terrain_continent_noise.seed = seed_value * 17 + 701
    terrain_continent_noise.frequency = 0.022
    terrain_ridge_noise = FastNoiseLite.new()
    terrain_ridge_noise.seed = seed_value * 29 + 1409
    terrain_ridge_noise.frequency = 0.075
    biome_warp_noise = FastNoiseLite.new()
    biome_warp_noise.seed = seed_value * 43 + 2081
    biome_warp_noise.frequency = 0.038
    for x in range(WORLD_SIZE_X):
        for z in range(WORLD_SIZE_Z):
            var biome := BIOME_MEADOW if _is_starter_meadow_cell(x, z) else _biome_for(x, z)
            var n_val := noise.get_noise_2d(x, z)
            var detail_val := detail_noise.get_noise_2d(x, z)
            var continent_val := terrain_continent_noise.get_noise_2d(x, z)
            var ridge_val := terrain_ridge_noise.get_noise_2d(x, z)
            var ridge_strength := 1.0 - absf(ridge_val)
            var biome_lift := _terrain_lift_for_biome(biome)
            if biome == BIOME_DUNES: biome_lift = 2
            elif biome == BIOME_EMBER: biome_lift = 3
            var river_center := 20.0 + sin(float(x) * 0.22 + float(seed_value % 37)) * 2.4
            var river_distance := absf(float(z) - river_center)
            var river_channel := biome == BIOME_MEADOW and x >= 8 and x <= WORLD_SIZE_X - 9 and river_distance < 1.65
            var height := clampi(5 + int(n_val * 4.0) + int(detail_val * 2.0) + int(continent_val * 3.0) + int(ridge_strength * 3.0) + biome_lift, 2, WORLD_SIZE_Y - 4)
            if continent_val > 0.58 and ridge_strength > 0.62:
                height = mini(WORLD_SIZE_Y - 4, height + 1)
            elif continent_val < -0.58 and ridge_strength < 0.20:
                height = maxi(3, height - 1)
            if river_channel:
                height = maxi(3, height - 2)
            for y in range(height + 1):
                var block_type := STONE
                if y == height:
                    block_type = _astral_surface_block(x, z) if biome == BIOME_ASTRAL else _surface_block_for_biome(biome)
                elif y >= height - 2:
                    block_type = _astral_subsurface_block(x, z) if biome == BIOME_ASTRAL else _subsurface_block_for_biome(biome)
                elif y < height - 3:
                    var ore_noise := (x * 13 + y * 7 + z * 17 + seed_value) % 100
                    if biome == BIOME_ASTRAL:
                        if ore_noise < 5: block_type = ASTRAL_METAL
                        elif ore_noise < 8: block_type = COSMIC_ICE
                        elif ore_noise < 10: block_type = VOID_SHARD
                        elif y < 4 and ore_noise < 11: block_type = ASTRAL_CRYSTAL
                        elif y < 2 and ore_noise < 12: block_type = ANTIMATTER
                    else:
                        var generated_ore := _ore_block_for_cell(x, y, z, biome)
                        if generated_ore > AIR:
                            block_type = generated_ore
                        elif ore_noise < 5: block_type = COAL_ORE
                        elif ore_noise < 8: block_type = IRON_ORE
                        elif ore_noise < 10: block_type = COPPER_ORE
                        elif y < 4 and ore_noise < 11: block_type = GOLD_ORE
                        elif y < 2 and ore_noise < 12: block_type = DIAMOND_ORE
                if river_channel and y == height:
                    block_type = WATER
                elif y == height and biome == BIOME_FEN and (x * 7 + z * 13 + seed_value) % 9 == 0:
                    block_type = WATER
                elif y == height and biome == BIOME_EMBER and (x * 11 + z * 5 + seed_value) % 13 == 0:
                    block_type = ASH_FLUID
                blocks[Vector3i(x, y, z)] = block_type

            var base := Vector3i(x, height + 1, z)
            if biome == BIOME_MEADOW and not river_channel and height < WORLD_SIZE_Y - 5:
                var grove_roll := absi((x * 17 + z * 31 + seed_value) % 43)
                var in_starter_clearing := _is_starter_meadow_cell(x, z)
                if grove_roll < (2 if in_starter_clearing else 4):
                    _add_tree(base)
                elif grove_roll == 7 or (x + z + seed_value) % 29 == 0:
                    _add_tree_variant(base)
                elif grove_roll == 12 or (x * 5 + z * 7 + seed_value) % 37 == 0:
                    _add_shrub(base)
            elif biome == BIOME_DUNES and (x * 7 + z * 11) % 19 == 0:
                _add_cactus(base)
            elif biome == BIOME_FROST and (x * 5 + z * 3) % 17 == 0:
                _add_frost_spires(base)
            elif biome == BIOME_RIFT and (x * 13 + z * 17) % 13 == 0:
                _add_crystal_cluster(base)
            elif biome == BIOME_FEN and (x * 5 + z * 7) % 11 == 0:
                _add_moss_pillar(base)
            elif biome == BIOME_SALT and (x * 3 + z * 5) % 9 == 0:
                _add_salt_marker(base)
            elif biome == BIOME_EMBER and (x * 7 + z * 13) % 12 == 0:
                _add_ember_vent(base)
            elif biome == BIOME_ASTRAL and (x * 11 + z * 5) % 9 == 0:
                _add_astral_marker(base)
            elif biome == BIOME_ASTRAL and (x * 17 + z * 23 + seed_value) % 17 == 0:
                _add_astral_wreck(base)
            elif biome == BIOME_WHISPER and (x * 13 + z * 7) % 10 == 0:
                _add_whisper_grove(base)

            if (x * 17 + z * 31 + seed_value) % 47 == 0:
                var glow_y := mini(height + 1, WORLD_SIZE_Y - 1)
                blocks[Vector3i(x, glow_y, z)] = GLOW
    _author_starter_clearing()
    if structures_enabled:
        _add_dungeon()
        _add_outpost()
        _add_ruins()
        _add_data_structures()
    if caves_enabled:
        _add_underground_caves()

func _author_starter_clearing() -> void:
    var floor_y := 7
    var stream_center := 17.0 + sin(float(seed_value % 37)) * 1.6
    for x in range(4, 30):
        for z in range(8, 34):
            var local_stream_center_x := stream_center + sin(float(z) * 0.32 + float(seed_value % 11)) * 2.8 + float(z - 20) * 0.16
            var stream_distance := absf(float(x) - local_stream_center_x)
            for y in range(1, WORLD_SIZE_Y):
                blocks.erase(Vector3i(x, y, z))
            if stream_distance < 3.0:
                blocks[Vector3i(x, floor_y, z)] = WATER
                if floor_y > 2:
                    blocks[Vector3i(x, floor_y - 1, z)] = WATER
                    blocks[Vector3i(x, floor_y - 2, z)] = WATER
            else:
                var bank := stream_distance < 4.6
                blocks[Vector3i(x, floor_y, z)] = SAND if bank else GRASS
                blocks[Vector3i(x, floor_y - 1, z)] = DIRT
                blocks[Vector3i(x, floor_y - 2, z)] = DIRT
                blocks[Vector3i(x, floor_y - 3, z)] = STONE
    for x in range(6, 29):
        for z in range(8, 13):
            var ridge := int(roundf(sin(float(x) * 0.55 + float(seed_value % 7)) * 1.4 + cos(float(z) * 0.8) * 0.8))
            var top_y := clampi(8 + ridge, 8, WORLD_SIZE_Y - 3)
            for y in range(7, top_y + 1):
                var ridge_cell := Vector3i(x, y, z)
                if not blocks.has(ridge_cell) or y >= 8:
                    blocks[ridge_cell] = GRASS if y == top_y else DIRT
    for tree_base in [Vector3i(5, floor_y + 1, 25), Vector3i(10, floor_y + 1, 14), Vector3i(27, floor_y + 1, 11), Vector3i(27, floor_y + 1, 26), Vector3i(6, floor_y + 1, 30), Vector3i(24, floor_y + 1, 31)]:
        _add_tree_variant(tree_base)
    for shrub_base in [Vector3i(10, floor_y + 1, 13), Vector3i(22, floor_y + 1, 14), Vector3i(10, floor_y + 1, 25), Vector3i(22, floor_y + 1, 27)]:
        _add_shrub(shrub_base)

func _setup_starter_grass_visuals() -> void:
    if is_instance_valid(starter_grass_visual_a):
        starter_grass_visual_a.queue_free()
    if is_instance_valid(starter_grass_visual_b):
        starter_grass_visual_b.queue_free()
    var positions: Array[Vector3] = []
    for x in range(4, 30):
        for z in range(8, 34):
            var cell := Vector3i(x, 7, z)
            if _get_stored_block(cell) != GRASS:
                continue
            if absi((x * 13 + z * 17 + seed_value) % 5) > 1:
                continue
            var offset_x := float((x * 7 + z * 3 + seed_value) % 5) * 0.10 - 0.20
            var offset_z := float((x * 5 + z * 11 + seed_value) % 5) * 0.10 - 0.20
            positions.append(Vector3(x + 0.5 + offset_x, float(cell.y) + 1.18, z + 0.5 + offset_z))
    if positions.is_empty():
        return
    var blade := BoxMesh.new()
    blade.size = Vector3(0.055, 0.38, 0.028)
    var material_a := StandardMaterial3D.new()
    material_a.albedo_color = Color("64a954")
    material_a.roughness = 0.95
    blade.material = material_a
    var multi_a := MultiMesh.new()
    multi_a.transform_format = MultiMesh.TRANSFORM_3D
    multi_a.instance_count = positions.size()
    multi_a.mesh = blade
    var multi_b := MultiMesh.new()
    multi_b.transform_format = MultiMesh.TRANSFORM_3D
    multi_b.instance_count = positions.size()
    multi_b.mesh = blade
    for index in positions.size():
        var p: Vector3 = positions[index]
        var lean := 0.78 + float((index % 4)) * 0.11
        multi_a.set_instance_transform(index, Transform3D(Basis(Vector3.UP, -lean), p))
        multi_b.set_instance_transform(index, Transform3D(Basis(Vector3.UP, lean), p + Vector3(0.03, 0.0, 0.03)))
    starter_grass_visual_a = MultiMeshInstance3D.new()
    starter_grass_visual_a.name = "StarterGrassVisualA"
    starter_grass_visual_a.multimesh = multi_a
    add_child(starter_grass_visual_a)
    starter_grass_visual_b = MultiMeshInstance3D.new()
    starter_grass_visual_b.name = "StarterGrassVisualB"
    starter_grass_visual_b.multimesh = multi_b
    add_child(starter_grass_visual_b)

func _structure_key(cell: Vector3i) -> String:
    return "%d:%d:%d" % [cell.x, cell.y, cell.z]

func _register_structure_loot(cell: Vector3i, table: Array[Dictionary], salt: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = abs(seed_value * 1009 + cell.x * 9176 + cell.y * 131 + cell.z * 6151 + salt)
    var loot: Dictionary = {}
    for entry in table:
        var chance := clampf(float(entry.get("chance", 1.0)), 0.0, 1.0)
        if rng.randf() <= chance:
            var item_id := int(entry.get("item", AIR))
            var min_count := maxi(1, int(entry.get("min", 1)))
            var max_count := maxi(min_count, int(entry.get("max", min_count)))
            loot[item_id] = rng.randi_range(min_count, max_count)
    if loot.is_empty() and not table.is_empty():
        var guaranteed := table[0]
        loot[int(guaranteed.get("item", AIR))] = maxi(1, int(guaranteed.get("min", 1)))
    structure_loot[_structure_key(cell)] = loot

func _claim_structure_loot(cell: Vector3i) -> void:
    var key := _structure_key(cell)
    if not structure_loot.has(key) or bool(claimed_structure_loot.get(key, false)):
        return
    var loot: Dictionary = structure_loot[key]
    for item_variant in loot.keys():
        var item_id := int(item_variant)
        var amount := maxi(0, int(loot[item_variant]))
        if amount > 0:
            storage_inventory[item_id] = int(storage_inventory.get(item_id, 0)) + amount
    claimed_structure_loot[key] = true
    generated_message = "Найден тайник: %s" % key

func _add_ruins() -> void:
    var pos := Vector3i(6, 0, 6)
    var floor_y := clampi(_highest_solid_y(pos.x, pos.z) + 1, 2, WORLD_SIZE_Y - 5)
    for x in range(pos.x - 2, pos.x + 3):
        for z in range(pos.z - 2, pos.z + 3):
            if (x + z) % 2 == 0:
                blocks[Vector3i(x, floor_y, z)] = STONE
                if randf() < 0.3:
                    blocks[Vector3i(x, floor_y + 1, z)] = STONE
    var ruin_chest := Vector3i(pos.x, floor_y + 1, pos.z)
    blocks[ruin_chest] = CHEST
    blocks[Vector3i(pos.x + 1, floor_y + 1, pos.z)] = FURNITURE_CRATE
    _register_structure_loot(ruin_chest, [{"item": IRON_ORE, "min": 1, "max": 3, "chance": 1.0}, {"item": BOLT, "min": 1, "max": 4, "chance": 0.65}, {"item": STAR_DUST, "min": 1, "max": 2, "chance": 0.2}], 17)

func _add_underground_caves() -> void:
    for x in range(2, WORLD_SIZE_X - 2):
        for z in range(2, WORLD_SIZE_Z - 2):
            if abs(x - dungeon_origin.x) <= 6 and abs(z - dungeon_origin.z) <= 6:
                continue
            for y in range(1, 4):
                var noise_value := (x * 17 + y * 31 + z * 13 + seed_value) % 29
                if noise_value == 0 or (y == 2 and (x * 7 + z * 11 + seed_value) % 37 == 0):
                    blocks.erase(Vector3i(x, y, z))
                elif noise_value == 3 and _get_block(Vector3i(x, y, z)) == STONE:
                    blocks[Vector3i(x, y, z)] = DEEP_CRYSTAL

func _highest_solid_y(x: int, z: int) -> int:
    for y in range(WORLD_SIZE_Y - 1, -1, -1):
        if _get_stored_block(Vector3i(x, y, z)) != AIR:
            return y
    return 0

func _add_dungeon() -> void:
    var floor_y := clampi(_highest_solid_y(dungeon_origin.x, dungeon_origin.z) + 1, 2, WORLD_SIZE_Y - 6)
    dungeon_origin.y = floor_y
    for x in range(dungeon_origin.x - 4, dungeon_origin.x + 5):
        for z in range(dungeon_origin.z - 4, dungeon_origin.z + 5):
            for y in range(floor_y, floor_y + 5):
                var cell := Vector3i(x, y, z)
                var edge := x == dungeon_origin.x - 4 or x == dungeon_origin.x + 4 or z == dungeon_origin.z - 4 or z == dungeon_origin.z + 4
                if y == floor_y:
                    blocks[cell] = STONE
                elif edge:
                    blocks[cell] = CRYSTAL if y == floor_y + 4 else STONE
                else:
                    blocks.erase(cell)
    for y in range(floor_y + 1, floor_y + 3):
        blocks.erase(Vector3i(dungeon_origin.x, y, dungeon_origin.z + 4))
    blocks[Vector3i(dungeon_origin.x, floor_y + 1, dungeon_origin.z)] = ECHO_LANTERN
    var dungeon_chest := Vector3i(dungeon_origin.x - 2, floor_y + 1, dungeon_origin.z - 2)
    blocks[dungeon_chest] = CHEST
    blocks[Vector3i(dungeon_origin.x + 2, floor_y + 1, dungeon_origin.z + 2)] = FURNITURE_LAMP
    _register_structure_loot(dungeon_chest, [{"item": ECHO_SHARD, "min": 2, "max": 5, "chance": 1.0}, {"item": DEEP_CRYSTAL, "min": 1, "max": 2, "chance": 0.7}, {"item": ASTRAL_CRYSTAL, "min": 1, "max": 1, "chance": 0.25}], 31)

func _add_outpost() -> void:
    var floor_y := clampi(_highest_solid_y(outpost_origin.x, outpost_origin.z) + 1, 2, WORLD_SIZE_Y - 4)
    outpost_origin.y = floor_y
    for x in range(outpost_origin.x - 3, outpost_origin.x + 4):
        for z in range(outpost_origin.z - 3, outpost_origin.z + 4):
            blocks[Vector3i(x, floor_y, z)] = WOOD if (x + z) % 2 == 0 else STONE
    for y in range(floor_y + 1, floor_y + 4):
        for corner in [Vector2i(-3, -3), Vector2i(-3, 3), Vector2i(3, -3), Vector2i(3, 3)]:
            blocks[Vector3i(outpost_origin.x + corner.x, y, outpost_origin.z + corner.y)] = WOOD
    for x in range(outpost_origin.x - 3, outpost_origin.x + 4):
        for z in range(outpost_origin.z - 3, outpost_origin.z + 4):
            if (x + z) % 3 == 0:
                blocks[Vector3i(x, floor_y + 4, z)] = WOOD
    blocks[Vector3i(outpost_origin.x - 2, floor_y + 1, outpost_origin.z - 2)] = FURNITURE_LAMP
    blocks[Vector3i(outpost_origin.x + 2, floor_y + 1, outpost_origin.z + 2)] = FURNITURE_TABLE
    var outpost_chest := Vector3i(outpost_origin.x, floor_y + 1, outpost_origin.z)
    blocks[outpost_chest] = CHEST
    _register_structure_loot(outpost_chest, [{"item": FOOD, "min": 2, "max": 5, "chance": 1.0}, {"item": FIBER, "min": 1, "max": 3, "chance": 0.8}, {"item": SALT_CRYSTAL, "min": 1, "max": 2, "chance": 0.35}], 43)

func _is_starter_meadow_cell(x: int, z: int) -> bool:
    return x >= 4 and x < 30 and z >= 8 and z < 34

func _biome_for(x: int, z: int) -> String:
    var sample_x := x
    var sample_z := z
    if biome_warp_noise != null:
        sample_x += roundi(biome_warp_noise.get_noise_2d(x, z) * 4.0)
        sample_z += roundi(biome_warp_noise.get_noise_2d(x + 83, z - 47) * 4.0)
    for definition_variant in external_biome_definitions.values():
        var definition: Dictionary = definition_variant
        if not bool(definition.get("custom", false)):
            continue
        var region: Array = definition.get("region", [])
        if region.size() == 4 and x >= int(region[0]) and x <= int(region[1]) and z >= int(region[2]) and z <= int(region[3]):
            return str(definition.get("name", BIOME_MEADOW))
    if sample_x < 8 and sample_z < 8:
        return BIOME_ASTRAL
    if sample_x < 8 and sample_z >= 16:
        return BIOME_WHISPER
    if sample_x >= 26:
        return BIOME_ECHO
    if sample_x >= 18 and sample_z >= 18:
        return BIOME_RIFT
    if sample_x < 10 and sample_z >= 16:
        return BIOME_DUNES
    if sample_x < 12 and sample_z < 16:
        return BIOME_FROST
    if sample_z < 7 and sample_x >= 12:
        return BIOME_FEN
    if sample_z >= 26 and sample_x < 18:
        return BIOME_EMBER
    if sample_z >= 7 and sample_z < 14 and sample_x >= 12:
        return BIOME_SALT
    var expanded_biomes: Array[String] = []
    for definition_variant in external_biome_definitions.values():
        var expanded_definition: Dictionary = definition_variant
        var expanded_name := str(expanded_definition.get("name", ""))
        if not bool(expanded_definition.get("custom", false)) and expanded_name not in [BIOME_MEADOW, BIOME_DUNES, BIOME_FROST, BIOME_RIFT, BIOME_ECHO, BIOME_FEN, BIOME_SALT, BIOME_EMBER, BIOME_ASTRAL, BIOME_WHISPER]:
            expanded_biomes.append(expanded_name)
    if not expanded_biomes.is_empty():
        var expanded_index := absi((sample_x * 31 + sample_z * 17 + seed_value) % expanded_biomes.size())
        return expanded_biomes[expanded_index]
    return BIOME_MEADOW

func _astral_subregion(x: int, z: int) -> String:
    var selector: int = absi((x * 37 + z * 53 + seed_value) % 100)
    if selector < 38:
        return "Звёздные равнины"
    if selector < 58:
        return "Туманностное поле"
    if selector < 78:
        return "Астероидные поля"
    if selector < 90:
        return "Чёрный карман"
    return "Кристаллический пояс"

func _astral_surface_block(x: int, z: int) -> int:
    match _astral_subregion(x, z):
        "Туманностное поле": return NEBULA_GAS
        "Астероидные поля": return ASTRAL_METAL
        "Чёрный карман": return VOID_SHARD
        "Кристаллический пояс": return ASTRAL_CRYSTAL
        _ : return COSMIC_STONE

func _astral_subsurface_block(x: int, z: int) -> int:
    match _astral_subregion(x, z):
        "Туманностное поле": return COSMIC_STONE
        "Астероидные поля": return ASTRAL_METAL
        "Чёрный карман": return VOID_SHARD
        "Кристаллический пояс": return COSMIC_ICE
        _ : return COSMIC_STONE

func _terrain_lift_for_biome(biome: String) -> int:
    if external_biome_definitions.has(biome):
        return clampi(int(external_biome_definitions[biome].get("terrain_lift", 0)), -2, 5)
    return 0

func _surface_block_for_biome(biome: String) -> int:
    if external_biome_definitions.has(biome):
        return int(external_biome_definitions[biome].get("surface_block", GRASS))
    match biome:
        BIOME_DUNES:
            return SAND
        BIOME_FROST:
            return SNOW
        BIOME_RIFT:
            return CRYSTAL
        BIOME_ECHO:
            return ASH
        BIOME_FEN:
            return MOSS
        BIOME_SALT:
            return SALT_CRUST
        BIOME_EMBER:
            return EMBER
        BIOME_ASTRAL:
            return COSMIC_STONE
        BIOME_WHISPER:
            return WHISPER_SOIL
        _:
            return GRASS

func _subsurface_block_for_biome(biome: String) -> int:
    if external_biome_definitions.has(biome):
        return int(external_biome_definitions[biome].get("subsurface_block", DIRT))
    match biome:
        BIOME_DUNES:
            return SAND
        BIOME_FROST:
            return STONE
        BIOME_RIFT:
            return STONE
        BIOME_ECHO:
            return ASH
        BIOME_FEN:
            return DIRT
        BIOME_SALT:
            return STONE
        BIOME_EMBER:
            return STONE
        BIOME_ASTRAL:
            return COSMIC_STONE
        BIOME_WHISPER:
            return DIRT
        _:
            return DIRT

func _add_moss_pillar(base: Vector3i) -> void:
    var height := 2 + ((base.x + base.z) % 2)
    for y in range(height):
        var cell := Vector3i(base.x, base.y + y, base.z)
        if _inside_world(cell):
            blocks[cell] = MOSS
    if _inside_world(Vector3i(base.x + 1, base.y + height - 1, base.z)):
        blocks[Vector3i(base.x + 1, base.y + height - 1, base.z)] = LEAVES

func _add_salt_marker(base: Vector3i) -> void:
    for offset_variant in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(0, 1, 0)]:
        var offset: Vector3i = offset_variant
        var cell: Vector3i = base + offset
        if _inside_world(cell):
            blocks[cell] = SALT_CRUST

func _add_ember_vent(base: Vector3i) -> void:
    for offset_variant in [Vector3i.ZERO, Vector3i(0, 1, 0), Vector3i(0, 2, 0)]:
        var offset: Vector3i = offset_variant
        var cell: Vector3i = base + offset
        if _inside_world(cell):
            blocks[cell] = EMBER

func _add_astral_marker(base: Vector3i) -> void:
    for offset_variant in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0)]:
        var offset: Vector3i = offset_variant
        var cell: Vector3i = base + offset
        if _inside_world(cell):
            blocks[cell] = ASTRAL_CRYSTAL if offset.y > 0 else COSMIC_STONE

func _add_astral_wreck(base: Vector3i) -> void:
    for x_offset in range(-2, 3):
        for z_offset in range(-1, 2):
            var deck := base + Vector3i(x_offset, 0, z_offset)
            if _inside_world(deck):
                blocks[deck] = ASTRAL_SCRAP
    for y_offset in range(1, 3):
        for x_offset in [-2, 2]:
            var frame := base + Vector3i(x_offset, y_offset, 0)
            if _inside_world(frame):
                blocks[frame] = ASTRAL_METAL
    var core := base + Vector3i(0, 1, 0)
    if _inside_world(core):
        blocks[core] = NEBULA_GAS
    var wreck_chest := base + Vector3i(0, 1, 1)
    if _inside_world(wreck_chest):
        blocks[wreck_chest] = CHEST
        blocks[base + Vector3i(1, 1, 1)] = FURNITURE_LAMP
        _register_structure_loot(wreck_chest, [{"item": ASTRAL_SCRAP, "min": 1, "max": 4, "chance": 1.0}, {"item": STAR_DUST, "min": 2, "max": 5, "chance": 0.8}, {"item": VOID_SHARD, "min": 1, "max": 2, "chance": 0.3}], 59)

func _add_whisper_grove(base: Vector3i) -> void:
    for y in range(3):
        var trunk := Vector3i(base.x, base.y + y, base.z)
        if _inside_world(trunk):
            blocks[trunk] = WHISPER_BARK
    for offset_variant in [Vector3i(0, 3, 0), Vector3i(1, 3, 0), Vector3i(-1, 3, 0), Vector3i(0, 3, 1), Vector3i(0, 3, -1)]:
        var offset: Vector3i = offset_variant
        var cell: Vector3i = base + offset
        if _inside_world(cell):
            blocks[cell] = WHISPER_SHARD

func _add_cactus(base: Vector3i) -> void:
    var height := 2 + ((base.x + base.z) % 2)
    for y in range(height):
        var cell := Vector3i(base.x, base.y + y, base.z)
        if _inside_world(cell):
            blocks[cell] = SAND
    if _inside_world(Vector3i(base.x, base.y + height, base.z)):
        blocks[Vector3i(base.x, base.y + height, base.z)] = GLOW

func _add_frost_spires(base: Vector3i) -> void:
    for offset in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(-1, 0, 1)]:
        var offset_vec: Vector3i = offset
        var height: int = 2 + abs(offset_vec.x + offset_vec.z)
        for y in range(height):
            var cell: Vector3i = base + offset_vec + Vector3i(0, y, 0)
            if _inside_world(cell):
                blocks[cell] = SNOW

func _add_crystal_cluster(base: Vector3i) -> void:
    for offset in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, -1)]:
        var offset_vec: Vector3i = offset
        var height: int = 2 + ((base.x + base.z + offset_vec.x + offset_vec.z) % 3)
        for y in range(height):
            var cell: Vector3i = base + offset_vec + Vector3i(0, y, 0)
            if _inside_world(cell):
                blocks[cell] = CRYSTAL

func _add_tree_variant(base: Vector3i) -> void:
    var trunk_height := 4 + absi((base.x * 3 + base.z + seed_value) % 2)
    var birch_variant := absi(base.x * 7 + base.z * 11 + seed_value) % 8 == 0
    for y in range(trunk_height):
        var trunk := Vector3i(base.x, base.y + y, base.z)
        if _inside_world(trunk):
            blocks[trunk] = WOOD
            if birch_variant:
                birch_bark_cells[trunk] = true
            else:
                birch_bark_cells.erase(trunk)
    var canopy_base := base.y + trunk_height - 3
    # Layered canopy: broad lower crown, narrower middle, stepped top and deliberate gaps.
    var canopy_layers := [[0, 2, 2], [1, 3, 2], [2, 3, 3], [3, 2, 2], [4, 2, 1], [5, 1, 1]]
    for layer_variant in canopy_layers:
        var layer: Array = layer_variant
        var y_offset: int = int(layer[0])
        var radius_x: int = int(layer[1])
        var radius_z: int = int(layer[2])
        for ox in range(-radius_x, radius_x + 1):
            for oz in range(-radius_z, radius_z + 1):
                var edge_gap := absi(ox) + absi(oz)
                if edge_gap > radius_x + radius_z - 1:
                    continue
                if (ox * 5 + oz * 7 + y_offset + base.x + base.z) % 9 == 0:
                    continue
                var leaf := Vector3i(base.x + ox, canopy_base + y_offset, base.z + oz)
                if _inside_world(leaf) and not blocks.has(leaf):
                    blocks[leaf] = LEAVES

func _add_shrub(base: Vector3i) -> void:
    for offset_variant in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(-1, 0, 0)]:
        var offset: Vector3i = offset_variant
        var cell := base + offset
        if _inside_world(cell) and not blocks.has(cell):
            blocks[cell] = LEAVES

func _add_tree(base: Vector3i) -> void:
    for y in range(3):
        var trunk := Vector3i(base.x, base.y + y, base.z)
        if _inside_world(trunk):
            blocks[trunk] = WOOD
    for ox in range(-2, 3):
        for oy in range(1, 4):
            for oz in range(-2, 3):
                if abs(ox) + abs(oz) + abs(oy - 2) <= 4:
                    var leaf := Vector3i(base.x + ox, base.y + oy, base.z + oz)
                    if _inside_world(leaf) and not blocks.has(leaf):
                        blocks[leaf] = LEAVES

func _setup_player() -> void:
    player = VoxelPlayerScript.new()
    player.name = "Player"
    player.position = Vector3(16.0, 12.0, 16.0)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.36
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position = Vector3(0.0, 0.9, 0.0)
    player.add_child(collision)
    add_child(player)
    player.configure_survival(difficulty_mode, hardcore_mode)
    player.set_avatar_profile(avatar_profile)
    player.set_creative_mode(world_mode == "Творческий тест")
    player.survival_changed.connect(_on_player_survival_changed)
    player.player_died.connect(_on_player_died)
    _apply_pending_player_state()

func _setup_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var hud_backdrop := Panel.new()
    hud_backdrop.position = Vector2(16.0, 12.0)
    hud_backdrop.size = Vector2(860.0, 370.0)
    var hud_backdrop_style := StyleBoxFlat.new()
    hud_backdrop_style.bg_color = Color(0.025, 0.045, 0.075, 0.78)
    hud_backdrop_style.border_color = Color(0.34, 0.48, 0.58, 0.72)
    hud_backdrop_style.set_border_width_all(1)
    hud_backdrop_style.corner_radius_top_left = 8
    hud_backdrop_style.corner_radius_top_right = 8
    hud_backdrop_style.corner_radius_bottom_left = 8
    hud_backdrop_style.corner_radius_bottom_right = 8
    hud_backdrop.add_theme_stylebox_override("panel", hud_backdrop_style)
    layer.add_child(hud_backdrop)
    layer.move_child(hud_backdrop, 0)
    hud_backdrop.visible = false

    var title := Label.new()
    title.position = Vector2(28.0, 18.0)
    title.text = "ПЕПЕЛЬНЫЙ РУБЕЖ  ·  VOXEL EXPEDITION"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("f4d08a"))
    layer.add_child(title)
    title.visible = false

    var help := Label.new()
    help.position = Vector2(30.0, 54.0)
    help.text = "WASD · SPACE · Shift · LMB/Q ломать · RMB/R ставить · X атака · I инвентарь · J guide · F5 save · F9 load"
    help.size = Vector2(820.0, 24.0)
    help.add_theme_font_size_override("font_size", 12)
    help.add_theme_color_override("font_color", Color("d1e6f4"))
    layer.add_child(help)
    help.visible = false

    health_label = Label.new()
    health_label.position = Vector2(30.0, 86.0)
    health_label.size = Vector2(108.0, 24.0)
    health_label.add_theme_font_size_override("font_size", 14)
    layer.add_child(health_label)

    hunger_label = Label.new()
    hunger_label.position = Vector2(180.0, 86.0)
    hunger_label.size = Vector2(108.0, 24.0)
    hunger_label.add_theme_font_size_override("font_size", 14)
    layer.add_child(hunger_label)

    thirst_label = Label.new()
    thirst_label.position = Vector2(30.0, 112.0)
    thirst_label.size = Vector2(108.0, 24.0)
    thirst_label.add_theme_font_size_override("font_size", 14)
    layer.add_child(thirst_label)

    energy_label = Label.new()
    energy_label.position = Vector2(180.0, 112.0)
    energy_label.size = Vector2(120.0, 24.0)
    energy_label.add_theme_font_size_override("font_size", 14)
    layer.add_child(energy_label)

    biome_label = Label.new()
    biome_label.position = Vector2(30.0, 138.0)
    biome_label.add_theme_font_size_override("font_size", 16)
    biome_label.add_theme_color_override("font_color", Color("b8f2d1"))
    layer.add_child(biome_label)

    quest_label = Label.new()
    quest_label.position = Vector2(30.0, 164.0)
    quest_label.add_theme_font_size_override("font_size", 16)
    quest_label.add_theme_color_override("font_color", Color("ffd76e"))
    layer.add_child(quest_label)

    rules_label = Label.new()
    rules_label.position = Vector2(30.0, 190.0)
    rules_label.add_theme_font_size_override("font_size", 15)
    rules_label.add_theme_color_override("font_color", Color("c3c9ff"))
    layer.add_child(rules_label)

    boss_label = Label.new()
    boss_label.position = Vector2(30.0, 216.0)
    boss_label.add_theme_font_size_override("font_size", 15)
    boss_label.add_theme_color_override("font_color", Color("d9a8ff"))
    layer.add_child(boss_label)

    weather_label = Label.new()
    weather_label.position = Vector2(30.0, 242.0)
    weather_label.add_theme_font_size_override("font_size", 15)
    weather_label.add_theme_color_override("font_color", Color("a9d7ea"))
    layer.add_child(weather_label)

    npc_label = Label.new()
    npc_label.position = Vector2(30.0, 294.0)
    npc_label.add_theme_font_size_override("font_size", 15)
    npc_label.add_theme_color_override("font_color", Color("8fd9cf"))
    layer.add_child(npc_label)

    dimension_label = Label.new()
    dimension_label.position = Vector2(30.0, 320.0)
    dimension_label.add_theme_font_size_override("font_size", 15)
    dimension_label.add_theme_color_override("font_color", Color("c29be8"))
    layer.add_child(dimension_label)

    storage_hint_label = Label.new()
    storage_hint_label.position = Vector2(30.0, 268.0)
    storage_hint_label.add_theme_font_size_override("font_size", 15)
    storage_hint_label.add_theme_color_override("font_color", Color("e4c991"))
    layer.add_child(storage_hint_label)

    ranged_hint_label = Label.new()
    ranged_hint_label.position = Vector2(30.0, 268.0)
    ranged_hint_label.add_theme_font_size_override("font_size", 15)
    ranged_hint_label.add_theme_color_override("font_color", Color("f2c777"))
    layer.add_child(ranged_hint_label)

    health_label.visible = false
    hunger_label.visible = false
    thirst_label.visible = false
    energy_label.visible = false
    biome_label.visible = false
    quest_label.visible = false
    rules_label.visible = false
    boss_label.visible = false
    weather_label.visible = false
    npc_label.visible = false
    dimension_label.visible = false
    storage_hint_label.visible = false
    ranged_hint_label.visible = false
    _create_compact_hud(layer)

    death_label = Label.new()
    death_label.position = Vector2(430.0, 300.0)
    death_label.add_theme_font_size_override("font_size", 24)
    death_label.add_theme_color_override("font_color", Color("ffb6aa"))
    death_label.visible = false
    layer.add_child(death_label)

    target_label = Label.new()
    target_label.position = Vector2(30.0, 268.0)
    target_label.add_theme_font_size_override("font_size", 15)
    target_label.add_theme_color_override("font_color", Color("ffe9a6"))
    layer.add_child(target_label)

    status_label = Label.new()
    status_label.position = Vector2(30.0, 650.0)
    status_label.add_theme_font_size_override("font_size", 17)
    status_label.add_theme_color_override("font_color", Color("e6f5ff"))
    layer.add_child(status_label)
    status_label.visible = false

    command_input = LineEdit.new()
    command_input.position = Vector2(350.0, 606.0)
    command_input.size = Vector2(580.0, 36.0)
    command_input.placeholder_text = "/give 42 1 · /weather ash · /tp 16 10 16"
    command_input.add_theme_font_size_override("font_size", 14)
    command_input.visible = false
    command_input.text_submitted.connect(_execute_command)
    layer.add_child(command_input)

    hotbar_label = Label.new()
    hotbar_label.position = Vector2(30.0, 680.0)
    hotbar_label.add_theme_font_size_override("font_size", 14)
    hotbar_label.add_theme_color_override("font_color", Color("ffd76e"))
    layer.add_child(hotbar_label)
    hotbar_label.visible = false

    inventory_label = Label.new()
    inventory_label.position = Vector2(850.0, 100.0)
    inventory_label.size = Vector2(380.0, 190.0)
    inventory_label.add_theme_font_size_override("font_size", 18)
    inventory_label.add_theme_color_override("font_color", Color("eff8ff"))
    inventory_label.add_theme_color_override("font_shadow_color", Color("08111f"))
    inventory_label.add_theme_constant_override("shadow_offset_x", 2)
    inventory_label.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(inventory_label)
    inventory_label.visible = false
    _create_inventory_panel(layer)
    _create_storage_panel(layer)
    _create_guide_panel(layer)
    _create_settings_panel(layer)

    crosshair_label = Label.new()
    var crosshair := crosshair_label
    var viewport_size := get_viewport().get_visible_rect().size
    crosshair.position = Vector2(viewport_size.x * 0.5 - 14.0, viewport_size.y * 0.5 - 20.0)
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 28)
    crosshair.add_theme_color_override("font_color", Color("ffffff"))
    layer.add_child(crosshair)

    break_progress_bar = ProgressBar.new()
    break_progress_bar.position = Vector2(560.0, 386.0)
    break_progress_bar.size = Vector2(160.0, 8.0)
    break_progress_bar.show_percentage = false
    break_progress_bar.add_theme_stylebox_override("background", _break_bar_style(Color(0.02, 0.04, 0.05, 0.58)))
    break_progress_bar.add_theme_stylebox_override("fill", _break_bar_style(Color("e4b66d")))
    break_progress_bar.visible = false
    layer.add_child(break_progress_bar)

    if touch_layout != "Классический экран" or OS.has_feature("mobile"):
        mobile_overlay = MobileOverlayScript.new()
        mobile_overlay.name = "MobileVoxelControls"
        layer.add_child(mobile_overlay)
    _create_telemetry_overlay(layer)

func _create_telemetry_overlay(layer: CanvasLayer) -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    telemetry_panel = Panel.new()
    telemetry_panel.name = "TelemetryPanel"
    telemetry_panel.position = Vector2(maxf(12.0, viewport_size.x - 366.0), 58.0)
    telemetry_panel.size = Vector2(350.0, 136.0)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.015, 0.025, 0.04, 0.92)
    panel_style.border_color = Color("65d6a0")
    panel_style.set_border_width_all(1)
    telemetry_panel.add_theme_stylebox_override("panel", panel_style)
    telemetry_panel.visible = false
    layer.add_child(telemetry_panel)

    telemetry_label = Label.new()
    telemetry_label.position = Vector2(10.0, 8.0)
    telemetry_label.size = Vector2(330.0, 120.0)
    telemetry_label.add_theme_font_size_override("font_size", 14)
    telemetry_label.add_theme_color_override("font_color", Color("d7f6e7"))
    telemetry_label.text = "Telemetry: OFF"
    telemetry_panel.add_child(telemetry_label)

    telemetry_button = Button.new()
    telemetry_button.name = "TelemetryToggle"
    telemetry_button.position = Vector2(maxf(12.0, viewport_size.x - 92.0), 16.0)
    telemetry_button.size = Vector2(76.0, 34.0)
    telemetry_button.text = "FPS"
    telemetry_button.add_theme_font_size_override("font_size", 13)
    telemetry_button.tooltip_text = "Telemetry (F10 on PC)"
    telemetry_button.visible = OS.has_feature("mobile")
    telemetry_button.pressed.connect(_toggle_telemetry)
    layer.add_child(telemetry_button)

func _toggle_telemetry() -> void:
    telemetry_enabled = not telemetry_enabled
    telemetry_update_timer = 0.0
    telemetry_frame_accum = 0.0
    telemetry_frame_samples = 0
    if is_instance_valid(telemetry_panel):
        telemetry_panel.visible = telemetry_enabled
    if is_instance_valid(telemetry_button):
        telemetry_button.text = "FPS ON" if telemetry_enabled else "FPS"
    if telemetry_enabled:
        _update_telemetry()

func _update_telemetry() -> void:
    if not is_instance_valid(telemetry_label):
        return
    var average_frame_ms := 0.0
    if telemetry_frame_samples > 0:
        average_frame_ms = telemetry_frame_accum / float(telemetry_frame_samples) * 1000.0
    var fps := Engine.get_frames_per_second()
    telemetry_label.text = "FPS: %d  |  frame: %.2f ms\n" % [fps, average_frame_ms]
    telemetry_label.text += "rebuild last/max: %.2f / %.2f ms\n" % [last_mesh_rebuild_ms, max_mesh_rebuild_ms]
    telemetry_label.text += "rebuild calls: %d\n" % mesh_rebuild_count
    telemetry_label.text += "dirty total/last: %d / %d\n" % [dirty_chunk_rebuild_count, last_dirty_chunk_count]
    telemetry_label.text += "pending dirty: %d  loaded: %d\n" % [dirty_chunk_keys.size(), loaded_chunk_keys.size()]
    telemetry_label.text += "visible cells: %d" % last_mesh_rebuild_cells
    telemetry_frame_accum = 0.0
    telemetry_frame_samples = 0

func _break_bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style

func _create_compact_hud(layer: CanvasLayer) -> void:
    compact_panel = Panel.new()
    compact_panel.position = Vector2(18.0, 612.0)
    compact_panel.size = Vector2(430.0, 92.0)
    var compact_style := StyleBoxFlat.new()
    compact_style.bg_color = Color(0.02, 0.04, 0.07, 0.78)
    compact_style.border_color = Color(0.42, 0.58, 0.66, 0.72)
    compact_style.set_border_width_all(1)
    compact_style.corner_radius_top_left = 8
    compact_style.corner_radius_top_right = 8
    compact_style.corner_radius_bottom_left = 8
    compact_style.corner_radius_bottom_right = 8
    compact_panel.add_theme_stylebox_override("panel", compact_style)
    layer.add_child(compact_panel)

    compact_hp_bar = _compact_bar(compact_panel, Vector2(14.0, 14.0), Color("d85b66"))
    compact_hunger_bar = _compact_bar(compact_panel, Vector2(222.0, 14.0), Color("e5b85f"))
    compact_thirst_bar = _compact_bar(compact_panel, Vector2(14.0, 42.0), Color("56b9d8"))
    compact_energy_bar = _compact_bar(compact_panel, Vector2(222.0, 42.0), Color("7bd28f"))

    compact_selection_label = Label.new()
    compact_selection_label.position = Vector2(466.0, 658.0)
    compact_selection_label.size = Vector2(360.0, 28.0)
    compact_selection_label.add_theme_font_size_override("font_size", 15)
    compact_selection_label.add_theme_color_override("font_color", Color("f0e3bb"))
    layer.add_child(compact_selection_label)
    compact_selection_label.visible = false

    compact_hotbar_label = Label.new()
    compact_hotbar_label.position = Vector2(466.0, 682.0)
    compact_hotbar_label.size = Vector2(360.0, 26.0)
    compact_hotbar_label.add_theme_font_size_override("font_size", 14)
    compact_hotbar_label.add_theme_color_override("font_color", Color("d5e6ed"))
    layer.add_child(compact_hotbar_label)
    compact_hotbar_label.visible = false

    compact_mana_bar = _compact_bar(layer, Vector2(1040.0, 22.0), Color("ae82ee"))
    compact_mana_bar.size = Vector2(214.0, 14.0)
    compact_mana_label = Label.new()
    compact_mana_label.position = Vector2(1040.0, 40.0)
    compact_mana_label.size = Vector2(214.0, 22.0)
    compact_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    compact_mana_label.add_theme_font_size_override("font_size", 13)
    compact_mana_label.add_theme_color_override("font_color", Color("eadbff"))
    layer.add_child(compact_mana_label)
    compact_mana_label.visible = false

func _compact_bar(parent: Node, bar_position: Vector2, fill_color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = bar_position
    bar.size = Vector2(188.0, 14.0)
    bar.max_value = 100.0
    bar.show_percentage = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color(0.05, 0.08, 0.11, 0.92)
    background.corner_radius_top_left = 4
    background.corner_radius_top_right = 4
    background.corner_radius_bottom_left = 4
    background.corner_radius_bottom_right = 4
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.corner_radius_top_left = 4
    fill.corner_radius_top_right = 4
    fill.corner_radius_bottom_left = 4
    fill.corner_radius_bottom_right = 4
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _create_inventory_panel(layer: CanvasLayer) -> void:
    inventory_panel = Panel.new()
    inventory_panel.name = "WorldForgeInventory"
    inventory_panel.position = Vector2(8.0, 10.0)
    var viewport_size := get_viewport().get_visible_rect().size
    inventory_panel.size = Vector2(maxf(1264.0, viewport_size.x - 20.0), maxf(580.0, viewport_size.y - 20.0))
    var panel_width := inventory_panel.size.x
    var panel_height := inventory_panel.size.y
    var preview_width := minf(430.0, panel_width * 0.34)
    var content_width := panel_width - preview_width - 128.0
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("101713")
    panel_style.border_color = Color("344239")
    panel_style.set_border_width_all(4)
    panel_style.corner_radius_top_left = 2
    panel_style.corner_radius_top_right = 2
    panel_style.corner_radius_bottom_left = 2
    panel_style.corner_radius_bottom_right = 2
    inventory_panel.add_theme_stylebox_override("panel", panel_style)
    inventory_icon_atlas = load("res://assets/ui_standard/assets/ui/inventory_icon_atlas.png") as Texture2D
    inventory_panel.visible = false
    layer.add_child(inventory_panel)
    var inventory_topbar := Panel.new()
    inventory_topbar.position = Vector2(0.0, 0.0)
    inventory_topbar.size = Vector2(panel_width, 56.0)
    inventory_topbar.add_theme_stylebox_override("panel", _panel_style(Color("c7c7c4"), Color("8b8b87")))
    inventory_panel.add_child(inventory_topbar)
    var inventory_back := Button.new()
    inventory_back.text = "‹"
    inventory_back.position = Vector2(16.0, 6.0)
    inventory_back.size = Vector2(42.0, 42.0)
    inventory_back.add_theme_font_size_override("font_size", 30)
    inventory_back.add_theme_color_override("font_color", Color("253029"))
    inventory_back.pressed.connect(func() -> void:
        inventory_open = false
        _update_hud()
    )
    inventory_topbar.add_child(inventory_back)
    var inventory_context := Label.new()
    inventory_context.position = Vector2(72.0, 15.0)
    inventory_context.text = "ВОКСЕЛЬНЫЙ РЮКЗАК"
    inventory_context.add_theme_font_size_override("font_size", 17)
    inventory_context.add_theme_color_override("font_color", Color("26322c"))
    inventory_topbar.add_child(inventory_context)
    var inventory_currency := Label.new()
    inventory_currency.position = Vector2(panel_width - 300.0, 16.0)
    inventory_currency.size = Vector2(112.0, 26.0)
    inventory_currency.text = "●  0   +"
    inventory_currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inventory_currency.add_theme_color_override("font_color", Color("1b321c"))
    inventory_currency.add_theme_stylebox_override("normal", _panel_style(Color("49a920"), Color("2d711c")))
    inventory_topbar.add_child(inventory_currency)
    var close_button := Button.new()
    close_button.text = "×"
    close_button.position = Vector2(panel_width - 48.0, 8.0)
    close_button.size = Vector2(36.0, 36.0)
    close_button.add_theme_font_size_override("font_size", 24)
    close_button.pressed.connect(func() -> void:
        inventory_open = false
        _update_hud()
    )
    inventory_panel.add_child(close_button)

    inventory_title = Label.new()
    inventory_title.position = Vector2(106.0, 70.0)
    inventory_title.text = "ВСЕ ПРЕДМЕТЫ"
    inventory_title.add_theme_font_size_override("font_size", 22)
    inventory_title.add_theme_color_override("font_color", Color("e5eee5"))
    inventory_panel.add_child(inventory_title)

    inventory_search = LineEdit.new()
    inventory_search.position = Vector2(92.0, 108.0)
    inventory_search.size = Vector2(content_width, 42.0)
    inventory_search.placeholder_text = "Поиск предмета"
    inventory_search.add_theme_font_size_override("font_size", 13)
    inventory_search.text_changed.connect(_on_inventory_search_changed)
    inventory_panel.add_child(inventory_search)

    inventory_category_select = OptionButton.new()
    inventory_category_select.position = Vector2(14.0, 108.0)
    inventory_category_select.size = Vector2(72.0, 34.0)
    for category in ["Все", "Строительство", "Декор", "Ресурсы", "Технология", "Кухня", "Оружие", "Магия"]:
        inventory_category_select.add_item(category)
    inventory_category_select.item_selected.connect(_on_inventory_category_changed)
    inventory_panel.add_child(inventory_category_select)
    inventory_category_select.visible = false
    var category_glyphs := ["●", "▦", "◇", "✦", "＋", "◆", "◈", "⋮"]
    for category_index in category_glyphs.size():
        var category_button := Button.new()
        category_button.text = category_glyphs[category_index]
        category_button.position = Vector2(14.0, 154.0 + category_index * 44.0)
        category_button.size = Vector2(72.0, 36.0)
        category_button.tooltip_text = inventory_category_select.get_item_text(category_index)
        category_button.add_theme_font_size_override("font_size", 18)
        category_button.add_theme_stylebox_override("normal", _panel_style(Color("17221b"), Color("3b4d40")))
        category_button.add_theme_stylebox_override("hover", _panel_style(Color("263b2c"), Color("8fb18c")))
        category_button.add_theme_stylebox_override("pressed", _panel_style(Color("31533a"), Color("b8d6a9")))
        category_button.pressed.connect(func() -> void:
            inventory_category_select.select(category_index)
            _on_inventory_category_changed(category_index)
        )
        inventory_panel.add_child(category_button)

    var inventory_scroll := ScrollContainer.new()
    inventory_scroll.position = Vector2(96.0, 164.0)
    inventory_scroll.size = Vector2(content_width, panel_height - 188.0)
    inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    inventory_panel.add_child(inventory_scroll)
    inventory_grid = GridContainer.new()
    inventory_grid.position = Vector2.ZERO
    inventory_grid.size = Vector2(content_width, 1200.0)
    inventory_grid.custom_minimum_size = Vector2(content_width, 1200.0)
    inventory_grid.columns = 6
    inventory_scroll.add_child(inventory_grid)
    inventory_item_ids = [GRASS, DIRT, STONE, WOOD, PLANKS, STICK, WORKBENCH, STOVE, CHEST, GLOW, SAND, SNOW, CRYSTAL, DEEP_CRYSTAL, ASH, COAL_ORE, IRON_ORE, COPPER_ORE, GOLD_ORE, DIAMOND_ORE, FOOD, COOKED_FOOD, BOLT, TRAP, ECHO_SHARD, SALT_CRYSTAL, ECHO_LANTERN, MOSS, SALT_CRUST, EMBER, COSMIC_STONE, STAR_DUST, ASTRAL_CRYSTAL, ASTRAL_SCRAP, ASTRAL_METAL, COSMIC_ICE, VOID_SHARD, ANTIMATTER, NEBULA_GAS, WHISPER_SOIL, WHISPER_BARK, WHISPER_SHARD, FURNITURE_CRATE, FURNITURE_TABLE, FURNITURE_LAMP, WATER, ASH_FLUID, ARCANE_CRYSTAL, ARCANE_CONDUIT, AUTOMATION_FORGE, CARGO_RAIL]
    for definition_variant in ore_definitions.values():
        var definition: Dictionary = definition_variant
        inventory_item_ids.append(int(definition["block_id"]))
        inventory_item_ids.append(int(definition["raw_id"]))
        inventory_item_ids.append(int(definition["ingot_id"]))
    for index in inventory_item_ids.size():
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(112.0, 92.0)
        slot.add_theme_font_size_override("font_size", 13)
        slot.add_theme_stylebox_override("normal", _panel_style(Color("19261e") if index % 3 == 0 else Color("1c2d22"), Color("4d6551")))
        slot.add_theme_stylebox_override("hover", _panel_style(Color("2d4933"), Color("b8d6a9")))
        slot.add_theme_stylebox_override("pressed", _panel_style(Color("3a6543"), Color("d4e9c6")))
        slot.clip_text = true
        var icon_rect := TextureRect.new()
        icon_rect.name = "Icon"
        icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.size = Vector2(68, 62)
        icon_rect.position = Vector2(22, 6)
        slot.add_child(icon_rect)
        slot.pressed.connect(_on_inventory_slot_pressed.bind(index))
        inventory_grid.add_child(slot)
        inventory_slots.append(slot)

    var preview_panel := Panel.new()
    preview_panel.name = "ReferenceCharacterPreview"
    preview_panel.position = Vector2(panel_width - preview_width - 16.0, 156.0)
    preview_panel.size = Vector2(preview_width, panel_height - 172.0)
    preview_panel.add_theme_stylebox_override("panel", _panel_style(Color("0b110d"), Color("536f59")))
    inventory_panel.add_child(preview_panel)
    var preview_scene := ColorRect.new()
    preview_scene.position = Vector2(12.0, 12.0)
    preview_scene.size = Vector2(preview_width - 24.0, 270.0)
    preview_scene.color = Color("101713")
    preview_panel.add_child(preview_scene)
    var avatar_head := ColorRect.new()
    avatar_head.position = Vector2(preview_width * 0.5 - 24.0, 58.0)
    avatar_head.size = Vector2(48.0, 52.0)
    avatar_head.color = Color("2b3340")
    preview_scene.add_child(avatar_head)
    var avatar_body := ColorRect.new()
    avatar_body.position = Vector2(preview_width * 0.5 - 38.0, 112.0)
    avatar_body.size = Vector2(76.0, 92.0)
    avatar_body.color = Color("5a628f")
    preview_scene.add_child(avatar_body)
    var avatar_legs := ColorRect.new()
    avatar_legs.position = Vector2(preview_width * 0.5 - 32.0, 207.0)
    avatar_legs.size = Vector2(64.0, 54.0)
    avatar_legs.color = Color("2f4050")
    preview_scene.add_child(avatar_legs)
    var avatar_arm_left := ColorRect.new()
    avatar_arm_left.position = Vector2(preview_width * 0.5 - 58.0, 116.0)
    avatar_arm_left.size = Vector2(18.0, 78.0)
    avatar_arm_left.color = Color("4c547d")
    preview_scene.add_child(avatar_arm_left)
    var avatar_arm_right := ColorRect.new()
    avatar_arm_right.position = Vector2(preview_width * 0.5 + 40.0, 116.0)
    avatar_arm_right.size = Vector2(18.0, 78.0)
    avatar_arm_right.color = Color("4c547d")
    preview_scene.add_child(avatar_arm_right)
    var avatar_hair := ColorRect.new()
    avatar_hair.position = Vector2(preview_width * 0.5 - 24.0, 52.0)
    avatar_hair.size = Vector2(48.0, 14.0)
    avatar_hair.color = Color("17202a")
    preview_scene.add_child(avatar_hair)
    var avatar_face := ColorRect.new()
    avatar_face.position = Vector2(preview_width * 0.5 - 14.0, 76.0)
    avatar_face.size = Vector2(28.0, 22.0)
    avatar_face.color = Color("b77f65")
    preview_scene.add_child(avatar_face)
    var preview_title := Label.new()
    preview_title.position = Vector2(18.0, 294.0)
    preview_title.text = "НАЧАЛО РАБОТЫ"
    preview_title.add_theme_font_size_override("font_size", 18)
    preview_title.add_theme_color_override("font_color", Color("e5eee5"))
    preview_panel.add_child(preview_title)
    var preview_copy := Label.new()
    preview_copy.position = Vector2(18.0, 332.0)
    preview_copy.size = Vector2(preview_width - 36.0, 100.0)
    preview_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_copy.text = "Выбирайте предметы слева, чтобы добавить их в быстрый доступ и посмотреть их силуэт на персонаже."
    preview_copy.add_theme_font_size_override("font_size", 13)
    preview_copy.add_theme_color_override("font_color", Color("a9b8aa"))
    preview_panel.add_child(preview_copy)

    var tool_header := Label.new()
    tool_header.position = Vector2(14.0, 154.0)
    tool_header.text = "ИНСТРУМЕНТЫ"
    tool_header.add_theme_font_size_override("font_size", 16)
    tool_header.add_theme_color_override("font_color", Color("c3c9ff"))
    tool_header.visible = false
    inventory_panel.add_child(tool_header)
    for tool_index in tool_names.size():
        var tool_button := Button.new()
        tool_button.position = Vector2(12.0, 188.0 + tool_index * 46.0)
        tool_button.size = Vector2(72.0, 38.0)
        tool_button.add_theme_font_size_override("font_size", 14)
        tool_button.pressed.connect(_on_tool_pressed.bind(tool_index))
        tool_button.visible = false
        inventory_panel.add_child(tool_button)
        inventory_slots.append(tool_button)

    armor_button = Button.new()
    armor_button.position = Vector2(12.0, 382.0)
    armor_button.size = Vector2(72.0, 34.0)
    armor_button.add_theme_font_size_override("font_size", 13)
    armor_button.pressed.connect(_toggle_armor)
    armor_button.visible = false
    inventory_panel.add_child(armor_button)

func _create_storage_panel(layer: CanvasLayer) -> void:
    storage_panel = Panel.new()
    storage_panel.name = "ExpeditionStorage"
    storage_panel.position = Vector2(370.0, 150.0)
    storage_panel.size = Vector2(520.0, 420.0)
    storage_panel.add_theme_stylebox_override("panel", _panel_style(Color("132337"), Color("e4c991")))
    storage_panel.visible = false
    layer.add_child(storage_panel)

    storage_title = Label.new()
    storage_title.position = Vector2(22.0, 18.0)
    storage_title.add_theme_font_size_override("font_size", 20)
    storage_title.add_theme_color_override("font_color", Color("f4d08a"))
    storage_panel.add_child(storage_title)

    var description := Label.new()
    description.position = Vector2(22.0, 50.0)
    description.text = "Нажми на ресурс, чтобы переложить весь его стек. Повторное нажатие возвращает стек."
    description.add_theme_font_size_override("font_size", 14)
    description.add_theme_color_override("font_color", Color("d9e6f2"))
    storage_panel.add_child(description)

    var grid := GridContainer.new()
    grid.position = Vector2(22.0, 88.0)
    grid.size = Vector2(475.0, 250.0)
    grid.columns = 4
    storage_panel.add_child(grid)
    storage_item_ids = [STONE, WOOD, SAND, SNOW, CRYSTAL, ASH, FOOD, COOKED_FOOD, FIBER, BOLT, TRAP, DEEP_CRYSTAL, ECHO_SHARD, SALT_CRYSTAL, MOSS, SALT_CRUST, EMBER, ECHO_LANTERN, CHEST, STOVE, FURNITURE_CRATE, FURNITURE_TABLE, FURNITURE_LAMP, WATER, ASH_FLUID, ARCANE_CRYSTAL, ARCANE_CONDUIT, AUTOMATION_FORGE, CARGO_RAIL, STAR_DUST, ASTRAL_METAL, ASTRAL_SCRAP]
    for definition_variant in ore_definitions.values():
        var definition: Dictionary = definition_variant
        storage_item_ids.append(int(definition["raw_id"]))
        storage_item_ids.append(int(definition["ingot_id"]))
    for index in storage_item_ids.size():
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(112.0, 58.0)
        slot.add_theme_font_size_override("font_size", 12)
        slot.pressed.connect(_on_storage_slot_pressed.bind(index))
        grid.add_child(slot)
        storage_slots.append(slot)

    var close_button := Button.new()
    close_button.position = Vector2(22.0, 360.0)
    close_button.size = Vector2(220.0, 38.0)
    close_button.text = "ЗАКРЫТЬ — O"
    close_button.pressed.connect(_close_storage)
    storage_panel.add_child(close_button)

func _init_storage_inventory() -> void:
    storage_inventory.clear()
    for item_id in storage_item_ids:
        storage_inventory[item_id] = 0
    storage_inventory[STONE] = 0
    storage_inventory[WOOD] = 0

func _refresh_storage_panel() -> void:
    if not is_instance_valid(storage_panel):
        return
    if storage_inventory.is_empty():
        _init_storage_inventory()
    storage_title.text = "СУНДУК  %s" % active_chest
    for index in storage_item_ids.size():
        var item_id := storage_item_ids[index]
        if index < storage_slots.size():
            storage_slots[index].text = "%s\\nРюкзак %d  ·  Сундук %d" % [_block_name(item_id), int(inventory.get(item_id, 0)), int(storage_inventory.get(item_id, 0))]

func _on_storage_slot_pressed(index: int) -> void:
    if index < 0 or index >= storage_item_ids.size():
        return
    var item_id := storage_item_ids[index]
    var backpack_amount := int(inventory.get(item_id, 0))
    var chest_amount := int(storage_inventory.get(item_id, 0))
    if backpack_amount > 0:
        storage_inventory[item_id] = chest_amount + backpack_amount
        inventory[item_id] = 0
        generated_message = "В сундук: %s ×%d" % [_block_name(item_id), backpack_amount]
    elif chest_amount > 0:
        inventory[item_id] = backpack_amount + chest_amount
        storage_inventory[item_id] = 0
        generated_message = "Из сундука: %s ×%d" % [_block_name(item_id), chest_amount]
    _refresh_storage_panel()
    _refresh_inventory_panel()

func _close_storage() -> void:
    storage_open = false

func _has_nearby_chest() -> bool:
    if not is_instance_valid(player):
        return false
    var center := Vector3i(floori(player.global_position.x), floori(player.global_position.y), floori(player.global_position.z))
    for x in range(center.x - 2, center.x + 3):
        for y in range(center.y - 2, center.y + 3):
            for z in range(center.z - 2, center.z + 3):
                if _get_block(Vector3i(x, y, z)) == CHEST:
                    return true
    return false

func _toggle_storage_nearby() -> void:
    if not is_instance_valid(player):
        return
    var center := Vector3i(floori(player.global_position.x), floori(player.global_position.y), floori(player.global_position.z))
    var nearest := Vector3i.ZERO
    var nearest_distance := 4.0
    for x in range(center.x - 2, center.x + 3):
        for y in range(center.y - 2, center.y + 3):
            for z in range(center.z - 2, center.z + 3):
                var cell := Vector3i(x, y, z)
                if _get_block(cell) == CHEST:
                    var distance := player.global_position.distance_to(Vector3(cell) + Vector3(0.5, 0.5, 0.5))
                    if distance < nearest_distance:
                        nearest = cell
                        nearest_distance = distance
    if nearest_distance >= 4.0:
        generated_message = "Сундук не найден: поставь блок хранения"
        return
    active_chest = nearest
    storage_open = not storage_open
    inventory_open = false
    guide_open = false
    settings_open = false
    if storage_inventory.is_empty():
        _init_storage_inventory()
    _claim_structure_loot(active_chest)

func _refresh_inventory_panel() -> void:
    if not is_instance_valid(inventory_panel):
        return
    _apply_inventory_search()
    for index in inventory_item_ids.size():
        if index >= inventory_slots.size():
            continue
        var item_id := inventory_item_ids[index]
        var slot := inventory_slots[index]
        var item_count := int(inventory.get(item_id, 0))
        slot.text = str(item_count) if item_count > 0 else ""
        slot.tooltip_text = "%s ×%d" % [_block_name(item_id), item_count]
        var icon_rect := slot.get_node_or_null("Icon") as TextureRect
        if is_instance_valid(icon_rect):
            icon_rect.modulate = Color.WHITE
            icon_rect.texture = _inventory_icon_texture(item_id)
    for tool_index in tool_names.size():
        var button_index := inventory_item_ids.size() + tool_index
        if button_index < inventory_slots.size():
            inventory_slots[button_index].text = "\n\n%s\n%d/%d" % [tool_names[tool_index], tool_durability[tool_index], tool_max_durability[tool_index]]
            inventory_slots[button_index].modulate = Color("ffffff") if equipped_tool == tool_index else Color("9aa6b6")
    if is_instance_valid(armor_button):
        armor_button.text = "Соляная броня: %s  |  прочность %d/80  |  N — переключить" % ["ЭКИПИРОВАНА" if player.armor_equipped else "в рюкзаке", player.armor_durability]

func _on_inventory_search_changed(_query: String) -> void:
    _apply_inventory_search()

func _on_inventory_category_changed(_index: int) -> void:
    _apply_inventory_search()

func _creative_category_matches(item_id: int) -> bool:
    if not is_instance_valid(inventory_category_select) or inventory_category_select.selected == 0:
        return true
    var category := inventory_category_select.get_item_text(inventory_category_select.selected)
    if category == "Строительство":
        return [GRASS, DIRT, STONE, WOOD, LEAVES, GLOW, SAND, SNOW, CRYSTAL, ASH, MOSS, SALT_CRUST, EMBER, COSMIC_STONE, WHISPER_SOIL, WHISPER_BARK, WATER, ASH_FLUID].has(item_id) or ore_definitions.has(item_id)
    if category == "Декор":
        return [GLOW, ECHO_LANTERN, CHEST, FURNITURE_CRATE, FURNITURE_TABLE, FURNITURE_LAMP].has(item_id)
    if category == "Ресурсы":
        return ore_definitions.has(item_id) or ore_raw_definitions.has(item_id) or ore_ingot_definitions.has(item_id) or [FIBER, ECHO_SHARD, SALT_CRYSTAL, DEEP_CRYSTAL, STAR_DUST, ASTRAL_METAL, ASTRAL_SCRAP, COSMIC_ICE, VOID_SHARD, ANTIMATTER, NEBULA_GAS, WHISPER_SHARD].has(item_id)
    if category == "Технология":
        return [WORKBENCH, FURNACE, STOVE, AUTOMATION_FORGE, ARCANE_CONDUIT, CARGO_RAIL].has(item_id)
    if category == "Кухня":
        return [FOOD, COOKED_FOOD, STOVE, WATER].has(item_id)
    if category == "Оружие":
        return [ARMOR, BOLT, TRAP, WORKBENCH].has(item_id)
    if category == "Магия":
        return [ARCANE_CRYSTAL, ARCANE_CONDUIT, ASTRAL_CRYSTAL, STAR_DUST, VOID_SHARD, ECHO_LANTERN, WHISPER_SHARD, ANTIMATTER].has(item_id)
    return true

func _apply_inventory_search() -> void:
    if not is_instance_valid(inventory_search):
        return
    var query := inventory_search.text.strip_edges().to_lower()
    for index in inventory_item_ids.size():
        if index >= inventory_slots.size():
            continue
        var slot := inventory_slots[index]
        var item_id := inventory_item_ids[index]
        var item_name := _block_name(item_id).to_lower()
        slot.visible = _creative_category_matches(item_id) and (query.is_empty() or item_name.contains(query))

func _inventory_icon_texture(id: int) -> Texture2D:
    if not is_instance_valid(inventory_icon_atlas):
        return null
    var icon_index := absi(id) % 32
    if ore_definitions.has(id) or ore_raw_definitions.has(id) or ore_ingot_definitions.has(id):
        icon_index = 26 + absi(id) % 6
    else:
        match id:
            GRASS: icon_index = 0
            DIRT: icon_index = 1
            STONE: icon_index = 2
            WOOD, PLANKS, FURNITURE_CRATE: icon_index = 3
            LEAVES: icon_index = 4
            SAND: icon_index = 5
            SNOW: icon_index = 6
            WATER: icon_index = 7
            FOOD: icon_index = 9
            COOKED_FOOD: icon_index = 10
            STICK: icon_index = 11
            BOLT: icon_index = 12
            WORKBENCH, FURNITURE_TABLE, FURNITURE_LAMP: icon_index = 14
            CRYSTAL, DEEP_CRYSTAL, ARCANE_CRYSTAL: icon_index = 15
            STAR_DUST, ASTRAL_CRYSTAL, VOID_SHARD, ECHO_SHARD: icon_index = 16
            AUTOMATION_FORGE, ARCANE_CONDUIT: icon_index = 19
            CARGO_RAIL: icon_index = 22
            _: pass
    var atlas_texture := AtlasTexture.new()
    atlas_texture.atlas = inventory_icon_atlas
    atlas_texture.region = Rect2(float(icon_index % 8) * 32.0, float(icon_index / 8) * 32.0, 32.0, 32.0)
    return atlas_texture

func _texture_path_for_item(id: int) -> String:
    var base := "res://assets/ui_standard/assets/ui/"
    if ore_definitions.has(id) or ore_raw_definitions.has(id) or ore_ingot_definitions.has(id):
        return base + "icons_gear.png"
    match id:
        FOOD: return base + "icons_apple.png"
        COOKED_FOOD: return base + "icons_bread.png"
        STONE: return base + "icons_pickaxe.png"
        IRON_ORE, GOLD_ORE: return base + "icons_gear.png"
        BOLT: return base + "icons_knife.png"
        STICK: return base + "icons_pan.png"
        WORKBENCH: return base + "inventory.png"
        _: return ""

func _on_inventory_slot_pressed(index: int) -> void:
    if index < 0 or index >= inventory_item_ids.size():
        return
    var item_id := inventory_item_ids[index]
    if item_id == FOOD:
        _eat_food()
    elif item_id != ASH:
        selected_block = item_id
        generated_message = "Выбран материал: %s" % _block_name(item_id)
    _refresh_inventory_panel()

func _on_tool_pressed(tool_index: int) -> void:
    if tool_index < 0 or tool_index >= tool_names.size():
        return
    equipped_tool = tool_index
    generated_message = "Экипирован: %s" % tool_names[tool_index]
    _refresh_inventory_panel()

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(2)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    return style

func _create_guide_panel(layer: CanvasLayer) -> void:
    guide_panel = Panel.new()
    guide_panel.name = "FirstEntryGuide"
    guide_panel.position = Vector2(180.0, 110.0)
    guide_panel.size = Vector2(920.0, 480.0)
    guide_panel.add_theme_stylebox_override("panel", _panel_style(Color("101b2a"), Color("d19a58")))
    guide_panel.visible = false
    layer.add_child(guide_panel)

    var title := Label.new()
    title.position = Vector2(28.0, 20.0)
    title.text = "ПЕРВЫЙ ВЫХОД: ПУТЕВОДИТЕЛЬ WORLD FORGE"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("f4d08a"))
    guide_panel.add_child(title)

    var guide_scroll := ScrollContainer.new()
    guide_scroll.position = Vector2(30.0, 72.0)
    guide_scroll.size = Vector2(850.0, 302.0)
    guide_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    var content := Label.new()
    content.custom_minimum_size = Vector2(820.0, 640.0)
    content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.text = "Добро пожаловать в Пепельный Рубеж · VoxelVerse. Это offline-first voxel-экспедиция: сначала собери ресурсы, сделай безопасное укрытие и запомни точку возвращения.\n\nУПРАВЛЕНИЕ\nWASD/стрелки — движение, SPACE — прыжок, Shift — бег, ЛКМ/Q — ломать, ПКМ/R — ставить, X — ближняя атака, V — болт, T — разговор, Y — смена доступного измерения, I — инвентарь, O — сундук, J — правила, F5 — сохранить, F9 — загрузить. На телефоне левый джойстик отвечает за движение, правая область — за обзор, tap-to-break и mobile attack работают через touch controls.\n\nПЕРВЫЕ ШАГИ\nДобудь дерево, камень и волокно. Сделай доски, палки, верстак и очаг. Еда поддерживает здоровье и hunger; вода и отдых важны для thirst/energy. Armor снижает урон, но имеет durability. Если One-Life выключен, Enter возвращает к respawn point; в hardcore смерть заканчивает маршрут.\n\nМИР И ДОБЫЧА\nВ мире загружены 51 biome/region definition, включая леса, пустыни, тундры, болота, редкие аномалии, Whisper Valley и Astral Expanse. В глубине ищи 30 common и 20 rare ore families. Руда ломается подходящим инструментом, выпадает как raw material и переплавляется в ingot через station recipe. Редкие структуры — shrine, tower, mine, temple, trial, gate, arena и ruins — имеют deterministic one-time loot.\n\nАСТРАЛЬНЫЙ ПРОСТОР И ОПАСНОСТИ\nAstral Expanse содержит звёздные равнины, туманностные поля, астероидные поля, чёрные карманы и кристаллические пояса. Там нужен oxygen/astral barrier, radiation постепенно опасна, а редкие ресурсы включают astral metal, cosmic ice, void shard, nebula gas, antimatter и star dust. Whisper/ash/frost/hazard регионы меняют риск через debuffs, weather и урон, а не через сексуализированный контент.\n\nКРАФТ, MAGIC И МАШИНЫ\nI открывает поиск предметов и creative catalog. Recipe definitions проходят валидацию. F4 запускает доступный spell с mana/cooldown; current spell slice включает healing focus, arcane lance и blink. Automation Forge обрабатывает Deep Crystal + Star Dust, а Cargo Rail переносит output в соседний chest. Fluids spread only inside bounded active chunks, поэтому simulation не должна бесконечно расходовать память.\n\nCREATIVE И КОМАНДЫ\nВ Creative Test доступны flight, invulnerability, отсутствие survival drain и registry items. Команды: /give ID amount, /clear, /tp X Y Z, /time day|night, /weather clear|rain|ash|frost, /difficulty calm|standard|severe|ironbound, /dimension surface|echo|astral и /save. В online сервер должен проверять inventory, block edits, permissions и combat; локальная команда не даёт права на чужом сервере.\n\nСОХРАНЕНИЯ И ONLINE\nСохранение включает seed, world rules, chunks, inventory, storage, player survival/mana, effects, achievements, claims, structures and transport counters. Voice включается только добровольно, через permission и push-to-talk; mute используй для любого unwanted audio. Friend code/LAN/dedicated ENet foundation проверяется локально, но public relay, matchmaking, NAT traversal, production voice relay and iOS build требуют отдельных platform gates."
    content.add_theme_font_size_override("font_size", 16)
    content.add_theme_color_override("font_color", Color("d9e6f2"))
    guide_scroll.add_child(content)
    guide_panel.add_child(guide_scroll)

    var close_button := Button.new()
    close_button.position = Vector2(30.0, 405.0)
    close_button.size = Vector2(260.0, 44.0)
    close_button.text = "ПОНЯТНО — ВОЙТИ В МИР"
    close_button.add_theme_font_size_override("font_size", 16)
    close_button.pressed.connect(_close_guide)
    guide_panel.add_child(close_button)

func _create_settings_panel(layer: CanvasLayer) -> void:
    settings_panel = Panel.new()
    settings_panel.name = "WorldForgeSettings"
    settings_panel.position = Vector2(210.0, 125.0)
    settings_panel.size = Vector2(860.0, 430.0)
    settings_panel.add_theme_stylebox_override("panel", _panel_style(Color("101b2a"), Color("557da1")))
    settings_panel.visible = false
    layer.add_child(settings_panel)

    var title := Label.new()
    title.position = Vector2(28.0, 20.0)
    title.text = "WORLD FORGE — ПРАВИЛА ЭКСПЕДИЦИИ"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("f4d08a"))
    settings_panel.add_child(title)

    var description := Label.new()
    description.position = Vector2(30.0, 68.0)
    description.text = "Выбирай правила до следующего сохранения. Изменения применяются сразу к урону и возрождению."
    description.add_theme_font_size_override("font_size", 16)
    description.add_theme_color_override("font_color", Color("d9e6f2"))
    settings_panel.add_child(description)

    var difficulty_title := Label.new()
    difficulty_title.position = Vector2(30.0, 118.0)
    difficulty_title.text = "СЛОЖНОСТЬ"
    difficulty_title.add_theme_font_size_override("font_size", 16)
    difficulty_title.add_theme_color_override("font_color", Color("c3c9ff"))
    settings_panel.add_child(difficulty_title)

    var modes := ["calm", "standard", "severe", "ironbound"]
    var mode_names := ["СПОКОЙНО", "СТАНДАРТ", "СУРОВО", "ЖЕЛЕЗНАЯ ВОЛЯ"]
    for mode_index in modes.size():
        var mode_button := Button.new()
        mode_button.position = Vector2(30.0 + mode_index * 200.0, 155.0)
        mode_button.size = Vector2(185.0, 54.0)
        mode_button.text = mode_names[mode_index]
        mode_button.add_theme_font_size_override("font_size", 14)
        mode_button.pressed.connect(_set_difficulty.bind(modes[mode_index]))
        settings_panel.add_child(mode_button)

    var hardcore_button := Button.new()
    hardcore_button.position = Vector2(30.0, 245.0)
    hardcore_button.size = Vector2(385.0, 48.0)
    hardcore_button.text = "H — ONE-LIFE"
    hardcore_button.add_theme_font_size_override("font_size", 15)
    hardcore_button.pressed.connect(_toggle_hardcore)
    settings_panel.add_child(hardcore_button)

    var save_button := Button.new()
    save_button.position = Vector2(445.0, 245.0)
    save_button.size = Vector2(385.0, 48.0)
    save_button.text = "СОХРАНИТЬ ПРАВИЛА И МИР"
    save_button.add_theme_font_size_override("font_size", 15)
    save_button.pressed.connect(_save_world)
    settings_panel.add_child(save_button)

    var close_button := Button.new()
    close_button.position = Vector2(30.0, 345.0)
    close_button.size = Vector2(260.0, 42.0)
    close_button.text = "ЗАКРЫТЬ — J"
    close_button.add_theme_font_size_override("font_size", 15)
    close_button.pressed.connect(_toggle_settings)
    settings_panel.add_child(close_button)

func _toggle_guide() -> void:
    guide_open = not guide_open
    if guide_open:
        inventory_open = false
        settings_open = false
    else:
        _close_guide()

func _close_guide() -> void:
    guide_open = false
    var file := FileAccess.open("user://voxelverse_guide_seen.flag", FileAccess.WRITE)
    if file != null:
        file.store_string("seen")
        file.close()

func _toggle_settings() -> void:
    settings_open = not settings_open
    if settings_open:
        inventory_open = false
        guide_open = false

func _set_difficulty(mode: String) -> void:
    difficulty_mode = mode
    if is_instance_valid(player):
        player.difficulty = mode
    generated_message = "Сложность изменена: %s" % _difficulty_name()

func _update_hud() -> void:
    if not is_instance_valid(compact_selection_label):
        return
    var block_name := _block_name(selected_block)
    compact_selection_label.text = "%s   ·   %s" % [block_name, tool_names[equipped_tool]]
    compact_hotbar_label.text = "1     2     3     4     5     6     7     8"
    
    if is_instance_valid(player):
        health_label.text = "HP %d/%d" % [int(player.health), int(player.MAX_HEALTH)]
        hunger_label.text = "FOOD %d/%d" % [int(player.hunger), int(player.MAX_HUNGER)]
        thirst_label.text = "WATER %d/%d" % [int(player.thirst), int(player.MAX_THIRST)]
        energy_label.text = "ENERGY %d/%d" % [int(player.energy), int(player.MAX_ENERGY)]
        
        health_label.modulate = Color.RED if player.health < 6.0 else Color.WHITE
        hunger_label.modulate = Color.ORANGE if player.hunger < 6.0 else Color.WHITE
        thirst_label.modulate = Color.AQUA if player.thirst < 6.0 else Color.WHITE
        energy_label.modulate = Color.YELLOW if player.energy < 6.0 else Color.WHITE
        compact_hp_bar.value = clampf(player.health / player.MAX_HEALTH * 100.0, 0.0, 100.0)
        compact_hunger_bar.value = clampf(player.hunger / player.MAX_HUNGER * 100.0, 0.0, 100.0)
        compact_thirst_bar.value = clampf(player.thirst / player.MAX_THIRST * 100.0, 0.0, 100.0)
        compact_energy_bar.value = clampf(player.energy / player.MAX_ENERGY * 100.0, 0.0, 100.0)
        compact_mana_bar.value = clampf(player.mana / player.MAX_MANA * 100.0, 0.0, 100.0)
        compact_mana_label.text = "МАНА %d/%d" % [int(player.mana), int(player.MAX_MANA)]

    if is_instance_valid(biome_label) and is_instance_valid(player):
        var current_biome := _player_biome()
        if current_biome == BIOME_ASTRAL:
            current_biome += " · " + _astral_subregion(floori(player.position.x), floori(player.position.z))
        biome_label.text = "Регион: %s   |   Координаты: X:%d Y:%d Z:%d" % [current_biome, int(player.position.x), int(player.position.y), int(player.position.z)]
    if is_instance_valid(quest_label):
        var ach_count := 0
        for a in achievements: if achievements[a]: ach_count += 1
        quest_label.text = "%s   |   Достижения: %d/5" % [_quest_text(), ach_count]
    if is_instance_valid(rules_label):
        rules_label.text = "Режим: %s   |   Сложность: %s   |   One-Life: %s   |   Световой цикл: %s" % [world_mode, _difficulty_name(), "ВКЛ" if hardcore_mode else "ВЫКЛ", "ВКЛ" if day_night_enabled else "ВЫКЛ"]
    if is_instance_valid(weather_label):
        weather_label.text = "Погода: %s  |  L — сменить" % _weather_name()
    if is_instance_valid(npc_label):
        npc_label.text = "NPC: рядом — T разговор · Y обмен" if _has_nearby_npc() else "NPC: аванпост x14 z13"
    if is_instance_valid(dimension_label):
        var dimension_name := "Астральный Простор" if dimension_mode == "astral_expanse" else ("Эхо-глубина" if dimension_mode == "echo_depth" else "Поверхность")
        dimension_label.text = "Измерение: %s  |  Y у ворот" % dimension_name
    if is_instance_valid(storage_hint_label):
        storage_hint_label.text = "Сундук: рядом — O для хранилища" if _has_nearby_chest() else "Сундуки: O рядом с блоком хранения"
    if is_instance_valid(ranged_hint_label):
        ranged_hint_label.text = "Болты: %d  |  V для выстрела" % int(inventory.get(BOLT, 0))
        if dimension_mode == "astral_expanse":
            ranged_hint_label.text += "  |  O2:%d%% Rad:%d%%" % [int(astral_oxygen), int(astral_radiation)]
    if is_instance_valid(boss_label):
        if boss_defeated:
            boss_label.text = "Эхо-Владыка: повержен"
        elif is_instance_valid(boss):
            boss_label.text = "Эхо-Владыка: %d/40 HP  ·  Логово: x22 z24" % int(round(boss.health))
        else:
            boss_label.text = "Эхо-Владыка: логово ждёт в Кристальном разломе"
    
    var inventory_query := inventory_search.text if is_instance_valid(inventory_search) else ""
    var inventory_category := inventory_category_select.selected if is_instance_valid(inventory_category_select) else -1
    var inventory_signature := "%s|%s|%s|%d|%d" % [inventory_open, storage_open, inventory_query, inventory_category, inventory_revision]
    if is_instance_valid(inventory_panel):
        inventory_panel.visible = inventory_open and not guide_open and not settings_open and not storage_open
        if inventory_signature != _last_inventory_signature:
            _refresh_inventory_panel()
            _last_inventory_signature = inventory_signature
    var storage_signature := "%s|%d|%d|%d" % [storage_open, active_chest.x, active_chest.z, transport_delivery_count]
    if is_instance_valid(storage_panel):
        storage_panel.visible = storage_open and not guide_open and not settings_open
        if storage_signature != _last_storage_signature:
            _refresh_storage_panel()
            _last_storage_signature = storage_signature
    if is_instance_valid(guide_panel):
        guide_panel.visible = guide_open
    if is_instance_valid(settings_panel):
        settings_panel.visible = settings_open
    var modal_open := guide_open or settings_open or inventory_open or storage_open
    if is_instance_valid(compact_panel):
        compact_panel.visible = not modal_open and touch_layout == "Классический экран"
    if is_instance_valid(compact_selection_label):
        compact_selection_label.visible = false
    if is_instance_valid(crosshair_label):
        crosshair_label.visible = not modal_open
    if is_instance_valid(compact_hotbar_label):
        compact_hotbar_label.visible = false
    if is_instance_valid(compact_mana_bar):
        compact_mana_bar.visible = not modal_open and touch_layout == "Классический экран"
    if is_instance_valid(compact_mana_label):
        compact_mana_label.visible = false
    if is_instance_valid(mobile_overlay):
        var available_hotbar: Array[int] = get_hotbar_items()
        var selected_slot: int = maxi(0, available_hotbar.find(selected_block))
        var health_bucket := int(player.health) if is_instance_valid(player) else -1
        var hunger_bucket := int(player.hunger) if is_instance_valid(player) else -1
        var hotbar_signature := ",".join(PackedStringArray(available_hotbar.map(func(item_id: int) -> String: return str(item_id))) )
        var overlay_signature := "%d|%d|%d|%s|%s" % [selected_slot, health_bucket, hunger_bucket, modal_open, hotbar_signature]
        if overlay_signature != _last_overlay_signature:
            mobile_overlay.visible = not modal_open
            mobile_overlay.call("set_selected_slot", selected_slot)
            if mobile_overlay.has_method("set_hotbar_items"):
                mobile_overlay.call("set_hotbar_items", available_hotbar)
            if is_instance_valid(player) and mobile_overlay.has_method("set_survival_values"):
                mobile_overlay.call("set_survival_values", player.health, player.MAX_HEALTH, player.hunger, player.MAX_HUNGER)
            _last_overlay_signature = overlay_signature
    for overlay_label in [health_label, hunger_label, thirst_label, energy_label, biome_label, quest_label, rules_label, boss_label, weather_label, npc_label, dimension_label, storage_hint_label, ranged_hint_label, hotbar_label, target_label, status_label]:
        if is_instance_valid(overlay_label):
            overlay_label.visible = false
    if is_instance_valid(boss_label):
        boss_label.visible = false
    if is_instance_valid(npc_label):
        npc_label.visible = false
    if is_instance_valid(storage_hint_label):
        storage_hint_label.visible = false
    if is_instance_valid(ranged_hint_label):
        ranged_hint_label.visible = false
    if is_instance_valid(death_label) and is_instance_valid(player):
        death_label.visible = player.dead and not modal_open
        if player.dead:
            death_label.text = "Ты погиб. Нажми Enter для возрождения" if not player.hardcore else "Ты погиб в режиме One-Life"
    target_label.visible = false
    if target_valid:
        target_label.text = "Цель: %s  %s" % [_block_name(_get_block(target_cell)), target_cell]
    else:
        target_label.text = ""

func _quest_text() -> String:
    match quest_stage:
        0:
            return "Задача 1: добудь 3 блока (%d/3)" % mini(blocks_broken, 3)
        1:
            return "Задача 2: найди Кристальный разлом"
        2:
            return "Задача 3: войди в Пустошь Эха"
        3:
            return "Задача 4: победи EchoCrawler (%d/1)" % mini(mobs_defeated, 1)
        4:
            return "Задача 5: очисти логово и победи Эхо-Владыку"
        _:
            return "Экспедиция завершена: награда получена"

func _quest_objective_progress(definition: Dictionary) -> int:
    var objective: Dictionary = definition.get("objective", {})
    var objective_type := str(objective.get("type", ""))
    var target := maxi(1, int(objective.get("target", 1)))
    match objective_type:
        "blocks_broken":
            return mini(blocks_broken, target)
        "biome_visit":
            return target if _player_biome() == str(objective.get("biome", "")) else 0
        "mob_defeated":
            return mini(int(mob_defeat_counts.get(str(objective.get("mob_kind", "")), 0)), target)
        "boss_defeated":
            return mini(int(boss_defeat_counts.get(str(objective.get("boss_kind", "")), 0)), target)
        "npc_talk":
            return mini(int(npc_talk_counts.get(str(objective.get("npc_id", "")), 0)), target)
        _:
            return 0

func _update_data_quests() -> void:
    for definition in quest_definitions:
        var quest_id := str(definition.get("id", ""))
        if quest_id.is_empty() or bool(quest_completed.get(quest_id, false)):
            continue
        var progress := _quest_objective_progress(definition)
        quest_progress[quest_id] = progress
        var objective: Dictionary = definition.get("objective", {})
        var target := maxi(1, int(objective.get("target", 1)))
        if progress < target:
            break
        quest_completed[quest_id] = true
        var flags: Array = definition.get("hidden_flags", [])
        for flag_variant in flags:
            quest_flags[str(flag_variant)] = true
        var reward: Dictionary = definition.get("reward", {})
        var reward_item := int(reward.get("item_id", -1))
        var reward_count := int(reward.get("count", 0))
        if reward_item >= 0 and reward_count > 0:
            inventory[reward_item] = int(inventory.get(reward_item, 0)) + reward_count
        generated_message = "Квест выполнен: %s · +%d %s" % [str(definition.get("title", quest_id)), reward_count, _name_for_block(reward_item)]
        _refresh_inventory_panel()
        break

func _update_quests() -> void:
    _update_data_quests()
    if quest_stage == 0 and blocks_broken >= 3:
        quest_stage = 1
        generated_message = "Новая задача: найди Кристальный разлом"
    if quest_stage == 1 and is_instance_valid(player) and _player_biome() == BIOME_RIFT:
        quest_stage = 2
        generated_message = "Новая задача: войди в Пустошь Эха"
    if quest_stage == 2 and is_instance_valid(player) and _player_biome() == BIOME_ECHO:
        quest_stage = 3
        generated_message = "Новая задача: победи EchoCrawler"
    if quest_stage == 3 and mobs_defeated >= 1:
        quest_stage = 4
        generated_message = "Новая задача: очисти логово и победи Эхо-Владыку"
    if quest_stage == 4 and boss_defeated:
        quest_stage = 5
        generated_message = "Экспедиция завершена: Эхо-Владыка повержен"
    _update_data_quests()

func _update_horror_encounters(delta: float) -> void:
    for encounter_id_variant in active_horror_cooldowns.keys():
        var encounter_id := str(encounter_id_variant)
        active_horror_cooldowns[encounter_id] = maxf(0.0, float(active_horror_cooldowns[encounter_id]) - delta)
    if not is_instance_valid(player) or horror_definitions.is_empty():
        return
    var current_biome := _player_biome()
    var current_dimension := dimension_mode
    var current_weather := weather_state
    if horror_last_biome.is_empty():
        horror_last_biome = current_biome
        horror_last_dimension = current_dimension
        horror_last_weather = current_weather
        return
    var biome_entered := current_biome != horror_last_biome
    var dimension_entered := current_dimension != horror_last_dimension
    var weather_changed := current_weather != horror_last_weather
    for encounter_variant in horror_definitions:
        var encounter: Dictionary = encounter_variant
        var encounter_id := str(encounter.get("id", ""))
        if float(active_horror_cooldowns.get(encounter_id, 0.0)) > 0.0:
            continue
        var trigger := str(encounter.get("trigger", ""))
        var triggered := false
        if trigger == "biome_enter":
            triggered = biome_entered and current_biome == str(encounter.get("biome", ""))
        elif trigger == "dimension_enter":
            triggered = dimension_entered and current_dimension == str(encounter.get("dimension", ""))
        elif trigger == "weather_change":
            triggered = weather_changed and current_weather == str(encounter.get("weather", ""))
        if not triggered:
            continue
        active_horror_cooldowns[encounter_id] = float(encounter.get("cooldown", 20.0))
        player.apply_fear(float(encounter.get("fear", 0.0)), float(encounter.get("weakness_duration", 0.0)))
        player.apply_whisper_debuff(float(encounter.get("weakness_duration", 0.0)))
        generated_message = str(encounter.get("message", "Опасная аномалия рядом"))
        _spawn_horror_pursuer(str(encounter.get("pursuit_kind", "")))
        break
    horror_last_biome = current_biome
    horror_last_dimension = current_dimension
    horror_last_weather = current_weather

func _spawn_horror_pursuer(kind: String) -> void:
    if kind.is_empty() or not mob_spawn_enabled or not is_instance_valid(player):
        return
    for mob_node in mobs:
        if is_instance_valid(mob_node) and (mob_node as VoxelMob).mob_kind == kind and mob_node.global_position.distance_to(player.global_position) < 12.0:
            return
    var pursuer := VoxelMobScript.new()
    pursuer.name = "HorrorPursuer_%s" % kind
    pursuer.position = player.global_position + Vector3(6.0, 1.0, 4.0)
    pursuer.configure_kind(kind)
    if external_mob_definitions.has(kind):
        pursuer.apply_external_definition(external_mob_definitions[kind])
    pursuer.target = player
    pursuer.world = self
    pursuer.mob_died.connect(_on_mob_died)
    add_child(pursuer)
    mobs.append(pursuer)

func _update_boss_arena() -> void:
    if not is_instance_valid(boss) or boss.defeated:
        return
    var arena: Dictionary = boss_arena_definitions.get(boss.boss_kind, {})
    if arena.is_empty():
        return
    var center: Vector3 = Vector3(arena.get("center", Vector3i.ZERO)) + Vector3(0.5, 0.0, 0.5)
    var radius := float(arena.get("radius", 7.0))
    if boss.global_position.distance_to(center) > radius + 3.0:
        boss.global_position = boss.global_position.move_toward(center, 0.35)
    var health_ratio := clampf(boss.health / maxf(0.1, boss.max_health), 0.0, 1.0)
    var thresholds: Array = arena.get("phase_thresholds", [0.66, 0.33])
    var next_phase := 0
    if health_ratio <= float(thresholds[0]):
        next_phase = 1
    if health_ratio <= float(thresholds[1]):
        next_phase = 2
    if next_phase > boss_arena_phase:
        boss_arena_phase = next_phase
        var messages: Array = arena.get("phase_messages", [])
        if next_phase < messages.size():
            generated_message = str(messages[next_phase])
        boss.attack_damage *= 1.12
        boss.move_speed *= 1.08

func _player_biome() -> String:
    if not is_instance_valid(player):
        return BIOME_MEADOW
    if dimension_mode == "echo_depth":
        return BIOME_ECHO
    if dimension_mode == "astral_expanse":
        return BIOME_ASTRAL
    var player_x := clampi(floori(player.position.x), 0, WORLD_SIZE_X - 1)
    var player_z := clampi(floori(player.position.z), 0, WORLD_SIZE_Z - 1)
    if _is_starter_meadow_cell(player_x, player_z):
        return BIOME_MEADOW
    return _biome_for(player_x, player_z)

func _toggle_dimension() -> void:
    if not is_instance_valid(player):
        return
    var gate_position := Vector3(dungeon_origin) + Vector3(0.5, 1.0, 4.0)
    if dimension_mode == "surface" and player.global_position.distance_to(gate_position) > 5.0:
        generated_message = "Ворота измерений находятся у Кристального логова"
        return
    if dimension_mode == "surface":
        dimension_mode = "echo_depth"
    elif dimension_mode == "echo_depth":
        dimension_mode = "astral_expanse"
        player.position = Vector3(4.0, 9.0, 4.0)
    else:
        dimension_mode = "surface"
        player.position = gate_position
    astral_oxygen = 100.0
    astral_radiation = 0.0
    generated_message = "Переход: %s" % ("Астральный Простор" if dimension_mode == "astral_expanse" else ("Эхо-глубина" if dimension_mode == "echo_depth" else "Поверхность"))

func _cleanup_mobs() -> void:
    var active_mobs: Array[Node3D] = []
    for mob in mobs:
        if is_instance_valid(mob):
            active_mobs.append(mob)
    mobs = active_mobs

func _update_mob_activation() -> void:
    if not is_instance_valid(player):
        return
    for mob_node in mobs:
        if not is_instance_valid(mob_node):
            continue
        var distance := mob_node.global_position.distance_to(player.global_position)
        mob_node.set_physics_process(distance <= mob_simulation_radius)
        mob_node.visible = true
    if is_instance_valid(boss):
        var boss_distance := boss.global_position.distance_to(player.global_position)
        boss.set_physics_process(boss_distance <= mob_simulation_radius)
        boss.visible = true

func _attack_nearby_mob() -> void:
    if not is_instance_valid(player) or player.dead or combat_cooldown > 0.0:
        return
    if NetworkAuthority.is_client_mode():
        var online_target := _find_online_attack_target()
        if online_target.is_empty():
            generated_message = "Удар не достиг цели"
        else:
            NetworkAuthority.send_entity_attack(str(online_target.get("id", "")), 4.0)
            combat_cooldown = 0.28
            generated_message = "Запрос атаки отправлен серверу"
        return
    if is_instance_valid(boss) and player.global_position.distance_to(boss.global_position) <= 4.0:
        var boss_to_target := boss.global_position - player.global_position
        if player.get_view_direction().dot(boss_to_target.normalized()) > 0.15:
            var boss_hit := _apply_boss_weapon_hit(5.0, player.global_position, 0.18, 3.2)
            combat_cooldown = 0.32
            generated_message = "Критический удар по Эхо-Владыке" if bool(boss_hit.get("critical", false)) else "Удар по Эхо-Владыке"
            return
    var best_mob: VoxelMob = null
    var best_distance := 3.2
    for mob_node in mobs:
        if not is_instance_valid(mob_node):
            continue
        var mob := mob_node as VoxelMob
        if mob == null:
            continue
        var to_mob := mob.global_position - player.global_position
        var distance := to_mob.length()
        if distance <= best_distance and distance > 0.1 and player.get_view_direction().dot(to_mob.normalized()) > 0.2:
            best_mob = mob
            best_distance = distance
    if best_mob == null:
        generated_message = "Удар не достиг цели"
        return
    var mob_hit := _apply_mob_weapon_hit(best_mob, 4.0, player.global_position, 0.18, 3.0)
    combat_cooldown = 0.32
    if bool(mob_hit.get("defeated", false)):
        mobs_defeated += 1
        generated_message = "Критическое поражение: %s" % best_mob.mob_kind if bool(mob_hit.get("critical", false)) else "Побеждён: %s" % best_mob.mob_kind
    else:
        generated_message = "Критическое попадание по %s" % best_mob.mob_kind if bool(mob_hit.get("critical", false)) else "Попадание по %s" % best_mob.mob_kind

func _apply_mob_weapon_hit(mob: VoxelMob, base_damage: float, attacker_position: Vector3, critical_chance: float, knockback_force: float) -> Dictionary:
    if not is_instance_valid(mob):
        return {}
    var critical := combat_rng.randf() < clampf(critical_chance, 0.0, 1.0)
    var damage := maxf(0.1, base_damage) * (2.0 if critical else 1.0)
    var away := mob.global_position - attacker_position
    away.y = 0.0
    if away.length_squared() < 0.01:
        away = Vector3.FORWARD
    var impulse := away.normalized() * knockback_force * (1.35 if critical else 1.0)
    impulse.y = 2.8 if critical else 1.7
    mob.take_damage(damage, impulse, critical)
    return {"damage": damage, "critical": critical, "defeated": mob.health <= 0.0}

func _apply_boss_weapon_hit(base_damage: float, attacker_position: Vector3, critical_chance: float, knockback_force: float) -> Dictionary:
    if not is_instance_valid(boss) or boss.defeated:
        return {}
    var critical := combat_rng.randf() < clampf(critical_chance, 0.0, 1.0)
    var damage := maxf(0.1, base_damage) * (2.0 if critical else 1.0)
    var away := boss.global_position - attacker_position
    away.y = 0.0
    if away.length_squared() < 0.01:
        away = Vector3.FORWARD
    var impulse := away.normalized() * knockback_force * (1.2 if critical else 0.8)
    impulse.y = 2.2 if critical else 1.2
    boss.take_damage(damage, impulse, critical)
    return {"damage": damage, "critical": critical, "defeated": boss.health <= 0.0}

func _find_online_attack_target() -> Dictionary:
    var best: Dictionary = {}
    var best_distance := 4.0
    for entity_id_variant in NetworkAuthority.remote_entities.keys():
        var entity_id := str(entity_id_variant)
        var entity: Node3D = NetworkAuthority.remote_entities[entity_id_variant]
        if not is_instance_valid(entity):
            continue
        var distance := player.global_position.distance_to(entity.global_position)
        if distance < best_distance:
            best_distance = distance
            best = {"id": entity_id}
    return best

func _network_apply_player_attack(entity_id: String, damage: float, attacker_position: Vector3) -> Dictionary:
    if entity_id.is_empty() or damage <= 0.0:
        return {}
    var safe_damage := clampf(damage, 1.0, 8.0)
    if is_instance_valid(boss) and not boss.defeated and boss.name == entity_id:
        if attacker_position.distance_to(boss.position) > 5.0:
            return {}
        var boss_hit := _apply_boss_weapon_hit(safe_damage, attacker_position, 0.18, 3.2)
        return {"health": boss.health, "critical": bool(boss_hit.get("critical", false))}
    for mob_variant in mobs:
        var mob := mob_variant as VoxelMob
        if not is_instance_valid(mob) or mob.name != entity_id:
            continue
        if attacker_position.distance_to(mob.position) > 5.0:
            return {}
        var mob_hit := _apply_mob_weapon_hit(mob, safe_damage, attacker_position, 0.18, 3.0)
        return {"health": mob.health, "critical": bool(mob_hit.get("critical", false))}
    return {}

func _day_factor() -> float:
    return clampf((sin(world_time * TAU) + 0.15) / 1.15, 0.0, 1.0)

func _update_day_night(delta: float) -> void:
    if not day_night_enabled or not is_instance_valid(sun_light):
        return
    world_time = fmod(world_time + delta * 0.004, 1.0)
    var daylight := _day_factor()
    sun_light.rotation_degrees = Vector3(-35.0 + sin(world_time * TAU) * 20.0, -35.0 + world_time * 360.0, 0.0)
    sun_light.light_energy = lerpf(0.40, 1.35, daylight)

func _toggle_day_night() -> void:
    day_night_enabled = not day_night_enabled
    generated_message = "Световой цикл: %s" % ("включён" if day_night_enabled else "зафиксирован")

func _weather_name() -> String:
    match weather_state:
        "rain":
            return "Дождь"
        "ash":
            return "Пепельный шторм"
        "frost":
            return "Белая мгла"
        _:
            return "Ясно"

func _cycle_weather() -> void:
    var states := ["clear", "rain", "ash", "frost"]
    var index := states.find(weather_state)
    weather_state = states[(index + 1) % states.size()]
    weather_timer = 35.0
    weather_hazard_timer = 0.0
    generated_message = "Погода: %s" % _weather_name()

func _update_weather(delta: float) -> void:
    weather_timer -= delta
    weather_hazard_timer -= delta
    if weather_timer <= 0.0:
        _cycle_weather()
    if not is_instance_valid(world_environment) or not is_instance_valid(player):
        return
    var environment := world_environment.environment
    match weather_state:
        "rain":
            environment.fog_density = 0.012
            environment.fog_light_energy = 0.42
            environment.fog_light_color = Color("7094a6")
        "ash":
            environment.fog_density = 0.021
            environment.fog_light_energy = 0.3
            environment.fog_light_color = Color("5a465f")
            if _player_biome() == BIOME_ECHO and weather_hazard_timer <= 0.0:
                player.take_damage(0.8, "Пепельный шторм")
                weather_hazard_timer = 7.0
        "frost":
            environment.fog_density = 0.016
            environment.fog_light_energy = 0.45
            environment.fog_light_color = Color("b8d5e2")
            if _player_biome() == BIOME_FROST and weather_hazard_timer <= 0.0:
                player.hunger = maxf(0.0, player.hunger - 0.6)
                player.survival_changed.emit()
                weather_hazard_timer = 8.0
        _:
            environment.fog_density = 0.006
            environment.fog_light_energy = 0.55

func _update_echo_biome(delta: float) -> void:
    if not is_instance_valid(player) or not is_instance_valid(world_environment):
        return
    var current_biome := _player_biome()
    var inside := dimension_mode == "echo_depth" or current_biome == BIOME_ECHO
    if inside and not echo_active:
        echo_active = true
        echo_time = 0.0
        echo_copy_timer = 4.0
        echo_copy_count = 0
        echo_whisper_timer = 2.0
        generated_message = "Пустошь Эха: тишина слушает тебя"
    elif not inside and echo_active:
        echo_active = false
        echo_time = 0.0
        generated_message = "Ты покинул Пустошь Эха"
    if echo_active:
        echo_time += delta
        echo_copy_timer -= delta
        echo_whisper_timer -= delta
        if echo_copy_timer <= 0.0:
            _try_echo_copy()
            echo_copy_timer = 8.0
        world_environment.environment.background_color = Color("160b22")
        world_environment.environment.ambient_light_color = Color("7d587d")
        world_environment.environment.ambient_light_energy = 0.45
        world_environment.environment.fog_light_color = Color("3d244a")
        world_environment.environment.fog_light_energy = 0.35
        world_environment.environment.fog_density = 0.018
        if echo_whisper_timer <= 0.0:
            var whispers := ["Эхо слышит шаги", "не смотри назад", "ты сам пришёл", "мы тебя ждали"]
            generated_message = "Пустошь Эха: «%s»" % whispers[int(echo_time) % whispers.size()]
            echo_whisper_timer = maxf(4.0, 10.0 - echo_time * 0.1)
    else:
        match current_biome:
            BIOME_DUNES:
                world_environment.environment.background_color = Color("d3a86c")
                world_environment.environment.ambient_light_color = Color("f1c98e")
                world_environment.environment.fog_light_color = Color("d6b57f")
            BIOME_FROST:
                world_environment.environment.background_color = Color("8caec6")
                world_environment.environment.ambient_light_color = Color("cfe8f2")
                world_environment.environment.fog_light_color = Color("b9d9e8")
            BIOME_RIFT:
                world_environment.environment.background_color = Color("284b68")
                world_environment.environment.ambient_light_color = Color("9bc9d5")
                world_environment.environment.fog_light_color = Color("5a91a6")
            BIOME_FEN:
                world_environment.environment.background_color = Color("4b7c78")
                world_environment.environment.ambient_light_color = Color("a4d3bd")
                world_environment.environment.fog_light_color = Color("78b4a0")
            BIOME_SALT:
                world_environment.environment.background_color = Color("a9b5bd")
                world_environment.environment.ambient_light_color = Color("e0e1d0")
                world_environment.environment.fog_light_color = Color("c9d0c4")
            BIOME_EMBER:
                world_environment.environment.background_color = Color("6d3029")
                world_environment.environment.ambient_light_color = Color("e1a07b")
                world_environment.environment.fog_light_color = Color("a85642")
            _:
                world_environment.environment.background_color = Color("77a8d6")
                world_environment.environment.ambient_light_color = Color("b7d5ec")
                world_environment.environment.fog_light_color = Color("a6c8d8")
        world_environment.environment.ambient_light_energy = 0.86 + _day_factor() * 0.22
        world_environment.environment.fog_light_energy = 0.72
        world_environment.environment.fog_density = 0.0028

func _try_echo_copy() -> void:
    if not is_instance_valid(player):
        return
    var source_cell := Vector3i(floori(player.position.x), maxi(1, floori(player.position.y) - 1), floori(player.position.z))
    var mirror_offset := Vector3i(3 if echo_copy_count % 2 == 0 else -3, 0, 0)
    var mirror_cell := source_cell + mirror_offset
    if not _inside_world(mirror_cell) or _get_stored_block(source_cell) == AIR or _get_stored_block(mirror_cell) != AIR:
        return
    var source_block := _get_stored_block(source_cell)
    if not _is_placeable_block(source_block):
        return
    _set_runtime_block(mirror_cell, source_block)
    echo_copy_count += 1
    generated_message = "Эхо повторило форму мира"

func _update_special_biomes(delta: float) -> void:
    if not is_instance_valid(player) or not is_instance_valid(world_environment):
        return
    var current_biome := _player_biome()
    if dimension_mode == "astral_expanse":
        player.set_astral_mode(true)
        astral_oxygen = maxf(0.0, astral_oxygen - delta * 0.8)
        astral_radiation = minf(100.0, astral_radiation + delta * 0.35)
        astral_hazard_timer -= delta
        if shaders_enabled:
            world_environment.environment.background_mode = Environment.BG_SKY
            world_environment.environment.sky = astral_sky
        else:
            world_environment.environment.background_mode = Environment.BG_COLOR
            world_environment.environment.sky = null
        world_environment.environment.background_color = Color("080d24")
        world_environment.environment.ambient_light_color = Color("5264b8")
        world_environment.environment.ambient_light_energy = 0.34
        world_environment.environment.fog_light_color = Color("263b82")
        world_environment.environment.fog_density = 0.004
        if astral_hazard_timer <= 0.0:
            if astral_oxygen <= 0.0:
                player.take_damage(1.0, "Разгерметизация")
            if astral_radiation >= 35.0:
                player.take_damage(0.5 + astral_radiation * 0.01, "Радиация")
            astral_hazard_timer = 3.0
    else:
        world_environment.environment.background_mode = Environment.BG_SKY if shaders_enabled else Environment.BG_COLOR
        world_environment.environment.sky = surface_sky if shaders_enabled else null
        player.set_astral_mode(false)
        astral_oxygen = minf(100.0, astral_oxygen + delta * 2.0)
        astral_radiation = maxf(0.0, astral_radiation - delta * 0.25)
        if current_biome == BIOME_WHISPER:
            world_environment.environment.background_color = Color("2b1646")
            world_environment.environment.ambient_light_color = Color("b67cbd")
            world_environment.environment.ambient_light_energy = 0.34
            world_environment.environment.fog_light_color = Color("6f3e79")
            world_environment.environment.fog_density = 0.016

func _update_target() -> void:
    target_valid = false
    if not is_instance_valid(player) or not is_instance_valid(player.camera):
        return
    var origin := player.get_view_origin()
    var end := origin + player.get_view_direction() * MAX_REACH
    var query := PhysicsRayQueryParameters3D.create(origin, end)
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var hit_position: Vector3 = hit["position"]
    target_normal = hit["normal"]
    target_cell = Vector3i(floori(hit_position.x - target_normal.x * 0.01), floori(hit_position.y - target_normal.y * 0.01), floori(hit_position.z - target_normal.z * 0.01))
    target_valid = _get_block(target_cell) != AIR

func _command_ints_valid(parts: PackedStringArray, start_index: int, end_index: int) -> bool:
    if start_index < 0 or end_index >= parts.size():
        return false
    for index in range(start_index, end_index + 1):
        if not parts[index].is_valid_int():
            return false
    return true

func _toggle_command_bar() -> void:
    if not is_instance_valid(command_input):
        return
    command_input.visible = not command_input.visible
    if command_input.visible:
        command_input.grab_focus()
    else:
        command_input.release_focus()

func _execute_command(raw_command: String) -> void:
    if not is_instance_valid(command_input):
        return
    command_input.clear()
    command_input.visible = false
    var command := raw_command.strip_edges()
    if command.begins_with("/"):
        command = command.substr(1)
    var parts := command.split(" ", false)
    if parts.is_empty():
        return
    var verb := parts[0].to_lower()
    if verb == "save":
        _save_world()
        return
    if not (world_mode == "Творческий тест"):
        generated_message = "Команды мира доступны только в Творческом тесте"
        return
    match verb:
        "give":
            if parts.size() < 3 or not parts[1].is_valid_int() or not parts[2].is_valid_int():
                generated_message = "Формат: /give ID количество"
                return
            var item_id := int(parts[1])
            var amount := clampi(int(parts[2]), 1, 999)
            if item_id < 0 or item_id > MAX_CONTENT_ID:
                generated_message = "Неизвестный ID предмета"
                return
            inventory[item_id] = int(inventory.get(item_id, 0)) + amount
            generated_message = "Выдано: %s ×%d" % [_block_name(item_id), amount]
        "clear":
            for item_id in inventory.keys():
                inventory[item_id] = 0
            generated_message = "Рюкзак очищен"
        "setblock":
            if parts.size() < 5 or not _command_ints_valid(parts, 1, 4):
                generated_message = "Формат: /setblock X Y Z ID"
                return
            var set_cell := Vector3i(int(parts[1]), int(parts[2]), int(parts[3]))
            var set_id := int(parts[4])
            if not _inside_world(set_cell) or set_id < AIR or set_id > MAX_BLOCK_ID:
                generated_message = "Координаты или ID вне границ мира"
                return
            _set_runtime_block(set_cell, set_id)
            _rebuild_world_mesh()
            generated_message = "Блок установлен"
        "fill":
            if parts.size() < 8 or not _command_ints_valid(parts, 1, 7):
                generated_message = "Формат: /fill X1 Y1 Z1 X2 Y2 Z2 ID"
                return
            var min_x := mini(int(parts[1]), int(parts[4]))
            var max_x := maxi(int(parts[1]), int(parts[4]))
            var min_y := mini(int(parts[2]), int(parts[5]))
            var max_y := maxi(int(parts[2]), int(parts[5]))
            var min_z := mini(int(parts[3]), int(parts[6]))
            var max_z := maxi(int(parts[3]), int(parts[6]))
            var fill_id := int(parts[7])
            var volume := (max_x - min_x + 1) * (max_y - min_y + 1) * (max_z - min_z + 1)
            if fill_id < AIR or fill_id > MAX_BLOCK_ID or volume <= 0 or volume > 4096:
                generated_message = "Fill превышает границы или лимит 4096 блоков"
                return
            for fill_x in range(min_x, max_x + 1):
                for fill_y in range(min_y, max_y + 1):
                    for fill_z in range(min_z, max_z + 1):
                        var fill_cell := Vector3i(fill_x, fill_y, fill_z)
                        if _inside_world(fill_cell):
                            _set_runtime_block(fill_cell, fill_id)
            _rebuild_world_mesh()
            generated_message = "Область заполнена"
        "tp":
            if parts.size() < 4 or not parts[1].is_valid_float() or not parts[2].is_valid_float() or not parts[3].is_valid_float():
                generated_message = "Формат: /tp X Y Z"
                return
            player.position = Vector3(float(parts[1]), clampf(float(parts[2]), 1.0, WORLD_SIZE_Y + 20.0), float(parts[3]))
            generated_message = "Переход выполнен"
        "time":
            if parts.size() < 2:
                generated_message = "Формат: /time day|night"
                return
            world_time = 0.25 if parts[1].to_lower() == "day" else 0.75
            generated_message = "Время изменено"
        "weather":
            if parts.size() < 2 or not ["clear", "rain", "ash", "frost"].has(parts[1].to_lower()):
                generated_message = "Формат: /weather clear|rain|ash|frost"
                return
            weather_state = parts[1].to_lower()
            weather_timer = 35.0
            generated_message = "Погода изменена: " + weather_state
        "difficulty":
            if parts.size() < 2 or not ["calm", "standard", "severe", "ironbound"].has(parts[1].to_lower()):
                generated_message = "Формат: /difficulty calm|standard|severe|ironbound"
                return
            difficulty_mode = parts[1].to_lower()
            player.difficulty = difficulty_mode
            generated_message = "Сложность изменена"
        "dimension":
            if parts.size() < 2 or not ["surface", "echo", "astral"].has(parts[1].to_lower()):
                generated_message = "Формат: /dimension surface|echo|astral"
                return
            dimension_mode = "echo_depth" if parts[1].to_lower() == "echo" else ("astral_expanse" if parts[1].to_lower() == "astral" else "surface")
            generated_message = "Измерение изменено"
        _:
            generated_message = "Неизвестная команда"
    _refresh_inventory_panel()

func _begin_block_break() -> void:
    if break_active:
        return
    if not target_valid or target_cell.y <= 0:
        return
    if equipped_tool < 0 or equipped_tool >= tool_durability.size() or tool_durability[equipped_tool] <= 0:
        generated_message = "Инструмент сломан: выбери другой"
        return
    break_active = true
    break_progress = 0.0
    break_cell = target_cell
    break_block_type = _get_block(target_cell)
    if world_mode == "Творческий тест" or (is_instance_valid(player) and player.creative_mode):
        break_progress = 1.0
        _complete_block_break()

func _end_block_break() -> void:
    break_active = false
    break_progress = 0.0
    if is_instance_valid(break_progress_bar):
        break_progress_bar.visible = false
        break_progress_bar.value = 0.0

func _update_block_break(delta: float) -> void:
    if not break_active:
        return
    if not target_valid or target_cell != break_cell or _get_block(break_cell) != break_block_type:
        _end_block_break()
        return
    if is_instance_valid(break_progress_bar):
        break_progress_bar.visible = true
    var hardness := _block_break_hardness(break_block_type)
    var speed := _block_break_speed(break_block_type)
    break_progress = minf(1.0, break_progress + delta * speed / hardness)
    if is_instance_valid(break_progress_bar):
        break_progress_bar.value = break_progress * 100.0
    if break_progress >= 1.0:
        _complete_block_break()

func _block_break_hardness(block_type: int) -> float:
    if ore_definitions.has(block_type):
        return 3.8
    match block_type:
        LEAVES, WATER, ASH_FLUID, FIBER:
            return 0.35
        GRASS, DIRT, SAND, SNOW, MOSS, SALT_CRUST:
            return 0.65
        WOOD, PLANKS, WHISPER_BARK, FURNITURE_CRATE, FURNITURE_TABLE:
            return 1.8
        STONE, CHEST, STOVE, WORKBENCH, FURNACE:
            return 2.4
        CRYSTAL, DEEP_CRYSTAL, COSMIC_STONE, ASTRAL_CRYSTAL, ASTRAL_METAL, COSMIC_ICE, VOID_SHARD:
            return 3.8
        ANTIMATTER, ARCANE_CRYSTAL, AUTOMATION_FORGE, ARCANE_CONDUIT:
            return 4.6
        _:
            return 1.2

func _block_break_speed(block_type: int) -> float:
    if world_mode == "Творческий тест" or (is_instance_valid(player) and player.creative_mode):
        return 60.0
    var speed := 0.82
    if equipped_tool == 0:
        if block_type == STONE or block_type == CRYSTAL or block_type == DEEP_CRYSTAL or ore_definitions.has(block_type):
            speed = 1.85
        elif block_type in [DIRT, GRASS, SAND, SNOW, MOSS]:
            speed = 1.15
        elif block_type in [WOOD, PLANKS, WHISPER_BARK]:
            speed = 0.72
    elif equipped_tool == 1:
        if block_type in [SALT_CRUST, ASH, EMBER, ASH_FLUID, WHISPER_SOIL, WHISPER_BARK]:
            speed = 2.05
        elif block_type in [STONE, CRYSTAL, DEEP_CRYSTAL] or ore_definitions.has(block_type):
            speed = 1.22
        elif block_type in [WOOD, PLANKS]:
            speed = 0.68
    if block_type in [LEAVES, WATER, ASH_FLUID]:
        speed = 2.8
    return speed

func _break_target() -> void:
    _begin_block_break()

func _complete_block_break() -> void:
    if not break_active or not target_valid or break_cell.y <= 0:
        _end_block_break()
        return
    var broken_type := _get_block(break_cell)
    if NetworkAuthority.is_client_mode():
        NetworkAuthority.send_block_edit_request(break_cell, AIR, broken_type, -1)
        generated_message = "Запрос разрушения отправлен серверу"
        _end_block_break()
        return
    _set_runtime_block(break_cell, AIR)
    tool_durability[equipped_tool] = maxi(0, tool_durability[equipped_tool] - 1)
    _drop_block_loot(broken_type, break_cell)
    blocks_broken += 1
    if not achievements["first_block"]:
        achievements["first_block"] = true
        generated_message = "Достижение: Первый блок!"
    if blocks_broken >= 3 and quest_stage == 0:
        generated_message = "Квест выполнен: добыто 3 блока"
    _end_block_break()
    _rebuild_world_mesh()

func _drop_block_loot(block_type: int, cell: Vector3i) -> void:
    var drops: Array = []
    match block_type:
        GRASS:
            drops.append([GRASS, 1])
            if (cell.x * 7 + cell.z * 11 + seed_value) % 3 == 0:
                drops.append([FIBER, 1])
        DIRT:
            drops.append([DIRT, 1])
        STONE:
            drops.append([STONE, 1])
        WOOD:
            drops.append([WOOD, 1])
            drops.append([FIBER, 1])
        LEAVES:
            drops.append([LEAVES, 1])
            if (cell.x + cell.z) % 4 == 0:
                drops.append([FOOD, 1])
        SAND:
            drops.append([SAND, 1])
        SNOW:
            drops.append([SNOW, 1])
        CRYSTAL:
            drops.append([CRYSTAL, 1])
            if (cell.x + cell.y + cell.z) % 2 == 0:
                drops.append([SALT_CRYSTAL, 1])
        ASH:
            drops.append([ASH, 1])
            if (cell.x + cell.z) % 2 == 0:
                drops.append([ECHO_SHARD, 1])
        GLOW:
            drops.append([GLOW, 1])
        ECHO_LANTERN:
            drops.append([ECHO_LANTERN, 1])
        CHEST:
            drops.append([CHEST, 1])
        STOVE:
            drops.append([STOVE, 1])
        TRAP:
            drops.append([TRAP, 1])
        DEEP_CRYSTAL:
            drops.append([DEEP_CRYSTAL, 1])
            drops.append([SALT_CRYSTAL, 1])
        COSMIC_STONE:
            drops.append([COSMIC_STONE, 1])
            if (cell.x + cell.z + seed_value) % 3 == 0:
                drops.append([STAR_DUST, 1])
        ASTRAL_METAL:
            drops.append([ASTRAL_METAL, 1])
            if (cell.x * 7 + cell.z * 11 + seed_value) % 5 == 0:
                drops.append([STAR_DUST, 1])
        COSMIC_ICE:
            drops.append([COSMIC_ICE, 1])
        VOID_SHARD:
            drops.append([VOID_SHARD, 1])
            if (cell.x + cell.y + cell.z + seed_value) % 17 == 0:
                drops.append([ANTIMATTER, 1])
        ANTIMATTER:
            drops.append([ANTIMATTER, 1])
        NEBULA_GAS:
            drops.append([NEBULA_GAS, 1])
        FURNITURE_CRATE:
            drops.append([FURNITURE_CRATE, 1])
        FURNITURE_TABLE:
            drops.append([FURNITURE_TABLE, 1])
        FURNITURE_LAMP:
            drops.append([FURNITURE_LAMP, 1])
        WATER:
            drops.append([WATER, 1])
        ASH_FLUID:
            drops.append([ASH_FLUID, 1])
        ARCANE_CRYSTAL:
            drops.append([ARCANE_CRYSTAL, 1])
        ARCANE_CONDUIT:
            drops.append([ARCANE_CONDUIT, 1])
        AUTOMATION_FORGE:
            drops.append([AUTOMATION_FORGE, 1])
        CARGO_RAIL:
            drops.append([CARGO_RAIL, 1])
        ASTRAL_CRYSTAL:
            drops.append([ASTRAL_CRYSTAL, 1])
            drops.append([STAR_DUST, 1])
        WHISPER_SOIL:
            drops.append([WHISPER_SOIL, 1])
            if (cell.x + cell.z) % 3 == 0:
                drops.append([WHISPER_SHARD, 1])
        WHISPER_BARK:
            drops.append([WHISPER_BARK, 1])
        WHISPER_SHARD:
            drops.append([WHISPER_SHARD, 1])
    if ore_definitions.has(block_type):
        var ore_definition: Dictionary = ore_definitions[block_type]
        drops.append([int(ore_definition["raw_id"]), 1])
        if (cell.x * 31 + cell.y * 17 + cell.z * 13 + seed_value) % 100 < 8:
            drops.append([int(ore_definition["raw_id"]), 1])
    for drop in drops:
        _spawn_pickup(int(drop[0]), int(drop[1]), cell)

func _spawn_pickup(item_id: int, amount: int, cell: Vector3i) -> void:
    var pickup := VoxelPickupScript.new()
    pickup.name = "Pickup_%d_%d" % [item_id, pickups.size()]
    pickup.position = Vector3(cell) + Vector3(0.5, 1.15, 0.5)
    pickup.setup(item_id, amount, player, self)
    add_child(pickup)
    pickups.append(pickup)

func _collect_pickup(pickup: VoxelPickup) -> void:
    if not is_instance_valid(pickup):
        return
    var item_id := pickup.item_id
    var amount := pickup.amount
    inventory[item_id] = int(inventory.get(item_id, 0)) + amount
    generated_message = "Подобрано: %s ×%d" % [_block_name(item_id), amount]
    pickup.collect()
    _refresh_inventory_panel()

func _cleanup_pickups() -> void:
    var active_pickups: Array[Node3D] = []
    for pickup in pickups:
        if is_instance_valid(pickup):
            active_pickups.append(pickup)
    pickups = active_pickups

func _cleanup_projectiles() -> void:
    var active_projectiles: Array[Node3D] = []
    for projectile in projectiles:
        if is_instance_valid(projectile):
            active_projectiles.append(projectile)
    projectiles = active_projectiles

func _fire_ranged_tool() -> void:
    if not is_instance_valid(player) or player.dead:
        return
    var bolt_count := int(inventory.get(BOLT, 0))
    if bolt_count <= 0:
        generated_message = "Нет болтов: создай их клавишей U"
        return
    inventory[BOLT] = bolt_count - 1
    var projectile := VoxelProjectileScript.new()
    projectile.setup(player.get_view_origin() + player.get_view_direction() * 0.8, player.get_view_direction(), self)
    add_child(projectile)
    projectiles.append(projectile)
    generated_message = "Арбалетный болт выпущен"

func _projectile_try_hit(projectile: VoxelProjectile) -> bool:
    if not is_instance_valid(projectile):
        return true
    if is_instance_valid(boss) and not boss_defeated and projectile.global_position.distance_to(boss.global_position) <= 1.25:
        var boss_hit := _apply_boss_weapon_hit(projectile.damage, projectile.global_position - projectile.direction * 0.6, projectile.critical_chance, projectile.knockback_force)
        generated_message = "Критический болт попал в Эхо-Владыку" if bool(boss_hit.get("critical", false)) else "Болт попал в Эхо-Владыку"
        return true
    for mob_node in mobs:
        if not is_instance_valid(mob_node):
            continue
        var mob := mob_node as VoxelMob
        if mob != null and projectile.global_position.distance_to(mob.global_position) <= 0.95:
            var mob_hit := _apply_mob_weapon_hit(mob, projectile.damage, projectile.global_position - projectile.direction * 0.6, projectile.critical_chance, projectile.knockback_force)
            generated_message = "Критический болт поразил %s" % mob.mob_kind if bool(mob_hit.get("critical", false)) else "Болт поразил %s" % mob.mob_kind
            return true
    return false

func _update_traps() -> void:
    if traps.is_empty():
        return
    var triggered: Array[Vector3i] = []
    for trap_cell in traps:
        var trap_position := Vector3(trap_cell) + Vector3(0.5, 0.5, 0.5)
        if is_instance_valid(boss) and not boss_defeated and boss.global_position.distance_to(trap_position) <= 1.4:
            boss.take_damage(8.0)
            triggered.append(trap_cell)
            generated_message = "Каменная ловушка сработала на Эхо-Владыке"
            continue
        for mob_node in mobs:
            if not is_instance_valid(mob_node):
                continue
            if mob_node.global_position.distance_to(trap_position) <= 1.25:
                var mob := mob_node as VoxelMob
                if mob != null:
                    mob.take_damage(8.0)
                    generated_message = "Каменная ловушка сработала"
                triggered.append(trap_cell)
                break
    if not triggered.is_empty():
        for trap_cell in triggered:
            traps.erase(trap_cell)
            _set_runtime_block(trap_cell, AIR)
        _rebuild_world_mesh()

func _is_placeable_block(block_id: int) -> bool:
    return [GRASS, DIRT, STONE, WOOD, LEAVES, GLOW, SAND, SNOW, CRYSTAL, ASH, ECHO_LANTERN, MOSS, SALT_CRUST, EMBER, CHEST, STOVE, TRAP, DEEP_CRYSTAL, COSMIC_STONE, ASTRAL_CRYSTAL, ASTRAL_SCRAP, WHISPER_SOIL, WHISPER_BARK, WHISPER_SHARD, ASTRAL_METAL, COSMIC_ICE, VOID_SHARD, ANTIMATTER, NEBULA_GAS, FURNITURE_CRATE, FURNITURE_TABLE, FURNITURE_LAMP, WATER, ASH_FLUID, ARCANE_CRYSTAL, ARCANE_CONDUIT, AUTOMATION_FORGE, CARGO_RAIL].has(block_id) or ore_definitions.has(block_id)

func _place_target() -> void:
    if not target_valid:
        return
    var place_cell := Vector3i(floori(float(target_cell.x) + target_normal.x), floori(float(target_cell.y) + target_normal.y), floori(float(target_cell.z) + target_normal.z))
    if not _inside_world(place_cell) or _get_block(place_cell) != AIR:
        return
    if player.global_position.distance_to(Vector3(place_cell) + Vector3(0.5, 0.5, 0.5)) < 1.5:
        return
    if not _is_placeable_block(selected_block):
        generated_message = "Этот предмет нельзя ставить как блок"
        return
    if NetworkAuthority.is_client_mode():
        NetworkAuthority.send_block_edit_request(place_cell, selected_block, AIR, selected_block)
        generated_message = "Запрос установки отправлен серверу"
        return
    var source_count := int(inventory.get(selected_block, 0))
    var creative := world_mode == "Творческий тест"
    if not creative and source_count <= 0:
        generated_message = "Нет материала: добудь или создай его"
        return
    if not creative:
        inventory[selected_block] = source_count - 1
    if selected_block == TRAP:
        traps.append(place_cell)
    _set_runtime_block(place_cell, selected_block)
    _rebuild_world_mesh()
    _refresh_inventory_panel()

func _should_draw_face(block_type: int, neighbor_type: int) -> bool:
    if block_type == WATER or block_type == ASH_FLUID:
        return neighbor_type == AIR
    if neighbor_type == AIR or neighbor_type == WATER or neighbor_type == ASH_FLUID:
        return true
    return false

func _ensure_chunk_render_roots() -> void:
    if not is_instance_valid(chunk_mesh_root):
        chunk_mesh_root = Node3D.new()
        chunk_mesh_root.name = "VoxelMesh"
        add_child(chunk_mesh_root)
        world_mesh_instance = chunk_mesh_root
    if not is_instance_valid(chunk_water_mesh_root):
        chunk_water_mesh_root = Node3D.new()
        chunk_water_mesh_root.name = "WaterSurfaceMesh"
        add_child(chunk_water_mesh_root)
    if not is_instance_valid(chunk_collision_root):
        chunk_collision_root = Node3D.new()
        chunk_collision_root.name = "VoxelCollision"
        add_child(chunk_collision_root)
        world_body = chunk_collision_root

func _chunk_mesh_instance(key: Vector2i) -> MeshInstance3D:
    _ensure_chunk_render_roots()
    var node := chunk_mesh_instances.get(key) as MeshInstance3D
    if not is_instance_valid(node):
        node = MeshInstance3D.new()
        node.name = "ChunkMesh_%d_%d" % [key.x, key.y]
        chunk_mesh_root.add_child(node)
        chunk_mesh_instances[key] = node
    return node

func _chunk_water_mesh_instance(key: Vector2i) -> MeshInstance3D:
    _ensure_chunk_render_roots()
    var node := chunk_water_mesh_instances.get(key) as MeshInstance3D
    if not is_instance_valid(node):
        node = MeshInstance3D.new()
        node.name = "ChunkWater_%d_%d" % [key.x, key.y]
        chunk_water_mesh_root.add_child(node)
        chunk_water_mesh_instances[key] = node
    return node

func _chunk_collision_body(key: Vector2i) -> StaticBody3D:
    _ensure_chunk_render_roots()
    var body := chunk_collision_bodies.get(key) as StaticBody3D
    if not is_instance_valid(body):
        body = StaticBody3D.new()
        body.name = "ChunkCollision_%d_%d" % [key.x, key.y]
        chunk_collision_root.add_child(body)
        chunk_collision_bodies[key] = body
    return body

func _remove_chunk_render(key: Vector2i) -> void:
    var mesh := chunk_mesh_instances.get(key) as MeshInstance3D
    if is_instance_valid(mesh):
        mesh.queue_free()
    chunk_mesh_instances.erase(key)
    var water_mesh := chunk_water_mesh_instances.get(key) as MeshInstance3D
    if is_instance_valid(water_mesh):
        water_mesh.queue_free()
    chunk_water_mesh_instances.erase(key)
    var body := chunk_collision_bodies.get(key) as StaticBody3D
    if is_instance_valid(body):
        body.queue_free()
    chunk_collision_bodies.erase(key)

func _get_chunk_world_material() -> StandardMaterial3D:
    if chunk_world_material == null:
        chunk_world_material = StandardMaterial3D.new()
        chunk_world_material.vertex_color_use_as_albedo = true
        chunk_world_material.albedo_texture = voxel_atlas_texture
        chunk_world_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        chunk_world_material.cull_mode = BaseMaterial3D.CULL_BACK
        chunk_world_material.roughness = 0.92
        chunk_world_material.metallic = 0.03
        chunk_world_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX if OS.has_feature("mobile") else BaseMaterial3D.SHADING_MODE_PER_PIXEL
    return chunk_world_material

func _get_chunk_water_material() -> ShaderMaterial:
    if chunk_water_material == null:
        chunk_water_material = ShaderMaterial.new()
        chunk_water_material.shader = WaterSurfaceShader
    return chunk_water_material

func _build_chunk_collision_faces(key: Vector2i) -> PackedVector3Array:
    var faces := PackedVector3Array()
    var chunk: Dictionary = chunk_storage.get(key, {})
    for cell_variant in chunk.keys():
        var cell: Vector3i = cell_variant
        for face_index in range(6):
            if _get_block(cell + _face_offset(face_index)) == AIR:
                var base := Vector3(cell)
                var vertices: Array[Vector3] = _face_vertices(face_index)
                faces.append(base + vertices[0])
                faces.append(base + vertices[1])
                faces.append(base + vertices[2])
                faces.append(base + vertices[0])
                faces.append(base + vertices[2])
                faces.append(base + vertices[3])
    return faces

func _rebuild_chunk_mesh(key: Vector2i) -> int:
    if not loaded_chunk_keys.has(key):
        _remove_chunk_render(key)
        return 0
    var chunk: Dictionary = chunk_storage.get(key, {})
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var colors := PackedColorArray()
    var uvs := PackedVector2Array()
    var water_vertices := PackedVector3Array()
    var water_normals := PackedVector3Array()
    var water_colors := PackedColorArray()
    var water_uvs := PackedVector2Array()
    var visible_cells := 0
    for cell_variant in chunk.keys():
        var cell: Vector3i = cell_variant
        var block_type := int(chunk[cell])
        var exposed := false
        for face_index in range(6):
            if _should_draw_face(block_type, _get_block(cell + _face_offset(face_index))):
                exposed = true
                break
        if not exposed:
            continue
        visible_cells += 1
        for face_index in range(6):
            if not _should_draw_face(block_type, _get_block(cell + _face_offset(face_index))):
                continue
            if block_type == WATER or block_type == ASH_FLUID:
                _append_face_arrays(water_vertices, water_normals, water_colors, water_uvs, cell, block_type, face_index)
            else:
                _append_face_arrays(vertices, normals, colors, uvs, cell, block_type, face_index)

    var mesh_instance := _chunk_mesh_instance(key)
    mesh_instance.material_override = _get_chunk_world_material()
    if vertices.is_empty():
        mesh_instance.mesh = null
    else:
        var mesh_arrays: Array = []
        mesh_arrays.resize(Mesh.ARRAY_MAX)
        mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
        mesh_arrays[Mesh.ARRAY_NORMAL] = normals
        mesh_arrays[Mesh.ARRAY_COLOR] = colors
        mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
        var voxel_mesh := ArrayMesh.new()
        voxel_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
        mesh_instance.mesh = voxel_mesh

    var water_mesh_instance_local := _chunk_water_mesh_instance(key)
    water_mesh_instance_local.material_override = _get_chunk_water_material()
    if water_vertices.is_empty():
        water_mesh_instance_local.mesh = null
    else:
        var water_arrays: Array = []
        water_arrays.resize(Mesh.ARRAY_MAX)
        water_arrays[Mesh.ARRAY_VERTEX] = water_vertices
        water_arrays[Mesh.ARRAY_NORMAL] = water_normals
        water_arrays[Mesh.ARRAY_COLOR] = water_colors
        water_arrays[Mesh.ARRAY_TEX_UV] = water_uvs
        var water_mesh := ArrayMesh.new()
        water_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, water_arrays)
        water_mesh_instance_local.mesh = water_mesh

    var body := _chunk_collision_body(key)
    var collision_shape := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
    if not is_instance_valid(collision_shape):
        collision_shape = CollisionShape3D.new()
        collision_shape.name = "CollisionShape3D"
        body.add_child(collision_shape)
    var collision_faces := _build_chunk_collision_faces(key)
    if collision_faces.size() > 0:
        var concave := ConcavePolygonShape3D.new()
        concave.set_faces(collision_faces)
        collision_shape.shape = concave
    else:
        collision_shape.shape = null
    return visible_cells

func _rebuild_world_mesh(force: bool = false) -> void:
    var rebuild_started_usec: int = Time.get_ticks_usec()
    if mesh_rebuild_cooldown > 0.0 and not force:
        mesh_rebuild_deferred = true
        return
    mesh_rebuild_count += 1
    if force or (dirty_chunk_keys.is_empty() and not loaded_chunk_keys.is_empty() and chunk_mesh_instances.is_empty()):
        for loaded_key_variant in loaded_chunk_keys.keys():
            dirty_chunk_keys[loaded_key_variant] = true
    if dirty_chunk_keys.is_empty():
        last_dirty_chunk_count = 0
        last_mesh_rebuild_cells = 0
        last_mesh_rebuild_ms = float(Time.get_ticks_usec() - rebuild_started_usec) / 1000.0
        max_mesh_rebuild_ms = maxf(max_mesh_rebuild_ms, last_mesh_rebuild_ms)
        return
    var rebuild_keys: Array[Vector2i] = []
    for key_variant in dirty_chunk_keys.keys():
        var key: Vector2i = key_variant
        if loaded_chunk_keys.has(key):
            rebuild_keys.append(key)
    dirty_chunk_keys.clear()
    var total_visible_cells := 0
    for key in rebuild_keys:
        total_visible_cells += _rebuild_chunk_mesh(key)
    last_dirty_chunk_count = rebuild_keys.size()
    dirty_chunk_rebuild_count += rebuild_keys.size()
    last_mesh_rebuild_cells = total_visible_cells
    last_mesh_rebuild_ms = float(Time.get_ticks_usec() - rebuild_started_usec) / 1000.0
    max_mesh_rebuild_ms = maxf(max_mesh_rebuild_ms, last_mesh_rebuild_ms)
    mesh_rebuild_cooldown = 0.08

func _build_collision_faces() -> PackedVector3Array:
    var faces := PackedVector3Array()
    for key_variant in loaded_chunk_keys.keys():
        var key: Vector2i = key_variant
        faces.append_array(_build_chunk_collision_faces(key))
    return faces

func _append_face_arrays(vertices_out: PackedVector3Array, normals_out: PackedVector3Array, colors_out: PackedColorArray, uvs_out: PackedVector2Array, cell: Vector3i, block_type: int, face_index: int) -> void:
    var base := Vector3(cell)
    var face_vertices: Array[Vector3] = _face_vertices(face_index)
    var normal := _face_normal(face_index)
    var color := _block_color(block_type)
    if block_type == WOOD and birch_bark_cells.has(cell):
        color = Color(0.78, 0.82, 0.76, 1.0)
    var tile := _texture_tile_for_block(block_type)
    var shade := 1.0
    match face_index:
        0: shade = 1.08
        1: shade = 0.78
        2, 3: shade = 0.96
        4, 5: shade = 0.88
    color = Color(color.r * shade, color.g * shade, color.b * shade, color.a)
    for index in [0, 1, 2, 0, 2, 3]:
        var local_vertex: Vector3 = face_vertices[index]
        vertices_out.append(base + local_vertex)
        normals_out.append(normal)
        colors_out.append(color)
        var atlas_uv := _atlas_uv(tile, local_vertex, face_index)
        uvs_out.append(atlas_uv)

func _texture_tile_for_block(block_type: int) -> Vector2i:
    if ore_definitions.has(block_type):
        return Vector2i(16 + ((block_type - 56) % 16), 0)
    match block_type:
        GRASS: return Vector2i(0, 0)
        DIRT: return Vector2i(1, 0)
        STONE: return Vector2i(2, 0)
        WOOD, PLANKS, FURNITURE_CRATE, FURNITURE_TABLE: return Vector2i(3, 0)
        LEAVES: return Vector2i(4, 0)
        SAND: return Vector2i(5, 0)
        SNOW: return Vector2i(6, 0)
        CRYSTAL: return Vector2i(7, 0)
        ASH, WHISPER_SOIL: return Vector2i(8, 0)
        MOSS: return Vector2i(9, 0)
        WATER: return Vector2i(2, 1)
        ASH_FLUID, EMBER: return Vector2i(3, 1)
        COSMIC_STONE: return Vector2i(4, 1)
        ASTRAL_CRYSTAL: return Vector2i(5, 1)
        DEEP_CRYSTAL: return Vector2i(6, 1)
        ARCANE_CRYSTAL, NEBULA_GAS: return Vector2i(7, 1)
        _ : return Vector2i(7, 3)

func _atlas_uv(tile: Vector2i, local_vertex: Vector3, face_index: int) -> Vector2:
    var local_uv := Vector2(local_vertex.x, 1.0 - local_vertex.y)
    if face_index == 0 or face_index == 1:
        local_uv = Vector2(local_vertex.x, local_vertex.z)
    elif face_index == 2 or face_index == 3:
        local_uv = Vector2(local_vertex.z, 1.0 - local_vertex.y)
    var atlas_x := float(tile.x % 8)
    var atlas_y := float(tile.y + tile.x / 8)
    return Vector2((atlas_x + 0.04 + local_uv.x * 0.92) / 8.0, (atlas_y + 0.04 + local_uv.y * 0.92) / 4.0)

func _face_vertices(face_index: int) -> Array[Vector3]:
    match face_index:
        0:
            return [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)]
        1:
            return [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)]
        2:
            return [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]
        3:
            return [Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1)]
        4:
            return [Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
        _:
            return [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]

func _face_normal(face_index: int) -> Vector3:
    match face_index:
        0:
            return Vector3.UP
        1:
            return Vector3.DOWN
        2:
            return Vector3.RIGHT
        3:
            return Vector3.LEFT
        4:
            return Vector3.FORWARD
        _:
            return Vector3.BACK

func _face_offset(face_index: int) -> Vector3i:
    match face_index:
        0:
            return Vector3i(0, 1, 0)
        1:
            return Vector3i(0, -1, 0)
        2:
            return Vector3i(1, 0, 0)
        3:
            return Vector3i(-1, 0, 0)
        4:
            return Vector3i(0, 0, 1)
        _:
            return Vector3i(0, 0, -1)

func _material_for(block_type: int) -> StandardMaterial3D:
    if materials.has(block_type):
        return materials[block_type]
    var material := StandardMaterial3D.new()
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.roughness = 0.9
    material.albedo_color = _block_color(block_type)
    if block_type == GLOW:
        material.emission_enabled = true
        material.emission = Color("ffd76e")
        material.emission_energy_multiplier = 2.0
    materials[block_type] = material
    return material

func _block_color(block_type: int) -> Color:
    if ore_definitions.has(block_type):
        return Color(str(ore_definitions[block_type].get("color", "ffffff")))
    match block_type:
        GRASS:
            return Color("5aad5f")
        DIRT:
            return Color("805d40")
        STONE:
            return Color("9aa19a")
        WOOD:
            return Color("936746")
        LEAVES:
            return Color("4b9b54")
        GLOW:
            return Color("f2bc53")
        SAND:
            return Color("d6b36a")
        SNOW:
            return Color("d9f2ff")
        CRYSTAL:
            return Color("72d5e8")
        ASH:
            return Color("766d73")
        FOOD:
            return Color("d68c54")
        FIBER:
            return Color("8bbf73")
        ECHO_SHARD:
            return Color("9b5dd1")
        SALT_CRYSTAL:
            return Color("f3e7b2")
        ECHO_LANTERN:
            return Color("b77cf0")
        MOSS:
            return Color("62b879")
        SALT_CRUST:
            return Color("e4d4a0")
        EMBER:
            return Color("d45b3f")
        CHEST:
            return Color("a86f42")
        STOVE:
            return Color("6f7882")
        COOKED_FOOD:
            return Color("d99b52")
        BOLT:
            return Color("f1d384")
        TRAP:
            return Color("b7a16a")
        DEEP_CRYSTAL:
            return Color("a783f2")
        COSMIC_STONE:
            return Color("344b7a")
        STAR_DUST:
            return Color("f2d57b")
        ASTRAL_CRYSTAL:
            return Color("69d9ff")
        ASTRAL_SCRAP:
            return Color("9aa7c5")
        WHISPER_SOIL:
            return Color("4c315f")
        WHISPER_BARK:
            return Color("704265")
        WHISPER_SHARD:
            return Color("d878d6")
        ASTRAL_METAL:
            return Color("8fabc7")
        COSMIC_ICE:
            return Color("9aeaff")
        VOID_SHARD:
            return Color("2a163d")
        ANTIMATTER:
            return Color("f1f4ff")
        NEBULA_GAS:
            return Color("b35cff")
        FURNITURE_CRATE:
            return Color("8a5a3b")
        FURNITURE_TABLE:
            return Color("b47a4d")
        FURNITURE_LAMP:
            return Color("f4cf71")
        WATER:
            return Color("4b94c5")
        ASH_FLUID:
            return Color("9b3f42")
        ARCANE_CRYSTAL:
            return Color("d16bff")
        ARCANE_CONDUIT:
            return Color("7ed7c4")
        AUTOMATION_FORGE:
            return Color("e58b55")
        CARGO_RAIL:
            return Color("52606d")
        ARMOR:
            return Color("b5c8d6")
        _:
            return Color("ffffff")

func _get_block(cell: Vector3i) -> int:
    return int(blocks.get(cell, AIR))

func _inside_world(cell: Vector3i) -> bool:
    return cell.x >= 0 and cell.x < WORLD_SIZE_X and cell.y >= 0 and cell.y < WORLD_SIZE_Y and cell.z >= 0 and cell.z < WORLD_SIZE_Z

func _block_name(block_type: int) -> String:
    if ore_definitions.has(block_type):
        return str(ore_definitions[block_type].get("name", "Руда"))
    if ore_raw_definitions.has(block_type):
        return "Сырьё: " + str(ore_raw_definitions[block_type].get("name", "руда"))
    if ore_ingot_definitions.has(block_type):
        return "Слиток: " + str(ore_ingot_definitions[block_type].get("name", "металл"))
    match block_type:
        GRASS:
            return "Трава"
        DIRT:
            return "Земля"
        STONE:
            return "Камень"
        WOOD:
            return "Дерево"
        LEAVES:
            return "Листья"
        GLOW:
            return "Светящийся блок"
        SAND:
            return "Песок"
        SNOW:
            return "Снег"
        CRYSTAL:
            return "Кристалл разлома"
        ASH:
            return "Эхо-пепел"
        FOOD:
            return "Сухой рацион"
        ARMOR:
            return "Соляная броня"
        FIBER:
            return "Волокно"
        ECHO_SHARD:
            return "Осколок Эха"
        SALT_CRYSTAL:
            return "Солевой кристалл"
        ECHO_LANTERN:
            return "Эхо-фонарь"
        MOSS:
            return "Моховая плита"
        SALT_CRUST:
            return "Солевая корка"
        EMBER:
            return "Эмберовый камень"
        CHEST:
            return "Сундук экспедиции"
        STOVE:
            return "Полевой очаг"
        COOKED_FOOD:
            return "Запечённый рацион"
        BOLT:
            return "Болт"
        TRAP:
            return "Каменная ловушка"
        DEEP_CRYSTAL:
            return "Глубинный кристалл"
        COSMIC_STONE:
            return "Космический камень"
        STAR_DUST:
            return "Звёздная пыль"
        ASTRAL_CRYSTAL:
            return "Астральный кристалл"
        ASTRAL_SCRAP:
            return "Обломок станции"
        WHISPER_SOIL:
            return "Шёпотная почва"
        WHISPER_BARK:
            return "Пульсирующая кора"
        WHISPER_SHARD:
            return "Осколок шёпота"
        ASTRAL_METAL:
            return "Метеоритный металл"
        COSMIC_ICE:
            return "Космический лёд"
        VOID_SHARD:
            return "Осколок пустоты"
        ANTIMATTER:
            return "Нестабильная антиматерия"
        NEBULA_GAS:
            return "Туманностный газ"
        FURNITURE_CRATE:
            return "Грузовой ящик"
        FURNITURE_TABLE:
            return "Полевой стол"
        FURNITURE_LAMP:
            return "Медная лампа"
        WATER:
            return "Чистая вода"
        ASH_FLUID:
            return "Жидкий пепел"
        ARCANE_CRYSTAL:
            return "Арканный кристалл"
        ARCANE_CONDUIT:
            return "Арканный проводник"
        AUTOMATION_FORGE:
            return "Автоматическая кузница"
        CARGO_RAIL:
            return "Грузовой рельс"
        _:
            return "Воздух"

func _cycle_difficulty() -> void:
    var modes := ["calm", "standard", "severe", "ironbound"]
    var index := modes.find(difficulty_mode)
    difficulty_mode = modes[(index + 1) % modes.size()]
    if is_instance_valid(player):
        player.difficulty = difficulty_mode
    generated_message = "Сложность: %s" % _difficulty_name()

func _toggle_hardcore() -> void:
    hardcore_mode = not hardcore_mode
    if is_instance_valid(player):
        player.hardcore = hardcore_mode
    generated_message = "One-Life: %s" % ("включён" if hardcore_mode else "выключен")

func _difficulty_name() -> String:
    match difficulty_mode:
        "calm":
            return "Спокойно"
        "severe":
            return "Сурово"
        "ironbound":
            return "Железная воля"
        _:
            return "Стандарт"

func _craft_bolts() -> void:
    var fiber_count := int(inventory.get(FIBER, 0))
    var stone_count := int(inventory.get(STONE, 0))
    if fiber_count < 2 or stone_count < 1:
        generated_message = "Для 4 болтов нужны 2 волокна и 1 камень"
        return
    inventory[FIBER] = fiber_count - 2
    inventory[STONE] = stone_count - 1
    inventory[BOLT] = int(inventory.get(BOLT, 0)) + 4
    generated_message = "Создано 4 арбалетных болта"

func _craft_trap() -> void:
    var stone_count := int(inventory.get(STONE, 0))
    var fiber_count := int(inventory.get(FIBER, 0))
    if stone_count < 3 or fiber_count < 1:
        generated_message = "Для ловушки нужны 3 камня и 1 волокно"
        return
    inventory[STONE] = stone_count - 3
    inventory[FIBER] = fiber_count - 1
    inventory[TRAP] = int(inventory.get(TRAP, 0)) + 1
    generated_message = "Создана каменная ловушка"

func _craft_chest() -> void:
    var wood_count := int(inventory.get(WOOD, 0))
    var fiber_count := int(inventory.get(FIBER, 0))
    if wood_count < 6 or fiber_count < 2:
        generated_message = "Для сундука нужны 6 дерева и 2 волокна"
        return
    inventory[WOOD] = wood_count - 6
    inventory[FIBER] = fiber_count - 2
    inventory[CHEST] = int(inventory.get(CHEST, 0)) + 1
    generated_message = "Создан сундук экспедиции"

func _craft_echo_lantern() -> void:
    var glow_count := int(inventory.get(GLOW, 0))
    var shard_count := int(inventory.get(ECHO_SHARD, 0))
    var salt_count := int(inventory.get(SALT_CRYSTAL, 0))
    if glow_count < 1 or shard_count < 2 or salt_count < 1:
        generated_message = "Для Эхо-фонаря нужны 1 свет, 2 осколка Эха и 1 солевой кристалл"
        return
    inventory[GLOW] = glow_count - 1
    inventory[ECHO_SHARD] = shard_count - 2
    inventory[SALT_CRYSTAL] = salt_count - 1
    inventory[ECHO_LANTERN] = int(inventory.get(ECHO_LANTERN, 0)) + 1
    generated_message = "Создан Эхо-фонарь"

func _craft_armor() -> void:
    var stone_count := int(inventory.get(STONE, 0))
    var wood_count := int(inventory.get(WOOD, 0))
    var crystal_count := int(inventory.get(CRYSTAL, 0))
    if stone_count < 4 or wood_count < 2 or crystal_count < 1:
        generated_message = "Для соляной брони нужны 4 камня, 2 дерева и 1 кристалл"
        return
    inventory[STONE] = stone_count - 4
    inventory[WOOD] = wood_count - 2
    inventory[CRYSTAL] = crystal_count - 1
    armor_owned += 1
    generated_message = "Создан комплект соляной брони"

func _toggle_armor() -> void:
    if not is_instance_valid(player):
        return
    if player.armor_equipped:
        player.set_armor(false)
        armor_owned += 1
        generated_message = "Броня снята"
    elif armor_owned > 0:
        armor_owned -= 1
        player.set_armor(true, 80)
        generated_message = "Соляная броня экипирована"
    else:
        generated_message = "Нет брони: создай её клавишей B"
    _refresh_inventory_panel()

func _eat_food() -> void:
    var cooked_count := int(inventory.get(COOKED_FOOD, 0))
    if cooked_count > 0:
        if not player.consume_food(8.0):
            generated_message = "Сытость уже заполнена"
            return
        inventory[COOKED_FOOD] = cooked_count - 1
        generated_message = "Съеден запечённый рацион"
        return
    var food_count := int(inventory.get(FOOD, 0))
    if food_count <= 0:
        generated_message = "Нет еды: найди листья или создай сухой рацион"
        return
    if not player.consume_food(5.0):
        generated_message = "Сытость уже заполнена"
        return
    inventory[FOOD] = food_count - 1
    generated_message = "Съеден сухой рацион"

func _cook_or_craft_stove() -> void:
    if _has_nearby_stove():
        _cook_food()
        return
    _craft_stove()

func _craft_stove() -> void:
    var stone_count := int(inventory.get(STONE, 0))
    var ember_count := int(inventory.get(EMBER, 0))
    if stone_count < 8 or ember_count < 2:
        generated_message = "Для полевого очага нужны 8 камней и 2 эмберовых камня"
        return
    inventory[STONE] = stone_count - 8
    inventory[EMBER] = ember_count - 2
    inventory[STOVE] = int(inventory.get(STOVE, 0)) + 1
    generated_message = "Создан полевой очаг: выбери его в хранилище и поставь"

func _has_nearby_stove() -> bool:
    if not is_instance_valid(player):
        return false
    var center := Vector3i(floori(player.global_position.x), floori(player.global_position.y), floori(player.global_position.z))
    for x in range(center.x - 2, center.x + 3):
        for y in range(center.y - 2, center.y + 3):
            for z in range(center.z - 2, center.z + 3):
                if _get_block(Vector3i(x, y, z)) == STOVE:
                    return true
    return false

func _cook_food() -> void:
    var raw_count := int(inventory.get(FOOD, 0))
    var ember_count := int(inventory.get(EMBER, 0))
    if raw_count < 2 or ember_count < 1:
        generated_message = "Для готовки нужны 2 сухих рациона и 1 эмберовый камень"
        return
    inventory[FOOD] = raw_count - 2
    inventory[EMBER] = ember_count - 1
    inventory[COOKED_FOOD] = int(inventory.get(COOKED_FOOD, 0)) + 2
    generated_message = "Приготовлено 2 запечённых рациона"

func _on_player_survival_changed() -> void:
    if is_instance_valid(player) and player.dead:
        return
    _update_hud()

func _on_player_died() -> void:
    generated_message = "Ты погиб" if not hardcore_mode else "Режим One-Life завершён"
    _update_hud()

func _respawn_player() -> void:
    if not is_instance_valid(player) or player.hardcore:
        return
    player.respawn()
    generated_message = "Возрождение: здоровье восстановлено, сытость снижена"

func _apply_pending_player_state() -> void:
    if not is_instance_valid(player) or pending_player_state.is_empty():
        return
    player.health = clampf(float(pending_player_state.get("health", player.health)), 0.0, player.MAX_HEALTH)
    player.hunger = clampf(float(pending_player_state.get("hunger", player.hunger)), 0.0, player.MAX_HUNGER)
    player.thirst = clampf(float(pending_player_state.get("thirst", player.thirst)), 0.0, player.MAX_THIRST)
    player.energy = clampf(float(pending_player_state.get("energy", player.energy)), 0.0, player.MAX_ENERGY)
    player.mana = clampf(float(pending_player_state.get("mana", player.mana)), 0.0, player.MAX_MANA)
    player.spell_cooldown = maxf(0.0, float(pending_player_state.get("spell_cooldown", player.spell_cooldown)))
    player.weakness_timer = maxf(0.0, float(pending_player_state.get("weakness_timer", player.weakness_timer)))
    player.slowness_timer = maxf(0.0, float(pending_player_state.get("slowness_timer", player.slowness_timer)))
    player.fear_level = clampf(float(pending_player_state.get("fear_level", player.fear_level)), 0.0, 100.0)
    player.fear_timer = maxf(0.0, float(pending_player_state.get("fear_timer", player.fear_timer)))
    player.dead = bool(pending_player_state.get("dead", false))
    var saved_position: Variant = pending_player_state.get("position", {})
    if saved_position is Dictionary:
        player.position = Vector3(float(saved_position.get("x", player.position.x)), float(saved_position.get("y", player.position.y)), float(saved_position.get("z", player.position.z)))
    var saved_respawn: Variant = pending_player_state.get("respawn_position", {})
    if saved_respawn is Dictionary:
        player.respawn_position = Vector3(float(saved_respawn.get("x", player.respawn_position.x)), float(saved_respawn.get("y", player.respawn_position.y)), float(saved_respawn.get("z", player.respawn_position.z)))
    pending_player_state.clear()

func _craft_recipe(idx: int) -> void:
    if NetworkAuthority.is_client_mode():
        generated_message = "Крафт в онлайн-срезе ожидает серверной транзакции"
        return
    if idx < 0 or idx >= recipes.size(): return
    var recipe: Dictionary = recipes[idx]
    var can_craft := true
    for item_id in recipe.input:
        if inventory.get(item_id, 0) < recipe.input[item_id]:
            can_craft = false
            break
    if "station" in recipe:
        var station_nearby := false
        for x in range(-3, 4):
            for y in range(-3, 4):
                for z in range(-3, 4):
                    if _get_block(Vector3i(player.global_position) + Vector3i(x, y, z)) == recipe.station:
                        station_nearby = true
                        break
        if not station_nearby:
            can_craft = false
            generated_message = "Нужна станция: " + _name_for_block(recipe.station)
    if can_craft:
        for item_id in recipe.input:
            inventory[item_id] -= recipe.input[item_id]
        inventory[recipe.output] = inventory.get(recipe.output, 0) + recipe.count
        generated_message = "Создано: " + _name_for_block(recipe.output)
    else:
        if generated_message == "":
            generated_message = "Недостаточно ресурсов"
    _update_hud()

func _name_for_block(id: int) -> String:
    if ore_definitions.has(id):
        return str(ore_definitions[id].get("name", "Руда"))
    if ore_raw_definitions.has(id):
        return "Сырьё: " + str(ore_raw_definitions[id].get("name", "руда"))
    if ore_ingot_definitions.has(id):
        return "Слиток: " + str(ore_ingot_definitions[id].get("name", "металл"))
    match id:
        AIR: return "Воздух"
        GRASS: return "Трава"
        DIRT: return "Земля"
        STONE: return "Камень"
        WOOD: return "Дерево"
        LEAVES: return "Листва"
        GLOW: return "Свет"
        SAND: return "Песок"
        SNOW: return "Снег"
        CRYSTAL: return "Кристалл"
        ASH: return "Пепел"
        FOOD: return "Еда"
        ARMOR: return "Броня"
        IRON_ORE: return "Железная руда"
        GOLD_ORE: return "Золотая руда"
        DIAMOND_ORE: return "Алмазная руда"
        COPPER_ORE: return "Медная руда"
        COAL_ORE: return "Угольная руда"
        PLANKS: return "Доски"
        STICK: return "Палка"
        WORKBENCH: return "Верстак"
        STOVE: return "Печь"
        CHEST: return "Сундук"
        COOKED_FOOD: return "Готовое блюдо"
        BOLT: return "Болт"
        TRAP: return "Ловушка"
        DEEP_CRYSTAL: return "Глубинный кристалл"
        COSMIC_STONE: return "Космический камень"
        STAR_DUST: return "Звёздная пыль"
        ASTRAL_CRYSTAL: return "Астральный кристалл"
        ASTRAL_SCRAP: return "Обломок станции"
        WHISPER_SOIL: return "Шёпотная почва"
        WHISPER_BARK: return "Пульсирующая кора"
        WHISPER_SHARD: return "Осколок шёпота"
        ASTRAL_METAL: return "Метеоритный металл"
        COSMIC_ICE: return "Космический лёд"
        VOID_SHARD: return "Осколок пустоты"
        ANTIMATTER: return "Нестабильная антиматерия"
        NEBULA_GAS: return "Туманностный газ"
        FURNITURE_CRATE: return "Грузовой ящик"
        FURNITURE_TABLE: return "Полевой стол"
        FURNITURE_LAMP: return "Медная лампа"
        WATER: return "Чистая вода"
        ASH_FLUID: return "Жидкий пепел"
        ARCANE_CRYSTAL: return "Арканный кристалл"
        ARCANE_CONDUIT: return "Арканный проводник"
        AUTOMATION_FORGE: return "Автоматическая кузница"
        CARGO_RAIL: return "Грузовой рельс"
        _: return "Предмет"

func _network_build_player_state() -> Dictionary:
    if not is_instance_valid(player):
        return {}
    return {"position": player.position, "health": player.health, "hunger": player.hunger, "thirst": player.thirst, "energy": player.energy, "mana": player.mana, "spell_cooldown": player.spell_cooldown, "dead": player.dead, "weakness_timer": player.weakness_timer, "slowness_timer": player.slowness_timer, "inventory": inventory.duplicate(true)}

func _network_build_world_state() -> Dictionary:
    return {"weather_state": weather_state, "world_time": world_time, "dimension_mode": dimension_mode, "astral_oxygen": astral_oxygen, "astral_radiation": astral_radiation}

func _network_apply_inventory_state(inventory_state: Dictionary) -> void:
    if not NetworkAuthority.is_client_mode():
        return
    var converted: Dictionary = {}
    for item_variant in inventory_state.keys():
        var item_id := int(item_variant)
        if item_id >= 0 and item_id <= MAX_CONTENT_ID:
            converted[item_id] = clampi(int(inventory_state[item_variant]), 0, 9999)
    if not converted.is_empty():
        inventory = converted
        _refresh_inventory_panel()
        _update_hud()

func _network_apply_world_state(state: Dictionary) -> void:
    if not NetworkAuthority.is_client_mode():
        return
    weather_state = str(state.get("weather_state", weather_state))
    world_time = clampf(float(state.get("world_time", world_time)), 0.0, 1.0)
    dimension_mode = str(state.get("dimension_mode", dimension_mode))
    astral_oxygen = clampf(float(state.get("astral_oxygen", astral_oxygen)), 0.0, 100.0)
    astral_radiation = clampf(float(state.get("astral_radiation", astral_radiation)), 0.0, 100.0)
    network_world_state_received = true

func _network_build_entity_snapshot() -> Array:
    var snapshot: Array = []
    for mob_variant in mobs:
        var mob := mob_variant as VoxelMob
        if not is_instance_valid(mob):
            continue
        snapshot.append({"id": mob.name, "kind": mob.mob_kind, "position": mob.position, "health": mob.health, "max_health": mob.max_health})
    if is_instance_valid(boss) and not boss.defeated:
        snapshot.append({"id": boss.name, "kind": boss.boss_kind, "position": boss.position, "health": boss.health, "max_health": boss.max_health})
    return snapshot

func _network_build_snapshot() -> Dictionary:
    var snapshot: Dictionary = {"version": 1, "seed": seed_value, "mode": world_mode, "dimension_mode": dimension_mode, "weather_state": weather_state, "world_time": world_time, "blocks": []}
    var snapshot_blocks: Array = []
    var count := 0
    for cell_variant in blocks.keys():
        if count >= 65536:
            break
        var cell: Vector3i = cell_variant
        snapshot_blocks.append([cell.x, cell.y, cell.z, int(blocks[cell])])
        count += 1
    snapshot["blocks"] = snapshot_blocks
    return snapshot

func _network_apply_snapshot(snapshot: Dictionary) -> void:
    var loaded_blocks: Variant = snapshot.get("blocks", [])
    if loaded_blocks is Array and loaded_blocks.size() <= 65536:
        blocks.clear()
        chunk_storage.clear()
        loaded_chunk_keys.clear()
        for record_variant in loaded_blocks:
            var cell := Vector3i.ZERO
            var block_type := AIR
            if record_variant is Dictionary:
                var record: Dictionary = record_variant
                cell = Vector3i(int(record.get("x", 0)), int(record.get("y", 0)), int(record.get("z", 0)))
                block_type = int(record.get("type", AIR))
            elif record_variant is Array and record_variant.size() >= 4:
                var packed_record: Array = record_variant
                cell = Vector3i(int(packed_record[0]), int(packed_record[1]), int(packed_record[2]))
                block_type = int(packed_record[3])
            if _inside_world(cell) and block_type >= AIR and block_type <= MAX_BLOCK_ID:
                blocks[cell] = block_type

        dimension_mode = str(snapshot.get("dimension_mode", dimension_mode))
        weather_state = str(snapshot.get("weather_state", weather_state))
        world_time = clampf(float(snapshot.get("world_time", world_time)), 0.0, 1.0)
        _rebuild_world_mesh()
        generated_message = "Получен снимок мира от сервера"

func _network_receive_block_edit(cell: Vector3i, new_block: int) -> void:
    if not _inside_world(cell) or new_block < AIR or new_block > MAX_BLOCK_ID:
        return
    _set_runtime_block(cell, new_block)
    _rebuild_world_mesh()

func _network_apply_block_edit(cell: Vector3i, new_block: int, expected_old: int, _sender: int, source_item: int = -1, peer_inventory: Dictionary = {}) -> bool:
    if not _inside_world(cell) or cell.y <= 0 or new_block < AIR or new_block > MAX_BLOCK_ID:
        return false
    if _get_stored_block(cell) != expected_old:
        return false
    if new_block != AIR and _get_stored_block(cell) != AIR:
        return false
    if new_block != AIR:
        if source_item != new_block or int(peer_inventory.get(source_item, 0)) <= 0:
            return false
    _network_receive_block_edit(cell, new_block)
    return true

func _serialize_chunk_storage() -> Array:
    var serialized: Array = []
    for key_variant in chunk_storage.keys():
        var key: Vector2i = key_variant
        var chunk: Dictionary = chunk_storage[key]
        var chunk_blocks: Array = []
        for cell_variant in chunk.keys():
            var cell: Vector3i = cell_variant
            chunk_blocks.append({"x": cell.x, "y": cell.y, "z": cell.z, "type": int(chunk[cell])})
        serialized.append({"cx": key.x, "cz": key.y, "blocks": chunk_blocks})
    return serialized

func _save_world() -> void:
    var save_data: Dictionary = {"version": 6, "seed": seed_value, "world_name": world_name, "mode": world_mode, "anomalies": anomalies_enabled, "autosave": autosave_enabled, "biome_rarity": biome_rarity_mode, "mob_spawns": mob_spawn_enabled, "structures": structures_enabled, "caves": caves_enabled, "pvp": pvp_enabled, "day_night_speed": day_night_speed, "backup_slots": backup_slots, "subtitles": subtitles_enabled, "touch_layout": touch_layout, "hud_layout": hud_layout, "camera_sway": camera_sway_enabled, "avatar_profile": avatar_profile, "chunks": _serialize_chunk_storage(), "inventory": inventory, "storage_inventory": storage_inventory, "difficulty": difficulty_mode, "hardcore": hardcore_mode, "tools": {"equipped": equipped_tool, "durability": tool_durability}, "armor_owned": armor_owned, "blocks_broken": blocks_broken, "quest_stage": quest_stage, "mobs_defeated": mobs_defeated, "boss_defeated": boss_defeated, "achievements": achievements, "claimed_structure_loot": claimed_structure_loot, "npc_talks": npc_talks, "npc_talk_counts": npc_talk_counts, "npc_reputation": npc_reputation, "quest_progress": quest_progress, "quest_completed": quest_completed, "quest_flags": quest_flags, "mob_defeat_counts": mob_defeat_counts, "boss_defeat_counts": boss_defeat_counts, "active_horror_cooldowns": active_horror_cooldowns, "horror_last_biome": horror_last_biome, "horror_last_dimension": horror_last_dimension, "horror_last_weather": horror_last_weather, "boss_arena_phase": boss_arena_phase, "arena_reward_granted": arena_reward_granted, "world_time": world_time, "day_night_enabled": day_night_enabled, "dimension_mode": dimension_mode, "astral_oxygen": astral_oxygen, "astral_radiation": astral_radiation, "weather_state": weather_state, "dirty_chunks": dirty_chunk_keys.size(), "transport_delivery_count": transport_delivery_count}
    if is_instance_valid(player):
        save_data["player"] = {"health": player.health, "hunger": player.hunger, "thirst": player.thirst, "energy": player.energy, "mana": player.mana, "spell_cooldown": player.spell_cooldown, "dead": player.dead, "weakness_timer": player.weakness_timer, "slowness_timer": player.slowness_timer, "fear_level": player.fear_level, "fear_timer": player.fear_timer, "position": {"x": player.position.x, "y": player.position.y, "z": player.position.z}, "respawn_position": {"x": player.respawn_position.x, "y": player.respawn_position.y, "z": player.respawn_position.z}}
    var file := FileAccess.open("user://voxelverse_slot_1.json", FileAccess.WRITE)
    if file == null:
        generated_message = "Ошибка сохранения"
        return
    file.store_string(JSON.stringify(save_data))
    file.close()
    dirty_chunk_keys.clear()
    generated_message = "Мир сохранён в слот 1 · чанков: %d" % chunk_storage.size()

func _load_world_config() -> void:
    if not FileAccess.file_exists("user://ashen_frontier_world_config.json"):
        return
    var config_file := FileAccess.open("user://ashen_frontier_world_config.json", FileAccess.READ)
    if config_file == null:
        return
    var parsed: Variant = JSON.parse_string(config_file.get_as_text())
    config_file.close()
    if parsed is Dictionary:
        var config: Dictionary = parsed
        seed_value = int(config.get("seed", seed_value))
        world_mode = str(config.get("mode", world_mode))
        anomalies_enabled = bool(config.get("anomalies", anomalies_enabled))
        autosave_enabled = bool(config.get("autosave", autosave_enabled))
        var difficulty_name := str(config.get("difficulty", "Стандартная экспедиция"))
        if difficulty_name.contains("Спокой"):
            difficulty_mode = "calm"
        elif difficulty_name.contains("Суров"):
            difficulty_mode = "severe"
        elif difficulty_name.contains("Желез"):
            difficulty_mode = "ironbound"
        else:
            difficulty_mode = "standard"
        hardcore_mode = bool(config.get("hardcore", hardcore_mode))
        world_name = str(config.get("world_name", world_name)).strip_edges()
        world_distance_profile = str(config.get("simulation_distance", world_distance_profile))
        if world_name.is_empty():
            world_name = "Пепельный Рубеж"
        biome_rarity_mode = str(config.get("biome_rarity", biome_rarity_mode))
        if biome_rarity_mode not in ["classic", "standard", "rich"]:
            biome_rarity_mode = "standard"
        mob_spawn_enabled = bool(config.get("mob_spawns", mob_spawn_enabled))
        structures_enabled = bool(config.get("structures", structures_enabled))
        caves_enabled = bool(config.get("caves", caves_enabled))
        pvp_enabled = bool(config.get("pvp", pvp_enabled))
        day_night_speed = clampf(float(config.get("day_night_speed", day_night_speed)), 0.25, 4.0)
        backup_slots = clampi(int(config.get("backup_slots", backup_slots)), 1, 5)
        subtitles_enabled = bool(config.get("subtitles", subtitles_enabled))
        touch_layout = str(config.get("touch_layout", touch_layout))
        hud_layout = str(config.get("hud_layout", hud_layout))
        camera_sway_enabled = bool(config.get("camera_sway", camera_sway_enabled))
        _set_avatar_profile(config.get("avatar_profile", avatar_profile))
        _apply_stream_budget()

func _set_avatar_profile(raw_profile: Variant) -> void:
    if raw_profile is Dictionary:
        var clean := {
            "style": str(raw_profile.get("style", "Разведчик")),
            "palette": str(raw_profile.get("palette", "Пепельная медь")),
            "mark": str(raw_profile.get("mark", "Сигил Рубежа"))
        }
        var allowed_styles := ["Разведчик", "Инженер", "Пилигрим"]
        var allowed_palettes := ["Пепельная медь", "Мятный свет", "Астральный индиго", "Песчаный янтарь"]
        var allowed_marks := ["Без эмблемы", "Сигил Рубежа", "Звёздный узел", "Эхо-метка"]
        if clean["style"] not in allowed_styles:
            clean["style"] = "Разведчик"
        if clean["palette"] not in allowed_palettes:
            clean["palette"] = "Пепельная медь"
        if clean["mark"] not in allowed_marks:
            clean["mark"] = "Сигил Рубежа"
        avatar_profile = clean

func _apply_stream_budget() -> void:
    match world_distance_profile:
        "Короткая": max_stream_chunks_runtime = 9
        "Дальняя": max_stream_chunks_runtime = 25
        "Экспедиционная": max_stream_chunks_runtime = 25
        _ : max_stream_chunks_runtime = 16

func _load_recipe_definitions() -> void:
    if not FileAccess.file_exists(RECIPE_DATA_PATH):
        return
    var recipe_file := FileAccess.open(RECIPE_DATA_PATH, FileAccess.READ)
    if recipe_file == null:
        return
    var parsed: Variant = JSON.parse_string(recipe_file.get_as_text())
    recipe_file.close()
    if not parsed is Array:
        return
    var loaded_recipes: Array[Dictionary] = []
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var output_id := int(entry.get("output", -1))
        var output_count := maxi(1, int(entry.get("count", 1)))
        var raw_input: Variant = entry.get("input", {})
        if output_id < 0 or output_id > MAX_CONTENT_ID or not raw_input is Dictionary:
            continue
        var converted_input: Dictionary = {}
        for raw_key in raw_input.keys():
            var input_id := int(raw_key)
            var amount := int(raw_input[raw_key])
            if input_id >= 0 and input_id <= MAX_CONTENT_ID and amount > 0:
                converted_input[input_id] = amount
        if converted_input.is_empty():
            continue
        var recipe: Dictionary = {"output": output_id, "count": output_count, "input": converted_input}
        if entry.has("station"):
            recipe["station"] = int(entry.get("station", -1))
        loaded_recipes.append(recipe)
    if not loaded_recipes.is_empty():
        recipes = loaded_recipes

func _load_ore_definitions() -> void:
    ore_definitions.clear()
    ore_raw_definitions.clear()
    ore_ingot_definitions.clear()
    if not FileAccess.file_exists("res://data/ores.json"):
        return
    var ore_file := FileAccess.open("res://data/ores.json", FileAccess.READ)
    if ore_file == null:
        return
    var parsed: Variant = JSON.parse_string(ore_file.get_as_text())
    ore_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var ore_id := str(entry.get("id", "")).strip_edges()
        var ore_name := str(entry.get("name", ore_id)).strip_edges()
        var block_id := int(entry.get("block_id", -1))
        var raw_id := int(entry.get("raw_id", -1))
        var ingot_id := int(entry.get("ingot_id", -1))
        var depth_min := int(entry.get("depth_min", -1))
        var depth_max := int(entry.get("depth_max", -1))
        var rarity_bps := int(entry.get("rarity_bps", -1))
        var cluster_size := int(entry.get("cluster_size", -1))
        var tool_tier := int(entry.get("tool_tier", -1))
        var tags_variant: Variant = entry.get("biome_tags", [])
        var tags: Array = tags_variant if tags_variant is Array else []
        var color_hex := str(entry.get("color", "ffffff")).strip_edges()
        var kind := str(entry.get("kind", "common"))
        if ore_id.is_empty() or ore_name.is_empty() or block_id < ORE_BLOCK_BASE or block_id > MAX_BLOCK_ID or raw_id < ORE_RAW_BASE or raw_id >= ORE_RAW_BASE + ORE_BLOCK_COUNT or ingot_id < ORE_INGOT_BASE or ingot_id > MAX_CONTENT_ID or depth_min < 1 or depth_max < depth_min or depth_max >= WORLD_SIZE_Y or rarity_bps <= 0 or rarity_bps > 10000 or cluster_size <= 0 or tool_tier < 0 or (kind != "common" and kind != "rare") or ore_definitions.has(block_id) or ore_raw_definitions.has(raw_id) or ore_ingot_definitions.has(ingot_id):
            continue
        var valid_tags := true
        for tag_variant in tags:
            if not tag_variant is String:
                valid_tags = false
        if not valid_tags:
            continue
        var definition := {"id": ore_id, "name": ore_name, "block_id": block_id, "raw_id": raw_id, "ingot_id": ingot_id, "kind": kind, "biome_tags": tags, "depth_min": depth_min, "depth_max": depth_max, "rarity_bps": rarity_bps, "cluster_size": cluster_size, "tool_tier": tool_tier, "color": color_hex}
        ore_definitions[block_id] = definition
        ore_raw_definitions[raw_id] = definition
        ore_ingot_definitions[ingot_id] = definition
        inventory[block_id] = int(inventory.get(block_id, 0))
        inventory[raw_id] = int(inventory.get(raw_id, 0))
        inventory[ingot_id] = int(inventory.get(ingot_id, 0))

func _append_ore_recipes() -> void:
    for definition_variant in ore_definitions.values():
        var definition: Dictionary = definition_variant
        recipes.append({"output": int(definition["ingot_id"]), "count": 1, "input": {int(definition["raw_id"]): 1}, "station": STOVE})

func _ore_block_for_cell(x: int, y: int, z: int, biome: String) -> int:
    for block_id_variant in ore_definitions.keys():
        var block_id := int(block_id_variant)
        var definition: Dictionary = ore_definitions[block_id]
        if y < int(definition["depth_min"]) or y > int(definition["depth_max"]):
            continue
        var tags: Array = definition["biome_tags"]
        if not tags.is_empty() and not tags.has(biome):
            continue
        var cluster_size := maxi(1, int(definition["cluster_size"]))
        var cluster_hash := absi((floori(float(x) / cluster_size) * 92821 + floori(float(y) / cluster_size) * 68917 + floori(float(z) / cluster_size) * 47297 + seed_value + block_id * 37) % 10000)
        if cluster_hash < int(definition["rarity_bps"]):
            return block_id
    return AIR

func _load_spell_definitions() -> void:
    spell_definitions.clear()
    if not FileAccess.file_exists(SPELL_DATA_PATH):
        return
    var spell_file := FileAccess.open(SPELL_DATA_PATH, FileAccess.READ)
    if spell_file == null:
        return
    var parsed: Variant = JSON.parse_string(spell_file.get_as_text())
    spell_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var spell_id := str(entry.get("id", "")).strip_edges()
        var spell_name := str(entry.get("name", spell_id)).strip_edges()
        var effect := str(entry.get("effect", "")).strip_edges()
        var mana_cost := float(entry.get("mana_cost", -1.0))
        var cooldown := float(entry.get("cooldown", -1.0))
        var power := float(entry.get("power", 0.0))
        var school := str(entry.get("school", "arcane")).strip_edges()
        var reagent_id := int(entry.get("reagent_id", -1))
        var reagent_count := maxi(0, int(entry.get("reagent_count", 0)))
        if spell_id.is_empty() or spell_name.is_empty() or effect.is_empty() or school.is_empty() or mana_cost < 0.0 or cooldown < 0.0 or power < 0.0 or reagent_count > 16 or (reagent_count > 0 and reagent_id < 0):
            continue
        spell_definitions[spell_id] = {"name": spell_name, "school": school, "mana_cost": mana_cost, "cooldown": cooldown, "effect": effect, "power": power, "status_duration": maxf(0.0, float(entry.get("status_duration", 0.0))), "reagent_id": reagent_id, "reagent_count": reagent_count}

func _load_biome_definitions() -> void:
    external_biome_definitions.clear()
    if not FileAccess.file_exists(BIOME_DATA_PATH):
        return
    var biome_file := FileAccess.open(BIOME_DATA_PATH, FileAccess.READ)
    if biome_file == null:
        return
    var parsed: Variant = JSON.parse_string(biome_file.get_as_text())
    biome_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var biome_name := str(entry.get("name", "")).strip_edges()
        var surface_id := int(entry.get("surface_block", -1))
        var subsurface_id := int(entry.get("subsurface_block", -1))
        var spawn_mob := str(entry.get("spawn_mob", "EchoCrawler")).strip_edges()
        var terrain_lift := int(entry.get("terrain_lift", 0))
        var temperature := float(entry.get("temperature", 0.5))
        var hazard := str(entry.get("hazard", "none")).strip_edges()
        var rarity := str(entry.get("rarity", "common")).strip_edges()
        var region_variant: Variant = entry.get("region", [])
        var region: Array = region_variant if region_variant is Array else []
        var valid_region := region.is_empty() or region.size() == 4
        if biome_name.is_empty() or surface_id < 1 or surface_id > MAX_BLOCK_ID or subsurface_id < 1 or subsurface_id > MAX_BLOCK_ID or spawn_mob.is_empty() or terrain_lift < -2 or terrain_lift > 5 or temperature < 0.0 or temperature > 1.0 or hazard.is_empty() or rarity.is_empty() or not valid_region:
            continue
        var valid_bounds := true
        for bound_variant in region:
            if not (bound_variant is int or bound_variant is float):
                valid_bounds = false
        if not valid_bounds:
            continue
        external_biome_definitions[biome_name] = {"name": biome_name, "surface_block": surface_id, "subsurface_block": subsurface_id, "spawn_mob": spawn_mob, "terrain_lift": terrain_lift, "temperature": temperature, "hazard": hazard, "rarity": rarity, "region": region, "custom": not region.is_empty()}

func _load_npc_definitions() -> void:
    npc_definitions.clear()
    if not FileAccess.file_exists(NPC_DATA_PATH):
        return
    var npc_file := FileAccess.open(NPC_DATA_PATH, FileAccess.READ)
    if npc_file == null:
        return
    var parsed: Variant = JSON.parse_string(npc_file.get_as_text())
    npc_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var npc_id := str(entry.get("id", "")).strip_edges()
        var npc_name := str(entry.get("name", "")).strip_edges()
        var role := str(entry.get("role", "")).strip_edges()
        var faction := str(entry.get("faction", "")).strip_edges()
        var spawn_tag := str(entry.get("spawn_tag", "")).strip_edges()
        var dialogue_variant: Variant = entry.get("dialogue", [])
        var schedule_variant: Variant = entry.get("schedule", [])
        var shop_variant: Variant = entry.get("shop", [])
        if npc_id.is_empty() or npc_name.is_empty() or role.is_empty() or faction.is_empty() or spawn_tag.is_empty() or npc_definitions.has(npc_id) or not dialogue_variant is Array or not schedule_variant is Array or not shop_variant is Array:
            continue
        var dialogue: Array[String] = []
        for line_variant in dialogue_variant:
            if line_variant is String and not str(line_variant).strip_edges().is_empty():
                dialogue.append(str(line_variant))
        if dialogue.is_empty():
            continue
        var schedule: Array[Dictionary] = []
        var schedule_valid := true
        for schedule_entry_variant in schedule_variant:
            if not schedule_entry_variant is Dictionary:
                schedule_valid = false
                break
            var schedule_entry: Dictionary = schedule_entry_variant
            var point_variant: Variant = schedule_entry.get("point", [])
            if not point_variant is Array or point_variant.size() != 3:
                schedule_valid = false
                break
            var from_value := float(schedule_entry.get("from", -1.0))
            var to_value := float(schedule_entry.get("to", -1.0))
            if from_value < 0.0 or to_value > 1.0 or to_value <= from_value or int(point_variant[0]) < 0 or int(point_variant[0]) >= WORLD_SIZE_X or int(point_variant[2]) < 0 or int(point_variant[2]) >= WORLD_SIZE_Z:
                schedule_valid = false
                break
            schedule.append({"from": from_value, "to": to_value, "point": [int(point_variant[0]), clampi(int(point_variant[1]), 1, WORLD_SIZE_Y - 2), int(point_variant[2])]})
        if not schedule_valid or schedule.is_empty():
            continue
        var shop: Array[Dictionary] = []
        var shop_valid := true
        for offer_variant in shop_variant:
            if not offer_variant is Dictionary:
                shop_valid = false
                break
            var offer: Dictionary = offer_variant
            var item_id := int(offer.get("item_id", -1))
            var price_id := int(offer.get("price_id", -1))
            var price_count := int(offer.get("price_count", 0))
            if item_id < 0 or item_id > MAX_CONTENT_ID or price_id < 0 or price_id > MAX_CONTENT_ID or price_count <= 0 or price_count > 64:
                shop_valid = false
                break
            shop.append({"item_id": item_id, "price_id": price_id, "price_count": price_count})
        if not shop_valid:
            continue
        npc_definitions[npc_id] = {"id": npc_id, "name": npc_name, "role": role, "faction": faction, "spawn_tag": spawn_tag, "dialogue": dialogue, "schedule": schedule, "shop": shop}
        npc_reputation[npc_id] = int(npc_reputation.get(npc_id, 0))

func _load_quest_definitions() -> void:
    quest_definitions.clear()
    quest_progress.clear()
    quest_completed.clear()
    if not FileAccess.file_exists(QUEST_DATA_PATH):
        return
    var quest_file := FileAccess.open(QUEST_DATA_PATH, FileAccess.READ)
    if quest_file == null:
        return
    var parsed: Variant = JSON.parse_string(quest_file.get_as_text())
    quest_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var quest_id := str(entry.get("id", "")).strip_edges()
        var title := str(entry.get("title", "")).strip_edges()
        var description := str(entry.get("description", "")).strip_edges()
        var order := int(entry.get("order", 0))
        var objective_variant: Variant = entry.get("objective", {})
        var reward_variant: Variant = entry.get("reward", {})
        var flags_variant: Variant = entry.get("hidden_flags", [])
        if quest_id.is_empty() or title.is_empty() or description.is_empty() or order <= 0 or not objective_variant is Dictionary or not reward_variant is Dictionary or not flags_variant is Array or quest_definitions.any(func(existing: Dictionary) -> bool: return str(existing.get("id", "")) == quest_id):
            continue
        var objective: Dictionary = objective_variant
        var objective_type := str(objective.get("type", ""))
        var target := int(objective.get("target", 0))
        if objective_type not in ["blocks_broken", "biome_visit", "mob_defeated", "boss_defeated", "npc_talk"] or target <= 0:
            continue
        if objective_type == "biome_visit" and str(objective.get("biome", "")).is_empty():
            continue
        if objective_type == "mob_defeated" and str(objective.get("mob_kind", "")).is_empty():
            continue
        if objective_type == "boss_defeated" and str(objective.get("boss_kind", "")).is_empty():
            continue
        if objective_type == "npc_talk" and str(objective.get("npc_id", "")).is_empty():
            continue
        var reward: Dictionary = reward_variant
        var reward_item := int(reward.get("item_id", -1))
        var reward_count := int(reward.get("count", 0))
        if reward_item < 0 or reward_item > MAX_CONTENT_ID or reward_count <= 0 or reward_count > 999:
            continue
        var flags: Array[String] = []
        for flag_variant in flags_variant:
            if flag_variant is String and not str(flag_variant).strip_edges().is_empty():
                flags.append(str(flag_variant))
        quest_definitions.append({"id": quest_id, "title": title, "description": description, "order": order, "objective": objective, "reward": {"item_id": reward_item, "count": reward_count}, "hidden_flags": flags})
        quest_progress[quest_id] = maxi(0, int(quest_progress.get(quest_id, 0)))
        quest_completed[quest_id] = bool(quest_completed.get(quest_id, false))
    quest_definitions.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.get("order", 0)) < int(right.get("order", 0)))

func _load_horror_definitions() -> void:
    horror_definitions.clear()
    if not FileAccess.file_exists(HORROR_DATA_PATH):
        return
    var horror_file := FileAccess.open(HORROR_DATA_PATH, FileAccess.READ)
    if horror_file == null:
        return
    var parsed: Variant = JSON.parse_string(horror_file.get_as_text())
    horror_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var encounter_id := str(entry.get("id", "")).strip_edges()
        var trigger := str(entry.get("trigger", "")).strip_edges()
        var message := str(entry.get("message", "")).strip_edges()
        var cooldown := float(entry.get("cooldown", -1.0))
        var fear := float(entry.get("fear", -1.0))
        var weakness_duration := float(entry.get("weakness_duration", -1.0))
        if encounter_id.is_empty() or trigger not in ["biome_enter", "dimension_enter", "weather_change"] or message.is_empty() or cooldown < 0.0 or fear < 0.0 or fear > 100.0 or weakness_duration < 0.0 or horror_definitions.any(func(existing: Dictionary) -> bool: return str(existing.get("id", "")) == encounter_id):
            continue
        if trigger == "biome_enter" and str(entry.get("biome", "")).is_empty():
            continue
        if trigger == "dimension_enter" and str(entry.get("dimension", "")).is_empty():
            continue
        if trigger == "weather_change" and str(entry.get("weather", "")).is_empty():
            continue
        horror_definitions.append({"id": encounter_id, "trigger": trigger, "biome": str(entry.get("biome", "")), "dimension": str(entry.get("dimension", "")), "weather": str(entry.get("weather", "")), "cooldown": cooldown, "fear": fear, "weakness_duration": weakness_duration, "message": message, "pursuit_kind": str(entry.get("pursuit_kind", ""))})
        active_horror_cooldowns[encounter_id] = maxf(0.0, float(active_horror_cooldowns.get(encounter_id, 0.0)))

func _load_boss_arena_definitions() -> void:
    boss_arena_definitions.clear()
    if not FileAccess.file_exists(BOSS_ARENA_DATA_PATH):
        return
    var arena_file := FileAccess.open(BOSS_ARENA_DATA_PATH, FileAccess.READ)
    if arena_file == null:
        return
    var parsed: Variant = JSON.parse_string(arena_file.get_as_text())
    arena_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var arena_id := str(entry.get("id", "")).strip_edges()
        var boss_kind := str(entry.get("boss_kind", "")).strip_edges()
        var center_variant: Variant = entry.get("center", [])
        var radius := float(entry.get("radius", 0.0))
        var thresholds_variant: Variant = entry.get("phase_thresholds", [])
        var messages_variant: Variant = entry.get("phase_messages", [])
        var reward_variant: Variant = entry.get("reward", {})
        if arena_id.is_empty() or boss_kind.is_empty() or boss_arena_definitions.has(boss_kind) or not center_variant is Array or center_variant.size() != 3 or radius < 3.0 or radius > 32.0 or not thresholds_variant is Array or thresholds_variant.size() != 2 or not messages_variant is Array or messages_variant.size() != 3 or not reward_variant is Dictionary:
            continue
        var center: Array = center_variant
        var thresholds: Array[float] = [float(thresholds_variant[0]), float(thresholds_variant[1])]
        if thresholds[0] <= thresholds[1] or thresholds[0] >= 1.0 or thresholds[1] <= 0.0:
            continue
        var messages: Array[String] = []
        for message_variant in messages_variant:
            if not message_variant is String or str(message_variant).strip_edges().is_empty():
                messages.clear()
                break
            messages.append(str(message_variant))
        var reward: Dictionary = reward_variant
        var reward_item := int(reward.get("item_id", -1))
        var reward_count := int(reward.get("count", 0))
        if messages.size() != 3 or reward_item < 0 or reward_item > MAX_CONTENT_ID or reward_count <= 0:
            continue
        boss_arena_definitions[boss_kind] = {"id": arena_id, "boss_kind": boss_kind, "center": Vector3i(int(center[0]), clampi(int(center[1]), 1, WORLD_SIZE_Y - 2), int(center[2])), "radius": radius, "phase_thresholds": thresholds, "phase_messages": messages, "reward": {"item_id": reward_item, "count": reward_count}}

func _load_structure_definitions() -> void:
    structure_definitions.clear()
    if not FileAccess.file_exists(STRUCTURE_DATA_PATH):
        return
    var structure_file := FileAccess.open(STRUCTURE_DATA_PATH, FileAccess.READ)
    if structure_file == null:
        return
    var parsed: Variant = JSON.parse_string(structure_file.get_as_text())
    structure_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var structure_id := str(entry.get("id", "")).strip_edges()
        var anchor_variant: Variant = entry.get("anchor", [])
        var size := int(entry.get("size", 0))
        var height := int(entry.get("height", 0))
        var floor_block := int(entry.get("floor_block", AIR))
        var wall_block := int(entry.get("wall_block", AIR))
        var chest_offset_variant: Variant = entry.get("chest_offset", [0, 1, 0])
        var loot_variant: Variant = entry.get("loot", [])
        if structure_id.is_empty() or structure_definitions.any(func(existing: Dictionary) -> bool: return str(existing.get("id", "")) == structure_id) or not anchor_variant is Array or anchor_variant.size() != 2 or not chest_offset_variant is Array or chest_offset_variant.size() != 3 or not loot_variant is Array or size < 3 or size > 9 or height < 2 or height > 6 or floor_block < 1 or floor_block > MAX_BLOCK_ID or wall_block < 1 or wall_block > MAX_BLOCK_ID:
            continue
        var anchor: Array = anchor_variant
        var chest_offset: Array = chest_offset_variant
        if int(anchor[0]) < 1 or int(anchor[0]) >= WORLD_SIZE_X - 1 or int(anchor[1]) < 1 or int(anchor[1]) >= WORLD_SIZE_Z - 1:
            continue
        var loot_table: Array[Dictionary] = []
        for loot_entry_variant in loot_variant:
            if loot_entry_variant is Dictionary:
                var loot_entry: Dictionary = loot_entry_variant
                var item_id := int(loot_entry.get("item", AIR))
                if item_id >= 0 and item_id <= MAX_CONTENT_ID and int(loot_entry.get("min", 0)) > 0 and int(loot_entry.get("max", 0)) >= int(loot_entry.get("min", 0)):
                    loot_table.append(loot_entry)
        if loot_table.is_empty():
            continue
        structure_definitions.append({"id": structure_id, "name": str(entry.get("name", structure_id)), "anchor": anchor, "size": size, "height": height, "floor_block": floor_block, "wall_block": wall_block, "chest_offset": chest_offset, "loot": loot_table, "salt": int(entry.get("salt", 0))})

func _add_data_structures() -> void:
    for definition in structure_definitions:
        var anchor: Array = definition["anchor"]
        var center_x := int(anchor[0])
        var center_z := int(anchor[1])
        var size := int(definition["size"])
        var height := int(definition["height"])
        var half := size / 2
        var floor_y := clampi(_highest_solid_y(center_x, center_z) + 1, 1, WORLD_SIZE_Y - height - 1)
        for local_x in range(-half, half + 1):
            for local_z in range(-half, half + 1):
                var edge: bool = abs(local_x) == half or abs(local_z) == half
                for local_y in range(height):
                    var cell := Vector3i(center_x + local_x, floor_y + local_y, center_z + local_z)
                    if not _inside_world(cell):
                        continue
                    if local_y == 0:
                        blocks[cell] = int(definition["floor_block"])
                    elif edge or local_y == height - 1:
                        blocks[cell] = int(definition["wall_block"])
                    else:
                        blocks.erase(cell)
        var chest_offset: Array = definition["chest_offset"]
        var chest_cell := Vector3i(center_x + int(chest_offset[0]), floor_y + int(chest_offset[1]), center_z + int(chest_offset[2]))
        if _inside_world(chest_cell):
            blocks[chest_cell] = CHEST
            _register_structure_loot(chest_cell, definition["loot"], int(definition["salt"]))

func _load_mob_definitions() -> void:
    external_mob_definitions.clear()
    if not FileAccess.file_exists(MOB_DATA_PATH):
        return
    var mob_file := FileAccess.open(MOB_DATA_PATH, FileAccess.READ)
    if mob_file == null:
        return
    var parsed: Variant = JSON.parse_string(mob_file.get_as_text())
    mob_file.close()
    if not parsed is Array:
        return
    for entry_variant in parsed:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = entry_variant
        var mob_id := str(entry.get("id", "")).strip_edges()
        var max_health := float(entry.get("max_health", 0.0))
        var move_speed := float(entry.get("move_speed", 0.0))
        var attack_damage := float(entry.get("attack_damage", 0.0))
        var attack_range := float(entry.get("attack_range", 0.0))
        var detection_range := float(entry.get("detection_range", 0.0))
        if mob_id.is_empty() or max_health <= 0.0 or move_speed <= 0.0 or attack_damage < 0.0 or attack_range <= 0.0 or detection_range <= 0.0:
            continue
        external_mob_definitions[mob_id] = {"id": mob_id, "max_health": max_health, "move_speed": move_speed, "attack_damage": attack_damage, "attack_range": attack_range, "detection_range": detection_range}

func _load_renderer_settings() -> void:
    if not FileAccess.file_exists("user://ashen_frontier_settings.json"):
        return
    var settings_file := FileAccess.open("user://ashen_frontier_settings.json", FileAccess.READ)
    if settings_file == null:
        return
    var parsed: Variant = JSON.parse_string(settings_file.get_as_text())
    settings_file.close()
    if parsed is Dictionary:
        renderer_profile = str(parsed.get("quality", renderer_profile))
        shaders_enabled = bool(parsed.get("shaders_enabled", shaders_enabled))
        world_distance_profile = str(parsed.get("distance", world_distance_profile))
        _apply_stream_budget()
        _apply_renderer_profile()

func _load_world() -> void:
    if not FileAccess.file_exists("user://voxelverse_slot_1.json"):
        return
    var file := FileAccess.open("user://voxelverse_slot_1.json", FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    difficulty_mode = str(parsed.get("difficulty", difficulty_mode))
    world_mode = str(parsed.get("mode", world_mode))
    anomalies_enabled = bool(parsed.get("anomalies", anomalies_enabled))
    autosave_enabled = bool(parsed.get("autosave", autosave_enabled))
    hardcore_mode = bool(parsed.get("hardcore", hardcore_mode))
    armor_owned = maxi(0, int(parsed.get("armor_owned", armor_owned)))
    blocks_broken = maxi(0, int(parsed.get("blocks_broken", blocks_broken)))
    quest_stage = clampi(int(parsed.get("quest_stage", quest_stage)), 0, 5)
    mobs_defeated = maxi(0, int(parsed.get("mobs_defeated", mobs_defeated)))
    var loaded_achievements: Variant = parsed.get("achievements", {})
    if loaded_achievements is Dictionary:
        for achievement_key in achievements.keys():
            achievements[achievement_key] = bool(loaded_achievements.get(achievement_key, achievements[achievement_key]))
    boss_defeated = bool(parsed.get("boss_defeated", boss_defeated))
    var loaded_claimed_loot: Variant = parsed.get("claimed_structure_loot", {})
    if loaded_claimed_loot is Dictionary:
        claimed_structure_loot.clear()
        for loot_key_variant in loaded_claimed_loot.keys():
            claimed_structure_loot[str(loot_key_variant)] = bool(loaded_claimed_loot[loot_key_variant])
    npc_talks = maxi(0, int(parsed.get("npc_talks", npc_talks)))
    var loaded_npc_talk_counts: Variant = parsed.get("npc_talk_counts", {})
    if loaded_npc_talk_counts is Dictionary:
        for key_variant in loaded_npc_talk_counts.keys():
            npc_talk_counts[str(key_variant)] = maxi(0, int(loaded_npc_talk_counts[key_variant]))
    var loaded_npc_reputation: Variant = parsed.get("npc_reputation", {})
    if loaded_npc_reputation is Dictionary:
        for key_variant in loaded_npc_reputation.keys():
            npc_reputation[str(key_variant)] = clampi(int(loaded_npc_reputation[key_variant]), -100, 100)
    var loaded_quest_progress: Variant = parsed.get("quest_progress", {})
    if loaded_quest_progress is Dictionary:
        for key_variant in loaded_quest_progress.keys():
            quest_progress[str(key_variant)] = maxi(0, int(loaded_quest_progress[key_variant]))
    var loaded_quest_completed: Variant = parsed.get("quest_completed", {})
    if loaded_quest_completed is Dictionary:
        for key_variant in loaded_quest_completed.keys():
            quest_completed[str(key_variant)] = bool(loaded_quest_completed[key_variant])
    var loaded_quest_flags: Variant = parsed.get("quest_flags", {})
    if loaded_quest_flags is Dictionary:
        for key_variant in loaded_quest_flags.keys():
            quest_flags[str(key_variant)] = bool(loaded_quest_flags[key_variant])
    var loaded_mob_defeat_counts: Variant = parsed.get("mob_defeat_counts", {})
    if loaded_mob_defeat_counts is Dictionary:
        for key_variant in loaded_mob_defeat_counts.keys():
            mob_defeat_counts[str(key_variant)] = maxi(0, int(loaded_mob_defeat_counts[key_variant]))
    var loaded_boss_defeat_counts: Variant = parsed.get("boss_defeat_counts", {})
    if loaded_boss_defeat_counts is Dictionary:
        for key_variant in loaded_boss_defeat_counts.keys():
            boss_defeat_counts[str(key_variant)] = maxi(0, int(loaded_boss_defeat_counts[key_variant]))
    var loaded_horror_cooldowns: Variant = parsed.get("active_horror_cooldowns", {})
    if loaded_horror_cooldowns is Dictionary:
        for key_variant in loaded_horror_cooldowns.keys():
            active_horror_cooldowns[str(key_variant)] = maxf(0.0, float(loaded_horror_cooldowns[key_variant]))
    horror_last_biome = str(parsed.get("horror_last_biome", horror_last_biome))
    horror_last_dimension = str(parsed.get("horror_last_dimension", horror_last_dimension))
    horror_last_weather = str(parsed.get("horror_last_weather", horror_last_weather))
    boss_arena_phase = clampi(int(parsed.get("boss_arena_phase", boss_arena_phase)), 0, 3)
    arena_reward_granted = bool(parsed.get("arena_reward_granted", arena_reward_granted))
    transport_delivery_count = maxi(0, int(parsed.get("transport_delivery_count", transport_delivery_count)))
    world_time = clampf(float(parsed.get("world_time", world_time)), 0.0, 1.0)
    day_night_enabled = bool(parsed.get("day_night_enabled", day_night_enabled))
    world_name = str(parsed.get("world_name", world_name))
    biome_rarity_mode = str(parsed.get("biome_rarity", biome_rarity_mode))
    mob_spawn_enabled = bool(parsed.get("mob_spawns", mob_spawn_enabled))
    structures_enabled = bool(parsed.get("structures", structures_enabled))
    caves_enabled = bool(parsed.get("caves", caves_enabled))
    pvp_enabled = bool(parsed.get("pvp", pvp_enabled))
    day_night_speed = clampf(float(parsed.get("day_night_speed", day_night_speed)), 0.25, 4.0)
    backup_slots = clampi(int(parsed.get("backup_slots", backup_slots)), 1, 5)
    subtitles_enabled = bool(parsed.get("subtitles", subtitles_enabled))
    touch_layout = str(parsed.get("touch_layout", touch_layout))
    hud_layout = str(parsed.get("hud_layout", hud_layout))
    camera_sway_enabled = bool(parsed.get("camera_sway", camera_sway_enabled))
    _set_avatar_profile(parsed.get("avatar_profile", avatar_profile))
    dimension_mode = str(parsed.get("dimension_mode", dimension_mode))
    _apply_stream_budget()

    astral_oxygen = clampf(float(parsed.get("astral_oxygen", astral_oxygen)), 0.0, 100.0)
    astral_radiation = clampf(float(parsed.get("astral_radiation", astral_radiation)), 0.0, 100.0)
    weather_state = str(parsed.get("weather_state", weather_state))
    var loaded_player: Variant = parsed.get("player", {})
    if loaded_player is Dictionary:
        pending_player_state = loaded_player
    var loaded_tools: Variant = parsed.get("tools", {})
    if loaded_tools is Dictionary:
        equipped_tool = clampi(int(loaded_tools.get("equipped", equipped_tool)), 0, tool_names.size() - 1)
        var loaded_durability: Variant = loaded_tools.get("durability", [])
        if loaded_durability is Array:
            for tool_index in mini(loaded_durability.size(), tool_durability.size()):
                tool_durability[tool_index] = maxi(0, int(loaded_durability[tool_index]))
    var loaded_chunks: Variant = parsed.get("chunks", [])
    if loaded_chunks is Array and not loaded_chunks.is_empty():
        blocks.clear()
        chunk_storage.clear()
        for chunk_variant in loaded_chunks:
            if not (chunk_variant is Dictionary):
                continue
            var chunk_record: Dictionary = chunk_variant
            var chunk_key := Vector2i(int(chunk_record.get("cx", 0)), int(chunk_record.get("cz", 0)))
            if not _chunk_key_in_bounds(chunk_key):
                continue
            var chunk := _ensure_chunk(chunk_key)
            var chunk_records: Variant = chunk_record.get("blocks", [])
            if chunk_records is Array:
                for record_variant in chunk_records:
                    if record_variant is Dictionary:
                        var record: Dictionary = record_variant
                        var cell := Vector3i(int(record.get("x", 0)), int(record.get("y", 0)), int(record.get("z", 0)))
                        var block_type := int(record.get("type", AIR))
                        if _inside_world(cell) and block_type > AIR and block_type <= MAX_BLOCK_ID:
                            chunk[cell] = block_type
    else:
        var loaded_blocks: Variant = parsed.get("blocks", [])
        if loaded_blocks is Array and not loaded_blocks.is_empty():
            blocks.clear()
            for record_variant in loaded_blocks:
                if record_variant is Dictionary:
                    var record: Dictionary = record_variant
                    var cell := Vector3i(int(record.get("x", 0)), int(record.get("y", 0)), int(record.get("z", 0)))
                    blocks[cell] = int(record.get("type", AIR))
    var loaded_storage: Variant = parsed.get("storage_inventory", {})
    if loaded_storage is Dictionary:
        storage_inventory.clear()
        for storage_key_variant in loaded_storage.keys():
            var storage_item_id := int(storage_key_variant)
            if storage_item_id >= 0 and storage_item_id <= MAX_CONTENT_ID:
                storage_inventory[storage_item_id] = clampi(int(loaded_storage[storage_key_variant]), 0, 9999)
    fluid_depth.clear()
    for chunk_variant in chunk_storage.values():
        var fluid_chunk: Dictionary = chunk_variant
        for fluid_cell_variant in fluid_chunk.keys():
            var fluid_cell: Vector3i = fluid_cell_variant
            var fluid_type := int(fluid_chunk[fluid_cell])
            if fluid_type == WATER or fluid_type == ASH_FLUID:
                fluid_depth[fluid_cell] = 0
    traps.clear()
    if not chunk_storage.is_empty():
        for chunk_variant in chunk_storage.values():
            var loaded_chunk: Dictionary = chunk_variant
            for saved_cell_variant in loaded_chunk.keys():
                var saved_cell: Vector3i = saved_cell_variant
                if int(loaded_chunk[saved_cell]) == TRAP:
                    traps.append(saved_cell)
    else:
        for saved_cell_variant in blocks.keys():
            var saved_cell: Vector3i = saved_cell_variant
            if int(blocks[saved_cell]) == TRAP:
                traps.append(saved_cell)
    var loaded_inventory: Variant = parsed.get("inventory", {})
    if loaded_inventory is Dictionary:
        var converted_inventory: Dictionary = {}
        for key_variant in loaded_inventory.keys():
            var loaded_item_id := int(key_variant)
            if loaded_item_id >= 0 and loaded_item_id <= MAX_CONTENT_ID:
                converted_inventory[loaded_item_id] = clampi(int(loaded_inventory[key_variant]), 0, 9999)
        if not converted_inventory.is_empty():
            inventory = converted_inventory
    for new_item_id in [WATER, ASH_FLUID, ARCANE_CRYSTAL, ARCANE_CONDUIT, AUTOMATION_FORGE, CARGO_RAIL]:
        if not inventory.has(new_item_id):
            inventory[new_item_id] = 0
    for ore_definition_variant in ore_definitions.values():
        var ore_definition: Dictionary = ore_definition_variant
        for ore_item_id in [int(ore_definition["block_id"]), int(ore_definition["raw_id"]), int(ore_definition["ingot_id"])]:
            if not inventory.has(ore_item_id):
                inventory[ore_item_id] = 0
    generated_message = "Мир загружен из слота 1"

func _spawn_npcs() -> void:
    npcs.clear()
    for definition_variant in npc_definitions.values():
        var definition: Dictionary = definition_variant
        var npc := VoxelNpcScript.new()
        npc.name = str(definition.get("id", "Npc"))
        npc.position = _npc_spawn_position(str(definition.get("spawn_tag", "outpost")))
        npc.setup(player, self, definition)
        add_child(npc)
        npcs.append(npc)
    if npcs.is_empty():
        var fallback := VoxelNpcScript.new()
        fallback.name = "Wayfinder_Ilara"
        fallback.position = Vector3(outpost_origin) + Vector3(0.5, 1.0, 0.5)
        fallback.setup(player, self)
        add_child(fallback)
        npcs.append(fallback)

func _npc_spawn_position(spawn_tag: String) -> Vector3:
    match spawn_tag:
        "outpost_east":
            return Vector3(34.5, 1.0, 14.5)
        "astral_gate":
            return Vector3(5.5, 9.0, 5.5)
        _:
            return Vector3(outpost_origin) + Vector3(0.5, 1.0, 0.5)

func _npc_schedule_destination(npc: VoxelNpc) -> Vector3:
    var definition: Dictionary = npc_definitions.get(npc.definition_id, {})
    var schedule_variant: Variant = definition.get("schedule", [])
    if not schedule_variant is Array or schedule_variant.is_empty():
        return npc.home_position
    var phase := fposmod(world_time, 1.0)
    for schedule_entry_variant in schedule_variant:
        if not schedule_entry_variant is Dictionary:
            continue
        var schedule_entry: Dictionary = schedule_entry_variant
        var from_value := float(schedule_entry.get("from", 0.0))
        var to_value := float(schedule_entry.get("to", 1.0))
        if phase >= from_value and phase < to_value:
            var point: Array = schedule_entry.get("point", [int(npc.home_position.x), int(npc.home_position.y), int(npc.home_position.z)])
            return Vector3(int(point[0]) + 0.5, int(point[1]), int(point[2]) + 0.5)
    return npc.home_position

func _nearest_npc(max_distance: float = 3.5) -> VoxelNpc:
    if not is_instance_valid(player):
        return null
    var nearest: VoxelNpc = null
    var nearest_distance := max_distance
    for npc_node in npcs:
        if not is_instance_valid(npc_node):
            continue
        var npc := npc_node as VoxelNpc
        if npc == null:
            continue
        var distance := npc.global_position.distance_to(player.global_position)
        if distance <= nearest_distance:
            nearest = npc
            nearest_distance = distance
    return nearest

func _has_nearby_npc() -> bool:
    return _nearest_npc() != null

func _interact_nearby_npc() -> void:
    if not is_instance_valid(player) or player.dead:
        return
    var nearest := _nearest_npc()
    if nearest == null:
        generated_message = "Рядом нет проводника"
        return
    nearest.interact()

func _trade_nearby_npc() -> void:
    if not is_instance_valid(player) or player.dead:
        return
    var nearest := _nearest_npc()
    if nearest == null:
        generated_message = "Рядом нет торговца"
        return
    var offers := nearest.get_shop_inventory()
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        var item_id := int(offer.get("item_id", -1))
        var price_id := int(offer.get("price_id", -1))
        var price_count := int(offer.get("price_count", 0))
        var source_count := int(inventory.get(price_id, 0))
        if item_id < 0 or price_id < 0 or price_count <= 0 or source_count < price_count:
            continue
        inventory[price_id] = source_count - price_count
        inventory[item_id] = int(inventory.get(item_id, 0)) + 1
        npc_reputation[nearest.definition_id] = clampi(int(npc_reputation.get(nearest.definition_id, 0)) + 1, -100, 100)
        generated_message = "Обмен у %s: +1 %s" % [nearest.npc_name, _name_for_block(item_id)]
        _refresh_inventory_panel()
        return
    generated_message = "%s: нет подходящего обмена" % nearest.npc_name

func _on_npc_talk(npc: VoxelNpc, line: String) -> void:
    npc_talks += 1
    npc_talk_counts[npc.definition_id] = int(npc_talk_counts.get(npc.definition_id, 0)) + 1
    npc_reputation[npc.definition_id] = clampi(int(npc_reputation.get(npc.definition_id, 0)) + 1, -100, 100)
    generated_message = line
    if quest_stage == 1:
        generated_message += "  Найди кристаллы на юго-востоке."

func _spawn_boss() -> void:
    if boss_defeated:
        return
    boss = VoxelBossScript.new()
    var astral_boss := dimension_mode == "astral_expanse"
    var boss_kind := "Void Leviathan" if astral_boss else "Echo Warden"
    boss.name = "VoidLeviathan" if astral_boss else "EchoWarden"
    var arena: Dictionary = boss_arena_definitions.get(boss_kind, {})
    var spawn_origin := Vector3i(4, 0, 4) if astral_boss else dungeon_origin
    if not arena.is_empty():
        spawn_origin = arena.get("center", spawn_origin)
    boss.position = Vector3(spawn_origin) + Vector3(0.5, 1.0, 0.5)
    boss.setup(player, self, boss_kind)
    boss_arena_phase = 0
    boss_last_phase_health = 1.0
    arena_reward_granted = false
    add_child(boss)

func _on_boss_defeated(defeated_boss: VoxelBoss) -> void:
    if boss != defeated_boss:
        return
    boss_defeated = true
    boss_arena_phase = 3
    var defeated_kind := defeated_boss.boss_kind
    boss_defeat_counts[defeated_kind] = int(boss_defeat_counts.get(defeated_kind, 0)) + 1
    var arena: Dictionary = boss_arena_definitions.get(defeated_kind, {})
    if not arena.is_empty() and not arena_reward_granted:
        var reward: Dictionary = arena.get("reward", {})
        var reward_item := int(reward.get("item_id", -1))
        var reward_count := int(reward.get("count", 0))
        if reward_item >= 0 and reward_count > 0:
            inventory[reward_item] = int(inventory.get(reward_item, 0)) + reward_count
        arena_reward_granted = true
    if defeated_kind == "Void Leviathan":
        generated_message = "Левиафан Пустоты повержен: астральный пояс очищен"
        inventory[ASTRAL_CRYSTAL] = int(inventory.get(ASTRAL_CRYSTAL, 0)) + 5
    else:
        generated_message = "Эхо-Владыка повержен: логово очищено"
        inventory[SALT_CRYSTAL] = int(inventory.get(SALT_CRYSTAL, 0)) + 3
    _refresh_inventory_panel()

func _spawn_mobs() -> void:
    if not mob_spawn_enabled:
        return
    var spawn_count := 10
    if difficulty_mode == "calm":
        spawn_count = 6
    elif difficulty_mode == "severe":
        spawn_count = 14
    elif difficulty_mode == "ironbound":
        spawn_count = 16
    for i in range(spawn_count):
        var x := randi_range(2, WORLD_SIZE_X - 3)
        var z := randi_range(2, WORLD_SIZE_Z - 3)
        if _is_starter_meadow_cell(x, z):
            continue
        var y := float(_highest_solid_y(x, z) + 1)
        var biome := _biome_for(x, z)
        var mob := VoxelMobScript.new()
        var kind := "EchoCrawler"
        if external_biome_definitions.has(biome):
            kind = str(external_biome_definitions[biome].get("spawn_mob", kind))
        if biome == BIOME_RIFT: kind = "RiftStalker"
        elif biome == BIOME_ECHO: kind = "Dweller"
        elif biome == BIOME_DUNES: kind = "AshMite"
        elif biome == BIOME_FROST: kind = "Goatman"
        elif biome == BIOME_FEN: kind = "Mimicer"
        elif biome == BIOME_WHISPER: kind = "WhisperEntity"
        elif biome == BIOME_ASTRAL:
            var astral_region := _astral_subregion(x, z)
            if astral_region == "Туманностное поле": kind = "StarSpirit"
            elif astral_region == "Чёрный карман": kind = "VoidSerpent"
            elif astral_region == "Кристаллический пояс": kind = "GuardianDrone"
        mob.name = "%s_%d" % [kind, mobs.size()]
        mob.configure_kind(kind)
        if external_mob_definitions.has(kind):
            mob.apply_external_definition(external_mob_definitions[kind])
        mob.position = Vector3(x, y, z)
        mob.target = player
        mob.world = self
        if not mob.mob_died.is_connected(_on_mob_died):
            mob.mob_died.connect(_on_mob_died)
        add_child(mob)
        mobs.append(mob)

func _on_mob_died(kind: String, pos: Vector3) -> void:
    mobs_defeated += 1
    mob_defeat_counts[kind] = int(mob_defeat_counts.get(kind, 0)) + 1
    if not achievements["first_mob"]:
        achievements["first_mob"] = true
        generated_message = "Достижение: Охотник!"
    var drop_id := FIBER
    match kind:
        "RiftStalker": drop_id = CRYSTAL
        "AshMite": drop_id = SAND
        "Dweller": drop_id = ECHO_SHARD
        "Goatman": drop_id = SALT_CRYSTAL
        "Mimicer": drop_id = MOSS
        "WhisperEntity": drop_id = WHISPER_SHARD
        "StarSpirit": drop_id = STAR_DUST
        "VoidSerpent": drop_id = VOID_SHARD
        "GuardianDrone": drop_id = ASTRAL_METAL
        _: drop_id = FOOD
    var pickup := VoxelPickupScript.new()
    pickup.setup(drop_id, 1, player, self)
    pickup.position = pos + Vector3(0, 0.5, 0)
    add_child(pickup)
    pickups.append(pickup)
    if generated_message == "":
        generated_message = "Побежден: " + kind
    _update_hud()
