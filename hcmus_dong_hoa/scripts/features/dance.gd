extends "res://scripts/features/feature.gd"
# Nhấn J để bật/tắt nhảy múa.

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != KEY_J:
		return

	if active:
		finish()
	elif not game.is_busy():
		begin()
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if active:
		game.anim += delta * 4.0

func draw_front_layer() -> void:
	if active:
		var bob := sin(game.clock * 8.0) * 2.0
		game.ctext("DANCE!", game.player.x - 20.0, game.player.y - 37.0 + bob, 40.0, 8, Color("ffd23f"))
