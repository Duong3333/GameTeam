extends Control

var answer_cells: Array[LineEdit] = []
var comma_markers: Array[Label] = []
var negative_button: Button
var decimal_position := -1
var is_negative := false

func _ready() -> void:
	_build_ui()

func get_response() -> String:
	var digits := ""
	var found_empty := false
	for cell in answer_cells:
		if cell.text.is_empty():
			found_empty = true
		else:
			if found_empty:
				return ""
			digits += cell.text
	if digits.is_empty():
		return ""
	if decimal_position >= 0:
		var position := mini(decimal_position, digits.length())
		digits = digits.insert(position, ",")
	if is_negative:
		digits = "-" + digits
	return digits

func clear_answer() -> void:
	for cell in answer_cells:
		cell.clear()
	decimal_position = -1
	is_negative = false
	_update_format_marks()

func set_editable(value: bool) -> void:
	if is_instance_valid(negative_button):
		negative_button.disabled = not value
	for cell in answer_cells:
		cell.editable = value

func _build_ui() -> void:
	var instruction := Label.new()
	instruction.position = Vector2(0, 0)
	instruction.size = Vector2(424, 16)
	instruction.text = "ĐÁP SỐ NGẮN  ·  4 CHỮ SỐ  ·  NHẤN , HOẶC . ĐỂ ĐẶT DẤU PHẨY"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 8)
	instruction.add_theme_color_override("font_color", Color("dbe7f6"))
	add_child(instruction)

	negative_button = Button.new()
	negative_button.position = Vector2(87, 20)
	negative_button.size = Vector2(34, 36)
	negative_button.text = "±"
	negative_button.focus_mode = Control.FOCUS_NONE
	negative_button.add_theme_font_size_override("font_size", 15)
	negative_button.add_theme_color_override("font_color", Color("f1f5fb"))
	var sign_style := StyleBoxFlat.new()
	sign_style.bg_color = Color("24415f")
	sign_style.border_color = Color("6685a8")
	sign_style.set_border_width_all(1)
	sign_style.set_corner_radius_all(3)
	negative_button.add_theme_stylebox_override("normal", sign_style)
	var sign_focus := sign_style.duplicate() as StyleBoxFlat
	sign_focus.bg_color = Color("315779")
	negative_button.add_theme_stylebox_override("hover", sign_focus)
	negative_button.pressed.connect(_toggle_sign)
	add_child(negative_button)

	for position in range(5):
		var marker := Label.new()
		marker.text = ","
		marker.size = Vector2(12, 36)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 15)
		marker.add_theme_color_override("font_color", Color("ffd66b"))
		marker.visible = false
		if position == 0:
			marker.position = Vector2(125, 20)
		else:
			marker.position = Vector2(137 + (position - 1) * 50 + 38, 20)
		add_child(marker)
		comma_markers.append(marker)

	for index in range(4):
		var cell := LineEdit.new()
		cell.position = Vector2(137 + index * 50, 20)
		cell.size = Vector2(38, 36)
		cell.max_length = 1
		cell.alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_theme_font_size_override("font_size", 15)
		cell.add_theme_color_override("font_color", Color("f1f5fb"))
		cell.add_theme_color_override("caret_color", Color("ffd66b"))
		cell.add_theme_color_override("selection_color", Color("6685a8"))
		cell.add_theme_color_override("font_placeholder_color", Color("b4c2d4"))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("101a2b")
		normal.border_color = Color("6685a8")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(3)
		normal.set_content_margin_all(2)
		cell.add_theme_stylebox_override("normal", normal)
		var focus := normal.duplicate() as StyleBoxFlat
		focus.border_color = Color("ffd66b")
		cell.add_theme_stylebox_override("focus", focus)
		cell.text_changed.connect(_on_cell_text_changed.bind(index))
		cell.gui_input.connect(_on_cell_gui_input.bind(index))
		add_child(cell)
		answer_cells.append(cell)
	_update_format_marks()

func _on_cell_text_changed(value: String, index: int) -> void:
	if not value.is_empty() and not value.is_valid_int():
		answer_cells[index].clear()
		return
	if not value.is_empty() and index < answer_cells.size() - 1:
		answer_cells[index + 1].grab_focus()

func _on_cell_gui_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_COMMA or key.keycode == KEY_PERIOD:
		decimal_position = index
		_update_format_marks()
		answer_cells[index].accept_event()
	elif key.keycode == KEY_MINUS:
		_toggle_sign()
		answer_cells[index].accept_event()
	elif key.keycode == KEY_BACKSPACE and answer_cells[index].text.is_empty() and index > 0:
		answer_cells[index - 1].grab_focus()
		answer_cells[index - 1].set_caret_column(answer_cells[index - 1].text.length())
		answer_cells[index].accept_event()
	elif key.keycode == KEY_LEFT and index > 0:
		answer_cells[index - 1].grab_focus()
		answer_cells[index - 1].set_caret_column(answer_cells[index - 1].text.length())
		answer_cells[index].accept_event()
	elif key.keycode == KEY_RIGHT and index < answer_cells.size() - 1:
		answer_cells[index + 1].grab_focus()
		answer_cells[index + 1].set_caret_column(answer_cells[index + 1].text.length())
		answer_cells[index].accept_event()

func _toggle_sign() -> void:
	is_negative = not is_negative
	negative_button.text = "−" if is_negative else "±"

func _update_format_marks() -> void:
	for index in range(comma_markers.size()):
		comma_markers[index].visible = index == decimal_position
