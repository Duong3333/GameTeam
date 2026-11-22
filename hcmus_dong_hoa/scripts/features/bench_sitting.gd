extends "res://scripts/features/feature.gd"

const BENCH_RANGE := 24.0
const SIT_GRACE := 0.3

var _seated_index := -1
var _sit_time := 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != KEY_E:
		return
	if _seated_index >= 0:
		if _stand_up():
			get_viewport().set_input_as_handled()
		return
	if game.is_busy():
		return
	var bench_index := _nearest_bench()
	if bench_index < 0:
		return
	_sit(bench_index)
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _seated_index < 0:
		return
	_sit_time += delta
	if _sit_time >= SIT_GRACE and _move_key_down():
		_stand_up()

func draw_front_layer() -> void:
	if _seated_index >= 0:
		if _seated_index < game.benches.size():
			game.draw_bench(game.benches[_seated_index])
		_draw_prompt("E: Đứng dậy")
		return
	if game.is_busy():
		return
	if _nearest_bench() >= 0:
		_draw_prompt("E: Ngồi")

func _nearest_bench() -> int:
	var best_index := -1
	var best_distance := BENCH_RANGE
	for i in range(game.benches.size()):
		var bench: Variant = game.benches[i]
		var bench_pos: Vector2 = game.get_bench_position(bench)
		var distance: float = game.player.distance_to(bench_pos)
		if distance <= best_distance:
			best_index = i
			best_distance = distance
	return best_index

func _sit(index: int) -> void:
	var bench: Variant = game.benches[index]
	var bench_pos: Vector2 = game.get_bench_position(bench)
	_seated_index = index
	_sit_time = 0.0
	game.player = bench_pos
	game.facing = int(bench.get("face", 2 if _is_vertical(bench) else 0)) if bench is Dictionary else 0
	active = true

func _stand_up() -> bool:
	if _seated_index >= game.benches.size():
		_seated_index = -1
		active = false
		return true
	var bench: Variant = game.benches[_seated_index]
	var bench_pos: Vector2 = game.get_bench_position(bench)
	var facing := int(bench.get("face", 2 if _is_vertical(bench) else 0)) if bench is Dictionary else 0
	var facing_offset: Vector2 = [Vector2(0, 12), Vector2(0, -12), Vector2(-12, 0), Vector2(12, 0)][facing]
	var side_offset := Vector2(12, 0) if _is_vertical(bench) else Vector2(0, 12)
	var offsets: Array = [facing_offset, -facing_offset, side_offset, -side_offset]
	for offset in offsets:
		var stand_pos: Vector2 = bench_pos + offset
		if game.blocked(stand_pos):
			continue
		game.player = stand_pos
		game.facing = 0
		_seated_index = -1
		active = false
		return true
	return false

func _is_vertical(bench: Variant) -> bool:
	return bench is Dictionary and bool(bench.get("vertical", false))

func _move_key_down() -> bool:
	return (
		Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	)

func _draw_prompt(text: String) -> void:
	var p: Vector2 = game.player
	if not game.view.grow(48.0).has_point(p):
		return
	game.rc(p.x - 35.0, p.y - 39.0, 70.0, 13.0, Color("30343b"))
	game.rc(p.x - 35.0, p.y - 39.0, 70.0, 1.0, Color("e0b020"))
	game.ctext(text, p.x - 33.0, p.y - 29.0, 66.0, 8, Color.WHITE)
