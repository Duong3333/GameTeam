extends RefCounted
# Luu workspace IDE rieng theo tung cau hoi, khong thay doi ket qua thi chinh thuc.

const SAVE_PATH := "user://cpp_ide_workspace.cfg"

static func load_workspace(question_id: String) -> Dictionary:
	if question_id.is_empty():
		return {}
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {}
	var section := _section_name(question_id)
	return {
		"source": str(config.get_value(section, "source", "")),
		"input": str(config.get_value(section, "input", ""))
	}

static func save_workspace(question_id: String, source: String, input_text: String) -> bool:
	if question_id.is_empty():
		return false
	var config := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		var load_error := config.load(SAVE_PATH)
		if load_error != OK:
			return false
	var section := _section_name(question_id)
	config.set_value(section, "source", source)
	config.set_value(section, "input", input_text)
	config.set_value(section, "saved_at", Time.get_datetime_string_from_system())
	return config.save(SAVE_PATH) == OK

static func _section_name(question_id: String) -> String:
	return "question_" + question_id.validate_filename()
