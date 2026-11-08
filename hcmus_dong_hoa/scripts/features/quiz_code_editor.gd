extends Control

signal close_requested
signal submit_requested

var question: Dictionary = {}
var source_edit: CodeEdit
var input_edit: TextEdit
var output_edit: TextEdit
var status_label: Label
var editor_font_size := 10

const COLOR_TEXT := Color("202a38")
const COLOR_MUTED := Color("667386")
const COLOR_PANEL := Color("ffffff")
const COLOR_BORDER := Color("aab6c6")

func _ready() -> void:
	_build_ui()

func set_question(value: Dictionary) -> void:
	question = value
	if is_instance_valid(source_edit):
		source_edit.text = ""
	if is_instance_valid(input_edit):
		input_edit.text = ""
	if is_instance_valid(output_edit):
		output_edit.text = ""
	if is_instance_valid(status_label):
		status_label.text = "Test: chưa chạy (chưa có sandbox an toàn hoặc test case nguồn)."

func get_response() -> String:
	if str(question.get("answer_type", "")) == "code_output":
		return output_edit.text if is_instance_valid(output_edit) else ""
	return source_edit.text if is_instance_valid(source_edit) else ""

func set_editable(value: bool) -> void:
	if is_instance_valid(source_edit):
		source_edit.editable = value
	if is_instance_valid(input_edit):
		input_edit.editable = value
	if is_instance_valid(output_edit):
		output_edit.editable = value

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = Color("f3f6fa")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var heading := Label.new()
	heading.position = Vector2(8, 3)
	heading.size = Vector2(330, 20)
	heading.text = "IDE C++11 — bài làm"
	heading.add_theme_color_override("font_color", Color("173a70"))
	heading.add_theme_font_size_override("font_size", 12)
	add_child(heading)
	var zoom_out := Button.new()
	zoom_out.position = Vector2(342, 3)
	zoom_out.size = Vector2(30, 20)
	zoom_out.text = "A−"
	_style_button(zoom_out, Color("46617f"))
	zoom_out.pressed.connect(_zoom_out)
	add_child(zoom_out)
	var zoom_in := Button.new()
	zoom_in.position = Vector2(376, 3)
	zoom_in.size = Vector2(30, 20)
	zoom_in.text = "A+"
	_style_button(zoom_in, Color("46617f"))
	zoom_in.pressed.connect(_zoom_in)
	add_child(zoom_in)
	var close := Button.new()
	close.position = Vector2(430, 3)
	close.size = Vector2(42, 20)
	close.text = "Đóng"
	_style_button(close, Color("8b3c4a"))
	close.pressed.connect(func() -> void:
		hide()
		close_requested.emit()
	)
	add_child(close)
	source_edit = CodeEdit.new()
	source_edit.position = Vector2(8, 27)
	source_edit.size = Vector2(464, 96)
	source_edit.gutters_draw_line_numbers = true
	source_edit.indent_size = 4
	source_edit.indent_use_spaces = true
	source_edit.indent_automatic = true
	source_edit.code_completion_enabled = true
	source_edit.auto_brace_completion_enabled = true
	source_edit.add_theme_font_size_override("font_size", editor_font_size)
	_style_text_edit(source_edit)
	source_edit.add_theme_color_override("line_number_color", Color("667386"))
	source_edit.add_theme_color_override("current_line_color", Color("edf4ff"))
	var highlighter := CodeHighlighter.new()
	for keyword in ["int", "void", "double", "float", "bool", "class", "const", "using"]:
		highlighter.add_keyword_color(keyword, Color("075985"))
	for keyword in ["if", "else", "for", "while", "return"]:
		highlighter.add_keyword_color(keyword, Color("b45309"))
	for keyword in ["std", "cout", "cin", "endl"]:
		highlighter.add_keyword_color(keyword, Color("6d28d9"))
	highlighter.add_color_region("\"", "\"", Color("15803d"))
	highlighter.add_color_region("//", "", Color("64748b"), true)
	source_edit.syntax_highlighter = highlighter
	add_child(source_edit)
	var input_label := Label.new()
	input_label.position = Vector2(8, 126)
	input_label.size = Vector2(220, 14)
	input_label.text = "Input (stdin)"
	input_label.add_theme_color_override("font_color", Color("075985"))
	input_label.add_theme_font_size_override("font_size", 9)
	add_child(input_label)
	var output_label := Label.new()
	output_label.position = Vector2(244, 126)
	output_label.size = Vector2(220, 14)
	output_label.text = "Output / đáp số"
	output_label.add_theme_color_override("font_color", Color("166534"))
	output_label.add_theme_font_size_override("font_size", 9)
	add_child(output_label)
	input_edit = TextEdit.new()
	input_edit.position = Vector2(8, 141)
	input_edit.size = Vector2(224, 72)
	input_edit.placeholder_text = "Nhập dữ liệu đầu vào"
	input_edit.add_theme_font_size_override("font_size", editor_font_size - 1)
	_style_text_edit(input_edit)
	add_child(input_edit)
	output_edit = TextEdit.new()
	output_edit.position = Vector2(244, 141)
	output_edit.size = Vector2(228, 72)
	output_edit.placeholder_text = "Nhập output / đáp số"
	output_edit.add_theme_font_size_override("font_size", editor_font_size - 1)
	_style_text_edit(output_edit)
	add_child(output_edit)
	status_label = Label.new()
	status_label.position = Vector2(8, 216)
	status_label.size = Vector2(464, 16)
	status_label.text = "Test: chưa chạy (chưa có sandbox an toàn hoặc test case nguồn)."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.add_theme_color_override("font_color", Color("805800"))
	add_child(status_label)
	var run_button := Button.new()
	run_button.position = Vector2(298, 237)
	run_button.size = Vector2(78, 25)
	run_button.text = "Run"
	_style_button(run_button, Color("24567c"))
	run_button.pressed.connect(_run_code)
	add_child(run_button)
	var submit_button := Button.new()
	submit_button.position = Vector2(384, 237)
	submit_button.size = Vector2(88, 25)
	submit_button.text = "Submit"
	_style_button(submit_button, Color("286144"))
	submit_button.pressed.connect(func() -> void:
		submit_requested.emit()
	)
	add_child(submit_button)

func _style_text_edit(edit: TextEdit) -> void:
	edit.add_theme_color_override("font_color", COLOR_TEXT)
	edit.add_theme_color_override("font_readonly_color", COLOR_TEXT)
	edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	edit.add_theme_color_override("line_number_color", Color("667386"))
	edit.add_theme_color_override("current_line_color", Color("edf4ff"))
	edit.add_theme_color_override("selection_color", Color("a9cfff"))
	edit.add_theme_color_override("caret_color", Color("173a70"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PANEL
	normal.border_color = COLOR_BORDER
	normal.set_border_width_all(1)
	normal.set_content_margin_all(4)
	edit.add_theme_stylebox_override("normal", normal)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color("78c6ff")
	edit.add_theme_stylebox_override("focus", focus)
	var read_only := normal.duplicate() as StyleBoxFlat
	read_only.bg_color = Color("f1f3f6")
	edit.add_theme_stylebox_override("read_only", read_only)

func _style_button(button: Button, color: Color) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 8)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = Color("91a6c4")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.18)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.18)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func _zoom_in() -> void:
	_set_editor_font_size(editor_font_size + 1)

func _zoom_out() -> void:
	_set_editor_font_size(editor_font_size - 1)

func _set_editor_font_size(value: int) -> void:
	editor_font_size = clampi(value, 8, 18)
	for edit in [source_edit, input_edit, output_edit]:
		if is_instance_valid(edit):
			edit.add_theme_font_size_override("font_size", editor_font_size if edit == source_edit else editor_font_size - 1)

func _run_code() -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = "Không chạy code trong game. Input và output/đáp số được nhập riêng để nộp bài."
