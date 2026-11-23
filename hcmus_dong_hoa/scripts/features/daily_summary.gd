extends "res://scripts/features/feature.gd"

const Schedule := preload("res://scripts/features/schedule_data.gd")

var layer: CanvasLayer
var panel: PanelContainer
var title_label: Label
var date_label: Label
var stats_label: Label
var log_label: Label

var tracked_day: int = -1
var start_gpa: float = 3.0
var start_drl: int = 70
var daily_logs: Array[String] = []
var was_paused: bool = false
var _connected_stats: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 32
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_build_panel()
	layer.visible = false

func _process(_delta: float) -> void:
	if game == null:
		return

	# Ket noi tin hieu thay doi diem ren luyen tu student_stats.gd
	if not _connected_stats and game.get("stats") != null:
		if not game.stats.drl_changed.is_connected(_on_drl_changed):
			game.stats.drl_changed.connect(_on_drl_changed)
		_connected_stats = true

	# Khoi tao moc dau ngay
	if tracked_day == -1:
		tracked_day = game.day
		_snapshot_start_of_day()
		return

	# Tu dong bat bang tong ket khi buoc sang ngay moi
	if game.day > tracked_day and not layer.visible:
		var finished_day := tracked_day
		tracked_day = game.day
		open_summary(finished_day)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# F9 mo nhanh bang tong ket ngay hien tai
		if event.keycode == KEY_F9 and not layer.visible:
			open_summary(game.day)
			get_viewport().set_input_as_handled()
		# Enter / Space / Esc dong bang tong ket
		elif layer.visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
			close_summary()
			get_viewport().set_input_as_handled()

func _on_drl_changed(amount: int, reason: String) -> void:
	var sign_str := "+" if amount > 0 else ""
	var desc := reason if reason != "" else "Hoat dong trong khuon vien"
	daily_logs.append("• %s%d ĐRL: %s" % [sign_str, amount, desc])

func _snapshot_start_of_day() -> void:
	if game != null and game.get("stats") != null:
		start_gpa = game.stats.gpa
		start_drl = game.stats.drl
	daily_logs.clear()

func open_summary(day_to_show: int) -> void:
	if game == null or game.get("stats") == null:
		return
	was_paused = get_tree().paused

	var cur_gpa: float = game.stats.gpa
	var cur_drl: int = game.stats.drl
	var diff_gpa: float = cur_gpa - start_gpa
	var diff_drl: int = cur_drl - start_drl

	var gpa_diff_str := "%+.2f" % diff_gpa if absf(diff_gpa) >= 0.005 else "0.00"
	var drl_diff_str := "%+d" % diff_drl if diff_drl != 0 else "0"

	title_label.text = "TỔNG KẾT NGÀY HỌC"
	date_label.text = "Thời điểm: %s (Tuần %d)" % [Schedule.date_text(day_to_show), Schedule.week_no(day_to_show)]
	stats_label.text = "GPA: %s (%s)    |    Điểm rèn luyện: %s (%s)" % [
		game.stats.gpa_text(), gpa_diff_str,
		game.stats.drl_text(), drl_diff_str
	]

	if daily_logs.is_empty():
		log_label.text = "• Không có biến động điểm rèn luyện nào trong ngày.\n• Hãy tham gia lớp học, làm quiz hoặc sự kiện để tích lũy điểm!"
	else:
		log_label.text = "\n".join(daily_logs)

	layer.visible = true
	get_tree().paused = true

func close_summary() -> void:
	layer.visible = false
	get_tree().paused = was_paused
	_snapshot_start_of_day()

func _build_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	panel = PanelContainer.new()
	panel.position = Vector2(55, 25)
	panel.size = Vector2(370, 220)
	panel.custom_minimum_size = Vector2(370, 220)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("facc15"))
	col.add_child(title_label)

	date_label = Label.new()
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 11)
	date_label.add_theme_color_override("font_color", Color("cbd5e1"))
	col.add_child(date_label)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", Color("93c5fd"))
	col.add_child(stats_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(340, 88)
	col.add_child(scroll)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size.x = 330
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.add_theme_font_size_override("font_size", 11)
	log_label.add_theme_color_override("font_color", Color("f8fafc"))
	scroll.add_child(log_label)

	var btn := Button.new()
	btn.text = "TIẾP TỤC SANG NGÀY MỚI (ENTER)"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn, Color("2563eb"))
	btn.pressed.connect(close_summary)
	col.add_child(btn)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111827")
	style.border_color = Color("475569")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	return style

func _style_button(control: Button, color: Color) -> void:
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _btn_style(color))
	control.add_theme_stylebox_override("hover", _btn_style(color.lightened(0.12)))
	control.add_theme_stylebox_override("pressed", _btn_style(color.darkened(0.12)))

func _btn_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("64748b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style
