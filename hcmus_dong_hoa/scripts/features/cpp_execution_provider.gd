extends Node
## Lop co so cho cac bo thuc thi C++.
## Controller chi giao tiep voi provider qua signal va cac ham ben duoi.

signal execution_completed(result: Dictionary)

func is_running() -> bool:
	return false

func is_available() -> bool:
	return false

func run_code(_source_code: String, _input_text: String, _context: Dictionary = {}) -> bool:
	return false
