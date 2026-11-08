extends Control

signal replay_requested
signal close_requested

var rank_label: Label
var stars_label: Label
var stats_label: Label

func _ready() -> void:
	_build_ui()

func show_result(data: Dictionary) -> void:
	rank_label.text = str(data.get("rank", ""))
	stars_label.text = str(data.get("stars", ""))
	stats_label.text = str(data.get("stats", ""))

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.05, 0.1, 0.2, 0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	rank_label = _add_label(Rect2(10, 26, 440, 24), 15, Color.WHITE)
	stars_label = _add_label(Rect2(10, 52, 440, 36), 25, Color("ffd23f"))
	stats_label = _add_label(Rect2(18, 88, 424, 116), 8, Color("dfe6ff"))
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var replay := Button.new()
	replay.position = Vector2(40, 211)
	replay.size = Vector2(170, 28)
	replay.text = "Chơi lại  (Enter)"
	replay.pressed.connect(func() -> void: replay_requested.emit())
	add_child(replay)
	var close := Button.new()
	close.position = Vector2(230, 211)
	close.size = Vector2(170, 28)
	close.text = "Đóng"
	close.pressed.connect(func() -> void: close_requested.emit())
	add_child(close)

func _add_label(rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
