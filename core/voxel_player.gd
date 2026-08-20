class_name VoxelPlayer
extends CharacterBody3D

const WALK_SPEED: float = 5.5
const SPRINT_SPEED: float = 8.0
const JUMP_SPEED: float = 6.5
const GRAVITY: float = 18.0
const MOUSE_SENSITIVITY: float = 0.0025
const MAX_HEALTH: float = 20.0
const MAX_HUNGER: float = 20.0
const MAX_THIRST: float = 20.0
const MAX_ENERGY: float = 20.0
const MAX_MANA: float = 100.0

signal survival_changed
signal player_died
signal damage_taken(amount: float, source: String)

var camera: Camera3D
var yaw: float = -0.58
var pitch: float = -0.08
var look_enabled: bool = true
var touch_move_index: int = -1
var touch_look_index: int = -1
var break_touch_index: int = -1
var touch_move_origin := Vector2.ZERO
var touch_move_vector := Vector2.ZERO
var touch_last_look := Vector2.ZERO

var health: float = MAX_HEALTH
var hunger: float = MAX_HUNGER
var thirst: float = MAX_THIRST
var energy: float = MAX_ENERGY
var mana: float = MAX_MANA
var spell_cooldown: float = 0.0
var difficulty: String = "standard"
var hardcore: bool = false
var armor_equipped: bool = false
var armor_durability: int = 0
var armor_rating: float = 0.0
var barrier_points: float = 0.0
var astral_mode: bool = false
var creative_mode: bool = false
var avatar_profile: Dictionary = {"style": "Разведчик", "palette": "Пепельная медь", "mark": "Сигил Рубежа"}
var dead: bool = false
var respawn_position := Vector3.ZERO
var survival_tick: float = 0.0
var weakness_timer: float = 0.0
var slowness_timer: float = 0.0
var spawn_protection_timer: float = 0.0
var fear_level: float = 0.0
var fear_timer: float = 0.0
var movement_input_magnitude: float = 0.0
var last_horizontal_speed: float = 0.0
var movement_diagnostic_timer: float = 0.0

func _ready() -> void:
    camera = Camera3D.new()
    camera.name = "PlayerCamera"
    camera.position = Vector3(0.0, 1.62, 0.0)
    camera.rotation.x = pitch
    camera.current = true
    camera.fov = 72.0
    add_child(camera)
    respawn_position = global_position
    _ensure_movement_input_actions()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ensure_movement_input_actions() -> void:
    var bindings: Dictionary = {
        "move_left": KEY_A,
        "move_right": KEY_D,
        "move_forward": KEY_W,
        "move_back": KEY_S,
        "jump": KEY_SPACE
    }
    for action_name in bindings.keys():
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
        var bound := false
        for event in InputMap.action_get_events(action_name):
            if event is InputEventKey and int(event.physical_keycode) == int(bindings[action_name]):
                bound = true
                break
        if not bound:
            var key_event := InputEventKey.new()
            key_event.physical_keycode = bindings[action_name]
            InputMap.action_add_event(action_name, key_event)
    for action_name in bindings.keys():
        if not InputMap.has_action(action_name) or InputMap.action_get_events(action_name).is_empty():
            push_error("ОТСУТСТВУЕТ input action: " + str(action_name))

func set_avatar_profile(profile: Dictionary) -> void:
    var allowed_styles := ["Разведчик", "Инженер", "Пилигрим"]
    var allowed_palettes := ["Пепельная медь", "Мятный свет", "Астральный индиго", "Песчаный янтарь"]
    var allowed_marks := ["Без эмблемы", "Сигил Рубежа", "Звёздный узел", "Эхо-метка"]
    var style := str(profile.get("style", avatar_profile["style"]))
    var palette := str(profile.get("palette", avatar_profile["palette"]))
    var mark := str(profile.get("mark", avatar_profile["mark"]))
    if style not in allowed_styles:
        style = "Разведчик"
    if palette not in allowed_palettes:
        palette = "Пепельная медь"
    if mark not in allowed_marks:
        mark = "Сигил Рубежа"
    avatar_profile = {"style": style, "palette": palette, "mark": mark}
    set_meta("avatar_profile", avatar_profile)

func configure_survival(difficulty_name: String = "standard", hardcore_mode: bool = false) -> void:
    difficulty = difficulty_name
    hardcore = hardcore_mode
    health = MAX_HEALTH
    hunger = MAX_HUNGER
    thirst = MAX_THIRST
    energy = MAX_ENERGY
    mana = MAX_MANA
    spell_cooldown = 0.0
    spawn_protection_timer = 4.0
    fear_level = 0.0
    fear_timer = 0.0
    dead = false
    survival_tick = 0.0
    survival_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * MOUSE_SENSITIVITY
        pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -1.45, 1.45)
        rotation.y = yaw
        camera.rotation.x = pitch
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        look_enabled = not look_enabled
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if look_enabled else Input.MOUSE_MODE_VISIBLE)
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        look_enabled = true
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    elif event is InputEventScreenTouch:
        var viewport_size := get_viewport().get_visible_rect().size
        if event.pressed:
            var action_surface: bool = event.position.x > viewport_size.x * 0.66 and event.position.y > viewport_size.y * 0.60
            if action_surface:
                if event.position.x > viewport_size.x * 0.83 and event.position.y < viewport_size.y * 0.80:
                    touch_jump()
                elif event.position.x > viewport_size.x * 0.72 and event.position.y < viewport_size.y * 0.80 and get_parent().has_method("_place_target"):
                    get_parent().call("_place_target")
                elif event.position.x > viewport_size.x * 0.83 and get_parent().has_method("_begin_block_break"):
                    break_touch_index = event.index
                    get_parent().call("_begin_block_break")
                elif get_parent().has_method("_attack_nearby_mob"):
                    get_parent().call("_attack_nearby_mob")
            elif event.position.x < viewport_size.x * 0.45 and event.position.y > viewport_size.y * 0.52 and touch_move_index < 0:
                touch_move_index = event.index
                touch_move_origin = event.position
                touch_move_vector = Vector2.ZERO
            elif touch_look_index < 0:
                touch_look_index = event.index
                touch_last_look = event.position
        else:
            if event.index == touch_move_index:
                touch_move_index = -1
                touch_move_vector = Vector2.ZERO
            if event.index == touch_look_index:
                touch_look_index = -1
            if event.index == break_touch_index:
                break_touch_index = -1
                if get_parent().has_method("_end_block_break"):
                    get_parent().call("_end_block_break")
    elif event is InputEventScreenDrag:
        if event.index == touch_move_index:
            touch_move_vector = (event.position - touch_move_origin).limit_length(100.0) / 100.0
        elif event.index == touch_look_index:
            var look_delta: Vector2 = event.position - touch_last_look
            touch_last_look = event.position
            yaw -= look_delta.x * MOUSE_SENSITIVITY * 1.8
            pitch = clampf(pitch - look_delta.y * MOUSE_SENSITIVITY * 1.8, -1.45, 1.45)
            rotation.y = yaw
            camera.rotation.x = pitch

func touch_jump() -> void:
    if dead:
        return
    if creative_mode or astral_mode:
        velocity.y = JUMP_SPEED
    elif _is_in_water():
        velocity.y = 3.4
    elif is_on_floor():
        velocity.y = JUMP_SPEED

func _is_in_water() -> bool:
    var world := get_parent()
    if world == null or not world.has_method("_get_block"):
        return false
    var base := Vector3i(floori(global_position.x), floori(global_position.y + 0.15), floori(global_position.z))
    for offset in [Vector3i.ZERO, Vector3i.UP, Vector3i(0, 2, 0)]:
        var block_type: int = int(world.call("_get_block", base + offset))
        if block_type == 50 or block_type == 51:
            return true
    return false

func set_creative_mode(active: bool) -> void:
    creative_mode = active
    if creative_mode:
        health = MAX_HEALTH
        hunger = MAX_HUNGER
        thirst = MAX_THIRST
        energy = MAX_ENERGY
        mana = MAX_MANA
        spell_cooldown = 0.0
        dead = false
        armor_equipped = false

func set_astral_mode(active: bool) -> void:
    astral_mode = active
    if not astral_mode and not is_on_floor():
        velocity.y = minf(velocity.y, 2.0)

func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        return

    weakness_timer = maxf(0.0, weakness_timer - delta)
    slowness_timer = maxf(0.0, slowness_timer - delta)
    spawn_protection_timer = maxf(0.0, spawn_protection_timer - delta)
    fear_timer = maxf(0.0, fear_timer - delta)
    fear_level = move_toward(fear_level, 0.0, delta * (2.0 if fear_timer <= 0.0 else 0.35))
    spell_cooldown = maxf(0.0, spell_cooldown - delta)
    if not dead:
        mana = minf(MAX_MANA, mana + delta * (1.5 if creative_mode else 0.7))

    var input_vector := Vector2.ZERO
    if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vector.x -= 1.0
    if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vector.x += 1.0
    if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vector.y -= 1.0
    if Input.is_action_pressed("move_back") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vector.y += 1.0
    input_vector += touch_move_vector
    input_vector = input_vector.limit_length(1.0)
    movement_input_magnitude = input_vector.length()

    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    var move_direction := (right * input_vector.x) + (forward * -input_vector.y)
    move_direction.y = 0.0
    move_direction = move_direction.normalized() if move_direction.length_squared() > 0.0 else Vector3.ZERO

    var in_water := _is_in_water()
    var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
    if in_water and not creative_mode:
        speed *= 0.68
    if astral_mode:
        speed *= 0.72
    if slowness_timer > 0.0 and not creative_mode:
        speed *= 0.62
    var previous_vertical_velocity: float = velocity.y
    velocity.x = move_direction.x * speed
    velocity.z = move_direction.z * speed
    if creative_mode:
        velocity.y = 4.0 if Input.is_key_pressed(KEY_SPACE) else (-4.0 if Input.is_key_pressed(KEY_CTRL) else 0.0)
    elif astral_mode:
        if Input.is_key_pressed(KEY_SPACE):
            velocity.y = minf(velocity.y + 7.0 * delta, 5.0)
        elif Input.is_key_pressed(KEY_CTRL):
            velocity.y = maxf(velocity.y - 7.0 * delta, -5.0)
        else:
            velocity.y = move_toward(velocity.y, 0.0, GRAVITY * 0.12 * delta)
    elif in_water:
        velocity.y = move_toward(velocity.y, -0.55, GRAVITY * 0.42 * delta)
    elif not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_action_pressed("jump") or Input.is_key_pressed(KEY_SPACE):
        velocity.y = JUMP_SPEED
    else:
        velocity.y = -0.2
    move_and_slide()
    last_horizontal_speed = Vector2(velocity.x, velocity.z).length()
    movement_diagnostic_timer = maxf(0.0, movement_diagnostic_timer - delta)
    if movement_input_magnitude > 0.2 and last_horizontal_speed < 0.2 and movement_diagnostic_timer <= 0.0:
        push_warning("VoxelPlayer: input detected but horizontal velocity is near zero; check collision or movement state")
        movement_diagnostic_timer = 2.0
    if not creative_mode and is_on_floor() and previous_vertical_velocity < -12.0:
        take_damage((absf(previous_vertical_velocity) - 12.0) * 0.35, "Падение")
    _update_survival(delta, input_vector.length())

func _update_survival(delta: float, movement_amount: float) -> void:
    if creative_mode:
        survival_changed.emit()
        return
    survival_tick += delta
    if survival_tick < 5.0:
        return
    survival_tick = 0.0
    var drain := 0.35 + movement_amount * 0.15
    var sprint_bonus := 0.2 if Input.is_key_pressed(KEY_SHIFT) else 0.0
    
    hunger = maxf(0.0, hunger - (drain + sprint_bonus))
    thirst = maxf(0.0, thirst - (drain * 1.2 + sprint_bonus))
    
    if movement_amount > 0.1:
        energy = maxf(0.0, energy - (0.1 + sprint_bonus))
    else:
        energy = minf(MAX_ENERGY, energy + 0.5)
        
    if hunger <= 0.0 or thirst <= 0.0:
        take_damage(1.0, "Истощение")
    elif hunger >= 16.0 and thirst >= 16.0:
        heal(0.25)
        
    survival_changed.emit()

func take_damage(amount: float, source: String = "") -> void:
    if dead or creative_mode or spawn_protection_timer > 0.0:
        return
    if dead:
        return
    var incoming := maxf(0.0, amount)
    if barrier_points > 0.0:
        var absorbed := minf(barrier_points, incoming)
        barrier_points -= absorbed
        incoming -= absorbed
        if incoming <= 0.0:
            survival_changed.emit()
            return
    var mitigated_amount := incoming
    if armor_equipped and armor_durability > 0:
        mitigated_amount *= (1.0 - armor_rating)
        armor_durability = maxi(0, armor_durability - 1)
        if armor_durability <= 0:
            armor_equipped = false
            armor_rating = 0.0
    var multiplier := 1.0
    if weakness_timer > 0.0:
        multiplier *= 0.65
    match difficulty:
        "calm":
            multiplier = 0.5
        "severe":
            multiplier = 1.35
        "ironbound":
            multiplier = 1.75
    health = maxf(0.0, health - mitigated_amount * multiplier)
    damage_taken.emit(mitigated_amount * multiplier, source)
    survival_changed.emit()
    if health <= 0.0:
        _die(source)

func apply_whisper_debuff(duration: float = 4.0) -> void:
    if creative_mode or dead:
        return
    weakness_timer = maxf(weakness_timer, duration)
    slowness_timer = maxf(slowness_timer, duration)
    survival_changed.emit()

func apply_fear(amount: float = 10.0, duration: float = 4.0) -> void:
    if creative_mode or dead:
        return
    fear_level = clampf(fear_level + maxf(0.0, amount), 0.0, 100.0)
    fear_timer = maxf(fear_timer, maxf(0.0, duration))
    if fear_level >= 35.0:
        weakness_timer = maxf(weakness_timer, minf(6.0, duration))
    survival_changed.emit()

func clear_fear() -> void:
    fear_level = 0.0
    fear_timer = 0.0
    survival_changed.emit()

func set_armor(active: bool, durability: int = 80) -> void:
    armor_equipped = active and durability > 0
    armor_durability = maxi(0, durability) if armor_equipped else 0
    armor_rating = 0.22 if armor_equipped else 0.0
    survival_changed.emit()

func can_cast_spell(cost: float) -> bool:
    return not dead and (creative_mode or (mana >= cost and spell_cooldown <= 0.0))

func spend_mana(cost: float, cooldown: float) -> bool:
    if not can_cast_spell(cost):
        return false
    if not creative_mode:
        mana = maxf(0.0, mana - cost)
    spell_cooldown = maxf(0.0, cooldown)
    survival_changed.emit()
    return true

func restore_mana(amount: float) -> void:
    mana = minf(MAX_MANA, mana + maxf(0.0, amount))
    survival_changed.emit()

func heal(amount: float) -> void:
    if dead:
        return
    health = minf(MAX_HEALTH, health + amount)

func grant_barrier(amount: float) -> void:
    if dead:
        return
    barrier_points = minf(24.0, barrier_points + maxf(0.0, amount))
    survival_changed.emit()

func consume_food(amount: float = 5.0) -> bool:
    if dead or hunger >= MAX_HUNGER:
        return false
    hunger = minf(MAX_HUNGER, hunger + amount)
    heal(1.0)
    survival_changed.emit()
    return true

func _die(source: String) -> void:
    dead = true
    velocity = Vector3.ZERO
    player_died.emit()

func respawn() -> void:
    if hardcore:
        return
    global_position = respawn_position
    velocity = Vector3.ZERO
    health = MAX_HEALTH
    hunger = MAX_HUNGER * 0.7
    mana = MAX_MANA
    spell_cooldown = 0.0
    dead = false
    survival_tick = 0.0
    survival_changed.emit()

func get_view_origin() -> Vector3:
    return camera.global_position

func get_view_direction() -> Vector3:
    return -camera.global_transform.basis.z
