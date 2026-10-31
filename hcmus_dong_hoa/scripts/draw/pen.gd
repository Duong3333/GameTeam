extends "res://scripts/maps/campus_setup.gd"
# BÚT VẼ CƠ BẢN: hình chữ nhật pixel, bóng đổ, chữ có viền, nền lát gạch, nhựa đường.

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
