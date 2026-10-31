extends Node2D
# DỮ LIỆU KHUÔN VIÊN GỐC - sửa bản đồ cơ sở tại đây.
# Muốn dời tòa nhà: sửa bảng BUILDINGS (x, y, rộng, cao). Quầy nhỏ: KIOSKS. Khu vực hiện tên: ZONES.
# Câu NPC hay nói: LINES.

const WORLD := Vector2(1600, 1000)
const SPEED := 70.0
const GATE_X := 690.0
const GATE_W := 100.0
const GATE_Y := 960.0
const FOUNT := Vector2(928, 421)
const QUIZ_NPC_POS := Vector2(1180, 580) # Vị trí NPC Cô Toán cạnh Tòa F
const DIEUHANH := Rect2(860, 680, 260, 170)
# Tốc độ thời gian: 1 giây thật = TIME_SCALE phút trong game (3.0 -> 1 ngày game dài khoảng 3 phút 20 giây)
const TIME_SCALE := 3.0
const FISH_POND := Rect2(886, 379, 84, 84)   # Hồ nước của đài phun nước (tâm = FOUNT, hình elip nội tiếp khung này) - nơi câu cá
const LAKE := FISH_POND
const LINES := ["Thi chưa?", "Deadline!", "Đi ăn không?", "Đến giờ học rồi!", "Mượn tui cây bút", "Nhà ăn đông quá", "Sáng nay có kiểm tra!", "Ngủ quên mất...", "Lên thư viện không?"]

var WALL := Color("f2d98c")
var ROOF := Color("c0453a")
# [tên, x, y, rộng, cao, màu tường, màu mái, mô tả]
var BUILDINGS := [
	["A", 152, 157, 120, 260, WALL, ROOF, "Tòa A - giảng đường."],
	["B", 296, 240, 105, 100, WALL, ROOF, "Tòa B - giảng đường, có khu vực tự học."],
	["C", 432, 240, 105, 213, WALL, ROOF, "Tòa C - có Thư viện, Quầy giáo trình và ATM."],
	["D", 576, 240, 100, 213, WALL, ROOF, "Tòa D - giảng đường, gần nhà ăn và khu tự học."],
	["E", 712, 278, 105, 286, WALL, ROOF, "Tòa E - giảng đường lớn."],
	["F", 1056, 278, 112, 286, WALL, ROOF, "Tòa F - giảng đường."],
	["G", 1256, 278, 120, 286, Color("dfe3e8"), Color("5d7c99"), "Tòa G - phòng học và phòng thí nghiệm."],
	["NHÀ THỂ DỤC", 872, 166, 192, 120, Color("e9efe9"), Color("5f9c6a"), "Nhà Thể Dục - sân tập trong nhà."],
]
# [tên, x, y, màu mái, mô tả] : quầy, kiosk nhỏ
var KIOSKS := [
	["Nhà ăn", 110, 150, Color("e08a2e"), "Nhà ăn - cơm, bún, trà đá."],
	["Nhà ăn", 690, 200, Color("e08a2e"), "Nhà ăn - ăn trưa ở đây!"],
	["Tự học", 306, 200, Color("3f8fbf"), "Khu vực tự học - ổ điện và wifi."],
	["Giáo trình", 546, 345, Color("8a5ac0"), "Quầy giáo trình - mua tài liệu học."],
	["Tự học", 682, 340, Color("3f8fbf"), "Khu vực tự học."],
	["Hội quán", 1005, 646, Color("3f9c6a"), "Hội quán Khoa học - sinh hoạt câu lạc bộ."],
	["ATM", 466, 462, Color("8e1f2c"), "Cây ATM."],
]
# ---------- CỔNG TRƯỜNG - ĐƯỜNG T1 - NHÀ ĐIỀU HÀNH (phần mở rộng) ----------
const ROAD_T1 := Rect2(GATE_X, 642.0, GATE_W, GATE_Y - 642.0)
const STRIP_T1 := Rect2(790.0, 646.0, 62.0, 216.0)
const GUARD_BOOTH := Rect2(800.0, 930.0, 28.0, 24.0)
const GATE_PANEL := Rect2(GATE_X - 70.0, GATE_Y - 26.0, 58.0, 26.0)
const GATE_BARRICADES := [Rect2(836.0, 950.0, 48.0, 4.0)]
const PARKING_SIGN := Vector2(674.0, 668.0)
const UMBRELLA_CART := Vector2(1136.0, 900.0)
const STREET_TREES := [[840.0, 858.0, 0], [610.0, 950.0, 0]]
const PARKING_LOT := Rect2(150.0, 690.0, 520.0, 200.0)
const LANE_SW := Rect2(150.0, 894.0, 540.0, 24.0)
const SHRINE_RECT := Rect2(588.0, 944.0, 10.0, 8.0)
const DOG_POS := Vector2(624.0, 946.0)
const VENDOR_CARTS := [Vector2(1250.0, 930.0), Vector2(1310.0, 934.0), Vector2(1370.0, 930.0)]
const CART_SIZE := Vector2(20.0, 10.0)
const ADMIN_PALMS := [[1160.0, 846.0, 2], [1186.0, 866.0, 2]]
const STREET_POLES := [
	{"pos": Vector2(684.0, 720.0), "mirror": false},
	{"pos": Vector2(793.0, 650.0), "mirror": true},
	{"pos": Vector2(793.0, 790.0), "mirror": false},
	{"pos": Vector2(684.0, 880.0), "mirror": false},
]
const STREET_CABLES := [[0, 1], [1, 2], [0, 3], [0, 2], [2, 3]]
const SHOP_X := 796.0
const SHOP_W := 52.0
const SHOP_H := 30.0

# Dãy quán Đường T1. kind: fashion | salon | phone | book | food | drink
var SHOPS := [
	{"id": "tien_thanh", "kind": "fashion", "name": "TIẾN THÀNH", "rect": Rect2(SHOP_X, 652.0, SHOP_W, SHOP_H), "wall": Color("23252b"), "accent": Color("e0b020"), "desc": "Thời trang Tiến Thành - quần áo, nón bảo hiểm."},
	{"id": "chigano", "kind": "salon", "name": "CHIGANO", "rect": Rect2(SHOP_X, 688.0, SHOP_W, SHOP_H), "wall": Color("2b2d33"), "accent": Color("c0262d"), "desc": "Chigano Salon - tóc nam nữ."},
	{"id": "a_bien", "kind": "phone", "name": "A BIỂN", "rect": Rect2(SHOP_X, 724.0, SHOP_W, SHOP_H), "wall": Color("f3f1ec"), "accent": Color("4aa44f"), "desc": "A Biển - phụ kiện điện thoại, dán cường lực 15K."},
	{"id": "nha_sach", "kind": "book", "name": "NHÀ SÁCH", "rect": Rect2(SHOP_X, 760.0, SHOP_W, SHOP_H), "wall": Color("e6d8b0"), "accent": Color("2f7d32"), "desc": "Nhà sách - vở, bút, giáo trình photo."},
	{"id": "bun_cha", "kind": "food", "name": "BÚN CHẢ", "rect": Rect2(SHOP_X, 796.0, SHOP_W, SHOP_H), "wall": Color("f2e6c9"), "accent": Color("c0262d"), "desc": "Quán bún chả, sinh tố - ăn nhanh cho sinh viên."},
	{"id": "quan_nuoc", "kind": "drink", "name": "QUÁN NƯỚC", "rect": Rect2(SHOP_X, 836.0, 40.0, 22.0), "wall": Color("f2e6c9"), "accent": Color("3a8f4a"), "desc": "Quán nước dưới gốc cây, có miếu nhỏ - trà đá, nước mía."},
]

# Nhà dân mái tôn dọc hẻm phía nam bãi xe.
var HOUSES := [
	{"id": "nha_tro", "name": "NHÀ TRỌ", "rect": Rect2(160.0, 926.0, 64.0, 30.0), "wall": Color("e8dcc0"), "roof": Color("8f959c"), "door": Color("5a3a22")},
	{"id": "tap_hoa", "name": "TẠP HÓA", "rect": Rect2(236.0, 926.0, 56.0, 30.0), "wall": Color("f2e6c9"), "roof": Color("b5651d"), "door": Color("2e3a44")},
	{"id": "giat_ui", "name": "GIẶT ỦI", "rect": Rect2(304.0, 926.0, 70.0, 30.0), "wall": Color("d9e4d2"), "roof": Color("6e747b"), "door": Color("8e3b32")},
]

# Quầy vỉa hè. kind: stool | cart | drink
var STALLS := [
	{"id": "an_vat", "kind": "stool", "rect": Rect2(392.0, 930.0, 48.0, 24.0), "accent": Color("3a9a63")},
	{"id": "xe_day", "kind": "cart", "rect": Rect2(452.0, 938.0, 22.0, 12.0), "accent": Color("ffd23f")},
	{"id": "nuoc_goc_cay", "kind": "drink", "rect": Rect2(540.0, 930.0, 40.0, 24.0), "accent": Color("c0262d")},
]

var ZONES := [
	["Đài phun nước và vườn điều - đứng sát bờ hồ rồi bấm E để câu cá", Rect2(832, 315, 192, 213)],
	["Sân trước Nhà Điều hành (bậc thềm có hoa cảnh)", Rect2(840, 850, 320, 110)],
	["Bãi giữ xe", Rect2(150, 690, 520, 200)],
	["Dãy quán Đường T1", Rect2(786, 646, 62, 204)],
	["Hẻm nhà dân và quán vỉa hè", Rect2(150, 894, 490, 66)],
	["Cổng trường - Đường T1", Rect2(640, 900, 200, 100)],
	["Đường nội bộ", Rect2(0, 585, 1600, 50)],
]
const PALMS := [[850, 332], [900, 332], [956, 332], [1006, 332], [850, 380], [1006, 380], [850, 462], [1006, 462], [850, 508], [900, 508], [956, 508], [1006, 508]]

# Cửa được tính từ kích thước công trình để tự đi theo khi bản đồ thay đổi.
func get_doorways() -> Array:
	var doors: Array = []
	for b in BUILDINGS:
		var building_name := str(b[0])
		if building_name in ["A", "B", "C", "D", "E", "F", "NHÀ THỂ DỤC"]:
			var kind := "gym" if building_name == "NHÀ THỂ DỤC" else "classroom"
			var title := "Nhà Thể Dục" if kind == "gym" else "Tòa " + building_name
			doors.append({
				"title": title,
				"kind": kind,
				"position": Vector2(b[1] + b[3] * 0.5, b[2] + b[4] + 7.0),
			})

	doors.append({
		"title": "Nhà Điều hành",
		"kind": "office",
		"position": Vector2(DIEUHANH.position.x + DIEUHANH.size.x * 0.5, DIEUHANH.end.y + 7.0),
	})
	for kiosk in KIOSKS:
		if kiosk[0] == "Nhà ăn":
			doors.append({
				"title": "Căn tin",
				"kind": "canteen",
				"position": Vector2(kiosk[1] + 13.0, kiosk[2] + 27.0),
			})
	return doors

func admin_topiary_points() -> PackedVector2Array:
	var x := DIEUHANH.position.x
	var e := DIEUHANH.end
	return PackedVector2Array([
		Vector2(x + 28.0, e.y + 30.0), Vector2(x + 52.0, e.y + 30.0),
		Vector2(e.x - 52.0, e.y + 30.0), Vector2(e.x - 28.0, e.y + 30.0),
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
		ROAD_T1, DIEUHANH, LAKE.grow(12.0), PARKING_LOT, LANE_SW,
		Rect2(FOUNT.x - 96.0, 315.0, 192.0, 213.0), Rect2(880.0, 650.0, 400.0, 15.0),
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
