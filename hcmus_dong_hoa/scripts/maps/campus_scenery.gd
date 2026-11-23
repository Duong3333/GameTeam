extends "res://scripts/draw/pen.gd"
# CẢNH VẬT KHUÔN VIÊN MỚI: cỏ, cây, đường, bãi xe, cổng, sân WE ❤ HCMUS, đài phun nước.
# Tái sử dụng SceneryElements cho tất cả thành phần lặp lại.

const POLE_STICKERS: Array[Color] = [Color(1.0, 0.82, 0.25), Color(1.0, 0.42, 0.54), Color(0.35, 0.65, 0.84)]
const WATER_MODULE  := preload("res://scripts/maps/ho_nuoc.gd")
const SE            := preload("res://scripts/maps/scenery_elements.gd")
const BX            := preload("res://scripts/maps/bai_xe.gd")

# Khi true, draw_ground() bo qua dai phun nuoc (ve bang clock nen khong duoc bake tinh).
var skip_fountain := false

# ─── NỀN CỎ VÀ HOA ────────────────────────────────────────────────────────────
func draw_grass() -> void:
	if grass_texture == null:
		if not SHOW_VEGETATION:
			draw_rect(view, Color("5a9e3e"))
			return
		# Compatibility fallback if setup was skipped or resources were reset.
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
		return
	var visible := view.intersection(Rect2(Vector2.ZERO, WORLD))
	if visible.size.x > 0.0 and visible.size.y > 0.0:
		draw_texture_rect_region(
			grass_texture,
			visible,
			Rect2(visible.position, visible.size)
		)

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

# ─── ĐÈN ĐƯỜNG ───────────────────────────────────────────────────────────────
func draw_lamp(p: Vector2) -> void:
	shadow(p + Vector2(3, 0), 5.0)
	rc(p.x - 1, p.y - 24, 2, 24, Color("3a3f4a"))
	rc(p.x - 3, p.y - 27, 6, 4, Color("3a3f4a"))
	rc(p.x - 2, p.y - 26, 4, 2, Color("c9d3da"))

func draw_bench(bench: Variant) -> void:
	var p := get_bench_position(bench)
	var vertical := bool(bench.get("vertical", false)) if bench is Dictionary else false
	var length := float(bench.get("length", 18.0)) if bench is Dictionary else 18.0
	var half_bounds := Vector2(11.0, length * 0.5 + 2.0) if vertical else Vector2(length * 0.5 + 2.0, 11.0)
	if not view.intersects(Rect2(p - half_bounds, half_bounds * 2.0)):
		return
	shadow(p + Vector2(0, 1), length * 0.6, PI * 0.5 if vertical else 0.0)
	draw_set_transform(p, PI * 0.5 if vertical else 0.0, Vector2.ONE)
	rc(-length * 0.5, -9, length, 3, Color("8a5a32"))
	rc(-length * 0.5, -6, length, 2, Color("a8733f"))
	rc(-length * 0.5, -4, length, 3, Color("8a5a32"))
	rc(-length * 0.5 + 1, -1, 2, 2, Color("333333"))
	rc(length * 0.5 - 3, -1, 2, 2, Color("333333"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_tree(t: Array) -> void:
	if not SHOW_VEGETATION:
		return
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
	draw_rect(Rect2(1547, 1129, WORLD.x - 1547, WORLD.y - 1129), Color("5fbb4a"))

	if SHOW_VEGETATION:
		var border := 32.0
		rc(0, 0, WORLD.x, border, Color("3a7a2a"))
		rc(0, WORLD.y - border, WORLD.x, border, Color("3a7a2a"))
		rc(0, 0, border, WORLD.y, Color("3a7a2a"))
		rc(WORLD.x - border, 0, border, WORLD.y, Color("3a7a2a"))
		for x in range(10, int(WORLD.x) - 10, 48):
			SE.draw_broad_tree(self, Vector2(x, 18), 0.7)
			SE.draw_broad_tree(self, Vector2(x + 20, WORLD.y - 20), 0.7)
		for y in range(10, int(WORLD.y) - 10, 48):
			SE.draw_broad_tree(self, Vector2(18, y), 0.7)
			SE.draw_broad_tree(self, Vector2(WORLD.x - 20, y + 20), 0.7)

	# ── Trục đường ngang giữa khuôn viên ──
	asphalt(Rect2(0, 879, WORLD.x, 211))
	if SHOW_ROAD_MARKINGS:
		for x in range(0, int(WORLD.x), 44):
			rc(x, 982, 24, 3, Color("e8e8e8"))
	paved(Rect2(0, 835, WORLD.x, 44), beige)
	paved(Rect2(0, 1090, 1098, 80), beige)
	paved(Rect2(1507, 1090, WORLD.x - 1507, 39), beige)

	# ── Các nhánh đường dọc kẹp khu hồ ──
	asphalt(Rect2(1268, 0, 109, 881), false)
	if SHOW_ROAD_MARKINGS:
		for y in range(0, int(WORLD.y), 44):
			rc(1321, y, 3, 24, Color("e8e8e8"))
	paved(Rect2(1249, 0, 19, 879), beige)
	# Đường nhựa phía trước Nhà Thể Dục và Bãi xe 2, ngăn với khu hồ.
	asphalt(Rect2(1377, 191, WORLD.x - 1377, 63))
	paved(Rect2(1377, 176, WORLD.x - 1377, 15), beige)
	asphalt(Rect2(1822, 260, 97, 621), false)
	paved(Rect2(1804, 260, 18, 619), beige)
	paved(Rect2(1919, 260, 18, 619), beige)
	asphalt(Rect2(
		GATE_APPROACH_ROAD.position.x,
		GATE_APPROACH_ROAD.position.y - 2.0,
		GATE_APPROACH_ROAD.size.x,
		GATE_APPROACH_ROAD.size.y + 2.0
	), false)

	# ── Dải phân cách trục đường dọc ──
	if SHOW_VEGETATION:
		SE.draw_road_divider(self, Vector2(1322, 100), Vector2(1322, 850), 20.0)
		var dy := 100.0
		while dy < 840.0:
			if int(dy / 100) % 2 == 0:
				SE.draw_pine_tree(self, Vector2(1322, dy), 0.75)
			else:
				SE.draw_palm_tree(self, Vector2(1322, dy), 0.70)
			dy += 100.0

	# ── Vạch qua đường tại các ngã tư lớn ──
	if SHOW_ROAD_MARKINGS:
		SE.draw_zebra_crossing(self, Vector2(1268, 860), 109.0, 10.0, false)
		SE.draw_zebra_crossing(self, Vector2(1822, 860), 97.0, 10.0, false)
		SE.draw_zebra_crossing(self, Vector2(1268, 540), 109.0, 10.0, true)

	if SHOW_VEGETATION:
		# ── Lối đi bộ hành lang có mái nối các tòa nhà ──
		SE.draw_covered_walkway(self, Vector2(250, 800), Vector2(1260, 800), 14.0)
		SE.draw_covered_walkway(self, Vector2(120, 848), Vector2(1090, 848), 12.0)
		SE.draw_covered_walkway(self, Vector2(1555, 848), Vector2(2350, 848), 12.0)

	# ── Lối đi bộ gạch beige nội bộ ──
	paved(Rect2(120, 790, 1130, 20), beige)

	# ── Đường ngang phía bắc, cạnh căn tin và Bãi xe 2 ──
	asphalt(Rect2(669, 113, 708, 94))
	paved(Rect2(669, 108, 708, 5), beige)

	# ── Lối đi bao quanh hồ và sân ghế ──
	paved(Rect2(1377, 260, 445, 24), beige)
	paved(Rect2(1377, 855, 445, 24), beige)
	paved(Rect2(1377, 260, 24, 619), beige)
	paved(Rect2(1798, 260, 24, 619), beige)
	draw_rect(Rect2(1438, 600, 322, 235), beige)
	draw_rect(Rect2(1580, 608, 36, 219), Color("4a9a3a"))

	# ── Sân cỏ trước Hội trường B (LAWN_B_RECT) — texture cỏ ──
	var lb := LAWN_B_RECT
	draw_rect(lb, Color("5fbb4a"))
	if SHOW_VEGETATION:
		for tx in range(floori(lb.position.x / 10.0), ceili(lb.end.x / 10.0)):
			for ty in range(floori(lb.position.y / 10.0), ceili(lb.end.y / 10.0)):
				if (tx + ty) % 3 == 0:
					rc(tx * 10, ty * 10, 10, 10, Color("4aa840"))
				elif hs(tx, ty) < 7:
					rc(tx * 10 + 2, ty * 10 + 3, 3, 4, Color("6acc50"))
	draw_rect(lb, Color("3a9a3a"), false, 2.0)
	if SHOW_VEGETATION:
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
	if not skip_fountain:
		SE.draw_fountain_plaza(self, FOUNTAIN_CENTER, 110.0, clock, SHOW_VEGETATION)
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
	if SHOW_VEGETATION:
		flowerbed(DIEUHANH.position.x + 60, DIEUHANH.end.y + 70, 80, 14)
		flowerbed(DIEUHANH.end.x - 140,     DIEUHANH.end.y + 70, 80, 14)

	# ── CỔng trường & đường nội bộ bên dưới ──
	if SHOW_ROAD_MARKINGS:
		for y in range(int(GATE_Y) - 200, int(GATE_Y), 36):
			rc(GATE_X + GATE_W / 2.0 - 1, y, 3, 20, Color("e8e8e8"))
		for i in 8:
			rc(GATE_X + 6 + i * 15, int(GATE_Y) - 180, 8, 50, Color(1, 1, 1, 0.75))
		for i in 6:
			rc(GATE_X, int(GATE_Y) - 20 + i * 7, GATE_W, 3, Color(1, 1, 1, 0.8))
	paved(Rect2(60, 1300, 100, 60), Color("9096a0"))
	draw_t1_strip()
	draw_school_gate()

# ─── DẢI QUÁN ĐƯỜNG NỘI BỘ, CỔNG TRƯỜNG ─────────────────────────────────────
func draw_t1_strip() -> void:
	for strip in [STRIP_T1_LEFT, STRIP_T1]:
		if not view.intersects(strip.grow(16.0)):
			continue
		paved(strip, Color("dccaa0"))
		var curb_x: float = strip.end.x - 2.0 if strip == STRIP_T1_LEFT else strip.position.x
		rc(curb_x, strip.position.y, 2, strip.size.y, Color("b9a77c"))

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
	# Cột cờ tại cổng và trước Nhà Điều hành
	SE.draw_flag_pole(self, Vector2(GATE_X - 50, GATE_Y - 60))
	SE.draw_flag_pole(self, Vector2(GATE_X + GATE_W + 50, GATE_Y - 60))

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
