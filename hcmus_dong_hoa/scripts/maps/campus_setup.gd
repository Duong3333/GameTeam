extends "res://scripts/maps/campus_update.gd"
# DỰNG KHUÔN VIÊN GỐC: va chạm bản đồ, cây, NPC, đèn, camera và HUD.

const CLOUD_COUNT := 3   # số đám mây trôi trên khuôn viên (trước đây 8; tăng lên nếu muốn nhiều mây hơn)

var _static_bg
var _bg_rect := Rect2()
var study_tables: Array[Vector2] = []

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
	setup_stone_bench_area()
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
	# Cột cổng 2 bên và cổng xếp phía trái
	solids.append(Rect2(GATE_X - 14.0, GATE_Y - 50.0, 16.0, 64.0))
	solids.append(Rect2(GATE_X + GATE_W - 2.0, GATE_Y - 50.0, 16.0, 64.0))
	solids.append(Rect2(GATE_PANEL.position.x, GATE_PANEL.position.y, GATE_PANEL.size.x, GATE_PANEL.size.y))
	solids.append(Rect2(GUARD_BOOTH.position.x, GUARD_BOOTH.position.y, GUARD_BOOTH.size.x, GUARD_BOOTH.size.y))
	for s in STALLS:
		solids.append(s["rect"])
	solids.append(PARKING1_RECT)
	solids.append(PARKING2_RECT)

func get_vegetation_blocked_areas() -> Array[Rect2]:
	var list: Array[Rect2] = []
	for b in BUILDINGS:
		list.append(Rect2(b[1], b[2], b[3], b[4]).grow(20.0))
	# Nhà Điều Hành: mở rộng vùng block bao phủ toàn bộ tòa nhà, sảnh trước, bậc thềm, cột cờ và lối tiếp cận
	list.append(Rect2(1780, 1080, 480, 365))
	list.append(PARKING1_RECT.grow(20.0))
	list.append(PARKING2_RECT.grow(20.0))
	list.append(GUARD_BOOTH.grow(20.0))
	list.append(Rect2(370, 0, 370, 195)) # Căn tin & sân căn tin
	list.append(Rect2(1030, 0, 170, 120)) # Tòa B4.2
	list.append(Rect2(1420, 590, 360, 260)) # Sân bê tông hồ nước có ghế đá
	list.append(Rect2(1440, 290, 320, 310)) # Khu vực hồ nước & đài phun nước
	list.append(Rect2(250, 530, 230, 130)) # Sân We Love HCMUS & tượng đài
	list.append(LAWN_B_RECT.grow(12.0))

	# Trục đường ngang & dọc chính và vỉa hè
	list.append(Rect2(0, 825, WORLD.x, 275))
	list.append(Rect2(655, 168, WORLD.x - 655, 96))
	list.append(Rect2(655, 248, 613, 28))
	list.append(Rect2(1373, 0, 26, 895))
	list.append(Rect2(1235, 0, 155, 895))
	list.append(Rect2(1790, 245, 160, 645))
	list.append(Rect2(2130, 245, 140, 645))
	list.append(Rect2(1085, 1075, 435, WORLD.y - 1075))

	# Toàn bộ khu Bãi Giữ Xe Số 1 (vỉa hè, hàng ghế, bãi đỗ xe và dải đất bao quanh)
	list.append(Rect2(0, 1070, 1100, WORLD.y - 1070))

	# Vỉa hè đường chính phía đông (phía trên Nhà Điều Hành và hoa viên)
	list.append(Rect2(1507, 1080, WORLD.x - 1507, 55))

	# Vỉa hè + crosswalk khu cổng chính (GATE_APPROACH_ROAD & ROAD_T1)
	list.append(Rect2(1085, 1075, 430, WORLD.y - 1075))

	# Lối đi bao quanh hồ
	list.append(Rect2(1365, 245, 470, 48))
	list.append(Rect2(1365, 845, 470, 40))
	list.append(Rect2(1365, 245, 45, 640))
	list.append(Rect2(1785, 245, 45, 640))

	# Lối đi bộ nối giữa các tòa
	list.append(Rect2(185, 355, 70, 55))
	list.append(Rect2(335, 445, 55, 85))
	list.append(Rect2(205, 505, 170, 55))
	list.append(Rect2(205, 505, 55, 345))
	list.append(Rect2(465, 355, 70, 55))
	list.append(Rect2(655, 505, 180, 55))
	list.append(Rect2(718, 505, 55, 345))
	list.append(Rect2(948, 505, 170, 55))
	list.append(Rect2(1005, 505, 55, 345))
	list.append(Rect2(2010, 785, 60, 60))
	list.append(Rect2(2330, 795, 60, 50))
	list.append(Rect2(1070, 95, 90, 90))
	list.append(Rect2(1995, 1115, 60, 100))
	list.append(Rect2(105, 775, 1160, 50))

	# Quán xá và nhà dân
	list.append(Rect2(1560, 1230, 100, 260))
	list.append(Rect2(50, 1430, 880, 70))
	return list

func is_point_on_concrete_or_blocked(pt: Vector2) -> bool:
	if pt.x < 38.0 or pt.x > WORLD.x - 38.0 or pt.y < 38.0 or pt.y > WORLD.y - 38.0:
		return true
	for r in get_vegetation_blocked_areas():
		if r.has_point(pt):
			return true
	for s in solids:
		if s.grow(16.0).has_point(pt):
			return true
	return false

func setup_trees() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 88
	trees.clear()
	if not SHOW_VEGETATION:
		return

	var add_tree_safe = func(pos: Vector2, type: int) -> bool:
		if is_point_on_concrete_or_blocked(pos):
			return false
		for existing in trees:
			if Vector2(existing[0], existing[1]).distance_to(pos) < 38.0:
				return false
		trees.append([pos.x, pos.y, type])
		return true

	# Phân bổ cây theo các khu vực thảm cỏ tự nhiên (dùng tọa độ ngẫu nhiên thực sự, hoàn toàn không theo ma trận)
	var natural_parks := [
		# 1. Công viên cây xanh quanh Sân We ❤ HCMUS (giữa A, B, C)
		{"rect": Rect2(220, 470, 270, 290), "count": 8, "types": [0, 2, 0, 1, 2]},
		# 2. Sân vườn giữa Tòa C và Tòa D (nửa trên)
		{"rect": Rect2(680, 330, 130, 160), "count": 3, "types": [0, 1]},
		# 3. Sân vườn giữa Tòa C và Tòa D (nửa dưới)
		{"rect": Rect2(680, 575, 130, 190), "count": 3, "types": [0, 1, 2]},
		# 4. Sân vườn giữa Tòa D và Tòa E (nửa trên)
		{"rect": Rect2(975, 330, 115, 160), "count": 3, "types": [1, 0]},
		# 5. Sân vườn giữa Tòa D và Tòa E (nửa dưới)
		{"rect": Rect2(975, 575, 115, 190), "count": 3, "types": [0, 1]},
		# 6. Dải cỏ xanh phía bắc (trên Tòa C, D, E)
		{"rect": Rect2(740, 260, 340, 45), "count": 4, "types": [0, 1, 0]},
		# 7. Vườn cảnh quan phía tây hồ nước
		{"rect": Rect2(1385, 290, 40, 540), "count": 4, "types": [2, 1, 0]},
		# 8. Vườn cảnh quan phía đông hồ nước
		{"rect": Rect2(1765, 290, 30, 540), "count": 4, "types": [2, 0, 1]},
		# 9. Vườn công viên viền phía đông Tòa G
		{"rect": Rect2(2450, 335, 25, 475), "count": 6, "types": [1, 0]},
		# 10. Khu hoa viên phía tây Nhà Điều Hành
		{"rect": Rect2(1600, 1150, 175, 260), "count": 6, "types": [0, 2, 1]},
		# 11. Khu hoa viên phía đông Nhà Điều Hành
		{"rect": Rect2(2250, 1150, 210, 260), "count": 6, "types": [2, 0, 1]},
	]

	for park in natural_parks:
		var r: Rect2 = park["rect"]
		var target: int = park["count"]
		var types: Array = park["types"]
		var tries := 0
		var placed := 0
		while tries < 80 and placed < target:
			tries += 1
			var pt := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
			var t_type: int = types[placed % types.size()]
			if add_tree_safe.call(pt, t_type):
				placed += 1

	# Rải thêm một số cây rải rác ngẫu nhiên trên các khoảng trống cỏ còn lại
	var global_tries := 0
	var global_placed := 0
	while global_tries < 250 and global_placed < 20:
		global_tries += 1
		var candidate := Vector2(rng.randf_range(50, WORLD.x - 50), rng.randf_range(50, WORLD.y - 50))
		if add_tree_safe.call(candidate, rng.randi_range(0, 2)):
			global_placed += 1

	# Bụi cỏ tự nhiên (tufts) chỉ nằm trên nền cỏ
	tufts.clear()
	var tuft_tries := 0
	while tuft_tries < 1500 and tufts.size() < 500:
		tuft_tries += 1
		var tp := Vector2(rng.randf_range(20, WORLD.x - 20), rng.randf_range(20, WORLD.y - 20))
		if not is_point_on_concrete_or_blocked(tp):
			tufts.append(tp)

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
	flowers.clear()
	var flower_tries := 0
	var flower_colors := [Color("ffffff"), Color("ffe066"), Color("ff9ecb"), Color("c9a0ff")]
	while flower_tries < 1500 and flowers.size() < 500:
		flower_tries += 1
		var fp := Vector2(rng.randf_range(20, WORLD.x - 20), rng.randf_range(20, WORLD.y - 60))
		if not is_point_on_concrete_or_blocked(fp):
			flowers.append([fp, flower_colors[rng.randi_range(0, 3)]])
	# Ghế đá theo cặp; mỗi cặp gồm hai đoạn nhỏ ghép đầu-cuối.
	# (Đã bỏ bớt các ghế tại y=1118 trên vỉa hè Bãi xe số 1 để tránh trùng với mái vòm dời xuống)
	var bench_pairs := [
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
	_static_bg.draw_lane_block()
	_static_bg.draw_street_furniture()
	_static_bg.draw_t1_shops()
	for b in BUILDINGS:
		if str(b[0]) == "B":
			continue
		_static_bg.draw_building(b)
	for k in KIOSKS:
		_static_bg.draw_kiosk(k)

func setup_stone_bench_area() -> void:
	# Keep furniture in the world's own draw pass so it is never hidden by the
	# baked background or painted over characters as a separate child layer.
	study_tables.clear()
	for i in 4:
		var center := Vector2(1509.0 + float(i % 2) * 179.0, 660.0 + float(int(i / 2)) * 110.0)
		study_tables.append(center)
		var seat_offset := 24.0 + 13.0 + 8.5
		var study_side := -1.0 if i % 2 == 0 else 1.0
		for side in [-1.0, 1.0]:
			var seat_pos := Vector2(center.x, center.y + side * seat_offset)
			benches.append({
				"position": seat_pos, "face": 0 if side < 0.0 else 1,
				"length": 112.0, "study_seat": true, "occupied": side == study_side,
			})
		# Place the seated character's foot anchor on the bench center, slightly
		# toward the table so the seat plank overlaps the lower legs naturally.
		var study_pos := Vector2(center.x, center.y + study_side * (24.0 + 13.0 + 8.5 - 5.0))
		npcs.append({
			"pos": study_pos, "dir": Vector2.ZERO, "timer": 0.0,
			"face": 0 if study_side < 0.0 else 1, "anim": 0.0,
			"shirt": [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80")][i],
			"hair": [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b")][i],
			"uni": i % 2 == 0, "long": i == 2, "pack": false,
			"say": "", "say_t": 0.0, "study": true
		})

		# Chặn mặt bàn, nhưng để trống mặt ghế cho thao tác ngồi/đứng.
		solids.append(Rect2(center - Vector2(56.0, 24.0), Vector2(112.0, 48.0)))

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
