extends "res://scripts/features/feature.gd"
# SỔ TAY SINH VIÊN (bấm Tab để mở/đóng): thanh lịch học kỳ, nhiệm vụ hôm nay, thời khóa biểu tuần.
# Chỉ HIỂN THỊ dữ liệu từ schedule_data.gd và giờ trong game. Khi mở, người chơi đứng yên (active = true).
# "Nhiệm vụ hôm nay" chỉ liệt kê các buổi học; phần điểm danh, cộng trừ điểm, dấu "!" trên bản đồ làm ở file khác.

const Schedule := preload("res://scripts/features/schedule_data.gd")

const PX := 20.0    # vị trí và kích thước khung sổ tay (khung game 480x270)
const PY := 20.0
const PW := 440.0
const PH := 204.0
const ROW := 11.0   # khoảng cách giữa các dòng chữ

const WHITE := Color(1.0, 1.0, 1.0)
const GRAY := Color(0.62, 0.68, 0.76)
const GOLD := Color(1.0, 0.82, 0.25)
const GREEN := Color(0.5, 1.0, 0.5)
const AMBER := Color(1.0, 0.72, 0.2)
const RED := Color(1.0, 0.35, 0.35)

var font: Font
var canvas: Control

func _ready() -> void:
	font = game.font
	var layer := CanvasLayer.new()
	layer.layer = 8          # nằm trên thanh góc trái (layer 7)
	add_child(layer)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.visible = false   # chỉ hiện khi mở sổ tay
	layer.add_child(canvas)
	canvas.draw.connect(_on_draw)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		if active:
			finish()
		else:
			begin()
		get_viewport().set_input_as_handled()

func begin() -> void:
	super()                  # active = true -> người chơi đứng yên
	canvas.visible = true

func finish() -> void:
	super()
	canvas.visible = false

func _process(_delta: float) -> void:
	if active:
		canvas.queue_redraw()

func _on_draw() -> void:
	var minute := int(game.game_min)
	var wd := Schedule.weekday(game.day)
	var week := Schedule.week_no(game.day)
	canvas.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.5))               # làm tối nền game
	canvas.draw_rect(Rect2(PX, PY, PW, PH), Color(0.07, 0.11, 0.2, 0.97))      # khung
	canvas.draw_rect(Rect2(PX, PY, PW, PH), GOLD, false, 1.0)                  # viền vàng
	write(Vector2(PX + 8, PY + 14), "Sổ tay sinh viên", GOLD, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 10)
	var now_text := "%s · Tuần %d · %02d:%02d" % [Schedule.DAY_NAMES[wd], week, int(minute / 60.0), minute % 60]
	write(Vector2(PX + 8, PY + 14), now_text, WHITE, PW - 16.0, HORIZONTAL_ALIGNMENT_RIGHT)
	paint_calendar(PY + 28.0, week)
	paint_today(PY + 92.0, wd, minute)
	paint_week(PY + 92.0, wd)
	write(Vector2(PX + 8, PY + PH - 6.0), "Tab: đóng", GRAY, PW - 16.0, HORIZONTAL_ALIGNMENT_RIGHT)

# Thanh lịch học kỳ: mỗi ô là 1 tuần. Vàng cam = giữa kỳ, đỏ = cuối kỳ, khung trắng = tuần hiện tại.
func paint_calendar(y: float, week: int) -> void:
	write(Vector2(PX + 8, y + 7), "Học kỳ 1", WHITE)
	var exam_color := GOLD
	if week in Schedule.MIDTERM_WEEKS or week in Schedule.FINAL_WEEKS:
		exam_color = RED
	write(Vector2(PX + 8, y + 7), Schedule.exam_text(week), exam_color, PW - 16.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var total := Schedule.SEMESTER_WEEKS
	var step := (PW - 16.0) / total
	for i in total:
		var w := i + 1
		var x := PX + 8.0 + i * step
		var color := Color(0.18, 0.24, 0.34)        # tuần chưa tới
		if w < week:
			color = Color(0.38, 0.44, 0.54)         # tuần đã qua
		if w in Schedule.MIDTERM_WEEKS:
			color = AMBER
		elif w in Schedule.FINAL_WEEKS:
			color = RED
		canvas.draw_rect(Rect2(x, y + 12, step - 2.0, 9.0), color)
		if w == week:
			canvas.draw_rect(Rect2(x - 1.0, y + 11, step, 11.0), WHITE, false, 1.0)
		write(Vector2(x, y + 31), str(w), GRAY, step - 2.0, HORIZONTAL_ALIGNMENT_CENTER)
	var mid_x := PX + 8.0 + (Schedule.MIDTERM_WEEKS[0] - 1) * step
	var final_x := PX + 8.0 + (Schedule.FINAL_WEEKS[0] - 1) * step
	write(Vector2(mid_x, y + 42), "Giữa kỳ", AMBER, step * 2.0 - 2.0, HORIZONTAL_ALIGNMENT_CENTER)
	write(Vector2(final_x, y + 42), "Cuối kỳ", RED, step * 2.0 - 2.0, HORIZONTAL_ALIGNMENT_CENTER)

# Các buổi học hôm nay: xanh = đang học, trắng = sắp tới, xám = đã xong.
func paint_today(y: float, wd: int, minute: int) -> void:
	var x := PX + 8.0
	write(Vector2(x, y), "Nhiệm vụ hôm nay", GOLD)
	var today := Schedule.courses_on(wd + 2)
	if today.is_empty():
		write(Vector2(x, y + ROW), "Hôm nay không có lịch học.", GRAY)
		return
	var row := y + ROW
	for c in today:
		var t := Schedule.time_range(c[1], c[3])
		var color := WHITE
		if minute >= t[1]:
			color = GRAY
		elif minute >= t[0]:
			color = GREEN
		var line := "%s-%s %s (%s)" % [Schedule.clock_text(t[0]), Schedule.clock_text(t[1]), c[5], c[1]]
		write(Vector2(x, row), line, color)
		write(Vector2(x + 10.0, row + ROW), Schedule.place_text(c[4]), color)
		row += ROW * 2.0 + 3.0

# Cả tuần: buổi của hôm nay sáng lên, các buổi khác màu xám.
func paint_week(y: float, wd: int) -> void:
	var x := PX + 196.0
	write(Vector2(x, y), "Thời khóa biểu tuần", GOLD)
	var row := y + ROW
	for c in Schedule.COURSES:
		var t := Schedule.time_range(c[1], c[3])
		var color := GRAY
		if c[2] == wd + 2:
			color = WHITE
		write(Vector2(x, row), "T%d" % c[2], color)
		write(Vector2(x + 18.0, row), "%s-%s" % [Schedule.clock_text(t[0]), Schedule.clock_text(t[1])], color)
		write(Vector2(x + 76.0, row), "%s (%s)" % [c[5], c[1]], color)
		write(Vector2(x + 172.0, row), Schedule.place_text(c[4]), color)
		row += ROW

# Chữ trên nền khung tối (không cần viền)
func write(pos: Vector2, text: String, color: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, size := 8) -> void:
	canvas.draw_string(font, pos, text, align, width, size, color)
