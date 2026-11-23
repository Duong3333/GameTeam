extends "res://scripts/features/feature.gd"

const MIDTERM_STAGE := "midterm"
const FINAL_STAGE := "final"
const Schedule := preload("res://scripts/features/schedule_data.gd")

var _layer: CanvasLayer
var _root: Control
var _panel: Panel
var _title_label: Label
var _details_label: Label
var _balance_label: Label
var _pay_button: Button
var _defer_button: Button
var _stage := ""
var _amount := 0
var _available := 0
var _was_paused := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _last_checked_day := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if game.stats == null or not game.stats.has_signal("tuition_decision_requested"):
		push_error("StudentTuition requires StudentStats.tuition_decision_requested.")
		return
	game.stats.tuition_decision_requested.connect(_on_tuition_decision_requested)
	game.stats.student_expelled.connect(_on_student_expelled)
	_build_dialog()

# Thay cho đoạn _update_tuition() mà bản (4) đặt trong main.gd (file lõi, không được sửa):
# mỗi khi sang ngày mới thì kiểm tra hạn học phí. Đồng thời gắn ví căn tin vào stats nếu HUD chưa gắn.
func _process(_delta: float) -> void:
	if game == null or game.stats == null:
		return
	if game.stats.has_method("has_wallet") and not game.stats.call("has_wallet"):
		for feature in game.features:
			if feature.has_method("get_wallet_text") and feature.has_method("set_wallet_balance"):
				game.stats.call("bind_wallet", feature)
				break
	var day := int(game.day)
	if day == _last_checked_day:
		return
	_last_checked_day = day
	if game.stats.has_method("check_tuition_due"):
		game.stats.call("check_tuition_due", Schedule.week_no(day))

func _build_dialog() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	var theme := Theme.new()
	theme.default_font = game.font
	_root.theme = theme
	_layer.add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	_panel = Panel.new()
	_panel.position = Vector2(42, 64)
	_panel.size = Vector2(396, 144)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(_panel)

	_title_label = _make_label(Rect2(16, 10, 364, 25), 14, Color("ffe28a"))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title_label)
	_details_label = _make_label(Rect2(20, 40, 356, 39), 9, Color("f1f5f9"))
	_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_details_label)
	_balance_label = _make_label(Rect2(20, 79, 356, 18), 9, Color("cbd5e1"))
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_balance_label)

	_pay_button = _make_button(Rect2(20, 106, 170, 26), Color("166534"), Color("22a05a"))
	_pay_button.pressed.connect(_on_pay_pressed)
	_panel.add_child(_pay_button)
	_defer_button = _make_button(Rect2(206, 106, 170, 26), Color("334155"), Color("475569"))
	_defer_button.pressed.connect(_on_defer_pressed)
	_panel.add_child(_defer_button)

func _on_tuition_decision_requested(stage: String, amount: int, available: int) -> void:
	_stage = stage
	_amount = amount
	_available = available
	_was_paused = get_tree().paused
	_previous_mouse_mode = Input.mouse_mode
	_begin_modal()
	_update_dialog()

func _begin_modal() -> void:
	super.begin()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_root.visible = true
	get_tree().paused = true

func _update_dialog() -> void:
	var stats: Variant = game.stats
	var amount_text: String = stats.money_compact_text(_amount)
	if _stage == MIDTERM_STAGE:
		_title_label.text = "HỌC PHÍ GIỮA KỲ"
		_details_label.text = "Bạn có thể đóng ngay hoặc dời khoản này sang cuối kỳ.\nNếu dời, học phí cuối kỳ sẽ tăng lên 200k."
		_defer_button.text = "DỜI SANG CUỐI KỲ"
	else:
		_title_label.text = "HỌC PHÍ CUỐI KỲ"
		_details_label.text = "Cần đóng toàn bộ khoản học phí còn nợ.\nNếu không đóng, bạn sẽ bị buộc thôi học."
		_defer_button.text = "KHÔNG ĐÓNG · BỊ ĐUỔI HỌC"
	_pay_button.text = "ĐÓNG %s" % amount_text
	_pay_button.disabled = _available < _amount
	if _pay_button.disabled:
		var shortfall := _amount - _available
		_balance_label.text = "Ví: %s · Còn thiếu %s" % [
			stats.money_compact_text(_available),
			stats.money_compact_text(shortfall)
		]
		_balance_label.add_theme_color_override("font_color", Color("ff9c8b"))
	else:
		_balance_label.text = "Ví: %s" % stats.money_compact_text(_available)
		_balance_label.add_theme_color_override("font_color", Color("b8f1c8"))
	if _pay_button.disabled:
		_defer_button.grab_focus()
	else:
		_pay_button.grab_focus()

func _on_pay_pressed() -> void:
	if not bool(game.stats.call("respond_tuition", true)):
		_balance_label.text = "Số dư không đủ để thanh toán khoản này."
		_balance_label.add_theme_color_override("font_color", Color("ff9c8b"))
		return
	_close_modal()

func _on_defer_pressed() -> void:
	var selected_stage := _stage
	if not bool(game.stats.call("respond_tuition", false)):
		return
	if selected_stage == MIDTERM_STAGE:
		_close_modal()
		_show_menu_notice("ĐÃ DỜI HỌC PHÍ", "100k sẽ được cộng vào khoản phải đóng cuối kỳ.\nNhấn Tab rồi B để xem chi tiết.")

func _on_student_expelled() -> void:
	_stage = "expelled"
	super.begin()
	_root.visible = true
	get_tree().paused = true
	_title_label.text = "BUỘC THÔI HỌC"
	_details_label.text = "Bạn đã chọn không đóng học phí cuối kỳ.\nKhông thể tiếp tục học kỳ này."
	_balance_label.text = "Học phí còn nợ: %s" % game.stats.money_compact_text(_amount)
	_balance_label.add_theme_color_override("font_color", Color("ff9c8b"))
	_pay_button.hide()
	_defer_button.hide()

func _close_modal() -> void:
	_root.visible = false
	super.finish()
	get_tree().paused = _was_paused
	Input.mouse_mode = _previous_mouse_mode

func _show_menu_notice(title: String, body: String) -> void:
	for feature in game.features:
		if feature != self and feature.has_method("show_notice"):
			feature.call("show_notice", title, body)
			return

func _make_label(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _make_button(rect: Rect2, color: Color, hover_color: Color) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("8b95a7"))
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(hover_color))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.2)))
	button.add_theme_stylebox_override("disabled", _button_style(Color("273244")))
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101a2b")
	style.border_color = Color("64748b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("64748b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(3)
	return style
