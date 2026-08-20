extends Control

const REFERENCE_WIDTH := 1640.0
const REFERENCE_HEIGHT := 720.0

var selected_slot: int = 0
var hotbar_items: Array[int] = []
var health_ratio: float = 1.0
var hunger_ratio: float = 1.0
var thirst_ratio: float = 1.0
var energy_ratio: float = 1.0
var _last_draw_size := Vector2.ZERO

# Reference-aligned, original palette: translucent grey-green controls over a bright world.
const PANEL_FILL := Color(0.34, 0.39, 0.36, 0.34)
const PANEL_FILL_DARK := Color(0.10, 0.14, 0.12, 0.34)
const PANEL_BORDER := Color(0.06, 0.09, 0.08, 0.78)
const PANEL_INNER := Color(0.74, 0.80, 0.74, 0.28)
const ICON := Color(0.07, 0.11, 0.09, 0.92)
const ICON_SOFT := Color(0.16, 0.22, 0.18, 0.80)
const SELECTED := Color(0.92, 0.96, 0.88, 0.96)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and size != _last_draw_size:
        _last_draw_size = size
        queue_redraw()

func set_selected_slot(slot_index: int) -> void:
    var next_slot := clampi(slot_index, 0, 8)
    if selected_slot == next_slot:
        return
    selected_slot = next_slot
    queue_redraw()

func set_hotbar_items(items: Array[int]) -> void:
    if hotbar_items == items:
        return
    hotbar_items = items.duplicate()
    queue_redraw()

func set_survival_values(current_health: float, max_health: float, current_hunger: float, max_hunger: float, current_thirst: float = 20.0, max_thirst: float = 20.0, current_energy: float = 20.0, max_energy: float = 20.0) -> void:
    health_ratio = clampf(current_health / maxf(max_health, 0.1), 0.0, 1.0)
    hunger_ratio = clampf(current_hunger / maxf(max_hunger, 0.1), 0.0, 1.0)
    thirst_ratio = clampf(current_thirst / maxf(max_thirst, 0.1), 0.0, 1.0)
    energy_ratio = clampf(current_energy / maxf(max_energy, 0.1), 0.0, 1.0)
    queue_redraw()

func _draw() -> void:
    var viewport_size := size
    if viewport_size.x < 640.0 or viewport_size.y < 360.0:
        return
    var scale_factor := clampf(minf(viewport_size.x / REFERENCE_WIDTH, viewport_size.y / REFERENCE_HEIGHT), 0.72, 1.15)
    # The supplied reference keeps the gameplay HUD quiet: no permanent text panel or heart rows.
    _draw_top_strip(viewport_size, scale_factor)
    _draw_survival_bars(viewport_size, scale_factor)
    _draw_left_pad(viewport_size, scale_factor)
    _draw_action_buttons(viewport_size, scale_factor)
    _draw_hotbar(viewport_size, scale_factor)
    _draw_first_person_hand(viewport_size, scale_factor)

func _draw_survival_bars(viewport_size: Vector2, scale_factor: float) -> void:
    var origin := Vector2(28.0, 76.0) * scale_factor
    var width := 228.0 * scale_factor
    var height := 13.0 * scale_factor
    var gap := 7.0 * scale_factor
    _draw_status_bar(origin, width, height, health_ratio, Color("d84f5c"), Color("ffb1a7"))
    _draw_status_bar(origin + Vector2(0.0, height + gap), width, height, hunger_ratio, Color("d9a447"), Color("ffe3a0"))
    _draw_status_bar(origin + Vector2(0.0, (height + gap) * 2.0), width, height, thirst_ratio, Color("3d9ed1"), Color("9bdfff"))
    _draw_status_bar(origin + Vector2(0.0, (height + gap) * 3.0), width, height, energy_ratio, Color("5cbf78"), Color("b4f5c6"))

func _draw_status_bar(origin: Vector2, width: float, height: float, ratio: float, fill_color: Color, edge_color: Color) -> void:
    var background := Rect2(origin, Vector2(width, height))
    draw_rect(background, Color(0.02, 0.035, 0.03, 0.74), true)
    draw_rect(Rect2(origin, Vector2(width * clampf(ratio, 0.0, 1.0), height)), fill_color, true)
    draw_rect(background, edge_color, false, 2.0)

func _draw_top_strip(viewport_size: Vector2, scale_factor: float) -> void:
    var icon_size := 52.0 * scale_factor
    var gap := 5.0 * scale_factor
    var total_width := icon_size * 4.0 + gap * 3.0
    var start := Vector2((viewport_size.x - total_width) * 0.5, 3.0 * scale_factor)
    for index in range(4):
        var rect := Rect2(start + Vector2((icon_size + gap) * index, 0.0), Vector2(icon_size, icon_size))
        _draw_reference_button(rect, scale_factor)
        _draw_top_icon(rect, index, scale_factor)

func _draw_top_icon(rect: Rect2, index: int, scale_factor: float) -> void:
    var center := rect.get_center()
    var width := 3.0 * scale_factor
    if index == 0:
        draw_arc(center, rect.size.x * 0.24, 0.15, TAU - 0.15, 20, ICON, width)
        draw_circle(center, rect.size.x * 0.075, ICON)
    elif index == 1:
        draw_line(center + Vector2(-11.0, 11.0) * scale_factor, center + Vector2(11.0, -11.0) * scale_factor, ICON, width)
        draw_circle(center + Vector2(-11.0, 11.0) * scale_factor, 4.0 * scale_factor, ICON)
        draw_circle(center + Vector2(11.0, -11.0) * scale_factor, 4.0 * scale_factor, ICON)
        draw_line(center + Vector2(-12.0, -12.0) * scale_factor, center + Vector2(-2.0, -2.0) * scale_factor, ICON, width)
    elif index == 2:
        draw_rect(Rect2(center - Vector2(15.0, 11.0) * scale_factor, Vector2(30.0, 22.0) * scale_factor), ICON, false, width)
        for dot in range(3):
            draw_circle(center + Vector2((dot - 1) * 8.0, 1.0) * scale_factor, 2.5 * scale_factor, ICON)
    else:
        for line_index in range(3):
            var y := rect.position.y + (15.0 + line_index * 9.0) * scale_factor
            draw_line(Vector2(rect.position.x + 13.0 * scale_factor, y), Vector2(rect.end.x - 12.0 * scale_factor, y), ICON, width)

func _draw_left_pad(viewport_size: Vector2, scale_factor: float) -> void:
    var pad_size := Vector2(232.0, 224.0) * scale_factor
    var pad_rect := Rect2(Vector2(64.0, 344.0) * scale_factor, pad_size)
    draw_rect(pad_rect, PANEL_FILL_DARK, true)
    draw_rect(pad_rect, PANEL_BORDER, false, 3.0 * scale_factor)
    draw_rect(pad_rect.grow(-7.0 * scale_factor), PANEL_INNER, false, 2.0 * scale_factor)
    var center := pad_rect.get_center() + Vector2(0.0, 5.0 * scale_factor)
    var cross := Color(0.06, 0.10, 0.08, 0.24)
    draw_line(center + Vector2(-70.0, 0.0) * scale_factor, center + Vector2(70.0, 0.0) * scale_factor, cross, 2.0 * scale_factor)
    draw_line(center + Vector2(0.0, -70.0) * scale_factor, center + Vector2(0.0, 70.0) * scale_factor, cross, 2.0 * scale_factor)
    draw_circle(center, 13.0 * scale_factor, Color(0.76, 0.82, 0.76, 0.55))
    draw_circle(center, 13.0 * scale_factor, PANEL_BORDER, false, 2.0 * scale_factor)
    _draw_arrow(center + Vector2(0.0, -55.0) * scale_factor, Vector2.UP, scale_factor)
    _draw_arrow(center + Vector2(-55.0, 0.0) * scale_factor, Vector2.LEFT, scale_factor)
    _draw_arrow(center + Vector2(55.0, 0.0) * scale_factor, Vector2.RIGHT, scale_factor)
    _draw_arrow(center + Vector2(0.0, 55.0) * scale_factor, Vector2.DOWN, scale_factor)
    # Separate action/health touch button under the pad, as in the supplied layout.
    var small_rect := Rect2(Vector2(370.0, 502.0) * scale_factor, Vector2(64.0, 64.0) * scale_factor)
    _draw_reference_button(small_rect, scale_factor)
    var small_center := small_rect.get_center()
    draw_rect(Rect2(small_center - Vector2(15.0, 4.0) * scale_factor, Vector2(30.0, 8.0) * scale_factor), ICON, true)
    draw_rect(Rect2(small_center - Vector2(4.0, 15.0) * scale_factor, Vector2(8.0, 30.0) * scale_factor), ICON, true)

func _draw_arrow(center: Vector2, direction: Vector2, scale_factor: float) -> void:
    var side := Vector2(-direction.y, direction.x)
    var tip := center + direction * 13.0 * scale_factor
    var base := center - direction * 8.0 * scale_factor
    draw_colored_polygon(PackedVector2Array([tip, base + side * 7.0 * scale_factor, base - side * 7.0 * scale_factor]), ICON_SOFT)

func _draw_action_buttons(viewport_size: Vector2, scale_factor: float) -> void:
    var button_size := Vector2(68.0, 68.0) * scale_factor
    var right_x := viewport_size.x / scale_factor - 240.0
    var upper := Rect2(Vector2(right_x + 98.0, 198.0) * scale_factor, button_size)
    var middle := Rect2(Vector2(right_x, 286.0) * scale_factor, button_size)
    var lower := Rect2(Vector2(right_x + 98.0, 344.0) * scale_factor, button_size)
    _draw_reference_button(upper, scale_factor)
    _draw_reference_button(middle, scale_factor)
    _draw_reference_button(lower, scale_factor)
    _draw_arrow(upper.get_center(), Vector2.UP, scale_factor)
    _draw_arrow(lower.get_center(), Vector2.DOWN, scale_factor)
    var center := middle.get_center()
    _draw_arrow(center + Vector2(-9.0, 0.0) * scale_factor, Vector2.RIGHT, scale_factor)
    _draw_arrow(center + Vector2(10.0, 0.0) * scale_factor, Vector2.RIGHT, scale_factor)

func _draw_reference_button(rect: Rect2, scale_factor: float) -> void:
    draw_rect(rect, PANEL_FILL, true)
    draw_rect(rect, PANEL_BORDER, false, 3.0 * scale_factor)
    draw_rect(rect.grow(-5.0 * scale_factor), PANEL_INNER, false, 2.0 * scale_factor)

func _draw_hotbar(viewport_size: Vector2, scale_factor: float) -> void:
    var slot_size := 60.0 * scale_factor
    var gap := 4.0 * scale_factor
    var total_width := slot_size * 9.0 + gap * 8.0
    var origin := Vector2((viewport_size.x - total_width) * 0.5, viewport_size.y - slot_size - 8.0 * scale_factor)
    for index in range(9):
        var rect := Rect2(origin + Vector2((slot_size + gap) * index, 0.0), Vector2(slot_size, slot_size))
        draw_rect(rect, Color(0.04, 0.07, 0.06, 0.86), true)
        draw_rect(rect, Color(0.08, 0.11, 0.09, 0.98), false, 4.0 * scale_factor)
        draw_rect(rect.grow(-6.0 * scale_factor), Color(0.20, 0.28, 0.18, 0.46), true)
        draw_rect(rect.grow(-2.0 * scale_factor), SELECTED if index == selected_slot else Color(0.42, 0.48, 0.42, 0.84), false, 2.0 * scale_factor)
        if index < hotbar_items.size():
            _draw_subtle_hotbar_icon(rect, hotbar_items[index], scale_factor)

func _draw_subtle_hotbar_icon(rect: Rect2, item_id: int, scale_factor: float) -> void:
    var center := rect.get_center()
    var width := 2.4 * scale_factor
    var icon_color := Color(0.78, 0.86, 0.72, 0.84)
    var icon_kind: int = absi(item_id) % 8
    match icon_kind:
        0:
            draw_colored_polygon(PackedVector2Array([center + Vector2(-15.0, 12.0) * scale_factor, center + Vector2(-10.0, -7.0) * scale_factor, center + Vector2(12.0, -13.0) * scale_factor, center + Vector2(16.0, 10.0) * scale_factor]), icon_color)
        1:
            draw_rect(Rect2(center - Vector2(14.0, 11.0) * scale_factor, Vector2(28.0, 22.0) * scale_factor), icon_color, true)
            draw_line(center + Vector2(-14.0, -3.0) * scale_factor, center + Vector2(14.0, -3.0) * scale_factor, Color(0.24, 0.34, 0.22, 0.9), width)
        2:
            draw_colored_polygon(PackedVector2Array([center + Vector2(-14.0, 12.0) * scale_factor, center + Vector2(-9.0, -12.0) * scale_factor, center + Vector2(8.0, -9.0) * scale_factor, center + Vector2(14.0, 12.0) * scale_factor]), icon_color)
        3:
            draw_rect(Rect2(center - Vector2(9.0, 16.0) * scale_factor, Vector2(18.0, 32.0) * scale_factor), icon_color, true)
            draw_line(center + Vector2(-4.0, -13.0) * scale_factor, center + Vector2(-4.0, 13.0) * scale_factor, Color(0.25, 0.32, 0.22, 0.9), width)
        4:
            draw_circle(center, 14.0 * scale_factor, icon_color)
            draw_circle(center + Vector2(4.0, -4.0) * scale_factor, 3.0 * scale_factor, Color(0.26, 0.34, 0.23, 0.9))
        5:
            draw_line(center + Vector2(-14.0, 10.0) * scale_factor, center + Vector2(0.0, -14.0) * scale_factor, icon_color, 4.0 * scale_factor)
            draw_line(center + Vector2(0.0, -14.0) * scale_factor, center + Vector2(14.0, 10.0) * scale_factor, icon_color, 4.0 * scale_factor)
        6:
            draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -16.0) * scale_factor, center + Vector2(14.0, 0.0) * scale_factor, center + Vector2(0.0, 16.0) * scale_factor, center + Vector2(-14.0, 0.0) * scale_factor]), icon_color)
        7:
            draw_circle(center, 14.0 * scale_factor, icon_color, false, width)
            draw_line(center + Vector2(-10.0, 8.0) * scale_factor, center + Vector2(10.0, -8.0) * scale_factor, icon_color, width)
        _:
            for dot in range(3):
                draw_circle(center + Vector2((dot - 1) * 9.0, 0.0) * scale_factor, 3.0 * scale_factor, icon_color)

func _draw_first_person_hand(viewport_size: Vector2, scale_factor: float) -> void:
    var base := Vector2(viewport_size.x / scale_factor - 212.0, viewport_size.y / scale_factor - 42.0) * scale_factor
    # Original blocky sleeve silhouette, kept close to the supplied reference framing.
    var sleeve := PackedVector2Array([base + Vector2(0.0, 50.0) * scale_factor, base + Vector2(18.0, 2.0) * scale_factor, base + Vector2(74.0, -22.0) * scale_factor, base + Vector2(122.0, 8.0) * scale_factor, base + Vector2(98.0, 66.0) * scale_factor, base + Vector2(20.0, 76.0) * scale_factor])
    draw_colored_polygon(sleeve, Color(0.20, 0.27, 0.48, 0.96))
    draw_polyline(sleeve, Color(0.08, 0.10, 0.16, 0.78), 2.0 * scale_factor)
    var cuff := PackedVector2Array([base + Vector2(34.0, 6.0) * scale_factor, base + Vector2(80.0, -12.0) * scale_factor, base + Vector2(105.0, 16.0) * scale_factor, base + Vector2(70.0, 35.0) * scale_factor])
    draw_colored_polygon(cuff, Color(0.68, 0.54, 0.42, 0.95))
    draw_polyline(cuff, Color(0.20, 0.16, 0.13, 0.66), 2.0 * scale_factor)
