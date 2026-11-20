extends "res://scripts/features/feature.gd"
# CƠ CHẾ NGHỈ HỌC, HỌC LẠI & HỌC PHÍ (ĐÃ TỐI ƯU CÔNG BẰNG CHO NGƯỜI CHƠI)

const Schedule := preload("res://scripts/features/schedule_data.gd")

const MAX_UNEXCUSED_ABSENCES: int = 2
const RETAKE_NEXT_SEM_SURCHARGE: int = 300
const MIN_GPA_THRESHOLD: float = 1.5

const MIDTERM_WEEK: int = 8
const FINAL_WEEK: int = 15
const SEMESTER_DAYS: int = 105
const BASE_TUITION_FEE: int = 1200

var _layer: CanvasLayer
var _ui: Node2D
var _di_hoc_f: Node = null
var _quiz_f: Node = null
var _looked: bool = false

var absences_by_course: Dictionary = {}
var excuse_passes: int = 3
var _last_absent_course: String = ""
var _checked_sessions: Dictionary = {}
var retake_list: Array = []

var midterm_done: bool = false
var final_done: bool = false
var _reminded_weeks: Dictionary = {}
var _midterm_checked: bool = false
var _final_checked: bool = false
var _gpa_warned_week: int = -1

var _semester_idx: int = 1
var _tuition_required: int = BASE_TUITION_FEE
var _tuition_paid_this_sem: bool = false
var is_game_over: bool = false

var _modal_title: String = ""
var _modal_lines: Array = []
var _modal_can_excuse: bool = false
var _modal_is_gameover: bool = false
var _last_min: int = -1

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 9
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_ui = script.new()
	_ui.font = game.font
	_ui.logo = game.logo
	_layer.add_child(_ui)
	_ui.draw.connect(_paint)

func _lookup() -> void:
	if _looked:
		return
	_looked = true
	for f in game.features:
		if f == self:
			continue
		if _di_hoc_f == null and f.has_method("notify_seat_entered"):
			_di_hoc_f = f
		if _quiz_f == null and f.has_method("start_round") and f.has_method("begin"):
			_quiz_f = f

func register_session_result(session_key: String, course_name: String, present: bool) -> void:
	_checked_sessions[session_key] = true
	if not present:
		_record_absence(course_name)

func _record_absence(course: String) -> void:
	var cnt: int = int(absences_by_course.get(course, 0)) + 1
	absences_by_course[course] = cnt
	_last_absent_course = course

	if cnt == 1:
		_show_alert(
			"THÔNG BÁO VẮNG HỌC (1/3 BUỔI)",
			[
				"Bạn vừa vắng 1 buổi môn %s." % course,
				"Lưu ý: Vắng 2 buổi sẽ cảnh báo, đến buổi thứ 3 mới bị học lại.",
				"Bạn hiện có %d Đơn xin phép nếu cần xin nghỉ có lý do." % excuse_passes
			],
			excuse_passes > 0,
			false
		)
	elif cnt == MAX_UNEXCUSED_ABSENCES:
		_show_alert(
			"CẢNH BÁO ĐỎ · VẮNG 2/3 BUỔI MÔN %s" % course,
			[
				"CẢNH BÁO: Bạn đã vắng 2 buổi môn %s!" % course,
				"Chỉ còn 1 buổi nữa là bạn sẽ bị buộc HỌC LẠI môn này ở kỳ sau!",
				"Hãy đi học đầy đủ hoặc dùng Đơn xin phép (còn %d đơn)." % excuse_passes
			],
			excuse_passes > 0,
			false
		)
	elif cnt > MAX_UNEXCUSED_ABSENCES:
		if not retake_list.has(course):
			retake_list.append(course)
		_show_alert(
			"ĐĂNG KÝ HỌC LẠI KỲ SAU · MÔN %s" % course,
			[
				"Bạn đã vắng tới buổi thứ %d môn %s (vượt mức cho phép)." % [cnt, course],
				"Môn %s được xếp vào danh sách HỌC LẠI ở kỳ sau (+%dđ học phí kỳ sau)." % [course, RETAKE_NEXT_SEM_SURCHARGE],
				"Trò chơi vẫn tiếp tục — hãy cố gắng giữ GPA và đủ tiền học phí nhé!"
			],
			excuse_passes > 0,
			false
		)

func _use_excuse_pass() -> void:
	if excuse_passes <= 0 or _last_absent_course == "":
		return
	excuse_passes -= 1
	var cur: int = int(absences_by_course.get(_last_absent_course, 1))
	absences_by_course[_last_absent_course] = maxi(0, cur - 1)
	if int(absences_by_course[_last_absent_course]) <= MAX_UNEXCUSED_ABSENCES:
		retake_list.erase(_last_absent_course)
	_modal_title = "ĐÃ NỘP ĐƠN XIN PHÉP THÀNH CÔNG"
	_modal_lines = [
		"Đã dùng 1 Đơn xin phép (lý do ốm / việc gia đình) cho môn %s." % _last_absent_course,
		"Buổi vắng đã được hợp lệ hóa! Số đơn xin phép còn lại: %d." % excuse_passes
	]
	_modal_can_excuse = false
	_last_absent_course = ""
	_ui.queue_redraw()

func _process(_delta: float) -> void:
	_lookup()
	if is_game_over:
		_ui.queue_redraw()
		return

	var cur_week: int = maxi(1, int((game.day - 1) / 7) + 1)

	if _quiz_f != null and bool(_quiz_f.active):
		if cur_week >= MIDTERM_WEEK - 1 and cur_week <= MIDTERM_WEEK:
			midterm_done = true
		if cur_week >= FINAL_WEEK - 1 and cur_week <= FINAL_WEEK:
			final_done = true

	var now: int = int(game.game_min)
	if now == _last_min:
		_ui.queue_redraw()
		return
	_last_min = now

	_check_schedule_absences(now)
	_check_exam_milestones(cur_week)
	_check_gpa_status(cur_week)
	_check_semester_tuition(cur_week)
	_ui.queue_redraw()

func _check_schedule_absences(now: int) -> void:
	var day_idx: int = Schedule.weekday(game.day) + 2
	for c in Schedule.courses_on(day_idx):
		var t: Array = Schedule.time_range(c[1], c[3])
		var end_min: int = int(t[1])
		var key: String = "%d:%s:%s" % [game.day, str(c[0]), str(c[1])]
		if now >= end_min and not _checked_sessions.has(key):
			_checked_sessions[key] = true
			var present: bool = _di_hoc_f != null and _di_hoc_f.attended_sessions.has(key)
			if not present:
				_record_absence(str(c[0]))

func _check_exam_milestones(cur_week: int) -> void:
	if (cur_week == 6 or cur_week == 7) and not midterm_done and not _reminded_weeks.has(cur_week):
		_reminded_weeks[cur_week] = true
		_show_alert(
			"NHẮC NHỞ LỊCH THI GIỮA KỲ (TUẦN %d/8)" % cur_week,
			[
				"Kỳ thi Giữa kỳ sẽ diễn ra vào Tuần 8!",
				"Bạn chỉ cần gặp Cô Toán (hoặc vào phòng thi) làm Quiz 1 lần để hoàn thành.",
				"Mẹo: Chép bài trên lớp [C] để tích lũy Bí kíp giúp thi dễ hơn!"
			],
			false,
			false
		)

	if cur_week > MIDTERM_WEEK and not _midterm_checked:
		_midterm_checked = true
		if not midterm_done:
			if not retake_list.has("Học phần Giữa kỳ"):
				retake_list.append("Học phần Giữa kỳ")
			_show_alert(
				"CHƯA HOÀN THÀNH THI GIỮA KỲ",
				[
					"Bạn đã bỏ lỡ kỳ thi Giữa kỳ ở Tuần 8.",
					"Học phần này sẽ phải đăng ký HỌC LẠI ở kỳ sau (+%dđ học phí kỳ sau)." % RETAKE_NEXT_SEM_SURCHARGE,
					"Game vẫn tiếp tục — đừng quên thi Cuối kỳ ở Tuần 15!"
				],
				false,
				false
			)

	if (cur_week == 13 or cur_week == 14) and not _reminded_weeks.has(cur_week):
		_reminded_weeks[cur_week] = true
		_show_alert(
			"NHẮC NHỞ CUỐI KỲ & HẠN NỘP HỌC PHÍ (TUẦN %d/15)" % cur_week,
			[
				"Tuần 15 là hạn chót Thi Cuối kỳ và Đóng Học phí học kỳ!",
				"Học phí cần nộp: %dđ (Hiện có: %dđ)." % [_tuition_required, _get_money()],
				"Hãy làm thêm [J] hoặc trả lời Quiz để đảm bảo đủ tiền đóng học phí!"
			],
			false,
			false
		)

	if cur_week > FINAL_WEEK and not _final_checked:
		_final_checked = true
		if not final_done:
			if not retake_list.has("Học phần Cuối kỳ"):
				retake_list.append("Học phần Cuối kỳ")
			_show_alert(
				"CHƯA HOÀN THÀNH THI CUỐI KỲ",
				[
					"Bạn đã bỏ lỡ kỳ thi Cuối kỳ ở Tuần 15.",
					"Môn thiếu điểm sẽ xếp lịch HỌC LẠI vào học kỳ sau (+%dđ)." % RETAKE_NEXT_SEM_SURCHARGE
				],
				false,
				false
			)

func _check_gpa_status(cur_week: int) -> void:
	if game.stats == null:
		return
	var g: float = float(game.stats.gpa)
	if g < MIN_GPA_THRESHOLD and _gpa_warned_week != cur_week:
		_gpa_warned_week = cur_week
		_show_alert(
			"CẢNH BÁO HỌC VỤ · GPA THẤP (%.2f)" % g,
			[
				"GPA của bạn đang dưới ngưỡng %.2f." % MIN_GPA_THRESHOLD,
				"Các môn điểm thấp sẽ phải học lại ở kỳ sau (tốn thêm %dđ/môn)." % RETAKE_NEXT_SEM_SURCHARGE,
				"Hãy đi học đầy đủ, tập trung nghe giảng và nộp BTVN [H] để kéo GPA lên!"
			],
			false,
			false
		)

func _check_semester_tuition(cur_week: int) -> void:
	if cur_week > FINAL_WEEK and not _tuition_paid_this_sem:
		var money_now: int = _get_money()
		if money_now < _tuition_required:
			is_game_over = true
			_show_alert(
				"HẾT HẠN ĐÓNG HỌC PHÍ · GAME OVER",
				[
					"Đã hết Tuần 15 nhưng bạn không đủ tiền đóng học phí học kỳ!",
					"Số dư hiện tại: %dđ  |  Học phí yêu cầu: %dđ." % [money_now, _tuition_required],
					"Hãy cân đối thời gian làm thêm [J] và trả lời Quiz ở lần chơi sau nhé!"
				],
				false,
				true
			)
		else:
			_tuition_paid_this_sem = true
			_add_money(-_tuition_required)
			var extra_fee: int = retake_list.size() * RETAKE_NEXT_SEM_SURCHARGE
			_semester_idx += 1
			_tuition_required = BASE_TUITION_FEE + extra_fee
			excuse_passes = 3
			midterm_done = false
			final_done = false
			_midterm_checked = false
			_final_checked = false
			_tuition_paid_this_sem = false
			game.day = 1
			_reminded_weeks.clear()
			_show_alert(
				"ĐÓNG HỌC PHÍ THÀNH CÔNG · BẮT ĐẦU KỲ %d" % _semester_idx,
				[
					"Bạn đã hoàn thành nghĩa vụ học phí và bước sang Học kỳ %d!" % _semester_idx,
					"Số môn học lại kỳ này: %d môn (Học phí kỳ mới: %dđ)." % [retake_list.size(), _tuition_required],
					"Hệ thống đã cấp lại 3 Đơn xin phép mới cho học kỳ này."
				],
				false,
				false
			)
			retake_list.clear()

func _get_money() -> int:
	if game.stats != null:
		if "money" in game.stats:
			return int(game.stats.money)
		if "tien" in game.stats:
			return int(game.stats.tien)
	return 0

func _add_money(amount: int) -> void:
	if game.stats != null:
		if game.stats.has_method("add_money"):
			game.stats.add_money(amount)
			return
		if "money" in game.stats:
			game.stats.money = maxi(0, int(game.stats.money) + amount)

func _show_alert(title: String, lines: Array, can_excuse: bool, gameover: bool) -> void:
	_modal_title = title
	_modal_lines = lines
	_modal_can_excuse = can_excuse
	_modal_is_gameover = gameover
	begin()
	_ui.queue_redraw()

func _input(event: InputEvent) -> void:
	if _modal_title == "":
		return
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if _modal_is_gameover:
		if k.keycode == KEY_R or k.keycode == KEY_ENTER or k.keycode == KEY_SPACE:
			get_tree().reload_current_scene()
			get_viewport().set_input_as_handled()
		return
	if _modal_can_excuse and k.physical_keycode == KEY_U:
		_use_excuse_pass()
		get_viewport().set_input_as_handled()
		return
	if k.keycode == KEY_E or k.keycode == KEY_ENTER or k.keycode == KEY_SPACE or k.keycode == KEY_ESCAPE:
		_modal_title = ""
		_modal_lines.clear()
		_modal_can_excuse = false
		finish()
		get_viewport().set_input_as_handled()

func _paint() -> void:
	var p := _ui
	var cur_week: int = maxi(1, int((game.day - 1) / 7) + 1)
	var days_left: int = maxi(0, SEMESTER_DAYS - game.day + 1)
	var money_now: int = _get_money()
	var hud_txt: String = "HP: %d/%dđ (Còn %dd · T%d/15) | Phép: %d/3 | Học lại: %d" % [
		money_now, _tuition_required, days_left, cur_week, excuse_passes, retake_list.size()
	]
	var hw: float = p.font.get_string_size(hud_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
	var hx: float = 474.0 - hw
	p.rc(hx - 1.0, 18.0, hw + 2.0, 12.0, Color("2b2b2b"))
	p.rc(hx, 19.0, hw, 10.0, Color(0.06, 0.1, 0.18, 0.9))
	var hcol: Color = Color("4ade80") if money_now >= _tuition_required else (Color("fde047") if days_left > 21 else Color("f87171"))
	p.ctext(hud_txt, hx, 27.0, hw, 7, hcol)

	if _modal_title == "":
		return
	p.rc(0, 0, 480, 270, Color(0, 0, 0, 0.72 if _modal_is_gameover else 0.48))
	var r := Rect2(42, 58, 396, 150)
	p.draw_rect(r, Color(0.13, 0.04, 0.05, 0.97) if _modal_is_gameover else Color(0.05, 0.09, 0.16, 0.97))
	p.draw_rect(r, Color("ef4444") if _modal_is_gameover else Color("f59e0b"), false, 2.0)

	p.draw_string(p.font, Vector2(56, 80), _modal_title, HORIZONTAL_ALIGNMENT_LEFT, 368.0, 10, Color("fca5a5") if _modal_is_gameover else Color("fde047"))
	var yy: float = 104.0
	for line in _modal_lines:
		p.draw_string(p.font, Vector2(56, yy), str(line), HORIZONTAL_ALIGNMENT_LEFT, 368.0, 8, Color.WHITE)
		yy += 18.0

	var footer: String = "Bấm [R] hoặc [Enter] để chơi lại từ đầu" if _modal_is_gameover else (
		"Bấm [U] để dùng Đơn xin phép xóa vắng   |   [E] / [Enter] Bỏ qua" if _modal_can_excuse else "Bấm [E] hoặc [Enter] để tiếp tục"
	)
	p.draw_string(p.font, Vector2(56, 196), footer, HORIZONTAL_ALIGNMENT_LEFT, 368.0, 8, Color("93c5fd"))
