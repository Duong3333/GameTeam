extends RefCounted

const EXAM_PATHS := {
	"CSLT": [
		"res://quiz_exam_bank/questions/exam_001.json",
		"res://quiz_exam_bank/questions/exam_002.json",
		"res://quiz_exam_bank/questions/exam_003.json",
		"res://quiz_exam_bank/questions/exam_004.json",
		"res://quiz_exam_bank/questions/exam_005.json",
	],
	"VTP1": [
		"res://quiz_exam_bank/questions/exam_006.json",
		"res://quiz_exam_bank/questions/exam_007.json",
		"res://quiz_exam_bank/questions/exam_008.json",
		"res://quiz_exam_bank/questions/exam_009.json",
		"res://quiz_exam_bank/questions/exam_010.json",
	],
}

static func load_random_exam(subject_code: String, exam_type: String) -> Dictionary:
	if exam_type != "midterm":
		push_error("Unsupported exam type: %s" % exam_type)
		return {}
	if not EXAM_PATHS.has(subject_code):
		push_error("Unknown exam subject: %s" % subject_code)
		return {}

	var exams: Array = []
	for path in EXAM_PATHS[subject_code]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Cannot open exam bank file %s: %s" % [path, error_string(FileAccess.get_open_error())])
			continue

		var parser := JSON.new()
		var parse_error := parser.parse(file.get_as_text())
		if parse_error != OK:
			push_error("Cannot parse exam bank file %s at line %d: %s" % [path, parser.get_error_line(), parser.get_error_message()])
			continue
		if typeof(parser.data) != TYPE_DICTIONARY:
			push_error("Exam bank file must contain a JSON object: %s" % path)
			continue

		var exam: Dictionary = parser.data
		if str(exam.get("subject_code", "")) != subject_code or str(exam.get("exam_type", "")) != exam_type:
			push_error("Exam metadata does not match the requested group: %s" % path)
			continue
		if typeof(exam.get("questions")) != TYPE_ARRAY or exam.questions.is_empty():
			push_error("Exam has no question list: %s" % path)
			continue
		exams.append(exam)

	if exams.is_empty():
		push_error("No usable %s exams found for %s." % [exam_type, subject_code])
		return {}
	return exams[randi_range(0, exams.size() - 1)]

static func grade_answer(question: Dictionary, response: String) -> Dictionary:
	var expected: String = str(question.get("official_answer", ""))
	var accepted: Array = question.get("accepted_answers", [])
	if not bool(question.get("verified", false)) or str(question.get("answer_status", "")) not in ["official", "verified_ai"]:
		return {"gradable": false, "correct": false, "expected": expected}
	if str(question.get("grading_method", "manual")) != "exact" or accepted.is_empty():
		return {"gradable": false, "correct": false, "expected": expected}

	var correct := false
	var answer_type := str(question.get("answer_type", ""))
	match answer_type:
		"integer":
			var actual_integer := response.strip_edges()
			if actual_integer.is_valid_int():
				for answer in accepted:
					var candidate_integer := str(answer).strip_edges()
					if candidate_integer.is_valid_int() and int(candidate_integer) == int(actual_integer):
						correct = true
						break
		"decimal":
			var actual_decimal := response.strip_edges()
			var tolerance := float(question.get("tolerance", 0.0))
			for answer in accepted:
				var candidate_decimal := str(answer).strip_edges()
				if actual_decimal.is_valid_float() and candidate_decimal.is_valid_float():
					if absf(float(actual_decimal) - float(candidate_decimal)) <= tolerance:
						correct = true
						break
				elif _normalize_spaces(actual_decimal) == _normalize_spaces(candidate_decimal):
					correct = true
					break
		"code_output":
			var actual_output := _normalize_output(response)
			for answer in accepted:
				if actual_output == _normalize_output(str(answer)):
					correct = true
					break
		"text", "expression":
			var actual_text := _normalize_spaces(response)
			for answer in accepted:
				if actual_text == _normalize_spaces(str(answer)):
					correct = true
					break
		_:
			return {"gradable": false, "correct": false, "expected": expected}

	return {"gradable": true, "correct": correct, "expected": expected}

static func latex_to_readable_text(source: String) -> String:
	var output := ""
	var index := 0
	while index < source.length():
		var character := source.substr(index, 1)
		if character == "$":
			index += 1
			continue
		if character == "\\":
			if source.substr(index, 2) == "\\\\":
				output += "\n"
				index += 2
				continue
			var command_start := index + 1
			var command_end := command_start
			while command_end < source.length() and source.substr(command_end, 1).is_valid_identifier():
				command_end += 1
			if command_end == command_start:
				output += _latex_symbol(source.substr(command_start, 1))
				index = mini(command_start + 1, source.length())
				continue
			var command := source.substr(command_start, command_end - command_start)
			index = command_end
			if command in ["begin", "end"]:
				var environment := _read_latex_group(source, index)
				if not environment.is_empty():
					index = int(environment["end"])
					if command == "begin" and str(environment["text"]) == "lstlisting":
						var listing_end := source.find("\\end{lstlisting}", index)
						if listing_end >= 0:
							output += "\n" + source.substr(index, listing_end - index).strip_edges() + "\n"
							index = listing_end + "\\end{lstlisting}".length()
						else:
							output += "\n"
					elif str(environment["text"]) == "cases":
						output += "\n"
				continue
			if command in ["frac", "dfrac", "tfrac"]:
				var numerator := _read_latex_group(source, index)
				if not numerator.is_empty():
					var denominator := _read_latex_group(source, int(numerator["end"]))
					if not denominator.is_empty():
						output += "(%s)/(%s)" % [
							latex_to_readable_text(str(numerator["text"])),
							latex_to_readable_text(str(denominator["text"]))
						]
						index = int(denominator["end"])
						continue
			if command == "sqrt":
				var root := _read_latex_group(source, index)
				if not root.is_empty():
					output += "√(%s)" % latex_to_readable_text(str(root["text"]))
					index = int(root["end"])
					continue
			if command in ["points", "texttt", "text", "mathrm", "mathbf", "mathit", "operatorname", "boxed"]:
				var argument := _read_latex_group(source, index)
				if not argument.is_empty():
					var argument_text := latex_to_readable_text(str(argument["text"]))
					output += "(%s điểm)" % argument_text if command == "points" else argument_text
					index = int(argument["end"])
					continue
			if command == "item":
				output += "\n• "
			elif command in ["left", "right", "displaystyle", "limits", "quad", "qquad"]:
				if command in ["quad", "qquad"]:
					output += " "
			elif command == "lim":
				output += "lim"
			else:
				output += _latex_command_text(command)
			continue
		if character in ["^", "_"]:
			var script := _read_latex_group(source, index + 1)
			var script_text := ""
			if not script.is_empty():
				script_text = latex_to_readable_text(str(script["text"]))
				index = int(script["end"])
			elif index + 1 < source.length():
				script_text = source.substr(index + 1, 1)
				index += 2
			else:
				index += 1
			output += _unicode_script(script_text, character == "^")
			continue
		if character == "{" or character == "}":
			index += 1
			continue
		if character == "&":
			output += " "
			index += 1
			continue
		output += " " if character == "~" else character
		index += 1
	return output.strip_edges()

static func _read_latex_group(source: String, start: int) -> Dictionary:
	if start >= source.length() or source.substr(start, 1) != "{":
		return {}
	var depth := 1
	var index := start + 1
	while index < source.length():
		var character := source.substr(index, 1)
		if character == "{":
			depth += 1
		elif character == "}":
			depth -= 1
			if depth == 0:
				return {"text": source.substr(start + 1, index - start - 1), "end": index + 1}
		index += 1
	return {"text": source.substr(start + 1), "end": source.length()}

static func _latex_command_text(command: String) -> String:
	var symbols := {
		"alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
		"epsilon": "ε", "theta": "θ", "lambda": "λ", "mu": "μ",
		"pi": "π", "sigma": "σ", "omega": "ω", "infty": "∞",
		"times": "×", "cdot": "·", "le": "≤", "leq": "≤",
		"ge": "≥", "geq": "≥", "ne": "≠", "neq": "≠",
		"to": "→", "rightarrow": "→", "Rightarrow": "⇒",
		"pm": "±", "mp": "∓", "approx": "≈", "equiv": "≡",
		"partial": "∂", "nabla": "∇", "sum": "∑", "int": "∫",
		"ell": "ℓ", "ldots": "…", "cdots": "⋯",
		" ": " ", "%": "%", "&": "&", "{": "{", "}": "}",
		"_": "_", "#": "#", "$": "$", "\\": "\\"
	}
	return str(symbols.get(command, command))

static func _latex_symbol(symbol: String) -> String:
	match symbol:
		"[", "]":
			return "\n"
		",", ";", ":", "!":
			return " "
		"%", "&", "{", "}", "_", "#", "$", "\\":
			return symbol
		_:
			return symbol

static func _unicode_script(value: String, superscript: bool) -> String:
	var subscripts := {
		"0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
		"5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
		"+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎",
		"a": "ₐ", "e": "ₑ", "i": "ᵢ", "j": "ⱼ", "o": "ₒ",
		"r": "ᵣ", "u": "ᵤ", "v": "ᵥ", "x": "ₓ"
	}
	var superscripts := {
		"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
		"5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
		"+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
		"a": "ᵃ", "b": "ᵇ", "c": "ᶜ", "d": "ᵈ", "e": "ᵉ",
		"f": "ᶠ", "g": "ᵍ", "h": "ʰ", "i": "ⁱ", "j": "ʲ",
		"k": "ᵏ", "l": "ˡ", "m": "ᵐ", "n": "ⁿ", "o": "ᵒ",
		"p": "ᵖ", "r": "ʳ", "s": "ˢ", "t": "ᵗ", "u": "ᵘ",
		"v": "ᵛ", "w": "ʷ", "x": "ˣ", "y": "ʸ", "z": "ᶻ"
	}
	var mapping: Dictionary = superscripts if superscript else subscripts
	var converted := ""
	for index in value.length():
		var character := value.substr(index, 1)
		if mapping.has(character):
			converted += str(mapping[character])
		elif character in ["→", "≤", "≥", "≠"]:
			converted += character
		else:
			return ("^(%s)" if superscript else "_(%s)") % value
	return converted

static func _normalize_spaces(value: String) -> String:
	var expression := RegEx.new()
	expression.compile("\\s+")
	return expression.sub(value.strip_edges(), " ", true)

static func _normalize_output(value: String) -> String:
	var normalized := value.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	var lines := normalized.split("\n", true)
	for index in lines.size():
		lines[index] = _normalize_spaces(lines[index])
	return "\n".join(lines)
