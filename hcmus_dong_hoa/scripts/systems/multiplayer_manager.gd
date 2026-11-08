extends Node

const DEFAULT_PORT := 2456
const MAX_CLIENTS := 64
const MAX_ROOM_PLAYERS := 6
const SNAPSHOT_INTERVAL := 0.05
const CONNECTION_TIMEOUT := 10.0
const ROOM_CODE_LENGTH := 6
const ROOM_CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var game: Node2D
var other_players: Dictionary = {}
var rooms: Dictionary = {}
var peer_rooms: Dictionary = {}
var _multiplayer: MultiplayerAPI
var _session_active := false
var _server_mode := false
var _snapshot_timer := 0.0
var _connection_elapsed := 0.0
var _pending_action := ""
var _requested_room_code := ""
var _ui_layer: CanvasLayer
var _screen_blur: ColorRect
var _mode_screen: Control
var _pause_screen: Control
var _session_badge: Label
var _connection_panel: PanelContainer
var _address_field: LineEdit
var _port_field: SpinBox
var _room_code_field: LineEdit
var _status_label: Label
var _ui_state: StringName = &"mode_select"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_multiplayer = get_tree().get_multiplayer()
	_multiplayer.peer_connected.connect(_on_peer_connected)
	_multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_multiplayer.connected_to_server.connect(_on_connected_to_server)
	_multiplayer.connection_failed.connect(_on_connection_failed)
	_multiplayer.server_disconnected.connect(_on_server_disconnected)
	_server_mode = OS.get_cmdline_user_args().has("--multiplayer-server")
	if _server_mode:
		get_tree().paused = false
		_start_server(_server_port_from_args())
	else:
		_create_mode_ui()

func _switch_mode() -> void:
	if _session_active:
		disconnect_session()
	_show_mode_screen()

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		physics_tick(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _server_mode or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return

	match _ui_state:
		&"gameplay":
			_show_pause_screen()
		&"pause":
			_resume_game()
		&"multiplayer_setup":
			if _session_active:
				disconnect_session()
			_show_mode_screen()
		&"mode_select":
			return
	get_viewport().set_input_as_handled()

func is_connected_to_session() -> bool:
	return _session_active

func get_other_players() -> Dictionary:
	return other_players

func host(address: String, port: int) -> void:
	_connect_to_relay(address, port, "create", "")

func join(address: String, port: int, room_code: String) -> void:
	var code := room_code.strip_edges().to_upper()
	if code.is_empty():
		_set_status("Nhập mã phòng bạn của bạn gửi.")
		return
	_connect_to_relay(address, port, "join", code)

func disconnect_session() -> void:
	if _session_active:
		_multiplayer.multiplayer_peer.close()
		_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_session_active = false
	_pending_action = ""
	_requested_room_code = ""
	other_players.clear()
	if is_instance_valid(_status_label):
		_set_status("Đã ngắt kết nối.")

func select_singleplayer() -> void:
	if _session_active:
		disconnect_session()
	_ui_state = &"gameplay"
	_set_ui_visibility()
	get_tree().paused = false

func select_multiplayer() -> void:
	_ui_state = &"multiplayer_setup"
	_set_ui_visibility()
	get_tree().paused = true

func _show_mode_screen() -> void:
	_ui_state = &"mode_select"
	_set_ui_visibility()
	get_tree().paused = true

func _show_pause_screen() -> void:
	_ui_state = &"pause"
	_set_ui_visibility()
	get_tree().paused = true

func _resume_game() -> void:
	_ui_state = &"gameplay"
	_set_ui_visibility()
	get_tree().paused = false

func _open_admin_time() -> void:
	for feature in game.features:
		if feature.has_method("open_admin"):
			feature.open_admin()
			return
	push_error("Admin time feature is not registered.")

func _set_ui_visibility() -> void:
	if not is_instance_valid(_screen_blur):
		return
	_screen_blur.visible = _ui_state != &"gameplay"
	_mode_screen.visible = _ui_state == &"mode_select"
	_pause_screen.visible = _ui_state == &"pause"
	_connection_panel.visible = _ui_state == &"multiplayer_setup"
	_session_badge.visible = _ui_state == &"gameplay" and _session_active

func physics_tick(delta: float) -> void:
	if not _session_active:
		return
	if _server_mode:
		_simulate_rooms(delta)
		_snapshot_timer += delta
		if _snapshot_timer >= SNAPSHOT_INTERVAL:
			_snapshot_timer = 0.0
			_broadcast_snapshots()
		return

	var connection_status := _multiplayer.multiplayer_peer.get_connection_status()
	if connection_status == MultiplayerPeer.CONNECTION_CONNECTING:
		_connection_elapsed += delta
		if _connection_elapsed >= CONNECTION_TIMEOUT:
			_reset_session("Hết thời gian kết nối. Kiểm tra địa chỉ server, cổng và trạng thái server.")
		return
	if connection_status != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var direction := Vector2.ZERO if _ui_state != &"gameplay" or game.is_busy() or _address_field.has_focus() or _room_code_field.has_focus() else _read_movement_input()
	rpc_id(1, "_submit_movement", direction)

func _start_server(port: int) -> void:
	if port < 1024 or port > 65535:
		push_error("Cổng relay server phải nằm trong khoảng 1024-65535.")
		get_tree().quit(1)
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		push_error("Không thể mở relay server trên cổng UDP %d (mã lỗi %d)." % [port, error])
		get_tree().quit(1)
		return
	_multiplayer.multiplayer_peer = peer
	_session_active = true
	print("Relay server đang lắng nghe UDP trên cổng %d." % port)

func _server_port_from_args() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			var value := argument.trim_prefix("--port=")
			if value.is_valid_int():
				var port := int(value)
				if port >= 1024 and port <= 65535:
					return port
			push_error("Cổng server không hợp lệ: %s" % value)
			return -1
	return DEFAULT_PORT

func _connect_to_relay(address: String, port: int, action: String, room_code: String) -> void:
	if _session_active:
		_set_status("Hãy thoát phòng hiện tại trước khi kết nối lại.")
		return
	var relay_address := address.strip_edges()
	if relay_address.is_empty():
		_set_status("Nhập địa chỉ IP hoặc tên miền của relay server.")
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(relay_address, port)
	if error != OK:
		_set_status("Không thể kết nối tới server (mã lỗi %d)." % error)
		return
	_multiplayer.multiplayer_peer = peer
	_session_active = true
	_connection_elapsed = 0.0
	_pending_action = action
	_requested_room_code = room_code
	_set_status("Đang kết nối tới %s:%d..." % [relay_address, port])

@rpc("any_peer", "call_remote", "reliable")
func _request_create_room() -> void:
	if not _server_mode:
		return
	var peer_id := _multiplayer.get_remote_sender_id()
	if peer_rooms.has(peer_id):
		return
	var code := _generate_room_code()
	var state := _new_player_state(peer_id, 0)
	var room: Dictionary = {}
	room[peer_id] = state
	rooms[code] = room
	peer_rooms[peer_id] = code
	rpc_id(peer_id, "_room_created", code)
	_send_room_snapshot(code)

@rpc("any_peer", "call_remote", "reliable")
func _request_join_room(room_code: String) -> void:
	if not _server_mode:
		return
	var peer_id := _multiplayer.get_remote_sender_id()
	var code := room_code.strip_edges().to_upper()
	if peer_rooms.has(peer_id):
		return
	if not rooms.has(code):
		rpc_id(peer_id, "_room_join_failed", "Không tìm thấy phòng. Kiểm tra lại mã phòng.")
		return
	var room: Dictionary = rooms[code]
	if room.size() >= MAX_ROOM_PLAYERS:
		rpc_id(peer_id, "_room_join_failed", "Phòng đã đủ %d người." % MAX_ROOM_PLAYERS)
		return
	room[peer_id] = _new_player_state(peer_id, room.size())
	rooms[code] = room
	peer_rooms[peer_id] = code
	rpc_id(peer_id, "_room_joined", code)
	_send_room_snapshot(code)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _submit_movement(direction: Vector2) -> void:
	if not _server_mode:
		return
	var peer_id := _multiplayer.get_remote_sender_id()
	if not peer_rooms.has(peer_id):
		return
	var code: String = peer_rooms[peer_id]
	var room: Dictionary = rooms[code]
	var state: Dictionary = room[peer_id]
	state["input"] = direction.limit_length(1.0)
	room[peer_id] = state
	rooms[code] = room

@rpc("authority", "call_remote", "reliable")
func _room_created(room_code: String) -> void:
	if _server_mode:
		return
	_requested_room_code = room_code
	if is_instance_valid(_room_code_field):
		_room_code_field.text = room_code
	_set_status("Đã tạo phòng. Gửi mã %s cho bạn của bạn." % room_code)
	_enter_multiplayer_game(room_code)

@rpc("authority", "call_remote", "reliable")
func _room_joined(room_code: String) -> void:
	if _server_mode:
		return
	_requested_room_code = room_code
	_set_status("Đã vào phòng %s. Dùng WASD để di chuyển." % room_code)
	_enter_multiplayer_game(room_code)

@rpc("authority", "call_remote", "reliable")
func _room_join_failed(message: String) -> void:
	if _server_mode:
		return
	_reset_session(message)

@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_snapshot(snapshot: Dictionary) -> void:
	if _server_mode:
		return
	other_players = snapshot
	var local_id := _multiplayer.get_unique_id()
	if snapshot.has(local_id):
		var local_state: Dictionary = snapshot[local_id]
		game.player = local_state["pos"]
		game.facing = local_state["facing"]
		game.anim = local_state["anim"]
	other_players.erase(local_id)

func _new_player_state(peer_id: int, slot: int) -> Dictionary:
	return {
		"id": peer_id,
		"pos": game.player + Vector2(18.0 * slot, 0.0),
		"facing": 0,
		"anim": 0.0,
		"input": Vector2.ZERO,
	}

func _simulate_rooms(delta: float) -> void:
	for code in rooms:
		var room: Dictionary = rooms[code]
		for peer_id in room:
			var state: Dictionary = room[peer_id]
			var direction: Vector2 = state.get("input", Vector2.ZERO)
			if direction != Vector2.ZERO:
				direction = direction.normalized()
				if absf(direction.x) > absf(direction.y):
					state["facing"] = 2 if direction.x < 0.0 else 3
				else:
					state["facing"] = 1 if direction.y < 0.0 else 0
				state["anim"] = float(state["anim"]) + delta
			state["pos"] = game.move_entity(state["pos"], direction * game.SPEED * delta)
			room[peer_id] = state
		rooms[code] = room

func _broadcast_snapshots() -> void:
	for code in rooms:
		_send_room_snapshot(code)

func _send_room_snapshot(code: String) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var snapshot: Dictionary = {}
	for peer_id in room:
		var state: Dictionary = room[peer_id]
		snapshot[peer_id] = {
			"id": peer_id,
			"pos": state["pos"],
			"facing": state["facing"],
			"anim": state["anim"],
		}
	for peer_id in room:
		rpc_id(peer_id, "_receive_snapshot", snapshot)

func _generate_room_code() -> String:
	var code := ""
	while code.is_empty() or rooms.has(code):
		code = ""
		for _index in range(ROOM_CODE_LENGTH):
			code += ROOM_CODE_CHARS[randi() % ROOM_CODE_CHARS.length()]
	return code

func _read_movement_input() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0
	return direction.normalized()

func _on_peer_connected(_peer_id: int) -> void:
	pass

func _on_peer_disconnected(peer_id: int) -> void:
	if not _server_mode or not peer_rooms.has(peer_id):
		return
	var code: String = peer_rooms[peer_id]
	peer_rooms.erase(peer_id)
	if rooms.has(code):
		var room: Dictionary = rooms[code]
		room.erase(peer_id)
		if room.is_empty():
			rooms.erase(code)
		else:
			rooms[code] = room
			_send_room_snapshot(code)

func _on_connected_to_server() -> void:
	_connection_elapsed = 0.0
	if _pending_action == "create":
		rpc_id(1, "_request_create_room")
	elif _pending_action == "join":
		rpc_id(1, "_request_join_room", _requested_room_code)
	else:
		_reset_session("Không xác định được thao tác kết nối.")

func _on_connection_failed() -> void:
	_reset_session("Kết nối thất bại. Kiểm tra địa chỉ server, cổng UDP và trạng thái server.")

func _on_server_disconnected() -> void:
	_reset_session("Mất kết nối với relay server.")

func _reset_session(message: String) -> void:
	_multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_session_active = false
	_pending_action = ""
	_requested_room_code = ""
	other_players.clear()
	_set_status(message)
	if not _server_mode and is_instance_valid(_connection_panel):
		_ui_state = &"multiplayer_setup"
		_set_ui_visibility()
		get_tree().paused = true

func _enter_multiplayer_game(room_code: String) -> void:
	_ui_state = &"gameplay"
	_session_badge.text = "Phòng %s  |  Esc: menu" % room_code
	_set_ui_visibility()
	get_tree().paused = false

func _create_mode_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)

	_screen_blur = ColorRect.new()
	_screen_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_blur.material = _make_blur_material()
	_ui_layer.add_child(_screen_blur)

	_mode_screen = Control.new()
	_mode_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_mode_screen)
	var mode_panel := _make_menu_panel(_mode_screen, Rect2(105, 20, 270, 230))
	var mode_column := VBoxContainer.new()
	mode_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mode_column.add_theme_constant_override("separation", 5)
	mode_panel.add_child(mode_column)
	var logo := TextureRect.new()
	logo.texture = load("res://quiz_exam_bank/assets/images/institution_logo.png")
	logo.custom_minimum_size = Vector2(76, 76)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mode_column.add_child(logo)
	var school_title := Label.new()
	school_title.text = "TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN"
	school_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	school_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	school_title.add_theme_font_size_override("font_size", 12)
	school_title.add_theme_color_override("font_color", Color("173a70"))
	mode_column.add_child(school_title)
	var game_title := Label.new()
	game_title.text = "MỘT NGÀY Ở HCMUS - ĐÔNG HÒA"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_size_override("font_size", 11)
	game_title.add_theme_color_override("font_color", Color("23395b"))
	mode_column.add_child(game_title)
	var singleplayer_button := Button.new()
	singleplayer_button.text = "Chơi đơn"
	singleplayer_button.custom_minimum_size = Vector2(0, 30)
	_style_multiplayer_button(singleplayer_button)
	singleplayer_button.pressed.connect(select_singleplayer)
	mode_column.add_child(singleplayer_button)
	var multiplayer_button := Button.new()
	multiplayer_button.text = "Multiplayer"
	multiplayer_button.custom_minimum_size = Vector2(0, 30)
	_style_multiplayer_button(multiplayer_button)
	multiplayer_button.pressed.connect(select_multiplayer)
	mode_column.add_child(multiplayer_button)

	_pause_screen = Control.new()
	_pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_pause_screen)
	var pause_panel := _make_menu_panel(_pause_screen, Rect2(132, 43, 216, 184))
	var pause_column := VBoxContainer.new()
	pause_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_column.add_theme_constant_override("separation", 7)
	pause_panel.add_child(pause_column)
	var pause_title := Label.new()
	pause_title.text = "TẠM DỪNG"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 16)
	pause_title.add_theme_color_override("font_color", Color("173a70"))
	pause_column.add_child(pause_title)
	var resume_button := Button.new()
	resume_button.text = "Tiếp tục"
	resume_button.custom_minimum_size = Vector2(0, 34)
	resume_button.pressed.connect(_resume_game)
	pause_column.add_child(resume_button)
	var time_button := Button.new()
	time_button.text = "Thời gian"
	time_button.custom_minimum_size = Vector2(0, 34)
	time_button.pressed.connect(_open_admin_time)
	pause_column.add_child(time_button)
	var mode_switch_button := Button.new()
	mode_switch_button.text = "Đổi chế độ"
	mode_switch_button.custom_minimum_size = Vector2(0, 34)
	mode_switch_button.pressed.connect(_switch_mode)
	pause_column.add_child(mode_switch_button)

	_session_badge = Label.new()
	_session_badge.position = Vector2(8, 8)
	_session_badge.size = Vector2(220, 28)
	_session_badge.add_theme_color_override("font_color", Color.WHITE)
	_session_badge.add_theme_stylebox_override("normal", _make_panel_style(Color(0.03, 0.07, 0.14, 0.85)))
	_ui_layer.add_child(_session_badge)

	_create_connection_panel()
	_ui_state = &"mode_select"
	_set_ui_visibility()
	get_tree().paused = true

func _make_blur_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius = 2.0;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_radius;
	vec4 color = texture(screen_texture, SCREEN_UV) * 0.20;
	color += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)) * 0.10;
	color += texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0)) * 0.10;
	color += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)) * 0.10;
	color += texture(screen_texture, SCREEN_UV - vec2(0.0, px.y)) * 0.10;
	color += texture(screen_texture, SCREEN_UV + px) * 0.10;
	color += texture(screen_texture, SCREEN_UV - px) * 0.10;
	color += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y)) * 0.10;
	color += texture(screen_texture, SCREEN_UV + vec2(-px.x, px.y)) * 0.10;
	color.rgb = mix(color.rgb, vec3(0.025, 0.055, 0.12), 0.38);
	color.a = 1.0;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _make_menu_panel(parent: Control, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.96, 0.97, 0.99, 0.97)))
	parent.add_child(panel)
	return panel

func _make_panel_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color("d3def0")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style

func _style_multiplayer_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_control_style(Color("155e75")))
	button.add_theme_stylebox_override("hover", _make_control_style(Color("0e7490")))
	button.add_theme_stylebox_override("pressed", _make_control_style(Color("164e63")))

func _create_connection_panel() -> void:
	_connection_panel = PanelContainer.new()
	_connection_panel.position = Vector2(35.0, 58.0)
	_connection_panel.size = Vector2(410.0, 154.0)
	_connection_panel.custom_minimum_size = Vector2(410.0, 154.0)
	_connection_panel.visible = false
	_connection_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("111827")))
	_ui_layer.add_child(_connection_panel)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 3)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connection_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "MULTIPLAYER"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 11)
	header.add_child(title)
	var back_button := Button.new()
	back_button.text = "Quay lại"
	back_button.custom_minimum_size = Vector2(70, 22)
	_style_small_button(back_button, Color("374151"))
	back_button.pressed.connect(_switch_mode)
	header.add_child(back_button)
	var server_row := HBoxContainer.new()
	column.add_child(server_row)
	var server_label := Label.new()
	server_label.text = "Server"
	server_label.custom_minimum_size.x = 42
	server_label.add_theme_color_override("font_color", Color("e2e8f0"))
	server_label.add_theme_font_size_override("font_size", 9)
	server_row.add_child(server_label)
	_address_field = LineEdit.new()
	_address_field.text = "127.0.0.1"
	_address_field.placeholder_text = "IP hoặc tên miền của relay server"
	_address_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_multiplayer_input(_address_field)
	server_row.add_child(_address_field)
	var port_label := Label.new()
	port_label.text = "Cổng:"
	port_label.add_theme_color_override("font_color", Color.WHITE)
	port_label.add_theme_font_size_override("font_size", 9)
	server_row.add_child(port_label)
	_port_field = SpinBox.new()
	_port_field.min_value = 1024
	_port_field.max_value = 65535
	_port_field.value = DEFAULT_PORT
	_port_field.step = 1
	_port_field.custom_minimum_size.x = 78
	_style_multiplayer_spinbox(_port_field)
	server_row.add_child(_port_field)
	var room_row := HBoxContainer.new()
	column.add_child(room_row)
	_room_code_field = LineEdit.new()
	_room_code_field.placeholder_text = "Mã phòng (để trống khi tạo)"
	_room_code_field.max_length = ROOM_CODE_LENGTH
	_room_code_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_multiplayer_input(_room_code_field)
	room_row.add_child(_room_code_field)
	var button_row := HBoxContainer.new()
	column.add_child(button_row)
	var host_button := Button.new()
	host_button.text = "Tạo phòng"
	host_button.custom_minimum_size = Vector2(84, 24)
	_style_small_button(host_button, Color("047857"))
	host_button.pressed.connect(_on_host_pressed)
	button_row.add_child(host_button)
	var join_button := Button.new()
	join_button.text = "Tham gia"
	join_button.custom_minimum_size = Vector2(84, 24)
	_style_small_button(join_button, Color("1d4ed8"))
	join_button.pressed.connect(_on_join_pressed)
	button_row.add_child(join_button)
	var disconnect_button := Button.new()
	disconnect_button.text = "Thoát phòng"
	disconnect_button.custom_minimum_size = Vector2(90, 24)
	_style_small_button(disconnect_button, Color("b91c1c"))
	disconnect_button.pressed.connect(disconnect_session)
	button_row.add_child(disconnect_button)
	_status_label = Label.new()
	_status_label.text = "127.0.0.1 dùng cùng máy; Internet cần IP relay server."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(350.0, 15.0)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_color_override("font_color", Color("e2e8f0"))
	_status_label.add_theme_font_size_override("font_size", 8)
	column.add_child(_status_label)

func _style_multiplayer_input(control: LineEdit) -> void:
	control.custom_minimum_size.y = 22
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_placeholder_color", Color("94a3b8"))
	control.add_theme_color_override("caret_color", Color.WHITE)
	control.add_theme_font_size_override("font_size", 9)
	control.add_theme_stylebox_override("normal", _make_control_style(Color("1f2937")))
	control.add_theme_stylebox_override("focus", _make_control_style(Color("1f2937")))
	control.add_theme_stylebox_override("read_only", _make_control_style(Color("1f2937")))

func _style_multiplayer_spinbox(control: SpinBox) -> void:
	control.custom_minimum_size = Vector2(78, 22)
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_stylebox_override("normal", _make_control_style(Color("1f2937")))
	control.add_theme_stylebox_override("focus", _make_control_style(Color("1f2937")))
	control.get_line_edit().add_theme_color_override("font_color", Color.WHITE)
	control.get_line_edit().add_theme_font_size_override("font_size", 9)

func _style_small_button(button: Button, color: Color) -> void:
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_control_style(color))
	button.add_theme_stylebox_override("hover", _make_control_style(color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _make_control_style(color.darkened(0.12)))

func _make_control_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color("64748b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	return style

func _on_host_pressed() -> void:
	host(_address_field.text, int(_port_field.value))

func _on_join_pressed() -> void:
	join(_address_field.text, int(_port_field.value), _room_code_field.text)

func _set_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = message
