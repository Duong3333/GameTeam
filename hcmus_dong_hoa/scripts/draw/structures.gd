extends "res://scripts/draw/scenery.gd"
# CÔNG TRÌNH: các tòa nhà A-G + Nhà Thể Dục, Nhà Điều hành, quầy nhỏ (kiosk), dãy quán Đường T1, va chạm mặt tiền.

const FRONTAGE_SOLID_LAYER := 1

var _frontage_root: Node2D

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
	# Bụi tròn và tay vịn cũ đã được thay bằng draw_dieuhanh_front() (gọi trong draw_frontage_overlay).
	var fp := Vector2(x - 30, r.end.y + 30)
	rc(fp.x, fp.y - 52, 2, 52, Color("c4c8cc"))
	draw_national_flag(Vector2(fp.x + 2.0, fp.y - 52.0))

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

# ---------- LỚP VẼ THEO CHIỀU SÂU (đối tượng đứng) ----------
# Gọi SAU khi vẽ nhân vật/NPC có y nhỏ hơn, hoặc đưa vào danh sách y-sort sẵn có.
# Nằm ở structures.gd (lớp con) vì gọi draw_t1_shops() và draw_dieuhanh_front().
func draw_frontage_overlay() -> void:
	draw_lane_block()
	draw_street_furniture()
	draw_t1_shops()
	draw_dieuhanh_front()

# ---------- HẺM NHÀ DÂN, QUÁN VỈA HÈ ----------
func draw_lane_block() -> void:
	for h in HOUSES:
		draw_house(h)
	for s in STALLS:
		draw_stall(s)
	draw_shrine(SHRINE_RECT)
	draw_dog(DOG_POS)
	for c in VENDOR_CARTS:
		draw_vendor_cart(c, Color("e86aa0"), Color("ffd23f"))

func draw_house(h: Dictionary) -> void:
	var r: Rect2 = h["rect"]
	if not view.intersects(r.grow(16.0)):
		return
	var wall: Color = h["wall"]
	var roof: Color = h["roof"]
	var x := r.position.x
	var y := r.position.y
	shadow(Vector2(x + r.size.x * 0.5 + 4.0, r.end.y + 1.0), r.size.x * 0.55)
	rc(x, y + 10, r.size.x, r.size.y - 10, wall)
	rc(x, r.end.y - 4, r.size.x, 4, wall.darkened(0.15))
	rc(x - 2, y, r.size.x + 4, 12, roof)
	for i in range(0, int(r.size.x) + 4, 4):
		rc(x - 2 + i, y, 1, 12, roof.darkened(0.2))
	rc(x - 2, y, r.size.x + 4, 2, roof.lightened(0.25))
	rc(x - 2, y + 12, r.size.x + 4, 2, Color(0, 0, 0, 0.25))
	rc(x, y + 14, r.size.x, 5, Color("f2e6c9"))
	ctext(h["name"], x, y + 18, r.size.x, 5, Color("2b2b2b"))
	rc(x + 6, y + 20, 14, r.size.y - 20, h["door"])
	if r.size.x >= 56.0:
		rc(x + 26, y + 21, 12, 7, Color("8fc9e6"))
		rc(x + 26, y + 21, 12, 2, Color("c8e8f7"))
	rc(x + r.size.x - 10, r.end.y - 7, 6, 5, Color("b5651d"))
	draw_circle(Vector2(x + r.size.x - 7.0, r.end.y - 9.0), 3.0, Color("3c9a40"))
	draw_rect(r, Color("2b2b2b"), false, 1.0)

func draw_stall(s: Dictionary) -> void:
	var r: Rect2 = s["rect"]
	if not view.intersects(r.grow(16.0)):
		return
	var accent: Color = s["accent"]
	shadow(Vector2(r.position.x + r.size.x * 0.5 + 3.0, r.end.y + 1.0), r.size.x * 0.55)
	match s["kind"]:
		"stool":
			draw_stall_stool(r, accent)
		"cart":
			draw_stall_cart(r, accent)
		"drink":
			draw_stall_drink(r, accent)
		_:
			push_warning("Unknown stall kind: %s" % s["kind"])

func draw_stall_stool(r: Rect2, accent: Color) -> void:
	var x := r.position.x
	var y := r.position.y
	rc(x - 2, y, r.size.x + 4, 8, accent)
	for i in range(0, int(r.size.x) + 4, 8):
		rc(x - 2 + i, y, 4, 8, Color.WHITE)
	rc(x - 2, y + 8, r.size.x + 4, 2, Color(0, 0, 0, 0.25))
	rc(x, y + 8, 2, 14, Color("5a3a1c"))
	rc(x + r.size.x - 2, y + 8, 2, 14, Color("5a3a1c"))
	rc(x + 4, y + 13, r.size.x - 8, 3, Color("a8733f"))
	for sx in [6, 16, 28, 38]:
		rc(x + sx, y + 18, 4, 4, Color("2f6fd0"))

func draw_stall_cart(r: Rect2, accent: Color) -> void:
	var x := r.position.x
	var y := r.position.y
	rc(x, y + 3, r.size.x, r.size.y - 3, accent)
	rc(x, y + 3, r.size.x, 2, accent.lightened(0.3))
	rc(x + 2, y, 10, 6, Color("e8f6ff"))
	rc(x + 14, y + 6, 6, 3, Color("c0262d"))
	draw_circle(Vector2(x + 4.0, y + r.size.y), 1.8, Color("2b2b2b"))
	draw_circle(Vector2(x + r.size.x - 4.0, y + r.size.y), 1.8, Color("2b2b2b"))

func draw_stall_drink(r: Rect2, accent: Color) -> void:
	var x := r.position.x
	var y := r.position.y
	var bottles := [Color("ffd23f"), Color("e5322d"), Color("5aa5d6"), Color("5fa04a"), Color("ff9a3c")]
	rc(x - 2, y, r.size.x + 4, 6, Color("8f959c"))
	for i in range(0, int(r.size.x) + 4, 4):
		rc(x - 2 + i, y, 1, 6, Color("6e747b"))
	rc(x - 2, y + 5, r.size.x + 4, 2, Color(0, 0, 0, 0.25))
	rc(x, y + 6, r.size.x, r.size.y - 6, Color("f2e6c9"))
	rc(x + 2, y + 9, r.size.x - 4, 3, Color("a8733f"))
	for i in bottles.size():
		rc(x + 4 + i * 6, y + 6, 3, 3, bottles[i])
	rc(x + 4, y + 15, 5, 5, accent)
	rc(x + r.size.x - 9, y + 15, 5, 5, accent)

func draw_shrine(r: Rect2) -> void:
	if not view.grow(20.0).has_point(r.position):
		return
	shadow(r.position + Vector2(5, 8), 7.0)
	rc(r.position.x, r.position.y + 3, r.size.x, r.size.y - 3, Color("b9a77c"))
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x - 1, r.position.y + 3), Vector2(r.position.x + 5, r.position.y - 2), Vector2(r.end.x + 1, r.position.y + 3)]), Color("c0392b"))
	rc(r.position.x + 4, r.position.y + 4, 2, 3, Color("ffd23f"))

func draw_dog(p: Vector2) -> void:
	if not view.grow(20.0).has_point(p):
		return
	shadow(p + Vector2(3, 4), 5.0)
	rc(p.x, p.y, 7, 4, Color("f4f4f4"))
	rc(p.x + 6, p.y - 2, 4, 4, Color("f4f4f4"))
	rc(p.x + 7, p.y - 3, 2, 2, Color("2b2b2b"))
	rc(p.x - 2, p.y, 2, 1, Color("f4f4f4"))
	rc(p.x + 1, p.y + 4, 1, 2, Color("f4f4f4"))
	rc(p.x + 5, p.y + 4, 1, 2, Color("f4f4f4"))

# ---------- DÃY QUÁN ĐƯỜNG T1 ----------
func draw_t1_shops() -> void:
	for s in SHOPS:
		draw_t1_shop(s)

func draw_t1_shop(s: Dictionary) -> void:
	var r: Rect2 = s["rect"]
	if not view.intersects(r.grow(16.0)):
		return
	shadow(Vector2(r.position.x + r.size.x * 0.5 + 4.0, r.end.y + 1.0), r.size.x * 0.55)
	match s["kind"]:
		"fashion":
			draw_shop_fashion(r, s)
		"salon":
			draw_shop_salon(r, s)
		"phone":
			draw_shop_phone(r, s)
		"book":
			draw_shop_book(r, s)
		"food":
			draw_shop_food(r, s)
		"drink":
			draw_shop_drink(r, s)
		_:
			push_warning("Unknown shop kind: %s" % s["kind"])
	draw_rect(r, Color("2b2b2b"), false, 1.0)

func shop_shell(r: Rect2, wall: Color) -> void:
	rc(r.position.x, r.position.y, r.size.x, r.size.y, wall)
	rc(r.position.x, r.end.y - 4.0, r.size.x, 4.0, wall.darkened(0.15))
	rc(r.position.x, r.position.y, 2.0, r.size.y, Color(1, 1, 1, 0.12))

func shop_sign(r: Rect2, text: String, board: Color, ink: Color) -> void:
	var bx := r.position.x - 1.0
	var bw := r.size.x + 2.0
	rc(bx, r.position.y - 3.0, bw, 11.0, board)
	rc(bx, r.position.y - 3.0, bw, 2.0, board.lightened(0.25))
	rc(bx, r.position.y + 6.0, bw, 2.0, Color(0, 0, 0, 0.25))
	ctext(text, bx, r.position.y + 5.0, bw, 7, ink)

func shop_awning(r: Rect2, c1: Color, c2: Color) -> void:
	var y := r.position.y + 8.0
	rc(r.position.x - 2.0, y, r.size.x + 4.0, 5.0, c1)
	for i in range(0, int(r.size.x) + 4, 8):
		rc(r.position.x - 2.0 + i, y, 4.0, 5.0, c2)
	rc(r.position.x - 2.0, y + 5.0, r.size.x + 4.0, 2.0, Color(0, 0, 0, 0.25))

func draw_shop_fashion(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	var wall: Color = s["wall"]
	var accent: Color = s["accent"]
	shop_shell(r, wall)
	shop_sign(r, s["name"], Color("14161a"), accent)
	shop_awning(r, Color("f2e6c9"), Color("cfd6dc"))
	rc(x + 20, y + 15, r.size.x - 22, 11, Color("14161a"))
	var shirts := [Color("f7efd2"), Color("2b2b2b"), Color("8d939c")]
	for i in 3:
		var mx := x + 24.0 + i * 8.0
		draw_circle(Vector2(mx + 2.0, y + 17.0), 1.6, Color("e8d9c0"))
		rc(mx, y + 18, 4, 7, shirts[i])
	var helmets := [Color("e5322d"), Color("3f8fbf"), Color("8d939c"), Color("ffd23f")]
	for i in 4:
		draw_circle(Vector2(x + 5.0 + (i % 2) * 8.0, y + 19.0 + floori(i * 0.5) * 6.0), 3.2, helmets[i])

func draw_shop_salon(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	var accent: Color = s["accent"]
	shop_shell(r, s["wall"])
	shop_sign(r, s["name"], Color("1b1d22"), Color.WHITE)
	shop_awning(r, Color("3a3d45"), Color("5a6068"))
	rc(x + 3, y + 15, 17, 12, accent)
	ctext("TÓC", x + 3, y + 22, 17, 8, Color.WHITE)
	ctext("NAM-NỮ", x + 3, y + 26, 17, 4, Color("ffd23f"))
	rc(x + 24, y + 15, 24, 11, Color("8fc9e6"))
	rc(x + 24, y + 15, 24, 3, Color("c8e8f7"))
	rc(x + 35, y + 15, 1, 11, Color("4a6b82"))
	rc(x + 28, y + 19, 3, 6, Color("2b2b2b"))
	rc(x + 40, y + 19, 3, 6, Color("2b2b2b"))

func draw_shop_phone(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	shop_shell(r, s["wall"])
	shop_sign(r, s["name"], Color("fafafa"), Color("d8352b"))
	shop_awning(r, s["accent"], Color.WHITE)
	rc(x + 2, y + 15, 14, 11, Color("f2c230"))
	ctext("15K", x + 2, y + 24, 14, 7, Color("d8352b"))
	rc(x + 18, y + 15, 32, 11, Color("dcdfe3"))
	for i in 8:
		for j in 2:
			rc(x + 19 + i * 4, y + 16 + j * 5, 3, 3, Color.from_hsv(hs(i, j + int(y)) / 100.0, 0.6, 0.9))

func draw_shop_book(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	shop_shell(r, s["wall"])
	shop_sign(r, s["name"], s["accent"], Color.WHITE)
	shop_awning(r, s["accent"], Color("f2e6c9"))
	rc(x + 2, y + 15, r.size.x - 4, 11, Color("7a5a2c"))
	var spines := [Color("c0392b"), Color("3f8fbf"), Color("f2c230"), Color("5fa04a")]
	for row in 2:
		for i in 15:
			rc(x + 3 + i * 3, y + 16 + row * 5, 2, 4, spines[hs(i, row + int(y)) % spines.size()])

func draw_shop_food(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	shop_shell(r, s["wall"])
	shop_sign(r, s["name"], s["accent"], Color.WHITE)
	shop_awning(r, s["accent"], Color.WHITE)
	rc(x + 3, y + 15, 20, 11, Color("8fc9e6"))
	rc(x + 3, y + 15, 20, 2, Color("c8e8f7"))
	rc(x + 5, y + 20, 4, 3, Color("ffd23f"))
	rc(x + 11, y + 20, 4, 3, Color("e08a2e"))
	rc(x + 17, y + 20, 4, 3, Color("f7efd2"))
	rc(x + 26, y + 16, 22, 10, Color("a8733f"))
	draw_circle(Vector2(x + 33.0, y + 19.0), 3.0, Color("c4c8cc"))
	rc(x + 27, y + 23, 4, 3, Color("2f6fd0"))
	rc(x + 37, y + 23, 4, 3, Color("2f6fd0"))

func draw_shop_drink(r: Rect2, s: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	var accent: Color = s["accent"]
	rc(x - 2, y, 32, 6, accent)
	for i in range(0, 32, 8):
		rc(x - 2 + i, y, 4, 6, accent.lightened(0.25))
	rc(x - 2, y + 5, 32, 2, Color(0, 0, 0, 0.25))
	rc(x, y + 6, 2, 16, Color("5a3a1c"))
	rc(x + 26, y + 6, 2, 16, Color("5a3a1c"))
	rc(x + 4, y + 12, 20, 3, Color("a8733f"))
	rc(x + 5, y + 16, 4, 4, Color("2f6fd0"))
	rc(x + 19, y + 16, 4, 4, Color("2f6fd0"))
	rc(x + 31, y + 12, 8, 10, Color("8e3b32"))
	rc(x + 31, y + 12, 8, 2, Color("d98a3d"))
	rc(x + 33, y + 16, 4, 3, Color("ffd23f"))
	rc(x + 34, y + 8, 1, 4, Color("c4c8cc"))

# ---------- MẶT TIỀN NHÀ ĐIỀU HÀNH ----------
func draw_admin_topiary(p: Vector2) -> void:
	if not view.grow(30.0).has_point(p):
		return
	shadow(p + Vector2(3, 0), 9.0)
	rc(p.x - 5, p.y - 7, 10, 7, Color("b5381e"))
	rc(p.x - 5, p.y - 7, 10, 2, Color("d9532f"))
	rc(p.x - 1, p.y - 13, 2, 6, Color("5a3a1c"))
	draw_circle(Vector2(p.x, p.y - 17), 6.5, Color("2a6f33"))
	draw_circle(Vector2(p.x - 1, p.y - 18), 5.0, Color("3c9a40"))
	draw_circle(Vector2(p.x, p.y - 25), 4.5, Color("2a6f33"))
	draw_circle(Vector2(p.x - 1, p.y - 26), 3.2, Color("4fb552"))

func draw_vendor_cart(p: Vector2, canopy_a: Color = Color("5aa5d6"), canopy_b: Color = Color("e86aa0")) -> void:
	if not view.grow(40.0).has_point(p):
		return
	shadow(p + Vector2(12, 11), 16.0)
	rc(p.x, p.y, 20, 10, Color("ffd23f"))
	rc(p.x, p.y, 20, 2, Color("fff1a8"))
	rc(p.x + 2, p.y + 3, 8, 5, Color("e8f6ff"))
	draw_circle(Vector2(p.x + 4.0, p.y + 10.0), 2.0, Color("2b2b2b"))
	draw_circle(Vector2(p.x + 16.0, p.y + 10.0), 2.0, Color("2b2b2b"))
	rc(p.x + 9, p.y - 22, 2, 22, Color("8f959c"))
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 6, p.y - 14), Vector2(p.x + 10, p.y - 26), Vector2(p.x + 26, p.y - 14)]), canopy_a)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x + 10, p.y - 26), Vector2(p.x + 26, p.y - 14), Vector2(p.x + 18, p.y - 14)]), canopy_b)

func draw_admin_hedge_banks() -> void:
	for b in admin_hedge_banks():
		for i in 4:
			var ty := b.position.y + i * 12.0
			rc(b.position.x, ty, b.size.x, 10, Color("2a6f33"))
			rc(b.position.x, ty, b.size.x, 3, Color("4aa44f"))
			rc(b.position.x + 2, ty + 1, 4, 2, Color("5bb85c"))
			rc(b.position.x, ty + 10, b.size.x, 2, Color(0, 0, 0, 0.22))

func draw_admin_rails() -> void:
	var r := DIEUHANH
	var steel := Color("d4dbe3")
	var shade := Color("8a94a0")
	var rails := [
		[Vector2(r.position.x + 15.0, r.end.y), Vector2(r.position.x + 5.0, r.end.y + 48.0)],
		[Vector2(r.end.x - 15.0, r.end.y), Vector2(r.end.x - 5.0, r.end.y + 48.0)],
	]
	for rail in rails:
		var a: Vector2 = rail[0]
		var b: Vector2 = rail[1]
		draw_line(a, b, steel, 2.0)
		for k in 6:
			var q := a.lerp(b, k / 5.0)
			rc(q.x, q.y - 5.0, 1, 5, shade)

func draw_dieuhanh_front() -> void:
	if not view.intersects(DIEUHANH.grow(120.0)):
		return
	draw_admin_hedge_banks()
	draw_admin_rails()
	for p in admin_topiary_points():
		draw_admin_topiary(p)
	for b in admin_barricades():
		draw_red_barricade(b)
	for t in ADMIN_PALMS:
		draw_tree(t)
	draw_vendor_cart(UMBRELLA_CART)

# ---------- VA CHẠM MẶT TIỀN ----------
# Gọi một lần trong _ready(), sau khi dữ liệu đã sẵn sàng:
#     if OS.is_debug_build():
#         assert(validate_frontage_layout(), "Frontage layout has invalid solids")
#     build_frontage_solids()
func build_frontage_solids() -> void:
	if is_instance_valid(_frontage_root):
		_frontage_root.queue_free()
	_frontage_root = Node2D.new()
	_frontage_root.name = "FrontageSolids"
	add_child(_frontage_root)
	for r in frontage_solid_rects():
		var body := StaticBody2D.new()
		body.collision_layer = FRONTAGE_SOLID_LAYER
		body.collision_mask = 0
		body.position = r.get_center()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape.shape = rect_shape
		body.add_child(shape)
		_frontage_root.add_child(body)
