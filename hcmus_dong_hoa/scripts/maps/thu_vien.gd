extends "res://scripts/features/feature.gd"
# THƯ VIỆN, nằm trong Tòa C.
#
# Không có tòa nhà riêng và không đổi tên Tòa C: vẫn là cửa Tòa C có sẵn ("E: Vào Tòa C" của building_doors),
# nhưng bấm E ở đó sẽ mở thẳng phòng Thư viện thay cho phòng học chung. Module bắt phím E bằng _input()
# (chạy trước mọi _unhandled_input) nên luôn thắng building_doors, không phụ thuộc thứ tự nạp và không sửa file lõi.
# Bên trong: phòng tự học theo ảnh tham chiếu: tường cửa sổ lá sách, tủ sách kim loại, quầy thủ thư có máy tính,
# bàn dài trắng, ghế xanh, tủ gửi đồ bên phải, xe đẩy sách. Nhiều sinh viên ngồi học. Đi bằng W A S D,
# bấm E gần cửa (giữa phía dưới) để ra ngoài, xuất hiện lại trước cửa Tòa C.
#
# ĐĂNG KÝ: chỉ cần 1 dòng trong scripts/maps/registry.gd:
#     "res://scripts/maps/thu_vien.gd", # Thư viện (cửa Tòa C)
#
# Cùng cách làm với b42_lab.gd: begin()/finish()/active của feature.gd; phòng vẽ bằng một painter dùng script
# characters.gd nên nhân vật dùng đúng draw_person() của game.

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

# Sinh viên ngồi học. t: hàng*4 + cột bàn, side: 0 = ngồi phía trên bàn (quay xuống), 1 = ngồi phía dưới bàn (quay lên),
# slot: 0 trái / 1 phải, what: book | laptop | write | tablet
const STUDENTS := [
	{"t": 0, "side": 0, "slot": 0, "what": "laptop", "shirt": "1b2f6e", "hair": "1b1b1b", "uni": true, "long": false, "pack": false},
	{"t": 0, "side": 1, "slot": 1, "what": "write", "shirt": "9aa0a8", "hair": "1b1b1b", "uni": false, "long": true, "pack": true},
	{"t": 1, "side": 0, "slot": 1, "what": "book", "shirt": "1b2f6e", "hair": "3b2a1a", "uni": true, "long": false, "pack": false},
	{"t": 2, "side": 1, "slot": 0, "what": "book", "shirt": "e8dcc0", "hair": "1b1b1b", "uni": false, "long": false, "pack": true},
	{"t": 3, "side": 0, "slot": 0, "what": "laptop", "shirt": "2a2a2e", "hair": "1b1b1b", "uni": false, "long": false, "pack": false},
	{"t": 4, "side": 1, "slot": 0, "what": "laptop", "shirt": "1b2f6e", "hair": "5a3a22", "uni": true, "long": false, "pack": true},
	{"t": 5, "side": 0, "slot": 0, "what": "write", "shirt": "e8a0a8", "hair": "1b1b1b", "uni": false, "long": true, "pack": false},
	{"t": 6, "side": 0, "slot": 1, "what": "book", "shirt": "1b2f6e", "hair": "1b1b1b", "uni": true, "long": false, "pack": false},
	{"t": 7, "side": 1, "slot": 1, "what": "tablet", "shirt": "a89c92", "hair": "3b2a1a", "uni": false, "long": true, "pack": true},
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

var inside := false
var _layer: CanvasLayer
var _painter: Node2D
var _pos := START_POS
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải (giống game.facing)
var _anim := 0.0
var _clock := 0.0
var _fade := 0.0
var _closing := false
var _seats: Array = []        # mọi ghế: {pos, x, top, side, who (chỉ số sinh viên hoặc -1)}
var _solid: Array = []        # vật cản trong phòng

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
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong phòng

func finish() -> void:
	super()
	inside = false
	_closing = false
	_layer.visible = false
	game.hud.visible = true

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.physical_keycode != KEY_E:
		return
	if inside:
		if not _closing and _pos.distance_to(DOOR_POS) < 24.0:
			_closing = true   # mờ dần rồi ra ngoài (xem _process)
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and _near_door_outside():
		begin()
		get_viewport().set_input_as_handled()

# ======================= TRONG PHÒNG: DI CHUYỂN =======================

func _process(delta: float) -> void:
	if not inside:
		return
	_clock += delta
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			finish()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		_walk(delta)
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
	if v == Vector2.ZERO:
		return
	v = v.normalized() * WALK_SPEED * delta
	if absf(v.x) > absf(v.y):
		_face = 2 if v.x < 0.0 else 3
	else:
		_face = 1 if v.y < 0.0 else 0
	_anim += delta
	var a := _pos + Vector2(v.x, 0.0)
	if _blocked(a):
		a = _pos
	var b := a + Vector2(0.0, v.y)
	if _blocked(b):
		b = a
	_pos = b

# cùng cách tính với game.blocked(): chân nhân vật là hộp 8x4
func _blocked(p: Vector2) -> bool:
	if p.x < 14.0 or p.x > VIEW.x - 14.0 or p.y < 64.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

# ======================= VẼ PHÒNG =======================

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, Color("23262e"))
	_paint_shell(p)
	var items: Array = []   # [khóa sắp xếp theo y, loại, dữ liệu]
	items.append([LIBRARIAN_FEET.y - 1.0, 0, null])
	items.append([COUNTER.end.y, 1, null])
	items.append([TROLLEY.end.y, 2, null])
	for i in TABLE_XS.size() * TABLE_TOPS.size():
		var top: float = TABLE_TOPS[i / TABLE_XS.size()]
		items.append([top - 1.0, 3, i])    # ghế + người ngồi phía trên bàn (vẽ trước bàn)
		items.append([top, 4, i])          # mặt bàn và đồ trên bàn
		items.append([top + 26.0, 5, i])   # ghế + người ngồi phía dưới bàn (vẽ sau bàn)
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
	_paint_prompt(p)
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
	for s in _seats:
		if s.t == i and s.who >= 0:
			_paint_item(p, s)

# Đồ học trên bàn trước mặt từng sinh viên
func _paint_item(p: Node2D, s: Dictionary) -> void:
	var st: Dictionary = STUDENTS[s.who]
	var top: float = s.top
	var x: float = s.x
	if s.side == 1:
		x += 10.0 if s.slot == 1 else -10.0   # người ngồi phía dưới che bàn nên đồ đặt lệch sang bên
	match st.what:
		"book":
			p.rc(x - 7, top + 1, 14, 7, Color("2b2b2b"))
			p.rc(x - 6, top + 2, 6, 5, Color("f6f3e8"))
			p.rc(x, top + 2, 6, 5, Color("f6f3e8"))
			p.rc(x - 1, top + 2, 1, 5, Color("9a9a90"))
			var flip: bool = int(_clock * 0.4 + float(s.x)) % 5 == 0   # thỉnh thoảng lật trang
			p.rc(x + 1, top + 3, 4 if not flip else 2, 1, Color("8a8a80"))
			p.rc(x + 1, top + 5, 4, 1, Color("8a8a80"))
		"laptop":
			if s.side == 0:   # người ngồi phía trên: thấy mặt lưng nắp máy
				p.rc(x - 7, top - 1, 14, 6, Color("8f98a2"))
				p.rc(x - 7, top - 1, 14, 1, Color("c3c9d0"))
				p.rc(x - 7, top + 5, 14, 3, Color("6f7782"))
			else:             # người ngồi phía dưới: thấy màn hình
				p.rc(x - 7, top, 14, 7, Color("2a2d36"))
				p.rc(x - 6, top + 1, 12, 5, Color("3b86e0"))
				var scroll: int = int(_clock * 3.0 + float(s.x)) % 3
				for l in 2:
					p.rc(x - 4, top + 2 + l * 2, 4 + ((l + scroll) % 3) * 2, 1, Color("d6eaff"))
		"write":
			p.rc(x - 7, top + 1, 14, 7, Color("f4f4ee"))
			p.rc(x - 7, top + 1, 14, 1, Color("d8d8d0"))
			for l in 3:
				p.rc(x - 5, top + 2 + l * 2, 6 + (l % 2) * 3, 1, Color("5a7fc0"))
			var pen: int = int(_clock * 2.0 + float(s.x)) % 3   # cây bút nhích nhẹ khi viết
			p.rc(x + 2 + pen, top + 4, 3, 1, Color("c0392b"))
		"tablet":
			p.rc(x - 5, top + 1, 10, 7, Color("23262e"))
			p.rc(x - 4, top + 2, 8, 5, Color("e8eef6"))
			p.rc(x - 3, top + 3, 5, 1, Color("5a7fc0"))
			p.rc(x - 3, top + 5, 3, 1, Color("5a7fc0"))
	# hộp bút hồng và điện thoại cho thêm sinh hoạt
	if s.slot == 0:
		p.rc(s.x - 13.0, top + 1.0, 6, 3, Color("f3a8c0"))

# Ghế + sinh viên ngồi ở phía trên (side 0) hoặc phía dưới (side 1) của bàn
func _paint_seats(p: Node2D, i: int, side: int) -> void:
	for s in _seats:
		if s.t != i or s.side != side:
			continue
		var sp: Vector2 = s.pos
		if side == 0:
			# lưng ghế phía sau người ngồi, người quay xuống bàn (mặt bàn vẽ sau che chân)
			p.rc(sp.x - 9, sp.y - 20, 18, 14, C_CHAIR_DK)
			p.rc(sp.x - 8, sp.y - 19, 16, 12, C_CHAIR)
			p.rc(sp.x - 8, sp.y - 19, 16, 2, C_CHAIR_HI)
			if s.who >= 0:
				var st: Dictionary = STUDENTS[s.who]
				p.draw_person(sp, Color(st.shirt), Color(st.hair), 0, 0.0, st.uni, st.long, false)
		else:
			# mặt ghế, người quay lưng về phía ta nhìn lên bàn, lưng ghế che phần hông
			p.rc(sp.x - 8, sp.y - 6, 16, 8, C_CHAIR_DK)
			p.rc(sp.x - 7, sp.y - 5, 14, 6, C_CHAIR)
			if s.who >= 0:
				var st2: Dictionary = STUDENTS[s.who]
				p.draw_person(sp, Color(st2.shirt), Color(st2.hair), 1, 0.0, st2.uni, st2.long, st2.pack)
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

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	if _pos.distance_to(DOOR_POS) < 24.0:
		p.ctext("[E] Ra ngoài", _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)
