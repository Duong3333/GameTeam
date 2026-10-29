extends Node
# THÔNG SỐ SINH VIÊN: GPA (thang 4.0) và điểm rèn luyện (thang 100).
# File này chỉ LƯU SỐ và BÁO khi số đổi, không vẽ gì (phần vẽ nằm ở student_hud.gd).
# Nơi khác trong game đổi điểm bằng:
#   game.stats.add_drl(1, "Đi học đúng giờ")    # cộng 1 điểm rèn luyện (số âm là trừ)
#   game.stats.set_gpa(3.4)                      # đặt GPA

signal drl_changed(amount: int, reason: String)   # phát ra mỗi khi điểm rèn luyện thật sự đổi

const GPA_MAX := 4.0
const DRL_MAX := 100

var gpa := 3.0   # GPA lúc bắt đầu
var drl := 70    # điểm rèn luyện lúc bắt đầu

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

# Màu thanh theo tỉ lệ: 0 -> đỏ, 1 -> xanh lá, ở giữa đi qua cam và vàng.
# from_hsv(màu sắc, độ đậm, độ sáng): màu sắc 0.0 là đỏ, 0.33 là xanh lá.
func bar_color(ratio: float) -> Color:
	return Color.from_hsv(clampf(ratio, 0.0, 1.0) * 0.33, 0.8, 0.95)
