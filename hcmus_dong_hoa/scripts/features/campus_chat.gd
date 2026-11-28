extends "res://scripts/features/feature.gd"
# Chat chung gon nhe. API relay hien tai chua co RPC gui/nhan chat,
# vi vay che do choi don duoc ghi ro la tin nhan cuc bo.
#
# GHI CHU KY THUAT (ban nang cap):
#  - Panel NEO THEO DAY man hinh (anchor bottom). Truoc day toa do co dinh theo y = 186
#    nen khi cua so thap hon ti le 16:9 thi o nhap bi cat mat o day.
#  - Lich su chat duoc ve bang draw_string (3 dong) thay vi Label, nen khong con
#    bi chong len o nhap. O nhap LineEdit nam trong khung cat (clip) nen chieu cao
#    tu nhien cua font khong lam phinh o chat.
#  - Nhan Enter khi o nhap trong, hoac bam ra ngoai khung chat, se tra lai dieu khien
#    cho nguoi choi (truoc day phai bam Esc).
#  - Ham receive_chat_message(sender, text) de module multiplayer goi khi co tin den.

const PANEL_BG := Color(0.035, 0.075, 0.14, 0.96)
const PANEL_BORDER := Color("6d89ad")
const TEXT_MAIN := Color("f4f7ff")
const TEXT_MUTED := Color("b7c7dd")
const ACCENT := Color("75c8ff")
const GOLD := Color("ffdc75")
const MAX_STORED_MESSAGES := 40
const VISIBLE_LINES := 3
const MAX_MESSAGE_LENGTH := 120

# Kich thuoc (don vi viewport goc 480 x 270) va khoang cach tu day man hinh.
const PANEL_LEFT := 6.0
const PANEL_WIDTH := 168.0
const EXPANDED_HEIGHT := 60.0
const COLLAPSED_HEIGHT := 14.0
const BOTTOM_MARGIN := 24.0   # chua cho cho dong phim dieu khien o day man hinh
const PAD := 6.0
const INPUT_HEIGHT := 16.0
const LINE_HEIGHT := 7.0

var layer: CanvasLayer
var chat_root: Control        # neo theo day man hinh; moi toa do ben trong la toa do cuc bo
var panel: Control            # ve nen, tieu de va lich su
var message_frame: Panel
var message_input: LineEdit
var send_button: Button
var collapse_button: Button
var collapsed := false
var messages: Array = []      # moi phan tu: {"sender", "text", "kind"}
var unread := 0
var status_text := "Cục bộ"
var status_elapsed := 0.0
var font: Font
var _style_cache: Dictionary = {}

func _ready() -> void:
	font = game.font
	_build_chat_ui()
	_add_system_message("Nhấn T hoặc Enter để trò chuyện.")
	_update_connection_status()

func _build_chat_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 9
	add_child(layer)

	chat_root = Control.new()
	chat_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(chat_root)

	panel = Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP   # bam vao khung chat khong "xuyen" xuong game
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chat_root.add_child(panel)
	panel.draw.connect(_on_panel_draw)

	collapse_button = Button.new()
	collapse_button.focus_mode = Control.FOCUS_NONE
	collapse_button.text = "−"
	collapse_button.tooltip_text = "Thu gọn / mở rộng"
	_style_button(collapse_button, Color("29466b"))
	collapse_button.pressed.connect(_toggle_collapsed)
	chat_root.add_child(collapse_button)

	# Khung nhap: Panel co clip_contents, LineEdit ben trong duoc can giua theo chieu doc.
	message_frame = Panel.new()
	message_frame.clip_contents = true
	message_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	message_frame.add_theme_stylebox_override("panel", _input_frame_style(false))
	chat_root.add_child(message_frame)

	message_input = LineEdit.new()
	message_input.placeholder_text = "Nhập tin nhắn..."
	message_input.max_length = MAX_MESSAGE_LENGTH
	message_input.focus_mode = Control.FOCUS_ALL
	message_input.context_menu_enabled = false
	message_input.add_theme_font_override("font", font)
	message_input.add_theme_font_size_override("font_size", 5)
	message_input.add_theme_color_override("font_color", TEXT_MAIN)
	message_input.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	message_input.add_theme_color_override("caret_color", ACCENT)
	var empty := StyleBoxEmpty.new()
	empty.set_content_margin(SIDE_LEFT, 4)
	empty.set_content_margin(SIDE_RIGHT, 3)
	empty.set_content_margin(SIDE_TOP, 0)
	empty.set_content_margin(SIDE_BOTTOM, 0)
	message_input.add_theme_stylebox_override("normal", empty)
	message_input.add_theme_stylebox_override("focus", empty)
	message_input.add_theme_stylebox_override("read_only", empty)
	message_input.text_submitted.connect(_on_message_submitted)
	message_input.text_changed.connect(_on_text_changed)
	message_input.focus_entered.connect(_on_input_focus_entered)
	message_input.focus_exited.connect(_on_input_focus_exited)
	message_frame.add_child(message_input)

	send_button = Button.new()
	send_button.text = "Gửi"
	send_button.focus_mode = Control.FOCUS_NONE
	_style_button(send_button, Color("1769aa"))
	send_button.pressed.connect(_send_current_message)
	chat_root.add_child(send_button)

	_apply_layout()
	_update_send_button()

# Dat lai vi tri moi thanh phan theo trang thai thu gon / mo rong.
func _apply_layout() -> void:
	var height := COLLAPSED_HEIGHT if collapsed else EXPANDED_HEIGHT
	chat_root.anchor_left = 0.0
	chat_root.anchor_right = 0.0
	chat_root.anchor_top = 1.0
	chat_root.anchor_bottom = 1.0
	chat_root.offset_left = PANEL_LEFT
	chat_root.offset_right = PANEL_LEFT + PANEL_WIDTH
	chat_root.offset_bottom = -BOTTOM_MARGIN
	chat_root.offset_top = -BOTTOM_MARGIN - height

	collapse_button.position = Vector2(PANEL_WIDTH - 21.0, 1.0)
	collapse_button.size = Vector2(15.0, 12.0)
	collapse_button.text = "+" if collapsed else "−"

	var input_y := EXPANDED_HEIGHT - PAD - INPUT_HEIGHT
	message_frame.position = Vector2(PAD, input_y)
	message_frame.size = Vector2(PANEL_WIDTH - PAD * 2.0 - 30.0, INPUT_HEIGHT)
	send_button.position = Vector2(PANEL_WIDTH - PAD - 27.0, input_y)
	send_button.size = Vector2(27.0, INPUT_HEIGHT)

	message_frame.visible = not collapsed
	send_button.visible = not collapsed
	_fit_input_height()
	if is_instance_valid(panel):
		panel.queue_redraw()

# LineEdit co chieu cao toi thieu theo font; can no vao giua khung nhap co dinh.
func _fit_input_height() -> void:
	var needed := maxf(INPUT_HEIGHT, message_input.get_combined_minimum_size().y)
	message_input.size = Vector2(message_frame.size.x, needed)
	message_input.position = Vector2(0.0, (INPUT_HEIGHT - needed) * 0.5)

func _process(delta: float) -> void:
	status_elapsed += delta
	if status_elapsed >= 0.5:
		status_elapsed = 0.0
		_update_connection_status()
	# Khong de chat phu len cua so thi/Quiz hoac feature khac dang mo.
	if is_instance_valid(chat_root):
		chat_root.visible = not game.is_busy() or message_input.has_focus()

func _unhandled_input(event: InputEvent) -> void:
	# Bam chuot ra ngoai khung chat -> thoat che do go chu, nguoi choi di chuyen lai duoc.
	if event is InputEventMouseButton and event.pressed and message_input.has_focus():
		var inside := Rect2(chat_root.global_position, chat_root.size).has_point(event.position)
		if not inside:
			message_input.release_focus()
		return

	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	if message_input.has_focus():
		if key.keycode == KEY_ESCAPE:
			message_input.release_focus()
			get_viewport().set_input_as_handled()
		return

	if key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_T] and not game.is_busy():
		if collapsed:
			_toggle_collapsed()
		message_input.grab_focus()
		get_viewport().set_input_as_handled()

func _on_input_focus_entered() -> void:
	begin()
	message_frame.add_theme_stylebox_override("panel", _input_frame_style(true))

func _on_input_focus_exited() -> void:
	finish()
	message_frame.add_theme_stylebox_override("panel", _input_frame_style(false))

func _on_message_submitted(_value: String) -> void:
	# Enter khi o trong: ket thuc go chu de quay lai choi.
	if message_input.text.strip_edges().is_empty():
		message_input.release_focus()
		return
	_send_current_message()

func _on_text_changed(_value: String) -> void:
	_update_send_button()

func _update_send_button() -> void:
	if not is_instance_valid(send_button):
		return
	var has_text := not message_input.text.strip_edges().is_empty()
	send_button.disabled = not has_text
	send_button.modulate = Color(1, 1, 1, 1.0 if has_text else 0.55)

func _send_current_message() -> void:
	var message := message_input.text.strip_edges()
	if message.is_empty():
		return

	var manager: Node = game.multiplayer_manager
	if manager != null and manager.has_method("is_connected_to_session") and manager.is_connected_to_session():
		if manager.has_method("send_chat_message"):
			manager.call("send_chat_message", message)
			_add_message("Bạn", message, "self")
		else:
			_add_system_message("Relay chưa hỗ trợ Chat chung.")
			return
	else:
		_add_message("Bạn · cục bộ", message, "self")

	message_input.clear()
	_update_send_button()
	# Gui xong tra dieu khien ngay cho nguoi choi (kieu Roblox): nhan T/Enter de chat tiep.
	message_input.release_focus()

# Module multiplayer goi ham nay khi nhan duoc tin nhan tu nguoi choi khac.
func receive_chat_message(sender: String, message: String) -> void:
	_add_message(sender, message, "other")

func _add_message(sender: String, message: String, kind: String) -> void:
	var safe_message := message.replace("\n", " ").replace("\r", " ").strip_edges()
	messages.append({"sender": sender, "text": safe_message, "kind": kind})
	while messages.size() > MAX_STORED_MESSAGES:
		messages.pop_front()
	if collapsed and kind == "other":
		unread += 1
	if is_instance_valid(panel):
		panel.queue_redraw()

func _add_system_message(message: String) -> void:
	_add_message("Hệ thống", message, "system")

func _update_connection_status() -> void:
	var new_status := "Cục bộ"
	var manager: Node = game.multiplayer_manager
	if manager != null and manager.has_method("is_connected_to_session") and manager.is_connected_to_session():
		if manager.has_method("send_chat_message"):
			var player_count := 1
			if manager.has_method("get_other_players"):
				player_count += manager.call("get_other_players").size()
			new_status = "%d người" % player_count
		else:
			new_status = "Phòng · chưa chat"
	if new_status != status_text:
		status_text = new_status
		if is_instance_valid(panel):
			panel.queue_redraw()

func _toggle_collapsed() -> void:
	collapsed = not collapsed
	if collapsed:
		if message_input.has_focus():
			message_input.release_focus()
	else:
		unread = 0
	_apply_layout()

func begin() -> void:
	super()

func finish() -> void:
	super()

# ---------------------------------------------------------------------------
# Ve
# ---------------------------------------------------------------------------

func _text_width(text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x

func _fit_text(text: String, width: float, size: int) -> String:
	if width <= 0.0:
		return ""
	if _text_width(text, size) <= width:
		return text
	var cut := text
	while cut.length() > 1 and _text_width(cut + "...", size) > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "..."

# Ve chu voi bong do nhe, can giua theo chieu doc quanh center_y.
func _draw_text(text: String, x: float, center_y: float, width: float, color: Color, size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var shown := _fit_text(text, width, size)
	var base := Vector2(x, center_y + float(size) * 0.36)
	panel.draw_string(font, base + Vector2(1, 1), shown, align, width, size, Color(0, 0, 0, 0.7))
	panel.draw_string(font, base, shown, align, width, size, color)

func _on_panel_draw() -> void:
	var height := COLLAPSED_HEIGHT if collapsed else EXPANDED_HEIGHT
	var area := Rect2(0.0, 0.0, PANEL_WIDTH, height)
	panel.draw_style_box(_panel_style(PANEL_BG, PANEL_BORDER, 8), area)

	# Hang tieu de.
	_draw_text("CHAT CHUNG", PAD + 3.0, 7.0, 62.0, TEXT_MAIN, 6)
	var status_right := PANEL_WIDTH - 25.0
	if collapsed and unread > 0:
		var badge := "%d mới" % unread
		_draw_text(badge, 76.0, 7.0, status_right - 76.0, GOLD, 5, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		_draw_text(status_text, 76.0, 7.0, status_right - 76.0, TEXT_MUTED, 5, HORIZONTAL_ALIGNMENT_RIGHT)
	if collapsed:
		return

	panel.draw_line(Vector2(PAD, 14.5), Vector2(PANEL_WIDTH - PAD, 14.5), Color(0.55, 0.72, 0.92, 0.30), 1.0)

	# Lich su: VISIBLE_LINES dong gan nhat, tin moi nhat o duoi cung, tin cu mo dan.
	var first := maxi(0, messages.size() - VISIBLE_LINES)
	var shown_count := messages.size() - first
	var line_width := PANEL_WIDTH - PAD * 2.0
	for i in range(first, messages.size()):
		var row := i - first
		var entry: Dictionary = messages[i]
		var center_y := 16.0 + LINE_HEIGHT * (float(row) + 0.5) + float(VISIBLE_LINES - shown_count) * LINE_HEIGHT
		var fade := 1.0 if i == messages.size() - 1 else 0.78
		var sender_color := ACCENT
		var text_color := TEXT_MAIN
		match str(entry.kind):
			"system":
				sender_color = TEXT_MUTED
				text_color = TEXT_MUTED
			"other":
				sender_color = GOLD
		sender_color.a = fade
		text_color.a = fade
		var sender_text := str(entry.sender) + ": "
		var sender_width := minf(_text_width(sender_text, 5), line_width * 0.5)
		_draw_text(sender_text, PAD, center_y, sender_width, sender_color, 5)
		_draw_text(str(entry.text), PAD + sender_width, center_y, line_width - sender_width, text_color, 5)

# ---------------------------------------------------------------------------
# Style
# ---------------------------------------------------------------------------

func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var key := "p|%s|%s|%d" % [background.to_html(true), border.to_html(true), radius]
	if _style_cache.has(key):
		return _style_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	style.set_content_margin_all(0)
	_style_cache[key] = style
	return style

func _input_frame_style(focused: bool) -> StyleBoxFlat:
	var key := "i|%s" % str(focused)
	if _style_cache.has(key):
		return _style_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14253d")
	style.border_color = ACCENT if focused else Color("506b90")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(0)
	_style_cache[key] = style
	return style

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 5)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(color, Color("8fb7e0"), 5))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.18), Color("c5e6ff"), 5))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.16), Color("8fb7e0"), 5))
	button.add_theme_stylebox_override("disabled", _panel_style(color.darkened(0.35), Color("506b90"), 5))
