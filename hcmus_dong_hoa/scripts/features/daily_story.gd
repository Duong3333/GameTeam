extends "res://scripts/features/feature.gd"
# Hiển thị đoạn cốt truyện ngắn ở những ngày có mốc sự kiện (trước daily_summary).
# Chỉ hiện 1 lần/ngày. Nhấn Enter / Space / Esc để bỏ qua.

const Schedule := preload("res://scripts/features/schedule_data.gd")

# ---------- NỘI DUNG CỐT TRUYỆN THEO NGÀY ----------
# Key = game.day (0 = ngày đầu tiên, tính từ Thứ 2 tuần 1)
# Value = [dòng 1, dòng 2, ...] (tối đa ~3 dòng cho gọn)
const DAY_STORIES: Dictionary = {
	0: [
		"☀  Sáng thứ Hai, tiếng chuông báo tiết đầu vang lên từ phía Nhà Thể Dục.",
		"Bạn siết quai ba lô, hít một hơi rồi bước vào khuôn viên — học kỳ đầu tiên chính thức bắt đầu.",
		"Ở sân trường, vài gương mặt mới cũng đang loay hoay tìm đường như bạn."
	],
	1: [
		"☕  Sáng thứ Ba. Bạn tìm ra con đường đến giảng đường nhanh hơn hôm qua.",
		"Vài người bạn mới bắt đầu quen mặt nhau ở hành lang Tòa B.",
		"Hôm nay không có tiết trong thời khóa biểu — bạn tranh thủ làm quen khuôn viên và xem trước bài ngày mai."
	],
	2: [
		"📚  Thứ Tư. Thư viện đông hơn mọi ngày — ai cũng đang tìm tài liệu.",
		"Bạn ghé qua và mượn được một cuốn giáo trình còn sót lại trên kệ.",
		"\"Tích lũy kiến thức từng ngày\" — câu khẩu hiệu dán trên cửa thư viện."
	],
	3: [
		"💻  Thứ Năm. Cơ sở lập trình buổi sáng, thực hành nối tiếp đến tận chiều.",
		"Thầy LĐK nhắc cả lớp kiểm tra lại bài trước khi nộp.",
		"Canteen hôm nay có món mới — nghe đồn ngon hơn thường lệ."
	],
	4: [
		"🎵  Thứ Sáu! Cả trường có vẻ vui hơn hẳn vì sắp đến cuối tuần.",
		"Nhóm sinh viên ngoài sân đang tập văn nghệ chuẩn bị cho sự kiện tháng sau.",
		"Bạn nhắc nhở bản thân: tuần sau còn bài tập chưa nộp."
	],
	5: [
		"☁  Thứ Bảy. Trường vắng hơn, chỉ còn vài nhóm ở lại học nhóm.",
		"Tiếng lá cây xào xạc trong gió — một buổi sáng yên tĩnh hiếm có.",
		"Đây là lúc tốt để ôn lại bài vở trước tuần mới."
	],
	6: [
		"🌿  Chủ nhật. Khuôn viên trường gần như trống vắng.",
		"Bạn tranh thủ đi dạo quanh sân, nhìn lại một tuần đã qua.",
		"Ngày mai lại bắt đầu — sẵn sàng chưa?"
	],
	7: [
		"📝  Tuần 2 bắt đầu. Thời khóa biểu đã vào nếp hơn tuần trước.",
		"Thầy LTC nhắc lịch nộp bài tập tuần này vào cuối tiết Vi tích phân.",
		"Bạn ghi vội vào sổ: \"Nộp bài trước Thứ 6.\""
	],
	10: [
		"💡  Thầy LĐK hướng dẫn vòng lặp trong buổi thực hành CSLT — \"Cứ lặp đến khi đúng.\"",
		"Cả lớp cười. Bạn ghi câu đó vào lề vở."
	],
	11: [
		"🌧  Mưa nhỏ. Mái hiên Tòa C đông người trú mưa hơn thường lệ.",
		"Ai đó để quên ô màu xanh ở gốc cột — đến tối vẫn chưa thấy ai lấy.",
		"Thời tiết mưa khiến buổi học cuối ngày trở nên buồn ngủ hơn."
	],
	13: [
		"🤔  Chủ nhật tuần 2. Bài tập CSLT đã nộp từ thứ Sáu.",
		"Bạn tranh thủ nghỉ ngơi, nhưng trong đầu vẫn nghĩ về mấy câu cuối cùng của bài.",
		"Ít nhất deadline đầu tiên đã qua. Thở phào."
	],
	14: [
		"🌞  Thứ Hai tuần 3. Bạn bắt đầu quen với nhịp sống đại học.",
		"Dậy sớm hơn, ngủ muộn hơn — nghe có vẻ mâu thuẫn nhưng đó là thực tế.",
		"Hai tuần trôi qua. Còn 15 tuần nữa của học kỳ."
	],
	21: [
		"📊  Tuần 4. GPA chưa cập nhật nhưng bạn tự cảm thấy mình đang... cố gắng.",
		"Trong sổ tay, bài thực hành Vi tích phân vẫn còn hạn nộp vào cuối tuần.",
		"Bạn mở máy tính lúc 10 giờ đêm. Màn hình quen thuộc hiện ra."
	],
	27: [
		"🏋  Tuần 4 đang trôi qua nhanh chóng. Lịch học dày đặc không còn xa lạ nữa.",
		"Điểm danh, ngồi đúng chỗ, ghi chép — thói quen hình thành từ lúc nào.",
		"Bác bảo vệ hôm nay chào bạn bằng tên — chắc đã quen mặt rồi."
	],
	34: [
		"⚠  Thầy LĐK thông báo: \"Tuần 8 thi giữa kỳ CSLT. Các em chuẩn bị kỹ nhé.\"",
		"Cả lớp im lặng vài giây rồi nhao nhao hỏi \"Thi những gì thầy ơi?\"",
		"Bạn mở lại tất cả bài ghi từ đầu kỳ. Nhiều hơn tưởng tượng."
	],
	42: [
		"🧠  Tuần 7. Phòng thư viện đông kín người ôn thi.",
		"Giữa kỳ còn 1 tuần nữa — không khí bắt đầu căng thẳng.",
		"Bạn tự nhủ: học đều còn hơn nhồi nhét."
	],
	48: [
		"📋  Ngày mai bắt đầu tuần thi giữa kỳ. CSLT sẽ thi vào buổi học thứ Năm.",
		"Bạn kiểm tra lại lịch thi và xếp tài liệu cần ôn lên bàn.",
		"Tuần này sẽ dài đây."
	],
	51: [
		"📝  Ngày mai thi giữa kỳ CSLT trong tiết của thầy LĐK.",
		"Thầy LTC nhắc: tuần sau đến lượt giữa kỳ Vi tích phân.",
		"\"Chưa xong đâu\" — câu nói quen thuộc của mùa thi."
	],
	52: [
		"✏  Thi giữa kỳ CSLT. Thầy LĐK ra đề — 60 phút, không được xem tài liệu.",
		"Bàn tay bạn gõ phím nhanh hơn bình thường. Đồng hồ đếm ngược.",
		"Nộp bài. Bước ra khỏi phòng. Thở."
	],
	58: [
		"📐  Thi Vi tích phân giữa kỳ. Tích phân từng phần — bài số 3 khó nhất.",
		"Thầy LTC đi qua dãy bàn, nhìn vào tờ bài của bạn rồi gật đầu.",
		"Không biết có phải dấu hiệu tốt không."
	],
	62: [
		"📈  Điểm giữa kỳ CSLT vừa được công bố.",
		"Bạn nhìn vào điểm của mình — cảm giác lẫn lộn giữa nhẹ nhõm và muốn làm tốt hơn.",
		"Còn nửa học kỳ. Vẫn còn kịp."
	],
	70: [
		"🍂  Tuần 11. Thời tiết bắt đầu mát hơn một chút.",
		"Sinh viên năm 2, năm 3 đang bàn chuyện đăng ký môn học kỳ sau.",
		"Bạn nhắc nhở: học kỳ này chưa xong, từ từ đã."
	],
	77: [
		"💼  Tuần 12. Câu lạc bộ IT thông báo tuyển thành viên mới.",
		"Một vài người bạn rủ tham gia. Bạn ghi tên vào — biết đâu hay.",
		"Điểm rèn luyện có thể tăng nếu tham gia tích cực."
	],
	84: [
		"🔔  Tuần 13. Thầy NKT nhắc bài tập Toán rời rạc nộp cuối tuần.",
		"Bài chứng minh đồ thị Euler — nghe hay nhưng làm thì đau đầu.",
		"Bạn ngồi lại thư viện đến 4 giờ chiều. Bác bảo vệ nhắc giờ đóng cổng."
	],
	91: [
		"🏆  Tuần 14. Học kỳ dần về đích. Mọi thứ bắt đầu dồn vào cuối kỳ.",
		"Deadline, bài tập lớn, ôn thi — danh sách việc cần làm dài ra mỗi ngày.",
		"Nhưng bạn đã đi được đến đây rồi. Thêm một chút nữa thôi."
	],
	98: [
		"⚡  Tuần 15. Thầy LĐK ra bài tập lập trình cuối kỳ — lớn nhất từ trước đến nay.",
		"\"Làm theo nhóm 2 người, nộp trước tuần thi cuối kỳ.\"",
		"Bạn nhắn tin cho người bạn cùng nhóm: \"Bắt đầu chưa?\""
	],
	105: [
		"📚  Tuần 16 — TUẦN THI CUỐI KỲ. Lịch thi dán khắp bảng thông báo.",
		"Thư viện mở cửa đến 5 giờ chiều — bạn tranh thủ đến ôn bài sau giờ học.",
		"Đây là chặng cuối. Tập trung."
	],
	108: [
		"🧠  Tuần thi cuối kỳ. Lịch CSLT dán kín bảng thông báo.",
		"Bạn dành buổi sáng ở thư viện rà lại thuật toán và những dòng code còn bỏ dở.",
		"Còn vài ngày nữa là đến môn thi cuối cùng. Không được chủ quan."
	],
	114: [
		"📐  Thi cuối kỳ Vi tích phân. Thầy LTC ra đề vừa sức — không dễ, không quá khó.",
		"Bạn làm được phần lớn bài. Còn 10 phút — kiểm tra lại.",
		"Nộp bài. Ra ngoài. Nắng chiều trải dài trên sân trường."
	],
	116: [
		"🎓  Kỳ thi cuối cùng kết thúc. Bạn đứng ở sân trường nhìn lại.",
		"Học kỳ 1 — 17 tuần — đã qua.",
		"Dù kết quả thế nào, bạn đã trải qua tất cả. Chờ bảng điểm thôi."
	],
}

# Mốc nhiệm vụ mở cùng ngày có sự kiện. Mục tiêu chỉ dẫn đường, không phạt nếu bỏ lỡ.
const STORY_OBJECTIVES: Array[Dictionary] = [
	{"day": 0, "title": "Ngày đầu ở HCMUS", "text": "Tìm và vào Nhà Thể Dục — nơi có tiết học đầu tiên.", "kind": "enter_module", "module": "nha_the_duc.gd"},
	{"day": 2, "title": "Mượn giáo trình", "text": "Vào Thư viện Tòa C, nói chuyện với thủ thư và mượn một cuốn sách.", "kind": "borrow_book"},
	{"day": 3, "title": "Quiz Nhập môn CNTT đầu tiên", "text": "Đến lớp đúng giờ, ngồi vào bàn để bắt đầu quiz Nhập môn Công nghệ Thông tin.", "kind": "class_started", "course": "INTRO_IT", "available_day": 3},
	{"day": 13, "title": "Bài tập đầu tiên", "text": "Mở sổ tay bằng Tab → B và hoàn thành bài tập CSLT.", "kind": "homework_completed", "course": "CSLT"},
	{"day": 34, "title": "Chuẩn bị giữa kỳ", "text": "Tự học 2 giờ trong game ở thư viện để tăng GPA và nhận ĐRL.", "kind": "library_study", "minutes": 120.0},
	{"day": 42, "title": "Ôn tập lần cuối", "text": "Tự học thêm 2 giờ trong game ở thư viện trước tuần thi.", "kind": "library_study", "minutes": 120.0},
	{"day": 52, "title": "Thi giữa kỳ CSLT", "text": "Hoàn thành lượt thi CSLT trong tuần 8.", "kind": "exam_completed", "exam": "CSLT_midterm", "deadline_week": 8},
	{"day": 58, "title": "Thi giữa kỳ Vi tích phân", "text": "Hoàn thành lượt thi Vi tích phân trong tuần 9.", "kind": "exam_completed", "exam": "VTP1_midterm", "deadline_week": 9},
	{"day": 84, "title": "Giữ nhịp học tập", "text": "Dành thêm 2 giờ trong game tự học ở thư viện.", "kind": "library_study", "minutes": 120.0},
	{"day": 105, "title": "Học phí cuối kỳ", "text": "Đọc kỹ thông báo và chọn cách xử lý học phí cuối kỳ.", "kind": "tuition_resolved"},
	{"day": 108, "title": "Ôn CSLT cuối kỳ", "text": "Tự học thêm 2 giờ trong game ở thư viện để củng cố kiến thức.", "kind": "library_study", "minutes": 120.0},
	{"day": 114, "title": "Thi cuối kỳ Vi tích phân", "text": "Hoàn thành lượt thi cuối kỳ Vi tích phân.", "kind": "exam_completed", "exam": "VTP1_final", "deadline_week": 17},
]

# ---------- BIẾN TRẠNG THÁI ----------
var _layer: CanvasLayer
var _bg: ColorRect
var _story_label: RichTextLabel
var _hint_label: Label
var _shown_days: Dictionary = {}   # {day: true} để không hiện 2 lần
var _visible: bool = false
var _was_paused: bool = false

# Typewriter
var _full_text: String = ""
var _char_index: int = 0
var _type_timer: float = 0.0
const TYPE_SPEED: float = 0.025   # giây/ký tự

# Tick sound
var _tick_player: AudioStreamPlayer
var _tick_last_ms: int = 0
var _objective_layer: CanvasLayer
var _objective_panel: PanelContainer
var _objective_title: Label
var _objective_text: Label
var _objective_queue: Array[Dictionary] = []
var _unlocked_objectives: Dictionary = {}
var _objective_feedback := ""
var _objective_feedback_time := 0.0
var _objective_display_cache := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 33   # trên daily_summary (32)
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_build_ui()
	_build_objective_ui()
	_setup_tick()
	_layer.visible = false

# ---------- PHÁT HIỆN NGÀY MỚI ----------
func _process(delta: float) -> void:
	if game == null:
		return
	_update_objectives(delta)

	if _visible:
		if _char_index < _full_text.length():
			_type_timer -= delta
			if _type_timer <= 0.0:
				_type_timer = TYPE_SPEED
				_char_index += 1
				_story_label.text = _full_text.left(_char_index)
				if _char_index < _full_text.length():
					_play_tick()
		return

	if get_tree().paused or game.is_busy():
		return

	if DAY_STORIES.has(game.day) and not _shown_days.has(game.day):
		_show_story(game.day)

func _unhandled_input(event: InputEvent) -> void:
	if not _visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			# Nếu đang gõ chữ, nhấn Enter = skip thẳng
			if _char_index < _full_text.length():
				_char_index = _full_text.length()
				_story_label.text = _full_text
			else:
				_close()
			get_viewport().set_input_as_handled()

# ---------- HIỆN / ẨN ----------
func _show_story(day: int) -> void:
	_shown_days[day] = true
	_was_paused = get_tree().paused
	var lines: Array = DAY_STORIES[day]
	if day == 116:
		lines = _semester_ending_lines()
	_full_text = "\n".join(lines)
	_char_index = 0
	_type_timer = 0.0
	_story_label.text = ""
	_hint_label.text = "Nhấn ENTER để tiếp tục..."
	_layer.visible = true
	_visible = true
	get_tree().paused = true

func _semester_ending_lines() -> Array:
	var stats: Node = game.stats
	if stats == null:
		return DAY_STORIES[116]
	var gpa_value := float(stats.get("gpa"))
	var drl_value := int(stats.get("drl"))
	var ending: Array
	if gpa_value >= 3.2 and drl_value >= 80:
		ending = [
			"🎓  Học kỳ đầu tiên khép lại. Bạn nhìn bảng điểm rồi bật cười — những ngày đến lớp và những buổi ôn bài đã thực sự có ý nghĩa.",
			"GPA %.2f, điểm rèn luyện %d. Bạn không chỉ vượt qua kỳ thi, mà còn trở thành một phần của ngôi trường này." % [gpa_value, drl_value],
			"Ngoài sân, nhóm bạn hẹn nhau học kỳ sau lại cùng cố gắng. Câu chuyện ở HCMUS vẫn còn tiếp tục."
		]
	elif gpa_value < 2.0 or drl_value < 50:
		ending = [
			"🎓  Kỳ thi cuối cùng đã qua. Bảng điểm chưa như mong đợi, và bạn biết vài lựa chọn trong học kỳ này đã để lại hậu quả.",
			"GPA %.2f, điểm rèn luyện %d. Thất bại không xóa được những gì bạn đã học về cách đứng dậy." % [gpa_value, drl_value],
			"Bạn mở sổ tay, khoanh ngày đầu học kỳ tới. Lần sau, mình sẽ bắt đầu sớm hơn."
		]
	else:
		ending = [
			"🎓  Học kỳ đầu tiên kết thúc. Bạn đã có những ngày làm tốt, cũng có lúc để deadline và bài thi cuốn đi.",
			"GPA %.2f, điểm rèn luyện %d — chưa hoàn hảo, nhưng là kết quả của chính những lựa chọn bạn đã làm." % [gpa_value, drl_value],
			"Trên đường về, bạn nhắn nhóm bạn: \"Học kỳ sau vẫn học chung chứ?\" Một chương khép lại, một chương mới chờ phía trước."
		]
	return ending

func _close() -> void:
	_layer.visible = false
	_visible = false
	get_tree().paused = _was_paused

# ---------- TUYẾN NHIỆM VỤ / EVENT ----------
func _update_objectives(delta: float) -> void:
	for objective in STORY_OBJECTIVES:
		var event_day := int(objective.get("day", -1))
		var event_key := str(event_day)
		if event_day == game.day and not _unlocked_objectives.has(event_key):
			for previous in _objective_queue:
				if str(previous.get("status", "")) == "active":
					previous["status"] = "superseded"
			var unlocked: Dictionary = objective.duplicate(true)
			unlocked["status"] = "active"
			if str(unlocked.get("kind", "")) == "library_study":
				unlocked["baseline_study"] = _total_library_study_minutes()
			_objective_queue.append(unlocked)
			_unlocked_objectives[event_key] = true
			_objective_layer.visible = true

	if _objective_feedback_time > 0.0:
		_objective_feedback_time = maxf(0.0, _objective_feedback_time - delta)
	for objective in _objective_queue:
		if str(objective.get("status", "")) != "active":
			continue
		var deadline := int(objective.get("deadline_week", 0))
		if deadline > 0 and Schedule.week_no(game.day) > deadline:
			objective["status"] = "expired"
			_objective_feedback = "Sự kiện đã qua: " + str(objective.get("title", ""))
			_objective_feedback_time = 3.0
		elif _is_objective_complete(objective):
			objective["status"] = "complete"
			_objective_feedback = "✓ Hoàn thành: " + str(objective.get("title", ""))
			_objective_feedback_time = 2.6
	_refresh_objective_ui()


func _current_objective() -> Dictionary:
	for objective in _objective_queue:
		if str(objective.get("status", "")) == "active":
			return objective
	return {}


func _is_objective_complete(objective: Dictionary) -> bool:
	var kind := str(objective.get("kind", ""))
	match kind:
		"enter_module":
			var module := _find_map_feature(str(objective.get("module", "")))
			return module != null and bool(module.get("inside"))
		"borrow_book":
			var library := _find_map_feature("thu_vien.gd")
			return library != null and not str(library.get("_borrowed")).is_empty()
		"class_started":
			var classes := _find_feature_with_script("/scripts/features/class_attendance.gd")
			if classes == null:
				return false
			var sessions: Variant = classes.get("_started_sessions")
			if typeof(sessions) != TYPE_DICTIONARY:
				return false
			for session_id in sessions:
				var fields := str(session_id).split(":")
				if fields.size() >= 2 and int(fields[0]) >= int(objective.get("available_day", objective.get("day", 0))) and fields[1].contains(str(objective.get("course", ""))):
					return true
			return false
		"homework_completed":
			var classes := _find_feature_with_script("/scripts/features/class_attendance.gd")
			if classes == null or not classes.has_method("get_homework_assignments"):
				return false
			for assignment in classes.call("get_homework_assignments"):
				if bool(assignment.get("completed", false)) and str(assignment.get("course_code", "")).begins_with(str(objective.get("course", ""))):
					return true
			return false
		"library_study":
			return _total_library_study_minutes() - float(objective.get("baseline_study", 0.0)) >= float(objective.get("minutes", 30.0))
		"exam_completed":
			var quiz := _find_feature_with_script("/scripts/features/math_quiz.gd")
			if quiz == null:
				return false
			var attempts: Variant = quiz.get("official_exam_attempts")
			if typeof(attempts) != TYPE_DICTIONARY:
				return false
			var attempt: Variant = attempts.get(str(objective.get("exam", "")), {})
			return typeof(attempt) == TYPE_DICTIONARY and str(attempt.get("status", "")) == "completed"
		"tuition_resolved":
			return game.stats != null and bool(game.stats.get("final_tuition_resolved"))
	return false


func _find_map_feature(filename: String) -> Node:
	return _find_feature_with_script("/scripts/maps/" + filename)


func _find_feature_with_script(path_suffix: String) -> Node:
	for feature in game.features:
		var script: Variant = feature.get_script()
		if script is Script and str(script.resource_path).ends_with(path_suffix):
			return feature
	return null


func _total_library_study_minutes() -> float:
	var library := _find_map_feature("thu_vien.gd")
	if library == null:
		return 0.0
	var study: Variant = library.get("_study_today")
	if typeof(study) != TYPE_DICTIONARY:
		return 0.0
	var total := 0.0
	for minutes in study.values():
		total += float(minutes)
	return total


func _build_objective_ui() -> void:
	_objective_layer = CanvasLayer.new()
	_objective_layer.layer = 8
	_objective_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_objective_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_layer.add_child(root)
	_objective_panel = PanelContainer.new()
	_objective_panel.position = Vector2(118.0, 5.0)
	_objective_panel.size = Vector2(250.0, 42.0)
	_objective_panel.custom_minimum_size = Vector2(250.0, 42.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.14, 0.94)
	style.border_color = Color("75c8ff")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	_objective_panel.add_theme_stylebox_override("panel", style)
	_objective_panel.visible = false
	root.add_child(_objective_panel)
	var theme := Theme.new()
	theme.default_font = game.font
	_objective_panel.theme = theme
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	_objective_panel.add_child(column)
	_objective_title = Label.new()
	_objective_title.add_theme_font_size_override("font_size", 7)
	_objective_title.add_theme_color_override("font_color", Color("ffd23f"))
	column.add_child(_objective_title)
	_objective_text = Label.new()
	_objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_objective_text.add_theme_font_size_override("font_size", 8)
	_objective_text.add_theme_color_override("font_color", Color("f4f7ff"))
	column.add_child(_objective_text)


func _refresh_objective_ui() -> void:
	if _objective_layer == null:
		return
	var current := _current_objective()
	var shown := true
	var title := ""
	var body := ""
	var text_color := Color("f4f7ff")
	if _objective_feedback_time > 0.0:
		title = "SỰ KIỆN CỐT TRUYỆN"
		body = _objective_feedback
		text_color = Color("8ff0ad") if _objective_feedback.begins_with("✓") else Color("ffd23f")
	elif not current.is_empty():
		title = "MỤC TIÊU · " + str(current.get("title", ""))
		body = str(current.get("text", ""))
	else:
		shown = false
	var display_key := "%s|%s|%s|%s" % [str(shown), title, body, text_color.to_html(true)]
	if display_key == _objective_display_cache:
		return
	_objective_display_cache = display_key
	_objective_panel.visible = shown
	_objective_title.text = title
	_objective_text.text = body
	_objective_text.add_theme_color_override("font_color", text_color)

# ---------- TYPEWRITER TICK SOUND ----------
func _setup_tick() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.05
	_tick_player = AudioStreamPlayer.new()
	_tick_player.stream = gen
	_tick_player.volume_db = -14.0
	_tick_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_tick_player)
	_tick_player.play()

func _play_tick() -> void:
	var now := Time.get_ticks_msec()
	if now - _tick_last_ms < 42:
		return
	_tick_last_ms = now
	if not _tick_player.playing:
		_tick_player.play()
	var pb := (_tick_player.get_stream_playback() as AudioStreamGeneratorPlayback)
	if pb == null:
		return
	var frames := pb.get_frames_available()
	for i in frames:
		var t := float(i) / 22050.0
		var env := exp(-t * 90.0)
		var s := sin(TAU * 920.0 * t) * env * 0.35
		pb.push_frame(Vector2(s, s))

# ---------- XÂY DỰNG UI ----------
func _build_ui() -> void:
	# Nền mờ
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.72)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_bg)

	# Panel giữa màn hình
	var panel := PanelContainer.new()
	panel.position = Vector2(50, 60)
	panel.size = Vector2(380, 160)
	panel.custom_minimum_size = Vector2(380, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f172a")
	style.border_color = Color("facc15")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	_layer.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	# Icon + tiêu đề
	var title := Label.new()
	title.text = "✦ NHẬT KÝ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("facc15"))
	col.add_child(title)

	# Text cốt truyện
	_story_label = RichTextLabel.new()
	_story_label.bbcode_enabled = false
	_story_label.fit_content = true
	_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_label.custom_minimum_size = Vector2(348, 72)
	_story_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_label.add_theme_font_size_override("normal_font_size", 12)
	_story_label.add_theme_color_override("default_color", Color("f8fafc"))
	col.add_child(_story_label)

	# Hint
	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.add_theme_color_override("font_color", Color("64748b"))
	col.add_child(_hint_label)
