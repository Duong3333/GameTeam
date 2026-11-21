extends Node2D
# DỮ LIỆU KHUÔN VIÊN GỐC - sửa bản đồ cơ sở tại đây.
# Muốn dời tòa nhà: sửa bảng BUILDINGS (x, y, rộng, cao). Quầy nhỏ: KIOSKS. Khu vực hiện tên: ZONES.
# Câu NPC hay nói: LINES.

const WORLD := Vector2(2400, 1500)
const SPEED := 70.0
const GATE_X := 1150.0
const GATE_W := 120.0
const GATE_Y := 1430.0
const FOUNT := Vector2(1280, 440)        # Đài phun nước - giữa tòa E và F
const QUIZ_NPC_POS := Vector2(1560, 500) # Vị trí NPC Cô Toán cạnh Tòa F
const DIEUHANH := Rect2(1180, 1060, 350, 230)
# Tốc độ thời gian: 1 giây thật = TIME_SCALE phút trong game (3.0 -> 1 ngày game dài khoảng 3 phút 20 giây)
const TIME_SCALE := 3.0
const LAKE := Rect2(1170, 330, 220, 220) # Hồ nước của đài phun nước (giữa E và F)
# ─── BỐ CỤC MỚI ─────────────────────────────────────────────────────────────
const WE_LOVE_POS   := Vector2(430, 480)   # Chữ We ❤ HCMUS - sân cỏ giữa A và C
const MONUMENT_POS  := Vector2(430, 540)   # Tượng đài trắng phía dưới chữ
const FOUNTAIN_CENTER := Vector2(1280, 440) # Trung tâm đài phun nước đồng tâm (giữa E và F)
const PARKING1_RECT := Rect2(60, 920, 380, 260)  # Bãi xe số 1 (trái cổng) - thu nhỏ
const PARKING2_RECT := Rect2(2030, 50, 250, 130) # Bãi xe số 2 (kế bên phải Nhà Thể Dục)
const LAWN_B_RECT   := Rect2(260, 360, 310, 190) # Sân cỏ trước Hội trường B (rút ngắn)
const LINES := ["Thi chưa?", "Deadline!", "Đi ăn không?", "Đến giờ học rồi!", "Mượn tui cây bút", "Nhà ăn đông quá", "Sáng nay có kiểm tra!", "Ngủ quên mất...", "Lên thư viện không?"]

var WALL := Color("f2d98c")
var ROOF := Color("c0453a")
# [tên, x, y, rộng, cao, màu tường, màu mái, mô tả]
# Bố cục mới: WORLD=2400x1500. Khu A-B-C-D-E bên trái; F-G + công viên bên phải.
var BUILDINGS := [
<<<<<<< Updated upstream
	["A", 152, 157, 120, 260, WALL, ROOF, "Tòa A - giảng đường."],
	["B", 240, 440, 182, 110, WALL, ROOF, "Hội trường B - hội trường lớn, có nhiều cửa vào."],
	["C", 432, 240, 105, 213, WALL, ROOF, "Tòa C - có Thư viện, Phòng học C301, Quầy giáo trình và ATM."],
	["D", 576, 240, 100, 213, WALL, ROOF, "Tòa D - giảng đường, gần nhà ăn và khu tự học."],
	["E", 712, 278, 105, 286, WALL, ROOF, "Tòa E - giảng đường lớn."],
	["F", 1056, 278, 112, 286, WALL, ROOF, "Tòa F - giảng đường."],
	["G", 1256, 278, 120, 286, Color("dfe3e8"), Color("5d7c99"), "Tòa G - phòng học và phòng thí nghiệm."],
	["NHÀ THỂ DỤC", 872, 166, 192, 120, Color("e9efe9"), Color("5f9c6a"), "Nhà Thể Dục - sân tập trong nhà."],
=======
	["A", 120, 160, 130, 380, WALL, ROOF, "Tòa A - giảng đường."],
	["B", 290, 220, 200, 130, WALL, Color("4a8a52"), "Hội trường B - hội trường lớn, có nhiều cửa vào."],
	["C", 530, 180, 125, 380, WALL, ROOF, "Tòa C - có Thư viện, Quầy giáo trình và ATM."],
	["D", 690, 180, 120, 380, WALL, ROOF, "Tòa D - giảng đường, gần nhà ăn và khu tự học."],
	["E", 860, 180, 125, 440, WALL, ROOF, "Tòa E - giảng đường lớn."],
	["F", 1420, 180, 135, 440, WALL, ROOF, "Tòa F - giảng đường."],
	["G", 1600, 180, 135, 440, Color("dfe3e8"), Color("5d7c99"), "Tòa G - phòng học và phòng thí nghiệm."],
	["NHÀ THỂ DỤC", 1760, 50, 240, 120, Color("e9efe9"), Color("5f9c6a"), "Nhà Thể Dục - sân tập trong nhà."],
>>>>>>> Stashed changes
]
# [tên, x, y, màu mái, mô tả] : quầy, kiosk nhỏ
# Đã xóa các kiosk thừa đè lên tòa nhà/bãi cỏ (Nhà ăn, Tự học, Giáo trình); ATM chuyển thành module riêng
var KIOSKS := [
	["Hội quán", 1250, 820, Color("3f9c6a"), "Hội quán Khoa học - sinh hoạt câu lạc bộ."],
]
# ---------- CỔNG TRƯỜNG - ĐƯỜNG NỘI BỘ - NHÀ ĐIỀU HÀNH (phần mở rộng) ----------
const ROAD_T1       := Rect2(GATE_X, 1240.0, GATE_W, GATE_Y - 1240.0)
const STRIP_T1      := Rect2(1310.0, 1244.0, 72.0, 186.0)
const GUARD_BOOTH   := Rect2(1328.0, 1400.0, 36.0, 30.0)
const GATE_PANEL    := Rect2(GATE_X - 80.0, GATE_Y - 30.0, 68.0, 30.0)
const GATE_BARRICADES := [Rect2(1296.0, 1414.0, 60.0, 4.0)]
const PARKING_SIGN  := Vector2(1130.0, 1050.0)
const UMBRELLA_CART := Vector2(1700.0, 1360.0)
const STREET_TREES  := [[1250.0, 1270.0, 0], [980.0, 1400.0, 0]]
const PARKING_LOT   := Rect2(60.0, 920.0, 540.0, 380.0)
const LANE_SW       := Rect2(60.0, 1304.0, 580.0, 30.0)
const SHRINE_RECT   := Rect2(900.0, 1380.0, 12.0, 10.0)
const DOG_POS       := Vector2(950.0, 1388.0)
const VENDOR_CARTS  := [Vector2(1900.0, 1340.0), Vector2(1960.0, 1346.0), Vector2(2020.0, 1340.0)]
const CART_SIZE     := Vector2(24.0, 12.0)
const ADMIN_PALMS   := [[1740.0, 1260.0, 2], [1770.0, 1284.0, 2]]
const STREET_POLES  := [
	{"pos": Vector2(1130.0, 1100.0), "mirror": false},
	{"pos": Vector2(1248.0, 1240.0), "mirror": true},
	{"pos": Vector2(1248.0, 1360.0), "mirror": false},
	{"pos": Vector2(1130.0, 1320.0), "mirror": false},
]
const STREET_CABLES := [[0, 1], [1, 2], [0, 3], [0, 2], [2, 3]]
const SHOP_X := 1312.0
const SHOP_W := 60.0
const SHOP_H := 36.0

# Dãy quán nội bộ trường (khu bên phải cổng). kind: fashion | salon | phone | book | food | drink
var SHOPS := [
	{"id": "tien_thanh", "kind": "fashion", "name": "TIẾN THÀNH", "rect": Rect2(SHOP_X, 1250.0, SHOP_W, SHOP_H), "wall": Color("23252b"), "accent": Color("e0b020"), "desc": "Thời trang Tiến Thành - quần áo, nón bảo hiểm."},
	{"id": "chigano",    "kind": "salon",   "name": "CHIGANO",    "rect": Rect2(SHOP_X, 1292.0, SHOP_W, SHOP_H), "wall": Color("2b2d33"), "accent": Color("c0262d"), "desc": "Chigano Salon - tóc nam nữ."},
	{"id": "a_bien",     "kind": "phone",   "name": "A BIỂN",     "rect": Rect2(SHOP_X, 1334.0, SHOP_W, SHOP_H), "wall": Color("f3f1ec"), "accent": Color("4aa44f"), "desc": "A Biển - phụ kiện điện thoại, dán cường lực 15K."},
	{"id": "nha_sach",   "kind": "book",    "name": "NHÀ SÁCH",   "rect": Rect2(SHOP_X, 1376.0, SHOP_W, SHOP_H), "wall": Color("e6d8b0"), "accent": Color("2f7d32"), "desc": "Nhà sách - vở, bút, giáo trình photo."},
	{"id": "bun_cha",    "kind": "food",    "name": "BÚN CHẢ",    "rect": Rect2(SHOP_X, 1414.0, SHOP_W, SHOP_H), "wall": Color("f2e6c9"), "accent": Color("c0262d"), "desc": "Quán bún chả, sinh tố - ăn nhanh cho sinh viên."},
	{"id": "quan_nuoc",  "kind": "drink",   "name": "QUÁN NƯỚC",  "rect": Rect2(SHOP_X, 1450.0, 50.0,  28.0),  "wall": Color("f2e6c9"), "accent": Color("3a8f4a"), "desc": "Quán nước dưới gốc cây - trà đá, nước mía."},
]

# Nhà dân mái tôn dọc hẻm phía nam bãi xe.
var HOUSES := [
	{"id": "nha_tro",  "name": "NHÀ TRỌ",  "rect": Rect2(60.0,  1340.0, 80.0, 38.0), "wall": Color("e8dcc0"), "roof": Color("8f959c"), "door": Color("5a3a22")},
	{"id": "tap_hoa",  "name": "TẠP HÓA",  "rect": Rect2(154.0, 1340.0, 72.0, 38.0), "wall": Color("f2e6c9"), "roof": Color("b5651d"), "door": Color("2e3a44")},
	{"id": "giat_ui",  "name": "GIẶT ỦI",  "rect": Rect2(240.0, 1340.0, 88.0, 38.0), "wall": Color("d9e4d2"), "roof": Color("6e747b"), "door": Color("8e3b32")},
]

# Quầy vỉa hè. kind: stool | cart | drink
var STALLS := [
	{"id": "an_vat",      "kind": "stool", "rect": Rect2(600.0, 1348.0, 60.0, 30.0), "accent": Color("3a9a63")},
	{"id": "xe_day",      "kind": "cart",  "rect": Rect2(676.0, 1358.0, 28.0, 16.0), "accent": Color("ffd23f")},
	{"id": "nuoc_goc_cay","kind": "drink", "rect": Rect2(820.0, 1348.0, 50.0, 30.0), "accent": Color("c0262d")},
]

var ZONES := [
	["Đài phun nước và hồ sinh viên", Rect2(1170, 330, 220, 220)],
	["Sân cỏ We ❤ HCMUS - trước Hội trường B", Rect2(260, 360, 310, 260)],
	["Sân trước Nhà Điều hành (bậc thềm có hoa cảnh)", Rect2(1130, 1290, 420, 160)],
	["Bãi giữ xe số 1", Rect2(60, 920, 380, 260)],
	["Bãi giữ xe số 2", Rect2(2030, 50, 250, 130)],
	["Dãy quán nội bộ trường", Rect2(1300, 1240, 72, 240)],
	["Hẻm nhà dân và quán vỉa hè", Rect2(60, 1304, 900, 80)],
	["Cổng trường", Rect2(1050, 1360, 300, 120)],
	["Đường nội bộ chính (ngang)", Rect2(0, 870, 2400, 60)],
	["Đường nội bộ chính (dọc)", Rect2(1070, 0, 90, 1500)],
]
# Hàng dừa vòng quanh đài phun nước (tọa độ tính trong draw_fountain_plaza)
const PALMS := [
	[1310, 180], [1360, 180], [1420, 180], [1480, 180],
	[1570, 180], [1660, 180], [1720, 180],
	[260, 160],  [310, 160],  [420, 160],  [470, 160],
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
		"position": Vector2(636.0, 158.0),
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
	for s in SHOPS:
		out.append(s["rect"])
	for t in STREET_TREES + ADMIN_PALMS:
		out.append(Rect2(t[0] - 2.0, t[1] - 4.0, 5.0, 4.0))
	for pole in STREET_POLES:
		var p: Vector2 = pole["pos"]
		out.append(Rect2(p.x - 2.0, p.y - 3.0, 4.0, 3.0))
	out.append(GUARD_BOOTH)
	out.append(Rect2(GATE_PANEL.position.x, GATE_PANEL.end.y - 6.0, GATE_PANEL.size.x, 6.0))
	for b in GATE_BARRICADES:
		out.append(b)
	for b in admin_barricades():
		out.append(b)
	for b in admin_hedge_banks():
		out.append(b)
	for q in admin_topiary_points():
		out.append(Rect2(q.x - 5.0, q.y - 7.0, 10.0, 7.0))
	out.append(Rect2(UMBRELLA_CART.x, UMBRELLA_CART.y, 20.0, 10.0))
	out.append(Rect2(PARKING_SIGN.x - 1.0, PARKING_SIGN.y - 2.0, 3.0, 2.0))
	for h in HOUSES:
		out.append(h["rect"])
	for s in STALLS:
		out.append(s["rect"])
	out.append(SHRINE_RECT)
	for c in VENDOR_CARTS:
		out.append(Rect2(c, CART_SIZE))
	return out


# Các vùng đi lại / công trình cũ mà vật cản mới không được đè lên.
func frontage_keepout_rects() -> Array[Rect2]:
	var out: Array[Rect2] = [
		ROAD_T1, DIEUHANH, LAKE.grow(16.0), PARKING_LOT, LANE_SW,
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
