extends "res://scripts/features/feature.gd"
# NHẢY TẠI CHỖ: Ctrl+J để bắt đầu, bấm lại để dừng.

const DANCE_DURATION := 3.0
const DANCE_SPEED := 2.0

var dance_time := 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode != KEY_J or not event.ctrl_pressed:
			return

		if active:
			finish()
		elif not game.is_busy():
			begin()
		get_viewport().set_input_as_handled()

func begin() -> void:
	super()
	dance_time = DANCE_DURATION

func finish() -> void:
	super()
	dance_time = 0.0

func _process(delta: float) -> void:
	if not active:
		return
	dance_time -= delta
	game.anim += delta * DANCE_SPEED
	if dance_time <= 0.0:
		finish()

func draw_front_layer() -> void:
	if not active:
		return

	var phase := (DANCE_DURATION - dance_time) * TAU / 0.8
	var bob := sin(phase) * 2.0
	var left_note := Vector2(game.player.x - 12.0, game.player.y - 28.0 + bob)
	var right_note := Vector2(game.player.x + 12.0, game.player.y - 34.0 - bob)
	game.draw_string(game.font, left_note, "♪", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("ffe066"))
	game.draw_string(game.font, right_note, "♫", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("ff8fab"))
