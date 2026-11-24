extends "res://scripts/features/feature.gd"
# NPC CÓ TÊN: Thầy LTC, Thầy LĐK, Thầy LKH, Thầy NKT, Bác bảo vệ, Bác giữ xe, Cô lao công.
# Thầy LTC (Vi tích phân 1 - Tòa F), Thầy LKH (Vi tích phân 1 TH - B4.2), Thầy NKT (Toán rời rạc - Tòa D) có LỊCH SINH HOẠT
# theo thời khóa biểu của nhân vật chính (scripts/features/schedule_data.gd): xem phần "GIÁO VIÊN CÓ LỊCH SINH HOẠT" ở cuối file.
# Đăng ký bằng 1 dòng trong scripts/features/registry.gd, KHÔNG sửa file nào trong scripts/draw hay main.gd.
# Vẽ pixel art cùng phong cách draw_person (viền đậm, bóng dưới chân), 4 hướng, Idle + Walk.
# Dùng lại của game: game.move_entity()/game.blocked() để đi và va chạm, game.rc()/shadow()/ctext() để vẽ.
# Hướng (face) giống người chơi: 0 = xuống, 1 = lên, 2 = trái, 3 = phải.
# Bấm E khi đứng gần để NPC nói câu thoại (lần lượt theo thứ tự). NPC được vẽ ở lớp trước (draw_front_layer).

const ROLE_TALK_RANGE := 30.0
const ROLE_SPEED := 20.0
const ROLE_WALK_RADIUS := 36.0
const ROLE_SAY_TIME := 4.5
const Schedule := preload("res://scripts/features/schedule_data.gd")

# Thông tin từng nhân vật: tên, chỗ đứng, câu thoại (GIỮ NGUYÊN từng chữ, từng dấu)
const ROLE_NPCS := {
	"thay_ltc": {
		"name": "Thầy LTC", "home": Vector2(1870, 960),
		"lines": ["Bài này dễ mà, mấy em thi 27 điểm thì như gãi ngứa.", "Mấy phần này mấy em biết rồi, thầy cho qua nhe."],
	},
	"thay_ldk": {
		"name": "Thầy LĐK", "home": Vector2(1010, 600),
		"lines": ["Thầy thấy điểm tuần này cao lắm, hay hôm nay mình Harmony nha các em.", "Các em mở máy làm bài test trên Moodles nhé."],
	},
	"thay_lkh": {
		"name": "Thầy LKH", "home": Vector2(1115, 150),
		"lines": ["Em nhớ làm bài thực hành Vi tích phân trước khi vào lab nhé.", "Đạo hàm mà sai dấu là mất điểm oan đó em."],
	},
	"thay_nkt": {
		"name": "Thầy NKT", "home": Vector2(892, 960),
		"lines": ["Đồ thị này thầy cho các em vẽ bằng tay, đừng chép của bạn nha.", "Quan hệ mà không có tính phản xạ là thầy trừ điểm đó."],
	},
	"bao_ve": {
		"name": "Bác bảo vệ", "home": Vector2(770, 928),
		"lines": ["Hôm nay ăn mặc đẹp đấy chàng trai.", "Mà thẻ sinh viên của em đâu?"],
	},
	"giu_xe": {
		"name": "Bác giữ xe", "home": Vector2(190, 676),
		"lines": ["Cứ giữ thói quen đi sớm này nhé chàng trai.", "Chúc cậu có một ngày tốt lành."],
	},
	"lao_cong": {
		"name": "Cô lao công", "home": Vector2(930, 884),
		"lines": ["Phải lau dọn sạch sẽ để có môi trường tốt hơn cho các con học mới được.", "Lao động là vinh quang."],
	},
}


var _npcs: Array = []

# ---------- Vẽ: gọi các hàm vẽ có sẵn của game ----------
# _cv = null: vẽ lên thế giới (game). Khác null: vẽ lên canvas của phòng học (draw_teacher_indoor).
var _cv: Node2D = null

func rc(x: float, y: float, w: float, h: float, c: Color) -> void:
	var cv: Node2D = _cv if _cv != null else game
	cv.rc(x, y, w, h, c)

func shadow(p: Vector2, rx: float) -> void:
	var cv: Node2D = _cv if _cv != null else game
	cv.shadow(p, rx)

func ctext(t: String, x: float, y: float, w: float, sz: int, c: Color) -> void:
	var cv: Node2D = _cv if _cv != null else game
	cv.ctext(t, x, y, w, sz, c)

# ---------- Dựng NPC lúc bắt đầu (feature được thêm sau khi game đã dựng thế giới) ----------
func _ready() -> void:
	for id in ROLE_NPCS:
		var info: Dictionary = ROLE_NPCS[id]
		var p: Vector2 = info.home
		var found: bool = not game.blocked(p)
		var r := 4.0
		while not found and r < 80.0:
			for a in 12:
				var c: Vector2 = info.home + Vector2.from_angle(a * TAU / 12.0) * r
				if not game.blocked(c):
					p = c
					found = true
					break
			r += 4.0
		var npc: Dictionary = {"role": id, "name": info.name, "lines": info.lines, "line_i": 0, "home": p, "pos": p,
			"dir": Vector2.ZERO, "timer": randf_range(0.5, 2.0), "face": 0, "anim": 0.0, "idle_t": randf() * 6.0,
			"say": "", "say_t": 0.0, "talk": 0.0, "sched": false, "hidden": false}
		if TEACHERS.has(id):   # giáo viên: do _update_teacher điều khiển, bắt đầu ngày ở ngoài trường
			npc["tch"] = _make_teacher_state(id)
			npc["sched"] = true
			npc["hidden"] = true
			npc["pose"] = "stand"
		_npcs.append(npc)

func _process(delta: float) -> void:
	_refresh_room_cache()
	for n in _npcs:
		update_role_npc(n, delta)

func update_role_npc(n: Dictionary, delta: float) -> void:
	if n.has("tch"):   # giáo viên có lịch sinh hoạt
		_update_teacher(n, delta)
		return
	if n.hidden:   # đã rời trường qua cổng (day_night.gd)
		return
	n.say_t -= delta
	n.idle_t += delta
	if n.talk > 0.0:
		n.talk -= delta
		n.dir = Vector2.ZERO
		return
	if not n.sched:   # sched = true: day_night.gd đang điều khiển (đi ra/vào cổng, tuần tra), không đi lang thang
		n.timer -= delta
	if not n.sched and n.timer <= 0.0:
		n.timer = randf_range(1.2, 3.2)
		var dirs := [Vector2.ZERO, Vector2.ZERO, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		n.dir = dirs[randi() % dirs.size()]
		var off: Vector2 = n.pos - n.home
		if off.length() > ROLE_WALK_RADIUS:   # đi quá xa thì quay về chỗ đứng
			n.dir = Vector2(-signf(off.x), 0.0) if absf(off.x) > absf(off.y) else Vector2(0.0, -signf(off.y))
		if n.dir != Vector2.ZERO:
			n.face = role_face(n.dir)
	var np: Vector2 = game.move_entity(n.pos, n.dir * ROLE_SPEED * delta)
	if np == n.pos and n.dir != Vector2.ZERO:
		n.timer = 0.0
		n.dir = Vector2.ZERO
	elif n.dir != Vector2.ZERO:
		n.anim += delta
		n.face = role_face(n.dir)
	n.pos = np

func role_face(d: Vector2) -> int:
	if absf(d.x) > absf(d.y):
		return 2 if d.x < 0.0 else 3
	return 1 if d.y < 0.0 else 0

# NPC có tên gần người chơi nhất trong tầm nói chuyện (null nếu không có)
func role_npc_near() -> Variant:
	var best: Variant = null
	var bd := ROLE_TALK_RANGE
	for n in _npcs:
		if n.has("role") and not n.hidden:
			var d: float = n.pos.distance_to(game.player)
			if d < bd:
				bd = d
				best = n
	return best

# Bấm E gần NPC: NPC quay mặt về phía người chơi và nói câu tiếp theo
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if k.pressed and not k.echo and k.physical_keycode == KEY_G and _try_ask_teacher():
		get_viewport().set_input_as_handled()
		return
	if not k.pressed or k.echo or k.physical_keycode != KEY_E or game.is_busy():
		return
	var n: Variant = role_npc_near()
	if n == null:
		return
	var exam := Schedule.exam_for_teacher(str(n.role))
	if not exam.is_empty():
		if Schedule.week_no(game.day) == int(exam["week"]):
			for feature in game.features:
				if feature.has_method("start_teacher_exam") and feature.start_teacher_exam(str(n.role)):
					n.dir = Vector2.ZERO
					n.face = role_face(game.player - n.pos)
					get_viewport().set_input_as_handled()
					return
			push_error("No quiz feature could start the scheduled exam for %s." % str(n.role))
		var exam_message := Schedule.teacher_exam_message(str(n.role), game.day)
		if not exam_message.is_empty():
			n.say = exam_message
			n.say_t = ROLE_SAY_TIME
			n.talk = ROLE_SAY_TIME
			n.dir = Vector2.ZERO
			n.face = role_face(game.player - n.pos)
			get_viewport().set_input_as_handled()
			return
	var lines: Array = n.lines
	if n.has("tch"):
		var ctx: Array = _context_lines(n)
		if not ctx.is_empty():
			lines = ctx
	n.say = lines[n.line_i % lines.size()]
	n.line_i += 1
	n.say_t = ROLE_SAY_TIME
	n.talk = ROLE_SAY_TIME
	n.dir = Vector2.ZERO
	n.face = role_face(game.player - n.pos)
	get_viewport().set_input_as_handled()

# Vẽ lên thế giới (sau khi game đã vẽ cây, người, đèn, ghế). Để NPC không đè lên vật đứng TRƯỚC mặt nó,
# ta xếp NPC cùng các vật ở gần theo y rồi vẽ lại các vật đó đúng thứ tự (cùng hàm vẽ của game, nên giống hệt).
const OCCLUDE_RANGE := 44.0

func draw_front_layer() -> void:
	var items: Array = []
	var named: Array = []
	for n in _npcs:
		if not n.hidden and game.view.has_point(n.pos):
			named.append(n)
			items.append([n.pos.y, 0, n])
	if named.is_empty():
		return
	for t in game.trees:
		if _near_named(Vector2(t[0], t[1]), named):
			items.append([float(t[1]), 1, t])
	for l in game.lamps:
		if _near_named(l, named):
			items.append([l.y, 2, l])
	for b in game.benches:
		var bench_pos: Vector2 = game.get_bench_position(b)
		if _near_named(bench_pos, named):
			items.append([bench_pos.y, 3, b])
	for o in game.npcs:
		if not o.has("role") and _near_named(o.pos, named):
			items.append([o.pos.y, 4, o])
	if _near_named(game.player, named):
		items.append([game.player.y, 5, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				draw_role_npc(it[2])
			1:
				game.draw_tree(it[2])
			2:
				game.draw_lamp(it[2])
			3:
				game.draw_bench(it[2])
			4:
				var o: Dictionary = it[2]
				game.draw_person(o.pos, o.shirt, o.hair, o.face, o.anim, o.uni, o.long, o.pack)
				if o.say_t > 0.0:
					game.draw_speech(o)
			5:
				game.draw_person(game.player, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
				ctext("Bạn", game.player.x - 15, game.player.y - 28, 30, 8, Color("ffd23f"))
	for n in named:
		draw_role_speech(n)

func _near_named(p: Vector2, named: Array) -> bool:
	for n in named:
		if absf(p.x - n.pos.x) < OCCLUDE_RANGE and absf(p.y - n.pos.y) < OCCLUDE_RANGE:
			return true
	return false

# Bóng thoại nhiều dòng (tự xuống dòng), kèm tên nhân vật
func draw_role_speech(n: Dictionary) -> void:
	var top: float = n.pos.y - 32.0 - (3.0 if n.role == "lao_cong" else 0.0)
	if n.say_t > 0.0:
		var lines := wrap_text(n.say, 150.0)
		var w := 0.0
		for l in lines:
			w = maxf(w, game.font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
		w += 8.0
		var h := 4.0 + lines.size() * 9.0
		var y0 := top - h
		rc(n.pos.x - w / 2.0 - 1, y0 - 1, w + 2, h + 2, Color("333333"))
		rc(n.pos.x - w / 2.0, y0, w, h, Color.WHITE)
		rc(n.pos.x - 1, top + 1, 3, 3, Color.WHITE)
		var cv: Node2D = _cv if _cv != null else game
		for i in lines.size():
			cv.draw_string(game.font, Vector2(n.pos.x - w / 2.0 + 4.0, y0 + 9.0 + i * 9.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
		ctext(n.name, n.pos.x - 40, y0 - 4, 80, 8, Color("ffd23f"))

func wrap_text(t: String, max_w: float) -> Array:
	var out: Array = []
	var cur := ""
	for word in t.split(" "):
		var test: String = word if cur == "" else cur + " " + word
		if cur != "" and game.font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > max_w:
			out.append(cur)
			cur = word
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out

# Bảng màu từng vai
func role_style(role: String) -> Dictionary:
	match role:
		"thay_ltc":   # thầy trẻ: sơ mi xanh dương nhạt, quần tây đen, không kính, tóc đen, túi áo
			return {"skin": Color("f5cf94"), "hair": Color("1b1b1b"), "shirt": Color("7fb2f0"), "sleeve": Color("7fb2f0"), "pants": Color("1c1c24"), "shoe": Color("111118"), "pocket": true}
		"thay_ldk":   # thầy trẻ: sơ mi trắng, cà vạt đỏ đô, quần tây đen, kính, tóc nâu đậm
			return {"skin": Color("f5cf94"), "hair": Color("4a2f1c"), "shirt": Color("f2f2f2"), "sleeve": Color("f2f2f2"), "pants": Color("1c1c24"), "shoe": Color("111118"), "tie": Color("a3262f"), "glasses": true}
		"thay_lkh":   # thầy trung niên: sơ mi be, cà vạt xanh lục, quần tây navy, tóc nâu đậm, túi áo
			return {"skin": Color("f1c27d"), "hair": Color("2a1d14"), "shirt": Color("e8c9a0"), "sleeve": Color("e8c9a0"), "pants": Color("2b3a55"), "shoe": Color("111118"), "tie": Color("2f6b4f"), "pocket": true}
		"thay_nkt":   # thầy lớn tuổi: sơ mi xanh xám, quần tây nâu than, kính, tóc muối tiêu
			return {"skin": Color("f5cf94"), "hair": Color("6b6b74"), "shirt": Color("c9d3e6"), "sleeve": Color("c9d3e6"), "pants": Color("3a3a46"), "shoe": Color("1a1a1a"), "glasses": true, "pocket": true}
		"bao_ve":     # áo và mũ kê-pi xanh navy, quần tây đen, thắt lưng, ria
			return {"skin": Color("d9a066"), "hair": Color("8a8a8a"), "shirt": Color("1f3a7a"), "sleeve": Color("1f3a7a"), "pants": Color("1c1c24"), "shoe": Color("1a1a1a"), "cap": Color("1b2f5e"), "belt": true, "stache": true}
		"giu_xe":     # áo phản quang cam trên áo xám, mũ lưỡi trai trắng
			return {"skin": Color("c98e5a"), "hair": Color("2b2b2b"), "shirt": Color("e8761e"), "sleeve": Color("8d939c"), "pants": Color("4a4f56"), "shoe": Color("6b3f1d"), "cap": Color("f2f2f2"), "stripe": true}
		_:            # lao công: áo xanh ngọc, tạp dề, nón lá, cầm chổi
			return {"skin": Color("f1c27d"), "hair": Color("1b1b1b"), "shirt": Color("2f8f83"), "sleeve": Color("2f8f83"), "pants": Color("2b3a55"), "shoe": Color("2b2f4a"), "apron": true, "conical": true, "broom": true}

# Vẽ 1 NPC có tên: Idle (thở nhẹ) và Walk (4 nhịp, nhún người, chân luân phiên)
func draw_role_npc(n: Dictionary) -> void:
	var st := role_style(n.role)
	var pos: Vector2 = n.pos
	var face: int = n.face
	var ol := Color("1a1a2e")
	var moving: bool = n.dir != Vector2.ZERO
	var ph := int(n.anim * 8.0) % 4 if moving else 0   # 0,2 đứng thẳng; 1 và 3 bước chân
	var bob := 1.0 if (ph == 1 or ph == 3) else 0.0
	if not moving and int(n.idle_t * 1.6) % 2 == 1:
		bob = 1.0   # Idle: thở nhẹ (người hạ xuống 1 px, chân đứng yên)
	var stride := 0.0
	if ph == 1:
		stride = 1.0
	elif ph == 3:
		stride = -1.0
	var pose: String = str(n.get("pose", ""))
	var sit_off := 3.0 if (pose == "sit" or pose == "sleep") else 0.0
	var by := pos.y - bob + sit_off
	var side := face >= 2
	var dirx := -1.0 if face == 2 else 1.0
	shadow(pos + Vector2(0, 1), 8.0)
	# chổi (lao công) đặt phía sau nhân vật khi quay lên
	if st.has("broom") and face == 1:
		draw_role_broom(pos.x + 8, pos.y, by)
	# chân và giày
	if side:
		rc(pos.x - 3 + stride * 2.0, pos.y - 7, 4, 7 - maxf(0.0, -stride), ol)
		rc(pos.x - 1 - stride * 2.0, pos.y - 7, 4, 7 - maxf(0.0, stride), ol)
		rc(pos.x - 2 + stride * 2.0, pos.y - 6, 2, 4, st.pants)
		rc(pos.x - 0 - stride * 2.0, pos.y - 6, 2, 4, st.pants)
		rc(pos.x - 3 + stride * 2.0 + (1.0 if dirx > 0.0 else 0.0), pos.y - 2, 4, 2, st.shoe)
		rc(pos.x - 1 - stride * 2.0 + (1.0 if dirx > 0.0 else 0.0), pos.y - 2, 4, 2, st.shoe)
	else:
		var l := maxf(0.0, stride)
		var r := maxf(0.0, -stride)
		rc(pos.x - 5, pos.y - 7 + l, 4, 7 - l, ol)
		rc(pos.x + 1, pos.y - 7 + r, 4, 7 - r, ol)
		rc(pos.x - 4, pos.y - 6 + l, 2, 4 - l, st.pants)
		rc(pos.x + 2, pos.y - 6 + r, 2, 4 - r, st.pants)
		rc(pos.x - 4, pos.y - 2, 3, 2, st.shoe)
		rc(pos.x + 1, pos.y - 2, 3, 2, st.shoe)
	if pose == "ride":   # đang chạy xe máy: vẽ xe dưới người
		var bike_col: Color = n.get("bike", Color("c02828"))
		draw_role_bike(pos, face, bike_col)
	# thân và tay
	rc(pos.x - 6, by - 14, 12, 10, ol)
	rc(pos.x - 8, by - 13, 2, 7, ol)
	rc(pos.x + 6, by - 13, 2, 7, ol)
	rc(pos.x - 5, by - 13, 10, 8, st.shirt)
	rc(pos.x - 5, by - 13, 10, 2, st.shirt.lightened(0.2))
	rc(pos.x - 5, by - 6, 10, 1, st.shirt.darkened(0.25))
	rc(pos.x - 7, by - 12, 2, 6, st.sleeve)
	rc(pos.x + 5, by - 12, 2, 6, st.sleeve)
	if side:
		# nhìn ngang: một tay vung theo nhịp bước
		var sx: float = pos.x - 2.0 + stride * 2.0
		rc(sx - 1, by - 12, 4, 6, ol)
		rc(sx, by - 11, 2, 4, st.sleeve)
		rc(sx, by - 7, 2, 2, st.skin)
	else:
		rc(pos.x - 7, by - 7, 2, 2, st.skin)
		rc(pos.x + 5, by - 7, 2, 2, st.skin)
	# trang phục theo vai
	if st.has("vest"):
		rc(pos.x - 5, by - 13, 10, 8, Color.WHITE)
		rc(pos.x - 5, by - 13, 3, 8, st.shirt)
		rc(pos.x + 2, by - 13, 3, 8, st.shirt)
		rc(pos.x - 5, by - 6, 10, 1, st.shirt.darkened(0.25))
	if st.has("stripe"):
		rc(pos.x - 5, by - 13, 10, 8, st.shirt)
		rc(pos.x - 5, by - 10, 10, 1, Color("ffe066"))
		rc(pos.x - 5, by - 7, 10, 1, Color("ffe066"))
		rc(pos.x - 5, by - 13, 2, 8, Color("ffe066"))
		rc(pos.x + 3, by - 13, 2, 8, Color("ffe066"))
		rc(pos.x - 7, by - 12, 2, 6, st.sleeve)
		rc(pos.x + 5, by - 12, 2, 6, st.sleeve)
	if st.has("apron"):
		rc(pos.x - 4, by - 11, 8, 8, Color("f4f4f4"))
		rc(pos.x - 4, by - 11, 8, 1, Color("c9d6d3"))
		rc(pos.x - 4, by - 4, 8, 1, Color("c9d6d3"))
	if st.has("pocket") and face == 0:
		rc(pos.x + 1, by - 11, 3, 3, st.shirt.darkened(0.2))
		rc(pos.x + 1, by - 11, 3, 1, st.shirt.lightened(0.3))
	if st.has("belt"):
		rc(pos.x - 5, by - 6, 10, 2, Color("1a1a1a"))
		rc(pos.x - 1, by - 6, 2, 2, Color("d4af37"))
	if face != 1:
		if st.has("tie"):
			var tx: float = pos.x - 1.0 + (dirx * 2.0 if side else 0.0)
			rc(tx - 1, by - 14, 4, 2, Color.WHITE)
			rc(tx, by - 13, 2, 8, st.tie)
			rc(tx, by - 13, 2, 1, st.tie.lightened(0.25))
		if st.has("belt"):
			rc(pos.x + (-4 if face != 3 else 1), by - 12, 3, 2, Color("d4af37"))   # phù hiệu
	# đầu
	rc(pos.x - 5, by - 22, 10, 9, ol)
	rc(pos.x - 4, by - 21, 8, 8, st.skin)
	rc(pos.x - 4, by - 21, 8, 3, st.hair)
	rc(pos.x - 3, by - 22, 3, 1, st.hair.lightened(0.3))
	if n.role == "lao_cong":
		rc(pos.x - 5, by - 21, 1, 8, st.hair)
		rc(pos.x + 4, by - 21, 1, 8, st.hair)
	if face == 1:
		rc(pos.x - 4, by - 21, 8, 8, st.hair)
		rc(pos.x - 3, by - 21, 3, 1, st.hair.lightened(0.3))
	elif face == 0:
		rc(pos.x - 3, by - 17, 1, 2, ol)
		rc(pos.x + 2, by - 17, 1, 2, ol)
		rc(pos.x - 3, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x + 2, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x - 1, by - 14, 2, 1, Color("a0522d"))
		if st.has("stache"):
			rc(pos.x - 2, by - 15, 4, 1, st.hair.darkened(0.2))
		if st.has("glasses"):
			rc(pos.x - 4, by - 18, 3, 3, ol)
			rc(pos.x + 1, by - 18, 3, 3, ol)
			rc(pos.x - 3, by - 17, 1, 1, Color("dfe6ff"))
			rc(pos.x + 2, by - 17, 1, 1, Color("dfe6ff"))
			rc(pos.x - 1, by - 17, 2, 1, ol)
	else:
		var ex: float = pos.x - 3.0 if face == 2 else pos.x + 2.0
		rc(ex, by - 17, 1, 2, ol)
		if face == 2:
			rc(pos.x + 2, by - 21, 2, 6, st.hair)
		else:
			rc(pos.x - 4, by - 21, 2, 6, st.hair)
		if st.has("glasses"):
			rc(ex - (1.0 if face == 2 else 0.0), by - 18, 3, 3, ol)
			rc(ex + (0.0 if face == 2 else 1.0), by - 17, 1, 1, Color("dfe6ff"))
		if st.has("stache"):
			rc(pos.x - 4 if face == 2 else pos.x + 1, by - 15, 3, 1, st.hair.darkened(0.2))
	if pose == "sleep":   # ngủ: nhắm mắt, hiện Zzz
		if face == 0:
			rc(pos.x - 3, by - 17, 1, 2, st.skin)
			rc(pos.x + 2, by - 17, 1, 2, st.skin)
			rc(pos.x - 3, by - 16, 2, 1, ol)
			rc(pos.x + 1, by - 16, 2, 1, ol)
		var zt: int = int(n.idle_t * 1.5) % 3
		ctext("z", pos.x + 7, by - 24 - zt * 3, 8, 8, Color("dfe6ff"))
		ctext("Z", pos.x + 11, by - 30 - zt * 3, 8, 9, Color.WHITE)
	# mũ
	if st.has("cap"):
		rc(pos.x - 5, by - 24, 10, 4, ol)
		rc(pos.x - 4, by - 23, 8, 3, st.cap)
		rc(pos.x - 4, by - 23, 8, 1, st.cap.lightened(0.25))
		if face == 0:
			rc(pos.x - 5, by - 21, 10, 2, ol)
			rc(pos.x - 4, by - 21, 8, 1, st.cap.darkened(0.2))
			if n.role == "bao_ve":
				rc(pos.x - 1, by - 23, 2, 2, Color("d4af37"))
		elif face == 2:
			rc(pos.x - 8, by - 21, 5, 2, ol)
			rc(pos.x - 7, by - 21, 4, 1, st.cap.darkened(0.2))
		elif face == 3:
			rc(pos.x + 3, by - 21, 5, 2, ol)
			rc(pos.x + 3, by - 21, 4, 1, st.cap.darkened(0.2))
	if st.has("conical"):
		var straw := Color("e6d29a")
		rc(pos.x - 8, by - 22, 16, 2, ol)
		rc(pos.x - 7, by - 22, 14, 1, straw)
		rc(pos.x - 6, by - 25, 12, 3, ol)
		rc(pos.x - 5, by - 25, 10, 2, straw)
		rc(pos.x - 3, by - 27, 6, 2, ol)
		rc(pos.x - 2, by - 27, 4, 1, straw.lightened(0.2))
		rc(pos.x - 5, by - 24, 10, 1, straw.darkened(0.15))
	# chổi (lao công) phía trước khi quay xuống/ngang
	if st.has("broom") and face != 1:
		var bx: float = pos.x - 9.0 if face == 2 else pos.x + 9.0
		draw_role_broom(bx, pos.y, by)
	# gợi ý tên + phím E khi người chơi đứng gần (không hiện khi đang nói)
	if n.say_t <= 0.0 and _cv == null:
		var near: Variant = role_npc_near()
		if near != null and near.role == n.role:
			var ty: float = pos.y - 32.0 - (3.0 if n.role == "lao_cong" else 0.0)
			ctext(n.name, pos.x - 40, ty - 8, 80, 8, Color("ffd23f"))
			ctext("[E] Nói chuyện", pos.x - 40, ty + 1, 80, 8, Color.WHITE)

func draw_role_broom(x: float, foot_y: float, by: float) -> void:
	rc(x - 1, by - 14, 2, 14, Color("1a1a2e"))
	rc(x - 0.0, by - 14, 1, 14, Color("8a5a2b"))
	rc(x - 3, foot_y - 3, 6, 4, Color("1a1a2e"))
	rc(x - 2, foot_y - 3, 4, 3, Color("e0b84a"))

# =====================================================================================================
# GIÁO VIÊN CÓ LỊCH SINH HOẠT: Thầy LTC, Thầy LKH, Thầy NKT
# -----------------------------------------------------------------------------------------------------
# - Lịch dạy lấy từ Schedule.COURSES (thời khóa biểu của nhân vật chính) nên thầy chỉ dạy đúng thứ, đúng tiết, đúng phòng:
#     Thầy NKT: Toán rời rạc (lý thuyết)  - Tòa D, phòng D_TRR        (phong_hoc.gd)
#     Thầy LKH: Vi tích phân 1 (thực hành) - Tòa B4.2, phòng B42_VTP  (b42_lab.gd)
#     Thầy LTC: Vi tích phân 1 (lý thuyết) - Tòa F, phòng F_VTP       (phong_hoc.gd)
# - Một ngày của thầy: chạy xe vào cổng -> gửi xe -> đi dạo / nói chuyện / ăn ở căn tin / ngủ trên ghế đá -> đi dạy đúng giờ
#   -> sau tiết: giảng lại cho sinh viên (bấm G trong phòng), ở lại chạy deadline bằng laptop, hoặc ăn / ngủ / đi dạo -> lấy xe ra về.
# - Giờ học được kiểm tra bằng lesson_at(): thầy chỉ hiện trạng thái "Đang giảng bài" khi giờ game nằm trong tiết dạy.
# - Phòng học (phong_hoc.gd, b42_lab.gd) gọi teacher_in_room() và draw_teacher_indoor() để vẽ thầy đúng chỗ đứng cũ.
# - Chủ nhật thầy không đến trường. Hết ngày game (17:00) mọi thầy đã rời trường; ngày mới được lập lịch lại từ đầu.
# - Đường đi: đồ thị điểm mốc NODES/EDGES nằm trên đường nội bộ, đã kiểm tra không cắt tòa nhà và vật cản.
# =====================================================================================================
const MIN_PER_SEC := 3.0      # giống TIME_SCALE trong maps/campus_data.gd: 1 giây thật = 3 phút game
const T_WALK := 48.0          # tốc độ đi bộ ổn định, chậm hơn người chơi; lịch được tính ETA để xuất phát sớm
const T_BIKE := 300.0         # tốc độ chạy xe máy trong trường
const T_BUFFER := 12.0        # dự phòng thời gian để đến phòng trước giờ dạy
const DAY_CLOSE := 1005.0     # 16:45: giờ muộn nhất phải ra tới cổng
const ASK_RANGE := 52.0       # khoảng cách trong phòng để bấm G hỏi bài
const BENCH_SEAT := Vector2(1516.0, 630.0)   # chỗ ngồi trên ghế đá (đoạn phải của cặp ghế ở 1507,629)

const NODES := {
	"gate_out": Vector2(1322, 1488), "gate": Vector2(1322, 1420), "s1": Vector2(1322, 1284),
	"p1_door": Vector2(990, 1284), "p1_j": Vector2(1040, 1284), "p1_n": Vector2(1040, 960),
	"j": Vector2(1322, 960), "m_w": Vector2(892, 960), "d_door": Vector2(892, 792),
	"m_e": Vector2(1870, 960), "f_in": Vector2(1870, 804), "f_door": Vector2(2005, 804),
	"v641": Vector2(1322, 641), "bench_ap": Vector2(1516, 641), "v_n": Vector2(1322, 220), "v_b": Vector2(1322, 150),
	"b42_ap": Vector2(1115, 150), "b42_door": Vector2(1115, 114),
	"cant_e": Vector2(740, 150), "cant_m": Vector2(700, 146), "cant_s": Vector2(636, 140), "cant_door": Vector2(636, 122),
	"pk2_in": Vector2(1870, 220), "pk2": Vector2(1900, 184),
}
const EDGES := [
	["gate_out", "gate"], ["gate", "s1"], ["s1", "p1_j"], ["p1_j", "p1_door"], ["p1_j", "p1_n"], ["p1_n", "j"], ["p1_n", "m_w"],
	["s1", "j"], ["j", "m_w"], ["m_w", "d_door"], ["j", "m_e"], ["m_e", "f_in"], ["f_in", "f_door"],
	["j", "v641"], ["v641", "bench_ap"], ["v641", "v_n"], ["v_n", "v_b"], ["v_b", "b42_ap"], ["b42_ap", "b42_door"],
	["b42_ap", "cant_e"], ["cant_e", "cant_m"], ["cant_m", "cant_s"], ["cant_s", "cant_door"],
	["v_n", "pk2_in"], ["pk2_in", "pk2"], ["pk2_in", "f_in"],
]
const STROLL_NODES := ["v641", "v_n", "m_w", "m_e", "p1_n", "j", "b42_ap", "cant_e", "f_in", "pk2_in", "s1"]

# course/kind: khớp thời khóa biểu (Schedule.COURSES). room: khóa phòng học. door: điểm mốc ngay cửa tòa.
# park_node: cửa bãi xe thầy gửi xe (bãi 1 gần cổng cho Tòa D; bãi 2 phía bắc cho B4.2 và Tòa F).
# early: số phút thầy thích đến sớm trước giờ dạy; off_arrive: giờ đến trường vào ngày không có tiết.
const TEACHERS := {
	"thay_nkt": {"course": "Toán rời rạc", "kind": "LT", "room": "D_TRR", "door": "d_door", "park_node": "p1_door",
		"early": 100.0, "off_arrive": 510.0, "bike": Color("2255aa"), "seed": 3},
	"thay_lkh": {"course": "Vi tích phân 1", "kind": "TH", "room": "B42_VTP", "door": "b42_door", "park_node": "pk2",
		"early": 25.0, "off_arrive": 540.0, "bike": Color("c02828"), "seed": 7},
	"thay_ltc": {"course": "Vi tích phân 1", "kind": "LT", "room": "F_VTP", "door": "f_door", "park_node": "pk2",
		"early": 75.0, "off_arrive": 480.0, "bike": Color("282828"), "seed": 11},
	"thay_ldk": {"course": "Cơ sở lập trình", "kind": "TH", "room": "D_CSLT", "door": "d_door", "park_node": "p1_door",
		"early": 30.0, "off_arrive": 525.0, "bike": Color("1f4e78"), "seed": 5},
}
# chỗ thầy đứng/ngồi trong phòng (toạ độ của canvas phòng)
const ROOM_SPOTS := {"D_TRR": Vector2(72, 56), "F_VTP": Vector2(72, 56), "B42_VTP": Vector2(176, 78), "D_CSLT": Vector2(176, 78)}
const ROOM_DOOR_SPOTS := {"D_TRR": Vector2(240, 242), "F_VTP": Vector2(240, 242), "B42_VTP": Vector2(412, 240), "D_CSLT": Vector2(412, 240)}
# Lộ trình trong canvas phòng (từ cửa phòng tới bàn giáo viên), đã kiểm tra với vùng va chạm thật của từng phòng:
# D/F: cửa -> lối đi giữa -> dọc sân khấu -> cạnh bàn -> sau bàn tới ghế giảng viên (đoạn cuối đi sau bàn, bàn vẽ đè lên thầy).
# B4.2: cửa -> sát tường phải -> lối đi phía trên dãy máy -> cạnh bàn giảng viên (bên trái).
const ROOM_WAYPOINTS := {
	"D_TRR": [Vector2(240, 84), Vector2(112, 84), Vector2(112, 56), Vector2(72, 56)],
	"F_VTP": [Vector2(240, 84), Vector2(112, 84), Vector2(112, 56), Vector2(72, 56)],
	"B42_VTP": [Vector2(440, 240), Vector2(440, 100), Vector2(176, 100), Vector2(176, 78)],
	"D_CSLT": [Vector2(440, 240), Vector2(440, 100), Vector2(176, 100), Vector2(176, 78)]
}
const ROOM_WALK_SPEED := 42.0   # đi chậm trong phòng, tốc độ không đổi
const NEAR_RANGE := 46.0        # người chơi vào phạm vi này: thầy đi chậm lại
const STOP_RANGE := 30.0        # trong phạm vi này: thầy dừng, quay mặt lại chờ tương tác
const NEAR_WAIT := 10.0         # chờ tối đa 10 giây (thời gian game: cộng dồn delta, dừng khi game tạm dừng)
const NEAR_COOLDOWN := 25.0     # sau khi hết chờ, bỏ qua người chơi một lúc để không bị chặn lại liên tục
const ACT_TEXT := {"teach": "Đang giảng bài", "prep": "Đang chuẩn bị bài", "work": "Đang chạy deadline", "assist": "Đang giảng lại bài", "enter": "Đang đi vào lớp", "exit": "Đang rời lớp"}
const NAP_LINES := ["Hử... ai đó? Cho thầy ngủ thêm năm phút nữa...", "Zzz... thầy mới chợp mắt chút xíu thôi mà."]
const HURRY_LINES := ["Thầy sắp tới giờ dạy rồi, gặp em ở lớp nhé!", "Thầy đang đi lên lớp, em vào học sớm nha."]
const HOME_LINES := ["Hết việc rồi, thầy về trước nhé!", "Chiều rồi, thầy đi lấy xe về đây."]
const TEACHER_CHAT := ["Chào em, hôm nay học thế nào?", "Dạo này bài vở sao rồi em?", "Nhớ ôn bài trước giờ kiểm tra nha em.", "Thầy thấy em đi học đều lắm."]
const GREET_STUDENT := ["Chào em nhé!", "Em chào thầy hả? Học tốt nha!", "Ơ, em đi học sớm quá."]
const GREET_TEACHER := ["Chào thầy, thầy khỏe không?", "Thầy ơi, chào buổi sáng!", "Chào thầy, lát nữa gặp nhé."]
const GREET_REPLY_STUDENT := ["Dạ em chào thầy!", "Dạ, em chào thầy ạ!"]
const GREET_REPLY_STAFF := ["Chào thầy ạ!", "Dạ chào thầy!"]
const GREET_REPLY_TEACHER := ["Chào thầy, thầy đi dạy à?", "Chào thầy, hẹn lát nhé!"]
const GREET_RANGE := 40.0       # chào hỏi khi đi ngang qua (chỉ hiện lời thoại, không dừng lại, không cản đường)
const GREET_COOLDOWN := 18.0
const SEPARATE_DIST := 14.0     # cách tối thiểu khi đứng chờ/trò chuyện: gần hơn thì tự dạng ra
const REPLY_STUDENT := ["Dạ em chào thầy ạ!", "Dạ thầy, em đang ôn bài ạ.", "Dạ em cảm ơn thầy!"]
const REPLY_STAFF := ["Chào thầy, hôm nay thầy đến sớm quá.", "Dạ chào thầy, thầy gửi xe chưa ạ?", "Chào thầy, trời nắng quá thầy nhỉ."]
const REPLY_TEACHER := ["Thầy ơi, deadline tuần này xong chưa?", "Thôi đừng nhắc deadline nữa thầy ơi!", "Lát mình ra căn tin uống cà phê nhé."]
const ASK_LINES := {
	"thay_nkt": ["Đồ thị liên thông nghĩa là giữa hai đỉnh bất kỳ đều có đường đi. Em vẽ thử ra giấy xem.", "Quan hệ tương đương cần đủ ba tính chất: phản xạ, đối xứng, bắc cầu em nhé."],
	"thay_lkh": ["Đạo hàm hàm hợp: đạo hàm hàm ngoài nhân đạo hàm hàm trong. Em nhớ đừng quên nhân đạo hàm của phần trong.", "Em kiểm tra lại dấu khi lấy giới hạn tại vô cực rồi chạy lại bài lab nhé."],
	"thay_ltc": ["Tích phân từng phần: chọn u dễ đạo hàm, dv dễ tích phân. Em thử lại bài này nhé.", "Giới hạn mà ra dạng vô định thì mình khử bằng nhân lượng liên hợp hoặc L'Hôpital đó em."],
	"thay_ldk": ["Con trỏ lưu địa chỉ ô nhớ của biến; em vẽ sơ đồ vùng nhớ ra trước khi viết code nhé.", "Khi truyền mảng vào hàm C/C++, nhớ truyền kèm kích thước mảng để tránh truy cập vượt biên em nha."],
}

var _rk := ""                       # khóa phòng học mà người chơi đang ở trong (rỗng nếu ở ngoài trời)
var _rpos := Vector2.ZERO           # vị trí người chơi trong phòng

func _make_teacher_state(role: String) -> Dictionary:
	return {"cfg": TEACHERS[role], "day": -1, "last_min": -1.0, "state": "off", "goal": "", "path": [], "leg_free": false, "stuck": 0.0,
		"lessons": [], "arrive": 99999.0, "leave_by": 0.0, "left": false, "in_room": "", "act": "", "room_until": 0.0,
		"until": 0.0, "wait": 0.0, "ate": false, "napped": false, "rewarded": false, "own_hidden": true, "ext_away": false,
		"vehicle": false, "outdoor_only": false, "partner": null, "chat_t": 0.0, "ask_i": 0,
		"room_pos": Vector2.ZERO, "room_path": [], "near_t": 0.0, "near_cd": 0.0, "greet_cd": 6.0, "chk": 0.0}

# ---------- Đồ thị đường đi ----------
func _node_pos(id: String) -> Vector2:
	return NODES[id]

func _adj(id: String) -> Array:
	var out: Array = []
	for e in EDGES:
		if e[0] == id:
			out.append(e[1])
		elif e[1] == id:
			out.append(e[0])
	return out

func _nearest_node(p: Vector2) -> String:
	var best := ""
	var bd := 1.0e12
	for id in NODES:
		var d: float = _node_pos(id).distance_to(p)
		if d < bd:
			bd = d
			best = id
	return best

# đường ngắn nhất giữa hai điểm mốc (Dijkstra, đồ thị chỉ ~24 điểm)
func _shortest(a: String, b: String) -> Array:
	if a == b:
		return [a]
	var dist: Dictionary = {a: 0.0}
	var prev: Dictionary = {}
	var done: Dictionary = {}
	var open: Array = [a]
	while not open.is_empty():
		var cur := ""
		var cd := 1.0e12
		for id in open:
			if float(dist[id]) < cd:
				cd = float(dist[id])
				cur = id
		open.erase(cur)
		if done.has(cur):
			continue
		done[cur] = true
		if cur == b:
			break
		for nb in _adj(cur):
			var nd: float = cd + _node_pos(cur).distance_to(_node_pos(nb))
			if not dist.has(nb) or nd < float(dist[nb]):
				dist[nb] = nd
				prev[nb] = cur
				open.append(nb)
	if not prev.has(b):
		return [a]
	var out: Array = []
	var c: String = b
	while c != a:
		out.push_front(c)
		c = prev[c]
	out.push_front(a)
	return out

# danh sách điểm cần đi qua từ vị trí hiện tại tới điểm mốc to_id
func _route(from_pos: Vector2, to_id: String) -> Array:
	var start := _nearest_node(from_pos)
	var ids := _shortest(start, to_id)
	var pts: Array = []
	for id in ids:
		pts.append(_node_pos(id))
	if not pts.is_empty() and from_pos.distance_to(pts[0]) < 3.0:
		pts.pop_front()
	return pts

func _route_len(from_pos: Vector2, to_id: String) -> float:
	var total := 0.0
	var cur := from_pos
	for pt in _route(from_pos, to_id):
		total += cur.distance_to(pt)
		cur = pt
	return total

# thời gian đi (phút game) từ vị trí tới điểm mốc
func _eta_min(from_pos: Vector2, to_id: String, speed: float = T_WALK) -> float:
	return (_route_len(from_pos, to_id) / speed + _indoor_sec(to_id)) * MIN_PER_SEC

func _eta_ids(a: String, b: String, speed: float = T_WALK) -> float:
	return (_route_len(_node_pos(a), b) / speed + _indoor_sec(a)) * MIN_PER_SEC

# Quãng đi trong phòng (giây thật) khi vào/ra qua điểm mốc cửa tòa này; 0 nếu không phải cửa phòng của thầy nào
func _indoor_sec(door_id: String) -> float:
	for role in TEACHERS:
		var cfg: Dictionary = TEACHERS[role]
		if str(cfg["door"]) == door_id:
			var key: String = str(cfg["room"])
			var cur: Vector2 = ROOM_DOOR_SPOTS[key]
			var total := 0.0
			for pt in ROOM_WAYPOINTS[key]:
				total += cur.distance_to(pt)
				cur = pt
			return total / ROOM_WALK_SPEED
	return 0.0

# thời gian cần cho một hoạt động: đi tới nơi + làm + đi tiếp tới điểm after_id
func _need(from_pos: Vector2, place_id: String, dur: float, after_id: String) -> float:
	return _eta_min(from_pos, place_id) + dur + _eta_ids(place_id, after_id)

# ---------- Lịch dạy và kiểm tra giờ học ----------
func _lessons_today(role: String) -> Array:
	var cfg: Dictionary = TEACHERS[role]
	var out: Array = []
	for c in Schedule.courses_on(Schedule.weekday(game.day) + 2):
		if c[0] == cfg["course"] and c[1] == cfg["kind"]:
			var tr: Array = Schedule.time_range(c[1], c[3])
			out.append({"start": float(tr[0]), "end": float(tr[1]), "room": cfg["room"], "door": cfg["door"], "title": str(c[5])})
	out.sort_custom(func(a, b): return float(a["start"]) < float(b["start"]))
	return out

# tiết đang diễn ra ở thời điểm m (rỗng nếu không có) - cơ chế chống thầy hiện "đang dạy" sai giờ
func _lesson_at(t: Dictionary, m: float) -> Dictionary:
	for L in t["lessons"]:
		if m >= float(L["start"]) and m < float(L["end"]):
			return L
	return {}

# tiết chưa kết thúc gần nhất (đang diễn ra hoặc sắp tới); rỗng nếu hôm nay hết tiết
func _next_lesson(t: Dictionary, m: float) -> Dictionary:
	for L in t["lessons"]:
		if float(L["end"]) > m:
			return L
	return {}

# Trạng thái giờ học của một thầy: {"state": "none"|"before"|"teaching"|"after", "start", "end", "room"}
func lesson_state(role: String) -> Dictionary:
	for n in _npcs:
		if n.role == role and n.has("tch"):
			var t: Dictionary = n.tch
			if int(t["day"]) != int(game.day) or t["lessons"].is_empty():
				return {"state": "none"}
			var m: float = game.game_min
			var cur := _lesson_at(t, m)
			if not cur.is_empty():
				return {"state": "teaching", "start": cur["start"], "end": cur["end"], "room": cur["room"]}
			var nxt := _next_lesson(t, m)
			if not nxt.is_empty():
				return {"state": "before", "start": nxt["start"], "end": nxt["end"], "room": nxt["room"]}
			return {"state": "after"}
	return {"state": "none"}

func _is_exam_week(role: String) -> bool:
	var exam := Schedule.exam_for_teacher(role)
	return not exam.is_empty() and Schedule.week_no(game.day) == int(exam["week"])

# Lập lịch cho ngày mới: giờ đến trường, giờ muộn nhất phải ra về, danh sách tiết
func _new_day(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	t["day"] = game.day
	t["lessons"] = _lessons_today(str(n.role))
	t["state"] = "off"
	t["goal"] = ""
	t["path"] = []
	t["left"] = false
	t["in_room"] = ""
	t["act"] = ""
	t["ate"] = false
	t["napped"] = false
	t["rewarded"] = false
	t["partner"] = null
	t["vehicle"] = false
	t["ext_away"] = false
	t["outdoor_only"] = _is_exam_week(str(n.role))   # tuần thi giữa kỳ: thầy không ẩn trong căn tin/phòng để còn gặp được
	n.hidden = true
	t["own_hidden"] = true
	n.pose = "stand"
	n.dir = Vector2.ZERO
	n.talk = 0.0
	var wd: int = Schedule.weekday(game.day)
	t["arrive"] = 99999.0   # Chủ nhật: không đến trường
	t["leave_by"] = 0.0
	if wd == 6:
		return
	var jitter: float = float((int(game.day) * 37 + int(cfg["seed"]) * 13) % 21)
	var park: String = cfg["park_node"]
	var out_eta: float
	if t["lessons"].is_empty():
		t["arrive"] = float(cfg["off_arrive"]) + jitter
		out_eta = _eta_ids("j", park) + _eta_ids(park, "gate_out", T_BIKE)
		t["leave_by"] = minf(930.0 + jitter, DAY_CLOSE - out_eta)
	else:
		var first: Dictionary = t["lessons"][0]
		var last: Dictionary = t["lessons"][t["lessons"].size() - 1]
		var in_eta: float = _eta_ids("gate_out", park, T_BIKE) + _eta_ids(park, str(first["door"]))
		t["arrive"] = clampf(float(first["start"]) - in_eta - 20.0 - float(cfg["early"]) - jitter, 450.0, 900.0)
		out_eta = _eta_ids(str(last["door"]), park) + _eta_ids(park, "gate_out", T_BIKE)
		t["leave_by"] = maxf(DAY_CLOSE - out_eta, float(last["end"]))

# Admin tua giờ/ngày: đặt thầy vào đúng trạng thái theo giờ hiện tại
func _resync(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var m: float = game.game_min
	t["path"] = []
	t["vehicle"] = false
	t["partner"] = null
	n.pose = "stand"
	n.dir = Vector2.ZERO
	n.talk = 0.0
	t["in_room"] = ""
	t["act"] = ""
	if m < float(t["arrive"]) or m >= float(t["leave_by"]) + 30.0 or int(Schedule.weekday(game.day)) == 6:
		n.hidden = true
		t["own_hidden"] = true
		t["state"] = "off"
		t["left"] = m >= float(t["leave_by"])
		return
	var cur := _lesson_at(t, m)
	if not cur.is_empty():
		n.pos = _node_pos(str(cur["door"]))
		_enter_room(n, "class", true)
		return
	n.hidden = false
	t["own_hidden"] = false
	n.pos = _node_pos(STROLL_NODES[randi() % STROLL_NODES.size()])
	t["state"] = "idle"

# Bị đánh biến mất rồi quay lại (danhnhau.gd) hoặc bị gián đoạn: lập kế hoạch lại từ chỗ đang đứng
func _replan_after_away(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	t["path"] = []
	t["vehicle"] = false
	t["partner"] = null
	n.pose = "stand"
	n.dir = Vector2.ZERO
	t["own_hidden"] = false
	t["state"] = "idle"

# ---------- Máy trạng thái chính ----------
func _update_teacher(n: Dictionary, delta: float) -> void:
	var t: Dictionary = n.tch
	n.say_t -= delta
	n.idle_t += delta
	if n.hidden and not bool(t["own_hidden"]):
		t["ext_away"] = true   # danhnhau.gd đã cho thầy bỏ đi: tạm dừng lịch
		return
	if bool(t["ext_away"]):
		t["ext_away"] = false
		_replan_after_away(n)
	elif not n.hidden and bool(t["own_hidden"]):
		n.hidden = true   # NPC đang ở trong phòng/căn tin/ngoài trường thì không được hiện ra
	var m: float = game.game_min
	if int(t["day"]) != int(game.day):
		_new_day(n)
	elif absf(m - float(t["last_min"])) > 20.0:
		_resync(n)
	t["last_min"] = m
	if n.talk > 0.0 and not n.hidden:
		n.talk -= delta
		n.dir = Vector2.ZERO
		t["near_t"] = 0.0
		t["near_cd"] = maxf(float(t["near_cd"]), 6.0)   # nói chuyện xong thì thầy đi tiếp
		return
	var st: String = str(t["state"])
	if not n.hidden and not bool(t["vehicle"]) and (st == "walk" or st == "look" or st == "idle"):
		_greet_nearby(n, delta)
		if st != "walk":
			_keep_apart(n, delta)
	match str(t["state"]):
		"off":
			_state_off(n)
		"ride", "walk":
			_state_move(n, delta)
		"park":
			t["wait"] = float(t["wait"]) - delta
			if float(t["wait"]) <= 0.0:
				t["state"] = "idle"
		"mount":
			t["wait"] = float(t["wait"]) - delta
			if float(t["wait"]) <= 0.0:
				t["vehicle"] = true
				n.pose = "ride"
				n["bike"] = (t["cfg"] as Dictionary)["bike"]
				_set_route(n, "gate_out", "ride_out")
				t["state"] = "ride"
		"look":
			t["wait"] = float(t["wait"]) - delta
			n.dir = Vector2.ZERO
			if float(t["wait"]) <= 0.0:
				t["state"] = "idle"
		"chat":
			t["wait"] = float(t["wait"]) - delta
			n.dir = Vector2.ZERO
			if float(t["wait"]) <= 0.0:
				t["partner"] = null
				t["state"] = "idle"
		"eat":
			_state_eat(n)
		"nap":
			_state_nap(n)
		"room_enter", "room_exit":
			_advance_room_walk(n, delta)
		"room":
			_state_room(n)
		"idle":
			n.dir = Vector2.ZERO
			_decide(n)

func _state_off(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var m: float = game.game_min
	if bool(t["left"]) or m < float(t["arrive"]) or m >= float(t["leave_by"]):
		return
	# đến giờ: chạy xe vào cổng trường, hướng tới bãi gửi xe của mình
	var cfg: Dictionary = t["cfg"]
	n.pos = _node_pos("gate_out")
	n.hidden = false
	t["own_hidden"] = false
	t["vehicle"] = true
	n.pose = "ride"
	n["bike"] = cfg["bike"]
	n.face = 1
	_set_route(n, str(cfg["park_node"]), "ride_in")
	t["state"] = "ride"

func _set_route(n: Dictionary, to_id: String, goal: String) -> void:
	var t: Dictionary = n.tch
	var pts: Array = _route(n.pos, to_id)
	t["path"] = pts
	t["leg_free"] = not pts.is_empty() and n.pos.distance_to(pts[0]) > 6.0
	t["stuck"] = 0.0
	t["goal"] = goal

# đi tới điểm mốc rồi làm việc "goal"
func _go(n: Dictionary, to_id: String, goal: String) -> void:
	var t: Dictionary = n.tch
	t["vehicle"] = false
	n.pose = "stand"
	_set_route(n, to_id, goal)
	if t["path"].is_empty():
		_on_arrive(n)
	else:
		t["state"] = "walk"

func _state_move(n: Dictionary, delta: float) -> void:
	var t: Dictionary = n.tch
	if str(t["goal"]) == "chat":
		t["chat_t"] = float(t["chat_t"]) - delta
		if float(t["chat_t"]) <= 0.0:
			t["path"] = []
			n.dir = Vector2.ZERO
			t["state"] = "idle"
			return
	if str(t["goal"]) == "chat":
		t["chk"] = float(t["chk"]) + delta
		if float(t["chk"]) >= 1.0:   # kiểm tra mỗi giây: trò chuyện không được làm trễ giờ dạy
			t["chk"] = 0.0
			if _hurry(n):
				t["path"] = []
				n.dir = Vector2.ZERO
				t["partner"] = null
				t["state"] = "idle"
				return
	var speed: float = T_BIKE if bool(t["vehicle"]) else T_WALK
	if _player_yield(n, delta):
		n.dir = Vector2.ZERO
		return   # đang dừng chờ người chơi
	if not bool(t["vehicle"]) and not n.hidden and _player_close(n, NEAR_RANGE) and float(t["near_cd"]) <= 0.0 and not _hurry(n):
		speed *= 0.6   # đi chậm lại khi người chơi ở gần, không chạy ngang qua
	if _follow(n, speed, delta):
		_on_arrive(n)

# ---------- Nhường đường / chờ người chơi ----------
func _player_close(n: Dictionary, r: float) -> bool:
	return _rk == "" and n.pos.distance_to(game.player) < r

# Đang trên đường vào lớp / về nhà, hoặc sắp trễ tiết kế tiếp: bỏ qua việc dừng chờ người chơi
func _hurry(n: Dictionary) -> bool:
	var t: Dictionary = n.tch
	var g: String = str(t["goal"])
	if g == "class" or g == "home" or g == "ride_out" or g == "ride_in":
		return true
	var L := _next_lesson(t, game.game_min)
	if L.is_empty():
		return false
	var slack: float = float(L["start"]) - game.game_min - _eta_min(n.pos, str(L["door"])) - T_BUFFER * 0.5
	return slack <= 0.0

# true = thầy đang dừng lại, quay mặt về phía người chơi để chờ tương tác.
# Đếm NEAR_WAIT giây (cộng dồn delta = thời gian game); hết giờ thì đi tiếp và bỏ qua người chơi NEAR_COOLDOWN giây.
# Bộ đếm chỉ reset khi người chơi rời hẳn phạm vi, không reset mỗi khi người chơi nhúc nhích.
func _player_yield(n: Dictionary, delta: float) -> bool:
	var t: Dictionary = n.tch
	t["near_cd"] = maxf(0.0, float(t["near_cd"]) - delta)
	if bool(t["vehicle"]) or n.hidden or not _player_close(n, NEAR_RANGE):
		t["near_t"] = 0.0
		return false
	if float(t["near_cd"]) > 0.0 or not _player_close(n, STOP_RANGE) or _hurry(n):
		return false
	t["near_t"] = float(t["near_t"]) + delta
	if float(t["near_t"]) >= NEAR_WAIT:
		t["near_t"] = 0.0
		t["near_cd"] = NEAR_COOLDOWN
		return false
	n.face = role_face(game.player - n.pos)
	return true

# mọi NPC khác trên bản đồ: sinh viên (game.npcs) và NPC có vai (_npcs, gồm cả các thầy), trừ chính n
func _others(n: Dictionary) -> Array:
	var out: Array = []
	for o in game.npcs:
		if o != n:
			out.append(o)
	for o in _npcs:
		if o != n:
			out.append(o)
	return out

# Chào hỏi khi đi ngang: chỉ hiện lời thoại hai bên, không dừng ai, không cản đường nên không làm trễ giờ dạy.
func _greet_nearby(n: Dictionary, delta: float) -> void:
	var t: Dictionary = n.tch
	t["greet_cd"] = float(t["greet_cd"]) - delta
	if float(t["greet_cd"]) > 0.0 or float(n.say_t) > 0.0:
		return
	for o in _others(n):
		if o.get("quiz", false) or o.get("hidden", false) or float(o.get("say_t", 0.0)) > 0.0 or float(o.get("talk", 0.0)) > 0.0:
			continue
		if n.pos.distance_to(o["pos"]) > GREET_RANGE:
			continue
		var line: Array = GREET_STUDENT
		var reply: Array = GREET_REPLY_STUDENT
		if o.has("tch"):
			line = GREET_TEACHER
			reply = GREET_REPLY_TEACHER
		elif o.has("role"):
			line = GREET_TEACHER
			reply = GREET_REPLY_STAFF
		n.say = line[randi() % line.size()]
		n.say_t = 2.4
		o["say"] = reply[randi() % reply.size()]
		o["say_t"] = 2.4
		t["greet_cd"] = GREET_COOLDOWN
		return
	t["greet_cd"] = 1.0

# Đứng chờ/trò chuyện mà bị người khác (NPC, người chơi) đứng sát chồng lên thì tự dạng ra một chút
func _keep_apart(n: Dictionary, delta: float) -> void:
	var away := Vector2.ZERO
	for o in _others(n):
		if o.get("hidden", false):
			continue
		var off: Vector2 = n.pos - o["pos"]
		if off.length() < SEPARATE_DIST:
			away += off.normalized() if off.length() > 0.01 else Vector2.RIGHT
	if _rk == "" and n.pos.distance_to(game.player) < SEPARATE_DIST:
		var po: Vector2 = n.pos - game.player
		away += po.normalized() if po.length() > 0.01 else Vector2.LEFT
	if away != Vector2.ZERO:
		n.pos = game.move_entity(n.pos, away.normalized() * 20.0 * delta)

# đi theo t.path; trả về true khi đã tới cuối. Chặng đầu (leg_free) dùng va chạm của game, các chặng sau đi thẳng theo đường mốc.
func _follow(n: Dictionary, speed: float, delta: float) -> bool:
	var t: Dictionary = n.tch
	var path: Array = t["path"]
	if path.is_empty():
		n.dir = Vector2.ZERO
		return true
	var target: Vector2 = path[0]
	var to: Vector2 = target - n.pos
	var dist: float = to.length()
	var step: float = speed * delta
	if dist <= step + 0.01:
		n.pos = target
		path.pop_front()
		t["leg_free"] = false
		t["stuck"] = 0.0
		if path.is_empty():
			n.dir = Vector2.ZERO
			return true
		return false
	var d: Vector2 = to / dist
	n.dir = d
	n.face = role_face(d)
	n.anim += delta
	var use_free: bool = bool(t["leg_free"]) or (str(t["goal"]) == "chat" and path.size() == 1)
	if use_free:
		var np: Vector2 = game.move_entity(n.pos, d * step)
		if np.distance_to(n.pos) < 0.01:
			t["stuck"] = float(t["stuck"]) + delta
			if float(t["stuck"]) > 1.2:
				if str(t["goal"]) == "chat":
					path.clear()
					n.dir = Vector2.ZERO
					return true
				n.pos = target   # điểm mốc luôn là chỗ đi được
				t["stuck"] = 0.0
		else:
			n.pos = np
			t["stuck"] = 0.0
	else:
		n.pos += d * step
	return false

func _on_arrive(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var m: float = game.game_min
	n.dir = Vector2.ZERO
	match str(t["goal"]):
		"ride_in":
			t["vehicle"] = false
			n.pose = "stand"
			n.face = 3 if str((t["cfg"] as Dictionary)["park_node"]) == "p1_door" else 1
			t["wait"] = 1.0   # xuống xe, khóa cổ xe
			t["state"] = "park"
		"class", "work":
			_enter_room(n, str(t["goal"]))
		"canteen":
			n.hidden = true
			t["own_hidden"] = true
			t["until"] = m + randf_range(18.0, 26.0)
			t["state"] = "eat"
		"nap", "rest":
			n.pos = BENCH_SEAT + Vector2(0, 1)
			n.face = 0
			n.pose = "sleep" if str(t["goal"]) == "nap" else "sit"
			t["until"] = m + (randf_range(20.0, 30.0) if str(t["goal"]) == "nap" else randf_range(8.0, 12.0))
			t["state"] = "nap"
		"stroll":
			n.face = randi() % 4
			t["wait"] = randf_range(1.5, 3.5)
			t["state"] = "look"
		"chat":
			var pr: Variant = t["partner"]
			if pr is Dictionary and not bool((pr as Dictionary).get("hidden", false)) and n.pos.distance_to((pr as Dictionary)["pos"]) <= 80.0:
				_start_chat(n)
			else:
				t["state"] = "idle"
		"home":
			t["wait"] = 0.8   # lấy xe
			t["state"] = "mount"
		"ride_out":
			n.hidden = true
			t["own_hidden"] = true
			t["vehicle"] = false
			n.pose = "stand"
			t["left"] = true
			t["state"] = "off"
		_:
			t["state"] = "idle"

# ---------- Quyết định việc tiếp theo khi rảnh ----------
func _decide(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var m: float = game.game_min
	var park: String = cfg["park_node"]
	var L := _next_lesson(t, m)
	if not L.is_empty():
		var door_id: String = L["door"]
		var slack: float = float(L["start"]) - m - _eta_min(n.pos, door_id) - T_BUFFER
		if slack <= 0.0:
			_go(n, door_id, "class")   # đến giờ lên lớp (hoặc đã trễ: vào thẳng phòng)
			return
		_choose_activity(n, slack, door_id)
	else:
		if m >= float(t["leave_by"]):
			_go(n, park, "home")
			return
		_choose_activity(n, float(t["leave_by"]) - m, park)

func _choose_activity(n: Dictionary, slack: float, after_id: String) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var m: float = game.game_min
	var here: Vector2 = n.pos
	var indoor_ok: bool = not bool(t["outdoor_only"])
	var kinds: Array = []
	var weights: Array = []
	if indoor_ok and not bool(t["ate"]) and m >= 630.0 and m <= 850.0 and _need(here, "cant_door", 24.0, after_id) <= slack:
		kinds.append("eat")
		weights.append(9.0 if m >= 690.0 else 2.0)
	if not bool(t["napped"]) and m >= 640.0 and _need(here, "bench_ap", 32.0, after_id) <= slack:
		kinds.append("nap")
		weights.append(4.0 if bool(t["ate"]) else 1.5)
	if _need(here, "bench_ap", 14.0, after_id) <= slack:
		kinds.append("rest")
		weights.append(1.5)
	if slack >= 70.0:
		kinds.append("chat")
		weights.append(5.0)
	var strolls: Array = []
	for sid in STROLL_NODES:
		if _need(here, sid, 6.0, after_id) <= slack and _nearest_node(here) != sid:
			strolls.append(sid)
	if not strolls.is_empty():
		kinds.append("stroll")
		weights.append(3.5)
	if indoor_ok and _need(here, str(cfg["door"]), 35.0, after_id) <= slack:
		kinds.append("work")
		weights.append(2.5)
	if kinds.is_empty():
		t["wait"] = 1.5   # sắp tới giờ: đứng chờ một lát
		t["state"] = "look"
		return
	var total := 0.0
	for w in weights:
		total += float(w)
	var r: float = randf() * total
	var pick := 0
	for i in weights.size():
		r -= float(weights[i])
		if r <= 0.0:
			pick = i
			break
	match str(kinds[pick]):
		"eat":
			_go(n, "cant_door", "canteen")
		"nap":
			_go(n, "bench_ap", "nap")
		"rest":
			_go(n, "bench_ap", "rest")
		"work":
			_go(n, str(cfg["door"]), "work")
		"chat":
			if not _start_chat_approach(n):
				_go(n, str(strolls[randi() % strolls.size()]) if not strolls.is_empty() else _nearest_node(here), "stroll")
		_:
			_go(n, str(strolls[randi() % strolls.size()]), "stroll")

# ---------- Nói chuyện với NPC khác ----------
func _pick_partner(n: Dictionary) -> Dictionary:
	var named: Array = []
	for o in _npcs:
		if str(o.role) != str(n.role) and not o.hidden:
			named.append(o)
	var students: Array = []
	for s in game.npcs:
		if not s.get("quiz", false):
			students.append(s)
	var pool: Array = named if (randf() < 0.45 and not named.is_empty()) else students
	if pool.is_empty():
		pool = named
	if pool.is_empty():
		return {}
	var tries := 0
	while tries < 6:
		var cand: Dictionary = pool[randi() % pool.size()]
		var nd := _nearest_node(cand["pos"])
		if _node_pos(nd).distance_to(cand["pos"]) <= 220.0:
			return cand
		tries += 1
	return {}

func _start_chat_approach(n: Dictionary) -> bool:
	var t: Dictionary = n.tch
	var partner := _pick_partner(n)
	if partner.is_empty():
		return false
	t["partner"] = partner
	t["chat_t"] = 8.0
	_go_then_approach(n, _nearest_node(partner["pos"]))
	return true

# đi tới điểm mốc gần bạn trò chuyện nhất, rồi tiến lại gần (chặng cuối dùng va chạm của game)
func _go_then_approach(n: Dictionary, node_id: String) -> void:
	var t: Dictionary = n.tch
	t["vehicle"] = false
	n.pose = "stand"
	_set_route(n, node_id, "chat")
	var partner: Dictionary = t["partner"]
	var side: float = 24.0 if n.pos.x > partner["pos"].x else -24.0
	var pts: Array = t["path"]
	pts.append(partner["pos"] + Vector2(side, 0.0))
	t["state"] = "walk"

func _start_chat(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var partner: Dictionary = t["partner"]
	n.face = role_face(partner["pos"] - n.pos)
	n.say = TEACHER_CHAT[randi() % TEACHER_CHAT.size()]
	n.say_t = 3.2
	var reply: Array = REPLY_STUDENT
	if partner.has("role"):
		reply = REPLY_TEACHER if partner.has("tch") else REPLY_STAFF
		partner["face"] = role_face(n.pos - partner["pos"])
		partner["talk"] = 3.6
		partner["dir"] = Vector2.ZERO
	else:
		partner["face"] = role_face(n.pos - partner["pos"])
		partner["dir"] = Vector2.ZERO
		partner["timer"] = 3.6
	partner["say"] = reply[randi() % reply.size()]
	partner["say_t"] = 3.4
	t["wait"] = 3.8
	t["state"] = "chat"

# ---------- Ăn, ngủ ----------
func _state_eat(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	if game.game_min < float(t["until"]) and game.game_min < float(t["leave_by"]):
		return
	n.pos = _node_pos("cant_door")
	n.hidden = false
	t["own_hidden"] = false
	t["ate"] = true
	n.face = 0
	t["state"] = "idle"

func _state_nap(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	n.dir = Vector2.ZERO
	var due: float = float(t["until"])
	if game.game_min < due and game.game_min < float(t["leave_by"]) and _lesson_start_soon(t):
		return
	if str(n.pose) == "sleep":
		t["napped"] = true
		n.say = "Ngủ một giấc đã quá, phải đi làm việc thôi."
		n.say_t = 3.0
	n.pose = "stand"
	n.pos = _node_pos("bench_ap")
	n.face = 1
	t["state"] = "idle"

# true nếu CHƯA tới lúc phải đi lên lớp (còn được nghỉ tiếp)
func _lesson_start_soon(t: Dictionary) -> bool:
	var L := _next_lesson(t, game.game_min)
	if L.is_empty():
		return true
	var need: float = _eta_ids("bench_ap", str(L["door"])) + T_BUFFER
	return float(L["start"]) - game.game_min > need

# ---------- Trong phòng học ----------
func _enter_room(n: Dictionary, goal: String, instant: bool = false) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var m: float = game.game_min
	var room_key := str(cfg["room"])
	n.hidden = true # Ẩn trên bản đồ ngoài trời; vẫn được vẽ động trong canvas phòng.
	t["own_hidden"] = true
	n.dir = Vector2.ZERO
	n.pose = "stand"
	t["in_room"] = room_key
	t["room_pos"] = ROOM_DOOR_SPOTS.get(room_key, Vector2.ZERO)
	t["room_path"] = (ROOM_WAYPOINTS.get(room_key, []) as Array).duplicate()
	t["state"] = "room_enter"
	if instant:   # chỉ dùng khi admin tua giờ giữa tiết: đặt thầy sẵn ở bàn
		t["room_pos"] = ROOM_SPOTS[room_key]
		t["room_path"] = []
		t["state"] = "room"
		n.face = 0
	t["act"] = "work" if goal == "work" else "prep"
	var L := _next_lesson(t, m)
	if goal == "work" or L.is_empty():
		t["room_until"] = m + randf_range(25.0, 40.0)
	else:
		t["room_until"] = float(L["end"])

# Đi bộ trong phòng theo t.room_path (vào: cửa -> bàn giáo viên; ra: bàn -> cửa). Tốc độ không đổi, không dịch chuyển.
func _advance_room_walk(n: Dictionary, delta: float) -> void:
	var t: Dictionary = n.tch
	var path: Array = t["room_path"]
	var entering: bool = str(t["state"]) == "room_enter"
	if not path.is_empty():
		var current: Vector2 = t["room_pos"]
		var target: Vector2 = path[0]
		var offset: Vector2 = target - current
		var distance: float = offset.length()
		var step: float = ROOM_WALK_SPEED * delta
		if distance <= step or distance < 0.01:
			t["room_pos"] = target
			path.pop_front()
			n.dir = Vector2.ZERO
			if not path.is_empty():
				var nxt: Vector2 = path[0]
				n.dir = (nxt - target).normalized()
		else:
			n.dir = offset / distance
			t["room_pos"] = current + n.dir * step
		if n.dir != Vector2.ZERO:
			n.face = role_face(n.dir)
		n.anim += delta
		t["room_path"] = path
	if not path.is_empty():
		return
	n.dir = Vector2.ZERO
	if entering:
		n.face = 0   # tới bàn giáo viên: quay mặt về phía bảng, sau đó mới chuyển sang trạng thái dạy ở _state_room
		t["state"] = "room"
	else:
		_exit_building(n)

# Ra khỏi cửa phòng -> xuất hiện ngoài cửa tòa -> đi tiếp ra xa tòa nhà rồi mới quay lại lịch bình thường
func _exit_building(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var door_id: String = str(cfg["door"])
	n.pos = _node_pos(door_id)
	n.hidden = false
	t["own_hidden"] = false
	t["in_room"] = ""
	t["act"] = ""
	n.say = ""
	n.say_t = 0.0
	var nb: Array = _adj(door_id)
	if nb.is_empty():
		t["state"] = "idle"
	else:
		_go(n, str(nb[0]), "exit_clear")

func _state_room(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var m: float = game.game_min
	var cur := _lesson_at(t, m)
	if not cur.is_empty():
		t["act"] = "teach"
		t["room_until"] = maxf(float(t["room_until"]), float(cur["end"]))
	else:
		var nxt := _next_lesson(t, m)
		if str(t["act"]) == "teach":
			_on_class_end(n)
		elif not nxt.is_empty() and float(nxt["start"]) - m < 90.0:
			if str(t["act"]) != "assist":
				t["act"] = "prep"
			t["room_until"] = maxf(float(t["room_until"]), float(nxt["end"]))
	var must_go: bool = m >= float(t["leave_by"]) and _lesson_at(t, m).is_empty()
	if (m >= float(t["room_until"]) and str(t["act"]) != "teach") or must_go:
		_leave_room(n)

# hết tiết: giảng lại nếu sinh viên (người chơi) còn ở trong phòng, ngược lại có thể ở lại chạy deadline hoặc đi về
func _on_class_end(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var cfg: Dictionary = t["cfg"]
	var m: float = game.game_min
	var slack: float = float(t["leave_by"]) - m
	if _rk == str(cfg["room"]) and slack > 6.0:
		t["act"] = "assist"
		t["room_until"] = minf(m + 10.0, float(t["leave_by"]))
		n.say = "Còn em nào chưa hiểu chỗ nào thì bấm G hỏi thầy nhé."
		n.say_t = 5.0
	elif slack > 22.0 and randf() < 0.6 and not bool(t["outdoor_only"]):
		t["act"] = "work"
		t["room_until"] = m + randf_range(20.0, minf(55.0, slack - 8.0))
	else:
		t["act"] = "prep"
		t["room_until"] = m

func _leave_room(n: Dictionary) -> void:
	var t: Dictionary = n.tch
	var room_key := str(t["in_room"])
	var path: Array = (ROOM_WAYPOINTS.get(room_key, []) as Array).duplicate()
	path.reverse() # bàn giáo viên -> lối đi -> cửa
	path.pop_front()   # điểm đầu = bàn giáo viên (đang đứng sẵn ở đó)
	path.append(ROOM_DOOR_SPOTS.get(room_key, Vector2.ZERO))
	t["room_pos"] = ROOM_SPOTS[room_key]
	t["act"] = "exit"
	t["room_path"] = path
	t["state"] = "room_exit"
	n.dir = Vector2.ZERO
	n.say = ""
	n.say_t = 0.0

# ---------- Giao tiếp với phòng học ----------
func _refresh_room_cache() -> void:
	_rk = ""
	for f in game.features:
		if f != self and f.has_method("current_room_key"):
			var key: String = f.current_room_key()
			if key != "":
				_rk = key
				_rpos = f.room_player_pos()
				return

# Phòng gọi để biết thầy nào đang ở trong phòng room_key. Trả về {} nếu không có ai.
func teacher_in_room(room_key: String) -> Dictionary:
	for n in _npcs:
		if not n.has("tch"):
			continue
		var t: Dictionary = n.tch
		if str(t["in_room"]) != room_key or not n.hidden or bool(t["ext_away"]) or int(t["day"]) != int(game.day):
			continue
		var act: String = str(t["act"])
		if str(t["state"]) == "room_enter":
			act = "enter"
		elif act == "teach" and _lesson_at(t, game.game_min).is_empty():
			act = "prep"   # không nằm trong khung giờ dạy thì không được hiện "đang dạy"
		return {"role": n.role, "name": n.name, "act": ACT_TEXT.get(act, ""), "state": act,
			"pos": t["room_pos"], "face": int(n.face)}
	return {}

# Phòng gọi để vẽ thầy lên canvas của phòng (pos = chỗ chân đứng/ngồi)
func draw_teacher_indoor(canvas: Node2D, role: String, pos: Vector2, face: int, tname: String, act: String) -> void:
	var src: Dictionary = {}
	for n in _npcs:
		if str(n.role) == role:
			src = n
	if src.is_empty():
		return
	var tmp: Dictionary = {"role": role, "name": tname, "pos": pos, "face": face, "anim": src["anim"], "dir": src["dir"],
		"idle_t": game.clock, "say": src["say"], "say_t": src["say_t"], "pose": "stand", "talk": 0.0}
	_cv = canvas
	draw_role_npc(tmp)
	var top: float = pos.y - 32.0
	if float(tmp["say_t"]) > 0.0:
		# khung thoại dời sang phải/xuống thấp một chút để không bị cắt ở mép màn hình phòng
		var sp: Dictionary = tmp.duplicate()
		sp["pos"] = Vector2(maxf(pos.x, 90.0), maxf(pos.y, 70.0))
		draw_role_speech(sp)
	else:
		ctext(tname, pos.x - 40, top - 8, 80, 7, Color("1e3a8a"))
		if act != "":
			ctext(act, pos.x - 50, top + 1, 100, 7, Color("334155"))
		if _rk != "" and _rpos.distance_to(pos) <= ASK_RANGE + 14.0 and act != ACT_TEXT["teach"]:
			ctext("[G] Hỏi bài thầy", pos.x - 50, top + 10, 100, 7, Color("c2410c"))
	_cv = null

# Bấm G trong phòng khi đứng gần thầy: hỏi bài. Chỉ được khi thầy không đang giảng và còn thời gian ở lại.
func _try_ask_teacher() -> bool:
	if _rk == "" or not ROOM_SPOTS.has(_rk):
		return false
	for n in _npcs:
		if not n.has("tch"):
			continue
		var t: Dictionary = n.tch
		if str(t["in_room"]) != _rk or not n.hidden or str(t["state"]) != "room":
			continue   # chỉ hỏi bài khi thầy đã tới bàn (không hỏi lúc thầy đang đi vào/ra)
		if _rpos.distance_to(t["room_pos"]) > ASK_RANGE:
			continue
		var m: float = game.game_min
		if not _lesson_at(t, m).is_empty():
			n.say = "Đang trong giờ học, em để lát hết tiết rồi hỏi thầy nhé."
		elif m >= float(t["leave_by"]) - 4.0:
			n.say = "Thầy phải về rồi, mai em hỏi thầy nhé."
		else:
			t["act"] = "assist"
			t["room_until"] = maxf(float(t["room_until"]), minf(m + 8.0, float(t["leave_by"]) - 2.0))
			var pool: Array = ASK_LINES.get(str(n.role), [])
			if not pool.is_empty():
				n.say = str(pool[int(t["ask_i"]) % pool.size()])
				t["ask_i"] = int(t["ask_i"]) + 1
			if not bool(t["rewarded"]) and game.stats != null:
				t["rewarded"] = true
				game.stats.add_drl(1, "Hỏi bài thầy sau giờ học")
		n.say_t = ROLE_SAY_TIME
		return true
	return false

# Câu thoại theo việc thầy đang làm (nói chuyện ngoài trời bằng E)
func _context_lines(n: Dictionary) -> Array:
	var t: Dictionary = n.tch
	if str(n.pose) == "sleep":
		return NAP_LINES
	if str(t["state"]) == "walk" or str(t["state"]) == "ride":
		if str(t["goal"]) == "class":
			return HURRY_LINES
		if str(t["goal"]) == "home" or str(t["goal"]) == "ride_out":
			return HOME_LINES
	return []

# Xe máy của thầy khi chạy trong trường (vẽ dưới người)
func draw_role_bike(pos: Vector2, face: int, col: Color) -> void:
	var dark := Color("1a1a2e")
	if face >= 2:
		var fx: float = 1.0 if face == 3 else -1.0
		rc(pos.x - 10, pos.y - 1, 6, 6, dark)
		rc(pos.x + 4, pos.y - 1, 6, 6, dark)
		rc(pos.x - 9, pos.y, 4, 4, Color("6b7280"))
		rc(pos.x + 5, pos.y, 4, 4, Color("6b7280"))
		rc(pos.x - 8, pos.y - 5, 16, 6, dark)
		rc(pos.x - 7, pos.y - 4, 14, 4, col)
		rc(pos.x - 3, pos.y - 7, 8, 2, dark)
		rc(pos.x + 7.0 * fx - (1.0 if fx > 0.0 else 0.0), pos.y - 9, 2, 5, dark)
		rc(pos.x + 8.0 * fx, pos.y - 3, 2, 2, Color("fff8c8"))
	elif face == 0:
		rc(pos.x - 2, pos.y + 1, 4, 8, dark)
		rc(pos.x - 7, pos.y - 9, 14, 2, dark)
		rc(pos.x - 4, pos.y - 6, 8, 9, dark)
		rc(pos.x - 3, pos.y - 5, 6, 7, col)
		rc(pos.x - 1, pos.y + 3, 2, 2, Color("fff8c8"))
	else:
		rc(pos.x - 2, pos.y + 1, 4, 8, dark)
		rc(pos.x - 4, pos.y - 6, 8, 9, dark)
		rc(pos.x - 3, pos.y - 5, 6, 7, col)
		rc(pos.x - 3, pos.y - 1, 6, 3, Color("2b2d34"))
		rc(pos.x - 1, pos.y + 7, 2, 1, Color("e02424"))
