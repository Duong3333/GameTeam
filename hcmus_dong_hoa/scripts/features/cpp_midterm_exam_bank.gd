extends RefCounted
## Ngân hàng đề giữa kỳ Cơ sở lập trình thực hành.
## Mỗi đề chọn 3 nhóm chủ đề lớn khác nhau; P1/P2/P3 trong cùng nhóm là lựa chọn loại trừ.

const BANK_PATH := "res://scripts/features/cpp_midterm_question_bank.json"
const CSLT_MIDTERM_DURATION_SECONDS := 90 * 60
const HEAVY_TOPIC_GROUP_IDS := ["ARRAY", "STRUCT_FILE"]
static var _cached_bank: Dictionary = {}

static func _bank() -> Dictionary:
	if not _cached_bank.is_empty():
		return _cached_bank
	if not FileAccess.file_exists(BANK_PATH):
		push_error("Không tìm thấy ngân hàng đề giữa kỳ: " + BANK_PATH)
		return {}
	var file := FileAccess.open(BANK_PATH, FileAccess.READ)
	if file == null:
		push_error("Không đọc được ngân hàng đề giữa kỳ.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Định dạng JSON ngân hàng đề giữa kỳ không hợp lệ.")
		return {}
	_cached_bank = parsed
	return _cached_bank

static func _question_by_id(question_id: String) -> Dictionary:
	var bank := _bank()
	for group_value in bank.get("groups", []):
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		for part_value in group_value.get("parts", []):
			if typeof(part_value) != TYPE_DICTIONARY:
				continue
			for question_value in part_value.get("questions", []):
				if typeof(question_value) != TYPE_DICTIONARY:
					continue
				if str(question_value.get("id", "")) == question_id and bool(question_value.get("enabled", true)):
					return question_value.duplicate(true)
	return {}

static func supports(question_id: String) -> bool:
	return not _question_by_id(question_id).is_empty()

static func get_default_input(question_id: String) -> String:
	var question := _question_by_id(question_id)
	return str(question.get("input", ""))

static func build_program(question_id: String, student_code: String) -> Dictionary:
	var question := _question_by_id(question_id)
	if question.is_empty():
		return {}
	var source := str(question.get("prelude", ""))
	if not source.ends_with("\n"):
		source += "\n"
	# Các prototypes (và struct/helper trong prelude) được cung cấp tự động như header.
	for prototype in question.get("required_functions", []):
		var declaration := str(prototype).strip_edges()
		if not declaration.ends_with(";"):
			declaration += ";"
		source += declaration + "\n"
	source += "\n" + student_code + "\n" + str(question.get("harness", ""))
	return {
		"source": source,
		"input": str(question.get("input", "")),
		"expected_cases": question.get("expected_cases", []).duplicate(true),
		"question_id": question_id
	}

static func build_submission(question_id: String, student_code: String) -> Dictionary:
	return build_program(question_id, student_code)

static func generate_exam() -> Dictionary:
	var bank := _bank()
	var heavy_groups: Array = []
	var regular_groups: Array = []
	for group_value in bank.get("groups", []):
		if typeof(group_value) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_value
		var has_questions := false
		for part_value in group.get("parts", []):
			if typeof(part_value) != TYPE_DICTIONARY:
				continue
			for question_value in part_value.get("questions", []):
				if typeof(question_value) == TYPE_DICTIONARY and bool(question_value.get("enabled", true)):
					has_questions = true
					break
			if has_questions:
				break
		if not has_questions:
			continue
		if str(group.get("id", "")) in HEAVY_TOPIC_GROUP_IDS:
			heavy_groups.append(group)
		else:
			regular_groups.append(group)

	if heavy_groups.is_empty() or regular_groups.size() < 1:
		push_error("Ngân hàng cần ít nhất một chủ đề khó (Array/Struct) và một chủ đề khác.")
		return {}

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	heavy_groups.shuffle()
	regular_groups.shuffle()

	# Một đề có 1 hoặc 2 câu thuộc nhóm khó Array/Struct.
	# Mỗi nhóm lớn chỉ đóng góp đúng một câu; P/Part cùng nhóm vẫn loại trừ nhau.
	var heavy_count := rng.randi_range(1, mini(2, heavy_groups.size()))
	var regular_needed := 3 - heavy_count
	if regular_groups.size() < regular_needed:
		push_error("Không đủ chủ đề Loop/Function/Advanced Function để hoàn thiện đề 3 câu.")
		return {}

	var chosen_groups: Array = []
	for index in range(heavy_count):
		chosen_groups.append(heavy_groups[index])
	for index in range(regular_needed):
		chosen_groups.append(regular_groups[index])
	chosen_groups.shuffle()

	if chosen_groups.size() != 3:
		push_error("Không thể tạo đề giữa kỳ gồm đúng 3 câu.")
		return {}

	var point_values := [3.0, 3.0, 4.0]
	var exam_questions: Array = []
	var selected_group_ids: Array[String] = []
	var selected_parts: Array[String] = []
	var actual_heavy_count := 0

	for index in chosen_groups.size():
		var group: Dictionary = chosen_groups[index]
		var available_parts: Array = []
		for part_value in group.get("parts", []):
			if typeof(part_value) != TYPE_DICTIONARY:
				continue
			var part: Dictionary = part_value
			var enabled_questions: Array = []
			for question_value in part.get("questions", []):
				if typeof(question_value) == TYPE_DICTIONARY and bool(question_value.get("enabled", true)):
					enabled_questions.append(question_value)
			if not enabled_questions.is_empty():
				available_parts.append({"part": part, "questions": enabled_questions})
		if available_parts.is_empty():
			push_error("Chủ đề không có câu hỏi dùng được: " + str(group.get("id", "")))
			return {}

		# Chỉ lấy một P/Part trong nhóm lớn (Function P1 hoặc P2; Array P1/P2/P3; ...).
		var selected_part_data: Dictionary = available_parts[rng.randi_range(0, available_parts.size() - 1)]
		var candidate_questions: Array = selected_part_data.get("questions", [])
		var selected_question: Dictionary = candidate_questions[rng.randi_range(0, candidate_questions.size() - 1)].duplicate(true)
		var group_id := str(group.get("id", ""))
		if group_id in HEAVY_TOPIC_GROUP_IDS:
			actual_heavy_count += 1
		selected_question["group_id"] = group_id
		selected_question["group_label"] = str(group.get("label", ""))
		selected_question["part_id"] = str(selected_part_data.get("part", {}).get("id", ""))
		selected_question["part_label"] = str(selected_part_data.get("part", {}).get("label", ""))
		selected_question["points"] = float(point_values[index])
		selected_question["answer_type"] = "short_code"
		selected_question["type"] = "short_code"
		selected_question["verified"] = true
		selected_question["answer_status"] = "verified_ai"
		selected_question["grading_method"] = "exact_testcases"
		var function_lines := PackedStringArray()
		for prototype in selected_question.get("required_functions", []):
			function_lines.append("• " + str(prototype))
		var prompt := "CHỦ ĐỀ: %s · PHẦN: %s · TỐI ĐA %.2f ĐIỂM\n\n" % [
			str(selected_question.get("group_label", "")),
			str(selected_question.get("part_label", "")),
			float(point_values[index])
		]
		prompt += "YÊU CẦU\n" + str(selected_question.get("display_prompt", selected_question.get("description", "")))
		if not function_lines.is_empty():
			prompt += "\n\nHÀM CẦN VIẾT\n" + "\n".join(function_lines)
		prompt += "\n\nChỉ viết các hàm trên trong một vùng code; không viết main() hay tạo file riêng."
		selected_question["question_text"] = prompt
		selected_question["title"] = str(selected_question.get("title", "Câu lập trình")) + " · " + str(selected_question.get("part_label", ""))
		exam_questions.append(selected_question)
		selected_group_ids.append(group_id)
		selected_parts.append(str(selected_question.get("part_id", "")))

	if actual_heavy_count < 1 or actual_heavy_count > 2:
		push_error("Đề giữa kỳ phải có từ 1 đến 2 câu thuộc Array/Struct.")
		return {}

	return {
		"exam_id": "CSLT_PRACTICAL_MIDTERM_RANDOM",
		"subject_code": "CSLT",
		"subject": "Cơ sở lập trình thực hành",
		"exam_type": "midterm",
		"duration_seconds": CSLT_MIDTERM_DURATION_SECONDS,
		"max_points": 10.0,
		"question_count": 3,
		"heavy_topic_question_count": actual_heavy_count,
		"selected_group_ids": selected_group_ids,
		"selected_part_ids": selected_parts,
		"questions": exam_questions
	}
