extends "res://scripts/features/feature.gd"
# ĐI VÀO / RA CÁC TÒA NHÀ, NHÀ THỂ DỤC, NHÀ ĐIỀU HÀNH VÀ CĂN TIN.

const DOOR_DISTANCE := 24.0
const ROOM_EXIT := Vector2(240.0, 226.0)
const ROOM_SPEED := 72.0

var font: Font
var canvas: Control
var doors: Array = []
var nearby_door: Dictionary = {}
var inside := false
var current_room: Dictionary = {}
var room_player := Vector2(240.0, 190.0)

func _ready() -> void:
	font = game.font
	doors = game.get_doorways()
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.visible = false
	layer.add_child(canvas)
	canvas.draw.connect(_on_draw)

func _process(delta: float) -> void:
	if inside:
		_update_room_player(delta)
	elif game.is_busy():
		nearby_door = {}
		canvas.visible = false
	else:
		nearby_door = _find_nearby_door()
		canvas.visible = not nearby_door.is_empty()
	if canvas.visible:
		canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode != KEY_E:
			return
		if inside:
			if room_player.distance_to(ROOM_EXIT) <= DOOR_DISTANCE:
				leave_room()
			get_viewport().set_input_as_handled()
			return
		if game.is_busy():
			return
		nearby_door = _find_nearby_door()
		if not nearby_door.is_empty():
			enter_room(nearby_door)
			get_viewport().set_input_as_handled()

func enter_room(door: Dictionary) -> void:
	current_room = door
	room_player = Vector2(240.0, 190.0)
	inside = true
	active = true
	canvas.visible = true
	canvas.queue_redraw()

func leave_room() -> void:
	inside = false
	current_room = {}
	active = false
	canvas.visible = false
	canvas.queue_redraw()

func _find_nearby_door() -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance := DOOR_DISTANCE
	for door in doors:
		var door_position: Vector2 = door["position"]
		var distance: float = game.player.distance_to(door_position)
		if distance <= nearest_distance:
			nearest = door
			nearest_distance = distance
	return nearest

func _update_room_player(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0
	if direction != Vector2.ZERO:
		room_player += direction.normalized() * ROOM_SPEED * delta
		room_player.x = clampf(room_player.x, 40.0, 440.0)
		room_player.y = clampf(room_player.y, 58.0, 229.0)

func _on_draw() -> void:
	if inside:
		_draw_room()
	elif not nearby_door.is_empty():
		canvas.draw_rect(Rect2(67, 226, 346, 28), Color(0.04, 0.08, 0.14, 0.9))
		canvas.draw_rect(Rect2(67, 226, 346, 28), Color("e0b020"), false, 1.0)
		_draw_text("E: Vào " + str(nearby_door["title"]), Vector2(72, 245), 10, Color.WHITE, 336)

func _draw_room() -> void:
	canvas.draw_rect(Rect2(0, 0, 480, 270), Color("19232d"))
	canvas.draw_rect(Rect2(22, 24, 436, 224), Color("b9a886"))
	canvas.draw_rect(Rect2(28, 30, 424, 212), Color("d8c9a8"))
	for x in range(32, 452, 24):
		canvas.draw_line(Vector2(x, 32), Vector2(x, 240), Color(0.38, 0.31, 0.22, 0.12), 1.0)
	for y in range(34, 242, 24):
		canvas.draw_line(Vector2(30, y), Vector2(450, y), Color(0.38, 0.31, 0.22, 0.12), 1.0)

	canvas.draw_rect(Rect2(22, 24, 436, 16), Color("594333"))
	canvas.draw_rect(Rect2(22, 24, 436, 2), Color("826348"))
	_draw_room_furniture()
	canvas.draw_rect(Rect2(215, 232, 50, 16), Color("d8c9a8"))
	canvas.draw_rect(Rect2(215, 232, 50, 2), Color("594333"))

	canvas.draw_rect(Rect2(0, 0, 480, 24), Color(0.03, 0.06, 0.1, 0.94))
	_draw_text(str(current_room["title"]), Vector2(12, 17), 11, Color("ffe28a"), 300)
	_draw_text("W A S D: di chuyển", Vector2(12, 260), 8, Color("e6e8eb"), 160)
	if room_player.distance_to(ROOM_EXIT) <= DOOR_DISTANCE:
		_draw_text("E: Ra ngoài", Vector2(318, 260), 9, Color("ffe28a"), 150)
	else:
		_draw_text("Tìm cửa ở phía dưới để ra", Vector2(282, 260), 8, Color("e6e8eb"), 180)
	_draw_room_player()

func _draw_room_furniture() -> void:
	match current_room["kind"]:
		"classroom":
			_draw_item(Rect2(174, 47, 132, 9), Color("537c69"), Color("dbe6d6"))
			_draw_item(Rect2(84, 88, 70, 30), Color("9b7145"), Color("65472f"))
			_draw_item(Rect2(326, 88, 70, 30), Color("9b7145"), Color("65472f"))
			for y in [142, 181]:
				for x in [112, 220, 328]:
					_draw_item(Rect2(x - 24, y, 48, 20), Color("b48550"), Color("725131"))
					canvas.draw_rect(Rect2(x - 18, y + 20, 36, 4), Color("594333"))
		"gym":
			for i in 4:
				_draw_item(Rect2(62 + i * 88, 74, 66, 122), Color("739c82"), Color("42634f"))
			canvas.draw_rect(Rect2(72, 54, 336, 6), Color("e6e2d5"))
			for x in [136, 240, 344]:
				canvas.draw_rect(Rect2(x - 20, 211, 40, 8), Color("6b7480"))
				canvas.draw_rect(Rect2(x - 3, 202, 6, 12), Color("454c56"))
		"office":
			_draw_item(Rect2(65, 66, 350, 8), Color("597b91"), Color("dce8ee"))
			for x in [112, 240, 368]:
				_draw_item(Rect2(x - 35, 112, 70, 34), Color("9a7046"), Color("61482f"))
				canvas.draw_rect(Rect2(x - 25, 146, 6, 19), Color("594333"))
				canvas.draw_rect(Rect2(x + 19, 146, 6, 19), Color("594333"))
				canvas.draw_rect(Rect2(x - 12, 101, 24, 10), Color("435363"))
		"canteen":
			for y in [104, 170]:
				for x in [124, 240, 356]:
					_draw_item(Rect2(x - 34, y, 68, 24), Color("b77b45"), Color("71482e"))
					canvas.draw_rect(Rect2(x - 26, y + 24, 5, 12), Color("594333"))
					canvas.draw_rect(Rect2(x + 21, y + 24, 5, 12), Color("594333"))

func _draw_item(rect: Rect2, surface: Color, edge: Color) -> void:
	canvas.draw_rect(rect, edge)
	canvas.draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 5)), surface)

func _draw_room_player() -> void:
	canvas.draw_circle(room_player + Vector2(0, 1), 8, Color(0, 0, 0, 0.25))
	canvas.draw_rect(Rect2(room_player.x - 6, room_player.y - 13, 12, 11), Color("1b2f6e"))
	canvas.draw_rect(Rect2(room_player.x - 4, room_player.y - 20, 8, 7), Color("f1c27d"))
	canvas.draw_rect(Rect2(room_player.x - 4, room_player.y - 21, 8, 3), Color("1b1b1b"))
	canvas.draw_rect(Rect2(room_player.x - 5, room_player.y - 2, 4, 7), Color("2b2f4a"))
	canvas.draw_rect(Rect2(room_player.x + 1, room_player.y - 2, 4, 7), Color("2b2f4a"))

func _draw_text(text: String, position: Vector2, size: int, color: Color, width: float) -> void:
	canvas.draw_string(font, position, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)
