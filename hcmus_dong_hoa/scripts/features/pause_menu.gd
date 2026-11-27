extends "res://scripts/features/feature.gd"
# MENU TẠM DỪNG (ESC): mở khi đang rảnh ngoài khuôn viên để chỉnh âm lượng, tiếp tục hoặc về Menu chính.

const MAIN_MENU_SCENE := "res://scripts/menu/main_menu.tscn"
const SETTINGS_PATH := "user://settings.cfg"

var _layer: CanvasLayer
var _was_paused := false
var _cfg := ConfigFile.new()
var _vol_slider: HSlider
var _vol_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cfg.load(SETTINGS_PATH)
	_layer = CanvasLayer.new()
	_layer.layer = 25
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.visible = false
	add_child(_layer)
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var kc := k.keycode
	var pk := k.physical_keycode
	if _layer.visible:
		if kc == KEY_ESCAPE or pk == KEY_ESCAPE or kc == KEY_1 or kc == KEY_KP_1:
			_close_pause()
			get_viewport().set_input_as_handled()
		elif kc == KEY_2 or kc == KEY_KP_2:
			_go_to_main_menu()
			get_viewport().set_input_as_handled()
		return
	if (kc == KEY_ESCAPE or pk == KEY_ESCAPE) and not game.is_busy() and not get_tree().paused:
		_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	_was_paused = get_tree().paused
	_sync_volume_ui()
	begin()
	_layer.visible = true
	get_tree().paused = true

func _close_pause() -> void:
	_layer.visible = false
	get_tree().paused = _was_paused
	finish()

func _go_to_main_menu() -> void:
	_layer.visible = false
	get_tree().paused = false
	finish()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _open_time_admin() -> void:
	for feature in game.features:
		if feature.has_method("open_admin"):
			feature.call("open_admin")
			return
	push_warning("Không tìm thấy công cụ admin tua thời gian.")

func _sync_volume_ui() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var v := 0.8
	if bus >= 0:
		v = 0.0 if AudioServer.is_bus_mute(bus) else clampf(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.0, 1.0)
	elif _cfg.has_section_key("audio", "volume"):
		v = float(_cfg.get_value("audio", "volume", 0.8))
	if _vol_slider != null:
		_vol_slider.set_value_no_signal(v)
	if _vol_label != null:
		_vol_label.text = "%d%%" % int(round(v * 100.0))

func _on_volume_changed(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(bus, v <= 0.0)
	if _vol_label != null:
		_vol_label.text = "%d%%" % int(round(v * 100.0))
	_cfg.set_value("audio", "volume", v)
	_cfg.save(SETTINGS_PATH)

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.58)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -125.0
	panel.offset_right = 125.0
	panel.offset_top = -100.0
	panel.offset_bottom = 100.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f1b2d")
	style.border_color = Color("e0b020")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("ffd23f"))
	box.add_child(title)

	# Thanh chỉnh âm lượng (đồng bộ với Menu chính & settings.cfg)
	var vol_row := HBoxContainer.new()
	box.add_child(vol_row)
	var vol_txt := Label.new()
	vol_txt.text = "Âm lượng"
	vol_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_txt.add_theme_font_size_override("font_size", 9)
	vol_txt.add_theme_color_override("font_color", Color.WHITE)
	vol_row.add_child(vol_txt)

	_vol_label = Label.new()
	_vol_label.text = "80%"
	_vol_label.add_theme_font_size_override("font_size", 9)
	_vol_label.add_theme_color_override("font_color", Color("ffd23f"))
	vol_row.add_child(_vol_label)

	_vol_slider = HSlider.new()
	_vol_slider.min_value = 0.0
	_vol_slider.max_value = 1.0
	_vol_slider.step = 0.05
	_vol_slider.custom_minimum_size = Vector2(0, 14)
	var sl := StyleBoxFlat.new()
	sl.bg_color = Color("1b2a42")
	sl.border_color = Color("64748b")
	sl.set_border_width_all(1)
	sl.content_margin_top = 3
	sl.content_margin_bottom = 3
	var ga := StyleBoxFlat.new()
	ga.bg_color = Color("e0b020")
	_vol_slider.add_theme_stylebox_override("slider", sl)
	_vol_slider.add_theme_stylebox_override("grabber_area", ga)
	_vol_slider.add_theme_stylebox_override("grabber_area_highlight", ga)
	_vol_slider.value_changed.connect(_on_volume_changed)
	box.add_child(_vol_slider)

	var btn_resume := _make_btn("[1] Tiếp tục chơi (Esc)", Color("1e3a5f"))
	btn_resume.pressed.connect(_close_pause)
	box.add_child(btn_resume)

	var btn_time := _make_btn("Thời gian (tua để test)", Color("34533f"))
	btn_time.pressed.connect(_open_time_admin)
	box.add_child(btn_time)

	var btn_menu := _make_btn("[2] Về Menu chính", Color("8b2635"))
	btn_menu.pressed.connect(_go_to_main_menu)
	box.add_child(btn_menu)

	_sync_volume_ui()

func _make_btn(label_text: String, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 24)
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = Color("64748b")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.14)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	return btn
