extends "res://scripts/features/feature.gd"
# CHỨC NĂNG RA / VÀO CỬA CÁC TÒA NHÀ
# Tòa A, B, C, D, E, F - Nhà Thể Dục - Nhà Điều hành - Nhà ăn (căn tin).
#
# Cách chơi:
#   1. Đi tới đứng ngay trước cửa tòa nhà (dưới chân cửa): cửa được viền vàng và hiện "[E] Vào ...". Bấm E để vào.
#   2. Màn hình tối dần rồi bạn ở bên trong phòng. Đi lại bằng W A S D.
#   3. Muốn ra: đứng lên tấm thảm trước cửa ra (phía dưới phòng), hiện "[E] Ra ngoài", bấm E.
#   4. Ra ngoài bạn đứng ngay trước cánh cửa vừa đi ra.
#
# Chỗ cần sửa:
#   - ROOMS (bên dưới): tên, kiểu phòng (classroom / library / gym / office / canteen), màu tường, màu sàn.
#     Thêm tòa mới (vd tòa G): thêm 1 dòng "G": {...} vào ROOMS, cửa tự xuất hiện vì vị trí lấy từ BUILDINGS.
#   - Vị trí cửa KHÔNG viết cứng: lấy từ BUILDINGS, DIEUHANH, KIOSKS trong data/game_data.gd.
#     Dời tòa nhà trong game_data.gd thì cửa tự đi theo.
#   - Hình cánh cửa vẽ trong draw/structures.gd. Hàm _build_doors() bên dưới phải khớp với hình đó
#     (cửa nằm giữa cạnh dưới tòa nhà). Đổi kiểu vẽ cửa thì sửa đúng hàm này.
#   - Đồ đạc trong phòng: _make_items() (vị trí, kích cỡ) và _draw_item() (hình vẽ).
#   - Hình người chơi trong phòng: _draw_me() (khớp với draw/overlay.gd; đổi skin nhân vật thì sửa chỗ đó).
#   - Âm thanh (tùy chọn, bỏ file vào assets/audio/): door_open, door_close.
#
# Dùng từ chức năng khác (vd điểm danh, học thư viện, ăn uống bên trong phòng):
#   Feature này có 2 tín hiệu: entered(place_id) và exited(place_id), place_id = "A", "B", ... "NHÀ THỂ DỤC",
#   "NHÀ ĐIỀU HÀNH", "NHÀ ĂN". Biến current = place_id đang ở trong ("" nếu đang ở ngoài).
#   Cách nối (đặt feature đó SAU building_doors.gd trong registry.gd):
#       for f in game.features:
#           if f.has_signal("entered"):
#               f.entered.connect(_on_enter)
#               f.exited.connect(_on_exit)
#   Trong lúc ở trong phòng, feature này luôn active = true nên game.is_busy() là true
#   (các chức năng khác như nhảy múa, câu cá sẽ không tự bật).

signal entered(place_id: String)
signal exited(place_id: String)

const KEY_USE := KEY_E              # phím vào / ra cửa
const FADE_TIME := 0.28             # số giây để màn hình tối dần (và sáng lại)
const ROOM := Vector2(288, 176)     # kích thước phòng bên trong (px)
const ROOM_SHIFT := Vector2(-10, 2) # lệch phòng khỏi giữa màn hình (tránh bản đồ nhỏ ở góc phải)
const WALL_H := 40.0                # chiều cao dải tường phía trên phòng
const GYM_ID := "NHÀ THỂ DỤC"       # tên trong BUILDINGS (game_data.gd)
const OFFICE_ID := "NHÀ ĐIỀU HÀNH"
const CANTEEN_ID := "NHÀ ĂN"
const CANTEEN_KIOSK := "Nhà ăn"     # tên quầy trong KIOSKS (game_data.gd)

enum Phase { OUTSIDE, GOING_IN, INSIDE, GOING_OUT }

# Khóa của ROOMS = tên tòa trong BUILDINGS (hoặc OFFICE_ID / CANTEEN_ID). Tòa nào không có ở đây thì chưa có cửa (vd tòa G).
# layout: classroom | library | gym | office | canteen
const ROOMS: Dictionary = {
	"A": {"label": "Tòa A", "title": "Tòa A - Giảng đường", "layout": "classroom", "wall": Color("efe3c0"), "floor": Color("cdb98f")},
	"B": {"label": "Tòa B", "title": "Tòa B - Giảng đường, khu tự học", "layout": "classroom", "wall": Color("efe3c0"), "floor": Color("c8b48a")},
	"C": {"label": "Tòa C", "title": "Tòa C - Thư viện", "layout": "library", "wall": Color("e9dcc0"), "floor": Color("b8a27c")},
	"D": {"label": "Tòa D", "title": "Tòa D - Giảng đường", "layout": "classroom", "wall": Color("efe3c0"), "floor": Color("cdb98f")},
	"E": {"label": "Tòa E", "title": "Tòa E - Giảng đường lớn", "layout": "classroom", "wall": Color("f2e6c4"), "floor": Color("c4af84")},
	"F": {"label": "Tòa F", "title": "Tòa F - Giảng đường", "layout": "classroom", "wall": Color("efe3c0"), "floor": Color("cdb98f")},
	"NHÀ THỂ DỤC": {"label": "Nhà Thể Dục", "title": "Nhà Thể Dục - Sân tập trong nhà", "layout": "gym", "wall": Color("e9efe9"), "floor": Color("d9a85f")},
	"NHÀ ĐIỀU HÀNH": {"label": "Nhà Điều hành", "title": "Nhà Điều hành - Các phòng ban", "layout": "office", "wall": Color("dcd9cf"), "floor": Color("c7c2b0")},
	"NHÀ ĂN": {"label": "Nhà ăn", "title": "Nhà ăn - Cơm, bún, trà đá", "layout": "canteen", "wall": Color("f2e6c9"), "floor": Color("e2d4b2")},
}

const OFFICE_SIGNS: Array = ["P. Đào tạo", "P. CTSV", "Đoàn - Hội", "Khảo thí"]
const BOOKS: Array = [Color("c0392b"), Color("2e86c1"), Color("f1c40f"), Color("27ae60"), Color("8e44ad"), Color("e67e22"), Color("ecf0f1")]

var doors: Array = []           # mỗi cửa: {room, leaf, zone, exit_pos}
var phase: Phase = Phase.OUTSIDE
var fade := 0.0                 # 0 = trong suốt, 1 = đen kịt
var fade_rect: ColorRect
var entering: Dictionary = {}   # cửa đang đi qua
var current := ""               # place_id đang ở trong ("" = đang ở ngoài)
var items: Array = []           # đồ đạc trong phòng
var ipos := Vector2.ZERO        # vị trí chân người chơi trong phòng (tọa độ phòng, gốc ở góc trên trái phòng)
var exit_open := 0.0            # 0..1: cửa ra mở bao nhiêu (để vẽ)

func _ready() -> void:
	_build_doors()
	var layer := CanvasLayer.new()
	layer.layer = 9             # nằm trên sổ tay (layer 8) để màn hình tối phủ hết
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.size = Vector2(480, 270)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0, 0, 0, 0)
	layer.add_child(fade_rect)

# ======================= TẠO DANH SÁCH CỬA TỪ DỮ LIỆU BẢN ĐỒ =======================

func _build_doors() -> void:
	doors.clear()
	var buildings: Array = game.BUILDINGS
	for b in buildings:
		var id := str(b[0])
		if not ROOMS.has(id):
			continue
		var r := Rect2(float(b[1]), float(b[2]), float(b[3]), float(b[4]))
		var cx: float = r.position.x + r.size.x * 0.5
		if id == GYM_ID:
			_add_door(id, Rect2(cx - 14.0, r.end.y - 20.0, 28.0, 20.0))   # khớp draw_building() nhánh Nhà Thể Dục
		else:
			_add_door(id, Rect2(cx - 12.0, r.end.y - 22.0, 24.0, 22.0))   # khớp draw_building() cửa kính ở giữa
	var office: Rect2 = game.DIEUHANH
	var ocx: float = office.position.x + office.size.x * 0.5
	_add_door(OFFICE_ID, Rect2(ocx - 30.0, office.end.y - 26.0, 60.0, 26.0))   # khớp draw_dieuhanh()
	var kiosks: Array = game.KIOSKS
	for k in kiosks:
		if str(k[0]) == CANTEEN_KIOSK:
			_add_door(CANTEEN_ID, Rect2(float(k[1]) + 15.0, float(k[2]) + 9.0, 8.0, 11.0))   # khớp draw_kiosk()

# leaf = hình cánh cửa; zone = chỗ đứng để bấm E (ngay dưới chân cửa); exit_pos = chỗ xuất hiện khi đi ra
func _add_door(room_id: String, leaf: Rect2) -> void:
	var cx: float = leaf.position.x + leaf.size.x * 0.5
	doors.append({
		"room": room_id,
		"leaf": leaf,
		"zone": Rect2(leaf.position.x - 10.0, leaf.end.y, leaf.size.x + 20.0, 26.0),
		"exit_pos": Vector2(cx, leaf.end.y + 8.0),
	})

func _near_door() -> Dictionary:
	var p: Vector2 = game.player
	for d in doors:
		var zone := Rect2(d["zone"])
		if zone.has_point(p):
			return d
	return {}

func is_inside() -> bool:
	return current != ""

# ======================= NHẬP LIỆU =======================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.physical_keycode != KEY_USE:
		return
	if phase == Phase.OUTSIDE:
		if game.is_busy():
			return
		var d := _near_door()
		if d.is_empty():
			return
		_start_enter(d)
		get_viewport().set_input_as_handled()
	elif phase == Phase.INSIDE:
		if _other_busy():
			return
		if _exit_zone().has_point(ipos):
			_start_leave()
			get_viewport().set_input_as_handled()

# true khi có chức năng KHÁC đang chạy (vd sổ tay đang mở) -> đứng yên, không bấm E
func _other_busy() -> bool:
	for f in game.features:
		if f != self and f.active:
			return true
	return false

# ======================= VÀO / RA =======================

func _start_enter(d: Dictionary) -> void:
	entering = d
	phase = Phase.GOING_IN
	begin()                          # active = true -> người chơi ngoài đường đứng yên
	game.audio.play_sfx("door_open")

func _start_leave() -> void:
	phase = Phase.GOING_OUT
	game.audio.play_sfx("door_close")

func _arrive_inside() -> void:
	current = str(entering["room"])
	var room: Dictionary = Dictionary(ROOMS[current])
	items = _make_items(str(room["layout"]))
	items.sort_custom(func(a, b): return a.r.end.y < b.r.end.y)
	ipos = Vector2(ROOM.x * 0.5, ROOM.y - 20.0)
	exit_open = 0.0
	game.facing = 1                  # quay mặt vào trong
	phase = Phase.INSIDE
	entered.emit(current)

func _arrive_outside() -> void:
	var d: Dictionary = Dictionary(entering)
	var id := current
	game.player = Vector2(d["exit_pos"])
	game.facing = 0                  # quay mặt ra đường
	current = ""
	items.clear()
	entering = {}
	phase = Phase.OUTSIDE
	finish()                         # active = false -> đi lại được
	exited.emit(id)

func _process(delta: float) -> void:
	match phase:
		Phase.GOING_IN:
			fade = move_toward(fade, 1.0, delta / FADE_TIME)
			if fade >= 1.0:
				_arrive_inside()
		Phase.GOING_OUT:
			fade = move_toward(fade, 1.0, delta / FADE_TIME)
			if fade >= 1.0:
				_arrive_outside()
		Phase.INSIDE:
			fade = move_toward(fade, 0.0, delta / FADE_TIME)
			_update_inside(delta)
		_:
			fade = move_toward(fade, 0.0, delta / FADE_TIME)
	fade_rect.color = Color(0, 0, 0, fade)

func _update_inside(delta: float) -> void:
	game.hud.text = str(ROOMS[current]["title"])
	if not _other_busy():
		_walk(delta)
	var target := 1.0 if _exit_zone().has_point(ipos) else 0.0
	exit_open = move_toward(exit_open, target, delta * 5.0)

# Đi lại trong phòng (giống update_player trong core/world_update.gd nhưng va chạm với đồ đạc trong phòng)
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
	var dir := v.normalized()
	if absf(dir.x) > absf(dir.y):
		game.facing = 2 if dir.x < 0.0 else 3
	else:
		game.facing = 1 if dir.y < 0.0 else 0
	game.anim += delta
	var spd: float = game.SPEED
	var step := dir * spd * delta
	var a := ipos + Vector2(step.x, 0.0)
	if _inside_blocked(a):
		a = ipos
	var b := a + Vector2(0.0, step.y)
	if _inside_blocked(b):
		b = a
	ipos = b

func _inside_blocked(p: Vector2) -> bool:
	if p.x < 12.0 or p.x > ROOM.x - 12.0 or p.y < WALL_H + 8.0 or p.y > ROOM.y - 8.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for it in items:
		var r := Rect2(it["r"])
		if bool(it.get("solid", false)) and hit.intersects(r):
			return true
	return false

# vùng thảm trước cửa ra (tọa độ phòng)
func _exit_zone() -> Rect2:
	return Rect2(ROOM.x * 0.5 - 20.0, ROOM.y - 34.0, 40.0, 34.0)

# ======================= VẼ =======================

# main.gd gọi hàm này mỗi khung hình (trong _draw của thế giới)
func draw_front_layer() -> void:
	if phase == Phase.INSIDE or phase == Phase.GOING_OUT:
		_draw_room()
	elif phase == Phase.OUTSIDE:
		_draw_door_prompt()

# Ngoài đường: viền vàng nhấp nháy quanh cửa + chữ gợi ý phía trên đầu
func _draw_door_prompt() -> void:
	if game.is_busy():
		return
	var d := _near_door()
	if d.is_empty():
		return
	var t: float = game.clock
	var leaf := Rect2(d["leaf"])
	var glow: float = 0.55 + 0.35 * sin(t * 6.0)
	game.draw_rect(leaf.grow(1.0), Color(1.0, 0.85, 0.3, glow), false, 1.0)
	var p: Vector2 = game.player
	var room: Dictionary = Dictionary(ROOMS[str(d["room"])])
	var label := str(room["label"])
	game.ctext("[E] Vào " + label, p.x - 70.0, p.y - 40.0 + sin(t * 5.0) * 1.5, 140.0, 8, Color("ffd23f"))

func _origin() -> Vector2:
	var v: Rect2 = game.view
	return (v.get_center() - ROOM * 0.5 + ROOM_SHIFT).floor()

func _draw_room() -> void:
	var v: Rect2 = game.view
	var o := _origin()
	var room: Dictionary = Dictionary(ROOMS[current])
	var wall := Color(room["wall"])
	var floor_col := Color(room["floor"])
	var layout := str(room["layout"])
	game.rc(v.position.x - 4.0, v.position.y - 4.0, v.size.x + 8.0, v.size.y + 8.0, Color("101218"))   # che hết bên ngoài
	game.rc(o.x - 2.0, o.y - 2.0, ROOM.x + 4.0, ROOM.y + 4.0, Color("2b2b2b"))
	game.rc(o.x, o.y, ROOM.x, WALL_H, wall)
	game.rc(o.x, o.y + WALL_H - 5.0, ROOM.x, 5.0, wall.darkened(0.2))
	game.rc(o.x, o.y + WALL_H, ROOM.x, ROOM.y - WALL_H, floor_col)
	var tile := floor_col.darkened(0.08)
	for x in range(16, int(ROOM.x), 16):
		game.rc(o.x + x, o.y + WALL_H, 1.0, ROOM.y - WALL_H, tile)
	for y in range(int(WALL_H) + 8, int(ROOM.y), 16):
		game.rc(o.x, o.y + y, ROOM.x, 1.0, tile)
	_draw_wall_deco(layout, o)
	_draw_floor_deco(layout, o)
	_draw_exit_door(o, wall)
	# đồ đạc và người chơi xếp theo chiều sâu (đứng sau bàn thì bàn che)
	var me_drawn := false
	for it in items:
		var r := Rect2(it["r"])
		if not me_drawn and r.end.y > ipos.y:
			_draw_me(o + ipos)
			me_drawn = true
		_draw_item(it, o)
	if not me_drawn:
		_draw_me(o + ipos)
	if phase == Phase.INSIDE and _exit_zone().has_point(ipos) and not _other_busy():
		var t: float = game.clock
		game.ctext("[E] Ra ngoài", o.x + ipos.x - 70.0, o.y + ipos.y - 40.0 + sin(t * 5.0) * 1.5, 140.0, 8, Color("ffd23f"))

# Hình người chơi. KHỚP với draw_sorted_items() trong draw/overlay.gd; đổi skin nhân vật thì sửa chỗ này.
func _draw_me(pos: Vector2) -> void:
	game.draw_person(pos, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
	game.ctext("Bạn", pos.x - 15.0, pos.y - 28.0, 30.0, 8, Color("ffd23f"))

# Cửa ra ở giữa cạnh dưới: 2 cánh kính trượt ra hai bên khi bạn đứng trên thảm
func _draw_exit_door(o: Vector2, wall: Color) -> void:
	var dx := o.x + ROOM.x * 0.5
	var dy := o.y + ROOM.y
	game.rc(o.x, dy - 6.0, ROOM.x, 6.0, wall.darkened(0.4))
	game.rc(dx - 18.0, dy - 8.0, 36.0, 8.0, Color("3a2f2a"))
	game.rc(dx - 16.0, dy - 7.0, 32.0, 7.0, Color("9fd3f0"))
	var gap := 32.0 * exit_open
	game.rc(dx - gap * 0.5, dy - 7.0, gap, 7.0, Color("fff1b8"))
	game.rc(dx - 16.0, dy - 18.0, 32.0, 10.0, Color("8e1f2c"))
	game.rc(dx - 16.0, dy - 18.0, 32.0, 2.0, Color("b5424f"))

func _frame(o: Vector2, r: Rect2, fill: Color) -> void:
	var p := o + r.position
	game.rc(p.x - 2.0, p.y - 2.0, r.size.x + 4.0, r.size.y + 4.0, Color("7a5429"))
	game.rc(p.x, p.y, r.size.x, r.size.y, fill)

func _window(o: Vector2, x: float, y: float) -> void:
	game.rc(o.x + x - 2.0, o.y + y - 2.0, 44.0, 26.0, Color("4a6b82"))
	game.rc(o.x + x, o.y + y, 40.0, 22.0, Color("8fc9e6"))
	game.rc(o.x + x, o.y + y, 40.0, 5.0, Color("c8e8f7"))
	game.rc(o.x + x + 19.0, o.y + y, 2.0, 22.0, Color("4a6b82"))

# Trang trí trên dải tường phía trên
func _draw_wall_deco(layout: String, o: Vector2) -> void:
	match layout:
		"classroom":
			_window(o, 14.0, 8.0)
			_window(o, ROOM.x - 54.0, 8.0)
			_frame(o, Rect2(88, 7, 112, 26), Color("2f4f3a"))
			game.rc(o.x + 96.0, o.y + 14.0, 44.0, 1.0, Color(1, 1, 1, 0.6))
			game.rc(o.x + 96.0, o.y + 20.0, 62.0, 1.0, Color(1, 1, 1, 0.6))
			game.rc(o.x + 96.0, o.y + 26.0, 30.0, 1.0, Color(1, 1, 1, 0.6))
		"library":
			_window(o, 20.0, 8.0)
			_window(o, 124.0, 8.0)
			_window(o, 228.0, 8.0)
		"gym":
			_window(o, 20.0, 8.0)
			_window(o, ROOM.x - 60.0, 8.0)
			_frame(o, Rect2(ROOM.x * 0.5 - 28.0, 9.0, 56.0, 18), Color("20242a"))
			game.ctext("HCMUS", o.x + ROOM.x * 0.5 - 28.0, o.y + 22.0, 56.0, 8, Color("ffd23f"))
		"office":
			for i in OFFICE_SIGNS.size():
				var x := 18.0 + i * 66.0
				game.rc(o.x + x, o.y + 6.0, 36.0, 22.0, Color("7a5429"))
				game.rc(o.x + x + 3.0, o.y + 9.0, 30.0, 19.0, Color("b9c4b0"))
				game.rc(o.x + x + 28.0, o.y + 20.0, 2.0, 2.0, Color("e0b020"))
				game.ctext(OFFICE_SIGNS[i], o.x + x - 15.0, o.y + 37.0, 66.0, 7, Color("2b2b2b"))
		"canteen":
			_window(o, 14.0, 8.0)
			_window(o, ROOM.x - 54.0, 8.0)
			_frame(o, Rect2(70, 7, 148, 26), Color("2b2b2b"))
			game.ctext("CƠM - BÚN - TRÀ ĐÁ", o.x + 70.0, o.y + 24.0, 148.0, 8, Color("ffe066"))

# Trang trí trên sàn (vẽ dưới đồ đạc)
func _draw_floor_deco(layout: String, o: Vector2) -> void:
	match layout:
		"gym":
			var line := Color(1, 1, 1, 0.75)
			game.draw_rect(Rect2(o.x + 24.0, o.y + 52.0, ROOM.x - 48.0, 88.0), line, false, 1.0)
			game.rc(o.x + ROOM.x * 0.5, o.y + 52.0, 1.0, 88.0, line)
			game.draw_arc(Vector2(o.x + ROOM.x * 0.5, o.y + 96.0), 16.0, 0.0, TAU, 32, line, 1.0)
			game.draw_rect(Rect2(o.x + 24.0, o.y + 76.0, 36.0, 40.0), line, false, 1.0)
			game.draw_rect(Rect2(o.x + ROOM.x - 60.0, o.y + 76.0, 36.0, 40.0), line, false, 1.0)
		"office":
			game.rc(o.x + 76.0, o.y + 98.0, 136.0, 40.0, Color("a8453d"))
			game.draw_rect(Rect2(o.x + 80.0, o.y + 102.0, 128.0, 32.0), Color("d8b46a"), false, 1.0)
		"library":
			game.rc(o.x + 112.0, o.y + WALL_H + 4.0, 64.0, 96.0, Color("7e8fae"))
			game.draw_rect(Rect2(o.x + 116.0, o.y + WALL_H + 8.0, 56.0, 88.0), Color("c9d3e6"), false, 1.0)

# ======================= ĐỒ ĐẠC TRONG PHÒNG =======================
# Tọa độ tính từ góc trên trái của phòng. Phòng rộng ROOM.x, cao ROOM.y. Dải tường cao WALL_H.
# Chừa trống chỗ gần cửa ra (đáy giữa phòng) để người chơi không bị kẹt.

func _item(kind: String, r: Rect2, extra: Dictionary = {}) -> Dictionary:
	var d := {"kind": kind, "r": r, "solid": true}
	d.merge(extra, true)
	return d

func _make_items(layout: String) -> Array:
	var list: Array = []
	match layout:
		"classroom":
			list.append(_item("desk", Rect2(116, 46, 56, 14)))   # bàn giảng viên
			for row in 3:
				for col in 3:
					list.append(_item("desk", Rect2(24 + col * 86, 82 + row * 24, 68, 14), {"seats": 2}))
		"library":
			for y in [56, 92]:
				list.append(_item("shelf", Rect2(24, y, 88, 16)))
				list.append(_item("shelf", Rect2(176, y, 88, 16)))
			list.append(_item("table", Rect2(104, 124, 80, 16), {"col": Color("c79257")}))
		"gym":
			list.append(_item("bench", Rect2(12, 146, 44, 8)))
			list.append(_item("bench", Rect2(ROOM.x - 56.0, 146, 44, 8)))
			list.append(_item("hoop", Rect2(6, 78, 10, 30)))
			list.append(_item("hoop", Rect2(ROOM.x - 16.0, 78, 10, 30)))
		"office":
			list.append(_item("counter", Rect2(64, 66, 160, 18)))
			list.append(_item("bench", Rect2(14, 110, 44, 10)))
			list.append(_item("bench", Rect2(ROOM.x - 58.0, 110, 44, 10)))
			list.append(_item("plant", Rect2(14, 50, 12, 12)))
			list.append(_item("plant", Rect2(ROOM.x - 26.0, 50, 12, 12)))
		"canteen":
			list.append(_item("counter", Rect2(20, 46, ROOM.x - 40.0, 16)))
			for row in 2:
				for col in 3:
					list.append(_item("table", Rect2(28 + col * 90, 88 + row * 34, 52, 18)))
	return list

func _draw_item(it: Dictionary, o: Vector2) -> void:
	var r := Rect2(it["r"])
	var p := o + r.position
	match str(it["kind"]):
		"desk":
			game.rc(p.x + 1.0, p.y + r.size.y, r.size.x - 2.0, 3.0, Color(0, 0, 0, 0.18))
			game.rc(p.x, p.y, r.size.x, r.size.y, Color("a9783f"))
			game.rc(p.x, p.y, r.size.x, 3.0, Color("c79257"))
			game.rc(p.x, p.y + r.size.y - 2.0, r.size.x, 2.0, Color("7a5429"))
			var seats := int(it.get("seats", 0))
			for s in seats:
				game.rc(p.x + 10.0 + s * (r.size.x - 32.0), p.y + r.size.y + 3.0, 12.0, 6.0, Color("5b6f8a"))
		"table":
			var top := Color(it.get("col", Color("d7dde3")))
			game.rc(p.x + 1.0, p.y + r.size.y, r.size.x - 2.0, 3.0, Color(0, 0, 0, 0.18))
			game.rc(p.x, p.y, r.size.x, r.size.y, top.darkened(0.15))
			game.rc(p.x, p.y, r.size.x, r.size.y - 3.0, top)
			game.rc(p.x - 8.0, p.y + 4.0, 6.0, 8.0, Color("8a6a4a"))
			game.rc(p.x + r.size.x + 2.0, p.y + 4.0, 6.0, 8.0, Color("8a6a4a"))
		"counter":
			game.rc(p.x + 2.0, p.y + r.size.y, r.size.x, 3.0, Color(0, 0, 0, 0.2))
			game.rc(p.x, p.y, r.size.x, r.size.y, Color("8a5a30"))
			game.rc(p.x, p.y, r.size.x, 6.0, Color("e2c9a0"))
			game.rc(p.x, p.y + 6.0, r.size.x, 1.0, Color("5b3a1c"))
			var n := 0
			for i in range(8, int(r.size.x) - 14, 26):
				game.rc(p.x + i, p.y + 1.0, 12.0, 4.0, Color("c9d6df") if n % 2 == 0 else Color("f3e3b0"))
				n += 1
		"shelf":
			game.rc(p.x, p.y, r.size.x, r.size.y, Color("6b4a2a"))
			game.rc(p.x, p.y, r.size.x, 2.0, Color("8a6238"))
			for row in 2:
				var by := p.y + 2.0 + row * 7.0
				var k := 0
				for bx in range(2, int(r.size.x) - 2, 4):
					game.rc(p.x + bx, by, 3.0, 6.0, BOOKS[(k * 3 + row * 2 + int(r.position.x)) % BOOKS.size()])
					k += 1
				game.rc(p.x, by + 6.0, r.size.x, 1.0, Color("4a3018"))
		"bench":
			game.rc(p.x, p.y + r.size.y, r.size.x, 2.0, Color(0, 0, 0, 0.2))
			game.rc(p.x, p.y, r.size.x, r.size.y, Color("b5651d"))
			game.rc(p.x, p.y, r.size.x, 2.0, Color("d98a3d"))
			game.rc(p.x + 3.0, p.y + r.size.y, 3.0, 3.0, Color("5a3a22"))
			game.rc(p.x + r.size.x - 6.0, p.y + r.size.y, 3.0, 3.0, Color("5a3a22"))
		"plant":
			game.rc(p.x + 2.0, p.y + 7.0, 8.0, 5.0, Color("b5651d"))
			game.draw_circle(p + Vector2(6.0, 4.0), 6.0, Color("2a6f33"))
			game.draw_circle(p + Vector2(4.0, 2.0), 4.0, Color("3c9a40"))
		"hoop":
			game.rc(p.x, p.y, r.size.x, 6.0, Color("f4f4f4"))
			game.draw_rect(Rect2(p.x, p.y, r.size.x, 6.0), Color("c0392b"), false, 1.0)
			game.rc(p.x + 3.0, p.y + 6.0, 4.0, r.size.y - 10.0, Color("7a8087"))
			game.rc(p.x + 1.0, p.y + r.size.y - 4.0, 8.0, 4.0, Color("3a3f45"))
