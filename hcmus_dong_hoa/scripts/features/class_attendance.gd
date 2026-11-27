extends "res://scripts/features/feature.gd"
# QUIZ THEO THOI KHOA BIEU – KHONG PHU THUOC NPC GIAO VIEN.
# Dieu kien bat dau: dung tiet hoc + dung phong + nguoi choi dang ngoi vao ban.
# Quiz tiet hoc chi gom ABCD va tra loi ngan. Essay/IDE chi nam trong luong thi rieng.

const Schedule := preload("res://scripts/features/schedule_data.gd")
const CourseCatalog := preload("res://scripts/features/course_quiz_catalog.gd")

var _quiz: Node
var _student_panel: Node
var _active_room: Node
var _active_session_id := ""
var _active_course_code := ""
var _active_course_title := ""
var _active_class_day := -1
var _active_class_end := 0.0
var _started_sessions: Dictionary = {}
var _homework_assignments: Array[Dictionary] = []
var _active_homework_id := ""

func _process(_delta: float) -> void:
	_find_features()
	_process_homework_result()
	if not _active_session_id.is_empty():
		_process_active_class_session()
		return
	if _quiz == null:
		return
	if _quiz.has_method("is_academic_quiz_open") and bool(_quiz.call("is_academic_quiz_open")):
		return
	var context := _find_seated_room_context()
	if context.is_empty():
		return
	var current_class := _find_current_class(context)
	if current_class.is_empty():
		return
	_start_class(current_class, context)

func _find_features() -> void:
	if _quiz == null or not is_instance_valid(_quiz):
		for feature in game.features:
			if feature != self and feature.has_method("start_class_round") and feature.has_method("is_class_quiz_open"):
				_quiz = feature
				break
	if _student_panel == null or not is_instance_valid(_student_panel):
		for feature in game.features:
			if feature != self and feature.has_method("show_notice"):
				_student_panel = feature
				break

func _has_property(object: Object, property_name: String) -> bool:
	for property_info in object.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false

func _find_seated_room_context() -> Dictionary:
	for feature in game.features:
		if feature == null or not is_instance_valid(feature):
			continue
		if not _has_property(feature, "inside") or not bool(feature.get("inside")):
			continue
		if not _has_property(feature, "_seated"):
			continue
		var seated_value: Variant = feature.get("_seated")
		if seated_value == null or int(seated_value) < 0:
			continue

		var script_path := ""
		var attached_script: Variant = feature.get_script()
		if attached_script is Script:
			script_path = str(attached_script.resource_path)
		if feature.has_method("open_classroom") and _has_property(feature, "_room_key"):
			return {
				"node": feature,
				"room_type": "classroom",
				"room_key": str(feature.get("_room_key")),
			}
		if script_path.ends_with("/scripts/maps/b42_lab.gd"):
			# b42_lab.gd dùng chung cho nhiều phòng máy; _active_preset cho biết đang ở phòng nào (B42_VTP, D_CSLT).
			var lab_key := str(feature.get("_active_preset")) if _has_property(feature, "_active_preset") else "B42_LAB"
			return {
				"node": feature,
				"room_type": "lab",
				"room_key": lab_key,
			}
	return {}

func _find_current_class(context: Dictionary) -> Dictionary:
	# Tuan thi giua ky/cuoi ky khong phat Quiz tiet hoc thong thuong.
	# Luong thi rieng van duoc giu trong he thong exam hien co.
	var current_week := Schedule.week_no(game.day)
	if current_week in Schedule.MIDTERM_WEEKS or current_week in Schedule.FINAL_WEEKS:
		return {}
	var day_of_week := Schedule.weekday(game.day) + 2
	for course_value in Schedule.courses_on(day_of_week):
		if typeof(course_value) != TYPE_ARRAY:
			continue
		var course: Array = course_value
		if course.size() < 5:
			continue
		var time_range := Schedule.time_range(str(course[1]), str(course[3]))
		var start_minute := float(time_range[0])
		var end_minute := float(time_range[1])
		if game.game_min < start_minute or game.game_min >= end_minute:
			continue
		var course_code := CourseCatalog.resolve_course_code(
			course,
			str(context.get("room_type", "")),
			str(context.get("room_key", ""))
		)
		if course_code.is_empty() or not CourseCatalog.has_class_bank(course_code):
			continue
		return {
			"course": course,
			"course_code": course_code,
			"course_name": CourseCatalog.course_name(course_code),
			"start_minute": start_minute,
			"end_minute": end_minute,
		}
	return {}

func _start_class(current_class: Dictionary, context: Dictionary) -> void:
	if _quiz == null:
		return
	var course_code := str(current_class.get("course_code", ""))
	var course_name := str(current_class.get("course_name", course_code))
	var start_minute := int(current_class.get("start_minute", 0.0))
	var session_id := "%d:%s:%d" % [game.day, course_code, start_minute]
	if _started_sessions.has(session_id):
		return
	var title := "QUIZ TRÊN LỚP · " + course_name
	# Mỗi tuần (tính theo tuần tuyệt đối của game) một bộ câu khác nhau; vào lại trong cùng tuần thì giữ nguyên bộ câu.
	var session_key := "CLASS:%s:W%d" % [course_code, int(game.day / 7)]
	var started := bool(_quiz.call("start_class_round", course_code, title, session_key))
	if not started:
		push_warning("Không thể mở Quiz trên lớp %s; kiểm tra ngân hàng câu hỏi của môn." % course_name)
		return

	_started_sessions[session_id] = true
	_active_session_id = session_id
	_active_course_code = course_code
	_active_course_title = course_name
	_active_class_day = game.day
	_active_class_end = float(current_class.get("end_minute", 0.0))
	_active_room = context.get("node") as Node
	_set_room_input_locked(_active_room, true)

func _process_active_class_session() -> void:
	if _quiz != null and bool(_quiz.call("is_class_quiz_open")):
		_set_room_input_locked(_active_room, true)
		if _quiz.call("is_class_quiz_running") and (game.day > _active_class_day or (game.day == _active_class_day and game.game_min >= _active_class_end)):
			_quiz.call("finish_class_round")
		return

	# Nguoi choi co the dong man hinh ket qua som; mo lai input trong phong,
	# nhung session_id da duoc danh dau nen khong the lam lai Quiz trong cung tiet.
	_set_room_input_locked(_active_room, false)
	if game.day > _active_class_day or (game.day == _active_class_day and game.game_min >= _active_class_end):
		_complete_class_session()

func _set_room_input_locked(room: Node, locked: bool) -> void:
	if room == null or not is_instance_valid(room):
		return
	room.set_process_input(not locked)
	room.set_process_unhandled_input(not locked)

func _complete_class_session() -> void:
	if CourseCatalog.homework_enabled(_active_course_code):
		_assign_homework()
	_active_session_id = ""
	_active_course_code = ""
	_active_course_title = ""
	_active_class_day = -1
	_active_class_end = 0.0
	_active_room = null

# ---------- Bài tập về nhà: hiện giữ cho Cơ sở lập trình lý thuyết ----------
func _assign_homework() -> void:
	for assignment in _homework_assignments:
		if str(assignment.get("id", "")) == _active_session_id:
			return
	var week := Schedule.week_no(_active_class_day)
	var title := "%s · Bài tập tuần %d" % [_active_course_title, week]
	_homework_assignments.append({
		"id": _active_session_id,
		"title": title,
		"week": week,
		"course_code": _active_course_code,
		"completed": false,
	})
	if _student_panel != null:
		_student_panel.call("show_notice", "BÀI TẬP VỀ NHÀ", "Bài tập tuần %d môn Cơ sở lập trình lý thuyết đã được giao. Nhấn Tab rồi B để mở." % week)

func get_homework_assignments() -> Array:
	return _homework_assignments.duplicate(true)

func start_homework(assignment_id: String) -> bool:
	if not _active_session_id.is_empty() or not _active_homework_id.is_empty() or _quiz == null:
		return false
	for assignment in _homework_assignments:
		if str(assignment.get("id", "")) != assignment_id or bool(assignment.get("completed", false)):
			continue
		var title := str(assignment.get("title", "BÀI TẬP VỀ NHÀ"))
		var course_code := str(assignment.get("course_code", "CSLT_THEORY"))
		if bool(_quiz.call("start_homework_round", title, course_code, "HW:" + assignment_id)):
			_active_homework_id = assignment_id
			return true
	return false

func _process_homework_result() -> void:
	if _active_homework_id.is_empty() or _quiz == null:
		return
	if bool(_quiz.call("is_academic_quiz_result")):
		for assignment in _homework_assignments:
			if str(assignment.get("id", "")) == _active_homework_id:
				assignment["completed"] = true
				if _student_panel != null:
					_student_panel.call("show_notice", "ĐÃ HOÀN THÀNH BÀI TẬP", str(assignment.get("title", "")))
				break
		_active_homework_id = ""
		return
	if not bool(_quiz.call("is_academic_quiz_open")):
		_active_homework_id = ""
