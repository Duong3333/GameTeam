extends RefCounted
# Ngan hang cau hoi Quiz tren lop.
# Chi dung ABCD va short-answer; tuyet doi khong chua short_code/Essay.

const DATA_PATH := "res://scripts/features/class_quiz_question_bank.json"
const DEFAULT_QUESTIONS_PER_ROUND := 5
const HISTORY_PATH := "user://class_quiz_history.json"
const MAX_SAVED_SESSIONS := 120
static var _cache: Dictionary = {}
static var _history: Dictionary = {}
static var _history_loaded := false

# Bốc câu cho MỘT buổi học / một bài tập. Cùng session_key (ví dụ "CLASS:VTP1:W5") thì luôn ra đúng bộ câu đã bốc lần đầu,
# nên ra vào lớp nhiều lần trong tuần không đổi đề. Buổi mới (tuần khác) thì bốc các câu CHƯA dùng của môn đó;
# dùng hết ngân hàng mới bắt đầu vòng mới. Lịch sử lưu ở user://class_quiz_history.json nên giữ nguyên khi tắt mở game.
static func load_session_round(course_code: String, session_key: String, count: int = DEFAULT_QUESTIONS_PER_ROUND) -> Dictionary:
	if session_key.is_empty():
		return load_random_round(course_code, count)
	var full_round: Dictionary = load_random_round(course_code, 100000)
	if full_round.is_empty():
		return {}
	var all_questions: Array = full_round.get("questions", [])
	var by_id: Dictionary = {}
	for question_value in all_questions:
		by_id[str((question_value as Dictionary).get("id", ""))] = question_value
	var take_count := clampi(count, 1, all_questions.size())
	_ensure_history_loaded()
	var course_history: Dictionary = _history.get(course_code, {})
	var sessions: Dictionary = course_history.get("sessions", {})
	var used: Array = course_history.get("used", [])
	var ids: Array = []
	if sessions.has(session_key):
		for saved_id in sessions[session_key]:
			if by_id.has(str(saved_id)):
				ids.append(str(saved_id))
		if ids.size() != take_count:
			ids.clear()   # ngân hàng đã đổi: bốc lại
	if ids.is_empty():
		var fresh: Array = []
		for question_id in by_id.keys():
			if not used.has(question_id):
				fresh.append(question_id)
		fresh.shuffle()
		if fresh.size() >= take_count:
			ids = fresh.slice(0, take_count)
			for picked_id in ids:
				used.append(picked_id)
		else:
			# Hết câu chưa dùng: lấy nốt phần còn lại của vòng cũ, rồi mở vòng mới cho phần thiếu.
			ids = fresh.duplicate()
			var next_cycle: Array = []
			for question_id in by_id.keys():
				if not ids.has(question_id):
					next_cycle.append(question_id)
			next_cycle.shuffle()
			var extra: Array = next_cycle.slice(0, take_count - ids.size())
			ids.append_array(extra)
			used = extra.duplicate()
		sessions[session_key] = ids
		while sessions.size() > MAX_SAVED_SESSIONS:
			sessions.erase(sessions.keys()[0])
		course_history["sessions"] = sessions
		course_history["used"] = used
		_history[course_code] = course_history
		_save_history()
	var selected: Array = []
	for question_id in ids:
		selected.append((by_id[question_id] as Dictionary).duplicate(true))
	full_round["exam_id"] = "CLASS_%s_%s" % [course_code, session_key]
	full_round["question_count"] = selected.size()
	full_round["questions"] = selected
	return full_round

# Xóa lịch sử bốc câu (dùng khi muốn thử lại từ đầu).
static func reset_history() -> void:
	_history = {}
	_history_loaded = true
	_save_history()

static func _ensure_history_loaded() -> void:
	if _history_loaded:
		return
	_history_loaded = true
	_history = {}
	if not FileAccess.file_exists(HISTORY_PATH):
		return
	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) == OK and typeof(parser.data) == TYPE_DICTIONARY:
		_history = parser.data

static func _save_history() -> void:
	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Không ghi được lịch sử Quiz tiết học: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(_history))

static func load_random_round(course_code: String, count: int = DEFAULT_QUESTIONS_PER_ROUND) -> Dictionary:
	if _cache.is_empty():
		if not _load_data():
			return {}
	if not _cache.has("courses"):
		push_error("Class quiz bank is missing the courses object.")
		return {}
	var courses: Dictionary = _cache.get("courses", {})
	if not courses.has(course_code):
		push_warning("No in-class Quiz bank for course: %s" % course_code)
		return {}
	var course_data: Dictionary = courses[course_code]
	var questions_value: Variant = course_data.get("questions", [])
	if typeof(questions_value) != TYPE_ARRAY:
		push_error("Invalid question list for class Quiz course %s." % course_code)
		return {}
	var questions: Array = questions_value.duplicate(true)
	if questions.is_empty():
		push_warning("Empty in-class Quiz bank for course: %s" % course_code)
		return {}
	for question_value in questions:
		if typeof(question_value) != TYPE_DICTIONARY:
			push_error("Class Quiz bank contains a non-dictionary question: %s" % course_code)
			return {}
		var question: Dictionary = question_value
		var question_type := str(question.get("type", ""))
		if question_type not in ["multiple_choice", "short_answer"]:
			push_error("In-class Quiz only supports multiple_choice/short_answer. Invalid question: %s" % str(question.get("id", "unknown")))
			return {}
	questions.shuffle()
	var take_count := clampi(count, 1, questions.size())
	var selected: Array = questions.slice(0, take_count)
	return {
		"exam_id": "CLASS_%s_%d_%d" % [course_code, Time.get_ticks_msec(), randi_range(100, 999)],
		"subject_code": course_code,
		"subject": str(course_data.get("subject", course_code)),
		"title": "QUIZ TRÊN LỚP · " + str(course_data.get("subject", course_code)),
		"exam_type": "class_quiz",
		"duration": "Theo thời lượng tiết học",
		"question_count": selected.size(),
		"questions": selected,
	}

static func _load_data() -> bool:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open class quiz bank %s: %s" % [DATA_PATH, error_string(FileAccess.get_open_error())])
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error("Invalid class quiz bank JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return false
	if typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Class quiz bank root must be a JSON object.")
		return false
	_cache = parser.data
	return true
