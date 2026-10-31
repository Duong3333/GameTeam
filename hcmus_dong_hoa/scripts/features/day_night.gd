extends "res://scripts/features/feature.gd"
# CHU KỲ NGÀY - ĐÊM (24 giờ) + đèn đường + người ra/vào cổng trường.
#
#   05:00 - 10:00  sáng dần          10:00 - 13:00  sáng nhất
#   13:00 - 18:00  tối dần           18:00 - 05:00  đêm (thế giới tối)
#
# Ban đêm : bật toàn bộ đèn đường. Sinh viên, 2 thầy, cô lao công đi ra khỏi trường qua cổng.
#           Bác giữ xe đứng lại ở cổng, bác bảo vệ đi tuần quanh trường.
# Ban ngày: tắt đèn đường. Sinh viên, 2 thầy, cô lao công đi vào trường qua cổng; bác bảo vệ và bác giữ xe về chỗ cũ.
#
# Dùng lại của game (không tạo hệ thống mới):
#   game.game_min   giờ trong game (phút, 0..1440), do main.gd cộng mỗi khung hình
#   game.lamps      danh sách đèn đường có sẵn (mỗi đèn thêm 1 PointLight2D để chiếu sáng)
#   game.npcs       sinh viên có sẵn (đi/animation do world_update.gd lo, file này chỉ chỉ hướng đi)
#   game.solids + game.blocked() / move_entity()  va chạm có sẵn
#   npc_nhan_vat.gd  2 thầy, bác bảo vệ, bác giữ xe, cô lao công
# Thời tiết (weather_system.gd) báo độ tối qua game.get_meta("weather_light"); file này chỉ ĐỌC giá trị đó.

enum S { WANDER, WAIT_LEAVE, GO_LEAVE, AWAY, WAIT_ENTER, GO_ENTER, GO_HOME, GO_POST, POST, PATROL }

# ---------- Giờ giấc (đơn vị: giờ) ----------
const DAY_START := 5.0          # 05:00 bắt đầu sáng dần và tắt đèn
const FULL_FROM := 10.0         # 10:00 - 13:00 sáng nhất
const FULL_TO := 13.0
const NIGHT_START := 18.0       # 18:00 bắt đầu đêm và bật đèn

# ---------- Ánh sáng ----------
const NIGHT_COLOR := Color(0.24, 0.27, 0.45)   # màu "tối" của thế giới (trắng = sáng nhất)
const LAMP_COLOR := Color(1.0, 0.86, 0.55)
const LAMP_HEAD := Vector2(0, -24)             # đầu đèn so với chân cột (khớp draw_lamp trong scenery.gd)
const LAMP_RADIUS := 78.0                      # bán kính vùng sáng (px)
const LAMP_FADE := 1.5                         # giây để đèn sáng dần / tắt dần

# ---------- Người ra/vào cổng ----------
const CELL := 16.0                             # ô lưới tìm đường
const GATE_OUT := Vector2(744, 984)            # điểm ngay ngoài cổng trường
const GATE_POST := Vector2(716, 944)           # chỗ bác giữ xe đứng ban đêm (cạnh cổng)
const LEAVE_SPREAD := 14.0                     # mỗi người rời đi sau 0..14 giây thật (không ra cùng lúc)
const ENTER_SPREAD := 14.0
const PATROL_PAUSE := 2.5                      # bác bảo vệ dừng lại quan sát ở mỗi điểm (giây)
const LEAVER_ROLES := ["thay_ltc", "thay_ldk", "lao_cong"]
const ENTER_ZONES := [Rect2(150, 470, 1300, 100), Rect2(840, 320, 176, 200)]   # giống chỗ sinh viên xuất hiện lúc đầu
const PATROL_POINTS := [Vector2(760, 940), Vector2(740, 610), Vector2(300, 610), Vector2(300, 530), Vector2(620, 530),
	Vector2(900, 560), Vector2(1400, 530), Vector2(1200, 610), Vector2(740, 610), Vector2(1000, 880)]

var _mod: CanvasModulate
var _lights: Array = []
var _lamp_level := 0.0
var _night := false

var _astar: AStarGrid2D
var _cols := 0
var _rows := 0
var _agents: Array = []
var _npcf: Node = null
var _agents_ready := false

# Độ sáng của ngày theo giờ: 0 = tối nhất, 1 = sáng nhất
static func brightness_at(h: float) -> float:
	if h >= DAY_START and h < FULL_FROM:
		return smoothstep(DAY_START, FULL_FROM, h)
	if h >= FULL_FROM and h < FULL_TO:
		return 1.0
	if h >= FULL_TO and h < NIGHT_START:
		return 1.0 - smoothstep(FULL_TO, NIGHT_START, h)
	return 0.0

static func is_night_hour(h: float) -> bool:
	return h >= NIGHT_START or h < DAY_START

func _ready() -> void:
	_mod = CanvasModulate.new()
	add_child(_mod)
	var tex := _make_light_texture()
	for l in game.lamps:
		var pl := PointLight2D.new()
		pl.texture = tex
		pl.color = LAMP_COLOR
		pl.energy = 0.0
		pl.texture_scale = LAMP_RADIUS * 2.0 / 128.0
		pl.position = l + LAMP_HEAD
		pl.visible = false
		add_child(pl)
		_lights.append(pl)
	_build_grid()
	_night = is_night_hour(game.game_min / 60.0)
	_lamp_level = 1.0 if _night else 0.0
	_update_light(game.game_min / 60.0, 0.0)

func _process(delta: float) -> void:
	var h: float = game.game_min / 60.0
	_update_light(h, delta)
	if not _agents_ready:
		_setup_agents()   # đợi tới khung hình đầu tiên để mọi feature (nhất là npc_nhan_vat.gd) đã sẵn sàng
	var night := is_night_hour(h)
	if night != _night:
		_night = night
		if night:
			_on_night(false)
		else:
			_on_day()
	_update_agents(delta)

# ======================= ÁNH SÁNG =======================

func _make_light_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

func _update_light(h: float, delta: float) -> void:
	var weather_light: float = game.get_meta("weather_light", 1.0)
	var c := NIGHT_COLOR.lerp(Color.WHITE, brightness_at(h))
	_mod.color = Color(c.r * weather_light, c.g * weather_light, c.b * weather_light, 1.0)
	game.set_meta("ambient_brightness", (c.r + c.g + c.b) / 3.0 * weather_light)   # weather_system.gd dùng để làm tối hạt mưa
	game.tint.color = Color(1, 1, 1, 0)   # lớp màu cũ (sáng 7h-17h) tắt đi, chu kỳ mới đã lo toàn bộ ánh sáng
	var target := 1.0 if is_night_hour(h) else 0.0
	_lamp_level = move_toward(_lamp_level, target, delta / LAMP_FADE)
	for pl in _lights:
		pl.visible = _lamp_level > 0.01
		pl.energy = _lamp_level * 1.1

# ======================= LƯỚI TÌM ĐƯỜNG (dùng va chạm có sẵn của game) =======================

func _build_grid() -> void:
	_cols = int(game.WORLD.x / CELL)
	_rows = int(game.WORLD.y / CELL)
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, _cols, _rows)
	_astar.cell_size = Vector2(CELL, CELL)
	_astar.offset = Vector2(CELL / 2.0, CELL / 2.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	# viền thế giới: giống điều kiện đầu của game.blocked()
	for cx in _cols:
		for cy in _rows:
			var p := Vector2(cx * CELL + CELL / 2.0, cy * CELL + CELL / 2.0)
			if p.x < 8.0 or p.x > game.WORLD.x - 8.0 or p.y < 22.0 or p.y > game.WORLD.y - 6.0:
				_astar.set_point_solid(Vector2i(cx, cy), true)
	# vật cản: chân nhân vật là hộp 8x4 nên mỗi vật cản "phình" ra 4 px (giống game.blocked())
	for s in game.solids:
		var x0 := int(floorf((s.position.x - 4.5 - CELL / 2.0) / CELL))
		var x1 := int(ceilf((s.end.x + 4.5 - CELL / 2.0) / CELL))
		var y0 := int(floorf((s.position.y - 0.5 - CELL / 2.0) / CELL))
		var y1 := int(ceilf((s.end.y + 4.5 - CELL / 2.0) / CELL))
		for cx in range(maxi(x0, 0), mini(x1, _cols - 1) + 1):
			for cy in range(maxi(y0, 0), mini(y1, _rows - 1) + 1):
				var p := Vector2(cx * CELL + CELL / 2.0, cy * CELL + CELL / 2.0)
				if p.x > s.position.x - 4.5 and p.x < s.end.x + 4.5 and p.y > s.position.y - 0.5 and p.y < s.end.y + 4.5:
					_astar.set_point_solid(Vector2i(cx, cy), true)

# Ô trống gần nhất với 1 điểm
func _free_cell(p: Vector2) -> Vector2i:
	var c := Vector2i(clampi(int(p.x / CELL), 0, _cols - 1), clampi(int(p.y / CELL), 0, _rows - 1))
	if not _astar.is_point_solid(c):
		return c
	for r in range(1, 14):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := c + Vector2i(dx, dy)
				if _astar.is_in_boundsv(q) and not _astar.is_point_solid(q):
					return q
	return c

func _cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * CELL + CELL / 2.0, c.y * CELL + CELL / 2.0)

func _find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return _astar.get_point_path(_free_cell(from), _free_cell(to))

# ======================= NGƯỜI RA / VÀO TRƯỜNG =======================

func _setup_agents() -> void:
	_agents_ready = true
	_agents.clear()
	for n in game.npcs:
		if not n.has("role"):
			_agents.append(_new_agent(n, "leaver"))
	for f in game.features:
		if f.has_method("role_npc_near"):
			_npcf = f
	if _npcf != null:
		for n in _npcf._npcs:
			var kind: String = "leaver" if n.role in LEAVER_ROLES else ("guard" if n.role == "bao_ve" else "attendant")
			_agents.append(_new_agent(n, kind))
	if _night:
		_on_night(true)

func _new_agent(n: Dictionary, kind: String) -> Dictionary:
	return {"n": n, "kind": kind, "state": S.WANDER, "wait": 0.0, "path": PackedVector2Array(), "pi": 0,
		"pause": 0.0, "pp": -1, "last": n.pos, "stuck": 0.0}

func _named(a: Dictionary) -> bool:
	return a.n.has("role")

# Bắt đầu đêm: sinh viên + thầy + lao công chuẩn bị ra về; bác bảo vệ đi tuần; bác giữ xe ra đứng ở cổng
func _on_night(instant: bool) -> void:
	for a in _agents:
		match a.kind:
			"leaver":
				if a.state != S.AWAY:
					a.state = S.WAIT_LEAVE
					a.wait = 0.0 if instant else randf() * LEAVE_SPREAD
					if instant:
						_vanish(a)
			"guard":
				a.state = S.PATROL
				a.path = PackedVector2Array()
				a.pp = -1
				a.pause = 0.0
				a.n["sched"] = true
			"attendant":
				if instant:
					a.n.pos = GATE_POST
					_hold(a)
					a.state = S.POST
					a.n["sched"] = true
				elif _goto(a, GATE_POST):
					a.state = S.GO_POST
				else:
					a.state = S.POST

# Bắt đầu ngày: người đã ra về lần lượt đi vào; người chưa kịp ra thì ở lại; bác bảo vệ, bác giữ xe về chỗ cũ
func _on_day() -> void:
	for a in _agents:
		match a.kind:
			"leaver":
				if a.state == S.AWAY:
					a.state = S.WAIT_ENTER
					a.wait = randf() * ENTER_SPREAD
				else:
					_release(a)
			_:
				if _goto(a, a.n.home):
					a.state = S.GO_HOME
				else:
					_release(a)

func _update_agents(delta: float) -> void:
	for a in _agents:
		match a.state:
			S.WAIT_LEAVE:
				a.wait -= delta
				if a.wait <= 0.0:
					if _goto(a, GATE_OUT):
						a.state = S.GO_LEAVE
					else:
						_vanish(a)
			S.GO_LEAVE:
				if _follow(a, delta):
					_vanish(a)
			S.WAIT_ENTER:
				a.wait -= delta
				if a.wait <= 0.0:
					_begin_enter(a)
			S.GO_ENTER, S.GO_HOME:
				if _follow(a, delta):
					_release(a)
			S.GO_POST:
				if _follow(a, delta):
					a.state = S.POST
			S.POST:
				_hold(a)
			S.PATROL:
				_patrol(a, delta)

# Bác bảo vệ đi hết vòng các điểm tuần tra, dừng lại vài giây ở mỗi điểm
func _patrol(a: Dictionary, delta: float) -> void:
	if a.pause > 0.0:
		a.pause -= delta
		_hold(a)
		return
	if a.pi >= a.path.size():
		for i in PATROL_POINTS.size():
			a.pp = (a.pp + 1) % PATROL_POINTS.size()
			if _goto(a, PATROL_POINTS[a.pp]):
				break
	if _follow(a, delta):
		a.pause = PATROL_PAUSE
		a.path = PackedVector2Array()
		a.pi = 0

func _begin_enter(a: Dictionary) -> void:
	var n: Dictionary = a.n
	n.pos = GATE_OUT
	n.dir = Vector2.ZERO
	var dest: Vector2 = n.home if _named(a) else _random_spot()
	if _named(a):
		n.hidden = false
	elif not game.npcs.any(func(o): return is_same(o, n)):
		game.npcs.append(n)
	if _goto(a, dest):
		a.state = S.GO_ENTER
	else:
		n.pos = dest
		_release(a)

func _random_spot() -> Vector2:
	for i in 40:
		var r: Rect2 = ENTER_ZONES[randi() % ENTER_ZONES.size()]
		var p := Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
		var c := Vector2i(clampi(int(p.x / CELL), 0, _cols - 1), clampi(int(p.y / CELL), 0, _rows - 1))
		if not _astar.is_point_solid(c):
			return _cell_center(c)
	return Vector2(480, 520)

# Ra khỏi trường: ẩn thầy/cô, gỡ sinh viên khỏi danh sách game.npcs (không còn được vẽ, không còn đi)
func _vanish(a: Dictionary) -> void:
	var n: Dictionary = a.n
	a.state = S.AWAY
	n.dir = Vector2.ZERO
	n.pos = GATE_OUT
	if _named(a):
		n.hidden = true
	else:
		for i in game.npcs.size():
			if is_same(game.npcs[i], n):
				game.npcs.remove_at(i)
				break

# Trả nhân vật về hành vi cũ (đi lang thang quanh chỗ đứng / ngẫu nhiên)
func _release(a: Dictionary) -> void:
	var n: Dictionary = a.n
	a.state = S.WANDER
	a.path = PackedVector2Array()
	a.pi = 0
	n.dir = Vector2.ZERO
	if _named(a):
		n["sched"] = false
		n.timer = 0.5
	else:
		n.timer = 0.0

func _goto(a: Dictionary, target: Vector2) -> bool:
	var p := _find_path(a.n.pos, target)
	if p.is_empty():
		return false
	a.path = p
	a.pi = 0
	a.stuck = 0.0
	a.last = a.n.pos
	if _named(a):
		a.n["sched"] = true
	return true

func _hold(a: Dictionary) -> void:
	a.n.dir = Vector2.ZERO
	if not _named(a):
		a.n.timer = 2.0   # giữ cho world_update.gd không tự đổi hướng sinh viên

# Đi theo đường đã tìm, trả về true khi tới nơi. Việc di chuyển/animation do game đảm nhận (dir -> move_entity).
func _follow(a: Dictionary, delta: float) -> bool:
	var n: Dictionary = a.n
	while a.pi < a.path.size() and (a.path[a.pi] - n.pos).length() < 3.0:
		a.pi += 1
	if a.pi >= a.path.size():
		_hold(a)
		return true
	var target: Vector2 = a.path[a.pi]
	var d: Vector2 = target - n.pos
	if absf(d.x) >= absf(d.y):
		n.dir = Vector2(signf(d.x), 0.0)
	else:
		n.dir = Vector2(0.0, signf(d.y))
	if not _named(a):
		n.timer = 2.0
	# kẹt (không nhích được trong ~1 giây, trừ lúc đang nói chuyện) thì nhảy tới điểm kế tiếp
	if n.get("talk", 0.0) <= 0.0:
		a.stuck += delta
		if a.stuck >= 1.0:
			if n.pos.distance_to(a.last) < 1.0:
				n.pos = target
			a.last = n.pos
			a.stuck = 0.0
	return false
