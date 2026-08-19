extends Control

const BG := Color("111312")
const PANEL := Color(0.08, 0.09, 0.10, 0.92)
const PANEL_ALT := Color(0.20, 0.21, 0.22, 0.94)
const TEXT := Color("f2f0ea")
const MUTED := Color("c4c3be")
const COPPER := Color("5a3ee6")
const TURQUOISE := Color("4cae2c")
const WARNING := Color("f0d36a")
const LIGHT_BAR := Color("e6e6e4")
const DARK_INK := Color("202124")

var content_panel: Panel
var topbar_panel: Panel
var nav_panel: Panel
var home_panel: Control
var page_title: Label
var page_subtitle: Label
var nav_buttons: Array[Button] = []
var page: String = "expeditions"
var world_name_edit: LineEdit
var seed_edit: LineEdit
var difficulty_select: OptionButton
var mode_select: OptionButton
var hardcore_check: CheckBox
var anomalies_check: CheckBox
var autosave_check: CheckBox
var biome_rarity_select: OptionButton
var simulation_distance_select: OptionButton
var day_speed_select: OptionButton
var mob_spawn_check: CheckBox
var structures_check: CheckBox
var caves_check: CheckBox
var pvp_check: CheckBox
var backup_slots_select: OptionButton
var status_label: Label
var settings_quality: OptionButton
var settings_shaders: CheckBox
var settings_distance: OptionButton
var settings_touch: OptionButton
var settings_hud: OptionButton
var settings_camera_sway: CheckBox
var settings_autosave: CheckBox
var online_address_edit: LineEdit
var online_port_edit: LineEdit
var online_name_edit: LineEdit
var online_voice_check: CheckBox
var online_friend_label: Label
var online_lan_select: OptionButton
var avatar_style_select: OptionButton
var transition_overlay: Control
var avatar_palette_select: OptionButton
var avatar_mark_select: OptionButton
var generated_seed_value: int = 2048
var seed_edit_was_changed: bool = false

func _ready() -> void:
    _build_shell()
    if NetworkSession != null and not NetworkSession.status_changed.is_connected(_on_network_status):
        NetworkSession.status_changed.connect(_on_network_status)
    if NetworkSession != null and not NetworkSession.discovery_updated.is_connected(_on_discovery_updated):
        NetworkSession.discovery_updated.connect(_on_discovery_updated)
    if NetworkSession != null and not NetworkSession.friend_code_changed.is_connected(_on_friend_code_changed):
        NetworkSession.friend_code_changed.connect(_on_friend_code_changed)
    if VoiceChat != null and not VoiceChat.status_changed.is_connected(_on_voice_status):
        VoiceChat.status_changed.connect(_on_voice_status)
    _show_page("home")

func _build_shell() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = BG
    add_child(background)
    var backdrop := TextureRect.new()
    backdrop.name = "ReferenceCaveBackdrop"
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.texture = load("res://assets/ui_standard/assets/ui/main_menu_cave_backdrop.png")
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.modulate = Color(0.96, 0.96, 0.92, 1.0)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)

    var atmosphere := ColorRect.new()
    atmosphere.name = "CaveAtmosphereOverlay"
    atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    atmosphere.color = Color(0.02, 0.02, 0.02, 0.18)
    atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(atmosphere)

    home_panel = Control.new()
    home_panel.name = "HomePanel"
    home_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(home_panel)

    topbar_panel = Panel.new()
    topbar_panel.name = "ReferenceTopBar"
    topbar_panel.position = Vector2(0, 0)
    topbar_panel.size = Vector2(1640, 72)
    topbar_panel.add_theme_stylebox_override("panel", _style(LIGHT_BAR, Color("303236"), 2))
    add_child(topbar_panel)

    var title := Label.new()
    title.position = Vector2(430, 12)
    title.size = Vector2(780, 48)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.text = "ПЕПЕЛЬНЫЙ РУБЕЖ"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", DARK_INK)
    topbar_panel.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(28, 25)
    subtitle.text = "VOXELVERSE"
    subtitle.add_theme_font_size_override("font_size", 15)
    subtitle.add_theme_color_override("font_color", DARK_INK)
    topbar_panel.add_child(subtitle)

    var save_status := Label.new()
    save_status.position = Vector2(1370, 23)
    save_status.text = "●  АРХИВ ОФЛАЙН"
    save_status.add_theme_font_size_override("font_size", 14)
    save_status.add_theme_color_override("font_color", DARK_INK)
    topbar_panel.add_child(save_status)

    nav_panel = Panel.new()
    nav_panel.name = "ReferenceNavigation"
    nav_panel.position = Vector2(0, 72)
    nav_panel.size = Vector2(302, 648)
    nav_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.09, 0.10, 0.96), Color("585b60"), 2))
    add_child(nav_panel)

    var nav_title := Label.new()
    nav_title.position = Vector2(26, 26)
    nav_title.text = "ЭКСПЕДИЦИОННЫЙ ЦЕНТР"
    nav_title.add_theme_font_size_override("font_size", 15)
    nav_title.add_theme_color_override("font_color", MUTED)
    nav_panel.add_child(nav_title)

    var labels := ["ЭКСПЕДИЦИИ", "МАСТЕР МИРА", "СНАРЯЖЕНИЕ", "ПАРАМЕТРЫ", "ОНЛАЙН"]
    var pages := ["expeditions", "forge", "loadout", "settings", "online"]
    for index in labels.size():
        var button := _nav_button(labels[index])
        button.position = Vector2(18, 78 + index * 60)
        button.pressed.connect(_show_page.bind(pages[index]))
        nav_panel.add_child(button)
        nav_buttons.append(button)

    var note := Label.new()
    note.position = Vector2(26, 390)
    note.size = Vector2(225, 160)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.text = "Здесь начинается маршрут над бесконечным туманом.\n\nСобирай реликты, укрепляй маяки и сохраняй точки восстановления перед экспериментальными правилами."
    note.add_theme_font_size_override("font_size", 14)
    note.add_theme_color_override("font_color", MUTED)
    nav_panel.add_child(note)

    var footer := Label.new()
    footer.position = Vector2(26, 580)
    footer.text = "VoxelVerse core · offline milestone"
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color("718089"))
    nav_panel.add_child(footer)

    content_panel = Panel.new()
    content_panel.name = "ReferenceContentPanel"
    content_panel.position = Vector2(330, 92)
    content_panel.size = Vector2(1280, 610)
    content_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.05, 0.06, 0.38), Color("77797a"), 2))
    add_child(content_panel)

    page_title = Label.new()
    page_title.position = Vector2(34, 28)
    page_title.add_theme_font_size_override("font_size", 27)
    page_title.add_theme_color_override("font_color", TEXT)
    content_panel.add_child(page_title)

    page_subtitle = Label.new()
    page_subtitle.position = Vector2(36, 68)
    page_subtitle.add_theme_font_size_override("font_size", 14)
    page_subtitle.add_theme_color_override("font_color", MUTED)
    content_panel.add_child(page_subtitle)

    status_label = Label.new()
    status_label.position = Vector2(36, 510)
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.add_theme_color_override("font_color", WARNING)
    content_panel.add_child(status_label)

func _show_page(next_page: String) -> void:
    page = next_page
    if is_instance_valid(home_panel):
        home_panel.visible = next_page == "home"
    if is_instance_valid(nav_panel):
        nav_panel.visible = next_page != "home"
    if is_instance_valid(content_panel):
        content_panel.visible = next_page != "home"
    for child in content_panel.get_children():
        if child != page_title and child != page_subtitle and child != status_label:
            child.queue_free()
    for child in home_panel.get_children():
        child.queue_free()
    for index in nav_buttons.size():
        var selected: bool = ["expeditions", "forge", "loadout", "settings", "online"][index] == page
        nav_buttons[index].modulate = Color.WHITE if selected else Color("e0ebe3")
    status_label.text = ""
    if next_page == "home":
        _build_home_page()
        return
    match page:
        "expeditions":
            _build_expeditions_page()
        "forge":
            _build_forge_page()
        "loadout":
            _build_loadout_page()
        "settings":
            _build_settings_page()
        "online":
            _build_online_page()

func _build_home_page() -> void:
    var shade := ColorRect.new()
    shade.position = Vector2(515, 92)
    shade.size = Vector2(610, 574)
    shade.color = Color(0.01, 0.01, 0.01, 0.52)
    home_panel.add_child(shade)

    var logo := Label.new()
    logo.position = Vector2(430, 126)
    logo.size = Vector2(780, 82)
    logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    logo.text = "ПЕПЕЛЬНЫЙ РУБЕЖ"
    logo.add_theme_font_size_override("font_size", 48)
    logo.add_theme_color_override("font_color", Color("f2eee5"))
    home_panel.add_child(logo)

    var subtitle := Label.new()
    subtitle.position = Vector2(520, 210)
    subtitle.size = Vector2(600, 30)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.text = "VOXELVERSE · ORIGINAL SURVIVAL SANDBOX"
    subtitle.add_theme_font_size_override("font_size", 14)
    subtitle.add_theme_color_override("font_color", Color("d1b267"))
    home_panel.add_child(subtitle)

    var buttons := [
        ["НАЧАТЬ", "expeditions"],
        ["НАСТРОЙКИ", "settings"],
        ["ДРУЗЬЯ / ОНЛАЙН", "online"],
        ["ГАРДЕРОБНАЯ", "loadout"]
    ]
    for index in buttons.size():
        var action := _reference_home_button(buttons[index][0])
        action.position = Vector2(650, 270 + index * 72)
        action.pressed.connect(_show_page.bind(buttons[index][1]))
        home_panel.add_child(action)

    var offline := Label.new()
    offline.position = Vector2(540, 584)
    offline.size = Vector2(560, 28)
    offline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    offline.text = "ОФЛАЙН ДОСТУПЕН ВСЕГДА · FRIEND/LAN И VOICE — ПО ЖЕЛАНИЮ"
    offline.add_theme_font_size_override("font_size", 12)
    offline.add_theme_color_override("font_color", Color("c9c2ad"))
    home_panel.add_child(offline)

    var version := Label.new()
    version.position = Vector2(36, 682)
    version.text = "VoxelVerse · Ashen Frontier · 2.0"
    version.add_theme_font_size_override("font_size", 12)
    version.add_theme_color_override("font_color", Color("e2d9c7"))
    home_panel.add_child(version)

func _reference_home_button(text_value: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(340, 58)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", DARK_INK)
    button.add_theme_stylebox_override("normal", _style(Color(0.90, 0.90, 0.89, 0.96), Color("242529"), 2))
    button.add_theme_stylebox_override("hover", _style(Color("a7db82"), Color("3f9f2f"), 2))
    button.add_theme_stylebox_override("pressed", _style(Color("6ca94e"), Color("1d4c19"), 2))
    return button

func _build_expeditions_page() -> void:
    page_title.text = "МИРЫ"
    page_subtitle.text = "Локальные сохранения, друзья и серверные маршруты в одном экране."

    var tabs := HBoxContainer.new()
    tabs.position = Vector2(28, 92)
    tabs.size = Vector2(1030, 46)
    tabs.add_theme_constant_override("separation", 4)
    content_panel.add_child(tabs)
    for tab_text in ["МИРЫ (1)", "ДРУЗЬЯ", "СЕРВЕРЫ"]:
        var tab := _secondary_button(tab_text)
        tab.custom_minimum_size = Vector2(330, 42)
        tabs.add_child(tab)

    var create_button := Button.new()
    create_button.text = "СОЗДАТЬ МИР"
    create_button.custom_minimum_size = Vector2(220, 46)
    create_button.position = Vector2(1050, 92)
    create_button.add_theme_font_size_override("font_size", 16)
    create_button.add_theme_color_override("font_color", Color("ffffff"))
    create_button.add_theme_stylebox_override("normal", _style(Color("3f9f2f"), Color("77c45d"), 2))
    create_button.pressed.connect(_show_page.bind("forge"))
    content_panel.add_child(create_button)

    var cards := [
        ["МОЙ МИР · ПЕРВЫЙ МАЯК", "Выживание", "Стандартная экспедиция", "Seed: случайный · 51 биом", "17.4 МБ"],
        ["ПЕПЕЛЬНЫЙ РУБЕЖ", "Творческий", "Богатый мир", "Seed: сохранён вручную", "8.2 МБ"]
    ]
    for index in cards.size():
        var card := Panel.new()
        card.position = Vector2(28, 162 + index * 190)
        card.size = Vector2(1230, 166)
        card.add_theme_stylebox_override("panel", _style(PANEL_ALT, Color("66686b"), 2))
        content_panel.add_child(card)

        var preview := TextureRect.new()
        preview.position = Vector2(14, 14)
        preview.size = Vector2(220, 138)
        preview.texture = load("res://assets/ui_standard/assets/ui/menu_backdrop.png")
        preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        preview.modulate = Color(0.90, 1.0, 0.86, 1.0)
        card.add_child(preview)

        var name_label := Label.new()
        name_label.position = Vector2(258, 20)
        name_label.text = cards[index][0]
        name_label.add_theme_font_size_override("font_size", 22)
        name_label.add_theme_color_override("font_color", TEXT)
        card.add_child(name_label)

        var mode_label := Label.new()
        mode_label.position = Vector2(258, 62)
        mode_label.text = "%s    ·    %s\n%s\nРазмер сохранения: %s" % [cards[index][1], cards[index][2], cards[index][3], cards[index][4]]
        mode_label.add_theme_font_size_override("font_size", 15)
        mode_label.add_theme_color_override("font_color", MUTED)
        card.add_child(mode_label)

        var edit := _secondary_button("РЕДАКТИРОВАТЬ")
        edit.position = Vector2(980, 42)
        edit.custom_minimum_size = Vector2(220, 46)
        card.add_child(edit)

    var footer := Label.new()
    footer.position = Vector2(32, 566)
    footer.text = "Сохранения локальны. Сетевая игра подключается отдельно через вкладку ОНЛАЙН."
    footer.add_theme_font_size_override("font_size", 14)
    footer.add_theme_color_override("font_color", WARNING)
    content_panel.add_child(footer)

func _build_forge_page() -> void:
    generated_seed_value = _generate_new_seed()
    page_title.text = "СОЗДАТЬ МИР"
    page_subtitle.text = "Настройки ниже записываются до генерации и становятся правилами сохранённой экспедиции."

    var form := GridContainer.new()
    form.position = Vector2(40, 112)
    form.size = Vector2(800, 348)
    form.columns = 2
    form.add_theme_constant_override("h_separation", 18)
    form.add_theme_constant_override("v_separation", 8)
    content_panel.add_child(form)

    world_name_edit = LineEdit.new()
    world_name_edit.placeholder_text = "Название мира"
    world_name_edit.text = "Пепельный Рубеж"
    world_name_edit.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("ИМЯ МИРА", world_name_edit))

    seed_edit = LineEdit.new()
    seed_edit.placeholder_text = "Случайный seed или введи свой"
    seed_edit.text = str(generated_seed_value)
    seed_edit.custom_minimum_size = Vector2(380, 34)
    seed_edit.text_changed.connect(_on_seed_text_changed)
    form.add_child(_field_with_label("СИД МИРА · НОВЫЙ ПРИ КАЖДОМ СОЗДАНИИ", seed_edit))

    difficulty_select = OptionButton.new()
    for value in ["Спокойный маршрут", "Стандартная экспедиция", "Суровая граница", "Железное правило"]:
        difficulty_select.add_item(value)
    difficulty_select.selected = 1
    difficulty_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("СЛОЖНОСТЬ", difficulty_select))

    mode_select = OptionButton.new()
    mode_select.add_item("Выживание")
    mode_select.add_item("Творческий тест")
    mode_select.selected = 0
    mode_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("РЕЖИМ", mode_select))

    biome_rarity_select = OptionButton.new()
    for value in ["Классический набор", "Стандартный атлас", "Богатый мир"]:
        biome_rarity_select.add_item(value)
    biome_rarity_select.selected = 1
    biome_rarity_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("РЕДКОСТЬ БИОМОВ", biome_rarity_select))

    simulation_distance_select = OptionButton.new()
    for value in ["Короткая", "Средняя", "Дальняя", "Экспедиционная"]:
        simulation_distance_select.add_item(value)
    simulation_distance_select.selected = 1
    simulation_distance_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("ДАЛЬНОСТЬ СИМУЛЯЦИИ", simulation_distance_select))

    day_speed_select = OptionButton.new()
    for value in ["0.5× медленно", "1× стандарт", "2× быстро"]:
        day_speed_select.add_item(value)
    day_speed_select.selected = 1
    day_speed_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("СКОРОСТЬ ДНЯ/НОЧИ", day_speed_select))

    backup_slots_select = OptionButton.new()
    for value in ["1 резерв", "2 резерва", "5 резервов"]:
        backup_slots_select.add_item(value)
    backup_slots_select.selected = 1
    backup_slots_select.custom_minimum_size = Vector2(380, 34)
    form.add_child(_field_with_label("РЕЗЕРВНЫЕ СЛОТЫ", backup_slots_select))

    hardcore_check = CheckBox.new()
    hardcore_check.text = "One-Life / hardcore"
    hardcore_check.add_theme_color_override("font_color", TEXT)
    form.add_child(hardcore_check)

    anomalies_check = CheckBox.new()
    anomalies_check.text = "Погодные аномалии"
    anomalies_check.button_pressed = true
    anomalies_check.add_theme_color_override("font_color", TEXT)
    form.add_child(anomalies_check)

    autosave_check = CheckBox.new()
    autosave_check.text = "Автосохранение"
    autosave_check.button_pressed = true
    autosave_check.add_theme_color_override("font_color", TEXT)
    form.add_child(autosave_check)

    mob_spawn_check = CheckBox.new()
    mob_spawn_check.text = "Спавн мобов"
    mob_spawn_check.button_pressed = true
    mob_spawn_check.add_theme_color_override("font_color", TEXT)
    form.add_child(mob_spawn_check)

    structures_check = CheckBox.new()
    structures_check.text = "Структуры и данжи"
    structures_check.button_pressed = true
    structures_check.add_theme_color_override("font_color", TEXT)
    form.add_child(structures_check)

    caves_check = CheckBox.new()
    caves_check.text = "Пещеры"
    caves_check.button_pressed = true
    caves_check.add_theme_color_override("font_color", TEXT)
    form.add_child(caves_check)

    pvp_check = CheckBox.new()
    pvp_check.text = "PvP разрешён только в online"
    pvp_check.button_pressed = false
    pvp_check.add_theme_color_override("font_color", TEXT)
    form.add_child(pvp_check)

    var start := _primary_button("ЗАПУСТИТЬ ЭКСПЕДИЦИЮ")
    start.position = Vector2(40, 488)
    start.pressed.connect(_on_start_expedition)
    content_panel.add_child(start)

    var warning := Label.new()
    warning.position = Vector2(310, 500)
    warning.text = "Seed создан заново автоматически; измени поле, если нужен повторяемый мир"
    warning.add_theme_font_size_override("font_size", 13)
    warning.add_theme_color_override("font_color", WARNING)
    content_panel.add_child(warning)

func _build_loadout_page() -> void:
    page_title.text = "ГАРДЕРОБНАЯ"
    page_subtitle.text = "Выбери оригинальный силуэт, палитру и эмблему экспедиции."

    var hero := Panel.new()
    hero.position = Vector2(28, 92)
    hero.size = Vector2(1230, 260)
    hero.add_theme_stylebox_override("panel", _style(Color(0.03, 0.04, 0.04, 0.72), Color("6b6d70"), 2))
    content_panel.add_child(hero)

    var left_arrow := _secondary_button("‹")
    left_arrow.position = Vector2(292, 98)
    left_arrow.custom_minimum_size = Vector2(56, 56)
    hero.add_child(left_arrow)
    var right_arrow := _secondary_button("›")
    right_arrow.position = Vector2(884, 98)
    right_arrow.custom_minimum_size = Vector2(56, 56)
    hero.add_child(right_arrow)

    var current := _skin_figure(Color("4b718a"), Color("24344d"), Color("b8d5e4"))
    current.position = Vector2(570, 22)
    hero.add_child(current)

    var current_title := Label.new()
    current_title.position = Vector2(430, 194)
    current_title.size = Vector2(340, 28)
    current_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    current_title.text = "ЭТО ТЕКУЩИЙ СКИН"
    current_title.add_theme_font_size_override("font_size", 17)
    current_title.add_theme_color_override("font_color", TEXT)
    hero.add_child(current_title)

    var controls := HBoxContainer.new()
    controls.position = Vector2(332, 224)
    controls.size = Vector2(560, 38)
    controls.add_theme_constant_override("separation", 8)
    hero.add_child(controls)
    avatar_style_select = _select_with_options(["Разведчик", "Инженер", "Пилигрим"], 0)
    avatar_palette_select = _select_with_options(["Пепельная медь", "Мятный свет", "Астральный индиго", "Песчаный янтарь"], 0)
    avatar_mark_select = _select_with_options(["Без эмблемы", "Сигил Рубежа", "Звёздный узел", "Эхо-метка"], 1)
    controls.add_child(avatar_style_select)
    controls.add_child(avatar_palette_select)
    controls.add_child(avatar_mark_select)

    var catalogue_title := Label.new()
    catalogue_title.position = Vector2(30, 374)
    catalogue_title.text = "РЕКОМЕНДУЕМЫЕ СКИНЫ"
    catalogue_title.add_theme_font_size_override("font_size", 19)
    catalogue_title.add_theme_color_override("font_color", TEXT)
    content_panel.add_child(catalogue_title)

    var catalogue := HBoxContainer.new()
    catalogue.position = Vector2(28, 410)
    catalogue.size = Vector2(1190, 190)
    catalogue.add_theme_constant_override("separation", 12)
    content_panel.add_child(catalogue)
    catalogue.add_child(_skin_card("ПЕПЕЛЬНЫЙ СЛЕДОПЫТ", Color("7b5843"), Color("262b35"), "НОВИНКА"))
    catalogue.add_child(_skin_card("МЯТНЫЙ ИНЖЕНЕР", Color("5c8f86"), Color("20382f"), "ЭКИПИРОВКА"))
    catalogue.add_child(_skin_card("АСТРАЛЬНЫЙ КАРТОГРАФ", Color("7660a7"), Color("1b223d"), "ЭКСПЕДИЦИЯ"))
    catalogue.add_child(_skin_card("ПЕСЧАНЫЙ ПИЛИГРИМ", Color("b38a50"), Color("473424"), "БЕСПЛАТНО"))

func _skin_figure(body_color: Color, hair_color: Color, accent: Color) -> Control:
    var figure := Control.new()
    figure.custom_minimum_size = Vector2(150, 205)
    var shadow := ColorRect.new()
    shadow.position = Vector2(28, 188)
    shadow.size = Vector2(94, 9)
    shadow.color = Color(0, 0, 0, 0.42)
    figure.add_child(shadow)
    var head := ColorRect.new()
    head.position = Vector2(50, 12)
    head.size = Vector2(50, 50)
    head.color = Color("d3a37b")
    figure.add_child(head)
    var hair := ColorRect.new()
    hair.position = Vector2(50, 12)
    hair.size = Vector2(50, 16)
    hair.color = hair_color
    figure.add_child(hair)
    var torso := ColorRect.new()
    torso.position = Vector2(38, 66)
    torso.size = Vector2(74, 74)
    torso.color = body_color
    figure.add_child(torso)
    var emblem := ColorRect.new()
    emblem.position = Vector2(62, 88)
    emblem.size = Vector2(26, 26)
    emblem.color = accent
    figure.add_child(emblem)
    var arm_left := ColorRect.new()
    arm_left.position = Vector2(20, 70)
    arm_left.size = Vector2(18, 66)
    arm_left.color = body_color.darkened(0.18)
    figure.add_child(arm_left)
    var arm_right := ColorRect.new()
    arm_right.position = Vector2(112, 70)
    arm_right.size = Vector2(18, 66)
    arm_right.color = body_color.darkened(0.18)
    figure.add_child(arm_right)
    var leg_left := ColorRect.new()
    leg_left.position = Vector2(42, 140)
    leg_left.size = Vector2(28, 48)
    leg_left.color = hair_color
    figure.add_child(leg_left)
    var leg_right := ColorRect.new()
    leg_right.position = Vector2(80, 140)
    leg_right.size = Vector2(28, 48)
    leg_right.color = hair_color
    figure.add_child(leg_right)
    return figure

func _skin_card(title_text: String, body_color: Color, hair_color: Color, tag_text: String) -> Panel:
    var card := Panel.new()
    card.custom_minimum_size = Vector2(282, 176)
    card.add_theme_stylebox_override("panel", _style(PANEL_ALT, Color("62666b"), 2))
    var figure := _skin_figure(body_color, hair_color, Color("ded27e"))
    figure.scale = Vector2(0.52, 0.52)
    figure.position = Vector2(66, -2)
    card.add_child(figure)
    var title := Label.new()
    title.position = Vector2(12, 105)
    title.text = title_text
    title.add_theme_font_size_override("font_size", 13)
    title.add_theme_color_override("font_color", TEXT)
    card.add_child(title)
    var tag := Label.new()
    tag.position = Vector2(12, 137)
    tag.text = tag_text
    tag.add_theme_font_size_override("font_size", 12)
    tag.add_theme_color_override("font_color", Color("73df39"))
    card.add_child(tag)
    return card

func _build_online_page() -> void:
    page_title.text = "ОНЛАЙН · FRIEND / LAN"
    page_subtitle.text = "Friend code и LAN discovery для проверяемого ENet host/join; без внешнего relay и без выдуманного server browser."

    var form := VBoxContainer.new()
    form.position = Vector2(40, 112)
    form.size = Vector2(790, 220)
    form.add_theme_constant_override("separation", 7)
    content_panel.add_child(form)

    online_name_edit = LineEdit.new()
    online_name_edit.placeholder_text = "Имя хоста"
    online_name_edit.text = "Ashen Frontier host"
    online_name_edit.custom_minimum_size = Vector2(0, 34)
    form.add_child(_field_with_label("ИМЯ FRIEND / DEDICATED HOST", online_name_edit))

    online_address_edit = LineEdit.new()
    online_address_edit.placeholder_text = "Адрес хоста или сервера"
    online_address_edit.text = "127.0.0.1"
    online_address_edit.custom_minimum_size = Vector2(0, 34)
    form.add_child(_field_with_label("АДРЕС ДЛЯ JOIN / LAN", online_address_edit))

    online_port_edit = LineEdit.new()
    online_port_edit.placeholder_text = "24560"
    online_port_edit.text = str(NetworkSession.DEFAULT_PORT)
    online_port_edit.custom_minimum_size = Vector2(0, 34)
    form.add_child(_field_with_label("ПОРТ ENET", online_port_edit))

    online_voice_check = CheckBox.new()
    online_voice_check.text = "Voice chat: opt-in микрофон · F6 push-to-talk"
    online_voice_check.button_pressed = false
    online_voice_check.add_theme_color_override("font_color", TEXT)
    online_voice_check.toggled.connect(_on_voice_toggle)
    form.add_child(online_voice_check)

    online_friend_label = Label.new()
    online_friend_label.position = Vector2(42, 328)
    online_friend_label.text = "Friend code: —  ·  host ещё не запущен"
    online_friend_label.add_theme_font_size_override("font_size", 14)
    online_friend_label.add_theme_color_override("font_color", TURQUOISE)
    content_panel.add_child(online_friend_label)

    var host_button := _primary_button("СОЗДАТЬ HOST")
    host_button.position = Vector2(40, 356)
    host_button.pressed.connect(_on_host_online)
    content_panel.add_child(host_button)

    var join_button := _secondary_button("JOIN ПО АДРЕСУ")
    join_button.position = Vector2(310, 356)
    join_button.pressed.connect(_on_join_online)
    content_panel.add_child(join_button)

    var stop_button := _secondary_button("ОТКЛЮЧИТЬСЯ")
    stop_button.position = Vector2(580, 356)
    stop_button.pressed.connect(_on_stop_online)
    content_panel.add_child(stop_button)

    online_lan_select = OptionButton.new()
    online_lan_select.position = Vector2(40, 416)
    online_lan_select.size = Vector2(510, 38)
    online_lan_select.add_item("LAN discovery: нажми «Найти хосты»")
    content_panel.add_child(online_lan_select)

    var scan_button := _secondary_button("НАЙТИ LAN")
    scan_button.position = Vector2(570, 412)
    scan_button.pressed.connect(_on_lan_scan)
    content_panel.add_child(scan_button)

    var lan_join_button := _secondary_button("JOIN ВЫБРАННОГО")
    lan_join_button.position = Vector2(570, 462)
    lan_join_button.pressed.connect(_on_lan_join)
    content_panel.add_child(lan_join_button)

    var info := Label.new()
    info.position = Vector2(40, 466)
    info.size = Vector2(510, 78)
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.text = "Friend code работает для обнаруженных LAN-хостов; публичного relay и интернет-каталога серверов нет. Dedicated config: res://data/dedicated_server.json. Синхронизация survival/entity уже проверена вертикальным срезом, но полноценные аккаунты, NAT traversal и production voice security ещё не готовы."
    info.add_theme_font_size_override("font_size", 12)
    info.add_theme_color_override("font_color", WARNING)
    content_panel.add_child(info)

func _online_port() -> int:
    if is_instance_valid(online_port_edit) and online_port_edit.text.is_valid_int():
        return clampi(int(online_port_edit.text), 1024, 65535)
    return NetworkSession.DEFAULT_PORT

func _on_host_online() -> void:
    var host_name := online_name_edit.text.strip_edges() if is_instance_valid(online_name_edit) else "Ashen Frontier host"
    NetworkSession.start_lan_discovery()
    NetworkSession.host_game(_online_port(), host_name)
    _on_friend_code_changed(NetworkSession.friend_code)
    status_label.text = NetworkSession.last_status

func _on_join_online() -> void:
    var host := online_address_edit.text.strip_edges() if is_instance_valid(online_address_edit) else "127.0.0.1"
    NetworkSession.join_game(host, _online_port())
    status_label.text = NetworkSession.last_status

func _on_stop_online() -> void:
    NetworkSession.stop_online()
    _on_friend_code_changed("")
    status_label.text = NetworkSession.last_status

func _on_lan_scan() -> void:
    if NetworkSession.start_lan_discovery():
        _refresh_online_discovery(NetworkSession.get_discovered_servers())
    status_label.text = NetworkSession.last_status

func _on_lan_join() -> void:
    if not is_instance_valid(online_lan_select) or online_lan_select.selected <= 0:
        status_label.text = "Сначала выбери найденный LAN-host"
        return
    var record: Variant = online_lan_select.get_item_metadata(online_lan_select.selected)
    if record is Dictionary:
        NetworkSession.join_game(str(record.get("address", "127.0.0.1")), int(record.get("port", NetworkSession.DEFAULT_PORT)))
    status_label.text = NetworkSession.last_status

func _on_discovery_updated(servers: Array) -> void:
    _refresh_online_discovery(servers)

func _refresh_online_discovery(servers: Array) -> void:
    if not is_instance_valid(online_lan_select):
        return
    online_lan_select.clear()
    online_lan_select.add_item("Выбери LAN-host")
    for record_variant in servers:
        if record_variant is Dictionary:
            var record: Dictionary = record_variant
            var label := "%s · %s · %s" % [str(record.get("server_name", "Host")), str(record.get("friend_code", "AF-???-???")), str(record.get("address", "LAN"))]
            online_lan_select.add_item(label)
            online_lan_select.set_item_metadata(online_lan_select.item_count - 1, record)

func _on_friend_code_changed(code: String) -> void:
    if is_instance_valid(online_friend_label):
        online_friend_label.text = "Friend code: %s  ·  только LAN / direct host" % (code if not code.is_empty() else "—")

func _on_voice_toggle(active: bool) -> void:
    VoiceChat.set_enabled(active)
    status_label.text = VoiceChat.last_status

func _on_voice_status(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message

func _on_network_status(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message

func _build_settings_page() -> void:
    page_title.text = "ПАРАМЕТРЫ"
    page_subtitle.text = "Графика, управление, звук, доступность и диагностика."
    var form := VBoxContainer.new()
    form.position = Vector2(40, 116)
    form.size = Vector2(780, 350)
    form.add_theme_constant_override("separation", 8)
    content_panel.add_child(form)

    settings_quality = OptionButton.new()
    for value in ["Авто качество", "Слабый маяк", "Сбалансированный", "Дальний обзор", "Кинематографичный"]:
        settings_quality.add_item(value)
    settings_quality.selected = 2
    settings_quality.custom_minimum_size = Vector2(0, 38)
    form.add_child(_field_with_label("ГРАФИЧЕСКИЙ ПРОФИЛЬ", settings_quality))

    settings_shaders = CheckBox.new()
    settings_shaders.text = "Включить Astral sky shader и эффекты региона"
    settings_shaders.button_pressed = true
    settings_shaders.add_theme_color_override("font_color", TEXT)
    form.add_child(settings_shaders)

    settings_distance = OptionButton.new()
    for value in ["Короткая", "Средняя", "Дальняя", "Экспедиционная"]:
        settings_distance.add_item(value)
    settings_distance.selected = 1
    settings_distance.custom_minimum_size = Vector2(0, 38)
    form.add_child(_field_with_label("ДАЛЬНОСТЬ МИРА", settings_distance))

    settings_touch = OptionButton.new()
    for value in ["Классический экран", "Карманный экран", "Большие зоны"]:
        settings_touch.add_item(value)
    settings_touch.selected = 1
    settings_touch.custom_minimum_size = Vector2(0, 38)
    form.add_child(_field_with_label("РАСКЛАДКА УПРАВЛЕНИЯ", settings_touch))

    settings_hud = OptionButton.new()
    for value in ["Полный HUD", "Сжатый HUD", "Минимальный HUD"]:
        settings_hud.add_item(value)
    settings_hud.selected = 0
    settings_hud.custom_minimum_size = Vector2(0, 38)
    form.add_child(_field_with_label("ОТОБРАЖЕНИЕ ИНТЕРФЕЙСА", settings_hud))

    settings_camera_sway = CheckBox.new()
    settings_camera_sway.text = "Мягкое покачивание камеры"
    settings_camera_sway.button_pressed = true
    settings_camera_sway.add_theme_color_override("font_color", TEXT)
    form.add_child(settings_camera_sway)

    settings_autosave = CheckBox.new()
    settings_autosave.text = "Автосохранение перед опасным экспериментом"
    settings_autosave.button_pressed = true
    settings_autosave.add_theme_color_override("font_color", TEXT)
    form.add_child(settings_autosave)

    var save_button := _primary_button("СОХРАНИТЬ ПАРАМЕТРЫ")
    save_button.position = Vector2(40, 486)
    save_button.pressed.connect(_save_settings)
    content_panel.add_child(save_button)

    var reset := _secondary_button("ВЕРНУТЬ СТАНДАРТЫ")
    reset.position = Vector2(310, 486)
    reset.pressed.connect(_on_reset_settings)
    content_panel.add_child(reset)

func _save_settings() -> void:
    var data := {
        "quality": settings_quality.get_item_text(settings_quality.selected) if is_instance_valid(settings_quality) else "Сбалансированный",
        "shaders_enabled": settings_shaders.button_pressed if is_instance_valid(settings_shaders) else true,
        "distance": settings_distance.get_item_text(settings_distance.selected) if is_instance_valid(settings_distance) else "Средняя",
        "touch_layout": settings_touch.get_item_text(settings_touch.selected) if is_instance_valid(settings_touch) else "Карманный экран",
        "hud": settings_hud.get_item_text(settings_hud.selected) if is_instance_valid(settings_hud) else "Полный HUD",
        "camera_sway": settings_camera_sway.button_pressed if is_instance_valid(settings_camera_sway) else true,
        "autosave": settings_autosave.button_pressed if is_instance_valid(settings_autosave) else true
    }
    var file := FileAccess.open("user://ashen_frontier_settings.json", FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()
    status_label.text = "Параметры сохранены в локальный архив."

func _field_with_label(label_text: String, control: Control) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", MUTED)
    box.add_child(label)
    box.add_child(control)
    return box

func _select_with_options(options: Array[String], selected_index: int = 0) -> OptionButton:
    var select := OptionButton.new()
    select.custom_minimum_size = Vector2(235.0, 32.0)
    for option in options:
        select.add_item(option)
    if not options.is_empty():
        select.select(clampi(selected_index, 0, options.size() - 1))
    return select

func _nav_button(text_value: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size = Vector2(246, 46)
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_stylebox_override("normal", _style(Color(0.10, 0.15, 0.13, 0.92), Color("405845"), 1))
    button.add_theme_stylebox_override("hover", _style(Color(0.18, 0.28, 0.21, 0.96), TURQUOISE, 1))
    button.add_theme_stylebox_override("pressed", _style(Color(0.24, 0.34, 0.24, 0.98), TURQUOISE, 1))
    return button

func _primary_button(text_value: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(250, 48)
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color("fff5e8"))
    button.add_theme_stylebox_override("normal", _style(COPPER, COPPER, 1))
    return button

func _secondary_button(text_value: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(250, 48)
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_stylebox_override("normal", _style(PANEL_ALT, Color("52636c"), 1))
    return button

func _style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    return style

func _on_new_game() -> void:
    _show_page("forge")

func _on_start_expedition() -> void:
    var seed_text := seed_edit.text.strip_edges() if is_instance_valid(seed_edit) else ""
    var use_manual_seed := seed_edit_was_changed and not seed_text.is_empty() and seed_text.is_valid_int()
    var parsed_seed := int(seed_text) if use_manual_seed else _generate_new_seed()
    generated_seed_value = parsed_seed
    var world_title := world_name_edit.text.strip_edges() if is_instance_valid(world_name_edit) else "Пепельный Рубеж"
    if world_title.is_empty():
        world_title = "Пепельный Рубеж"
    world_title = world_title.left(40)
    var rarity_text := biome_rarity_select.get_item_text(biome_rarity_select.selected) if is_instance_valid(biome_rarity_select) else "Стандартный атлас"
    var biome_rarity := "classic" if rarity_text.contains("Класс") else ("rich" if rarity_text.contains("Богат") else "standard")
    var day_text := day_speed_select.get_item_text(day_speed_select.selected) if is_instance_valid(day_speed_select) else "1× стандарт"
    var day_speed := 0.5 if day_text.begins_with("0.5") else (2.0 if day_text.begins_with("2") else 1.0)
    var backup_text := backup_slots_select.get_item_text(backup_slots_select.selected) if is_instance_valid(backup_slots_select) else "2 резерва"
    var backup_count := 5 if backup_text.begins_with("5") else (1 if backup_text.begins_with("1") else 2)
    var data := {
        "seed": parsed_seed,
        "world_name": world_title,
        "difficulty": difficulty_select.get_item_text(difficulty_select.selected) if is_instance_valid(difficulty_select) else "Стандартная экспедиция",
        "mode": mode_select.get_item_text(mode_select.selected) if is_instance_valid(mode_select) else "Выживание",
        "hardcore": hardcore_check.button_pressed if is_instance_valid(hardcore_check) else false,
        "anomalies": anomalies_check.button_pressed if is_instance_valid(anomalies_check) else true,
        "autosave": autosave_check.button_pressed if is_instance_valid(autosave_check) else true,
        "biome_rarity": biome_rarity,
        "simulation_distance": simulation_distance_select.get_item_text(simulation_distance_select.selected) if is_instance_valid(simulation_distance_select) else "Средняя",
        "mob_spawns": mob_spawn_check.button_pressed if is_instance_valid(mob_spawn_check) else true,
        "structures": structures_check.button_pressed if is_instance_valid(structures_check) else true,
        "caves": caves_check.button_pressed if is_instance_valid(caves_check) else true,
        "pvp": pvp_check.button_pressed if is_instance_valid(pvp_check) else false,
        "day_night_speed": day_speed,
        "backup_slots": backup_count,
        "subtitles": true,
        "touch_layout": "Карманный экран",
        "hud_layout": "Полный HUD",
        "camera_sway": true,
        "avatar_profile": {
            "style": avatar_style_select.get_item_text(avatar_style_select.selected) if is_instance_valid(avatar_style_select) else "Разведчик",
            "palette": avatar_palette_select.get_item_text(avatar_palette_select.selected) if is_instance_valid(avatar_palette_select) else "Пепельная медь",
            "mark": avatar_mark_select.get_item_text(avatar_mark_select.selected) if is_instance_valid(avatar_mark_select) else "Сигил Рубежа"
        }
    }
    var file := FileAccess.open("user://ashen_frontier_world_config.json", FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()
    if FileAccess.file_exists("user://voxelverse_slot_1.json"):
        DirAccess.remove_absolute("user://voxelverse_slot_1.json")
    await _transition_to_world()

func _on_seed_text_changed(_text: String) -> void:
    seed_edit_was_changed = true

func _generate_new_seed() -> int:
    var entropy := "%d|%d|%s|%s|%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), OS.get_unique_id(), str(randi()), str(Time.get_ticks_msec())]
    var generated := absi(entropy.hash())
    if generated == generated_seed_value:
        generated = absi((entropy + "|reroll").hash())
    return maxi(1, generated)

func _on_load_game() -> void:
    await _transition_to_world()

func _transition_to_world() -> void:
    if is_instance_valid(transition_overlay):
        return
    transition_overlay = Control.new()
    transition_overlay.name = "LaunchTransition"
    transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    transition_overlay.z_index = 100
    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.79, 0.87, 0.82, 0.96)
    transition_overlay.add_child(backdrop)
    var card := Panel.new()
    card.position = Vector2(410, 250)
    card.size = Vector2(460, 168)
    card.add_theme_stylebox_override("panel", _style(Color("eef3ed"), Color("6c9484"), 2))
    transition_overlay.add_child(card)
    var title := Label.new()
    title.position = Vector2(32, 28)
    title.text = "ПЕПЕЛЬНЫЙ РУБЕЖ"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", TEXT)
    card.add_child(title)
    var status := Label.new()
    status.position = Vector2(34, 72)
    status.text = "Подготавливаем светлую экспедицию…"
    status.add_theme_font_size_override("font_size", 15)
    status.add_theme_color_override("font_color", MUTED)
    card.add_child(status)
    var detail := Label.new()
    detail.position = Vector2(34, 112)
    detail.text = "Мир, река и стартовая поляна загружаются"
    detail.add_theme_font_size_override("font_size", 12)
    detail.add_theme_color_override("font_color", TURQUOISE)
    card.add_child(detail)
    add_child(transition_overlay)
    await get_tree().process_frame
    get_tree().change_scene_to_file("res://core/voxel_world.tscn")

func _on_settings() -> void:
    _show_page("settings")

func _on_reset_settings() -> void:
    status_label.text = "Настройки возвращены к безопасному сбалансированному профилю."

func _on_exit() -> void:
    get_tree().quit()
