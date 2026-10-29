extends "res://scripts/features/feature.gd"
# GÓC TRÁI TRÊN: 2 thanh nhỏ (rèn luyện ở trên, GPA ở dưới), đồng hồ và buổi học kế tiếp.
# Khi điểm rèn luyện đổi: chữ "+1 lý do" (xanh) hoặc "-2 lý do" (đỏ) nổi bên phải rồi mờ dần.
# File này chỉ VẼ. Số liệu ở student_stats.gd, thời khóa biểu ở schedule_data.gd.

const Schedule := preload("res://scripts/features/schedule_data.gd")

const X := 4.0           # góc trái trên (khung 480x270)
const Y := 4.0
const LABEL_W := 40.0    # chỗ cho tên thanh
const BAR_W := 60.0
const BAR_H := 6.0
const ROW_H := 11.0      # khoảng cách giữa 2 thanh
const POPUP_TIME := 1.6  # số giây chữ +/- tồn tại

# true: bấm phím để thử khi chạy game: 1 = +1 điểm, 2 = -2 điểm, 3 = +5 điểm, 4 = sang ngày sau, 5 = sang tuần sau.
var debug_keys := true

var stats: Node
var font: Font
var canvas: Control
var popups: Array = []   # mỗi phần tử: {"text": chữ, "color": màu, "t": số giây còn lại}

func _ready() -> void:
	stats = game.stats
	font = game.font
	stats.drl_changed.connect(_on_drl_changed)
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(canvas)
	canvas.draw.connect(_on_draw)   # khi canvas cần vẽ thì gọi _on_draw

func _process(delta: float) -> void:
	for p in popups:
		p.t -= delta
	popups = popups.filter(func(p): return p.t > 0.0)   # bỏ chữ đã hết giờ
	canvas.queue_redraw()                              # yêu cầu vẽ lại mỗi khung hình

func _unhandled_input(event: InputEvent) -> void:
	if not debug_keys:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				stats.add_drl(1, "Đi học đúng giờ")
			KEY_2:
				stats.add_drl(-2, "Đi học trễ")
			KEY_3:
				stats.add_drl(5, "Hoạt động tình nguyện")
			KEY_4:
				game.skip_days(1)
			KEY_5:
				game.skip_days(7)

func _on_drl_changed(amount: int, reason: String) -> void:
	var text := "%s%d" % ["+" if amount > 0 else "-", absi(amount)]
	if reason != "":
		text += " " + reason
	var color := Color(0.45, 1.0, 0.45) if amount > 0 else Color(1.0, 0.4, 0.4)
	popups.append({"text": text, "color": color, "t": POPUP_TIME})

func _on_draw() -> void:
	canvas.draw_rect(Rect2(2, 2, 176, 53), Color(0, 0, 0, 0.35))   # nền mờ cho dễ đọc
	paint_row(0, "Rèn luyện", stats.drl_text(), stats.drl_ratio())
	paint_row(1, "GPA", stats.gpa_text(), stats.gpa_ratio())
	var minute := int(game.game_min)
	var clock_line := "%s · %02d:%02d" % [Schedule.DAY_NAMES[Schedule.weekday(game.day)], int(minute / 60.0), minute % 60]
	write(Vector2(X, Y + 2 * ROW_H + 9), clock_line, Color.WHITE)
	write(Vector2(X, Y + 2 * ROW_H + 20), Schedule.next_class_text(game.day, game.game_min), Color(1.0, 0.85, 0.3))
	for i in popups.size():
		var p: Dictionary = popups[i]
		var life := clampf(p.t / POPUP_TIME, 0.0, 1.0)   # 1 = vừa hiện, 0 = biến mất
		var color: Color = p.color
		color.a = minf(1.0, life * 2.0)                  # mờ dần ở nửa sau
		write(Vector2(184, 11 + i * 10 + (1.0 - life) * 5.0), p.text, color)   # trôi nhẹ xuống

# Vẽ 1 thanh: tên bên trái, thanh ở giữa (đầy theo tỉ lệ, đổi màu), giá trị bên phải.
func paint_row(index: int, label: String, value_text: String, ratio: float) -> void:
	var y := Y + index * ROW_H
	write(Vector2(X, y + 7), label, Color.WHITE)
	var bar := Vector2(X + LABEL_W, y + 1)
	canvas.draw_rect(Rect2(bar, Vector2(BAR_W, BAR_H)), Color(0, 0, 0, 0.7))   # nền thanh
	canvas.draw_rect(Rect2(bar + Vector2(1, 1), Vector2((BAR_W - 2.0) * ratio, BAR_H - 2.0)), stats.bar_color(ratio))
	write(Vector2(bar.x + BAR_W + 4, y + 7), value_text, Color.WHITE)

# Chữ cỡ 8 có viền đen cho dễ đọc trên nền game
func write(pos: Vector2, text: String, color: Color) -> void:
	canvas.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, color.a))
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
