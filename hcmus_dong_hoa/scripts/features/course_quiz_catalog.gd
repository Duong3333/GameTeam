extends RefCounted
# COURSE QUIZ CATALOG
# Quiz duoc gan voi tiet hoc + phong + thoi khoa bieu, KHONG gan voi NPC giao vien.
# Them mon moi: bo sung ma mon trong CLASS_BANK_CODES va resolve_course_code().

const CLASS_BANK_CODES := ["DISCRETE", "INTRO_IT", "CSLT_THEORY", "CSLT_PRACTICAL", "VTP1", "VTP1_PRACTICAL"]

const COURSE_NAMES := {
	"DISCRETE": "Toán rời rạc",
	"INTRO_IT": "Nhập môn Công nghệ Thông tin",
	"CSLT_THEORY": "Cơ sở lập trình lý thuyết",
	"CSLT_PRACTICAL": "Cơ sở lập trình thực hành",
	"VTP1": "Vi tích phân 1 - Lý thuyết",
	"VTP1_PRACTICAL": "Vi tích phân 1B - Thực hành",
}

static func resolve_course_code(course: Array, room_type: String, room_key: String) -> String:
	if course.size() < 5:
		return ""
	var subject_name := str(course[0])
	var class_kind := str(course[1])
	var place := str(course[4])

	# Toán rời rạc: LT tại Tòa D; TH tại Nhà Điều hành.
	if subject_name == "Toán rời rạc":
		if place == "D" and room_type == "classroom" and room_key == "D_TRR":
			return "DISCRETE"
		if place == "NHÀ ĐIỀU HÀNH" and room_type == "classroom" and room_key == "NDH":
			return "DISCRETE"

	# Vi tích phân: tách ngân hàng lý thuyết và thực hành theo loại tiết trong TKB.
	if subject_name == "Vi tích phân 1":
		if class_kind == "LT" and place == "F" and room_type == "classroom" and room_key == "F_VTP":
			return "VTP1"
		if class_kind == "TH" and place == "B":
			# Tiết thực hành Vi tích phân diễn ra ở phòng lab B4.2 (b42_lab.gd, preset B42_VTP);
			# vẫn nhận phòng học tòa B (khóa "B") như trước.
			if room_type == "lab" and room_key in ["B42_VTP", "B42_LAB"]:
				return "VTP1_PRACTICAL"
			if room_type == "classroom" and room_key == "B":
				return "VTP1_PRACTICAL"

	# Cơ sở lập trình được tách thành LT và TH dựa vào cột loại tiết trong TKB.
	if subject_name == "Cơ sở lập trình":
		if class_kind == "LT" and place == "F" and room_type == "classroom" and room_key == "F_CSLT":
			return "CSLT_THEORY"
		if class_kind == "TH" and place == "D":
			# Ưu tiên phòng máy nếu map lab đang mở; cho phép phòng D làm lớp thay thế
			# khi project chưa mở được module lab. TKB + giờ học là tiêu chí phân biệt môn.
			if (room_type == "lab" and room_key in ["D_CSLT", "B42_LAB"]) or (room_type == "classroom" and room_key == "D_TRR"):
				return "CSLT_PRACTICAL"

	# Nhập môn CNTT: LT tại E, TH tại D (phòng D được dùng chung theo TKB).
	if subject_name == "Nhập môn Công nghệ Thông tin":
		if class_kind == "LT" and place == "E" and room_type == "classroom" and room_key == "E":
			return "INTRO_IT"
		if class_kind == "TH" and place == "D" and room_type == "classroom" and room_key == "D_TRR":
			return "INTRO_IT"

	return ""

static func course_name(course_code: String) -> String:
	return str(COURSE_NAMES.get(course_code, course_code))

static func homework_enabled(course_code: String) -> bool:
	# Theo yêu cầu hiện tại: bài tập về nhà được giao sau tiết CSLT lý thuyết.
	return course_code == "CSLT_THEORY"

static func has_class_bank(course_code: String) -> bool:
	return course_code in CLASS_BANK_CODES
