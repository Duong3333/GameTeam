extends "res://scripts/features/cpp_execution_provider.gd"
# Provider thuc thi C++17 cuc bo bang GCC dong goi cung game Windows.
# Gioi han thoi gian khong thay the sandbox cach ly ma.

const MAX_SOURCE_LENGTH := 30000
const MAX_INPUT_LENGTH := 100000
const RUN_TIMEOUT_SECONDS := 5
const COMPILE_TIMEOUT_SECONDS := 15

var _thread: Thread
var _is_running := false
var _next_job_id := 0

func is_running() -> bool:
	return _is_running

func is_available() -> bool:
	if OS.get_name() != "Windows":
		return false
	for candidate in _get_compiler_candidates():
		if FileAccess.file_exists(candidate):
			return true
	return false

func run_code(source_code: String, input_text: String, _context: Dictionary = {}) -> bool:
	if _is_running:
		return false
	if source_code.strip_edges().is_empty():
		execution_completed.emit({"success": false, "message": "Chưa có code để chạy."})
		return false
	if source_code.length() > MAX_SOURCE_LENGTH:
		execution_completed.emit({"success": false, "message": "Code quá dài. Giới hạn hiện tại là 30.000 ký tự."})
		return false
	if input_text.length() > MAX_INPUT_LENGTH:
		execution_completed.emit({"success": false, "message": "Input quá dài. Giới hạn hiện tại là 100.000 ký tự."})
		return false

	_next_job_id += 1
	var folder := "user://cpp_runner/job_%d_%d" % [Time.get_ticks_usec(), _next_job_id]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK:
		execution_completed.emit({"success": false, "message": "Không tạo được thư mục tạm để chạy code."})
		return false

	var paths := {
		"source": ProjectSettings.globalize_path(folder + "/submission.cpp"),
		"input": ProjectSettings.globalize_path(folder + "/input.txt"),
		"executable": ProjectSettings.globalize_path(folder + ("/submission.exe" if OS.get_name() == "Windows" else "/submission")),
		"stdout": ProjectSettings.globalize_path(folder + "/stdout.txt"),
		"stderr": ProjectSettings.globalize_path(folder + "/stderr.txt"),
		"compile_stdout": ProjectSettings.globalize_path(folder + "/compile_stdout.txt"),
		"compile_stderr": ProjectSettings.globalize_path(folder + "/compile_stderr.txt"),
		"folder": ProjectSettings.globalize_path(folder),
		"compiler_candidates": _get_compiler_candidates()
	}
	if not _write_text(str(paths["source"]), source_code) or not _write_text(str(paths["input"]), input_text):
		_cleanup_job(paths)
		execution_completed.emit({"success": false, "message": "Không ghi được file tạm cho chương trình."})
		return false

	_thread = Thread.new()
	var start_error := _thread.start(_run_job.bind(paths))
	if start_error != OK:
		_thread = null
		_cleanup_job(paths)
		execution_completed.emit({"success": false, "message": "Không khởi động được tiến trình biên dịch."})
		return false
	_is_running = true
	return true

func _process(_delta: float) -> void:
	if not _is_running or _thread == null:
		return
	if _thread.is_alive():
		return

	var result: Dictionary = _thread.wait_to_finish()
	_thread = null
	_is_running = false
	execution_completed.emit(result)

func _exit_tree() -> void:
	# Thu gom thread neu nguoi choi dong game giua luc dang chay bai.
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	_is_running = false

func _run_job(paths: Dictionary) -> Dictionary:
	if OS.get_name() != "Windows":
		_cleanup_job(paths)
		return {
			"success": false,
			"stage": "platform",
			"message": "Bản IDE offline hiện được cấu hình cho Windows."
		}
	var compiler := _find_compiler(paths)
	if compiler.is_empty():
		_cleanup_job(paths)
		return {
			"success": false,
			"stage": "compiler",
			"message": "Không tìm thấy GCC đi kèm game. Hãy kiểm tra scripts/features/tools/gcc/bin/g++.exe trong bản phát hành."
		}

	var compile_result := _compile_program(paths, compiler)
	var compile_exit := int(compile_result.get("exit_code", -1))
	var compile_text := str(compile_result.get("details", ""))
	var compile_timed_out := bool(compile_result.get("timed_out", false))
	if compile_exit != 0 or compile_timed_out:
		_cleanup_job(paths)
		return {
			"success": false,
			"stage": "compile",
			"message": "Biên dịch quá %d giây và đã bị dừng." % COMPILE_TIMEOUT_SECONDS if compile_timed_out else "Biên dịch thất bại (mã %d)." % compile_exit,
			"details": compile_text,
			"compiler": compiler
		}

	var execution := _execute_program(paths)
	var stdout_text := _read_text(str(paths["stdout"]))
	var stderr_text := _read_text(str(paths["stderr"]))
	var exit_code := int(execution.get("exit_code", -1))
	var timed_out := bool(execution.get("timed_out", false))
	var success := exit_code == 0 and not timed_out
	_cleanup_job(paths)
	return {
		"success": success,
		"stage": "run",
		"message": "Chạy thành công." if success else ("Chương trình chạy quá %d giây và đã bị dừng." % RUN_TIMEOUT_SECONDS if timed_out else "Chương trình kết thúc với mã lỗi %d." % exit_code),
		"output": stdout_text,
		"details": stderr_text,
		"exit_code": exit_code,
		"timed_out": timed_out,
		"compiler": compiler
	}

func _compile_program(paths: Dictionary, compiler: String) -> Dictionary:
	return _compile_windows(paths, compiler)

func _compile_windows(paths: Dictionary, compiler: String) -> Dictionary:
	var script_path := str(paths["folder"]) + "/compile_submission.ps1"
	var script := """
param([string]$Compiler, [string]$SourcePath, [string]$ExecutablePath, [string]$OutputPath, [string]$ErrorPath)
$ErrorActionPreference = 'Stop'
$process = New-Object System.Diagnostics.Process
$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $Compiler
$info.Arguments = '-std=c++17 -O0 -pipe -static-libgcc -static-libstdc++ "' + $SourcePath + '" -o "' + $ExecutablePath + '"'
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$process.StartInfo = $info
[void]$process.Start()
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(15000)) {
    try { $process.Kill() } catch {}
    $process.WaitForExit()
    [System.IO.File]::WriteAllText($OutputPath, $stdoutTask.Result)
    [System.IO.File]::WriteAllText($ErrorPath, $stderrTask.Result)
    exit 124
}
$process.WaitForExit()
[System.IO.File]::WriteAllText($OutputPath, $stdoutTask.Result)
[System.IO.File]::WriteAllText($ErrorPath, $stderrTask.Result)
exit $process.ExitCode
"""
	if not _write_text(script_path, script):
		return {"exit_code": -1, "timed_out": false, "details": "Không tạo được script biên dịch."}
	var process_output: Array = []
	var exit_code := OS.execute("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", script_path,
		compiler,
		str(paths["source"]),
		str(paths["executable"]),
		str(paths["compile_stdout"]),
		str(paths["compile_stderr"])
	]), process_output, true, false)
	var details := _read_text(str(paths["compile_stdout"])) + _read_text(str(paths["compile_stderr"]))
	return {"exit_code": exit_code, "timed_out": exit_code == 124, "details": details.strip_edges()}

func _get_compiler_candidates() -> Array[String]:
	var game_dir := OS.get_executable_path().get_base_dir()
	return [
		game_dir.path_join("scripts/features/tools/gcc/bin/g++.exe"),
		game_dir.path_join("scripts/features/tools/mingw64/bin/g++.exe"),
		game_dir.path_join("tools/gcc/bin/g++.exe"),
		game_dir.path_join("tools/mingw64/bin/g++.exe"),
		ProjectSettings.globalize_path("res://scripts/features/tools/gcc/bin/g++.exe"),
		ProjectSettings.globalize_path("res://scripts/features/tools/mingw64/bin/g++.exe"),
		ProjectSettings.globalize_path("res://tools/gcc/bin/g++.exe"),
		ProjectSettings.globalize_path("res://tools/mingw64/bin/g++.exe")
	]

func _find_compiler(paths: Dictionary) -> String:
	if OS.get_name() != "Windows":
		return ""
	for candidate_value in paths.get("compiler_candidates", []):
		var candidate := str(candidate_value)
		if not FileAccess.file_exists(candidate):
			continue
		var version_output: Array = []
		var exit_code := OS.execute(candidate, PackedStringArray(["--version"]), version_output, true, true)
		if exit_code == 0:
			return candidate
	return ""

func _execute_program(paths: Dictionary) -> Dictionary:
	return _execute_windows(paths)

func _execute_windows(paths: Dictionary) -> Dictionary:
	var script_path := str(paths["folder"]) + "/run_submission.ps1"
	var script := """
param([string]$Executable, [string]$InputPath, [string]$OutputPath, [string]$ErrorPath)
$ErrorActionPreference = 'Stop'
$process = New-Object System.Diagnostics.Process
$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $Executable
$info.WorkingDirectory = Split-Path -Parent $Executable
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardInput = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$process.StartInfo = $info
[void]$process.Start()
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
$inputText = [System.IO.File]::ReadAllText($InputPath)
$process.StandardInput.Write($inputText)
$process.StandardInput.Close()
if (-not $process.WaitForExit(5000)) {
    try { $process.Kill() } catch {}
    $process.WaitForExit()
    [System.IO.File]::WriteAllText($OutputPath, $stdoutTask.Result)
    [System.IO.File]::WriteAllText($ErrorPath, $stderrTask.Result)
    exit 124
}
$process.WaitForExit()
[System.IO.File]::WriteAllText($OutputPath, $stdoutTask.Result)
[System.IO.File]::WriteAllText($ErrorPath, $stderrTask.Result)
exit $process.ExitCode
"""
	if not _write_text(script_path, script):
		return {"exit_code": -1, "timed_out": false}
	var process_output: Array = []
	var exit_code := OS.execute("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", script_path,
		str(paths["executable"]),
		str(paths["input"]),
		str(paths["stdout"]),
		str(paths["stderr"])
	]), process_output, true, false)
	return {"exit_code": exit_code, "timed_out": exit_code == 124}

func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content


func _cleanup_job(paths: Dictionary) -> void:
	var folder := str(paths.get("folder", ""))
	var job_root := ProjectSettings.globalize_path("user://cpp_runner/")
	if folder.is_empty() or not folder.begins_with(job_root):
		return
	_remove_job_directory_contents(folder)
	DirAccess.remove_absolute(folder)

func _remove_job_directory_contents(folder: String) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path := folder.path_join(entry)
			if dir.current_is_dir():
				_remove_job_directory_contents(entry_path)
				DirAccess.remove_absolute(entry_path)
			else:
				DirAccess.remove_absolute(entry_path)
		entry = dir.get_next()
	dir.list_dir_end()
