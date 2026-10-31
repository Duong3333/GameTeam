extends RefCounted
# DANH SÁCH CHỨC NĂNG - mỗi feature = 1 dòng. Đây là NƠI DUY NHẤT cần sửa để đăng ký feature mới.
# main.gd đọc danh sách này và tự add_feature cho từng dòng, nên KHÔNG cần sửa main.gd.
#
# Thêm feature mới: chép file vào scripts/features/, rồi thêm 1 dòng (nhớ dấu phẩy cuối dòng).
# Thứ tự = thứ tự khởi tạo. Nếu feature B dùng dữ liệu của feature A thì đặt A đứng trước B.

const LIST := [
	"res://scripts/features/fishing.gd",         # câu cá ở Hồ sinh viên
	"res://scripts/features/student_hud.gd",     # GPA/rèn luyện, đồng hồ và thời khóa biểu
	"res://scripts/features/student_panel.gd",   # sổ tay sinh viên
	"res://scripts/features/building_doors.gd",  # vào / ra công trình và căn tin
	"res://scripts/features/dance.gd",           # nhấn J để nhảy múa
	"res://scripts/features/math_quiz.gd",       # NPC Cô Toán: nhấn E để làm quiz
]
