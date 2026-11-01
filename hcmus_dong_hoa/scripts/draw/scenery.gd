extends "res://scripts/draw/pen.gd"
# CẢNH VẬT NGOÀI TRỜI: cỏ, hàng rào cây, bồn hoa, đèn, ghế, cây, và toàn bộ nền đất (đường, bãi xe, đài phun nước, cổng).

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

func draw_ground() -> void:
	draw_grass()
	draw_lake()
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

# ---------- HỒ SINH VIÊN (nơi câu cá, xem scripts/features/fishing.gd) ----------
func lake_poly(c: Vector2, rx: float, ry: float, n: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func draw_lake() -> void:
	if not view.grow(30.0).intersects(LAKE.grow(12.0)):
		return
	var c := LAKE.get_center()
	var rx := LAKE.size.x * 0.5
	var ry := LAKE.size.y * 0.5
	# bờ đá + mặt nước
	draw_colored_polygon(lake_poly(c + Vector2(0, 3), rx + 7.0, ry + 7.0), Color(0, 0, 0, 0.22))
	draw_colored_polygon(lake_poly(c, rx + 6.0, ry + 6.0), Color("8f8566"))
	draw_colored_polygon(lake_poly(c, rx + 4.0, ry + 4.0), Color("d9c9a3"))
	draw_colored_polygon(lake_poly(c, rx + 1.0, ry + 1.0), Color("b9a77c"))
	draw_colored_polygon(lake_poly(c, rx, ry), Color("3d86bd"))
	draw_colored_polygon(lake_poly(c + Vector2(-3, -2), rx * 0.88, ry * 0.86), Color("4f9bd0"))
	draw_colored_polygon(lake_poly(c + Vector2(-8, -5), rx * 0.58, ry * 0.52), Color("5aa5d6"))
	for i in 36:
		var a := TAU * i / 36.0
		var sp := c + Vector2(cos(a) * (rx + 4.5), sin(a) * (ry + 4.5))
		var g := 0.55 + hs(i, 5) * 0.004
		rc(sp.x - 2.0, sp.y - 1.5, 4.0, 3.0, Color(g, g * 0.95, g * 0.8))
	# ánh nước lấp lánh
	for i in 22:
		var a := hs(i, 7) / 100.0 * TAU
		var r := sqrt(hs(i, 13) / 100.0) * 0.88
		var sp := c + Vector2(cos(a) * rx * r, sin(a) * ry * r)
		if sin(clock * 2.0 + i * 1.7) > 0.55:
			rc(sp.x, sp.y, 3, 1, Color(1, 1, 1, 0.7))
	# cá bơi dưới nước (chỉ thấy bóng)
	for i in 4:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var ang := clock * (0.25 + 0.07 * i) * dir + i * 1.7
		var rr := 0.35 + 0.12 * i
		var fp := c + Vector2(cos(ang) * rx * rr, sin(ang) * ry * rr)
		var tv := Vector2(-sin(ang) * rx, cos(ang) * ry) * dir
		var xf := Transform2D(tv.angle(), fp)
		var wag := sin(clock * 6.0 + i) * 1.5
		var col := Color(0.05, 0.2, 0.4, 0.3)
		if i == 3:
			col = Color(0.95, 0.55, 0.2, 0.3)
		var body := PackedVector2Array()
		for k in 10:
			var b := TAU * k / 10.0
			body.append(Vector2(cos(b) * 6.0, sin(b) * 2.6))
		var tail := PackedVector2Array([Vector2(-5, 0), Vector2(-10, -3.0 + wag), Vector2(-10, 3.0 + wag)])
		draw_colored_polygon(xf * body, col)
		draw_colored_polygon(xf * tail, col)
	# lá súng và hoa súng
	var pads := [Vector2(-0.55, -0.25), Vector2(0.5, 0.35), Vector2(-0.2, 0.55), Vector2(0.62, -0.38), Vector2(0.05, -0.6), Vector2(-0.72, 0.3)]
	for i in pads.size():
		var q: Vector2 = pads[i]
		var pp := c + Vector2(q.x * rx, q.y * ry) + Vector2(0, sin(clock * 1.2 + i) * 0.8)
		draw_circle(pp, 4.5, Color("2c7d33"))
		draw_circle(pp + Vector2(-1, -1), 3.2, Color("3f9c45"))
		draw_colored_polygon(PackedVector2Array([pp, pp + Vector2(5, -1), pp + Vector2(5, 1.5)]), Color("4f9bd0"))
		if i % 2 == 0:
			draw_circle(pp + Vector2(-1.5, -1.5), 1.7, Color("ff9ecb"))
			draw_circle(pp + Vector2(-1.5, -1.5), 0.7, Color("ffe066"))
	# lau sậy ven bờ
	for a in [2.5, 2.8, 3.2, 3.7, 5.5, 5.9, 0.15]:
		var base := c + Vector2(cos(a) * (rx + 4.0), sin(a) * (ry + 4.0))
		for k in 3:
			var sway := sin(clock * 1.5 + base.x * 0.1 + k) * 1.5
			var top := base + Vector2(k * 2.0 - 2.0 + sway, -9.0 - k * 2.0)
			draw_line(base + Vector2(k * 2.0 - 2.0, 0), top, Color("3f7a35"), 1.0)
			rc(top.x - 1.0, top.y - 3.0, 2, 4, Color("6b4423"))
	# biển báo
	var sx := LAKE.position.x - 40.0
	var sy := LAKE.position.y + 108.0
	shadow(Vector2(sx, sy), 14.0)
	rc(sx - 1, sy - 14, 2, 14, Color("5a3a1c"))
	rc(sx - 29, sy - 25, 58, 12, Color("5a3a1c"))
	rc(sx - 28, sy - 24, 56, 10, Color("a8733f"))
	ctext("HỒ SINH VIÊN", sx - 28, sy - 16, 56, 7, Color.WHITE)
