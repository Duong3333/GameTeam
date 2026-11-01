extends "res://scripts/features/feature.gd"

const Schedule := preload("res://scripts/features/schedule_data.gd")

var layer: CanvasLayer
var panel: PanelContainer
var week_select: OptionButton
var weekday_select: OptionButton
var hour_select: SpinBox
var minute_select: SpinBox
var status_label: Label
var was_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_build_panel()
	layer.visible = false

func open_admin() -> void:
	if game.multiplayer_manager != null and game.multiplayer_manager.is_connected_to_session():
		status_label.text = "Không thể tua thời gian khi đang chơi Multiplayer."
		return
	was_paused = get_tree().paused
	_sync_controls()
	layer.visible = true
	get_tree().paused = true

func close_admin() -> void:
	layer.visible = false
	get_tree().paused = was_paused

func jump_to_selected_time() -> void:
	var week := week_select.get_selected_id()
	var weekday := weekday_select.get_selected_id()
	game.day = (week - 1) * 7 + weekday
	game.game_min = hour_select.value * 60.0 + minute_select.value
	status_label.text = "Đã chuyển tới %s, %02d:%02d." % [
		Schedule.date_text(game.day),
		int(game.game_min / 60.0),
		int(game.game_min) % 60
	]

func _sync_controls() -> void:
	var week := Schedule.week_no(game.day)
	week_select.select(clampi(week - 1, 0, week_select.item_count - 1))
	weekday_select.select(Schedule.weekday(game.day))
	hour_select.value = clampi(int(game.game_min / 60.0), 7, 16)
	minute_select.value = int(game.game_min) % 60
	status_label.text = "Thời gian hiện tại: %s, %02d:%02d." % [
		Schedule.date_text(game.day),
		int(game.game_min / 60.0),
		int(game.game_min) % 60
	]

func _build_panel() -> void:
	var background := ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.62)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	panel = PanelContainer.new()
	panel.position = Vector2(65, 25)
	panel.size = Vector2(350, 220)
	panel.custom_minimum_size = Vector2(350, 220)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title := Label.new()
	title.text = "TUA THỜI GIAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Chọn thời điểm để kiểm tra lịch học và kỳ thi."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 320
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("cbd5e1"))
	column.add_child(hint)
	var week_row := HBoxContainer.new()
	column.add_child(week_row)
	week_row.add_child(_make_label("Tuần"))
	week_select = OptionButton.new()
	week_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_option_button(week_select)
	for week in Schedule.SEMESTER_WEEKS:
		week_select.add_item("Tuần %d" % (week + 1), week + 1)
	week_row.add_child(week_select)
	var weekday_row := HBoxContainer.new()
	column.add_child(weekday_row)
	weekday_row.add_child(_make_label("Ngày"))
	weekday_select = OptionButton.new()
	weekday_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_option_button(weekday_select)
	for index in Schedule.DAY_NAMES.size():
		weekday_select.add_item(Schedule.DAY_NAMES[index], index)
	weekday_row.add_child(weekday_select)
	var time_row := HBoxContainer.new()
	column.add_child(time_row)
	time_row.add_child(_make_label("Giờ"))
	hour_select = SpinBox.new()
	hour_select.min_value = 7
	hour_select.max_value = 16
	hour_select.step = 1
	hour_select.custom_minimum_size.x = 82
	_style_spin_box(hour_select)
	time_row.add_child(hour_select)
	time_row.add_child(_make_label("Phút"))
	minute_select = SpinBox.new()
	minute_select.min_value = 0
	minute_select.max_value = 59
	minute_select.step = 1
	minute_select.custom_minimum_size.x = 82
	_style_spin_box(minute_select)
	time_row.add_child(minute_select)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.x = 320
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_color_override("font_color", Color("f8fafc"))
	column.add_child(status_label)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	var jump_button := Button.new()
	jump_button.text = "CHUYỂN TỚI"
	jump_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(jump_button, Color("2563eb"))
	jump_button.pressed.connect(jump_to_selected_time)
	buttons.add_child(jump_button)
	var close_button := Button.new()
	close_button.text = "ĐÓNG"
	_style_button(close_button, Color("374151"))
	close_button.pressed.connect(close_admin)
	buttons.add_child(close_button)

func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 48
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("f8fafc"))
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111827")
	style.border_color = Color("475569")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	return style

func _style_option_button(control: OptionButton) -> void:
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	control.add_theme_color_override("font_focus_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _control_style(Color("1f2937")))
	control.add_theme_stylebox_override("hover", _control_style(Color("334155")))
	control.add_theme_stylebox_override("pressed", _control_style(Color("334155")))
	control.add_theme_stylebox_override("focus", _control_style(Color("1f2937")))
	control.add_theme_stylebox_override("disabled", _control_style(Color("1f2937")))
	control.add_theme_constant_override("outline_size", 0)

func _style_spin_box(control: SpinBox) -> void:
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_focus_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _control_style(Color("1f2937")))
	control.add_theme_stylebox_override("focus", _control_style(Color("1f2937")))
	control.add_theme_stylebox_override("read_only", _control_style(Color("1f2937")))
	control.add_theme_stylebox_override("field", _control_style(Color("1f2937")))
	control.get_line_edit().add_theme_color_override("font_color", Color.WHITE)
	control.get_line_edit().add_theme_color_override("font_selected_color", Color("111827"))
	control.get_line_edit().add_theme_color_override("selection_color", Color("93c5fd"))

func _style_button(control: Button, color: Color) -> void:
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _control_style(color))
	control.add_theme_stylebox_override("hover", _control_style(color.lightened(0.12)))
	control.add_theme_stylebox_override("pressed", _control_style(color.darkened(0.12)))

func _control_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("64748b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style
