extends "res://scripts/features/feature.gd"
# Điều khiển quiz toán và đề thi do giảng viên khởi động.
#
# Nếu mới học code, hãy đọc các hàm theo thứ tự:
# 1. start_round()       - bắt đầu một vòng mới.
# 2. next_question()     - lấy câu tiếp theo từ đề đã tải.
# 3. submit_answer()     - kiểm tra đáp án ngắn theo dữ liệu đề.
# 4. finish_answer()     - hiện nút sang câu tiếp theo.
# 5. end_round()         - tính kết quả và cập nhật GPA.
#
# MathQuestions (math_questions.gd) chỉ lo tải đề và kiểm tra đáp án.
# File này lo luồng chơi, giao diện và phản hồi cho người chơi.

const MathQuestions := preload("res://scripts/systems/math_questions.gd")
const ClassQuestionBank := preload("res://scripts/features/class_quiz_question_bank.gd")
const GradingEngine := preload("res://scripts/systems/quiz_grading_engine.gd")
const Schedule := preload("res://scripts/features/schedule_data.gd")
const MathInput := preload("res://scripts/features/quiz_math_input.gd")
const CodeEditor := preload("res://scripts/features/quiz_code_editor.gd")
const PdfViewer := preload("res://scripts/features/quiz_pdf_viewer.gd")
const ResultScreen := preload("res://scripts/features/quiz_result_screen.gd")
const ProgrammingRunner := preload("res://scripts/features/programming_runner.gd")
const ProgrammingTestBank := preload("res://scripts/features/programming_test_bank.gd")
const ProgrammingJudge := preload("res://scripts/features/programming_judge.gd")
const RewardWheel := preload("res://scripts/features/quiz_reward_wheel.gd")
const INTERACT_RANGE := 36.0
const PANEL_SIZE := Vector2(460, 260)
const GPA_PENALTY := 0.1
const CLASS_GPA_PER_CORRECT := 0.02
const OFFICIAL_EXAM_ATTEMPTS_PATH := "user://official_exam_attempts.json"

enum State { MENU, PLAY, RESULT }

var npc: Dictionary = {}
var question: Dictionary = {}
var exam: Dictionary = {}
var selected_subject_code := "VTP1"
var selected_exam_type := "midterm"
var is_vtp_short_answer_exam := false
var round_title := "ÔN TẬP"
var state: int = State.MENU
var question_no := 0
var round_len := 5
var score := 0
var correct_count := 0
var gradable_count := 0
var ungraded_count := 0
var streak := 0
var best_streak := 0
var earned_points := 0.0
var gradable_points := 0.0
var programming_testcases_correct := 0
var programming_testcases_total := 0
var grading_config: Dictionary = {}
var is_programming_question := false
var answered := false
var time_left := 0.0
var time_limit := 20.0
var exam_time_left := 0.0
var exam_time_limit := 3600.0
var was_near := false
var prev_mouse_mode := Input.MOUSE_MODE_VISIBLE

var prompt_layer: CanvasLayer
var prompt: Label
var root: Control
var panel: Panel
var title_label: Label
var close_btn: Button
var menu_box: Control
var play_box: Control
var result_box: Control
var info_label: Label
var score_label: Label
var streak_label: Label
var time_bg: ColorRect
var time_fill: ColorRect
var question_label: RichTextLabel
var question_input: TextEdit
var math_input: Control
var code_editor: Control
var pdf_viewer: Control
var result_screen: Control
var code_editor_btn: Button
var solution_area: RichTextLabel
var submit_btn: Button
var result_label: Label
var next_btn: Button
var menu_notice: Label
var programming_runner: Node
var reward_wheel: Control
var reward_rng := RandomNumberGenerator.new()
var reward_wheel_running := false
var academic_quiz_mode := false
var class_quiz_mode := false
var official_exam_round := false
var course_question_mode := false
var class_quiz_subject_code := ""
var selected_choice := ""
var choice_buttons: Array[Button] = []
var pending_cpp_action := ""
var pending_cpp_expected_cases: Array = []
var pending_cpp_source := ""
var official_exam_attempts: Dictionary = {}
var official_exam_attempts_storage_ok := true

# Mau giao dien HUD navy - vang cua game.
var c_bg := Color(0.05, 0.1, 0.2, 0.98)
var c_gold := Color("ffd23f")
var c_option_off := Color(0.1, 0.14, 0.24)
var c_red := Color(0.78, 0.2, 0.2)

func _ready() -> void:
	for i in range(game.npcs.size() - 1, -1, -1):
		if bool(game.npcs[i].get("quiz", false)):
			game.npcs.remove_at(i)
	npc = {}
	build_prompt()
	build_ui()
	programming_runner = ProgrammingRunner.new()
	add_child(programming_runner)
	programming_runner.connect("run_completed", _on_cpp_run_completed)
	reward_rng.randomize()
	grading_config = GradingEngine.load_config()
	_load_official_exam_attempts()
	root.visible = false
	show_state(State.MENU)

# ---------- Tuong tac NPC ----------
func is_near() -> bool:
	if npc.is_empty():
		return false
	var p: Vector2 = game.player
	var q: Vector2 = npc.pos
	return p.distance_to(q) <= INTERACT_RANGE

func _process(delta: float) -> void:
	if not npc.is_empty() and float(npc.get("say_t", 0.0)) > 0.0:
		npc.say_t -= delta
	var near := is_near()
	prompt.visible = near and not active and not game.is_busy()
	if prompt.visible:
		var teacher_exam := Schedule.exam_for_teacher(str(npc.get("role", "")))
		if Schedule.week_no(game.day) in Schedule.FINAL_WEEKS and str(teacher_exam.get("subject_code", "")) == "VTP1":
			prompt.text = "Nhấn E để bắt đầu thi cuối kỳ Vi tích phân"
		elif not teacher_exam.is_empty() and Schedule.week_no(game.day) == int(teacher_exam.get("week", -1)):
			prompt.text = "Nhấn E để bắt đầu kỳ thi giữa kỳ"
		else:
			prompt.text = "Nhấn E để ôn tập đề giữa kỳ"
	if near and not active:
		var d: Vector2 = game.player - npc.pos
		if absf(d.x) > absf(d.y):
			npc.face = 2 if d.x < 0.0 else 3
		else:
			npc.face = 1 if d.y < 0.0 else 0
		if not was_near:
			npc_say(greeting())
	was_near = near
	if active and state == State.PLAY:
		if official_exam_round:
			# Kỳ thi chính thức có một đồng hồ chung 60 phút cho toàn bộ đề.
			exam_time_left = maxf(exam_time_left - delta, 0.0)
			time_left = exam_time_left
			time_limit = exam_time_limit
			update_time_bar()
			if exam_time_left <= 0.0:
				if not answered:
					time_up()
				if state == State.PLAY:
					end_round()
		elif not answered:
			time_left -= delta
			update_time_bar()
			if time_left <= 0.0:
				time_up()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if active:
		# Khi IDE đang mở và con trỏ nằm trong CodeEdit/TextEdit,
		# không để phím điều khiển quiz chặn thao tác nhập code hoặc Input.
		if is_instance_valid(code_editor) and code_editor.visible:
			var focused_control := get_viewport().gui_get_focus_owner()
			if focused_control is TextEdit:
				if k.keycode == KEY_ESCAPE:
					code_editor.hide()
					focused_control.release_focus()
					get_viewport().set_input_as_handled()
				return
		handle_key(k)
		get_viewport().set_input_as_handled()
	elif (k.keycode == KEY_E or k.physical_keycode == KEY_E) and is_near() and not game.is_busy():
		begin()
		get_viewport().set_input_as_handled()

func handle_key(k: InputEventKey) -> void:
	if reward_wheel_running:
		return
	if k.keycode == KEY_ESCAPE:
		if is_instance_valid(pdf_viewer) and pdf_viewer.visible:
			pdf_viewer.call("close_view")
			return
		if is_instance_valid(code_editor) and code_editor.visible:
			code_editor.hide()
			return
		finish()
		return
	if state == State.MENU:
		if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			start_round("VTP1")
	elif state == State.PLAY:
		if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and answered:
			if programming_runner != null and bool(programming_runner.call("is_running")):
				return
			next_question()
	elif state == State.RESULT:
		if official_exam_round and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_R]:
			# Kỳ thi chính thức không có chức năng thi lại.
			finish()
		elif not academic_quiz_mode and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_R]:
			start_round(selected_subject_code, round_title, false, selected_exam_type)

func begin() -> void:
	super()
	prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.visible = false
	root.visible = true
	pop_in()

func finish() -> void:
	if class_quiz_mode and state != State.RESULT:
		return
	super()
	root.visible = false
	for option_button in choice_buttons:
		option_button.visible = false
	Input.mouse_mode = prev_mouse_mode
	if state == State.PLAY and not academic_quiz_mode:
		npc_say("Em cứ đi dạo, quay lại làm tiếp nhé!")
	academic_quiz_mode = false
	class_quiz_mode = false
	course_question_mode = false
	class_quiz_subject_code = ""

# session_key: khóa buổi học/bài tập để ngân hàng bốc bộ câu khác nhau mỗi tuần (xem class_quiz_question_bank.gd).
func start_class_round(subject_code: String = "CSLT_THEORY", title: String = "GIỜ HỌC", session_key: String = "") -> bool:
	return _start_academic_round(subject_code, title, true, session_key)

func start_homework_round(title: String = "BÀI TẬP VỀ NHÀ", subject_code: String = "CSLT_THEORY", session_key: String = "") -> bool:
	return _start_academic_round(subject_code, title, false, session_key)

func _start_academic_round(subject_code: String, title: String, during_class: bool, session_key: String = "") -> bool:
	if active:
		return false
	var class_exam: Dictionary = ClassQuestionBank.load_session_round(subject_code, session_key) if not session_key.is_empty() \
		else ClassQuestionBank.load_random_round(subject_code)
	if class_exam.is_empty():
		push_error("Cannot start course Quiz: no class question bank for %s." % subject_code)
		return false
	academic_quiz_mode = true
	class_quiz_mode = during_class
	course_question_mode = true
	class_quiz_subject_code = subject_code
	begin()
	var started := _start_round_with_exam(subject_code, title, false, class_exam)
	if not started:
		academic_quiz_mode = false
		class_quiz_mode = false
		course_question_mode = false
		class_quiz_subject_code = ""
		finish()
		return false
	return true

func is_class_quiz_running() -> bool:
	return class_quiz_mode and active and state == State.PLAY

func is_class_quiz_open() -> bool:
	return class_quiz_mode and active

func is_class_quiz_result() -> bool:
	return class_quiz_mode and state == State.RESULT

func finish_class_round() -> void:
	if class_quiz_mode and state == State.PLAY:
		if programming_runner != null and bool(programming_runner.call("is_running")):
			pending_cpp_action = ""
			pending_cpp_expected_cases.clear()
			pending_cpp_source = ""
		end_round()

func is_academic_quiz_result() -> bool:
	return academic_quiz_mode and state == State.RESULT

func is_academic_quiz_open() -> bool:
	return academic_quiz_mode and active

# ---------- Lượt thi chính thức (lưu bền qua lần tắt/mở game) ----------
func _load_official_exam_attempts() -> void:
	official_exam_attempts = {}
	official_exam_attempts_storage_ok = true
	if not FileAccess.file_exists(OFFICIAL_EXAM_ATTEMPTS_PATH):
		return
	var file := FileAccess.open(OFFICIAL_EXAM_ATTEMPTS_PATH, FileAccess.READ)
	if file == null:
		official_exam_attempts_storage_ok = false
		push_error("Cannot read official exam attempt history: %s" % OFFICIAL_EXAM_ATTEMPTS_PATH)
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		official_exam_attempts_storage_ok = false
		push_error("Official exam attempt history is invalid JSON; official exams are locked to avoid accidental retakes.")
		return
	var saved_attempts: Variant = parser.data.get("attempts", {})
	if typeof(saved_attempts) != TYPE_DICTIONARY:
		official_exam_attempts_storage_ok = false
		push_error("Official exam attempt history has an invalid attempts field.")
		return
	official_exam_attempts = saved_attempts.duplicate(true)

func _save_official_exam_attempts() -> bool:
	var file := FileAccess.open(OFFICIAL_EXAM_ATTEMPTS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot save official exam attempt history: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify({"version": 1, "attempts": official_exam_attempts}, "\t"))
	file.flush()
	return file.get_error() == OK

func _official_exam_attempt_key(subject_code: String, exam_type: String) -> String:
	return "%s_%s" % [subject_code.strip_edges().to_upper(), exam_type.strip_edges().to_lower()]

func is_official_exam_attempt_storage_ready() -> bool:
	return official_exam_attempts_storage_ok

func is_official_exam_used(subject_code: String, exam_type: String) -> bool:
	var key := _official_exam_attempt_key(subject_code, exam_type)
	var attempt_value: Variant = official_exam_attempts.get(key, {})
	return typeof(attempt_value) == TYPE_DICTIONARY and bool(attempt_value.get("used", false))

func _start_official_exam_once(subject_code: String, title: String, exam_type: String, loaded_exam: Dictionary) -> bool:
	if not official_exam_attempts_storage_ok:
		menu_notice.text = "Không đọc được dữ liệu lượt thi. Kỳ thi chưa thể bắt đầu để tránh phát sinh lượt thi lại."
		return false
	var attempt_key := _official_exam_attempt_key(subject_code, exam_type)
	if is_official_exam_used(subject_code, exam_type):
		return false
	if loaded_exam.is_empty():
		return false
	# Ghi nhận lượt ngay trước khi mở đề: thoát game giữa chừng cũng không tạo lượt thi mới.
	official_exam_attempts[attempt_key] = {
		"used": true,
		"subject_code": subject_code,
		"exam_type": exam_type,
		"exam_id": str(loaded_exam.get("exam_id", "")),
		"started_day": int(game.day)
	}
	if not _save_official_exam_attempts():
		official_exam_attempts.erase(attempt_key)
		menu_notice.text = "Không lưu được lượt thi. Bài thi chưa bắt đầu; hãy kiểm tra quyền ghi dữ liệu game."
		return false
	selected_exam_type = exam_type
	begin()
	var started := _start_round_with_exam(subject_code, title, true, loaded_exam)
	if not started:
		# Chỉ hoàn tác khi game không mở được bài thi; không hoàn tác khi người chơi tự thoát giữa bài.
		official_exam_attempts.erase(attempt_key)
		_save_official_exam_attempts()
		finish()
		return false
	return true

# ---------- Luong quiz ----------
func show_state(s: int) -> void:
	state = s
	close_btn.visible = not class_quiz_mode or s == State.RESULT
	menu_box.visible = (s == State.MENU)
	play_box.visible = (s == State.PLAY)
	result_box.visible = (s == State.RESULT)
	if is_instance_valid(pdf_viewer):
		if pdf_viewer.visible:
			pdf_viewer.call("close_view")
	if is_instance_valid(code_editor):
		code_editor.hide()
	if s == State.RESULT:
		if official_exam_round:
			title_label.text = "KẾT QUẢ THI CUỐI KỲ" if selected_exam_type == "final" else "KẾT QUẢ THI GIỮA KỲ"
		elif class_quiz_mode:
			title_label.text = "KẾT QUẢ QUIZ TRÊN LỚP"
		elif academic_quiz_mode:
			title_label.text = "KẾT QUẢ BÀI TẬP"
		else:
			title_label.text = "KẾT QUẢ ÔN TẬP"
	elif s == State.PLAY:
		title_label.text = round_title if academic_quiz_mode else "%s | %s" % [round_title, str(exam.get("subject", ""))]
	else:
		title_label.text = "ÔN TẬP ĐỀ GIỮA KỲ"

func start_round(subject_code: String = "VTP1", title: String = "ÔN TẬP", is_official_exam: bool = false, exam_type: String = "midterm") -> void:
	if is_official_exam:
		menu_notice.text = "Kỳ thi chính thức chỉ được mở qua giảng viên và mỗi môn chỉ có một lượt thi."
		show_state(State.MENU)
		return
	selected_exam_type = exam_type
	var loaded_exam: Dictionary = {}
	if subject_code == "VTP1" and exam_type == "final":
		loaded_exam = _load_vtp1_final_exam()
	elif exam_type == "midterm":
		if subject_code == "VTP1":
			# Đề giữa kỳ Vi tích phân lấy từ vtp1_midterm_exam_bank.json (cùng dạng Quiz Vi tích phân lý thuyết:
			# mỗi câu một đáp số ngắn), không dùng các đề cũ trong quiz_exam_bank vì không trả lời ngắn được.
			loaded_exam = _load_vtp1_midterm_exam()
			if loaded_exam.is_empty():
				menu_notice.text = "Đề giữa kỳ Vi tích phân phải có đúng 5 câu trả lời ngắn hợp lệ. Hãy kiểm tra ngân hàng đề."
				push_error("Rejected Vi tích phân midterm: no exam with 5 short-answer questions and verified answer data was found.")
				show_state(State.MENU)
				return
		else:
			loaded_exam = MathQuestions.load_random_exam(subject_code, exam_type)
	else:
		menu_notice.text = "Chưa có ngân hàng đề cho kỳ thi này."
		show_state(State.MENU)
		return
	_start_round_with_exam(subject_code, title, is_official_exam, loaded_exam)


# Đề giữa kỳ Vi tích phân lưu câu hỏi ở dạng phẳng (answer_type, accepted_answers, verified... không có "type")
# hoặc dạng lồng "short_answer". Chuẩn hóa về cùng một dạng rồi mới kiểm tra, và nếu đề bốc trúng có câu
# chưa xác minh đáp án (ví dụ exam_010) thì bốc đề khác thay vì kẹt ở menu.
func _normalize_vtp1_exam(source: Dictionary) -> Dictionary:
	var exam_copy: Dictionary = source.duplicate(true)
	var questions_value: Variant = exam_copy.get("questions", [])
	if typeof(questions_value) != TYPE_ARRAY:
		return exam_copy
	var answer_keys := ["answer_type", "official_answer", "accepted_answers", "verified", "grading_method", "tolerance"]
	for question_value in questions_value:
		if typeof(question_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = question_value
		var nested: Dictionary = {}
		if typeof(item.get("short_answer", null)) == TYPE_DICTIONARY:
			nested = item["short_answer"]
		for key in answer_keys:
			if item.has(key) and not nested.has(key):
				nested[key] = item[key]
			elif nested.has(key) and not item.has(key):
				item[key] = nested[key]
		if not nested.is_empty():
			item["short_answer"] = nested
			if str(item.get("type", "")).is_empty():
				item["type"] = "short_answer"
	return exam_copy

func _load_vtp1_midterm_exam() -> Dictionary:
	const MIDTERM_BANK_PATH := "res://scripts/features/vtp1_midterm_exam_bank.json"
	var file := FileAccess.open(MIDTERM_BANK_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open Vi tích phân midterm exam bank: %s" % MIDTERM_BANK_PATH)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Invalid Vi tích phân midterm exam bank JSON.")
		return {}
	var exams_value: Variant = parser.data.get("exams", [])
	if typeof(exams_value) != TYPE_ARRAY or exams_value.is_empty():
		push_error("Vi tích phân midterm exam bank contains no exams.")
		return {}
	var usable_exams: Array = []
	for exam_value in exams_value:
		if typeof(exam_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = _normalize_vtp1_exam(exam_value)
		if str(candidate.get("subject_code", "")) == "VTP1" and str(candidate.get("exam_type", "")) == "midterm" \
				and _validate_vtp1_midterm_exam(candidate):
			usable_exams.append(candidate)
	if usable_exams.is_empty():
		push_error("No valid Vi tích phân midterm exam set with 5 verified short-answer questions was found.")
		return {}
	return usable_exams[randi_range(0, usable_exams.size() - 1)].duplicate(true)

func _validate_vtp1_midterm_exam(candidate: Dictionary) -> bool:
	if candidate.is_empty() or str(candidate.get("subject_code", "")) != "VTP1":
		return false
	if str(candidate.get("exam_type", "midterm")) != "midterm":
		return false
	var questions_value: Variant = candidate.get("questions", [])
	if typeof(questions_value) != TYPE_ARRAY or questions_value.size() != 5:
		return false
	for question_value in questions_value:
		if typeof(question_value) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = question_value
		if str(item.get("type", "")) != "short_answer":
			return false
		var answer_value: Variant = item.get("short_answer", {})
		if typeof(answer_value) != TYPE_DICTIONARY or answer_value.is_empty():
			return false
		var answer_data: Dictionary = answer_value
		if str(answer_data.get("answer_type", item.get("answer_type", ""))).is_empty():
			return false
		var accepted: Variant = answer_data.get("accepted_answers", item.get("accepted_answers", []))
		if typeof(accepted) != TYPE_ARRAY or accepted.is_empty():
			return false
		if not bool(answer_data.get("verified", item.get("verified", false))):
			return false
	return true

func _load_vtp1_final_exam() -> Dictionary:
	const FINAL_BANK_PATH := "res://scripts/features/vtp1_final_exam_bank.json"
	var file := FileAccess.open(FINAL_BANK_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open Vi tích phân final exam bank: %s" % FINAL_BANK_PATH)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Invalid Vi tích phân final exam bank JSON.")
		return {}
	var exams_value: Variant = parser.data.get("exams", [])
	if typeof(exams_value) != TYPE_ARRAY or exams_value.is_empty():
		push_error("Vi tích phân final exam bank contains no exams.")
		return {}
	var usable_exams: Array = []
	for exam_value in exams_value:
		if typeof(exam_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = exam_value
		if str(candidate.get("subject_code", "")) != "VTP1" or str(candidate.get("exam_type", "")) != "final":
			continue
		var question_list: Variant = candidate.get("questions", [])
		if typeof(question_list) != TYPE_ARRAY or question_list.size() != 5:
			continue
		usable_exams.append(candidate)
	if usable_exams.is_empty():
		push_error("No valid Vi tích phân final exam set with 5 questions was found.")
		return {}
	return usable_exams[randi_range(0, usable_exams.size() - 1)].duplicate(true)

func _start_round_with_exam(subject_code: String, title: String, is_official_exam: bool, loaded_exam: Dictionary) -> bool:
	if grading_config.is_empty():
		push_error("Quiz cannot start without a valid grading_config.json.")
		menu_notice.text = "Không tải được cấu hình chấm điểm. Xem lỗi trong Debugger."
		show_state(State.MENU)
		return false
	if loaded_exam.is_empty():
		menu_notice.text = "Không tải được ngân hàng đề cho môn này. Xem lỗi trong Debugger."
		show_state(State.MENU)
		return false
	selected_subject_code = subject_code
	round_title = title
	official_exam_round = is_official_exam
	exam = loaded_exam.duplicate(true)
	exam_time_limit = maxf(float(exam.get("duration_seconds", 3600.0)), 1.0) if official_exam_round else 0.0
	exam_time_left = exam_time_limit
	var exam_questions: Variant = exam.get("questions", [])
	if typeof(exam_questions) != TYPE_ARRAY:
		push_error("Selected exam has an invalid question list: %s" % str(exam.get("exam_id", "")))
		menu_notice.text = "Dữ liệu câu hỏi không hợp lệ; hãy kiểm tra ngân hàng."
		show_state(State.MENU)
		return false
	var valid_exam_questions: Array = exam_questions
	round_len = valid_exam_questions.size()
	if round_len == 0:
		push_error("Selected exam has no questions: %s" % str(exam.get("exam_id", "")))
		menu_notice.text = "Đề không có câu hỏi; hãy kiểm tra dữ liệu ngân hàng."
		show_state(State.MENU)
		return false
	question_no = 0
	score = 0
	correct_count = 0
	gradable_count = 0
	ungraded_count = 0
	streak = 0
	best_streak = 0
	earned_points = 0.0
	gradable_points = 0.0
	programming_testcases_correct = 0
	programming_testcases_total = _count_programming_testcases(valid_exam_questions)
	reward_wheel_running = false
	pending_cpp_action = ""
	pending_cpp_expected_cases.clear()
	pending_cpp_source = ""
	question = {}
	answered = false
	menu_notice.text = ""
	show_state(State.PLAY)
	next_question()
	pop_in()
	return state == State.PLAY

func next_question() -> void:
	if question_no >= round_len:
		end_round()
		return
	var exam_questions: Array = exam.get("questions", [])
	var next_item: Variant = exam_questions[question_no]
	if typeof(next_item) != TYPE_DICTIONARY:
		push_error("Question %d in exam %s is not a JSON object." % [question_no + 1, str(exam.get("exam_id", ""))])
		menu_notice.text = "Câu hỏi không hợp lệ; hãy kiểm tra dữ liệu ngân hàng."
		show_state(State.MENU)
		return
	question = next_item.duplicate(true)
	question_no += 1
	# Vi tích phân thi giữa kỳ/cuối kỳ dùng trường short_answer đã có trong mỗi câu đề.
	is_vtp_short_answer_exam = official_exam_round and str(exam.get("subject_code", "")) == "VTP1"
	if is_vtp_short_answer_exam:
		var short_answer_value: Variant = question.get("short_answer", {})
		if typeof(short_answer_value) == TYPE_DICTIONARY and not short_answer_value.is_empty():
			for answer_key in short_answer_value:
				question[answer_key] = short_answer_value[answer_key]
	# Chi de thi CSLT thuc hanh moi duoc hien IDE viet code.
	is_programming_question = official_exam_round and str(exam.get("subject_code", "")) == "CSLT" and str(question.get("answer_type", "")) == "short_code"
	var question_type := str(question.get("type", ""))
	var is_multiple_choice := course_question_mode and question_type == "multiple_choice"
	answered = false
	selected_choice = ""
	if official_exam_round:
		time_limit = exam_time_limit
		time_left = exam_time_left
	else:
		time_limit = 180.0
		time_left = time_limit
	var question_source := str(question.get("question_latex", question.get("question_text", "")))
	var readable_question := MathQuestions.latex_to_readable_text(question_source)
	question_label.text = readable_question
	question_input.text = ""
	question_input.editable = true
	question_input.placeholder_text = "Nhập đáp án ngắn bằng bàn phím..." if (course_question_mode or is_vtp_short_answer_exam) else "Nhập kết quả đã tính..."
	question_input.visible = (course_question_mode and not is_multiple_choice) or is_vtp_short_answer_exam
	math_input.visible = not course_question_mode and not is_programming_question and not is_vtp_short_answer_exam
	if math_input.has_method("set_editable"):
		math_input.call("set_editable", true)
	if math_input.has_method("clear_answer"):
		math_input.call("clear_answer")
	code_editor_btn.visible = is_programming_question
	code_editor.hide()
	code_editor.call("set_question", question)
	for index in choice_buttons.size():
		var option_button := choice_buttons[index]
		option_button.visible = is_multiple_choice
		option_button.disabled = false
		option_button.text = ""
		option_button.add_theme_stylebox_override("normal", make_style(c_option_off, c_gold, 1))
	if is_multiple_choice:
		var options: Array = question.get("options", [])
		for index in mini(choice_buttons.size(), options.size()):
			var option_value: Variant = options[index]
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_value
			choice_buttons[index].text = "%s. %s" % [str(option.get("value", "ABCD"[index])), str(option.get("text", ""))]
	solution_area.text = ""
	solution_area.visible = false
	submit_btn.disabled = false
	submit_btn.visible = not is_programming_question
	result_label.text = "Mở IDE để viết code C++ trong bài thi thực hành." if is_programming_question else ("Chọn một đáp án A/B/C/D." if is_multiple_choice else ("Nhập đáp án ngắn bằng bàn phím." if (course_question_mode or is_vtp_short_answer_exam) else "Nhập tối đa 4 chữ số; dùng ± và dấu phẩy để ghi số âm, số thập phân."))
	result_label.add_theme_color_override("font_color", Color("dfe6ff"))
	next_btn.visible = false
	update_info()
	update_time_bar()

func _select_class_choice(index: int) -> void:
	if answered or not course_question_mode or str(question.get("type", "")) != "multiple_choice":
		return
	if index < 0 or index >= choice_buttons.size():
		return
	selected_choice = "ABCD".substr(index, 1)
	for button_index in choice_buttons.size():
		var selected := button_index == index
		choice_buttons[button_index].add_theme_stylebox_override(
			"normal",
			make_style(Color("315b86") if selected else c_option_off, c_gold if selected else Color("65779c"), 2 if selected else 1)
		)

func _count_programming_testcases(exam_questions: Array) -> int:
	var total := 0
	for item in exam_questions:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var question_id := str(item.get("id", ""))
		var spec: Dictionary = ProgrammingTestBank.build_program(question_id, "")
		if not spec.is_empty():
			total += spec["expected_cases"].size()
		elif str(item.get("answer_type", "")) == "code_output" and bool(item.get("verified", false)) and str(item.get("grading_method", "")) == "exact":
			# Cau doc output co mot dap an chinh xac duoc xem la mot lan kiem tra.
			total += 1
	return total

func submit_answer(timed_out: bool = false) -> void:
	if answered:
		return
	if course_question_mode and str(question.get("type", "")) == "multiple_choice" and selected_choice.is_empty() and not timed_out:
		result_label.text = "Bạn hãy chọn một đáp án A/B/C/D trước khi nộp."
		result_label.add_theme_color_override("font_color", Color("ffd23f"))
		return
	if is_programming_question and not timed_out:
		submit_code_from_editor()
		return
	answered = true
	question_input.editable = false
	if math_input.has_method("set_editable"):
		math_input.call("set_editable", false)
	submit_btn.disabled = true
	submit_btn.visible = false
	var response := "" if timed_out else _current_response()
	for option_button in choice_buttons:
		option_button.disabled = true
	var grade_override: Dictionary = {}
	if course_question_mode or is_vtp_short_answer_exam:
		# Câu VTP thi chính thức dùng cùng bộ chấm typed-answer với Quiz trên lớp.
		grade_override = _grade_course_question(response)
	_process_answer(response, timed_out, grade_override)

func submit_code_from_editor() -> void:
	if answered or not code_editor.has_method("get_response"):
		return

	var answer_type := str(question.get("answer_type", ""))
	var source_code := str(code_editor.call("get_response"))
	var question_id := str(question.get("id", ""))
	if answer_type == "short_code" and ProgrammingTestBank.supports(question_id):
		_start_programming_submission(source_code)
	else:
		submit_answer_with_response(source_code if answer_type != "code_output" else str(code_editor.call("get_response")))

func _run_code_from_editor(source_code: String, input_text: String) -> void:
	if answered or programming_runner == null:
		return
	var built: Dictionary = ProgrammingTestBank.build_program(str(question.get("id", "")), source_code)
	if built.is_empty():
		code_editor.call("set_busy", false)
		code_editor.call("set_status", "Câu này chưa có bộ khung Run tự động.", true)
		return
	pending_cpp_action = "run"
	pending_cpp_expected_cases.clear()
	pending_cpp_source = source_code
	var started: bool = programming_runner.call("run_code", str(built["source"]), input_text)
	if not started and pending_cpp_action == "run":
		pending_cpp_action = ""
		code_editor.call("set_busy", false)
		code_editor.call("set_status", "Không thể bắt đầu chạy code. Hãy thử lại.", true)

func _start_programming_submission(source_code: String) -> void:
	if source_code.strip_edges().is_empty():
		code_editor.call("set_status", "Bạn chưa nhập hàm cần nộp.", true)
		return
	var built: Dictionary = ProgrammingTestBank.build_submission(str(question.get("id", "")), source_code)
	if built.is_empty():
		code_editor.call("set_status", "Câu này chưa có testcase chấm tự động.", true)
		return

	pending_cpp_action = "submit"
	pending_cpp_expected_cases = built["expected_cases"].duplicate()
	pending_cpp_source = source_code
	answered = true
	question_input.editable = false
	if math_input.has_method("set_editable"):
		math_input.call("set_editable", false)
	submit_btn.disabled = true
	submit_btn.visible = false
	code_editor.call("set_editable", false)
	code_editor.call("set_busy", true)
	code_editor.call("set_status", "Đang biên dịch và chấm %d testcase..." % pending_cpp_expected_cases.size())
	var started: bool = programming_runner.call("run_code", str(built["source"]), str(built["input"]))
	if not started and pending_cpp_action == "submit":
		pending_cpp_action = ""
		answered = false
		question_input.editable = true
		submit_btn.disabled = false
		submit_btn.visible = true
		code_editor.call("set_editable", true)
		code_editor.call("set_busy", false)
		code_editor.call("set_status", "Không thể bắt đầu chấm bài. Hãy thử lại.", true)

func _on_cpp_run_completed(result: Dictionary) -> void:
	var action := pending_cpp_action
	var expected_cases := pending_cpp_expected_cases.duplicate()
	var submitted_source := pending_cpp_source
	pending_cpp_action = ""
	pending_cpp_expected_cases.clear()
	pending_cpp_source = ""
	if not is_instance_valid(code_editor):
		return
	code_editor.call("set_busy", false)

	var success := bool(result.get("success", false))
	var output := str(result.get("output", ""))
	var details := str(result.get("details", ""))
	if action == "run":
		var visible_output := output.replace("@@CASE_END@@", "").strip_edges()
		if not details.is_empty():
			visible_output += ("\n" if not visible_output.is_empty() else "") + "[stderr]\n" + details
		if not success and visible_output.is_empty():
			visible_output = str(result.get("message", "Không chạy được chương trình."))
		code_editor.call("set_output", visible_output)
		code_editor.call("set_status", str(result.get("message", "Đã chạy xong.")), not success)
		return

	if action == "submit":
		var weight := maxf(float(question.get("points", 2.0)), 0.0)
		var grade: Dictionary = ProgrammingJudge.grade_submission(output, expected_cases, weight, success)
		grade["feedback"] = str(result.get("message", ""))
		if not details.is_empty():
			grade["feedback"] += "\n\nChi tiết trình biên dịch/chương trình:\n" + details
		_process_answer(submitted_source, false, grade)

func submit_answer_with_response(response: String) -> void:
	if answered:
		return
	answered = true
	question_input.editable = false
	if math_input.has_method("set_editable"):
		math_input.call("set_editable", false)
	submit_btn.disabled = true
	submit_btn.visible = false
	for option_button in choice_buttons:
		option_button.disabled = true
	var grade_override: Dictionary = _grade_course_question(response) if course_question_mode else {}
	_process_answer(response, false, grade_override)

func _current_response() -> String:
	if is_vtp_short_answer_exam:
		return question_input.text.strip_edges()
	if course_question_mode:
		if str(question.get("type", "")) == "multiple_choice":
			return selected_choice
		return question_input.text.strip_edges()
	if is_programming_question:
		return str(code_editor.call("get_response")) if code_editor.has_method("get_response") else ""
	return str(math_input.call("get_response")).replace(",", ".") if math_input.has_method("get_response") else ""

func _grade_course_question(response: String) -> Dictionary:
	var weight := maxf(float(question.get("points", 1.0)), 0.0)
	var answer_type := str(question.get("answer_type", ""))
	var expected := str(question.get("official_answer", ""))
	var is_correct := false
	if not bool(question.get("verified", false)) or str(question.get("answer_status", "")) not in ["official", "verified_ai"] or weight <= 0.0:
		return {"gradable": false, "needs_review": true, "earned_points": 0.0, "max_points": 0.0, "percentage": 0.0, "criteria": [], "expected": ""}
	if str(question.get("type", "")) == "multiple_choice":
		var correct_value := str(question.get("correct_option", "")).to_upper()
		is_correct = response.strip_edges().to_upper() == correct_value and not correct_value.is_empty()
		for option_value in question.get("options", []):
			if typeof(option_value) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_value
			if str(option.get("value", "")).to_upper() == correct_value:
				expected = "%s. %s" % [correct_value, str(option.get("text", ""))]
				break
	else:
		var accepted: Variant = question.get("accepted_answers", [])
		if typeof(accepted) == TYPE_ARRAY:
			for accepted_value in accepted:
				var target := str(accepted_value).strip_edges()
				if answer_type in ["integer", "decimal"]:
					var entered := _parse_class_number(response)
					var expected_number := _parse_class_number(target)
					if bool(entered.get("valid", false)) and bool(expected_number.get("valid", false)):
						if absf(float(entered["value"]) - float(expected_number["value"])) <= maxf(float(question.get("tolerance", 0.0)), 0.000000001):
							is_correct = true
							break
				else:
					if _normalize_class_text(response) == _normalize_class_text(target):
						is_correct = true
						break
	return {
		"gradable": true,
		"needs_review": false,
		"earned_points": weight if is_correct else 0.0,
		"max_points": weight,
		"percentage": 100.0 if is_correct else 0.0,
		"criteria": [{"id": "class_answer", "label": "Đáp án đã xác minh", "earned_points": weight if is_correct else 0.0, "max_points": weight, "gradable": true}],
		"expected": expected,
		"feedback": "Đáp án được đối chiếu theo ngân hàng câu hỏi đã kiểm tra."
	}

func _parse_class_number(value: String) -> Dictionary:
	var normalized := value.strip_edges().replace("−", "-").replace(",", ".")
	if not normalized.is_valid_float():
		return {"valid": false, "value": 0.0}
	return {"valid": true, "value": float(normalized)}

func _normalize_class_text(value: String) -> String:
	var normalized := value.strip_edges().to_lower().replace("\r\n", "\n").replace("\r", "\n")
	var whitespace := RegEx.new()
	whitespace.compile("\\s+")
	return whitespace.sub(normalized, " ", true)

func _process_answer(response: String, timed_out: bool, grade_override: Dictionary = {}) -> void:
	code_editor.hide()
	if pdf_viewer.visible:
		pdf_viewer.call("close_view")
	var grade: Dictionary = grade_override if not grade_override.is_empty() else GradingEngine.grade_question(question, response)
	if grade.has("correct_testcases"):
		programming_testcases_correct += int(grade.get("correct_testcases", 0))
	elif is_programming_question and str(question.get("answer_type", "")) == "code_output" and bool(grade.get("gradable", false)) and not bool(grade.get("needs_review", true)) and float(grade.get("percentage", 0.0)) >= 100.0:
		programming_testcases_correct += 1
	var expected := str(grade.get("expected", ""))
	var solution := str(question.get("solution_latex", ""))
	if bool(question.get("verified", false)):
		solution_area.text = "Đáp án nguồn:\n%s\n\nLời giải:\n%s" % [
			expected if not expected.is_empty() else "Chưa có đáp án đáng tin cậy.",
			MathQuestions.latex_to_readable_text(solution) if not solution.is_empty() else "Chưa có lời giải."
		]
	else:
		solution_area.text = "Đáp án/lời giải trong nguồn chưa xác minh; không hiển thị để tránh gây nhầm lẫn. Vui lòng kiểm tra answer_audit.json."
	var criteria_lines := PackedStringArray()
	var grade_criteria: Variant = grade.get("criteria", [])
	if typeof(grade_criteria) == TYPE_ARRAY:
		for criterion_value in grade_criteria:
			if typeof(criterion_value) != TYPE_DICTIONARY:
				continue
			var criterion: Dictionary = criterion_value
			var criterion_status := "%.2f/%.2f điểm" % [
				float(criterion.get("earned_points", 0.0)),
				float(criterion.get("max_points", 0.0))
			] if bool(criterion.get("gradable", false)) else "cần kiểm tra thủ công; chưa chấm"
			criteria_lines.append("%s: %s" % [str(criterion.get("label", criterion.get("id", "Tiêu chí"))), criterion_status])
	if not criteria_lines.is_empty():
		solution_area.text += "\n\nRubric:\n" + "\n".join(criteria_lines)
	var grading_feedback := str(grade.get("feedback", ""))
	if not grading_feedback.is_empty():
		solution_area.text += "\n\n" + grading_feedback
	solution_area.visible = true

	var question_is_gradable := bool(grade.get("gradable", false))
	var needs_review := bool(grade.get("needs_review", true))
	if question_is_gradable:
		gradable_count += 1
		gradable_points += float(grade.get("max_points", 0.0))
		earned_points += float(grade.get("earned_points", 0.0))
	if response.strip_edges().is_empty():
		if not question_is_gradable or needs_review:
			ungraded_count += 1
		streak = 0
		result_label.text = "Hết giờ: 0 điểm tự chấm." if timed_out else "Bỏ trống: 0 điểm tự chấm."
		if not question_is_gradable or needs_review:
			result_label.text += " Phần chưa có dữ liệu chấm tin cậy vẫn cần kiểm tra thủ công."
		result_label.add_theme_color_override("font_color", Color("ffd23f"))
	elif not question_is_gradable:
		ungraded_count += 1
		streak = 0
		result_label.text = "Câu này cần kiểm tra thủ công; không tự chấm và không tính điểm."
		result_label.add_theme_color_override("font_color", Color("ffd23f"))
	elif needs_review:
		ungraded_count += 1
		streak = 0
		result_label.text = "Đã chấm tiêu chí có dữ liệu; phần còn lại cần kiểm tra thủ công."
		result_label.add_theme_color_override("font_color", Color("ffd23f"))
	elif float(grade.get("percentage", 0.0)) >= 100.0:
		streak += 1
		best_streak = maxi(best_streak, streak)
		correct_count += 1
		var gain := points_for_answer()
		score += gain
		var msg := "Chính xác! +%d điểm." % gain
		if streak >= 3:
			msg += " Combo x%d!" % streak
		result_label.text = msg
		result_label.add_theme_color_override("font_color", Color("7dffa0"))
		float_text("+%d" % gain, Color("7dffa0"))
		npc_say(["Giỏi lắm!", "Chuẩn rồi!", "Tuyệt vời!", "Nhanh quá!"][randi() % 4] if streak < 3 else "Combo x%d! Quá đỉnh!" % streak)
	else:
		streak = 0
		if grade.has("correct_testcases"):
			result_label.text = "Đúng %d/%d testcase — %.2f/%.2f điểm." % [
				int(grade.get("correct_testcases", 0)),
				int(grade.get("total_testcases", 0)),
				float(grade.get("earned_points", 0.0)),
				float(grade.get("max_points", 0.0))
			]
		else:
			result_label.text = "Chưa chính xác." if not timed_out else "Hết giờ."
		result_label.add_theme_color_override("font_color", Color("ff8080"))
		npc_say(["Không sao, thử lại nhé!", "Cẩn thận hơn nào!", "Tiếc quá!"][randi() % 3])
		shake()
	finish_answer()

func time_up() -> void:
	if answered:
		return
	submit_answer(true)

func finish_answer() -> void:
	next_btn.text = "Xem kết quả (Enter)" if question_no >= round_len else "Câu tiếp theo (Enter)"
	next_btn.visible = true
	update_info()

# Tính điểm cho một câu trả lời đúng.
# Điểm = điểm nền + thưởng thời gian + thưởng combo.
func points_for_answer() -> int:
	var base_points := int(round(float(question.get("points", 1.0)) * 10.0))

	var time_bonus := int(ceil(10.0 * time_left / maxf(time_limit, 1.0)))
	var combo_bonus := 0
	if streak >= 5:
		combo_bonus = 10
	elif streak >= 3:
		combo_bonus = 5

	return base_points + time_bonus + combo_bonus

# Kết thúc lượt chơi: tính điểm, cập nhật GPA và hiện kết quả.
func end_round() -> void:
	var has_gradable_evidence := gradable_points > 0.0
	var accuracy := earned_points / gradable_points if has_gradable_evidence else 0.0
	var quiz_grade := GradingEngine.grade_to_ten(accuracy * 100.0, grading_config) if has_gradable_evidence and not grading_config.is_empty() else 0.0
	var total_exam_points := 0.0
	for item in exam.get("questions", []):
		if typeof(item) == TYPE_DICTIONARY:
			total_exam_points += maxf(float(item.get("points", 0.0)), 0.0)
	var full_exam_was_gradable := ungraded_count == 0 and gradable_points >= total_exam_points and total_exam_points > 0.0
	var is_programming_exam := str(exam.get("subject_code", "")) == "CSLT"
	var gpa_deducted := false
	var gpa_increased := false
	var gpa_change := 0.0

	if academic_quiz_mode:
		gpa_change = CLASS_GPA_PER_CORRECT * float(correct_count)
		if game.stats != null and game.stats.has_method("set_gpa"):
			var previous_gpa := float(game.stats.gpa)
			game.stats.set_gpa(previous_gpa + gpa_change)
			gpa_change = float(game.stats.gpa) - previous_gpa
			gpa_increased = gpa_change > 0.0
	elif is_programming_exam:
		if programming_testcases_total > 0 and programming_testcases_correct > 0:
			# Đúng một phần: cộng GPA theo tỷ lệ testcase đúng.
			gpa_change = float(programming_testcases_correct) / float(programming_testcases_total)
			if game.stats != null and game.stats.has_method("set_gpa"):
				game.stats.set_gpa(float(game.stats.gpa) + gpa_change)
				gpa_increased = true
		elif programming_testcases_total > 0:
			# Sai toàn bộ: trừ trực tiếp 0.10 GPA thay vì giữ nguyên như trước.
			gpa_change = -GPA_PENALTY
			if game.stats != null and game.stats.has_method("set_gpa"):
				game.stats.set_gpa(float(game.stats.gpa) + gpa_change)
				gpa_deducted = true
	else:
		gpa_deducted = full_exam_was_gradable and apply_gpa_penalty(quiz_grade)
		if gpa_deducted:
			gpa_change = -GPA_PENALTY

	var rank_data := get_rank_for_accuracy(accuracy) if full_exam_was_gradable else {"stars": 0}
	var stars := int(rank_data["stars"])
	var eligible_for_quiz_reward := not academic_quiz_mode and not official_exam_round
	var earns_quiz_reward := eligible_for_quiz_reward and reward_rng.randf() < RewardWheel.REWARD_CHANCE
	# Màn hình kết quả chỉ hiện "Hoàn thành" và số GPA thay đổi (xem quiz_result_screen.gd).
	result_screen.call("show_result", {"gpa": gpa_change})
	result_screen.call("set_replay_enabled", not academic_quiz_mode and not official_exam_round)

	show_state(State.RESULT)

	if not academic_quiz_mode:
		if gpa_deducted:
			if is_programming_exam:
				npc_say("Không vượt qua testcase nào, GPA bị trừ %.2f. Hãy thử lại nhé!" % GPA_PENALTY)
			else:
				npc_say("Điểm quiz dưới 5/10, GPA bị trừ %.2f. Cố gắng hơn nhé!" % GPA_PENALTY)
		elif gpa_increased:
			npc_say("Bài lập trình được cộng %.2f GPA. Làm tốt lắm!" % gpa_change)
		elif full_exam_was_gradable and stars >= 2:
			npc_say("Làm tốt lắm!")
		elif full_exam_was_gradable:
			npc_say("Lần sau sẽ tốt hơn!")

	pop_in()
	if earns_quiz_reward:
		reward_wheel_running = true
		reward_wheel.call("start_spin")

func _on_quiz_reward_awarded(amount: int) -> void:
	if game.stats == null or not game.stats.has_method("add_money"):
		push_error("Quiz reward cannot be paid: StudentStats.add_money is unavailable.")
		return
	game.stats.call("add_money", amount, "Thưởng quiz")

func _on_quiz_reward_finished() -> void:
	reward_wheel_running = false

# Trừ GPA khi điểm quiz thấp hơn 5/10.
# StudentStats tự giới hạn GPA trong khoảng 0.0 đến 4.0.
func apply_gpa_penalty(quiz_grade: float) -> bool:
	if quiz_grade >= 5.0:
		return false

	if game.stats != null and game.stats.has_method("set_gpa"):
		game.stats.set_gpa(float(game.stats.gpa) - GPA_PENALTY)

	return true

# Trả về lời nhận xét và số sao dựa trên tỷ lệ câu đúng.
func get_rank_for_accuracy(accuracy: float) -> Dictionary:
	if accuracy >= 0.9:
		return {"text": "Thủ khoa Toán học!", "stars": 3}
	if accuracy >= 0.7:
		return {"text": "Sinh viên giỏi!", "stars": 2}
	if accuracy >= 0.5:
		return {"text": "Khá lắm!", "stars": 1}
	return {"text": "Cố gắng thêm nhé!", "stars": 0}

func update_info() -> void:
	info_label.text = "Câu %d/%d" % [question_no, round_len]
	score_label.text = "Điểm: %d" % score
	streak_label.text = "Combo x%d" % streak if streak >= 2 else ""

func update_time_bar() -> void:
	var ratio := clampf(time_left / maxf(time_limit, 1.0), 0.0, 1.0)
	time_fill.size.x = time_bg.size.x * ratio
	if ratio > 0.5:
		time_fill.color = Color("4fd16b")
	elif ratio > 0.25:
		time_fill.color = Color("f0b429")
	else:
		time_fill.color = Color("e5484d")

# ---------- Loi thoai NPC ----------
func npc_say(text: String) -> void:
	if npc.is_empty():
		return
	npc.say = text
	npc.say_t = 2.6

func greeting() -> String:
	var teacher_exam := Schedule.exam_for_teacher(str(npc.get("role", "")))
	if Schedule.week_no(game.day) in Schedule.FINAL_WEEKS and str(teacher_exam.get("subject_code", "")) == "VTP1":
		return "Đã đến kỳ thi cuối kỳ Vi tích phân. Nhấn E để bắt đầu bài thi trả lời ngắn nhé!"
	if not teacher_exam.is_empty() and Schedule.week_no(game.day) == int(teacher_exam.get("week", -1)):
		return "Đã đến kỳ thi giữa kỳ. Nhấn E để bắt đầu làm bài nhé!"
	return "Chọn một bộ đề giữa kỳ để ôn tập nhé!"

func restart_round() -> void:
	if academic_quiz_mode or official_exam_round:
		return
	start_round(selected_subject_code, round_title, false, selected_exam_type)

func start_teacher_exam(teacher_role: String) -> bool:
	var exam_info := Schedule.exam_for_teacher(teacher_role)
	if exam_info.is_empty() or Schedule.week_no(game.day) != int(exam_info["week"]) or active:
		return false
	var subject_code := str(exam_info["subject_code"])
	if is_official_exam_used(subject_code, "midterm"):
		return false
	var midterm_exam: Dictionary = _load_vtp1_midterm_exam() if subject_code == "VTP1" else MathQuestions.load_random_exam(subject_code, "midterm")
	if midterm_exam.is_empty():
		return false
	round_title = "THI GIỮA KỲ"
	return _start_official_exam_once(subject_code, round_title, "midterm", midterm_exam)

func start_teacher_final_exam(teacher_role: String) -> bool:
	var exam_info := Schedule.exam_for_teacher(teacher_role)
	if exam_info.is_empty() or str(exam_info.get("subject_code", "")) != "VTP1":
		return false
	if Schedule.week_no(game.day) not in Schedule.FINAL_WEEKS or active:
		return false
	if is_official_exam_used("VTP1", "final"):
		return false
	var final_exam := _load_vtp1_final_exam()
	if final_exam.is_empty():
		return false
	round_title = "THI CUỐI KỲ"
	return _start_official_exam_once("VTP1", round_title, "final", final_exam)

func submit_current_answer() -> void:
	if is_programming_question:
		submit_code_from_editor()
	else:
		submit_answer()

# ---------- Hieu ung ----------
func pop_in() -> void:
	panel.pivot_offset = PANEL_SIZE / 2.0
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.14)
	tw.tween_property(panel, "modulate:a", 1.0, 0.14)

func shake() -> void:
	var x0 := (480.0 - PANEL_SIZE.x) / 2.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "position:x", x0 - 4.0, 0.04)
	tw.tween_property(panel, "position:x", x0 + 4.0, 0.06)
	tw.tween_property(panel, "position:x", x0 - 2.0, 0.05)
	tw.tween_property(panel, "position:x", x0, 0.04)

func float_text(t: String, col: Color) -> void:
	var l := make_text(panel, Rect2(PANEL_SIZE.x - 84, 55, 70, 20), 13, col)
	l.text = t
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", 35.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(l.queue_free)

# ---------- Dung giao dien ----------
func build_prompt() -> void:
	prompt_layer = CanvasLayer.new()
	prompt_layer.layer = 7
	add_child(prompt_layer)
	prompt = game.make_label(prompt_layer, Vector2(0, 214), 11)
	prompt.text = "Nhấn E để ôn tập đề giữa kỳ"
	prompt.add_theme_color_override("font_color", c_gold)
	prompt.custom_minimum_size = Vector2(480, 16)
	prompt.size = Vector2(480, 16)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.visible = false

func build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	root = Control.new()
	root.size = Vector2(480, 270)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var quiz_theme := Theme.new()
	quiz_theme.default_font = game.font
	root.theme = quiz_theme
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	panel = Panel.new()
	panel.position = (Vector2(480, 270) - PANEL_SIZE) / 2.0
	panel.size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", make_style(c_bg, c_gold, 2))
	root.add_child(panel)
	title_label = make_text(panel, Rect2(0, 4, PANEL_SIZE.x, 20), 14, c_gold)
	close_btn = make_button(panel, Rect2(PANEL_SIZE.x - 25, 4, 18, 18), "X", 10, c_red, Color(0.95, 0.35, 0.35))
	close_btn.pressed.connect(finish)
	build_menu()
	build_play()
	build_result()
	reward_wheel = RewardWheel.new()
	reward_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(reward_wheel)
	reward_wheel.connect("prize_awarded", _on_quiz_reward_awarded)
	reward_wheel.connect("spin_finished", _on_quiz_reward_finished)

func build_menu() -> void:
	menu_box = Control.new()
	menu_box.size = PANEL_SIZE
	menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(menu_box)
	var sub := make_text(menu_box, Rect2(16, 32, PANEL_SIZE.x - 32, 38), 11, Color.WHITE)
	sub.text = "Chọn môn để bắt đầu luyện tập."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var programming_btn := make_button(menu_box, Rect2(28, 82, 196, 72), "CƠ SỞ LẬP TRÌNH\nC++  ·  IDE / Run", 10, Color("174a3a"), Color("23664e"))
	programming_btn.pressed.connect(start_round.bind("CSLT"))
	var calculus_btn := make_button(menu_box, Rect2(236, 82, 196, 72), "VI TÍCH PHÂN 1\nToán  ·  Đáp số ngắn", 10, Color("243f73"), Color("315795"))
	calculus_btn.pressed.connect(start_round.bind("VTP1"))
	menu_notice = make_text(menu_box, Rect2(12, 158, PANEL_SIZE.x - 24, 20), 8, Color("ff8080"))
	menu_notice.text = ""
	var hint := make_text(menu_box, Rect2(16, 184, PANEL_SIZE.x - 32, 45), 8, Color("9fb0d8"))
	hint.text = "C++ chạy offline bằng g++/clang++. Quiz có 50% cơ hội quay thưởng 5k–50k; học phí tuần 8 là 100k."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_play() -> void:
	play_box = Control.new()
	play_box.size = PANEL_SIZE
	play_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(play_box)
	score_label = make_text(play_box, Rect2(12, 24, 96, 14), 10, c_gold)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label = make_text(play_box, Rect2(145, 24, 120, 14), 10, Color("dfe6ff"))
	streak_label = make_text(play_box, Rect2(PANEL_SIZE.x - 126, 24, 110, 14), 10, Color("ff9f43"))
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_bg = ColorRect.new()
	time_bg.color = Color(0.02, 0.05, 0.12)
	time_bg.position = Vector2(20, 42)
	time_bg.size = Vector2(PANEL_SIZE.x - 40, 6)
	play_box.add_child(time_bg)
	time_fill = ColorRect.new()
	time_fill.color = Color("4fd16b")
	time_fill.size = time_bg.size
	time_bg.add_child(time_fill)
	question_label = RichTextLabel.new()
	question_label.position = Vector2(14, 52)
	question_label.size = Vector2(PANEL_SIZE.x - 28, 50)
	question_label.scroll_active = true
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.bbcode_enabled = false
	question_label.add_theme_font_override("normal_font", game.font)
	question_label.add_theme_font_size_override("normal_font_size", 12)
	question_label.add_theme_color_override("default_color", Color.WHITE)
	question_label.add_theme_stylebox_override("normal", make_style(Color(0.02, 0.05, 0.12), Color(0.3, 0.4, 0.65), 1))
	play_box.add_child(question_label)
	var view_question_btn := make_button(play_box, Rect2(PANEL_SIZE.x - 104, 105, 90, 18), "XEM ĐỀ", 8, Color(0.16, 0.35, 0.58), Color(0.2, 0.45, 0.7))
	view_question_btn.pressed.connect(_open_question_view)
	code_editor_btn = make_button(play_box, Rect2(PANEL_SIZE.x - 190, 105, 78, 18), "IDE / CODE", 8, Color(0.16, 0.5, 0.28), Color(0.22, 0.65, 0.36))
	code_editor_btn.pressed.connect(_open_code_editor)
	question_input = TextEdit.new()
	question_input.position = Vector2(18, 128)
	question_input.size = Vector2(PANEL_SIZE.x - 36, 69)
	question_input.placeholder_text = "Nhập kết quả đã tính..."
	question_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	question_input.add_theme_font_override("font", game.font)
	question_input.add_theme_font_size_override("font_size", 10)
	question_input.add_theme_color_override("font_color", Color.WHITE)
	question_input.add_theme_stylebox_override("normal", make_style(Color(0.02, 0.05, 0.12), Color(0.3, 0.4, 0.65), 1))
	play_box.add_child(question_input)
	math_input = MathInput.new()
	math_input.position = Vector2(18, 128)
	math_input.size = Vector2(PANEL_SIZE.x - 36, 69)
	play_box.add_child(math_input)
	choice_buttons.clear()
	for index in 4:
		var column := index % 2
		var row := int(index / 2)
		var choice_rect := Rect2(18 + column * 222, 128 + row * 34, 216, 30)
		var choice_button := make_button(play_box, choice_rect, "", 8, c_option_off, Color("274b73"))
		choice_button.visible = false
		choice_button.pressed.connect(_select_class_choice.bind(index))
		choice_buttons.append(choice_button)
	solution_area = RichTextLabel.new()
	solution_area.position = question_input.position
	solution_area.size = question_input.size
	solution_area.scroll_active = true
	solution_area.bbcode_enabled = false
	solution_area.add_theme_font_override("normal_font", game.font)
	solution_area.add_theme_font_size_override("normal_font_size", 9)
	solution_area.add_theme_color_override("default_color", Color.WHITE)
	solution_area.add_theme_stylebox_override("normal", make_style(Color(0.02, 0.05, 0.12), Color(0.3, 0.4, 0.65), 1))
	solution_area.visible = false
	play_box.add_child(solution_area)
	pdf_viewer = PdfViewer.new()
	root.add_child(pdf_viewer)
	pdf_viewer.connect("close_requested", func() -> void: pdf_viewer.hide())
	code_editor = CodeEditor.new()
	root.add_child(code_editor)
	code_editor.hide()
	code_editor.connect("close_requested", func() -> void: code_editor.hide())
	code_editor.connect("submit_requested", submit_code_from_editor)
	code_editor.connect("run_requested", _run_code_from_editor)
	submit_btn = make_button(play_box, Rect2(18, 201, PANEL_SIZE.x - 36, 18), "NỘP ĐÁP ÁN", 9, Color(0.16, 0.5, 0.28), Color(0.22, 0.65, 0.36))
	submit_btn.pressed.connect(submit_current_answer)
	result_label = make_text(play_box, Rect2(12, 221, PANEL_SIZE.x - 24, 17), 8, Color.WHITE)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	next_btn = make_button(play_box, Rect2(18, 241, PANEL_SIZE.x - 36, 18), "Câu tiếp theo  (Enter)", 9, Color(0.75, 0.55, 0.1), Color(0.9, 0.7, 0.2))
	next_btn.pressed.connect(next_question)
	next_btn.visible = false

func _open_question_view() -> void:
	pdf_viewer.call("open_exam", exam, exam.get("questions", []))

func _open_code_editor() -> void:
	code_editor.show()

func build_result() -> void:
	result_box = Control.new()
	result_box.size = PANEL_SIZE
	result_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(result_box)
	result_screen = ResultScreen.new()
	result_box.add_child(result_screen)
	result_screen.connect("replay_requested", restart_round)
	result_screen.connect("close_requested", finish)

func make_style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(4)
	return s

func make_text(parent: Control, r: Rect2, sz: int, col: Color) -> Label:
	var l: Label = game.make_label(parent, r.position, sz)
	l.add_theme_constant_override("outline_size", 2)
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = r.size
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func make_button(parent: Control, r: Rect2, txt: String, sz: int, col: Color, hover: Color) -> Button:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", game.font)
	b.add_theme_font_size_override("font_size", sz)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(key, Color.WHITE)
	b.add_theme_stylebox_override("normal", make_style(col, c_gold, 1))
	b.add_theme_stylebox_override("hover", make_style(hover, Color.WHITE, 1))
	b.add_theme_stylebox_override("pressed", make_style(col.darkened(0.25), c_gold, 1))
	b.add_theme_stylebox_override("disabled", make_style(c_option_off, Color(0.3, 0.35, 0.5), 1))
	parent.add_child(b)
	return b
