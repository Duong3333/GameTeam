extends "res://scripts/core/world_update.gd"
# DỰNG THẾ GIỚI LÚC BẮT ĐẦU: va chạm, cây, NPC, xe máy, đèn, ghế, camera, lớp phủ ánh sáng, HUD.

func setup_world() -> void:
	load_resources()
	setup_collision()
	setup_trees()
	spawn_npcs()
	spawn_bikes()
	setup_decor()
	setup_camera()
	setup_overlay()
	setup_hud()

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
	solids.append(Rect2(FOUNT.x - 45, FOUNT.y - 45, 90, 90))
	solids.append(Rect2(0, GATE_Y, GATE_X, 14))
	solids.append(Rect2(GATE_X + GATE_W, GATE_Y, WORLD.x - GATE_X - GATE_W, 14))
	solids.append(Rect2(800, 920, 28, 34)) # chòi bảo vệ

func setup_trees() -> void:
	for x in range(120, 1500, 80):
		if (x > 680 and x < 770) or (x > 140 and x < 240):
			continue
		trees.append([x, 668, 1])
	for p in PALMS:
		trees.append([p[0], p[1], 2])
	rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in 260:
		tufts.append(Vector2(rng.randi_range(0, 1598), rng.randi_range(0, 998)))
	var n := 0
	while n < 70:
		var p := Vector2(rng.randi_range(20, 1580), rng.randi_range(40, 940))
		if p.y > 560 and p.y < 700:
			continue
		var ok := true
		for s in solids:
			if s.grow(16).has_point(p):
				ok = false
		for z in ZONES:
			if z[1].has_point(p):
				ok = false
		if p.x > 680 and p.x < 800 and p.y > 560:
			ok = false
		if ok:
			trees.append([p.x, p.y, 0])
			n += 1
	for t in trees:
		solids.append(Rect2(t[0] - 3, t[1] - 4, 6, 4))

func spawn_npcs() -> void:
	var shirts := [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80"), Color("e8e8e8")]
	var hairs := [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b")]
	var spawn := [Rect2(150, 470, 1300, 100), Rect2(840, 320, 176, 200)]
	for i in 18:
		var p := Vector2(480, 520)
		for tries in 80:
			var r: Rect2 = spawn[randi() % 2]
			var c := Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not blocked(c):
				p = c
				break
		npcs.append({"pos": p, "dir": Vector2.ZERO, "timer": randf_range(0.2, 2.0), "face": 0, "anim": 0.0, "shirt": shirts[randi() % shirts.size()], "hair": hairs[randi() % hairs.size()], "uni": randf() < 0.55, "long": randf() < 0.4, "pack": randf() < 0.6, "say": "", "say_t": 0.0})

func spawn_bikes() -> void:
	bikes.append({"x": 100.0, "y": 596.0, "dir": 1.0, "sp": 70.0, "col": Color("c0392b")})
	bikes.append({"x": 700.0, "y": 596.0, "dir": 1.0, "sp": 55.0, "col": Color("2980b9")})
	bikes.append({"x": 1200.0, "y": 620.0, "dir": -1.0, "sp": 65.0, "col": Color("27ae60")})

func setup_decor() -> void:
	for i in 420:
		flowers.append([Vector2(rng.randi_range(0, 1596), rng.randi_range(0, 940)), [Color("ffffff"), Color("ffe066"), Color("ff9ecb"), Color("c9a0ff")][rng.randi_range(0, 3)]])
	for x in range(160, 1500, 140):
		lamps.append(Vector2(x, 576))
	for x in range(200, 800, 150):
		lamps.append(Vector2(x, 480))
	for q in [Vector2(838, 322), Vector2(1018, 322), Vector2(838, 524), Vector2(1018, 524)]:
		lamps.append(q)
	benches = [Vector2(868, 534), Vector2(960, 534), Vector2(300, 470), Vector2(620, 470), Vector2(1200, 570), Vector2(400, 570)]
	for l in lamps:
		solids.append(Rect2(l.x - 2, l.y - 3, 4, 3))
	for b in benches:
		solids.append(Rect2(b.x - 9, b.y - 5, 18, 5))
	for i in 6:
		clouds.append({"x": rng.randf_range(0, 1600), "y": rng.randf_range(100, 900), "r": rng.randf_range(60, 110), "sp": rng.randf_range(6, 14)})

func setup_camera() -> void:
	cam = Camera2D.new()
	cam.position = player
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(WORLD.x)
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
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.1, 0.2, 0.62)
	panel.size = Vector2(480, 32)
	hl.add_child(panel)
	var line := ColorRect.new()
	line.color = Color("ffd23f")
	line.position = Vector2(0, 32)
	line.size = Vector2(480, 1)
	hl.add_child(line)
	hud = make_label(hl, Vector2(6, 3), 10)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.custom_minimum_size = Vector2(468, 0)
	hud.size = Vector2(468, 20)
	var hint := make_label(hl, Vector2(6, 254), 9)
	hint.text = "W A S D: di chuyển"

func make_label(parent: Node, pos: Vector2, sz: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l
