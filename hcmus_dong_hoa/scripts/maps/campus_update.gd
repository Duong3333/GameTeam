extends "res://scripts/core/game_state.gd"
# CẬP NHẬT THẾ GIỚI KHUÔN VIÊN MỖI KHUNG HÌNH: người chơi, NPC, xe máy, vùng và ánh sáng.

func update_player(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if v != Vector2.ZERO:
		v = v.normalized() * SPEED
		if absf(v.x) > absf(v.y):
			facing = 2 if v.x < 0.0 else 3
		else:
			facing = 1 if v.y < 0.0 else 0
		anim += delta
	player = move_entity(player, v * delta)

func update_npcs(delta: float) -> void:
	for n in npcs:
		if n.get("quiz", false):
			continue
		n.timer -= delta
		if n.timer <= 0.0:
			n.timer = randf_range(1.0, 3.0)
			n.dir = [Vector2.ZERO, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][randi() % 5]
			if randf() < 0.18:
				n.say = LINES[randi() % LINES.size()]
				n.say_t = 2.2
		var np: Vector2 = move_entity(n.pos, n.dir * 22.0 * delta)
		if np == n.pos and n.dir != Vector2.ZERO:
			n.timer = 0.0
		elif n.dir != Vector2.ZERO:
			n.anim += delta
			if absf(n.dir.x) > 0.0:
				n.face = 2 if n.dir.x < 0.0 else 3
			else:
				n.face = 1 if n.dir.y < 0.0 else 0
		n.pos = np
		n.say_t -= delta

func blocked(p: Vector2) -> bool:
	if p.x < 8.0 or p.x > WORLD.x - 8.0 or p.y < 22.0 or p.y > WORLD.y - 6.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in solids:
		if hit.intersects(s):
			return true
	return false

func move_entity(p: Vector2, v: Vector2) -> Vector2:
	var a := p + Vector2(v.x, 0.0)
	if blocked(a):
		a = p
	var b := a + Vector2(0.0, v.y)
	if blocked(b):
		b = a
	return b

func place() -> String:
	if DIEUHANH.grow(20.0).has_point(player):
		return "Nhà Điều hành - Phòng Đào tạo, Công tác Sinh viên, Văn phòng Đoàn - Hội, Khảo thí, Kế hoạch - Tài chính, Văn phòng khoa (P.8.2)."
	for b in BUILDINGS:
		if Rect2(b[1], b[2], b[3], b[4]).grow(18.0).has_point(player):
			return b[7]
	for k in KIOSKS:
		if Rect2(k[1], k[2], 26, 20).grow(14.0).has_point(player):
			return k[4]
	for z in ZONES:
		if z[1].has_point(player):
			return z[0]
	return "Khuôn viên cơ sở Đông Hòa"

func update_ambient(delta: float) -> void:
	for c in clouds:
		c.x += c.sp * delta
		if c.x > WORLD.x + 150.0:
			c.x = -150.0
	if petals.size() < 40 and randf() < 0.5:
		var t: Array = trees[randi() % trees.size()]
		if t[2] == 1 and absf(t[0] - player.x) < 300.0 and absf(t[1] - player.y) < 200.0:
			petals.append({"pos": Vector2(t[0] + randf_range(-9, 9), t[1] - randf_range(10, 24)), "life": 0.0, "ph": randf() * 6.0})
	for p in petals:
		p.life += delta
		p.pos = p.pos + Vector2(sin(p.life * 3.0 + p.ph) * 12.0 * delta + 6.0 * delta, 18.0 * delta)
	petals = petals.filter(func(p): return p.life < 2.2)

func update_bikes(delta: float) -> void:
	for b in bikes:
		b.x += b.dir * b.sp * delta
		if b.x > WORLD.x + 20.0:
			b.x = -20.0
		if b.x < -20.0:
			b.x = WORLD.x + 20.0

func update_daylight() -> void:
	var h := game_min / 60.0
	if h < 8.5:
		tint.color = Color(0.7, 0.8, 1.0, (8.5 - h) / 1.5 * 0.18)
	elif h > 15.0:
		tint.color = Color(1.0, 0.5, 0.15, clampf((h - 15.0) / 2.0, 0.0, 1.0) * 0.3)
	else:
		tint.color = Color(1, 1, 1, 0)

func update_hud() -> void:
	hud.text = place()   # giờ đã hiện ở student_hud.gd
