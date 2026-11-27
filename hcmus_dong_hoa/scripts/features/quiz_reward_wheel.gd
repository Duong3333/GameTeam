extends Control

signal prize_awarded(amount: int)
signal spin_finished

const PRIZES := [5000, 10000, 15000, 20000, 30000, 50000]
const SECTOR_COLORS := [
	Color("237c91"),
	Color("3155a3"),
	Color("7c4c9d"),
	Color("b64e60"),
	Color("c17a27"),
	Color("458753"),
]
const SPIN_SECONDS := 4.2
const POPUP_SECONDS := 1.8

var _rng := RandomNumberGenerator.new()
var _wheel: Control
var _title: Label
var _subtitle: Label
var _popup: Panel
var _amount_label: Label
var _prize_index := 0
var _prize_amount := 0
var _spin_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	_build_ui()
	hide()

func start_spin() -> void:
	_prize_index = _rng.randi_range(0, PRIZES.size() - 1)
	_prize_amount = int(PRIZES[_prize_index])
	_wheel.rotation = 0.0
	_wheel.show()
	_popup.hide()
	_title.text = "VÒNG QUAY MAY MẮN"
	_subtitle.text = "Quay để nhận tiền thưởng!"
	show()

	var sector_angle := TAU / float(PRIZES.size())
	var selected_offset := (float(_prize_index) + 0.5) * sector_angle
	var full_turns := _rng.randi_range(6, 8)
	var target_rotation := TAU * float(full_turns) - selected_offset
	_spin_tween = create_tween()
	_spin_tween.tween_property(_wheel, "rotation", target_rotation, SPIN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_spin_tween.tween_callback(_show_prize)

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var frame := Panel.new()
	frame.position = Vector2(50, 5)
	frame.size = Vector2(380, 260)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("101a2b")
	frame_style.border_color = Color("ffd23f")
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	_title = _make_label(Rect2(60, 14, 360, 20), 14, Color("ffd23f"))
	_title.text = "VÒNG QUAY MAY MẮN"
	_subtitle = _make_label(Rect2(60, 34, 360, 15), 8, Color("dfe6ff"))
	_subtitle.text = "Quay để nhận tiền thưởng!"

	_wheel = Control.new()
	_wheel.position = Vector2(155, 54)
	_wheel.size = Vector2(170, 170)
	_wheel.pivot_offset = _wheel.size * 0.5
	_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.draw.connect(_draw_wheel)
	add_child(_wheel)

	var pointer := Polygon2D.new()
	pointer.position = Vector2(240, 51)
	pointer.polygon = PackedVector2Array([
		Vector2(-10, 0),
		Vector2(10, 0),
		Vector2(0, 17),
	])
	pointer.color = Color("fff3a6")
	add_child(pointer)

	_popup = Panel.new()
	_popup.position = Vector2(104, 102)
	_popup.size = Vector2(272, 64)
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color("fff7dc")
	popup_style.border_color = Color("ffd23f")
	popup_style.set_border_width_all(2)
	popup_style.set_corner_radius_all(8)
	_popup.add_theme_stylebox_override("panel", popup_style)
	add_child(_popup)

	var coin := Panel.new()
	coin.position = Vector2(14, 12)
	coin.size = Vector2(40, 40)
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = Color("ffd23f")
	coin_style.border_color = Color("b8860b")
	coin_style.set_border_width_all(2)
	coin_style.set_corner_radius_all(20)
	coin.add_theme_stylebox_override("panel", coin_style)
	_popup.add_child(coin)

	var coin_label := _make_child_label(coin, Rect2(0, 0, 40, 40), "đ", 18, Color("654500"))
	coin_label.add_theme_color_override("font_color", Color("654500"))
	_amount_label = _make_child_label(_popup, Rect2(58, 8, 200, 48), "", 20, Color("183a36"))
	_popup.hide()

func _make_label(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _make_child_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _draw_wheel() -> void:
	var center := _wheel.size * 0.5
	var radius := 78.0
	var sector_angle := TAU / float(PRIZES.size())
	var font := _wheel.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	for index in PRIZES.size():
		var start_angle := -PI * 0.5 + float(index) * sector_angle
		var end_angle := start_angle + sector_angle
		var points := PackedVector2Array([center])
		for step in range(13):
			var angle := start_angle + sector_angle * float(step) / 12.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		points.append(center)
		_wheel.draw_colored_polygon(points, SECTOR_COLORS[index])
		_wheel.draw_arc(center, radius, start_angle, end_angle, 16, Color("fff3c4"), 1.4, true)

		var label_center := center + Vector2(cos(start_angle + sector_angle * 0.5), sin(start_angle + sector_angle * 0.5)) * 49.0
		_wheel.draw_string(
			font,
			label_center + Vector2(-23, 3),
			_format_compact_amount(int(PRIZES[index])),
			HORIZONTAL_ALIGNMENT_CENTER,
			46,
			8,
			Color.WHITE
		)

	_wheel.draw_arc(center, radius, 0.0, TAU, 48, Color("fff3c4"), 2.5, true)
	_wheel.draw_circle(center, 15.0, Color("fff0a8"))
	_wheel.draw_circle(center, 11.0, Color("b8860b"))
	_wheel.draw_string(font, center + Vector2(-4, 3), "đ", HORIZONTAL_ALIGNMENT_CENTER, 8, 9, Color.WHITE)

func _show_prize() -> void:
	_wheel.hide()
	_title.text = "CHÚC MỪNG!"
	_subtitle.text = "Phần thưởng quiz của bạn"
	_amount_label.text = "+%s" % _format_compact_amount(_prize_amount)
	_popup.show()
	prize_awarded.emit(_prize_amount)
	await get_tree().create_timer(POPUP_SECONDS).timeout
	hide()
	spin_finished.emit()

func _format_compact_amount(amount: int) -> String:
	return "%dk" % int(amount / 1000)


