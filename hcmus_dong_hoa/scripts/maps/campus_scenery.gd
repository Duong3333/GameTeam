extends "res://scripts/draw/pen.gd"
# CẢNH VẬT KHUÔN VIÊN MỚI: cỏ, cây, đường, bãi xe, cổng, sân WE ❤ HCMUS, đài phun nước.
# Tái sử dụng SceneryElements cho tất cả thành phần lặp lại.

const POLE_STICKERS: Array[Color] = [Color(1.0, 0.82, 0.25), Color(1.0, 0.42, 0.54), Color(0.35, 0.65, 0.84)]
const WATER_MODULE  := preload("res://scripts/maps/ho_nuoc.gd")
const SE            := preload("res://scripts/maps/scenery_elements.gd")
const BX            := preload("res://scripts/maps/bai_xe.gd")

# ─── NỀN CỎ VÀ HOA ────────────────────────────────────────────────────────────
func draw_grass() -> void:
	draw_rect(view, Color("5a9e3e"))
	for tx in range(floori(view.position.x / 16.0), ceili(view.end.x / 16.0)):
		for ty in range(floori(view.position.y / 16.0), ceili(view.end.y / 16.0)):
			if (tx + ty) % 2 == 0:
				rc(tx * 16, ty * 16, 16, 16, Color(1, 1, 1, 0.03))
			if hs(tx, ty) < 14:
				rc(tx * 16 + 3, ty * 16 + 6, 10, 5, Color(0, 0, 0, 0.05))
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

# ─── ĐÈN ĐƯỜNG CÓ HIỆU ỨNG BAN ĐÊM ─────────────────────────────────────────
func draw_lamp(p: Vector2) -> void:
	shadow(p + Vector2(3, 0), 5.0)
	rc(p.x - 1, p.y - 24, 2, 24, Color("3a3f4a"))
	rc(p.x - 3, p.y - 27, 6, 4, Color("3a3f4a"))
	var hour := game_min / 60.0
	if hour <= 15.7:
		rc(p.x - 2, p.y - 26, 4, 2, Color("c9d3da"))
		return
	var power := clampf((hour - 15.7) / 0.6, 0.0, 1.0)
	var pulse := 1.0 + sin(clock * 3.0 + p.x * 0.1) * 0.04
	var bulb := p + Vector2(0, -24)
	draw_colored_polygon(lake_poly(p + Vector2(0, 2), 34.0 * pulse, 13.0 * pulse, 24), Color(1.0, 0.88, 0.45, 0.12 * power))
	draw_colored_polygon(lake_poly(p + Vector2(0, 2), 21.0 * pulse, 8.0 * pulse, 24), Color(1.0, 0.92, 0.55, 0.18 * power))
	draw_circle(bulb, 40.0 * pulse, Color(1.0, 0.9, 0.5, 0.07 * power))
	draw_circle(bulb, 30.0 * pulse, Color(1.0, 0.9, 0.5, 0.10 * power))
	draw_circle(bulb, 21.0 * pulse, Color(1.0, 0.92, 0.55, 0.16 * power))
	draw_circle(bulb, 12.0 * pulse, Color(1.0, 0.95, 0.65, 0.30 * power))
	draw_circle(bulb, 6.0, Color(1.0, 0.98, 0.8, 0.75 * power))
	rc(p.x - 2, p.y - 26, 4, 2, Color("fff1a8").lerp(Color.WHITE, 0.4 * power))
	rc(p.x - 1, p.y - 25, 2, 1, Color.WHITE)

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
	match t[2]:
		2:
			SE.draw_palm_tree(self, p, 1.0)
		1:
			SE.draw_pine_tree(self, p, 1.0)
		_:
			SE.draw_broad_tree(self, p, 1.0)

# ─── ĐẤT / ĐƯỜNG / BÃI XE / CỔNG ────────────────────────────────────────────
func draw_ground() -> void:
	draw_grass()
	var beige := Color("dccaa0")

	# ── Viền rừng cây bao quanh toàn bản đồ ──
	var border := 32.0
	rc(0, 0, WORLD.x, border, Color("3a7a2a"))
	rc(0, WORLD.y - border, WORLD.x, border, Color("3a7a2a"))
	rc(0, 0, border, WORLD.y, Color("3a7a2a"))
	rc(WORLD.x - border, 0, border, WORLD.y, Color("3a7a2a"))
	# cây đứng dày theo viền
	for x in range(10, int(WORLD.x) - 10, 48):
		SE.draw_broad_tree(self, Vector2(x, 18), 0.7)
		SE.draw_broad_tree(self, Vector2(x + 20, WORLD.y - 20), 0.7)
	for y in range(10, int(WORLD.y) - 10, 48):
		SE.draw_broad_tree(self, Vector2(18, y), 0.7)
		SE.draw_broad_tree(self, Vector2(WORLD.x - 20, y + 20), 0.7)

	# ── Đường nội bộ chính (ngang) y≈870–930 ──
	asphalt(Rect2(0, 870, WORLD.x, 60))
	# vạch trắng giữa đường ngang
	for x in range(0, int(WORLD.x), 44):
		rc(x, 898, 24, 3, Color("e8e8e8"))
	paved(Rect2(0, 862, WORLD.x, 8), beige)
	paved(Rect2(0, 930, WORLD.x, 8), beige)

	# ── Đường nội bộ chính (dọc) x≈1070–1160 ──
	asphalt(Rect2(1070, 0, 90, WORLD.y))
	# vạch trắng giữa đường dọc
	for y in range(0, int(WORLD.y), 44):
		rc(1113, y, 3, 24, Color("e8e8e8"))
	paved(Rect2(1062, 0, 8, WORLD.y), beige)
	paved(Rect2(1160, 0, 8, WORLD.y), beige)

	# ── Dải phân cách trục đường dọc ──
	SE.draw_road_divider(self, Vector2(1115, 100), Vector2(1115, 850), 20.0)
	# trồng thông xen kẽ cọ dọc dải phân cách
	var dy := 100.0
	while dy < 840.0:
		if int(dy / 100) % 2 == 0:
			SE.draw_pine_tree(self, Vector2(1115, dy), 0.75)
		else:
			SE.draw_palm_tree(self, Vector2(1115, dy), 0.70)
		dy += 100.0

	# ── Đường vào bãi xe số 1 (nhánh từ đường ngang vào trái) ──
	asphalt(Rect2(60, 920, 540, 20))
	paved(Rect2(60, 916, 540, 4), beige)

	# ── Đường vào khu Nhà Điều hành (phải cổng) ──
	asphalt(Rect2(1160, 930, 540, 20))
	paved(Rect2(1160, 930, 540, 4), beige)

	# ── Đường vòng quanh khu công viên đài phun nước — ĐÃ XÓA (gây lane thừa) ──
	# vạch kẻ người đi bộ tại các ngã tư lớn
	SE.draw_zebra_crossing(self, Vector2(1070, 860), 90.0, 10.0, false)
	SE.draw_zebra_crossing(self, Vector2(600,  860), 90.0, 10.0, false)
	SE.draw_zebra_crossing(self, Vector2(1070, 540), 90.0, 10.0, true)

	# ── Lối đi bộ hành lang có mái nối các tòa nhà (hướng ngang) ──
	SE.draw_covered_walkway(self, Vector2(250, 580), Vector2(1060, 580), 14.0)
	# ── Hành lang mái vòm thứ 2 phía trên đường ngang chính ──
	SE.draw_covered_walkway(self, Vector2(120, 848), Vector2(1060, 848), 12.0)
	SE.draw_covered_walkway(self, Vector2(1160, 848), Vector2(2350, 848), 12.0)

	# ── Lối đi bộ gạch beige nội bộ ──
	paved(Rect2(120, 558, 950, 20), beige)   # lối đi ngang trước các tòa
	# (đã xóa paved trên y=150 vì gây ra lane thừa phía bắc các tòa nhà)

	# ── Lối đi bộ gạch vào Tòa B4.2 (thoáng đãng, không bị bãi xe đè) ──
	paved(Rect2(870, 110, 100, 45), beige)     # sân gạch trước cửa B4.2
	paved(Rect2(970, 120, 92, 16), beige)      # lối đi bộ nối từ trục đường dọc sang B4.2

	# ── Trục đường ngang trên dẫn vào Nhà Thể Dục và Bãi xe số 2 ──
	asphalt(Rect2(1160, 50, 1130, 24))         # đường chạy từ trục dọc x=1160 qua Nhà TD tới Bãi xe 2
	paved(Rect2(1160, 46, 1130, 4), beige)     # viền beige đường trên

	# ── Sân cỏ trước Hội trường B (LAWN_B_RECT) — texture cỏ ──
	var lb := LAWN_B_RECT
	draw_rect(lb, Color("5fbb4a"))
	# texture cỏ: checkerboard sáng tối + tua cỏ nhỏ
	for tx in range(floori(lb.position.x / 10.0), ceili(lb.end.x / 10.0)):
		for ty in range(floori(lb.position.y / 10.0), ceili(lb.end.y / 10.0)):
			if (tx + ty) % 3 == 0:
				rc(tx * 10, ty * 10, 10, 10, Color("4aa840"))
			elif hs(tx, ty) < 7:
				rc(tx * 10 + 2, ty * 10 + 3, 3, 4, Color("6acc50"))
	draw_rect(lb, Color("3a9a3a"), false, 2.0)
	# bờ viền bụi thấp quanh sân
	SE.draw_trimmed_hedge(self, lb.position + Vector2(0, lb.size.y),
		lb.position + Vector2(lb.size.x, lb.size.y), 8.0)
	SE.draw_trimmed_hedge(self, lb.position,
		lb.position + Vector2(0, lb.size.y), 8.0)
	SE.draw_trimmed_hedge(self, lb.position + Vector2(lb.size.x, 0),
		lb.position + Vector2(lb.size.x, lb.size.y), 8.0)

	# ── BÃI GIỮ XE SỐ 1 (XE MÁY) — module bai_xe.gd ──
	var p1 := PARKING1_RECT
	BX.draw(self, p1, "BÃI GIỮ XE MÁY SỐ 1", 13.0, [2.0, 85.0, 170.0])
	if font != null:
		ctext("BÃI GIỮ XE MÁY SỐ 1", p1.position.x, p1.end.y - 10, p1.size.x, 9, Color.WHITE)

	# ── BÃI GIỮ XE SỐ 2 (XE MÁY) — module bai_xe.gd (kế bên phải Nhà Thể Dục) ──
	var p2 := PARKING2_RECT
	BX.draw(self, p2, "BÃI GIỮ XE MÁY SỐ 2", 13.0, [2.0, 65.0])
	if font != null:
		ctext("BÃI GIỮ XE MÁY SỐ 2", p2.position.x, p2.end.y - 10, p2.size.x, 9, Color.WHITE)

	# ── QUẢNG TRƯỜNG ĐÀI PHUN NƯỚC (giữa tòa E và F) ──
	SE.draw_fountain_plaza(self, FOUNTAIN_CENTER, 110.0, clock)
	# biển "HỒ SINH VIÊN"
	var sx := FOUNTAIN_CENTER.x
	var sy := FOUNTAIN_CENTER.y + 128.0
	shadow(Vector2(sx, sy), 14.0)
	rc(sx - 1, sy - 14, 2, 14, Color("5a3a1c"))
	rc(sx - 36, sy - 25, 72, 12, Color("5a3a1c"))
	rc(sx - 35, sy - 24, 70, 10, Color("a8733f"))
	ctext("HỒ SINH VIÊN", sx - 35, sy - 16, 70, 7, Color.WHITE)

	# ── SÂN WE ❤ HCMUS ── (pixel art block letters, không cần font)
	SE.draw_we_love_hcmus(self, WE_LOVE_POS)
	# Tượng đài trắng
	SE.draw_white_monument(self, MONUMENT_POS)

	# ── BỒN HOA TRANG TRÍ dọc lối đi chính ──
	flowerbed(DIEUHANH.position.x + 60, DIEUHANH.end.y + 70, 80, 14)
	flowerbed(DIEUHANH.end.x - 140,     DIEUHANH.end.y + 70, 80, 14)

	# ── CỔng trường & đường nội bộ bên dưới ──
	asphalt(Rect2(GATE_X, GATE_Y - 200, GATE_W, 200))
	for y in range(int(GATE_Y) - 200, int(GATE_Y), 36):
		rc(GATE_X + GATE_W / 2.0 - 1, y, 3, 20, Color("e8e8e8"))
	for i in 8:
		rc(GATE_X + 6 + i * 15, int(GATE_Y) - 180, 8, 50, Color(1, 1, 1, 0.75))
	for i in 6:
		rc(GATE_X, int(GATE_Y) - 20 + i * 7, GATE_W, 3, Color(1, 1, 1, 0.8))
	paved(Rect2(60, 1300, 100, 60), Color("9096a0"))
	draw_t1_strip()
	draw_school_gate()
	# đường phố ngoài cổng
	asphalt(Rect2(0, GATE_Y + 14, WORLD.x, 36))
	for x in range(0, int(WORLD.x), 44):
		rc(x, GATE_Y + 26, 24, 2, Color("e8e8e8"))

# ─── DẢI QUÁN ĐƯỜNG NỘI BỘ, CỔNG TRƯỜNG ─────────────────────────────────────
func draw_t1_strip() -> void:
	if not view.intersects(STRIP_T1.grow(16.0)):
		return
	paved(STRIP_T1, Color("dccaa0"))
	rc(STRIP_T1.position.x, STRIP_T1.position.y, 2, STRIP_T1.size.y, Color("b9a77c"))

func draw_red_barricade(r: Rect2) -> void:
	var red := Color("d8352b")
	var base := r.end.y
	shadow(Vector2(r.position.x + r.size.x / 2.0, base + 1.0), r.size.x / 2.0)
	for i in range(0, int(r.size.x) - 7, 8):
		rc(r.position.x + i, base - 9, 4, 3, red)
		rc(r.position.x + i + 4, base - 9, 4, 3, Color.WHITE)
		rc(r.position.x + i, base - 5, 4, 3, Color.WHITE)
		rc(r.position.x + i + 4, base - 5, 4, 3, red)
	rc(r.position.x, base - 10, 2, 10, Color("c4c8cc"))
	rc(r.end.x - 2, base - 10, 2, 10, Color("c4c8cc"))

func draw_street_pole(p: Vector2, mirror: bool) -> void:
	if not view.grow(60.0).has_point(p):
		return
	shadow(p + Vector2(3, 0), 4.0)
	rc(p.x - 2, p.y - 46, 4, 46, Color("8f959c"))
	rc(p.x - 2, p.y - 46, 1, 46, Color("b4bac1"))
	rc(p.x - 9, p.y - 44, 18, 2, Color("6e747b"))
	rc(p.x - 6, p.y - 38, 12, 2, Color("6e747b"))
	rc(p.x + 2, p.y - 30, 6, 9,  Color("aeb8c4"))
	rc(p.x + 2, p.y - 30, 6, 1,  Color("d4dbe3"))
	for i in POLE_STICKERS.size():
		rc(p.x - 2, p.y - 16 + i * 5, 4, 3, POLE_STICKERS[i])
	if mirror:
		rc(p.x + 2, p.y - 36, 6, 1, Color("6e747b"))
		draw_circle(p + Vector2(9, -36), 6.0, Color("e5322d"))
		draw_circle(p + Vector2(9, -36), 4.5, Color("e8f6ff"))
		draw_circle(p + Vector2(8, -37), 1.5, Color.WHITE)

func draw_street_cable(a: Vector2, b: Vector2, sag: float) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(a.lerp(b, t) + Vector2(0.0, sin(PI * t) * sag))
	draw_polyline(pts, Color("2a2d33"), 1.0)

func draw_parking_signboard(p: Vector2) -> void:
	if not view.grow(40.0).has_point(p):
		return
	shadow(p + Vector2(3, 0), 5.0)
	rc(p.x - 1, p.y - 16, 2, 16, Color("8f959c"))
	rc(p.x - 12, p.y - 30, 24, 15, Color("1e5aa8"))
	rc(p.x - 12, p.y - 30, 24, 2,  Color("4c86d0"))
	ctext("BÃI GIỮ XE", p.x - 12, p.y - 23, 24, 5, Color.WHITE)
	rc(p.x - 8, p.y - 19, 12, 2, Color("ff9a3c"))
	draw_colored_polygon(PackedVector2Array([Vector2(p.x + 8, p.y - 18), Vector2(p.x + 4, p.y - 21), Vector2(p.x + 4, p.y - 15)]), Color("ff9a3c"))

func draw_street_furniture() -> void:
	for pole in STREET_POLES:
		draw_street_pole(pole["pos"], pole["mirror"])
	for t in STREET_TREES:
		draw_tree(t)
	draw_parking_signboard(PARKING_SIGN)
	for c in STREET_CABLES:
		var a: Vector2 = STREET_POLES[c[0]]["pos"] + Vector2(0.0, -44.0)
		var b: Vector2 = STREET_POLES[c[1]]["pos"] + Vector2(0.0, -44.0)
		draw_street_cable(a, b, 6.0)
		draw_street_cable(a + Vector2(0.0, 3.0), b + Vector2(0.0, 3.0), 7.0)
	# Thêm cột đèn và cột cờ dọc các trục chính
	var lamp_x := 160.0
	while lamp_x < 1060.0:
		SE.draw_street_lamp(self, Vector2(lamp_x, 866))
		lamp_x += 160.0
	var lamp_x2 := 1200.0
	while lamp_x2 < 2370.0:
		SE.draw_street_lamp(self, Vector2(lamp_x2, 866))
		lamp_x2 += 160.0
	# Cột cờ tại cổng và trước Nhà Điều hành
	SE.draw_flag_pole(self, Vector2(GATE_X - 50, GATE_Y - 60))
	SE.draw_flag_pole(self, Vector2(GATE_X + GATE_W + 50, GATE_Y - 60))
	SE.draw_flag_pole(self, Vector2(DIEUHANH.position.x + 20, DIEUHANH.position.y - 10))
	SE.draw_flag_pole(self, Vector2(DIEUHANH.end.x - 20, DIEUHANH.position.y - 10))

func draw_folding_gate(r: Rect2) -> void:
	var rail  := Color("6e747b")
	var steel := Color("aab2bb")
	rc(r.position.x, r.position.y, r.size.x, 2, rail)
	rc(r.position.x, r.end.y - 2,  r.size.x, 2, rail)
	rc(r.position.x, r.position.y, 2, r.size.y, rail)
	rc(r.end.x - 2,  r.position.y, 2, r.size.y, rail)
	for i in range(0, int(r.size.x) - 5, 6):
		var x0 := r.position.x + i
		draw_line(Vector2(x0, r.end.y - 2),    Vector2(x0 + 6, r.position.y + 2), steel, 1.0)
		draw_line(Vector2(x0, r.position.y + 2), Vector2(x0 + 6, r.end.y - 2),   steel, 1.0)

func draw_gate_booth() -> void:
	var r := GUARD_BOOTH
	shadow(Vector2(r.position.x + 18.0, r.end.y + 2.0), 24.0)
	rc(r.position.x, r.position.y, r.size.x, r.size.y, Color("c4c8cc"))
	rc(r.position.x, r.position.y, 3, r.size.y, Color(1, 1, 1, 0.25))
	rc(r.position.x + 3, r.position.y + 6, 14, 10, Color("8fc9e6"))
	rc(r.position.x + 3, r.position.y + 6, 14, 3,  Color("c8e8f7"))
	rc(r.position.x + 20, r.position.y + 5, 8, 22, Color("5a6068"))
	rc(r.position.x - 4,  r.position.y - 7, r.size.x + 8, 8, Color("4a4f57"))
	rc(r.position.x - 4,  r.position.y - 7, r.size.x + 8, 2, Color("6e747b"))
	ctext("Bảo vệ", r.position.x - 10, r.end.y + 14, 60, 8, Color.WHITE)

func draw_national_flag(top_left: Vector2, w: float = 24.0, h: float = 16.0) -> void:
	rc(top_left.x, top_left.y, w, h, Color("da251d"))
	var center := top_left + Vector2(w, h) * 0.5
	var outer := h * 0.3
	var pts := PackedVector2Array()
	for k in 10:
		var angle := -PI / 2.0 + k * PI / 5.0
		var radius := outer if k % 2 == 0 else outer * 0.382
		pts.append(center + Vector2.from_angle(angle) * radius)
	draw_colored_polygon(pts, Color("ffde00"))

func draw_school_gate() -> void:
	for px in [GATE_X - 14.0, GATE_X + GATE_W - 2.0]:
		rc(px, GATE_Y - 50, 16, 64, Color("8e3b32"))
		rc(px, GATE_Y - 50, 5, 64, Color("a84c42"))
	rc(GATE_X - 14, GATE_Y - 64, GATE_W + 28, 15, Color("1e5aa8"))
	rc(GATE_X - 14, GATE_Y - 64, GATE_W + 28, 2, Color("4c86d0"))
	ctext("HCMUS", GATE_X - 14, GATE_Y - 54, GATE_W + 28, 10, Color.WHITE)
	draw_folding_gate(GATE_PANEL)
	var right_x := GATE_X + GATE_W + 14.0
	var right_w := WORLD.x - right_x
	rc(0, GATE_Y, GATE_X - 14, 14, Color("b9b2a5"))
	rc(right_x, GATE_Y, right_w, 14, Color("b9b2a5"))
	rc(0, GATE_Y, GATE_X - 14, 3, Color("d6d0c4"))
	rc(right_x, GATE_Y, right_w, 3, Color("d6d0c4"))
	draw_gate_booth()
	for b in GATE_BARRICADES:
		draw_red_barricade(b)

# ─── HỒ NƯỚC (tái dùng ho_nuoc.gd cho animation phun nước) ──────────────────
func lake_poly(c: Vector2, rx: float, ry: float, n: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func draw_lake() -> void:
	# Đài phun nước mới vẽ bởi draw_fountain_plaza trong draw_ground()
	# Hàm này giữ để tương thích với campus_structures.gd (không làm gì thêm)
	pass
