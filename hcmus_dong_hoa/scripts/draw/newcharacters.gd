extends "res://scripts/draw/characters.gd"
# ======================================================================================
# 5 NPC CÓ TÊN: Thầy LTC, Thầy LĐK, Bác bảo vệ, Bác giữ xe, Cô lao công.
# Vẽ pixel art cùng phong cách draw_person (viền đậm, bóng dưới chân), 4 hướng, Idle + Walk.
# Dùng lại: move_entity() để đi/va chạm, draw_speech/bóng thoại, spawn_npcs()/update_npcs() có sẵn.
# Hướng (face) giống người chơi: 0 = xuống, 1 = lên, 2 = trái, 3 = phải.
# Bấm E khi đứng gần để NPC nói câu thoại (lần lượt theo thứ tự).
# ======================================================================================

const ROLE_TALK_RANGE := 30.0
const ROLE_SPEED := 20.0
const ROLE_WALK_RADIUS := 36.0
const ROLE_SAY_TIME := 4.5

# Thông tin từng nhân vật: tên, chỗ đứng, câu thoại (GIỮ NGUYÊN từng chữ, từng dấu)
const ROLE_NPCS := {
	"thay_ltc": {
		"name": "Thầy LTC", "home": Vector2(610, 545),
		"lines": ["Bài này dễ mà, mấy em thi 27 điểm thì như gãi ngứa.", "Mấy phần này mấy em biết rồi, thầy cho qua nhe."],
	},
	"thay_ldk": {
		"name": "Thầy LĐK", "home": Vector2(1010, 600),
		"lines": ["Thầy thấy điểm tuần này cao lắm, hay hôm nay mình Harmony nha các em.", "Các em mở máy làm bài test trên Moodles nhé."],
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

# Thêm 5 NPC vào danh sách npcs (cùng cơ chế sắp xếp chiều sâu với NPC thường)
func spawn_npcs() -> void:
	super()
	for id in ROLE_NPCS:
		var info: Dictionary = ROLE_NPCS[id]
		var p: Vector2 = info.home
		var found := not blocked(p)
		var r := 4.0
		while not found and r < 80.0:
			for a in 12:
				var c: Vector2 = info.home + Vector2.from_angle(a * TAU / 12.0) * r
				if not blocked(c):
					p = c
					found = true
					break
			r += 4.0
		npcs.append({"role": id, "name": info.name, "lines": info.lines, "line_i": 0, "home": p, "pos": p,
			"dir": Vector2.ZERO, "timer": randf_range(0.5, 2.0), "face": 0, "anim": 0.0, "idle_t": randf() * 6.0,
			"say": "", "say_t": 0.0, "talk": 0.0})

# NPC thường đi lung tung như cũ; 5 NPC có tên đi quanh chỗ đứng, dừng lại khi đang nói chuyện
func update_npcs(delta: float) -> void:
	var normal: Array = []
	var named: Array = []
	for n in npcs:
		if n.has("role"):
			named.append(n)
		else:
			normal.append(n)
	npcs = normal
	super(delta)
	npcs = normal + named
	for n in named:
		update_role_npc(n, delta)

func update_role_npc(n: Dictionary, delta: float) -> void:
	n.say_t -= delta
	n.idle_t += delta
	if n.talk > 0.0:
		n.talk -= delta
		n.dir = Vector2.ZERO
		return
	n.timer -= delta
	if n.timer <= 0.0:
		n.timer = randf_range(1.2, 3.2)
		var dirs := [Vector2.ZERO, Vector2.ZERO, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		n.dir = dirs[randi() % dirs.size()]
		var off: Vector2 = n.pos - n.home
		if off.length() > ROLE_WALK_RADIUS:   # đi quá xa thì quay về chỗ đứng
			n.dir = Vector2(-signf(off.x), 0.0) if absf(off.x) > absf(off.y) else Vector2(0.0, -signf(off.y))
		if n.dir != Vector2.ZERO:
			n.face = role_face(n.dir)
	var np: Vector2 = move_entity(n.pos, n.dir * ROLE_SPEED * delta)
	if np == n.pos and n.dir != Vector2.ZERO:
		n.timer = 0.0
		n.dir = Vector2.ZERO
	elif n.dir != Vector2.ZERO:
		n.anim += delta
	n.pos = np

func role_face(d: Vector2) -> int:
	if absf(d.x) > absf(d.y):
		return 2 if d.x < 0.0 else 3
	return 1 if d.y < 0.0 else 0

# NPC có tên gần người chơi nhất trong tầm nói chuyện (null nếu không có)
func role_npc_near() -> Variant:
	var best: Variant = null
	var bd := ROLE_TALK_RANGE
	for n in npcs:
		if n.has("role"):
			var d: float = n.pos.distance_to(player)
			if d < bd:
				bd = d
				best = n
	return best

# Bấm E gần NPC: NPC quay mặt về phía người chơi và nói câu tiếp theo
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.physical_keycode != KEY_E:
		return
	for f in features:   # đang câu cá / mở sổ tay thì không nói chuyện (is_busy() nằm ở main.gd, file này không gọi được)
		if f.active:
			return
	var n: Variant = role_npc_near()
	if n == null:
		return
	var lines: Array = n.lines
	n.say = lines[n.line_i % lines.size()]
	n.line_i += 1
	n.say_t = ROLE_SAY_TIME
	n.talk = ROLE_SAY_TIME
	n.dir = Vector2.ZERO
	n.face = role_face(player - n.pos)
	get_viewport().set_input_as_handled()

# Bóng thoại nhiều dòng (tự xuống dòng), kèm tên nhân vật
func draw_role_speech(n: Dictionary) -> void:
	var top: float = n.pos.y - 32.0 - (3.0 if n.role == "lao_cong" else 0.0)
	if n.say_t > 0.0:
		var lines := wrap_text(n.say, 150.0)
		var w := 0.0
		for l in lines:
			w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
		w += 8.0
		var h := 4.0 + lines.size() * 9.0
		var y0 := top - h
		rc(n.pos.x - w / 2.0 - 1, y0 - 1, w + 2, h + 2, Color("333333"))
		rc(n.pos.x - w / 2.0, y0, w, h, Color.WHITE)
		rc(n.pos.x - 1, top + 1, 3, 3, Color.WHITE)
		for i in lines.size():
			draw_string(font, Vector2(n.pos.x - w / 2.0 + 4.0, y0 + 9.0 + i * 9.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
		ctext(n.name, n.pos.x - 40, y0 - 4, 80, 8, Color("ffd23f"))

func wrap_text(t: String, max_w: float) -> Array:
	var out: Array = []
	var cur := ""
	for word in t.split(" "):
		var test: String = word if cur == "" else cur + " " + word
		if cur != "" and font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > max_w:
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
	var by := pos.y - bob
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
	if n.say_t <= 0.0:
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
