extends "res://scripts/features/feature.gd"
# TÒA B4.2 + PHÒNG LAB MÁY TÍNH DÙNG CHUNG (Không hiển thị tên sinh viên NPC).

# ---------- Tòa nhà ngoài trời ----------
# Đặt tại phía bắc dãy E theo sơ đồ mới: x=860, y=10, w=120, h=100 (dịch lên để có không gian cổng)
# Tòa B4.2 nằm dọc lối đi phía bắc các tòa chính.
const RECT := Rect2(1045, 2, 140, 105)
const DOOR_RANGE := 44.0                 # đứng cách cửa tối đa bấm E mới vào được (px)

const VIEW := Vector2(480, 270)
const WALL_H := 56.0
const FLOOR_BOTTOM := 258.0
const DOOR_POS := Vector2(412, 252)
const START_POS := Vector2(412, 240)
const WALK_SPEED := 70.0
const SEAT_RANGE := 18.0
const ROW_TOPS := [116.0, 162.0, 208.0]
const DESK_XS := [110.0, 240.0, 370.0]
const DESK_W := 84.0
const PC_OFFSET := 21.0
const TEACHER_DESK := Rect2(200, 66, 80, 14)

const C_FLOOR_A := Color("b4bdc7")
const C_FLOOR_B := Color("a8b2bd")
const C_WALL := Color("cfd8df")
const C_WOOD_TOP := Color("c19660")
const C_WOOD_FRONT := Color("8a6238")

const LAB_PRESETS := {
	"B42_VTP": {
		"title": "PHÒNG LAB B4.2 · THỰC HÀNH VI TÍCH PHÂN",
		"npcs": [
			{"seat": 0,  "shirt": "2c3e50", "hair": "2a1d14", "uni": false, "long": false, "pack": false, "label": "GV. Vi tích phân"},
			{"seat": 1,  "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"seat": 3,  "shirt": "81b29a", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"seat": 5,  "shirt": "e07a5f", "hair": "2a1d14", "uni": false, "long": true,  "pack": true},
			{"seat": 7,  "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": false, "pack": false},
			{"seat": 9,  "shirt": "f2cc8f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": true},
			{"seat": 11, "shirt": "457b9d", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"seat": 13, "shirt": "d96b43", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false},
			{"seat": 15, "shirt": "3d5a80", "hair": "5a3a22", "uni": true,  "long": false, "pack": true},
			{"seat": 17, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true}
		]
	},
	"D_CSLT": {
		"title": "PHÒNG MÁY TÒA D · THỰC HÀNH CƠ SỞ LẬP TRÌNH",
		"npcs": [
			{"seat": 0,  "shirt": "1f4e78", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false, "label": "GV. Cơ sở lập trình"},
			{"seat": 1,  "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"seat": 3,  "shirt": "81b29a", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"seat": 5,  "shirt": "e07a5f", "hair": "5a3a22", "uni": false, "long": false, "pack": true},
			{"seat": 7,  "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": false},
			{"seat": 9,  "shirt": "3d5a80", "hair": "2a1d14", "uni": false, "long": false, "pack": true},
			{"seat": 11, "shirt": "81b29a", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
			{"seat": 13, "shirt": "457b9d", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"seat": 15, "shirt": "d96b43", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false},
			{"seat": 17, "shirt": "e07a5f", "hair": "2a1d14", "uni": true,  "long": false, "pack": false}
		]
	}
}

var inside := false
var _layer: CanvasLayer
var _painter: Node2D
var _pos := START_POS
var _face := 1
var _anim := 0.0
var _clock := 0.0
var _seated := -1
var _fade := 0.0
var _closing := false
var _groups: Array = []
var _seats: Array = []
var _solid: Array = []

var _board_title := "PHÒNG LAB B4.2 · THỰC HÀNH VI TÍCH PHÂN"
var _seat_npcs: Dictionary = {}
var _di_hoc_f: Node = null
var _looked: bool = false
var _active_preset: String = "B42_VTP"

func _ready() -> void:
	game.BUILDINGS.append(["B4.2", RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y, Color("8e959f"), Color("1f4a8c"), "Tòa B4.2 - Phòng Lab Thực hành Vi tích phân."])
	_build_room()
	_apply_preset("B42_VTP")
	_layer = CanvasLayer.new()
	_layer.layer = 5
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint)

func _lookup() -> void:
	if _looked:
		return
	_looked = true
	for f in game.features:
		if f != self and f.has_method("notify_seat_entered"):
			_di_hoc_f = f

func _build_room() -> void:
	_groups.clear()
	_seats.clear()
	_solid.clear()
	_add_group(TEACHER_DESK, [240.0], true, Vector2(176, 78))
	for top in ROW_TOPS:
		for cx in DESK_XS:
			_add_group(Rect2(cx - DESK_W / 2.0, top, DESK_W, 14.0), [cx - PC_OFFSET, cx + PC_OFFSET], false, Vector2.ZERO)

func _add_group(desk: Rect2, xs: Array, teacher: bool, stand_override: Vector2) -> void:
	var gi: int = _groups.size()
	_groups.append({"id": gi, "desk": desk, "xs": xs, "teacher": teacher})
	_solid.append(desk)
	for x in xs:
		var top: float = desk.position.y
		if teacher:
			_seats.append({"g": gi, "x": x, "top": top, "pos": Vector2(x, top + 4.0), "stand": stand_override, "face": 0})
			_solid.append(Rect2(x - 7.0, top - 14.0, 14.0, 18.0))
		else:
			_seats.append({"g": gi, "x": x, "top": top, "pos": Vector2(x, top + 26.0), "stand": Vector2(x, top + 34.0), "face": 1})
			_solid.append(Rect2(x - 7.0, top + 16.0, 14.0, 11.0))

func _apply_preset(preset_key: String, custom_title: String = "") -> void:
	_active_preset = preset_key
	_seat_npcs.clear()
	var cfg: Dictionary = LAB_PRESETS.get(preset_key, LAB_PRESETS["B42_VTP"])
	_board_title = custom_title if custom_title != "" else str(cfg.get("title", "PHÒNG LAB MÁY TÍNH"))
	var list: Array = cfg.get("npcs", [])
	for n in list:
		if n is Dictionary:
			var si: int = int(n.get("seat", -1))
			if si >= 0 and si < _seats.size():
				_seat_npcs[si] = n

func open_lab(preset_key: String = "B42_VTP", custom_title: String = "") -> void:
	_apply_preset(preset_key, custom_title)
	begin()

func _door_outside() -> Vector2:
	return Vector2(RECT.get_center().x, RECT.end.y + 8.0)

func _near_door_outside() -> bool:
	return game.player.distance_to(_door_outside()) < DOOR_RANGE

func begin() -> void:
	super()
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_seated = -1
	_fade = 1.0
	_layer.visible = true
	game.hud.visible = false

func finish() -> void:
	super()
	if _di_hoc_f != null:
		_di_hoc_f.notify_seat_exited()
	inside = false
	_closing = false
	_seated = -1
	_layer.visible = false
	game.hud.visible = true

func _class_session_busy() -> bool:
	return _di_hoc_f != null and _di_hoc_f.has_method("is_session_modal_open") and bool(_di_hoc_f.is_session_modal_open())

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if inside:
		if _closing or _class_session_busy():
			return
		var in_active_lesson: bool = _di_hoc_f != null and _di_hoc_f.has_method("is_in_active_lesson") and bool(_di_hoc_f.is_in_active_lesson())
		if _seated >= 0:
			if in_active_lesson:
				if k.keycode == KEY_ESCAPE:
					_stand_up()
					get_viewport().set_input_as_handled()
				return
			if k.physical_keycode == KEY_E or k.keycode == KEY_ESCAPE:
				_stand_up()
				get_viewport().set_input_as_handled()
			return
		if k.physical_keycode != KEY_E:
			return
		if _pos.distance_to(DOOR_POS) < 24.0:
			_closing = true
		else:
			var s: int = _nearest_seat()
			if s >= 0:
				_sit(s)
		get_viewport().set_input_as_handled()
	elif k.physical_keycode == KEY_E and not game.is_busy() and _near_door_outside():
		open_lab("B42_VTP")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not inside:
		return
	_clock += delta
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			finish()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		if _seated < 0:
			_walk(delta)
		elif _di_hoc_f != null:
			_di_hoc_f.process_classroom_sitting(delta)
	_painter.queue_redraw()

func _walk(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if v == Vector2.ZERO:
		return
	v = v.normalized() * WALK_SPEED * delta
	if absf(v.x) > absf(v.y):
		_face = 2 if v.x < 0.0 else 3
	else:
		_face = 1 if v.y < 0.0 else 0
	_anim += delta
	var a := _pos + Vector2(v.x, 0.0)
	if _blocked(a):
		a = _pos
	var b := a + Vector2(0.0, v.y)
	if _blocked(b):
		b = a
	_pos = b

func _blocked(p: Vector2) -> bool:
	if p.x < 14.0 or p.x > VIEW.x - 14.0 or p.y < 62.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

func _nearest_seat() -> int:
	var best: int = -1
	var bd: float = SEAT_RANGE
	for i in _seats.size():
		if _seat_npcs.has(i):
			continue
		var d: float = _pos.distance_to(_seats[i].stand)
		if d < bd:
			bd = d
			best = i
	return best

func _adjacent_lab_friend(seat_idx: int) -> String:
	if seat_idx <= 0:
		return ""
	var gi: int = int(_seats[seat_idx].g)
	for i in _seats.size():
		if i != seat_idx and int(_seats[i].g) == gi and _seat_npcs.has(i):
			return "bạn cùng bàn"
	return ""

func _sit(i: int) -> void:
	_lookup()
	_seated = i
	_pos = _seats[i].pos
	_face = int(_seats[i].face)
	var fn: String = _adjacent_lab_friend(i)
	if _di_hoc_f != null:
		_di_hoc_f.notify_seat_entered(_active_preset, _board_title, fn)

func _stand_up() -> void:
	_pos = _seats[_seated].stand
	_face = 0
	_seated = -1
	if _di_hoc_f != null:
		_di_hoc_f.notify_seat_exited()

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, Color("23262e"))
	_paint_shell(p)
	var items: Array = []
	for g in _groups:
		items.append([g.desk.end.y, 0, g])
	if _seated < 0:
		items.append([_pos.y, 1, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[1] == 0:
			_paint_group(p, it[2])
		else:
			_paint_player(p)
	_paint_prompt(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

func _paint_shell(p: Node2D) -> void:
	p.rc(0, 0, VIEW.x, WALL_H, C_WALL)
	p.rc(0, WALL_H - 4.0, VIEW.x, 4, C_WALL.darkened(0.15))
	p.rc(0, 0, VIEW.x, 3, C_WALL.lightened(0.2))
	for ty in range(int(WALL_H), int(FLOOR_BOTTOM), 16):
		for tx in range(0, int(VIEW.x), 16):
			p.rc(tx, ty, 16, 16, C_FLOOR_A if ((tx + ty) / 16) % 2 == 0 else C_FLOOR_B)
	p.rc(0, FLOOR_BOTTOM, VIEW.x, VIEW.y - FLOOR_BOTTOM, Color("5a5f6b"))
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 2, Color("3f434d"))
	p.rc(0, 0, 8, VIEW.y, Color("4a4f5b"))
	p.rc(VIEW.x - 8.0, 0, 8, VIEW.y, Color("4a4f5b"))
	_paint_board(p)
	_paint_aircon(p)
	p.rc(394, FLOOR_BOTTOM, 36, 12, Color("2b2b2b"))
	p.rc(396, FLOOR_BOTTOM + 1.0, 32, 11, Color("8a5a32"))
	p.rc(410, FLOOR_BOTTOM + 1.0, 2, 11, Color("3a2412"))
	p.rc(424, FLOOR_BOTTOM + 5.0, 2, 2, Color("e8d28a"))

func _paint_board(p: Node2D) -> void:
	p.rc(140, 6, 200, 38, Color("7d848d"))
	p.rc(142, 8, 196, 34, Color("f4f6f8"))
	p.rc(142, 8, 196, 2, Color("dfe4e8"))
	p.draw_string(p.font, Vector2(142, 21), _board_title, HORIZONTAL_ALIGNMENT_CENTER, 196, 7, Color("2457c5"))
	var inks := [Color("c0392b"), Color("1f7a3a"), Color("222222")]
	for line in 3:
		var yy: int = 26 + line * 5
		var ink: Color = inks[line]
		var n: int = 21 if line < 2 else 13
		for i in n:
			var w: int = 3 + ((i * 7 + line * 3) % 4)
			p.rc(150 + i * 8 + (line % 2) * 2, yy + (i % 2), w, 1, ink)
	p.rc(148, 38, 184, 3, Color("e8ecef"))
	p.rc(192, 42, 96, 3, Color("6a7078"))
	p.rc(198, 40, 9, 2, Color("2457c5"))
	p.rc(210, 40, 9, 2, Color("c0392b"))
	p.rc(222, 40, 9, 2, Color("222222"))
	p.rc(266, 39, 12, 4, Color("3a3f4a"))
	p.rc(266, 39, 12, 1, Color("5a606c"))

func _paint_aircon(p: Node2D) -> void:
	p.rc(356, 10, 58, 20, Color("b8bec6"))
	p.rc(357, 11, 56, 18, Color("eef1f4"))
	p.rc(357, 11, 56, 3, Color("ffffff"))
	p.rc(359, 22, 52, 4, Color("c9ced4"))
	for i in 9:
		p.rc(360 + i * 6, 23, 4, 1, Color("9aa1ab"))
	p.rc(402, 15, 4, 2, Color("46d07a"))
	p.rc(396, 15, 4, 2, Color("9aa1ab"))
	var f: int = int(_clock * 3.0) % 4
	for i in 4:
		p.rc(364 + i * 13, 31 + ((i + f) % 4) * 4, 2, 3, Color(0.75, 0.92, 1.0, 0.45))

func _paint_seat_occupants(p: Node2D, group_id: int) -> void:
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if int(s.g) != group_id:
			continue
		if _seated == si:
			_paint_player(p)
		elif _seat_npcs.has(si):
			var npc: Dictionary = _seat_npcs[si]
			p.draw_person(
				s.pos,
				Color(str(npc.get("shirt", "3d5a80"))),
				Color(str(npc.get("hair", "1b1b1b"))),
				int(s.face),
				0.0,
				bool(npc.get("uni", true)),
				bool(npc.get("long", false)),
				bool(npc.get("pack", false))
			)
			var lbl: String = str(npc.get("label", ""))
			if lbl != "":
				var w: float = p.font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 6.0
				p.ctext(lbl, float(s.pos.x) - w / 2.0, float(s.pos.y) - 29.0, w, 7, Color("ffe9a8"))

func _paint_group(p: Node2D, g: Dictionary) -> void:
	var desk: Rect2 = g.desk
	var top: float = desk.position.y
	var xs: Array = g.xs
	var teacher: bool = g.teacher
	if teacher:
		for x in xs:
			p.rc(x - 12, top - 21, 24, 18, Color("2b3550"))
			p.rc(x - 11, top - 20, 22, 16, Color("3d4d70"))
			p.rc(x - 11, top - 20, 22, 2, Color("56688f"))
			p.rc(x - 6, top - 4, 12, 6, Color("2f3b5a"))
			p.rc(x - 6, top - 4, 12, 2, Color("4b5d86"))
			p.rc(x - 1, top + 2, 2, 3, Color("1e2027"))
		_paint_seat_occupants(p, int(g.id))
	p.rc(desk.position.x - 1, top - 1, desk.size.x + 2, 16, Color("5c4126"))
	p.rc(desk.position.x, top, desk.size.x, 8, C_WOOD_TOP)
	p.rc(desk.position.x, top, desk.size.x, 1, C_WOOD_TOP.lightened(0.2))
	p.rc(desk.position.x, top + 8.0, desk.size.x, 6, C_WOOD_FRONT)
	p.rc(desk.position.x, top + 13.0, desk.size.x, 1, C_WOOD_FRONT.darkened(0.3))
	for x in xs:
		_paint_computer(p, x, top, teacher)
	if not teacher:
		_paint_seat_occupants(p, int(g.id))
		for x in xs:
			p.rc(x - 1, top + 25, 2, 4, Color("1e2027"))
			p.rc(x - 5, top + 28, 10, 1, Color("1e2027"))
			p.rc(x - 7, top + 16, 14, 11, Color("2b3550"))
			p.rc(x - 6, top + 17, 12, 9, Color("3d4d70"))
			p.rc(x - 6, top + 17, 12, 2, Color("56688f"))

func _paint_computer(p: Node2D, x: float, top: float, big: bool) -> void:
	var hw: float = 11.0 if big else 9.0
	var hh: float = 13.0 if big else 11.0
	if not big:
		p.rc(x - hw, top - hh, hw * 2.0, hh + 3.0, Color("23262e"))
		p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, hh + 1.0, Color("3a3e48"))
		p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, 2, Color("565b68"))
		for i in 3:
			p.rc(x - 5.0, top - hh + 4.0 + i * 2.0, 10, 1, Color("2c3038"))
		p.rc(x + hw - 4.0, top - 2.0, 2, 1, Color("46d07a"))
		p.rc(x - 2, top + 2, 4, 2, Color("1e2027"))
		p.rc(x - hw + 1.0, top + 4.0, hw * 2.0 - 2.0, 3, Color("dde1e6"))
		for i in 5:
			p.rc(x - hw + 2.0 + i * 3.0, top + 5.0, 2, 1, Color("8d949c"))
		p.rc(x + hw + 2.0, top + 5.0, 3, 2, Color("f2f2f2"))
		return
	p.rc(x - hw, top - hh, hw * 2.0, hh + 3.0, Color("2a2d36"))
	p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, hh - 2.0, Color("3b86e0"))
	p.rc(x - hw + 1.0, top - hh + 1.0, hw * 2.0 - 2.0, 2, Color("6aa8f0"))
	var scroll: int = int(_clock * 3.0 + x) % 4
	for i in 3:
		p.rc(x - hw + 3.0, top - hh + 4.0 + i * 2.0, 5.0 + ((i + scroll) % 3) * 3.0, 1, Color("d6eaff"))
	p.rc(x - 2, top + 2, 4, 2, Color("1e2027"))
	p.rc(x - hw + 1.0, top + 4.0, hw * 2.0 - 2.0, 3, Color("dde1e6"))
	for i in 5:
		p.rc(x - hw + 2.0 + i * 3.0, top + 5.0, 2, 1, Color("8d949c"))
	p.rc(x + hw + 2.0, top + 5.0, 3, 2, Color("f2f2f2"))

func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var in_active_lesson: bool = _di_hoc_f != null and _di_hoc_f.has_method("is_in_active_lesson") and bool(_di_hoc_f.is_in_active_lesson())
	if in_active_lesson:
		return
	var text: String = ""
	if _seated >= 0:
		text = "[E] Đứng dậy (Đang tự học · thời gian x4)"
	elif _pos.distance_to(DOOR_POS) < 26.0:
		text = "[E] Ra ngoài"
	else:
		var si: int = _nearest_seat()
		if si >= 0:
			var fn: String = _adjacent_lab_friend(si)
			text = "[E] Ngồi máy cạnh %s" % fn if fn != "" else "[E] Ngồi vào máy"
	if text != "":
		p.ctext(text, _pos.x - 65.0, _pos.y - 44.0, 130, 8, Color.WHITE)

func draw_front_layer() -> void:
	if not game.view.intersects(RECT.grow(60.0)):
		return
	_paint_facade()
	_repaint_front_items()
	if not inside and not game.is_busy() and _near_door_outside():
		var text: String = "Bấm [E] để vào Tòa B4.2 (TH Vi tích phân)"
		var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
		var px: float = game.player.x
		var py: float = game.player.y - 46.0
		game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
		game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
		game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))

func _repaint_front_items() -> void:
	var area := Rect2(RECT.position.x - 40.0, RECT.end.y - 4.0, RECT.size.x + 80.0, 80.0)
	var items: Array = []
	for t in game.trees:
		if area.has_point(Vector2(t[0], t[1])):
			items.append([float(t[1]), 0, t])
	for l in game.lamps:
		if area.has_point(l):
			items.append([l.y, 1, l])
	for b in game.benches:
		var bench_pos: Vector2 = game.get_bench_position(b)
		if area.has_point(bench_pos):
			items.append([bench_pos.y, 2, b])
	for o in game.npcs:
		if not o.has("role") and area.has_point(o.pos):
			items.append([o.pos.y, 3, o])
	if area.has_point(game.player):
		items.append([game.player.y, 4, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				game.draw_tree(it[2])
			1:
				game.draw_lamp(it[2])
			2:
				game.draw_bench(it[2])
			3:
				var o: Dictionary = it[2]
				game.draw_person(o.pos, o.shirt, o.hair, o.face, o.anim, o.uni, o.long, o.pack)
				if o.say_t > 0.0:
					game.draw_speech(o)
			4:
				game.draw_person(game.player, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
				game.ctext("Bạn", game.player.x - 15.0, game.player.y - 28.0, 30, 8, Color("ffd23f"))

func _paint_facade() -> void:
	var r := RECT
	var x: float = r.position.x
	var y: float = r.position.y
	var w: float = r.size.x
	var end_y: float = r.end.y
	var cx: float = x + w / 2.0
	var frame := Color("8e959f")
	var frame_dark := Color("5f6671")
	var panel := Color("d4d8dd")
	var panel_shade := Color("9aa1ab")
	game.rc(x, y, w, r.size.y, frame)
	game.rc(x, y, w, 4, frame.lightened(0.25))
	game.rc(x + w - 52, y - 4, 40, 4, frame)
	game.rc(x + w - 46, y - 8, 28, 4, frame)
	game.rc(x + w - 44, y - 6, 24, 8, Color("eef1f4"))
	game.ctext("B4.2", x + w - 44, y + 1, 24, 8, Color("1f4aa8"))
	var gx: float = x + 12.0
	var gw: float = w - 24.0
	var gy: float = y + 12.0
	var gh: float = r.size.y - 12.0 - 30.0
	var bands: int = 8
	for i in bands:
		var t: float = float(i) / (bands - 1)
		var c: Color = Color("4a86d0").lerp(Color("14305f"), t)
		game.rc(gx, gy + gh * i / bands, gw, ceilf(gh / bands) + 1.0, c)
	for i in range(1, int(gw / 11.0) + 1):
		game.rc(gx + i * 11.0, gy, 1, gh, Color("14305f"))
	for j in range(0, int(gh / 12.0) + 1):
		game.rc(gx, gy + j * 12.0, gw, 1, Color("6fa3e6", 0.55))
	for k in 5:
		game.rc(gx + 6.0 + k * 17.0, gy + 8.0 + k * 22.0, 14, 2, Color(1, 1, 1, 0.18))
	game.rc(cx - 3, gy, 6, gh, frame_dark)
	game.rc(cx - 3, gy, 1, gh, frame_dark.lightened(0.2))
	_paint_fin(x + 2.0, y + 74.0, 28.0, end_y - 30.0, panel, panel_shade)
	_paint_fin(cx - 14.0, y + 38.0, 28.0, end_y - 30.0, panel, panel_shade)
	_paint_fin(x + w - 30.0, y + 58.0, 28.0, end_y - 30.0, panel, panel_shade)
	game.rc(x, end_y - 30, w, 30, frame)
	game.rc(x, end_y - 30, w, 2, frame.lightened(0.2))
	game.rc(x, end_y - 8, w, 8, frame_dark)
	for wx in [x + 8.0, x + 30.0, x + w - 52.0, x + w - 30.0]:
		game.rc(wx, end_y - 25, 20, 14, Color("1a2f55"))
		game.rc(wx + 1, end_y - 24, 18, 12, Color("3f6fb0"))
		game.rc(wx + 1, end_y - 24, 18, 3, Color("7fb0e6"))
		game.rc(wx + 9, end_y - 24, 1, 12, Color("1a2f55"))
	game.hedge(x - 2, end_y, w + 4)
	game.rc(cx - 12, end_y - 22, 24, 22, Color("3a2f2a"))
	game.rc(cx - 10, end_y - 20, 9, 20, Color("9fd3f0"))
	game.rc(cx + 1, end_y - 20, 9, 20, Color("9fd3f0"))
	game.rc(cx - 14, end_y - 26, 28, 5, frame_dark)
	for i in 3:
		game.rc(cx - 14 + i * 2, end_y + 7 + i * 2, 28 - i * 4, 2, Color("bdbdbd") if i % 2 == 0 else Color("a5a5a5"))
	game.draw_rect(r, Color("2b2b2b"), false, 1.0)

func _paint_fin(fx: float, fy: float, fw: float, bottom: float, panel: Color, shade: Color) -> void:
	var fh: float = bottom - fy
	game.rc(fx + fw, fy + 4, 5, fh, Color(0, 0, 0, 0.25))
	game.rc(fx - 1, fy - 3, fw + 2, 3, panel.lightened(0.2))
	game.rc(fx, fy, fw, fh, panel)
	game.rc(fx + fw - 5, fy, 5, fh, shade)
	game.rc(fx, fy, 2, fh, panel.lightened(0.12))
	var yy: float = fy + 7.0
	while yy + 8.0 < bottom:
		for wx in [fx + 4.0, fx + 14.0]:
			game.rc(wx, yy, 9, 7, Color("f0f0f0"))
			game.rc(wx + 1, yy + 1, 7, 5, Color("3a5f94"))
			game.rc(wx + 1, yy + 1, 7, 1, Color("7ca3d6"))
		yy += 12.0
