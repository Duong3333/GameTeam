extends RefCounted

const CONFIG_PATH := "res://quiz_exam_bank/grading_config.json"

static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open quiz grading config %s: %s" % [CONFIG_PATH, error_string(FileAccess.get_open_error())])
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error("Invalid quiz grading config %s at line %d: %s" % [CONFIG_PATH, parser.get_error_line(), parser.get_error_message()])
		return {}
	if typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Quiz grading config must contain a JSON object: %s" % CONFIG_PATH)
		return {}
	var conversion: Variant = parser.data.get("conversion")
	if typeof(conversion) != TYPE_DICTIONARY or not conversion.has("scale_10") or not conversion.has("gpa_multiplier") or not conversion.has("gpa_max"):
		push_error("Quiz grading config must define conversion.scale_10, conversion.gpa_multiplier, and conversion.gpa_max.")
		return {}
	if float(conversion["scale_10"]) <= 0.0 or float(conversion["gpa_multiplier"]) <= 0.0 or float(conversion["gpa_max"]) <= 0.0:
		push_error("Quiz grading conversion values must be positive.")
		return {}
	return parser.data

static func grade_question(question: Dictionary, response: String) -> Dictionary:
	var result := {
		"gradable": false,
		"needs_review": true,
		"earned_points": 0.0,
		"max_points": 0.0,
		"percentage": 0.0,
		"criteria": [],
		"expected": ""
	}
	if not bool(question.get("verified", false)) or str(question.get("answer_status", "")) not in ["official", "verified_ai"]:
		return result

	result.expected = str(question.get("official_answer", ""))
	var rubric: Variant = question.get("grading_rubric", [])
	if question.has("grading_rubric") and typeof(rubric) != TYPE_ARRAY:
		push_error("Question %s has an invalid grading_rubric; expected an array." % str(question.get("id", "unknown")))
		return result
	if typeof(rubric) == TYPE_ARRAY and not rubric.is_empty():
		var rubric_array: Array = rubric
		return _grade_rubric(question, rubric_array, response, result)

	var config := load_config()
	if config.is_empty():
		return result
	if str(question.get("grading_method", "manual")) != "exact":
		return result
	var answer_type := str(question.get("answer_type", ""))
	if answer_type not in ["integer", "decimal", "code_output"]:
		return result
	var accepted: Variant = question.get("accepted_answers", [])
	if typeof(accepted) != TYPE_ARRAY or accepted.is_empty():
		return result
	var accepted_answers: Array = accepted

	var weight := maxf(float(question.get("points", 1.0)), 0.0)
	if weight <= 0.0:
		return result
	var tolerance := float(question.get("tolerance", 0.0))
	if tolerance < 0.0:
		push_error("Question %s has a negative grading tolerance." % str(question.get("id", "unknown")))
		return result
	var correct := _matches_supported_answer(answer_type, response, accepted_answers, tolerance)
	result.gradable = true
	result.needs_review = false
	result.earned_points = weight if correct else 0.0
	result.max_points = weight
	result.percentage = 100.0 if correct else 0.0
	result.criteria = [{
		"id": "verified_exact_result",
		"label": "Kết quả chính xác đã xác minh",
		"earned_points": result.earned_points,
		"max_points": weight,
		"gradable": true
	}]
	return result

static func _grade_rubric(question: Dictionary, rubric: Array, response: String, result: Dictionary) -> Dictionary:
	var total := 0.0
	var earned := 0.0
	var criteria: Array[Dictionary] = []
	var has_unassessed_criterion := false
	for criterion_value in rubric:
		if typeof(criterion_value) != TYPE_DICTIONARY:
			push_error("Question %s has a non-object rubric criterion." % str(question.get("id", "unknown")))
			return result
		var criterion: Dictionary = criterion_value
		var weight := float(criterion.get("weight", 0.0))
		if weight <= 0.0:
			push_error("Question %s has a rubric criterion with a non-positive weight." % str(question.get("id", "unknown")))
			return result
		var method := str(criterion.get("method", "manual"))
		if method not in ["exact", "numeric_tolerance"]:
			has_unassessed_criterion = true
			criteria.append({
				"id": str(criterion.get("id", "")),
				"label": str(criterion.get("label", "Cần kiểm tra thủ công")),
				"earned_points": 0.0,
				"max_points": weight,
				"gradable": false
			})
			continue
		var accepted: Variant = criterion.get("accepted_answers", [])
		if typeof(accepted) != TYPE_ARRAY or accepted.is_empty():
			has_unassessed_criterion = true
			criteria.append({
				"id": str(criterion.get("id", "")),
				"label": str(criterion.get("label", "Thiếu đáp án cho tiêu chí")),
				"earned_points": 0.0,
				"max_points": weight,
				"gradable": false
			})
			continue
		var accepted_answers: Array = accepted
		var criterion_type := str(criterion.get("answer_type", question.get("answer_type", "")))
		if criterion_type not in ["integer", "decimal", "code_output"] or (method == "numeric_tolerance" and criterion_type not in ["integer", "decimal"]):
			has_unassessed_criterion = true
			criteria.append({
				"id": str(criterion.get("id", "")),
				"label": str(criterion.get("label", "Chưa hỗ trợ chấm tự động tiêu chí này")),
				"earned_points": 0.0,
				"max_points": weight,
				"gradable": false
			})
			continue
		var tolerance := float(criterion.get("tolerance", question.get("tolerance", 0.0)))
		if tolerance < 0.0:
			push_error("Question %s has a rubric criterion with negative tolerance." % str(question.get("id", "unknown")))
			return result
		var criterion_response := _get_criterion_response(response, criterion)
		var correct := _matches_supported_answer(
			criterion_type,
			criterion_response,
			accepted_answers,
			tolerance
		)
		total += weight
		if correct:
			earned += weight
		criteria.append({
			"id": str(criterion.get("id", "")),
			"label": str(criterion.get("label", "")),
			"earned_points": weight if correct else 0.0,
			"max_points": weight,
			"gradable": true
		})
	result.criteria = criteria
	result.earned_points = earned
	result.max_points = total
	result.gradable = total > 0.0
	result.needs_review = has_unassessed_criterion or total == 0.0
	result.percentage = earned / total * 100.0 if total > 0.0 else 0.0
	return result

static func _get_criterion_response(response: String, criterion: Dictionary) -> String:
	var line_index := int(criterion.get("response_line", -1))
	if line_index < 0:
		return response
	var lines := response.replace("\r\n", "\n").replace("\r", "\n").split("\n", true)
	return str(lines[line_index]).strip_edges() if line_index < lines.size() else ""

static func _matches_supported_answer(answer_type: String, response: String, accepted: Array, tolerance: float) -> bool:
	var candidate := response.strip_edges()
	if candidate.is_empty():
		return false
	for answer in accepted:
		var expected := str(answer).strip_edges()
		match answer_type:
			"integer", "decimal":
				var candidate_number := _parse_numeric_answer(candidate)
				var expected_number := _parse_numeric_answer(expected)
				var both_valid := bool(candidate_number.get("valid", false)) and bool(expected_number.get("valid", false))
				if both_valid:
					var candidate_value := float(candidate_number["value"])
					var expected_value := float(expected_number["value"])
					var difference := absf(candidate_value - expected_value)
					var comparison_scale := maxf(1.0, maxf(absf(candidate_value), absf(expected_value)))
					var floating_point_epsilon := comparison_scale * 2.220446049250313e-16
					if difference <= tolerance + floating_point_epsilon:
						return true
			"code_output":
				if _normalize_output(candidate) == _normalize_output(expected):
					return true
	return false

static func _parse_numeric_answer(value: String) -> Dictionary:
	var normalized := value.strip_edges().replace("−", "-").replace(",", ".")
	if not normalized.is_valid_float():
		return {"valid": false, "value": 0.0}
	return {"valid": true, "value": float(normalized)}

static func grade_to_ten(percentage: float, config: Dictionary) -> float:
	var conversion: Dictionary = config.get("conversion", {})
	var scale := float(conversion["scale_10"])
	return clampf(percentage, 0.0, 100.0) / 100.0 * scale

static func grade_to_gpa(grade_10: float, config: Dictionary) -> float:
	var conversion: Dictionary = config.get("conversion", {})
	var factor := float(conversion["gpa_multiplier"])
	var maximum_gpa := float(conversion["gpa_max"])
	return clampf(grade_10 * factor, 0.0, maximum_gpa)

static func gpa_max(config: Dictionary) -> float:
	var conversion: Dictionary = config.get("conversion", {})
	return float(conversion["gpa_max"])

static func _normalize_output(value: String) -> String:
	var normalized := value.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	var lines := normalized.split("\n", true)
	var spaces := RegEx.new()
	spaces.compile("\\s+")
	for index in lines.size():
		lines[index] = spaces.sub(lines[index].strip_edges(), " ", true)
	return "\n".join(lines)
