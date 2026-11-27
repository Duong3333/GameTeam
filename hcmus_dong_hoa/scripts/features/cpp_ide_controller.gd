extends Node
## Lop dieu phoi IDE. Giao dien va bai thi khong phu thuoc truc tiep vao GCC hay HTTP.

signal run_completed(result: Dictionary)

const LocalGccProvider := preload("res://scripts/features/cpp_local_gcc_provider.gd")
const RemoteJudgeProvider := preload("res://scripts/features/cpp_remote_judge_provider.gd")

@export_enum("Local GCC", "Remote Judge") var backend_mode: int = 0
@export var remote_endpoint: String = ""
var remote_access_token: String = ""

var _provider: Node

func _ready() -> void:
	_rebuild_provider()

func is_running() -> bool:
	return _provider != null and bool(_provider.call("is_running"))

func run_code(source_code: String, input_text: String, context: Dictionary = {}) -> bool:
	if _provider == null:
		_rebuild_provider()
	if _provider == null:
		run_completed.emit({
			"success": false,
			"stage": "provider",
			"message": "IDE chưa khởi tạo được bộ thực thi."
		})
		return false
	return bool(_provider.call("run_code", source_code, input_text, context))

func set_backend_mode(mode: int) -> bool:
	if is_running():
		return false
	backend_mode = clampi(mode, 0, 1)
	_rebuild_provider()
	return _provider != null

func set_remote_endpoint(url: String) -> bool:
	if is_running():
		return false
	remote_endpoint = url.strip_edges()
	if backend_mode == 1:
		_rebuild_provider()
	return true

func set_remote_access_token(token: String) -> bool:
	if is_running():
		return false
	remote_access_token = token.strip_edges()
	if backend_mode == 1:
		_rebuild_provider()
	return true

func get_backend_name() -> String:
	if backend_mode == 1:
		return "Remote Judge"
	return "Local GCC C++17"

func is_backend_available() -> bool:
	if _provider == null:
		return false
	return bool(_provider.call("is_available"))

func _rebuild_provider() -> void:
	if _provider != null:
		if _provider.has_signal("execution_completed"):
			_provider.disconnect("execution_completed", _on_execution_completed)
		_provider.queue_free()
		_provider = null

	if backend_mode == 1:
		_provider = RemoteJudgeProvider.new()
		_provider.set("endpoint_url", remote_endpoint)
		_provider.set("access_token", remote_access_token)
	else:
		_provider = LocalGccProvider.new()

	add_child(_provider)
	_provider.connect("execution_completed", _on_execution_completed)

func _on_execution_completed(result: Dictionary) -> void:
	run_completed.emit(result)
