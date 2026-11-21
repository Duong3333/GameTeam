extends "res://scripts/maps/campus_update.gd"
# DỰNG KHUÔN VIÊN GỐC: va chạm bản đồ, cây, NPC, xe máy, đèn, camera và HUD.

func setup_world() -> void:
	load_resources()
	setup_map_modules()
	setup_collision()
	setup_trees()
	spawn_npcs()
	spawn_bikes()
	setup_decor()
	setup_camera()
	setup_overlay()
	setup_hud()

func setup_map_modules() -> void:
	pass

func load_resources() -> void:
	font = ThemeDB.fallback_font
	if ResourceLoader.exists("res://font.ttf"):
		font = load("res://font.ttf")
	if ResourceLoader.exists("res://assets/hcmus_logo.png"):
		logo = load("res://assets/hcmus_logo.png")

func setup_collision() -> void:
	for b in BUILDINGS:
		solids.append(Rect2(b[1], b[2], b[3], b[4]))
	for k in KIOSKS:
		solids.append(Rect2(k[1], k[2], 26, 20))
	solids.append(DIEUHANH)
	# Va chạm hồ nước: chỉ chặn mặt nước và bể phun, người chơi đi được trên cầu và vào đảo trung tâm!
	solids.append_array(HoNuoc.collision_rects(FOUNTAIN_CENTER))
	solids.append(Rect2(0, GATE_Y, GATE_X, 14))
	solids.append(Rect2(GATE_X + GATE_W, GATE_Y, WORLD.x - GATE_X - GATE_W, 14))
	solids.append(Rect2(GUARD_BOOTH.position.x, GUARD_BOOTH.position.y, GUARD_BOOTH.size.x, GUARD_BOOTH.size.y))
	solids.append(PARKING1_RECT)
	solids.append(PARKING2_RECT)

func setup_trees() -> void:
	# Hàng cây dừa (type 2) vòng quanh đài phun nước (do draw_fountain_plaza vẽ)
	# Hàng thông (type 1) và cây tán rộng (type 0) dọc các trục đường lớn
	for x in range(100, 1060, 100):
		trees.append([x, 668, 1])  # thông dọc đường ngang (khu A-E)
	for x in range(1200, 2350, 100):
		trees.append([x, 668, 1])  # thông dọc đường ngang (khu F-G)
	# Hàng dừa phía trên các tòa nhà
	for p in PALMS:
		trees.append([p[0], p[1], 2])
	rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in 420:
		tufts.append(Vector2(rng.randi_range(0, int(WORLD.x) - 2), rng.randi_range(0, int(WORLD.y) - 2)))
	var n := 0
	while n < 100:
		var p := Vector2(rng.randi_range(32, int(WORLD.x) - 32), rng.randi_range(40, int(WORLD.y) - 40))
		# Không đặt cây trên đường nội bộ, bãi xe, khu tòa nhà
		if p.y > 840 and p.y < 950:
			continue
		if p.x > 1050 and p.x < 1180:
			continue
		if PARKING1_RECT.grow(16).has_point(p) or PARKING2_RECT.grow(16).has_point(p):
			continue
		if LAWN_B_RECT.grow(8).has_point(p):
			continue
		var ok := true
		for s in solids:
			if s.grow(16).has_point(p):
				ok = false
				break
		for z in ZONES:
			if z[1].has_point(p):
				ok = false
				break
		if ok:
			trees.append([p.x, p.y, 0])
			n += 1
	for t in trees:
		solids.append(Rect2(t[0] - 3, t[1] - 4, 6, 4))

func spawn_npcs() -> void:
	var shirts := [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80"), Color("e8e8e8")]
	var hairs  := [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b")]
	# Khu spawn: hành lang giữa các tòa và vườn công viên
	var spawn := [
		Rect2(120, 580, 950, 180),
		Rect2(1440, 320, 320, 240),
	]
	for i in 24:
		var p := Vector2(600, 700)
		for tries in 100:
			var r: Rect2 = spawn[randi() % 2]
			var c := Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not blocked(c):
				p = c
				break
		npcs.append({"pos": p, "dir": Vector2.ZERO, "timer": randf_range(0.2, 2.0), "face": 0, "anim": 0.0, "shirt": shirts[randi() % shirts.size()], "hair": hairs[randi() % hairs.size()], "uni": randf() < 0.55, "long": randf() < 0.4, "pack": randf() < 0.6, "say": "", "say_t": 0.0})

	# NPC quiz toán: nhấn E khi đứng gần để mở bài tập.
	npcs.append({"pos": QUIZ_NPC_POS, "dir": Vector2.ZERO, "timer": 0.0, "face": 0, "anim": 0.0, "shirt": Color("8e5bd0"), "hair": Color("3b2a1a"), "uni": false, "long": true, "pack": false, "say": "", "say_t": 0.0, "quiz": true})
	solids.append(Rect2(QUIZ_NPC_POS.x - 5, QUIZ_NPC_POS.y - 4, 10, 4))

func spawn_bikes() -> void:
	# Chỉ 2 xe máy chạy dọc đường nội bộ (bớt xe không có người lái)
	bikes.append({"x": 100.0,  "y": 898.0, "dir":  1.0, "sp": 90.0, "col": Color("c0392b")})
	bikes.append({"x": 1800.0, "y": 905.0, "dir": -1.0, "sp": 85.0, "col": Color("27ae60")})

func setup_decor() -> void:
	for i in 700:
		flowers.append([Vector2(rng.randi_range(0, int(WORLD.x) - 4), rng.randi_range(0, int(WORLD.y) - 60)), [Color("ffffff"), Color("ffe066"), Color("ff9ecb"), Color("c9a0ff")][rng.randi_range(0, 3)]])
	# Đèn dọc hành lang (y≈562, cứ 140px)
	for x in range(200, 1060, 140):
		lamps.append(Vector2(x, 562))
	# Đèn khu công viên đài phun nước
	for q in [Vector2(1440, 320), Vector2(1760, 320), Vector2(1440, 560), Vector2(1760, 560)]:
		lamps.append(q)
	# Ghế đá (bỏ ghế trong sân cỏ WE ❤ HCMUS — không fit)
	benches = [
		Vector2(300, 660),
		Vector2(750, 660),
		Vector2(1500, 440),  # khu công viên
		Vector2(1700, 440),
		Vector2(1500, 350),
		Vector2(1700, 350),
		Vector2(1800, 1050),
		Vector2(2100, 1360),
	]
	for l in lamps:
		solids.append(Rect2(l.x - 2, l.y - 3, 4, 3))
	for b in benches:
		solids.append(Rect2(b.x - 9, b.y - 5, 18, 5))
	for i in 8:
		clouds.append({"x": rng.randf_range(0, WORLD.x), "y": rng.randf_range(100, WORLD.y - 100), "r": rng.randf_range(70, 130), "sp": rng.randf_range(6, 14)})

func setup_camera() -> void:
	cam = Camera2D.new()
	cam.position = player
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = int(WORLD.x)
	cam.limit_bottom = int(WORLD.y)
	cam.position_smoothing_enabled = true
	add_child(cam)

func setup_overlay() -> void:
	var tl := CanvasLayer.new()
	tl.layer = 5
	add_child(tl)
	tint = ColorRect.new()
	tint.size = Vector2(480, 270)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = Color(1, 0.55, 0.15, 0)
	tl.add_child(tint)
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.55, 1.0])
	gr.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.42)])
	gt.gradient = gr
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 480
	gt.height = 270
	var vg := TextureRect.new()
	vg.texture = gt
	vg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	vg.size = Vector2(480, 270)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(vg)

func setup_hud() -> void:
	var hl := CanvasLayer.new()
	hl.layer = 6
	add_child(hl)
	# Thanh vàng cũ ở đỉnh màn hình đã bỏ (nó che 2 thanh GPA/rèn luyện). Chỉ còn dòng tên khu vực.
	hud = make_label(hl, Vector2(6, 60), 9)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.custom_minimum_size = Vector2(300, 0)
	var hint := make_label(hl, Vector2(6, 254), 9)
	hint.text = "W A S D: di chuyển   Tab: sổ tay   E: tương tác"

func make_label(parent: Node, pos: Vector2, sz: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l
