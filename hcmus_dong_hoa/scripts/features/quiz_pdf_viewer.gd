extends Control

const MathQuestions := preload("res://scripts/systems/math_questions.gd")

signal close_requested

var _questions: Array = []
var _page_index := 0
var _font_size := 14
var _previous_window_mode := DisplayServer.WINDOW_MODE_MAXIMIZED
var _changed_window_mode := false
var _page_label: Label
var _content: RichTextLabel
var _title_label: Label

func _ready() -> void:
	_build_ui()
	visible = false

func open_exam(exam: Dictionary, questions: Array) -> void:
	_questions = questions.duplicate()
	_page_index = 0
	_title_label.text = str(exam.get("title", "NỘI DUNG ĐỀ THI"))
	visible = true
	_update_page()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.97)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var page := Panel.new()
	page.position = Vector2(6, 5)
	page.size = Vector2(468, 260)
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("f5f7fb")
	page.add_theme_stylebox_override("panel", page_style)
	add_child(page)
	_title_label = Label.new()
	_title_label.position = Vector2(10, 4)
	_title_label.size = Vector2(280, 20)
	_title_label.add_theme_color_override("font_color", Color("173a70"))
	page.add_child(_title_label)
	_page_label = Label.new()
	_page_label.position = Vector2(286, 4)
	_page_label.size = Vector2(80, 20)
	_page_label.add_theme_color_override("font_color", Color("173a70"))
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page.add_child(_page_label)
	_add_button(page, Rect2(371, 3, 25, 21), "−", _zoom_out)
	_add_button(page, Rect2(398, 3, 25, 21), "+", _zoom_in)
	_add_button(page, Rect2(425, 3, 36, 21), "X", _close)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(10, 30)
	scroll.size = Vector2(448, 192)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	_content = RichTextLabel.new()
	_content.fit_content = true
	_content.bbcode_enabled = false
	_content.scroll_active = false
	_content.custom_minimum_size = Vector2(428, 600)
	_content.add_theme_color_override("default_color", Color("17243a"))
	scroll.add_child(_content)
	_add_button(page, Rect2(10, 228, 80, 24), "◀ Trước", _previous_page)
	_add_button(page, Rect2(96, 228, 80, 24), "Sau ▶", _next_page)
	_add_button(page, Rect2(345, 228, 112, 24), "Toàn màn hình", _toggle_fullscreen)

func _add_button(parent: Control, rect: Rect2, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

func _update_page() -> void:
	if _questions.is_empty() or not is_instance_valid(_content):
		return
	_page_index = clampi(_page_index, 0, _questions.size() - 1)
	var question: Dictionary = _questions[_page_index]
	var source := str(question.get("question_latex", question.get("question_text", "")))
	_content.text = "CÂU %d\n\n%s" % [
		int(question.get("question_number", _page_index + 1)),
		MathQuestions.latex_to_readable_text(source)
	]
	_content.add_theme_font_size_override("normal_font_size", _font_size)
	_page_label.text = "%d / %d" % [_page_index + 1, _questions.size()]
	_content.scroll_to_line(0)

func _zoom_in() -> void:
	_font_size = mini(_font_size + 2, 32)
	_update_page()

func _zoom_out() -> void:
	_font_size = maxi(_font_size - 2, 8)
	_update_page()

func _previous_page() -> void:
	_page_index = maxi(_page_index - 1, 0)
	_update_page()

func _next_page() -> void:
	_page_index = mini(_page_index + 1, _questions.size() - 1)
	_update_page()

func _toggle_fullscreen() -> void:
	if _changed_window_mode:
		DisplayServer.window_set_mode(_previous_window_mode)
		_changed_window_mode = false
	else:
		_previous_window_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_changed_window_mode = true

func _close() -> void:
	close_view()

func close_view() -> void:
	if _changed_window_mode:
		DisplayServer.window_set_mode(_previous_window_mode)
		_changed_window_mode = false
	hide()
	close_requested.emit()
