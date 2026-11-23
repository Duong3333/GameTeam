extends "res://scripts/draw/newcharacters.gd"
# HIỂN THỊ KHUÔN VIÊN: sắp xếp chiều sâu, hiệu ứng trời và minimap.

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
	draw_sorted_items()
	for f in features:
		f.draw_front_layer()
	draw_sky_effects()
	draw_minimap()

func draw_sorted_items() -> void:
	var items: Array = []
	var tree_view := view.grow(30.0)
	for t in trees:
		var tree_pos := Vector2(t[0], t[1])
		if tree_view.has_point(tree_pos):
			items.append([float(t[1]), 0, t])
	for n in npcs:
		if view.has_point(n.pos):
			items.append([n.pos.y, 1, n])
	if multiplayer_manager != null:
		var remote_players: Dictionary = multiplayer_manager.get_other_players()
		for remote in remote_players.values():
			if view.has_point(remote.pos):
				items.append([remote.pos.y, 5, remote])
	for l in lamps:
		if view.has_point(l):
			items.append([l.y, 3, l])
	for bn in benches:
		if view.has_point(bn):
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
			if n.get("quiz", false):
				draw_quiz_marker(n)
			if n.say_t > 0.0:
				draw_speech(n)
		elif it[1] == 5:
			var remote: Dictionary = it[2]
			var remote_pos: Vector2 = remote.pos
			if not view.has_point(remote_pos):
				continue
			draw_person(remote_pos, Color("7dc8ff"), Color("3b2a1a"), remote.facing, remote.anim, true, false, false)
			var peer_id: int = remote.get("id", 0)
			ctext("Chủ phòng" if peer_id == 1 else "Người chơi %d" % peer_id, remote_pos.x - 36, remote_pos.y - 28, 72, 8, Color("9fe3ff"))
		else:
			draw_person(player, Color.WHITE, Color("1b1b1b"), facing, anim, true, false, true)
			ctext("Bạn", player.x - 15, player.y - 28, 30, 8, Color("ffd23f"))

func draw_sky_effects() -> void:
	for c in clouds:
		if not view.grow(float(c.r)).has_point(Vector2(c.x, c.y)):
			continue
		draw_set_transform(Vector2(c.x, c.y), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, c.r, Color(0, 0, 0, 0.06))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in petals:
		if view.has_point(p.pos):
			rc(p.pos.x, p.pos.y, 2, 2, Color("ff5a4d"))

func draw_minimap() -> void:
	var map_width := 108.0
	var map_height := WORLD.y * map_width / WORLD.x
	var o := cam.get_screen_center_position() - Vector2(240, 135) + Vector2(356, 55)
	var sc := map_width / WORLD.x
	var frame := Rect2(o - Vector2(4, 4), Vector2(map_width + 8, map_height + 8))
	draw_rect(frame, Color("101a2b"))
	draw_rect(frame, Color("71839a"), false, 1.0)
	rc(o.x, o.y, map_width, map_height, Color("4f8a45"))
	rc(o.x, o.y + 585.0 * sc, map_width, 50.0 * sc, Color("6a7078"))
	rc(o.x + GATE_X * sc, o.y + 635.0 * sc, GATE_W * sc, 325.0 * sc, Color("6a7078"))
	rc(o.x + 150.0 * sc, o.y + 690.0 * sc, 520.0 * sc, 200.0 * sc, Color("8d939c"))
	for b in BUILDINGS:
		rc(o.x + b[1] * sc, o.y + b[2] * sc, b[3] * sc, b[4] * sc, Color("e0b84a"))
	rc(o.x + DIEUHANH.position.x * sc, o.y + DIEUHANH.position.y * sc, DIEUHANH.size.x * sc, DIEUHANH.size.y * sc, Color("e8e2d0"))
	draw_circle(o + FOUNT * sc, 2.5, Color("6fb7e0"))
	draw_rect(Rect2(o, Vector2(map_width, map_height)), Color("b8c5d6"), false, 1.0)
	if int(clock * 3.0) % 2 == 0:
		draw_circle(o + player * sc, 2.2, Color.WHITE)
	draw_circle(o + player * sc, 1.3, Color("e5322d"))
	if multiplayer_manager != null:
		for remote in multiplayer_manager.get_other_players().values():
			draw_circle(o + remote.pos * sc, 1.6, Color("36d9ff"))
