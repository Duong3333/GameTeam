class_name Walkway
extends RefCounted
# MÁI VÒM HÀNH LANG KHUNG THÉP XANH - HCMUS ĐÔNG HÒA
#
# GÓC NHÌN: Camera2D không xoay, không zoom (khung nhìn 480x270, phóng 2.67x kiểu pixel-art),
# công trình vẽ theo kiểu "nhìn chếch từ phía nam": chiều cao = dịch lên trên (y nhỏ hơn).
# Hành lang chạy dọc theo trục X, nên mặt phẳng của mỗi khung vòm bán nguyệt vuông góc với X
# => nhìn từ camera chỉ thấy khung vòm "đứng cạnh", tức là một THANH NGANG MÁI (vạch dọc màn hình),
# KHÔNG BAO GIỜ là hình tròn. Vòng tròn chỉ đúng khi nhìn dọc theo trục hành lang.
#
# CẤU TRÚC (mỗi phần là một hàm riêng, dễ chỉnh):
#   NỀN  (vẽ trong draw_ground, TRƯỚC nhân vật):
#     _draw_pavement()     nền gạch + viền đá
#     _draw_ground_frame() bóng mái đổ xuống nền + đế chân khung
#   MÁI  (vẽ sau draw_sorted_items, SAU nhân vật -> che đầu người đi dưới mái):
#     _draw_shell()        dải mái liên tục trắng/kem, có đổ bóng hình trụ
#     _draw_legs()         chân đỡ + tai giằng của khung vòm (nối mái xuống đế)
#     _draw_rib()          thanh thép xanh đậm chạy ngang mái, cách đều nhau
#   Khi người chơi đứng dưới mái, mái tự mờ đi một đoạn quanh người (tham số focus).
#
# CÁCH GỌI (chữ ký cũ vẫn dùng được, tham số focus là tùy chọn):
#   Walkway.draw_walkway_ground(self, x1, x2, y, view)                  # trong draw_ground()
#   Walkway.draw_walkway_roof(self, x1, x2, y, view, player)            # sau draw_sorted_items()
# y = mép trên của lối đi; lối đi rộng WALKWAY_H px; khung đặt cách đều nhau ~UNIT_W px,
# hai đầu luôn có khung (khoảng cách được chia đều cho khớp chiều dài).

const UNIT_W := 24.0         # Khoảng cách chuẩn giữa 2 khung vòm
const WALKWAY_H := 18.0      # Chiều rộng lòng hành lang (bắc -> nam)
const ROOF_TOP := -14.0      # Đỉnh mái so với mép trên lối đi (âm = nằm cao hơn trên màn hình)
const SHELL_H := 18.0        # Bề cao của dải mái trên màn hình (mép dưới mái = y + 4)
const FADE_ALPHA := 0.45     # Độ đặc của mái ngay trên đầu người chơi
const NO_FOCUS := Vector2(-1.0e9, -1.0e9)

# Thép sơn xanh lá đậm
const C_STEEL_DARK  := Color("0f4a27")
const C_STEEL_MID   := Color("17622f")
const C_STEEL_LIGHT := Color("3d9a5a")   # vệt sáng kim loại (chỉ dùng mờ)
# Tấm lợp trắng xám / kem nhạt
const C_ROOF_HI     := Color("f8f6ec")   # sống mái nhận nắng
const C_ROOF_LIGHT  := Color("ece9db")
const C_ROOF_MID    := Color("dcd8c6")
const C_ROOF_LOW    := Color("c9c5b1")   # phần mái cong xuống, tối hơn
const C_ROOF_SEAM   := Color("b6b29d")   # mối ghép tấm lợp
# Nền gạch
const C_PAVE_LIGHT  := Color("dfd2b5")
const C_PAVE_DARK   := Color("c8b894")
const C_PAVE_LINE   := Color("b3a17a")

# ─── HÀM GỌI CHO CẢ DẢI (dùng trong draw_ground / sau draw_sorted_items) ────

static func draw_walkway_ground(cv: CanvasItem, start_x: float, end_x: float, y: float, view: Rect2) -> void:
	if not view.intersects(Rect2(start_x - 4.0, y - 2.0, end_x - start_x + 8.0, WALKWAY_H + 4.0)):
		return
	var n := _bay_count(start_x, end_x)
	var bw := (end_x - start_x) / float(n)
	for i in n:
		var bx := start_x + float(i) * bw
		if bx + bw < view.position.x - 4.0 or bx > view.end.x + 4.0:
			continue
		draw_ground_segment(cv, Vector2(bx, y), bw)
	if end_x >= view.position.x - 4.0 and end_x <= view.end.x + 4.0:
		_draw_ground_frame(cv, roundf(end_x), y)

# focus = vị trí chân người chơi (tùy chọn). Đứng dưới mái thì đoạn mái phía trên đầu mờ đi.
static func draw_walkway_roof(cv: CanvasItem, start_x: float, end_x: float, y: float, view: Rect2, focus: Vector2 = NO_FOCUS) -> void:
	if not view.intersects(Rect2(start_x - 4.0, y + ROOF_TOP - 3.0, end_x - start_x + 8.0, WALKWAY_H - ROOF_TOP + 4.0)):
		return
	var n := _bay_count(start_x, end_x)
	var bw := (end_x - start_x) / float(n)
	for i in n:
		var bx := start_x + float(i) * bw
		if bx + bw < view.position.x - 4.0 or bx > view.end.x + 4.0:
			continue
		draw_roof_segment(cv, Vector2(bx, y), bw, _fade(bx + bw * 0.5, y, focus))
	if end_x >= view.position.x - 4.0 and end_x <= view.end.x + 4.0:
		_draw_frame(cv, roundf(end_x), y, _fade(end_x, y, focus))

# ─── 1 NHỊP (từ khung này tới khung kế tiếp) ────────────────────────────────

# NỀN: gạch + bóng mái + đế chân khung bên trái của nhịp
static func draw_ground_segment(cv: CanvasItem, pos: Vector2, bay_w: float = UNIT_W) -> void:
	var x0 := roundf(pos.x)
	var x1 := roundf(pos.x + bay_w)
	_draw_pavement(cv, x0, x1, pos.y)
	_draw_ground_frame(cv, x0, pos.y)

# MÁI: dải mái + chân + thanh thép ngang mái bên trái của nhịp. alpha < 1 để mái mờ đi.
static func draw_roof_segment(cv: CanvasItem, pos: Vector2, bay_w: float = UNIT_W, alpha: float = 1.0) -> void:
	var x0 := roundf(pos.x)
	var x1 := roundf(pos.x + bay_w)
	_draw_shell(cv, x0, x1, pos.y, alpha)
	_draw_frame(cv, x0, pos.y, alpha)

# ─── THÀNH PHẦN NỀN ─────────────────────────────────────────────────────────

static func _draw_pavement(cv: CanvasItem, x0: float, x1: float, y: float) -> void:
	# Đã xóa phần gạch nền theo yêu cầu, chỉ giữ bóng mờ nhẹ của mái đổ xuống vỉa hè
	var w := x1 - x0
	cv.draw_rect(Rect2(x0, y + 1.0, w, WALKWAY_H - 3.0), Color(0.04, 0.12, 0.07, 0.10))

# Bóng thanh thép trên nền (vạch sáng-tối đều nhau) + đế chân khung phía nam
static func _draw_ground_frame(cv: CanvasItem, x: float, y: float) -> void:
	cv.draw_rect(Rect2(x + 1.0, y + 2.0, 2.0, WALKWAY_H - 5.0), Color(0.03, 0.10, 0.05, 0.16))
	cv.draw_rect(Rect2(x - 3.0, y + WALKWAY_H - 3.0, 6.0, 3.0), C_STEEL_DARK)
	cv.draw_rect(Rect2(x - 2.0, y + WALKWAY_H - 3.0, 4.0, 1.0), C_STEEL_MID)

# ─── THÀNH PHẦN MÁI ─────────────────────────────────────────────────────────

# Dải mái liên tục: sống mái sáng ở trên, tối dần xuống mép (hình trụ), hai thanh dọc xanh ở đỉnh và mép
static func _draw_shell(cv: CanvasItem, x0: float, x1: float, y: float, a: float) -> void:
	var w := x1 - x0
	var top := y + ROOF_TOP
	# [dịch xuống từ đỉnh, bề cao, màu]  (tổng bề cao = SHELL_H = 18)
	var rows: Array = [
		[0.0, 1.0, C_STEEL_MID],     # xà dọc đỉnh mái
		[1.0, 1.0, C_ROOF_HI],
		[2.0, 4.0, C_ROOF_LIGHT],
		[6.0, 5.0, C_ROOF_MID],
		[11.0, 4.0, C_ROOF_LOW],
		[15.0, 1.0, C_ROOF_SEAM],
		[16.0, 1.0, C_STEEL_MID],    # xà dọc mép mái
		[17.0, 1.0, C_STEEL_DARK],
	]
	for r in rows:
		var oy: float = r[0]
		var rh: float = r[1]
		var rcol: Color = r[2]
		cv.draw_rect(Rect2(x0, top + oy, w, rh), _a(rcol, a))
	# vệt phản chiếu và mối ghép tấm lợp giữa nhịp
	cv.draw_rect(Rect2(x0 + w * 0.15, top + 2.0, w * 0.35, 1.0), Color(1, 1, 1, 0.55 * a))
	cv.draw_rect(Rect2(roundf(x0 + w * 0.5), top + 1.0, 1.0, 15.0), _a(C_ROOF_SEAM, 0.55 * a))
	# bóng mái đổ ngay dưới mép
	cv.draw_rect(Rect2(x0, top + SHELL_H, w, 1.0), Color(0, 0, 0, 0.22 * a))

# Khung vòm = chân đỡ + thanh ngang mái (vẽ chân trước, thanh sau để thanh đè lên mối nối)
static func _draw_frame(cv: CanvasItem, x: float, y: float, a: float) -> void:
	_draw_legs(cv, x, y, a)
	_draw_rib(cv, x, y, a)

# Thanh thép xanh đậm vắt ngang mái (một cung của vòm nhìn nghiêng)
static func _draw_rib(cv: CanvasItem, x: float, y: float, a: float) -> void:
	var top := y + ROOF_TOP - 1.0
	var h := SHELL_H + 1.0
	cv.draw_rect(Rect2(x - 1.0, top, 2.0, h), _a(C_STEEL_DARK, a))
	cv.draw_rect(Rect2(x - 1.0, top + 1.0, 1.0, h - 2.0), _a(C_STEEL_MID, a))
	cv.draw_rect(Rect2(x - 1.0, top + 3.0, 1.0, h - 7.0), _a(C_STEEL_LIGHT, 0.35 * a))
	# mối nối đỉnh vòm
	cv.draw_rect(Rect2(x - 2.0, top, 4.0, 2.0), _a(C_STEEL_DARK, a))
	cv.draw_rect(Rect2(x - 2.0, top, 4.0, 1.0), _a(C_STEEL_MID, a))
	# bóng thanh đổ lên tấm lợp bên phải
	cv.draw_rect(Rect2(x + 1.0, top + 2.0, 1.0, h - 4.0), Color(0.03, 0.10, 0.05, 0.20 * a))

# Chân khung phía nam (từ mép mái xuống đế) + tai giằng tam giác ở chỗ nối với mái
static func _draw_legs(cv: CanvasItem, x: float, y: float, a: float) -> void:
	var la := maxf(a, 0.75)
	var top := y + ROOF_TOP + SHELL_H          # ngay dưới mép mái
	var h := y + WALKWAY_H - 2.0 - top
	cv.draw_rect(Rect2(x - 1.0, top, 2.0, h), _a(C_STEEL_DARK, la))
	cv.draw_rect(Rect2(x - 1.0, top, 1.0, h), _a(C_STEEL_MID, la))
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 1.0, top + 5.0), Vector2(x - 4.0, top), Vector2(x - 1.0, top)
	]), _a(C_STEEL_DARK, la))
	cv.draw_colored_polygon(PackedVector2Array([
		Vector2(x + 1.0, top + 5.0), Vector2(x + 4.0, top), Vector2(x + 1.0, top)
	]), _a(C_STEEL_DARK, la))

# ─── TIỆN ÍCH ───────────────────────────────────────────────────────────────

# Số nhịp (chia đều chiều dài để khung hai đầu khớp, khoảng cách ~UNIT_W)
static func _bay_count(start_x: float, end_x: float) -> int:
	return maxi(1, roundi((end_x - start_x) / UNIT_W))

static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

# Hệ số đặc của mái: mờ dần khi người chơi đứng dưới/gần mái
static func _fade(cx: float, y: float, focus: Vector2) -> float:
	if focus.y < y + ROOF_TOP or focus.y > y + WALKWAY_H + 6.0:
		return 1.0
	var d := clampf(absf(focus.x - cx) / (UNIT_W * 1.5), 0.0, 1.0)
	return lerpf(FADE_ALPHA, 1.0, d * d)
