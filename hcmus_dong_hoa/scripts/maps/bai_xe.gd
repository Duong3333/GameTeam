class_name BaiXe
extends RefCounted
# BÃI GIỮ XE MÁY HCMUS — Module vẽ riêng bãi giữ xe máy sinh viên khuôn viên trường.
# Sử dụng cho cả Bãi xe số 1 (cổng) và Bãi xe số 2 (kế bên phải Nhà Thể Dục).
# Dùng: BaiXe.draw(canvas, rect, label, bay_w, roofs)

# ─── MÀU SẮC ────────────────────────────────────────────────────────────────
const C_ASPHALT     := Color("454a52")
const C_STRIPE      := Color(1.0, 1.0, 1.0, 0.4)
const C_ROOF_DARK   := Color("4a8cae")
const C_ROOF_LIGHT  := Color("7cc4e2")
const C_ROOF_EDGE   := Color("2a6b8c")
const C_ROOF_POST   := Color("3a6580")
const C_BORDER      := Color("333840")
const C_LANE_LINE   := Color("5a606d")

# Bảng màu xe máy phong phú của sinh viên (Wave, Vision, Exciter, AirBlade, v.v.)
const MOTO_COLORS: Array[Color] = [
	Color("c02828"), # Đỏ đô
	Color("2255aa"), # Xanh GP Yamaha
	Color("282828"), # Đen bóng
	Color("ededed"), # Trắng ngọc trai
	Color("707880"), # Xám xi măng thời thượng
	Color("226644"), # Xanh rêu
	Color("d88020"), # Cam thể thao
	Color("b8a038"), # Vàng cát
	Color("3a7a9a"), # Xanh đá
	Color("4a3055"), # Tím mận
]

# ─── HÀM VẼ CHÍNH ───────────────────────────────────────────────────────────
static func draw(
	canvas: CanvasItem,
	rect: Rect2,
	label: String,
	bay_w: float = 13.0,
	roofs: Array = [2.0, 85.0]
) -> void:
	_draw_ground(canvas, rect)
	_draw_moto_lanes(canvas, rect, bay_w)
	_draw_roofs(canvas, rect, roofs)
	_draw_label_bar(canvas, rect, label)

# ─── NỀN NHỰA + ĐƯỜNG PHÂN LÀN ──────────────────────────────────────────────
static func _draw_ground(canvas: CanvasItem, r: Rect2) -> void:
	canvas.draw_rect(r, C_ASPHALT)
	# Vạch phân làn dọc mờ (lối đi bộ chia các khu)
	var lx := r.position.x + 65.0
	while lx < r.end.x - 20.0:
		canvas.draw_line(Vector2(lx, r.position.y), Vector2(lx, r.end.y - 14.0), C_LANE_LINE, 1.0)
		lx += 65.0
	# Viền bê tông bao quanh bãi xe
	canvas.draw_rect(r, C_BORDER, false, 2.0)

# ─── CÁC HÀNG XE MÁY SINH VIÊN ─────────────────────────────────────────────
static func _draw_moto_lanes(canvas: CanvasItem, r: Rect2, bay_w: float) -> void:
	var row_h := 24.0   # chiều dài 1 xe máy
	var gap   := 14.0   # lối đi bộ giữa 2 hàng xe
	var row_y := r.position.y + 16.0
	var row_idx := 0

	while row_y + row_h < r.end.y - 14.0:
		_draw_moto_row(canvas, r, row_y, row_h, bay_w, row_idx)
		row_y += row_h + gap
		row_idx += 1

	# Lối đi bê tông chính ở chân bãi xe
	canvas.draw_rect(Rect2(r.position.x, r.end.y - 14.0, r.size.x, 14.0), Color("3d424a"))

static func _draw_moto_row(canvas: CanvasItem, r: Rect2, row_y: float, row_h: float, bay_w: float, row_idx: int) -> void:
	var bx := r.position.x + 8.0
	var moto_idx := 0

	while bx + bay_w < r.end.x - 8.0:
		# Vạch kẻ sơn trắng chia từng ô xe máy
		canvas.draw_rect(Rect2(bx, row_y, 1.0, row_h), C_STRIPE)

		# 85% các ô có xe máy đỗ (chừa vài ô trống tạo độ chân thực)
		var hash_val := int(bx * 7.3 + row_y * 13.1 + row_idx * 17.0)
		if hash_val % 7 != 0:
			_draw_one_motorcycle(canvas, bx + 1.5, row_y + 1.0, hash_val)

		bx += bay_w
		moto_idx += 1

# ─── VẼ 1 CHIẾC XE MÁY TOP-DOWN VIEW ────────────────────────────────────────
static func _draw_one_motorcycle(canvas: CanvasItem, x: float, y: float, hash_seed: int) -> void:
	var col_idx := absi(hash_seed) % MOTO_COLORS.size()
	var body_col: Color = MOTO_COLORS[col_idx]
	var is_brown_seat := (hash_seed % 4 == 0)
	var seat_col: Color = Color("4a2e18") if is_brown_seat else Color("1a1a1a")

	# 1. Bóng đổ dưới gầm xe
	canvas.draw_rect(Rect2(x + 1.0, y + 2.0, 8.0, 19.0), Color(0.0, 0.0, 0.0, 0.22))

	# 2. Bánh trước (cao su đen)
	canvas.draw_rect(Rect2(x + 3.5, y, 2.0, 4.0), Color("202020"))

	# 3. Dè chắn bùn trước + chóa đèn
	canvas.draw_rect(Rect2(x + 2.5, y + 2.0, 4.0, 3.5), body_col)
	# Đèn pha trước sáng
	canvas.draw_rect(Rect2(x + 3.5, y + 1.5, 2.0, 1.5), Color("fff8c8"))

	# 4. Ghi đông / tay lái ngang (kim loại đen)
	canvas.draw_rect(Rect2(x + 0.5, y + 4.0, 8.0, 1.5), Color("151515"))
	# 2 gương chiếu hậu tròn nhỏ 2 bên
	canvas.draw_rect(Rect2(x, y + 3.0, 1.5, 1.5), Color("303030"))
	canvas.draw_rect(Rect2(x + 7.5, y + 3.0, 1.5, 1.5), Color("303030"))

	# 5. Yếm xe / dàn áo giữa
	canvas.draw_rect(Rect2(x + 2.0, y + 5.5, 5.0, 4.5), body_col)
	# Vạch decal bóng trên dàn áo
	canvas.draw_rect(Rect2(x + 2.5, y + 6.0, 1.0, 3.0), Color(1.0, 1.0, 1.0, 0.35))

	# 6. Sàn để chân / cụm máy
	canvas.draw_rect(Rect2(x + 1.5, y + 8.5, 6.0, 2.5), Color("2e2e2e"))

	# 7. Yên xe dài bọc da (yên đen hoặc nâu da bò)
	canvas.draw_rect(Rect2(x + 2.5, y + 10.5, 4.0, 8.0), seat_col)
	# Viền sáng chỉ may trên yên xe
	canvas.draw_rect(Rect2(x + 3.0, y + 11.0, 1.0, 7.0), Color(1.0, 1.0, 1.0, 0.15))

	# 8. Cản tay dắt sau (kim loại bạc)
	canvas.draw_rect(Rect2(x + 2.5, y + 18.0, 4.0, 1.5), Color("889098"))

	# 9. Đèn hậu đỏ phía đuôi
	canvas.draw_rect(Rect2(x + 3.5, y + 18.5, 2.0, 1.5), Color("e02424"))

	# 10. Bánh sau
	canvas.draw_rect(Rect2(x + 3.5, y + 19.5, 2.0, 3.5), Color("202020"))

# ─── MÁI CHE KHUNG DẦM THOÁNG (nhìn thấy xe máy bên dưới) ───────────────────
static func _draw_roofs(canvas: CanvasItem, r: Rect2, roofs: Array) -> void:
	for y_off in roofs:
		var ry: float = r.position.y + float(y_off)
		# Bóng mái che dầm
		canvas.draw_rect(Rect2(r.position.x + 2.0, ry + 7.0, r.size.x, 6.0), Color(0.0, 0.0, 0.0, 0.16))
		# Thanh dầm ngang kim loại (màu xanh lam hiện đại)
		canvas.draw_rect(Rect2(r.position.x, ry,       r.size.x, 8.0), C_ROOF_DARK)
		canvas.draw_rect(Rect2(r.position.x, ry,       r.size.x, 2.5), C_ROOF_LIGHT)
		canvas.draw_rect(Rect2(r.position.x, ry + 7.0, r.size.x, 1.0), C_ROOF_EDGE)
		# Cột đỡ thép cách đều 70px
		var px := r.position.x + 18.0
		while px < r.end.x - 10.0:
			canvas.draw_rect(Rect2(px - 1.5, ry + 8.0, 3.0, 12.0), C_ROOF_POST)
			canvas.draw_rect(Rect2(px - 0.5, ry + 8.0, 1.0, 12.0), Color(C_ROOF_LIGHT, 0.5))
			px += 70.0

# ─── BẢNG TÊN BÃI XE ───────────────────────────────────────────────────────
static func _draw_label_bar(canvas: CanvasItem, r: Rect2, label: String) -> void:
	var lh := 14.0
	var ly := r.end.y - lh
	canvas.draw_rect(Rect2(r.position.x, ly, r.size.x, lh), Color(0.0, 0.0, 0.0, 0.5))
	canvas.draw_line(Vector2(r.position.x, ly), Vector2(r.end.x, ly), C_ROOF_LIGHT, 1.5)
