extends Node2D
# MỘT NGÀY Ở HCMUS - CƠ SỞ ĐÔNG HÒA (Godot 4.7)
# Bản đồ dựng theo sơ đồ cơ sở: Tòa A-G, Nhà Thể Dục, Nhà Điều hành, đài phun nước, bãi giữ xe.
# Di chuyển bằng W A S D. Muốn dời tòa nhà: sửa bảng BUILDINGS (x, y, rộng, cao).

const WORLD := Vector2(1600, 1000)
const SPEED := 70.0
const GATE_X := 690.0
const GATE_W := 100.0
const GATE_Y := 960.0
const FOUNT := Vector2(928, 421)
const DIEUHANH := Rect2(860, 680, 260, 170)
const LINES := ["Thi chưa?", "Deadline!", "Đi ăn không?", "Đến giờ học rồi!", "Mượn tui cây bút", "Nhà ăn đông quá", "Sáng nay có kiểm tra!", "Ngủ quên mất...", "Lên thư viện không?"]

var WALL := Color("f2d98c")
var ROOF := Color("c0453a")
# [tên, x, y, rộng, cao, màu tường, màu mái, mô tả]
var BUILDINGS := [
	["A", 152, 157, 120, 260, WALL, ROOF, "Tòa A - giảng đường."],
	["B", 296, 240, 105, 100, WALL, ROOF, "Tòa B - giảng đường, có khu vực tự học."],
	["C", 432, 240, 105, 213, WALL, ROOF, "Tòa C - có Thư viện, Quầy giáo trình và ATM."],
	["D", 576, 240, 100, 213, WALL, ROOF, "Tòa D - giảng đường, gần nhà ăn và khu tự học."],
	["E", 712, 278, 105, 286, WALL, ROOF, "Tòa E - giảng đường lớn."],
	["F", 1056, 278, 112, 286, WALL, ROOF, "Tòa F - giảng đường."],
	["G", 1256, 278, 120, 286, Color("dfe3e8"), Color("5d7c99"), "Tòa G - phòng học và phòng thí nghiệm."],
	["NHÀ THỂ DỤC", 872, 166, 192, 120, Color("e9efe9"), Color("5f9c6a"), "Nhà Thể Dục - sân tập trong nhà."],
]
# [tên, x, y, màu mái, mô tả] : quầy, kiosk nhỏ
var KIOSKS := [
	["Nhà ăn", 110, 150, Color("e08a2e"), "Nhà ăn - cơm, bún, trà đá."],
	["Nhà ăn", 690, 200, Color("e08a2e"), "Nhà ăn - ăn trưa ở đây!"],
	["Tự học", 306, 200, Color("3f8fbf"), "Khu vực tự học - ổ điện và wifi."],
	["Giáo trình", 546, 345, Color("8a5ac0"), "Quầy giáo trình - mua tài liệu học."],
	["Tự học", 682, 340, Color("3f8fbf"), "Khu vực tự học."],
	["Hội quán", 1005, 646, Color("3f9c6a"), "Hội quán Khoa học - sinh hoạt câu lạc bộ."],
	["ATM", 466, 462, Color("8e1f2c"), "Cây ATM."],
]
var ZONES := [
	["Đài phun nước và vườn điều", Rect2(832, 315, 192, 213)],
	["Sân trước Nhà Điều hành (bậc thềm có hoa cảnh)", Rect2(840, 850, 320, 110)],
	["Bãi giữ xe", Rect2(150, 690, 520, 200)],
	["Cổng trường - Đường T1", Rect2(640, 900, 200, 100)],
	["Đường nội bộ", Rect2(0, 585, 1600, 50)],
]
const PALMS := [[850, 332], [900, 332], [956, 332], [1006, 332], [850, 380], [1006, 380], [850, 462], [1006, 462], [850, 508], [900, 508], [956, 508], [1006, 508]]

var solids: Array = []
var trees: Array = []   # [x, y, loại] 0 thường, 1 phượng, 2 cọ
var tufts: Array = []
var npcs: Array = []
var bikes: Array = []
var player := Vector2(740, 940)
var facing := 1
var anim := 0.0
var game_min := 7.0 * 60.0
var logo: Texture2D = null
var font: Font
var cam: Camera2D
var hud: Label
var tint: ColorRect
var clock := 0.0
var view := Rect2()
var flowers: Array = []
var petals: Array = []
var lamps: Array = []
var benches: Array = []
var clouds: Array = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	if ResourceLoader.exists("res://font.ttf"):
		font = load("res://font.ttf")
	if ResourceLoader.exists("res://assets/hcmus_logo.png"):
		logo = load("res://assets/hcmus_logo.png")
	for b in BUILDINGS:
		solids.append(Rect2(b[1], b[2], b[3], b[4]))
	for k in KIOSKS:
		solids.append(Rect2(k[1], k[2], 26, 20))
	solids.append(DIEUHANH)
	solids.append(Rect2(FOUNT.x - 45, FOUNT.y - 45, 90, 90))
	solids.append(Rect2(0, GATE_Y, GATE_X, 14))
	solids.append(Rect2(GATE_X + GATE_W, GATE_Y, WORLD.x - GATE_X - GATE_W, 14))
	solids.append(Rect2(800, 920, 28, 34)) # chòi bảo vệ
	for x in range(120, 1500, 80):
		if (x > 680 and x < 770) or (x > 140 and x < 240):
			continue
		trees.append([x, 668, 1])
	for p in PALMS:
		trees.append([p[0], p[1], 2])
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 260:
		tufts.append(Vector2(rng.randi_range(0, 1598), rng.randi_range(0, 998)))
	var n := 0
	while n < 70:
		var p := Vector2(rng.randi_range(20, 1580), rng.randi_range(40, 940))
		if p.y > 560 and p.y < 700:
			continue
		var ok := true
		for s in solids:
			if s.grow(16).has_point(p):
				ok = false
		for z in ZONES:
			if z[1].has_point(p):
				ok = false
		if p.x > 680 and p.x < 800 and p.y > 560:
			ok = false
		if ok:
			trees.append([p.x, p.y, 0])
			n += 1
	for t in trees:
		solids.append(Rect2(t[0] - 3, t[1] - 4, 6, 4))
	var shirts := [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80"), Color("e8e8e8")]
	var hairs := [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b")]
	var spawn := [Rect2(150, 470, 1300, 100), Rect2(840, 320, 176, 200)]
	for i in 18:
		var p := Vector2(480, 520)
		for tries in 80:
			var r: Rect2 = spawn[randi() % 2]
			var c := Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not blocked(c):
				p = c
				break
		npcs.append({"pos": p, "dir": Vector2.ZERO, "timer": randf_range(0.2, 2.0), "face": 0, "anim": 0.0, "shirt": shirts[randi() % shirts.size()], "hair": hairs[randi() % hairs.size()], "uni": randf() < 0.55, "long": randf() < 0.4, "pack": randf() < 0.6, "say": "", "say_t": 0.0})
	bikes.append({"x": 100.0, "y": 596.0, "dir": 1.0, "sp": 70.0, "col": Color("c0392b")})
	bikes.append({"x": 700.0, "y": 596.0, "dir": 1.0, "sp": 55.0, "col": Color("2980b9")})
	bikes.append({"x": 1200.0, "y": 620.0, "dir": -1.0, "sp": 65.0, "col": Color("27ae60")})
	for i in 420:
		flowers.append([Vector2(rng.randi_range(0, 1596), rng.randi_range(0, 940)), [Color("ffffff"), Color("ffe066"), Color("ff9ecb"), Color("c9a0ff")][rng.randi_range(0, 3)]])
	for x in range(160, 1500, 140):
		lamps.append(Vector2(x, 576))
	for x in range(200, 800, 150):
		lamps.append(Vector2(x, 480))
	for q in [Vector2(838, 322), Vector2(1018, 322), Vector2(838, 524), Vector2(1018, 524)]:
		lamps.append(q)
	benches = [Vector2(868, 534), Vector2(960, 534), Vector2(300, 470), Vector2(620, 470), Vector2(1200, 570), Vector2(400, 570)]
	for l in lamps:
		solids.append(Rect2(l.x - 2, l.y - 3, 4, 3))
	for b in benches:
		solids.append(Rect2(b.x - 9, b.y - 5, 18, 5))
	for i in 6:
		clouds.append({"x": rng.randf_range(0, 1600), "y": rng.randf_range(100, 900), "r": rng.randf_range(60, 110), "sp": rng.randf_range(6, 14)})
	cam = Camera2D.new()
	cam.position = player
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(WORLD.x)
	cam.limit_bottom = int(WORLD.y)
	cam.position_smoothing_enabled = true
	add_child(cam)
	var tl := CanvasLayer.new()
	tl.layer = 5
	add_child(tl)
	tint = ColorRect.new()
	tint.size = Vector2(480, 270)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = Color(1, 0.55, 0.15, 0)
	tl.add_child(tint)
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.55, 1.0])
	gr.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.42)])
	gt.gradient = gr
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 480
	gt.height = 270
	var vg := TextureRect.new()
	vg.texture = gt
	vg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	vg.size = Vector2(480, 270)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(vg)
	var hl := CanvasLayer.new()
	hl.layer = 6
	add_child(hl)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.1, 0.2, 0.62)
	panel.size = Vector2(480, 32)
	hl.add_child(panel)
	var line := ColorRect.new()
	line.color = Color("ffd23f")
	line.position = Vector2(0, 32)
	line.size = Vector2(480, 1)
	hl.add_child(line)
	hud = make_label(hl, Vector2(6, 3), 10)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.custom_minimum_size = Vector2(468, 0)
	hud.size = Vector2(468, 20)
	var hint := make_label(hl, Vector2(6, 254), 9)
	hint.text = "W A S D: di chuyển"

func make_label(parent: Node, pos: Vector2, sz: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l

# ---------- Di chuyển và va chạm ----------
func blocked(p: Vector2) -> bool:
	if p.x < 8.0 or p.x > WORLD.x - 8.0 or p.y < 22.0 or p.y > WORLD.y - 6.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in solids:
		if hit.intersects(s):
			return true
	return false

func move_entity(p: Vector2, v: Vector2) -> Vector2:
	var a := p + Vector2(v.x, 0.0)
	if blocked(a):
		a = p
	var b := a + Vector2(0.0, v.y)
	if blocked(b):
		b = a
	return b

func _physics_process(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if v != Vector2.ZERO:
		v = v.normalized() * SPEED
		if absf(v.x) > absf(v.y):
			facing = 2 if v.x < 0.0 else 3
		else:
			facing = 1 if v.y < 0.0 else 0
		anim += delta
	player = move_entity(player, v * delta)
	for n in npcs:
		n.timer -= delta
		if n.timer <= 0.0:
			n.timer = randf_range(1.0, 3.0)
			n.dir = [Vector2.ZERO, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][randi() % 5]
			if randf() < 0.18:
				n.say = LINES[randi() % LINES.size()]
				n.say_t = 2.2
		var np: Vector2 = move_entity(n.pos, n.dir * 22.0 * delta)
		if np == n.pos and n.dir != Vector2.ZERO:
			n.timer = 0.0
		elif n.dir != Vector2.ZERO:
			n.anim += delta
			if absf(n.dir.x) > 0.0:
				n.face = 2 if n.dir.x < 0.0 else 3
			else:
				n.face = 1 if n.dir.y < 0.0 else 0
		n.pos = np
		n.say_t -= delta

func place() -> String:
	if DIEUHANH.grow(20.0).has_point(player):
		return "Nhà Điều hành - Phòng Đào tạo, Công tác Sinh viên, Văn phòng Đoàn - Hội, Khảo thí, Kế hoạch - Tài chính, Văn phòng khoa (P.8.2)."
	for b in BUILDINGS:
		if Rect2(b[1], b[2], b[3], b[4]).grow(18.0).has_point(player):
			return b[7]
	for k in KIOSKS:
		if Rect2(k[1], k[2], 26, 20).grow(14.0).has_point(player):
			return k[4]
	for z in ZONES:
		if z[1].has_point(player):
			return z[0]
	return "Khuôn viên cơ sở Đông Hòa"

func _process(delta: float) -> void:
	game_min += delta
	if game_min >= 17.0 * 60.0:
		game_min = 7.0 * 60.0
	cam.position = player
	clock += delta
	update_ambient(delta)
	for b in bikes:
		b.x += b.dir * b.sp * delta
		if b.x > WORLD.x + 20.0:
			b.x = -20.0
		if b.x < -20.0:
			b.x = WORLD.x + 20.0
	var h := game_min / 60.0
	if h < 8.5:
		tint.color = Color(0.7, 0.8, 1.0, (8.5 - h) / 1.5 * 0.18)
	elif h > 15.0:
		tint.color = Color(1.0, 0.5, 0.15, clampf((h - 15.0) / 2.0, 0.0, 1.0) * 0.3)
	else:
		tint.color = Color(1, 1, 1, 0)
	hud.text = "%02d:%02d   %s" % [int(h), int(game_min) % 60, place()]
	queue_redraw()

# ---------- Hiệu ứng nền (cánh phượng rơi, bóng mây) ----------
func update_ambient(delta: float) -> void:
	for c in clouds:
		c.x += c.sp * delta
		if c.x > WORLD.x + 150.0:
			c.x = -150.0
	if petals.size() < 40 and randf() < 0.5:
		var t: Array = trees[randi() % trees.size()]
		if t[2] == 1 and absf(t[0] - player.x) < 300.0 and absf(t[1] - player.y) < 200.0:
			petals.append({"pos": Vector2(t[0] + randf_range(-9, 9), t[1] - randf_range(10, 24)), "life": 0.0, "ph": randf() * 6.0})
	for p in petals:
		p.life += delta
		p.pos = p.pos + Vector2(sin(p.life * 3.0 + p.ph) * 12.0 * delta + 6.0 * delta, 18.0 * delta)
	petals = petals.filter(func(p): return p.life < 2.2)

# ---------- Vẽ ----------
func rc(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func hs(a: int, b: int) -> int:
	return absi((a * 73856093) ^ (b * 19349663)) % 100

func shadow(p: Vector2, rx: float) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func octa(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(c + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * r)
	draw_colored_polygon(pts, col)

func ctext(t: String, x: float, y: float, w: float, sz: int, c: Color) -> void:
	draw_string(font, Vector2(x + 1, y + 1), t, HORIZONTAL_ALIGNMENT_CENTER, w, sz, Color(0, 0, 0, 0.45))
	draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_CENTER, w, sz, c)

func paved(r: Rect2, base: Color) -> void:
	var rr := r.intersection(view)
	if rr.size.x <= 0.0 or rr.size.y <= 0.0:
		return
	draw_rect(rr, base)
	var ln := base.darkened(0.13)
	var x0 := int(rr.position.x) - int(rr.position.x) % 12
	for x in range(x0, int(rr.end.x) + 1, 12):
		if x >= rr.position.x:
			rc(x, rr.position.y, 1, rr.size.y, ln)
	var y0 := int(rr.position.y) - int(rr.position.y) % 12
	for y in range(y0, int(rr.end.y) + 1, 12):
		if y >= rr.position.y:
			rc(rr.position.x, y, rr.size.x, 1, ln)

func asphalt(r: Rect2) -> void:
	var rr := r.intersection(view)
	if rr.size.x <= 0.0 or rr.size.y <= 0.0:
		return
	draw_rect(rr, Color("565b63"))
	for t in tufts:
		if rr.has_point(t):
			rc(t.x, t.y, 2, 1, Color("6a7078") if int(t.x) % 2 == 0 else Color("4a4f56"))
	rc(rr.position.x, r.position.y, rr.size.x, 2, Color("7b818a"))
	rc(rr.position.x, r.end.y - 2, rr.size.x, 2, Color("3f444b"))

func draw_grass() -> void:
	draw_rect(view, Color("6aa84f"))
	for tx in range(floori(view.position.x / 16.0), ceili(view.end.x / 16.0)):
		for ty in range(floori(view.position.y / 16.0), ceili(view.end.y / 16.0)):
			if (tx + ty) % 2 == 0:
				rc(tx * 16, ty * 16, 16, 16, Color(1, 1, 1, 0.04))
			if hs(tx, ty) < 14:
				rc(tx * 16 + 3, ty * 16 + 6, 10, 5, Color(0, 0, 0, 0.06))
	for t in tufts:
		if view.has_point(t):
			rc(t.x, t.y, 2, 3, Color("84c764") if int(t.x + t.y) % 2 == 0 else Color("559040"))
			rc(t.x + 2, t.y + 1, 1, 2, Color("84c764"))
	for f in flowers:
		if view.has_point(f[0]):
			rc(f[0].x, f[0].y, 2, 2, f[1])
			rc(f[0].x, f[0].y + 2, 1, 2, Color("3f7a35"))

func hedge(x: float, y: float, w: float) -> void:
	rc(x, y + 1, w, 7, Color("2a6f33"))
	rc(x, y, w, 3, Color("4aa44f"))
	for i in range(0, int(w), 6):
		rc(x + i, y - 1, 4, 2, Color("5bb85c"))
		rc(x + i + 2, y + 4, 2, 2, Color("225c2b"))

func flowerbed(x: float, y: float, w: float, h: float) -> void:
	rc(x, y, w, h, Color("7a5230"))
	rc(x + 1, y + 1, w - 2, h - 2, Color("4a8a3a"))
	for i in range(0, int(w) - 3, 5):
		for j in range(0, int(h) - 3, 5):
			var k := hs(i + int(x), j + int(y))
			rc(x + 2 + i, y + 2 + j, 2, 2, [Color("ff6b8a"), Color("ffd23f"), Color("ffffff"), Color("ff9a3c")][k % 4])

func draw_lamp(p: Vector2) -> void:
	shadow(p + Vector2(3, 0), 5.0)
	rc(p.x - 1, p.y - 24, 2, 24, Color("3a3f4a"))
	rc(p.x - 3, p.y - 27, 6, 4, Color("3a3f4a"))
	var night := game_min / 60.0 > 16.0
	rc(p.x - 2, p.y - 26, 4, 2, Color("fff1a8") if night else Color("c9d3da"))
	if night:
		draw_circle(p + Vector2(0, -24), 16.0, Color(1.0, 0.9, 0.5, 0.18))

func draw_bench(p: Vector2) -> void:
	shadow(p + Vector2(0, 1), 11.0)
	rc(p.x - 9, p.y - 9, 18, 3, Color("8a5a32"))
	rc(p.x - 9, p.y - 6, 18, 2, Color("a8733f"))
	rc(p.x - 9, p.y - 4, 18, 3, Color("8a5a32"))
	rc(p.x - 8, p.y - 1, 2, 2, Color("333333"))
	rc(p.x + 6, p.y - 1, 2, 2, Color("333333"))

func draw_building(b: Array) -> void:
	var r := Rect2(b[1], b[2], b[3], b[4])
	if not view.intersects(r.grow(16.0)):
		return
	var wall: Color = b[5]
	var roof: Color = b[6]
	var x := r.position.x
	var y := r.position.y
	rc(x + 8, y + 10, r.size.x, r.size.y, Color(0, 0, 0, 0.14))
	rc(x + 4, y + 5, r.size.x, r.size.y, Color(0, 0, 0, 0.14))
	var cx := x + r.size.x / 2.0
	if b[0] == "NHÀ THỂ DỤC":
		rc(x, y, r.size.x, r.size.y, wall)
		rc(x, y, r.size.x, 56, roof)
		for xx in range(int(x) + 6, int(r.end.x) - 4, 14):
			rc(xx, y, 5, 56, Color("e6f2e8"))
		rc(x, y, r.size.x, 5, Color(1, 1, 1, 0.25))
		rc(x - 3, y + 53, r.size.x + 6, 5, roof.darkened(0.3))
		rc(x, y + 59, r.size.x, 4, Color(0, 0, 0, 0.2))
		for xx in range(int(x) + 10, int(r.end.x) - 20, 26):
			rc(xx, y + 68, 16, 22, Color("9fd3f0"))
			rc(xx, y + 68, 16, 4, Color("c8e8f7"))
			rc(xx + 7, y + 68, 2, 22, Color("4a6b82"))
		ctext(b[0], x, y + 104, r.size.x, 11, Color("2f5d3a"))
		rc(cx - 14, r.end.y - 20, 28, 20, Color("5a3a22"))
		rc(cx - 1, r.end.y - 20, 2, 20, Color("3a2412"))
		draw_rect(r, Color("2b2b2b"), false, 1.0)
		return
	var roof_h := r.size.y * 0.42
	rc(x, y, r.size.x, r.size.y, wall)
	rc(x, y + roof_h, r.size.x, r.size.y - roof_h, wall)
	rc(x, r.end.y - 14, r.size.x, 14, wall.darkened(0.08))
	rc(x, y, r.size.x, roof_h, roof)
	var row := 0
	for yy in range(int(y) + 3, int(y + roof_h) - 2, 5):
		rc(x, yy, r.size.x, 1, roof.darkened(0.25))
		for xx in range(int(x) + (row % 2) * 4, int(r.end.x), 8):
			rc(xx, yy + 1, 1, 4, roof.darkened(0.12))
		row += 1
	rc(x, y, 7, roof_h, Color(0, 0, 0, 0.16))
	rc(r.end.x - 7, y, 7, roof_h, Color(1, 1, 1, 0.1))
	rc(x, y, r.size.x, 3, roof.lightened(0.25))
	rc(x - 2, y + roof_h - 3, r.size.x + 4, 4, roof.darkened(0.35))
	rc(x, y + roof_h + 1, r.size.x, 3, Color(0, 0, 0, 0.22))
	if r.size.y > 150.0:
		for k in 2:
			var tx := x + 14 + k * (r.size.x - 40)
			rc(tx, y + 8, 12, 5, Color("cfd6dc"))
			draw_circle(Vector2(tx + 6, y + 15), 4, Color("e4e9ed"))
	rc(cx - 13, y + roof_h / 2.0 - 4, 26, 24, Color("f7efd2"))
	draw_rect(Rect2(cx - 13, y + roof_h / 2.0 - 4, 26, 24), Color("333333"), false, 1.0)
	ctext(b[0], x, y + roof_h / 2.0 + 15, r.size.x, 20, Color("2b2b2b"))
	var wy0 := int(y + roof_h) + 10
	for xx in range(int(x), int(r.end.x), 36):
		rc(xx, wy0 - 6, 3, int(r.end.y) - wy0 - 4, wall.darkened(0.12))
	rc(r.end.x - 3, wy0 - 6, 3, int(r.end.y) - wy0 - 4, wall.darkened(0.12))
	for yy in range(wy0, int(r.end.y) - 30, 22):
		rc(x + 3, yy + 12, r.size.x - 6, 2, Color("7a5a2c"))
		for xx in range(int(x) + 9, int(r.end.x) - 14, 18):
			rc(xx, yy, 12, 11, Color("4a6b82"))
			rc(xx + 1, yy + 1, 10, 9, Color("8fc9e6"))
			rc(xx + 1, yy + 1, 10, 3, Color("c8e8f7"))
			rc(xx + 5, yy + 1, 1, 9, Color("4a6b82"))
			if hs(xx, yy) < 14:
				rc(xx + 2, yy + 12, 8, 4, Color("b8c0c6"))
	hedge(x - 2, r.end.y, r.size.x + 4)
	rc(cx - 12, r.end.y - 22, 24, 22, Color("3a2f2a"))
	rc(cx - 10, r.end.y - 20, 9, 20, Color("9fd3f0"))
	rc(cx + 1, r.end.y - 20, 9, 20, Color("9fd3f0"))
	rc(cx - 14, r.end.y - 26, 28, 5, roof.darkened(0.1))
	for i in 3:
		rc(cx - 14 + i * 2, r.end.y + 7 + i * 2, 28 - i * 4, 2, Color("bdbdbd") if i % 2 == 0 else Color("a5a5a5"))
	draw_rect(r, Color("2b2b2b"), false, 1.0)

func draw_dieuhanh() -> void:
	var r := DIEUHANH
	if not view.intersects(r.grow(80.0)):
		return
	var x := r.position.x
	var y := r.position.y
	var cx := x + r.size.x / 2.0
	var gold := Color("e0b020")
	rc(x + 9, y + 10, r.size.x, r.size.y, Color(0, 0, 0, 0.16))
	rc(x, y, r.size.x, r.size.y, Color("dcd9cf"))
	rc(x, y, 46, 76, Color("c9dbc2"))
	rc(x + r.size.x - 46, y, 46, 76, Color("c9dbc2"))
	rc(x, y, 46, 4, Color("e4eedf"))
	rc(x + r.size.x - 46, y, 46, 4, Color("e4eedf"))
	rc(x + 60, y + 2, r.size.x - 120, 14, Color("b9c4b0"))
	for yy in [y + 20, y + 40]:
		for xx in range(int(x) + 6, int(r.end.x) - 10, 18):
			rc(xx, yy, 12, 10, Color("4a6b82"))
			rc(xx + 1, yy + 1, 10, 8, Color("8fc9e6"))
			rc(xx + 1, yy + 1, 10, 3, Color("c8e8f7"))
	for xx in range(int(x) + 60, int(r.end.x) - 60, 22):
		rc(xx, y + 18, 3, 52, Color("c07a3a"))
	rc(x + 8, y + 58, r.size.x - 16, 16, Color("f3ecd0"))
	ctext("TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN", x + 8, y + 70, r.size.x - 16, 9, gold)
	rc(x - 10, y + 78, r.size.x + 20, 11, Color("6e747b"))
	rc(x - 10, y + 78, r.size.x + 20, 3, Color("8d949c"))
	rc(x - 10, y + 89, r.size.x + 20, 8, Color(0, 0, 0, 0.22))
	for yy in [y + 100, y + 118]:
		for xx in range(int(x) + 12, int(r.end.x) - 14, 22):
			rc(xx, yy, 14, 10, Color("4a6b82"))
			rc(xx + 1, yy + 1, 12, 8, Color("8fc9e6"))
	ctext("UNIVERSITY OF SCIENCE", x, y + 143, r.size.x, 9, gold)
	for i in 6:
		var px := x + 14 + i * (r.size.x - 34) / 5.0
		rc(px, y + 90, 7, 80, Color("aeb8c4"))
		rc(px, y + 90, 2, 80, Color("d4dbe3"))
		rc(px + 5, y + 90, 2, 80, Color("8a94a0"))
	rc(cx - 30, y + 144, 60, 26, Color("2e3a44"))
	rc(cx - 28, y + 146, 27, 24, Color("8fc9e6"))
	rc(cx + 1, y + 146, 27, 24, Color("8fc9e6"))
	rc(cx - 28, y + 146, 27, 5, Color("c8e8f7"))
	rc(cx + 1, y + 146, 27, 5, Color("c8e8f7"))
	rc(cx - 40, y + 124, 10, 38, Color("c0392b"))
	rc(cx + 30, y + 124, 10, 38, Color("c0392b"))
	rc(cx - 38, y + 130, 6, 6, gold)
	rc(cx + 32, y + 130, 6, 6, gold)
	draw_rect(r, Color("2b2b2b"), false, 1.0)
	for i in 6:
		rc(x + 18 - i * 2, r.end.y + i * 8, r.size.x - 36 + i * 4, 8, Color("c9c9c9") if i % 2 == 0 else Color("adadad"))
	rc(x + 14, r.end.y, 3, 48, Color("6e747b"))
	rc(r.end.x - 17, r.end.y, 3, 48, Color("6e747b"))
	for bx in [x + 4, x + 34, r.end.x - 34, r.end.x - 4]:
		shadow(Vector2(bx + 3, r.end.y + 24), 8.0)
		rc(bx - 5, r.end.y + 17, 10, 8, Color("b5651d"))
		rc(bx - 5, r.end.y + 17, 10, 2, Color("d98a3d"))
		draw_circle(Vector2(bx, r.end.y + 12), 8, Color("2a6f33"))
		draw_circle(Vector2(bx - 2, r.end.y + 10), 5, Color("3c9a40"))
	var fp := Vector2(x - 30, r.end.y + 30)
	rc(fp.x, fp.y - 52, 2, 52, Color("c4c8cc"))
	var wv := sin(clock * 4.0) * 1.5
	rc(fp.x + 2, fp.y - 52, 22, 14, Color("da251d"))
	rc(fp.x + 2, fp.y - 52 + wv, 22, 1, Color("f04a42"))
	rc(fp.x + 11, fp.y - 48, 4, 4, Color("ffde00"))

func draw_kiosk(k: Array) -> void:
	var p := Vector2(k[1], k[2])
	if not view.has_point(p):
		return
	shadow(p + Vector2(15, 22), 18.0)
	rc(p.x, p.y + 6, 26, 14, Color("f2e6c9"))
	rc(p.x, p.y + 6, 26, 2, Color("d6c9a6"))
	rc(p.x + 3, p.y + 9, 9, 7, Color("8fc9e6"))
	rc(p.x + 15, p.y + 9, 8, 11, Color("5a3a22"))
	rc(p.x - 3, p.y, 32, 8, k[3])
	for i in range(0, 32, 8):
		rc(p.x - 3 + i, p.y, 4, 8, Color(1, 1, 1, 0.55))
	rc(p.x - 3, p.y + 7, 32, 2, Color(0, 0, 0, 0.25))
	ctext(k[0], p.x - 14, p.y - 3, 54, 8, Color.WHITE)

func draw_tree(t: Array) -> void:
	var p := Vector2(t[0], t[1])
	if not view.grow(30.0).has_point(p):
		return
	shadow(p + Vector2(5, 1), 13.0)
	if t[2] == 2:
		for k in 5:
			rc(p.x - 1 + k * 0.2, p.y - 4 - k * 3, 3, 4, Color("8a6a3a") if k % 2 == 0 else Color("a07c46"))
		var top := p + Vector2(0.6, -17)
		for a in [-2.8, -2.2, -1.57, -0.9, -0.3, 0.2, -3.3]:
			var e: Vector2 = top + Vector2.from_angle(a) * 13.0 + Vector2(0, 3)
			draw_line(top, e, Color("1f6a2b"), 4.0)
			draw_line(top, e + Vector2(0, -1), Color("3aa04a"), 2.0)
		draw_circle(top + Vector2(-2, 2), 2, Color("6b4423"))
		draw_circle(top + Vector2(2, 3), 2, Color("6b4423"))
		return
	rc(p.x - 2, p.y - 8, 5, 8, Color("5a3a1c"))
	rc(p.x - 2, p.y - 8, 2, 8, Color("7a5230"))
	draw_circle(Vector2(p.x, p.y - 13), 11, Color("246b2b"))
	draw_circle(Vector2(p.x - 7, p.y - 10), 8, Color("2c7d33"))
	draw_circle(Vector2(p.x + 7, p.y - 10), 8, Color("2c7d33"))
	draw_circle(Vector2(p.x, p.y - 17), 9, Color("379a3f"))
	draw_circle(Vector2(p.x - 3, p.y - 19), 5, Color("4fb552"))
	if t[2] == 1:
		for i in 12:
			var h1 := hs(int(p.x) + i, int(p.y) * 3)
			var h2 := hs(int(p.y) + i * 5, int(p.x))
			rc(p.x - 11 + h1 * 0.22, p.y - 27 + h2 * 0.2, 3, 3, Color("e5322d") if i % 3 != 0 else Color("ff6a4d"))

# nhân vật pixel: áo polo trường (cổ xanh navy sọc trắng, vai trắng, thân và tay navy, logo ngực)
func draw_person(pos: Vector2, shirt: Color, hair: Color, face: int, step: float, uni: bool, long_hair: bool, pack: bool) -> void:
	var skin := Color("f1c27d")
	var ol := Color("1a1a2e")
	var navy := Color("1b2f6e")
	var odd := int(step * 8.0) % 2 == 1
	var sw := 1.0 if odd else 0.0
	var bob := 1.0 if odd else 0.0
	shadow(pos + Vector2(0, 1), 8.0)
	# chân và giày
	rc(pos.x - 5, pos.y - 7 + sw, 4, 7 - sw, ol)
	rc(pos.x + 1, pos.y - 7 + (1.0 - sw), 4, 7 - (1.0 - sw), ol)
	rc(pos.x - 4, pos.y - 6 + sw, 2, 4 - sw, Color("2b2f4a"))
	rc(pos.x + 2, pos.y - 6 + (1.0 - sw), 2, 4 - (1.0 - sw), Color("2b2f4a"))
	rc(pos.x - 4, pos.y - 2 + sw * 0.0, 3, 2, Color("f4f4f4"))
	rc(pos.x + 1, pos.y - 2, 3, 2, Color("f4f4f4"))
	var by := pos.y - bob
	# ba lô (phía sau lưng)
	if pack and face == 1:
		rc(pos.x - 6, by - 14, 12, 10, ol)
		rc(pos.x - 5, by - 13, 10, 8, Color("2f6bd0"))
		rc(pos.x - 5, by - 13, 10, 2, Color("5b8de8"))
	elif pack and face == 2:
		rc(pos.x + 3, by - 13, 4, 8, ol)
		rc(pos.x + 4, by - 12, 2, 6, Color("2f6bd0"))
	elif pack and face == 3:
		rc(pos.x - 7, by - 13, 4, 8, ol)
		rc(pos.x - 6, by - 12, 2, 6, Color("2f6bd0"))
	# thân
	rc(pos.x - 6, by - 14, 12, 10, ol)
	rc(pos.x - 8, by - 13, 2, 7, ol)
	rc(pos.x + 6, by - 13, 2, 7, ol)
	if uni:
		rc(pos.x - 5, by - 13, 10, 4, Color.WHITE)
		rc(pos.x - 5, by - 9, 10, 5, navy)
		rc(pos.x - 7, by - 12, 2, 6, navy)
		rc(pos.x + 5, by - 12, 2, 6, navy)
		rc(pos.x - 3, by - 14, 6, 2, navy)
		rc(pos.x - 3, by - 13, 6, 1, Color("dfe6ff"))
		rc(pos.x - 5, by - 5, 10, 1, navy.darkened(0.3))
		if face == 0:
			rc(pos.x, by - 13, 1, 5, navy)
			if logo != null:
				draw_texture_rect(logo, Rect2(pos.x + 1, by - 12, 4, 4), false)
			else:
				rc(pos.x + 1, by - 12, 3, 3, navy)
				rc(pos.x + 2, by - 11, 1, 1, Color.WHITE)
	else:
		rc(pos.x - 5, by - 13, 10, 8, shirt)
		rc(pos.x - 7, by - 12, 2, 6, shirt)
		rc(pos.x + 5, by - 12, 2, 6, shirt)
		rc(pos.x - 5, by - 13, 10, 2, shirt.lightened(0.2))
		rc(pos.x - 5, by - 6, 10, 1, shirt.darkened(0.25))
	rc(pos.x - 7, by - 7, 2, 2, skin)
	rc(pos.x + 5, by - 7, 2, 2, skin)
	# đầu
	rc(pos.x - 5, by - 22, 10, 9, ol)
	rc(pos.x - 4, by - 21, 8, 8, skin)
	rc(pos.x - 4, by - 21, 8, 3, hair)
	rc(pos.x - 3, by - 22, 3, 1, hair.lightened(0.3))
	if long_hair:
		rc(pos.x - 5, by - 21, 1, 9, hair)
		rc(pos.x + 4, by - 21, 1, 9, hair)
	if face == 1:
		rc(pos.x - 4, by - 21, 8, 8, hair)
		rc(pos.x - 3, by - 21, 3, 1, hair.lightened(0.3))
	elif face == 0:
		rc(pos.x - 3, by - 17, 1, 2, ol)
		rc(pos.x + 2, by - 17, 1, 2, ol)
		rc(pos.x - 3, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x + 2, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x - 1, by - 14, 2, 1, Color("a0522d"))
	elif face == 2:
		rc(pos.x - 3, by - 17, 1, 2, ol)
		rc(pos.x + 2, by - 21, 2, 6, hair)
	else:
		rc(pos.x + 2, by - 17, 1, 2, ol)
		rc(pos.x - 4, by - 21, 2, 6, hair)

func draw_bike(b: Dictionary) -> void:
	var x: float = b.x
	var y: float = b.y
	if not view.grow(20.0).has_point(Vector2(x, y)):
		return
	shadow(Vector2(x + 8, y + 7), 10.0)
	rc(x, y, 14, 4, b.col)
	rc(x + 2, y - 1, 8, 2, b.col.lightened(0.3))
	rc(x, y + 3, 4, 4, Color.BLACK)
	rc(x + 10, y + 3, 4, 4, Color.BLACK)
	rc(x + 1, y + 4, 2, 2, Color("9aa3ad"))
	rc(x + 11, y + 4, 2, 2, Color("9aa3ad"))
	rc(x + 5, y - 8, 4, 8, Color("e8e8e8"))
	rc(x + 5, y - 12, 4, 4, Color("f1c27d"))
	rc(x + 4, y - 14, 6, 3, Color("cc2b2b"))

func draw_ground() -> void:
	draw_grass()
	var beige := Color("dccaa0")
	paved(Rect2(150, 462, 680, 16), beige)
	paved(Rect2(120, 562, 1380, 16), beige)
	paved(Rect2(0, 578, WORLD.x, 7), beige)
	asphalt(Rect2(0, 585, WORLD.x, 50))
	for x in range(0, 1600, 40):
		rc(x, 609, 22, 3, Color("e8e8e8"))
	paved(Rect2(0, 635, WORLD.x, 7), beige)
	asphalt(Rect2(GATE_X, 642, GATE_W, GATE_Y - 642))
	for y in range(650, 940, 30):
		rc(GATE_X + GATE_W / 2.0 - 1, y, 3, 16, Color("e8e8e8"))
	for i in 6:
		rc(GATE_X + 6 + i * 15, 585, 8, 50, Color(1, 1, 1, 0.8))
	for i in 5:
		rc(GATE_X, 930 + i * 7, GATE_W, 3, Color(1, 1, 1, 0.8))
	paved(Rect2(150, 640, 80, 50), Color("9096a0"))
	paved(Rect2(150, 690, 520, 200), Color("8d939c"))
	draw_rect(Rect2(150, 690, 520, 200), Color("5f646b"), false, 2.0)
	for i in 16:
		for row in [706, 746, 786, 826]:
			rc(150 + i * 30 + 14, row - 4, 1, 16, Color(1, 1, 1, 0.5))
			rc(166 + i * 30, row, 10, 6, Color.from_hsv(fmod(i * 0.13 + row * 0.01, 1.0), 0.5, 0.8))
			rc(166 + i * 30, row + 5, 3, 3, Color.BLACK)
	ctext("BÃI GIỮ XE", 150, 884, 520, 10, Color.WHITE)
	paved(Rect2(FOUNT.x - 96, 315, 192, 213), beige)
	paved(Rect2(900, 528, 56, 36), beige)
	for q in [Vector2(840, 323), Vector2(946, 323), Vector2(840, 450), Vector2(946, 450)]:
		rc(q.x - 2, q.y - 2, 74, 74, Color("b9a77c"))
		rc(q.x, q.y, 70, 70, Color("5fa04a"))
		for i in 10:
			rc(q.x + hs(i, int(q.x)) * 0.6, q.y + hs(int(q.y), i) * 0.6, 3, 3, Color("7bbf5e"))
	flowerbed(880, 536, 40, 14)
	flowerbed(936, 536, 40, 14)
	flowerbed(DIEUHANH.position.x + 44, DIEUHANH.end.y + 52, 60, 10)
	flowerbed(DIEUHANH.end.x - 104, DIEUHANH.end.y + 52, 60, 10)
	# đài phun nước chuyển động
	shadow(FOUNT + Vector2(6, 38), 52.0)
	octa(FOUNT, 50, Color("b7a77f"))
	octa(FOUNT, 47, Color("d9c9a3"))
	octa(FOUNT, 42, Color("5aa5d6"))
	octa(FOUNT, 36, Color("6fb7e0"))
	octa(FOUNT, 25, Color("d9c9a3"))
	octa(FOUNT, 22, Color("5aa5d6"))
	octa(FOUNT, 13, Color("d9c9a3"))
	octa(FOUNT, 10, Color("7cc3ea"))
	for i in 3:
		var rr := fmod(clock * 10.0 + i * 12.0, 36.0)
		draw_arc(FOUNT, 10.0 + rr, 0.0, TAU, 32, Color(1, 1, 1, 0.6 - rr / 60.0), 1.0)
	for i in 8:
		var a := i * PI / 4.0
		draw_line(FOUNT, FOUNT + Vector2.from_angle(a) * (9.0 + sin(clock * 5.0 + i) * 2.0), Color("e8f6ff"), 2.0)
	for i in 8:
		var sp := FOUNT + Vector2.from_angle(clock * 0.7 + i * 0.785) * (30.0 + sin(clock * 3.0 + i) * 5.0)
		rc(sp.x, sp.y, 2, 2, Color(1, 1, 1, 0.85))
	draw_circle(FOUNT, 4, Color("ffffff"))
	rc(880, 650, 400, 12, Color("5fb7b0"))
	rc(880, 650, 400, 3, Color("a8e0da"))
	rc(880, 662, 400, 3, Color(0, 0, 0, 0.2))
	for x in range(880, 1280, 50):
		rc(x, 650, 2, 12, Color("3a8f88"))
	# cổng trường, chòi bảo vệ
	rc(GATE_X - 12, GATE_Y - 40, 14, 54, Color("8e3b32"))
	rc(GATE_X - 12, GATE_Y - 40, 4, 54, Color("a84c42"))
	rc(GATE_X + GATE_W - 2, GATE_Y - 40, 14, 54, Color("8e3b32"))
	rc(GATE_X + GATE_W - 2, GATE_Y - 40, 4, 54, Color("a84c42"))
	rc(GATE_X - 12, GATE_Y - 52, GATE_W + 24, 13, Color("1e5aa8"))
	rc(GATE_X - 12, GATE_Y - 52, GATE_W + 24, 2, Color("4c86d0"))
	ctext("HCMUS", GATE_X - 12, GATE_Y - 42, GATE_W + 24, 10, Color.WHITE)
	for i in range(0, 58, 6):
		rc(GATE_X - 70 + i, GATE_Y - 18, 2, 18, Color("9aa3ad"))
	rc(GATE_X - 70, GATE_Y - 10, 58, 2, Color("c4c8cc"))
	rc(0, GATE_Y, GATE_X - 12, 14, Color("b9b2a5"))
	rc(GATE_X + GATE_W + 12, GATE_Y, WORLD.x - GATE_X - GATE_W - 12, 14, Color("b9b2a5"))
	rc(0, GATE_Y, GATE_X - 12, 3, Color("d6d0c4"))
	rc(GATE_X + GATE_W + 12, GATE_Y, WORLD.x - GATE_X - GATE_W - 12, 3, Color("d6d0c4"))
	shadow(Vector2(816, 956), 22.0)
	rc(800, 930, 28, 24, Color("e8dcc0"))
	rc(803, 934, 10, 8, Color("8fc9e6"))
	rc(797, 920, 34, 12, Color("2f7d32"))
	rc(797, 920, 34, 3, Color("4aa44f"))
	ctext("Bảo vệ", 790, 966, 50, 8, Color.WHITE)
	asphalt(Rect2(0, GATE_Y + 14, WORLD.x, 26))
	for x in range(0, 1600, 40):
		rc(x, GATE_Y + 26, 22, 2, Color("e8e8e8"))

func draw_minimap() -> void:
	var o := cam.get_screen_center_position() - Vector2(240, 135) + Vector2(376, 40)
	var sc := 96.0 / WORLD.x
	rc(o.x - 2, o.y - 2, 100, 64, Color(0, 0, 0, 0.6))
	rc(o.x, o.y, 96, 60, Color("4f8a45"))
	rc(o.x, o.y + 585.0 * sc, 96, 50.0 * sc, Color("6a7078"))
	rc(o.x + GATE_X * sc, o.y + 635.0 * sc, GATE_W * sc, 325.0 * sc, Color("6a7078"))
	rc(o.x + 150.0 * sc, o.y + 690.0 * sc, 520.0 * sc, 200.0 * sc, Color("8d939c"))
	for b in BUILDINGS:
		rc(o.x + b[1] * sc, o.y + b[2] * sc, b[3] * sc, b[4] * sc, Color("e0b84a"))
	rc(o.x + DIEUHANH.position.x * sc, o.y + DIEUHANH.position.y * sc, DIEUHANH.size.x * sc, DIEUHANH.size.y * sc, Color("e8e2d0"))
	draw_circle(o + FOUNT * sc, 2.5, Color("6fb7e0"))
	if int(clock * 3.0) % 2 == 0:
		rc(o.x + player.x * sc - 1.5, o.y + player.y * sc - 1.5, 3, 3, Color.WHITE)
	rc(o.x + player.x * sc - 0.5, o.y + player.y * sc - 0.5, 1, 1, Color("e5322d"))

func _draw() -> void:
	var cc := cam.get_screen_center_position()
	view = Rect2(cc - Vector2(262, 152), Vector2(524, 304))
	draw_ground()
	draw_dieuhanh()
	for b in BUILDINGS:
		draw_building(b)
	for k in KIOSKS:
		draw_kiosk(k)
	for bk in bikes:
		draw_bike(bk)
	var items: Array = []
	for t in trees:
		items.append([float(t[1]), 0, t])
	for n in npcs:
		items.append([n.pos.y, 1, n])
	for l in lamps:
		items.append([l.y, 3, l])
	for bn in benches:
		items.append([bn.y, 4, bn])
	items.append([player.y, 2, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[1] == 0:
			draw_tree(it[2])
		elif it[1] == 3:
			if view.has_point(it[2]):
				draw_lamp(it[2])
		elif it[1] == 4:
			if view.has_point(it[2]):
				draw_bench(it[2])
		elif it[1] == 1:
			var n: Dictionary = it[2]
			if not view.has_point(n.pos):
				continue
			draw_person(n.pos, n.shirt, n.hair, n.face, n.anim, n.uni, n.long, n.pack)
			if n.say_t > 0.0:
				var w := font.get_string_size(n.say, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8.0
				rc(n.pos.x - w / 2.0 - 1, n.pos.y - 39, w + 2, 14, Color("333333"))
				rc(n.pos.x - w / 2.0, n.pos.y - 38, w, 12, Color.WHITE)
				rc(n.pos.x - 1, n.pos.y - 26, 3, 3, Color.WHITE)
				draw_string(font, Vector2(n.pos.x - w / 2.0 + 4.0, n.pos.y - 29), n.say, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
		else:
			draw_person(player, Color.WHITE, Color("1b1b1b"), facing, anim, true, false, true)
			ctext("Bạn", player.x - 15, player.y - 28, 30, 8, Color("ffd23f"))
	for c in clouds:
		draw_set_transform(Vector2(c.x, c.y), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, c.r, Color(0, 0, 0, 0.06))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in petals:
		rc(p.pos.x, p.pos.y, 2, 2, Color("ff5a4d"))
	draw_minimap()
