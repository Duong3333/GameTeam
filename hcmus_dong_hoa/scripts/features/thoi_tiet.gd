extends "res://scripts/features/feature.gd"
# THỜI TIẾT: một số ngày game có mưa vào buổi sáng, mưa tới rồi tạnh dần.
# Mỗi ngày có 30% khả năng mưa; giờ bắt đầu và độ dài trận mưa cố định theo số ngày (cùng một ngày luôn giống nhau).
# Vẽ lên thế giới ngoài trời bằng draw_front_layer(): phủ màu xám xanh nhẹ và các vệt mưa; có tiếng mưa nhỏ
# (assets/audio/mua_roi.wav, thiếu file thì im lặng). Trong phòng/khi đang chơi một chức năng thì tiếng mưa nhỏ lại.
# Không đổi chỉ số hay cách chơi, chỉ là hiệu ứng.

const RAIN_CHANCE := 30            # % số ngày có mưa
const RAIN_START_MIN := 480        # trận mưa bắt đầu từ 08:00 tới 11:00
const RAIN_START_SPREAD := 180
const RAIN_LEN_MIN := 120          # kéo dài 2 tới 4 giờ game
const RAIN_LEN_SPREAD := 120
const FADE_MIN := 20.0             # phút game để mưa nặng hạt dần / tạnh dần
const DROPS := 90

var _intensity := 0.0              # 0 = không mưa, 1 = mưa đủ lớn
var _drops: Array = []             # {x, y, len, sp}: vị trí theo tỉ lệ 0..1 trong khung nhìn
var _player: AudioStreamPlayer

func _ready() -> void:
	for i in DROPS:
		_drops.append({"x": randf(), "y": randf(), "len": randf_range(5.0, 9.0), "sp": randf_range(0.9, 1.5)})
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var path := "res://assets/audio/mua_roi.wav"
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path) as AudioStream
		if s is AudioStreamWAV:
			var w := s as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * float(w.mix_rate))
		_player.stream = s

# Mức mưa mục tiêu (0..1) của giờ hiện tại, tính từ số ngày
func _target() -> float:
	var h: int = absi(hash("mua%d" % game.day))
	if h % 100 >= RAIN_CHANCE:
		return 0.0
	var start: float = RAIN_START_MIN + (h / 100) % RAIN_START_SPREAD
	var length: float = RAIN_LEN_MIN + (h / 1000) % RAIN_LEN_SPREAD
	var m: float = game.game_min
	if m < start or m > start + length:
		return 0.0
	return clampf(minf(m - start, start + length - m) / FADE_MIN, 0.0, 1.0)

func _process(delta: float) -> void:
	_intensity = move_toward(_intensity, _target(), delta * 0.4)
	if _player.stream == null:
		return
	if _intensity > 0.01:
		var quiet := game.is_busy()   # đang ở trong phòng / làm chức năng: tiếng mưa nhỏ lại
		_player.volume_db = linear_to_db(maxf(0.0001, _intensity * (0.06 if quiet else 0.25)))
		if not _player.playing:
			_player.play()
	elif _player.playing:
		_player.stop()

func draw_front_layer() -> void:
	if _intensity <= 0.01:
		return
	var v: Rect2 = game.view
	game.draw_rect(v, Color(0.18, 0.22, 0.32, 0.2 * _intensity))
	var n := int(DROPS * _intensity)
	var dt: float = get_process_delta_time()
	for i in n:
		var d: Dictionary = _drops[i]
		d.y = float(d.y) + dt * float(d.sp) * 1.6
		d.x = float(d.x) - dt * 0.25
		if d.y > 1.0:
			d.y = 0.0
			d.x = randf()
		if d.x < 0.0:
			d.x = 1.0
		var a := v.position + Vector2(float(d.x) * v.size.x, float(d.y) * v.size.y)
		game.draw_line(a, a + Vector2(-2.0, float(d.len)), Color(0.75, 0.86, 1.0, 0.55 * _intensity), 1.0)
