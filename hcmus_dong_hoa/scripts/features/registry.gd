extends RefCounted
# DANH SÁCH GAMEPLAY DÙNG CHUNG - mỗi feature = 1 dòng.
# Nội dung riêng của công trình/khu vực bản đồ đăng ký tại scripts/maps/registry.gd.
#
# Thêm gameplay dùng chung: chép file vào scripts/features/, rồi thêm 1 dòng (nhớ dấu phẩy cuối dòng).
# Thứ tự = thứ tự khởi tạo. Nếu feature B dùng dữ liệu của feature A thì đặt A đứng trước B.
# Chỉ thêm entry mới trước dấu ] cuối danh sách; không xóa hoặc sắp xếp lại entry hiện có.

const LIST := [
	"res://scripts/features/student_hud.gd",     # GPA/rèn luyện, đồng hồ và thời khóa biểu
	"res://scripts/features/student_panel.gd",   # sổ tay sinh viên
	"res://scripts/features/student_tuition.gd", # lựa chọn đóng học phí và trạng thái học vụ
	"res://scripts/features/building_doors.gd",  # vào / ra công trình và căn tin
	"res://scripts/features/math_quiz.gd",       # Quiz toán và đề thi do giảng viên khởi động
	"res://scripts/features/class_attendance.gd", # Quiz trên lớp Cơ sở lập trình và bài tập về nhà
	"res://scripts/features/newcharacters.gd",   # NPC mới
	"res://scripts/features/npc_random_quiz.gd", # Mini quiz ngẫu nhiên từ NPC sinh viên thường
	"res://scripts/features/admin_time.gd",      # Chế độ admin: tua tuần, thứ và giờ từ menu Esc
	"res://scripts/features/bike_collision.gd",  # Va chạm xe máy và NPC qua đường
	"res://scripts/features/game_pace.gd",       # Nhịp thời gian: chậm hơn bình thường, chậm thêm 10 lần khi làm quiz
	"res://scripts/features/campus_chat.gd",     # Giao diện Chat chung và khung nhập tin nhắn
]
