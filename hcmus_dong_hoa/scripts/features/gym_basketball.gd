extends "res://scripts/features/feature.gd"
# LỚP THỂ DỤC - minigame bóng rổ.
# Bấm E vào Nhà Thể Dục -> hiện bảng hướng dẫn + luật cộng/trừ GPA -> bấm E mở game ném bóng.
# Canh HƯỚNG: W/S (hoặc mũi tên lên/xuống) chỉnh góc ném.
# Canh LỰC: thanh lực tự chạy qua lại, bấm E (hoặc Space) đúng lúc để chốt lực và ném.
# Ném 5 quả, vào >= 3 quả thì ĐẠT (+GPA), không thì RỚT (-GPA).
#
# Tự kích hoạt: _process() thấy building_doors.gd đang ở trong phòng kind = "gym" thì gọi start_class().
# Không cần sửa building_doors.gd. Màn hình game là 480x270 nên mọi tọa độ ở đây theo khung đó.

# ---------- Cấu hình (chỉnh ở đây) ----------
const SHOTS_TOTAL := 5          # số quả ném
const SHOTS_NEEDED := 3         # số quả vào để đạt
const GPA_REWARD := 0.05        # đạt: cộng GPA
const GPA_PENALTY := 0.10       # rớt: trừ GPA
const ONCE_PER_DAY := true      # mỗi ngày chỉ học 1 lần (khi thử game có thể đặt false)

const GRAVITY := 340.0
const POWER_MIN := 190.0        # tốc độ ném khi lực = 0
const POWER_MAX := 450.0        # tốc độ ném khi lực = 1
const POWER_SPEED := 1.1        # tốc độ chạy của thanh lực
const ANGLE_MIN := 20.0
const ANGLE_MAX := 80.0
const ANGLE_STEP := 35.0        # độ/giây khi giữ W/S

const VIEW := Vector2(480, 270)
const FLOOR_Y := 226.0
const BALL_R := 6.0
const RIM_Y := 125.0
const RIM_HALF := 14.0          # nửa chiều rộng vành rổ
const HOOP_X_MIN := 285.0       # mỗi quả, rổ ở xa gần khác nhau
const HOOP_X_MAX := 350.0

# Nhân vật: cùng kiểu người chơi trong phòng (building_doors.gd), phóng to K lần
const CHAR_X := 60.0
const K := 3.0
const BALL_START := Vector2(98, 172)

enum Phase { INTRO, AIM, FLY, RESULT_SHOT, SUMMARY, NOTICE }

var font: Font
var layer: CanvasLayer
var ctl: Control
var phase: int = Phase.INTRO
var shots_done := 0
var made := 0
var angle := 55.0
var power := 0.0
var power_dir := 1.0
var hoop_x := 320.0
var ball_pos := BALL_START
var ball_vel := Vector2.ZERO
var last_made := false
var wait := 0.0
var passed := false
var last_class_day := -1
var msg := ""
var gpa_line := ""
var opened_frame := -1      # frame vừa mở, tránh phím E của cửa bị tính là "bắt đầu"
var was_in_gym := false
var doors_feature = null

func _ready() -> void:
	font = game.font
	layer = CanvasLayer.new()
	layer.layer = 50
	layer.visible = false
	add_child(layer)
	ctl = Control.new()
	ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctl.draw.connect(_on_ctl_draw)
	layer.add_child(ctl)

# ---------- Điểm vào ----------
func start_class() -> void:
	if active:
		return
	layer.visible = true
	begin()   # bật chế độ bận
	opened_frame = Engine.get_process_frames()
	ball_pos = BALL_START
	ball_vel = Vector2.ZERO
	if ONCE_PER_DAY and last_class_day == game.day:
		msg = "Hôm nay bạn đã học thể dục rồi. Mai quay lại nhé!"
		phase = Phase.NOTICE
		return
	last_class_day = game.day
	shots_done = 0
	made = 0
	msg = ""
	gpa_line = ""
	game.audio.play_sfx("whistle")
	phase = Phase.INTRO   # bảng hướng dẫn trước, bấm E mới ném

# Thấy người chơi vừa bấm E vào phòng "gym" của building_doors.gd thì mở lớp thể dục.
func _watch_gym_door() -> void:
	if doors_feature == null:
		for f in game.features:
			if f != self and f.get("current_room") != null and f.get("inside") != null:
				doors_feature = f
				break
	var in_gym := false
	if doors_feature != null and doors_feature.get("inside") == true:
		var room: Dictionary = doors_feature.get("current_room")
		in_gym = str(room.get("kind", "")) == "gym"
	if in_gym and not was_in_gym:
		start_class()
	was_in_gym = in_gym

func _new_shot() -> void:
	phase = Phase.AIM
	power = 0.0
	power_dir = 1.0
	hoop_x = randf_range(HOOP_X_MIN, HOOP_X_MAX)
	ball_pos = BALL_START
	ball_vel = Vector2.ZERO

# ---------- Vòng lặp ----------
func _process(delta: float) -> void:
	if not active:
		_watch_gym_door()
		return
	match phase:
		Phase.AIM:
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				angle = minf(angle + ANGLE_STEP * delta, ANGLE_MAX)
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				angle = maxf(angle - ANGLE_STEP * delta, ANGLE_MIN)
			power += power_dir * POWER_SPEED * delta   # lực tự chạy qua lại
			if power >= 1.0:
				power = 1.0
				power_dir = -1.0
			elif power <= 0.0:
				power = 0.0
				power_dir = 1.0
		Phase.FLY:
			_step_ball(delta)
		Phase.RESULT_SHOT:
			wait -= delta
			if wait <= 0.0:
				if shots_done >= SHOTS_TOTAL:
					_end_class()
				else:
					_new_shot()
	ctl.queue_redraw()

func _step_ball(delta: float) -> void:
	var prev := ball_pos
	ball_vel.y += GRAVITY * delta
	ball_pos += ball_vel * delta
	# Bảng rổ: bóng đập vào thì nảy ngược lại
	var board_x := hoop_x + RIM_HALF + 2.0
	if ball_vel.x > 0.0 and prev.x + BALL_R < board_x and ball_pos.x + BALL_R >= board_x \
			and ball_pos.y > RIM_Y - 40.0 and ball_pos.y < RIM_Y + 4.0:
		ball_vel.x = -ball_vel.x * 0.4
	# Vào rổ: bóng đi xuống và cắt vành rổ trong khoảng giữa hai mép
	if ball_vel.y > 0.0 and prev.y < RIM_Y and ball_pos.y >= RIM_Y:
		var t := (RIM_Y - prev.y) / (ball_pos.y - prev.y)
		var x_at := lerpf(prev.x, ball_pos.x, t)
		if absf(x_at - hoop_x) <= RIM_HALF - 3.0:
			_finish_shot(true)
			return
	if ball_pos.y > FLOOR_Y or ball_pos.x > VIEW.x + 20.0:
		_finish_shot(false)

func _finish_shot(ok: bool) -> void:
	last_made = ok
	shots_done += 1
	if ok:
		made += 1
		game.audio.play_sfx("swish")
	else:
		game.audio.play_sfx("miss")
	phase = Phase.RESULT_SHOT
	wait = 0.9

func _end_class() -> void:
	passed = made >= SHOTS_NEEDED
	var before: float = game.stats.gpa
	game.stats.set_gpa(before + (GPA_REWARD if passed else -GPA_PENALTY))   # set_gpa tự giới hạn 0.0 - 4.0
	var after: float = game.stats.gpa
	if passed:
		msg = "ĐẠT môn Thể dục! +%.2f GPA" % GPA_REWARD
	else:
		msg = "RỚT môn Thể dục... -%.2f GPA" % GPA_PENALTY
	gpa_line = "GPA: %.2f -> %.2f" % [before, after]
	phase = Phase.SUMMARY

# ---------- Phím ----------
func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()   # đang chơi thì không cho phím lọt xuống cửa/feature khác
	if Engine.get_process_frames() == opened_frame:
		return
	var k: int = event.physical_keycode
	var confirm := k == KEY_E or k == KEY_SPACE or k == KEY_ENTER
	match phase:
		Phase.INTRO:
			if confirm:
				_new_shot()
		Phase.AIM:
			if k == KEY_E or k == KEY_SPACE:
				_shoot()
		Phase.SUMMARY, Phase.NOTICE:
			if confirm or k == KEY_ESCAPE:
				_close()

func _shoot() -> void:
	var speed := lerpf(POWER_MIN, POWER_MAX, power)
	var a := deg_to_rad(angle)
	ball_vel = Vector2(cos(a), -sin(a)) * speed
	phase = Phase.FLY
	game.audio.play_sfx("throw")

func _close() -> void:
	layer.visible = false
	finish()

# ---------- Vẽ ----------
func _text(s: String, pos: Vector2, size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ctl.draw_string_outline(font, pos, s, align, width, size, 3, Color(0, 0, 0, 0.9))
	ctl.draw_string(font, pos, s, align, width, size, color)

func _on_ctl_draw() -> void:
	ctl.draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.09, 0.1, 0.16))
	ctl.draw_rect(Rect2(0, FLOOR_Y, VIEW.x, VIEW.y - FLOOR_Y), Color(0.72, 0.48, 0.25))   # sàn gỗ
	ctl.draw_rect(Rect2(0, FLOOR_Y - 2, VIEW.x, 3), Color(0.95, 0.9, 0.8))                # vạch sân
	_draw_hoop()
	_draw_thrower()
	ctl.draw_circle(ball_pos, BALL_R, Color(0.95, 0.5, 0.15))
	ctl.draw_arc(ball_pos, BALL_R, 0, TAU, 20, Color(0.2, 0.1, 0.05), 1.0)
	var playing: bool = phase == Phase.AIM or phase == Phase.FLY or phase == Phase.RESULT_SHOT
	if playing:
		_draw_hud()
	if phase == Phase.INTRO:
		_draw_intro()
	elif phase == Phase.SUMMARY:
		_draw_summary()
	elif phase == Phase.NOTICE:
		_draw_notice()

func _draw_hoop() -> void:
	var px := hoop_x + RIM_HALF + 8.0
	ctl.draw_rect(Rect2(px, RIM_Y - 40.0, 4, FLOOR_Y - RIM_Y + 40.0), Color(0.55, 0.55, 0.6))          # cột
	ctl.draw_rect(Rect2(hoop_x + RIM_HALF + 2.0, RIM_Y - 40.0, 3, 44), Color.WHITE)                    # bảng
	ctl.draw_line(Vector2(hoop_x - RIM_HALF, RIM_Y), Vector2(hoop_x + RIM_HALF, RIM_Y), Color(1, 0.4, 0.1), 2.5)
	for i in range(5):
		var x := lerpf(hoop_x - RIM_HALF, hoop_x + RIM_HALF, i / 4.0)
		var x2 := lerpf(hoop_x - RIM_HALF * 0.6, hoop_x + RIM_HALF * 0.6, i / 4.0)
		ctl.draw_line(Vector2(x, RIM_Y), Vector2(x2, RIM_Y + 15.0), Color(1, 1, 1, 0.8), 1.0)

# Nhân vật giống người chơi trong phòng (building_doors.gd -> _draw_room_player), phóng to K lần
func _draw_thrower() -> void:
	var px := CHAR_X
	var py := FLOOR_Y - 5.0 * K
	ctl.draw_circle(Vector2(px, py + 5.0 * K), 8.0 * K * 0.6, Color(0, 0, 0, 0.25))   # bóng đổ
	ctl.draw_rect(Rect2(px - 5.0 * K, py - 2.0 * K, 4.0 * K, 7.0 * K), Color("2b2f4a"))   # chân
	ctl.draw_rect(Rect2(px + 1.0 * K, py - 2.0 * K, 4.0 * K, 7.0 * K), Color("2b2f4a"))
	ctl.draw_rect(Rect2(px - 6.0 * K, py - 13.0 * K, 12.0 * K, 11.0 * K), Color("1b2f6e"))   # thân áo
	ctl.draw_rect(Rect2(px - 4.0 * K, py - 20.0 * K, 8.0 * K, 7.0 * K), Color("f1c27d"))     # mặt
	ctl.draw_rect(Rect2(px - 4.0 * K, py - 21.0 * K, 8.0 * K, 3.0 * K), Color("1b1b1b"))     # tóc
	# tay đưa ra giữ bóng
	var shoulder := Vector2(px + 5.0 * K, py - 11.0 * K)
	ctl.draw_line(shoulder, BALL_START + Vector2(-5, 3), Color("1b2f6e"), 6.0)
	ctl.draw_circle(BALL_START + Vector2(-5, 3), 3.5, Color("f1c27d"))
	# mũi tên hướng ném
	if phase == Phase.AIM:
		var a := deg_to_rad(angle)
		var dir := Vector2(cos(a), -sin(a))
		ctl.draw_line(BALL_START, BALL_START + dir * 38.0, Color(1, 1, 0.4), 1.5)
		ctl.draw_circle(BALL_START + dir * 38.0, 2.5, Color(1, 1, 0.4))

func _draw_hud() -> void:
	_text("LỚP THỂ DỤC - BÓNG RỔ", Vector2(10, 18), 11, Color(1, 0.9, 0.4))
	_text("Ném %d/%d   Vào rổ: %d (cần %d)" % [mini(shots_done + 1, SHOTS_TOTAL), SHOTS_TOTAL, made, SHOTS_NEEDED],
		Vector2(10, 32), 8, Color.WHITE)
	_text("W/S: canh hướng    E: chốt lực và ném", Vector2(10, 44), 8, Color(0.85, 0.85, 0.9))
	# thanh lực (tự chạy)
	var bar := Rect2(36, 240, 150, 12)
	ctl.draw_rect(bar, Color(0.2, 0.2, 0.25))
	var col := Color(0.3, 0.9, 0.4).lerp(Color(0.95, 0.2, 0.2), power)
	ctl.draw_rect(Rect2(bar.position, Vector2(bar.size.x * power, bar.size.y)), col)
	ctl.draw_rect(bar, Color.WHITE, false, 1.0)
	_text("LỰC", Vector2(8, 250), 8, Color.WHITE)
	_text("Hướng: %d°" % int(angle), Vector2(200, 250), 8, Color.WHITE)
	if phase == Phase.RESULT_SHOT:
		var t := "VÀO RỔ!" if last_made else "Trượt rồi"
		_text(t, Vector2(0, 96), 20, Color(0.4, 1, 0.5) if last_made else Color(1, 0.55, 0.55), VIEW.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_intro() -> void:
	var r := Rect2(30, 14, 420, 236)
	ctl.draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	ctl.draw_rect(r, Color(0.08, 0.1, 0.2))
	ctl.draw_rect(r, Color(1, 0.9, 0.4), false, 2.0)
	_text("LỚP THỂ DỤC", Vector2(r.position.x, 40), 15, Color(1, 0.9, 0.4), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Thầy giáo: hôm nay kiểm tra ném bóng rổ!", Vector2(r.position.x, 58), 9, Color.WHITE, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var lines := [
		["CÁCH CHƠI", Color(0.6, 0.85, 1.0), true],
		["- Bạn ném %d quả. Bấm W/S (hoặc mũi tên lên/xuống) để canh hướng ném." % SHOTS_TOTAL, Color.WHITE, false],
		["- Thanh lực tự chạy qua lại. Bấm E (hoặc Space) đúng lúc để chốt lực và ném.", Color.WHITE, false],
		["- Mỗi quả, rổ nằm ở khoảng cách khác nhau nên phải canh lại.", Color.WHITE, false],
		["CƠ CHẾ GPA", Color(0.6, 0.85, 1.0), true],
		["- Vào rổ từ %d/%d quả trở lên: ĐẠT, cộng %.2f GPA." % [SHOTS_NEEDED, SHOTS_TOTAL, GPA_REWARD], Color(0.4, 1, 0.5), false],
		["- Vào rổ dưới %d quả: RỚT, trừ %.2f GPA." % [SHOTS_NEEDED, GPA_PENALTY], Color(1, 0.55, 0.55), false],
		["- Mỗi ngày chỉ học thể dục một lần." if ONCE_PER_DAY else "- Có thể học thể dục nhiều lần.", Color(0.85, 0.85, 0.9), false],
	]
	var y := 86.0
	for l in lines:
		var head: bool = l[2]
		_text(l[0], Vector2(r.position.x + 24, y), 10 if head else 8, l[1])
		y += 18.0 if head else 15.0
	_text("Nhấn E để bắt đầu", Vector2(r.position.x, 236), 11, Color(1, 0.9, 0.4), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_summary() -> void:
	var r := Rect2(90, 70, 300, 120)
	ctl.draw_rect(r, Color(0, 0, 0, 0.88))
	ctl.draw_rect(r, Color(1, 0.9, 0.4), false, 2.0)
	_text("Kết quả: %d/%d quả vào rổ" % [made, SHOTS_TOTAL], Vector2(r.position.x, 98), 11, Color.WHITE, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(msg, Vector2(r.position.x, 124), 12, Color(0.4, 1, 0.5) if passed else Color(1, 0.55, 0.55), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(gpa_line, Vector2(r.position.x, 144), 9, Color.WHITE, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Nhấn E để tiếp tục", Vector2(r.position.x, 174), 9, Color(0.85, 0.85, 0.9), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_notice() -> void:
	var r := Rect2(80, 90, 320, 80)
	ctl.draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.55))
	ctl.draw_rect(r, Color(0.08, 0.1, 0.2))
	ctl.draw_rect(r, Color(1, 0.9, 0.4), false, 2.0)
	_text(msg, Vector2(r.position.x, 125), 9, Color.WHITE, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Nhấn E để đóng", Vector2(r.position.x, 152), 8, Color(0.85, 0.85, 0.9), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
