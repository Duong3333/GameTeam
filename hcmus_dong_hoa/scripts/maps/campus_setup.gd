extends "res://scripts/maps/campus_update.gd"
# DỰNG KHUÔN VIÊN GỐC: va chạm bản đồ, cây, NPC, đèn, camera và HUD.

const CLOUD_COUNT := 3   # số đám mây trôi trên khuôn viên (trước đây 8; tăng lên nếu muốn nhiều mây hơn)

var _static_bg
var _bg_rect := Rect2()

func hs(a: int, b: int) -> int:
	return absi((a * 73856093) ^ (b * 19349663)) % 100

func setup_world() -> void:
	load_resources()
	setup_map_modules()
	setup_collision()
	setup_trees()
	spawn_npcs()
	setup_decor()
	_bake_static_grass()
	setup_camera()
	setup_overlay()
	setup_hud()

# Bake the deterministic grass, tufts, and flowers once so the outdoor renderer
# does not repeat hundreds of draw calls every frame.
func _bake_static_grass() -> void:
	var image := Image.create(int(WORLD.x), int(WORLD.y), false, Image.FORMAT_RGBA8)
	var base := Color("5a9e3e")
	image.fill(base)

	if SHOW_VEGETATION:
		for tx in range(0, ceili(WORLD.x / 16.0)):
			for ty in range(0, ceili(WORLD.y / 16.0)):
				var tile := Rect2i(tx * 16, ty * 16, 16, 16)
				tile = Rect2i(
					tile.position,
					Vector2i(
						mini(tile.size.x, int(WORLD.x) - tile.position.x),
						mini(tile.size.y, int(WORLD.y) - tile.position.y)
					)
				)
				if (tx + ty) % 2 == 0:
					image.fill_rect(tile, base.lerp(Color.WHITE, 0.03))
				if hs(tx, ty) < 14:
					image.fill_rect(Rect2i(tx * 16 + 3, ty * 16 + 6, 10, 5), base.lerp(Color.BLACK, 0.05))

		for t in tufts:
			var p: Vector2 = t
			var tufty := Color("84c764") if int(p.x + p.y) % 2 == 0 else Color("559040")
			image.fill_rect(Rect2i(int(p.x), int(p.y), 2, 3), tufty)
			image.fill_rect(Rect2i(int(p.x) + 2, int(p.y) + 1, 1, 2), Color("84c764"))

		for f in flowers:
			var p: Vector2 = f[0]
			var flower: Color = f[1]
			image.fill_rect(Rect2i(int(p.x), int(p.y), 2, 2), flower)
			image.fill_rect(Rect2i(int(p.x), int(p.y) + 2, 1, 2), Color("3f7a35"))

	grass_texture = ImageTexture.create_from_image(image)

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
	rng = RandomNumberGenerator.new()
	rng.seed = 11
	if not SHOW_VEGETATION:
		return

	# Hàng dừa phía trên các tòa nhà
	for p in PALMS:
		trees.append([p[0], p[1], 2])

	# Danh sách các khu vực không được đặt cây (đường sá, vỉa hè, công trình, bãi xe)
	var blocked_areas: Array[Rect2] = []
	for b in BUILDINGS:
		blocked_areas.append(Rect2(b[1], b[2], b[3], b[4]).grow(16.0))
	blocked_areas.append(DIEUHANH.grow(16.0))
	blocked_areas.append(PARKING1_RECT.grow(16.0))
	blocked_areas.append(PARKING2_RECT.grow(16.0))
	blocked_areas.append(LAKE.grow(20.0))
	blocked_areas.append(Rect2(0, 835, WORLD.x, 260)) # Trục đường ngang chính và vỉa hè
	blocked_areas.append(Rect2(669, 176, WORLD.x - 669, 82)) # Trục đường ngang bắc
	blocked_areas.append(Rect2(1249, 0, 135, 885)) # Trục đường dọc chính
	blocked_areas.append(Rect2(1804, 250, 140, 635)) # Trục đường cạnh hồ
	blocked_areas.append(Rect2(2140, 250, 120, 635)) # Trục đường giữa F và G
	blocked_areas.append(Rect2(GATE_X - 100, GATE_Y - 40, GATE_W + 200, 80)) # Khu cổng trường
	blocked_areas.append(LAWN_B_RECT.grow(8.0))

	# Các lối đi bộ nối giữa các tòa
	blocked_areas.append(Rect2(196, 360, 50, 45))
	blocked_areas.append(Rect2(477, 360, 50, 45))
	blocked_areas.append(Rect2(669, 510, 160, 45))
	blocked_areas.append(Rect2(725, 510, 40, 330))
	blocked_areas.append(Rect2(962, 510, 150, 45))
	blocked_areas.append(Rect2(1010, 510, 40, 330))
	blocked_areas.append(Rect2(2020, 790, 40, 50))
	blocked_areas.append(Rect2(2340, 800, 40, 40))

	var is_point_blocked = func(pt: Vector2) -> bool:
		if pt.x < 30.0 or pt.x > WORLD.x - 30.0 or pt.y < 30.0 or pt.y > WORLD.y - 30.0:
			return true
		for r in blocked_areas:
			if r.has_point(pt):
				return true
		for s in solids:
			if s.grow(14.0).has_point(pt):
				return true
		return false

	var add_tree_safe = func(pos: Vector2, type: int) -> bool:
		if is_point_blocked.call(pos):
			return false
		for existing in trees:
			if Vector2(existing[0], existing[1]).distance_to(pos) < 32.0:
				return false
		trees.append([pos.x, pos.y, type])
		return true

	# 1. Cụm cây công viên xanh quanh Sân We ❤ HCMUS
	for x in range(230, 480, 55):
		for y in [490, 720, 760]:
			add_tree_safe.call(Vector2(x + rng.randf_range(-10, 10), y + rng.randf_range(-10, 10)), rng.randi_range(0, 2))

	# 2. Cụm cây xanh bóng mát giữa Tòa C và Tòa D
	for y in [360, 430, 600, 680, 740]:
		add_tree_safe.call(Vector2(700 + rng.randf_range(-8, 8), y), 1)
		add_tree_safe.call(Vector2(790 + rng.randf_range(-8, 8), y), 0)

	# 3. Cụm cây xanh bóng mát giữa Tòa D và Tòa E
	for y in [360, 430, 600, 680, 740]:
		add_tree_safe.call(Vector2(990 + rng.randf_range(-8, 8), y), 0)
		add_tree_safe.call(Vector2(1075 + rng.randf_range(-8, 8), y), 1)

	# 4. Hàng cây bóng mát & dừa quanh Hồ Nước (phía nam hồ)
	for x in range(1410, 1790, 60):
		add_tree_safe.call(Vector2(x, 580), 2)
		add_tree_safe.call(Vector2(x, 700), 0)
		add_tree_safe.call(Vector2(x, 780), 1)

	# 5. Dải cây xanh viền phía đông Tòa G (công viên viền đông khuôn viên)
	for y in range(320, 820, 65):
		add_tree_safe.call(Vector2(2465 + rng.randf_range(-6, 6), y), rng.randi_range(0, 1))

	# 6. Dải cây xanh cảnh quan khuôn viên Nhà Điều Hành
	for x in range(1620, 1780, 50):
		for y in range(1160, 1420, 65):
			add_tree_safe.call(Vector2(x, y), rng.randi_range(0, 2))
	for x in range(2250, 2460, 55):
		for y in range(1160, 1420, 65):
			add_tree_safe.call(Vector2(x, y), rng.randi_range(0, 2))

	# 7. Rải thêm các bụi cỏ (tufts) tự nhiên khắp khuôn viên
	for i in 600:
		var tp := Vector2(rng.randi_range(10, int(WORLD.x) - 10), rng.randi_range(10, int(WORLD.y) - 10))
		tufts.append(tp)

	# 8. Phủ thêm cây ngẫu nhiên vào các khoảng trống cỏ còn lại
	var attempts := 0
	var added := 0
	while attempts < 300 and added < 60:
		attempts += 1
		var candidate := Vector2(rng.randf_range(40, WORLD.x - 40), rng.randf_range(40, WORLD.y - 40))
		if add_tree_safe.call(candidate, rng.randi_range(0, 2)):
			added += 1

	if SHOW_VEGETATION:
		for t in trees:
			solids.append(Rect2(t[0] - 3, t[1] - 4, 6, 4))

func spawn_npcs() -> void:
	var shirts := [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80"), Color("e8e8e8")]
	var hairs  := [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b")]
	# Khu spawn: hành lang giữa các tòa và vườn công viên
	var spawn := [
		Rect2(100, 790, 1150, 75),
		Rect2(1395, 600, 400, 250),
		Rect2(203, 474, 321, 196),
	]
	for i in 24:
		var p := Vector2(600, 700)
		for tries in 100:
			var r: Rect2 = spawn[randi() % spawn.size()]
			var c := Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not blocked(c):
				p = c
				break
		npcs.append({"pos": p, "dir": Vector2.ZERO, "timer": randf_range(0.2, 2.0), "face": 0, "anim": 0.0, "shirt": shirts[randi() % shirts.size()], "hair": hairs[randi() % hairs.size()], "uni": randf() < 0.55, "long": randf() < 0.4, "pack": randf() < 0.6, "say": "", "say_t": 0.0})

	# NPC quiz toán: nhấn E khi đứng gần để mở bài tập.
	npcs.append({"pos": QUIZ_NPC_POS, "dir": Vector2.ZERO, "timer": 0.0, "face": 0, "anim": 0.0, "shirt": Color("8e5bd0"), "hair": Color("3b2a1a"), "uni": false, "long": true, "pack": false, "say": "", "say_t": 0.0, "quiz": true})
	solids.append(Rect2(QUIZ_NPC_POS.x - 5, QUIZ_NPC_POS.y - 4, 10, 4))

func setup_decor() -> void:
	for i in 700:
		flowers.append([Vector2(rng.randi_range(0, int(WORLD.x) - 4), rng.randi_range(0, int(WORLD.y) - 60)), [Color("ffffff"), Color("ffe066"), Color("ff9ecb"), Color("c9a0ff")][rng.randi_range(0, 3)]])
	# Ghế đá theo cặp; mỗi cặp gồm hai đoạn nhỏ ghép đầu-cuối.
	var bench_pairs := [
		{"position": Vector2(331, 1118)},
		{"position": Vector2(440, 1118)},
		{"position": Vector2(547, 1118)},
		{"position": Vector2(670, 1118)},
		{"position": Vector2(796, 1118)},
		{"position": Vector2(900, 1118)},
		{"position": Vector2(1684, 1096)},
		{"position": Vector2(1790, 1096)},
		{"position": Vector2(1874, 1096)},
		{"position": Vector2(1985, 1096)},
		{"position": Vector2(2104, 1096)},
		{"position": Vector2(2210, 1096)},
		{"position": Vector2(2313, 1096)},
		{"position": Vector2(1137, 1191), "vertical": true, "face": 3},
		{"position": Vector2(1137, 1253), "vertical": true, "face": 3},
		{"position": Vector2(1137, 1316), "vertical": true, "face": 3},
		{"position": Vector2(1137, 1377), "vertical": true, "face": 3},
		{"position": Vector2(1468, 1196), "vertical": true, "face": 2},
		{"position": Vector2(1468, 1258), "vertical": true, "face": 2},
		{"position": Vector2(1468, 1320), "vertical": true, "face": 2},
		{"position": Vector2(1468, 1381), "vertical": true, "face": 2},
		{"position": Vector2(1507, 629)},
		{"position": Vector2(1468, 687), "vertical": true, "face": 3},
		{"position": Vector2(1468, 727), "vertical": true, "face": 3},
		{"position": Vector2(1468, 768), "vertical": true, "face": 3},
	]
	benches.clear()
	for pair in bench_pairs:
		var pair_pos: Vector2 = pair.position
		var is_vertical := bool(pair.get("vertical", false))
		var segment_offset := Vector2(0, 9) if is_vertical else Vector2(9, 0)
		for offset in [-segment_offset, segment_offset]:
			var segment: Dictionary = pair.duplicate()
			segment["position"] = pair_pos + offset
			benches.append(segment)
	for b in benches:
		var bench_pos := get_bench_position(b)
		var bench_vertical := bool(b.get("vertical", false)) if b is Dictionary else false
		var bench_offset := Vector2(-2.5, -9.0) if bench_vertical else Vector2(-9.0, -5.0)
		var bench_size := Vector2(5.0, 18.0) if bench_vertical else Vector2(18.0, 5.0)
		solids.append(Rect2(bench_pos + bench_offset, bench_size))
	for i in CLOUD_COUNT:
		clouds.append({"x": rng.randf_range(0, WORLD.x), "y": rng.randf_range(100, WORLD.y - 100), "r": rng.randf_range(70, 130), "sp": rng.randf_range(6, 14)})

func get_bench_position(bench: Variant) -> Vector2:
	if bench is Dictionary:
		return bench.get("position", Vector2.ZERO)
	return bench

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
	_setup_static_bg()

# Nen tinh duoc ve tren mot Node2D rieng va chi redraw khi camera gan ra khoi vung da bake.
func _setup_static_bg() -> void:
	var script: Script = load("res://scripts/draw/characters.gd")
	_static_bg = script.new()
	add_child(_static_bg)
	_static_bg.show_behind_parent = true
	_static_bg.font = font
	_static_bg.logo = logo
	_static_bg.tufts = tufts
	_static_bg.flowers = flowers
	_static_bg.grass_texture = grass_texture
	_static_bg.BUILDINGS = BUILDINGS
	_static_bg.KIOSKS = KIOSKS
	_static_bg.skip_fountain = true
	_static_bg.draw.connect(_draw_static_bg)
	_bg_rect = Rect2()
	_static_bg.queue_redraw()

func _draw_static_bg() -> void:
	_static_bg.draw_ground()
	_static_bg.draw_dieuhanh()
	for b in BUILDINGS:
		if str(b[0]) == "B":
			continue
		_static_bg.draw_building(b)
	for k in KIOSKS:
		_static_bg.draw_kiosk(k)

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
