extends "res://scripts/draw/scenery.gd"
# CÔNG TRÌNH: các tòa nhà A-G + Nhà Thể Dục, Nhà Điều hành, quầy nhỏ (kiosk).

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
