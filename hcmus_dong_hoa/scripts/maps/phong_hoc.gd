extends "res://scripts/features/feature.gd"
# HỆ THỐNG PHÒNG HỌC DÃY A - G & NHÀ ĐIỀU HÀNH (Redesign theo bản vẽ giảng đường chuẩn).
#
# Bố cục nội thất giảng đường (480x270):
#   - Tường vàng kem, bảng trắng dài viền xám kèm khay bút (đỏ, xanh) & giẻ lau, đồng hồ treo tường.
#   - 2 máy lạnh treo góc trên tường + 2 máy lạnh đặt góc dưới sàn, 2 loa treo tường trái & phải.
#   - Bục giảng gỗ chạy ngang + bàn giảng viên góc trái bục giảng.
#   - Sàn gạch caro sáng + 4 cột bàn dãy ghế dài (mỗi cột 5 hàng = 20 dãy bàn).
#
# Chức năng theo từng tòa nhà:
#   - Tòa A, B, G: Phòng học giảng đường chung.
#   - Tòa C: Đã tích hợp chọn [1] Thư viện / [2] Phòng học trong thu_vien.gd (gọi open_classroom("C")).
#   - Tòa D: Bấm [E] trước cửa chọn:
#       [1] Thực hành Cơ sở lập trình (mở phòng máy tính b42_lab.gd preset "D_CSLT")
#       [2] Toán rời rạc (phòng học giảng đường)
#   - Tòa E: Phòng học Nhập môn Công nghệ thông tin.
#   - Tòa F: Bấm [E] trước cửa chọn:
#       [1] Vi tích phân (phòng học giảng đường)
#       [2] Cơ sở lập trình lý thuyết (phòng học giảng đường)
#   - Nhà Điều hành: Bấm [E] trước cửa để vào Thực hành Toán rời rạc (hoặc gọi open_classroom("NDH")).

const VIEW := Vector2(480, 270)
const WALL_H := 56.0
const STAGE_Y := 56.0
const STAGE_H := 20.0
const FLOOR_TOP := 76.0
const FLOOR_BOTTOM := 258.0
const DOOR_POS := Vector2(240, 250)
const START_POS := Vector2(240, 242)
const WALK_SPEED := 70.0
const SEAT_RANGE := 16.0
const DOOR_RANGE := 26.0

# 4 cột bàn x 5 hàng = 20 dãy bàn (khớp ảnh tham chiếu)
const COL_XS := [18.0, 134.0, 250.0, 366.0]
const COL_W := 96.0
const ROW_YS := [100.0, 128.0, 156.0, 184.0, 212.0]
const BENCH_H := 13.0
const TEACHER_DESK := Rect2(40, 52, 64, 16)

# Bảng màu kiến trúc giảng đường (theo ảnh tham chiếu)
const C_WALL := Color("f3e5c2")
const C_WALL_SHADE := Color("e2cfa4")
const C_STAGE := Color("d69d5c")
const C_STAGE_EDGE := Color("9a6532")
const C_WOOD_TOP := Color("c98642")
const C_WOOD_FRONT := Color("9e6129")
const C_WOOD_DARK := Color("5e3816")
const C_TILE_A := Color("f8f1e1")
const C_TILE_B := Color("efe5cf")
const C_TILE_LINE := Color("dfd2b8")
const C_FRAME := Color("231f1d")

# Cấu hình từng phòng học (tiêu đề bảng, nội dung bảng, danh sách NPC sinh viên & giảng viên)
const ROOM_CONFIGS := {
	"A": {
		"title": "GIẢNG ĐƯỜNG TÒA A · PHÒNG A101",
		"sub": "Đại số tuyến tính & Giải tích cơ bản",
		"teacher": {"shirt": "2f5f6a", "hair": "2a1d14", "long": true, "name": "Giảng viên"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.25, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 2, "frac": 0.72, "shirt": "e07a5f", "hair": "2a1d14", "uni": false, "long": true,  "pack": false},
			{"col": 1, "row": 1, "frac": 0.30, "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 0, "frac": 0.65, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": true},
			{"col": 3, "row": 3, "frac": 0.45, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": false, "pack": false},
		]
	},
	"B": {
		"title": "GIẢNG ĐƯỜNG TÒA B · PHÒNG B202",
		"sub": "Vật lý đại cương & Kỹ năng mềm",
		"teacher": {"shirt": "4a5568", "hair": "1b1b1b", "long": false, "name": "Giảng viên"},
		"npcs": [
			{"col": 0, "row": 1, "frac": 0.60, "shirt": "81b29a", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.25, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 2, "frac": 0.70, "shirt": "e07a5f", "hair": "5a3a22", "uni": false, "long": true,  "pack": false},
			{"col": 3, "row": 1, "frac": 0.35, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
		]
	},
	"C": {
		"title": "GIẢNG ĐƯỜNG TÒA C · PHÒNG C301",
		"sub": "Pháp luật đại cương & Triết học Mác - Lênin",
		"teacher": {"shirt": "5a3a22", "hair": "3b3b3b", "long": false, "name": "Giảng viên"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.70, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": true},
			{"col": 1, "row": 2, "frac": 0.28, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 1, "frac": 0.55, "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": true,  "pack": false},
			{"col": 3, "row": 0, "frac": 0.30, "shirt": "e07a5f", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
		]
	},
	"D_TRR": {
		"title": "TÒA D · TOÁN RỜI RẠC",
		"sub": "Logic mệnh đề · Đồ thị · Tổ hợp & Quan hệ",
		"teacher": {"shirt": "1f4e78", "hair": "1b1b1b", "long": false, "name": "GV. Toán rời rạc"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.22, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 1, "frac": 0.72, "shirt": "e07a5f", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.65, "shirt": "81b29a", "hair": "5a3a22", "uni": false, "long": false, "pack": false},
			{"col": 1, "row": 3, "frac": 0.30, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
			{"col": 2, "row": 1, "frac": 0.25, "shirt": "457b9d", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 2, "frac": 0.75, "shirt": "d96b43", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false},
			{"col": 3, "row": 0, "frac": 0.40, "shirt": "3d5a80", "hair": "5a3a22", "uni": true,  "long": false, "pack": true},
		]
	},
	"E": {
		"title": "TÒA E · NHẬP MÔN CÔNG NGHỆ THÔNG TIN",
		"sub": "Tổng quan ngành CNTT · Kiến trúc máy tính · Hướng nghiệp",
		"teacher": {"shirt": "2f7d4c", "hair": "1b1b1b", "long": true, "name": "GV. Nhập môn CNTT"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.30, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 2, "frac": 0.68, "shirt": "f2cc8f", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.75, "shirt": "e07a5f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false},
			{"col": 1, "row": 1, "frac": 0.25, "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 0, "frac": 0.35, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 2, "row": 3, "frac": 0.70, "shirt": "e07a5f", "hair": "1b1b1b", "uni": false, "long": false, "pack": true},
			{"col": 3, "row": 1, "frac": 0.60, "shirt": "81b29a", "hair": "2a1d14", "uni": true,  "long": true,  "pack": false},
			{"col": 3, "row": 2, "frac": 0.25, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
		]
	},
	"F_VTP": {
		"title": "TÒA F (PHÒNG 1) · VI TÍCH PHÂN 1",
		"sub": "Giới hạn · Đạo hàm · Xấp xỉ tuyến tính & Tích phân",
		"teacher": {"shirt": "6b4226", "hair": "2a1d14", "long": false, "name": "GV. Vi tích phân"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.25, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 1, "frac": 0.75, "shirt": "e07a5f", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.30, "shirt": "81b29a", "hair": "5a3a22", "uni": false, "long": false, "pack": true},
			{"col": 1, "row": 2, "frac": 0.70, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": false},
			{"col": 2, "row": 0, "frac": 0.65, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 1, "frac": 0.25, "shirt": "e07a5f", "hair": "1b1b1b", "uni": false, "long": true,  "pack": true},
			{"col": 3, "row": 0, "frac": 0.50, "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": false, "pack": false},
		]
	},
	"F_CSLT": {
		"title": "TÒA F (PHÒNG 2) · CƠ SỞ LẬP TRÌNH (LÝ THUYẾT)",
		"sub": "C++ · Mảng · Hàm · Đệ quy & Con trỏ",
		"teacher": {"shirt": "1f2f5a", "hair": "1b1b1b", "long": true, "name": "GV. Cơ sở lập trình"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.70, "shirt": "81b29a", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 2, "frac": 0.25, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.22, "shirt": "e07a5f", "hair": "5a3a22", "uni": false, "long": false, "pack": false},
			{"col": 1, "row": 1, "frac": 0.68, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
			{"col": 2, "row": 0, "frac": 0.30, "shirt": "457b9d", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 2, "row": 3, "frac": 0.75, "shirt": "d96b43", "hair": "1b1b1b", "uni": false, "long": true,  "pack": false},
			{"col": 3, "row": 1, "frac": 0.35, "shirt": "3d5a80", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
		]
	},
	"G": {
		"title": "GIẢNG ĐƯỜNG TÒA G · PHÒNG G101",
		"sub": "Anh văn chuyên ngành & Giáo dục quốc phòng",
		"teacher": {"shirt": "7c3aed", "hair": "2a1d14", "long": true, "name": "Giảng viên"},
		"npcs": [
			{"col": 0, "row": 1, "frac": 0.30, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 1, "row": 0, "frac": 0.65, "shirt": "e07a5f", "hair": "2a1d14", "uni": false, "long": true,  "pack": false},
			{"col": 2, "row": 2, "frac": 0.40, "shirt": "81b29a", "hair": "5a3a22", "uni": true,  "long": false, "pack": true},
			{"col": 3, "row": 0, "frac": 0.72, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
		]
	},
	"NDH": {
		"title": "NHÀ ĐIỀU HÀNH · THỰC HÀNH TOÁN RỜI RẠC",
		"sub": "Thuật toán trên đồ thị · Cây khung · Đường đi ngắn nhất",
		"teacher": {"shirt": "1e3a5f", "hair": "1b1b1b", "long": false, "name": "GV. TH Toán rời rạc"},
		"npcs": [
			{"col": 0, "row": 0, "frac": 0.25, "shirt": "3d5a80", "hair": "1b1b1b", "uni": true,  "long": false, "pack": true},
			{"col": 0, "row": 1, "frac": 0.70, "shirt": "81b29a", "hair": "2a1d14", "uni": true,  "long": true,  "pack": true},
			{"col": 1, "row": 0, "frac": 0.30, "shirt": "e07a5f", "hair": "5a3a22", "uni": false, "long": false, "pack": false},
			{"col": 1, "row": 2, "frac": 0.75, "shirt": "f2cc8f", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": true},
			{"col": 2, "row": 1, "frac": 0.35, "shirt": "457b9d", "hair": "2a1d14", "uni": true,  "long": false, "pack": true},
			{"col": 3, "row": 0, "frac": 0.65, "shirt": "d96b43", "hair": "1b1b1b", "uni": true,  "long": true,  "pack": false},
		]
	}
}

# Các tòa cho phép bấm [E] trực tiếp tại cửa ngoài trời (Tòa C do thu_vien.gd quản lý menu chọn)
const DIRECT_DOORS := ["A", "B", "D", "E", "F", "G"]

var inside := false
var _choice_building := ""    # "" | "D" | "F"
var _layer: CanvasLayer
var _painter: Node2D
var _pos := START_POS
var _face := 1                # 0 xuống, 1 lên, 2 trái, 3 phải
var _anim := 0.0
var _clock := 0.0
var _seated := -1
var _fade := 0.0
var _closing := false

var _room_key := "A"
var _room_title := ""
var _room_sub := ""
var _teacher_npc: Dictionary = {}
var _active_npcs: Array = []

var _desks: Array = []        # danh sách 20 dãy bàn: {col, row, rect, y_sort}
var _seats: Array = []        # danh sách ghế ngồi (3 ghế/dãy bàn = 60 ghế): {desk_idx, pos, stand, face}
var _solid: Array = []        # vùng va chạm vật thể trong phòng
var _lab_f: Node = null       # tham chiếu tới b42_lab.gd để mở phòng máy tính dùng chung
var _looked := false

func _ready() -> void:
	_build_room()
	_layer = CanvasLayer.new()
	_layer.layer = 5
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint)

func _lookup() -> void:
	if _looked:
		return
	_looked = true
	for f in game.features:
		if f == self:
			continue
		if f.has_method("open_lab"):
			_lab_f = f

# ======================= DỰNG GIẢNG ĐƯỜNG & GHẾ NGỒI =======================

func _build_room() -> void:
	_desks.clear()
	_seats.clear()
	_solid.clear()
	# Bàn giảng viên trên bục giảng góc trái
	_solid.append(TEACHER_DESK)
	# 2 máy lạnh đặt góc dưới sàn (trái & phải)
	_solid.append(Rect2(8, 240, 52, 16))
	_solid.append(Rect2(420, 240, 52, 16))

	var seat_fracs: Array[float] = [0.22, 0.50, 0.78]
	# 4 cột x 5 hàng = 20 dãy bàn sinh viên
	for r in ROW_YS.size():
		var ry: float = float(ROW_YS[r])
		for c in COL_XS.size():
			var cx: float = float(COL_XS[c])
			var di: int = _desks.size()
			var rect := Rect2(cx, ry, COL_W, BENCH_H)
			_desks.append({"id": di, "col": c, "row": r, "rect": rect, "y_sort": ry + BENCH_H})
			_solid.append(Rect2(cx + 1.0, ry + 1.0, COL_W - 2.0, BENCH_H - 1.0))
			# Mỗi dãy bàn có 3 vị trí ghế ngồi dọc theo chiều ngang bàn
			for frac: float in seat_fracs:
				var sx: float = cx + COL_W * frac
				_seats.append({
					"desk_idx": di,
					"pos": Vector2(sx, ry + BENCH_H + 6.0),
					"stand": Vector2(sx, ry + BENCH_H + 11.0),
					"face": 1
				})

# ======================= CỬA TÒA NHÀ & TƯƠNG THÍCH HỆ THỐNG =======================

func _building_door(b_name: String) -> Vector2:
	for b in game.BUILDINGS:
		if str(b[0]) == b_name:
			return Vector2(float(b[1]) + float(b[3]) * 0.5, float(b[2]) + float(b[4]) + 7.0)
	return Vector2(-9999.0, -9999.0)

func _near_direct_building() -> String:
	for b_name in DIRECT_DOORS:
		if game.player.distance_to(_building_door(b_name)) < DOOR_RANGE:
			return b_name
	return ""

func _near_ndh_door() -> bool:
	for b in game.BUILDINGS:
		var bn: String = str(b[0]).to_upper()
		if bn.find("ĐIỀU HÀNH") >= 0 or bn == "NDH" or bn == "ĐH":
			var pt := Vector2(float(b[1]) + float(b[3]) * 0.5, float(b[2]) + float(b[4]) + 8.0)
			if game.player.distance_to(pt) < DOOR_RANGE + 8.0:
				return true
	return false

# Hàm mở phòng học theo mã cấu hình (dùng được từ cả thu_vien.gd cho Tòa C và nhà điều hành)
func open_classroom(room_key: String = "A") -> void:
	_lookup()
	var key: String = room_key if ROOM_CONFIGS.has(room_key) else "A"
	var cfg: Dictionary = ROOM_CONFIGS[key]
	_room_key = key
	_room_title = str(cfg.get("title", "GIẢNG ĐƯỜNG"))
	_room_sub = str(cfg.get("sub", ""))
	_teacher_npc = cfg.get("teacher", {})
	_active_npcs.clear()
	for n in cfg.get("npcs", []):
		if n is Dictionary:
			var col: int = int(n.get("col", 0))
			var row: int = int(n.get("row", 0))
			var frac: float = float(n.get("frac", 0.5))
			var rx: float = float(COL_XS[clampi(col, 0, COL_XS.size() - 1)]) + COL_W * frac
			var ry: float = float(ROW_YS[clampi(row, 0, ROW_YS.size() - 1)]) + BENCH_H + 6.0
			var item: Dictionary = n.duplicate()
			item["pos"] = Vector2(rx, ry)
			_active_npcs.append(item)
	_choice_building = ""
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_seated = -1
	_fade = 1.0
	begin()
	_layer.visible = true
	game.hud.visible = false
	_painter.queue_redraw()

# Tương thích nếu doors feature gọi enter_room(d)
func enter_room(d: Dictionary) -> void:
	var title: String = str(d.get("title", ""))
	if title.find("Tòa C") >= 0:
		open_classroom("C")
	elif title.find("Tòa E") >= 0:
		open_classroom("E")
	elif title.find("Tòa A") >= 0:
		open_classroom("A")
	elif title.find("Tòa B") >= 0:
		open_classroom("B")
	elif title.find("Tòa G") >= 0:
		open_classroom("G")
	elif title.find("Điều hành") >= 0:
		open_classroom("NDH")
	else:
		open_classroom("A")

func begin() -> void:
	super()

func finish() -> void:
	super()
	inside = false
	_choice_building = ""
	_closing = false
	_seated = -1
	_layer.visible = false
	game.hud.visible = true

# ======================= XỬ LÝ PHÍM =======================

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if _choice_building != "":
		_handle_choice_key(k)
		return
	if inside:
		_handle_room_key(k)
		return
	if k.physical_keycode == KEY_E and not game.is_busy():
		var b: String = _near_direct_building()
		if b != "":
			_trigger_building_entry(b)
			get_viewport().set_input_as_handled()
		elif _near_ndh_door():
			open_classroom("NDH")
			get_viewport().set_input_as_handled()

func _trigger_building_entry(b: String) -> void:
	_lookup()
	if b == "D" or b == "F":
		_choice_building = b
		begin()
		_layer.visible = true
		_painter.queue_redraw()
	else:
		open_classroom(b)

func _handle_choice_key(k: InputEventKey) -> void:
	var kc := k.keycode
	if kc == KEY_1 or kc == KEY_KP_1:
		if _choice_building == "D":
			finish()
			if _lab_f != null:
				_lab_f.open_lab("D_CSLT")
		elif _choice_building == "F":
			open_classroom("F_VTP")
	elif kc == KEY_2 or kc == KEY_KP_2:
		if _choice_building == "D":
			open_classroom("D_TRR")
		elif _choice_building == "F":
			open_classroom("F_CSLT")
	elif kc == KEY_ESCAPE or kc == KEY_E or kc == KEY_BACKSPACE:
		finish()
	else:
		return
	get_viewport().set_input_as_handled()

func _handle_room_key(k: InputEventKey) -> void:
	if _closing:
		return
	var pk := k.physical_keycode
	if _seated >= 0:
		if pk == KEY_E or k.keycode == KEY_ESCAPE or pk == KEY_W or pk == KEY_A or pk == KEY_S or pk == KEY_D:
			_stand_up()
			get_viewport().set_input_as_handled()
		return
	if pk != KEY_E:
		return
	if _pos.distance_to(DOOR_POS) < 26.0:
		_closing = true
	else:
		var s: int = _nearest_seat()
		if s >= 0:
			_sit(s)
	get_viewport().set_input_as_handled()

# ======================= DI CHUYỂN & NGỒI TRONG PHÒNG =======================

func _process(delta: float) -> void:
	if _choice_building != "":
		_painter.queue_redraw()
		return
	if not inside:
		return
	_clock += delta
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			finish()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		if _seated < 0:
			_walk(delta)
	_painter.queue_redraw()

func _walk(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if v == Vector2.ZERO:
		return
	v = v.normalized() * WALK_SPEED * delta
	if absf(v.x) > absf(v.y):
		_face = 2 if v.x < 0.0 else 3
	else:
		_face = 1 if v.y < 0.0 else 0
	_anim += delta
	var a := _pos + Vector2(v.x, 0.0)
	if _blocked(a):
		a = _pos
	var b := a + Vector2(0.0, v.y)
	if _blocked(b):
		b = a
	_pos = b

func _blocked(p: Vector2) -> bool:
	if p.x < 12.0 or p.x > VIEW.x - 12.0 or p.y < 60.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

func _nearest_seat() -> int:
	var best: int = -1
	var bd: float = SEAT_RANGE
	for i in _seats.size():
		var sp: Vector2 = _seats[i].pos
		var busy := false
		for npc in _active_npcs:
			if sp.distance_to(npc.pos) < 10.0:
				busy = true
				break
		if busy:
			continue
		var d: float = _pos.distance_to(_seats[i].stand)
		if d < bd:
			bd = d
			best = i
	return best

func _sit(i: int) -> void:
	_seated = i
	_pos = _seats[i].pos
	_face = int(_seats[i].face)

func _stand_up() -> void:
	if _seated < 0:
		return
	_pos = _seats[_seated].stand
	_face = 0
	_seated = -1

# ======================= VẼ GIẢNG ĐƯỜNG (THEO ẢNH THAM CHIẾU) =======================

func _paint() -> void:
	var p := _painter
	if _choice_building != "":
		_paint_choice_menu(p)
		return
	p.rc(0, 0, VIEW.x, VIEW.y, C_FRAME)
	_paint_wall_and_stage(p)
	_paint_floor_tiles(p)
	_paint_teacher_area(p)

	# Y-sort cho 20 dãy bàn, sinh viên NPC và người chơi
	var items: Array = []
	for d in _desks:
		items.append([float(d.y_sort), 0, d])
	for npc in _active_npcs:
		items.append([float(npc.pos.y), 1, npc])
	items.append([_pos.y, 2, null])
	items.sort_custom(func(a, b): return a[0] < b[0])

	for it in items:
		match it[1]:
			0:
				_paint_bench_desk(p, it[2])
			1:
				var npc: Dictionary = it[2]
				p.draw_person(
					npc.pos,
					Color(str(npc.get("shirt", "3d5a80"))),
					Color(str(npc.get("hair", "1b1b1b"))),
					1,
					0.0,
					bool(npc.get("uni", true)),
					bool(npc.get("long", false)),
					bool(npc.get("pack", false))
				)
			2:
				_paint_player(p)

	_paint_bottom_aircons_and_door(p)
	_paint_prompt(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

func _paint_wall_and_stage(p: Node2D) -> void:
	# Tường vàng kem phía trên
	p.rc(4, 3, VIEW.x - 8.0, WALL_H - 3.0, C_WALL)
	p.rc(4, 3, VIEW.x - 8.0, 3, C_WALL_SHADE)

	# 2 máy lạnh treo góc trên (trái & phải)
	_paint_wall_ac(p, 10.0, 9.0)
	_paint_wall_ac(p, 424.0, 9.0)

	# Đồng hồ treo tường tròn cạnh máy lạnh trái
	p.draw_circle(Vector2(104, 19), 9.5, Color("2e3440"))
	p.draw_circle(Vector2(104, 19), 8.0, Color("f8fafc"))
	p.rc(103.5, 13, 1, 6, Color("1e293b"))
	p.rc(104, 18.5, 5, 1, Color("1e293b"))

	# Bảng trắng dài viền xám ở trung tâm tường
	p.rc(118, 16, 294, 38, Color("6e747c"))
	p.rc(120, 18, 290, 34, Color("9aa0a8"))
	p.rc(122, 20, 286, 30, Color("f4f6f9"))
	p.rc(122, 20, 286, 2, Color("e2e8f0"))
	p.draw_string(p.font, Vector2(122, 33), _room_title, HORIZONTAL_ALIGNMENT_CENTER, 286, 8, Color("1e40af"))
	if _room_sub != "":
		p.draw_string(p.font, Vector2(122, 44), _room_sub, HORIZONTAL_ALIGNMENT_CENTER, 286, 7, Color("334155"))
	# Khay phấn/bút & giẻ lau dưới mép bảng
	p.rc(117, 53, 296, 3, Color("5a6068"))
	p.rc(146, 51, 8, 2, Color("ffffff"))
	p.rc(162, 50, 16, 4, Color("2b2d34"))   # giẻ lau bảng đen
	p.rc(186, 51, 8, 2, Color("ffffff"))
	p.rc(320, 51, 9, 2, Color("dc2626"))     # bút đỏ
	p.rc(332, 51, 9, 2, Color("e2e8f0"))     # bút trắng
	p.rc(344, 51, 9, 2, Color("2563eb"))     # bút xanh

	# 2 loa hộp đen treo tường trái & phải
	_paint_speaker(p, 4.0, 29.0, 8.0, 16.0)
	_paint_speaker(p, 8.0, 52.0, 15.0, 22.0)
	_paint_speaker(p, 471.0, 29.0, 6.0, 16.0)

	# Bục giảng gỗ chạy ngang phòng
	p.rc(4, STAGE_Y, VIEW.x - 8.0, STAGE_H - 3.0, C_STAGE)
	p.rc(4, STAGE_Y, VIEW.x - 8.0, 2, C_STAGE.lightened(0.18))
	p.rc(4, STAGE_Y + STAGE_H - 3.0, VIEW.x - 8.0, 3, C_STAGE_EDGE)

func _paint_wall_ac(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y, 46, 16, Color("9aa1ab"))
	p.rc(x + 1, y + 1, 44, 14, Color("f1f5f9"))
	p.rc(x + 1, y + 1, 44, 2, Color("ffffff"))
	p.rc(x + 3, y + 11, 40, 3, Color("cbd5e1"))
	p.rc(x + 38, y + 4, 3, 2, Color("22c55e"))

func _paint_speaker(p: Node2D, x: float, y: float, w: float, h: float) -> void:
	p.rc(x, y, w, h, Color("1f2228"))
	p.rc(x + 1, y + 1, w - 2, h - 2, Color("383c46"))
	if w >= 12.0:
		p.draw_circle(Vector2(x + w * 0.5, y + 6.0), 2.2, Color("181a1f"))
		p.draw_circle(Vector2(x + w * 0.5, y + 14.0), 4.0, Color("181a1f"))
		p.draw_circle(Vector2(x + w * 0.5, y + 14.0), 1.5, Color("5a606e"))

func _paint_floor_tiles(p: Node2D) -> void:
	p.rc(4, FLOOR_TOP, VIEW.x - 8.0, FLOOR_BOTTOM - FLOOR_TOP, C_TILE_A)
	var step: int = 16
	for ty in range(int(FLOOR_TOP), int(FLOOR_BOTTOM), step):
		for tx in range(4, int(VIEW.x) - 4, step):
			var w: int = mini(step, int(VIEW.x) - 4 - tx)
			var h: int = mini(step, int(FLOOR_BOTTOM) - ty)
			var c: Color = C_TILE_A if ((tx + ty) / step) % 2 == 0 else C_TILE_B
			p.rc(tx, ty, w, h, c)
			p.rc(tx, ty, w, 1, C_TILE_LINE)
			p.rc(tx, ty, 1, h, C_TILE_LINE)

func _paint_teacher_area(p: Node2D) -> void:
	# Giảng viên đứng sau bàn giảng viên
	if not _teacher_npc.is_empty():
		var tpos := Vector2(72.0, 56.0)
		p.draw_person(
			tpos,
			Color(str(_teacher_npc.get("shirt", "2f5f6a"))),
			Color(str(_teacher_npc.get("hair", "1b1b1b"))),
			0,
			0.0,
			false,
			bool(_teacher_npc.get("long", false)),
			false
		)
		var tname: String = str(_teacher_npc.get("name", "Giảng viên"))
		var w: float = p.font.get_string_size(tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 6.0
		p.ctext(tname, tpos.x - w / 2.0, tpos.y - 30.0, w, 7, Color("1e3a8a"))

	# Bàn giảng viên gỗ góc trái bục giảng
	var d: Rect2 = TEACHER_DESK
	p.rc(d.position.x - 1, d.position.y - 1, d.size.x + 2, d.size.y + 11, C_WOOD_DARK)
	p.rc(d.position.x, d.position.y, d.size.x, 9, C_WOOD_TOP)
	p.rc(d.position.x, d.position.y, d.size.x, 1, C_WOOD_TOP.lightened(0.22))
	p.rc(d.position.x, d.position.y + 9, d.size.x, 7, C_WOOD_FRONT)
	p.rc(d.position.x + 2, d.position.y + 16, 3, 9, C_WOOD_DARK)
	p.rc(d.position.x + d.size.x - 5, d.position.y + 16, 3, 9, C_WOOD_DARK)

func _paint_bench_desk(p: Node2D, d: Dictionary) -> void:
	var r: Rect2 = d.rect
	var x: float = r.position.x
	var y: float = r.position.y
	var w: float = r.size.x
	# Chân sắt xám 2 bên + băng ghế dài phía sau bàn
	p.rc(x + 2, y + 10, 3, 12, Color("64748b"))
	p.rc(x + w - 5, y + 10, 3, 12, Color("64748b"))
	p.rc(x + 3, y + 15, w - 6, 4, C_WOOD_FRONT)
	p.rc(x + 3, y + 15, w - 6, 1, C_WOOD_TOP)
	# Mặt bàn gỗ & yếm bàn
	p.rc(x - 1, y - 1, w + 2, 14, C_WOOD_DARK)
	p.rc(x, y, w, 8, C_WOOD_TOP)
	p.rc(x, y, w, 1, C_WOOD_TOP.lightened(0.22))
	p.rc(x, y + 8, w, 4, C_WOOD_FRONT)

func _paint_bottom_aircons_and_door(p: Node2D) -> void:
	# Tường viền dưới & 2 máy lạnh đặt góc dưới trái/phải như ảnh tham chiếu
	p.rc(0, FLOOR_BOTTOM, VIEW.x, VIEW.y - FLOOR_BOTTOM, Color("8a5a32"))
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 2, Color("4a2e16"))
	_paint_floor_ac(p, 8.0, 244.0)
	_paint_floor_ac(p, 422.0, 244.0)
	# Cửa ra vào ở lối đi giữa phía dưới
	p.rc(220, FLOOR_BOTTOM, 40, 12, Color("2b2b2b"))
	p.rc(222, FLOOR_BOTTOM + 1, 36, 11, Color("b8834a"))
	p.rc(239, FLOOR_BOTTOM + 1, 2, 11, Color("4a2e16"))

func _paint_floor_ac(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y, 50, 13, Color("64748b"))
	p.rc(x + 1, y + 1, 48, 11, Color("f8fafc"))
	p.rc(x + 4, y + 2, 42, 3, Color("cbd5e1"))

func _paint_player(p: Node2D) -> void:
	p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

func _paint_prompt(p: Node2D) -> void:
	if _closing:
		return
	var text: String = ""
	if _seated >= 0:
		text = "[E] Đứng dậy"
	elif _pos.distance_to(DOOR_POS) < 26.0:
		text = "[E] Ra ngoài"
	elif _nearest_seat() >= 0:
		text = "[E] Ngồi học"
	if text != "":
		var w: float = p.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
		var x: float = clampf(_pos.x - w / 2.0, 4.0, VIEW.x - w - 4.0)
		var y: float = _pos.y - 40.0
		p.rc(x - 1, y - 10, w + 2, 14, Color("333333"))
		p.rc(x, y - 9, w, 12, Color(0.08, 0.1, 0.18, 0.92))
		p.ctext(text, x, y, w, 8, Color("ffd23f"))

func _paint_choice_menu(p: Node2D) -> void:
	var r := Rect2(86, 84, 308, 94)
	p.draw_rect(r, Color(0.04, 0.08, 0.14, 0.95))
	p.draw_rect(r, Color("e0b020"), false, 1.0)
	if _choice_building == "D":
		p.draw_string(p.font, Vector2(98, 102), "Tòa D · Chọn phòng học", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe28a"))
		p.draw_string(p.font, Vector2(100, 124), "[1] Thực hành Cơ sở lập trình (Phòng máy tính)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(100, 141), "[2] Toán rời rạc (Giảng đường)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(100, 159), "[Esc] Hủy", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.65))
	elif _choice_building == "F":
		p.draw_string(p.font, Vector2(98, 102), "Tòa F · Chọn phòng học", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe28a"))
		p.draw_string(p.font, Vector2(100, 124), "[1] Vi tích phân 1 (Phòng học 1)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(100, 141), "[2] Cơ sở lập trình lý thuyết (Phòng học 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		p.draw_string(p.font, Vector2(100, 159), "[Esc] Hủy", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.65))

# ======================= GỢI Ý BẤM [E] NGOÀI TRỜI =======================

func draw_front_layer() -> void:
	if inside or _choice_building != "" or game.is_busy():
		return
	var b: String = _near_direct_building()
	var label: String = ""
	match b:
		"A":
			label = "Bấm [E] để vào Giảng đường Tòa A"
		"B":
			label = "Bấm [E] để vào Giảng đường Tòa B"
		"D":
			label = "Bấm [E] để vào Tòa D (TH CSLT / Toán rời rạc)"
		"E":
			label = "Bấm [E] để vào Tòa E (Nhập môn CNTT)"
		"F":
			label = "Bấm [E] để vào Tòa F (Vi tích phân / CSLT)"
		"G":
			label = "Bấm [E] để vào Giảng đường Tòa G"
	if label == "" and _near_ndh_door():
		label = "Bấm [E] để vào Nhà Điều hành (TH Toán rời rạc)"
	if label == "":
		return
	var w: float = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(label, px - w / 2.0, py, w, 8, Color("ffd23f"))
