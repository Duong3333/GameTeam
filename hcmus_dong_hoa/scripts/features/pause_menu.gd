extends "res://scripts/features/feature.gd"
# MENU TẠM DỪNG (ESC): mở khi đang rảnh ngoài khuôn viên để chỉnh âm lượng, tiếp tục hoặc về Menu chính.

const MAIN_MENU_SCENE := "res://scripts/menu/main_menu.tscn"
const SETTINGS_PATH := "user://settings.cfg"

var _layer: CanvasLayer
var _was_paused := false
var _cfg := ConfigFile.new()
var _vol_slider: HSlider
var _vol_label: Label
var _drl_slider: HSlider
var _gpa_slider: HSlider
var _wallet_slider: HSlider
var _drl_value_label: Label
var _gpa_value_label: Label
var _wallet_value_label: Label

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
			_adjust_drl(1)
			get_viewport().set_input_as_handled()
		elif kc == KEY_3 or kc == KEY_KP_3:
			_adjust_drl(-1)
			get_viewport().set_input_as_handled()
		elif kc == KEY_4 or kc == KEY_KP_4:
			_go_to_main_menu()
			get_viewport().set_input_as_handled()
		return
	if (kc == KEY_ESCAPE or pk == KEY_ESCAPE) and not game.is_busy() and not get_tree().paused:
		_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	_was_paused = get_tree().paused
	_sync_volume_ui()
	_sync_test_stats_ui()
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

func _adjust_drl(amount: int) -> void:
	if game.stats == null:
		return
	game.stats.add_drl(amount, "Điều chỉnh ĐRL để test")
	_sync_test_stats_ui()

func _sync_test_stats_ui() -> void:
	if game.stats == null:
		return
	_ensure_wallet_bound()
	var drl := int(game.stats.get("drl"))
	var gpa := float(game.stats.get("gpa"))
	var wallet := int(game.stats.get("money"))
	if _drl_slider != null:
		_drl_slider.set_value_no_signal(drl)
	if _gpa_slider != null:
		_gpa_slider.set_value_no_signal(gpa)
	if _wallet_slider != null:
		_wallet_slider.set_value_no_signal(clampf(float(wallet), _wallet_slider.min_value, _wallet_slider.max_value))
	if _drl_value_label != null:
		_drl_value_label.text = "Điểm rèn luyện: %d/100" % drl
	if _gpa_value_label != null:
		_gpa_value_label.text = "GPA: %.2f/4.00" % gpa
	if _wallet_value_label != null:
		_wallet_value_label.text = "Ví: %s" % game.stats.money_compact_text(wallet)

func _ensure_wallet_bound() -> void:
	if game.stats.has_method("has_wallet") and game.stats.call("has_wallet"):
		return
	var candidates: Array = game.features.duplicate()
	candidates.append_array(game.get_children())
	for feature in candidates:
		if feature != game and feature.has_method("get_wallet_text") and feature.has_method("set_wallet_balance"):
			game.stats.call("bind_wallet", feature)
			return

func _on_drl_slider_changed(value: float) -> void:
	if game.stats == null:
		return
	var target := roundi(value)
	game.stats.add_drl(target - int(game.stats.get("drl")), "Điều chỉnh ĐRL để test")
	_sync_test_stats_ui()

func _on_gpa_slider_changed(value: float) -> void:
	if game.stats == null:
		return
	game.stats.set_gpa(value)
	_sync_test_stats_ui()

func _on_wallet_slider_changed(value: float) -> void:
	if game.stats == null:
		return
	game.stats.set("money", roundi(value))
	_sync_test_stats_ui()

func _adjust_wallet(amount: int) -> void:
	if game.stats == null:
		return
	game.stats.set("money", maxi(0, int(game.stats.get("money")) + amount))
	_sync_test_stats_ui()

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
	panel.offset_top = -127.0
	panel.offset_bottom = 127.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f1b2d")
	style.border_color = Color("e0b020")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
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
	btn_resume.custom_minimum_size.y = 20
	btn_resume.pressed.connect(_close_pause)
	box.add_child(btn_resume)

	var btn_time := _make_btn("Thời gian (tua để test)", Color("34533f"))
	btn_time.custom_minimum_size.y = 20
	btn_time.pressed.connect(_open_time_admin)
	box.add_child(btn_time)

	_drl_value_label = _make_stat_label()
	box.add_child(_drl_value_label)
	_drl_slider = _make_stat_slider(0.0, 100.0, 1.0)
	_drl_slider.value_changed.connect(_on_drl_slider_changed)
	box.add_child(_drl_slider)
	var drl_hint := Label.new()
	drl_hint.text = "Phím 2: +1  ·  Phím 3: −1"
	drl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drl_hint.add_theme_font_size_override("font_size", 7)
	drl_hint.add_theme_color_override("font_color", Color("cbd5e1"))
	box.add_child(drl_hint)

	_gpa_value_label = _make_stat_label()
	box.add_child(_gpa_value_label)
	_gpa_slider = _make_stat_slider(0.0, 4.0, 0.1)
	_gpa_slider.value_changed.connect(_on_gpa_slider_changed)
	box.add_child(_gpa_slider)

	_wallet_value_label = _make_stat_label()
	box.add_child(_wallet_value_label)
	_wallet_slider = _make_stat_slider(0.0, 10000000.0, 50000.0)
	_wallet_slider.value_changed.connect(_on_wallet_slider_changed)
	box.add_child(_wallet_slider)
	var wallet_row := HBoxContainer.new()
	wallet_row.add_theme_constant_override("separation", 4)
	box.add_child(wallet_row)
	var wallet_down := _make_btn("−100k", Color("8b3a3a"))
	wallet_down.custom_minimum_size.y = 18
	wallet_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_down.pressed.connect(_adjust_wallet.bind(-100000))
	wallet_row.add_child(wallet_down)
	var wallet_up := _make_btn("+100k", Color("256b4a"))
	wallet_up.custom_minimum_size.y = 18
	wallet_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_up.pressed.connect(_adjust_wallet.bind(100000))
	wallet_row.add_child(wallet_up)

	var btn_menu := _make_btn("[4] Về Menu chính", Color("8b2635"))
	btn_menu.custom_minimum_size.y = 20
	btn_menu.pressed.connect(_go_to_main_menu)
	box.add_child(btn_menu)

	_sync_volume_ui()
	_sync_test_stats_ui()

func _make_stat_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("f8fafc"))
	return label

func _make_stat_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(0, 12)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("1b2a42")
	track.border_color = Color("64748b")
	track.set_border_width_all(1)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e0b020")
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	return slider

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
