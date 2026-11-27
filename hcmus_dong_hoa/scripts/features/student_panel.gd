extends "res://scripts/features/feature.gd"
# SỔ TAY SINH VIÊN (bấm Tab để mở/đóng): thanh lịch học kỳ, nhiệm vụ hôm nay, thời khóa biểu tuần.
# Chỉ HIỂN THỊ dữ liệu từ schedule_data.gd và giờ trong game. Khi mở, người chơi đứng yên (active = true).
# "Nhiệm vụ hôm nay" chỉ liệt kê các buổi học; phần điểm danh, cộng trừ điểm, dấu "!" trên bản đồ làm ở file khác.

const Schedule := preload("res://scripts/features/schedule_data.gd")

const PX := 16.0    # vị trí và kích thước khung sổ tay (khung game 480x270)
const PY := 10.0
const PW := 448.0
const PH := 228.0
const ROW := 11.0   # khoảng cách giữa các dòng chữ

const WHITE := Color(1.0, 1.0, 1.0)
const GRAY := Color(0.62, 0.68, 0.76)
const GOLD := Color(1.0, 0.82, 0.25)
const GREEN := Color(0.5, 1.0, 0.5)
const AMBER := Color(1.0, 0.72, 0.2)
const RED := Color(1.0, 0.35, 0.35)
const NOTICE_SECONDS := 7.0

var font: Font
var canvas: Control
var show_homework_page := false
var selected_homework := 0
var notice_title := ""
var notice_body := ""
var notice_time := 0.0
var close_notice_button: Button
var _box_cache: Dictionary = {}

func _ready() -> void:
	font = game.font
	if game.stats != null and game.stats.has_signal("money_changed"):
		game.stats.money_changed.connect(_on_money_changed)
	var layer := CanvasLayer.new()
	layer.layer = 8          # nằm trên thanh góc trái (layer 7)
	add_child(layer)
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.visible = false   # chỉ hiện khi mở sổ tay
	layer.add_child(canvas)
	canvas.draw.connect(_on_draw)
	close_notice_button = Button.new()
	close_notice_button.position = Vector2(379, 91)
	close_notice_button.size = Vector2(16, 16)
	close_notice_button.text = "X"
	close_notice_button.focus_mode = Control.FOCUS_NONE
	close_notice_button.add_theme_font_override("font", font)
	close_notice_button.add_theme_font_size_override("font_size", 7)
	close_notice_button.add_theme_color_override("font_color", WHITE)
	close_notice_button.add_theme_stylebox_override("normal", _notice_close_style(Color("7f3540")))
	close_notice_button.add_theme_stylebox_override("hover", _notice_close_style(Color("b94b58")))
	close_notice_button.pressed.connect(_dismiss_notice)
	close_notice_button.visible = false
	canvas.add_child(close_notice_button)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_TAB:
		if active:
			finish()
		elif _can_open():
			show_homework_page = false
			begin()
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if key.keycode == KEY_ESCAPE:
		finish()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_B:
		if not show_homework_page:
			selected_homework = maxi(0, _homework_assignments().size() - 1)
		show_homework_page = not show_homework_page
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_G:
		var requested := false
		if game.stats != null and game.stats.has_method("request_tuition_prompt"):
			requested = bool(game.stats.call("request_tuition_prompt", Schedule.week_no(game.day)))
		if not requested:
			show_notice("HỌC PHÍ", "Hiện không có khoản học phí nào cần quyết định.")
		get_viewport().set_input_as_handled()
	elif show_homework_page and key.keycode in [KEY_UP, KEY_DOWN]:
		var assignments := _homework_assignments()
		if not assignments.is_empty():
			var step := -1 if key.keycode == KEY_UP else 1
			selected_homework = posmod(selected_homework + step, assignments.size())
		get_viewport().set_input_as_handled()
	elif show_homework_page and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_start_selected_homework()
		get_viewport().set_input_as_handled()

# Trong giang duong / phong hoc, building_doors dat active = true nen is_busy() luon true.
# Van cho mo so tay neu viec "ban" duy nhat la dang o trong phong (khong co quiz hay UI khac dang mo).
func _can_open() -> bool:
	if not game.is_busy():
		return true
	var in_room := false
	for feature in game.features:
		if feature == self or not is_instance_valid(feature):
			continue
		# Bat ky module nao co bien "inside" (building_doors, phong hoc/giang duong trong scripts/maps...)
		if feature.get("inside") != null:
			if bool(feature.get("inside")):
				in_room = true
			continue
		if feature.get("active") == true:
			return false
	return in_room

func begin() -> void:
	super()                  # active = true -> người chơi đứng yên
	canvas.visible = true

func finish() -> void:
	super()
	canvas.visible = notice_time > 0.0

func _process(delta: float) -> void:
	if notice_time > 0.0:
		notice_time = maxf(notice_time - delta, 0.0)
	close_notice_button.visible = notice_time > 0.0
	if active or notice_time > 0.0:
		canvas.visible = true
		canvas.queue_redraw()
	else:
		canvas.visible = false

func show_notice(title: String, body: String) -> void:
	notice_title = title
	notice_body = body
	notice_time = NOTICE_SECONDS
	canvas.visible = true
	close_notice_button.visible = true
	canvas.queue_redraw()

func _dismiss_notice() -> void:
	notice_time = 0.0
	close_notice_button.hide()
	if not active:
		canvas.hide()
	canvas.queue_redraw()

func _notice_close_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("c4a66a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	return style

func _on_money_changed(amount: int, reason: String) -> void:
	if amount >= 0 or not reason.begins_with("Học phí"):
		return
	var stage := "GIỮA KỲ" if reason == "Học phí giữa kỳ" else "CUỐI KỲ"
	show_notice("ĐÃ ĐÓNG HỌC PHÍ " + stage, "Đã đóng %s.\nNhấn Tab rồi B để xem trạng thái." % game.stats.money_compact_text(absi(amount)))

func _box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var key := "%s|%s|%d" % [bg.to_html(true), border.to_html(true), radius]
	if _box_cache.has(key):
		return _box_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(0)
	_box_cache[key] = style
	return style

func _on_draw() -> void:
	if active:
		var minute := int(game.game_min)
		var wd := Schedule.weekday(game.day)
		var week := Schedule.week_no(game.day)
		canvas.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.55))
		canvas.draw_style_box(_box(Color(0.06, 0.1, 0.19, 0.98), GOLD, 8), Rect2(PX, PY, PW, PH))
		# Tieu de + dong ho
		write(Vector2(PX + 12, PY + 17), "MENU SINH VIÊN", GOLD, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 10)
		var now_text := "%s · Tuần %d · %02d:%02d" % [Schedule.DAY_NAMES[wd], week, int(minute / 60.0), minute % 60]
		write(Vector2(PX + 12, PY + 17), now_text, WHITE, PW - 24.0, HORIZONTAL_ALIGNMENT_RIGHT)
		canvas.draw_line(Vector2(PX + 10, PY + 23), Vector2(PX + PW - 10, PY + 23), Color(1, 1, 1, 0.14), 1.0)
		if show_homework_page:
			paint_homework()
		else:
			paint_calendar(PY + 29.0, week)
			# Hoc phi: thanh rieng, khong de len chu khac
			canvas.draw_style_box(_box(Color(1.0, 0.72, 0.2, 0.12), Color(1.0, 0.72, 0.2, 0.45), 4), Rect2(PX + 10, PY + 76, PW - 20, 13))
			write(Vector2(PX + 16, PY + 85.5), _tuition_text(week), AMBER, PW - 32.0, HORIZONTAL_ALIGNMENT_LEFT, 8)
			var top := PY + 95.0
			paint_today(Rect2(PX + 10, top, 204, 116), wd, minute)
			paint_week(Rect2(PX + 222, top, 216, 116), wd)
		canvas.draw_line(Vector2(PX + 10, PY + PH - 16), Vector2(PX + PW - 10, PY + PH - 16), Color(1, 1, 1, 0.14), 1.0)
		write(Vector2(PX + 12, PY + PH - 5.5), "B: Bài tập  ·  G: Học phí  ·  Tab: đóng", GRAY, PW - 24.0, HORIZONTAL_ALIGNMENT_RIGHT, 7)
	if notice_time > 0.0:
		canvas.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.32))
		_draw_notice()

func paint_homework() -> void:
	write(Vector2(PX + 8, PY + 34), _tuition_text(Schedule.week_no(game.day)), AMBER)
	write(Vector2(PX + 8, PY + 54), "Bài tập về nhà", GOLD)
	var assignments := _homework_assignments()
	if assignments.is_empty():
		write(Vector2(PX + 8, PY + 72), "Chưa có bài tập. Bài tập sẽ được giao sau buổi học Cơ sở lập trình.", GRAY, PW - 16.0)
		return
	selected_homework = clampi(selected_homework, 0, assignments.size() - 1)
	var first_index := clampi(selected_homework - 5, 0, max(0, assignments.size() - 8))
	var last_index := mini(assignments.size(), first_index + 8)
	for i in range(first_index, last_index):
		var baseline := PY + 73.0 + (i - first_index) * 13.0
		if i == selected_homework:
			canvas.draw_rect(Rect2(PX + 6, baseline - 9, PW - 12, 12), Color("29456b"))
		var assignment: Dictionary = assignments[i]
		var completed := bool(assignment.get("completed", false))
		var title := str(assignment.get("title", "Bài tập"))
		write(Vector2(PX + 12, baseline), title, GREEN if completed else WHITE, 278.0)
		write(Vector2(PX + PW - 10, baseline), "Đã làm" if completed else "Chưa làm", GREEN if completed else AMBER, 92.0, HORIZONTAL_ALIGNMENT_RIGHT)
	write(Vector2(PX + 8, PY + PH - 22), "↑/↓ chọn  ·  Enter làm quiz  ·  G: học phí  ·  B: lịch", GRAY)

func _tuition_text(week: int) -> String:
	if game.stats != null and game.stats.has_method("tuition_summary"):
		return str(game.stats.call("tuition_summary", week))
	return "Học phí: chưa có dữ liệu"

func _homework_assignments() -> Array:
	for feature in game.features:
		if feature != self and feature.has_method("get_homework_assignments"):
			var value: Variant = feature.call("get_homework_assignments")
			if typeof(value) == TYPE_ARRAY:
				return value
	return []

func _start_selected_homework() -> void:
	var assignments := _homework_assignments()
	if assignments.is_empty():
		return
	selected_homework = clampi(selected_homework, 0, assignments.size() - 1)
	var assignment: Dictionary = assignments[selected_homework]
	if bool(assignment.get("completed", false)):
		return
	var assignment_id := str(assignment.get("id", ""))
	for feature in game.features:
		if feature != self and feature.has_method("start_homework"):
			if bool(feature.call("start_homework", assignment_id)):
				notice_time = 0.0
				finish()
			return

func _draw_notice() -> void:
	canvas.draw_rect(Rect2(80, 88, 320, 94), Color(0.02, 0.04, 0.09, 0.97))
	canvas.draw_rect(Rect2(80, 88, 320, 94), GOLD, false, 2.0)
	write(Vector2(90, 109), notice_title, GOLD, 300.0, HORIZONTAL_ALIGNMENT_CENTER, 10)
	var body_lines := notice_body.split("\n")
	var body_y := 135.0 - (body_lines.size() - 1) * 6.0
	for line in body_lines:
		write(Vector2(90, body_y), line, WHITE, 300.0, HORIZONTAL_ALIGNMENT_CENTER, 8)
		body_y += 12.0
	write(Vector2(90, 171), "Tab → B để xem lại trong Menu", GRAY, 300.0, HORIZONTAL_ALIGNMENT_CENTER, 7)

# Thanh lich hoc ky: moi o la 1 tuan. Vang cam = giua ky, do = cuoi ky, khung trang = tuan hien tai.
func paint_calendar(y: float, week: int) -> void:
	var left := PX + 12.0
	var span := PW - 24.0
	write(Vector2(left, y + 7), "Học kỳ 1", WHITE)
	var exam_color := GOLD
	if week in Schedule.MIDTERM_WEEKS or week in Schedule.FINAL_WEEKS:
		exam_color = RED
	write(Vector2(left, y + 7), Schedule.exam_text(week), exam_color, span, HORIZONTAL_ALIGNMENT_RIGHT)
	var total := Schedule.SEMESTER_WEEKS
	var step := span / total
	for i in total:
		var w := i + 1
		var x := left + i * step
		var color := Color(0.18, 0.24, 0.34)        # tuan chua toi
		if w < week:
			color = Color(0.38, 0.44, 0.54)         # tuan da qua
		if w in Schedule.MIDTERM_WEEKS:
			color = AMBER
		elif w in Schedule.FINAL_WEEKS:
			color = RED
		canvas.draw_rect(Rect2(x, y + 12, step - 2.0, 9.0), color)
		if w == week:
			canvas.draw_rect(Rect2(x - 1.0, y + 11, step, 11.0), WHITE, false, 1.0)
		write(Vector2(x, y + 30), str(w), WHITE if w == week else GRAY, step - 2.0, HORIZONTAL_ALIGNMENT_CENTER, 7)
	var mid_x := left + (Schedule.MIDTERM_WEEKS[0] - 1) * step
	var final_x := left + (Schedule.FINAL_WEEKS[0] - 1) * step
	write(Vector2(mid_x, y + 40), "Giữa kỳ", AMBER, step * 2.0 - 2.0, HORIZONTAL_ALIGNMENT_CENTER, 7)
	write(Vector2(final_x, y + 40), "Cuối kỳ", RED, step * 2.0 - 2.0, HORIZONTAL_ALIGNMENT_CENTER, 7)

func _card(rect: Rect2, title: String) -> void:
	canvas.draw_style_box(_box(Color(1, 1, 1, 0.045), Color(1, 1, 1, 0.12), 5), rect)
	write(Vector2(rect.position.x + 7, rect.position.y + 11), title, GOLD, rect.size.x - 14.0, HORIZONTAL_ALIGNMENT_LEFT, 8)

# Cac buoi hoc hom nay: the rieng tung buoi. Xanh = dang hoc, xanh duong = sap toi, xam = da xong.
func paint_today(card: Rect2, wd: int, minute: int) -> void:
	_card(card, "Nhiệm vụ hôm nay")
	var today := Schedule.courses_on(wd + 2)
	var x := card.position.x + 6.0
	var w := card.size.x - 12.0
	if today.is_empty():
		write(Vector2(x + 2, card.position.y + 32), "Hôm nay không có lịch học.", GRAY, w)
		return
	var three_lines := today.size() <= 3
	var gap := 2.0
	var h := 32.0 if three_lines else minf(22.0, (card.size.y - 20.0 - (today.size() - 1) * gap) / today.size())
	var cy := card.position.y + 17.0
	for c in today:
		var t := Schedule.time_range(c[1], c[3])
		var color := WHITE
		var strip := Color("75c8ff")
		var tag := "SẮP TỚI"
		if minute >= t[1]:
			color = GRAY
			strip = Color(0.45, 0.5, 0.58)
			tag = "ĐÃ XONG"
		elif minute >= t[0]:
			color = GREEN
			strip = GREEN
			tag = "ĐANG HỌC"
		canvas.draw_style_box(_box(Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), 3), Rect2(x, cy, w, h))
		canvas.draw_rect(Rect2(x, cy + 2, 3, h - 4), strip)
		var time_text := "%s-%s" % [Schedule.clock_text(t[0]), Schedule.clock_text(t[1])]
		write(Vector2(x + 8, cy + 10), time_text, color, 80.0)
		write(Vector2(x + w - 4 - 70.0, cy + 10), tag, strip, 70.0, HORIZONTAL_ALIGNMENT_RIGHT, 7)
		var subject := "%s (%s)" % [c[5], c[1]]
		if three_lines:
			write(Vector2(x + 8, cy + 20), subject, color, w - 14.0)
			write(Vector2(x + 8, cy + 28.5), Schedule.place_text(c[4]), GRAY if color != GREEN else GREEN, w - 14.0, HORIZONTAL_ALIGNMENT_LEFT, 7)
		else:
			write(Vector2(x + 8, cy + 19), "%s · %s" % [subject, Schedule.place_text(c[4])], color, w - 14.0, HORIZONTAL_ALIGNMENT_LEFT, 7)
		cy += h + gap

# Ca tuan: buoi cua hom nay duoc to nen va sang len, cac buoi khac mau xam.
func paint_week(card: Rect2, wd: int) -> void:
	_card(card, "Thời khóa biểu tuần")
	var x := card.position.x
	var row := card.position.y + 25.0
	for c in Schedule.COURSES:
		var t := Schedule.time_range(c[1], c[3])
		var color := GRAY
		if c[2] == wd + 2:
			color = WHITE
			canvas.draw_rect(Rect2(x + 3, row - 8, card.size.x - 6, 10), Color(0.46, 0.78, 1.0, 0.16))
		write(Vector2(x + 7, row), "T%d" % c[2], color, 16.0, HORIZONTAL_ALIGNMENT_LEFT, 7)
		write(Vector2(x + 24, row), "%s-%s" % [Schedule.clock_text(t[0]), Schedule.clock_text(t[1])], color, 50.0, HORIZONTAL_ALIGNMENT_LEFT, 7)
		write(Vector2(x + 77, row), "%s (%s)" % [c[5], c[1]], color, 88.0, HORIZONTAL_ALIGNMENT_LEFT, 7)
		write(Vector2(x + card.size.x - 6 - 42.0, row), Schedule.place_text(c[4]), color, 42.0, HORIZONTAL_ALIGNMENT_RIGHT, 7)
		row += 10.0

func _fit(text: String, width: float, size: int) -> String:
	if width <= 0.0 or font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= width:
		return text
	var cut := text
	while cut.length() > 1 and font.get_string_size(cut + "...", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "..."

# Chu tren nen khung toi (khong can vien). Tu cat "..." neu vuot qua width.
func write(pos: Vector2, text: String, color: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, size := 8) -> void:
	canvas.draw_string(font, pos, _fit(text, width, size), align, width, size, color)
