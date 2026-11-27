extends "res://scripts/features/feature.gd"
# CÂY ATM HCMUS — Module bản đồ riêng (scripts/maps/atm.gd)
# Đặt tại lối đi bộ trước Tòa C, làm cảnh trang trí khuôn viên.

const BOOTH_POS   := Vector2(540.0, 782.0)
const BOOTH_SIZE  := Vector2(36.0, 40.0)
const BOOTH_RECT  := Rect2(BOOTH_POS, BOOTH_SIZE)
const SOLID_RECT  := Rect2(BOOTH_POS.x - 3.0, BOOTH_POS.y, BOOTH_SIZE.x + 6.0, BOOTH_SIZE.y + 3.0)

func _ready() -> void:
	# Thêm va chạm phủ cả bậc thềm để người chơi không đi xuyên qua buồng ATM
	if game != null and "solids" in game:
		game.solids.append(SOLID_RECT)

func get_sort_y() -> float:
	return BOOTH_POS.y + BOOTH_SIZE.y + 2.0

# ─── VẼ BUỒNG ATM LÊN BẢN ĐỒ (THEO Y-SORT) ─────────────────────────────────
func draw_booth() -> void:
	if game == null:
		return
	var bx := BOOTH_RECT.position.x
	var by := BOOTH_RECT.position.y
	var bw := BOOTH_RECT.size.x
	var bh := BOOTH_RECT.size.y

	# Chỉ vẽ khi nằm trong khung nhìn
	if "view" in game and not game.view.intersects(BOOTH_RECT.grow(50.0)):
		return

	# 1. Bóng đổ dưới chân buồng
	game.draw_rect(Rect2(bx - 2, by + bh - 2, bw + 4, 8), Color(0, 0, 0, 0.28))

	# 2. Bậc thềm đá hoa cương xám
	game.draw_rect(Rect2(bx - 3, by + bh - 4, bw + 6, 6), Color("505860"))
	game.draw_rect(Rect2(bx - 2, by + bh - 4, bw + 4, 2), Color("788088"))

	# 3. Thân buồng ATM: vách kim loại + kính cường lực
	game.draw_rect(Rect2(bx, by + 10, bw, bh - 14), Color("2b3842")) # khung nhôm đen
	# Vách kính cường lực xanh ngọc phản quang
	game.draw_rect(Rect2(bx + 2, by + 12, bw - 4, bh - 18), Color("3d8c82", 0.85))
	# Vệt sáng phản chiếu trên kính
	game.draw_line(Vector2(bx + 5, by + 14), Vector2(bx + 16, by + bh - 10), Color(1, 1, 1, 0.3), 1.5)

	# 4. Máy ATM bên trong buồng kính
	var mx := bx + 7.0
	var my := by + 15.0
	var mw := bw - 14.0
	# Thân cây máy
	game.draw_rect(Rect2(mx, my, mw, bh - 20), Color("808a94"))
	# Màn hình LCD phát sáng xanh dương
	game.draw_rect(Rect2(mx + 2, my + 3, mw - 4, 9), Color("1565c0"))
	game.draw_rect(Rect2(mx + 3, my + 4, mw - 6, 3), Color("64b5f6", 0.7))
	# Bàn phím số kim loại
	game.draw_rect(Rect2(mx + 3, my + 14, mw - 6, 4), Color("3a4048"))
	for dot in 3:
		game.draw_rect(Rect2(mx + 5 + dot * 4, my + 15, 2, 2), Color("d0d8e0"))
	# Khe nhét thẻ phát sáng xanh lá
	game.draw_rect(Rect2(mx + mw - 5, my + 10, 3, 1.5), Color("2ecc71"))
	# Khe trả tiền phía dưới
	game.draw_rect(Rect2(mx + 4, my + 19, mw - 8, 2), Color("1a1a1a"))

	# 5. Khung cửa và cột bo góc buồng
	game.draw_rect(Rect2(bx, by + 10, 2, bh - 14), Color("8a94a0"))
	game.draw_rect(Rect2(bx + bw - 2, by + 10, 2, bh - 14), Color("8a94a0"))

	# 6. HỘP ĐÈN BIỂN HIỆU TRÊN NÓC (Biển hiệu ATM Agribank/Vietcombank đỏ/xanh chuẩn)
	var sign_h := 13.0
	game.draw_rect(Rect2(bx - 2, by, bw + 4, sign_h), Color("c02828")) # nền đỏ ngân hàng
	game.draw_rect(Rect2(bx - 2, by, bw + 4, 2), Color("e74c3c"))     # viền sáng trên
	game.draw_rect(Rect2(bx - 2, by + sign_h - 1, bw + 4, 1), Color("8a1a1a")) # viền dưới
	# Viền vàng kim 2 bên
	game.draw_rect(Rect2(bx - 2, by, 2, sign_h), Color("f1c40f"))
	game.draw_rect(Rect2(bx + bw + 2, by, 2, sign_h), Color("f1c40f"))

	# Vẽ chữ "ATM" pixel art màu trắng sắc sảo ở giữa biển
	var ax := bx + 7.0
	var ay := by + 2.5
	_draw_pixel_atm_logo(ax, ay)

# ─── VẼ CHỮ "ATM" PIXEL ART ────────────────────────────────────────────────
func _draw_pixel_atm_logo(x: float, y: float) -> void:
	var c := Color.WHITE
	var S := 1.5

	# 'A' (5x6)
	var A_dots := [[1,0],[2,0],[3,0],[0,1],[4,1],[0,2],[1,2],[2,2],[3,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5]]
	for d in A_dots:
		game.draw_rect(Rect2(x + d[0] * S, y + d[1] * S, S, S), c)

	# 'T' (5x6)
	var tx := x + 6.0 * S + 2.0
	var T_dots := [[0,0],[1,0],[2,0],[3,0],[4,0],[2,1],[2,2],[2,3],[2,4],[2,5]]
	for d in T_dots:
		game.draw_rect(Rect2(tx + d[0] * S, y + d[1] * S, S, S), c)

	# 'M' (5x6)
	var mx := tx + 6.0 * S + 2.0
	var M_dots := [[0,0],[4,0],[0,1],[1,1],[3,1],[4,1],[0,2],[2,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5]]
	for d in M_dots:
		game.draw_rect(Rect2(mx + d[0] * S, y + d[1] * S, S, S), c)
