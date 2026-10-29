extends RefCounted
# THỜI KHÓA BIỂU + GIỜ TỪNG TIẾT + LỊCH HỌC KỲ (cơ sở Đông Hòa). Chỉ có dữ liệu và vài hàm tra cứu, không vẽ gì.
# Cách dùng ở file khác:
#   const Schedule := preload("res://scripts/features/schedule_data.gd")
#   Schedule.courses_on(4)                      # các buổi học của Thứ 4
#   Schedule.time_range("LT", "2-5")            # [500, 710] = 8:20 đến 11:50 (phút trong ngày)
#   Schedule.clock_text(500)                    # "08:20"

# ---------- Lịch học kỳ 1 (tạm đặt, sửa theo lịch thật của trường) ----------
const SEMESTER_WEEKS := 17
const MIDTERM_WEEKS := [8, 9]     # tuần thi giữa kỳ
const FINAL_WEEKS := [16, 17]     # tuần thi cuối kỳ
const DAY_NAMES := ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"]

# ---------- Giờ từng tiết LÝ THUYẾT: tiết -> [phút bắt đầu, phút kết thúc], tính từ 0:00 ----------
const LT_PERIODS := {
	1: [450, 500],    # 7:30 - 8:20
	2: [500, 550],    # 8:20 - 9:10
	3: [550, 600],    # 9:10 - 10:00
	4: [610, 660],    # 10:10 - 11:00
	5: [660, 710],    # 11:00 - 11:50
	6: [760, 810],    # 12:40 - 13:30
	7: [810, 860],    # 13:30 - 14:20
	8: [860, 910],    # 14:20 - 15:10
	9: [920, 970],    # 15:20 - 16:10
	10: [970, 1020],  # 16:10 - 17:00
}

# Giờ các ca THỰC HÀNH (mỗi ca 2,5 tiết). Khóa là chuỗi ghi trong thời khóa biểu.
# "1-2.5" chưa có môn nào dùng, mình suy ra theo quy luật của 3 ca còn lại.
const TH_SHIFTS := {
	"1-2.5": [450, 575],   # 7:30 - 9:35
	"3.5-5": [585, 710],   # 9:45 - 11:50
	"6-7.5": [760, 885],   # 12:40 - 14:45
	"8.5-10": [895, 1020], # 14:55 - 17:00
}

# Tên hiển thị của nơi học. Chữ cái = Tòa đó; nơi không phải tòa thì ghi ở đây.
const PLACE_NAMES := {
	"NHÀ THỂ DỤC": "Nhà TD",
	"NHÀ ĐIỀU HÀNH": "Nhà ĐH",
}

# [tên môn, loại (LT/TH), thứ, tiết, nơi học, tên ngắn]   thứ: 2 = Thứ 2 ... 7 = Thứ 7. Sắp theo thứ rồi theo giờ.
# Nơi học ghi theo chữ tòa (khớp tên trong BUILDINGS của game_data.gd), không ghi số phòng.
const COURSES := [
	["Thể dục 1", "LT", 2, "2-5", "NHÀ THỂ DỤC", "Thể dục"],
	["Toán rời rạc", "LT", 2, "6-9", "D", "Toán rời rạc"],
	["Vi tích phân 1", "TH", 3, "3.5-5", "B", "Vi tích phân"],
	["Vi tích phân 1", "LT", 3, "6-9", "F", "Vi tích phân"],
	["Cơ sở lập trình", "LT", 4, "2-5", "F", "Cơ sở lập trình"],
	["Cơ sở lập trình", "TH", 4, "6-7.5", "D", "Cơ sở lập trình"],
	["Nhập môn Công nghệ Thông tin", "TH", 4, "8.5-10", "D", "Nhập môn CNTT"],
	["Nhập môn Công nghệ Thông tin", "LT", 5, "6-9", "E", "Nhập môn CNTT"],
	["Toán rời rạc", "TH", 6, "3.5-5", "NHÀ ĐIỀU HÀNH", "Toán rời rạc"],
]

# Đổi (loại, tiết) thành [phút bắt đầu, phút kết thúc]
static func time_range(kind: String, tiet: String) -> Array:
	if kind == "TH":
		return TH_SHIFTS[tiet]
	var parts := tiet.split("-")   # "2-5" -> ["2", "5"]
	return [LT_PERIODS[int(parts[0])][0], LT_PERIODS[int(parts[1])][1]]

# 500 -> "08:20"
static func clock_text(minute: int) -> String:
	return "%02d:%02d" % [int(minute / 60.0), minute % 60]

# Các buổi học trong 1 ngày (thứ 2..7)
static func courses_on(day_of_week: int) -> Array:
	var result: Array = []
	for c in COURSES:
		if c[2] == day_of_week:
			result.append(c)
	return result

# Số ngày đã trôi trong game -> thứ (0 = Thứ 2 ... 6 = Chủ nhật) và số tuần (tuần 1, 2, ...)
static func weekday(day: int) -> int:
	return day % 7

static func week_no(day: int) -> int:
	return int(day / 7.0) + 1

# "G" -> "Tòa G"; nơi đặc biệt lấy tên ngắn trong PLACE_NAMES
static func place_text(place: String) -> String:
	return PLACE_NAMES.get(place, "Tòa " + place)

# Dòng chữ về kỳ thi theo tuần hiện tại
static func exam_text(week: int) -> String:
	if week in MIDTERM_WEEKS:
		return "Đang thi giữa kỳ"
	if week < MIDTERM_WEEKS[0]:
		return "Giữa kỳ còn %d tuần" % (MIDTERM_WEEKS[0] - week)
	if week in FINAL_WEEKS:
		return "Đang thi cuối kỳ"
	if week < FINAL_WEEKS[0]:
		return "Cuối kỳ còn %d tuần" % (FINAL_WEEKS[0] - week)
	return "Hết học kỳ"

# Dòng "buổi học kế tiếp" cho HUD, dựa vào ngày và giờ hiện tại trong game
static func next_class_text(day: int, game_min: float) -> String:
	var now := int(game_min)
	var today := courses_on(weekday(day) + 2)
	for c in today:
		var t := time_range(c[1], c[3])
		if now < t[0]:
			return "Tiếp: %s · %s · %s" % [c[5], place_text(c[4]), clock_text(t[0])]
		if now < t[1]:
			return "Đang học: %s · %s" % [c[5], place_text(c[4])]
	if today.is_empty():
		return "Hôm nay không có lịch học"
	return "Hôm nay hết lịch học"
