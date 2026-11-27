extends RefCounted
# DANH SÁCH GAMEPLAY DÙNG CHUNG - mỗi feature = 1 dòng.
# Nội dung riêng của công trình/khu vực bản đồ đăng ký tại scripts/maps/registry.gd.
#
# Thứ tự = thứ tự khởi tạo. Nếu feature B dùng dữ liệu của feature A thì đặt A đứng trước B.

const LIST := [
	"res://scripts/features/student_hud.gd",     # GPA/rèn luyện, đồng hồ và thời khóa biểu
	"res://scripts/features/student_panel.gd",   # sổ tay sinh viên
	"res://scripts/features/student_tuition.gd", # lựa chọn đóng học phí và trạng thái học vụ
	"res://scripts/features/building_doors.gd",  # vào / ra công trình và căn tin
	"res://scripts/features/math_quiz.gd",       # Quiz toán và đề thi do giảng viên khởi động
	"res://scripts/features/class_attendance.gd",# Quiz trên lớp theo thời khóa biểu và bài tập về nhà
	"res://scripts/features/character.gd",   # NPC có tên
	"res://scripts/features/npc_random_quiz.gd", # Mini quiz từ NPC sinh viên thường
	"res://scripts/features/khoc.gd",            # bấm C để khóc; hiệu ứng khóc cho NPC (UpdateMap)
	"res://scripts/features/danhnhau.gd",        # đứng gần NPC và bấm H để đánh trêu (UpdateMap)
	"res://scripts/features/daily_story.gd",     # Cốt truyện theo ngày (typewriter, hiện trước daily_summary)
	"res://scripts/features/daily_summary.gd",   # Tổng kết cuối ngày (UpdateMap)
	"res://scripts/features/admin_time.gd",      # Chế độ admin: tua tuần, thứ và giờ từ menu Esc
	"res://scripts/features/bench_sitting.gd",   # Bấm E để ngồi và đứng dậy khỏi ghế đá (UpdateMap)
	"res://scripts/features/chidori.gd",         # Thử nghiệm Chidori: bấm J gần NPC (UpdateMap)
	"res://scripts/features/game_pace.gd",       # Làm chậm thời gian để người chơi khám phá; quiz chậm thêm 10 lần
	"res://scripts/features/pause_menu.gd",      # Menu tạm dừng khi bấm Esc để quay về Menu chính
	"res://scripts/features/rasengan.gd",        # Rasengan: bấm K gần NPC để tung cầu chakra
]
