extends "res://scripts/features/feature.gd"
## Rasengan: charge a chakra sphere and strike a nearby NPC with a short-range blast.

const ABILITY_KEY := KEY_K
const TARGET_RANGE := 105.0
const RECOVER_TIME := 0.32
const STRIKE_TIME := 0.24
const COOLDOWN := 1.2
const ROLE_SCRIPT := "res://scripts/features/character.gd"
const CANTEEN_SCRIPT := "res://scripts/maps/canteen.gd"
const RASENGAN_SOUND: AudioStream = preload("res://assets/audio/rasengan.mp3")
const RASENGAN_BLUE := Color("62c8ff")
const RASENGAN_CORE := Color("e8fbff")

var _cooldown := 0.0
var _phase := ""
var _phase_time := 0.0
var _target: Variant = null
var _direction := Vector2.RIGHT
var _clock := 0.0
var _sound_player: AudioStreamPlayer
var _cast_duration := 0.0
var _hit_done := false


func _ready() -> void:
	_sound_player = AudioStreamPlayer.new()
	_sound_player.stream = RASENGAN_SOUND
	_sound_player.volume_db = linear_to_db(0.3)
	add_child(_sound_player)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != ABILITY_KEY:
		return
	if active or _cooldown > 0.0 or (game.is_busy() and not _inside_canteen()):
		return
	var target: Variant = _find_target()
	if not target is Dictionary:
		return
	_target = target
	var to_target: Vector2 = target["pos"] - _player_pos()
	_direction = to_target.normalized() if to_target.length() > 0.1 else _face_vector(int(game.facing))
	game.facing = _face_index(_direction)
	var canteen := _canteen()
	if canteen != null and bool(canteen.get("inside")):
		canteen.set("_face", game.facing)
	_phase = "charge"
	_phase_time = 0.0
	_cast_duration = maxf(RASENGAN_SOUND.get_length(), STRIKE_TIME + RECOVER_TIME + 0.25)
	_hit_done = false
	_cooldown = COOLDOWN
	_sound_player.play()
	game.hidden_arms = 3
	begin()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if not active:
		return
	_phase_time += delta
	if _phase == "charge" and _phase_time >= _cast_duration - STRIKE_TIME - RECOVER_TIME:
		_phase = "strike"
		_phase_time = 0.0
	elif _phase == "strike":
		if not _hit_done and _phase_time >= STRIKE_TIME * 0.35:
			_apply_rasengan_hit()
			_hit_done = true
		if _phase_time >= STRIKE_TIME:
			_phase = "recover"
			_phase_time = 0.0
	elif _phase == "recover" and _phase_time >= RECOVER_TIME:
		finish()


func finish() -> void:
	_phase = ""
	_phase_time = 0.0
	_target = null
	game.hidden_arms = 0
	super()


func _find_target() -> Variant:
	var player := _player_pos()
	var best: Variant = null
	var best_distance := TARGET_RANGE
	for npc in _all_npcs():
		if not npc is Dictionary or npc.get("hidden", false) or npc.get("mode") == "staff":
			continue
		var pos: Variant = npc.get("pos")
		if not pos is Vector2:
			continue
		var distance: float = player.distance_to(pos)
		if distance <= best_distance:
			best = npc
			best_distance = distance
	return best


func _all_npcs() -> Array:
	var result: Array = game.npcs.duplicate()
	for feature in game.features:
		var script: Script = feature.get_script()
		if script == null:
			continue
		if script.resource_path == ROLE_SCRIPT:
			result.append_array(feature.get("_npcs"))
		elif script.resource_path == CANTEEN_SCRIPT and bool(feature.get("inside")):
			result.append_array(feature.get("_npcs"))
	return result


func _canteen() -> Node:
	for feature in game.features:
		var script: Script = feature.get_script()
		if script != null and script.resource_path == CANTEEN_SCRIPT:
			return feature
	return null


func _inside_canteen() -> bool:
	var canteen := _canteen()
	return canteen != null and bool(canteen.get("inside"))


func _player_pos() -> Vector2:
	var canteen := _canteen()
	if canteen != null and bool(canteen.get("inside")):
		return canteen.get("_pos")
	return game.player


func _apply_rasengan_hit() -> void:
	if not _target is Dictionary or bool(_target.get("hidden", false)):
		return
	var npc: Dictionary = _target
	var away: Vector2 = npc["pos"] - _player_pos()
	away = away.normalized() if away.length() > 0.1 else _direction
	npc["face"] = _face_index(-away)
	npc["dir"] = Vector2.ZERO
	npc["timer"] = maxf(float(npc.get("timer", 0.0)), 1.1)
	npc["say"] = "Uwaa! Rasengan!"
	npc["say_t"] = 1.8
	var fx: Variant = npc.get("fx")
	if not fx is Dictionary:
		fx = {"hit_t": 0.0, "angry_t": 0.0, "kb": Vector2.ZERO, "hits": 0, "limit": 999,
			"leaving": false, "phase": "", "rant": [], "walk_t": 0.0, "flee": Vector2.ZERO}
		npc["fx"] = fx
	fx["hit_t"] = 0.5
	fx["angry_t"] = maxf(float(fx.get("angry_t", 0.0)), 1.0)
	fx["kb"] = Vector2.ZERO if _is_canteen_npc(npc) or npc.get("study", false) else away * 190.0


func _is_canteen_npc(npc: Dictionary) -> bool:
	var canteen := _canteen()
	if canteen == null:
		return false
	for other in canteen.get("_npcs"):
		if is_same(other, npc):
			return true
	return false


func _face_vector(face: int) -> Vector2:
	match face:
		0: return Vector2.DOWN
		1: return Vector2.UP
		2: return Vector2.LEFT
	return Vector2.RIGHT


func _face_index(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 2 if direction.x < 0.0 else 3
	return 1 if direction.y < 0.0 else 0


func draw_front_layer() -> void:
	if not active:
		return
	var player := _player_pos()
	if not game.view.grow(70.0).has_point(player):
		return
	var side := Vector2(-_direction.y, _direction.x)
	var bob := sin(_clock * 4.0) * 1.2 if _phase == "charge" else 0.0
	var strike := clampf(_phase_time / STRIKE_TIME, 0.0, 1.0) if _phase == "strike" else 0.0
	var hand := player + _direction * (12.0 + 10.0 * strike) + Vector2(0.0, -10.0 + bob)
	var charge_duration := maxf(_cast_duration - STRIKE_TIME - RECOVER_TIME, 0.01)
	var radius := 3.0 + 6.0 * clampf(_phase_time / charge_duration, 0.0, 1.0)
	if _phase == "recover":
		radius = 9.0 * clampf(1.0 - _phase_time / RECOVER_TIME, 0.0, 1.0)
	_draw_rasengan_arms(player, hand, strike)
	# Layered glow, rotating chakra bands, and a bright core make the orb read clearly at pixel scale.
	game.draw_circle(hand, radius + 8.0, Color(RASENGAN_BLUE, 0.10))
	game.draw_circle(hand, radius + 4.0, Color(RASENGAN_BLUE, 0.24))
	game.draw_circle(hand, radius + 1.0, Color("168be8"))
	game.draw_circle(hand, radius - 1.0, Color("54c9ff"))
	game.draw_circle(hand + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.48, RASENGAN_CORE)
	for i in 3:
		var start_angle := _clock * (8.0 + float(i) * 2.0) + float(i) * TAU / 3.0
		var end_angle := start_angle + PI * 1.35
		game.draw_arc(hand, radius + 3.0 + float(i % 2) * 2.0, start_angle, end_angle, 18, Color(RASENGAN_CORE, 0.85), 1.2, true)
	for i in 6:
		var angle := -_clock * 13.0 + float(i) * TAU / 6.0
		var swirl := hand + Vector2.from_angle(angle) * (radius + 4.0 + sin(_clock * 16.0 + float(i)) * 1.5)
		game.rc(roundf(swirl.x), roundf(swirl.y), 2, 2, RASENGAN_CORE)
	if _phase == "recover":
		var impact_pos: Vector2 = _target["pos"] if _target is Dictionary else hand
		var pulse := clampf(1.0 - _phase_time / RECOVER_TIME, 0.0, 1.0)
		game.draw_arc(impact_pos, 10.0 + (1.0 - pulse) * 15.0, 0.0, TAU, 32, Color(RASENGAN_BLUE, pulse), 2.0, true)
		game.ctext("RASENGAN", impact_pos.x - 32.0, impact_pos.y + 27.0, 64.0, 9, Color(RASENGAN_BLUE, pulse))


func _draw_rasengan_arms(player: Vector2, orb: Vector2, extension: float) -> void:
	var side := Vector2(-_direction.y, _direction.x)
	var up := Vector2(0.0, -10.0)
	var left_shoulder := player + side * 4.0 + up
	var right_shoulder := player - side * 4.0 + up
	var left_elbow := player + _direction * (3.0 + extension * 3.0) + side * 7.0 + up
	var right_elbow := player + _direction * (3.0 + extension * 3.0) - side * 7.0 + up
	var left_hand := orb - side * 3.0
	var right_hand := orb + side * 3.0
	_draw_sleeve(left_shoulder, left_elbow)
	_draw_sleeve(left_elbow, left_hand)
	_draw_sleeve(right_shoulder, right_elbow)
	_draw_sleeve(right_elbow, right_hand)
	_draw_wrist(left_hand)
	_draw_wrist(right_hand)


func _draw_sleeve(from: Vector2, to: Vector2) -> void:
	game.draw_line(from.round(), to.round(), Color("1a1a2e"), 5.0, false)
	game.draw_line(from.round(), to.round(), Color("1b2f6e"), 3.0, false)


func _draw_wrist(at: Vector2) -> void:
	game.draw_circle(at.round(), 2.2, Color("1a1a2e"))
	game.draw_circle(at.round(), 1.5, Color("f1c27d"))
