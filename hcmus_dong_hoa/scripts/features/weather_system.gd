extends "res://scripts/features/feature.gd"
# HỆ THỐNG THỜI TIẾT: 4 loại xuất hiện ngẫu nhiên - Nắng, Nhiều mây, Mưa, Bão.
#
#   Nắng      : sáng bình thường. Mây nhỏ/lớn ngẫu nhiên bay ngang kèm bóng đổ. Kéo dài tới khi có thời tiết khác xen vào.
#   Nhiều mây : mây lớn che nắng, đứng yên hoặc trôi rất chậm, bóng đổ rõ. Thời gian ngẫu nhiên.
#   Mưa       : tối hơn, mây đen, hạt mưa xanh. Thời gian ngẫu nhiên.
#   Bão       : mưa lớn, mây to và đen hơn, hạt mưa dày và nhanh hơn, có sấm chớp. Kéo dài. Cứ 4 ngày mưa thì có 1 ngày bão.
#
# Dùng lại của game: game.game_min / game.day (giờ và ngày), game.view (khung nhìn), game.rc() (vẽ khối pixel),
#   draw_front_layer() (vẽ lên thế giới, như mọi feature), game.audio (nếu có file assets/audio/thunder.*).
# Độ tối do thời tiết gửi cho day_night.gd qua game.set_meta("weather_light", ...) (1 = bình thường).
# Gọi thử: set_weather(W.STORMY) từ code khác (vd game.features[i].set_weather(...)); phần còn lại tự chạy.

enum W { SUNNY, CLOUDY, RAINY, STORMY }

const WEATHER_NAMES := {W.SUNNY: "Nắng", W.CLOUDY: "Nhiều mây", W.RAINY: "Mưa", W.STORMY: "Bão"}

# Hồ sơ từng loại: độ sáng, số mây, tốc độ gió (px/giây), cỡ mây, màu/độ đậm mây, độ đậm bóng, cường độ mưa thường, mưa bão
const PROFILE := {
	W.SUNNY:  {"light": 1.00, "clouds": 3,  "wind": 12.0, "size": [1.6, 2.2], "col": Color(1.00, 1.00, 1.00), "alpha": 0.55, "shadow": 0.16, "rain": 0.0, "storm": 0.0},
	W.CLOUDY: {"light": 0.80, "clouds": 9,  "wind": 1.5,  "size": [2.2, 3.2], "col": Color(0.82, 0.84, 0.88), "alpha": 0.60, "shadow": 0.24, "rain": 0.0, "storm": 0.0},
	W.RAINY:  {"light": 0.66, "clouds": 7,  "wind": 7.0,  "size": [1.8, 2.6], "col": Color(0.46, 0.49, 0.56), "alpha": 0.62, "shadow": 0.26, "rain": 1.0, "storm": 0.0},
	W.STORMY: {"light": 0.48, "clouds": 11, "wind": 18.0, "size": [2.4, 3.4], "col": Color(0.24, 0.26, 0.32), "alpha": 0.72, "shadow": 0.30, "rain": 0.0, "storm": 1.0},
}
# Thời gian kéo dài (phút trong game; 1 ngày game = 1440 phút). Nắng không có thời gian: nắng tới khi bị thời tiết khác xen vào.
const DURATION := {W.CLOUDY: [180.0, 420.0], W.RAINY: [120.0, 360.0], W.STORMY: [600.0, 900.0]}

const SUNNY_EVENT_CHANCE_PER_HOUR := 0.25   # mỗi giờ game, khi đang nắng, có 25% khả năng chuyển sang nhiều mây hoặc mưa
const RAINY_DAYS_PER_STORM := 4             # cứ 4 ngày mưa thì có 1 ngày bão
const STORM_HOUR := 6.0                     # ngày bão bắt đầu lúc 06:00
const BLEND_RATE := 0.6                     # tốc độ chuyển mượt giữa các loại thời tiết
const SHADOW_OFFSET := Vector2(30, 26)      # bóng đổ lệch so với mây (hướng nắng)

var weather: int = W.SUNNY
var rainy_days := 0            # số ngày mưa đã đếm từ lần bão trước
var storm_due := false         # đã đủ 4 ngày mưa, đang chờ ngày bão
var storm_day := -1            # ngày (game.day) sẽ có bão

var _left := 0.0               # phút game còn lại của thời tiết hiện tại (không dùng cho nắng)
var _roll_t := 0.0
var _last_rain_day := -1

# giá trị đang hiển thị (tiến dần về hồ sơ của thời tiết hiện tại)
var _light := 1.0
var _rain := 0.0
var _storm := 0.0
var _wind := 12.0
var _alpha := 0.55
var _shadow := 0.16
var _col := Color.WHITE

var clouds: Array = []
var _spawn_t := 0.0
var _trim_t := 0.0

var _rain_fx: CPUParticles2D
var _storm_fx: CPUParticles2D
var _flash_rect: ColorRect
var _flash := 0.0
var _events: Array = []
var _bolt_t := 6.0
var _thunder_player: AudioStreamPlayer
var _thunder_stream: AudioStreamWAV

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4   # dưới lớp ánh sáng cũ (5) và HUD (6+)
	add_child(layer)
	var drop := _make_drop_texture(7)
	_rain_fx = _make_emitter(150, 1.0, 300.0, Vector2(0.22, 1.0), drop, Color(0.5, 0.7, 1.0, 0.9))
	var big_drop := _make_drop_texture(11)
	_storm_fx = _make_emitter(480, 0.6, 520.0, Vector2(0.45, 1.0), big_drop, Color(0.45, 0.65, 1.0, 0.95))
	layer.add_child(_rain_fx)
	layer.add_child(_storm_fx)
	_flash_rect = ColorRect.new()
	_flash_rect.size = Vector2(480, 270)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash_rect)
	_thunder_player = AudioStreamPlayer.new()
	add_child(_thunder_player)
	_snap_to_profile()
	for i in PROFILE[weather].clouds:
		_spawn_cloud(false, 1.0)

# ======================= ĐIỀU KHIỂN THỜI TIẾT =======================

# Đổi thời tiết ngay (cũng dùng để thử). minutes < 0: lấy thời gian ngẫu nhiên theo DURATION.
func set_weather(w: int, minutes: float = -1.0) -> void:
	weather = w
	if w == W.SUNNY:
		_left = 0.0
	elif minutes >= 0.0:
		_left = minutes
	else:
		var r: Array = DURATION[w]
		_left = randf_range(r[0], r[1])
	_roll_t = 0.0
	_bolt_t = randf_range(1.0, 4.0)

func weather_name() -> String:
	return WEATHER_NAMES[weather]

func _process(delta: float) -> void:
	var ts: float = game.TIME_SCALE
	var minutes := delta * ts
	# --- hết thời gian -> trở về nắng ---
	if weather != W.SUNNY:
		_left -= minutes
		if _left <= 0.0:
			set_weather(W.SUNNY)
	# --- ngày bão theo quy tắc 4 ngày mưa ---
	if weather == W.RAINY and game.day != _last_rain_day:
		_last_rain_day = game.day
		rainy_days += 1
		if rainy_days >= RAINY_DAYS_PER_STORM:
			rainy_days = 0
			storm_due = true
			storm_day = game.day + 1
	if storm_due and weather != W.STORMY and (game.day > storm_day or (game.day == storm_day and game.game_min / 60.0 >= STORM_HOUR)):
		storm_due = false
		set_weather(W.STORMY)
	# --- đang nắng: thỉnh thoảng có thời tiết khác xen vào (bão chỉ đến theo quy tắc trên) ---
	if weather == W.SUNNY:
		_roll_t += delta
		if _roll_t >= 5.0:
			_roll_t = 0.0
			if randf() < SUNNY_EVENT_CHANCE_PER_HOUR * (5.0 * ts / 60.0):
				set_weather(W.CLOUDY if randf() < 0.5 else W.RAINY)
	_blend(delta)
	_update_clouds(delta)
	_update_rain()
	_update_lightning(delta)
	game.set_meta("weather_light", _light)

func _snap_to_profile() -> void:
	var p: Dictionary = PROFILE[weather]
	_light = p.light
	_rain = p.rain
	_storm = p.storm
	_wind = p.wind
	_alpha = p.alpha
	_shadow = p.shadow
	_col = p.col

# Chuyển mượt các giá trị hiển thị về hồ sơ của thời tiết hiện tại
func _blend(delta: float) -> void:
	var p: Dictionary = PROFILE[weather]
	var k := 1.0 - exp(-delta * BLEND_RATE)
	_light = lerpf(_light, p.light, k)
	_rain = lerpf(_rain, p.rain, k)
	_storm = lerpf(_storm, p.storm, k)
	_wind = lerpf(_wind, p.wind, k)
	_alpha = lerpf(_alpha, p.alpha, k)
	_shadow = lerpf(_shadow, p.shadow, k)
	_col = _col.lerp(p.col, k)

# ======================= MÂY VÀ BÓNG ĐỔ =======================

# Mây pixel: các hàng chữ nhật xếp liền nhau (không chồng lên nhau nên vẫn đẹp khi mờ trong suốt)
func _make_rows() -> Array:
	var rows: Array = []
	var n := randi_range(4, 6)
	var y := 0.0
	var h := 7.0
	for i in n:
		var w := 90.0 * (0.4 + 0.6 * sin(PI * (i + 0.5) / n)) * randf_range(0.85, 1.0)
		rows.append(Rect2(-w / 2.0 + randf_range(-6.0, 6.0), y, w, h))
		y += h
	return rows

func _spawn_cloud(at_edge: bool, fade: float) -> void:
	var p: Dictionary = PROFILE[weather]
	var s: float
	if weather == W.SUNNY and randf() < 0.5:
		s = randf_range(0.6, 0.95)   # mây nhỏ
	else:
		s = randf_range(p.size[0], p.size[1])   # mây lớn
	var pos := Vector2(randf_range(-100.0, game.WORLD.x + 100.0), randf_range(-40.0, game.WORLD.y + 40.0))
	if at_edge:
		pos.x = -170.0 * maxf(s, 1.0)
	clouds.append({"pos": pos, "s": s, "k": randf_range(0.7, 1.3), "a": fade, "dying": false, "rows": _make_rows()})

func _update_clouds(delta: float) -> void:
	var target: int = PROFILE[weather].clouds
	for c in clouds:
		c.pos += Vector2(1.0, 0.1) * _wind * c.k * delta
		c.a = clampf(c.a + (-0.4 if c.dying else 0.4) * delta, 0.0, 1.0)
	clouds = clouds.filter(func(c): return not (c.dying and c.a <= 0.0) and c.pos.x < game.WORLD.x + 360.0 and c.pos.y < game.WORLD.y + 300.0)
	var alive := 0
	for c in clouds:
		if not c.dying:
			alive += 1
	# thiếu mây -> sinh thêm (gió mạnh: mây bay vào từ mép trái, gió yếu: hiện dần tại chỗ)
	_spawn_t -= delta
	if alive < target and _spawn_t <= 0.0:
		_spawn_cloud(_wind > 5.0, 0.0)
		_spawn_t = 0.15 if alive < target / 2 else 0.8
	# thừa mây -> cho mây cũ nhất mờ dần rồi biến mất
	_trim_t -= delta
	if alive > target and _trim_t <= 0.0:
		for c in clouds:
			if not c.dying:
				c.dying = true
				break
		_trim_t = 0.6

# Vẽ lên thế giới (sau người/cây): bóng đổ trước, rồi thân mây
func draw_front_layer() -> void:
	if clouds.is_empty():
		return
	var view: Rect2 = game.view.grow(280.0)
	for c in clouds:
		if view.has_point(c.pos):
			_draw_cloud(c, true)
	for c in clouds:
		if view.has_point(c.pos):
			_draw_cloud(c, false)

func _draw_cloud(c: Dictionary, as_shadow: bool) -> void:
	var s: float = c.s
	var off := Vector2.ZERO
	var base: Color
	if as_shadow:
		off = SHADOW_OFFSET * (0.6 + 0.4 * minf(s, 2.5))
		base = Color(0.04, 0.06, 0.14, _shadow * c.a)
	else:
		base = Color(_col.r, _col.g, _col.b, _alpha * c.a)
	var rows: Array = c.rows
	for i in rows.size():
		var r: Rect2 = rows[i]
		var x0 := floorf(c.pos.x + off.x + r.position.x * s)
		var x1 := floorf(c.pos.x + off.x + (r.position.x + r.size.x) * s)
		var y0 := floorf(c.pos.y + off.y + r.position.y * s * 0.8)
		var y1 := floorf(c.pos.y + off.y + (r.position.y + r.size.y) * s * 0.8)
		var col := base
		if not as_shadow:
			col = base.lightened(0.14 * (1.0 - float(i) / maxf(rows.size() - 1.0, 1.0))) if i < rows.size() - 1 else base.darkened(0.1)
		game.rc(x0, y0, x1 - x0, y1 - y0, col)

# ======================= MƯA (CPUParticles2D) =======================

func _make_drop_texture(length: int) -> Texture2D:
	var img := Image.create(1, length, false, Image.FORMAT_RGBA8)
	for y in length:
		img.set_pixel(0, y, Color(1, 1, 1, 0.25 + 0.75 * float(y) / (length - 1)))
	return ImageTexture.create_from_image(img)

func _make_emitter(amount: int, life: float, speed: float, dir: Vector2, tex: Texture2D, col: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.texture = tex
	p.color = col
	p.position = Vector2(220, -14)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(330, 4)
	p.direction = dir
	p.spread = 2.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.92
	p.initial_velocity_max = speed * 1.08
	p.particle_flag_align_y = true
	p.emitting = false
	return p

func _update_rain() -> void:
	# hạt mưa không bị CanvasModulate làm tối, nên tự nhân với độ sáng của ngày/đêm
	var b: float = clampf(float(game.get_meta("ambient_brightness", 1.0)) * 1.4, 0.35, 1.0)
	var tint := Color(b, b, b, 1.0)
	_rain_fx.emitting = _rain > 0.02
	_rain_fx.modulate = Color(tint.r, tint.g, tint.b, clampf(_rain, 0.0, 1.0))
	_storm_fx.emitting = _storm > 0.02
	_storm_fx.modulate = Color(tint.r, tint.g, tint.b, clampf(_storm, 0.0, 1.0))

# ======================= SẤM CHỚP (chỉ khi bão) =======================

func _update_lightning(delta: float) -> void:
	if _storm > 0.6 and weather == W.STORMY:
		_bolt_t -= delta
		if _bolt_t <= 0.0:
			_bolt_t = randf_range(4.0, 11.0)
			var thunder_delay := randf_range(0.4, 1.6)
			_events.append({"t": 0.0, "k": "flash", "v": 0.9})
			_events.append({"t": 0.16, "k": "flash", "v": 0.6})
			_events.append({"t": thunder_delay, "k": "thunder", "v": thunder_delay})
	for e in _events:
		e.t -= delta
		if e.t <= 0.0:
			if e.k == "flash":
				_flash = e.v
			else:
				_play_thunder(e.v)
	_events = _events.filter(func(e): return e.t > 0.0)
	_flash = move_toward(_flash, 0.0, delta * 3.2)
	_flash_rect.color = Color(0.92, 0.95, 1.0, _flash * 0.55)

func _play_thunder(delay: float) -> void:
	# có file assets/audio/thunder.(ogg|wav|mp3) thì dùng AudioManager có sẵn, không thì tự tạo tiếng sấm
	for ext in AudioManagerExts:
		if ResourceLoader.exists("res://assets/audio/thunder." + ext):
			game.audio.play_sfx("thunder")
			return
	if _thunder_stream == null:
		_thunder_stream = _make_thunder()
	_thunder_player.stream = _thunder_stream
	_thunder_player.volume_db = lerpf(-3.0, -14.0, clampf(delay / 1.6, 0.0, 1.0))
	_thunder_player.play()

const AudioManagerExts := ["ogg", "wav", "mp3"]

# Tiếng sấm tự tạo: nhiễu trầm giảm dần (không cần file âm thanh)
func _make_thunder() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 2.8)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var lp := 0.0
	for i in count:
		var t := float(i) / rate
		var env := minf(t / 0.08, 1.0) * exp(-t * 1.5) * (0.65 + 0.35 * sin(t * 9.0))
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.06
		data.encode_s16(i * 2, int(clampf(lp * env * 5.0, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
