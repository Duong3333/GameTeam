extends "res://scripts/features/feature.gd"
# LỰA CHỌN TRONG NGÀY: THANH NĂNG LƯỢNG, LÀM THÊM KIẾM TIỀN, SỰ KIỆN NGẪU NHIÊN & MỤC TIÊU TUẦN

var _layer: CanvasLayer
var _ui: Node2D

var energy: float = 85.0
const MAX_ENERGY: float = 100.0

var _menu_open: bool = false
var _event_open: bool = false
var _current_event: Dictionary = {}
var _last_event_day: int = -1
var _last_event_hour: int = -1

var _goal_week: int = 1
var _goal_type: int = 0
var _goal_progress: float = 0.0
var _goal_target: float = 300.0
var _goal_title: String = "Tuần 1: Tự học đủ 5 giờ ở thư viện"
var _goal_claimed: bool = false

var _toast_text: String = ""
var _toast_t: float = 0.0

const RANDOM_EVENTS := [
	{
		"id": "hangout",
		"title": "SỰ KIỆN: BẠN BÈ RỦ ĐI CHƠI",
		"desc": "Nhóm bạn cùng phòng rủ đi trà sữa & dạo phố buổi tối.",
		"opt1": "[1] Đi chơi cùng bạn (-80đ, hồi +35 Năng lượng & +1 ĐRL)",
		"opt2": "[2] Từ chối ở lại ôn bài (+0.02 GPA, tốn 10 Năng lượng)"
	},
	{
		"id": "wallet",
		"title": "SỰ KIỆN: NHẶT ĐƯỢC VÍ TIỀN",
		"desc": "Bạn thấy một chiếc ví rơi gần ghế đá sân trường.",
		"opt1": "[1] Mang nộp phòng Công tác Sinh viên (+3 ĐRL)",
		"opt2": "[2] Giữ lại tiền bên trong (+200đ, -1 ĐRL)"
	},
	{
		"id": "class_cancel",
		"title": "SỰ KIỆN: LỚP NGHỈ ĐỘT XUẤT",
		"desc": "Giảng viên bận họp đột xuất nên buổi học chiều nay được nghỉ!",
		"opt1": "[1] Tranh thủ vào thư viện tự học (+0.03 GPA & +60p mục tiêu tuần)",
		"opt2": "[2] Về ký túc xá ngủ bù (+40 Năng lượng)"
	},
	{
		"id": "rain",
		"title": "SỰ KIỆN: TRỜI ĐỔ MƯA RÀO BẤT CHỢT",
		"desc": "Mây đen kéo tới và mưa lớn ngoài sân trường.",
		"opt1": "[1] Đội mưa chạy về phòng (-20 Năng lượng, tiết kiệm thời gian)",
		"opt2": "[2] Trú mưa ở sảnh & tranh thủ xem lại bài (+0.01 GPA)"
	}
]

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_ui = script.new()
	_ui.font = game.font
	_ui.logo = game.logo
	_layer.add_child(_ui)
	_ui.draw.connect(_paint)
	_setup_weekly_goal(1)

func consume_energy(amount: float) -> void:
	energy = maxf(0.0, energy - amount)

func restore_energy(amount: float) -> void:
	energy = minf(MAX_ENERGY, energy + amount)

func record_study_minutes(mins: float, in_library: bool) -> void:
	if _goal_type == 0 and in_library and not _goal_claimed:
		_goal_progress += mins
		_check_goal_done()

func record_hw_completed() -> void:
	if _goal_type == 1 and not _goal_claimed:
		_goal_progress += 1.0
		_check_goal_done()

func record_money_earned(amount: int) -> void:
	if _goal_type == 2 and amount > 0 and not _goal_claimed:
		_goal_progress += float(amount)
		_check_goal_done()

func _setup_weekly_goal(week_num: int) -> void:
	_goal_week = week_num
	_goal_claimed = false
	_goal_progress = 0.0
	_goal_type = (week_num - 1) % 3
	if _goal_type == 0:
		_goal_target = 300.0
		_goal_title = "Tuần %d: Học đủ 5 giờ (300p) ở Thư viện" % week_num
	elif _goal_type == 1:
		_goal_target = 2.0
		_goal_title = "Tuần %d: Hoàn thành 2 Bài tập về nhà" % week_num
	else:
		_goal_target = 600.0
		_goal_title = "Tuần %d: Kiếm đủ 600đ từ Quiz / Làm thêm" % week_num

func _check_goal_done() -> void:
	if _goal_claimed:
		return
	if _goal_progress >= _goal_target:
		_goal_claimed = true
		_add_money(250)
		_add_gpa(0.03)
		_add_drl(2, "Hoàn thành mục tiêu tuần")
		_toast("HOÀN THÀNH MỤC TIÊU TUẦN! Thưởng +250đ, +0.03 GPA & +2 ĐRL!")

func _do_job(job_id: int) -> void:
	var m: int = int(game.game_min)
	if job_id == 1:
		if m < 420 or m > 1020:
			_toast("Thư viện chỉ tuyển xếp sách từ 07:00 - 17:00!")
			return
		if energy < 20.0:
			_toast("Không đủ năng lượng (cần 20 NL)! Hãy ăn ở căn tin hoặc ngủ.")
			return
		consume_energy(20.0)
		game.game_min += 90.0
		_add_money(140)
		record_money_earned(140)
		_toast("Xếp sách thư viện xong: +140đ (-20 Năng lượng)")
	elif job_id == 2:
		if m < 600 or m > 1170:
			_toast("Căn tin chỉ nhận ca làm từ 10:00 - 19:30!")
			return
		if energy < 25.0:
			_toast("Không đủ năng lượng (cần 25 NL)!")
			return
		consume_energy(15.0)
		game.game_min += 120.0
		_add_money(170)
		record_money_earned(170)
		_toast("Làm ca căn tin xong: +170đ & suất ăn nhẹ (-15 NL ròng)")
	elif job_id == 3:
		if m < 1080 or m > 1290:
			_toast("Ca dạy kèm gia sư diễn ra buổi tối (18:00 - 21:30)!")
			return
		if energy < 30.0:
			_toast("Không đủ năng lượng dạy kèm (cần 30 NL)!")
			return
		consume_energy(30.0)
		game.game_min += 120.0
		_add_money(260)
		record_money_earned(260)
		_toast("Dạy kèm gia sư xong: +260đ (-30 Năng lượng)")
	elif job_id == 4:
		if _get_money() < 35:
			_toast("Không đủ 35đ mua cơm căn tin!")
			return
		_add_money(-35)
		restore_energy(40.0)
		game.game_min += 30.0
		_toast("Ăn cơm tại Căn tin: -35đ, hồi +40 Năng lượng!")
	elif job_id == 5:
		restore_energy(55.0)
		game.game_min += 120.0
		_toast("Nghỉ ngơi 2 tiếng: hồi +55 Năng lượng!")

func _try_trigger_random_event() -> void:
	if _event_open or game.is_busy():
		return
	var hr: int = int(game.game_min) / 60
	if game.day == _last_event_day or hr == _last_event_hour:
		return
	if hr >= 8 and hr <= 20 and randf() < 0.0025:
		_last_event_day = game.day
		_last_event_hour = hr
		_current_event = RANDOM_EVENTS[randi() % RANDOM_EVENTS.size()]
		_event_open = true
		begin()
		_ui.queue_redraw()

func _resolve_event(opt: int) -> void:
	var eid: String = str(_current_event.get("id", ""))
	if eid == "hangout":
		if opt == 1:
			_add_money(-80)
			restore_energy(35.0)
			_add_drl(1, "Giao lưu cùng bạn bè")
			_toast("Đi chơi vui vẻ: -80đ, +35 Năng lượng, +1 ĐRL")
		else:
			consume_energy(10.0)
			_add_gpa(0.02)
			_toast("Ở nhà ôn bài: +0.02 GPA, -10 Năng lượng")
	elif eid == "wallet":
		if opt == 1:
			_add_drl(3, "Nhặt được của rơi trả người mất")
			_toast("Nộp ví cho CTSV: +3 Điểm rèn luyện!")
		else:
			_add_money(200)
			_add_drl(-1, "Giữ tài sản nhặt được")
			_toast("Giữ lại tiền: +200đ, -1 ĐRL")
	elif eid == "class_cancel":
		if opt == 1:
			_add_gpa(0.03)
			record_study_minutes(60.0, true)
			_toast("Tự học thư viện giờ trống: +0.03 GPA & +60p mục tiêu tuần")
		else:
			restore_energy(40.0)
			_toast("Ngủ bù buổi nghỉ: +40 Năng lượng")
	elif eid == "rain":
		if opt == 1:
			consume_energy(20.0)
			_toast("Chạy dưới mưa: -20 Năng lượng")
		else:
			_add_gpa(0.01)
			game.game_min += 20.0
			_toast("Trú mưa ôn bài: +0.01 GPA")
	_event_open = false
	_current_event = {}
	finish()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return

	if _event_open:
		if k.keycode == KEY_1 or k.keycode == KEY_KP_1:
			_resolve_event(1)
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_2 or k.keycode == KEY_KP_2:
			_resolve_event(2)
			get_viewport().set_input_as_handled()
		return

	if k.physical_keycode == KEY_J and (not game.is_busy() or _menu_open):
		_menu_open = not _menu_open
		if _menu_open:
			begin()
		else:
			finish()
		_ui.queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if _menu_open:
		if k.keycode == KEY_ESCAPE:
			_menu_open = false
			finish()
		elif k.keycode == KEY_1:
			_do_job(1)
		elif k.keycode == KEY_2:
			_do_job(2)
		elif k.keycode == KEY_3:
			_do_job(3)
		elif k.keycode == KEY_4:
			_do_job(4)
		elif k.keycode == KEY_5:
			_do_job(5)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
	var cur_week: int = maxi(1, int((game.day - 1) / 7) + 1)
	if cur_week != _goal_week:
		_setup_weekly_goal(cur_week)

	if not game.is_busy() and Input.is_physical_key_pressed(KEY_SHIFT):
		consume_energy(delta * 1.2)

	_try_trigger_random_event()
	_ui.queue_redraw()

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

func _add_gpa(x: float) -> void:
	if game.stats != null and game.stats.has_method("set_gpa"):
		game.stats.set_gpa(maxf(0.0, float(game.stats.gpa) + x))

func _add_drl(x: int, reason: String) -> void:
	if game.stats != null and game.stats.has_method("add_drl"):
		game.stats.add_drl(x, reason)

func _toast(msg: String) -> void:
	_toast_text = msg
	_toast_t = 3.2

func _paint() -> void:
	var p := _ui
	var e_txt: String = "NL: %d%% | [J] Làm thêm & Mục tiêu" % int(energy)
	var ew: float = p.font.get_string_size(e_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
	p.rc(5.0, 20.0, ew + 2.0, 12.0, Color("2b2b2b"))
	p.rc(6.0, 21.0, ew, 10.0, Color(0.06, 0.1, 0.18, 0.88))
	var ecol: Color = Color("4ade80") if energy >= 40.0 else (Color("facc15") if energy >= 20.0 else Color("f87171"))
	p.ctext(e_txt, 6.0, 29.0, ew, 7, ecol)

	if _toast_t > 0.0:
		var tw: float = p.font.get_string_size(_toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 12.0
		var tx: float = clampf(240.0 - tw / 2.0, 4.0, 476.0 - tw)
		p.rc(tx - 1.0, 52.0, tw + 2.0, 14.0, Color("333333"))
		p.rc(tx, 53.0, tw, 12.0, Color(0.05, 0.12, 0.22, 0.94))
		p.ctext(_toast_text, tx, 62.0, tw, 8, Color("86efac"))

	if _menu_open:
		_paint_daily_menu(p)
	if _event_open:
		_paint_event_modal(p)

func _paint_daily_menu(p: Node2D) -> void:
	var r := Rect2(46, 40, 388, 190)
	p.draw_rect(r, Color(0.04, 0.08, 0.15, 0.96))
	p.draw_rect(r, Color("38bdf8"), false, 1.5)

	p.draw_string(p.font, Vector2(58, 58), "HOẠT ĐỘNG TRONG NGÀY · LÀM THÊM & MỤC TIÊU TUẦN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7dd3fc"))
	var g_status: String = "ĐÃ HOÀN THÀNH!" if _goal_claimed else ("%d / %d" % [int(_goal_progress), int(_goal_target)])
	p.draw_string(p.font, Vector2(58, 74), "Mục tiêu: %s  [%s]" % [_goal_title, g_status], HORIZONTAL_ALIGNMENT_LEFT, 365.0, 8, Color("fde047"))

	p.draw_string(p.font, Vector2(58, 95), "[1] Xếp sách Thư viện (07:00-17:00)  ->  +140đ  (-20 NL)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.draw_string(p.font, Vector2(58, 112), "[2] Phục vụ Căn tin (10:00-19:30)   ->  +170đ  (-15 NL ròng)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.draw_string(p.font, Vector2(58, 129), "[3] Dạy kèm Gia sư (18:00-21:30)    ->  +260đ  (-30 NL)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	p.draw_string(p.font, Vector2(58, 148), "[4] Ăn cơm tại Căn tin              ->  -35đ   (+40 NL)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("86efac"))
	p.draw_string(p.font, Vector2(58, 165), "[5] Nghỉ ngơi / Chợp mắt (2 giờ)    ->  +55 Năng lượng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("86efac"))

	p.draw_string(p.font, Vector2(58, 192), "Năng lượng hiện tại: %d/100   |   Số dư: %dđ" % [int(energy), _get_money()], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fde047"))
	p.draw_string(p.font, Vector2(58, 214), "Bấm phím [1-5] để thực hiện   |   [J] hoặc [Esc] để đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("94a3b8"))

func _paint_event_modal(p: Node2D) -> void:
	var r := Rect2(56, 72, 368, 118)
	p.draw_rect(r, Color(0.05, 0.09, 0.17, 0.97))
	p.draw_rect(r, Color("eab308"), false, 1.5)
	p.draw_string(p.font, Vector2(68, 92), str(_current_event.get("title", "SỰ KIỆN NGẪU NHIÊN")), HORIZONTAL_ALIGNMENT_LEFT, 344.0, 9, Color("fde047"))
	p.draw_string(p.font, Vector2(68, 112), str(_current_event.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, 344.0, 8, Color.WHITE)
	p.draw_string(p.font, Vector2(68, 138), str(_current_event.get("opt1", "")), HORIZONTAL_ALIGNMENT_LEFT, 344.0, 8, Color("7dd3fc"))
	p.draw_string(p.font, Vector2(68, 156), str(_current_event.get("opt2", "")), HORIZONTAL_ALIGNMENT_LEFT, 344.0, 8, Color("86efac"))
