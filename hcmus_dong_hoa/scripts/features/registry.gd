extends RefCounted
# DANH SÁCH CHỨC NĂNG - mỗi feature = 1 dòng. Đây là NƠI DUY NHẤT cần sửa để đăng ký feature mới.
# main.gd đọc danh sách này và tự add_feature cho từng dòng, nên KHÔNG cần sửa main.gd.
#
# Thêm feature mới: chép file vào scripts/features/, rồi thêm 1 dòng (nhớ dấu phẩy cuối dòng).
# Thứ tự = thứ tự khởi tạo. Nếu feature B dùng dữ liệu của feature A thì đặt A đứng trước B.

const LIST := [
	#"res://scripts/features/fishing.gd",         # câu cá ở Hồ sinh viên
	"res://scripts/features/student_hud.gd",     # 2 thanh GPA/rèn luyện, đồng hồ
	"res://scripts/features/student_panel.gd",   # sổ tay (Tab)
	"res://scripts/features/dance.gd",           # nhấn J để nhảy múa
	# <<< thêm dòng mới ngay phía trên dòng này
]
