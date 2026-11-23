extends "res://scripts/draw/newcharacters.gd"
# HIỂN THỊ KHUÔN VIÊN: sắp xếp chiều sâu, hiệu ứng trời và minimap.

const BG_MARGIN := 400.0
const BG_TRIGGER := 120.0

func _draw() -> void:
	var cc := cam.get_screen_center_position()
	view = Rect2(cc - Vector2(262, 152), Vector2(524, 304))
	_sync_static_bg()

	# Hoi truong B van duoc ve boi Main vi draw_hall_b_exterior() dung game.rc().
	for b in BUILDINGS:
		if str(b[0]) == "B":
			draw_building(b)
			break
	draw_fountain_dynamic()
	draw_sorted_items()
	for f in features:
		f.draw_front_layer()
	draw_sky_effects()
	draw_minimap()

func _sync_static_bg() -> void:
	if _static_bg == null:
		return
	var world_rect := Rect2(Vector2.ZERO, WORLD)
	var want := view.grow(BG_TRIGGER).intersection(world_rect)
	if _bg_rect.has_area() and _bg_rect.encloses(want):
		return
	_bg_rect = view.grow(BG_MARGIN).intersection(world_rect)
	_static_bg.view = _bg_rect
	_static_bg.queue_redraw()

func invalidate_static_bg() -> void:
	_bg_rect = Rect2()
	if _static_bg != null:
		_static_bg.queue_redraw()

func draw_fountain_dynamic() -> void:
	if view.intersects(Rect2(FOUNTAIN_CENTER - Vector2(130, 130), Vector2(260, 260))):
		SE.draw_fountain_plaza(self, FOUNTAIN_CENTER, 110.0, clock, SHOW_VEGETATION)

func draw_sorted_items() -> void:
	var items: Array = []
	for t in trees:
		items.append([float(t[1]), 0, t])
	for n in npcs:
		items.append([n.pos.y, 1, n])
	for l in lamps:
		items.append([l.y, 3, l])
	for bn in benches:
		items.append([get_bench_position(bn).y, 4, bn])
	items.append([player.y, 2, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[1] == 0:
			draw_tree(it[2])
		elif it[1] == 3:
			if view.has_point(it[2]):
				draw_lamp(it[2])
		elif it[1] == 4:
			if view.has_point(get_bench_position(it[2])):
				draw_bench(it[2])
		elif it[1] == 1:
			var n: Dictionary = it[2]
			if not view.has_point(n.pos):
				continue
			draw_person(n.pos, n.shirt, n.hair, n.face, n.anim, n.uni, n.long, n.pack)
			if n.get("quiz", false):
				draw_quiz_marker(n)
			if n.say_t > 0.0:
				draw_speech(n)
		else:
			draw_person(player, Color.WHITE, Color("1b1b1b"), facing, anim, true, false, true)
			ctext("Bạn", player.x - 15, player.y - 28, 30, 8, Color("ffd23f"))

func draw_sky_effects() -> void:
	for c in clouds:
		if not view.grow(c.r).has_point(Vector2(c.x, c.y)):
			continue
		draw_set_transform(Vector2(c.x, c.y), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, c.r, Color(0, 0, 0, 0.06))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_minimap_rect(origin: Vector2, rect: Rect2, scale: float, color: Color) -> void:
	rc(
		origin.x + rect.position.x * scale,
		origin.y + rect.position.y * scale,
		rect.size.x * scale,
		rect.size.y * scale,
		color
	)

func draw_minimap() -> void:
	var o := cam.get_screen_center_position() - Vector2(240, 135) + Vector2(376, 40)
	var sc := 96.0 / WORLD.x
	rc(o.x - 2, o.y - 2, 100, 64, Color(0, 0, 0, 0.6))
	rc(o.x, o.y, 96, 60, Color("4f8a45"))
	var road_color := Color("6a7078")
	var sidewalk_color := Color("dccaa0")
	for road in [
		Rect2(0, 879, WORLD.x, 211),
		Rect2(1268, 0, 109, 879),
		Rect2(1822, 260, 97, 619),
		Rect2(669, 191, WORLD.x - 669, 63),
		GATE_APPROACH_ROAD,
	]:
		_draw_minimap_rect(o, road, sc, road_color)
	for sidewalk in [
		Rect2(0, 835, WORLD.x, 44),
		Rect2(0, 1090, 1098, 80),
		Rect2(1507, 1090, WORLD.x - 1507, 39),
		Rect2(1249, 0, 19, 879),
		Rect2(1804, 260, 18, 619),
		Rect2(1919, 260, 18, 619),
		Rect2(669, 176, WORLD.x - 669, 15),
		STRIP_T1_LEFT,
		STRIP_T1,
		Rect2(0, GATE_Y, GATE_X - 14, 14),
		Rect2(GATE_X + GATE_W + 14, GATE_Y, WORLD.x - GATE_X - GATE_W - 14, 14),
	]:
		_draw_minimap_rect(o, sidewalk, sc, sidewalk_color)
	_draw_minimap_rect(o, PARKING1_RECT, sc, Color("8d939c"))
	_draw_minimap_rect(o, PARKING2_RECT, sc, Color("8d939c"))
	for b in BUILDINGS:
		rc(o.x + b[1] * sc, o.y + b[2] * sc, b[3] * sc, b[4] * sc, Color("e0b84a"))
	rc(o.x + DIEUHANH.position.x * sc, o.y + DIEUHANH.position.y * sc, DIEUHANH.size.x * sc, DIEUHANH.size.y * sc, Color("e8e2d0"))
	draw_circle(o + FOUNT * sc, 2.5, Color("6fb7e0"))
	if int(clock * 3.0) % 2 == 0:
		rc(o.x + player.x * sc - 1.5, o.y + player.y * sc - 1.5, 3, 3, Color.WHITE)
	rc(o.x + player.x * sc - 0.5, o.y + player.y * sc - 0.5, 1, 1, Color("e5322d"))
