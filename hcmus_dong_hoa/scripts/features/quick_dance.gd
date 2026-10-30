extends "res://scripts/features/feature.gd"
# CHỨC NĂNG NHẢY NHANH
#
# Cách chơi: bấm số 5 để nhảy, bấm 5 lần nữa để dừng (hoặc tự dừng sau DURATION giây).
# Trong lúc nhảy người chơi đứng yên tại chỗ, nhân vật xoay hướng và nhún theo nhịp.
#
# Chỗ cần sửa:
#   - KEY_DANCE: phím nhảy. DURATION: nhảy tối đa bao nhiêu giây (0 = nhảy mãi tới khi bấm lại).
#   - Âm thanh (tùy chọn, bỏ file vào assets/audio/): dance_start (lúc bắt đầu), dance_loop (nhạc nền lúc nhảy).
#   - LƯU Ý: student_hud.gd cũng dùng phím 5 làm phím debug (tua 1 tuần). Feature này được xếp SAU student_hud
#     trong registry.gd nên nhận phím trước và chặn phím debug đó. Muốn chắc ăn thì đặt debug_keys := false trong student_hud.gd.

const KEY_DANCE := KEY_5
const DURATION := 6.0      # giây
const BEAT := 0.35         # cứ mỗi BEAT giây thì xoay sang hướng khác
const FACINGS := [0, 2, 1, 3]   # thứ tự hướng: xuống, trái, lên, phải (như game.facing)

var timer := 0.0
var beat_t := 0.0
var step := 0

func begin() -> void:
	super()                          # active = true -> người chơi đứng yên
	timer = 0.0
	beat_t = 0.0
	step = 0
	game.audio.play_sfx("dance_start")
	game.audio.play_music("dance_loop")

func finish() -> void:
	super()
	game.audio.stop_music()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != KEY_DANCE:
		return
	if active:
		finish()
	elif not game.is_busy():         # đang câu cá, mở sổ tay... thì không nhảy
		begin()
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not active:
		return
	timer += delta
	beat_t += delta
	game.anim += delta * 4.0         # chân nhân vật bước theo nhịp
	if beat_t >= BEAT:
		beat_t = 0.0
		step += 1
		game.facing = FACINGS[step % FACINGS.size()]
	if DURATION > 0.0 and timer >= DURATION:
		finish()

# Chữ "DANCE!" nhún nhẹ phía trên đầu
func draw_front_layer() -> void:
	if not active:
		return
	var p: Vector2 = game.player
	var t: float = game.clock
	game.ctext("DANCE!", p.x - 20.0, p.y - 40.0 + sin(t * 8.0) * 2.0, 40.0, 8, Color("ffd23f"))
