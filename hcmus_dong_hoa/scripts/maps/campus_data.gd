extends Node2D
# DỮ LIỆU KHUÔN VIÊN GỐC - sửa bản đồ cơ sở tại đây.
# Muốn dời tòa nhà: sửa bảng BUILDINGS (x, y, rộng, cao). Quầy nhỏ: KIOSKS. Khu vực hiện tên: ZONES.
# Câu NPC hay nói: LINES.

const WORLD := Vector2(2500, 1500)
const SPEED := 70.0
const GATE_X := 1262.0
const GATE_W := 120.0
const GATE_Y := 1430.0
const FOUNT := Vector2(1597, 447)        # Đài phun nước giữa khuôn viên
const QUIZ_NPC_POS := Vector2(1700, 500) # Vị trí NPC Cô Toán cạnh Tòa F
const DIEUHANH := Rect2(1818, 1201, 411, 150)
# Tốc độ thời gian: 1 giây thật = TIME_SCALE phút trong game (3.0 -> 1 ngày game dài khoảng 3 phút 20 giây)
const TIME_SCALE := 3.0
const SHOW_VEGETATION := true
const SHOW_ROAD_MARKINGS := true
const LAKE := Rect2(1487, 337, 220, 220) # Hồ nước của đài phun nước
# ─── BỐ CỤC MỚI ─────────────────────────────────────────────────────────────
const WE_LOVE_POS   := Vector2(364, 572)   # Chữ We ❤ HCMUS - sân cỏ giữa A và C
const MONUMENT_POS  := Vector2(364, 632)   # Tượng đài trắng phía dưới chữ
const FOUNTAIN_CENTER := Vector2(1597, 447)
const PARKING1_RECT := Rect2(172, 1182, 804, 258)
const PARKING2_RECT := Rect2(1751, 39, 294, 135)
const LAWN_B_RECT   := Rect2(203, 474, 321, 196)
const LINES := ["Thi chưa?", "Deadline!", "Đi ăn không?", "Đến giờ học rồi!", "Mượn tui cây bút", "Nhà ăn đông quá", "Sáng nay có kiểm tra!", "Ngủ quên mất...", "Lên thư viện không?"]

var WALL := Color("f2d98c")
var ROOF := Color("c0453a")
# [tên, x, y, rộng, cao, màu tường, màu mái, mô tả]
# Bố cục mới: WORLD=2500x1500. Khu A-B-C-D-E bên trái; F-G + công viên bên phải.
var BUILDINGS := [
	["A", 43, 76, 153, 574, WALL, ROOF, "Tòa A - giảng đường."],
	["B", 242, 322, 235, 133, WALL, Color("4a8a52"), "Hội trường B - hội trường lớn, có nhiều cửa vào."],
	["C", 524, 314, 145, 465, WALL, ROOF, "Tòa C - có Thư viện, Quầy giáo trình và ATM."],
	["D", 822, 314, 140, 465, WALL, ROOF, "Tòa D - giảng đường, gần nhà ăn và khu tự học."],
	["E", 1104, 311, 147, 543, WALL, ROOF, "Tòa E - giảng đường lớn."],
	["F", 1960, 326, 163, 471, WALL, ROOF, "Tòa F - giảng đường."],
	["G", 2282, 338, 163, 473, Color("dfe3e8"), Color("5d7c99"), "Tòa G - phòng học và phòng thí nghiệm."],
	["NHÀ THỂ DỤC", 1422, 51, 280, 125, Color("e9efe9"), Color("5f9c6a"), "Nhà Thể Dục - sân tập trong nhà."],
]
# [tên, x, y, màu mái, mô tả] : quầy, kiosk nhỏ
# Đã xóa các kiosk thừa đè lên tòa nhà/bãi cỏ (Nhà ăn, Tự học, Giáo trình); ATM chuyển thành module riêng
var KIOSKS := [
]
# ---------- CỔNG TRƯỜNG - ĐƯỜNG NỘI BỘ - NHÀ ĐIỀU HÀNH (phần mở rộng) ----------
const ROAD_T1       := Rect2(GATE_X, 1090.0, GATE_W, GATE_Y - 1090.0)
const GATE_APPROACH_ROAD := Rect2(1098.0, 1090.0, 409.0, WORLD.y - 1090.0)
const STRIP_T1_LEFT := Rect2(1026.0, 1170.0, 72.0, GATE_Y - 1170.0)
const STRIP_T1      := Rect2(1507.0, 1129.0, 72.0, GATE_Y - 1129.0)
const GUARD_BOOTH   := Rect2(1424.0, 1400.0, 36.0, 30.0)
const GATE_PANEL    := Rect2(GATE_X - 80.0, GATE_Y - 30.0, 68.0, 30.0)
const GATE_BARRICADES := []
const PARKING_SIGN  := Vector2(-1000.0, -1000.0)
const UMBRELLA_CART := Vector2(-1000.0, -1000.0)
const STREET_TREES  := []
const PARKING_LOT   := Rect2(172.0, 1182.0, 804.0, 258.0)
const LANE_SW       := Rect2(172.0, 1440.0, 804.0, 30.0)
const SHRINE_RECT   := Rect2(-1000.0, -1000.0, 0.0, 0.0)
const DOG_POS       := Vector2(-1000.0, -1000.0)
const VENDOR_CARTS  := []
const CART_SIZE     := Vector2(24.0, 12.0)
const ADMIN_PALMS   := []
const STREET_POLES  := []
const STREET_CABLES := []
const SHOP_X := 1580.0
const SHOP_W := 60.0
const SHOP_H := 36.0

# Dãy quán nội bộ đã được dọn sạch theo yêu cầu
var SHOPS := []

# Nhà dân đã được xóa theo yêu cầu
var HOUSES := []

# Quầy tạp hóa / quán nước sinh viên đặt ngay dưới bãi cỏ dưới bậc thềm Nhà Điều Hành (y≈1415, không đè bậc thang)
var STALLS := [
	{"id": "tap_hoa",      "kind": "drink", "rect": Rect2(1878.0, 1415.0, 56.0, 26.0), "accent": Color("3a8f4a")},
	{"id": "an_vat",       "kind": "stool", "rect": Rect2(1990.0, 1415.0, 56.0, 26.0), "accent": Color("3a9a63")},
	{"id": "nuoc_goc_cay", "kind": "drink", "rect": Rect2(2100.0, 1415.0, 56.0, 26.0), "accent": Color("c0262d")},
]

var ZONES := [
	["Đài phun nước và hồ sinh viên", Rect2(1487, 337, 220, 220)],
	["Sân cỏ We ❤ HCMUS - trước Hội trường B", Rect2(203, 474, 321, 196)],
	["Sân trước Nhà Điều hành (bậc thềm có hoa cảnh)", Rect2(1788, 1129, 712, 371)],
	["Bãi giữ xe số 1", Rect2(172, 1182, 804, 258)],
	["Bãi giữ xe số 2", Rect2(1751, 39, 294, 135)],
	["Dãy quán nội bộ trường", Rect2(1560, 1240, 72, 240)],
	["Hẻm nhà dân và quán vỉa hè", Rect2(60, 1444, 900, 56)],
	["Cổng trường", Rect2(1098, 1360, 449, 120)],
	["Đường nội bộ chính (ngang)", Rect2(0, 879, 2500, 211)],
	["Đường nội bộ chính (dọc)", Rect2(1268, 0, 109, 879)],
	["Đường trước Nhà Thể Dục và Bãi xe 2", Rect2(669, 191, WORLD.x - 669, 63)],
	["Đường cạnh khu hồ", Rect2(1822, 254, 97, 627)],
	["Đường giữa Tòa F và G", Rect2(2161, 254, 80, 627)],
]
# Hàng dừa vòng quanh đài phun nước (tọa độ tính trong draw_fountain_plaza)
const PALMS := []

# Danh sách các đoạn mái vòm hành lang (x_start, x_end, y):
# Bố cục mới: mái vòm nối liền một dải từ dưới hồ nước tới Tòa G,
# và đoạn vỉa hè trước Bãi xe số 1.
const WALKWAY_SECTIONS := [
	# Đoạn vỉa hè trước Bãi xe số 1
	{"start_x": 180.0,  "end_x": 976.0,  "y": 1118.0},
	# Mái vòm nối liền một dải từ dưới hồ nước tới Tòa G
	{"start_x": 1390.0, "end_x": 2465.0, "y": 844.0},
]

# Cửa được tính từ kích thước công trình để tự đi theo khi bản đồ thay đổi.
func get_doorways() -> Array:
	var doors: Array = []
	for b in BUILDINGS:
		var building_name := str(b[0])
		if building_name in ["A", "B", "C", "D", "E", "F", "NHÀ THỂ DỤC"]:
			var kind := "gym" if building_name == "NHÀ THỂ DỤC" else "classroom"
			var title := "Nhà Thể Dục" if kind == "gym" else "Tòa " + building_name
			var door := {
				"title": title,
				"kind": kind,
				"position": Vector2(b[1] + b[3] * 0.5, b[2] + b[4] + 7.0),
			}
			if building_name == "B":
				for fraction in [0.2, 0.5, 0.8]:
					var hall_door: Dictionary = door.duplicate()
					hall_door["position"] = Vector2(b[1] + b[3] * fraction, b[2] + b[4] + 7.0)
					hall_door["interior"] = "hall_b"   # nội thất riêng: scripts/maps/hoitruongB.gd
					doors.append(hall_door)
			else:
				doors.append(door)

	doors.append({
		"title": "Nhà Điều hành",
		"kind": "office",
		"position": Vector2(DIEUHANH.position.x + DIEUHANH.size.x * 0.5, DIEUHANH.end.y + 7.0),
	})
	doors.append({
		"title": "Căn tin",
		"kind": "canteen",
		"interior": "canteen",   # nội thất riêng: scripts/maps/canteen.gd
		"position": Vector2(750.0, 167.0),
	})
	return doors

func admin_topiary_points() -> PackedVector2Array:
	var x := DIEUHANH.position.x
	var e := DIEUHANH.end
	return PackedVector2Array([
		Vector2(x + 36.0, e.y + 40.0), Vector2(x + 72.0, e.y + 40.0),
		Vector2(e.x - 72.0, e.y + 40.0), Vector2(e.x - 36.0, e.y + 40.0),
	])


func admin_barricades() -> Array[Rect2]:
	var x := DIEUHANH.position.x
	var y := DIEUHANH.end.y + 54.0
	var out: Array[Rect2] = []
	out.append(Rect2(x + 8.0, y, 32.0, 4.0))
	out.append(Rect2(x + 152.0, y, 40.0, 4.0))
	out.append(Rect2(x + 220.0, y, 32.0, 4.0))
	return out


func admin_hedge_banks() -> Array[Rect2]:
	var y := DIEUHANH.end.y + 2.0
	var out: Array[Rect2] = []
	out.append(Rect2(DIEUHANH.position.x - 10.0, y, 16.0, 48.0))
	out.append(Rect2(DIEUHANH.end.x - 6.0, y, 16.0, 48.0))
	return out


# Nguồn duy nhất cho va chạm của phần mở rộng (vẽ và chặn dùng chung dữ liệu).
func frontage_solid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.append(GUARD_BOOTH)
	out.append(Rect2(GATE_PANEL.position.x, GATE_PANEL.end.y - 6.0, GATE_PANEL.size.x, 6.0))
	if SHOW_VEGETATION:
		for b in admin_hedge_banks():
			out.append(b)
	for s in STALLS:
		out.append(s["rect"])
	return out


# Các vùng đi lại / công trình cũ mà vật cản mới không được đè lên.
func frontage_keepout_rects() -> Array[Rect2]:
	var out: Array[Rect2] = [
		ROAD_T1, DIEUHANH, LAKE.grow(16.0), PARKING_LOT,
		LAWN_B_RECT,
		Rect2(FOUNTAIN_CENTER.x - 110.0, FOUNTAIN_CENTER.y - 110.0, 220.0, 220.0),
		Rect2(1150.0, 870.0, 1200.0, 20.0),
	]
	for b in BUILDINGS:
		out.append(Rect2(b[1], b[2], b[3], b[4]))
	for k in KIOSKS:
		out.append(Rect2(k[1] - 3.0, k[2], 32.0, 22.0))
	return out


# Gọi trong _ready(): if OS.is_debug_build(): assert(validate_frontage_layout())
func validate_frontage_layout() -> bool:
	var solids := frontage_solid_rects()
	var keepout := frontage_keepout_rects()
	var world := Rect2(Vector2.ZERO, WORLD)
	var ok := true
	for i in solids.size():
		var a := solids[i]
		if not world.encloses(a):
			push_error("Solid #%d nằm ngoài thế giới: %s" % [i, a])
			ok = false
		for k in keepout:
			if a.intersects(k):
				push_error("Solid #%d chặn vùng đi lại %s: %s" % [i, k, a])
				ok = false
		for j in range(i + 1, solids.size()):
			if a.intersects(solids[j]):
				push_error("Solid #%d chồng lên #%d: %s | %s" % [i, j, a, solids[j]])
				ok = false
	return ok


# Kiểm tra một điểm (vd. vị trí spawn của người chơi) có đi được không.
func frontage_is_walkable(p: Vector2, radius: float = 4.0) -> bool:
	var probe := Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	if not Rect2(Vector2.ZERO, WORLD).encloses(probe):
		return false
	for r in frontage_solid_rects():
		if r.intersects(probe):
			return false
	return not (probe.intersects(DIEUHANH) or probe.intersects(LAKE))
