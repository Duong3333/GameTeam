extends "res://scripts/features/feature.gd"

const PLAYER_HITBOX := Rect2(-5.0, -5.0, 10.0, 6.0)
const PLAYER_FALL_TIME := 1.0
const KNOCKBACK_TIME := 0.24
const HIT_COOLDOWN := 1.5
const PEDESTRIAN_CLEARANCE := 10.0

var _fall_timer := 0.0
var _fall_elapsed := 0.0
var _knockback_timer := 0.0
var _hit_cooldown := 0.0
var _knockback_velocity := Vector2.ZERO

func _physics_process(delta: float) -> void:
	_protect_npcs_from_traffic()
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _fall_timer > 0.0:
		_fall_timer = maxf(_fall_timer - delta, 0.0)
		_fall_elapsed += delta
		if _knockback_timer > 0.0:
			var step := minf(delta, _knockback_timer)
			game.player = game.move_entity(game.player, _knockback_velocity * step)
			_knockback_timer -= step
		if _fall_timer == 0.0:
			active = false
		return
	if game.is_busy() or _hit_cooldown > 0.0:
		return
	_check_player_bike_collision()

func _check_player_bike_collision() -> void:
	var player_rect := Rect2(game.player + PLAYER_HITBOX.position, PLAYER_HITBOX.size)
	for bike in game.bikes:
		var bike_rect := Rect2(Vector2(float(bike.x), float(bike.y)), Vector2(14.0, 7.0)).grow(2.0)
		if player_rect.intersects(bike_rect):
			_start_fall(float(bike.get("dir", 1.0)))
			return

func _start_fall(bike_direction: float) -> void:
	var push_direction := -signf(bike_direction)
	if is_zero_approx(push_direction):
		push_direction = -1.0
	_knockback_velocity = Vector2(push_direction * 64.0, -12.0)
	_knockback_timer = KNOCKBACK_TIME
	_fall_timer = PLAYER_FALL_TIME
	_fall_elapsed = 0.0
	_hit_cooldown = HIT_COOLDOWN
	active = true

func _protect_npcs_from_traffic() -> void:
	for npc_data in game.npcs:
		if bool(npc_data.get("quiz", false)) or npc_data.has("role"):
			continue
		var position: Vector2 = npc_data.get("pos", Vector2.ZERO)
		if not npc_data.has("_traffic_safe_pos"):
			npc_data["_traffic_safe_pos"] = position
		if _bike_is_near_pedestrian(position):
			npc_data["pos"] = npc_data["_traffic_safe_pos"]
			npc_data["dir"] = Vector2.ZERO
			npc_data["timer"] = maxf(float(npc_data.get("timer", 0.0)), 0.15)
		else:
			npc_data["_traffic_safe_pos"] = position

func _bike_is_near_pedestrian(position: Vector2) -> bool:
	var pedestrian_rect := Rect2(position - Vector2(5.0, 5.0), Vector2(10.0, 6.0))
	for bike in game.bikes:
		var bike_rect := Rect2(Vector2(float(bike.x), float(bike.y)), Vector2(14.0, 7.0)).grow(PEDESTRIAN_CLEARANCE)
		if pedestrian_rect.intersects(bike_rect):
			return true
	return false

func draw_front_layer() -> void:
	if _fall_timer <= 0.15:
		return
	var p: Vector2 = game.player
	var bob := 1.0 if int(_fall_elapsed * 12.0) % 2 == 0 else 0.0
	game.rc(p.x - 10.0, p.y - 24.0, 20.0, 25.0, Color("565b63"))
	game.draw_circle(p + Vector2(0.0, -2.0), 8.0, Color(0.0, 0.0, 0.0, 0.22))
	game.rc(p.x - 8.0, p.y - 12.0 + bob, 16.0, 8.0, Color("1a1a2e"))
	game.rc(p.x - 7.0, p.y - 11.0 + bob, 14.0, 6.0, Color("1b2f6e"))
	game.rc(p.x - 4.0, p.y - 10.0 + bob, 5.0, 2.0, Color.WHITE)
	game.rc(p.x - 8.0, p.y - 5.0 + bob, 5.0, 2.0, Color("1a1a2e"))
	game.rc(p.x + 3.0, p.y - 5.0 + bob, 5.0, 2.0, Color("1a1a2e"))
	game.draw_circle(p + Vector2(8.0, -9.0 + bob), 4.0, Color("1a1a2e"))
	game.draw_circle(p + Vector2(8.0, -9.0 + bob), 3.0, Color("f1c27d"))
	if int(_fall_elapsed * 8.0) % 2 == 0:
		game.ctext("*", p.x + 12.0, p.y - 17.0, 8.0, 10, Color("ffd23f"))
		game.ctext("*", p.x + 4.0, p.y - 21.0, 8.0, 8, Color("fff0a3"))
