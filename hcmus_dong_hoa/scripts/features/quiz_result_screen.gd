extends Control
# MÀN HÌNH HOÀN THÀNH QUIZ - chỉ hiện: huy hiệu, "Hoàn thành" và GPA thay đổi.
# math_quiz.gd gọi: show_result({"gpa": số GPA thay đổi}) và set_replay_enabled(có nút Chơi lại hay không).
# GPA > 0 hiện màu xanh lá (+0.50 GPA), = 0 hiện màu xanh dương nhạt (+0.00 GPA), < 0 hiện màu đỏ (-0.10 GPA).

signal replay_requested
signal close_requested

const COL_BG_TOP := Color("0f2040")
const COL_BG_BOTTOM := Color("060d1c")
const COL_UP := Color("5be38a")
const COL_ZERO := Color("8ec5ff")
const COL_DOWN := Color("ff7b7b")
const COL_CHECK := Color("0a1730")
const BADGE_Y := 58.0
const TITLE_Y := 102.0
const PILL_Y := 140.0
const BUTTON_Y := 206.0
const PILL_SIZE := Vector2(210.0, 50.0)
# vị trí các đốm sáng quanh huy hiệu (dx, dy so với tâm huy hiệu)
const SPARKLES := [
	Vector2(-150, -40), Vector2(-118, -18), Vector2(-172, 6), Vector2(-96, -52), Vector2(-142, 40), Vector2(-192, -16),
	Vector2(150, -36), Vector2(120, -16), Vector2(176, 8), Vector2(98, -50), Vector2(142, 44), Vector2(192, -18),
	Vector2(-62, -30), Vector2(64, -34)
]

var title_label: Label
var gpa_label: Label
var replay_button: Button
var close_button: Button

var _gpa := 0.0
var _accent := COL_UP
var _shown_gpa := 0.0   # số GPA đang hiện (chạy từ 0 tới _gpa)
var _intro := 0.0       # 0 -> 1: huy hiệu bật ra
var _time := 0.0
var _tween: Tween
var _frame_style := StyleBoxFlat.new()
var _pill_style := StyleBoxFlat.new()

func _ready() -> void:
	_build_ui()
	_apply_accent()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_update_gpa_text()
	queue_redraw()

# data: {"gpa": float}
func show_result(data: Dictionary) -> void:
	_gpa = float(data.get("gpa", 0.0))
	if _gpa > 0.004:
		_accent = COL_UP
	elif _gpa < -0.004:
		_accent = COL_DOWN
	else:
		_accent = COL_ZERO
	_apply_accent()
	_intro = 0.0
	_shown_gpa = 0.0
	_time = 0.0
	_update_gpa_text()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "_intro", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_shown_gpa", absf(_gpa), 0.8).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()

func set_replay_enabled(enabled: bool) -> void:
	replay_button.visible = enabled
	_layout()
	if enabled:
		_style_button(close_button, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.35), Color("dfe6ff"))
	else:
		_style_button(close_button, _accent.darkened(0.45), _accent, Color.WHITE)

func _layout() -> void:
	if title_label == null:
		return
	var w := size.x
	title_label.position = Vector2(0.0, TITLE_Y)
	title_label.size = Vector2(w, 30.0)
	gpa_label.position = Vector2(0.0, PILL_Y)
	gpa_label.size = Vector2(w, PILL_SIZE.y)
	if replay_button.visible:
		replay_button.size = Vector2(140.0, 32.0)
		replay_button.position = Vector2(w * 0.5 - 146.0, BUTTON_Y)
		close_button.size = Vector2(140.0, 32.0)
		close_button.position = Vector2(w * 0.5 + 6.0, BUTTON_Y)
	else:
		close_button.size = Vector2(170.0, 32.0)
		close_button.position = Vector2(w * 0.5 - 85.0, BUTTON_Y)

func _update_gpa_text() -> void:
	var sign_text := "+" if _gpa >= 0.0 else "-"
	gpa_label.text = "%s%.2f GPA" % [sign_text, _shown_gpa]

func _apply_accent() -> void:
	if gpa_label == null:
		return
	gpa_label.add_theme_color_override("font_color", _accent)
	_pill_style.bg_color = Color(_accent.r, _accent.g, _accent.b, 0.16)
	_pill_style.border_color = _accent
	_frame_style.border_color = Color(_accent.r, _accent.g, _accent.b, 0.35)
	_style_button(replay_button, _accent.darkened(0.45), _accent, Color.WHITE)
	if not replay_button.visible:
		_style_button(close_button, _accent.darkened(0.45), _accent, Color.WHITE)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([COL_BG_TOP, COL_BG_TOP, COL_BG_BOTTOM, COL_BG_BOTTOM])
	)
	draw_style_box(_frame_style, Rect2(10, 10, w - 20, h - 20))
	var center := Vector2(cx, BADGE_Y)
	var pop := clampf(_intro, 0.0, 1.2)
	if pop < 0.02:
		draw_style_box(_pill_style, Rect2(cx - PILL_SIZE.x * 0.5, PILL_Y, PILL_SIZE.x, PILL_SIZE.y))
		return
	# vầng sáng mềm sau huy hiệu
	for i in 10:
		draw_circle(center, (100.0 - i * 9.0) * pop, Color(_accent.r, _accent.g, _accent.b, 0.03))
	# đốm sáng lấp lánh (không hiện khi bị trừ GPA)
	if _gpa >= 0.0:
		for i in SPARKLES.size():
			var p: Vector2 = center + SPARKLES[i]
			var twinkle := 0.5 + 0.5 * sin(_time * 2.4 + i * 1.7)
			var a := (0.25 + 0.75 * twinkle) * clampf(_intro, 0.0, 1.0)
			var arm := 2.0 + 3.0 * twinkle
			var c := Color(1, 1, 1, a)
			draw_line(p - Vector2(arm, 0), p + Vector2(arm, 0), c, 1.0)
			draw_line(p - Vector2(0, arm), p + Vector2(0, arm), c, 1.0)
	# huy hiệu tròn có dấu tích
	draw_arc(center, 36.0 * pop, 0.0, TAU, 48, Color(_accent.r, _accent.g, _accent.b, 0.55), 2.0)
	draw_circle(center, 30.0 * pop, _accent.darkened(0.25))
	draw_circle(center, 26.0 * pop, _accent)
	draw_arc(center + Vector2(0, -2) * pop, 20.0 * pop, deg_to_rad(200.0), deg_to_rad(290.0), 12, Color(1, 1, 1, 0.35), 2.0)
	var check := PackedVector2Array([
		center + Vector2(-11, 1) * pop,
		center + Vector2(-3, 9) * pop,
		center + Vector2(12, -8) * pop
	])
	draw_polyline(check, COL_CHECK, 4.5 * pop, true)
	# nền viên thuốc quanh số GPA
	draw_style_box(_pill_style, Rect2(cx - PILL_SIZE.x * 0.5, PILL_Y, PILL_SIZE.x, PILL_SIZE.y))

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame_style.bg_color = Color(0, 0, 0, 0)
	_frame_style.set_border_width_all(1)
	_frame_style.set_corner_radius_all(10)
	_pill_style.set_border_width_all(2)
	_pill_style.set_corner_radius_all(14)
	title_label = _add_label(Rect2(0, TITLE_Y, 460, 30), 22, Color.WHITE)
	title_label.text = "Hoàn thành"
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	title_label.add_theme_constant_override("outline_size", 3)
	gpa_label = _add_label(Rect2(0, PILL_Y, 460, 50), 24, _accent)
	replay_button = _add_button("Chơi lại", Vector2(84, BUTTON_Y), Vector2(140, 32))
	replay_button.pressed.connect(func() -> void: replay_requested.emit())
	close_button = _add_button("Đóng", Vector2(246, BUTTON_Y), Vector2(140, 32))
	close_button.pressed.connect(func() -> void: close_requested.emit())
	resized.connect(_layout)
	_layout()

func _add_label(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _add_button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE   # Enter/Space do math_quiz.gd xử lý, tránh bấm trùng
	button.add_theme_font_size_override("font_size", 11)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(button)
	return button

func _style_button(button: Button, fill: Color, border: Color, text_color: Color) -> void:
	if button == null:
		return
	for state_name in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		var lift := 0.0
		if state_name == "hover":
			lift = 0.12
		elif state_name == "pressed":
			lift = -0.08
		style.bg_color = fill.lightened(lift) if lift >= 0.0 else fill.darkened(-lift)
		style.border_color = border
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
