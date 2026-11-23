class_name Walkway
extends RefCounted
# MÁI VÒM HÀNH LANG VÒNG TRÒN XANH LÁ - HCMUS ĐÔNG HÒA
# Thiết kế module hóa: 1 đoạn ngắn chuẩn (UNIT_W = 24.0px),
# gọi lặp lại liên tiếp để tạo thành dải hành lang dài tùy ý.
# - draw_ground_segment() / draw_walkway_ground(): vẽ nền gạch và chân trụ (static bg)
# - draw_roof_segment()   / draw_walkway_roof():   vẽ vòng tròn sắt và mái vòm xanh (overlay, che khuất nhân vật)

const UNIT_W := 24.0         # Chiều dài của 1 đoạn module
const WALKWAY_H := 18.0      # Chiều rộng lòng hành lang

# Màu sắc mô phỏng hành lang vòm trường ĐH Khoa học Tự nhiên
const C_STEEL_DARK  := Color("14532d")  # Thép sơn xanh lá đậm
const C_STEEL_MID   := Color("1b6b30")  # Thép màu chính
const C_STEEL_LIGHT := Color("4ade80")  # Vệt sáng phản chiếu kim loại
const C_ROOF_MAIN   := Color("2e8b44")  # Tấm lợp mái vòm xanh lá
const C_ROOF_TOP    := Color("52c76a")  # Gờ đỉnh mái sáng
const C_ROOF_SHADOW := Color("165829")  # Mép dưới mái vòm
const C_RIB         := Color("86efac")  # Xương sườn đỡ mái
const C_PAVE_LIGHT  := Color("dfd2b5")  # Gạch lát nền sáng
const C_PAVE_DARK   := Color("c8b894")  # Gạch lát nền tối
const C_PAVE_LINE   := Color("b3a17a")  # Ron gạch

# ─── VẼ 1 ĐOẠN MODULE NỀN GẠCH & CHÂN TRỤ (Lớp nền - dưới chân người chơi) ───
static func draw_ground_segment(cv: CanvasItem, pos: Vector2) -> void:
	var x := pos.x
	var y := pos.y
	# 1. Nền gạch lát đường đi bộ
	cv.draw_rect(Rect2(x, y, UNIT_W, WALKWAY_H), C_PAVE_LIGHT)
	# Họa tiết gạch zíc zắc / xen kẽ
	cv.draw_rect(Rect2(x, y + 4.0, UNIT_W, 1.0), C_PAVE_LINE)
	cv.draw_rect(Rect2(x, y + 9.0, UNIT_W, 1.0), C_PAVE_LINE)
	cv.draw_rect(Rect2(x, y + 14.0, UNIT_W, 1.0), C_PAVE_LINE)
	for i in 3:
		var bx := x + i * 8.0
		cv.draw_rect(Rect2(bx, y, 1.0, 4.0), C_PAVE_LINE)
		cv.draw_rect(Rect2(bx + 4.0, y + 4.0, 1.0, 5.0), C_PAVE_LINE)
		cv.draw_rect(Rect2(bx, y + 9.0, 1.0, 5.0), C_PAVE_LINE)
		cv.draw_rect(Rect2(bx + 4.0, y + 14.0, 1.0, 4.0), C_PAVE_LINE)
	
	# Viền mép đá 2 bên lối đi
	cv.draw_rect(Rect2(x, y, UNIT_W, 1.0), C_PAVE_DARK)
	cv.draw_rect(Rect2(x, y + WALKWAY_H - 1.0, UNIT_W, 1.0), C_PAVE_DARK)

	# 2. Chân đế trụ vòng tròn sắt gắn xuống đất (ở giữa module)
	var mid_x := x + UNIT_W * 0.5
	# Đế chân phía bắc
	cv.draw_rect(Rect2(mid_x - 3.0, y - 1.0, 6.0, 3.0), C_STEEL_DARK)
	cv.draw_rect(Rect2(mid_x - 2.0, y, 4.0, 2.0), C_STEEL_MID)
	# Đế chân phía nam
	cv.draw_rect(Rect2(mid_x - 3.0, y + WALKWAY_H - 2.0, 6.0, 3.0), C_STEEL_DARK)
	cv.draw_rect(Rect2(mid_x - 2.0, y + WALKWAY_H - 2.0, 4.0, 2.0), C_STEEL_MID)

# ─── VẼ 1 ĐOẠN MODULE MÁI VÒM & VÒNG TRÒN SẮT (Lớp trên - che khuất người chơi) ───
static func draw_roof_segment(cv: CanvasItem, pos: Vector2) -> void:
	var x := pos.x
	var y := pos.y
	var mid_x := x + UNIT_W * 0.5
	var center_y := y + WALKWAY_H * 0.5

	# 1. Tấm mái vòm xanh lá (che từ đỉnh xuống ngang tầm vòm)
	# Mái vòm cong che nửa trên hành lang
	cv.draw_rect(Rect2(x, y - 5.0, UNIT_W, 14.0), C_ROOF_MAIN)
	# Gờ đỉnh mái (highlight sáng màu xanh nhạt)
	cv.draw_rect(Rect2(x, y - 5.0, UNIT_W, 2.0), C_ROOF_TOP)
	# Sọc phản chiếu sáng trên thân vòm
	cv.draw_rect(Rect2(x, y - 1.0, UNIT_W, 2.0), Color(C_ROOF_TOP.r, C_ROOF_TOP.g, C_ROOF_TOP.b, 0.5))
	# Mép dưới của mái (đổ bóng tối)
	cv.draw_rect(Rect2(x, y + 8.0, UNIT_W, 1.0), C_ROOF_SHADOW)

	# Thanh xà kim loại / xương sườn chạy dọc dưới mái
	cv.draw_rect(Rect2(x, y + 2.0, UNIT_W, 1.0), C_RIB)

	# 2. Vòng tròn sắt tròn đặc trưng (Circular green hoop)
	# Vẽ vòng tròn thép đứng bao quanh lối đi
	var radius := 11.0
	cv.draw_arc(Vector2(mid_x, center_y), radius, -PI, PI, 24, C_STEEL_MID, 2.0)
	# Highlight viền sáng phía trên vòng tròn
	cv.draw_arc(Vector2(mid_x, center_y), radius, -PI * 0.85, -PI * 0.15, 16, C_STEEL_LIGHT, 1.0)
	# Nút khớp nối cơ khí ở đỉnh vòng tròn
	cv.draw_rect(Rect2(mid_x - 2.0, center_y - radius - 1.0, 4.0, 3.0), C_STEEL_DARK)

# ─── HÀM GỌI LIÊN TIẾP ĐỂ TẠO DẢI MÁI VÒM DÀI TÙY Ý ─────────────────────────
# Gọi liên tiếp nhiều module ngắn nối tiếp nhau từ start_x đến end_x
static func draw_walkway_ground(cv: CanvasItem, start_x: float, end_x: float, y: float, view: Rect2) -> void:
	if not view.intersects(Rect2(start_x, y - 2.0, end_x - start_x, WALKWAY_H + 4.0)):
		return
	var x := start_x
	while x < end_x:
		if x + UNIT_W >= view.position.x and x <= view.end.x:
			draw_ground_segment(cv, Vector2(x, y))
		x += UNIT_W

static func draw_walkway_roof(cv: CanvasItem, start_x: float, end_x: float, y: float, view: Rect2) -> void:
	if not view.intersects(Rect2(start_x, y - 10.0, end_x - start_x, WALKWAY_H + 18.0)):
		return
	var x := start_x
	while x < end_x:
		if x + UNIT_W >= view.position.x and x <= view.end.x:
			draw_roof_segment(cv, Vector2(x, y))
		x += UNIT_W
