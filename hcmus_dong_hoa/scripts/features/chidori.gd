extends "res://scripts/features/feature.gd"
## Experimental Chidori dash. Remove this feature's registry line and this file to disable it.

const ABILITY_KEY := KEY_J
const TARGET_RANGE := 150.0
const DASH_TIME := 0.24
const RECOVER_TIME := 0.28
const COOLDOWN := 1.0
const ROLE_SCRIPT := "res://scripts/features/character.gd"
const CANTEEN_SCRIPT := "res://scripts/maps/canteen.gd"
const CHIDORI_SOUND: AudioStream = preload("res://assets/audio/chidori.mp3")
const ELECTRIC_BLUE := Color("63d9ff")
const ELECTRIC_CORE := Color("e4fbff")

var _cooldown := 0.0
var _phase := ""
var _phase_time := 0.0
var _target: Variant = null
var _dash_start := Vector2.ZERO
var _dash_end := Vector2.ZERO
var _dash_dir := Vector2.RIGHT
var _hit_done := false
var _clock := 0.0
var _electric_player: AudioStreamPlayer
var _cast_duration := 0.0


func _ready() -> void:
	_electric_player = AudioStreamPlayer.new()
	_electric_player.volume_db = linear_to_db(0.3)
	add_child(_electric_player)
	_electric_player.stream = CHIDORI_SOUND


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != ABILITY_KEY:
		return
	if active or _cooldown > 0.0 or (game.is_busy() and not _inside_canteen()):
		return
	var target: Variant = _find_target()
	if target == null:
		return
	if not target is Dictionary:
		return
	_start_chidori(target)
	get_viewport().set_input_as_handled()


func _start_chidori(target: Dictionary) -> void:
	_target = target
	_dash_start = _player_pos()
	var to_target: Vector2 = target["pos"] - _dash_start
	_dash_dir = to_target.normalized() if to_target.length() > 0.1 else _face_vector(int(game.facing))
	game.facing = _face_index(_dash_dir)
	var canteen := _canteen()
	if canteen != null and bool(canteen.get("inside")):
		canteen.set("_face", game.facing)
	_dash_end = _choose_dash_end(target["pos"], -_dash_dir)
	_cast_duration = maxf(CHIDORI_SOUND.get_length(), DASH_TIME + RECOVER_TIME + 0.25)
	_phase = "charge"
	_phase_time = 0.0
	_hit_done = false
	_cooldown = COOLDOWN
	_electric_player.play()
	game.hidden_arms = 3
	begin()


func _process(delta: float) -> void:
	_clock += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if not active:
		return
	_phase_time += delta
	match _phase:
		"charge":
			if _phase_time >= _cast_duration - DASH_TIME - RECOVER_TIME:
				if _target is Dictionary and not bool(_target.get("hidden", false)):
					_dash_end = _choose_dash_end(_target["pos"], -_dash_dir)
				_phase = "dash"
				_phase_time = 0.0
		"dash":
			var t := clampf(_phase_time / DASH_TIME, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - t, 2.0)
			var desired: Vector2 = _dash_start.lerp(_dash_end, eased)
			_move_player_toward(desired)
			if t >= 1.0:
				if not _hit_done and _target is Dictionary and not bool(_target.get("hidden", false)):
					_apply_chidori_hit(_target)
				_hit_done = true
				_phase = "recover"
				_phase_time = 0.0
		"recover":
			if _phase_time >= RECOVER_TIME:
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


func _set_player_pos(pos: Vector2) -> void:
	var canteen := _canteen()
	if canteen != null and bool(canteen.get("inside")):
		canteen.set("_pos", pos)
	else:
		game.player = pos


func _move_player_toward(desired: Vector2) -> void:
	var current := _player_pos()
	if _inside_canteen():
		_set_player_pos(desired)
		return
	var displacement := desired - current
	var steps := maxi(1, ceili(displacement.length() / 4.0))
	for _step in steps:
		var next_pos: Vector2 = game.move_entity(current, displacement / float(steps))
		if next_pos == current:
			break
		current = next_pos
	_set_player_pos(current)


func _choose_dash_end(target_pos: Vector2, away: Vector2) -> Vector2:
	var canteen := _canteen()
	var inside_canteen := canteen != null and bool(canteen.get("inside"))
	var directions: Array[Vector2] = [away, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for direction in directions:
		var candidate := target_pos + direction * 20.0
		if inside_canteen or not game.blocked(candidate):
			return candidate
	return _player_pos()


func _apply_chidori_hit(npc: Dictionary) -> void:
	if game.stats != null:
		game.stats.add_drl(-1, "Dùng Chidori đánh NPC")
	var player := _player_pos()
	var away: Vector2 = npc["pos"] - player
	away = away.normalized() if away.length() > 0.1 else _dash_dir
	npc["face"] = _face_index(-away)
	npc["dir"] = Vector2.ZERO
	npc["timer"] = maxf(float(npc.get("timer", 0.0)), 1.0)
	if npc.has("talk"):
		npc["talk"] = maxf(float(npc.get("talk", 0.0)), 1.0)
	npc["say"] = "Tê cả người luôn!"
	npc["say_t"] = 1.8
	var fx: Variant = npc.get("fx")
	if not fx is Dictionary:
		fx = {
			"hit_t": 0.0, "angry_t": 0.0, "kb": Vector2.ZERO,
			"hits": 0, "limit": 999, "leaving": false, "phase": "",
			"rant": [], "walk_t": 0.0, "flee": Vector2.ZERO,
		}
		npc["fx"] = fx
	fx["hit_t"] = 0.42
	fx["angry_t"] = maxf(float(fx.get("angry_t", 0.0)), 0.9)
	fx["kb"] = Vector2.ZERO if _is_canteen_npc(npc) or npc.get("study", false) else away * 135.0


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
		if not game.is_busy() and _cooldown <= 0.0:
			var nearby: Variant = _find_target()
			if nearby != null and game.view.grow(34.0).has_point(nearby["pos"]):
				game.ctext("[J] Chidori   [K] Rasengan", nearby["pos"].x - 69.0, nearby["pos"].y - 53.0, 138.0, 8, ELECTRIC_BLUE)
		return
	var player := _player_pos()
	var target_pos: Vector2 = _target["pos"] if _target is Dictionary else player + _dash_dir * 24.0
	if not game.view.grow(90.0).has_point(player):
		return
	var hand := player + _dash_dir * 10.0 + Vector2(-_dash_dir.y, _dash_dir.x) * 3.0 + Vector2(0.0, -10.0)
	var alpha := 1.0
	if _phase == "recover":
		alpha = clampf(1.0 - _phase_time / RECOVER_TIME, 0.0, 1.0)
	var arm_tip := hand
	if _phase == "charge":
		var charge := clampf(_phase_time / maxf(_cast_duration - DASH_TIME - RECOVER_TIME, 0.01), 0.0, 1.0)
		var orb_radius := 3.0 + charge * 5.0
		_draw_chidori_arms(player, hand)
		game.draw_circle(hand, orb_radius + 6.0, Color(ELECTRIC_BLUE, 0.10 + charge * 0.12))
		game.draw_circle(hand, orb_radius + 2.0, Color(ELECTRIC_BLUE, 0.32 + charge * 0.25))
		game.draw_circle(hand, orb_radius, Color("8beaff"))
		game.draw_circle(hand, orb_radius * 0.38, ELECTRIC_CORE)
		for i in 5:
			var angle := _clock * 17.0 + float(i) * TAU / 5.0
			var spark := hand + Vector2.from_angle(angle) * (orb_radius + 2.0 + fmod(_clock * 10.0 + float(i) * 2.0, 7.0))
			game.draw_line(spark, hand, Color(ELECTRIC_BLUE, alpha * 0.75), 1.2, true)
	if _phase == "dash":
		var strike := clampf(_phase_time / DASH_TIME, 0.0, 1.0)
		arm_tip = player + _dash_dir * (14.0 + 8.0 * strike) + Vector2(0.0, -10.0)
		_draw_chidori_arms(player, arm_tip)
		# Keep the lightning bound to the striking hand: no beam stretching across the scene.
		_draw_bolt(arm_tip, arm_tip + _dash_dir * 14.0, alpha)
	if _phase == "recover":
		_draw_chidori_arms(player, hand)
	if _phase == "recover":
		var impact_radius := 6.0 + (1.0 - alpha) * 13.0
		game.draw_arc(target_pos, impact_radius, 0.0, TAU, 24, Color(ELECTRIC_BLUE, alpha * 0.8), 1.5, true)
		for i in 8:
			var spark := target_pos + Vector2.from_angle(float(i) * TAU / 8.0 + _clock * 3.0) * (9.0 + fmod(_clock * 16.0 + float(i), 5.0))
			game.rc(roundf(spark.x), roundf(spark.y), 2, 2, Color(ELECTRIC_CORE, alpha))
		game.ctext("CHIDORI", target_pos.x - 30.0, target_pos.y - 39.0, 60.0, 9, Color(ELECTRIC_BLUE, alpha))


func _draw_chidori_arms(player: Vector2, lead_hand: Vector2) -> void:
	var side := Vector2(-_dash_dir.y, _dash_dir.x)
	var up := Vector2(0.0, -10.0)
	var lead_shoulder := player + side * 4.0 + up
	var lead_elbow := player + _dash_dir * 3.0 + side * 7.0 + up
	var support_shoulder := player - side * 4.0 + up
	var support_elbow := player - _dash_dir * 2.0 - side * 6.0 + up
	_draw_sleeve(lead_shoulder, lead_elbow)
	_draw_sleeve(lead_elbow, lead_hand)
	_draw_hand_pixel(lead_hand)
	_draw_sleeve(support_shoulder, support_elbow)
	_draw_sleeve(support_elbow, support_elbow + _dash_dir * 2.0)
	_draw_hand_pixel(support_elbow + _dash_dir * 2.0)


func _draw_sleeve(from: Vector2, to: Vector2) -> void:
	game.draw_line(from.round(), to.round(), Color("1a1a2e"), 5.0, false)
	game.draw_line(from.round(), to.round(), Color("1b2f6e"), 3.0, false)


func _draw_hand_pixel(at: Vector2) -> void:
	game.draw_circle(at.round(), 2.2, Color("1a1a2e"))
	game.draw_circle(at.round(), 1.5, Color("f1c27d"))


func _draw_bolt(start: Vector2, end: Vector2, alpha: float) -> void:
	var delta := end - start
	var perpendicular := Vector2(-delta.y, delta.x).normalized()
	var points: Array[Vector2] = [start]
	for i in range(1, 7):
		var t := float(i) / 7.0
		var offset := sin(_clock * 42.0 + float(i) * 2.7) * (3.0 if i % 2 == 0 else -3.0)
		points.append(start.lerp(end, t) + perpendicular * offset)
	points.append(end)
	for i in range(points.size() - 1):
		game.draw_line(points[i], points[i + 1], Color(ELECTRIC_BLUE, alpha * 0.8), 4.0, true)
		game.draw_line(points[i], points[i + 1], Color(ELECTRIC_CORE, alpha), 1.5, true)
