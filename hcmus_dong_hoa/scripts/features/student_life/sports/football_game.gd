extends Node2D
## Bóng đá 2v2, nhìn từ trên xuống. Bạn (xanh, viền trắng) + 1 đồng đội AI đấu 2 bạn sinh viên (đỏ).
## Điều khiển: mũi tên / WASD (ui_left, ui_right, ui_up, ui_down) để chạy, Space/Enter (ui_accept) để sút.
## Chạm bóng sẽ tự rê bóng. Đội xanh tấn công sang phải.
## Chưa dùng sprite: mọi thứ vẽ bằng _draw() để bạn thay bằng pixel art sau.

signal finished(won: bool, my_score: int, opp_score: int)

const FIELD := Rect2(20, 30, 440, 210)
const GOAL_H := 70.0
const MATCH_TIME := 60.0
const PLAYER_SPEED := 90.0
const AI_SPEED := 68.0
const AGENT_R := 7.0
const BALL_R := 4.0

var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var agents: Array = []
var score := [0, 0]
var time_left := MATCH_TIME
var state := "play"   # play | goal | over
var _goal_timer := 0.0
var kick_power_multiplier := 1.0


func _ready() -> void:
	_reset_positions()


func _reset_positions() -> void:
	var c := FIELD.get_center()
	ball_pos = c
	ball_vel = Vector2.ZERO
	agents = [
		_agent(Vector2(c.x - 70, c.y), 0, true),
		_agent(Vector2(c.x - 150, c.y + 40), 0, false),
		_agent(Vector2(c.x + 70, c.y - 30), 1, false),
		_agent(Vector2(c.x + 150, c.y + 30), 1, false),
	]


func _agent(pos: Vector2, team: int, human: bool) -> Dictionary:
	return {"pos": pos, "team": team, "human": human, "cd": 0.0}


func _process(delta: float) -> void:
	if state == "over":
		return
	if state == "goal":
		_goal_timer -= delta
		if _goal_timer <= 0.0:
			state = "play"
			_reset_positions()
		queue_redraw()
		return
	time_left -= delta
	if time_left <= 0.0:
		state = "over"
		finished.emit(score[0] > score[1], score[0], score[1])
		return
	_move_agents(delta)
	_move_ball(delta)
	queue_redraw()


func _goal_point(team: int) -> Vector2:
	# Điểm khung thành mà đội `team` tấn công vào.
	return Vector2(FIELD.end.x if team == 0 else FIELD.position.x, FIELD.get_center().y)


func _move_agents(delta: float) -> void:
	for i in agents.size():
		var a: Dictionary = agents[i]
		var dir := Vector2.ZERO
		var speed := AI_SPEED
		if a.human:
			dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			speed = PLAYER_SPEED
		else:
			dir = _ai_dir(i)
		a.pos += dir * speed * delta
		a.pos = a.pos.clamp(FIELD.position, FIELD.end)
		a.cd = maxf(0.0, a.cd - delta)

		var to_ball: Vector2 = ball_pos - a.pos
		var dist := to_ball.length()
		if dist < AGENT_R + BALL_R + 1.0 and a.cd <= 0.0:
			var n := to_ball.normalized() if dist > 0.01 else Vector2.RIGHT
			var goal := _goal_point(a.team)
			if a.human:
				if Input.is_action_just_pressed("ui_accept"):
					ball_vel = (goal - ball_pos).normalized() * 230.0 * kick_power_multiplier
					a.cd = 0.3
				else:
					ball_vel = n * 60.0 + dir * speed
			else:
				ball_vel = (goal - ball_pos).normalized().rotated(randf_range(-0.35, 0.35)) * 170.0
				a.cd = 0.5
			ball_pos = a.pos + n * (AGENT_R + BALL_R + 0.5)


func _ai_dir(i: int) -> Vector2:
	var a: Dictionary = agents[i]
	var my_d: float = a.pos.distance_to(ball_pos)
	var chaser := true
	for j in agents.size():
		if j != i and agents[j].team == a.team and agents[j].pos.distance_to(ball_pos) < my_d:
			chaser = false
	var target: Vector2
	if chaser:
		var goal := _goal_point(a.team)
		target = ball_pos - (goal - ball_pos).normalized() * 6.0
	else:
		var own_x := FIELD.position.x if a.team == 0 else FIELD.end.x
		target = Vector2(lerpf(own_x, ball_pos.x, 0.45), FIELD.get_center().y)
	var d: Vector2 = target - a.pos
	return d.normalized() if d.length() > 3.0 else Vector2.ZERO


func _move_ball(delta: float) -> void:
	ball_pos += ball_vel * delta
	ball_vel *= pow(0.4, delta)

	var goal_top := FIELD.get_center().y - GOAL_H / 2.0
	var in_goal_y := ball_pos.y > goal_top and ball_pos.y < goal_top + GOAL_H

	if ball_pos.y < FIELD.position.y + BALL_R:
		ball_pos.y = FIELD.position.y + BALL_R
		ball_vel.y = absf(ball_vel.y)
	elif ball_pos.y > FIELD.end.y - BALL_R:
		ball_pos.y = FIELD.end.y - BALL_R
		ball_vel.y = -absf(ball_vel.y)

	if ball_pos.x < FIELD.position.x + BALL_R:
		if in_goal_y:
			_score_goal(1)
		else:
			ball_pos.x = FIELD.position.x + BALL_R
			ball_vel.x = absf(ball_vel.x)
	elif ball_pos.x > FIELD.end.x - BALL_R:
		if in_goal_y:
			_score_goal(0)
		else:
			ball_pos.x = FIELD.end.x - BALL_R
			ball_vel.x = -absf(ball_vel.x)


func _score_goal(team: int) -> void:
	score[team] += 1
	state = "goal"
	_goal_timer = 1.2
	ball_vel = Vector2.ZERO


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(FIELD, Color(0.18, 0.55, 0.22))
	draw_rect(FIELD, Color.WHITE, false, 1.0)
	var c := FIELD.get_center()
	draw_line(Vector2(c.x, FIELD.position.y), Vector2(c.x, FIELD.end.y), Color(1, 1, 1, 0.6), 1.0)
	draw_arc(c, 22.0, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 1.0)
	var gt := c.y - GOAL_H / 2.0
	draw_rect(Rect2(FIELD.position.x - 8, gt, 8, GOAL_H), Color(0.9, 0.9, 0.9))
	draw_rect(Rect2(FIELD.end.x, gt, 8, GOAL_H), Color(0.9, 0.9, 0.9))

	for a in agents:
		var col := Color(0.25, 0.5, 1.0) if a.team == 0 else Color(0.95, 0.3, 0.3)
		draw_circle(a.pos, AGENT_R, col)
		if a.human:
			draw_arc(a.pos, AGENT_R + 1.5, 0.0, TAU, 16, Color.WHITE, 1.0)
	draw_circle(ball_pos, BALL_R, Color.WHITE)

	draw_string(font, Vector2(0, 18), "Xanh %d – %d Đỏ     Còn %d giây" % [score[0], score[1], ceili(time_left)],
		HORIZONTAL_ALIGNMENT_CENTER, 480, 12, Color.WHITE)
	draw_string(font, Vector2(0, 262), "Mũi tên/WASD: chạy    Space: sút",
		HORIZONTAL_ALIGNMENT_CENTER, 480, 8, Color(1, 1, 1, 0.7))
	if state == "goal":
		draw_string(font, Vector2(0, 140), "VÀO!", HORIZONTAL_ALIGNMENT_CENTER, 480, 24, Color.YELLOW)
