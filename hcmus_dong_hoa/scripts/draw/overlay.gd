extends "res://scripts/draw/newcharacters.gd"
# GHÉP LỚP VẼ: sắp xếp cây/người/đèn/ghế theo chiều sâu, bóng mây, cánh phượng, bản đồ nhỏ.

func draw_sorted_items() -> void:
	var items: Array = []
	for t in trees:
		items.append([float(t[1]), 0, t])
	for n in npcs:
		items.append([n.pos.y, 1, n])
	for l in lamps:
		items.append([l.y, 3, l])
	for bn in benches:
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
			if n.has("role"):
				draw_role_npc(n)
				if n.say_t > 0.0:
					draw_role_speech(n)
			else:
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
		draw_set_transform(Vector2(c.x, c.y), 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, c.r, Color(0, 0, 0, 0.06))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in petals:
		rc(p.pos.x, p.pos.y, 2, 2, Color("ff5a4d"))

func draw_minimap() -> void:
	var o := cam.get_screen_center_position() - Vector2(240, 135) + Vector2(376, 40)
	var sc := 96.0 / WORLD.x
	rc(o.x - 2, o.y - 2, 100, 64, Color(0, 0, 0, 0.6))
	rc(o.x, o.y, 96, 60, Color("4f8a45"))
	rc(o.x, o.y + 585.0 * sc, 96, 50.0 * sc, Color("6a7078"))
	rc(o.x + GATE_X * sc, o.y + 635.0 * sc, GATE_W * sc, 325.0 * sc, Color("6a7078"))
	rc(o.x + 150.0 * sc, o.y + 690.0 * sc, 520.0 * sc, 200.0 * sc, Color("8d939c"))
	for b in BUILDINGS:
		rc(o.x + b[1] * sc, o.y + b[2] * sc, b[3] * sc, b[4] * sc, Color("e0b84a"))
	rc(o.x + DIEUHANH.position.x * sc, o.y + DIEUHANH.position.y * sc, DIEUHANH.size.x * sc, DIEUHANH.size.y * sc, Color("e8e2d0"))
	draw_circle(o + FOUNT * sc, 2.5, Color("6fb7e0"))
	if int(clock * 3.0) % 2 == 0:
		rc(o.x + player.x * sc - 1.5, o.y + player.y * sc - 1.5, 3, 3, Color.WHITE)
	rc(o.x + player.x * sc - 0.5, o.y + player.y * sc - 0.5, 1, 1, Color("e5322d"))
