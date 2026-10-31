extends Node2D
# DỮ LIỆU GAME - file bạn sẽ sửa nhiều nhất khi chỉnh bản đồ.
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
var ZONES := [
	["Đài phun nước và vườn điều - đứng sát bờ hồ rồi bấm E để câu cá", Rect2(832, 315, 192, 213)],
	["Sân trước Nhà Điều hành (bậc thềm có hoa cảnh)", Rect2(840, 850, 320, 110)],
	["Bãi giữ xe", Rect2(150, 690, 520, 200)],
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
