extends "res://scripts/features/feature.gd"
# THƯ VIỆN - Nằm trong Tòa C (Redesign theo bản vẽ phòng đọc chuẩn).
#
# Vào / Ra:
#   - Đứng trước cửa Tòa C, bấm [E] để chọn: [1] Thư viện hoặc [2] Phòng học Tòa C.
#   - Ở cuối thảm xanh (cửa dưới), bấm [E] để ra ngoài (nếu quên lấy cặp trong tủ thì cặp tự trả lại).
#
# Tính năng bên trong:
#   - W A S D: đi lại. Giữ Shift để chạy (thủ thư sẽ nhắc; từ lần 2 bị -1 điểm rèn luyện).
#   - [E] trước tủ 12 ô (góc dưới trái): gửi cặp / lấy cặp (khi gửi, nhân vật bỏ ba lô trên lưng).
#   - [E] ở ghế trống: ngồi học (thời gian trôi x4, cộng GPA theo mỗi 30 phút game, đủ 2h +1 ĐRL,
#     nhân 1.5 tốc độ cộng GPA nếu đang mượn sách; ngồi học trùng giờ có tiết bị -2 ĐRL "Bỏ tiết").
#   - [Q] khi đang ngồi học: mở bộ đề ôn tập giữa kỳ (math_quiz).
#   - [E] trước quầy "MƯỢN - TRẢ SÁCH" (góc dưới phải): nói chuyện với cô thủ thư để mượn/trả sách
#     (hạn 3 ngày), hỏi giờ mở cửa, hoặc nhận/báo cáo nhiệm vụ nhặt 3 cuốn sách rơi.
#   - Giờ mở cửa: Thứ 2 - Thứ 7, 07:00-12:00 và 13:00-17:00 (Chủ nhật nghỉ).

const Schedule := preload("res://scripts/features/schedule_data.gd")

# ---------- Cửa Tòa C ----------
const BUILDING_NAME := "C"
const DOOR_RANGE := 24.0

# ---------- Kích thước & Bố cục phòng đọc (480x270) ----------
const VIEW := Vector2(480, 270)
const WALL_H := 40.0
const START_POS := Vector2(241, 244)
const EXIT_ZONE := Rect2(212, 246, 56, 24)

const LOCKER_BOX := Rect2(48, 202, 140, 38)      # tủ gửi cặp 12 ô (6 cột x 2 hàng) góc dưới trái
const LOCKER_ZONE := Rect2(44, 240, 148, 20)     # vùng đứng trước tủ để gửi / lấy cặp

const COUNTER_BOX := Rect2(292, 212, 104, 22)    # quầy cô thủ thư góc dưới phải
const CART_BOX := Rect2(404, 214, 34, 22)        # xe đẩy sách góc dưới phải
const LIBRARIAN_FEET := Vector2(330, 224)        # cô thủ thư đứng sau quầy
const DESK_ZONE := Rect2(284, 196, 118, 62)      # vùng đứng quanh quầy để nói chuyện với cô thủ thư

const WALK_SPEED := 70.0
const RUN_MULT := 1.6
const TOAST_TIME := 2.6

# 8 kệ sách dọc A - H ở nửa trên phòng
const SHELF_Y := 44.0
const SHELF_W := 18.0
const SHELF_H := 72.0
const SHELF_XS := [36.0, 92.0, 148.0, 204.0, 260.0, 316.0, 372.0, 428.0]
const SHELF_LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H"]

# 4 bàn gỗ dài nằm ngang [x, y, rộng] và 4 bàn lẻ sát tường [x, y]
const TABLES := [[72, 136, 120], [290, 136, 120], [72, 172, 120], [290, 172, 120]]
const WALL_TABLES := [[14, 138], [14, 168], [444, 138], [444, 168]]
const PLANTS := [Vector2(21, 76), Vector2(459, 76)]

# ---------- Giờ mở cửa (phút trong ngày) ----------
const OPEN_HOURS := [[420, 720], [780, 1020]]   # 07:00-12:00 và 13:00-17:00
const CLOSED_WEEKDAY := 6                       # Chủ nhật

# ---------- Thông số học tập & nhiệm vụ ----------
const STUDY_TIME_MULT := 4.0
const STUDY_STEP_MIN := 30.0
const STUDY_GPA_STEP := 0.01
const STUDY_GPA_DAILY_CAP := 0.12
const STUDY_DRL_MIN := 120.0
const STUDY_DRL_DAILY_CAP := 1
const BORROW_BONUS := 1.5
const BORROW_DAYS := 3
const SKIP_CLASS_MIN := 15.0
const QUEST_BOOKS := 3
const BOOK_SPOTS := [Vector2(132, 126), Vector2(241, 154), Vector2(350, 126)]
const BOOK_TITLES := ["Giải tích 1", "Nhập môn lập trình C++", "Toán rời rạc cơ bản", "Cơ sở dữ liệu cho người mới"]

# Danh sách sinh viên NPC theo bố cục ảnh tham chiếu (có khung giờ đến/về)
const STUDENTS := [
	{"kind": "long", "t": 0, "side": "n", "frac": 0.25, "what": "laptop", "shirt": "3d5a80", "hair": "1b1b1b", "uni": false, "long": false, "pack": false, "from": 420, "to": 1020},
	{"kind": "long", "t": 0, "side": "s", "frac": 0.70, "what": "book",   "shirt": "e07a5f", "hair": "2a1d14", "uni": false, "long": true,  "pack": false, "from": 440, "to": 720},
	{"kind": "long", "t": 1, "side": "n", "frac": 0.50, "what": "book",   "shirt": "81b29a", "hair": "5a3a22", "uni": false, "long": false, "pack": false, "from": 480, "to": 1020},
	{"kind": "long", "t": 1, "side": "s", "frac": 0.30, "what": "write",  "shirt": "f2cc8f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false, "from": 420, "to": 680},
	{"kind": "long", "t": 2, "side": "s", "frac": 0.45, "what": "laptop", "shirt": "3d5a80", "hair": "1b1b1b", "uni": false, "long": false, "pack": false, "from": 540, "to": 1020},
	{"kind": "long", "t": 3, "side": "n", "frac": 0.65, "what": "tablet", "shirt": "e07a5f", "hair": "2a1d14", "uni": false, "long": true,  "pack": false, "from": 780, "to": 1020},
	{"kind": "wall", "w": 0, "what": "book",  "shirt": "81b29a", "hair": "5a3a22", "uni": false, "long": false, "pack": false, "from": 420, "to": 920},
	{"kind": "wall", "w": 3, "what": "write", "shirt": "f2cc8f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false, "from": 600, "to": 1020},
]

# Bảng màu kiến trúc phòng đọc (theo ảnh tham chiếu)
const BOOK_COLORS := [Color("c0392b"), Color("2980b9"), Color("27ae60"), Color("f1c40f"), Color("8e44ad"), Color("e67e22"), Color("ecf0f1"), Color("16a085")]
const BAG_BLUE := Color("2f6bd0")
const C_NAVY := Color("1f2f5a")
const C_BROWN := Color("5a3a1e")
const C_WOOD := Color("8a5a2a")
const C_WOOD_LT := Color("d9a05a")
const C_DOOR := Color("7a4f28")
const C_CREAM := Color("fff6e0")
const C_FRAME := Color("2e2f2b")
const C_GOLD := Color("ffd86a")

var inside := false
var _choice := false
var _choice_msg := ""
var _layer: CanvasLayer
var _painter: Node2D
var _pos := START_POS
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải
var _anim := 0.0
var _clock := 0.0
var _fade := 0.0
var _closing := false
var _banner := 0.0
var _enter_day := 0
var _close_warned := false

var _seats: Array = []        # danh sách chỗ ngồi học: {kind, t/w, side, frac, pos, access, face, chair, who}
var _solid: Array = []        # vùng va chạm vật thể trong phòng
var _looked := false
var _quiz: Node = null
var _room_f: Node = null

# Tủ gửi cặp
var _slot_cols: Array = []
var _bag_slot := -1

# Học tập
var _sit := -1
var _sit_acc := 0.0
var _page_t := 5.0
var _gpa_today: Dictionary = {}
var _study_today: Dictionary = {}
var _drl_today: Dictionary = {}
var _cap_told_day := -1
var _class_acc: Dictionary = {}
var _class_penalized: Dictionary = {}

# Thủ thư & nhiệm vụ
var _dlg_mode := ""           # "" | "menu" | "text"
var _dlg_text := ""
var _borrowed := ""
var _borrow_day := 0
var _borrow_count := 0
var _quest := 0               # 0 chưa nhận, 1 đang làm, 2 đã đủ sách chờ báo cáo
var _quest_got := 0
var _quest_done_day := -1
var _books: Array = []
var _say_text := ""
var _say_t := 0.0

# Nhắc nhở yên tĩnh & thông báo
var _running := false
var _run_t := 0.0
var _warn_cd := 0.0
var _warns := 0
var _step_t := 0.0
var _toast_text := ""
var _toast_t := 0.0

# Âm thanh
var _amb: AudioStreamPlayer
var _sfx_step: AudioStreamPlayer
var _sfx_misc: AudioStreamPlayer
var _music_db := 0.0
var _ducked := false

func _ready() -> void:
	_build_room()
	_reset_lockers()
	_layer = CanvasLayer.new()
	_layer.layer = 5
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

# ======================= DỰNG PHÒNG & CHỖ NGỒI =======================

func _build_room() -> void:
	_solid.clear()
	_seats.clear()
	for sx in SHELF_XS:
		_solid.append(Rect2(float(sx) - 2.0, SHELF_Y - 2.0, SHELF_W + 4.0, SHELF_H + 6.0))
	for tb in TABLES:
		_solid.append(Rect2(float(tb[0]) - 2.0, float(tb[1]) - 2.0, float(tb[2]) + 4.0, 20.0))
	for wt in WALL_TABLES:
		if float(wt[0]) < 100.0:
			_solid.append(Rect2(float(wt[0]) - 2.0, float(wt[1]) - 2.0, 42.0, 18.0))
		else:
			_solid.append(Rect2(float(wt[0]) - 18.0, float(wt[1]) - 2.0, 42.0, 18.0))
	for pc in PLANTS:
		_solid.append(Rect2(pc.x - 7.0, pc.y, 14.0, 9.0))
	_solid.append(LOCKER_BOX)
	_solid.append(COUNTER_BOX)
	_solid.append(CART_BOX)

	# Tạo danh sách ghế ngồi học trên 4 bàn dài
	var long_defs := [
		{"t": 0, "side": "n", "frac": 0.25},
		{"t": 0, "side": "n", "frac": 0.72},
		{"t": 0, "side": "s", "frac": 0.70},
		{"t": 1, "side": "n", "frac": 0.50},
		{"t": 1, "side": "s", "frac": 0.30},
		{"t": 1, "side": "s", "frac": 0.75},
		{"t": 2, "side": "n", "frac": 0.30},
		{"t": 2, "side": "s", "frac": 0.45},
		{"t": 3, "side": "n", "frac": 0.25},
		{"t": 3, "side": "n", "frac": 0.65},
	]
	for d in long_defs:
		_add_long_seat(int(d.t), str(d.side), float(d.frac))

	# Tạo danh sách ghế ngồi học ở 4 bàn lẻ sát tường
	for wi in WALL_TABLES.size():
		_add_wall_seat(wi)

	_fix_seat_access_points()

func _seat_access_clear(pos: Vector2, require_open_space: bool = false) -> bool:
	if _blocked(pos):
		return false
	if LOCKER_ZONE.has_point(pos) or EXIT_ZONE.has_point(pos) or DESK_ZONE.has_point(pos):
		return false
	var clear_directions := 0
	var step := 2.5
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		if not _blocked(pos + direction * step):
			clear_directions += 1
	if require_open_space:
		return clear_directions == 4
	return clear_directions >= 2

func _find_clear_seat_access(seat: Dictionary) -> Vector2:
	var origin: Vector2 = seat.access
	var side := str(seat.side)
	var directions: Array[Vector2] = []
	if side == "s":
		directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP,
			Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
			Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]
	elif side == "n":
		directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
			Vector2(-1, -1).normalized(), Vector2(1, -1).normalized(),
			Vector2(-1, 1).normalized(), Vector2(1, 1).normalized()]
	elif side == "l":
		directions = [Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.LEFT,
			Vector2(1, -1).normalized(), Vector2(1, 1).normalized(),
			Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized()]
	else:
		directions = [Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.RIGHT,
			Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized(),
			Vector2(1, -1).normalized(), Vector2(1, 1).normalized()]

	for direction in directions:
		for distance in range(2, 161, 2):
			var candidate: Vector2 = origin + direction * float(distance)
			if _seat_access_clear(candidate, true):
				return candidate

	for direction in directions:
		for distance in range(2, 161, 2):
			var candidate: Vector2 = origin + direction * float(distance)
			if _seat_access_clear(candidate, false):
				return candidate

	return START_POS

func _fix_seat_access_points() -> void:
	for si in _seats.size():
		var seat: Dictionary = _seats[si]
		if not _seat_access_clear(seat.access, false):
			seat.access = _find_clear_seat_access(seat)
			_seats[si] = seat

func _add_long_seat(t_idx: int, side: String, frac: float) -> void:
	var tb: Array = TABLES[t_idx]
	var x := float(tb[0]) + float(tb[2]) * frac
	var y := float(tb[1])
	var seat: Dictionary
	if side == "n":
		seat = {
			"kind": "long", "t": t_idx, "w": -1, "side": "n", "frac": frac,
			"pos": Vector2(x, y + 8.0),
			"access": Vector2(x, y - 8.0),
			"face": 0,
			"chair": Rect2(x - 7.0, y - 5.0, 14.0, 6.0),
			"who": -1
		}
	else:
		var feet := Vector2(x, y + 26.0)
		seat = {
			"kind": "long", "t": t_idx, "w": -1, "side": "s", "frac": frac,
			"pos": feet,
			"access": Vector2(x, y + 32.0),
			"face": 1,
			"chair": Rect2(x - 7.0, feet.y - 7.0, 14.0, 7.0),
			"who": -1
		}
		_solid.append(Rect2(x - 7.0, feet.y - 7.0, 14.0, 8.0))
	for s in STUDENTS.size():
		var st: Dictionary = STUDENTS[s]
		if str(st.kind) == "long" and int(st.t) == t_idx and str(st.side) == side and is_equal_approx(float(st.frac), frac):
			seat.who = s
	_seats.append(seat)

func _add_wall_seat(w_idx: int) -> void:
	var wt: Array = WALL_TABLES[w_idx]
	var feet := _chair_feet(w_idx)
	var is_left := float(wt[0]) < 100.0
	var access := Vector2(feet.x, float(wt[1]) + 22.0) if (w_idx % 2 == 1) else Vector2(feet.x, float(wt[1]) - 6.0)
	var seat := {
		"kind": "wall", "t": -1, "w": w_idx, "side": "l" if is_left else "r", "frac": 0.5,
		"pos": feet,
		"access": access,
		"face": 2 if is_left else 3,
		"chair": Rect2(feet.x - 6.0, feet.y - 7.0, 12.0, 7.0),
		"who": -1
	}
	for s in STUDENTS.size():
		var st: Dictionary = STUDENTS[s]
		if str(st.kind) == "wall" and int(st.w) == w_idx:
			seat.who = s
	_seats.append(seat)

func _chair_feet(wall_i: int) -> Vector2:
	var wt: Array = WALL_TABLES[wall_i]
	if float(wt[0]) < 100.0:
		return Vector2(float(wt[0]) + 33.0, float(wt[1]) + 12.0)
	return Vector2(float(wt[0]) - 11.0, float(wt[1]) + 12.0)

func _reset_lockers() -> void:
	_slot_cols = [Color("d9534f"), null, null, Color("f0ad4e"), Color("5cb85c"), null, null, Color("9b59b6"), null, null, Color("e67e22"), null]
	_bag_slot = -1

# ======================= TÌM FEATURE CÓ SẴN =======================

func _lookup() -> void:
	if _looked:
		return
	_looked = true
	# Tìm trong cả features lẫn map modules (phong_hoc là map module, không nằm trong game.features)
	var all_nodes: Array = game.features + game.get_children()
	for f in all_nodes:
		if f == self:
			continue
		if _quiz == null and f.has_method("start_round") and f.has_method("begin"):
			_quiz = f
		if _room_f == null and f.has_method("open_classroom") and f.has_method("enter_room"):
			_room_f = f

func _quiz_open() -> bool:
	return _quiz != null and bool(_quiz.active)

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
	return "Thư viện mở Thứ 2 - Thứ 7: %s-%s và %s-%s. Chủ nhật nghỉ. Nhớ gửi cặp vào tủ và giữ yên lặng nhé!" % [
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

# ======================= VÀO / RA TÒA C =======================

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
	_reset_lockers()
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
	_banner = 2.5
	_sit = -1
	_dlg_mode = ""
	_enter_day = game.day
	_close_warned = false
	_warns = 0
	_run_t = 0.0
	_warn_cd = 0.0
	_reset_lockers()
	_layer.visible = true
	game.hud.visible = false
	_audio_start()
	_painter.queue_redraw()

# ======================= XỬ LÝ PHÍM =======================

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if _quiz_open():
		return
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
		finish()
		if _room_f != null:
			_room_f.open_classroom("C")
		else:
			_choice_msg = "Chưa nạp được module phòng học."
			_painter.queue_redraw()
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
		if pk == KEY_E or k.keycode == KEY_ESCAPE or pk == KEY_W or pk == KEY_A or pk == KEY_S or pk == KEY_D or pk == KEY_UP or pk == KEY_DOWN or pk == KEY_LEFT or pk == KEY_RIGHT:
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
		_closing = true
	elif kind == "locker":
		_use_locker()
	elif kind == "book":
		_pick_book(int(it.idx))
	elif kind == "desk":
		_open_desk()
	elif kind == "seat":
		_sit_down(int(it.idx))
	get_viewport().set_input_as_handled()

# ======================= TƯƠNG TÁC TRONG PHÒNG =======================

func _interaction() -> Dictionary:
	if EXIT_ZONE.has_point(_pos):
		return {"kind": "door", "text": "[E] Ra ngoài"}
	if LOCKER_ZONE.has_point(_pos):
		return {"kind": "locker", "text": "[E] Lấy cặp" if _bag_slot >= 0 else "[E] Gửi cặp"}
	for i in _books.size():
		var b: Dictionary = _books[i]
		if not b.got and _pos.distance_to(b.pos) < 16.0:
			return {"kind": "book", "idx": i, "text": "[E] Nhặt sách"}
	if DESK_ZONE.has_point(_pos):
		return {"kind": "desk", "text": "[E] Nói chuyện với thủ thư"}
	var si := _nearest_seat()
	if si >= 0:
		return {"kind": "seat", "idx": si, "text": "[E] Ngồi học"}
	return {}

func _use_locker() -> void:
	if _bag_slot >= 0:
		_slot_cols[_bag_slot] = null
		_bag_slot = -1
		_toast("Đã lấy cặp ra khỏi tủ.")
		return
	var slot := -1
	for i in _slot_cols.size():
		if _slot_cols[i] == null:
			slot = i
			break
	if slot < 0:
		_toast("Tủ đầy rồi!")
		return
	_slot_cols[slot] = BAG_BLUE
	_bag_slot = slot
	_toast("Đã gửi cặp vào ô " + str(slot + 1) + ".")

func _present(who: int) -> bool:
	var st: Dictionary = STUDENTS[who]
	var m: float = game.game_min
	return m >= float(st["from"]) and m < float(st["to"])

func _seat_free(si: int) -> bool:
	var s: Dictionary = _seats[si]
	if si == _sit:
		return false
	return s.who < 0 or not _present(s.who)

func _nearest_seat() -> int:
	var best := -1
	var best_d := 16.0
	for si in _seats.size():
		if not _seat_free(si):
			continue
		var d: float = _pos.distance_to(_seats[si].access)
		if d < best_d:
			best_d = d
			best = si
	return best

func _sit_down(si: int) -> void:
	var s: Dictionary = _seats[si]
	_sit = si
	_pos = s.pos
	_face = int(s.face)
	_sit_acc = 0.0
	_page_t = 3.0
	_play_misc("thu_vien_lat_sach")
	_toast("Bắt đầu học. Thời gian trôi nhanh gấp %d lần." % int(STUDY_TIME_MULT))

func _stand_up() -> void:
	if _sit < 0:
		return
	var s: Dictionary = _seats[_sit]
	_pos = s.access
	_face = 1 if int(s.face) == 0 else (0 if int(s.face) == 1 else (3 if int(s.face) == 2 else 2))
	_sit = -1

func _open_quiz() -> void:
	if _quiz == null:
		_toast("Chưa có bộ đề để ôn.")
		return
	var code := "VTP1" if randi() % 2 == 0 else "CSLT"
	_quiz.begin()
	_quiz.start_library_review_round(code, "ÔN TẬP · THƯ VIỆN")

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

# ======================= CÔ THỦ THƯ =======================

func _librarian_say(text: String) -> void:
	_say_text = text
	_say_t = 3.0

func _open_desk() -> void:
	_dlg_mode = "menu"
	_dlg_text = ""
	if _bag_slot >= 0:
		_librarian_say("Ngoan lắm, cặp gửi gọn rồi đó. Em cần gì nào?")
	else:
		_librarian_say("Nhớ gửi cặp vào tủ bên trái nhé. Em cần gì nào?")

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
		_dlg_text = "Em mới nhặt được %d/%d cuốn thôi. Sách nằm trên lối đi giữa các bàn và kệ." % [_quest_got, QUEST_BOOKS]
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

# ======================= TOAST & ÂM THANH =======================

func _toast(text: String) -> void:
	_toast_text = text
	_toast_t = TOAST_TIME

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
		(m as AudioStreamPlayer).volume_db = _music_db - 12.0
		_ducked = true

func _audio_stop() -> void:
	if _amb != null:
		_amb.stop()
	if _ducked:
		var m = game.audio.get("_music") if game.audio != null else null
		if m is AudioStreamPlayer:
			(m as AudioStreamPlayer).volume_db = _music_db
		_ducked = false

# ======================= CẬP NHẬT MỖI KHUNG HÌNH =======================

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
	if _say_t > 0.0:
		_say_t -= delta
	if _banner > 0.0:
		_banner -= delta
	if _choice:
		_painter.queue_redraw()
		return
	if not inside:
		return
	_clock += delta
	if _closing:
		_fade = minf(_fade + delta * 3.5, 1.0)
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
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
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

func _walkable(pt: Vector2) -> bool:
	if pt.x >= 18.0 and pt.x <= 462.0 and pt.y >= 50.0 and pt.y <= 258.0:
		return true
	if pt.x >= 214.0 and pt.x <= 266.0 and pt.y > 258.0 and pt.y <= 268.0:
		return true
	return false

func _blocked(p: Vector2) -> bool:
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for pt in [hit.position, Vector2(hit.end.x, hit.position.y), Vector2(hit.position.x, hit.end.y), hit.end]:
		if not _walkable(pt):
			return true
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

# ======================= VẼ PHÒNG ĐỌC (THEO ẢNH THAM CHIẾU) =======================

func _paint() -> void:
	var p := _painter
	if _choice:
		_paint_choice(p)
		return
	p.rc(0, 0, VIEW.x, VIEW.y, C_FRAME)
	_paint_floor(p)
	_paint_wall(p)
	for i in SHELF_XS.size():
		_paint_shelf(p, float(SHELF_XS[i]), i)
	_paint_dropped_books(p)

	# Sắp xếp Y-sort cho bàn, ghế, người ngồi, cây, quầy, tủ, xe đẩy, người chơi
	var items: Array = []
	for i in TABLES.size():
		items.append([float(TABLES[i][1]) + 14.0, 0, i])
	for i in WALL_TABLES.size():
		items.append([float(WALL_TABLES[i][1]) + 14.0, 1, i])
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		var occupied := (si == _sit) or (int(s.who) >= 0 and _present(int(s.who)))
		if occupied:
			items.append([float(s.pos.y), 2, si])
	items.append([LIBRARIAN_FEET.y, 3, null])
	for pc in PLANTS:
		items.append([pc.y + 9.0, 4, pc])
	items.append([COUNTER_BOX.end.y, 5, null])
	items.append([CART_BOX.end.y, 6, null])
	items.append([LOCKER_BOX.end.y, 7, null])
	if _sit < 0:
		items.append([_pos.y, 8, null])
	items.sort_custom(func(a, b): return a[0] < b[0])

	for it in items:
		match it[1]:
			0:
				_paint_long_table(p, it[2])
			1:
				_paint_wall_table(p, it[2])
			2:
				_paint_seated_person(p, it[2])
			3:
				_paint_librarian(p)
			4:
				_paint_plant(p, it[2])
			5:
				_paint_counter(p)
			6:
				_paint_cart(p)
			7:
				_paint_locker(p)
			8:
				_paint_player(p)

	_paint_overlay(p)
	_paint_banner(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

func _ctext_fit(p: Node2D, text: String, cx: float, y: float, size: int, col: Color) -> void:
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 6.0
	p.ctext(text, cx - w / 2.0, y, w, size, col)

func _paint_floor(p: Node2D) -> void:
	p.rc(8, WALL_H, 464, 220, Color("c8a06a"))
	var row := 0
	var y := WALL_H
	while y < 260.0:
		p.rc(8, y, 464, 1, Color("b08a55"))
		for j in 10:
			p.rc(8.0 + j * 48.0 + (row % 3) * 16.0, y, 1, minf(14.0, 260.0 - y), Color("b08a55"))
		y += 14.0
		row += 1
	p.rc(224, 48, 34, 212, Color("d4a93a"))     # thảm xanh viền vàng chạy dọc trục giữa
	p.rc(226, 48, 30, 212, Color("2f5d4c"))
	p.rc(230, 48, 22, 212, Color("3f6b5a"))
	p.rc(0, 260, VIEW.x, 10, C_FRAME)
	p.rc(207, 256, 3, 14, C_FRAME)
	p.rc(270, 256, 3, 14, C_FRAME)
	p.rc(210, 258, 60, 12, Color("cfdde8"))
	p.rc(214, 262, 52, 8, Color("eef6fb"))

func _paint_wall(p: Node2D) -> void:
	p.rc(8, 8, 464, WALL_H - 8.0, Color("efe4c8"))
	p.rc(8, 8, 464, 3, Color(0, 0, 0, 0.12))
	p.rc(8, 28, 464, 12, Color("3f6b5a"))
	p.rc(8, 28, 464, 2, Color("5a8b78"))
	p.rc(8, WALL_H - 2.0, 464, 2, Color("2a4a3d"))
	for wx in [56.0, 116.0, 326.0, 386.0]:
		_paint_window(p, wx)
	p.draw_circle(Vector2(241, 22), 11.0, C_BROWN)
	p.draw_circle(Vector2(241, 22), 9.5, Color("f8f4e6"))
	p.rc(240.5, 15, 1, 8, Color("1a1a2e"))
	p.rc(241, 21.5, 6, 1, Color("1a1a2e"))
	_plaque(p, "THƯ VIỆN", 197.0, Color("1f2f5a"), C_GOLD)
	_plaque(p, "IM LẶNG", 285.0, Color("fff6e0"), Color("c0262d"))

func _plaque(p: Node2D, text: String, cx: float, bg: Color, fg: Color) -> void:
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
	p.rc(cx - w / 2.0 - 1.0, 15, w + 2.0, 13, C_BROWN)
	p.rc(cx - w / 2.0, 16, w, 11, bg)
	p.ctext(text, cx - w / 2.0, 25, w, 7, fg)

func _paint_window(p: Node2D, x: float) -> void:
	p.rc(x - 1, 11, 42, 26, C_BROWN)
	p.rc(x, 12, 40, 24, Color("a8d8f0"))
	p.rc(x, 12, 40, 6, Color("c8e8f8"))
	p.rc(x + 3, 28, 14, 8, Color("4f9c4a"))
	p.rc(x + 24, 26, 14, 10, Color("3f8a3f"))
	p.rc(x + 19, 12, 2, 24, C_BROWN)
	p.rc(x, 22, 40, 2, C_BROWN)

func _paint_shelf(p: Node2D, x: float, idx: int) -> void:
	var y := SHELF_Y
	p.rc(x + SHELF_W, y + 2.0, 3, SHELF_H, Color(0, 0, 0, 0.16))
	p.rc(x - 1, y - 1, SHELF_W + 2.0, SHELF_H + 2.0, Color("3d2a16"))
	p.rc(x, y, SHELF_W, SHELF_H, C_WOOD)
	var n := int(SHELF_H / 4.0)
	for j in n:
		p.rc(x + 2.0, y + 2.0 + j * 4.0, 6, 4, BOOK_COLORS[int(p.hs(idx, j)) % 8])
		p.rc(x + 10.0, y + 2.0 + j * 4.0, 6, 4, BOOK_COLORS[int(p.hs(idx + 11, j)) % 8])
	p.rc(x + 8.0, y, 2, SHELF_H, Color("5a3a1e"))
	p.rc(x + 3.0, y + SHELF_H + 1.0, 12, 8, C_NAVY)
	p.ctext(str(SHELF_LETTERS[idx]), x + 3.0, y + SHELF_H + 7.0, 12, 6, C_GOLD)

func _paint_long_table(p: Node2D, idx: int) -> void:
	var tb: Array = TABLES[idx]
	var x := float(tb[0])
	var y := float(tb[1])
	var w := float(tb[2])
	p.rc(x + 2, y + 18, w - 2.0, 6, Color(0, 0, 0, 0.14))
	p.rc(x + 2, y + 18, 3, 6, C_BROWN)
	p.rc(x + w - 5.0, y + 18, 3, 6, C_BROWN)
	p.rc(x, y, w, 14, C_WOOD_LT)
	p.rc(x, y, w, 1, Color("f0c27a"))
	p.rc(x, y + 14, w, 4, C_WOOD)
	var any := false
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if str(s.kind) != "long" or int(s.t) != idx:
			continue
		var occupied := (si == _sit) or (int(s.who) >= 0 and _present(int(s.who)))
		if occupied:
			any = true
			var bx := float(s.pos.x) - 5.0
			var by := y + (3.0 if str(s.side) == "n" else 7.0)
			_paint_book(p, bx, by)
	if not any:
		_paint_book_stack(p, x + w * 0.5 - 5.0, y + 3.0)

func _paint_wall_table(p: Node2D, idx: int) -> void:
	var wt: Array = WALL_TABLES[idx]
	var x := float(wt[0])
	var y := float(wt[1])
	p.rc(x + 1, y + 16, 20, 4, Color(0, 0, 0, 0.14))
	p.rc(x, y, 22, 14, C_WOOD_LT)
	p.rc(x, y, 22, 1, Color("f0c27a"))
	p.rc(x, y + 14, 22, 3, C_WOOD)
	var seated := false
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if str(s.kind) == "wall" and int(s.w) == idx:
			if (si == _sit) or (int(s.who) >= 0 and _present(int(s.who))):
				seated = true
	if seated:
		_paint_book(p, x + 6.0, y + 4.0)
	else:
		_paint_book_stack(p, x + 6.0, y + 4.0)
	var cf := _chair_feet(idx)
	p.rc(cf.x - 6.0, cf.y - 7.0, 12, 7, C_DOOR)
	p.rc(cf.x - 6.0, cf.y - 7.0, 12, 1, Color("a8703c"))

func _paint_book(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y, 10, 6, C_BROWN)
	p.rc(x + 1, y + 1, 4, 4, Color("f4f4ee"))
	p.rc(x + 5, y + 1, 4, 4, Color("e8e8e0"))
	p.rc(x + 2, y + 2, 2, 1, Color("9aa0a8"))
	p.rc(x + 6, y + 2, 2, 1, Color("9aa0a8"))
	p.rc(x + 2, y + 3, 2, 1, Color("9aa0a8"))

func _paint_book_stack(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y + 4, 10, 3, Color("2980b9"))
	p.rc(x + 1, y + 2, 9, 3, Color("c0392b"))
	p.rc(x, y, 8, 3, Color("27ae60"))

func _paint_seated_person(p: Node2D, si: int) -> void:
	var s: Dictionary = _seats[si]
	var pos: Vector2 = s.pos
	var face: int = int(s.face)
	if si == _sit:
		p.draw_person(pos, Color.WHITE, Color("1b1b1b"), face, 0.0, true, false, _bag_slot < 0)
	elif int(s.who) >= 0 and _present(int(s.who)):
		var st: Dictionary = STUDENTS[int(s.who)]
		p.draw_person(pos, Color(str(st.shirt)), Color(str(st.hair)), face, 0.0, bool(st.uni), bool(st.long), bool(st.pack))
	if str(s.kind) == "long" and str(s.side) == "s":
		p.rc(pos.x - 7, pos.y - 7, 14, 7, C_DOOR)
		p.rc(pos.x - 7, pos.y - 7, 14, 1, Color("a8703c"))

func _paint_librarian(p: Node2D) -> void:
	var pos := LIBRARIAN_FEET
	var hair := Color("5a5a66")
	p.draw_person(pos, Color("2f5f6a"), hair, 0, 0.0, false, false, false)
	var by := pos.y
	p.rc(pos.x - 3, by - 26, 6, 4, hair)
	p.rc(pos.x - 4, by - 18, 4, 1, Color("2a2a2a"))
	p.rc(pos.x - 4, by - 15, 4, 1, Color("2a2a2a"))
	p.rc(pos.x - 4, by - 18, 1, 4, Color("2a2a2a"))
	p.rc(pos.x - 1, by - 18, 1, 4, Color("2a2a2a"))
	p.rc(pos.x + 1, by - 18, 4, 1, Color("2a2a2a"))
	p.rc(pos.x + 1, by - 15, 4, 1, Color("2a2a2a"))
	p.rc(pos.x + 1, by - 18, 1, 4, Color("2a2a2a"))
	p.rc(pos.x + 4, by - 18, 1, 4, Color("2a2a2a"))
	p.rc(pos.x, by - 17, 1, 1, Color("2a2a2a"))
	if _say_t <= 0.0:
		_ctext_fit(p, "Cô thủ thư", pos.x, pos.y - 30.0, 7, Color("ffe9a8"))

func _paint_counter(p: Node2D) -> void:
	var x := COUNTER_BOX.position.x
	var y := COUNTER_BOX.position.y
	var w := COUNTER_BOX.size.x
	p.rc(x, y, w, 7, C_WOOD_LT)
	p.rc(x, y, w, 1, Color("f0c27a"))
	p.rc(x, y + 7, w, 15, C_WOOD)
	p.rc(x, y + 20, w, 2, Color("5a3a1e"))
	p.rc(x + 2, y + 9, 14, 10, Color("a8703c"))
	p.rc(x + 88, y + 9, 14, 10, Color("a8703c"))
	_ctext_fit(p, "MƯỢN - TRẢ SÁCH", x + w / 2.0, y + 17.0, 6, C_GOLD)
	p.rc(x + 10, y - 7, 12, 8, Color("2a2c33"))
	p.rc(x + 11, y - 6, 10, 5, Color("5b8de8"))
	p.rc(x + 14, y + 1, 4, 2, Color("2a2c33"))
	_paint_book_stack(p, x + 60.0, y - 3.0)
	p.rc(x + 86, y - 2, 2, 3, Color("2a2c33"))
	p.rc(x + 82, y - 6, 8, 4, Color("2f7d4c"))
	p.rc(x + 82, y - 6, 8, 1, Color("4fb356"))

func _paint_cart(p: Node2D) -> void:
	var x := CART_BOX.position.x
	var y := CART_BOX.position.y
	p.rc(x, y + 4, 34, 14, C_WOOD)
	p.rc(x + 1, y + 5, 32, 6, Color("3d2a16"))
	p.rc(x + 1, y + 12, 32, 5, Color("3d2a16"))
	for i in 8:
		p.rc(x + 2.0 + i * 4.0, y + 5, 3, 6, BOOK_COLORS[i % 8])
		p.rc(x + 2.0 + i * 4.0, y + 12, 3, 5, BOOK_COLORS[(i + 3) % 8])
	p.rc(x, y + 3, 34, 2, Color("f0c27a"))
	p.draw_circle(Vector2(x + 5, y + 20), 2.0, Color("1a1a2e"))
	p.draw_circle(Vector2(x + 29, y + 20), 2.0, Color("1a1a2e"))

func _paint_locker(p: Node2D) -> void:
	var x := LOCKER_BOX.position.x
	var y := LOCKER_BOX.position.y
	var w := LOCKER_BOX.size.x
	var h := LOCKER_BOX.size.y
	p.rc(x - 1, y - 1, w + 2.0, h + 2.0, Color("3d2a16"))
	p.rc(x, y, w, h, Color("a8703c"))
	p.rc(x, y, w, 3, Color("c8904c"))
	p.rc(x, y + h - 3.0, w, 3, C_DOOR)
	for r in 2:
		for c in 6:
			var sx := x + 4.0 + c * 22.0
			var sy := y + 5.0 + r * 16.0
			p.rc(sx, sy, 20, 14, Color("2e2014"))
			p.rc(sx, sy + 12.0, 20, 2, C_DOOR)
			var bag: Variant = _slot_cols[r * 6 + c]
			if bag is Color:
				_paint_bag(p, sx, sy, bag)
	p.shadow(Vector2(x + w / 2.0, y + h + 1.0), 66.0)

func _paint_bag(p: Node2D, sx: float, sy: float, col: Color) -> void:
	p.rc(sx + 7, sy + 2, 6, 2, Color("1a1a2e"))
	p.rc(sx + 3, sy + 4, 14, 10, Color("1a1a2e"))
	p.rc(sx + 4, sy + 5, 12, 8, col)
	p.rc(sx + 4, sy + 5, 12, 3, col.lightened(0.25))
	p.rc(sx + 7, sy + 10, 6, 3, col.darkened(0.2))
	p.rc(sx + 9, sy + 8, 2, 2, Color("ffd23f"))

func _paint_plant(p: Node2D, c: Vector2) -> void:
	p.shadow(c + Vector2(0, 9), 9.0)
	p.rc(c.x - 7, c.y, 14, 9, Color("3b4252"))
	p.rc(c.x - 6, c.y + 1, 12, 7, Color("9aa8bb"))
	p.rc(c.x - 7, c.y, 14, 2, Color("b8c4d4"))
	var greens := [Color("2f7d32"), Color("3f9c45"), Color("2f7d32"), Color("4fb356"), Color("3f9c45")]
	var offs := [Vector2(-6, -3), Vector2(6, -3), Vector2(0, -9), Vector2(-3, -1), Vector2(3, -1)]
	for i in 5:
		p.draw_circle(c + offs[i], 5.0, greens[i])

func _paint_dropped_books(p: Node2D) -> void:
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

func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, _bag_slot < 0)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

# ======================= LỚP PHỦ & HỘP THOẠI =======================

func _paint_overlay(p: Node2D) -> void:
	if _say_t > 0.0:
		_bubble(p, _say_text, LIBRARIAN_FEET.x, LIBRARIAN_FEET.y - 34.0, Color("ffe28a"))
	if _toast_t > 0.0:
		_bubble(p, _toast_text, 240.0, 56.0, Color.WHITE)
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

func _paint_banner(p: Node2D) -> void:
	if _banner <= 0.0 or _closing:
		return
	var a := clampf(_banner, 0.0, 1.0)
	var text := "THƯ VIỆN - GIỮ YÊN LẶNG"
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 14.0
	p.rc(12, 244, w + 2.0, 15, Color(0.2, 0.2, 0.2, a))
	p.rc(13, 245, w, 13, Color(0.08, 0.1, 0.18, 0.92 * a))
	p.ctext(text, 13, 255, w, 8, Color(1.0, 0.82, 0.25, a))

func _paint_dialog(p: Node2D) -> void:
	var r := Rect2(16, 168, 448, 86)
	p.draw_rect(r, Color(0.04, 0.08, 0.14, 0.95))
	p.draw_rect(r, Color("e0b020"), false, 1.0)
	p.draw_string(p.font, Vector2(24, 182), "Cô thủ thư", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffd23f"))
	if _dlg_mode == "menu":
		var lines := _menu_lines()
		for i in lines.size():
			p.draw_string(p.font, Vector2(30, 197 + i * 12), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(330, 248), "Esc: đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6))
	else:
		p.draw_multiline_string(p.font, Vector2(24, 198), _dlg_text, HORIZONTAL_ALIGNMENT_LEFT, 430.0, 9, 4, Color.WHITE)
		p.draw_string(p.font, Vector2(330, 248), "E: tiếp tục · Esc: đóng", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6))

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

func draw_front_layer() -> void:
	if inside or _choice or game.is_busy():
		return
	if not _near_door_outside():
		return
	var label := "Bấm [E] để vào Tòa C (Thư viện / Phòng học)"
	var w: float = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(label, px - w / 2.0, py, w, 8, Color("ffd23f"))
