extends RefCounted
class_name HoNuoc
# HỒ NƯỚC + ĐÀI PHUN ở sân giữa khuôn viên (tâm = FOUNT trong campus_data.gd).
# Bát giác có cạnh phẳng hướng lên/xuống/trái/phải. Từ ngoài vào trong:
#   bậc đá -> bờ đá -> mặt nước -> vòng đá đồng tâm -> nước trong -> đảo hoa + đài phun
# 4 lối đi đá (trên/dưới/trái/phải) bắc từ sân vào đảo, 4 lá sen ở các góc chéo.
#
# Muốn to/nhỏ: sửa các hằng số *_A bên dưới
# (A = khoảng cách từ tâm tới GIỮA mỗi cạnh bát giác, đơn vị px).
# Chặn đi xuống nước: campus_setup.gd gọi collision_rects(); vùng chặn bám theo COPING_A.

const STEP_A := 71.0     # mép ngoài cùng của bậc đá
const COPING_A := 66.0   # mặt bờ đá (cũng là mép vùng va chạm)
const WATER_A := 61.0    # mép mặt nước ngoài
const RING_A := 40.0     # vòng đá đồng tâm
const POOL_A := 35.0     # mặt nước bên trong vòng đá
const ISLAND_A := 17.0   # đảo giữa
const WALK_HALF := 5.0   # nửa bề rộng lối đi

const STONE_DARK := Color("a3adaa")
const STONE := Color("d9d5c8")
const STONE_LIGHT := Color("f4f0e2")
const STONE_SHADE := Color("aaa999")
const STONE_JOINT := Color("c8c4b5")
const WATER_EDGE := Color("2f6f86")
const WATER_DEEP := Color("3f8aa3")
const WATER_MID := Color("4a98b0")
const WATER_LIGHT := Color("56a4bb")
const POOL_DEEP := Color("4f9fb8")
const POOL_MID := Color("5cb0c6")
const POOL_LIGHT := Color("69bdd0")

static func draw_landscape(canvas, center: Vector2, clock: float) -> void:
	# Ngoài màn hình thì khỏi vẽ.
	var area := Rect2(center - Vector2(100, 112), Vector2(200, 224))
	if not canvas.view.grow(24.0).intersects(area):
		return
	_draw_gardens(canvas, center)
	_draw_basin(canvas, center)
	_draw_lily_pads(canvas, center, clock)
	_draw_water_effects(canvas, center, clock)
	_draw_walkways(canvas, center)
	_draw_island(canvas, center)
	_draw_fountain(canvas, center, clock)
	_draw_posts(canvas, center)

# Các khối chữ nhật chặn người đi xuống nước (ghép thành hình bát giác).
# Gọi từ campus_setup.gd: solids.append_array(...collision_rects(FOUNT))
static func collision_rects(center: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var a := COPING_A
	var row := 6.0
	var y := -a
	while y < a - 0.01:
		var near: float = minf(absf(y), absf(y + row))
		var hw: float = a if near <= a * 0.4142 else a * 1.4142 - near
		out.append(Rect2(center.x - hw, center.y + y, hw * 2.0, row))
		y += row
	return out

# ---------- Hình học ----------

static func _octagon(c: Vector2, apothem: float) -> PackedVector2Array:
	var r := apothem / cos(PI / 8.0)
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(c + Vector2.from_angle(PI / 8.0 + float(i) * PI / 4.0) * r)
	return pts

static func _oct(canvas, c: Vector2, apothem: float, col: Color) -> void:
	canvas.draw_colored_polygon(_octagon(c, apothem), col)

static func _octagon_outline(canvas, c: Vector2, apothem: float, col: Color) -> void:
	var pts := _octagon(c, apothem)
	pts.append(pts[0])
	canvas.draw_polyline(pts, col, 1.0)

# ---------- Bờ đá + mặt nước ----------

static func _draw_basin(canvas, c: Vector2) -> void:
	# bóng đổ xuống sân
	_oct(canvas, c + Vector2(0, 3), STEP_A + 1.0, Color(0, 0, 0, 0.16))
	# bậc đá thấp + bậc đá cao (bờ hồ)
	_oct(canvas, c, STEP_A, STONE_DARK)
	_oct(canvas, c, STEP_A - 1.0, STONE)
	_oct(canvas, c, COPING_A + 1.0, STONE_SHADE)
	_oct(canvas, c, COPING_A, STONE_LIGHT)
	_oct(canvas, c, COPING_A - 3.0, STONE_DARK)
	# mặt nước ngoài: đậm ở sát bờ, sáng dần vào trong
	_oct(canvas, c, WATER_A + 1.0, WATER_EDGE)
	_oct(canvas, c, WATER_A, WATER_DEEP)
	_oct(canvas, c, WATER_A - 4.0, WATER_MID)
	_oct(canvas, c, WATER_A - 11.0, WATER_LIGHT)

	# vòng đá đồng tâm quanh đài phun (bóng đổ xuống nước trước)
	_oct(canvas, c + Vector2(0, 2), RING_A + 1.5, Color(0, 0.1, 0.2, 0.25))
	_oct(canvas, c, RING_A, STONE_DARK)
	_oct(canvas, c, RING_A - 1.0, STONE_LIGHT)
	_oct(canvas, c, RING_A - 3.0, STONE)
	_oct(canvas, c, RING_A - 4.0, STONE_SHADE)
	# nước trong vòng đá: sáng hơn nước ngoài
	_oct(canvas, c, POOL_A, POOL_DEEP)
	_oct(canvas, c, POOL_A - 5.0, POOL_MID)
	_oct(canvas, c, POOL_A - 11.0, POOL_LIGHT)

static func _draw_water_effects(canvas, c: Vector2, clock: float) -> void:
	# sóng lan từ đảo ra tới vòng đá
	for i in 3:
		var t := fposmod(clock * 0.35 + float(i) / 3.0, 1.0)
		var ap: float = lerpf(ISLAND_A + 2.0, POOL_A - 1.0, t)
		_octagon_outline(canvas, c, ap, Color(0.9, 0.98, 1.0, (1.0 - t) * 0.5))
	# gợn nhẹ ở mặt nước ngoài
	_octagon_outline(canvas, c, WATER_A - 7.0, Color(1, 1, 1, 0.12 + 0.06 * sin(clock * 1.5)))
	# ánh nắng lấp lánh
	for k in 8:
		if sin(clock * 2.0 + float(k) * 1.3) > 0.3:
			var p: Vector2 = (c + Vector2.from_angle(PI / 8.0 + float(k) * PI / 4.0) * (RING_A + 14.0)).round()
			canvas.rc(p.x - 1, p.y, 3, 1, Color(1, 1, 1, 0.75))
			canvas.rc(p.x + 2, p.y + 2, 2, 1, Color(1, 1, 1, 0.5))

# ---------- Lá sen ở 4 góc chéo ----------

static func _draw_lily_pads(canvas, c: Vector2, clock: float) -> void:
	var mid := (RING_A + WATER_A) * 0.5
	for k in 4:
		var dir := Vector2.from_angle(PI / 4.0 + float(k) * PI / 2.0)
		var bob := Vector2(sin(clock * 0.7 + float(k) * 1.9), cos(clock * 0.5 + float(k) * 2.3)) * 0.7
		var p := c + dir * mid + bob
		var side := Vector2(-dir.y, dir.x)
		_lily(canvas, p, 3.5, dir.angle() + PI)
		_lily(canvas, p + side * 7.0 + dir * 2.0, 2.4, dir.angle() + 2.0)
		_lily(canvas, p - side * 6.0 - dir * 3.0, 2.0, dir.angle() - 2.0)
		if k % 2 == 0:
			var f := p.round()
			canvas.rc(f.x - 1, f.y - 1, 2, 2, Color("f08fb4"))
			canvas.rc(f.x, f.y - 1, 1, 1, Color("ffe0ec"))

static func _lily(canvas, p: Vector2, r: float, notch: float) -> void:
	canvas.draw_circle(p + Vector2(0, 1), r, Color(0, 0.12, 0.2, 0.25))
	canvas.draw_circle(p, r, Color("397e4a"))
	canvas.draw_circle(p + Vector2(-0.5, -0.5), r * 0.65, Color("59a95e"))
	canvas.draw_colored_polygon(PackedVector2Array([
		p,
		p + Vector2.from_angle(notch - 0.25) * (r + 1.0),
		p + Vector2.from_angle(notch + 0.25) * (r + 1.0),
	]), WATER_MID)

# ---------- Lối đi đá bắc qua hồ ----------

static func _draw_walkways(canvas, c: Vector2) -> void:
	var h := WALK_HALF
	# bóng của lối đi trên mặt nước
	var shade := Color(0, 0.15, 0.25, 0.28)
	for ab in [Vector2(RING_A, WATER_A), Vector2(ISLAND_A, POOL_A)]:
		var a: float = ab.x
		var length: float = ab.y - ab.x
		canvas.draw_rect(Rect2(c + Vector2(a + 1, -h + 2), Vector2(length, h * 2.0)), shade)
		canvas.draw_rect(Rect2(c + Vector2(-a - length + 1, -h + 2), Vector2(length, h * 2.0)), shade)
		canvas.draw_rect(Rect2(c + Vector2(-h + 1, a + 2), Vector2(h * 2.0, length)), shade)
		canvas.draw_rect(Rect2(c + Vector2(-h + 1, -a - length + 2), Vector2(h * 2.0, length)), shade)
	# đoạn ngoài: từ vòng đá ra tới bậc đá; đoạn trong: từ đảo ra tới vòng đá
	for seg in [Vector2(RING_A - 2.0, STEP_A), Vector2(ISLAND_A - 3.0, POOL_A + 2.0)]:
		var a: float = seg.x
		var length: float = seg.y - seg.x
		_draw_walk(canvas, Rect2(c + Vector2(a, -h), Vector2(length, h * 2.0)), true)
		_draw_walk(canvas, Rect2(c + Vector2(-a - length, -h), Vector2(length, h * 2.0)), true)
		_draw_walk(canvas, Rect2(c + Vector2(-h, a), Vector2(h * 2.0, length)), false)
		_draw_walk(canvas, Rect2(c + Vector2(-h, -a - length), Vector2(h * 2.0, length)), false)

static func _draw_walk(canvas, rect: Rect2, horizontal: bool) -> void:
	canvas.draw_rect(rect.grow(1.0), STONE_DARK)
	canvas.draw_rect(rect, STONE)
	if horizontal:
		canvas.rc(rect.position.x, rect.position.y, rect.size.x, 1, STONE_LIGHT)
		canvas.rc(rect.position.x, rect.end.y - 1.0, rect.size.x, 1, STONE_SHADE)
		var x := rect.position.x + 4.0
		while x < rect.end.x - 2.0:
			canvas.rc(x, rect.position.y + 1.0, 1, rect.size.y - 2.0, STONE_JOINT)
			x += 6.0
	else:
		canvas.rc(rect.position.x, rect.position.y, 1, rect.size.y, STONE_LIGHT)
		canvas.rc(rect.end.x - 1.0, rect.position.y, 1, rect.size.y, STONE_SHADE)
		var y := rect.position.y + 4.0
		while y < rect.end.y - 2.0:
			canvas.rc(rect.position.x + 1.0, y, rect.size.x - 2.0, 1, STONE_JOINT)
			y += 6.0

# ---------- Đảo giữa + đài phun ----------

static func _draw_island(canvas, c: Vector2) -> void:
	_oct(canvas, c + Vector2(0, 2), ISLAND_A + 1.5, Color(0, 0.1, 0.2, 0.3))
	_oct(canvas, c, ISLAND_A, STONE_DARK)
	_oct(canvas, c, ISLAND_A - 1.0, STONE_LIGHT)
	_oct(canvas, c, ISLAND_A - 3.0, Color("286d38"))
	_oct(canvas, c, ISLAND_A - 4.0, Color("4a8a3a"))
	# hoa quanh đài phun
	var flower_colors := [Color("e8584f"), Color("f2c94c"), Color("f08fb4"), Color("ffffff")]
	for i in 12:
		var p: Vector2 = (c + Vector2.from_angle(float(i) * TAU / 12.0) * 10.5).round()
		canvas.rc(p.x - 1, p.y - 1, 2, 2, flower_colors[i % flower_colors.size()])

static func _draw_fountain(canvas, c: Vector2, clock: float) -> void:
	# bệ tròn
	canvas.draw_circle(c + Vector2(0, 1), 7.0, Color("536f79"))
	canvas.draw_circle(c, 6.0, Color("aeb9b8"))
	canvas.draw_circle(c, 4.5, Color("e3e1d4"))
	canvas.draw_circle(c, 3.0, Color("68bfd8"))
	canvas.draw_circle(c, 1.5, Color("e8f6ff"))
	# tia nước phun toả 8 hướng
	for i in 8:
		var angle := float(i) * PI / 4.0
		var length := 7.0 + sin(clock * 4.0 + float(i)) * 2.0
		var tip := c + Vector2.from_angle(angle) * length
		canvas.draw_line(c, tip, Color(0.91, 0.96, 1.0, 0.9), 1.0)
		canvas.draw_circle(tip, 1.0, Color.WHITE)
	# giọt nước rơi xuống mặt nước quanh đảo
	for i in 8:
		var ph := fposmod(clock * 0.9 + float(i) * 0.125, 1.0)
		var r: float = lerpf(11.0, 27.0, ph)
		var p: Vector2 = (c + Vector2.from_angle(float(i) * PI / 4.0 + PI / 8.0) * r).round()
		canvas.rc(p.x, p.y, 1, 1, Color(1, 1, 1, 1.0 - ph))

# ---------- Trụ đá ở 8 góc bờ hồ ----------

static func _draw_posts(canvas, c: Vector2) -> void:
	for p in _octagon(c, COPING_A - 1.0):
		canvas.draw_circle(p + Vector2(0, 1), 2.5, STONE_DARK)
		canvas.draw_circle(p, 2.0, STONE_LIGHT)
		canvas.draw_circle(p + Vector2(-0.5, -0.5), 1.0, Color.WHITE)

# ---------- Luống hoa (giữ nguyên như bản cũ) ----------

static func _draw_gardens(canvas, center: Vector2) -> void:
	for x_sign in [-1.0, 1.0]:
		for y_sign in [-1.0, 1.0]:
			var p := center + Vector2(72.0 * x_sign, 72.0 * y_sign)
			var bed := Rect2(p - Vector2(12, 12), Vector2(24, 24))
			canvas.draw_rect(bed.grow(1), Color("777f78"))
			canvas.draw_rect(bed, Color("b9a77c"))
			canvas.draw_rect(bed.grow(-2), Color("4a8a3a"))
			for angle in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
				var tip := p + Vector2.from_angle(angle) * 8.0 + Vector2(0, 1)
				canvas.draw_line(p, tip, Color("286d38"), 2.0)
				canvas.draw_line(p, tip + Vector2(0, -1), Color("75b94f"), 1.0)
			canvas.rc(p.x - 1, p.y - 1, 2, 2, Color("8a5a32"))
