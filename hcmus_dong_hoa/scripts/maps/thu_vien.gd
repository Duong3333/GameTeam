extends "res://scripts/features/feature.gd"
# TÒA THƯ VIỆN: một tầng, mặt tiền cổ điển (mái ngói, đầu hồi có biển THƯ VIỆN, hiên 4 cột, cửa sổ vòm có sách bên trong).
#
# Vị trí : khoảng trống phía bắc, giữa Tòa B và Tòa C (khối ở x 378-550, y 92-196), cửa quay xuống phía nam.
# Vào    : đứng trước cửa, bấm E. Module tự lo cả lúc vào, trong phòng và lúc ra.
#
# Phòng đọc (nhìn từ trên xuống, đặt cửa ở giữa cạnh dưới, gốc O ở cửa, x sang phải, y đi lên):
#   - phía trên: 8 kệ sách dài đứng song song (dọc trục Oy), xếp thành hàng ngang, lối đi giữa các kệ, thảm xanh dẫn từ cửa lên
#   - dưới kệ: 4 bàn dài nằm ngang (dọc trục Ox) xếp 2 hàng, hai bên tường có 4 bàn lẻ
#   - bên phải cửa: quầy nhỏ của cô thủ thư (có máy tính, chồng sách, đèn) và xe đẩy sách
#   - bên trái cửa: tủ 12 ô trống để gửi cặp (một số ô đã có cặp của người khác)
# Tương tác: W A S D đi lại.
#   - E gần NPC: trò chuyện (cô thủ thư nói khác đi tùy bạn đã gửi cặp chưa)
#   - E ở trước tủ: gửi cặp vào ô trống đầu tiên / lấy cặp ra (khi gửi, nhân vật không còn đeo ba lô)
#   - E ở cuối lối đi (cửa): ra ngoài. Nếu quên lấy cặp thì cặp tự trả lại khi ra.
#   - Sinh viên NPC ngồi đọc sách yên lặng, đứng yên.
#
# ĐĂNG KÝ: chỉ cần thêm 1 dòng vào cuối danh sách trong scripts/maps/registry.gd:
#     "res://scripts/maps/thu_vien.gd", # Tòa thư viện
#
# Dùng lại của game (không sửa file lõi):
#   game.BUILDINGS   thêm tòa mới: va chạm, minimap, dòng tên khu vực và việc cây ngẫu nhiên tránh tòa đều tự nhận
#   game.rc/ctext/draw_person/draw_speech/shadow   hàm vẽ có sẵn (painter dùng script characters.gd như b42_lab.gd)
#   begin()/finish()/active của feature.gd         active = true thì người chơi ngoài trời đứng yên
#   draw_front_layer()                              vẽ mặt tiền ngoài trời và khung chỉ dẫn "Bấm [E] để vào"

const RECT := Rect2(378, 92, 172, 104)   # khối tòa nhà (cũng là vùng va chạm); y 92-196, cách Tòa C (y 240) 44 px
const DOOR_RANGE := 28.0                 # đứng cách cửa tối đa bấm E mới vào được (px)

# ---------- Bên trong: khung 480x270 như màn hình game ----------
const VIEW := Vector2(480, 270)
const WALL_H := 40.0                     # chân tường sau (sàn bắt đầu từ y = 40)
const START_POS := Vector2(241, 244)     # chỗ xuất hiện khi vừa vào (ngay trong cửa)
const EXIT_ZONE := Rect2(212, 246, 56, 24)       # đứng đây bấm E để ra ngoài
const LOCKER_BOX := Rect2(48, 202, 140, 38)      # tủ gửi cặp bên trái cửa (6 cột x 2 hàng = 12 ô)
const LOCKER_ZONE := Rect2(44, 244, 148, 16)     # đứng phía trước tủ để gửi / lấy cặp
const COUNTER_BOX := Rect2(292, 212, 104, 22)    # quầy cô thủ thư bên phải cửa
const CART_BOX := Rect2(404, 214, 34, 22)        # xe đẩy sách
const LIBRARIAN_FEET := Vector2(330, 224)        # cô thủ thư đứng sau quầy
const WALK_SPEED := 70.0
const TALK_RANGE := 30.0
const SAY_TIME := 3.2
const TOAST_TIME := 2.2
const SHELF_Y := 44.0
const SHELF_W := 18.0
const SHELF_H := 72.0
const SHELF_XS := [36.0, 92.0, 148.0, 204.0, 260.0, 316.0, 372.0, 428.0]   # đối xứng qua x = 241, lối đi giữa rộng 38
const SHELF_LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H"]
# bàn dài: [x, y, rộng], mặt bàn cao 14. Người ngồi phía bắc (sau bàn) hoặc phía nam (trước bàn)
const TABLES := [[72, 136, 120], [290, 136, 120], [72, 172, 120], [290, 172, 120]]
# bàn lẻ sát tường: [x, y], rộng 22, cao 14. Bàn bên trái có ghế phía đông, bàn bên phải có ghế phía tây
const WALL_TABLES := [[14, 138], [14, 168], [444, 138], [444, 168]]
const PLANTS := [Vector2(21, 76), Vector2(459, 76)]
const BOOK_COLORS := [Color("c0392b"), Color("2980b9"), Color("27ae60"), Color("f1c40f"), Color("8e44ad"), Color("e67e22"), Color("ecf0f1"), Color("16a085")]
const BAG_BLUE := Color("2f6bd0")

const C_WALL := Color("ecdcb4")
const C_WALL_DK := Color("d4c59c")
const C_STONE := Color("b8ad98")
const C_STONE_HI := Color("d4cab6")
const C_ROOF := Color("8c3f2e")
const C_ROOF_DK := Color("6f2f22")
const C_ROOF_HI := Color("b25a42")
const C_PEDIMENT := Color("f4ead0")
const C_NAVY := Color("1f2f5a")
const C_COLUMN := Color("f4f4ee")
const C_COLUMN_DK := Color("d8d4c8")
const C_BROWN := Color("5a3a1e")
const C_WOOD := Color("8a5a2a")
const C_WOOD_LT := Color("d9a05a")
const C_GLASS := Color("9fd3f0")
const C_DOOR := Color("7a4f28")
const C_CREAM := Color("fff6e0")
const C_FRAME := Color("2e2f2b")
const C_GOLD := Color("ffd86a")

var inside := false
var _layer: CanvasLayer
var _painter: Node2D          # Node2D dùng script vẽ của game (characters.gd) để vẽ phòng đọc
var _pos := START_POS         # vị trí nhân vật trong phòng (bàn chân)
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải
var _anim := 0.0
var _fade := 0.0
var _closing := false
var _banner := 0.0            # thời gian còn lại của biển "THƯ VIỆN" khi mới vào
var _say := ""
var _say_t := 0.0
var _say_i := -1
var _toast := ""              # dòng báo ngắn trên đầu người chơi (gửi / lấy cặp)
var _toast_t := 0.0
var _slot_cols: Array = []    # 12 ô tủ: Color nếu có cặp, null nếu trống
var _bag_slot := -1           # ô đang chứa cặp của người chơi, -1 nếu đang đeo
var _npcs: Array = []         # cô thủ thư + sinh viên ngồi đọc sách
var _solid: Array = []        # vật cản trong phòng

func _ready() -> void:
	# Đăng ký trước setup_collision(): va chạm, minimap, tên khu vực tự nhận tòa mới; cây ngẫu nhiên tránh tòa.
	game.BUILDINGS.append(["THƯ VIỆN", RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y, C_WALL, C_ROOF, "Thư viện - yên lặng, gửi cặp ở tủ bên trái cửa."])
	_build_room()
	_reset_lockers()
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

func _door_pos() -> Vector2:
	return Vector2(RECT.get_center().x, RECT.end.y + 7.0)

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_pos()) < DOOR_RANGE

# ======================= DỰNG PHÒNG =======================

func _build_room() -> void:
	_solid.clear()
	_npcs.clear()
	for sx in SHELF_XS:
		_solid.append(Rect2(sx - 2.0, SHELF_Y - 2.0, SHELF_W + 4.0, SHELF_H + 6.0))
	for tb in TABLES:
		_solid.append(Rect2(tb[0] - 2.0, tb[1] - 6.0, tb[2] + 4.0, 34.0))
	for wt in WALL_TABLES:
		if wt[0] < 100:
			_solid.append(Rect2(wt[0] - 2.0, wt[1] - 4.0, 46.0, 24.0))   # bàn + ghế phía đông
		else:
			_solid.append(Rect2(wt[0] - 22.0, wt[1] - 4.0, 46.0, 24.0))  # bàn + ghế phía tây
	for pc in PLANTS:
		_solid.append(Rect2(pc.x - 7.0, pc.y, 14.0, 9.0))
	_solid.append(LOCKER_BOX)
	_solid.append(COUNTER_BOX)
	_solid.append(CART_BOX)
	_npcs.append(_npc("librarian", LIBRARIAN_FEET, 0, Color("2f5f6a"), Color("5a5a66"), false, -1, []))
	_npcs.append(_seat_long(0, "n", 0.25, Color("3d5a80"), Color("1b1b1b"), false, [
		"Suỵt... đang đọc dở chương cuối.",
		"Cuốn này hay lắm, bạn thử đi."]))
	_npcs.append(_seat_long(0, "s", 0.7, Color("e07a5f"), Color("2a1d14"), true, [
		"Mai thi giải tích, đừng ồn nha.",
		"Kệ C có nhiều sách lập trình."]))
	_npcs.append(_seat_long(1, "n", 0.5, Color("81b29a"), Color("5a3a22"), false, [
		"Ở đây yên tĩnh dễ học hơn nhà.",
		"Mình mượn cuốn này ba tuần rồi."]))
	_npcs.append(_seat_long(1, "s", 0.3, Color("f2cc8f"), Color("1b1b1b"), true, [
		"Mình đang tìm tài liệu làm đồ án.",
		"Sách hiếm nằm ở kệ cuối cùng."]))
	_npcs.append(_seat_long(2, "s", 0.45, Color("3d5a80"), Color("1b1b1b"), false, [
		"Bạn nói nhỏ thôi, suỵt.",
		"Đọc xong mình sẽ xếp sách về kệ."]))
	_npcs.append(_seat_long(3, "n", 0.65, Color("e07a5f"), Color("2a1d14"), true, [
		"Chỗ này có ổ điện, tiện sạc máy.",
		"Cô thủ thư hiền nhưng nghiêm lắm."]))
	_npcs.append(_seat_wall(0, Color("81b29a"), Color("5a3a22"), false, [
		"Mình thích ngồi sát tường cho đỡ ồn.",
		"Suỵt... đang đến đoạn gay cấn."]))
	_npcs.append(_seat_wall(3, Color("f2cc8f"), Color("1b1b1b"), true, [
		"Góc này yên nhất cả thư viện.",
		"Mình ngồi đây từ sáng rồi."]))

func _npc(kind: String, pos: Vector2, face: int, shirt: Color, hair: Color, lh: bool, table: int, lines: Array) -> Dictionary:
	return {"kind": kind, "pos": pos, "face": face, "shirt": shirt, "hair": hair, "long": lh, "table": table, "lines": lines, "idx": 0}

# người ngồi ở bàn dài: side "n" ngồi sau bàn (nhìn về phía mình), "s" ngồi trước bàn (quay lưng về phía mình)
func _seat_long(table_i: int, side: String, frac: float, shirt: Color, hair: Color, lh: bool, lines: Array) -> Dictionary:
	var tb: Array = TABLES[table_i]
	var x := float(tb[0]) + float(tb[2]) * frac
	var y := float(tb[1])
	if side == "n":
		return _npc("sit_n", Vector2(x, y + 8.0), 0, shirt, hair, lh, table_i, lines)
	return _npc("sit_s", Vector2(x, y + 28.0), 1, shirt, hair, lh, table_i, lines)

# người ngồi ở bàn lẻ sát tường, quay mặt vào bàn
func _seat_wall(wall_i: int, shirt: Color, hair: Color, lh: bool, lines: Array) -> Dictionary:
	var wt: Array = WALL_TABLES[wall_i]
	if float(wt[0]) < 100.0:
		return _npc("sit_l", _chair_feet(wall_i), 2, shirt, hair, lh, wall_i, lines)
	return _npc("sit_r", _chair_feet(wall_i), 3, shirt, hair, lh, wall_i, lines)

func _chair_feet(wall_i: int) -> Vector2:
	var wt: Array = WALL_TABLES[wall_i]
	if float(wt[0]) < 100.0:
		return Vector2(float(wt[0]) + 33.0, float(wt[1]) + 12.0)
	return Vector2(float(wt[0]) - 11.0, float(wt[1]) + 12.0)

func _reset_lockers() -> void:
	_slot_cols = [Color("d9534f"), null, null, Color("f0ad4e"), Color("5cb85c"), null, null, Color("9b59b6"), null, null, Color("e67e22"), null]
	_bag_slot = -1

# ======================= VÀO / RA / TƯƠNG TÁC =======================

func begin() -> void:
	super()
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_banner = 2.5
	_say_t = 0.0
	_toast_t = 0.0
	_reset_lockers()
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong phòng

func finish() -> void:
	super()
	inside = false
	_closing = false
	_say_t = 0.0
	_toast_t = 0.0
	_reset_lockers()           # quên lấy cặp thì cặp tự trả lại
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
		_interact()
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and _near_door_outside():
		begin()
		get_viewport().set_input_as_handled()

# ưu tiên: lối ra, tủ gửi cặp, rồi mới tới trò chuyện với NPC
func _interact() -> void:
	if EXIT_ZONE.has_point(_pos):
		_closing = true   # mờ dần rồi ra ngoài (xem _process)
	elif LOCKER_ZONE.has_point(_pos):
		_use_locker()
	else:
		var i := _npc_near()
		if i >= 0:
			_talk(i)

func _use_locker() -> void:
	if _bag_slot >= 0:
		_slot_cols[_bag_slot] = null
		_bag_slot = -1
		_show_toast("Đã lấy cặp ra khỏi tủ.")
		return
	var slot := -1
	for i in _slot_cols.size():
		if _slot_cols[i] == null:
			slot = i
			break
	if slot < 0:
		_show_toast("Tủ đầy rồi!")
		return
	_slot_cols[slot] = BAG_BLUE
	_bag_slot = slot
	_show_toast("Đã gửi cặp vào ô " + str(slot + 1) + ".")

func _show_toast(text: String) -> void:
	_toast = text
	_toast_t = TOAST_TIME

# ======================= TRONG PHÒNG: DI CHUYỂN, TRÒ CHUYỆN =======================

func _process(delta: float) -> void:
	if not inside:
		return
	_say_t = maxf(_say_t - delta, 0.0)
	_toast_t = maxf(_toast_t - delta, 0.0)
	_banner = maxf(_banner - delta, 0.0)
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

# vùng đi được: sàn phòng đọc + lối ra ở giữa đáy
func _walkable(pt: Vector2) -> bool:
	if pt.x >= 18.0 and pt.x <= 462.0 and pt.y >= 50.0 and pt.y <= 258.0:
		return true
	if pt.x >= 214.0 and pt.x <= 266.0 and pt.y > 258.0 and pt.y <= 268.0:
		return true
	return false

# cùng cách tính với game.blocked(): chân nhân vật là hộp 8x4
func _blocked(p: Vector2) -> bool:
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for pt in [hit.position, Vector2(hit.end.x, hit.position.y), Vector2(hit.position.x, hit.end.y), hit.end]:
		if not _walkable(pt):
			return true
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

func _npc_near() -> int:
	var best := -1
	var bd := TALK_RANGE
	for i in _npcs.size():
		var c: Vector2 = _npcs[i].pos + Vector2(0, -8)
		var d := _pos.distance_to(c)
		if d < bd:
			bd = d
			best = i
	return best

# cô thủ thư nói khác đi tùy bạn đã gửi cặp chưa; sinh viên có câu riêng
func _lines_for(n: Dictionary) -> Array:
	if str(n.kind) == "librarian":
		if _bag_slot >= 0:
			return ["Ngoan lắm, cặp gửi gọn rồi đó.", "Đọc xong nhớ xếp sách về kệ nha.", "Giữ yên lặng giúp cô nhé."]
		return ["Em gửi cặp vào tủ bên trái nhé.", "Cặp để ở tủ, đừng mang vào đọc.", "Tủ không có khóa, em cứ yên tâm."]
	return n.lines

func _talk(i: int) -> void:
	var n: Dictionary = _npcs[i]
	var lines: Array = _lines_for(n)
	_say = str(lines[int(n.idx) % lines.size()])
	n["idx"] = int(n.idx) + 1
	_say_i = i
	_say_t = SAY_TIME

# ======================= VẼ PHÒNG ĐỌC =======================

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, C_FRAME)
	_paint_floor(p)
	_paint_wall(p)
	for i in SHELF_XS.size():
		_paint_shelf(p, float(SHELF_XS[i]), i)
	# vật đứng: sắp theo chân / đáy để người đi trước hoặc sau bàn, quầy, tủ
	var items: Array = []
	for i in TABLES.size():
		items.append([float(TABLES[i][1]) + 14.0, 0, i])
	for i in WALL_TABLES.size():
		items.append([float(WALL_TABLES[i][1]) + 14.0, 1, i])
	for i in _npcs.size():
		items.append([float(_npcs[i].pos.y), 2, i])
	for pc in PLANTS:
		items.append([pc.y + 9.0, 3, pc])
	items.append([COUNTER_BOX.end.y, 4, null])
	items.append([CART_BOX.end.y, 5, null])
	items.append([LOCKER_BOX.end.y, 6, null])
	items.append([_pos.y, 7, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				_paint_long_table(p, it[2])
			1:
				_paint_wall_table(p, it[2])
			2:
				_paint_npc(p, _npcs[it[2]])
			3:
				_paint_plant(p, it[2])
			4:
				_paint_counter(p)
			5:
				_paint_cart(p)
			6:
				_paint_locker(p)
			7:
				_paint_player(p)
	if _say_t > 0.0 and _say_i >= 0 and _say_i < _npcs.size():
		var s: Dictionary = _npcs[_say_i]
		p.draw_speech({"pos": s.pos, "say": _say})
	if _toast_t > 0.0:
		p.draw_speech({"pos": _pos, "say": _toast})
	_paint_prompt(p)
	_paint_banner(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# chữ canh giữa có bề rộng đo theo chữ thật (ctext cắt chữ nếu bề rộng nhỏ hơn chữ)
func _ctext_fit(p: Node2D, text: String, cx: float, y: float, size: int, col: Color) -> void:
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 6.0
	p.ctext(text, cx - w / 2.0, y, w, size, col)

# Sàn ván gỗ, thảm xanh viền vàng dẫn từ cửa lên giữa hai hàng kệ, ánh sáng ngoài trời ở cửa
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
	p.rc(224, 48, 34, 212, Color("d4a93a"))     # thảm: viền vàng
	p.rc(226, 48, 30, 212, Color("2f5d4c"))
	p.rc(230, 48, 22, 212, Color("3f6b5a"))
	p.rc(0, 260, VIEW.x, 10, C_FRAME)
	p.rc(207, 256, 3, 14, C_FRAME)               # khung cửa và ánh sáng ngoài trời
	p.rc(270, 256, 3, 14, C_FRAME)
	p.rc(210, 258, 60, 12, Color("cfdde8"))
	p.rc(214, 262, 52, 8, Color("eef6fb"))

# Tường sau: 4 cửa sổ nhìn ra sân, đồng hồ, biển THƯ VIỆN và biển IM LẶNG
func _paint_wall(p: Node2D) -> void:
	p.rc(8, 8, 464, WALL_H - 8.0, Color("efe4c8"))
	p.rc(8, 8, 464, 3, Color(0, 0, 0, 0.12))
	p.rc(8, 28, 464, 12, Color("3f6b5a"))
	p.rc(8, 28, 464, 2, Color("5a8b78"))
	p.rc(8, WALL_H - 2.0, 464, 2, Color("2a4a3d"))
	for wx in [56.0, 116.0, 326.0, 386.0]:
		_paint_window(p, wx)
	p.draw_circle(Vector2(241, 22), 11.0, C_BROWN)      # đồng hồ treo giữa tường
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
	p.rc(x + 3, 28, 14, 8, Color("4f9c4a"))     # ngọn cây ngoài sân
	p.rc(x + 24, 26, 14, 10, Color("3f8a3f"))
	p.rc(x + 19, 12, 2, 24, C_BROWN)
	p.rc(x, 22, 40, 2, C_BROWN)

# Kệ sách nhìn từ trên xuống: khung gỗ dài theo trục Oy, hai hàng gáy sách, biển chữ cái ở đầu phía nam
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
	# mỗi người ngồi có một cuốn sách đang mở trước mặt; bàn trống để chồng sách nhỏ
	var any := false
	for n in _npcs:
		if (str(n.kind) == "sit_n" or str(n.kind) == "sit_s") and int(n.table) == idx:
			any = true
			_paint_book(p, float(n.pos.x) - 5.0, y + (3.0 if str(n.kind) == "sit_n" else 7.0))
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
	for n in _npcs:
		if (str(n.kind) == "sit_l" or str(n.kind) == "sit_r") and int(n.table) == idx:
			seated = true
	if seated:
		_paint_book(p, x + 6.0, y + 4.0)
	else:
		_paint_book_stack(p, x + 6.0, y + 4.0)
	# ghế: tấm ngồi che chân người ngồi
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

func _paint_npc(p: Node2D, n: Dictionary) -> void:
	var pos: Vector2 = n.pos
	p.draw_person(pos, n.shirt, n.hair, n.face, 0.0, false, n.long, false)
	var kind: String = n.kind
	if kind == "sit_s":
		p.rc(pos.x - 7, pos.y - 7, 14, 7, C_DOOR)    # ghế che chân
		p.rc(pos.x - 7, pos.y - 7, 14, 1, Color("a8703c"))
	elif kind == "librarian":
		var by := pos.y
		p.rc(pos.x - 3, by - 26, 6, 4, n.hair)       # búi tóc
		p.rc(pos.x - 4, by - 18, 4, 1, Color("2a2a2a"))   # kính: hai gọng vuông + sống kính
		p.rc(pos.x - 4, by - 15, 4, 1, Color("2a2a2a"))
		p.rc(pos.x - 4, by - 18, 1, 4, Color("2a2a2a"))
		p.rc(pos.x - 1, by - 18, 1, 4, Color("2a2a2a"))
		p.rc(pos.x + 1, by - 18, 4, 1, Color("2a2a2a"))
		p.rc(pos.x + 1, by - 15, 4, 1, Color("2a2a2a"))
		p.rc(pos.x + 1, by - 18, 1, 4, Color("2a2a2a"))
		p.rc(pos.x + 4, by - 18, 1, 4, Color("2a2a2a"))
		p.rc(pos.x, by - 17, 1, 1, Color("2a2a2a"))
		if not (_say_t > 0.0 and _say_i == 0):
			_ctext_fit(p, "Cô thủ thư", pos.x, pos.y - 30.0, 7, Color("ffe9a8"))

# Quầy cô thủ thư: mặt quầy, thân quầy, máy tính, chồng sách, đèn bàn, biển MƯỢN - TRẢ
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
	p.rc(x + 10, y - 7, 12, 8, Color("2a2c33"))      # máy tính
	p.rc(x + 11, y - 6, 10, 5, Color("5b8de8"))
	p.rc(x + 14, y + 1, 4, 2, Color("2a2c33"))
	_paint_book_stack(p, x + 60.0, y - 3.0)           # chồng sách chờ trả
	p.rc(x + 86, y - 2, 2, 3, Color("2a2c33"))        # đèn bàn xanh
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

# Tủ gửi cặp: 6 cột x 2 hàng ô trống, một số ô đã có cặp; cặp người chơi hiện ra khi gửi
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
	p.rc(sx + 7, sy + 2, 6, 2, Color("1a1a2e"))           # quai xách
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

# gửi cặp xong thì nhân vật không còn ba lô
func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, _bag_slot < 0)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _prompt_text() -> String:
	if EXIT_ZONE.has_point(_pos):
		return "[E] Ra ngoài"
	if LOCKER_ZONE.has_point(_pos):
		return "[E] Lấy cặp" if _bag_slot >= 0 else "[E] Gửi cặp"
	if _npc_near() >= 0:
		return "[E] Trò chuyện"
	return ""

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var text := _prompt_text()
	if text != "":
		_ctext_fit(p, text, _pos.x, _pos.y - 44.0, 8, Color.WHITE)

# Biển tên hiện vài giây ở góc trái dưới khi mới vào
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

# ======================= NGOÀI TRỜI =======================

func draw_front_layer() -> void:
	if not game.view.intersects(RECT.grow(60.0)):
		return
	_paint_facade()
	_repaint_front_items()
	if inside or game.is_busy() or not _near_door_outside():
		return
	var text := "Bấm [E] để vào Thư viện"
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))

# Vẽ lại cây, đèn, ghế, NPC và người chơi đang đứng phía trước tòa để không bị mặt tiền che mất (giống b42_lab.gd)
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

# Mặt tiền (từ trên xuống): mái ngói, đầu hồi có sách và biển THƯ VIỆN, hiên 4 cột, cửa vòm, bậc thềm, hai cánh có cửa sổ vòm
func _paint_facade() -> void:
	var r := RECT
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var cx := x + w / 2.0
	# tường kem, chân đế đá
	game.rc(x, y + 20, w, 84, C_WALL)
	game.rc(x, y + 92, w, 12, C_STONE)
	game.rc(x, y + 92, w, 1, C_STONE_HI)
	# mái ngói đỏ
	game.rc(x - 3, y, w + 6, 22, C_ROOF)
	for i in 4:
		game.rc(x - 3, y + 4 + i * 5, w + 6, 1, C_ROOF_DK)
	game.rc(x - 3, y, w + 6, 2, C_ROOF_HI)
	game.rc(x, y + 22, w, 3, Color(0, 0, 0, 0.16))
	# hai cánh: mỗi bên hai cửa sổ vòm
	for wx in [x + 5.0, x + 23.0, x + w - 19.0, x + w - 37.0]:
		_paint_arch_window(wx, y + 46.0)
	# hiên giữa, đầu hồi, biển
	game.rc(cx - 44, y + 36, 88, 56, C_WALL_DK)
	game.draw_colored_polygon(PackedVector2Array([Vector2(cx - 46, y + 24), Vector2(cx, y - 10), Vector2(cx + 46, y + 24)]), C_ROOF)
	game.draw_colored_polygon(PackedVector2Array([Vector2(cx - 40, y + 22), Vector2(cx, y - 5), Vector2(cx + 40, y + 22)]), C_PEDIMENT)
	_paint_book_emblem(cx, y + 9.0)
	game.rc(cx - 46, y + 22, 92, 14, C_NAVY)
	game.rc(cx - 46, y + 22, 92, 1, Color("3a4f8a"))
	game.ctext("THƯ VIỆN", cx - 46, y + 33, 92, 9, C_GOLD)
	# bốn cột
	for off in [-42.0, -26.0, 20.0, 36.0]:
		_paint_column(cx + off, y + 36.0)
	# cửa chính hình vòm hai cánh
	game.rc(cx - 12, y + 52, 24, 40, C_BROWN)
	game.draw_circle(Vector2(cx, y + 52), 12.0, C_BROWN)
	game.draw_circle(Vector2(cx, y + 52), 9.0, C_GLASS)
	game.rc(cx - 10, y + 56, 9, 36, C_DOOR)
	game.rc(cx + 1, y + 56, 9, 36, C_DOOR)
	game.rc(cx - 8, y + 59, 5, 12, C_GLASS)
	game.rc(cx + 3, y + 59, 5, 12, C_GLASS)
	game.rc(cx - 3, y + 73, 1, 4, C_GOLD)
	game.rc(cx + 2, y + 73, 1, 4, C_GOLD)
	# bậc thềm và bồn hoa hai bên
	game.rc(cx - 28, y + 92, 56, 4, Color("cfc6b0"))
	game.rc(cx - 32, y + 96, 64, 4, Color("bdb39c"))
	game.rc(cx - 36, y + 100, 72, 4, Color("aaa08a"))
	for bx in [x + 4.0, x + w - 34.0]:
		game.rc(bx, y + 96, 30, 8, Color("3f9c45"))
		for i in 6:
			game.rc(bx + 3.0 + i * 5.0, y + 97.0 + (i % 2) * 3.0, 2, 2, Color("ffd23f") if i % 2 == 0 else Color("e07a5f"))
	game.draw_rect(r, Color("2b2b2b"), false, 1.0)

func _paint_column(x: float, y: float) -> void:
	game.rc(x, y, 6, 56, C_COLUMN)
	game.rc(x + 4, y, 2, 56, C_COLUMN_DK)
	game.rc(x - 1, y, 8, 3, C_CREAM)
	game.rc(x - 1, y + 53, 8, 3, C_COLUMN_DK)

# Cửa sổ vòm 14 rộng, bên trong thấy gáy sách xếp ở phần dưới
func _paint_arch_window(wx: float, wy: float) -> void:
	game.rc(wx - 1, wy + 6, 16, 36, C_BROWN)
	game.draw_circle(Vector2(wx + 7, wy + 6), 8.0, C_BROWN)
	game.rc(wx, wy + 6, 14, 34, C_GLASS)
	game.draw_circle(Vector2(wx + 7, wy + 6), 7.0, C_GLASS)
	game.rc(wx + 6, wy - 1, 2, 41, C_BROWN)
	game.rc(wx, wy + 18, 14, 2, C_BROWN)
	for i in 5:
		game.rc(wx + 1.0 + i * 2.5, wy + 28, 2, 12, BOOK_COLORS[(i * 3) % 8])
	game.rc(wx - 2, wy + 40, 18, 3, C_STONE)

# Cuốn sách mở màu vàng kem trong đầu hồi
func _paint_book_emblem(cx: float, y: float) -> void:
	game.rc(cx - 10, y - 1, 20, 12, C_DOOR)
	game.rc(cx - 9, y, 9, 10, C_CREAM)
	game.rc(cx, y, 9, 10, Color("f0e6c8"))
	game.rc(cx - 1, y - 1, 2, 12, C_BROWN)
	for i in 3:
		game.rc(cx - 7, y + 2.0 + i * 3.0, 5, 1, Color("9aa0a8"))
		game.rc(cx + 2, y + 2.0 + i * 3.0, 5, 1, Color("9aa0a8"))
