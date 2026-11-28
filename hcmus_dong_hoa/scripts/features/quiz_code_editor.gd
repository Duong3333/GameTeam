extends Control

const TestBank := preload("res://scripts/features/programming_test_bank.gd")
const Workspace := preload("res://scripts/features/cpp_ide_save_manager.gd")

signal close_requested
signal submit_requested
signal run_requested(source_code: String, input_text: String)

var question: Dictionary = {}
var source_edit: CodeEdit
var input_edit: TextEdit
var output_edit: TextEdit
var input_panel: PanelContainer
var status_label: Label
var run_button: Button
var submit_button: Button
var save_button: Button
var editor_font_size := 8
var _save_timer: Timer
var _loading_workspace := false
var _initial_source := ""

const BG := Color("111827")
const PANEL := Color("1f2937")
const PANEL_DARK := Color("0f172a")
const BORDER := Color("374151")
const TEXT := Color("e5e7eb")
const MUTED := Color("9ca3af")
const BLUE := Color("2563eb")
const GREEN := Color("15803d")
const KEYWORD_COLOR := Color("7dd3fc")
const SNIPPET_COLOR := Color("fde68a")
const LIBRARY_COLOR := Color("f9a8d4")
const VARIABLE_COLOR := Color("e5e7eb")
const ERROR_LINE_COLOR := Color(0.75, 0.2, 0.2, 0.32)
const RESET_CONFIRM_SECONDS := 3.0
const COMPILE_ERROR_PATTERN := "(?:submission\\.cpp:(\\d+):(\\d+):|Dòng (\\d+):)\\s*(?:fatal )?error:\\s*(.*)"

const CPP_KEYWORDS := ["int", "long", "short", "unsigned", "signed", "char", "bool", "float", "double", "void", "auto", "const", "static", "struct", "class", "enum", "return", "if", "else", "for", "while", "do", "switch", "case", "break", "continue", "true", "false", "nullptr", "sizeof", "using", "namespace", "template", "typename", "new", "delete"]
const CPP_LIBRARY := ["cout", "cin", "endl", "vector", "string", "sort", "max", "min", "abs", "swap", "sqrt", "pow", "floor", "ceil", "to_string", "reverse", "setprecision", "fixed", "size", "push_back", "pop_back", "length", "substr", "find", "begin", "end"]
const CPP_SNIPPETS := {
	"for": "for (int i = 0; i < n; i++) {\n\t\n}",
	"while": "while (cond) {\n\t\n}",
	"if": "if (cond) {\n\t\n}",
	"ifelse": "if (cond) {\n\t\n} else {\n\t\n}",
	"cout": "cout << \"\" << endl;",
	"cin": "cin >> ;",
}

var reset_button: Button
var prototype_button: Button
var backend_label: Label
var position_label: Label
var _reset_timer: Timer
var _reset_armed := false
var _error_lines: Array[int] = []

func _ready() -> void:
	_build_ui()
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.8
	_save_timer.timeout.connect(_save_workspace)
	add_child(_save_timer)
	_reset_timer = Timer.new()
	_reset_timer.one_shot = true
	_reset_timer.wait_time = RESET_CONFIRM_SECONDS
	_reset_timer.timeout.connect(_disarm_reset)
	add_child(_reset_timer)

func set_question(value: Dictionary) -> void:
	question = value
	var answer_type := str(question.get("answer_type", ""))
	var question_id := str(question.get("id", ""))
	var can_run := answer_type == "short_code" and TestBank.supports(question_id)

	_loading_workspace = true
	_disarm_reset()
	_clear_error_marks()
	var saved := Workspace.load_workspace(question_id)
	if is_instance_valid(source_edit):
		source_edit.text = str(saved.get("source", ""))
		source_edit.editable = true
		if question_id in ["CSLT_EXAM_002_Q01", "CSLT_EXAM_004_Q01"]:
			source_edit.placeholder_text = "Viết đoạn lệnh if/else theo đề (không cần main() hay include)."
		elif answer_type == "short_code":
			source_edit.placeholder_text = "Chỉ viết định nghĩa các hàm được yêu cầu. Hệ thống cung cấp main(), struct, prototype và testcase."
		else:
			source_edit.placeholder_text = "Nhập lời giải hoặc phần giải thích của bạn tại đây."
	var default_input := TestBank.get_default_input(question_id)
	var is_composite_midterm := question_id.begins_with("CSLT_MID_")
	var uses_stdin := (not default_input.is_empty()) and (not is_composite_midterm)
	if is_instance_valid(input_panel):
		input_panel.visible = uses_stdin
	if is_instance_valid(input_edit):
		var saved_input := str(saved.get("input", ""))
		input_edit.text = saved_input if not saved_input.is_empty() else default_input
		input_edit.editable = true
		input_edit.placeholder_text = "Nhập dữ liệu đầu vào để thử chương trình" if uses_stdin else "Testcase mẫu do hệ thống cung cấp"
	if is_instance_valid(output_edit):
		output_edit.text = ""
		output_edit.editable = answer_type == "code_output"
		output_edit.placeholder_text = "Output chạy thử hoặc đáp số"
	_initial_source = str(source_edit.text) if is_instance_valid(source_edit) else ""
	_loading_workspace = false

	if is_instance_valid(status_label):
		if can_run:
			status_label.text = ("Ctrl+R chạy thử với Input  ·  " if uses_stdin else "Ctrl+R chạy testcase mẫu  ·  ") + "Ctrl+Enter nộp bài  ·  Ctrl+S lưu"
		elif answer_type == "code_output":
			status_label.text = "Nhập output / đáp số vào vùng kết quả rồi Submit."
		elif answer_type == "short_code":
			status_label.text = "Câu này chưa có testcase tự động."
		else:
			status_label.text = "Nhập lời giải vào vùng soạn thảo rồi Submit."
	if is_instance_valid(run_button):
		run_button.disabled = not can_run
	if is_instance_valid(save_button):
		save_button.disabled = false
	if is_instance_valid(prototype_button):
		var funcs: Variant = question.get("required_functions", [])
		prototype_button.visible = typeof(funcs) == TYPE_ARRAY and not (funcs as Array).is_empty()
	set_busy(false)

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
		output_edit.editable = value and str(question.get("answer_type", "")) == "code_output"
	if is_instance_valid(save_button):
		save_button.disabled = not value

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var topbar := HBoxContainer.new()
	topbar.add_theme_constant_override("separation", 5)
	layout.add_child(topbar)

	var heading := Label.new()
	heading.text = "C++ PRACTICE"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_color_override("font_color", TEXT)
	heading.add_theme_font_size_override("font_size", 12)
	topbar.add_child(heading)

	var standard_label := Label.new()
	standard_label.text = "C++17"
	standard_label.add_theme_color_override("font_color", Color("86efac"))
	standard_label.add_theme_font_size_override("font_size", 9)
	topbar.add_child(standard_label)

	backend_label = Label.new()
	backend_label.text = "· Online Judge" if OS.has_feature("web") else "· Local GCC"
	backend_label.add_theme_color_override("font_color", Color("93c5fd") if OS.has_feature("web") else MUTED)
	backend_label.add_theme_font_size_override("font_size", 9)
	topbar.add_child(backend_label)

	var zoom_out := _make_button("A−", Color("475569"), 28)
	zoom_out.pressed.connect(func() -> void: _set_editor_font_size(editor_font_size - 1))
	topbar.add_child(zoom_out)

	var zoom_in := _make_button("A+", Color("475569"), 28)
	zoom_in.pressed.connect(func() -> void: _set_editor_font_size(editor_font_size + 1))
	topbar.add_child(zoom_in)

	var close := _make_button("×", Color("7f1d1d"), 28)
	close.pressed.connect(func() -> void:
		_save_workspace()
		hide()
		close_requested.emit()
	)
	topbar.add_child(close)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	layout.add_child(body)

	var editor_panel := _make_panel()
	editor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_panel.size_flags_stretch_ratio = 2.15
	body.add_child(editor_panel)

	var editor_box := VBoxContainer.new()
	editor_box.add_theme_constant_override("separation", 3)
	editor_panel.add_child(editor_box)

	var file_label := Label.new()
	file_label.text = "●  solution.cpp · C++17"
	file_label.add_theme_color_override("font_color", Color("93c5fd"))
	file_label.add_theme_font_size_override("font_size", 9)
	editor_box.add_child(file_label)

	source_edit = CodeEdit.new()
	source_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	source_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_edit.gutters_draw_line_numbers = true
	source_edit.indent_size = 4
	source_edit.indent_use_spaces = true
	source_edit.indent_automatic = true
	source_edit.auto_brace_completion_enabled = true
	source_edit.code_completion_enabled = true
	var completion_prefixes: Array[String] = ["."]
	source_edit.code_completion_prefixes = completion_prefixes
	source_edit.code_completion_requested.connect(_on_completion_requested)
	source_edit.highlight_all_occurrences = true
	source_edit.caret_changed.connect(_update_position_label)
	source_edit.add_theme_font_size_override("font_size", editor_font_size)
	source_edit.add_theme_color_override("font_color", TEXT)
	source_edit.add_theme_color_override("line_number_color", MUTED)
	source_edit.add_theme_color_override("current_line_color", Color("263449"))
	source_edit.add_theme_color_override("caret_color", Color("f8fafc"))
	source_edit.add_theme_color_override("selection_color", Color("36577e"))
	_style_text_area(source_edit)
	source_edit.syntax_highlighter = _make_cpp_highlighter()
	source_edit.text_changed.connect(_on_source_changed)
	editor_box.add_child(source_edit)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.85
	side.add_theme_constant_override("separation", 5)
	body.add_child(side)

	input_panel = _make_panel()
	input_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	input_panel.size_flags_stretch_ratio = 1.0
	side.add_child(input_panel)

	var input_box := VBoxContainer.new()
	input_box.add_theme_constant_override("separation", 3)
	input_panel.add_child(input_box)

	var input_title := Label.new()
	input_title.text = "INPUT  ·  stdin"
	input_title.add_theme_color_override("font_color", Color("93c5fd"))
	input_title.add_theme_font_size_override("font_size", 9)
	input_box.add_child(input_title)

	input_edit = TextEdit.new()
	input_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	input_edit.placeholder_text = "Nhập input..."
	input_edit.add_theme_font_size_override("font_size", editor_font_size - 1)
	_style_text_area(input_edit)
	input_edit.text_changed.connect(_schedule_save)
	input_box.add_child(input_edit)

	var output_panel := _make_panel()
	output_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_panel.size_flags_stretch_ratio = 1.0
	side.add_child(output_panel)

	var output_box := VBoxContainer.new()
	output_box.add_theme_constant_override("separation", 3)
	output_panel.add_child(output_box)

	var output_title := Label.new()
	output_title.text = "OUTPUT  ·  KẾT QUẢ"
	output_title.add_theme_color_override("font_color", Color("86efac"))
	output_title.add_theme_font_size_override("font_size", 9)
	output_box.add_child(output_title)

	output_edit = TextEdit.new()
	output_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	output_edit.placeholder_text = "Kết quả chạy sẽ hiển thị tại đây..."
	output_edit.editable = false
	output_edit.add_theme_font_size_override("font_size", editor_font_size - 1)
	_style_text_area(output_edit)
	output_box.add_child(output_edit)

	status_label = Label.new()
	status_label.text = "Sẵn sàng · IDE C++17"
	status_label.custom_minimum_size.y = 15
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.clip_text = true
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	position_label = Label.new()
	position_label.add_theme_color_override("font_color", MUTED)
	position_label.add_theme_font_size_override("font_size", 8)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status_row.add_child(status_label)
	status_row.add_child(position_label)
	layout.add_child(status_row)
	_update_position_label()

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 5)
	layout.add_child(actions)

	prototype_button = _make_button("Chèn Prototype", Color("0f766e"), 96)
	prototype_button.tooltip_text = "Chèn khung hàm mẫu vào vùng code và copy vào clipboard"
	prototype_button.pressed.connect(_insert_prototypes)
	actions.add_child(prototype_button)

	reset_button = _make_button("Reset", Color("475569"), 54)
	reset_button.tooltip_text = "Bấm 2 lần để xóa code và input"
	reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_button)

	save_button = _make_button("Save", Color("334155"), 54)
	save_button.pressed.connect(_save_workspace)
	actions.add_child(save_button)

	run_button = _make_button("▶ Run", BLUE, 60)
	run_button.pressed.connect(_run_code)
	actions.add_child(run_button)

	submit_button = _make_button("Submit", GREEN, 68)
	submit_button.pressed.connect(_on_submit_pressed)
	actions.add_child(submit_button)

# ---------- Phím tắt ----------
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed:
		return
	# Bắt phím Tab trước hệ thống focus của Viewport để thụt lề giống IDE chuẩn.
	if key.keycode == KEY_TAB and not key.ctrl_pressed and not key.alt_pressed:
		if is_instance_valid(source_edit) and source_edit.has_focus() and source_edit.editable:
			if key.shift_pressed:
				source_edit.unindent_lines()
			elif source_edit.has_selection():
				source_edit.indent_lines()
			else:
				source_edit.insert_text_at_caret("    ")
			get_viewport().set_input_as_handled()
			return
	if key.echo or not key.ctrl_pressed:
		return
	if key.keycode == KEY_R and is_instance_valid(run_button) and not run_button.disabled:
		_run_code()
	elif (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER) and is_instance_valid(submit_button) and not submit_button.disabled:
		_on_submit_pressed()
	elif key.keycode == KEY_S:
		_save_workspace()
		set_status("Đã lưu bài làm.")
	else:
		return
	get_viewport().set_input_as_handled()

func _on_submit_pressed() -> void:
	_save_workspace()
	submit_requested.emit()

# ---------- Xác nhận Reset ----------
func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "Chắc chắn?"
		reset_button.custom_minimum_size.x = 84
		_reset_timer.start()
		set_status("Bấm Reset lần nữa để xóa code và input (tự hủy sau 3 giây).", true)
		return
	_disarm_reset()
	_reset_code()

func _disarm_reset() -> void:
	_reset_armed = false
	if is_instance_valid(_reset_timer):
		_reset_timer.stop()
	if is_instance_valid(reset_button):
		reset_button.text = "Reset"
		reset_button.custom_minimum_size.x = 54

# ---------- Gợi ý code ----------
func _on_completion_requested() -> void:
	var typed := _current_word()
	var seen := {}
	for word in CPP_KEYWORDS:
		_add_completion(seen, word, word, CodeEdit.KIND_PLAIN_TEXT, KEYWORD_COLOR)
	for name in CPP_LIBRARY:
		_add_completion(seen, name, name, CodeEdit.KIND_FUNCTION, LIBRARY_COLOR)
	for key in CPP_SNIPPETS.keys():
		_add_completion(seen, key + "  (mẫu)", CPP_SNIPPETS[key], CodeEdit.KIND_PLAIN_TEXT, SNIPPET_COLOR)
	for word in _identifiers_in_source():
		if word != typed:
			_add_completion(seen, word, word, CodeEdit.KIND_VARIABLE, VARIABLE_COLOR)
	source_edit.update_code_completion_options(true)

func _add_completion(seen: Dictionary, display: String, insert: String, kind: int, color: Color) -> void:
	if seen.has(display):
		return
	seen[display] = true
	source_edit.add_code_completion_option(kind, display, insert, color)

func _identifiers_in_source() -> Array[String]:
	var result: Array[String] = []
	var regex := RegEx.new()
	regex.compile("[A-Za-z_][A-Za-z0-9_]*")
	var known := {}
	for word in CPP_KEYWORDS + CPP_LIBRARY:
		known[word] = true
	for match in regex.search_all(source_edit.text):
		var word := match.get_string()
		if word.length() < 2 or known.has(word):
			continue
		known[word] = true
		result.append(word)
	return result

func _current_word() -> String:
	var line := source_edit.get_line(source_edit.get_caret_line())
	var col := source_edit.get_caret_column()
	var start := col
	while start > 0 and _is_word_char(line.substr(start - 1, 1)):
		start -= 1
	return line.substr(start, col - start)

func _is_word_char(c: String) -> bool:
	return c == "_" or (c >= "0" and c <= "9") or (c.to_lower() >= "a" and c.to_lower() <= "z")

func _on_source_changed() -> void:
	_clear_error_marks()
	_schedule_save()
	_update_position_label()
	if _loading_workspace or not is_instance_valid(source_edit):
		return
	var col := source_edit.get_caret_column()
	if col <= 0:
		return
	var typed := source_edit.get_line(source_edit.get_caret_line()).substr(col - 1, 1)
	if typed == "." or (_is_word_char(typed) and not typed.is_valid_int()):
		source_edit.request_code_completion(false)

# ---------- Đánh dấu lỗi biên dịch ----------
func show_compile_errors(details: String) -> void:
	_clear_error_marks()
	if not is_instance_valid(source_edit):
		return
	var offset := _student_line_offset()
	var regex := RegEx.new()
	regex.compile(COMPILE_ERROR_PATTERN)
	var first_line := -1
	var first_message := ""
	for match in regex.search_all(details):
		var raw_line := match.get_string(1) if not match.get_string(1).is_empty() else match.get_string(3)
		var line := int(raw_line) - offset - 1
		if line < 0 or line >= source_edit.get_line_count():
			continue
		source_edit.set_line_background_color(line, ERROR_LINE_COLOR)
		_error_lines.append(line)
		if first_line < 0:
			first_line = line
			first_message = match.get_string(4).strip_edges()
	if first_line >= 0:
		source_edit.set_caret_line(first_line)
		source_edit.set_caret_column(0)
		source_edit.center_viewport_to_caret()
		set_status("Lỗi ở dòng %d: %s" % [first_line + 1, first_message], true)

func _clear_error_marks() -> void:
	if not is_instance_valid(source_edit):
		return
	for line in _error_lines:
		if line < source_edit.get_line_count():
			source_edit.set_line_background_color(line, Color(0, 0, 0, 0))
	_error_lines.clear()

func get_student_line_count() -> int:
	return source_edit.get_line_count() if is_instance_valid(source_edit) else 0

# Số dòng mà TestBank thêm vào trước mã sinh viên (header #include, using...)
func _student_line_offset() -> int:
	var question_id := str(question.get("id", ""))
	if question_id.is_empty() or source_edit.text.is_empty():
		return 0
	var built := TestBank.build_program(question_id, source_edit.text)
	if built.is_empty():
		return 0
	var full := str(built.get("source", ""))
	var index := full.find(source_edit.text)
	if index < 0:
		return 0
	return full.substr(0, index).count("\n")

func _update_position_label() -> void:
	if not is_instance_valid(position_label) or not is_instance_valid(source_edit):
		return
	position_label.text = "Dòng %d, cột %d  ·  %d dòng" % [
		source_edit.get_caret_line() + 1,
		source_edit.get_caret_column() + 1,
		source_edit.get_line_count(),
	]

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_button(caption: String, color: Color, min_width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(min_width, 23)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.15)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	return button

func _style_text_area(edit: Control) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_DARK
	normal.border_color = BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(4)
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", normal)

func _make_cpp_highlighter() -> CodeHighlighter:
	var highlighter := CodeHighlighter.new()
	highlighter.number_color = Color("fbbf24")
	highlighter.symbol_color = Color("cbd5e1")
	highlighter.function_color = Color("60a5fa")
	highlighter.member_variable_color = Color("a7f3d0")
	for keyword in ["int", "void", "double", "float", "bool", "char", "string", "auto", "long", "short", "unsigned", "struct", "class", "const", "using", "namespace", "nullptr"]:
		highlighter.add_keyword_color(keyword, Color("7dd3fc"))
	for keyword in ["if", "else", "for", "while", "do", "switch", "case", "break", "continue", "return", "try", "catch", "throw"]:
		highlighter.add_keyword_color(keyword, Color("c4b5fd"))
	for keyword in ["std", "cout", "cin", "cerr", "endl", "vector", "string"]:
		highlighter.add_keyword_color(keyword, Color("f9a8d4"))
	highlighter.add_color_region("\"", "\"", Color("86efac"))
	highlighter.add_color_region("'", "'", Color("fca5a5"))
	highlighter.add_color_region("//", "", Color("94a3b8"), true)
	highlighter.add_color_region("/*", "*/", Color("94a3b8"))
	highlighter.add_color_region("#", "", Color("fbbf24"))
	return highlighter

func _set_editor_font_size(value: int) -> void:
	editor_font_size = clampi(value, 5, 16)
	for edit in [source_edit, input_edit, output_edit]:
		if is_instance_valid(edit):
			edit.add_theme_font_size_override("font_size", editor_font_size if edit == source_edit else maxi(editor_font_size - 1, 5))

func _schedule_save() -> void:
	if _loading_workspace or not is_instance_valid(_save_timer):
		return
	_save_timer.start()

func _save_workspace() -> void:
	if not is_instance_valid(source_edit) or not is_instance_valid(input_edit):
		return
	var question_id := str(question.get("id", ""))
	if question_id.is_empty():
		return
	var saved := Workspace.save_workspace(question_id, source_edit.text, input_edit.text)
	if is_instance_valid(save_button):
		save_button.tooltip_text = "Đã lưu workspace" if saved else "Không thể lưu workspace"

func _reset_code() -> void:
	if is_instance_valid(source_edit):
		source_edit.text = _initial_source
	if is_instance_valid(input_edit):
		input_edit.text = ""
	_save_workspace()
	set_status("Đã khôi phục nội dung ban đầu.", false)

func _run_code() -> void:
	if not is_instance_valid(source_edit) or not is_instance_valid(input_edit):
		return
	if str(question.get("answer_type", "")) != "short_code" or not TestBank.supports(str(question.get("id", ""))):
		set_status("Câu này không hỗ trợ Run tự động.", true)
		return
	_save_workspace()
	set_busy(true)
	set_status("Đang xử lý chương trình C++17...")
	run_requested.emit(source_edit.text, input_edit.text)

func set_status(message: String, is_error: bool = false) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("fca5a5") if is_error else MUTED)

func set_output(value: String) -> void:
	if is_instance_valid(output_edit):
		output_edit.text = value

func set_backend_info(backend_name: String, is_remote: bool) -> void:
	if not is_instance_valid(backend_label):
		return
	backend_label.text = "· " + backend_name
	backend_label.add_theme_color_override("font_color", Color("93c5fd") if is_remote else MUTED)

func _strip_default_args(signature: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\s*=\\s*[^,)]+")
	return regex.sub(signature, "", true)

func _insert_prototypes() -> void:
	if not is_instance_valid(source_edit) or not source_edit.editable:
		return
	var funcs: Variant = question.get("required_functions", [])
	if typeof(funcs) != TYPE_ARRAY or (funcs as Array).is_empty():
		set_status("Câu này không có prototype mẫu.", true)
		return
	var existing_text := source_edit.text
	var stubs: Array[String] = []
	for fn_val in funcs:
		var sig := str(fn_val).strip_edges()
		if sig.ends_with(";"):
			sig = sig.substr(0, sig.length() - 1).strip_edges()
		sig = _strip_default_args(sig)
		if sig.is_empty():
			continue
		var paren_idx := sig.find("(")
		var fn_name := sig.substr(0, paren_idx).strip_edges().get_slice(" ", sig.substr(0, paren_idx).strip_edges().get_slice_count(" ") - 1) if paren_idx > 0 else ""
		if not fn_name.is_empty() and existing_text.contains(fn_name + "("):
			continue
		stubs.append(sig + " {\n    \n}")
	if stubs.is_empty():
		set_status("Các prototype của câu này đã có sẵn trong vùng code.")
		return
	var snippet := "\n\n".join(stubs)
	DisplayServer.clipboard_set(snippet)
	if source_edit.text.strip_edges().is_empty():
		source_edit.text = snippet + "\n"
		source_edit.set_caret_line(1)
		source_edit.set_caret_column(4)
	else:
		source_edit.insert_text_at_caret("\n" + snippet + "\n")
	source_edit.grab_focus()
	_schedule_save()
	set_status("Đã chèn prototype vào IDE và copy vào clipboard.")

func set_busy(value: bool) -> void:
	if is_instance_valid(run_button):
		var can_run := str(question.get("answer_type", "")) == "short_code" and TestBank.supports(str(question.get("id", "")))
		run_button.disabled = value or not can_run
	if is_instance_valid(submit_button):
		submit_button.disabled = value
	if is_instance_valid(save_button):
		save_button.disabled = value
