extends SceneTree

const MathQuestions := preload("res://scripts/systems/math_questions.gd")

func _initialize() -> void:
	var files := DirAccess.get_files_at("res://quiz_exam_bank/questions")
	var leftovers := 0
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var file := FileAccess.open("res://quiz_exam_bank/questions/" + file_name, FileAccess.READ)
		var parser := JSON.new()
		if parser.parse(file.get_as_text()) != OK:
			push_error("Cannot parse " + file_name)
			quit(1)
			return
		for item in parser.data.get("questions", []):
			var source := str(item.get("question_latex", ""))
			var rendered := MathQuestions.latex_to_readable_text(source)
			var listing_start := source.find("\\begin{lstlisting}")
			var listing_end := source.find("\\end{lstlisting}")
			if listing_start >= 0 and listing_end > listing_start:
				var raw_listing := source.substr(listing_start + "\\begin{lstlisting}".length(), listing_end - listing_start - "\\begin{lstlisting}".length()).strip_edges()
				rendered = rendered.replace(raw_listing, "")
			var regex := RegEx.new()
			regex.compile("\\\\[A-Za-z]+|\\\\[{}%#$&]")
			var matches := regex.search_all(rendered)
			for match in matches:
				print("%s %s: %s" % [file_name, item.get("id"), match.get_string()])
				leftovers += 1
	if leftovers > 0:
		push_error("%d raw LaTeX commands remain in rendered questions." % leftovers)
		quit(1)
		return
	print("All exam questions render without raw LaTeX commands.")
	quit()
