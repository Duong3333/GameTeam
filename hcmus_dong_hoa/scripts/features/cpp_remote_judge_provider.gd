extends "res://scripts/features/cpp_execution_provider.gd"
## Khung provider online qua HTTPS.
## Chua duoc chon mac dinh; can co dich vu judge tu xa dung API duoc mo ta trong tai lieu.

@export var endpoint_url: String = ""
@export var request_timeout_seconds: float = 30.0
var access_token: String = ""

var _http: HTTPRequest
var _is_running := false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = request_timeout_seconds
	_http.use_threads = true
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)

func is_running() -> bool:
	return _is_running

func is_available() -> bool:
	return endpoint_url.begins_with("https://") and _http != null

func run_code(source_code: String, input_text: String, context: Dictionary = {}) -> bool:
	if _is_running:
		return false
	if not is_available():
		execution_completed.emit({
			"success": false,
			"stage": "remote_config",
			"message": "Chưa cấu hình HTTPS endpoint cho dịch vụ chấm bài online."
		})
		return false
	if source_code.length() > 30000:
		execution_completed.emit({
			"success": false,
			"stage": "validation",
			"message": "Code quá dài. Giới hạn hiện tại là 30.000 ký tự."
		})
		return false
	if input_text.length() > 100000:
		execution_completed.emit({
			"success": false,
			"stage": "validation",
			"message": "Input quá dài. Giới hạn hiện tại là 100.000 ký tự."
		})
		return false

	var action := str(context.get("action", "run"))
	var remote_source := str(context.get("remote_source", source_code))
	var payload := {
		"task_id": str(context.get("question_id", "")),
		"language": "cpp",
		"standard": "c++17",
		"action": action,
		"source_code": remote_source,
		"stdin": input_text if action == "run" else ""
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
	if not access_token.is_empty():
		headers.append("Authorization: Bearer " + access_token)
	var error := _http.request(
		endpoint_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if error != OK:
		execution_completed.emit({
			"success": false,
			"stage": "network",
			"message": "Không thể gửi yêu cầu tới dịch vụ IDE online (mã lỗi %d)." % error
		})
		return false
	_is_running = true
	return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_running = false
	if result != HTTPRequest.RESULT_SUCCESS:
		execution_completed.emit({
			"success": false,
			"stage": "network",
			"message": "Kết nối tới dịch vụ chấm bài bị gián đoạn (mã %d)." % result
		})
		return
	if response_code < 200 or response_code >= 300:
		execution_completed.emit({
			"success": false,
			"stage": "http",
			"message": "Dịch vụ chấm bài trả về HTTP %d." % response_code,
			"details": body.get_string_from_utf8().substr(0, 2000)
		})
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		execution_completed.emit({
			"success": false,
			"stage": "protocol",
			"message": "Phản hồi từ dịch vụ chấm bài không đúng định dạng JSON object."
		})
		return

	var response: Dictionary = parsed
	var normalized := {
		"success": bool(response.get("success", false)),
		"stage": str(response.get("stage", "remote")),
		"message": str(response.get("message", "Dịch vụ chấm bài đã phản hồi.")),
		"output": str(response.get("stdout", response.get("output", ""))),
		"details": str(response.get("stderr", response.get("details", ""))),
		"exit_code": int(response.get("exit_code", 0)),
		"remote": true
	}
	if response.has("grade") and typeof(response["grade"]) == TYPE_DICTIONARY:
		normalized["grade"] = response["grade"]
	if response.has("test_results"):
		normalized["test_results"] = response["test_results"]
	execution_completed.emit(normalized)
