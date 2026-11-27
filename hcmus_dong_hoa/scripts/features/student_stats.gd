extends Node
# THÔNG SỐ SINH VIÊN: GPA (thang 4.0) và điểm rèn luyện (thang 100).
# File này chỉ LƯU SỐ và BÁO khi số đổi, không vẽ gì (phần vẽ nằm ở student_hud.gd).
# Nơi khác trong game đổi điểm bằng:
#   game.stats.add_drl(1, "Đi học đúng giờ")    # cộng 1 điểm rèn luyện (số âm là trừ)
#   game.stats.set_gpa(3.4)                      # đặt GPA

signal drl_changed(amount: int, reason: String)   # phát ra mỗi khi điểm rèn luyện thật sự đổi
signal money_changed(amount: int, reason: String)
signal tuition_decision_requested(stage: String, amount: int, available: int)
signal student_expelled

const GPA_MAX := 4.0
const DRL_MAX := 100
const START_MONEY := 0
const MIDTERM_TUITION_WEEK := 8
const FINAL_TUITION_WEEK := 16
const TUITION_AMOUNT := 100000

var gpa := 3.0   # GPA lúc bắt đầu
var drl := 70    # điểm rèn luyện lúc bắt đầu
var wallet: Node = null          # ví dùng chung (canteen.gd); chưa gắn thì dùng ví tạm bên dưới
var _local_money := START_MONEY
var money: int:
	get:
		return _read_balance()
	set(value):
		_apply_balance_change(value - _read_balance(), "")
var midterm_tuition_resolved := false
var midterm_tuition_paid := false
var final_tuition_resolved := false
var final_tuition_paid := false
var tuition_prompt_stage := ""
var tuition_prompt_amount := 0
var expelled := false

func add_money(amount: int, reason: String = "") -> void:
	if amount <= 0:
		push_error("Money reward must be positive.")
		return
	_apply_balance_change(amount, reason)

# ---------- Ví dùng chung với căn tin / ATM ----------
# student_hud.gd (hoặc student_tuition.gd) gọi bind_wallet() khi tìm thấy ví căn tin.
func bind_wallet(node: Node) -> void:
	if node == wallet:
		return
	if is_instance_valid(wallet) and wallet.is_connected("money_changed", _on_wallet_money_changed):
		wallet.disconnect("money_changed", _on_wallet_money_changed)
	wallet = node
	if is_instance_valid(wallet) and wallet.has_signal("money_changed"):
		wallet.connect("money_changed", _on_wallet_money_changed)

func has_wallet() -> bool:
	return is_instance_valid(wallet)

func _on_wallet_money_changed(amount: int, reason: String) -> void:
	money_changed.emit(amount, reason)   # chuyển tiếp cho các nơi đang nghe stats.money_changed

func _read_balance() -> int:
	if is_instance_valid(wallet):
		return int(wallet.get("money"))
	return _local_money

# Đổi số dư qua ví chung (ví tự phát money_changed); chưa có ví thì dùng ví tạm.
func _apply_balance_change(delta: int, reason: String) -> void:
	if delta == 0:
		return
	if is_instance_valid(wallet) and wallet.has_method("set_wallet_balance"):
		wallet.call("set_wallet_balance", _read_balance() + delta, reason)
		return
	_local_money = maxi(_local_money + delta, 0)
	money_changed.emit(delta, reason)

func check_tuition_due(week_no: int) -> void:
	if expelled or not tuition_prompt_stage.is_empty():
		return
	if week_no >= FINAL_TUITION_WEEK:
		if not midterm_tuition_resolved:
			midterm_tuition_resolved = true
		if not final_tuition_resolved:
			_open_tuition_prompt("final", final_tuition_amount())
	elif week_no >= MIDTERM_TUITION_WEEK and not midterm_tuition_resolved:
		_open_tuition_prompt("midterm", TUITION_AMOUNT)

func request_tuition_prompt(week_no: int) -> bool:
	if expelled or not tuition_prompt_stage.is_empty():
		return false
	if week_no >= FINAL_TUITION_WEEK:
		if final_tuition_resolved:
			return false
		if not midterm_tuition_resolved:
			midterm_tuition_resolved = true
		_open_tuition_prompt("final", final_tuition_amount())
	elif week_no >= MIDTERM_TUITION_WEEK and not midterm_tuition_paid:
		_open_tuition_prompt("midterm", TUITION_AMOUNT)
	else:
		return false
	return true

func _open_tuition_prompt(stage: String, amount: int) -> void:
	tuition_prompt_stage = stage
	tuition_prompt_amount = amount
	tuition_decision_requested.emit(stage, amount, money)

func respond_tuition(should_pay: bool) -> bool:
	if tuition_prompt_stage.is_empty():
		return false
	if should_pay and money < tuition_prompt_amount:
		return false

	var stage := tuition_prompt_stage
	var amount := tuition_prompt_amount
	if stage == "midterm":
		midterm_tuition_resolved = true
		midterm_tuition_paid = should_pay
	else:
		final_tuition_resolved = true
		final_tuition_paid = should_pay
		expelled = not should_pay
	tuition_prompt_stage = ""
	tuition_prompt_amount = 0
	if should_pay:
		_apply_balance_change(-amount, "Học phí giữa kỳ" if stage == "midterm" else "Học phí cuối kỳ")
	if expelled:
		student_expelled.emit()
	return true

func final_tuition_amount() -> int:
	return TUITION_AMOUNT * (1 if midterm_tuition_paid else 2)

func tuition_summary(week_no: int) -> String:
	if expelled:
		return "Trạng thái: đã bị buộc thôi học do chưa đóng học phí"
	if final_tuition_paid:
		return "Học phí: đã hoàn tất"
	if not midterm_tuition_resolved:
		return "Giữa kỳ: 100k · Cuối kỳ: 100k"
	if midterm_tuition_paid:
		return "Giữa kỳ: đã đóng 100k · Cuối kỳ: 100k"
	if week_no >= FINAL_TUITION_WEEK:
		return "Cuối kỳ phải đóng 200k (đã cộng nợ giữa kỳ)"
	return "Đã dời 100k · Cuối kỳ phải đóng 200k"

func add_drl(amount: int, reason: String = "") -> void:
	var before := drl
	drl = clampi(drl + amount, 0, DRL_MAX)   # giữ trong khoảng 0..100
	if drl != before:
		drl_changed.emit(drl - before, reason)

func set_gpa(value: float) -> void:
	gpa = clampf(value, 0.0, GPA_MAX)

func gpa_ratio() -> float:
	return gpa / GPA_MAX

func drl_ratio() -> float:
	return float(drl) / DRL_MAX

func gpa_text() -> String:
	return "%.2f/%.1f" % [gpa, GPA_MAX]

func drl_text() -> String:
	return "%d/%d" % [drl, DRL_MAX]

func money_text() -> String:
	return money_compact_text(money)

func money_compact_text(amount: int) -> String:
	if absi(amount) >= 1000:
		if amount % 1000 == 0:
			return "%dk" % int(amount / 1000.0)
		return "%.1fk" % (float(amount) / 1000.0)
	return "%dđ" % amount

# Màu thanh theo tỉ lệ: 0 -> đỏ, 1 -> xanh lá, ở giữa đi qua cam và vàng.
# from_hsv(màu sắc, độ đậm, độ sáng): màu sắc 0.0 là đỏ, 0.33 là xanh lá.
func bar_color(ratio: float) -> Color:
	return Color.from_hsv(clampf(ratio, 0.0, 1.0) * 0.33, 0.8, 0.95)
