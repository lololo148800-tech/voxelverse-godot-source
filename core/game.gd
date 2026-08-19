extends Node2D

const WORLD_RECT := Rect2(44.0, 112.0, 1192.0, 520.0)
const PLAYER_SPEED := 260.0
const WISE_TREE := Vector2(360.0, 330.0)
const ECHO_ZONE_RECT := Rect2(700.0, 150.0, 500.0, 470.0)
const ECHO_CENTER := Vector2(950.0, 360.0)
const ECHO_BLADE := Vector2(950.0, 360.0)

const TOUCH_JOYSTICK_CENTER := Vector2(150.0, 570.0)
const TOUCH_JOYSTICK_RADIUS := 92.0
const TOUCH_INTERACT := Vector2(1080.0, 570.0)
const TOUCH_GUIDE := Vector2(1190.0, 570.0)

var player_position := Vector2(420.0, 380.0)
var knowledge := 0
var guide_open := true
var message := "Подойди к Мудрому Древу и нажми E"
var dialogue_index := 0
var dialogue := [
    "Корни помнят дорогу, которую карты забыли.",
    "Не верь тишине в пещерах: она слушает первой.",
    "Сила требует цены. Сохраняй равновесие души.",
    "Когда ветер стихнет, ищи убежище до рассвета."
]

var touch_points: Dictionary = {}
var echo_zone_active := false
var echo_elapsed := 0.0
var echo_whisper_timer := 7.0
var echo_apparition_timer := 0.0
var echo_apparition_life := 0.0
var echo_apparition_position := Vector2.ZERO
var echo_fall_event_done := false
var echo_afterglow := 0.0
var echo_whisper := ""

var echo_blade_owned := false
var blade_curse_level := 0
var blade_curse_time := 0.0
var blade_curse_timer := 10.0

var echo_whispers := [
    "уходи",
    "ты сам пришёл",
    "мы тебя ждали",
    "ты виноват",
    "я всё ещё здесь",
    "не смотри назад"
]

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direction.y += 1.0

    var touch_direction := _get_touch_direction()
    if touch_direction.length_squared() > 0.0:
        direction += touch_direction
    if direction.length_squared() > 0.0:
        player_position += direction.normalized() * PLAYER_SPEED * delta
        player_position.x = clamp(player_position.x, WORLD_RECT.position.x + 24.0, WORLD_RECT.end.x - 24.0)
        player_position.y = clamp(player_position.y, WORLD_RECT.position.y + 24.0, WORLD_RECT.end.y - 24.0)

    _update_echo_wasteland(delta)
    _update_echo_blade(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
            if event.position.distance_to(TOUCH_INTERACT) <= 58.0:
                _primary_interact()
            elif event.position.distance_to(TOUCH_GUIDE) <= 58.0:
                _toggle_guide()
        else:
            touch_points.erase(event.index)
        queue_redraw()
    elif event is InputEventScreenDrag:
        touch_points[event.index] = event.position
        queue_redraw()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_B:
            _toggle_guide()
        elif event.keycode == KEY_E or event.keycode == KEY_F:
            _primary_interact()

func _get_touch_direction() -> Vector2:
    var result := Vector2.ZERO
    for point_variant in touch_points.values():
        var point: Vector2 = point_variant
        if point.x <= 360.0 and point.y >= 430.0:
            var touch_delta := point - TOUCH_JOYSTICK_CENTER
            if touch_delta.length() > 18.0:
                var distance: float = minf(touch_delta.length(), TOUCH_JOYSTICK_RADIUS)
                result = touch_delta.normalized() * (distance / TOUCH_JOYSTICK_RADIUS)
    return result

func _toggle_guide() -> void:
    guide_open = not guide_open
    queue_redraw()

func _primary_interact() -> void:
    if echo_zone_active and player_position.distance_to(ECHO_BLADE) < 72.0 and not echo_blade_owned:
        _take_echo_blade()
    else:
        _interact_with_tree()

func _interact_with_tree() -> void:
    if player_position.distance_to(WISE_TREE) < 115.0:
        knowledge += 1
        dialogue_index = (dialogue_index + 1) % dialogue.size()
        message = dialogue[dialogue_index]
    elif echo_zone_active:
        message = "Эхо слышит тебя. Найди Клинок в центре Пустоши."
    else:
        message = "Подойди к Мудрому Древу ближе"
    queue_redraw()

func _take_echo_blade() -> void:
    echo_blade_owned = true
    blade_curse_level = 0
    blade_curse_time = 0.0
    blade_curse_timer = 6.0
    message = "Ты поднял Клинок Эха. Он помнит тебя."
    echo_whisper = "он всё ещё смотрит"
    queue_redraw()

func _update_echo_wasteland(delta: float) -> void:
    var inside := ECHO_ZONE_RECT.has_point(player_position)
    if inside and not echo_zone_active:
        echo_zone_active = true
        echo_elapsed = 0.0
        echo_whisper_timer = 3.0
        echo_apparition_timer = 5.0
        echo_fall_event_done = false
        echo_whisper = ""
        message = "Пустошь Эха открылась. Найди выход или Клинок."
    elif not inside and echo_zone_active:
        echo_zone_active = false
        echo_afterglow = 8.0
        echo_apparition_life = 0.0
        message = "Пустошь исчезла. Но эхо осталось."

    if echo_zone_active:
        echo_elapsed += delta
        echo_whisper_timer -= delta
        echo_apparition_timer -= delta
        if echo_whisper_timer <= 0.0:
            echo_whisper = echo_whispers[int(echo_elapsed) % echo_whispers.size()]
            message = echo_whisper
            echo_whisper_timer = maxf(4.0, 12.0 - echo_elapsed * 0.18)
        if echo_apparition_timer <= 0.0:
            echo_apparition_timer = 8.0
            echo_apparition_life = 3.0
            echo_apparition_position = player_position + Vector2(100.0, -34.0)
        if echo_apparition_life > 0.0:
            echo_apparition_life -= delta
            echo_apparition_position = player_position + Vector2(100.0, -34.0 + sin(echo_elapsed * 2.0) * 8.0)
        if echo_elapsed >= 18.0 and not echo_fall_event_done:
            echo_fall_event_done = true
            message = "Земля исчезает под ногами. Эхо забирает тебя глубже."
    elif echo_afterglow > 0.0:
        echo_afterglow -= delta
        if echo_afterglow <= 0.0:
            echo_whisper = ""

func _update_echo_blade(delta: float) -> void:
    if not echo_blade_owned:
        return
    blade_curse_time += delta
    blade_curse_timer -= delta
    var next_level := clampi(int(blade_curse_time / 45.0), 0, 5)
    if next_level > blade_curse_level:
        blade_curse_level = next_level
        message = "Клинок Эха усилил проклятие: уровень %d/5" % blade_curse_level
        echo_whisper = "он всё ещё смотрит"
        blade_curse_timer = 8.0
    if blade_curse_timer <= 0.0:
        blade_curse_timer = maxf(7.0, 18.0 - float(blade_curse_level) * 2.0)
        if blade_curse_level >= 2:
            echo_whisper = "ты забрал меня"
            message = echo_whisper

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("07101f"))
    draw_rect(Rect2(0.0, 0.0, 1280.0, 82.0), Color("111f3a"))
    draw_string(ThemeDB.fallback_font, Vector2(44.0, 50.0), "VOXELVERSE 2.0", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(342.0, 48.0), "Integrity Recovery Build", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("8fdcff"))
    draw_string(ThemeDB.fallback_font, Vector2(1080.0, 48.0), "Knowledge: %d" % knowledge, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("ffd76e"))

    draw_rect(WORLD_RECT, Color("101d28"), true)
    for x in range(int(WORLD_RECT.position.x), int(WORLD_RECT.end.x), 40):
        draw_line(Vector2(x, WORLD_RECT.position.y), Vector2(x, WORLD_RECT.end.y), Color(0.18, 0.31, 0.34, 0.28), 1.0)
    for y in range(int(WORLD_RECT.position.y), int(WORLD_RECT.end.y), 40):
        draw_line(Vector2(WORLD_RECT.position.x, y), Vector2(WORLD_RECT.end.x, y), Color(0.18, 0.31, 0.34, 0.28), 1.0)

    _draw_tree(WISE_TREE)
    _draw_echo_zone()
    draw_circle(player_position, 18.0, Color("64d8ff"))
    draw_circle(player_position, 10.0, Color("d9f8ff"))
    draw_string(ThemeDB.fallback_font, player_position + Vector2(-24.0, 38.0), "Player", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("d9f8ff"))

    draw_rect(Rect2(62.0, 650.0, 1160.0, 48.0), Color(0.04, 0.09, 0.15, 0.92), true)
    draw_string(ThemeDB.fallback_font, Vector2(82.0, 681.0), message, HORIZONTAL_ALIGNMENT_LEFT, 900.0, 18, Color("d6e8ef"))
    draw_string(ThemeDB.fallback_font, Vector2(1028.0, 681.0), "WASD · E/F · B", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("8fb8c8"))
    _draw_mobile_controls()

    if guide_open:
        draw_rect(Rect2(62.0, 130.0, 520.0, 190.0), Color(0.04, 0.07, 0.13, 0.96), true)
        draw_rect(Rect2(62.0, 130.0, 520.0, 190.0), Color("5cccf2"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(88.0, 164.0), "SOULBOUND GUIDE BOOK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("ffd76e"))
        draw_string(ThemeDB.fallback_font, Vector2(88.0, 200.0), "Движение: WASD, стрелки или джойстик", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("d6e8ef"))
        draw_string(ThemeDB.fallback_font, Vector2(88.0, 228.0), "Мудрое Древо: подойди и нажми E", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("d6e8ef"))
        draw_string(ThemeDB.fallback_font, Vector2(88.0, 256.0), "Пустошь: войди в тёмную зону справа", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("d6e8ef"))
        draw_string(ThemeDB.fallback_font, Vector2(88.0, 284.0), "Клинок: найди центр и нажми F или E", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("d6e8ef"))

func _draw_echo_zone() -> void:
    var zone_color := Color(0.10, 0.02, 0.15, 0.34) if not echo_zone_active else Color(0.20, 0.01, 0.12, 0.64)
    draw_rect(ECHO_ZONE_RECT, zone_color, true)
    var border_color := Color("703d86") if not echo_zone_active else Color("db4d80")
    draw_rect(ECHO_ZONE_RECT, border_color, false, 3.0)
    draw_string(ThemeDB.fallback_font, ECHO_ZONE_RECT.position + Vector2(22.0, 32.0), "ПУСТОШЬ ЭХА", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("f09ab7"))
    draw_string(ThemeDB.fallback_font, ECHO_ZONE_RECT.position + Vector2(22.0, 58.0), "вход усиливает давление", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("c98aa9"))

    if not echo_blade_owned:
        draw_line(ECHO_BLADE + Vector2(-18.0, 18.0), ECHO_BLADE + Vector2(18.0, -18.0), Color("d8e9ff"), 8.0)
        draw_line(ECHO_BLADE + Vector2(-8.0, 22.0), ECHO_BLADE + Vector2(28.0, -14.0), Color("e35d91"), 3.0)
        draw_string(ThemeDB.fallback_font, ECHO_BLADE + Vector2(-52.0, 52.0), "Клинок Эха", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("f0b2d0"))

    if echo_apparition_life > 0.0:
        draw_circle(echo_apparition_position, 22.0, Color(0.01, 0.01, 0.02, 0.92))
        draw_circle(echo_apparition_position + Vector2(-7.0, -3.0), 3.0, Color("e84d74"))
        draw_circle(echo_apparition_position + Vector2(7.0, -3.0), 3.0, Color("e84d74"))
        draw_string(ThemeDB.fallback_font, echo_apparition_position + Vector2(-42.0, 42.0), "ты", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("cf6d8d"))

    if echo_whisper != "":
        draw_string(ThemeDB.fallback_font, ECHO_ZONE_RECT.position + Vector2(24.0, 96.0), "«%s»" % echo_whisper, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("ed9ab5"))
    if echo_zone_active:
        draw_string(ThemeDB.fallback_font, ECHO_ZONE_RECT.position + Vector2(24.0, 126.0), "Время внутри: %.0f с" % echo_elapsed, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("c89ab5"))
    if echo_blade_owned:
        draw_string(ThemeDB.fallback_font, ECHO_ZONE_RECT.position + Vector2(24.0, 154.0), "Клинок Эха · проклятие %d/5" % blade_curse_level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("ff789c"))

func _draw_mobile_controls() -> void:
    draw_circle(TOUCH_JOYSTICK_CENTER, TOUCH_JOYSTICK_RADIUS, Color(0.04, 0.10, 0.16, 0.78))
    draw_arc(TOUCH_JOYSTICK_CENTER, TOUCH_JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.36, 0.80, 0.95, 0.85), 3.0)
    draw_circle(TOUCH_JOYSTICK_CENTER + _get_touch_direction() * 52.0, 34.0, Color(0.36, 0.80, 0.95, 0.86))
    draw_circle(TOUCH_INTERACT, 52.0, Color(0.18, 0.38, 0.31, 0.90))
    draw_arc(TOUCH_INTERACT, 52.0, 0.0, TAU, 40, Color(0.58, 0.92, 0.72, 0.95), 3.0)
    draw_string(ThemeDB.fallback_font, TOUCH_INTERACT + Vector2(-12.0, 10.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color("e8fff0"))
    draw_circle(TOUCH_GUIDE, 52.0, Color(0.25, 0.25, 0.48, 0.90))
    draw_arc(TOUCH_GUIDE, 52.0, 0.0, TAU, 40, Color(0.76, 0.72, 1.0, 0.95), 3.0)
    draw_string(ThemeDB.fallback_font, TOUCH_GUIDE + Vector2(-12.0, 10.0), "B", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color("f3efff"))

func _draw_tree(position: Vector2) -> void:
    draw_circle(position + Vector2(0.0, -72.0), 92.0, Color("214b43"))
    draw_circle(position + Vector2(-58.0, -28.0), 62.0, Color("2c6651"))
    draw_circle(position + Vector2(58.0, -30.0), 62.0, Color("2a5a4b"))
    draw_rect(Rect2(position.x - 24.0, position.y - 30.0, 48.0, 150.0), Color("75482b"), true)
    draw_line(position + Vector2(-8.0, 5.0), position + Vector2(-50.0, 86.0), Color("a06738"), 8.0)
    draw_line(position + Vector2(8.0, 6.0), position + Vector2(48.0, 82.0), Color("a06738"), 8.0)
    draw_circle(position + Vector2(-16.0, -78.0), 7.0, Color("f7d36a"))
    draw_circle(position + Vector2(16.0, -78.0), 7.0, Color("f7d36a"))
    draw_arc(position + Vector2(0.0, -54.0), 24.0, 0.2, 2.9, 20, Color("f7d36a"), 4.0)
    draw_string(ThemeDB.fallback_font, position + Vector2(-84.0, 145.0), "Ancient Wise Tree", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("b8f2d1"))
