extends RefCounted
# So sanh output cua chuong trinh voi cac testcase offline.

const CASE_END := "@@CASE_END@@"

static func grade_submission(actual_output: String, expected_cases: Array, max_points: float, _run_success: bool) -> Dictionary:
	var actual_cases := _split_cases(actual_output)
	var total := expected_cases.size()
	var correct := 0
	var criteria: Array[Dictionary] = []

	for index in total:
		var expected := str(expected_cases[index])
		var actual := str(actual_cases[index]) if index < actual_cases.size() else ""
		# Moi marker xac nhan mot testcase da chay xong; giu diem cac case hoan tat
		# neu testcase sau gap runtime error hoac timeout.
		var passed := index < actual_cases.size() and _normalize(actual) == _normalize(expected)
		if passed:
			correct += 1
		criteria.append({
			"id": "test_%d" % (index + 1),
			"label": "Testcase %d" % (index + 1),
			"earned_points": max_points / maxf(float(total), 1.0) if passed else 0.0,
			"max_points": max_points / maxf(float(total), 1.0),
			"gradable": true
		})

	var percentage := float(correct) / float(total) * 100.0 if total > 0 else 0.0
	return {
		"gradable": total > 0,
		"needs_review": false,
		"earned_points": max_points * percentage / 100.0,
		"max_points": max_points,
		"percentage": percentage,
		"correct_testcases": correct,
		"total_testcases": total,
		"criteria": criteria,
		"expected": "Testcase đúng: %d/%d" % [correct, total]
	}

static func _split_cases(output: String) -> Array[String]:
	var cases: Array[String] = []
	var normalized_output := output.replace("\r", "")
	var search_from := 0
	while true:
		var marker_position := normalized_output.find(CASE_END, search_from)
		if marker_position < 0:
			break
		var value := normalized_output.substr(search_from, marker_position - search_from).strip_edges()
		cases.append(value)
		search_from = marker_position + CASE_END.length()
	return cases

static func _normalize(value: String) -> String:
	var text := value.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text
