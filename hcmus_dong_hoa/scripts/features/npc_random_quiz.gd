extends "res://scripts/features/feature.gd"
# MINI QUIZ NGẪU NHIÊN TỪ NPC SINH VIÊN THƯỜNG.
# NPC thường có 50% khả năng xuất hiện quiz và có thể được thử lại mỗi phút.
# Không áp dụng cho NPC quiz cố định hoặc NPC có vai trò đặc biệt trong character.gd.

const QuestionBank := preload("res://scripts/features/npc_quiz_question_bank.gd")
const RewardWheel := preload("res://scripts/features/quiz_reward_wheel.gd")

const TALK_RANGE := 34.0
const QUIZ_CHANCE := 0.5
const QUIZ_REROLL_SECONDS := 60.0
const QUESTIONS_PER_ROUND := 5
const PANEL_RECT := Rect2(18, 6, 444, 258)

const COLOR_BG := Color(0.045, 0.075, 0.14, 0.98)
const COLOR_GOLD := Color("ffd23f")
const COLOR_WHITE := Color("f4f6ff")
const COLOR_MUTED := Color("aab7d4")
const COLOR_GREEN := Color("66e39a")
const COLOR_RED := Color("ff8585")
const COLOR_BLUE := Color("477fb9")

var _rng := RandomNumberGenerator.new()
var _recent_question_ids_by_type: Dictionary = {
	"multiple_choice": [],
	"reorder": [],
	"fill_blank": []
}
var _root: Control
var _dim: ColorRect
var _panel: Panel
var _title_label: Label
var _progress_label: Label
var _question_label: RichTextLabel
var _answer_area: Control
var _status_label: Label
var _source_label: Label
var _action_button: Button
var _close_button: Button
var _fill_input: LineEdit
var _option_buttons: Array[Button] = []
var _reorder_order: Array[int] = []
var _reorder_positions: Array[int] = []
var _reorder_rows: Array[Label] = []
var _reorder_line_numbers: Array[Label] = []
var _reorder_rank_buttons: Array = []

var _current_npc: Dictionary = {}
var _question_set: Array = []
var _question_index := 0
var _correct_answers := 0
var _selected_option := -1
var _answered := false
var _finished := false
var _reward_wheel: Control
var _reward_wheel_running := false
var _class_mode := false      # true = đang chạy quiz lý thuyết trên lớp do class_attendance.gd mở
var _class_finished := false  # true khi đã làm hết các câu ở chế độ trên lớp
var _class_title := ""
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	_rng.randomize()
	_build_interface()

func _ensure_npc_question_history(npc_data: Dictionary) -> void:
	if typeof(npc_data.get("mini_quiz_question_history", null)) != TYPE_DICTIONARY:
		npc_data["mini_quiz_question_history"] = {}

func _process(_delta: float) -> void:
	_update_quiz_chances()

func draw_front_layer() -> void:
	if active or game.is_busy() or _near_excluded_npc():
		return
	var nearby: Variant = _find_nearby_npc()
	if nearby == null:
		return
	var has_quiz := bool(nearby.get("quiz_giver", false))
	var prompt := "[E] Làm quiz" if has_quiz else "[E] Tương tác"
	var color := COLOR_GOLD if has_quiz else COLOR_WHITE
	game.ctext(prompt, nearby.pos.x - 42.0, nearby.pos.y - 34.0, 84.0, 8, color)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	if active:
		if _reward_wheel_running:
			return
		if key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE:
			finish()
			get_viewport().set_input_as_handled()
		return

	if key.keycode != KEY_E and key.physical_keycode != KEY_E:
		return
	if game.is_busy() or _near_excluded_npc():
		return

	var target: Variant = _find_nearby_npc()
	if target == null:
		return

	_interact_with_npc(target)
	get_viewport().set_input_as_handled()

# ---------- Tim NPC ----------
func _find_nearby_npc() -> Variant:
	var nearest: Variant = null
	var nearest_distance := TALK_RANGE
	for npc_data in game.npcs:
		if not _is_ordinary_npc(npc_data):
			continue
		var distance: float = game.player.distance_to(npc_data.pos)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = npc_data
	return nearest

func _is_ordinary_npc(npc_data: Dictionary) -> bool:
	if bool(npc_data.get("quiz", false)):
		return false
	if npc_data.has("role") or bool(npc_data.get("special", false)):
		return false
	var npc_position: Vector2 = npc_data.get("pos", Vector2.ZERO)
	if game.DIEUHANH.has_point(npc_position):
		return false
	for building_data in game.BUILDINGS:
		if str(building_data[0]) in ["C", "THƯ VIỆN"] and Rect2(
			building_data[1], building_data[2], building_data[3], building_data[4]
		).has_point(npc_position):
			return false
	return true

func _update_quiz_chances() -> void:
	for npc_data in game.npcs:
		if not _is_ordinary_npc(npc_data):
			continue
		if not bool(npc_data.get("quiz_chance_checked", false)) or bool(npc_data.get("quiz_giver", false)):
			continue
		if game.clock >= float(npc_data.get("quiz_next_roll_at", INF)):
			_roll_quiz_chance(npc_data)

func _roll_quiz_chance(npc_data: Dictionary) -> void:
	npc_data["quiz_chance_checked"] = true
	npc_data["quiz_giver"] = _rng.randf() < QUIZ_CHANCE
	if bool(npc_data["quiz_giver"]):
		npc_data.erase("quiz_next_roll_at")
	else:
		npc_data["quiz_next_roll_at"] = game.clock + QUIZ_REROLL_SECONDS

# NPC có tên (giáo viên, bảo vệ, giữ xe, lao công...) được feature character xử lý riêng.
func _near_named_npc() -> bool:
	for feature in game.features:
		if feature == self:
			continue
		if feature.has_method("role_npc_near"):
			if feature.call("role_npc_near") != null:
				return true
	return false

# Cũng giữ ưu tiên cho NPC quiz cố định của Cô Toán nếu người chơi đứng cạnh NPC đó.
func _near_excluded_npc() -> bool:
	if _near_named_npc():
		return true
	for feature in game.features:
		if feature != self and feature.has_method("is_near") and bool(feature.call("is_near")):
			return true
	return false

func _interact_with_npc(npc_data: Dictionary) -> void:
	if not bool(npc_data.get("quiz_chance_checked", false)):
		_roll_quiz_chance(npc_data)
	if bool(npc_data.get("quiz_giver", false)):
		npc_data["quiz_giver"] = false
		npc_data["quiz_next_roll_at"] = game.clock + QUIZ_REROLL_SECONDS
		_ensure_npc_question_history(npc_data)
		_current_npc = npc_data
		_start_quiz()

# ---------- Tao giao dien ----------
func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font = game.font
	_root.theme = ui_theme
	layer.add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.62)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	_root.add_child(_dim)

	_panel = Panel.new()
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.add_theme_stylebox_override("panel", _make_style(COLOR_BG, COLOR_GOLD, 2))
	_panel.visible = false
	_root.add_child(_panel)

	_title_label = _make_label(_panel, Rect2(12, 5, 390, 20), 13, COLOR_GOLD)
	_title_label.text = "THỬ THÁCH C++"
	_close_button = _make_button(_panel, Rect2(414, 5, 20, 18), "X", 9, Color("a33d46"), Color("c64d58"))
	_close_button.pressed.connect(finish)

	_progress_label = _make_label(_panel, Rect2(14, 28, 416, 14), 8, COLOR_MUTED)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_question_label = RichTextLabel.new()
	_question_label.position = Vector2(14, 47)
	_question_label.size = Vector2(416, 46)
	_question_label.bbcode_enabled = false
	_question_label.scroll_active = true
	_question_label.fit_content = false
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_label.add_theme_font_override("normal_font", game.font)
	_question_label.add_theme_font_size_override("normal_font_size", 9)
	_question_label.add_theme_color_override("default_color", COLOR_WHITE)
	_panel.add_child(_question_label)

	_answer_area = Control.new()
	_answer_area.position = Vector2(14, 95)
	_answer_area.size = Vector2(416, 107)
	_answer_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_answer_area)

	_status_label = _make_label(_panel, Rect2(14, 203, 416, 27), 9, COLOR_MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_action_button = _make_button(_panel, Rect2(300, 232, 130, 20), "Kiểm tra đáp án", 8, Color("237447"), Color("2c945b"))
	_action_button.pressed.connect(_on_action_pressed)

	_source_label = _make_label(_panel, Rect2(14, 253, 280, 8), 6, COLOR_MUTED)
	_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_source_label.text = "Chủ đề tham khảo: W3Schools C++ Tutorial / Exercises"

	_reward_wheel = RewardWheel.new()
	_reward_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_reward_wheel)
	_reward_wheel.connect("prize_awarded", _on_quiz_reward_awarded)
	_reward_wheel.connect("spin_finished", _on_quiz_reward_finished)

# ---------- Bat dau va chon cau hoi ----------
func _start_quiz(external_questions: Array = []) -> void:
	_question_set = external_questions.duplicate(true) if not external_questions.is_empty() else _make_question_set()
	_class_finished = false
	_question_index = 0
	_correct_answers = 0
	_answered = false
	_finished = false
	_reward_wheel_running = false
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	begin()
	_dim.visible = true
	_panel.visible = true
	_show_question()

func _make_question_set() -> Array:
	var bank := QuestionBank.all_questions()
	var type_order: Array[String] = ["multiple_choice", "reorder", "fill_blank"]
	_shuffle_array(type_order)
	while type_order.size() < QUESTIONS_PER_ROUND:
		type_order.append(["multiple_choice", "reorder", "fill_blank"][_rng.randi_range(0, 2)])
	_shuffle_array(type_order)

	var selected: Array = []
	var round_used_ids: Dictionary = {
		"multiple_choice": [],
		"reorder": [],
		"fill_blank": []
	}
	var history_value: Variant = _current_npc.get("mini_quiz_question_history", {})
	var history: Dictionary = {}
	if typeof(history_value) == TYPE_DICTIONARY:
		history = history_value.duplicate(true)
	for question_type in type_order:
		var npc_used_ids: Array = history.get(question_type, []).duplicate()
		var recent_ids: Array = _recent_question_ids_by_type.get(question_type, []).duplicate()
		var current_round_ids: Array = round_used_ids.get(question_type, []).duplicate()
		var type_questions: Array = []
		var candidates: Array = []

		for item in bank:
			if str(item.get("type", "")) != question_type:
				continue
			type_questions.append(item)
			var candidate_id := str(item.get("id", ""))
			if not npc_used_ids.has(candidate_id) and not recent_ids.has(candidate_id) and not current_round_ids.has(candidate_id):
				candidates.append(item)

		if candidates.is_empty():
			recent_ids.clear()
			for item in type_questions:
				var retry_id := str(item.get("id", ""))
				if not npc_used_ids.has(retry_id) and not current_round_ids.has(retry_id):
					candidates.append(item)

		if candidates.is_empty():
			npc_used_ids.clear()
			for item in type_questions:
				var remaining_id := str(item.get("id", ""))
				if not recent_ids.has(remaining_id) and not current_round_ids.has(remaining_id):
					candidates.append(item)

		if candidates.is_empty():
			recent_ids.clear()
			for item in type_questions:
				var round_fallback_id := str(item.get("id", ""))
				if not current_round_ids.has(round_fallback_id):
					candidates.append(item)

		if candidates.is_empty():
			continue

		var picked: Dictionary = candidates[_rng.randi_range(0, candidates.size() - 1)]
		var picked_id := str(picked.get("id", ""))
		selected.append(picked.duplicate(true))
		npc_used_ids.append(picked_id)
		recent_ids.append(picked_id)
		current_round_ids.append(picked_id)
		round_used_ids[question_type] = current_round_ids
		history[question_type] = npc_used_ids
		_recent_question_ids_by_type[question_type] = recent_ids

	_current_npc["mini_quiz_question_history"] = history
	return selected

func _shuffle_array(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp: Variant = items[i]
		items[i] = items[j]
		items[j] = temp

func _show_question() -> void:
	if _question_index >= _question_set.size():
		_show_summary()
		return

	_answered = false
	_selected_option = -1
	_fill_input = null
	_option_buttons.clear()
	_reorder_rows.clear()
	_reorder_line_numbers.clear()
	_reorder_rank_buttons.clear()
	_reorder_positions.clear()
	_clear_answer_area()
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", COLOR_MUTED)
	_action_button.text = "Kiểm tra đáp án"

	var question_data: Dictionary = _question_set[_question_index]
	_configure_question_layout(str(question_data.get("type", "")) == "reorder")
	_progress_label.text = "CÂU %d/%d   |   ĐÚNG: %d   |   DẠNG: %s" % [
		_question_index + 1,
		_question_set.size(),
		_correct_answers,
		_type_name(str(question_data.get("type", "")))
	]
	var body := str(question_data.get("prompt", ""))
	var code := str(question_data.get("code", ""))
	if not code.is_empty():
		body += "\n" + code
	_question_label.text = body
	if _class_mode:
		_source_label.text = "Nguồn tham khảo: " + str(question_data.get("source", ""))

	match str(question_data.get("type", "")):
		"multiple_choice":
			_build_multiple_choice(question_data)
		"reorder":
			_build_reorder(question_data)
		"fill_blank":
			_build_fill_blank(question_data)

func _configure_question_layout(is_reorder: bool) -> void:
	_source_label.visible = not is_reorder
	if is_reorder:
		_question_label.size = Vector2(416, 37)
		_answer_area.position = Vector2(14, 86)
		_answer_area.size = Vector2(416, 125)
		_status_label.position = Vector2(14, 212)
		_status_label.size = Vector2(416, 24)
		_action_button.position = Vector2(300, 238)
		return
	_question_label.size = Vector2(416, 46)
	_answer_area.position = Vector2(14, 95)
	_answer_area.size = Vector2(416, 107)
	_status_label.position = Vector2(14, 203)
	_status_label.size = Vector2(416, 27)
	_action_button.position = Vector2(300, 232)

func _type_name(question_type: String) -> String:
	match question_type:
		"multiple_choice": return "TRẮC NGHIỆM"
		"reorder": return "SẮP XẾP CODE"
		"fill_blank": return "ĐIỀN CHỖ TRỐNG"
	return "C++"

func _clear_answer_area() -> void:
	for child in _answer_area.get_children():
		child.queue_free()

# ---------- Dang 1: multiple choice ----------
func _build_multiple_choice(question_data: Dictionary) -> void:
	var options: Array = question_data.get("options", [])
	for i in options.size():
		var button := _make_button(
			_answer_area,
			Rect2(0, i * 23, 416, 20),
			"%s. %s" % [["A", "B", "C", "D"][i], str(options[i])],
			8,
			Color(0.11, 0.17, 0.29),
			Color(0.17, 0.27, 0.43)
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 7)
		button.pressed.connect(_select_option.bind(i))
		_option_buttons.append(button)

func _select_option(index: int) -> void:
	if _answered:
		return
	_selected_option = index
	for i in _option_buttons.size():
		var color := Color("315b83") if i == index else Color(0.11, 0.17, 0.29)
		_option_buttons[i].add_theme_stylebox_override("normal", _make_style(color, COLOR_GOLD if i == index else Color("52617c"), 1))

# ---------- Dang 2: sap xep code ----------
func _build_reorder(question_data: Dictionary) -> void:
	var lines: Array = question_data.get("lines", [])
	_reorder_order.clear()
	_reorder_positions.clear()
	for i in lines.size():
		_reorder_order.append(i)
	_shuffle_array(_reorder_order)
	var already_in_order := true
	for i in _reorder_order.size():
		if _reorder_order[i] != i:
			already_in_order = false
			break
	if already_in_order and _reorder_order.size() > 1:
		var first := _reorder_order[0]
		_reorder_order[0] = _reorder_order[1]
		_reorder_order[1] = first
	_reorder_positions.resize(lines.size())
	_reorder_positions.fill(-1)

	var row_count: int = maxi(lines.size(), 1)
	var row_height: float = minf(22.0, floor((_answer_area.size.y - 17.0 - (row_count - 1) * 2.0) / row_count))
	var row_gap := 2.0
	var button_size: float = row_height - 2.0
	var button_gap := 3.0
	var rank_group_width: float = lines.size() * button_size + maxi(lines.size() - 1, 0) * button_gap
	var rank_start_x: float = _answer_area.size.x - rank_group_width - 5.0

	var help := _make_label(_answer_area, Rect2(0, 0, 416, 15), 8, COLOR_MUTED)
	help.text = "Bấm số thứ tự bên phải mỗi dòng; số trùng sẽ tự đổi chỗ."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in _reorder_order.size():
		var y := 17.0 + i * (row_height + row_gap)
		var row := Panel.new()
		row.position = Vector2(0, y)
		row.size = Vector2(416, row_height)
		var row_color := Color("172944") if i % 2 == 0 else Color("203653")
		row.add_theme_stylebox_override("panel", _make_style(row_color, Color("38516f"), 1))
		_answer_area.add_child(row)
		var line_number := _make_label(row, Rect2(3, 0, 44, row_height), 7, COLOR_GOLD)
		line_number.text = "DÒNG %d" % (i + 1)
		_reorder_line_numbers.append(line_number)
		var text_box := Panel.new()
		text_box.position = Vector2(50, 1)
		text_box.size = Vector2(rank_start_x - 54.0, row_height - 2.0)
		text_box.add_theme_stylebox_override("panel", _make_style(Color("0d1a2c"), Color("52617c"), 1))
		row.add_child(text_box)
		var line_label := _make_label(text_box, Rect2(4, 0, text_box.size.x - 8.0, text_box.size.y), 8, COLOR_WHITE)
		line_label.position.y = -2.0
		line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_reorder_rows.append(line_label)
		var rank_buttons: Array[Button] = []
		for position in lines.size():
			var button_x: float = rank_start_x + position * (button_size + button_gap)
			var button := _make_button(
				row,
				Rect2(button_x, (row_height - button_size) * 0.5, button_size, button_size),
				str(position + 1),
				8 if button_size >= 18.0 else 7,
				Color("26364f"),
				Color("477fb9")
			)
			button.pressed.connect(_set_reorder_position.bind(i, position))
			rank_buttons.append(button)
		_reorder_rank_buttons.append(rank_buttons)
	_refresh_reorder_rows()

func _is_order_correct() -> bool:
	for i in _reorder_order.size():
		if _reorder_positions[i] != _reorder_order[i]:
			return false
	return true

func _set_reorder_position(row_index: int, selected_position: int) -> void:
	if _answered:
		return
	var previous_position := _reorder_positions[row_index]
	for i in _reorder_positions.size():
		if i != row_index and _reorder_positions[i] == selected_position:
			_reorder_positions[i] = previous_position
			break
	_reorder_positions[row_index] = selected_position
	_refresh_reorder_rows()

func _refresh_reorder_rows() -> void:
	if _question_index >= _question_set.size():
		return
	var lines: Array = _question_set[_question_index].get("lines", [])
	for i in _reorder_order.size():
		_reorder_line_numbers[i].text = "DÒNG %d" % (i + 1)
		_reorder_rows[i].text = str(lines[_reorder_order[i]])
		for position in _reorder_rank_buttons[i].size():
			var button: Button = _reorder_rank_buttons[i][position]
			var selected: bool = _reorder_positions[i] == position
			var color := Color("8a6224") if selected else Color("26364f")
			var border := COLOR_GOLD if selected else Color("52617c")
			button.add_theme_stylebox_override("normal", _make_style(color, border, 1))
			button.disabled = _answered

# ---------- Dang 3: dien cho trong ----------
func _build_fill_blank(question_data: Dictionary) -> void:
	var code_label := _make_label(_answer_area, Rect2(2, 2, 412, 40), 9, COLOR_WHITE)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	code_label.text = str(question_data.get("code", "____"))
	var hint := _make_label(_answer_area, Rect2(2, 44, 412, 15), 7, COLOR_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.text = "Nhập phần còn thiếu vào ô bên dưới:"
	_fill_input = LineEdit.new()
	_fill_input.position = Vector2(2, 63)
	_fill_input.size = Vector2(412, 25)
	_fill_input.placeholder_text = "Đáp án..."
	_fill_input.add_theme_font_override("font", game.font)
	_fill_input.add_theme_font_size_override("font_size", 9)
	_fill_input.add_theme_color_override("font_color", COLOR_WHITE)
	_fill_input.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.05, 0.1), Color("52617c"), 1))
	_answer_area.add_child(_fill_input)
	_fill_input.grab_focus()

# ---------- Cham dap an va chuyen cau ----------
func _on_action_pressed() -> void:
	if _reward_wheel_running:
		return
	if _finished:
		finish()
	elif _answered:
		_question_index += 1
		_show_question()
	else:
		_check_answer()

func _check_answer() -> void:
	var question_data: Dictionary = _question_set[_question_index]
	if str(question_data.get("type", "")) == "reorder" and _reorder_positions.has(-1):
		_status_label.text = "Hãy chọn vị trí cho tất cả các dòng trước khi kiểm tra."
		_status_label.add_theme_color_override("font_color", COLOR_GOLD)
		return
	var is_correct := false
	match str(question_data.get("type", "")):
		"multiple_choice":
			is_correct = _selected_option == int(question_data.get("answer", -1))
		"reorder":
			is_correct = _is_order_correct()
		"fill_blank":
			var submitted := _normalise_answer(_fill_input.text if is_instance_valid(_fill_input) else "")
			for expected in question_data.get("answers", []):
				if submitted == _normalise_answer(str(expected)):
					is_correct = true
					break

	_answered = true
	if is_correct:
		_correct_answers += 1
		_status_label.text = "CHÍNH XÁC! " + str(question_data.get("explanation", ""))
		_status_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		_status_label.text = "CHƯA ĐÚNG. " + str(question_data.get("explanation", ""))
		_status_label.add_theme_color_override("font_color", COLOR_RED)
		if str(question_data.get("type", "")) == "multiple_choice":
			var options: Array = question_data.get("options", [])
			var answer_i := int(question_data.get("answer", -1))
			if answer_i >= 0 and answer_i < options.size():
				_status_label.text += " Đáp án: %s." % str(options[answer_i])
		elif str(question_data.get("type", "")) == "fill_blank":
			_status_label.text += " Đáp án: %s." % str(question_data.get("answers", [""])[0])
	_disable_answer_controls()
	_action_button.text = "Câu tiếp theo"
	_progress_label.text = "CÂU %d/%d   |   ĐÚNG: %d" % [_question_index + 1, _question_set.size(), _correct_answers]

func _normalise_answer(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "").replace("\t", "").replace("\n", "")

func _disable_answer_controls() -> void:
	for button in _option_buttons:
		button.disabled = true
	for rank_buttons in _reorder_rank_buttons:
		for button in rank_buttons:
			button.disabled = true
	if is_instance_valid(_fill_input):
		_fill_input.editable = false

func _show_summary() -> void:
	_finished = true
	_answered = true
	if _class_mode:
		_class_finished = true
		var total := _question_set.size()
		_title_label.text = "KẾT THÚC · " + _class_title
		_progress_label.text = "KẾT QUẢ CUỐI CÙNG"
		_question_label.text = "Bạn đã hoàn thành %d câu hỏi.\nSố câu đúng: %d/%d" % [total, _correct_answers, total]
		_clear_answer_area()
		_status_label.text = "Quiz lý thuyết trên lớp không làm thay đổi GPA."
		_status_label.add_theme_color_override("font_color", COLOR_GOLD)
		_action_button.text = "Đóng"
		return
	_title_label.text = "HOÀN THÀNH THỬ THÁCH"
	_progress_label.text = "KẾT QUẢ CUỐI CÙNG"
	_question_label.text = "Bạn đã hoàn thành 5 câu hỏi C++.\nSố câu đúng: %d/5\n\nHãy tiếp tục ôn tập các chủ đề C++ nhé!" % _correct_answers
	_clear_answer_area()
	_status_label.text = "Mini quiz chỉ dùng để luyện tập, không làm thay đổi GPA."
	_status_label.add_theme_color_override("font_color", COLOR_GOLD)
	_action_button.text = "Đóng"
	if _question_set.size() == QUESTIONS_PER_ROUND and _correct_answers >= 4:
		_reward_wheel_running = true
		_status_label.text = "Đúng ít nhất 4/5 câu! Đang quay thưởng quiz..."
		_reward_wheel.call("start_spin")
	else:
		_status_label.text += " Cần đúng ít nhất 4/5 câu để mở vòng quay."

func _on_quiz_reward_awarded(amount: int) -> void:
	for feature in game.features:
		if not feature.has_method("add_quiz_reward"):
			continue
		var formatted_amount := str(feature.call("add_quiz_reward", amount))
		if formatted_amount.is_empty():
			push_error("Canteen rejected a positive mini quiz reward.")
			return
		_status_label.text = "Đã cộng +%s vào ví." % formatted_amount
		return
	push_error("Mini quiz reward cannot be paid: canteen wallet is unavailable.")

func _on_quiz_reward_finished() -> void:
	_reward_wheel_running = false

# ---------- Quiz lý thuyết trên lớp (class_attendance.gd gọi) ----------
# questions: mảng câu hỏi cùng lược đồ với npc_quiz_question_bank.gd (multiple_choice / fill_blank).
func start_class_theory_round(title: String, questions: Array) -> bool:
	if active or questions.is_empty():
		return false
	_class_mode = true
	_class_title = title
	_start_quiz(questions)
	_title_label.text = title
	return true

func is_class_theory_open() -> bool:
	return _class_mode and active

func is_class_theory_finished() -> bool:
	return _class_mode and _class_finished

func finish_class_theory() -> void:
	_reward_wheel_running = false
	finish()

# ---------- Ket thuc ----------
func finish() -> void:
	if not active or _reward_wheel_running:
		return
	super()
	_dim.visible = false
	_panel.visible = false
	Input.mouse_mode = _previous_mouse_mode
	_class_mode = false
	_title_label.text = "THỬ THÁCH C++"
	_current_npc = {}
	_question_set.clear()

# ---------- UI helpers ----------
func _make_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	return style

func _make_label(parent: Control, rect: Rect2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = ""
	label.add_theme_font_override("font", game.font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _make_button(parent: Control, rect: Rect2, text_value: String, size: int, bg: Color, hover: Color) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", game.font)
	button.add_theme_font_size_override("font_size", size)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(key, COLOR_WHITE)
	button.add_theme_stylebox_override("normal", _make_style(bg, Color("52617c"), 1))
	button.add_theme_stylebox_override("hover", _make_style(hover, COLOR_GOLD, 1))
	button.add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.25), COLOR_GOLD, 1))
	button.add_theme_stylebox_override("disabled", _make_style(Color(0.12, 0.15, 0.21), Color(0.28, 0.32, 0.42), 1))
	parent.add_child(button)
	return button
