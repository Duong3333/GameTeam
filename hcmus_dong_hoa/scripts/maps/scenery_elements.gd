class_name SceneryElements
extends RefCounted
# THÀNH PHẦN CẢNH QUAN TÁI SỬ DỤNG - vẽ cây cối, đèn, bãi xe, v.v.

# ─── MÀU DÙNG CHUNG ─────────────────────────────────────────────────────────
const C_TRUNK_PALM   := Color("7a5230")
const C_TRUNK_PINE   := Color("5a3a1c")
const C_LEAF_DARK    := Color("1e5c28")
const C_LEAF_MID     := Color("2d8a38")
const C_LEAF_LIGHT   := Color("4fb552")
const C_PALM_FROND   := Color("3aa04a")
const C_PINE_DARK    := Color("1f4a1a")
const C_BROAD_DARK   := Color("246b2b")
const C_BROAD_MID    := Color("2c7d33")
const C_BROAD_LIGHT  := Color("379a3f")
const C_HEDGE_DARK   := Color("2a6f33")
const C_HEDGE_MID    := Color("4aa44f")
const C_HEDGE_LIGHT  := Color("5bb85c")
const C_LAMP_POLE    := Color("3a3f4a")
const C_LAMP_HEAD    := Color("6e747b")
const C_ASPHALT      := Color("5a5f68")
const C_STRIPE       := Color("e8e8e8")
const C_PARKING_ROOF := Color("7ab8d4")
const C_PARKING_ROOF2:= Color("a8d8ea")
const C_GRASS_LAWN   := Color("4aa84f")
const C_FLAG_RED     := Color("da251d")
const C_FLAG_YELLOW  := Color("ffde00")
const C_PATH_BEIGE   := Color("dccaa0")
const C_WATER_DARK   := Color("3d86bd")
const C_WATER_MID    := Color("4f9bd0")
const C_WATER_LIGHT  := Color("5aa5d6")
const C_WATER_BORDER := Color("d9c9a3")
const C_WALKWAY_ROOF := Color("4a9a5a")
const C_WALKWAY_FRAME:= Color("2a7a3a")

# ─── CÂY DỪAVỪA / CỌ ────────────────────────────────────────────────────────
static func draw_palm_tree(canvas: CanvasItem, pos: Vector2, scale: float = 1.0) -> void:
	var s := scale
	var p := pos
	# bóng
	canvas.draw_colored_polygon(_oval(p + Vector2(4*s, 2*s), 10*s, 4*s, 16), Color(0,0,0,0.18))
	# thân uốn
	for k in 5:
		canvas.draw_rect(Rect2(p.x - 1.5*s + k*0.15*s, p.y - 4*s - k*3.5*s, 3*s, 4.5*s),
			C_TRUNK_PALM if k % 2 == 0 else Color("9a6840"))
	var top := p + Vector2(0.5*s, -18*s)
	# tán lá dừa
	for a in [-2.9, -2.3, -1.57, -0.85, -0.28, 0.25, -3.4, 1.0, -0.05]:
		var tip: Vector2 = top + Vector2.from_angle(a) * 15.0 * s + Vector2(0, 3*s)
		canvas.draw_line(top, tip, C_LEAF_DARK, 3.5*s)
		canvas.draw_line(top, tip + Vector2(0,-1*s), C_PALM_FROND, 2.0*s)
	# trái dừa nhỏ
	canvas.draw_circle(top + Vector2(-2*s, 2*s), 2.0*s, Color("6b4423"))
	canvas.draw_circle(top + Vector2(2*s, 3*s),  2.0*s, Color("6b4423"))

# ─── CÂY THÔNG CAO VÚT ──────────────────────────────────────────────────────
static func draw_pine_tree(canvas: CanvasItem, pos: Vector2, scale: float = 1.0) -> void:
	var s := scale
	var p := pos
	# bóng
	canvas.draw_colored_polygon(_oval(p + Vector2(3*s, 1*s), 7*s, 3*s, 12), Color(0,0,0,0.18))
	# thân
	canvas.draw_rect(Rect2(p.x - 1.5*s, p.y - 10*s, 3*s, 10*s), C_TRUNK_PINE)
	canvas.draw_rect(Rect2(p.x - 1*s,   p.y - 10*s, 1*s, 10*s), Color("7a5230"))
	# tán 3 tầng
	for layer in 3:
		var base_y := p.y - 12*s - layer * 8*s
		var half_w  := (9.0 - layer * 1.5) * s
		var pts := PackedVector2Array([
			Vector2(p.x, base_y - 10*s + layer*1.5*s),
			Vector2(p.x - half_w, base_y),
			Vector2(p.x + half_w, base_y),
		])
		canvas.draw_colored_polygon(pts, C_PINE_DARK if layer == 0 else (C_LEAF_DARK if layer == 1 else C_LEAF_MID))
		# viền sáng trên
		canvas.draw_line(pts[0], pts[1] + Vector2(1*s, 0), Color(C_LEAF_MID, 0.5), 1.0)
		canvas.draw_line(pts[0], pts[2] + Vector2(-1*s, 0), Color(C_LEAF_LIGHT, 0.4), 1.0)

# ─── CÂY TÁN RỘNG BÓNG MÁT ──────────────────────────────────────────────────
static func draw_broad_tree(canvas: CanvasItem, pos: Vector2, scale: float = 1.0) -> void:
	var s := scale
	var p := pos
	canvas.draw_colored_polygon(_oval(p + Vector2(5*s, 2*s), 14*s, 5*s, 16), Color(0,0,0,0.20))
	canvas.draw_rect(Rect2(p.x - 2.5*s, p.y - 10*s, 5*s, 10*s), C_TRUNK_PINE)
	canvas.draw_rect(Rect2(p.x - 2.5*s, p.y - 10*s, 2*s,  10*s), Color("7a5230"))
	# tán chính
	canvas.draw_circle(Vector2(p.x, p.y - 15*s),    13*s, C_BROAD_DARK)
	canvas.draw_circle(Vector2(p.x - 8*s, p.y - 12*s), 9*s, C_BROAD_MID)
	canvas.draw_circle(Vector2(p.x + 8*s, p.y - 12*s), 9*s, C_BROAD_MID)
	canvas.draw_circle(Vector2(p.x, p.y - 20*s),     9*s, C_BROAD_LIGHT)
	canvas.draw_circle(Vector2(p.x - 3*s, p.y - 22*s), 5*s, C_LEAF_LIGHT)

# ─── HÀNG BỤI THẤP CẮT TỈA ──────────────────────────────────────────────────
static func draw_trimmed_hedge(canvas: CanvasItem, from: Vector2, to: Vector2, thickness: float = 8.0) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x) * thickness
	var pts := PackedVector2Array([from, to, to + perp, from + perp])
	canvas.draw_colored_polygon(pts, C_HEDGE_DARK)
	# viền sáng trên
	var pts2 := PackedVector2Array([from, to, to + perp * 0.4, from + perp * 0.4])
	canvas.draw_colored_polygon(pts2, C_HEDGE_MID)
	# cục sáng
	var len := (to - from).length()
	var step := 6.0
	var i := 0.0
	while i < len - 2.0:
		var base := from + dir * i
		canvas.draw_rect(Rect2(base.x, base.y - 1, 4, 2), C_HEDGE_LIGHT)
		i += step

# ─── CỘT ĐÈN ĐƯỜNG ───────────────────────────────────────────────────────────
static func draw_street_lamp(canvas: CanvasItem, pos: Vector2) -> void:
	var p := pos
	canvas.draw_colored_polygon(_oval(p + Vector2(3,0), 5, 2, 10), Color(0,0,0,0.2))
	canvas.draw_rect(Rect2(p.x - 2, p.y - 28, 4, 28), C_LAMP_POLE)
	canvas.draw_rect(Rect2(p.x - 2, p.y - 28, 1, 28), Color("6a6f7a"))
	canvas.draw_rect(Rect2(p.x - 10, p.y - 29, 20, 2), C_LAMP_HEAD)
	canvas.draw_rect(Rect2(p.x - 7,  p.y - 25, 14, 2), C_LAMP_HEAD)
	canvas.draw_rect(Rect2(p.x + 2,  p.y - 32, 7, 10), Color("aeb8c4"))
	canvas.draw_rect(Rect2(p.x + 2,  p.y - 32, 7, 1),  Color("d4dbe3"))

# ─── CỘT CỜ ──────────────────────────────────────────────────────────────────
static func draw_flag_pole(canvas: CanvasItem, pos: Vector2) -> void:
	var p := pos
	# bóng cột
	canvas.draw_colored_polygon(_oval(p + Vector2(4,0), 5, 2, 10), Color(0,0,0,0.18))
	# thân cột
	canvas.draw_rect(Rect2(p.x - 1, p.y - 50, 2, 50), Color("aeb8c4"))
	canvas.draw_rect(Rect2(p.x - 1, p.y - 50, 1, 50), Color("d4dbe3"))
	# cờ đỏ sao vàng (nhỏ)
	var fw := 20.0; var fh := 13.0
	canvas.draw_rect(Rect2(p.x + 1, p.y - 50, fw, fh), C_FLAG_RED)
	var fc := Vector2(p.x + 1 + fw * 0.4, p.y - 50 + fh * 0.5)
	var outer := fh * 0.28
	var pts := PackedVector2Array()
	for k in 10:
		var angle := -PI / 2.0 + k * PI / 5.0
		var radius := outer if k % 2 == 0 else outer * 0.382
		pts.append(fc + Vector2.from_angle(angle) * radius)
	canvas.draw_colored_polygon(pts, C_FLAG_YELLOW)

# ─── HÀNH LANG MÁI CHE VÒNG ─────────────────────────────────────────────────
static func draw_covered_walkway(canvas: CanvasItem, from: Vector2, to: Vector2, width: float = 14.0) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x) * width
	var len := (to - from).length()
	# nền hành lang
	var base_pts := PackedVector2Array([from, to, to + perp, from + perp])
	canvas.draw_colored_polygon(base_pts, Color("c8d6b0"))
	# trụ cột cứ 24px
	var i := 0.0
	while i <= len:
		var cp := from + dir * i
		canvas.draw_rect(Rect2(cp.x - 2, cp.y - 2, 4, width + 2), C_WALKWAY_FRAME)
		# vòm mái
		canvas.draw_rect(Rect2(cp.x - 4, cp.y - 7, 8, 7), C_WALKWAY_ROOF)
		canvas.draw_rect(Rect2(cp.x - 4, cp.y - 7, 8, 2), Color("6aba7a"))
		i += 24.0

# ─── Ô ĐỖ XE CÓ VẠCH KẺ ────────────────────────────────────────────────────
# direction: 0 = ngang (kẻ dọc theo x), 1 = dọc (kẻ ngang theo y)
static func draw_parking_bays(canvas: CanvasItem, rect: Rect2, direction: int = 0, bay_w: float = 24.0) -> void:
	canvas.draw_rect(rect, C_ASPHALT)
	canvas.draw_rect(rect, Color("4a4f57"), false, 1.5)
	if direction == 0:
		var x := rect.position.x + bay_w
		while x < rect.end.x - 2:
			canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(C_STRIPE, 0.6), 1.0)
			x += bay_w
		# vạch phân chia làn
		var mid_y := rect.position.y + rect.size.y * 0.5
		canvas.draw_line(Vector2(rect.position.x, mid_y), Vector2(rect.end.x, mid_y), Color(C_STRIPE, 0.3), 1.0)
	else:
		var y := rect.position.y + bay_w
		while y < rect.end.y - 2:
			canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(C_STRIPE, 0.6), 1.0)
			y += bay_w

# ─── MÁI CHE BÃI XE ─────────────────────────────────────────────────────────
static func draw_parking_roof(canvas: CanvasItem, rect: Rect2) -> void:
	# cột chống đỡ
	var x := rect.position.x + 10
	while x < rect.end.x - 5:
		canvas.draw_rect(Rect2(x - 2, rect.position.y, 4, rect.size.y), Color("4a5560"))
		x += 50.0
	# mái
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 10), C_PARKING_ROOF)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3),  C_PARKING_ROOF2)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + 7, rect.size.x, 3), Color("5a9ab8"))

# ─── VẠCH KẺ ĐƯỜNG NGƯỜI ĐI BỘ ──────────────────────────────────────────────
static func draw_zebra_crossing(canvas: CanvasItem, pos: Vector2, width: float = 40.0, height: float = 10.0, horizontal: bool = true) -> void:
	if horizontal:
		var x := pos.x
		while x < pos.x + width - 4:
			canvas.draw_rect(Rect2(x, pos.y, 5, height), Color(C_STRIPE, 0.9))
			x += 9.0
	else:
		var y := pos.y
		while y < pos.y + height - 4:
			canvas.draw_rect(Rect2(pos.x, y, width, 5), Color(C_STRIPE, 0.9))
			y += 9.0

# ─── DẢI PHÂN CÁCH GIỮA ĐƯỜNG ──────────────────────────────────────────────
static func draw_road_divider(canvas: CanvasItem, from: Vector2, to: Vector2, width: float = 20.0) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x) * (width * 0.5)
	var pts := PackedVector2Array([from - perp, to - perp, to + perp, from + perp])
	canvas.draw_colored_polygon(pts, C_GRASS_LAWN)
	# bờ viền
	canvas.draw_polyline(PackedVector2Array([from - perp, to - perp]), Color("3a7a3a"), 1.5)
	canvas.draw_polyline(PackedVector2Array([from + perp, to + perp]), Color("3a7a3a"), 1.5)

# --- CHU "We HCMUS" - pixel art block letters ---
static func draw_we_love_hcmus(canvas: CanvasItem, pos: Vector2) -> void:
	# nen co sang hon
	canvas.draw_rect(Rect2(pos.x - 82, pos.y - 30, 164, 48), Color("5fbb4a"))
	var blue := Color("1a4fa8")
	var red  := Color("e8231e")
	var S    := 3.0
	var x    := pos.x - 80.0
	var y    := pos.y - 24.0

	# W
	for d in [[0,0],[4,0],[0,1],[4,1],[0,2],[4,2],[0,3],[2,3],[4,3],[0,4],[2,4],[4,4],[1,5],[3,5],[1,6],[3,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 6*S + 2

	# e
	for d in [[1,2],[2,2],[0,3],[0,4],[1,4],[2,4],[3,4],[0,5],[1,6],[2,6],[3,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 5*S + 4

	# HEART
	for d in [[1,1],[2,1],[4,1],[5,1],[0,2],[1,2],[2,2],[3,2],[4,2],[5,2],[6,2],[0,3],[1,3],[2,3],[3,3],[4,3],[5,3],[6,3],[1,4],[2,4],[3,4],[4,4],[5,4],[2,5],[3,5],[4,5],[3,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), red)
	x += 9*S + 4

	# H
	for d in [[0,0],[4,0],[0,1],[4,1],[0,2],[1,2],[2,2],[3,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5],[0,6],[4,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 6*S + 1

	# C
	for d in [[1,0],[2,0],[3,0],[4,0],[0,1],[0,2],[0,3],[0,4],[0,5],[1,5],[2,5],[3,5],[4,5]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 6*S + 1

	# M
	for d in [[0,0],[4,0],[0,1],[1,1],[3,1],[4,1],[0,2],[2,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5],[0,6],[4,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 6*S + 1

	# U
	for d in [[0,0],[4,0],[0,1],[4,1],[0,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5],[1,6],[2,6],[3,6]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
	x += 6*S + 1

	# S
	for d in [[1,0],[2,0],[3,0],[4,0],[0,1],[1,2],[2,2],[3,2],[4,3],[4,4],[0,5],[1,5],[2,5],[3,5]]:
		canvas.draw_rect(Rect2(x + d[0]*S, y + d[1]*S, S, S), blue)
static func draw_white_monument(canvas: CanvasItem, pos: Vector2) -> void:
	var p := pos
	# bóng bệ
	canvas.draw_colored_polygon(_oval(p + Vector2(4,2), 20, 6, 16), Color(0,0,0,0.22))
	# bệ bát giác (vẽ bằng đa giác)
	var base_pts := PackedVector2Array()
	for k in 8:
		var a := TAU * k / 8.0 - PI / 8.0
		base_pts.append(p + Vector2(cos(a) * 18, sin(a) * 8) + Vector2(0, 4))
	canvas.draw_colored_polygon(base_pts, Color("c8c0a8"))
	var inner_pts := PackedVector2Array()
	for k in 8:
		var a := TAU * k / 8.0 - PI / 8.0
		inner_pts.append(p + Vector2(cos(a) * 14, sin(a) * 6) + Vector2(0, 2))
	canvas.draw_colored_polygon(inner_pts, Color("e8e0cc"))
	# bệ trụ
	canvas.draw_rect(Rect2(p.x - 6, p.y - 18, 12, 20), Color("d4cbb8"))
	canvas.draw_rect(Rect2(p.x - 6, p.y - 18, 2, 20), Color("eee6d4"))
	canvas.draw_rect(Rect2(p.x - 8, p.y - 20, 16, 4), Color("c0b8a0"))
	# trụ chính
	canvas.draw_rect(Rect2(p.x - 4, p.y - 42, 8, 24), Color("e8e4da"))
	canvas.draw_rect(Rect2(p.x - 4, p.y - 42, 2, 24), Color("f8f4ee"))
	# đỉnh tháp
	var tip := PackedVector2Array([
		Vector2(p.x, p.y - 54), Vector2(p.x - 6, p.y - 42), Vector2(p.x + 6, p.y - 42)
	])
	canvas.draw_colored_polygon(tip, Color("e0dcd2"))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(p.x, p.y - 54), Vector2(p.x - 1, p.y - 42), Vector2(p.x + 3, p.y - 42)
	]), Color("f0ece4"))
	# bồn hoa quanh bệ
	var fr := 22.0
	for k in 6:
		var a := TAU * k / 6.0
		var fp := p + Vector2(cos(a) * fr, sin(a) * fr * 0.45) + Vector2(0, 6)
		canvas.draw_circle(fp, 3.5, Color("2a7a35"))
		canvas.draw_circle(fp + Vector2(-1,-1), 2.0, Color("3f9c45"))
		if k % 2 == 0:
			canvas.draw_circle(fp + Vector2(-1,-2), 1.5, Color("ff9ecb"))

# ─── ĐÀI PHUN NƯỚC & HỒ SINH VIÊN (TÁI HIỆN CHUẨN XÁC THEO ẢNH THẬT HCMUS) ──
static func draw_fountain_plaza(canvas: CanvasItem, center: Vector2, radius: float = 110.0, clock: float = 0.0, show_vegetation: bool = true) -> void:
	HoNuoc.draw_landscape(canvas, center, clock, show_vegetation)

# ─── HELPER NỘI BỘ ─────────────────────────────────────────────────────────
static func _oval(c: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
