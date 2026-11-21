class_name HoNuoc
extends RefCounted
# ==============================================================================
# HỒ SINH VIÊN & CÔNG VIÊN ĐÀI PHUN NƯỚC HCMUS LINH TRUNG
# (scripts/maps/ho_nuoc.gd)
#
# Thiết kế kiến trúc hồ nước lớn nhiều vòng tròn đồng tâm chuẩn xác theo ảnh
# thực tế khuôn viên HCMUS Đông Hòa (Linh Trung) và yêu cầu thiết kế:
#
# CẤU TRÚC ĐỒNG TÂM TỪ NGOÀI VÀO TRONG (Tất cả chung một tâm cân đối):
#   1. Vòng quảng trường bao quanh hồ (R_PLAZA = 110px) với thảm cỏ & hàng cau vua.
#   2. Bờ kè đá ngoài cùng hồ nước (R_OUTER_RIM = 95px).
#   3. VÀNH NƯỚC TRÒN LỚN PHÍA NGOÀI (R: 72px -> 92px, rộng 20px).
#   4. VÒNG THÀNH HỒ BẰNG ĐÁ/BÊ TÔNG PHÂN CÁCH (R: 56px -> 72px, rộng 16px)
#      với mặt đi bộ lát đá, viền gạch terracotta và vành cây cảnh cắt tỉa uốn lượn.
#   5. VÀNH NƯỚC RIÊNG BIỆT PHÍA TRONG (R: 38px -> 56px, rộng 18px).
#   6. ĐẢO TRÒN Ở CHÍNH GIỮA (R_ISLAND = 38px) với vành đai cây cảnh và luống hoa.
#   7. BỂ PHUN NƯỚC CYAN & ĐÀI PHUN NƯỚC TRUNG TÂM (R_FOUNTAIN = 16px).
#
# HỆ THỐNG CẦU HƯỚNG TÂM:
#   - 4 Cầu trục chính (Bắc, Nam, Đông, Tây) rộng 14px.
#   - 4 Cầu chéo 45° (Tây Bắc, Đông Bắc, Tây Nam, Đông Nam) rộng 10px.
#   - Chạy xuyên qua các vành nước, kết nối liền mạch với vòng thành phân cách
#     và đảo trung tâm, chia hồ thành 16 khoang nước đối xứng tuyệt đẹp!
# ==============================================================================

# ─── BÁN KÍNH HÌNH HỌC ĐỒNG TÂM (CHUNG MỘT TÂM center) ────────────────────────
const R_PLAZA        := 110.0  # Mép ngoài quảng trường công viên đi dạo
const R_OUTER_RIM    := 95.0   # Bờ kè đá ngoài cùng hồ nước
const R_WATER1_OUT   := 92.0   # Mép ngoài vành nước 1 (vành ngoài)
const R_WATER1_IN    := 72.0   # Mép trong vành nước 1 (rộng 20px)
const R_STONE_RING   := 72.0   # Mép ngoài vòng thành đá phân cách
const R_STONE_INNER  := 56.0   # Mép trong vòng thành đá phân cách (rộng 16px)
const R_WATER2_OUT   := 56.0   # Mép ngoài vành nước 2 (vành trong)
const R_WATER2_IN    := 38.0   # Mép trong vành nước 2 (rộng 18px)
const R_ISLAND       := 38.0   # Bán kính đảo tròn trung tâm
const R_FOUNTAIN     := 16.0   # Bán kính bể đài phun nước cyan

# Bề rộng các cây cầu hướng tâm
const BRIDGE_MAIN_W  := 14.0   # Cầu trục chính Bắc, Nam, Đông, Tây
const BRIDGE_SPOKE_W := 10.0   # Cầu chéo 45 độ

# ─── MÀU SẮC KIẾN TRÚC & VẬT LIỆU ──────────────────────────────────────────────
# Đá lát & bờ kè
const C_PLAZA_BG     := Color("e5ded0") # Nền quảng trường đá be sáng
const C_PLAZA_BORDER := Color("b8b09f") # Viền bờ quảng trường
const C_STONE_DARK   := Color("4a463e") # Bờ kè đá tối / bóng chân kè
const C_STONE_MID    := Color("c8c2b5") # Mặt bờ đá hoa cương
const C_STONE_LIGHT  := Color("f6f2e8") # Gờ đá sáng nổi khối 3D
const C_STONE_SHADE  := Color("8e877a") # Mặt đứng bờ kè đá
const C_JOINT        := Color("bbb2a1") # Mạch ron gạch lát sàn
const C_BRICK_RIM    := Color("a63e2d") # Viền gạch terracotta đỏ nâu đặc trưng
const C_BRICK_LIGHT  := Color("cb523f") # Cạnh sáng viền gạch

# Mặt nước hồ chính (xanh lục ngọc bích emerald teal theo ảnh thực tế)
const C_WATER_EDGE   := Color("103024") # Nước chân bờ kè sâu thẳm
const C_WATER_DEEP   := Color("184a3c") # Nước sâu đậm màu
const C_WATER_MID    := Color("226352") # Nước xanh ngọc bích
const C_WATER_LIGHT  := Color("2d7866") # Nước phản quang sáng
const C_RIPPLE       := Color(0.50, 0.86, 0.76, 0.45) # Gợn sóng nước lấp lánh

# Bể phun nước trung tâm (xanh cyan / turquoise rực rỡ đặc trưng trong ảnh)
const C_CYAN_DEEP    := Color("0077b6") # Đáy bể cyan đậm
const C_CYAN_MID     := Color("00b4d8") # Nước bể cyan ngọc biển
const C_CYAN_LIGHT   := Color("48cae4") # Mặt nước cyan sáng lấp lánh
const C_CYAN_FOAM    := Color("90e0ef") # Bọt nước bề mặt
const C_CYAN_RIM     := Color("fbfaf5") # Thành bể đá hoa cương trắng

# Cây cảnh & đài phun nước
const C_HEDGE_DARK   := Color("1e5622") # Cây tỉa bóng râm
const C_HEDGE_MID    := Color("3ca342") # Cây tỉa xanh lá tươi tắn
const C_HEDGE_LIGHT  := Color("6be071") # Đọt lá non sáng
const C_FOUNT_SPRAY  := Color(0.92, 0.98, 1.0, 0.92) # Tia nước phun trắng xóa
const C_BENCH_WOOD   := Color("9c6b3e") # Ghế đá / gỗ công viên
const C_BENCH_LEG    := Color("4a3c28") # Chân ghế

# ─── HÀM CHÍNH: VẼ TOÀN BỘ CÔNG TRÌNH HỒ NƯỚC ĐỒNG TÂM ──────────────────────────
static func draw_landscape(canvas: CanvasItem, center: Vector2, clock: float = 0.0) -> void:
	var c := center
	var bbox := Rect2(c - Vector2(170, 170), Vector2(340, 340))
	if "view" in canvas and not canvas.view.grow(40.0).intersects(bbox):
		return

	# 1. Vòng quảng trường công viên bao quanh hồ & các lối tiếp cận 4 hướng
	_draw_plaza_and_avenues(canvas, c)

	# 2. Vành nước tròn lớn phía ngoài (Outer Water Ring)
	_draw_outer_water_ring(canvas, c, clock)

	# 3. Vòng thành hồ phân cách bằng đá/bê tông (Concentric Stone Divider Ring)
	_draw_stone_divider_ring_base(canvas, c)

	# 4. Vành nước riêng biệt phía trong (Inner Water Ring)
	_draw_inner_water_ring(canvas, c, clock)

	# 5. Hệ thống 8 cây cầu hướng tâm (chia hồ thành 16 khoang nước đối xứng)
	_draw_radial_bridges(canvas, c)

	# 6. Bề mặt đi bộ & vành cây cảnh uốn lượn trên vòng thành đá phân cách
	_draw_stone_divider_walkway_and_hedges(canvas, c)

	# 7. Đảo tròn ở chính giữa có bồn cây cảnh và luống hoa
	_draw_central_island(canvas, c)

	# 8. Bể phun nước cyan và cột đài phun nước trung tâm sinh động
	_draw_fountain_basin_and_jets(canvas, c, clock)

	# 9. Cảnh quan cây xanh (hàng cau vua thẳng tắp, ghế đá, hàng rào tỉa)
	_draw_park_landscaping(canvas, c)

# ─── 1. VÒNG QUẢNG TRƯỜNG CÔNG VIÊN & LỐI TIẾP CẬN 4 HƯỚNG ────────────────────
static func _draw_plaza_and_avenues(canvas: CanvasItem, c: Vector2) -> void:
	# Nền cỏ công viên xanh bao quanh quảng trường
	_draw_circle_poly(canvas, c, R_PLAZA + 28.0, Color("4aa246"), 36)

	# 4 mảng cỏ hoa viên ở 4 góc chéo
	for k: int in [1, 3, 5, 7]:
		var ang: float = float(k) * PI * 0.25
		var lawn_pos := c + Vector2(cos(ang), sin(ang)) * (R_PLAZA + 12.0)
		_draw_circle_poly(canvas, lawn_pos, 18.0, Color("3da443"), 20)
		_draw_circle_poly(canvas, lawn_pos + Vector2(-1, -1), 15.0, Color("54c24b"), 20)

	# Vòng quảng trường đi dạo lát đá be sáng
	_draw_circle_poly(canvas, c + Vector2(0, 3), R_PLAZA + 2.0, Color(0, 0, 0, 0.18), 36) # bóng đổ
	_draw_circle_poly(canvas, c, R_PLAZA, C_PLAZA_BORDER, 36)
	_draw_circle_poly(canvas, c, R_PLAZA - 1.5, C_PLAZA_BG, 36)

	# Đường chỉ ron đá tròn đồng tâm trên quảng trường
	_draw_circle_outline(canvas, c, R_PLAZA - 6.0, C_JOINT, 1.0, 36)

	# ── 4 Lối đi tiếp cận từ các hướng ──
	# Nhánh Nam: Đại lộ chính dẫn vào hồ từ phía cổng trường
	var s_rect := Rect2(c.x - 14.0, c.y + R_PLAZA - 2.0, 28.0, 52.0)
	canvas.draw_rect(s_rect.grow(1.5), C_PLAZA_BORDER)
	canvas.draw_rect(s_rect, C_PLAZA_BG)
	for sy in range(int(s_rect.position.y) + 4, int(s_rect.end.y), 8):
		canvas.draw_line(Vector2(s_rect.position.x + 2, sy), Vector2(s_rect.end.x - 2, sy), C_JOINT, 1.0)

	# Nhánh Bắc: dẫn lên Nhà Thể Dục
	var n_rect := Rect2(c.x - 12.0, c.y - R_PLAZA - 48.0, 24.0, 50.0)
	canvas.draw_rect(n_rect.grow(1.5), C_PLAZA_BORDER)
	canvas.draw_rect(n_rect, C_PLAZA_BG)
	for ny in range(int(n_rect.position.y) + 4, int(n_rect.end.y), 8):
		canvas.draw_line(Vector2(n_rect.position.x + 2, ny), Vector2(n_rect.end.x - 2, ny), C_JOINT, 1.0)

	# Nhánh Đông (sang Tòa F) & Nhánh Tây (sang trục đường chính)
	var e_rect := Rect2(c.x + R_PLAZA - 2.0, c.y - 11.0, 50.0, 22.0)
	canvas.draw_rect(e_rect.grow(1.5), C_PLAZA_BORDER)
	canvas.draw_rect(e_rect, C_PLAZA_BG)

	var w_rect := Rect2(c.x - R_PLAZA - 48.0, c.y - 11.0, 50.0, 22.0)
	canvas.draw_rect(w_rect.grow(1.5), C_PLAZA_BORDER)
	canvas.draw_rect(w_rect, C_PLAZA_BG)

# ─── 2. VÀNH NƯỚC TRÒN LỚN PHÍA NGOÀI (OUTER WATER RING) ──────────────────────
static func _draw_outer_water_ring(canvas: CanvasItem, c: Vector2, clock: float) -> void:
	# Bờ kè đá ngoài cùng hồ nước (Outer Retaining Wall)
	_draw_circle_poly(canvas, c + Vector2(0, 3.5), R_OUTER_RIM + 2.5, Color(0, 0, 0, 0.26), 40)
	_draw_circle_poly(canvas, c, R_OUTER_RIM + 1.5, C_STONE_DARK, 40)
	_draw_circle_poly(canvas, c, R_OUTER_RIM, C_STONE_MID, 40)
	_draw_circle_poly(canvas, c, R_OUTER_RIM - 1.5, C_STONE_LIGHT, 40)
	_draw_circle_poly(canvas, c, R_OUTER_RIM - 3.0, C_STONE_SHADE, 40)

	# Mặt nước vành ngoài (từ R_OUTER_RIM - 3px = 92px đến R_WATER1_IN = 72px)
	_draw_circle_poly(canvas, c, R_WATER1_OUT, C_WATER_EDGE, 40)
	_draw_circle_poly(canvas, c, R_WATER1_OUT - 2.5, C_WATER_DEEP, 40)
	_draw_circle_poly(canvas, c, R_WATER1_OUT - 7.0, C_WATER_MID, 40)
	_draw_circle_poly(canvas, c, R_WATER1_OUT - 12.0, C_WATER_LIGHT, 40)

	# Gợn sóng nước lấp lánh trên vành nước ngoài
	for i in 20:
		var ang := float(i) * TAU / 20.0
		var r_wave := lerpf(R_WATER1_IN + 4.0, R_WATER1_OUT - 4.0, fmod(float(i) * 0.37 + clock * 0.14, 1.0))
		var wp := c + Vector2(cos(ang), sin(ang)) * r_wave
		if sin(clock * 2.8 + float(i) * 1.7) > -0.1:
			var w_len := 6.5 + sin(clock * 3.2 + float(i)) * 2.0
			canvas.draw_line(Vector2(wp.x - w_len * 0.5, wp.y), Vector2(wp.x + w_len * 0.5, wp.y), C_RIPPLE, 1.2)

# ─── 3. VÒNG THÀNH HỒ BẰNG ĐÁ ĐỒNG TÂM PHÂN CÁCH (NỀN ĐÁ CƠ BẢN) ─────────────
static func _draw_stone_divider_ring_base(canvas: CanvasItem, c: Vector2) -> void:
	# Bóng đổ của vòng thành đá phân cách xuống vành nước ngoài
	_draw_circle_poly(canvas, c + Vector2(0, 3.0), R_STONE_RING + 2.5, Color(0, 0, 0, 0.32), 36)

	# Vòng thành đá đồng tâm phân cách (R từ 56px đến 72px, rộng 16px)
	_draw_circle_poly(canvas, c, R_STONE_RING + 1.2, C_STONE_DARK, 36)
	_draw_circle_poly(canvas, c, R_STONE_RING, C_BRICK_RIM, 36)
	_draw_circle_poly(canvas, c, R_STONE_RING - 1.5, C_BRICK_LIGHT, 36)
	_draw_circle_poly(canvas, c, R_STONE_RING - 2.5, C_PLAZA_BG, 36)

# ─── 4. VÀNH NƯỚC RIÊNG BIỆT PHÍA TRONG (INNER WATER RING) ────────────────────
static func _draw_inner_water_ring(canvas: CanvasItem, c: Vector2, clock: float) -> void:
	# Bờ kè trong của vòng thành đá đổ bóng xuống vành nước trong
	_draw_circle_poly(canvas, c + Vector2(0, 2.5), R_WATER2_OUT + 2.0, Color(0, 0, 0, 0.30), 32)
	_draw_circle_poly(canvas, c, R_WATER2_OUT + 1.0, C_BRICK_RIM, 32)

	# Mặt nước vành trong (từ R_WATER2_OUT = 56px đến R_WATER2_IN = 38px, rộng 18px)
	_draw_circle_poly(canvas, c, R_WATER2_OUT, C_WATER_EDGE, 32)
	_draw_circle_poly(canvas, c, R_WATER2_OUT - 2.5, C_WATER_DEEP, 32)
	_draw_circle_poly(canvas, c, R_WATER2_OUT - 6.0, C_WATER_MID, 32)
	_draw_circle_poly(canvas, c, R_WATER2_OUT - 10.0, C_WATER_LIGHT, 32)

	# Gợn sóng nước lấp lánh trên vành trong
	for i in 12:
		var ang := float(i) * TAU / 12.0 + PI * 0.1
		var r_wave := lerpf(R_WATER2_IN + 3.0, R_WATER2_OUT - 3.0, fmod(float(i) * 0.42 + clock * 0.16, 1.0))
		var wp := c + Vector2(cos(ang), sin(ang)) * r_wave
		if sin(clock * 3.0 + float(i) * 2.2) > 0.0:
			canvas.draw_line(Vector2(wp.x - 3.5, wp.y), Vector2(wp.x + 3.5, wp.y), C_RIPPLE, 1.0)

# ─── 5. HỆ THỐNG CÁC LỐI ĐI RỘNG CHẠY THEO HƯỚNG TÂM (CẦU ĐI BỘ) ────────────
static func _draw_radial_bridges(canvas: CanvasItem, c: Vector2) -> void:
	var shade_col := Color(0, 0, 0, 0.34)

	# A. 4 CẦU CHÉO 45° (Tây Bắc, Đông Bắc, Tây Nam, Đông Nam) rộng 10px
	var spoke_angles: Array[float] = [
		-PI * 0.75, # Tây Bắc
		-PI * 0.25, # Đông Bắc
		 PI * 0.75, # Tây Nam
		 PI * 0.25  # Đông Nam
	]
	var spoke_hw := BRIDGE_SPOKE_W * 0.5

	for ang: float in spoke_angles:
		var dir := Vector2(cos(ang), sin(ang))
		var perp := Vector2(-dir.y, dir.x) * spoke_hw
		var p_start := c + dir * (R_ISLAND - 1.0)
		var p_end   := c + dir * (R_OUTER_RIM + 2.0)

		# Bóng đổ cầu chéo xuống mặt nước hồ
		canvas.draw_colored_polygon(PackedVector2Array([
			p_start - perp + Vector2(1.5, 3.0), p_end - perp + Vector2(1.5, 3.0),
			p_end + perp + Vector2(1.5, 3.0),   p_start + perp + Vector2(1.5, 3.0)
		]), shade_col)

		# Thân cầu viền đá hoa cương
		canvas.draw_colored_polygon(PackedVector2Array([
			p_start - perp, p_end - perp, p_end + perp, p_start + perp
		]), C_STONE_MID)

		# Mặt cầu lát đá màu be sáng
		var inner_perp := perp * 0.78
		canvas.draw_colored_polygon(PackedVector2Array([
			p_start - inner_perp, p_end - inner_perp, p_end + inner_perp, p_start + inner_perp
		]), C_PLAZA_BG)

		# Gờ thành lan can cầu đá 2 bên nổi khối 3D
		canvas.draw_line(p_start - perp, p_end - perp, C_STONE_LIGHT, 1.4)
		canvas.draw_line(p_start + perp, p_end + perp, C_STONE_SHADE, 1.4)

	# B. 4 CẦU TRỤC CHÍNH (BẮC, NAM, ĐÔNG, TÂY) RỘNG 14px
	var m_hw := BRIDGE_MAIN_W * 0.5

	# 1. Cầu trục Nam (dẫn từ đại lộ vào đảo trung tâm)
	var s_y0 := c.y + R_ISLAND - 1.0
	var s_y1 := c.y + R_OUTER_RIM + 3.0
	var s_len := s_y1 - s_y0
	canvas.draw_rect(Rect2(c.x - m_hw + 2.5, s_y0 + 3.0, BRIDGE_MAIN_W, s_len), shade_col)
	canvas.draw_rect(Rect2(c.x - m_hw - 1.2, s_y0, BRIDGE_MAIN_W + 2.4, s_len), C_STONE_MID)
	canvas.draw_rect(Rect2(c.x - m_hw, s_y0, BRIDGE_MAIN_W, s_len), C_PLAZA_BG)
	canvas.draw_line(Vector2(c.x - m_hw, s_y0), Vector2(c.x - m_hw, s_y1), C_STONE_LIGHT, 1.5)
	canvas.draw_line(Vector2(c.x + m_hw, s_y0), Vector2(c.x + m_hw, s_y1), C_STONE_SHADE, 1.5)
	for gy in range(int(s_y0) + 4, int(s_y1) - 2, 7):
		canvas.draw_line(Vector2(c.x - m_hw + 1, gy), Vector2(c.x + m_hw - 1, gy), C_JOINT, 1.0)

	# 2. Cầu trục Bắc (dẫn lên Nhà Thể Dục)
	var n_y0 := c.y - R_OUTER_RIM - 3.0
	var n_y1 := c.y - R_ISLAND + 1.0
	var n_len := n_y1 - n_y0
	canvas.draw_rect(Rect2(c.x - m_hw + 2.5, n_y0 + 3.0, BRIDGE_MAIN_W, n_len), shade_col)
	canvas.draw_rect(Rect2(c.x - m_hw - 1.2, n_y0, BRIDGE_MAIN_W + 2.4, n_len), C_STONE_MID)
	canvas.draw_rect(Rect2(c.x - m_hw, n_y0, BRIDGE_MAIN_W, n_len), C_PLAZA_BG)
	canvas.draw_line(Vector2(c.x - m_hw, n_y0), Vector2(c.x - m_hw, n_y1), C_STONE_LIGHT, 1.5)
	canvas.draw_line(Vector2(c.x + m_hw, n_y0), Vector2(c.x + m_hw, n_y1), C_STONE_SHADE, 1.5)
	for gy in range(int(n_y0) + 4, int(n_y1) - 2, 7):
		canvas.draw_line(Vector2(c.x - m_hw + 1, gy), Vector2(c.x + m_hw - 1, gy), C_JOINT, 1.0)

	# 3. Cầu trục Tây (sang trục đường chính)
	var w_x0 := c.x - R_OUTER_RIM - 3.0
	var w_x1 := c.x - R_ISLAND + 1.0
	var w_len := w_x1 - w_x0
	canvas.draw_rect(Rect2(w_x0 + 2.5, c.y - m_hw + 3.0, w_len, BRIDGE_MAIN_W), shade_col)
	canvas.draw_rect(Rect2(w_x0, c.y - m_hw - 1.2, w_len, BRIDGE_MAIN_W + 2.4), C_STONE_MID)
	canvas.draw_rect(Rect2(w_x0, c.y - m_hw, w_len, BRIDGE_MAIN_W), C_PLAZA_BG)
	canvas.draw_line(Vector2(w_x0, c.y - m_hw), Vector2(w_x1, c.y - m_hw), C_STONE_LIGHT, 1.5)
	canvas.draw_line(Vector2(w_x0, c.y + m_hw), Vector2(w_x1, c.y + m_hw), C_STONE_SHADE, 1.5)
	for gx in range(int(w_x0) + 4, int(w_x1) - 2, 7):
		canvas.draw_line(Vector2(gx, c.y - m_hw + 1), Vector2(gx, c.y + m_hw - 1), C_JOINT, 1.0)

	# 4. Cầu trục Đông (sang Tòa F)
	var e_x0 := c.x + R_ISLAND - 1.0
	var e_x1 := c.x + R_OUTER_RIM + 3.0
	var e_len := e_x1 - e_x0
	canvas.draw_rect(Rect2(e_x0 + 2.5, c.y - m_hw + 3.0, e_len, BRIDGE_MAIN_W), shade_col)
	canvas.draw_rect(Rect2(e_x0, c.y - m_hw - 1.2, e_len, BRIDGE_MAIN_W + 2.4), C_STONE_MID)
	canvas.draw_rect(Rect2(e_x0, c.y - m_hw, e_len, BRIDGE_MAIN_W), C_PLAZA_BG)
	canvas.draw_line(Vector2(e_x0, c.y - m_hw), Vector2(e_x1, c.y - m_hw), C_STONE_LIGHT, 1.5)
	canvas.draw_line(Vector2(e_x0, c.y + m_hw), Vector2(e_x1, c.y + m_hw), C_STONE_SHADE, 1.5)
	for gx in range(int(e_x0) + 4, int(e_x1) - 2, 7):
		canvas.draw_line(Vector2(gx, c.y - m_hw + 1), Vector2(gx, c.y + m_hw - 1), C_JOINT, 1.0)

# ─── 6. BỀ MẶT ĐI BỘ & CÂY CẢNH TRÊN VÒNG THÀNH ĐÁ PHÂN CÁCH ───────────────────
# ĐẶC ĐIỂM NỔI BẬT TRONG ẢNH: Vòng thành phân cách có hàng cây cảnh cắt tỉa
# hình khuyên uốn lượn tuyệt đẹp chạy quanh giữa 2 vành nước!
static func _draw_stone_divider_walkway_and_hedges(canvas: CanvasItem, c: Vector2) -> void:
	# Bán kính tim của vành cây cảnh trên vòng thành đá phân cách
	var r_hedge_mid := (R_STONE_RING + R_STONE_INNER) * 0.5 # ≈ 64.0px

	# Vẽ vành đai cây cảnh cắt tỉa hình khuyên chạy dọc vòng thành đá,
	# chừa lối mở thông thoáng tại 8 giao điểm với 8 cây cầu hướng tâm!
	for i in 32:
		var ang := float(i) * TAU / 32.0

		# Kiểm tra xem có trùng với lối đi của 8 cây cầu không
		var is_bridge_crossing := false
		for k in 8:
			var bridge_ang := float(k) * PI * 0.25
			if absf(fposmod(ang - bridge_ang + PI, TAU) - PI) < 0.16:
				is_bridge_crossing = true
				break
		if is_bridge_crossing:
			continue

		var hp := c + Vector2(cos(ang), sin(ang)) * r_hedge_mid

		# Bụi cây tròn cắt tỉa xinh xắn
		canvas.draw_circle(hp + Vector2(0, 1.5), 3.8, C_HEDGE_DARK)
		canvas.draw_circle(hp, 3.4, C_HEDGE_MID)
		canvas.draw_circle(hp + Vector2(-0.8, -0.8), 1.8, C_HEDGE_LIGHT)

		# Hoa đỏ và vàng xen kẽ
		if i % 3 == 0:
			canvas.draw_rect(Rect2(hp.x - 0.6, hp.y - 1.2, 1.4, 1.4), Color("ff3b30"))
		elif i % 3 == 1:
			canvas.draw_rect(Rect2(hp.x + 0.4, hp.y - 0.8, 1.4, 1.4), Color("ffd60a"))

# ─── 7. ĐẢO TRÒN Ở CHÍNH GIỮA CÓ CÂY CẢNH VÀ HOA ──────────────────────────────
static func _draw_central_island(canvas: CanvasItem, c: Vector2) -> void:
	# Bóng bờ kè đảo đổ xuống vành nước trong
	_draw_circle_poly(canvas, c + Vector2(0, 3.2), R_ISLAND + 2.2, Color(0, 0, 0, 0.35), 32)

	# Bờ kè đảo bằng gạch terracotta đỏ nâu nổi bật
	_draw_circle_poly(canvas, c, R_ISLAND + 1.6, C_BRICK_RIM, 32)
	_draw_circle_poly(canvas, c, R_ISLAND, Color("c24836"), 32)
	_draw_circle_poly(canvas, c + Vector2(0, -1), R_ISLAND - 1.2, Color("df6450"), 32)

	# Nền sân đảo trung tâm lát đá màu be sạch sẽ
	_draw_circle_poly(canvas, c, R_ISLAND - 2.8, C_PLAZA_BG, 32)

	# VÀNH ĐAI CÂY CẢNH CẮT TỈA HÌNH KHUYÊN TRÊN ĐẢO (Circular Hedge Ring)
	# Bao quanh bồn phun nước, chừa 8 cửa mở tương ứng 8 cây cầu hướng tâm
	var r_island_hedge := R_ISLAND - 7.5 # ≈ 30.5px
	for i in 24:
		var ang := float(i) * TAU / 24.0

		var is_door := false
		for k in 8:
			var bridge_ang := float(k) * PI * 0.25
			if absf(fposmod(ang - bridge_ang + PI, TAU) - PI) < 0.20:
				is_door = true
				break
		if is_door:
			continue

		var hp := c + Vector2(cos(ang), sin(ang)) * r_island_hedge
		canvas.draw_circle(hp + Vector2(0, 1.4), 3.6, C_HEDGE_DARK)
		canvas.draw_circle(hp, 3.2, C_HEDGE_MID)
		canvas.draw_circle(hp + Vector2(-0.8, -0.8), 1.6, C_HEDGE_LIGHT)

		if i % 2 == 0:
			canvas.draw_rect(Rect2(hp.x - 0.5, hp.y - 1.2, 1.4, 1.4), Color("ff334b"))
		else:
			canvas.draw_rect(Rect2(hp.x + 0.5, hp.y - 0.8, 1.4, 1.4), Color("ffcc00"))

# ─── 8. BỂ PHUN NƯỚC CYAN VÀ ĐÀI PHUN NƯỚC TRUNG TÂM ──────────────────────────
# Bám sát ảnh thực tế: Lòng bể nước màu xanh cyan/ngọc biển rực rỡ nổi bật
static func _draw_fountain_basin_and_jets(canvas: CanvasItem, c: Vector2, clock: float) -> void:
	# Thành bể bát giác viền đá trắng kem nổi khối
	_draw_octagon_poly(canvas, c + Vector2(0, 2.5), R_FOUNTAIN + 3.0, Color(0, 0, 0, 0.28)) # bóng đổ
	_draw_octagon_poly(canvas, c, R_FOUNTAIN + 2.5, C_STONE_DARK)
	_draw_octagon_poly(canvas, c, R_FOUNTAIN + 1.6, C_CYAN_RIM)
	_draw_octagon_poly(canvas, c, R_FOUNTAIN + 1.0, Color.WHITE)

	# LÒNG BỂ MÀU XANH CYAN/AZURE RỰC RỠ ĐẶC TRƯNG TRONG ẢNH
	_draw_octagon_poly(canvas, c, R_FOUNTAIN, C_CYAN_DEEP)
	_draw_octagon_poly(canvas, c, R_FOUNTAIN - 2.0, C_CYAN_MID)
	_draw_octagon_poly(canvas, c, R_FOUNTAIN - 5.0, C_CYAN_LIGHT)

	# Hiệu ứng nước xao động trong bể cyan
	var wave_shift := sin(clock * 4.0) * 1.5
	canvas.draw_line(Vector2(c.x - 8 + wave_shift, c.y - 2), Vector2(c.x + 8 + wave_shift, c.y - 2), Color(1, 1, 1, 0.50), 1.0)
	canvas.draw_line(Vector2(c.x - 6 - wave_shift, c.y + 3), Vector2(c.x + 6 - wave_shift, c.y + 3), Color(1, 1, 1, 0.40), 1.0)

	# Bệ đá trụ phun nước trung tâm (White Marble Pedestal)
	canvas.draw_rect(Rect2(c.x - 4.5, c.y - 5.5, 9, 9), Color("7e8a96"))
	canvas.draw_rect(Rect2(c.x - 3.5, c.y - 6.5, 7, 9), Color("e8eef4"))
	canvas.draw_rect(Rect2(c.x - 2.5, c.y - 7.5, 5, 4), Color.WHITE)

	# CỘT NƯỚC CHÍNH BẮN THẲNG LÊN CAO
	var main_h := 22.0 + sin(clock * 5.0) * 3.8
	var top_pos := Vector2(c.x, c.y - 7.0 - main_h)

	# Cột nước trắng bung bọt
	canvas.draw_line(Vector2(c.x, c.y - 7.0), top_pos, Color("d0f0fd", 0.85), 3.4)
	canvas.draw_line(Vector2(c.x, c.y - 7.0), top_pos, Color.WHITE, 1.8)
	canvas.draw_circle(top_pos, 3.6, Color("e1f5fe", 0.95))
	canvas.draw_circle(top_pos + Vector2(-0.6, -0.6), 2.2, Color.WHITE)

	# 8 TIA NƯỚC VÒNG CUNG BẮN TỎA RA 8 HƯỚNG
	for k in 8:
		var ang := float(k) * PI * 0.25 + clock * 0.20
		var spray_r := 11.0 + sin(clock * 3.5 + float(k)) * 1.8
		var fall_pos := c + Vector2(cos(ang), sin(ang)) * spray_r
		var mid_h := 12.0 + sin(clock * 4.0 + float(k)) * 2.2
		var mid_pos := Vector2.ZERO.lerp(fall_pos - c, 0.5) + c + Vector2(0, -mid_h)

		canvas.draw_line(Vector2(c.x, c.y - 7.0), mid_pos, Color(C_FOUNT_SPRAY, 0.88), 1.4)
		canvas.draw_line(mid_pos, fall_pos, Color(C_FOUNT_SPRAY, 0.72), 1.1)
		canvas.draw_circle(fall_pos, 1.8, Color(1, 1, 1, 0.85))
		canvas.draw_circle(fall_pos + Vector2(0.5, -0.5), 0.9, Color.WHITE)

	# Bọt nước li ti bay trong không khí
	for i in 8:
		var ph := fmod(clock * 1.8 + float(i) * 0.125, 1.0)
		var sp_y := top_pos.y + ph * main_h * 0.85
		var sp_x := c.x + sin(float(i) * 2.1 + clock * 3.0) * (ph * 7.5)
		canvas.draw_rect(Rect2(sp_x, sp_y, 1.4, 1.4), Color(1.0, 1.0, 1.0, 1.0 - ph))

# ─── 9. CẢNH QUAN CÂY XANH (HÀNG CAU VUA VÀ GHẾ ĐÁ CÔNG VIÊN) ─────────────────
static func _draw_park_landscaping(canvas: CanvasItem, c: Vector2) -> void:
	# Hai hàng cây cau vua thẳng tắp đối xứng dọc lối vào Nam (chuẩn ảnh thực tế!)
	for row in 3:
		var py := c.y + R_PLAZA + 8.0 + float(row) * 17.0
		_draw_palm_tree(canvas, Vector2(c.x - 18.0, py), 0.88)
		_draw_palm_tree(canvas, Vector2(c.x + 18.0, py), 0.88)

	# Các cây cau vua đứng ở các góc ngoài quảng trường
	for k in [1, 3, 5, 7]:
		var ang: float = float(k) * PI * 0.25
		var pp := c + Vector2(cos(ang), sin(ang)) * (R_PLAZA + 12.0)
		_draw_palm_tree(canvas, pp, 0.92)

	# Hàng rào cây xanh cắt tỉa gọn gàng ở 2 bên lối vào Nam
	_draw_neat_hedge(canvas, c.x - 14.0 - 28.0, c.y + R_PLAZA + 4.0, 28.0)
	_draw_neat_hedge(canvas, c.x + 14.0,        c.y + R_PLAZA + 4.0, 28.0)

	# Các băng ghế đá công viên trên quảng trường (đặt ở các cung tròn)
	_draw_park_bench(canvas, Vector2(c.x - 72.0, c.y + 72.0), 0.0)
	_draw_park_bench(canvas, Vector2(c.x + 72.0, c.y + 72.0), 0.0)
	_draw_park_bench(canvas, Vector2(c.x - 72.0, c.y - 72.0), 0.0)
	_draw_park_bench(canvas, Vector2(c.x + 72.0, c.y - 72.0), 0.0)

# ─── HELPER: VẼ HÌNH TRÒN POLYGON ĐỀU ĐỒNG TÂM ────────────────────────────────
static func _circle_polygon(c: Vector2, r: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

static func _draw_circle_poly(canvas: CanvasItem, c: Vector2, r: float, col: Color, n: int = 32) -> void:
	canvas.draw_colored_polygon(_circle_polygon(c, r, n), col)

static func _draw_circle_outline(canvas: CanvasItem, c: Vector2, r: float, col: Color, width: float = 1.0, n: int = 32) -> void:
	var pts := _circle_polygon(c, r, n)
	pts.append(pts[0])
	canvas.draw_polyline(pts, col, width)

# ─── HELPER: VẼ HÌNH BÁT GIÁC ĐỀU CHO BỂ NƯỚC TRUNG TÂM ───────────────────────
static func _octagon_polygon(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := PI * 0.125 + float(i) * PI * 0.25
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

static func _draw_octagon_poly(canvas: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	canvas.draw_colored_polygon(_octagon_polygon(c, r), col)

# ─── HELPER: CÂY CAU VUA, GHẾ ĐÁ, HÀNG RÀO TỈA ──────────────────────────────
static func _draw_palm_tree(canvas: CanvasItem, pos: Vector2, s: float = 1.0) -> void:
	var p := pos
	canvas.draw_colored_polygon(_oval(p + Vector2(3 * s, 1.5 * s), 7 * s, 3 * s, 12), Color(0, 0, 0, 0.18))
	var trunk_h := 22.0 * s
	var tw := 3.0 * s
	var top := p + Vector2(0, -trunk_h)
	canvas.draw_rect(Rect2(p.x - tw * 0.5, top.y, tw, trunk_h), Color("a8a296"))
	canvas.draw_rect(Rect2(p.x - tw * 0.5 + 0.5 * s, top.y, 1.0 * s, trunk_h), Color("dcd6c8"))
	for k in 5:
		var ring_y := top.y + float(k + 1) * (trunk_h / 6.0)
		canvas.draw_line(Vector2(p.x - tw * 0.5, ring_y), Vector2(p.x + tw * 0.5, ring_y), Color("767064"), 1.0)
	canvas.draw_rect(Rect2(p.x - tw * 0.5, top.y - 3 * s, tw, 3 * s), Color("4aa246"))
	for a: float in [-3.0, -2.4, -1.8, -1.3, -0.7, -0.15, 0.35, -3.4]:
		var frond_tip := top + Vector2.from_angle(a) * (14.0 * s) + Vector2(0, 3.5 * s)
		canvas.draw_line(top, frond_tip, Color("256b2c"), 2.8 * s)
		canvas.draw_line(top, frond_tip + Vector2(0, -0.8 * s), Color("4fb554"), 1.6 * s)

static func _draw_neat_hedge(canvas: CanvasItem, x: float, y: float, w: float) -> void:
	canvas.draw_rect(Rect2(x, y + 5.0, w, 3.0), Color(0, 0, 0, 0.16))
	canvas.draw_rect(Rect2(x, y, w, 6.0), Color("286b2c"))
	canvas.draw_rect(Rect2(x, y, w, 2.5), Color("48b34e"))
	for i in range(2, int(w) - 2, 5):
		canvas.draw_rect(Rect2(x + float(i), y - 0.5, 3.0, 1.5), Color("6ed874"))

static func _draw_park_bench(canvas: CanvasItem, pos: Vector2, _rot: float = 0.0) -> void:
	var p := pos
	# Bóng đổ
	canvas.draw_colored_polygon(_oval(p + Vector2(0, 2), 7.0, 2.5, 8), Color(0, 0, 0, 0.20))
	# Chân ghế
	canvas.draw_rect(Rect2(p.x - 5, p.y - 3, 2, 4), C_BENCH_LEG)
	canvas.draw_rect(Rect2(p.x + 3, p.y - 3, 2, 4), C_BENCH_LEG)
	# Mặt ghế ngồi
	canvas.draw_rect(Rect2(p.x - 6, p.y - 5, 12, 3), C_BENCH_WOOD)
	canvas.draw_line(Vector2(p.x - 6, p.y - 5), Vector2(p.x + 6, p.y - 5), Color("c48b52"), 1.0)

static func _oval(c: Vector2, rx: float, ry: float, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

# ─── HỆ THỐNG VA CHẠM (COLLISION): CHẶN NƯỚC, CHỪ CẦU VÀ ĐẢO ─────────────────
static func collision_rects(c: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []

	# 1. Bể phun nước trung tâm (vật cản tuyệt đối)
	out.append(Rect2(c.x - R_FOUNTAIN - 2.0, c.y - R_FOUNTAIN - 2.0, (R_FOUNTAIN + 2.0) * 2.0, (R_FOUNTAIN + 2.0) * 2.0))

	# 2. Chặn các vành nước bằng lưới ô nhỏ, bỏ qua 4 cầu trục và 4 cầu chéo
	# Đảo (<= R_ISLAND) và vòng đá phân cách (R_STONE_INNER..R_STONE_RING) đi bộ tự do.
	var step := 4.0
	var max_r := R_WATER1_OUT
	var start_x := c.x - max_r
	var start_y := c.y - max_r
	var x := start_x
	while x < c.x + max_r:
		var y := start_y
		while y < c.y + max_r:
			var cx := x + step * 0.5
			var cy := y + step * 0.5
			if _is_water_blocked(cx - c.x, cy - c.y):
				out.append(Rect2(x, y, step, step))
			y += step
		x += step

	return out

static func _is_water_blocked(dx: float, dy: float) -> bool:
	var r := sqrt(dx * dx + dy * dy)
	if r < R_FOUNTAIN + 2.0:
		return false # đã có khối chặn bể trung tâm
	if r <= R_ISLAND:
		return false # đảo trung tâm
	if r >= R_STONE_INNER and r <= R_STONE_RING:
		return false # vòng thành đá đi bộ
	var in_inner_water := r > R_WATER2_IN and r < R_WATER2_OUT
	var in_outer_water := r > R_WATER1_IN and r < R_WATER1_OUT
	if not in_inner_water and not in_outer_water:
		return false

	var half_main := BRIDGE_MAIN_W * 0.5
	if absf(dx) <= half_main or absf(dy) <= half_main:
		return false # 4 cầu trục chính

	var half_spoke := BRIDGE_SPOKE_W * 0.5
	var inv_sqrt2 := 0.70710678
	# 4 cầu chéo tại ±45°: khoảng cách vuông góc tới trục cầu
	if absf(-dx * inv_sqrt2 + dy * inv_sqrt2) <= half_spoke:
		return false
	if absf(dx * inv_sqrt2 + dy * inv_sqrt2) <= half_spoke:
		return false

	return true
