extends "res://scripts/features/feature.gd"
# NHÀ ĐIỀU HÀNH + SẢNH ĐÓN HCMUS (bên trong).
#
# Ngoài trời : dùng lại mặt tiền Nhà Điều hành có sẵn của bản đồ gốc (DIEUHANH trong campus_data.gd).
#              Đứng trước cửa tòa nhà, bấm E để vào.
# Bên trong  : sảnh ốp gỗ lam cam, logo HCMUS và dòng chữ SCIENCE trên tường, hành lang đá tối ở giữa,
#              hai tấm thảm đỏ, cây đàn piano lớn, chữ HCMUS 3D ở tường trái, 4 bức chân dung ở tường phải, 2 chậu cây.
#              NPC nữ tóc đen đeo kính ngồi chơi piano (chậm); vài NPC nằm ngủ trên thảm đỏ.
#              Đi bằng W A S D, bấm E gần NPC để trò chuyện, bấm E ở cuối hành lang (lối ra) để ra ngoài.
#
# ĐĂNG KÝ: chỉ cần thêm 1 dòng vào cuối danh sách trong scripts/maps/registry.gd:
#     "res://scripts/maps/nha_dieu_hanh.gd", # Nhà Điều hành và sảnh đón
#
# Module tự lo mọi thứ, không cần sửa file lõi:
#   - Phòng "office" chung của features/building_doors.gd bị gỡ khỏi danh sách cửa của nó (xem _detach_generic_office_door),
#     nên bấm E trước Nhà Điều hành sẽ vào sảnh này. Tọa độ cửa lấy từ game.get_doorways() nên đi theo khi bản đồ dời.
#   - Va chạm / minimap / tên khu vực của Nhà Điều hành đã có sẵn trong bản đồ gốc, không thêm vào BUILDINGS.
#
# Dùng lại của game (không tạo hệ thống mới):
#   game.rc/ctext/draw_person/draw_speech/shadow   hàm vẽ có sẵn (qua painter dùng script characters.gd như b42_lab.gd)
#   begin()/finish()/active của feature.gd         active = true thì người chơi ngoài trời đứng yên
#   draw_front_layer()                              vẽ khung chỉ dẫn "Bấm [E] để vào" ngoài trời

# ---------- Cửa ngoài trời ----------
const DOOR_RANGE := 28.0                 # đứng cách cửa tối đa bấm E mới vào được (px)

# ---------- Sảnh (khung 480x270 như màn hình game, bố cục theo ảnh tham chiếu nhìn từ trên xuống) ----------
const VIEW := Vector2(480, 270)
const FLOOR_RECT := Rect2(28, 70, 410, 190)     # sàn gạch xám
const AISLE_RECT := Rect2(206, 20, 70, 250)     # hành lang đá tối ở giữa, kéo xuống cửa ra
const WALL_BOTTOM := 70.0                       # chân tường gỗ lam
const START_POS := Vector2(241, 244)            # chỗ xuất hiện khi vừa vào
const EXIT_ZONE := Rect2(213, 248, 56, 22)      # đứng trong vùng này bấm E để ra
const WALK_SPEED := 70.0                        # giống người chơi ngoài trời
const TALK_RANGE := 26.0                        # đứng gần NPC tối đa bấm E mới nói chuyện được
const SAY_TIME := 3.2
const CARPET_L := Rect2(83, 83, 109, 100)       # thảm đỏ bên trái (3 x 3 ô), có đàn piano
const CARPET_R := Rect2(287, 83, 121, 100)      # thảm đỏ bên phải (4 x 3 ô)
const PIANO_BOX := Rect2(103, 104, 76, 64)
const PIANIST_FEET := Vector2(92, 142)          # chân cô gái chơi đàn (ngồi ở ghế bên trái bàn phím)
const PLANTS := [Vector2(182, 248), Vector2(284, 248)]
const SIGN_BOX := Rect2(19, 72, 31, 176)        # chữ HCMUS nổi trên tường trái
const PIANO_PTS := [Vector2(113, 104), Vector2(146, 104), Vector2(165, 108), Vector2(176, 118), Vector2(178, 136),
		Vector2(176, 152), Vector2(168, 162), Vector2(150, 164), Vector2(113, 160)]
const ACRO_HEAD := ["S", "C", "I", "E", "N", "C", "E"]
const ACRO_REST := ["cience", "reativity", "ntegration", "mpathy", "urture", "ommunity", "mpowerment"]

const C_FRAME := Color("2e2f2b")
const C_TILE_A := Color("bcbdc0")
const C_TILE_B := Color("b2b4b8")
const C_GROUT := Color("8e9095")
const C_SLAT := Color("d9913f")
const C_SLAT_HI := Color("f0b768")
const C_SLAT_GAP := Color("5c3b1d")
const C_BEIGE := Color("e6d9b8")
const C_STONE := Color("8c8c8e")
const C_AISLE := Color("3b3e47")
const C_AISLE_LN := Color("2a2c33")
const C_CARPET := Color("8b2a2d")
const C_CARPET_LN := Color("771f23")
const C_CARPET_DK := Color("5a1518")
const C_PIANO := Color("111318")
const C_PIANO_HI := Color("292c34")
const C_BLUE := Color("1c2f9e")
const C_NAVY := Color("1b2f6e")
const C_OUTLINE := Color("1a1a2e")
const C_SKIN := Color("f1c27d")
const C_HAIR_GOLD := Color("101114")
const C_HAIR_GOLD_HI := Color("292b32")

var inside := false
var _layer: CanvasLayer
var _painter: Node2D          # Node2D dùng script vẽ của game (characters.gd) để vẽ sảnh
var _door_out := Vector2(990, 857)   # cửa ngoài trời (cập nhật từ game.get_doorways() trong _ready)
var _pos := START_POS         # vị trí nhân vật trong sảnh (bàn chân)
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải (giống game.facing)
var _anim := 0.0
var _clock := 0.0
var _fade := 0.0
var _closing := false
var _banner := 0.0            # thời gian còn lại của biển "NHÀ ĐIỀU HÀNH" khi mới vào
var _say := ""
var _say_t := 0.0
var _say_i := -1
var _npcs: Array = []         # NPC trong sảnh: 1 người chơi đàn + các bạn nằm ngủ
var _solid: Array = []        # vật cản trong sảnh

func _ready() -> void:
	# Cửa của Nhà Điều hành do bản đồ gốc tính sẵn; lấy đúng tọa độ đó để cửa đi theo khi công trình bị dời.
	for d in game.get_doorways():
		if str(d.get("kind", "")) == "office":
			_door_out = d["position"]
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
	# features/building_doors.gd được nạp SAU module bản đồ nên chưa tồn tại lúc này -> gỡ cửa chung ở cuối khung hình.
	call_deferred("_detach_generic_office_door")

# Gỡ phòng "office" chung khỏi building_doors.gd để phím E trước Nhà Điều hành chỉ mở sảnh của module này.
func _detach_generic_office_door() -> void:
	for f in game.features:
		if f == self:
			continue
		var list: Variant = f.get("doors")
		if list is Array:
			for i in range(list.size() - 1, -1, -1):
				var d: Variant = list[i]
				if d is Dictionary and str(d.get("kind", "")) == "office":
					list.remove_at(i)

# ======================= DỰNG SẢNH =======================

func _build_room() -> void:
	_solid.clear()
	_npcs.clear()
	_solid.append(PIANO_BOX)
	_solid.append(Rect2(82, 118, 18, 28))   # ghế đàn + người chơi
	_solid.append(SIGN_BOX)
	for pc in PLANTS:
		_solid.append(Rect2(pc.x - 7.0, pc.y, 14.0, 9.0))
	# cô gái chơi piano
	_npcs.append({"kind": "piano", "c": Vector2(94, 130), "idx": 0, "lines": [
		"Shh... mình đang tập đàn.",
		"Bài này mình tập cho lễ khai giảng.",
		"Nhạc nền của trường là mình chơi đó!",
		"Bạn nghe có hay không?"]})
	# các bạn nằm ngủ giữa thảm đỏ (u = hướng từ đầu về chân; c = tâm thân người)
	_npcs.append(_sleeper(Vector2(321, 105), Vector2(1, 0), 0, Color("e07a5f"), Color("1b1b1b"), false, true, 0.0, [
		"Zzz... còn 5 phút nữa thôi...",
		"Zzz... deadline... đừng gọi em...",
		"Thảm này êm hơn giường ký túc xá..."]))
	_npcs.append(_sleeper(Vector2(395, 112), Vector2(0, 1), 2, Color.WHITE, Color("3b2a1a"), true, false, 0.4, [
		"Thi chưa thầy ơi... Zzz",
		"Hôm qua em code tới 4 giờ sáng...",
		"Đừng đánh thức em... đang mơ được 10 điểm."]))
	_npcs.append(_sleeper(Vector2(350, 136), Vector2(-1, 0), 1, Color("3d5a80"), Color("5a3a22"), false, false, 0.7, [
		"Zzz... bug... ở dòng 42...",
		"Cho em ngủ chút... rồi em làm bài tập...",
		"Ưm... tái bản giáo trình... Zzz"]))
	_npcs.append(_sleeper(Vector2(127, 176), Vector2(1, 0), 0, Color("81b29a"), Color("5a3a22"), false, true, 0.2, [
		"Zzz... tiếng đàn êm quá...",
		"Đừng đạp lên em... em đang nghe nhạc.",
		"Zzz... mai thi môn gì nhỉ..."]))
	# bạn nằm ngủ thêm
	_npcs.append(_sleeper(Vector2(345, 165), Vector2(-1, 0), 1, Color("f2cc8f"), Color("1b1b1b"), false, false, 0.1, [
		"Zzz... cho em xin gia hạn học phí...",
		"Ngủ một chút rồi em làm bài...",
		"Zzz... đừng gọi em..."]))
	for n in _npcs:
		if n.kind == "sleep":
			_solid.append(_npc_rect(n))

func _sleeper(c: Vector2, u: Vector2, pose: int, shirt: Color, hair: Color, uni: bool, pack: bool, ph: float, lines: Array) -> Dictionary:
	return {"kind": "sleep", "c": c, "u": u, "pose": pose, "shirt": shirt, "hair": hair, "uni": uni, "pack": pack,
		"ph": ph, "lines": lines, "idx": 0}

# hộp va chạm của người nằm (thân dài 30 px, đầu ở c - u*15)
func _npc_rect(n: Dictionary) -> Rect2:
	var u: Vector2 = n.u
	var c: Vector2 = n.c
	var o: Vector2 = c - u * 15.0
	var e: Vector2 = o + u * 30.0
	var r := Rect2(minf(o.x, e.x), minf(o.y, e.y), absf(e.x - o.x), absf(e.y - o.y))
	return r.grow(9.0 if int(n.pose) == 2 else 5.0)

# ======================= VÀO / RA =======================

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_out) < DOOR_RANGE

func _in_exit() -> bool:
	return EXIT_ZONE.has_point(_pos)

func begin() -> void:
	super()
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_banner = 3.0
	_say_t = 0.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong sảnh

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
		if _in_exit():
			_closing = true   # mờ dần rồi ra ngoài (xem _process)
		else:
			var i := _npc_near()
			if i >= 0:
				_talk(i)
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and _near_door_outside():
		begin()
		get_viewport().set_input_as_handled()

# ======================= TRONG SẢNH: DI CHUYỂN, TRÒ CHUYỆN =======================

func _process(delta: float) -> void:
	if not inside:
		return
	_clock += delta
	_say_t = maxf(_say_t - delta, 0.0)
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

# vùng đi được: sàn gạch + hành lang giữa (kéo lên sát tường và xuống cửa ra)
func _walkable(pt: Vector2) -> bool:
	if pt.x >= 30.0 and pt.x <= 436.0 and pt.y >= 76.0 and pt.y <= 258.0:
		return true
	if pt.x >= 209.0 and pt.x <= 273.0 and pt.y >= 32.0 and pt.y <= 268.0:
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
		var c: Vector2 = _npcs[i].c
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

# ======================= VẼ SẢNH =======================

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, C_FRAME)
	_paint_floor(p)
	_paint_slats(p)
	_paint_side_walls(p)
	_paint_aisle(p)
	_paint_wall_art(p)
	_paint_carpet(p, CARPET_L, 3, 3)
	_paint_carpet(p, CARPET_R, 4, 3)
	_paint_sign_letters(p)
	_paint_piano(p)
	for n in _npcs:
		if n.kind == "sleep":
			_paint_sleeper(p, n)
	# vật đứng: sắp theo chân để người chơi đi trước / sau chậu cây và người chơi đàn
	var items: Array = []
	items.append([PIANIST_FEET.y, 0, null])
	for pc in PLANTS:
		items.append([pc.y + 9.0, 1, pc])
	items.append([_pos.y, 2, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				_paint_pianist(p)
			1:
				_paint_plant(p, it[2])
			2:
				_paint_player(p)
	_paint_effects(p)
	_paint_prompt(p)
	_paint_banner(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# Sàn gạch xám lớn có vết bẩn nhẹ
func _paint_floor(p: Node2D) -> void:
	var r := FLOOR_RECT
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y, C_GROUT)
	var ty := 0
	var y := r.position.y
	while y < r.end.y:
		var h := minf(30.0, r.end.y - y)
		var tx := 0
		var x := r.position.x
		while x < r.end.x:
			var w := minf(30.0, r.end.x - x)
			var col: Color = C_TILE_A if p.hs(tx, ty) < 55 else C_TILE_B
			p.rc(x + 1.0, y + 1.0, w - 1.0, h - 1.0, col)
			x += 30.0
			tx += 1
		y += 30.0
		ty += 1
	p.rc(r.position.x, r.position.y, r.size.x, 3, Color(0, 0, 0, 0.16))   # bóng tường đổ xuống sàn

# Tường gỗ lam cam phía trên: hai mảng hình thang hai bên + dải lam trên đầu hành lang
func _paint_slats(p: Node2D) -> void:
	p.rc(7, 7, VIEW.x - 14.0, WALL_BOTTOM - 7.0, C_SLAT_GAP)
	_slat_panel(p, 9.0, 206.0, 45.0, 206.0)
	_slat_panel(p, 276.0, 470.0, 276.0, 440.0)
	for x in range(208, 274, 8):
		p.rc(x, 8, 6, 12, C_SLAT)
		p.rc(x, 8, 1, 12, C_SLAT_HI)
	p.rc(206, 18, 70, 2, Color("8a5a24"))
	p.rc(45, WALL_BOTTOM - 2.0, 161, 2, Color("8a5a24"))    # len chân tường
	p.rc(276, WALL_BOTTOM - 2.0, 164, 2, Color("8a5a24"))

# x0..x1 là mép trên, b0..b1 là mép dưới (lam nghiêng dần về phía hành lang cho có chiều sâu)
func _slat_panel(p: Node2D, x0: float, x1: float, b0: float, b1: float) -> void:
	var n := int((x1 - x0) / 8.0)
	for i in n:
		var t0 := float(i) / n
		var t1 := (float(i) + 0.75) / n
		var xa := lerpf(x0, x1, t0)
		var xb := lerpf(x0, x1, t1)
		var ba := lerpf(b0, b1, t0)
		var bb := lerpf(b0, b1, t1)
		p.draw_colored_polygon(PackedVector2Array([Vector2(xa, 8), Vector2(xb, 8), Vector2(bb, WALL_BOTTOM - 2.0), Vector2(ba, WALL_BOTTOM - 2.0)]), C_SLAT)
		p.draw_line(Vector2(xa + 0.5, 8), Vector2(ba + 0.5, WALL_BOTTOM - 2.0), C_SLAT_HI, 1.0)

# Tường trái be, tường phải đá xám có 4 chân dung
func _paint_side_walls(p: Node2D) -> void:
	p.draw_colored_polygon(PackedVector2Array([Vector2(7, 8), Vector2(9, 8), Vector2(45, WALL_BOTTOM), Vector2(28, WALL_BOTTOM), Vector2(28, 260), Vector2(7, 260)]), C_BEIGE)
	p.rc(24, WALL_BOTTOM, 4, 190, Color("c9bb96"))
	p.rc(7, WALL_BOTTOM, 2, 190, Color("cdbf9a"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(470, 8), Vector2(440, WALL_BOTTOM), Vector2(438, WALL_BOTTOM), Vector2(438, 260), Vector2(470, 260)]), C_STONE)
	for y in range(80, 260, 18):
		p.rc(438, y, 32, 1, Color("78787a"))
	p.rc(438, WALL_BOTTOM, 3, 190, Color("6c6c6e"))
	var hairs := [Color("1b1b1b"), Color("8a8a8a"), Color("2a1a10"), Color("c8c8c8")]
	var suits := [Color("1b2540"), Color("3a3a42"), Color("1d1d22"), Color("2b3550")]
	var ties := [Color("c0262d"), Color("1f4aa8"), Color("c0262d"), Color("2f7d32")]
	for i in 4:
		_paint_portrait(p, 452.0, 80.0 + i * 36.0, hairs[i], suits[i], ties[i])

func _paint_portrait(p: Node2D, x: float, y: float, hair: Color, suit: Color, tie: Color) -> void:
	p.rc(x, y, 18, 33, Color("2d1d10"))
	p.rc(x + 1, y + 1, 16, 31, Color("8a5a2a"))
	p.rc(x + 3, y + 3, 12, 27, Color("6f6a5a"))
	p.rc(x + 6, y + 8, 6, 7, C_SKIN)
	p.rc(x + 6, y + 7, 6, 3, hair)
	p.rc(x + 3, y + 16, 12, 14, suit)
	p.rc(x + 7, y + 16, 4, 3, Color.WHITE)
	p.rc(x + 8, y + 18, 2, 6, tie)

# Hành lang đá tối ở giữa, đáy hành lang là lối ra (ánh sáng ngoài trời)
func _paint_aisle(p: Node2D) -> void:
	var r := AISLE_RECT
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y, C_AISLE)
	for i in range(1, 3):
		p.rc(r.position.x + r.size.x * i / 3.0, r.position.y, 1, r.size.y, C_AISLE_LN)
	var y := r.position.y + 25.0
	while y < 258.0:
		p.rc(r.position.x, y, r.size.x, 1, C_AISLE_LN)
		y += 30.0
	p.rc(r.position.x, r.position.y, 2, r.size.y, Color(0, 0, 0, 0.25))
	p.rc(r.end.x - 2.0, r.position.y, 2, r.size.y, Color(0, 0, 0, 0.25))
	# thảm chùi chân + cửa sáng
	p.rc(215, 247, 52, 7, Color("5a2326"))
	p.rc(216, 248, 50, 5, Color("7a2f33"))
	p.rc(216, 248, 50, 1, Color("93444a"))
	p.rc(203, 257, 3, 13, C_FRAME)
	p.rc(276, 257, 3, 13, C_FRAME)
	p.rc(206, 259, 70, 11, Color("cfdde8"))
	p.rc(210, 263, 62, 7, Color("eef6fb"))

# Dòng SCIENCE, hai bảng logo và chữ HCMUS trên tường gỗ lam
func _paint_wall_art(p: Node2D) -> void:
	var f: Font = p.font
	for i in ACRO_HEAD.size():
		var yb := 17.0 + i * 8.0
		var x0 := 9.0 + 36.0 * (yb - 8.0) / 62.0 + 4.0
		_set_wall_projection(p, Vector2(x0, yb), 0.5)
		var head: String = ACRO_HEAD[i]
		var w1: float = f.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			p.draw_string(f, Vector2(x0, yb) + off, head, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		p.draw_string(f, Vector2(x0, yb), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("2347c8"))
		p.draw_string(f, Vector2(x0 + w1 + 2.0, yb + 1.0), ACRO_REST[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.36, 0.23, 0.11, 0.8))
		p.draw_string(f, Vector2(x0 + w1 + 1.0, yb), ACRO_REST[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fdfdfd"))
		p.draw_set_transform_matrix(Transform2D.IDENTITY)
	_paint_emblem(p, Vector2(171, 29), 38.0, 0.1)
	var fs := 18
	var tw: float = f.get_string_size("HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if tw > 0.0:
		fs = int(float(fs) * 72.0 / tw)
	var base := Vector2(359, 34)
	_set_wall_projection(p, base, 0.1)
	p.draw_string(f, base + Vector2(1, 1), "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("0b1450"))
	p.draw_string(f, base, "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_BLUE)
	p.draw_string(f, base + Vector2(1, 0), "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_BLUE)
	var small := ["Viet Nam National University", "Ho Chi Minh City", "University of Science"]
	for i in 3:
		p.draw_string(f, Vector2(359, 47 + i * 6), small[i],
				HORIZONTAL_ALIGNMENT_LEFT, 78.0, 5, Color("142070"))
	p.draw_set_transform_matrix(Transform2D.IDENTITY)

func _paint_emblem(p: Node2D, c: Vector2, logo_width: float, wall_shear: float) -> void:
	_set_wall_projection(p, c, wall_shear)
	if p.logo != null:
		var logo_size: Vector2 = p.logo.get_size() * logo_width / p.logo.get_size().x
		var logo_rect := Rect2(c - logo_size * 0.5, logo_size)
		var logo_shadow_rect := Rect2(logo_rect.position + Vector2(1, 2), logo_rect.size)
		p.draw_texture_rect(p.logo, logo_shadow_rect, false,
				Color(0, 0, 0, 0.32))
		p.draw_texture_rect(p.logo, logo_rect, false)
	else:
		p.draw_circle(c + Vector2(1, 2), logo_width * 0.15, Color(0, 0, 0, 0.28))
		p.draw_circle(c, logo_width * 0.14, Color("1c3fb0"))
	p.draw_set_transform_matrix(Transform2D.IDENTITY)

func _set_wall_projection(p: Node2D, pivot: Vector2, shear: float) -> void:
	var y_axis := Vector2(shear, 1.0)
	var origin := pivot - Vector2(pivot.x, 0.0) - y_axis * pivot.y
	p.draw_set_transform_matrix(Transform2D(Vector2.RIGHT, y_axis, origin))

func _paint_carpet(p: Node2D, r: Rect2, cols: int, rows: int) -> void:
	p.rc(r.position.x - 1.0, r.position.y - 1.0, r.size.x + 2.0, r.size.y + 2.0, C_CARPET_DK)
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y, C_CARPET)
	for i in range(1, cols):
		p.rc(r.position.x + r.size.x * i / float(cols), r.position.y, 1, r.size.y, C_CARPET_LN)
	for j in range(1, rows):
		p.rc(r.position.x, r.position.y + r.size.y * j / float(rows), r.size.x, 1, C_CARPET_LN)

# Chữ HCMUS xoay dọc, đùn khối sát tường bên trái.
func _paint_sign_letters(p: Node2D) -> void:
	var f: Font = p.font
	var font_size := 40
	var text_width: float = f.get_string_size(
		"HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	if text_width > 0.0:
		font_size = int(float(font_size) * 158.0 / text_width)
	var base := Vector2(23, 244)
	var sign_transform := Transform2D(
		Vector2(0.0, -1.0),
		Vector2(1.0, 0.0),
		base
	)
	p.draw_set_transform_matrix(Transform2D(
		sign_transform.x, sign_transform.y, base + Vector2(1, 1)
	))
	p.draw_string(f, Vector2.ZERO, "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(0, 0, 0, 0.42))
	for depth in range(3, 0, -1):
		p.draw_set_transform_matrix(Transform2D(
			sign_transform.x, sign_transform.y, base + Vector2(depth, -depth)
		))
		p.draw_string(f, Vector2.ZERO, "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size, Color("9b541f"))
	p.draw_set_transform_matrix(sign_transform)
	p.draw_string(f, Vector2.ZERO, "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color("f2a33a"))
	p.draw_set_transform_matrix(Transform2D(
		sign_transform.x, sign_transform.y, base + Vector2(-1, -1)
	))
	p.draw_string(f, Vector2.ZERO, "HCMUS", HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color("ffd16e"))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Đàn grand piano nhìn từ trên xuống, với viền sơn mài, bảng cộng hưởng và bàn phím hai quãng.
func _paint_piano(p: Node2D) -> void:
	var sh := PackedVector2Array()
	var body := PackedVector2Array()
	for v in PIANO_PTS:
		sh.append(v + Vector2(4, 5))
		body.append(v)
	p.draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	p.rc(111, 157, 4, 9, Color("090a0d"))
	p.rc(112, 157, 2, 8, Color("343640"))
	p.rc(164, 153, 4, 10, Color("090a0d"))
	p.rc(165, 153, 2, 9, Color("343640"))
	p.draw_colored_polygon(body, C_PIANO)
	p.draw_polyline(body, Color("555965"), 1.5, true)
	p.draw_line(Vector2(115, 106), Vector2(145, 106), Color("737783"), 1.0)
	p.draw_line(Vector2(114, 108), Vector2(114, 155), Color("3b3e48"), 1.0)
	# Bảng cộng hưởng gỗ lộ ra dưới nắp đàn.
	var soundboard := PackedVector2Array([
		Vector2(121, 121), Vector2(145, 119), Vector2(165, 125),
		Vector2(171, 135), Vector2(170, 147), Vector2(163, 155),
		Vector2(121, 153)
	])
	p.draw_colored_polygon(soundboard, Color("54391f"))
	p.draw_colored_polygon(PackedVector2Array([
		Vector2(123, 123), Vector2(145, 121), Vector2(163, 127),
		Vector2(168, 136), Vector2(167, 146), Vector2(161, 152),
		Vector2(123, 151)
	]), Color("81552d"))
	p.draw_polyline(soundboard, Color("c29a61"), 1.0, true)
	for i in 9:
		var sx := 126.0 + i * 4.2
		p.draw_line(Vector2(sx, 125), Vector2(sx, 149), Color("d2b178"), 0.55)
	# Nắp đàn mở, tạo lớp sáng tối thay vì phủ kín mặt đàn.
	var lid := PackedVector2Array([
		Vector2(113, 104), Vector2(143, 104), Vector2(165, 109),
		Vector2(157, 116), Vector2(130, 113), Vector2(116, 117)
	])
	p.draw_colored_polygon(lid, Color("08090d"))
	p.draw_colored_polygon(PackedVector2Array([
		Vector2(115, 105), Vector2(142, 105), Vector2(162, 110),
		Vector2(156, 113), Vector2(130, 111), Vector2(117, 115)
	]), C_PIANO_HI)
	p.draw_polyline(lid, Color("777b87"), 1.0, true)
	p.draw_line(Vector2(120, 108), Vector2(145, 108), Color("9b9eaa"), 0.7)
	p.draw_circle(Vector2(119, 118), 1.2, Color("d4b26e"))
	p.draw_circle(Vector2(158, 118), 1.2, Color("d4b26e"))
	# Khung phím và phím trắng có viền riêng.
	p.rc(101, 103, 15, 57, Color("090a0d"))
	p.rc(102, 104, 12, 54, Color("d9d7d1"))
	p.rc(103, 104, 10, 53, Color("faf9f4"))
	for i in 15:
		var ky := 105.0 + i * 3.45
		p.rc(103, ky + 2.8, 10, 0.65, Color("b8b7b2"))
		p.rc(112, ky, 1, 2.8, Color("e2e0d9"))
	var black_keys := [0, 1, 3, 4, 5, 7, 8, 10, 11, 12]
	for k in black_keys:
		var by := 105.0 + float(k) * 3.45
		p.rc(102, by, 7, 2.5, Color("08090c"))
		p.rc(102, by, 6, 0.65, Color("555863"))
	p.rc(107, 160, 8, 2, Color("b79050"))
	p.rc(109, 160, 3, 1, Color("e2c47f"))

func _paint_plant(p: Node2D, c: Vector2) -> void:
	p.shadow(c + Vector2(0, 9), 9.0)
	p.rc(c.x - 7, c.y, 14, 9, Color("3b4252"))
	p.rc(c.x - 6, c.y + 1, 12, 7, Color("9aa8bb"))
	p.rc(c.x - 7, c.y, 14, 2, Color("b8c4d4"))
	var greens := [Color("2f7d32"), Color("3f9c45"), Color("2f7d32"), Color("4fb356"), Color("3f9c45")]
	var offs := [Vector2(-6, -3), Vector2(6, -3), Vector2(0, -9), Vector2(-3, -1), Vector2(3, -1)]
	for i in 5:
		p.draw_circle(c + offs[i], 5.0, greens[i])
	p.draw_circle(c + Vector2(-1, -9), 2.0, Color("7ad080"))

# Cô gái tóc đen đeo kính ngồi chơi piano, chuyển động tay chậm và nhẹ.
func _paint_pianist(p: Node2D) -> void:
	var px := PIANIST_FEET.x
	var py := PIANIST_FEET.y
	var lean := sin(_clock * 0.55) * 0.35
	var hy := sin(_clock * 1.35) * 0.45
	var hy2 := sin(_clock * 1.35 + 2.4) * 0.45
	var bx := px + lean
	p.shadow(PIANIST_FEET + Vector2(2, 2), 11.0)
	# Ghế bọc nệm và chân ghế.
	p.rc(px - 8, py - 1, 2, 4, Color("1d1e25"))
	p.rc(px + 3, py - 1, 2, 4, Color("1d1e25"))
	p.rc(px - 9, py - 10, 16, 7, Color("171920"))
	p.rc(px - 8, py - 10, 14, 4, Color("484b58"))
	p.rc(px - 7, py - 10, 12, 1, Color("777986"))
	# Váy, chân và giày.
	p.rc(px - 5, py - 12, 14, 6, C_OUTLINE)
	p.rc(px - 4, py - 11, 12, 4, Color("6b3a6e"))
	p.rc(px - 2, py - 11, 1, 3, Color("a16d91"))
	p.rc(px + 5, py - 7, 4, 9, C_OUTLINE)
	p.rc(px + 6, py - 7, 2, 7, C_SKIN)
	p.rc(px + 5, py - 2, 6, 4, C_OUTLINE)
	p.rc(px + 6, py - 2, 5, 2, Color("22222a"))
	# Tay xa và tóc buông sau vai.
	p.rc(bx + 5, py - 12 + hy2, 7, 4, C_OUTLINE)
	p.rc(bx + 6, py - 11 + hy2, 3, 2, Color("e4e6ed"))
	p.rc(bx + 9, py - 11 + hy2, 3, 2, C_SKIN.darkened(0.12))
	p.rc(bx - 8, py - 26, 5, 16, C_OUTLINE)
	p.rc(bx - 7, py - 25, 3, 14, C_HAIR_GOLD)
	p.rc(bx - 7, py - 25, 1, 12, C_HAIR_GOLD_HI)
	p.rc(bx - 6, py - 23, 1, 7, Color("1c1e24"))
	# Áo sáng màu có cổ áo, nếp vải và đường viền tay.
	p.rc(bx - 6, py - 20, 11, 12, C_OUTLINE)
	p.rc(bx - 5, py - 19, 9, 10, Color("cbd3df"))
	p.rc(bx - 4, py - 19, 6, 2, Color("f3f4f7"))
	p.draw_colored_polygon(PackedVector2Array([
		Vector2(bx - 3, py - 19), Vector2(bx, py - 16), Vector2(bx + 2, py - 19)
	]), Color("ffffff"))
	p.rc(bx - 1, py - 16, 2, 4, Color("8d3448"))
	p.rc(bx - 4, py - 9, 7, 1, Color("8792a3"))
	# Tay gần duỗi về bàn phím, nhấn phím rất nhẹ.
	p.rc(bx - 1, py - 18, 5, 4, C_OUTLINE)
	p.rc(bx, py - 17, 3, 2, Color("cbd3df"))
	p.rc(bx + 1, py - 16 + hy, 11, 4, C_OUTLINE)
	p.rc(bx + 2, py - 15 + hy, 6, 2, Color("cbd3df"))
	p.rc(bx + 8, py - 15 + hy, 3, 2, C_SKIN)
	# Khuôn mặt nghiêng về đàn, tóc đen nhiều lớp và kính bắt sáng.
	p.rc(bx - 5, py - 28, 10, 10, C_OUTLINE)
	p.rc(bx - 4, py - 27, 8, 8, C_SKIN)
	p.rc(bx - 4, py - 27, 8, 3, C_HAIR_GOLD)
	p.rc(bx - 4, py - 27, 3, 9, C_HAIR_GOLD)
	p.rc(bx - 3, py - 28, 5, 1, C_HAIR_GOLD_HI)
	p.rc(bx - 4, py - 25, 2, 1, Color("41434c"))
	p.rc(bx + 1, py - 27, 4, 4, C_HAIR_GOLD)
	p.rc(bx - 2, py - 23, 3, 2, Color("272a32"))
	p.rc(bx + 2, py - 23, 3, 2, Color("272a32"))
	p.rc(bx - 1, py - 22, 1, 1, Color("a9d8ec"))
	p.rc(bx + 3, py - 22, 1, 1, Color("a9d8ec"))
	p.rc(bx, py - 23, 2, 1, Color("272a32"))
	p.rc(bx - 1, py - 22, 1, 1, Color("ffffff"))
	p.rc(bx, py - 22, 1, 1, Color("34323a"))
	p.rc(bx + 4, py - 22, 1, 1, Color("34323a"))
	p.rc(bx + 5, py - 22, 1, 2, C_SKIN)
	p.rc(bx + 3, py - 20, 2, 1, Color("b7645c"))

# Người nằm ngủ nhìn từ trên xuống. Hệ trục thân: a chạy từ đầu về chân, c chạy ngang thân.
# pose 0 nằm ngửa, 1 nằm sấp (tay ôm đầu), 2 nằm dang tay chân. Nhân vật luôn nằm yên.
func _paint_sleeper(p: Node2D, n: Dictionary) -> void:
	var u: Vector2 = n.u
	var c: Vector2 = n.c
	var o: Vector2 = c - u * 15.0
	var pose: int = n.pose
	var shirt: Color = n.shirt
	var hair: Color = n.hair
	var pants := Color("2b2f4a")
	var shoe := Color("f4f4f4")
	p.shadow(c + Vector2(0, 4), 16.0)
	var parts: Array = []   # [a, c, dài, rộng, màu]
	if n.pack and pose == 0:
		parts.append([-4.0, -4.0, 5.0, 8.0, Color("2f6bd0")])   # ba lô làm gối
	# thân (áo thể dục / áo polo trường) và hông
	if n.uni:
		parts.append([6.0, -4.0, 3.0, 8.0, Color.WHITE])
		parts.append([9.0, -4.0, 5.0, 8.0, C_NAVY])
	else:
		parts.append([6.0, -4.0, 8.0, 8.0, shirt])
	parts.append([14.0, -4.0, 3.0, 8.0, pants])
	# tay chân theo tư thế
	if pose == 0:
		parts.append([7.0, -7.0, 8.0, 3.0, shirt])
		parts.append([7.0, 4.0, 8.0, 3.0, shirt])
		parts.append([15.0, -7.0, 2.0, 3.0, C_SKIN])
		parts.append([15.0, 4.0, 2.0, 3.0, C_SKIN])
		parts.append([17.0, -4.0, 11.0, 4.0, pants])
		parts.append([17.0, 0.0, 11.0, 4.0, pants])
		parts.append([27.0, -4.0, 3.0, 4.0, shoe])
		parts.append([27.0, 0.0, 3.0, 4.0, shoe])
	elif pose == 1:
		parts.append([-3.0, -7.0, 10.0, 3.0, shirt])
		parts.append([-3.0, 4.0, 10.0, 3.0, shirt])
		parts.append([-5.0, -7.0, 2.0, 3.0, C_SKIN])
		parts.append([-5.0, 4.0, 2.0, 3.0, C_SKIN])
		var l1 := 11.0
		var l2 := 7.0
		parts.append([17.0, -4.0, l1, 4.0, pants])
		parts.append([17.0, 0.0, l2, 4.0, pants])
		parts.append([17.0 + l1 - 1.0, -4.0, 3.0, 4.0, shoe])
		parts.append([17.0 + l2 - 1.0, 0.0, 3.0, 4.0, shoe])
	else:
		parts.append([8.0, -12.0, 3.0, 8.0, shirt])
		parts.append([8.0, 4.0, 3.0, 8.0, shirt])
		parts.append([8.0, -14.0, 3.0, 2.0, C_SKIN])
		parts.append([8.0, 12.0, 3.0, 2.0, C_SKIN])
		parts.append([17.0, -8.0, 11.0, 4.0, pants])
		parts.append([17.0, 4.0, 11.0, 4.0, pants])
		parts.append([27.0, -8.0, 3.0, 4.0, shoe])
		parts.append([27.0, 4.0, 3.0, 4.0, shoe])
	# đầu (đè lên tay khi nằm sấp)
	parts.append([0.0, -3.0, 6.0, 6.0, hair if pose == 1 else C_SKIN])
	for q in parts:
		_seg(p, o, u, q[0] - 1.0, q[1] - 1.0, q[2] + 2.0, q[3] + 2.0, C_OUTLINE)
	for q in parts:
		_seg(p, o, u, q[0], q[1], q[2], q[3], q[4])
	if pose != 1:
		_seg(p, o, u, 0.0, -3.0, 3.0, 6.0, hair)          # tóc
		_seg(p, o, u, 3.0, -2.0, 1.0, 1.0, C_OUTLINE)       # mắt nhắm
		_seg(p, o, u, 3.0, 1.0, 1.0, 1.0, C_OUTLINE)
		_seg(p, o, u, 5.0, -1.0, 1.0, 2.0, Color("c0675a"))   # miệng
	else:
		_seg(p, o, u, 1.0, -2.0, 2.0, 1.0, hair.lightened(0.25))
# vẽ hình chữ nhật theo hệ trục thân người (o = đầu, u = hướng về chân, v vuông góc với u)
func _seg(p: Node2D, o: Vector2, u: Vector2, a: float, c: float, l: float, w: float, col: Color) -> void:
	var v := Vector2(-u.y, u.x)
	var p1 := o + u * a + v * c
	var p2 := o + u * (a + l) + v * (c + w)
	p.rc(minf(p1.x, p2.x), minf(p1.y, p2.y), absf(p2.x - p1.x), absf(p2.y - p1.y), col)

# Nốt nhạc bay lên từ đàn, chữ Zzz bay lên từ đầu người ngủ, bóng thoại khi nói chuyện
func _paint_effects(p: Node2D) -> void:
	for i in 3:
		var nt := fmod(_clock * 0.16 + i / 3.0, 1.0)
		var nx := 142.0 + i * 12.0 + sin((_clock * 0.7 + i) * 2.0) * 2.0 + nt * 5.0
		var ny := 100.0 - nt * 30.0
		var ncol := Color(1.0, 0.95, 0.75, sin(nt * PI))
		p.rc(nx, ny + 5.0, 3, 2, ncol)
		p.rc(nx + 2.0, ny, 1, 6, ncol)
		p.rc(nx + 2.0, ny, 3, 1, ncol)
	var f: Font = p.font
	for n in _npcs:
		if n.kind != "sleep":
			continue
		var u: Vector2 = n.u
		var head: Vector2 = n.c - u * 15.0 + u * 3.0
		for k in 3:
			var t := fmod(_clock * 0.5 + float(n.ph) + k / 3.0, 1.0)
			var zp := head + Vector2(5.0 + t * 7.0, -6.0 - t * 14.0)
			p.draw_string(f, zp, "Z" if k == 1 else "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 6 + int(t * 4.0), Color(1, 1, 1, 1.0 - t))
	if _say_t > 0.0 and _say_i >= 0 and _say_i < _npcs.size():
		var s: Dictionary = _npcs[_say_i]
		var bpos := Vector2(PIANIST_FEET.x, PIANIST_FEET.y - 7.0)
		if s.kind == "sleep":
			var su: Vector2 = s.u
			var hc: Vector2 = s.c - su * 15.0 + su * 3.0
			bpos = Vector2(hc.x, hc.y + 17.0)
		p.draw_speech({"pos": bpos, "say": _say})

func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var text := ""
	if _in_exit():
		text = "[E] Ra ngoài"
	elif _npc_near() >= 0:
		text = "[E] Trò chuyện"
	if text != "":
		p.ctext(text, _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)

# Biển tên hiện ra vài giây khi mới bước vào sảnh
func _paint_banner(p: Node2D) -> void:
	if _banner <= 0.0 or _closing:
		return
	var a := clampf(_banner, 0.0, 1.0)
	var text := "NHÀ ĐIỀU HÀNH"
	var w: float = p.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 16.0
	p.rc(240.0 - w / 2.0 - 1.0, 28, w + 2.0, 15, Color(0.2, 0.2, 0.2, a))
	p.rc(240.0 - w / 2.0, 29, w, 13, Color(0.08, 0.1, 0.18, 0.92 * a))
	p.ctext(text, 240.0 - w / 2.0, 39, w, 8, Color(1.0, 0.82, 0.25, a))

# ======================= NGOÀI TRỜI =======================

# Bản đồ gốc đã vẽ mặt tiền Nhà Điều hành; module chỉ vẽ thêm khung chỉ dẫn phía trên đầu người chơi.
func draw_front_layer() -> void:
	if inside or game.is_busy() or not _near_door_outside():
		return
	var text := "Bấm [E] để vào Nhà Điều hành"
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))
