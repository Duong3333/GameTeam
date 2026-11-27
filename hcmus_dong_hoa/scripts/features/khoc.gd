extends "res://scripts/features/feature.gd"
# CƠ CHẾ KHÓC - dùng chung cho người chơi và MỌI NPC (sinh viên thường, Cô Toán, NPC có tên).
# Không sửa file nào trong scripts/draw hay main.gd; chỉ vẽ thêm lớp hiệu ứng lên trên nhân vật (draw_front_layer).
#
# Hiệu ứng: nước mắt chảy từ mắt xuống má và rơi, giọt nước bắn ra hai bên, miệng mếu, chữ "hic / huhu" bên đầu,
# vũng nước dưới chân lớn dần rồi khô từ từ sau khi nín. Có tiếng khóc (assets/audio/cry.wav).
# Nhân vật hướng lưng về camera thì không thấy mặt nên chỉ có giọt bắn, chữ và vũng nước.
#
# Người chơi:
#   - Bấm C để khóc, bấm C lần nữa để nín.
#   - Tự khóc khoảng PLAYER_CRY_TIME giây khi GPA bị tụt (ví dụ làm sai bài thi).
# NPC: khóc khi bị đánh (xem danhnhau.gd, có xác suất khóc hoặc giận), hoặc khi feature khác gọi start_crying().
#
# HÀM CHO FEATURE KHÁC GỌI (tìm feature bằng has_method để không phụ thuộc đường dẫn file):
#   for f in game.features:
#       if f.has_method("start_crying"):
#           f.start_crying(npc)           # npc là Dictionary trong game.npcs hoặc NPC có tên; NPC đứng yên khi khóc
#           f.start_crying()              # người chơi khóc (mặc định PLAYER_CRY_TIME giây, NPC là NPC_CRY_TIME)
#           f.start_crying(null, 0.0)     # thời gian <= 0: khóc mãi cho tới khi gọi stop_crying()
#           f.stop_crying(npc)
#           f.is_crying(npc)
# Đăng ký SAU character.gd trong registry để lớp nước mắt được vẽ đè lên NPC có tên.

const CRY_KEY := KEY_C
const NPC_CRY_TIME := 7.0       # NPC khóc bấy nhiêu giây
const PLAYER_CRY_TIME := 6.0    # người chơi khóc khi tụt GPA
const PUDDLE_FADE := 5.0        # vũng nước khô sau bấy nhiêu giây kể từ lúc nín
const SOB_INTERVAL := 1.8       # chu kỳ tiếng nấc
const ROLE_SCRIPT := "res://scripts/features/character.gd"
const CANTEEN_SCRIPT := "res://scripts/maps/canteen.gd"
const SOB_WORDS := ["hic", "huhu", "hu hu", "hic hic"]
const TEAR := Color("8fd3ff")
const TEAR_LIGHT := Color("e3f6ff")
const MOUTH := Color("5a1620")

var _player_cry: Dictionary = {}   # rỗng = người chơi không khóc
var _last_gpa := -1.0
var _roles: Variant = null         # feature NPC có tên (tìm khi cần)

# ---------- Hàm công khai ----------
func start_crying(target: Variant = null, duration: float = -1.0) -> void:
	if duration < 0.0:   # không truyền thời gian: dùng mặc định (NPC và người chơi khác nhau)
		duration = NPC_CRY_TIME if target != null else PLAYER_CRY_TIME
	var st: Variant = _state(target)
	if st != null:   # đang khóc hoặc vũng nước đang khô: khóc tiếp, kéo dài thêm
		st["done"] = false
		st["dry"] = 0.0
		st["dur"] = (float(st["t"]) + duration) if duration > 0.0 else 0.0
		return
	var fresh := {"t": 0.0, "wet": 0.0, "dur": duration, "done": false, "dry": 0.0, "sob": 0.0, "word": randi() % SOB_WORDS.size()}
	if target == null:
		_player_cry = fresh
	else:
		target["cry"] = fresh

func stop_crying(target: Variant = null) -> void:
	var st: Variant = _state(target)
	if st != null:
		st["done"] = true

func is_crying(target: Variant = null) -> bool:
	var st: Variant = _state(target)
	return st != null and not st["done"]

func _state(target: Variant) -> Variant:
	if target == null:
		if _player_cry.is_empty():
			return null
		return _player_cry
	return target.get("cry")

# Mọi NPC: sinh viên thường + NPC có tên (lấy từ features/character.gd, tìm theo đường dẫn script)
func _all_npcs() -> Array:
	var out: Array = game.npcs.duplicate()
	if _roles == null:
		for f in game.features:
			var s: Script = f.get_script()
			if s != null and s.resource_path == ROLE_SCRIPT:
				_roles = f
				break
	if _roles != null:
		var named: Array = _roles.get("_npcs")
		out.append_array(named)
	var canteen := _canteen()
	if canteen != null:
		out.append_array(canteen.get("_npcs"))
	return out

func _canteen() -> Node:
	for f in game.features:
		var s: Script = f.get_script()
		if s != null and s.resource_path == CANTEEN_SCRIPT:
			return f
	for f in game.get_children():
		var s: Script = f.get_script()
		if s != null and s.resource_path == CANTEEN_SCRIPT:
			return f
	return null

# ---------- Cập nhật ----------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.physical_keycode != CRY_KEY:
		return
	if game.is_busy():
		return
	if is_crying(null):
		stop_crying(null)
	else:
		start_crying(null, 0.0)   # bấm C để khóc, bấm C lần nữa mới nín
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_watch_gpa()
	if not _player_cry.is_empty():
		_tick(null, _player_cry, delta)
	for n in _all_npcs():
		var st: Variant = n.get("cry")
		if st != null:
			_tick(n, st, delta)

# GPA tụt (làm sai bài thi...) thì người chơi khóc. Chỉ đọc game.stats.gpa, không sửa file của quiz.
func _watch_gpa() -> void:
	if game.stats == null:
		return
	var gpa: float = game.stats.gpa
	if _last_gpa >= 0.0 and gpa < _last_gpa - 0.001:
		start_crying(null, PLAYER_CRY_TIME)
	_last_gpa = gpa

func _tick(target: Variant, st: Dictionary, delta: float) -> void:
	st["t"] = float(st["t"]) + delta
	if not st["done"]:
		var dur: float = st["dur"]
		if dur > 0.0 and float(st["t"]) >= dur:
			st["done"] = true   # nín, vũng nước bắt đầu khô
		else:
			st["wet"] = float(st["wet"]) + delta
			if target != null:
				_hold_still(target)
			st["sob"] = float(st["sob"]) - delta
			if float(st["sob"]) <= 0.0:
				st["sob"] = SOB_INTERVAL
				_sob_sound(_pos_of(target))
			return
	st["dry"] = float(st["dry"]) + delta
	if float(st["dry"]) >= PUDDLE_FADE:
		if target == null:
			_player_cry = {}
		else:
			target.erase("cry")

# NPC đang khóc thì đứng yên (NPC thường: không chọn hướng đi mới; NPC có tên: dùng cờ "talk" của character.gd)
func _hold_still(n: Dictionary) -> void:
	n["dir"] = Vector2.ZERO
	if n.has("role"):
		n["talk"] = maxf(float(n["talk"]), 0.3)
	else:
		n["timer"] = maxf(float(n["timer"]), 0.3)

func _pos_of(target: Variant) -> Vector2:
	if target == null:
		return game.player
	return target.pos

func _sob_sound(pos: Vector2) -> void:
	var view: Rect2 = game.view.grow(40.0)
	if view.has_point(pos):
		game.audio.play_sfx("cry")

# ---------- Vẽ ----------
func draw_front_layer() -> void:
	var view: Rect2 = game.view.grow(30.0)
	if not _player_cry.is_empty():
		_draw_cry(game.player, int(game.facing), _bob_player(), _player_cry, false)
	for n in _all_npcs():
		var st: Variant = n.get("cry")
		if st == null or n.get("hidden", false):
			continue
		var pos: Vector2 = n["pos"]
		if view.has_point(pos):
			_draw_cry(pos, int(n["face"]), _bob_npc(n), st, float(n["say_t"]) > 0.0)

# Độ nhún của thân (cùng công thức với draw_person / draw_role_npc) để nước mắt khớp đúng vị trí mắt.
func _bob_player() -> float:
	return 1.0 if int(float(game.anim) * 8.0) % 2 == 1 else 0.0

func _bob_npc(n: Dictionary) -> float:
	var anim: float = n["anim"]
	if not n.has("role"):
		return 1.0 if int(anim * 8.0) % 2 == 1 else 0.0
	var moving: bool = n["dir"] != Vector2.ZERO
	var ph: int = (int(anim * 8.0) % 4) if moving else 0
	if ph == 1 or ph == 3:
		return 1.0
	if not moving and int(float(n["idle_t"]) * 1.6) % 2 == 1:
		return 1.0
	return 0.0

# face: 0 = xuống (thấy mặt), 1 = lên (thấy lưng), 2 = trái, 3 = phải. talking: đang có bóng thoại thì ẩn chữ "hic".
func _draw_cry(pos: Vector2, face: int, bob: float, st: Dictionary, talking: bool) -> void:
	var t: float = st["wet"]
	var by: float = pos.y - bob
	var crying: bool = not st["done"]
	_draw_puddle(pos, st, crying)
	if not crying:
		return
	var eyes: Array = []
	match face:
		0:
			eyes = [pos.x - 3.0, pos.x + 2.0]
		2:
			eyes = [pos.x - 3.0]
		3:
			eyes = [pos.x + 2.0]
	for ex in eyes:
		_draw_tear_stream(ex, by, t)
	if face == 0:   # miệng mếu, há ra rồi mím lại theo nhịp nấc
		var wide: bool = int(t * 5.0) % 2 == 0
		var mw: float = 4.0 if wide else 2.0
		game.rc(pos.x - mw / 2.0, by - 14.0, mw, 1, MOUTH)
	# giọt nước bắn ra hai bên đầu theo hình vòng cung
	for i in 3:
		var ph: float = fposmod(t * 1.3 + i * 0.37, 1.0)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var px: float = pos.x + side * (6.0 + ph * 9.0)
		var py: float = by - 16.0 - 7.0 * ph + 16.0 * ph * ph
		game.rc(roundf(px), roundf(py), 2, 2, Color(TEAR, 1.0 - ph * ph))
	if not talking:
		var word: String = SOB_WORDS[(int(t / SOB_INTERVAL) + int(st["word"])) % SOB_WORDS.size()]
		var wob: float = roundf(sin(t * 5.0))
		game.ctext(word, pos.x - 34.0, pos.y - 25.0 + wob, 24.0, 8, Color(0.62, 0.84, 1.0))

# Vệt nước mắt dưới mắt + hai giọt rơi lần lượt xuống má rồi xuống áo
func _draw_tear_stream(ex: float, by: float, t: float) -> void:
	game.rc(ex, by - 15.0, 1, 2, Color(TEAR, 0.9))
	for i in 2:
		var ph: float = fposmod(t * 1.6 + i * 0.5, 1.0)
		var y: float = roundf(by - 15.0 + ph * 10.0)
		game.rc(ex, y, 1, 2, Color(TEAR, 1.0 - ph))
		game.rc(ex, y, 1, 1, Color(TEAR_LIGHT, 1.0 - ph))

# Vũng nước: lớn dần trong lúc khóc, nhỏ và mờ dần khi nước khô
func _draw_puddle(pos: Vector2, st: Dictionary, crying: bool) -> void:
	var r: float = minf(3.0 + float(st["wet"]) * 1.1, 9.0)
	var a := 0.5
	if not crying:
		var k: float = clampf(float(st["dry"]) / PUDDLE_FADE, 0.0, 1.0)
		a = 0.5 * (1.0 - k)
		r *= 1.0 - 0.4 * k
	game.draw_set_transform(pos + Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.38))
	game.draw_circle(Vector2.ZERO, r, Color(0.45, 0.72, 1.0, a))
	game.draw_circle(Vector2.ZERO, r * 0.55, Color(0.7, 0.88, 1.0, a * 0.8))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
