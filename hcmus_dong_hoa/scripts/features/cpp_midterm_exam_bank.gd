extends RefCounted
## Ngân hàng đề giữa kỳ Cơ sở lập trình thực hành.
## Mỗi đề chọn 3 nhóm chủ đề lớn khác nhau; P1/P2/P3 trong cùng nhóm là lựa chọn loại trừ.
## Trong mỗi chủ đề được chọn, bốc tối đa 3 câu hỏi nhỏ (giảm còn 1-2 câu nếu câu nặng/dài),
## ghép thành một câu lớn có tối đa 10 testcase và 1 hàm main() kiểm thử tự động.

const BANK_PATH := "res://scripts/features/cpp_midterm_question_bank.json"
const CSLT_MIDTERM_DURATION_SECONDS := 90 * 60
const HEAVY_TOPIC_GROUP_IDS := ["ARRAY", "STRUCT_FILE"]
const MAX_SUBQUESTIONS_PER_TOPIC := 3
const MAX_TESTCASES_PER_QUESTION := 10
const MAX_ESTIMATED_LINES_PER_TOPIC := 65

static var _cached_bank: Dictionary = {}
static var _generated_questions: Dictionary = {}
static var _composite_counter: int = 0

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
	if _generated_questions.has(question_id):
		return (_generated_questions[question_id] as Dictionary).duplicate(true)
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

static func get_required_functions(question_id: String) -> Array:
	var question := _question_by_id(question_id)
	var funcs: Variant = question.get("required_functions", [])
	return funcs.duplicate() if typeof(funcs) == TYPE_ARRAY else []

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

static func _pick_subquestions(candidates: Array, group_id: String, rng: RandomNumberGenerator) -> Array:
	if candidates.is_empty():
		return []
	var pool := candidates.duplicate()
	pool.shuffle()

	# Với Array hoặc Struct & File (mỗi câu đã gồm 4-6 hàm, ~65-85 dòng code), chỉ bốc 1 câu.
	if group_id in HEAVY_TOPIC_GROUP_IDS:
		return [pool[0]]

	var picked: Array = []
	var total_lines := 0
	var total_funcs := 0
	for item in pool:
		if picked.size() >= MAX_SUBQUESTIONS_PER_TOPIC:
			break
		var q: Dictionary = item
		var est_lines := int(q.get("estimated_student_code_lines", 20))
		if est_lines <= 0:
			est_lines = 20
		var complexity := str(q.get("complexity", "medium"))
		var func_count: int = q.get("required_functions", []).size()

		if picked.is_empty():
			picked.append(q)
			total_lines += est_lines
			total_funcs += func_count
			# Nếu câu đầu tiên đã quá nặng (vd: linear_regression, spiral), dừng ở 1-2 câu.
			if complexity == "very_hard" or est_lines >= 50:
				break
			continue

		if total_lines + est_lines > MAX_ESTIMATED_LINES_PER_TOPIC:
			continue
		if total_funcs + func_count > 5:
			continue
		picked.append(q)
		total_lines += est_lines
		total_funcs += func_count

	return picked

static func _merge_preludes(subquestions: Array) -> String:
	var seen := {}
	var include_lines: Array[String] = []
	var other_lines: Array[String] = []
	var has_using_std := false
	var required_includes := ["#include <iostream>", "#include <sstream>", "#include <string>"]

	for req in required_includes:
		seen[req] = true
		include_lines.append(req)

	for q_val in subquestions:
		var q: Dictionary = q_val
		var prelude := str(q.get("prelude", ""))
		for raw_line in prelude.split("\n"):
			var line := raw_line.strip_edges()
			if line.is_empty():
				continue
			if line == "using namespace std;":
				has_using_std = true
				continue
			if seen.has(line):
				continue
			seen[line] = true
			if line.begins_with("#include"):
				include_lines.append(line)
			else:
				other_lines.append(line)

	var result := "\n".join(include_lines)
	if has_using_std or true:
		result += "\nusing namespace std;"
	if not other_lines.is_empty():
		result += "\n" + "\n".join(other_lines)
	return result + "\n"

static func _select_balanced_case_indices(case_counts: Array[int], max_cases: int) -> Array[int]:
	var total := 0
	for c in case_counts:
		total += c
	var selected: Array[int] = []
	if total <= max_cases:
		for i in range(total):
			selected.append(i)
		return selected

	# Phân bổ đều tối đa max_cases chỉ số qua các câu hỏi nhỏ.
	var n_subs := case_counts.size()
	var quotas: Array[int] = []
	var offsets: Array[int] = []
	var running := 0
	for i in range(n_subs):
		offsets.append(running)
		running += case_counts[i]
		quotas.append(0)

	var remaining := max_cases
	while remaining > 0:
		var progressed := false
		for i in range(n_subs):
			if remaining <= 0:
				break
			if quotas[i] < case_counts[i]:
				quotas[i] += 1
				remaining -= 1
				progressed = true
		if not progressed:
			break

	for i in range(n_subs):
		var c := case_counts[i]
		var q := quotas[i]
		var off := offsets[i]
		if q <= 0:
			continue
		if q >= c:
			for j in range(c):
				selected.append(off + j)
		elif q == 1:
			selected.append(off)
		else:
			for k in range(q):
				var idx := int(round(float(k) * float(c - 1) / float(q - 1)))
				var g_idx := off + idx
				if not (g_idx in selected):
					selected.append(g_idx)
				else:
					# Tìm vị trí lân cận chưa chọn nếu bị trùng do làm tròn
					for alt in range(c):
						if not ((off + alt) in selected):
							selected.append(off + alt)
							break
	selected.sort()
	return selected

static func _build_composite_harness(subquestions: Array) -> Dictionary:
	var main_regex := RegEx.new()
	main_regex.compile("\\bint\\s+main\\s*\\([^)]*\\)")

	var sub_funcs_code := ""
	var sub_calls: Array[String] = []
	var combined_input_parts: Array[String] = []
	var all_expected: Array[String] = []
	var case_counts: Array[int] = []

	for i in range(subquestions.size()):
		var q: Dictionary = subquestions[i]
		var raw_harness := str(q.get("harness", ""))
		var fn_name := "__sub_test_%d" % i
		var replaced := main_regex.sub(raw_harness, "static void %s()" % fn_name)
		sub_funcs_code += replaced + "\n\n"
		sub_calls.append("std::cout.flags(std::ios::fmtflags(0)); std::cout.precision(6); %s();" % fn_name)

		var sub_input := str(q.get("input", "")).strip_edges()
		if not sub_input.is_empty():
			combined_input_parts.append(sub_input)

		var cases: Array = q.get("expected_cases", [])
		case_counts.append(cases.size())
		for c in cases:
			all_expected.append(str(c))

	var selected_indices := _select_balanced_case_indices(case_counts, MAX_TESTCASES_PER_QUESTION)
	var final_expected: Array = []
	var index_literals: Array[String] = []
	for idx in selected_indices:
		if idx >= 0 and idx < all_expected.size():
			final_expected.append(all_expected[idx])
			index_literals.append(str(idx))

	var main_body := sub_funcs_code + """int main() {
	std::ostringstream __cap;
	std::streambuf* __orig_buf = std::cout.rdbuf(__cap.rdbuf());
	""" + "\n\t".join(sub_calls) + """
	std::cout.rdbuf(__orig_buf);
	std::string __raw = __cap.str();
	std::string __marker = "@@CASE_END@@";
	std::string __cases[256];
	int __count = 0;
	size_t __pos = 0;
	while (__count < 256) {
		size_t __found = __raw.find(__marker, __pos);
		if (__found == std::string::npos) break;
		__cases[__count++] = __raw.substr(__pos, __found - __pos);
		__pos = __found + __marker.length();
	}
	int __pick[] = { """ + (", ".join(index_literals) if not index_literals.is_empty() else "0") + """ };
	int __pick_count = """ + str(index_literals.size()) + """;
	for (int __i = 0; __i < __pick_count; ++__i) {
		int __idx = __pick[__i];
		if (__idx >= 0 && __idx < __count) {
			std::cout << __cases[__idx] << "\\n@@CASE_END@@\\n";
		} else {
			std::cout << "\\n@@CASE_END@@\\n";
		}
	}
	std::cout << std::flush;
	return 0;
}
"""
	return {
		"harness": main_body,
		"input": "\n".join(combined_input_parts) + ("\n" if not combined_input_parts.is_empty() else ""),
		"expected_cases": final_expected
	}

static func _extract_provided_declarations(prelude: String) -> Array[String]:
	var decls: Array[String] = []
	for raw_line in prelude.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#include") or line == "using namespace std;":
			continue
		if line.begins_with("struct ") or line.begins_with("const "):
			decls.append(line)
		elif line.contains("round_to_decimal("):
			var sig_end := line.find("{")
			var sig := (line.substr(0, sig_end).strip_edges() + ";") if sig_end >= 0 else line
			decls.append(sig)
	return decls

static func _clean_prompt_text(raw_text: String) -> String:
	var kept: Array[String] = []
	for line in raw_text.split("\n"):
		var lower := line.strip_edges().to_lower()
		if lower.begins_with("lưu ý khi nộp") or lower.begins_with("upload đúng") or lower.begins_with("không upload") or lower.begins_with("prototype và cấu trúc") or lower.begins_with("chỉ viết phần định nghĩa"):
			continue
		kept.append(line)
	return "\n".join(kept).strip_edges()

static func _build_composite_question(question_index: int, group: Dictionary, part: Dictionary, subquestions: Array, points: float) -> Dictionary:
	_composite_counter += 1
	var group_id := str(group.get("id", ""))
	var part_id := str(part.get("id", ""))
	var composite_id := "CSLT_MID_%s_%s_%d" % [group_id, part_id, _composite_counter]

	var merged_prelude := _merge_preludes(subquestions)
	var seen_funcs := {}
	var merged_funcs: Array = []
	for q_val in subquestions:
		var q: Dictionary = q_val
		for fn_val in q.get("required_functions", []):
			var fn_str := str(fn_val).strip_edges()
			if not fn_str.is_empty() and not seen_funcs.has(fn_str):
				seen_funcs[fn_str] = true
				merged_funcs.append(fn_str)

	var harness_data := _build_composite_harness(subquestions)

	var prompt_parts: Array[String] = []
	prompt_parts.append("CÂU %d — %s (%s) · %.1f ĐIỂM" % [
		question_index + 1,
		str(group.get("label", "")),
		str(part.get("label", "")),
		points
	])

	for i in range(subquestions.size()):
		var sq: Dictionary = subquestions[i]
		var sub_title := str(sq.get("title", "Bài %d" % (i + 1)))
		var sub_header := ("\n[%d.%d] %s" % [question_index + 1, i + 1, sub_title]) if subquestions.size() > 1 else ("\n" + sub_title)
		var sub_desc := _clean_prompt_text(str(sq.get("display_prompt", sq.get("description", ""))))
		var block := sub_header + "\n" + sub_desc
		if group_id == "STRUCT_FILE":
			block += "\nĐịnh dạng CSV: `Ho va ten, MSSV, diem` (vd: `Nguyen Van A, 123456, 8.0`). Ghi điểm 1 chữ số thập phân (riêng average_score ghi 2 chữ số, nếu rỗng ghi `0.00`). Danh sách rỗng ghi file rỗng."
		var provided := _extract_provided_declarations(str(sq.get("prelude", "")))
		if not provided.is_empty():
			block += "\nHệ thống cung cấp sẵn (không khai báo lại):"
			for d in provided:
				block += "\n  " + d
		var sq_funcs: Array = sq.get("required_functions", [])
		if not sq_funcs.is_empty():
			block += "\nPrototype:"
			for f in sq_funcs:
				block += "\n  " + str(f).strip_edges() + ";"
		prompt_parts.append(block)

	prompt_parts.append("\nChỉ viết định nghĩa các hàm trên trong IDE (dùng nút 'Chèn Prototype' để tạo khung nhanh). Không viết main().")
	var question_text := "\n".join(prompt_parts)

	var composite := {
		"id": composite_id,
		"title": "%s (%s)" % [str(group.get("label", "Câu lập trình")), str(part.get("label", ""))],
		"group_id": group_id,
		"group_label": str(group.get("label", "")),
		"part_id": part_id,
		"part_label": str(part.get("label", "")),
		"points": points,
		"answer_type": "short_code",
		"type": "short_code",
		"verified": true,
		"answer_status": "verified_ai",
		"grading_method": "exact_testcases",
		"prelude": merged_prelude,
		"required_functions": merged_funcs,
		"harness": str(harness_data["harness"]),
		"input": str(harness_data["input"]),
		"expected_cases": harness_data["expected_cases"],
		"question_text": question_text,
		"subquestion_count": subquestions.size()
	}
	_generated_questions[composite_id] = composite
	return composite

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

	# Một đề có đúng 1 câu thuộc nhóm nặng (Array hoặc Struct & File) và 2 chủ đề khác (Loop/Function/Advanced Function).
	var heavy_count := 1
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

	var point_values := [3.0, 4.0, 3.0]
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
		var part_dict: Dictionary = selected_part_data.get("part", {})
		var candidate_questions: Array = selected_part_data.get("questions", [])
		var group_id := str(group.get("id", ""))
		if group_id in HEAVY_TOPIC_GROUP_IDS:
			actual_heavy_count += 1

		var subquestions := _pick_subquestions(candidate_questions, group_id, rng)
		if subquestions.is_empty():
			push_error("Không bốc được câu hỏi con cho chủ đề: " + group_id)
			return {}

		var composite := _build_composite_question(index, group, part_dict, subquestions, float(point_values[index]))
		exam_questions.append(composite)
		selected_group_ids.append(group_id)
		selected_parts.append(str(part_dict.get("id", "")))

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
