extends Node2D
## Bóng rổ ném rổ đối kháng: 5 lượt mỗi bên, mỗi lần vào rổ +2 điểm. Hòa thì đấu thêm lượt.
## Điều khiển: nhấn Space/Enter (ui_accept) khi vạch chạy nằm trong vùng xanh giữa thanh.
## Ưu đãi CLB Thể thao ("shot_window") làm vùng xanh rộng hơn.

signal finished(won: bool, my_score: int, opp_score: int)

const ROUNDS := 5
const HOOP := Vector2(380, 95)
const SHOOTER := Vector2(120, 205)
const FLIGHT_TIME := 0.9
const METER_RECT := Rect2(140, 245, 200, 8)

var round_i := 0
var turn := 0   # 0 = bạn, 1 = đối thủ
var score := [0, 0]
var meter := 0.0
var meter_dir := 1.0
var state := "aim"   # aim | flying | result | over
var timer := 0.0
var made := false
var msg := ""
var ball := SHOOTER
var zone_half := 0.07
var shot_window_multiplier := 1.0


func _ready() -> void:
	zone_half = 0.07 * shot_window_multiplier
	_start_turn()


func _start_turn() -> void:
	state = "aim"
	timer = 0.9   # độ trễ trước khi đối thủ ném
	meter = 0.0
	meter_dir = 1.0
	msg = ""
	ball = SHOOTER


func _process(delta: float) -> void:
	match state:
		"aim":
			if turn == 0:
				meter += meter_dir * delta * 1.7
				if meter >= 1.0:
					meter = 1.0
					meter_dir = -1.0
				elif meter <= 0.0:
					meter = 0.0
					meter_dir = 1.0
				if Input.is_action_just_pressed("ui_accept"):
					var d := absf(meter - 0.5)
					if d <= zone_half:
						made = true
					elif d <= zone_half * 2.5:
						made = randf() < 0.4
					else:
						made = false
					_shoot()
			else:
				timer -= delta
				if timer <= 0.0:
					made = randf() < 0.5
					_shoot()
		"flying":
			timer += delta / FLIGHT_TIME
			var t := minf(timer, 1.0)
			var target := HOOP if made else HOOP + Vector2(22, 10)
			ball = SHOOTER.lerp(target, t) + Vector2(0, -sin(t * PI) * 70.0)
			if timer >= 1.0:
				if made:
					score[turn] += 2
					msg = "Vào rổ! +2"
				else:
					msg = "Trượt!"
				state = "result"
				timer = 1.0
		"result":
			timer -= delta
			if timer <= 0.0:
				_next_turn()
	queue_redraw()


func _shoot() -> void:
	state = "flying"
	timer = 0.0


func _next_turn() -> void:
	if turn == 0:
		turn = 1
	else:
		turn = 0
		round_i += 1
		if round_i >= ROUNDS and score[0] != score[1]:
			state = "over"
			finished.emit(score[0] > score[1], score[0], score[1])
			return
	_start_turn()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 480, 270), Color(0.15, 0.12, 0.1))
	draw_rect(Rect2(0, 215, 480, 55), Color(0.65, 0.45, 0.25))   # sàn sân
	# bảng rổ + vành
	draw_rect(Rect2(HOOP.x + 14, HOOP.y - 40, 6, 50), Color(0.9, 0.9, 0.9))
	draw_line(HOOP + Vector2(-14, 0), HOOP + Vector2(14, 0), Color(1, 0.5, 0.1), 2.0)
	draw_line(HOOP + Vector2(-12, 0), HOOP + Vector2(-6, 14), Color(1, 1, 1, 0.6), 1.0)
	draw_line(HOOP + Vector2(12, 0), HOOP + Vector2(6, 14), Color(1, 1, 1, 0.6), 1.0)
	# người ném + bóng
	var shooter_col := Color(0.25, 0.5, 1.0) if turn == 0 else Color(0.95, 0.3, 0.3)
	draw_circle(SHOOTER + Vector2(0, 8), 9.0, shooter_col)
	draw_circle(ball, 5.0, Color(1, 0.55, 0.15))

	draw_string(font, Vector2(0, 18), "Bạn %d – %d Đối thủ     Lượt %d/%d" % [score[0], score[1], mini(round_i + 1, ROUNDS), ROUNDS],
		HORIZONTAL_ALIGNMENT_CENTER, 480, 12, Color.WHITE)
	if msg != "":
		draw_string(font, Vector2(0, 150), msg, HORIZONTAL_ALIGNMENT_CENTER, 480, 20, Color.YELLOW)

	if turn == 0 and state == "aim":
		draw_rect(METER_RECT, Color(0.3, 0.3, 0.3))
		var zw := METER_RECT.size.x * zone_half * 2.0
		var zx := METER_RECT.position.x + METER_RECT.size.x * 0.5 - zw / 2.0
		draw_rect(Rect2(zx, METER_RECT.position.y, zw, METER_RECT.size.y), Color(0.2, 0.85, 0.3))
		var mx := METER_RECT.position.x + METER_RECT.size.x * meter
		draw_rect(Rect2(mx - 1, METER_RECT.position.y - 3, 3, METER_RECT.size.y + 6), Color.WHITE)
		draw_string(font, Vector2(0, 238), "Nhấn Space khi vạch nằm trong vùng xanh",
			HORIZONTAL_ALIGNMENT_CENTER, 480, 8, Color(1, 1, 1, 0.7))
	elif turn == 1 and state == "aim":
		draw_string(font, Vector2(0, 238), "Đối thủ đang ngắm...", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, Color(1, 1, 1, 0.7))
