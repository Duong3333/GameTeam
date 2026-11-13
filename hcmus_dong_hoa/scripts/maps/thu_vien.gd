extends "res://scripts/features/feature.gd"
# THƯ VIỆN, nằm trong Tòa C.
#
# Không có tòa nhà riêng và không đổi tên Tòa C: vẫn là cửa Tòa C có sẵn ("E: Vào Tòa C" của building_doors).
# Bấm E ở cửa Tòa C hiện khung chọn: [1] Thư viện hoặc [2] Phòng học Tòa C (phòng học chung có sẵn, mở qua
# building_doors nên lịch học không bị mất chỗ). Module bắt phím E bằng _input() nên luôn chạy trước
# building_doors, không phụ thuộc thứ tự nạp và không sửa file lõi.
#
# TRONG THƯ VIỆN:
#   - Đi bằng W A S D. Giữ Shift để chạy, nhưng thủ thư sẽ nhắc (lần 2 trở đi bị trừ 1 điểm rèn luyện).
#   - E ở ghế trống: ngồi học. Thời gian trôi nhanh gấp 4 lần, cứ 30 phút game cộng 0.01 GPA (tối đa 0.12 mỗi ngày,
#     nhân 1.5 nếu đang mượn sách). Học đủ 2 giờ game được +1 điểm rèn luyện. Ngồi học đúng lúc đang có tiết
#     của mình thì bị -2 điểm rèn luyện ("Bỏ tiết"). Khi ngồi bấm Q để ôn đề giữa kỳ (dùng quiz có sẵn).
#   - E ở quầy: thủ thư cho mượn/trả sách (trả quá 3 ngày bị -1 điểm rèn luyện), cho biết giờ mở cửa,
#     giao việc nhặt 3 cuốn sách rơi trong phòng (thưởng +2 điểm rèn luyện, +0.02 GPA, mỗi ngày một lần).
#   - Giờ mở cửa: Thứ 2 - Thứ 7, 07:00-12:00 và 13:00-17:00. Chủ nhật và giờ nghỉ trưa đóng cửa;
#     đang ở trong mà hết giờ thì thủ thư báo và mời ra ngoài.
#   - Sinh viên NPC đến và về theo giờ (mỗi bạn có khung giờ riêng).
#   - Âm thanh: quạt trần, bước chân khẽ, lật sách, "suỵt" của thủ thư, chuông đóng cửa; nhạc nền ngoài sân nhỏ đi
#     khi vào phòng (file wav nằm ở assets/audio/thu_vien_*.wav, thiếu file thì im lặng, không lỗi).
#
# ĐĂNG KÝ: chỉ cần 1 dòng trong scripts/maps/registry.gd:
#     "res://scripts/maps/thu_vien.gd", # Thư viện (cửa Tòa C)
#
# Cùng cách làm với b42_lab.gd: begin()/finish()/active của feature.gd; phòng vẽ bằng một painter dùng script
# characters.gd nên nhân vật dùng đúng draw_person() của game.

const Schedule := preload("res://scripts/features/schedule_data.gd")

# ---------- Cửa Tòa C ----------
const BUILDING_NAME := "C"
const DOOR_RANGE := 24.0                  # bằng DOOR_DISTANCE của building_doors: lời nhắc "E: Vào Tòa C" hiện là bấm E được

# ---------- Phòng tự học (khung 480x270 như màn hình game) ----------
const VIEW := Vector2(480, 270)
const WALL_H := 56.0
const FLOOR_BOTTOM := 258.0
const DOOR_POS := Vector2(240, 252)       # điểm đứng để ra ngoài (cửa giữa phía dưới)
const START_POS := Vector2(240, 238)      # chỗ xuất hiện khi vừa vào phòng
const WALK_SPEED := 70.0                  # giống người chơi ngoài trời
const RUN_MULT := 1.6                     # giữ Shift: nhanh gấp 1.6 lần
const TABLE_W := 76.0
const TABLE_H := 14.0
const TABLE_XS := [76.0, 168.0, 312.0, 404.0]   # tâm 4 bàn trong mỗi hàng (chừa lối đi giữa x 206-274)
const TABLE_TOPS := [112.0, 170.0]              # mép trên của 2 hàng bàn
const SEAT_DX := 18.0                            # ghế lệch trái/phải so với tâm bàn
const SHELVES := Rect2(12, 38, 190, 24)         # dãy tủ sách sát tường trái
const COUNTER := Rect2(214, 64, 112, 16)        # quầy thủ thư
const LOCKERS := Rect2(446, 60, 26, 92)         # tủ gửi đồ sát tường phải
const TROLLEY := Rect2(418, 208, 28, 26)        # xe đẩy sách
const LIBRARIAN_FEET := Vector2(270, 72)
const DESK_POINT := Vector2(270, 86)            # đứng ở đây (trước quầy) để nói chuyện với thủ thư

# ---------- Giờ mở cửa (phút trong ngày; ngày game chạy từ 07:00 đến 17:00) ----------
const OPEN_HOURS := [[420, 720], [780, 1020]]   # 07:00-12:00 và 13:00-17:00
const CLOSED_WEEKDAY := 6                       # Chủ nhật (Schedule.weekday: 0 = Thứ 2)

# ---------- Học ở thư viện ----------
const STUDY_TIME_MULT := 4.0        # thời gian trôi nhanh gấp 4 lần khi đang ngồi học
const STUDY_STEP_MIN := 30.0        # cứ 30 phút game học được cộng GPA 1 lần
const STUDY_GPA_STEP := 0.01
const STUDY_GPA_DAILY_CAP := 0.12   # tối đa GPA học thêm được mỗi ngày game
const STUDY_DRL_MIN := 120.0        # học đủ 120 phút game trong ngày thì +1 điểm rèn luyện
const STUDY_DRL_DAILY_CAP := 1
const BORROW_BONUS := 1.5           # đang mượn sách: GPA cộng nhanh gấp 1.5 lần
const BORROW_DAYS := 3              # mượn quá 3 ngày game mới trả thì bị trừ điểm
const SKIP_CLASS_MIN := 15.0        # ngồi học 15 phút game trong giờ có tiết của mình thì tính là bỏ tiết
const QUEST_BOOKS := 3
const BOOK_SPOTS := [Vector2(122, 148), Vector2(240, 112), Vector2(358, 148)]   # chỗ rơi sách (đều nằm trên lối đi)
const BOOK_TITLES := ["Giải tích 1", "Nhập môn lập trình C++", "Toán rời rạc cơ bản", "Cơ sở dữ liệu cho người mới"]

# Sinh viên ngồi học. t: hàng*4 + cột bàn, side: 0 = ngồi phía trên bàn (quay xuống), 1 = ngồi phía dưới bàn (quay lên),
# slot: 0 trái / 1 phải, what: book | laptop | write | tablet, from/to: khung giờ có mặt (phút trong ngày)
const STUDENTS := [
	{"t": 0, "side": 0, "slot": 0, "what": "laptop", "shirt": "1b2f6e", "hair": "1b1b1b", "uni": true, "long": false, "pack": false, "from": 420, "to": 1020},
	{"t": 0, "side": 1, "slot": 1, "what": "write", "shirt": "9aa0a8", "hair": "1b1b1b", "uni": false, "long": true, "pack": true, "from": 440, "to": 700},
	{"t": 1, "side": 0, "slot": 1, "what": "book", "shirt": "1b2f6e", "hair": "3b2a1a", "uni": true, "long": false, "pack": false, "from": 500, "to": 1020},
	{"t": 2, "side": 1, "slot": 0, "what": "book", "shirt": "e8dcc0", "hair": "1b1b1b", "uni": false, "long": false, "pack": true, "from": 420, "to": 640},
	{"t": 3, "side": 0, "slot": 0, "what": "laptop", "shirt": "2a2a2e", "hair": "1b1b1b", "uni": false, "long": false, "pack": false, "from": 560, "to": 1020},
	{"t": 4, "side": 1, "slot": 0, "what": "laptop", "shirt": "1b2f6e", "hair": "5a3a22", "uni": true, "long": false, "pack": true, "from": 780, "to": 1000},
	{"t": 5, "side": 0, "slot": 0, "what": "write", "shirt": "e8a0a8", "hair": "1b1b1b", "uni": false, "long": true, "pack": false, "from": 420, "to": 900},
	{"t": 6, "side": 0, "slot": 1, "what": "book", "shirt": "1b2f6e", "hair": "1b1b1b", "uni": true, "long": false, "pack": false, "from": 600, "to": 1020},
	{"t": 7, "side": 1, "slot": 1, "what": "tablet", "shirt": "a89c92", "hair": "3b2a1a", "uni": false, "long": true, "pack": true, "from": 780, "to": 960},
]

const C_WALL := Color("dfe5e4")
const C_FLOOR_A := Color("b7c4bb")
const C_FLOOR_B := Color("aebcb2")
const C_GROUT := Color("98a79e")
const C_FRAME_BLUE := Color("7f93b0")
const C_CHAIR := Color("2f55b8")
const C_CHAIR_HI := Color("5578d8")
const C_CHAIR_DK := Color("1f3a85")
const C_TABLE_TOP := Color("eef1f3")
const C_TABLE_FRONT := Color("b8c0c8")
const C_METAL := Color("8f98a2")

var inside := false           # đang ở trong phòng thư viện
var _choice := false          # đang hiện khung chọn Thư viện / Phòng học ở cửa Tòa C
var _choice_msg := ""
var _layer: CanvasLayer
var _painter: Node2D
var _pos := START_POS
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải (giống game.facing)
var _anim := 0.0
var _clock := 0.0
var _fade := 0.0
var _closing := false
var _enter_day := 0
var _close_warned := false
var _seats: Array = []        # mọi ghế: {pos, x, top, side, t, slot, who (chỉ số sinh viên hoặc -1)}
var _solid: Array = []        # vật cản trong phòng
var _looked := false
var _quiz: Node = null        # math_quiz (tìm theo hàm start_round)
var _doors_f: Node = null     # building_doors (tìm theo hàm enter_room)

# học
var _sit := -1                # chỉ số ghế đang ngồi, -1 = không ngồi
var _sit_acc := 0.0
var _page_t := 5.0
var _gpa_today: Dictionary = {}
var _study_today: Dictionary = {}
var _drl_today: Dictionary = {}
var _cap_told_day := -1
var _class_acc: Dictionary = {}
var _class_penalized: Dictionary = {}

# thủ thư
var _dlg_mode := ""           # "" | "menu" | "text"
var _dlg_text := ""
var _borrowed := ""
var _borrow_day := 0
var _borrow_count := 0
var _quest := 0               # 0 chưa nhận, 1 đang làm, 2 đã đủ sách chờ báo cáo
var _quest_got := 0
var _quest_done_day := -1
var _books: Array = []        # sách rơi: {pos, got}
var _say_text := ""
var _say_t := 0.0

# yên tĩnh
var _running := false
var _run_t := 0.0
var _warn_cd := 0.0
var _warns := 0
var _step_t := 0.0

var _toast_text := ""
var _toast_t := 0.0

# âm thanh
var _amb: AudioStreamPlayer
var _sfx_step: AudioStreamPlayer
var _sfx_misc: AudioStreamPlayer
var _music_db := 0.0
var _ducked := false

func _ready() -> void:
	_build_room()
	_layer = CanvasLayer.new()
	_layer.layer = 5   # trên thế giới, dưới các thanh HUD và sổ tay (6-8), giống b42_lab.gd
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -14.0
	add_child(_amb)
	_sfx_step = AudioStreamPlayer.new()
	_sfx_step.volume_db = -10.0
	add_child(_sfx_step)
	_sfx_misc = AudioStreamPlayer.new()
	_sfx_misc.volume_db = -6.0
	add_child(_sfx_misc)
	print("[Thư viện] đã nạp, cửa Tòa C tại ", _door_outside())

# ======================= DỰNG PHÒNG =======================

func _build_room() -> void:
	_seats.clear()
	_solid.clear()
	_solid.append(SHELVES)
	_solid.append(COUNTER)
	_solid.append(LOCKERS)
	_solid.append(TROLLEY)
	for i in TABLE_XS.size() * TABLE_TOPS.size():
		var cx: float = TABLE_XS[i % TABLE_XS.size()]
		var top: float = TABLE_TOPS[i / TABLE_XS.size()]
		_solid.append(Rect2(cx - TABLE_W / 2.0, top, TABLE_W, TABLE_H))
		for side in 2:
			for slot in 2:
				var sx: float = cx + (-SEAT_DX if slot == 0 else SEAT_DX)
				var sp: Vector2 = Vector2(sx, top + 6.0) if side == 0 else Vector2(sx, top + 26.0)
				var seat: Dictionary = {"pos": sp, "x": sx, "top": top, "side": side, "t": i, "slot": slot, "who": -1}
				for s in STUDENTS.size():
					var st: Dictionary = STUDENTS[s]
					if st.t == i and st.side == side and st.slot == slot:
						seat.who = s
				_seats.append(seat)
				# ghế (và người ngồi) là vật cản
				if side == 0:
					_solid.append(Rect2(sx - 7.0, top - 14.0, 14.0, 14.0))
				else:
					_solid.append(Rect2(sx - 7.0, top + 18.0, 14.0, 10.0))

# ======================= TÌM CÁC FEATURE CÓ SẴN =======================

func _lookup() -> void:
	if _looked:
		return
	_looked = true
	for f in game.features:
		if f == self:
			continue
		if _quiz == null and f.has_method("start_round") and f.has_method("begin"):
			_quiz = f
		if _doors_f == null and f.has_method("enter_room") and f.get("doors") is Array:
			_doors_f = f

func _quiz_open() -> bool:
	return _quiz != null and bool(_quiz.active)

# mục "Tòa C" trong danh sách cửa của building_doors (để mở phòng học chung)
func _c_door() -> Dictionary:
	if _doors_f == null:
		return {}
	for d in _doors_f.doors:
		if d is Dictionary and str(d.get("title", "")) == "Tòa " + BUILDING_NAME:
			return d
	return {}

# ======================= GIỜ MỞ CỬA =======================

func _is_open() -> bool:
	if Schedule.weekday(game.day) == CLOSED_WEEKDAY:
		return false
	var m := int(game.game_min)
	for r in OPEN_HOURS:
		if m >= int(r[0]) and m < int(r[1]):
			return true
	return false

func _next_open_text() -> String:
	if Schedule.weekday(game.day) == CLOSED_WEEKDAY:
		return "Chủ nhật nghỉ, Thứ 2 mở lúc %s." % Schedule.clock_text(int(OPEN_HOURS[0][0]))
	var m := int(game.game_min)
	for r in OPEN_HOURS:
		if m < int(r[0]):
			return "Mở cửa lúc %s." % Schedule.clock_text(int(r[0]))
	return "Mai mở lại lúc %s." % Schedule.clock_text(int(OPEN_HOURS[0][0]))

func _hours_text() -> String:
	return "Thư viện mở Thứ 2 - Thứ 7: %s-%s và %s-%s. Chủ nhật nghỉ. Nhớ giữ yên lặng, không chạy nhé!" % [
		Schedule.clock_text(int(OPEN_HOURS[0][0])), Schedule.clock_text(int(OPEN_HOURS[0][1])),
		Schedule.clock_text(int(OPEN_HOURS[1][0])), Schedule.clock_text(int(OPEN_HOURS[1][1]))]

func _check_hours() -> void:
	if not _is_open() or game.day != _enter_day:
		_start_close("Thư viện đã đóng cửa. " + _next_open_text())
		return
	if _close_warned:
		return
	var m := int(game.game_min)
	for r in OPEN_HOURS:
		if m >= int(r[1]) - 5 and m < int(r[1]):
			_close_warned = true
			_librarian_say("Sắp đến giờ đóng cửa rồi, em thu dọn nhé!")
			_play_misc("thu_vien_chuong")

func _start_close(msg: String) -> void:
	if _closing:
		return
	_closing = true
	_dlg_mode = ""
	if _sit >= 0:
		_stand_up()
	_toast(msg)
	_play_misc("thu_vien_chuong")

# ======================= VÀO / RA =======================

# Cửa Tòa C, cùng công thức với get_doorways(): giữa mặt dưới tòa nhà, lệch xuống 7 px
func _door_outside() -> Vector2:
	for b in game.BUILDINGS:
		if str(b[0]) == BUILDING_NAME:
			return Vector2(b[1] + b[3] * 0.5, b[2] + b[4] + 7.0)
	return Vector2(-9999.0, -9999.0)

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_outside()) < DOOR_RANGE

func begin() -> void:
	super()

func finish() -> void:
	super()
	inside = false
	_choice = false
	_closing = false
	_sit = -1
	_dlg_mode = ""
	_layer.visible = false
	game.hud.visible = true
	_audio_stop()

func _open_choice() -> void:
	_lookup()
	_choice_msg = ""
	_choice = true
	begin()
	_layer.visible = true
	_painter.queue_redraw()

func _enter_room() -> void:
	_choice = false
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_sit = -1
	_dlg_mode = ""
	_enter_day = game.day
	_close_warned = false
	_warns = 0
	_run_t = 0.0
	_warn_cd = 0.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong phòng
	_audio_start()
	_painter.queue_redraw()

# ======================= PHÍM =======================

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if _quiz_open():
		return   # đang làm quiz: để quiz tự xử lý phím
	if _choice:
		_choice_key(k)
	elif inside:
		_room_key(k)
	elif k.physical_keycode == KEY_E and not game.is_busy() and _near_door_outside():
		_open_choice()
		get_viewport().set_input_as_handled()

func _choice_key(k: InputEventKey) -> void:
	var kc := k.keycode
	if kc == KEY_1 or kc == KEY_KP_1:
		if _is_open():
			_enter_room()
		else:
			_choice_msg = "Thư viện đóng cửa. " + _next_open_text()
			_painter.queue_redraw()
	elif kc == KEY_2 or kc == KEY_KP_2:
		var d: Dictionary = _c_door()
		finish()
		if not d.is_empty() and _doors_f != null:
			_doors_f.enter_room(d)
	elif kc == KEY_ESCAPE or kc == KEY_E or kc == KEY_BACKSPACE:
		finish()
	else:
		return
	get_viewport().set_input_as_handled()

func _room_key(k: InputEventKey) -> void:
	if _closing:
		return
	var pk := k.physical_keycode
	if _dlg_mode != "":
		_dlg_key(k)
		return
	if _sit >= 0:
		if pk == KEY_E or k.keycode == KEY_ESCAPE or pk == KEY_W or pk == KEY_A or pk == KEY_S or pk == KEY_D:
			_stand_up()
			get_viewport().set_input_as_handled()
		elif pk == KEY_Q:
			_open_quiz()
			get_viewport().set_input_as_handled()
		return
	if pk != KEY_E:
		return
	var it: Dictionary = _interaction()
	var kind: String = str(it.get("kind", ""))
	if kind == "door":
		_closing = true   # mờ dần rồi ra ngoài (xem _process)
	elif kind == "book":
		_pick_book(int(it.idx))
	elif kind == "desk":
		_open_desk()
	elif kind == "seat":
		_sit_down(int(it.idx))
	get_viewport().set_input_as_handled()

# ======================= TƯƠNG TÁC =======================

# Việc E sẽ làm ở chỗ người chơi đang đứng (ưu tiên: cửa, sách, quầy, ghế)
func _interaction() -> Dictionary:
	if _pos.distance_to(DOOR_POS) < 24.0:
		return {"kind": "door", "text": "[E] Ra ngoài"}
	for i in _books.size():
		var b: Dictionary = _books[i]
		if not b.got and _pos.distance_to(b.pos) < 16.0:
			return {"kind": "book", "idx": i, "text": "[E] Nhặt sách"}
	if _pos.distance_to(DESK_POINT) < 30.0:
		return {"kind": "desk", "text": "[E] Nói chuyện với thủ thư"}
	var si := _nearest_seat()
	if si >= 0:
		return {"kind": "seat", "idx": si, "text": "[E] Ngồi học"}
	return {}

func _present(who: int) -> bool:
	var st: Dictionary = STUDENTS[who]
	var m: float = game.game_min
	return m >= float(st["from"]) and m < float(st["to"])

func _seat_free(si: int) -> bool:
	var s: Dictionary = _seats[si]
	if si == _sit:
		return false
	return s.who < 0 or not _present(s.who)

# chỗ đứng để vào ghế (sát mép ghế, ngoài vật cản)
func _seat_access(s: Dictionary) -> Vector2:
	if s.side == 0:
		return Vector2(s.x, s.top - 18.0)
	return Vector2(s.x, s.top + 34.0)

func _nearest_seat() -> int:
	var best := -1
	var best_d := 16.0
	for si in _seats.size():
		if not _seat_free(si):
			continue
		var d: float = _pos.distance_to(_seat_access(_seats[si]))
		if d < best_d:
			best_d = d
			best = si
	return best

func _sit_down(si: int) -> void:
	var s: Dictionary = _seats[si]
	_sit = si
	_pos = s.pos
	_face = 0 if s.side == 0 else 1
	_sit_acc = 0.0
	_page_t = 3.0
	_play_misc("thu_vien_lat_sach")
	_toast("Bắt đầu học. Thời gian trôi nhanh gấp %d lần." % int(STUDY_TIME_MULT))

func _stand_up() -> void:
	if _sit < 0:
		return
	var s: Dictionary = _seats[_sit]
	_pos = _seat_access(s)
	_face = 1 if s.side == 1 else 0
	_sit = -1

func _open_quiz() -> void:
	if _quiz == null:
		_toast("Chưa có bộ đề để ôn.")
		return
	var code := "VTP1" if randi() % 2 == 0 else "CSLT"
	_quiz.begin()
	_quiz.start_round(code, "ÔN TẬP · THƯ VIỆN")

# ======================= HỌC: THỜI GIAN, GPA, ĐIỂM RÈN LUYỆN =======================

func _add_gpa(x: float) -> void:
	if game.stats != null and game.stats.has_method("set_gpa"):
		game.stats.set_gpa(float(game.stats.gpa) + x)

func _add_drl(x: int, reason: String) -> void:
	if game.stats != null and game.stats.has_method("add_drl"):
		game.stats.add_drl(x, reason)

func _update_study(delta: float) -> void:
	if _sit < 0:
		return
	# chạy thêm phần thời gian để tổng cộng nhanh gấp STUDY_TIME_MULT lần
	game.game_min += delta * game.TIME_SCALE * (STUDY_TIME_MULT - 1.0)
	var played: float = delta * game.TIME_SCALE * STUDY_TIME_MULT
	_sit_acc += played
	_page_t -= delta
	if _page_t <= 0.0:
		_page_t = randf_range(6.0, 12.0)
		_play_misc("thu_vien_lat_sach")
	while _sit_acc >= STUDY_STEP_MIN:
		_sit_acc -= STUDY_STEP_MIN
		_study_step()
	var key := _class_in_session()
	if key != "" and not _class_penalized.has(key):
		_class_acc[key] = float(_class_acc.get(key, 0.0)) + played
		if float(_class_acc[key]) >= SKIP_CLASS_MIN:
			_class_penalized[key] = true
			_add_drl(-2, "Bỏ tiết")
			_toast("Bạn đang bỏ tiết để ngồi ở thư viện!")

# Tiết học đang diễn ra lúc này theo thời khóa biểu ("" nếu không có)
func _class_in_session() -> String:
	var now := int(game.game_min)
	for c in Schedule.courses_on(Schedule.weekday(game.day) + 2):
		var t: Array = Schedule.time_range(c[1], c[3])
		if now >= int(t[0]) and now < int(t[1]):
			return "%d:%s:%s" % [game.day, str(c[0]), str(c[3])]
	return ""

func _study_step() -> void:
	var d: int = game.day
	var got: float = float(_gpa_today.get(d, 0.0))
	var mins: float = float(_study_today.get(d, 0.0)) + STUDY_STEP_MIN
	_study_today[d] = mins
	if mins >= STUDY_DRL_MIN and int(_drl_today.get(d, 0)) < STUDY_DRL_DAILY_CAP:
		_drl_today[d] = int(_drl_today.get(d, 0)) + 1
		_add_drl(1, "Tự học ở thư viện")
	if got >= STUDY_GPA_DAILY_CAP - 0.0001:
		if _cap_told_day != d:
			_cap_told_day = d
			_toast("Hôm nay học đủ rồi, nghỉ ngơi chút nhé!")
		return
	var amount: float = STUDY_GPA_STEP * (BORROW_BONUS if _borrowed != "" else 1.0)
	amount = minf(amount, STUDY_GPA_DAILY_CAP - got)
	_add_gpa(amount)
	_gpa_today[d] = got + amount
	_toast("+%.3f GPA" % amount)

# ======================= THỦ THƯ =======================

func _librarian_say(text: String) -> void:
	_say_text = text
	_say_t = 3.0

func _open_desk() -> void:
	_dlg_mode = "menu"
	_dlg_text = ""
	_librarian_say("Chào em, em cần gì nào?")

func _menu_lines() -> Array:
	var lines: Array = []
	lines.append("[1] Trả sách: \"%s\"" % _borrowed if _borrowed != "" else "[1] Mượn sách")
	lines.append("[2] Hỏi giờ mở cửa")
	if _quest == 0:
		lines.append("[3] Nhận việc: nhặt sách rơi")
	elif _quest == 1:
		lines.append("[3] Việc nhặt sách (%d/%d)" % [_quest_got, QUEST_BOOKS])
	else:
		lines.append("[3] Báo cáo đã nhặt đủ sách")
	lines.append("[4] Thôi, cảm ơn cô")
	return lines

func _dlg_key(k: InputEventKey) -> void:
	var kc := k.keycode
	if kc == KEY_ESCAPE:
		_dlg_mode = ""
	elif _dlg_mode == "menu":
		if kc == KEY_1 or kc == KEY_KP_1:
			_dlg_choose(1)
		elif kc == KEY_2 or kc == KEY_KP_2:
			_dlg_choose(2)
		elif kc == KEY_3 or kc == KEY_KP_3:
			_dlg_choose(3)
		elif kc == KEY_4 or kc == KEY_KP_4:
			_dlg_choose(4)
		else:
			return
	else:
		if kc == KEY_E or kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
			_dlg_mode = "menu"
		else:
			return
	get_viewport().set_input_as_handled()

func _dlg_choose(n: int) -> void:
	if n == 4:
		_dlg_mode = ""
		return
	_dlg_mode = "text"
	if n == 1:
		if _borrowed == "":
			_borrowed = BOOK_TITLES[_borrow_count % BOOK_TITLES.size()]
			_borrow_count += 1
			_borrow_day = game.day
			_dlg_text = "Cô cho em mượn \"%s\". Nhớ trả trong %d ngày nhé. Có sách trong tay, em học hiệu quả hơn đó!" % [_borrowed, BORROW_DAYS]
		else:
			if game.day - _borrow_day <= BORROW_DAYS:
				_add_drl(1, "Trả sách đúng hạn")
				_dlg_text = "Cảm ơn em đã trả sách đúng hạn!"
			else:
				_add_drl(-1, "Trả sách trễ hạn")
				_dlg_text = "Em trả trễ hạn rồi đó. Lần sau nhớ trả đúng hẹn nhé."
			_borrowed = ""
	elif n == 2:
		_dlg_text = _hours_text()
	elif n == 3:
		_quest_talk()

func _quest_talk() -> void:
	if _quest == 0:
		if _quest_done_day == game.day:
			_dlg_text = "Hôm nay em giúp cô xong rồi, cảm ơn em nhé. Mai cô lại nhờ."
			return
		_quest = 1
		_quest_got = 0
		_spawn_books()
		_dlg_text = "Có %d cuốn sách bị bỏ quên trên lối đi. Em nhặt giúp cô rồi quay lại báo nhé." % QUEST_BOOKS
	elif _quest == 1:
		_dlg_text = "Em mới nhặt được %d/%d cuốn thôi. Sách nằm trên lối đi giữa các bàn." % [_quest_got, QUEST_BOOKS]
	else:
		_quest = 0
		_quest_done_day = game.day
		_books.clear()
		_add_drl(2, "Giúp thủ thư")
		_add_gpa(0.02)
		_dlg_text = "Cảm ơn em! Thưởng cho em ít điểm rèn luyện và một chút GPA."

func _spawn_books() -> void:
	_books.clear()
	for i in QUEST_BOOKS:
		_books.append({"pos": BOOK_SPOTS[i], "got": false})

func _pick_book(i: int) -> void:
	var b: Dictionary = _books[i]
	b.got = true
	_quest_got += 1
	_play_misc("thu_vien_lat_sach")
	if _quest_got >= QUEST_BOOKS:
		_quest = 2
		_toast("Đủ %d cuốn rồi, mang lại cho thủ thư." % QUEST_BOOKS)
	else:
		_toast("Nhặt được sách (%d/%d)." % [_quest_got, QUEST_BOOKS])

# ======================= TOAST, ÂM THANH =======================

func _toast(text: String) -> void:
	_toast_text = text
	_toast_t = 3.0

func _load_wav(sound_name: String, loop: bool = false) -> AudioStream:
	var path := "res://assets/audio/%s.wav" % sound_name
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path) as AudioStream
	if s != null and loop and s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * float(w.mix_rate))
	return s

func _play_misc(sound_name: String) -> void:
	var s := _load_wav(sound_name)
	if s == null:
		return
	_sfx_misc.stream = s
	_sfx_misc.play()

func _audio_start() -> void:
	var a := _load_wav("thu_vien_quat", true)
	if a != null:
		_amb.stream = a
		_amb.play()
	var m = game.audio.get("_music") if game.audio != null else null
	if m is AudioStreamPlayer and not _ducked:
		_music_db = (m as AudioStreamPlayer).volume_db
		(m as AudioStreamPlayer).volume_db = _music_db - 12.0   # nhạc nền ngoài sân nhỏ đi
		_ducked = true

func _audio_stop() -> void:
	if _amb != null:
		_amb.stop()
	if _ducked:
		var m = game.audio.get("_music") if game.audio != null else null
		if m is AudioStreamPlayer:
			(m as AudioStreamPlayer).volume_db = _music_db
		_ducked = false

# ======================= TRONG PHÒNG: CẬP NHẬT MỖI KHUNG HÌNH =======================

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
	if _say_t > 0.0:
		_say_t -= delta
	if _choice:
		_painter.queue_redraw()
		return
	if not inside:
		return
	_clock += delta
	if _closing:
		_fade = minf(_fade + delta * 3.0, 1.0)
		if _fade >= 1.0:
			finish()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		if not _quiz_open():
			_check_hours()
			if _dlg_mode == "" and _sit < 0:
				_walk(delta)
			_update_study(delta)
			_update_run_warning(delta)
	_painter.queue_redraw()

func _walk(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	_running = false
	if v == Vector2.ZERO:
		return
	_running = Input.is_physical_key_pressed(KEY_SHIFT)
	var spd: float = WALK_SPEED * (RUN_MULT if _running else 1.0)
	v = v.normalized() * spd * delta
	if absf(v.x) > absf(v.y):
		_face = 2 if v.x < 0.0 else 3
	else:
		_face = 1 if v.y < 0.0 else 0
	_anim += delta * (RUN_MULT if _running else 1.0)
	var a := _pos + Vector2(v.x, 0.0)
	if _blocked(a):
		a = _pos
	var b := a + Vector2(0.0, v.y)
	if _blocked(b):
		b = a
	_pos = b
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.27 if _running else 0.42
		var s := _load_wav("thu_vien_buoc_chan")
		if s != null:
			_sfx_step.stream = s
			_sfx_step.play()

# Chạy trong thư viện: thủ thư nhắc; từ lần nhắc thứ 2 bị trừ điểm rèn luyện
func _update_run_warning(delta: float) -> void:
	_warn_cd -= delta
	if _running:
		_run_t += delta
	else:
		_run_t = 0.0
	if _run_t > 0.5 and _warn_cd <= 0.0:
		_run_t = 0.0
		_warn_cd = 8.0
		_warns += 1
		_librarian_say("Suỵt! Trong thư viện không được chạy!")
		_play_misc("thu_vien_suyt")
		if _warns >= 2:
			_add_drl(-1, "Chạy trong thư viện")

# cùng cách tính với game.blocked(): chân nhân vật là hộp 8x4
func _blocked(p: Vector2) -> bool:
	if p.x < 14.0 or p.x > VIEW.x - 14.0 or p.y < 64.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

# ======================= VẼ =======================

func _paint() -> void:
	var p := _painter
	if _choice:
		_paint_choice(p)
		return
	p.rc(0, 0, VIEW.x, VIEW.y, Color("23262e"))
	_paint_shell(p)
	_paint_books(p)
	var items: Array = []   # [khóa sắp xếp theo y, loại, dữ liệu]
	items.append([LIBRARIAN_FEET.y - 1.0, 0, null])
	items.append([COUNTER.end.y, 1, null])
	items.append([TROLLEY.end.y, 2, null])
	for i in TABLE_XS.size() * TABLE_TOPS.size():
		var top: float = TABLE_TOPS[i / TABLE_XS.size()]
		items.append([top - 1.0, 3, i])    # ghế + người ngồi phía trên bàn (vẽ trước bàn)
		items.append([top, 4, i])          # mặt bàn và đồ trên bàn
		items.append([top + 26.0, 5, i])   # ghế + người ngồi phía dưới bàn (vẽ sau bàn)
	if _sit < 0:
		items.append([_pos.y, 6, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				_paint_librarian(p)
			1:
				_paint_counter(p)
			2:
				_paint_trolley(p)
			3:
				_paint_seats(p, it[2], 0)
			4:
				_paint_table(p, it[2])
			5:
				_paint_seats(p, it[2], 1)
			6:
				_paint_player(p)
	_paint_overlay(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# Tường, cửa sổ, tủ sách, tủ gửi đồ, sàn gạch, cửa ra
func _paint_shell(p: Node2D) -> void:
	p.rc(0, 0, VIEW.x, WALL_H, C_WALL)
	p.rc(0, 0, VIEW.x, 3, C_WALL.lightened(0.2))
	p.rc(0, WALL_H - 4.0, VIEW.x, 4, C_WALL.darkened(0.15))
	for ty in range(int(WALL_H), int(FLOOR_BOTTOM), 16):
		for tx in range(0, int(VIEW.x), 16):
			p.rc(tx, ty, 16, 16, C_FLOOR_A if ((tx + ty) / 16) % 2 == 0 else C_FLOOR_B)
			p.rc(tx, ty, 16, 1, C_GROUT)
			p.rc(tx, ty, 1, 16, C_GROUT)
	p.rc(0, FLOOR_BOTTOM, VIEW.x, VIEW.y - FLOOR_BOTTOM, Color("5a5f6b"))
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 2, Color("3f434d"))
	p.rc(0, 0, 8, VIEW.y, Color("4a4f5b"))
	p.rc(VIEW.x - 8.0, 0, 8, VIEW.y, Color("4a4f5b"))
	_paint_flags(p)
	# biển tên phòng trên tường trái, phía trên dãy tủ sách
	p.rc(14, 4, 150, 13, Color("2f5ea8"))
	p.rc(15, 5, 148, 11, Color("f4f6f8"))
	p.ctext("THƯ VIỆN", 15, 14, 148, 8, Color("1f4aa8"))
	_paint_wall_items(p)
	_paint_windows(p)
	_paint_shelves(p)
	_paint_lockers(p)
	# cửa ra (giữa phía dưới): hai cánh kính khung xanh
	p.rc(222, FLOOR_BOTTOM, 36, 12, Color("2b2b2b"))
	p.rc(224, FLOOR_BOTTOM + 1.0, 15, 11, Color("9fd3f0"))
	p.rc(241, FLOOR_BOTTOM + 1.0, 15, 11, Color("9fd3f0"))
	p.rc(224, FLOOR_BOTTOM + 1.0, 15, 2, Color("cdeaf8"))
	p.rc(241, FLOOR_BOTTOM + 1.0, 15, 2, Color("cdeaf8"))
	p.rc(239, FLOOR_BOTTOM + 1.0, 2, 11, C_FRAME_BLUE)

# Dây cờ đỏ sao vàng treo dọc đỉnh tường (như ảnh), tam giác nhỏ xen kẽ
func _paint_flags(p: Node2D) -> void:
	for i in 7:
		var fx := 330.0 + i * 16.0
		p.rc(fx, 3, 12, 6, Color("c8222a"))
		p.rc(fx + 2, 9, 8, 2, Color("c8222a"))
		p.rc(fx + 4, 11, 4, 1, Color("c8222a"))
		p.rc(fx + 5, 4, 2, 2, Color("ffd23f"))

# Bảng nội quy xanh, đồng hồ, máy lạnh trên tường phía sau quầy
func _paint_wall_items(p: Node2D) -> void:
	p.rc(216, 14, 22, 30, Color("1f4a8c"))
	p.rc(217, 15, 20, 28, Color("2f5ea8"))
	p.ctext("NỘI QUY", 216, 23, 22, 6, Color.WHITE)
	for i in 4:
		p.rc(220, 27 + i * 4, 14, 1, Color("bcd2f0"))
	p.rc(246, 14, 14, 14, Color("7d848d"))
	p.rc(247, 15, 12, 12, Color("f4f6f8"))
	p.rc(252, 17, 1, 5, Color("2b2b2b"))
	p.rc(252, 21, 4, 1, Color("2b2b2b"))
	p.rc(268, 10, 52, 16, Color("b8bec6"))
	p.rc(269, 11, 50, 14, Color("eef1f4"))
	p.rc(270, 19, 48, 3, Color("c9ced4"))
	p.rc(310, 13, 4, 2, Color("46d07a"))

# Hai cửa sổ khung xanh có lá sách (như ảnh) ở tường phải phía sau
func _paint_windows(p: Node2D) -> void:
	for wx in [330.0, 384.0]:
		p.rc(wx, 12, 48, 36, C_FRAME_BLUE.darkened(0.25))
		p.rc(wx + 2, 14, 44, 32, C_FRAME_BLUE)
		p.rc(wx + 2, 14, 44, 5, Color("e4c34a"))   # dải vàng phía trên cửa sổ
		for i in 3:
			var lx: float = wx + 4.0 + i * 14.0
			p.rc(lx, 21, 12, 23, Color("cdd5dc"))
			for j in 6:
				p.rc(lx, 22 + j * 4, 12, 1, Color("8d99a6"))
		p.rc(wx, 46, 48, 3, C_FRAME_BLUE.darkened(0.15))

# Tủ sách kim loại xám (như ảnh 4): 4 khoang, gáy sách nhiều màu
func _paint_shelves(p: Node2D) -> void:
	var cols := [Color("c0392b"), Color("2f6bd0"), Color("e8c34a"), Color("3a8f4a"), Color("f2f2f2"), Color("8e5bd0"), Color("e08a2e")]
	for k in 4:
		var bx := 14.0 + k * 47.0
		p.rc(bx, 20, 45, 42, Color("3f4651"))
		p.rc(bx + 1, 21, 43, 40, Color("59616d"))
		for lvl in 3:
			var ly := 22.0 + lvl * 13.0
			p.rc(bx + 2, ly + 11.0, 41, 2, Color("2a2f37"))
			var x := bx + 3.0
			var n := 0
			while x < bx + 41.0:
				var w := 2.0 + float((n * 5 + k * 3 + lvl) % 3)
				var h := 8.0 + float((n * 3 + lvl) % 3)
				p.rc(x, ly + 11.0 - h, w, h, cols[(n * 3 + k + lvl * 2) % cols.size()])
				x += w + 1.0
				n += 1
		p.rc(bx, 20, 45, 2, Color("6f7886"))

# Tủ gửi đồ xám nhiều ngăn sát tường phải
func _paint_lockers(p: Node2D) -> void:
	var r := LOCKERS
	p.rc(r.position.x - 1, r.position.y - 1, r.size.x + 2, r.size.y + 2, Color("3f4651"))
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y, Color("aab1ba"))
	for col in 2:
		for row in 6:
			var lx := r.position.x + 1.0 + col * 12.0
			var ly := r.position.y + 1.0 + row * 15.0
			p.rc(lx, ly, 11, 14, Color("c6ccd3"))
			p.rc(lx, ly, 11, 1, Color("e2e6ea"))
			p.rc(lx, ly + 13.0, 11, 1, Color("7f8893"))
			p.rc(lx + 8.0, ly + 6.0, 2, 3, Color("4a525c"))

# ---------- đồ nội thất ----------

func _paint_table(p: Node2D, i: int) -> void:
	var cx: float = TABLE_XS[i % TABLE_XS.size()]
	var top: float = TABLE_TOPS[i / TABLE_XS.size()]
	var x0 := cx - TABLE_W / 2.0
	p.rc(x0 - 1, top - 1, TABLE_W + 2, TABLE_H + 2, C_METAL.darkened(0.35))
	p.rc(x0, top, TABLE_W, 8, C_TABLE_TOP)
	p.rc(x0, top, TABLE_W, 1, Color.WHITE)
	p.rc(x0, top + 8.0, TABLE_W, 6, C_TABLE_FRONT)
	p.rc(x0, top + 13.0, TABLE_W, 1, C_METAL)
	p.rc(x0 + 2, top + 14.0, 2, 3, C_METAL)
	p.rc(x0 + TABLE_W - 4.0, top + 14.0, 2, 3, C_METAL)
	# biển nhỏ trên bàn giữa (nội quy dựng đứng như ảnh) và chai nước
	if i % 3 == 1:
		p.rc(cx - 2, top + 1, 5, 6, Color("2f5ea8"))
		p.rc(cx - 1, top + 2, 3, 3, Color("f4f6f8"))
	elif i % 3 == 2:
		p.rc(cx - 1, top + 1, 3, 6, Color("b9d6e8"))
		p.rc(cx - 1, top + 1, 3, 1, Color("2f6bd0"))
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if s.t != i:
			continue
		var what := _item_for(si)
		if what != "":
			_paint_item(p, s, what)

# Món đồ học trên bàn trước chỗ ngồi si ("" nếu chỗ đó trống)
func _item_for(si: int) -> String:
	var s: Dictionary = _seats[si]
	if si == _sit:
		return "book"
	if s.who >= 0 and _present(s.who):
		var st: Dictionary = STUDENTS[s.who]
		return str(st.what)
	return ""

# Đồ học trên bàn trước mặt từng người ngồi
func _paint_item(p: Node2D, s: Dictionary, what: String) -> void:
	var top: float = s.top
	var x: float = s.x
	if s.side == 1:
		x += 10.0 if s.slot == 1 else -10.0   # người ngồi phía dưới che bàn nên đồ đặt lệch sang bên
	var seed_x: float = s.x
	if what == "book":
		p.rc(x - 7, top + 1, 14, 7, Color("2b2b2b"))
		p.rc(x - 6, top + 2, 6, 5, Color("f6f3e8"))
		p.rc(x, top + 2, 6, 5, Color("f6f3e8"))
		p.rc(x - 1, top + 2, 1, 5, Color("9a9a90"))
		var flip: bool = int(_clock * 0.4 + seed_x) % 5 == 0   # thỉnh thoảng lật trang
		p.rc(x + 1, top + 3, 2 if flip else 4, 1, Color("8a8a80"))
		p.rc(x + 1, top + 5, 4, 1, Color("8a8a80"))
	elif what == "laptop":
		if s.side == 0:   # người ngồi phía trên: thấy mặt lưng nắp máy
			p.rc(x - 7, top - 1, 14, 6, Color("8f98a2"))
			p.rc(x - 7, top - 1, 14, 1, Color("c3c9d0"))
			p.rc(x - 7, top + 5, 14, 3, Color("6f7782"))
		else:             # người ngồi phía dưới: thấy màn hình
			p.rc(x - 7, top, 14, 7, Color("2a2d36"))
			p.rc(x - 6, top + 1, 12, 5, Color("3b86e0"))
			var scroll: int = int(_clock * 3.0 + seed_x) % 3
			for l in 2:
				p.rc(x - 4, top + 2 + l * 2, 4 + ((l + scroll) % 3) * 2, 1, Color("d6eaff"))
	elif what == "write":
		p.rc(x - 7, top + 1, 14, 7, Color("f4f4ee"))
		p.rc(x - 7, top + 1, 14, 1, Color("d8d8d0"))
		for l in 3:
			p.rc(x - 5, top + 2 + l * 2, 6 + (l % 2) * 3, 1, Color("5a7fc0"))
		var pen: int = int(_clock * 2.0 + seed_x) % 3   # cây bút nhích nhẹ khi viết
		p.rc(x + 2 + pen, top + 4, 3, 1, Color("c0392b"))
	elif what == "tablet":
		p.rc(x - 5, top + 1, 10, 7, Color("23262e"))
		p.rc(x - 4, top + 2, 8, 5, Color("e8eef6"))
		p.rc(x - 3, top + 3, 5, 1, Color("5a7fc0"))
		p.rc(x - 3, top + 5, 3, 1, Color("5a7fc0"))
	# hộp bút hồng cho thêm sinh hoạt
	if s.slot == 0:
		p.rc(s.x - 13.0, top + 1.0, 6, 3, Color("f3a8c0"))

# Ghế + người ngồi ở phía trên (side 0) hoặc phía dưới (side 1) của bàn: sinh viên NPC hoặc chính người chơi
func _paint_seats(p: Node2D, i: int, side: int) -> void:
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if s.t != i or s.side != side:
			continue
		var sp: Vector2 = s.pos
		var who := -1
		if si != _sit and s.who >= 0 and _present(s.who):
			who = s.who
		var mine := (si == _sit)
		if side == 0:
			# lưng ghế phía sau người ngồi, người quay xuống bàn (mặt bàn vẽ sau che chân)
			p.rc(sp.x - 9, sp.y - 20, 18, 14, C_CHAIR_DK)
			p.rc(sp.x - 8, sp.y - 19, 16, 12, C_CHAIR)
			p.rc(sp.x - 8, sp.y - 19, 16, 2, C_CHAIR_HI)
			if who >= 0:
				var st: Dictionary = STUDENTS[who]
				p.draw_person(sp, Color(str(st.shirt)), Color(str(st.hair)), 0, 0.0, st.uni, st.long, false)
			elif mine:
				p.draw_person(sp, Color.WHITE, Color("1b1b1b"), 0, 0.0, true, false, false)
		else:
			# mặt ghế, người quay lưng về phía ta nhìn lên bàn, lưng ghế che phần hông
			p.rc(sp.x - 8, sp.y - 6, 16, 8, C_CHAIR_DK)
			p.rc(sp.x - 7, sp.y - 5, 14, 6, C_CHAIR)
			if who >= 0:
				var st2: Dictionary = STUDENTS[who]
				p.draw_person(sp, Color(str(st2.shirt)), Color(str(st2.hair)), 1, 0.0, st2.uni, st2.long, st2.pack)
			elif mine:
				p.draw_person(sp, Color.WHITE, Color("1b1b1b"), 1, 0.0, true, false, true)
			p.rc(sp.x - 8, sp.y - 8, 16, 4, C_CHAIR_DK)
			p.rc(sp.x - 7, sp.y - 8, 14, 3, C_CHAIR_HI)
			p.rc(sp.x - 6, sp.y + 2, 2, 2, Color("1e2027"))
			p.rc(sp.x + 4, sp.y + 2, 2, 2, Color("1e2027"))

func _paint_librarian(p: Node2D) -> void:
	p.draw_person(LIBRARIAN_FEET, Color("5fa8a0"), Color("1b1b1b"), 0, 0.0, false, true, false)

func _paint_counter(p: Node2D) -> void:
	var r := COUNTER
	p.rc(r.position.x - 1, r.position.y - 1, r.size.x + 2, r.size.y + 2, Color("5b3a22"))
	p.rc(r.position.x, r.position.y, r.size.x, 8, Color("c8a070"))
	p.rc(r.position.x, r.position.y, r.size.x, 1, Color("e0c498"))
	p.rc(r.position.x, r.position.y + 8.0, r.size.x, 8, Color("8a6238"))
	p.rc(r.position.x, r.position.y + 15.0, r.size.x, 1, Color("5b3a22"))
	# hai máy tính hai bên thủ thư (mặt lưng màn hình) và hoa nhỏ
	for mx in [r.position.x + 14.0, r.end.x - 26.0]:
		p.rc(mx, r.position.y - 9, 16, 11, Color("23262e"))
		p.rc(mx + 1, r.position.y - 8, 14, 9, Color("3a3e48"))
		p.rc(mx + 1, r.position.y - 8, 14, 2, Color("565b68"))
		p.rc(mx + 6, r.position.y + 2, 4, 2, Color("1e2027"))
	p.rc(r.position.x + 52, r.position.y - 4, 5, 6, Color("e08a2e"))
	p.rc(r.position.x + 53, r.position.y - 7, 3, 3, Color("c0392b"))

# Xe đẩy sách inox có thanh chắn
func _paint_trolley(p: Node2D) -> void:
	var r := TROLLEY
	p.shadow(Vector2(r.get_center().x, r.end.y), 14.0)
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y - 4.0, Color("aeb5bd"))
	p.rc(r.position.x + 1, r.position.y + 1, r.size.x - 2.0, 6, Color("d6dbe0"))
	p.rc(r.position.x + 3, r.position.y + 1, 7, 4, Color("2f6bd0"))
	p.rc(r.position.x + 12, r.position.y + 2, 8, 3, Color("f2f2f2"))
	p.rc(r.position.x + 1, r.position.y + 10.0, r.size.x - 2.0, 10, Color("8f98a2"))
	p.rc(r.position.x + 2, r.end.y - 4.0, 3, 4, Color("23262e"))
	p.rc(r.end.x - 5.0, r.end.y - 4.0, 3, 4, Color("23262e"))

# Nhân vật dùng đúng hàm draw_person() của game (áo polo trường, animation đi bộ)
func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

# Sách rơi (việc thủ thư giao): bìa màu có chấm sáng nhấp nháy để dễ thấy
func _paint_books(p: Node2D) -> void:
	var cols := [Color("c0392b"), Color("2f6bd0"), Color("3a8f4a")]
	for i in _books.size():
		var b: Dictionary = _books[i]
		if b.got:
			continue
		var bp: Vector2 = b.pos
		p.shadow(bp, 6.0)
		p.rc(bp.x - 5, bp.y - 5, 10, 6, Color("2b2b2b"))
		p.rc(bp.x - 4, bp.y - 4, 8, 4, cols[i % cols.size()])
		p.rc(bp.x - 4, bp.y - 1, 8, 1, Color("f6f3e8"))
		if int(_clock * 2.0) % 2 == 0:
			p.rc(bp.x + 4, bp.y - 8, 2, 2, Color("ffe28a"))

# Lớp phủ: lời thủ thư, gợi ý phím, thông báo, hộp thoại
func _paint_overlay(p: Node2D) -> void:
	if _say_t > 0.0:
		_bubble(p, _say_text, LIBRARIAN_FEET.x, 40.0, Color("ffe28a"))
	if _toast_t > 0.0:
		_bubble(p, _toast_text, 240.0, 80.0 + 0.0, Color.WHITE)
	if _closing:
		return
	if _dlg_mode != "":
		_paint_dialog(p)
		return
	if _sit >= 0:
		_bubble(p, "[E] Đứng dậy   [Q] Ôn đề giữa kỳ", 240.0, 250.0, Color("ffd23f"))
		var lines := "Đang học · thời gian x%d" % int(STUDY_TIME_MULT)
		_bubble(p, lines, 240.0, 236.0, Color("9be29b"))
		return
	var it: Dictionary = _interaction()
	if not it.is_empty():
		_bubble(p, str(it.text), _pos.x, _pos.y - 40.0, Color("ffd23f"))

func _bubble(p: Node2D, text: String, cx: float, y: float, col: Color) -> void:
	var w: float = p.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var x := clampf(cx - w / 2.0, 3.0, VIEW.x - w - 3.0)
	p.rc(x - 1, y - 10.0, w + 2.0, 14, Color("333333"))
	p.rc(x, y - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	p.ctext(text, x, y, w, 8, col)

func _paint_dialog(p: Node2D) -> void:
	var r := Rect2(16, 168, 448, 86)
	p.draw_rect(r, Color(0.04, 0.08, 0.14, 0.95))
	p.draw_rect(r, Color("e0b020"), false, 1.0)
	p.draw_string(p.font, Vector2(24, 182), "Thủ thư", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffd23f"))
	if _dlg_mode == "menu":
		var lines := _menu_lines()
		for i in lines.size():
			p.draw_string(p.font, Vector2(30, 197 + i * 12), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(330, 248), "Esc: đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6))
	else:
		p.draw_multiline_string(p.font, Vector2(24, 198), _dlg_text, HORIZONTAL_ALIGNMENT_LEFT, 430.0, 9, 4, Color.WHITE)
		p.draw_string(p.font, Vector2(330, 248), "E: tiếp tục · Esc: đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6))

# Khung chọn ở cửa Tòa C: hành lang có hai lối
func _paint_choice(p: Node2D) -> void:
	var r := Rect2(100, 84, 280, 96)
	p.draw_rect(r, Color(0.04, 0.08, 0.14, 0.94))
	p.draw_rect(r, Color("e0b020"), false, 1.0)
	p.draw_string(p.font, Vector2(112, 102), "Tòa C", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffe28a"))
	var open := _is_open()
	var lib_text := "[1] Thư viện (đang mở)" if open else "[1] Thư viện (đóng cửa)"
	p.draw_string(p.font, Vector2(114, 124), lib_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE if open else Color(1, 1, 1, 0.55))
	p.draw_string(p.font, Vector2(114, 140), "[2] Phòng học", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	p.draw_string(p.font, Vector2(114, 156), "[Esc] Hủy", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.65))
	if _choice_msg != "":
		p.draw_string(p.font, Vector2(112, 172), _choice_msg, HORIZONTAL_ALIGNMENT_LEFT, 262.0, 8, Color("ff9b9b"))
