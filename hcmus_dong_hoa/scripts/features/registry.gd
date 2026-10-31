extends RefCounted
# DANH SÁCH GAMEPLAY DÙNG CHUNG - mỗi feature = 1 dòng.
# Nội dung riêng của công trình/khu vực bản đồ đăng ký tại scripts/maps/registry.gd.
#
# Thêm gameplay dùng chung: chép file vào scripts/features/, rồi thêm 1 dòng (nhớ dấu phẩy cuối dòng).
# Thứ tự = thứ tự khởi tạo. Nếu feature B dùng dữ liệu của feature A thì đặt A đứng trước B.
# Chỉ thêm entry mới trước dấu ] cuối danh sách; không xóa hoặc sắp xếp lại entry hiện có.

const LIST := [
	"res://scripts/features/fishing.gd",         # câu cá ở hồ đài phun nước
	"res://scripts/features/student_hud.gd",     # GPA/rèn luyện, đồng hồ và thời khóa biểu
	"res://scripts/features/student_panel.gd",   # sổ tay sinh viên
	"res://scripts/features/building_doors.gd",  # vào / ra công trình và căn tin
	"res://scripts/features/math_quiz.gd",       # NPC Cô Toán: nhấn E để làm quiz
	"res://scripts/features/newcharacters.gd",   # NPC mới
]
