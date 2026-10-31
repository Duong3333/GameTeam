extends "res://scripts/features/feature.gd"
# TÒA B4.2 + PHÒNG LAB MÁY TÍNH (bên trong).
#
# Ngoài trời : tòa tháp kính xanh (lõi kính, 3 mảng tường trắng xám có cửa sổ nhỏ, đỉnh xám có biển "B4.2")
#              đặt ngay phía sau (phía bắc) Tòa E. Đứng trước cửa tòa nhà, bấm E để vào.
# Bên trong  : phòng lab có nhiều máy tính trên bàn, ghế để ngồi dùng máy, bảng trắng viết bút lông,
#              bàn giáo viên có máy tính và ghế, máy lạnh. Đi bằng W A S D, bấm E gần ghế để ngồi / đứng dậy,
#              bấm E gần cửa (góc phải phía dưới) để ra ngoài.
#
# Cách tích hợp (không sửa file nào khác): chép file này vào scripts/features/ rồi thêm 1 dòng vào registry.gd:
#     "res://scripts/features/toa_b42.gd",
# Nên đặt TRƯỚC dòng npc_nhan_vat.gd / day_night.gd / weather_system.gd để tòa nhà được vẽ trước NPC và mây.
#
# Dùng lại của game (không tạo hệ thống mới):
#   game.solids      va chạm: tòa B4.2 là 1 khối cứng như các tòa khác
#   game.BUILDINGS   bảng tòa nhà: minimap và dòng tên khu vực ở góc trái tự nhận tòa B4.2
#   game.rc/ctext/hedge/draw_person/draw_tree/draw_lamp/draw_bench   hàm vẽ có sẵn
#   draw_front_layer()  vẽ lên thế giới (như mọi feature); begin()/finish()/active của feature.gd
#                       (active = true thì người chơi ngoài trời đứng yên, giống lúc câu cá)
#   Nhân vật trong phòng lab được vẽ bằng chính draw_person() của game (cùng áo polo, cùng animation đi bộ).

# ---------- Tòa nhà ngoài trời ----------
const RECT := Rect2(722, 40, 116, 212)   # khối tòa nhà (cũng là vùng va chạm); nằm phía bắc Tòa E (E: x 712-817, y 278-564)
const DOOR_RANGE := 44.0                 # đứng cách cửa tối đa bấm E mới vào được (px)

# ---------- Phòng lab (khung 480x270 như màn hình game) ----------
const VIEW := Vector2(480, 270)
const WALL_H := 56.0                     # tường phía trên
const FLOOR_BOTTOM := 258.0              # mép dưới sàn
const DOOR_POS := Vector2(412, 252)      # điểm đứng để ra ngoài (cửa ở góc phải phía dưới)
const START_POS := Vector2(412, 240)     # chỗ xuất hiện khi vừa vào phòng
const WALK_SPEED := 70.0                 # giống người chơi ngoài trời
const SEAT_RANGE := 18.0                 # đứng cách chỗ ngồi tối đa bấm E mới ngồi được
const ROW_TOPS := [116.0, 162.0, 208.0]  # mép trên của 3 hàng bàn sinh viên
const DESK_XS := [110.0, 240.0, 370.0]   # tâm 3 bàn trong mỗi hàng
const DESK_W := 84.0
const PC_OFFSET := 21.0                  # mỗi bàn có 2 máy, lệch trái/phải so với tâm bàn
const TEACHER_DESK := Rect2(200, 66, 80, 14)

const C_FLOOR_A := Color("b4bdc7")
const C_FLOOR_B := Color("a8b2bd")
const C_WALL := Color("cfd8df")
const C_WOOD_TOP := Color("c19660")
const C_WOOD_FRONT := Color("8a6238")

var inside := false
var _layer: CanvasLayer
var _painter: Node2D          # Node2D dùng script vẽ của game (characters.gd) để vẽ nhân vật trong phòng
var _pos := START_POS         # vị trí nhân vật trong phòng (bàn chân)
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải (giống game.facing)
var _anim := 0.0
var _clock := 0.0
var _seated := -1             # chỉ số chỗ ngồi đang ngồi, -1 = đang đứng
var _fade := 0.0
var _closing := false
var _groups: Array = []       # mỗi nhóm: 1 bàn + các ghế/máy (3 hàng sinh viên + bàn giáo viên)
var _seats: Array = []
var _solid: Array = []        # vật cản trong phòng

func _ready() -> void:
	game.solids.append(RECT)
	# Đăng ký vào bảng BUILDINGS có sẵn: minimap và dòng tên khu vực ở góc trái tự nhận. Mặt tiền thật được vẽ đè lên trong draw_front_layer().
	game.BUILDINGS.append(["B4.2", RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y, Color("8e959f"), Color("1f4a8c"), "Tòa B4.2 - phòng Lab máy tính."])
	_build_room()
	_layer = CanvasLayer.new()
	_layer.layer = 5   # trên thế giới (kể cả mưa, ánh sáng), dưới các thanh HUD và sổ tay (6-8)
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint)

# ======================= DỰNG PHÒNG LAB =======================

func _build_room() -> void:
	_groups.clear()
	_seats.clear()
	_solid.clear()
	# bàn giáo viên (1 máy, 1 ghế). Ghế ở phía sau bàn (sát tường), đứng dậy thì bước ra bên trái bàn.
	_add_group(TEACHER_DESK, [240.0], true, Vector2(176, 78))
	# 3 hàng x 3 bàn x 2 máy = 18 máy tính sinh viên, mỗi máy 1 ghế
	for top in ROW_TOPS:
		for cx in DESK_XS:
			_add_group(Rect2(cx - DESK_W / 2.0, top, DESK_W, 14.0), [cx - PC_OFFSET, cx + PC_OFFSET], false, Vector2.ZERO)

func _add_group(desk: Rect2, xs: Array, teacher: bool, stand_override: Vector2) -> void:
	var gi := _groups.size()
	_groups.append({"id": gi, "desk": desk, "xs": xs, "teacher": teacher})
	_solid.append(desk)
	for x in xs:
		var top := desk.position.y
		if teacher:   # ghế giáo viên: phía sau (trên) bàn, quay mặt xuống
			_seats.append({"g": gi, "x": x, "top": top, "pos": Vector2(x, top + 4.0), "stand": stand_override, "face": 0})
			_solid.append(Rect2(x - 7.0, top - 14.0, 14.0, 18.0))
		else:         # ghế sinh viên: phía dưới bàn, quay mặt lên màn hình
			_seats.append({"g": gi, "x": x, "top": top, "pos": Vector2(x, top + 26.0), "stand": Vector2(x, top + 34.0), "face": 1})
			_solid.append(Rect2(x - 7.0, top + 16.0, 14.0, 11.0))   # ghế là vật cản (trừ khi đang ngồi)

# ======================= VÀO / RA =======================

func _door_outside() -> Vector2:
	return Vector2(RECT.get_center().x, RECT.end.y + 8.0)

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_outside()) < DOOR_RANGE

func begin() -> void:
	super()
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_seated = -1
	_fade = 1.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong phòng

func finish() -> void:
	super()
	inside = false
	_closing = false
	_seated = -1
	_layer.visible = false
	game.hud.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.physical_keycode != KEY_E:
		return
	if inside:
		if _closing:
			return
		if _seated >= 0:
			_stand_up()
		elif _pos.distance_to(DOOR_POS) < 24.0:
			_closing = true   # mờ dần rồi ra ngoài (xem _process)
		else:
			var s := _nearest_seat()
			if s >= 0:
				_sit(s)
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and _near_door_outside():
		begin()
		get_viewport().set_input_as_handled()

# ======================= TRONG PHÒNG: DI CHUYỂN, NGỒI =======================

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
		if _seated < 0:
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
	if p.x < 14.0 or p.x > VIEW.x - 14.0 or p.y < 62.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

func _nearest_seat() -> int:
	var best := -1
	var bd := SEAT_RANGE
	for i in _seats.size():
		var d: float = _pos.distance_to(_seats[i].stand)
		if d < bd:
			bd = d
			best = i
	return best

func _sit(i: int) -> void:
	_seated = i
	_pos = _seats[i].pos
	_face = _seats[i].face

func _stand_up() -> void:
	_pos = _seats[_seated].stand
	_face = 0
	_seated = -1

# ======================= VẼ PHÒNG LAB =======================

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, Color("23262e"))
	_paint_shell(p)
	var items: Array = []
	for g in _groups:
		items.append([g.desk.end.y, 0, g])
	if _seated < 0:
		items.append([_pos.y, 1, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[1] == 0:
			_paint_group(p, it[2])
		else:
			_paint_player(p)
	_paint_prompt(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# Tường, sàn, bảng, máy lạnh, cửa
func _paint_shell(p: Node2D) -> void:
	p.rc(0, 0, VIEW.x, WALL_H, C_WALL)
	p.rc(0, WALL_H - 4.0, VIEW.x, 4, C_WALL.darkened(0.15))   # chân tường
	p.rc(0, 0, VIEW.x, 3, C_WALL.lightened(0.2))
	for ty in range(int(WALL_H), int(FLOOR_BOTTOM), 16):
		for tx in range(0, int(VIEW.x), 16):
			p.rc(tx, ty, 16, 16, C_FLOOR_A if ((tx + ty) / 16) % 2 == 0 else C_FLOOR_B)
	p.rc(0, FLOOR_BOTTOM, VIEW.x, VIEW.y - FLOOR_BOTTOM, Color("5a5f6b"))
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 2, Color("3f434d"))
	p.rc(0, 0, 8, VIEW.y, Color("4a4f5b"))
	p.rc(VIEW.x - 8.0, 0, 8, VIEW.y, Color("4a4f5b"))
	_paint_board(p)
	_paint_aircon(p)
	# cửa ra (góc phải phía dưới)
	p.rc(394, FLOOR_BOTTOM, 36, 12, Color("2b2b2b"))
	p.rc(396, FLOOR_BOTTOM + 1.0, 32, 11, Color("8a5a32"))
	p.rc(410, FLOOR_BOTTOM + 1.0, 2, 11, Color("3a2412"))
	p.rc(424, FLOOR_BOTTOM + 5.0, 2, 2, Color("e8d28a"))

# Bảng trắng viết bút lông: khung bạc, chữ xanh, vài dòng chữ viết tay, khay bút và giẻ lau
func _paint_board(p: Node2D) -> void:
	p.rc(198, 6, 144, 38, Color("7d848d"))
	p.rc(200, 8, 140, 34, Color("f4f6f8"))
	p.rc(200, 8, 140, 2, Color("dfe4e8"))
	p.draw_string(p.font, Vector2(200, 21), "PHÒNG LAB B4.2", HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color("2457c5"))
	var inks := [Color("c0392b"), Color("1f7a3a"), Color("222222")]
	for line in 3:
		var yy := 26 + line * 5
		var ink: Color = inks[line]
		var n := 15 if line < 2 else 9
		for i in n:
			var w := 3 + ((i * 7 + line * 3) % 4)
			p.rc(208 + i * 8 + (line % 2) * 2, yy + (i % 2), w, 1, ink)
	p.rc(206, 38, 128, 3, Color("e8ecef"))   # vệt bút đã lau mờ
	p.rc(222, 42, 96, 3, Color("6a7078"))   # khay bút
	p.rc(228, 40, 9, 2, Color("2457c5"))
	p.rc(240, 40, 9, 2, Color("c0392b"))
	p.rc(252, 40, 9, 2, Color("222222"))
	p.rc(296, 39, 12, 4, Color("3a3f4a"))     # giẻ lau bảng
	p.rc(296, 39, 12, 1, Color("5a606c"))

# Máy lạnh treo tường, gió mát nhẹ thổi xuống
func _paint_aircon(p: Node2D) -> void:
	p.rc(356, 10, 58, 20, Color("b8bec6"))
	p.rc(357, 11, 56, 18, Color("eef1f4"))
	p.rc(357, 11, 56, 3, Color("ffffff"))
	p.rc(359, 22, 52, 4, Color("c9ced4"))
	for i in 9:
		p.rc(360 + i * 6, 23, 4, 1, Color("9aa1ab"))
	p.rc(402, 15, 4, 2, Color("46d07a"))
	p.rc(396, 15, 4, 2, Color("9aa1ab"))
	var f := int(_clock * 3.0) % 4
	for i in 4:
		p.rc(364 + i * 13, 31 + ((i + f) % 4) * 4, 2, 3, Color(0.75, 0.92, 1.0, 0.45))

func _paint_group(p: Node2D, g: Dictionary) -> void:
	var desk: Rect2 = g.desk
	var top := desk.position.y
	var xs: Array = g.xs
	var teacher: bool = g.teacher
	# ghế giáo viên nằm phía sau (trên) bàn nên vẽ trước
	if teacher:
		for x in xs:
			p.rc(x - 12, top - 21, 24, 18, Color("2b3550"))
			p.rc(x - 11, top - 20, 22, 16, Color("3d4d70"))
			p.rc(x - 11, top - 20, 22, 2, Color("56688f"))
			p.rc(x - 6, top - 4, 12, 6, Color("2f3b5a"))
			p.rc(x - 6, top - 4, 12, 2, Color("4b5d86"))
			p.rc(x - 1, top + 2, 2, 3, Color("1e2027"))
		if _seated >= 0 and _seats[_seated].g == g.id:
			_paint_player(p)
	# mặt bàn và thành bàn
	p.rc(desk.position.x - 1, top - 1, desk.size.x + 2, 16, Color("5c4126"))
	p.rc(desk.position.x, top, desk.size.x, 8, C_WOOD_TOP)
	p.rc(desk.position.x, top, desk.size.x, 1, C_WOOD_TOP.lightened(0.2))
	p.rc(desk.position.x, top + 8.0, desk.size.x, 6, C_WOOD_FRONT)
	p.rc(desk.position.x, top + 13.0, desk.size.x, 1, C_WOOD_FRONT.darkened(0.3))
	# máy tính: bàn giáo viên thấy màn hình, bàn sinh viên thấy mặt lưng màn hình (sinh viên ngồi phía dưới nhìn lên)
	for x in xs:
		_paint_computer(p, x, top, teacher)
	# ghế sinh viên ở phía dưới bàn (người ngồi vẽ trước, lưng ghế che phần lưng)
	if not teacher:
		if _seated >= 0 and _seats[_seated].g == g.id:
			_paint_player(p)
		for x in xs:
			p.rc(x - 1, top + 25, 2, 4, Color("1e2027"))
			p.rc(x - 5, top + 28, 10, 1, Color("1e2027"))
			p.rc(x - 7, top + 16, 14, 11, Color("2b3550"))
			p.rc(x - 6, top + 17, 12, 9, Color("3d4d70"))
			p.rc(x - 6, top + 17, 12, 2, Color("56688f"))

func _paint_computer(p: Node2D, x: float, top: float, big: bool) -> void:
	var hw := 11.0 if big else 9.0
	var hh := 13.0 if big else 11.0
	if not big:   # bàn sinh viên: mặt lưng màn hình + bàn phím, chuột phía người ngồi
		p.rc(x - hw, top - hh, hw * 2.0, hh + 3.0, Color("23262e"))
		p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, hh + 1.0, Color("3a3e48"))
		p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, 2, Color("565b68"))
		for i in 3:
			p.rc(x - 5.0, top - hh + 4.0 + i * 2.0, 10, 1, Color("2c3038"))
		p.rc(x + hw - 4.0, top - 2.0, 2, 1, Color("46d07a"))
		p.rc(x - 2, top + 2, 4, 2, Color("1e2027"))
		p.rc(x - hw + 1.0, top + 4.0, hw * 2.0 - 2.0, 3, Color("dde1e6"))
		for i in 5:
			p.rc(x - hw + 2.0 + i * 3.0, top + 5.0, 2, 1, Color("8d949c"))
		p.rc(x + hw + 2.0, top + 5.0, 3, 2, Color("f2f2f2"))
		return
	p.rc(x - hw, top - hh, hw * 2.0, hh + 3.0, Color("2a2d36"))
	p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, hh - 2.0, Color("3b86e0"))
	p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, 2, Color("6aa8f0"))
	var scroll := int(_clock * 3.0 + x) % 4
	for i in 3:
		p.rc(x - hw + 3.0, top - hh + 4.0 + i * 2.0, 5.0 + ((i + scroll) % 3) * 3.0, 1, Color("d6eaff"))
	p.rc(x - 2, top + 2, 4, 2, Color("1e2027"))
	p.rc(x - hw + 1.0, top + 4.0, hw * 2.0 - 2.0, 3, Color("dde1e6"))
	for i in 5:
		p.rc(x - hw + 2.0 + i * 3.0, top + 5.0, 2, 1, Color("8d949c"))
	p.rc(x + hw + 2.0, top + 5.0, 3, 2, Color("f2f2f2"))

# Nhân vật dùng đúng hàm draw_person() của game (áo polo trường, animation đi bộ)
func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var text := ""
	if _seated >= 0:
		text = "[E] Đứng dậy"
	elif _pos.distance_to(DOOR_POS) < 24.0:
		text = "[E] Ra ngoài"
	elif _nearest_seat() >= 0:
		text = "[E] Ngồi vào máy"
	if text != "":
		p.ctext(text, _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)

# ======================= VẼ TÒA NHÀ NGOÀI TRỜI =======================

# Vẽ sau khi game đã vẽ cây/người. Để nhân vật và cây đứng TRƯỚC tòa nhà không bị mặt tiền đè lên,
# ta vẽ lại chúng (cùng hàm vẽ của game) ngay sau mặt tiền.
func draw_front_layer() -> void:
	if not game.view.intersects(RECT.grow(60.0)):
		return
	_paint_facade()
	_repaint_front_items()
	if not inside and not game.is_busy() and _near_door_outside():
		# khung chỉ dẫn phía trên đầu người chơi: "Bấm E để vào tòa B4.2"
		var text := "Bấm [E] để vào tòa B4.2"
		var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
		var px: float = game.player.x
		var py: float = game.player.y - 46.0
		game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
		game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
		game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))

func _repaint_front_items() -> void:
	var area := Rect2(RECT.position.x - 40.0, RECT.end.y - 4.0, RECT.size.x + 80.0, 80.0)
	var items: Array = []
	for t in game.trees:
		if area.has_point(Vector2(t[0], t[1])):
			items.append([float(t[1]), 0, t])
	for l in game.lamps:
		if area.has_point(l):
			items.append([l.y, 1, l])
	for b in game.benches:
		if area.has_point(b):
			items.append([b.y, 2, b])
	for o in game.npcs:
		if not o.has("role") and area.has_point(o.pos):
			items.append([o.pos.y, 3, o])
	if area.has_point(game.player):
		items.append([game.player.y, 4, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				game.draw_tree(it[2])
			1:
				game.draw_lamp(it[2])
			2:
				game.draw_bench(it[2])
			3:
				var o: Dictionary = it[2]
				game.draw_person(o.pos, o.shirt, o.hair, o.face, o.anim, o.uni, o.long, o.pack)
				if o.say_t > 0.0:
					game.draw_speech(o)
			4:
				game.draw_person(game.player, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
				game.ctext("Bạn", game.player.x - 15.0, game.player.y - 28.0, 30, 8, Color("ffd23f"))

# Mặt tiền: lõi kính xanh cao, 3 mảng tường trắng xám có cửa sổ nhỏ chìa ra phía trước, đỉnh xám có biển B4.2
func _paint_facade() -> void:
	var r := RECT
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var end_y := r.end.y
	var cx := x + w / 2.0
	var frame := Color("8e959f")
	var frame_dark := Color("5f6671")
	var panel := Color("d4d8dd")
	var panel_shade := Color("9aa1ab")
	game.rc(x, y, w, r.size.y, frame)
	# đỉnh tòa: gờ xám, bậc cao ở góc phải mang biển "B4.2"
	game.rc(x, y, w, 4, frame.lightened(0.25))
	game.rc(x + w - 52, y - 4, 40, 4, frame)
	game.rc(x + w - 46, y - 8, 28, 4, frame)
	game.rc(x + w - 44, y - 6, 24, 8, Color("eef1f4"))
	game.ctext("B4.2", x + w - 44, y + 1, 24, 8, Color("1f4aa8"))
	# lõi kính xanh
	var gx := x + 12.0
	var gw := w - 24.0
	var gy := y + 12.0
	var gh := r.size.y - 12.0 - 30.0
	var bands := 8
	for i in bands:
		var t := float(i) / (bands - 1)
		var c := Color("4a86d0").lerp(Color("14305f"), t)
		game.rc(gx, gy + gh * i / bands, gw, ceilf(gh / bands) + 1.0, c)
	for i in range(1, int(gw / 11.0) + 1):
		game.rc(gx + i * 11.0, gy, 1, gh, Color("14305f"))
	for j in range(0, int(gh / 12.0) + 1):
		game.rc(gx, gy + j * 12.0, gw, 1, Color("6fa3e6", 0.55))
	for k in 5:   # ánh phản chiếu trời trên kính
		game.rc(gx + 6.0 + k * 17.0, gy + 8.0 + k * 22.0, 14, 2, Color(1, 1, 1, 0.18))
	game.rc(cx - 3, gy, 6, gh, frame_dark)   # dải tường xám giữa lõi kính
	game.rc(cx - 3, gy, 1, gh, frame_dark.lightened(0.2))
	# 3 mảng tường trắng xám có cửa sổ nhỏ (trái thấp, giữa cao, phải trung bình)
	_paint_fin(x + 2.0, y + 74.0, 28.0, end_y - 30.0, panel, panel_shade)
	_paint_fin(cx - 14.0, y + 38.0, 28.0, end_y - 30.0, panel, panel_shade)
	_paint_fin(x + w - 30.0, y + 58.0, 28.0, end_y - 30.0, panel, panel_shade)
	# tầng trệt: tường xám, cửa sổ tối, lối vào kính
	game.rc(x, end_y - 30, w, 30, frame)
	game.rc(x, end_y - 30, w, 2, frame.lightened(0.2))
	game.rc(x, end_y - 8, w, 8, frame_dark)
	for wx in [x + 8.0, x + 30.0, x + w - 52.0, x + w - 30.0]:
		game.rc(wx, end_y - 25, 20, 14, Color("1a2f55"))
		game.rc(wx + 1, end_y - 24, 18, 12, Color("3f6fb0"))
		game.rc(wx + 1, end_y - 24, 18, 3, Color("7fb0e6"))
		game.rc(wx + 9, end_y - 24, 1, 12, Color("1a2f55"))
	game.hedge(x - 2, end_y, w + 4)
	game.rc(cx - 12, end_y - 22, 24, 22, Color("3a2f2a"))
	game.rc(cx - 10, end_y - 20, 9, 20, Color("9fd3f0"))
	game.rc(cx + 1, end_y - 20, 9, 20, Color("9fd3f0"))
	game.rc(cx - 14, end_y - 26, 28, 5, frame_dark)
	for i in 3:
		game.rc(cx - 14 + i * 2, end_y + 7 + i * 2, 28 - i * 4, 2, Color("bdbdbd") if i % 2 == 0 else Color("a5a5a5"))
	game.draw_rect(r, Color("2b2b2b"), false, 1.0)

func _paint_fin(fx: float, fy: float, fw: float, bottom: float, panel: Color, shade: Color) -> void:
	var fh := bottom - fy
	game.rc(fx + fw, fy + 4, 5, fh, Color(0, 0, 0, 0.25))   # bóng đổ lên kính bên cạnh
	game.rc(fx - 1, fy - 3, fw + 2, 3, panel.lightened(0.2))
	game.rc(fx, fy, fw, fh, panel)
	game.rc(fx + fw - 5, fy, 5, fh, shade)
	game.rc(fx, fy, 2, fh, panel.lightened(0.12))
	var yy := fy + 7.0
	while yy + 8.0 < bottom:
		for wx in [fx + 4.0, fx + 14.0]:
			game.rc(wx, yy, 9, 7, Color("f0f0f0"))
			game.rc(wx + 1, yy + 1, 7, 5, Color("3a5f94"))
			game.rc(wx + 1, yy + 1, 7, 1, Color("7ca3d6"))
		yy += 12.0
