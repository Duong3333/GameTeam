extends "res://scripts/features/feature.gd"
# CƠ CHẾ ĐI HỌC TƯƠNG TÁC (2.5 PHÚT THẬT MỖI TIẾT) & BÀI TẬP VỀ NHÀ (BTVN)
# - Điểm danh nhanh [E] trong 3.5 giây khi giảng viên gọi tên.
# - Tư thế học tập gọn gàng: [1] Nghe giảng (+Tập trung) hoặc [2] Ngủ gật (+Hồi năng lượng, -Tập trung).
# - Câu hỏi đột xuất dùng quiz có sẵn, Chép bài theo nhịp [C], Tương tác bạn cùng bàn [F] & BTVN [H].

const Schedule := preload("res://scripts/features/schedule_data.gd")

const LESSON_REAL_DURATION: float = 150.0     # 2.5 phút thật (150 giây) cho mỗi tiết học
const ROLLCALL_WINDOW: float = 3.5            # Cửa sổ điểm danh nhanh 3.5 giây
const STUDY_TIME_MULT: float = 4.0
const HW_STUDY_MINUTES_REQUIRED: float = 60.0
const HW_DEADLINE_DAYS: int = 3
const HW_GPA_REWARD: float = 0.02
const HW_GPA_PENALTY: float = 0.05

var _layer: CanvasLayer
var _ui: Node2D
var _quiz_f: Node = null
var _daily_f: Node = null
var _nghi_hoc_f: Node = null
var _looked: bool = false

var _sitting_room: String = ""
var _sitting_title: String = ""
var _has_adjacent_friend: bool = false

var lesson_active: bool = false
var _lesson_elapsed: float = 0.0
var _lesson_course: String = ""
var _lesson_session_key: String = ""
var _focus: float = 55.0               # 0..100
var _posture: String = "listen"        # "listen" | "sleep"
var _rollcall_active: bool = false
var _rollcall_timer: float = 0.0
var _rollcall_done: bool = false
var _rollcall_present: bool = false
var _next_rollcall_at: float = 18.0
var _next_popquiz_at: float = 55.0
var _popquiz_count: int = 0

# Mini-game Chép bài theo nhịp
var _note_game_active: bool = false
var _note_cursor: float = 0.0
var _note_dir: float = 1.0
var _note_target_key: int = 1
var _note_hits: int = 0
var _note_attempts: int = 0
var midterm_prep_bonus: int = 0

var _friend_menu_open: bool = false
var _fallback_quiz_open: bool = false
var _fb_q: Dictionary = {}

var attended_sessions: Dictionary = {}
var missed_by_rollcall: Dictionary = {}
var _hw_issued_sessions: Dictionary = {}
var homeworks: Array = []
var _next_hw_id: int = 1
var _show_hw_board: bool = false

var _toast_text: String = ""
var _toast_t: float = 0.0
var _last_checked_min: int = -1

const QUICK_QUESTIONS := [
	{"q": "Đạo hàm của hàm số f(x) = x^3 + 2x tại x = 1 là bao nhiêu?", "opts": ["[1] 5", "[2] 3", "[3] 6"], "ans": 1},
	{"q": "Trong C++, toán tử nào dùng để lấy địa chỉ của biến?", "opts": ["[1] *", "[2] &", "[3] ->"], "ans": 2},
	{"q": "Đồ thị vô hướng liên thông có n đỉnh thì cây khung có bao nhiêu cạnh?", "opts": ["[1] n", "[2] n + 1", "[3] n - 1"], "ans": 3},
	{"q": "Giới hạn lim (sin x / x) khi x tiến tới 0 bằng bao nhiêu?", "opts": ["[1] 0", "[2] 1", "[3] Vô cùng"], "ans": 2}
]

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 7
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
		if _quiz_f == null and f.has_method("start_round") and f.has_method("begin"):
			_quiz_f = f
		if _daily_f == null and f.has_method("consume_energy"):
			_daily_f = f
		if _nghi_hoc_f == null and f.has_method("register_session_result"):
			_nghi_hoc_f = f

func is_in_active_lesson() -> bool:
	return lesson_active

func is_session_modal_open() -> bool:
	return _friend_menu_open or _fallback_quiz_open or _note_game_active or (_quiz_f != null and bool(_quiz_f.active))

# ======================= KẾT NỐI KHI NGỒI / ĐỨNG DẬY =======================

func notify_seat_entered(room_key: String, room_title: String = "", friend_label: String = "") -> void:
	_lookup()
	_sitting_room = room_key
	_sitting_title = room_title
	_has_adjacent_friend = friend_label != ""

	var c: Array = _current_scheduled_course()
	if not c.is_empty():
		var key: String = _session_key(game.day, c)
		if not attended_sessions.has(key) and not missed_by_rollcall.has(key):
			_start_interactive_lesson(str(c[0]), key)
			return
	_toast("Ngồi tự học · Thời gian x4 (Bấm [B] nếu muốn vào tiết học giả lập)")

func notify_seat_exited() -> void:
	if lesson_active:
		_finish_interactive_lesson(true)
	_sitting_room = ""
	_sitting_title = ""
	_has_adjacent_friend = false
	_friend_menu_open = false
	_note_game_active = false
	_fallback_quiz_open = false

func _start_interactive_lesson(course_name: String, session_key: String) -> void:
	lesson_active = true
	_lesson_elapsed = 0.0
	_lesson_course = course_name
	_lesson_session_key = session_key
	_focus = 55.0
	_posture = "listen"
	_rollcall_active = false
	_rollcall_done = false
	_rollcall_present = false
	_next_rollcall_at = randf_range(12.0, 26.0)
	_next_popquiz_at = randf_range(45.0, 75.0)
	_popquiz_count = 0
	_note_game_active = false
	_friend_menu_open = false
	_toast("Bắt đầu tiết %s! Chú ý nghe giảng & chờ điểm danh [E]!" % course_name)

func _finish_interactive_lesson(left_early: bool) -> void:
	if not lesson_active:
		return
	lesson_active = false
	_note_game_active = false
	_friend_menu_open = false

	var present: bool = _rollcall_present and not left_early
	if present:
		attended_sessions[_lesson_session_key] = {
			"day": game.day,
			"course": _lesson_course,
			"room": _sitting_room
		}
		if _focus >= 75.0:
			_add_gpa(0.03)
			_add_drl(1, "Tập trung tốt trong tiết " + _lesson_course)
			_toast("Hết tiết %s! Tập trung %.0f%% -> +0.03 GPA & +1 ĐRL!" % [_lesson_course, _focus])
		else:
			_toast("Hết tiết %s! Tập trung %.0f%% (Cần >=75%% để nhận điểm cộng)." % [_lesson_course, _focus])
		_hw_issued_sessions[_lesson_session_key] = true
		_assign_homework(_lesson_course)
	else:
		missed_by_rollcall[_lesson_session_key] = true
		_toast("Vắng tiết %s (Lỡ điểm danh hoặc bỏ về sớm)!" % _lesson_course)

	if _nghi_hoc_f != null:
		_nghi_hoc_f.register_session_result(_lesson_session_key, _lesson_course, present)

	if _daily_f != null and _daily_f.has_method("record_study_minutes"):
		_daily_f.record_study_minutes(45.0, _sitting_room == "C")

# ======================= CẬP NHẬT MỖI FRAME =======================

func process_classroom_sitting(delta: float) -> void:
	if _sitting_room == "":
		return
	if _quiz_f != null and bool(_quiz_f.active):
		return

	if lesson_active:
		_update_active_lesson(delta)
	else:
		game.game_min += delta * game.TIME_SCALE * (STUDY_TIME_MULT - 1.0)
		var studied: float = delta * game.TIME_SCALE * STUDY_TIME_MULT
		_advance_homework_progress(studied)
		if _daily_f != null:
			_daily_f.consume_energy(delta * 0.45)
			if _daily_f.has_method("record_study_minutes"):
				_daily_f.record_study_minutes(studied, false)

func _update_active_lesson(delta: float) -> void:
	_lesson_elapsed += delta
	game.game_min += delta * 0.3

	# 1. Cập nhật Thanh tập trung & Năng lượng theo tư thế
	var low_energy: bool = _daily_f != null and float(_daily_f.energy) < 20.0
	if _posture == "listen":
		var rate: float = 1.6 if not low_energy else 0.7
		_focus = minf(100.0, _focus + delta * rate)
		if _daily_f != null:
			_daily_f.consume_energy(delta * 0.35)
	elif _posture == "sleep":
		_focus = maxf(0.0, _focus - delta * 3.0)
		if _daily_f != null:
			_daily_f.restore_energy(delta * 1.8)

	# 2. Sự kiện Điểm danh (3.5 giây phản xạ)
	if not _rollcall_done and not _rollcall_active and _lesson_elapsed >= _next_rollcall_at:
		_rollcall_active = true
		_rollcall_timer = ROLLCALL_WINDOW
		_toast("ĐIỂM DANH! Giảng viên gọi tên — Bấm [E] trong 3.5 giây!")

	if _rollcall_active:
		_rollcall_timer -= delta
		if _rollcall_timer <= 0.0:
			_rollcall_active = false
			_rollcall_done = true
			_rollcall_present = false
			_toast("Lỡ điểm danh! Buổi học này sẽ bị tính VẮNG.")

	# 3. Câu hỏi đột xuất (Pop Quiz)
	if _popquiz_count == 0 and _lesson_elapsed >= _next_popquiz_at and not is_session_modal_open():
		_popquiz_count += 1
		_trigger_pop_quiz()

	# 4. Mini-game Chép bài theo nhịp
	if _note_game_active:
		_note_cursor += _note_dir * delta * 1.15
		if _note_cursor >= 1.0:
			_note_cursor = 1.0
			_note_dir = -1.0
		elif _note_cursor <= 0.0:
			_note_cursor = 0.0
			_note_dir = 1.0

	# 5. Kết thúc tiết học sau 2.5 phút thật
	if _lesson_elapsed >= LESSON_REAL_DURATION:
		_finish_interactive_lesson(false)

func _trigger_pop_quiz() -> void:
	if _quiz_f != null:
		var code: String = "VTP1" if _lesson_course.find("Vi tích") >= 0 else "CSLT"
		_quiz_f.begin()
		_quiz_f.start_round(code, "CÂU HỎI ĐỘT XUẤT · " + _lesson_course)
		_add_money(150)
		_toast("Trả lời câu hỏi đột xuất trên lớp (+150đ thưởng tham gia)!")
	else:
		_fb_q = QUICK_QUESTIONS[randi() % QUICK_QUESTIONS.size()]
		_fallback_quiz_open = true

# ======================= XỬ LÝ PHÍM TRONG TIẾT HỌC =======================

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return

	if k.physical_keycode == KEY_H and not is_session_modal_open():
		_show_hw_board = not _show_hw_board
		_ui.queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if _sitting_room == "":
		return

	if not lesson_active and k.physical_keycode == KEY_B:
		var cname: String = _sitting_title if _sitting_title != "" else "Môn học trên lớp"
		var skey: String = "%d:%s:%d" % [game.day, _sitting_room, int(game.game_min)]
		_start_interactive_lesson(cname, skey)
		get_viewport().set_input_as_handled()
		return

	if not lesson_active:
		return

	if _fallback_quiz_open:
		var choice: int = 0
		if k.keycode == KEY_1 or k.keycode == KEY_KP_1:
			choice = 1
		elif k.keycode == KEY_2 or k.keycode == KEY_KP_2:
			choice = 2
		elif k.keycode == KEY_3 or k.keycode == KEY_KP_3:
			choice = 3
		if choice > 0:
			_fallback_quiz_open = false
			if choice == int(_fb_q.get("ans", 1)):
				_add_money(150)
				_add_gpa(0.02)
				_toast("Chính xác! Thưởng +150đ & +0.02 GPA!")
			else:
				_toast("Chưa đúng rồi, không sao cả — tiếp tục nghe giảng nhé!")
			get_viewport().set_input_as_handled()
		return

	if _friend_menu_open:
		if k.keycode == KEY_1 or k.keycode == KEY_KP_1:
			_friend_menu_open = false
			_focus = minf(100.0, _focus + 18.0)
			midterm_prep_bonus += 1
			_toast("Đã mượn vở bạn cùng bàn! (+18% Tập trung & +1 Bí kíp ôn thi)")
		elif k.keycode == KEY_2 or k.keycode == KEY_KP_2:
			_friend_menu_open = false
			_try_skip_class_with_friend()
		elif k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_F:
			_friend_menu_open = false
		get_viewport().set_input_as_handled()
		return

	if _note_game_active:
		if k.keycode == KEY_ESCAPE:
			_note_game_active = false
			get_viewport().set_input_as_handled()
			return
		var pressed_num: int = 0
		if k.keycode == KEY_1 or k.physical_keycode == KEY_A:
			pressed_num = 1
		elif k.keycode == KEY_2 or k.physical_keycode == KEY_S:
			pressed_num = 2
		elif k.keycode == KEY_3 or k.physical_keycode == KEY_D:
			pressed_num = 3
		elif k.keycode == KEY_4 or k.physical_keycode == KEY_F:
			pressed_num = 4
		if pressed_num > 0:
			_handle_note_rhythm_hit(pressed_num)
			get_viewport().set_input_as_handled()
		return

	var pk := k.physical_keycode
	if pk == KEY_E and _rollcall_active:
		_rollcall_active = false
		_rollcall_done = true
		_rollcall_present = true
		_focus = minf(100.0, _focus + 10.0)
		_toast("Điểm danh thành công! ('Em có mặt ạ!')")
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_1:
		_posture = "listen"
		_toast("Tư thế: Chăm chú nghe giảng (+Tập trung)")
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_2:
		_posture = "sleep"
		_toast("Tư thế: Ngủ gật trên bàn (+Hồi năng lượng, -Tập trung)")
		get_viewport().set_input_as_handled()
	elif pk == KEY_C:
		_start_note_rhythm_game()
		get_viewport().set_input_as_handled()
	elif pk == KEY_F:
		if _has_adjacent_friend:
			_friend_menu_open = true
		else:
			_toast("Không có bạn ngồi ngay cạnh để tương tác!")
		get_viewport().set_input_as_handled()

func _start_note_rhythm_game() -> void:
	_note_game_active = true
	_note_cursor = 0.0
	_note_dir = 1.0
	_note_hits = 0
	_note_attempts = 0
	_note_target_key = (randi() % 4) + 1

func _handle_note_rhythm_hit(key_num: int) -> void:
	_note_attempts += 1
	var in_zone: bool = absf(_note_cursor - 0.5) <= 0.16
	if key_num == _note_target_key and in_zone:
		_note_hits += 1
		_focus = minf(100.0, _focus + 6.0)
		_toast("Chép bài chuẩn nhịp! (%d/4)" % _note_hits)
	else:
		_toast("Lệch nhịp chép bài!")
	if _note_attempts >= 4:
		_note_game_active = false
		if _note_hits >= 3:
			midterm_prep_bonus += 2
			_toast("Hoàn tất chép bài xuất sắc! Nhận +2 Bí kíp ôn Giữa kỳ.")
		else:
			midterm_prep_bonus += 1
			_toast("Hoàn tất chép bài! Nhận +1 Bí kíp ôn Giữa kỳ.")
	else:
		_note_target_key = (randi() % 4) + 1

func _try_skip_class_with_friend() -> void:
	if randf() < 0.5:
		lesson_active = false
		if _daily_f != null:
			_daily_f.restore_energy(25.0)
		_toast("Trốn tiết trót lọt cùng bạn cùng bàn! (+25 Năng lượng)")
	else:
		_rollcall_present = false
		_add_drl(-2, "Rủ nhau trốn tiết bị phát hiện")
		_toast("Bị giảng viên bắt gặp trốn tiết! (-2 ĐRL & Tính vắng buổi này)")
		_finish_interactive_lesson(true)

# ======================= BÀI TẬP VỀ NHÀ (BTVN) =======================

func _session_key(day_num: int, c: Array) -> String:
	return "%d:%s:%s" % [day_num, str(c[0]), str(c[1])]

func _current_scheduled_course() -> Array:
	var day_idx: int = Schedule.weekday(game.day) + 2
	var now: int = int(game.game_min)
	for c in Schedule.courses_on(day_idx):
		var t: Array = Schedule.time_range(c[1], c[3])
		if now >= int(t[0]) and now < int(t[1]):
			return c
	return []

func _check_schedule_and_deadlines() -> void:
	var now: int = int(game.game_min)
	if now == _last_checked_min:
		return
	_last_checked_min = now

	var day_idx: int = Schedule.weekday(game.day) + 2
	for c in Schedule.courses_on(day_idx):
		var t: Array = Schedule.time_range(c[1], c[3])
		var end_min: int = int(t[1])
		var key: String = _session_key(game.day, c)
		if now >= end_min and not _hw_issued_sessions.has(key):
			_hw_issued_sessions[key] = true
			if attended_sessions.has(key):
				_assign_homework(str(c[0]))

	for hw in homeworks:
		if str(hw.get("status", "")) != "pending":
			continue
		var d_day: int = int(hw.get("deadline_day", 9999))
		var d_min: int = int(hw.get("deadline_min", 1020))
		if game.day > d_day or (game.day == d_day and now >= d_min):
			hw["status"] = "overdue"
			_add_gpa(-HW_GPA_PENALTY)
			_toast("Trễ deadline BTVN %s! Bị trừ %.2f GPA" % [str(hw.get("course", "")), HW_GPA_PENALTY])

func _assign_homework(course_name: String) -> void:
	var hw: Dictionary = {
		"id": _next_hw_id,
		"course": course_name,
		"title": "BTVN %s #%d" % [course_name, _next_hw_id],
		"assigned_day": game.day,
		"deadline_day": game.day + HW_DEADLINE_DAYS,
		"deadline_min": 1020,
		"progress_min": 0.0,
		"required_min": HW_STUDY_MINUTES_REQUIRED,
		"status": "pending"
	}
	_next_hw_id += 1
	homeworks.append(hw)
	_toast("Giao BTVN mới: %s (Hạn: Ngày %d - Đến phòng học ngồi tự học để làm)" % [course_name, int(hw["deadline_day"])])

func _advance_homework_progress(minutes: float) -> void:
	var target: Dictionary = {}
	for hw in homeworks:
		if str(hw.get("status", "")) == "pending":
			target = hw
			break
	if target.is_empty():
		return
	var prog: float = float(target.get("progress_min", 0.0)) + minutes
	var req: float = float(target.get("required_min", HW_STUDY_MINUTES_REQUIRED))
	target["progress_min"] = prog
	if prog >= req:
		target["status"] = "done"
		_add_gpa(HW_GPA_REWARD)
		if _daily_f != null and _daily_f.has_method("record_hw_completed"):
			_daily_f.record_hw_completed()
		_toast("Hoàn thành %s! (+%.2f GPA)" % [str(target.get("title", "BTVN")), HW_GPA_REWARD])

# ======================= HỖ TRỢ STATS & VẼ HUD =======================

func _add_gpa(x: float) -> void:
	if game.stats != null and game.stats.has_method("set_gpa"):
		game.stats.set_gpa(maxf(0.0, float(game.stats.gpa) + x))

func _add_drl(x: int, reason: String) -> void:
	if game.stats != null and game.stats.has_method("add_drl"):
		game.stats.add_drl(x, reason)

func _add_money(amount: int) -> void:
	if game.stats != null:
		if game.stats.has_method("add_money"):
			game.stats.add_money(amount)
			return
		if "money" in game.stats:
			game.stats.money = maxi(0, int(game.stats.money) + amount)

func _process(delta: float) -> void:
	_lookup()
	if _toast_t > 0.0:
		_toast_t -= delta
	_check_schedule_and_deadlines()
	_ui.queue_redraw()

func _toast(msg: String) -> void:
	_toast_text = msg
	_toast_t = 3.2

func _paint() -> void:
	var p := _ui
	var pending: int = 0
	for hw in homeworks:
		if str(hw.get("status", "")) == "pending":
			pending += 1
	var top_tag: String = "[H] BTVN: %d | Bí kíp GK: %d" % [pending, midterm_prep_bonus]
	var tw: float = p.font.get_string_size(top_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
	p.rc(474.0 - tw - 1.0, 4.0, tw + 2.0, 12.0, Color("2b2b2b"))
	p.rc(474.0 - tw, 5.0, tw, 10.0, Color(0.06, 0.1, 0.18, 0.9))
	p.ctext(top_tag, 474.0 - tw, 13.0, tw, 7, Color("fde047"))

	if _toast_t > 0.0:
		var bw: float = p.font.get_string_size(_toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 12.0
		var bx: float = clampf(240.0 - bw / 2.0, 4.0, 476.0 - bw)
		p.rc(bx - 1.0, 36.0, bw + 2.0, 14.0, Color("333333"))
		p.rc(bx, 37.0, bw, 12.0, Color(0.05, 0.12, 0.22, 0.95))
		p.ctext(_toast_text, bx, 46.0, bw, 8, Color("fde047"))

	if lesson_active:
		_paint_lesson_hud(p)
	if _note_game_active:
		_paint_note_minigame(p)
	if _friend_menu_open:
		_paint_friend_menu(p)
	if _fallback_quiz_open:
		_paint_fallback_quiz(p)
	if _show_hw_board:
		_paint_hw_modal(p)

func _paint_lesson_hud(p: Node2D) -> void:
	var r := Rect2(14, 212, 452, 52)
	p.draw_rect(r, Color(0.04, 0.08, 0.15, 0.94))
	p.draw_rect(r, Color("38bdf8"), false, 1.0)

	var remain: int = maxi(0, int(ceilf(LESSON_REAL_DURATION - _lesson_elapsed)))
	var mins: int = remain / 60
	var secs: int = remain % 60
	var header: String = "TIẾT HỌC: %s  |  Còn lại: %02d:%02d  |  Điểm danh: %s" % [
		_lesson_course, mins, secs,
		"ĐÃ CÓ MẶT" if _rollcall_present else ("ĐANG GỌI TÊN [E]!" if _rollcall_active else "Chờ gọi tên")
	]
	p.draw_string(p.font, Vector2(22, 225), header, HORIZONTAL_ALIGNMENT_LEFT, 436.0, 8, Color("fde047") if _rollcall_active else Color("7dd3fc"))

	p.draw_string(p.font, Vector2(22, 239), "Tập trung: %d%%" % int(_focus), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.rc(96, 231, 110, 9, Color("1e293b"))
	var fcol: Color = Color("22c55e") if _focus >= 75.0 else (Color("eab308") if _focus >= 40.0 else Color("ef4444"))
	p.rc(97, 232, 108.0 * (_focus / 100.0), 7, fcol)

	var controls: String = "[1] Nghe giảng   [2] Ngủ gật   [C] Chép bài   [F] Bạn cùng bàn   [Esc] Rời lớp"
	p.draw_string(p.font, Vector2(22, 255), controls, HORIZONTAL_ALIGNMENT_LEFT, 440.0, 7, Color("cbd5e1"))

	if _rollcall_active:
		var box := Rect2(125, 84, 230, 34)
		p.draw_rect(box, Color(0.55, 0.08, 0.08, 0.96))
		p.draw_rect(box, Color("fde047"), false, 1.5)
		p.ctext("GIẢNG VIÊN ĐIỂM DANH! BẤM [E] (%.1fs)" % _rollcall_timer, 129, 105, 222, 8, Color.WHITE)

func _paint_note_minigame(p: Node2D) -> void:
	var r := Rect2(115, 92, 250, 76)
	p.draw_rect(r, Color(0.05, 0.1, 0.18, 0.96))
	p.draw_rect(r, Color("eab308"), false, 1.5)
	var key_names := ["", "1 / A", "2 / S", "3 / D", "4 / F"]
	p.draw_string(p.font, Vector2(128, 110), "MINI-GAME CHÉP BÀI (%d/4)" % _note_attempts, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("fde047"))
	p.draw_string(p.font, Vector2(128, 125), "Canh vạch trắng vào ô xanh & bấm phím: [%s]" % key_names[_note_target_key], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.rc(130, 136, 220, 14, Color("1e293b"))
	p.rc(130 + 220 * 0.34, 136, 220 * 0.32, 14, Color("16a34a"))
	var cx: float = 130.0 + _note_cursor * 216.0
	p.rc(cx, 134, 4, 18, Color.WHITE)

func _paint_friend_menu(p: Node2D) -> void:
	var r := Rect2(105, 92, 270, 84)
	p.draw_rect(r, Color(0.05, 0.1, 0.18, 0.96))
	p.draw_rect(r, Color("38bdf8"), false, 1.5)
	p.draw_string(p.font, Vector2(118, 110), "Tương tác với bạn cùng bàn", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7dd3fc"))
	p.draw_string(p.font, Vector2(118, 129), "[1] Mượn vở chép bù (+18% Tập trung & +Bí kíp)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.draw_string(p.font, Vector2(118, 145), "[2] Rủ trốn tiết (50% hồi Năng lượng / 50% bị bắt)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fca5a5"))
	p.draw_string(p.font, Vector2(118, 163), "[Esc] Thôi, quay lại nghe giảng", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("94a3b8"))

func _paint_fallback_quiz(p: Node2D) -> void:
	var r := Rect2(84, 80, 312, 98)
	p.draw_rect(r, Color(0.05, 0.1, 0.18, 0.97))
	p.draw_rect(r, Color("eab308"), false, 1.5)
	p.draw_string(p.font, Vector2(96, 98), "CÂU HỎI ĐỘT XUẤT (Đúng +150đ, Sai không mất gì)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fde047"))
	p.draw_string(p.font, Vector2(96, 115), str(_fb_q.get("q", "")), HORIZONTAL_ALIGNMENT_LEFT, 290.0, 8, Color.WHITE)
	var opts: Array = _fb_q.get("opts", [])
	for i in opts.size():
		p.draw_string(p.font, Vector2(102, 134 + i * 14), str(opts[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("93c5fd"))

func _paint_hw_modal(p: Node2D) -> void:
	var r := Rect2(44, 44, 392, 182)
	p.draw_rect(r, Color(0.04, 0.08, 0.15, 0.96))
	p.draw_rect(r, Color("eab308"), false, 1.0)
	p.draw_string(p.font, Vector2(56, 62), "DANH SÁCH BÀI TẬP VỀ NHÀ (BTVN)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("fde047"))
	p.draw_string(p.font, Vector2(56, 75), "Vào phòng học hoặc thư viện ngồi tự học để hoàn thành BTVN trước hạn.", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.75))
	if homeworks.is_empty():
		p.draw_string(p.font, Vector2(56, 105), "Chưa có BTVN nào được giao.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	else:
		var start_idx: int = maxi(0, homeworks.size() - 6)
		var row_y: float = 96.0
		for i in range(start_idx, homeworks.size()):
			var hw: Dictionary = homeworks[i]
			var st: String = str(hw.get("status", "pending"))
			var pct: int = mini(100, int(round((float(hw.get("progress_min", 0.0)) / float(hw.get("required_min", 60.0))) * 100.0)))
			var line: String = "- %s | Hạn: Ngày %d | %s" % [
				str(hw.get("title", "")),
				int(hw.get("deadline_day", 0)),
				"HOÀN THÀNH" if st == "done" else ("QUÁ HẠN (-GPA)" if st == "overdue" else "Tiến độ: %d%%" % pct)
			]
			var col: Color = Color("4ade80") if st == "done" else (Color("f87171") if st == "overdue" else Color.WHITE)
			p.draw_string(p.font, Vector2(56, row_y), line, HORIZONTAL_ALIGNMENT_LEFT, 370.0, 8, col)
			row_y += 17.0
	p.draw_string(p.font, Vector2(56, 216), "Bấm [H] để đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("93c5fd"))
