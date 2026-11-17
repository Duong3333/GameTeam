extends "res://scripts/features/feature.gd"
# TÒA CĂN TIN: căn tin nhỏ trệt + 2 lầu, mặt tiền cam kem, mái hiên sọc, bên ngoài treo nhãn dán gà rán,
# mì Ý và giảm giá lủng lẳng đung đưa, có dây cờ trang trí. Bên trong có đủ 3 tầng nối bằng cầu thang.
#
# Vị trí : thay cho quầy "Nhà ăn" cạnh Tòa D (quầy ở 690,200). Tòa mới nằm ngay phía bắc Tòa D, phía tây Tòa B4.2.
# Vào    : đứng trước cửa, bấm E. Module tự lo cả lúc vào, trong nhà và lúc ra (không dùng phòng căn tin chung).
# Trong nhà: W A S D đi lại, E gần NPC để trò chuyện, E ở chân cầu thang để lên / xuống lầu, E ở cửa tầng trệt để ra ngoài.
#   Tầng trệt: quầy gà rán + mì Ý (đầu bếp, thu ngân), tủ nước, thực đơn, bàn ghế.  Lầu 1: bàn ăn, cửa sổ.  Lầu 2: bàn dài học nhóm.
#
# ĐĂNG KÝ: chỉ cần thêm 1 dòng vào cuối danh sách trong scripts/maps/registry.gd:
#     "res://scripts/maps/can_tin.gd", # Tòa căn tin
#
# Dùng lại của game (không sửa file lõi):
#   game.BUILDINGS   thêm tòa mới: va chạm, minimap, dòng tên khu vực và việc cây ngẫu nhiên tránh tòa đều tự nhận
#   game.KIOSKS      gỡ quầy Nhà ăn cũ ở (690,200): hình vẽ, va chạm và cửa chung của quầy đó biến mất theo
#   game.rc/ctext/draw_tree/draw_lamp/draw_bench/draw_person   hàm vẽ có sẵn
#   draw_front_layer()  vẽ mặt tiền lên thế giới (như b42_lab.gd)
#   begin()/finish()/active của feature.gd   active = true thì người chơi ngoài trời đứng yên
#   game.hud, painter dùng script characters.gd   giống b42_lab.gd và nha_dieu_hanh.gd

const RECT := Rect2(594, 90, 100, 128)   # khối tòa nhà (cũng là vùng va chạm); y 90-218, cách Tòa D (y 240) 22 px để đi vào cửa
const OLD_KIOSK := Vector2(690, 200)     # quầy Nhà ăn cũ bị tòa này thay thế
const WINDOW_XS := [8.0, 39.0, 70.0]     # x ba cửa sổ mỗi tầng, tính từ mép trái tòa (mỗi cửa rộng 22)

const C_WALL := Color("f4e2b8")
const C_WALL_DK := Color("e6cf9a")
const C_ORANGE := Color("e08a2e")
const C_ORANGE_DK := Color("a8571a")
const C_BROWN := Color("5a3a1e")
const C_GLASS := Color("9fd3f0")
const C_GLASS_HI := Color("d8effa")
const C_RED := Color("d62828")
const C_RED_DK := Color("7a1010")
const C_CREAM := Color("fff6e0")
const BUNTING := [Color("d62828"), Color("ffd23f"), Color("3f9c45"), Color("fff6e0")]

# loại nhãn dán: 0 gà rán, 1 mì Ý, 2 giảm 30%, 3 giảm 20%, 4 giảm 50%
const SALE_LABELS := {2: "-30%", 3: "-20%", 4: "-50%"}

const DOOR_RANGE := 28.0                 # đứng cách cửa tối đa bấm E mới vào được (px)

# ---------- Bên trong: 3 tầng (trệt, lầu 1, lầu 2), khung 480x270 như màn hình game ----------
const VIEW := Vector2(480, 270)
const WALL_H := 64.0                     # chân tường sau (sàn bắt đầu từ y = 64)
const FLOOR_NAMES := ["tầng trệt", "lầu 1", "lầu 2"]
const BANNER_NAMES := ["CĂN TIN - TẦNG TRỆT", "CĂN TIN - LẦU 1", "CĂN TIN - LẦU 2"]
const START_POS := Vector2(240, 244)     # chỗ xuất hiện khi vừa vào
const EXIT_ZONE := Rect2(212, 246, 56, 24)   # tầng trệt: đứng đây bấm E để ra ngoài
const UP_STAIR := Rect2(404, 68, 30, 36)     # hình cầu thang lên (tầng trệt, lầu 1)
const DN_STAIR := Rect2(436, 68, 30, 36)     # hình cầu thang xuống (lầu 1, lầu 2)
const UP_ZONE := Rect2(404, 106, 30, 26)     # đứng dưới chân cầu thang để bấm E
const DN_ZONE := Rect2(436, 106, 30, 26)
const UP_LAND := Vector2(419, 120)           # chỗ xuất hiện khi vừa đi xuống tới tầng này
const DN_LAND := Vector2(451, 120)           # chỗ xuất hiện khi vừa đi lên tới tầng này
const WALK_SPEED := 70.0
const TALK_RANGE := 26.0
const SAY_TIME := 3.2
# bàn từng tầng: [x, y, rộng]. Mặt bàn cao 14, người ngồi phía bắc (sau bàn) hoặc phía nam (trước bàn)
const TABLES := [
	[[44, 152, 40], [150, 152, 40], [256, 152, 40], [44, 214, 40], [150, 214, 40], [256, 214, 40]],
	[[60, 128, 40], [180, 128, 40], [300, 128, 40], [60, 200, 40], [180, 200, 40], [300, 200, 40]],
	[[40, 134, 150], [220, 134, 150], [40, 210, 150], [220, 210, 150]],
]
const PLANTS := [
	[Vector2(392, 240), Vector2(451, 92)],
	[Vector2(24, 240), Vector2(392, 240)],
	[Vector2(24, 240), Vector2(392, 240), Vector2(419, 92)],
]
const WALL_COLORS := [Color("f6d9a0"), Color("cfe8e1"), Color("f4e8c8")]
const WAINSCOT := [Color("e08a2e"), Color("5fa89a"), Color("c9a14a")]
const C_FRAME := Color("2e2f2b")
const C_STEP_A := Color("b78950")
const C_STEP_B := Color("9a703b")

var inside := false
var _layer: CanvasLayer
var _painter: Node2D          # Node2D dùng script vẽ của game (characters.gd) để vẽ nội thất
var _floor := 0               # 0 trệt, 1 lầu 1, 2 lầu 2
var _pos := START_POS         # vị trí nhân vật trong nhà (bàn chân)
var _face := 0                # 0 xuống, 1 lên, 2 trái, 3 phải
var _anim := 0.0
var _clock := 0.0
var _fade := 0.0
var _closing := false
var _action := ""             # "exit", "up", "down": việc sẽ làm khi màn hình mờ hết
var _banner := 0.0            # thời gian còn lại của biển tên tầng khi mới tới
var _say := ""
var _say_t := 0.0
var _say_i := -1
var _npcs: Array = []         # NPC từng tầng (đầu bếp, thu ngân, sinh viên ngồi ăn)
var _solid: Array = []        # _solid[tầng] = danh sách vật cản Rect2

func _ready() -> void:
	# Đăng ký trước setup_collision(): va chạm, minimap, tên khu vực tự nhận tòa mới; cây ngẫu nhiên tránh tòa.
	for i in range(game.KIOSKS.size() - 1, -1, -1):
		var k: Array = game.KIOSKS[i]
		if str(k[0]) == "Nhà ăn" and int(k[1]) == int(OLD_KIOSK.x) and int(k[2]) == int(OLD_KIOSK.y):
			game.KIOSKS.remove_at(i)
	game.BUILDINGS.append(["CĂN TIN", RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y, C_WALL, C_ORANGE, "Căn tin - gà rán, mì Ý, nước giải khát, đang giảm giá."])
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

func _door_pos() -> Vector2:
	return Vector2(RECT.get_center().x, RECT.end.y + 7.0)

# ======================= VẼ MẶT TIỀN =======================

func draw_front_layer() -> void:
	if not game.view.intersects(RECT.grow(60.0)):
		return
	_paint_facade()
	_repaint_front_items()
	if inside or game.is_busy() or not _near_door_outside():
		return
	var text := "Bấm [E] để vào Căn tin"
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

# Mặt tiền (từ trên xuống): biển CĂN TIN, lầu 2, dây cờ, lầu 1, mái hiên sọc, tầng trệt có cửa chính.
func _paint_facade() -> void:
	var r := RECT
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var end_y := r.end.y
	var cx := x + w / 2.0
	var t: float = Time.get_ticks_msec() / 1000.0
	game.rc(x, y, w, r.size.y, C_WALL)
	# gờ mái
	game.rc(x - 2, y - 3, w + 4, 5, C_ORANGE)
	game.rc(x - 2, y + 2, w + 4, 1, C_ORANGE_DK)
	# biển CĂN TIN có hàng bóng đèn vàng
	game.rc(x + 7, y + 5, w - 14, 17, C_BROWN)
	game.rc(x + 8, y + 6, w - 16, 15, Color("b3261e"))
	for i in 11:
		game.rc(x + 11.0 + i * 8.0, y + 7, 2, 2, Color("ffe27a"))
	game.ctext("CĂN TIN", x + 8, y + 19, w - 16, 10, Color("ffe27a"))
	# lầu 2 và lầu 1: cửa sổ, nhãn dán treo, lan can, sàn tầng
	_paint_floor_row(x, y + 28.0, w, t, [0, 2, 1])
	_paint_floor_row(x, y + 64.0, w, t, [3, 1, 0])
	# dây cờ giăng ngang dưới sàn lầu 2
	game.rc(x, y + 60, w, 1, C_BROWN)
	for i in 12:
		var fx := x + 1.0 + i * 8.0
		var sw := roundf(sin(t * 2.2 + i) * 1.0)
		var col: Color = BUNTING[i % 4]
		game.draw_colored_polygon(PackedVector2Array([Vector2(fx, y + 61), Vector2(fx + 6, y + 61), Vector2(fx + 3.0 + sw, y + 66)]), col)
	# tầng trệt: tường, hai cửa kính hai bên, cửa chính ở giữa
	game.rc(x, y + 104, w, 24, C_WALL_DK)
	game.rc(x, y + 126, w, 2, C_ORANGE_DK)
	for wx in [x + 6.0, x + w - 30.0]:
		game.rc(wx - 1, y + 107, 26, 17, C_BROWN)
		game.rc(wx, y + 108, 24, 15, C_GLASS)
		game.rc(wx, y + 108, 24, 3, C_GLASS_HI)
	game.rc(cx - 11, y + 105, 22, 23, C_BROWN)
	game.rc(cx - 9, y + 107, 8, 21, C_GLASS)
	game.rc(cx + 1, y + 107, 8, 21, C_GLASS)
	game.rc(cx - 3, y + 117, 1, 3, Color("ffd23f"))
	game.rc(cx + 2, y + 117, 1, 3, Color("ffd23f"))
	# mái hiên sọc cam trắng viền vỏ sò
	for i in 13:
		var ac: Color = C_ORANGE if i % 2 == 0 else Color.WHITE
		game.rc(x - 2.0 + i * 8.0, y + 94, 8, 8, ac)
		game.draw_circle(Vector2(x - 2.0 + i * 8.0 + 4.0, y + 102), 4.0, ac)
	# nhãn treo dưới mái hiên: bảng GÀ RÁN, bảng MÌ Ý và nhãn giảm giá trước cửa
	var s1 := roundf(sin(t * 1.6) * 1.0)
	var s2 := roundf(sin(t * 1.6 + 1.7) * 1.0)
	_hang_card("GÀ RÁN", Vector2(x + 18.0 + s1, y + 108.0), Color("c0262d"))
	_hang_card("MÌ Ý", Vector2(x + w - 18.0 + s2, y + 108.0), Color("2f7d32"))
	_hang_sticker(4, Vector2(cx, y + 104.0), roundf(sin(t * 1.9) * 1.0))
	# thảm chùi chân, viền ngoài
	game.rc(cx - 13, end_y + 1, 26, 3, Color("a0382a"))
	game.draw_rect(r, Color("2b2b2b"), false, 1.0)

# Một tầng lầu: 3 cửa sổ có nhãn dán treo (kinds = loại nhãn từng cửa), lan can có song, sàn tầng.
func _paint_floor_row(x: float, wy: float, w: float, t: float, kinds: Array) -> void:
	for i in 3:
		var wx: float = x + WINDOW_XS[i]
		game.rc(wx - 1, wy - 1, 24, 20, C_BROWN)
		game.rc(wx, wy, 22, 18, C_GLASS)
		game.rc(wx, wy, 22, 3, C_GLASS_HI)
		game.rc(wx + 17, wy + 3, 2, 12, C_GLASS_HI)
		_hang_sticker(int(kinds[i]), Vector2(wx + 11.0, wy + 1.0), roundf(sin(t * 1.8 + wx * 0.3) * 1.0))
	game.rc(x + 2, wy + 18, w - 4, 2, C_CREAM)
	for j in 19:
		game.rc(x + 3.0 + j * 5.0, wy + 20, 1, 6, C_BROWN)
	game.rc(x + w - 4.0, wy + 20, 1, 6, C_BROWN)   # song cuối sát mép phải
	game.rc(x, wy + 26, w, 4, C_ORANGE)
	game.rc(x, wy + 29, w, 1, C_ORANGE_DK)

# Nhãn dán tròn treo bằng dây từ điểm neo (đung đưa sang trái phải theo sway)
func _hang_sticker(kind: int, anchor: Vector2, sway: float) -> void:
	game.rc(anchor.x, anchor.y, 1, 3, C_BROWN)
	_sticker(game, kind, Vector2(anchor.x + sway, anchor.y + 10.0))

# Bảng chữ nhật treo bằng hai sợi dây dưới mái hiên; bề rộng tự theo độ dài chữ để chữ (GÀ RÁN) không bị cắt
func _hang_card(text: String, anchor: Vector2, col: Color) -> void:
	var fnt: Font = game.font
	var tw: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var cw := maxf(22.0, tw + 8.0)
	game.rc(anchor.x - cw / 2.0 + 3.0, anchor.y - 3, 1, 4, C_BROWN)
	game.rc(anchor.x + cw / 2.0 - 4.0, anchor.y - 3, 1, 4, C_BROWN)
	game.rc(anchor.x - cw / 2.0 - 1.0, anchor.y + 1, cw + 2.0, 11, C_BROWN)
	game.rc(anchor.x - cw / 2.0, anchor.y + 2, cw, 9, col)
	game.ctext(text, anchor.x - cw / 2.0, anchor.y + 9, cw, 6, Color.WHITE)

# Nhãn dán: không cần chi tiết, chỉ gợi hình gà rán, tô mì Ý và ngôi sao giảm giá
func _sticker(g: Node2D, kind: int, c: Vector2) -> void:
	if kind == 0:
		g.draw_circle(c, 7.0, Color("7a3a10"))
		g.draw_circle(c, 6.0, Color("ffd23f"))
		g.draw_circle(c + Vector2(-1, -1), 3.5, Color("c8742a"))
		g.draw_circle(c + Vector2(-2, -2), 1.2, Color("e8a050"))
		g.rc(c.x + 1.0, c.y + 1.0, 4, 2, Color.WHITE)
		g.rc(c.x + 4.0, c.y + 0.0, 2, 4, Color.WHITE)
	elif kind == 1:
		g.draw_circle(c, 7.0, Color("8a1f1f"))
		g.draw_circle(c, 6.0, C_CREAM)
		g.rc(c.x - 4.5, c.y + 1.5, 9, 3.5, Color("3f6fb0"))
		g.draw_circle(c + Vector2(0, -0.5), 3.5, Color("f2cc4a"))
		g.rc(c.x - 3.0, c.y, 6, 1, Color("d9a92a"))
		g.draw_circle(c + Vector2(0, -2), 1.6, Color("c0262d"))
	else:
		_star(g, c, 9.0, C_RED_DK)
		_star(g, c, 8.0, C_RED)
		g.ctext(str(SALE_LABELS.get(kind, "-20%")), c.x - 10.0, c.y + 2.5, 20, 6, Color.WHITE)

func _star(g: Node2D, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.7
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	g.draw_colored_polygon(pts, col)

# ======================= BÊN TRONG: DỰNG PHÒNG =======================

func _build_room() -> void:
	_solid.clear()
	_npcs.clear()
	for f in 3:
		var arr: Array = []
		for tb in TABLES[f]:
			arr.append(Rect2(tb[0] - 4.0, tb[1] - 6.0, tb[2] + 8.0, 34.0))
		for pc in PLANTS[f]:
			arr.append(Rect2(pc.x - 7.0, pc.y, 14.0, 9.0))
		if f < 2:
			arr.append(Rect2(UP_STAIR.position.x - 2.0, 60.0, UP_STAIR.size.x + 4.0, 46.0))
		if f > 0:
			arr.append(Rect2(DN_STAIR.position.x - 2.0, 60.0, DN_STAIR.size.x + 4.0, 46.0))
		_solid.append(arr)
	_solid[0].append(Rect2(40, 84, 250, 22))    # quầy bán hàng
	_solid[0].append(Rect2(300, 60, 36, 34))    # tủ nước ngọt
	# tầng trệt: sau quầy là đầu bếp và thu ngân
	_npcs.append(_npc(0, "cook", Vector2(205, 96), 0, Color.WHITE, Color("1b1b1b"), false, [
		"Gà rán mới ra lò, nóng hổi đây!",
		"Hôm nay mì Ý giảm 20% nha bạn.",
		"Muốn ăn gì cứ nói, quán hết nhanh lắm."], -1))
	_npcs.append(_npc(0, "cashier", Vector2(262, 96), 0, Color("e07a5f"), Color("2a1d14"), true, [
		"Combo gà rán + nước chỉ 29K thôi.",
		"Nhớ mang thẻ sinh viên để được giảm giá nhé.",
		"Lầu 1 và lầu 2 còn nhiều bàn trống đó."], -1))
	_npcs.append(_seat(0, 1, "n", 0.35, Color("3d5a80"), Color("1b1b1b"), false, [
		"Gà rán ở đây giòn lắm!",
		"Mình ăn nhanh cho kịp giờ học."]))
	_npcs.append(_seat(0, 4, "s", 0.65, Color("81b29a"), Color("5a3a22"), true, [
		"Mì Ý hôm nay giảm giá nên mình mua hai phần.",
		"Ngon hơn cơm ký túc xá nhiều."]))
	_npcs.append(_seat(0, 2, "n", 0.6, Color("f2cc8f"), Color("1b1b1b"), false, [
		"Chỗ này gần quầy, gọi món tiện lắm.",
		"Bạn lên lầu ngồi cho mát nha."]))
	# lầu 1
	_npcs.append(_seat(1, 0, "n", 0.4, Color("e07a5f"), Color("2a1d14"), true, [
		"Lầu 1 ngồi mát, gió thổi qua cửa sổ.",
		"Ăn xong mình ngồi ôn bài luôn."]))
	_npcs.append(_seat(1, 1, "s", 0.6, Color("3d5a80"), Color("1b1b1b"), false, [
		"Bạn ơi, ngồi chung không?",
		"Mình chờ bạn cùng nhóm tới."]))
	_npcs.append(_seat(1, 4, "n", 0.5, Color("81b29a"), Color("5a3a22"), false, [
		"Hôm nay quán đông ghê.",
		"Gà rán giảm giá là phải ăn liền."]))
	_npcs.append(_seat(1, 5, "s", 0.4, Color("f2cc8f"), Color("1b1b1b"), true, [
		"Mì Ý ở đây sốt đậm đà lắm.",
		"Mình ngồi đây ngắm sân trường."]))
	# lầu 2: yên tĩnh, học nhóm
	_npcs.append(_seat(2, 0, "n", 0.25, Color("3d5a80"), Color("1b1b1b"), false, [
		"Lầu 2 yên tĩnh, hợp học nhóm.",
		"Deadline tuần này khủng khiếp..."]))
	_npcs.append(_seat(2, 0, "n", 0.7, Color("e07a5f"), Color("2a1d14"), true, [
		"Mình vừa ăn gà rán vừa code.",
		"Chờ mình sửa xong cái bug này đã."]))
	_npcs.append(_seat(2, 1, "s", 0.5, Color("81b29a"), Color("5a3a22"), false, [
		"Bàn dài ngồi được cả nhóm.",
		"Wifi ở đây mạnh đó."]))
	_npcs.append(_seat(2, 3, "s", 0.3, Color("f2cc8f"), Color("1b1b1b"), true, [
		"Lên đây ăn cho khỏi ồn.",
		"Mai thi rồi, mình ôn nốt chương cuối."]))

func _npc(floor_i: int, kind: String, pos: Vector2, face: int, shirt: Color, hair: Color, lh: bool, lines: Array, table: int) -> Dictionary:
	return {"floor": floor_i, "kind": kind, "pos": pos, "face": face, "shirt": shirt, "hair": hair, "long": lh,
		"lines": lines, "idx": 0, "table": table}

# người ngồi ăn: side "n" ngồi sau bàn (nhìn về phía mình), "s" ngồi trước bàn (quay lưng về phía mình)
func _seat(floor_i: int, table_i: int, side: String, frac: float, shirt: Color, hair: Color, lh: bool, lines: Array) -> Dictionary:
	var tb: Array = TABLES[floor_i][table_i]
	var x := float(tb[0]) + float(tb[2]) * frac
	var y := float(tb[1])
	if side == "n":
		return _npc(floor_i, "sit_n", Vector2(x, y + 8.0), 0, shirt, hair, lh, lines, table_i)
	return _npc(floor_i, "sit_s", Vector2(x, y + 28.0), 1, shirt, hair, lh, lines, table_i)

# ======================= VÀO / RA / ĐỔI TẦNG =======================

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_pos()) < DOOR_RANGE

func begin() -> void:
	super()
	inside = true
	_closing = false
	_action = ""
	_floor = 0
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_banner = 2.5
	_say_t = 0.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong nhà

func finish() -> void:
	super()
	inside = false
	_closing = false
	_say_t = 0.0
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

# ưu tiên: lối ra, cầu thang, rồi mới tới trò chuyện với NPC
func _interact() -> void:
	if _floor == 0 and EXIT_ZONE.has_point(_pos):
		_go("exit")
	elif _floor < 2 and UP_ZONE.has_point(_pos):
		_go("up")
	elif _floor > 0 and DN_ZONE.has_point(_pos):
		_go("down")
	else:
		var i := _npc_near()
		if i >= 0:
			_talk(i)

func _go(action: String) -> void:
	_action = action
	_closing = true   # mờ dần rồi mới thực hiện (xem _process)

func _apply_action() -> void:
	match _action:
		"exit":
			finish()
			return
		"up":
			_floor += 1
			_pos = DN_LAND
		"down":
			_floor -= 1
			_pos = UP_LAND
	_face = 0
	_closing = false
	_banner = 2.5
	_say_t = 0.0

func _process(delta: float) -> void:
	if not inside:
		return
	_clock += delta
	_say_t = maxf(_say_t - delta, 0.0)
	_banner = maxf(_banner - delta, 0.0)
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			_apply_action()
			if not inside:
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

# vùng đi được: sàn của tầng; tầng trệt có thêm lối ra ở giữa đáy
func _walkable(pt: Vector2) -> bool:
	if pt.x >= 18.0 and pt.x <= 462.0 and pt.y >= 72.0 and pt.y <= 258.0:
		return true
	if _floor == 0 and pt.x >= 214.0 and pt.x <= 266.0 and pt.y > 258.0 and pt.y <= 268.0:
		return true
	return false

# cùng cách tính với game.blocked(): chân nhân vật là hộp 8x4
func _blocked(p: Vector2) -> bool:
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for pt in [hit.position, Vector2(hit.end.x, hit.position.y), Vector2(hit.position.x, hit.end.y), hit.end]:
		if not _walkable(pt):
			return true
	for s in _solid[_floor]:
		if hit.intersects(s):
			return true
	return false

func _npc_near() -> int:
	var best := -1
	var bd := TALK_RANGE
	for i in _npcs.size():
		if int(_npcs[i].floor) != _floor:
			continue
		var c: Vector2 = _npcs[i].pos + Vector2(0, -8)
		var d := _pos.distance_to(c)
		if d < bd:
			bd = d
			best = i
	return best

func _talk(i: int) -> void:
	var n: Dictionary = _npcs[i]
	var lines: Array = n.lines
	_say = str(lines[int(n.idx) % lines.size()])
	n["idx"] = int(n.idx) + 1
	_say_i = i
	_say_t = SAY_TIME

# ======================= BÊN TRONG: VẼ =======================

func _paint() -> void:
	var p := _painter
	var f := _floor
	p.rc(0, 0, VIEW.x, VIEW.y, C_FRAME)
	_paint_floor_tiles(p)
	_paint_walls(p)
	_paint_wall_decor(p)
	if f < 2:
		_paint_stairs(p, UP_STAIR, true)
	if f > 0:
		_paint_stairs(p, DN_STAIR, false)
	# vật đứng: sắp theo chân / đáy để người đi trước hoặc sau bàn, quầy, cây
	var items: Array = []
	for i in TABLES[f].size():
		items.append([float(TABLES[f][i][1]) + 14.0, 0, i])
	for i in _npcs.size():
		if int(_npcs[i].floor) == f:
			items.append([float(_npcs[i].pos.y), 1, i])
	for pc in PLANTS[f]:
		items.append([pc.y + 9.0, 2, pc])
	if f == 0:
		items.append([106.0, 3, null])
		items.append([94.0, 4, null])
	items.append([_pos.y, 5, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				_paint_table(p, TABLES[f][it[2]], it[2])
			1:
				_paint_npc(p, _npcs[it[2]])
			2:
				_paint_plant(p, it[2])
			3:
				_paint_counter(p)
			4:
				_paint_fridge(p)
			5:
				_paint_player(p)
	if _say_t > 0.0 and _say_i >= 0 and _say_i < _npcs.size():
		var s: Dictionary = _npcs[_say_i]
		if int(s.floor) == f:
			p.draw_speech({"pos": s.pos, "say": _say})
	_paint_prompt(p)
	_paint_banner(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# chữ canh giữa có bề rộng đo theo chữ thật (ctext cắt chữ nếu bề rộng nhỏ hơn chữ)
func _ctext_fit(p: Node2D, text: String, cx: float, y: float, size: int, col: Color) -> void:
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 6.0
	p.ctext(text, cx - w / 2.0, y, w, size, col)

# Sàn: tầng trệt lát gạch caro kem cam, hai lầu trên lát ván gỗ
func _paint_floor_tiles(p: Node2D) -> void:
	if _floor == 0:
		p.rc(8, WALL_H, 464, 196, Color("f3e8cf"))
		var ty := 0
		var y := WALL_H
		while y < 260.0:
			var tx := 0
			var x := 8.0
			while x < 472.0:
				if (tx + ty) % 2 == 0:
					p.rc(x, y, minf(24.0, 472.0 - x), minf(24.0, 260.0 - y), Color("e8d8b4"))
				x += 24.0
				tx += 1
			y += 24.0
			ty += 1
	else:
		p.rc(8, WALL_H, 464, 196, Color("c99a5e"))
		var row := 0
		var y2 := WALL_H
		while y2 < 260.0:
			p.rc(8, y2, 464, 1, Color("b0824a"))
			for j in 10:
				p.rc(8.0 + j * 48.0 + (row % 3) * 16.0, y2, 1, minf(14.0, 260.0 - y2), Color("b0824a"))
			y2 += 14.0
			row += 1

# Tường sau, ốp chân tường, khung ngoài; tầng trệt có lối ra sáng ở giữa đáy
func _paint_walls(p: Node2D) -> void:
	var wc: Color = WALL_COLORS[_floor]
	var wd: Color = WAINSCOT[_floor]
	p.rc(8, 8, 464, WALL_H - 8.0, wc)
	p.rc(8, 8, 464, 4, Color(0, 0, 0, 0.12))
	p.rc(8, 48, 464, 16, wd)
	p.rc(8, 48, 464, 2, wd.lightened(0.25))
	p.rc(8, WALL_H - 2.0, 464, 2, wd.darkened(0.3))
	p.rc(0, 260, VIEW.x, 10, C_FRAME)
	if _floor == 0:
		p.rc(215, 247, 50, 7, Color("5a2326"))      # thảm chùi chân
		p.rc(216, 248, 48, 5, Color("7a2f33"))
		p.rc(207, 256, 3, 14, C_FRAME)               # khung cửa và ánh sáng ngoài trời
		p.rc(270, 256, 3, 14, C_FRAME)
		p.rc(210, 258, 60, 12, Color("cfdde8"))
		p.rc(214, 262, 52, 8, Color("eef6fb"))

# Đồ treo tường: thực đơn + nhãn dán (tầng trệt), cửa sổ + nhãn dán (hai lầu)
func _paint_wall_decor(p: Node2D) -> void:
	if _floor == 0:
		_paint_menu(p)
		_sticker(p, 3, Vector2(30, 32))
		_sticker(p, 0, Vector2(60, 32))
		_sticker(p, 1, Vector2(268, 32))
		_sticker(p, 2, Vector2(358, 32))
		_sticker(p, 0, Vector2(382, 32))
		return
	for wx in [60.0, 180.0, 300.0]:
		_paint_window(p, wx)
	var kinds: Array = [1, 2, 0] if _floor == 1 else [0, 3, 1]
	for i in 3:
		_sticker(p, int(kinds[i]), Vector2(146.0 + i * 116.0 + (i - 1) * 4.0, 32))

func _paint_menu(p: Node2D) -> void:
	var fnt: Font = p.font
	p.rc(96, 14, 140, 44, C_BROWN)
	p.rc(98, 16, 136, 40, Color("1f3b2d"))
	_ctext_fit(p, "THỰC ĐƠN", 166.0, 25, 7, Color("ffe27a"))
	var menu := [["Gà rán", "29K"], ["Mì Ý", "35K"], ["Cơm sườn", "30K"], ["Trà đá", "5K"]]
	for i in 4:
		var yb := 33.0 + i * 6.0
		p.draw_string(fnt, Vector2(106, yb), str(menu[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("f4f4f4"))
		var pw: float = fnt.get_string_size(str(menu[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		p.draw_string(fnt, Vector2(226.0 - pw, yb), str(menu[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("ffe27a"))

func _paint_window(p: Node2D, x: float) -> void:
	p.rc(x - 2, 12, 56, 38, C_BROWN)
	p.rc(x, 14, 52, 34, Color("a8d8f0"))
	p.rc(x, 14, 52, 8, Color("c8e8f8"))
	p.rc(x + 4, 40, 18, 8, Color("4f9c4a"))     # ngọn cây ngoài sân
	p.rc(x + 30, 38, 18, 10, Color("3f8a3f"))
	p.rc(x + 24, 14, 4, 34, C_BROWN)
	p.rc(x, 28, 52, 3, C_BROWN)
	p.rc(x, 14, 7, 34, C_ORANGE)                # rèm
	p.rc(x + 45, 14, 7, 34, C_ORANGE)
	p.rc(x, 14, 7, 2, C_ORANGE_DK)
	p.rc(x + 45, 14, 7, 2, C_ORANGE_DK)

# Cầu thang: khối bậc gỗ có tay vịn, bảng xanh có mũi tên và chữ LÊN / XUỐNG phía trên
func _paint_stairs(p: Node2D, r: Rect2, up: bool) -> void:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	p.rc(x - 1, y - 1, w + 2, h + 2, C_BROWN)
	for i in 6:
		p.rc(x, y + i * h / 6.0, w, h / 6.0, C_STEP_A if i % 2 == 0 else C_STEP_B)
	p.rc(x, y, 2, h, C_BROWN)
	p.rc(x + w - 2.0, y, 2, h, C_BROWN)
	p.rc(x + 1, 40, w - 2.0, 20, Color("1f4aa8"))
	p.rc(x + 2, 41, w - 4.0, 18, Color("2d62c8"))
	var cx := x + w / 2.0
	var tri: PackedVector2Array
	if up:
		tri = PackedVector2Array([Vector2(cx, 43), Vector2(cx - 4, 49), Vector2(cx + 4, 49)])
	else:
		tri = PackedVector2Array([Vector2(cx, 49), Vector2(cx - 4, 43), Vector2(cx + 4, 43)])
	p.draw_colored_polygon(tri, Color.WHITE)
	_ctext_fit(p, "LÊN" if up else "XUỐNG", cx, 57, 6, Color.WHITE)

# Quầy bán hàng tầng trệt: tủ kính trưng bày gà rán và mì Ý, mặt quầy, nhãn dán ở mặt trước, máy tính tiền
func _paint_counter(p: Node2D) -> void:
	p.rc(52, 66, 122, 20, C_BROWN)
	p.rc(53, 67, 120, 18, Color("cfe9f5"))
	for i in 8:
		var fx := 62.0 + i * 14.0
		if i % 2 == 0:
			p.draw_circle(Vector2(fx, 78), 4.0, Color("c8742a"))
			p.draw_circle(Vector2(fx - 1, 77), 1.5, Color("e8a050"))
		else:
			p.draw_circle(Vector2(fx, 79), 4.0, Color("f2cc4a"))
			p.draw_circle(Vector2(fx, 77), 1.8, Color("c0262d"))
	p.rc(52, 84, 122, 2, C_BROWN)
	p.rc(40, 84, 250, 6, Color("f0c27a"))
	p.rc(40, 90, 250, 16, C_ORANGE)
	p.rc(40, 90, 250, 2, Color("f6a64a"))
	p.rc(40, 104, 250, 2, C_ORANGE_DK)
	_sticker(p, 0, Vector2(70, 98))
	_sticker(p, 1, Vector2(110, 98))
	_sticker(p, 2, Vector2(150, 98))
	p.rc(246, 76, 14, 8, Color("2a2c33"))
	p.rc(248, 77, 10, 4, C_GLASS)

func _paint_fridge(p: Node2D) -> void:
	p.rc(300, 38, 36, 54, Color("aeb8c4"))
	p.rc(302, 40, 32, 50, Color("2a2c33"))
	p.rc(303, 41, 30, 48, C_GLASS)
	var cans := [Color("d62828"), Color("2d62c8"), Color("3f9c45"), Color("ffd23f")]
	for r in 4:
		for c in 5:
			p.rc(305.0 + c * 5.5, 44.0 + r * 11.0, 4, 8, cans[(r + c) % 4])
	p.rc(300, 38, 36, 3, C_RED)

func _paint_table(p: Node2D, tb: Array, idx: int) -> void:
	var x := float(tb[0])
	var y := float(tb[1])
	var w := float(tb[2])
	p.rc(x + 2, y + 18, w - 2.0, 6, Color(0, 0, 0, 0.14))
	p.rc(x + 2, y + 18, 3, 6, C_BROWN)
	p.rc(x + w - 5.0, y + 18, 3, 6, C_BROWN)
	p.rc(x, y, w, 14, Color("d9a05a"))
	p.rc(x, y, w, 1, Color("f0c27a"))
	p.rc(x, y + 14, w, 4, Color("8a5a2a"))
	# đĩa gà rán hoặc mì Ý trước mặt mỗi người đang ngồi
	for n in _npcs:
		if int(n.floor) != _floor or int(n.table) != idx:
			continue
		var dx: float = float(n.pos.x) - 4.0
		var dy := y + 3.0 if str(n.kind) == "sit_n" else y + 7.0
		p.rc(dx, dy, 9, 4, Color.WHITE)
		if int(n.pos.x) % 2 == 0:
			p.draw_circle(Vector2(dx + 4.0, dy + 1.5), 2.5, Color("c8742a"))
		else:
			p.draw_circle(Vector2(dx + 4.0, dy + 1.5), 2.5, Color("f2cc4a"))
			p.rc(dx + 3.0, dy, 2, 2, Color("c0262d"))

func _paint_npc(p: Node2D, n: Dictionary) -> void:
	var pos: Vector2 = n.pos
	p.draw_person(pos, n.shirt, n.hair, n.face, 0.0, false, n.long, false)
	var kind: String = n.kind
	if kind == "cook":
		p.rc(pos.x - 4, pos.y - 28, 8, 5, Color.WHITE)    # mũ bếp
		p.rc(pos.x - 5, pos.y - 24, 10, 2, Color.WHITE)
	elif kind == "sit_s":
		p.rc(pos.x - 9, pos.y - 7, 18, 7, Color("7a4f28"))   # ghế dài che chân
		p.rc(pos.x - 9, pos.y - 7, 18, 1, Color("a8703c"))

func _paint_plant(p: Node2D, c: Vector2) -> void:
	p.shadow(c + Vector2(0, 9), 9.0)
	p.rc(c.x - 7, c.y, 14, 9, Color("3b4252"))
	p.rc(c.x - 6, c.y + 1, 12, 7, Color("9aa8bb"))
	p.rc(c.x - 7, c.y, 14, 2, Color("b8c4d4"))
	var greens := [Color("2f7d32"), Color("3f9c45"), Color("2f7d32"), Color("4fb356"), Color("3f9c45")]
	var offs := [Vector2(-6, -3), Vector2(6, -3), Vector2(0, -9), Vector2(-3, -1), Vector2(3, -1)]
	for i in 5:
		p.draw_circle(c + offs[i], 5.0, greens[i])

func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _prompt_text() -> String:
	if _floor == 0 and EXIT_ZONE.has_point(_pos):
		return "[E] Ra ngoài"
	if _floor < 2 and UP_ZONE.has_point(_pos):
		return "[E] Lên " + str(FLOOR_NAMES[_floor + 1])
	if _floor > 0 and DN_ZONE.has_point(_pos):
		return "[E] Xuống " + str(FLOOR_NAMES[_floor - 1])
	if _npc_near() >= 0:
		return "[E] Trò chuyện"
	return ""

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var text := _prompt_text()
	if text != "":
		_ctext_fit(p, text, _pos.x, _pos.y - 44.0, 8, Color.WHITE)

# Biển tên tầng hiện vài giây ở góc trái dưới khi mới tới
func _paint_banner(p: Node2D) -> void:
	if _banner <= 0.0 or _closing:
		return
	var a := clampf(_banner, 0.0, 1.0)
	var text: String = BANNER_NAMES[_floor]
	var fnt: Font = p.font
	var w: float = fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 14.0
	p.rc(12, 240, w + 2.0, 15, Color(0.2, 0.2, 0.2, a))
	p.rc(13, 241, w, 13, Color(0.08, 0.1, 0.18, 0.92 * a))
	p.ctext(text, 13, 251, w, 8, Color(1.0, 0.82, 0.25, a))
