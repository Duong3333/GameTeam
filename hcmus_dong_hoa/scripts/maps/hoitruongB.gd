extends "res://scripts/features/feature.gd"
class_name HoiTruongB
# HỘI TRƯỜNG B (bên trong Tòa B).
#
# Phím       : E = vào hội trường (đứng trước cửa Tòa B) / nghe MC (đứng gần MC) / ra ngoài (đứng ở thảm đỏ cửa sau).
#              F = ngồi vào ghế trống ở lối đi giữa / đứng dậy (cùng một phím). W A S D = di chuyển.
# Bố cục     : sân khấu ở PHÍA TRÊN màn hình, cửa vào ở phía dưới. Logic (va chạm, ghế, vị trí) dùng toạ độ gốc (sân khấu ở y lớn);
#              phần vẽ lật dọc, nên W đi lên (về phía sân khấu) và S đi xuống (về phía cửa).
# Khi ngồi   : camera chuyển sang góc nhìn thứ nhất, ghim vào sân khấu (không phóng to / thu nhỏ).
#
# Module bản đồ được đăng ký tại scripts/maps/registry.gd. Dùng lại của game: game.get_doorways() (cửa có "interior": "hall_b"),
# game.player / is_busy / font / logo / hud, game.rc / ctext, draw_front_layer(), begin() / finish() của feature.gd.

const DOOR_RANGE := 24.0           # đứng cách cửa tối đa bấm E mới vào được (px), giống building_doors.gd
const WALK_SPEED := 72.0
const SIT_KEY := KEY_F             # phím ngồi / đứng dậy (cùng một phím)
var seat_blend := 0.0              # 0 = camera bám người chơi, 1 = camera nhìn từ ghế về phía sân khấu (mượt dần)

var inside := false
var pos := Vector2(280.0, 64.0)    # chân người chơi, tọa độ cục bộ hội trường
var face := 0                      # hướng nhìn của người chơi: 0 xuống, 1 lên, 2 trái, 3 phải (giống characters.gd)
var moving := false
var seat_idx := -1                 # >= 0: đang ngồi ở ghế thứ seat_idx (chỉ số trong student_seats())
var sit_target := -1               # ghế trống gần nhất có thể ngồi (-1 = không có)
var mc_line := 0
var time := 0.0
var _layer: CanvasLayer
var _canvas: HallCanvas
var _door := Vector2.ZERO          # vị trí cửa Tòa B ngoài trời (lấy từ game.get_doorways())
var _door_searched := false
var _door_found := false

# ---------- DỮ LIỆU BỐ CỤC (tọa độ cục bộ, 0,0 = góc trên trái) ----------
# Tọa độ CỤC BỘ của hội trường (0,0 = góc trên trái). Bố cục lấy theo ảnh thật:
# cửa sau ở trên cùng -> bậc thang giữa -> bàn gỗ hai bên -> bàn đoàn trải khăn trắng -> sân khấu.
const SIZE := Vector2(560.0, 480.0)
const SPAWN := Vector2(280.0, 64.0)            # nơi đứng khi vừa bước vào
const EXIT := Rect2(262.0, 44.0, 36.0, 8.0)    # thảm cửa: đứng gần rồi bấm E để ra ngoài
const TIERS := 8
const TIER_Y0 := 46.0
const TIER_H := 28.0
const AISLE_X := 252.0
const AISLE_W := 56.0
const FRONT_Y := 322.0
const STAGE_Y := 346.0
const WALL_Y := 412.0
const MC_POS := Vector2(318.0, 401.0)          # chân của MC (thầy MC đứng sau bục phát biểu)
const SIGN := Rect2(248.0, 322.0, 64.0, 18.0)  # bảng "We ♥ FIT"
const BUST := Rect2(70.0, 380.0, 30.0, 30.0)   # tượng Bác trên bệ
const PODIUM := Rect2(300.0, 374.0, 36.0, 36.0)   # bục ở chỗ MC đứng (tâm x = MC_POS.x)
const FLOWER := Rect2(452.0, 366.0, 28.0, 44.0) # lẵng hoa hướng dương
const SPEAKER_L := Rect2(34.0, 388.0, 22.0, 22.0)
const SPEAKER_R := Rect2(504.0, 388.0, 22.0, 22.0)
var MC_LINES := ["Thân chào các bạn tân sinh viên K26!", "Khoa Công nghệ Thông tin chào đón các bạn!", "Giơ hộp quà lên chụp ảnh nào!", "Cười lên, 1 - 2 - 3!"]

# Hàm băm cố định theo toạ độ: dùng chung cho vẽ và cho logic ghế trống (để hai bên luôn khớp nhau).
static func hash_at(a: float, b: float, salt: float = 0.0) -> int:
	return int(fposmod(sin(a * 12.9898 + b * 78.233 + salt * 37.719) * 43758.5453, 1.0) * 100.0)

# Ghế trống = ghế không có sinh viên ngồi (người chơi có thể vào ngồi).
static func seat_empty(p: Vector2) -> bool:
	return hash_at(p.x, p.y) < 12

# Chỗ ngồi sinh viên (góc trên trái của từng người), 18 chỗ mỗi bậc, bậc 0 ở xa sân khấu nhất.
static func student_seats() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for tier in TIERS:
		var y := TIER_Y0 + tier * TIER_H + 1.0
		for i in 9:
			out.append(Vector2(34.0 + i * 22.0, y))
		for i in 9:
			out.append(Vector2(336.0 + i * 22.0, y))
	return out

# Chỗ ngồi của thầy cô ở bàn đoàn (7 người mỗi bên).
static func teacher_seats() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var y := TIER_Y0 + TIERS * TIER_H + 1.0
	for i in 7:
		out.append(Vector2(36.0 + i * 28.0, y))
	for i in 7:
		out.append(Vector2(336.0 + i * 28.0, y))
	return out

# Chỗ đứng ở lối đi giữa sau khi đứng dậy khỏi ghế idx.
static func stand_pos_for(idx: int) -> Vector2:
	var tier := idx / 18
	var left := (idx % 18) < 9
	var y := TIER_Y0 + tier * TIER_H + 14.0
	var x := AISLE_X + 6.0 if left else AISLE_X + AISLE_W - 6.0
	return Vector2(x, y)

static func solid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(0.0, 0.0, 560.0, 44.0),                       # tường sau (có cửa)
		Rect2(0.0, 0.0, 22.0, 480.0),                       # tường trái
		Rect2(538.0, 0.0, 22.0, 480.0),                     # tường phải
		Rect2(22.0, WALL_Y, 516.0, 68.0),            # tường gỗ sân khấu
		Rect2(22.0, 46.0, 228.0, 224.0),                    # dãy bàn học bên trái
		Rect2(310.0, 46.0, 228.0, 224.0),                   # dãy bàn học bên phải
		Rect2(22.0, 270.0, 214.0, 52.0),                    # bàn đoàn trái
		Rect2(324.0, 270.0, 214.0, 52.0),                   # bàn đoàn phải
		SIGN, BUST, PODIUM, FLOWER,
		SPEAKER_L, SPEAKER_R,
	]
	return out

static func is_walkable(p: Vector2, radius: float = 4.0) -> bool:
	var probe := Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	if not Rect2(Vector2.ZERO, SIZE).encloses(probe):
		return false
	for r in solid_rects():
		if r.intersects(probe):
			return false
	return true

static func validate_layout() -> bool:
	var ok := true
	if not is_walkable(SPAWN):
		push_error("Hội trường B: điểm spawn bị chặn %s" % SPAWN)
		ok = false
	for r in solid_rects():
		if r.intersects(EXIT):
			push_error("Hội trường B: vật cản đè lên thảm cửa: %s" % r)
			ok = false
	for i in 144:
		if not is_walkable(stand_pos_for(i)):
			push_error("Hội trường B: chỗ đứng dậy của ghế %d bị chặn" % i)
			ok = false
	return ok

func _ready() -> void:
	if OS.is_debug_build():
		assert(validate_layout())
	_layer = CanvasLayer.new()
	_layer.layer = 10   # trên mọi HUD của game (6-9) để thanh gợi ý phím của game không đè lên chữ của hội trường
	_layer.visible = false
	add_child(_layer)
	_canvas = HallCanvas.new()
	_canvas.hall = self
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_layer.add_child(_canvas)

# ======================= VÀO / RA =======================

# Cửa Tòa B ngoài trời: phần tử của game.get_doorways() có "interior" == "hall_b".
func _near_door_outside() -> bool:
	if not _door_searched:
		_door_searched = true
		for d in game.get_doorways():
			if str(d.get("interior", "")) == "hall_b":
				_door = d["position"]
				_door_found = true
				break
		if not _door_found:
			push_warning("Hội trường B: không thấy cửa nào có \"interior\": \"hall_b\" trong get_doorways()")
	return _door_found and game.player.distance_to(_door) < DOOR_RANGE

func begin() -> void:
	super()
	inside = true
	pos = SPAWN
	face = 0
	moving = false
	seat_idx = -1
	sit_target = -1
	mc_line = 0
	seat_blend = 0.0
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong hội trường
	_canvas.queue_redraw()

func finish() -> void:
	super()
	inside = false
	moving = false
	seat_idx = -1
	sit_target = -1
	_layer.visible = false
	game.hud.visible = true

# Ghế trống gần nhất mà người chơi (đứng ở lối đi giữa) có thể ngồi; -1 nếu không có.
func find_sit_target() -> int:
	if seat_idx >= 0:
		return -1
	if pos.x < AISLE_X - 4.0 or pos.x > AISLE_X + AISLE_W + 4.0:
		return -1
	if pos.y < TIER_Y0 - 4.0 or pos.y > TIER_Y0 + TIERS * TIER_H:
		return -1
	var tier := clampi(int((pos.y - TIER_Y0) / TIER_H), 0, TIERS - 1)
	var left := pos.x < AISLE_X + AISLE_W * 0.5
	var seats := student_seats()
	var best := -1
	var best_d := 140.0
	for t in range(maxi(tier - 1, 0), mini(tier + 1, TIERS - 1) + 1):
		var from_i := t * 18 + (0 if left else 9)
		for n in range(from_i, from_i + 9):
			var p := seats[n]
			if not seat_empty(p):
				continue
			var d := pos.distance_to(p + Vector2(6.0, 12.0))
			if d < best_d:
				best_d = d
				best = n
	return best

func sit_down(idx: int) -> void:
	var seats := student_seats()
	seat_idx = idx
	sit_target = -1
	face = 0
	moving = false
	pos = seats[idx] + Vector2(6.0, 22.0)   # chân người ngồi (camera bám theo)

func stand_up() -> void:
	if seat_idx < 0:
		return
	pos = stand_pos_for(seat_idx)
	seat_idx = -1
	face = 0

# Đứng gần thảm đỏ ở cửa sau thì bấm E để ra ngoài.
func near_exit() -> bool:
	return EXIT.grow(10.0).has_point(pos)

# E: ngoài trời = vào hội trường; trong hội trường = ra ngoài (ở thảm đỏ) hoặc nói chuyện với MC khi đứng gần.
# F (SIT_KEY): ngồi vào ghế trống / đứng dậy.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	# F: ngồi vào ghế trống / đứng dậy (cùng một phím)
	if inside and k.physical_keycode == SIT_KEY:
		if seat_idx >= 0:
			stand_up()
		elif sit_target >= 0:
			sit_down(sit_target)
		get_viewport().set_input_as_handled()
		return
	if k.physical_keycode != KEY_E:
		return
	if inside:
		if seat_idx < 0:
			if near_exit():
				finish()
			elif pos.distance_to(MC_POS) < 60.0:
				mc_line = (mc_line + 1) % MC_LINES.size()
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and _near_door_outside():
		begin()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not inside:
		return
	time += delta
	seat_blend = lerpf(seat_blend, 1.0 if seat_idx >= 0 else 0.0, 1.0 - exp(-delta * 5.0))   # chuyển góc nhìn mượt khi ngồi / đứng dậy
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y += 1.0   # lật dọc: lên màn hình = về phía sân khấu (y gốc tăng)
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if seat_idx >= 0:
		# đang ngồi: đứng yên, chỉ bấm F để đứng dậy (phím di chuyển không làm gì)
		moving = false
		_canvas.queue_redraw()
		return
	moving = false
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		moving = true
		if absf(dir.x) > absf(dir.y):
			face = 3 if dir.x > 0.0 else 2
		else:
			face = 0 if dir.y > 0.0 else 1
		var step := dir * WALK_SPEED * delta
		if is_walkable(pos + Vector2(step.x, 0.0)):
			pos.x += step.x
		if is_walkable(pos + Vector2(0.0, step.y)):
			pos.y += step.y
	sit_target = find_sit_target()
	_canvas.queue_redraw()

# ======================= VẼ NGOÀI TRỜI =======================

func draw_front_layer() -> void:
	if inside or game.is_busy() or not _near_door_outside():
		return
	# khung chỉ dẫn phía trên đầu người chơi: "Bấm E để vào Hội trường B"
	var text := "Bấm [E] để vào Hội trường B"
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))


# ======================================================================
# LỚP VẼ (inner class). Mọi lệnh draw_* chạy ở đây.
# ======================================================================
class HallCanvas extends Node2D:
	const H := HoiTruongB
	var hall: HoiTruongB
	var view := Rect2()

	var HB_NAVY := Color("22336b")
	var HB_KRAFT := Color("b88a50")
	var HB_SKINS := [Color("f0c8a0"), Color("e6b98e"), Color("d9a679"), Color("f4d3b0")]
	var HB_HAIRS := [Color("16171c"), Color("16171c"), Color("16171c"), Color("2a2018"), Color("3a2a1e"), Color("c9a24a")]
	# beige polo (đồng phục thầy cô khoa), áo dài mint, sơ mi trắng, vest xanh đen
	var HB_TEACHER_SHIRTS := [Color("d4aa86"), Color("d4aa86"), Color("9fe0d0"), Color("d4aa86"), Color("f4f4f4"), Color("1f2f5a"), Color("d4aa86")]

	# ---------- SPRITE pixel (một ký tự = một điểm ảnh, "." = trong suốt) ----------
	# chai nước suối (nhỏ 4x9 cho bàn sinh viên, lớn 5x11 cho bàn đoàn)
	var PAL_BOTTLE := {"c": Color("2f6fd0"), "b": Color("d7eefa"), "w": Color("ffffff"), "d": Color("9ccbe6"), "l": Color("2f6fd0"), "L": Color("1f5fbf"), "n": Color("f4f9ff"), "N": Color("dfe8f2")}
	var SPR_BOTTLE_S := [
		".cc.",
		".bd.",
		"bwbd",
		"bwbd",
		"llLL",
		"nnNN",
		"bwbd",
		"bwbd",
		"dddd",
	]
	var SPR_BOTTLE_L := [
		".ccc.",
		"..bd.",
		".bwbd",
		"bbwbd",
		"bbwbd",
		"llllL",
		"nnnnN",
		"llllL",
		"bbwbd",
		"bbwbd",
		"ddddd",
	]
	# ly trà sữa có ống hút
	var PAL_CUP := {"s": Color("3fa34d"), "w": Color("ffffff"), "t": Color("c8925a"), "d": Color("a8723e"), "m": Color("e8c9a0")}
	var SPR_CUP := [
		".s..",
		".s..",
		"wwww",
		"tttd",
		"mmmd",
		"tttd",
		".tt.",
	]
	# sprite FLAG_PARTY (36x26)
	var PAL_FLAG_PARTY := {"a": Color("ee4a40"), "b": Color("e0302a"), "c": Color("ffe62a"), "d": Color("a81e19")}
	var SPR_FLAG_PARTY := [
		"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbcccbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbcccccbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbccbbccccbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbccccbbccccbbbbbbbbbb",
		"bbbbbbbbbbbbbbbccccccbbccccbbbbbbbbb",
		"bbbbbbbbbbbbbbcccccccbbbcccbbbbbbbbb",
		"bbbbbbbbbbbbbcccccccbbbbcccbbbbbbbbb",
		"bbbbbbbbbbbbbcccccccbbbbccccbbbbbbbb",
		"bbbbbbbbbbbbbbcccccccbbbccccbbbbbbbb",
		"bbbbbbbbbbbbbbbccbccccbbccccbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbb",
		"bbbbbbbbbbbbccbbbbbbcccccccbbbbbbbbb",
		"bbbbbbbbbccccccbbbbbbccccccbbbbbbbbb",
		"bbbbbbbbbccccccbbbbcccccccbbbbbbbbbb",
		"bbbbbbbbbccccccccccccccccccbbbbbbbbb",
		"bbbbbbbbbccccccccccccccccccbbbbbbbbb",
		"bbbbbbbbbbcbbcccccccccbbbcbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"dddddddddddddddddddddddddddddddddddd",
	]
	# sprite FLAG_NAT (36x26)
	var PAL_FLAG_NAT := {"a": Color("ee4a40"), "b": Color("da251d"), "c": Color("ffeb1a"), "d": Color("a81e19")}
	var SPR_FLAG_NAT := [
		"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbccccbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbccccbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbccccccccccccccbbbbbbbbbbb",
		"bbbbbbbbbbbbccccccccccccbbbbbbbbbbbb",
		"bbbbbbbbbbbbbccccccccccbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbccccccbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbcccbbcccbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbcccbbbbcccbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbcbbbbbbbbcbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"dddddddddddddddddddddddddddddddddddd",
	]
	# sprite BUST (34x49)
	var PAL_BUST := {"a": Color("c9962c"), "b": Color("e8c158"), "c": Color("8f6416"), "d": Color("b0801f"), "e": Color("f6c9a0"), "f": Color("5d8a2e"), "g": Color("f4efe0"), "h": Color("fbe2c8"), "i": Color("ffffff"), "j": Color("e8703a"), "k": Color("b8501e"), "l": Color("7a2a10"), "m": Color("e0804e"), "n": Color("c85a28"), "o": Color("6e2a0e"), "p": Color("a8421a"), "q": Color("d46a38"), "r": Color("c0522a"), "s": Color("8a2e12")}
	var SPR_BUST := [
		"..................................",
		"...............aaaaa..............",
		"..............bbaaaaa.............",
		".............bbbbbbbba............",
		"............bcccbbacccc...........",
		"............bbcbbbacaac...........",
		"............bbbbbbaaaac...........",
		"............bbbbbcaaaac...........",
		"............abbcccccaac...........",
		".............abcccccaac...........",
		"..............accccca.............",
		".............ccacccacc............",
		"..........aaaacdcccdcaaaa.........",
		".......cccaaaaacccccaaaaaccc......",
		".......cccaaaaacccccaaaaaccc......",
		".......cccbbbbaacccaabbbbccc......",
		"......cccccaacaaacaaacaaccccc.....",
		"......ccccccccaaacaaacccccccc.....",
		"......cccaaaaaaaacaaaaaaaaccc.....",
		"......cccaaaaaaeeeaaaaaaaaccc.....",
		"..f..cccfagggaehhhefgggaaeeecc..f.",
		"..ff.eeefgiiigehehegiiigehhhec.ff.",
		"..ffehhhegigigehhhegigigeheheffff.",
		"...fjhehgggiijeeeegggiieeehhgggj..",
		"...fehhgiiigehhhegiijgehhhejiiig..",
		"...fkeegigigehehegigigehehegigig..",
		".....llgiiigehhhegiiigehhhegiiig..",
		".....lllggglleeellggglleeellggg...",
		"......lllllllllllllllllllllll.....",
		"...mmmmmmmmmmmmmmmmmmmmmmmmmmmm...",
		"...nnnnnnnnnnnnnnnnnnnnnnnnnnnn...",
		"...oooooooooooooooooooooooooooo...",
		".....pppppppppppppppppppppppp.....",
		".....ponponponponponponponpon.....",
		".....pppppppppppppppppppppppp.....",
		".....nnnnnnnnnnnnnnnnnnnnnnnn.....",
		"......onnnnnnnnnnnnnnnnnnnno......",
		"......oppppppppqqqpppppppppo......",
		"......oppoooooqqqqqooooooppo......",
		"......opporrrqqsssqqrrrroppo......",
		"......opporppqsssssqppproppo......",
		"......opporpqqsssssqqpproppo......",
		"......opporppqqsssqqppproppo......",
		"......opporrrrqqqqqrrrrroppo......",
		"......oppooooooqqqoooooooppo......",
		"......oppppppppppppppppppppo......",
		"....nnnnnnnnnnnnnnnnnnnnnnnnnn....",
		"...oooooooooooooooooooooooooooo...",
		"...oooooooooooooooooooooooooooo...",
	]
	# sprite PODIUM (36x44): bục gỗ có huy hiệu Trường ĐH KHTN (cánh buồm xanh navy, vòng chữ, KHTN, ĐHQG-HCM)
	var PAL_PODIUM := {"a": Color("9aa0aa"), "b": Color("444851"), "c": Color("2b2b2b"), "d": Color("e5322d"), "e": Color("ffd23f"), "f": Color("f4f4f4"), "g": Color("f08a1c"), "h": Color("e0702e"), "i": Color("ff6a5e"), "j": Color("3f9a49"), "k": Color("fff08a"), "l": Color("ffffff"), "m": Color("ffb85a"), "n": Color("2a6f33"), "o": Color("f2c230"), "p": Color("a8420f"), "q": Color("9a3a12"), "r": Color("c8501e"), "s": Color("f4fbff"), "t": Color("3f7fd8"), "u": Color("2b5fb0"), "v": Color("dfe8f2"), "w": Color("7a2e0c"), "x": Color("c9903f"), "y": Color("a8702a"), "z": Color("e0aa5a"), "N": Color("1f2f6a"), "L": Color("465fa0"), "W": Color("f4f4ff")}
	var SPR_PODIUM := [
		"....................................",
		"....................................",
		"...............abbb.................",
		"...............bbbbccc..............",
		"...............bbbb...c.............",
		".......................c............",
		"........................c...........",
		"........................c...........",
		"........................c...........",
		"........................c...........",
		"........................c...........",
		"........................c...........",
		"........................c...........",
		"..ddd...eee...fff...ggg.c.eee...ddd.",
		"hdiiidjekkkejflllfjgmmmgjekkkejdiiid",
		"ndioidjekgkejflolfjgmomgjekgkejdioid",
		"ndiiijjjkkkjjjllljjjmmmjjjkkkjjjiiid",
		"nndddjjjeeejjjfffjjjgggjjjeeejjjdddn",
		"pppqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqppp",
		"pppzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzppp",
		"pppxxxxxxyxxxNNNNNNNNNxxxxxyxxxxxppp",
		"pppxxxxxxyxxNNxyxxxxxyNNxxxyxxxxxppp",
		"pppxxxxxxyxNxxxyxxxxxyxxNxxyxxxxxppp",
		"pppxxxxxxyNxxxxyxxxxxyxxxNxyxxxxxppp",
		"pppxxxxxxNNxxxxyxNxxxyxxxNNyxxxxxppp",
		"pppxxxxxNNxxxxxWNNxxxyxxxxxNxxxxxppp",
		"pppxxxxxxyxxxxWLWNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxxxNWNNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxxNWNWNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxNNNNNNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxLLNNNNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxNNLLLNxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxNNNNLLxxxyxxxxxNxxxxxppp",
		"pppxxxxxNyxxxNNNNNLxxyxxxxxNxxxxxppp",
		"pppxxxxxNNxxxNWNWNWLWyxxxxNyxxxxxppp",
		"pppxxxxxxNxxxNWNWNWNWyxxxxNyxxxxxppp",
		"pppxxxxxxyNxxxxyxxxxxLxxxNxyxxxxxppp",
		"pppxxxxxxyxxxxxyxxxxxyxxxxxyxxxxxppp",
		"pppxxxxxxyxxxxxyxxxxxyxxxxxyxxxxxppp",
		"pppxxxxxxyxxNNxNNxNNxNNxxxxyxxxxxppp",
		"pppyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyppp",
		"pppqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqppp",
		"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
		"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
	]
	# sprite SPEAKER (22x34)
	var PAL_SPEAKER := {"a": Color("3a3d45"), "b": Color("4a4d55"), "c": Color("0f1013"), "d": Color("1b1d22"), "e": Color("6a6e78"), "f": Color("14161a"), "g": Color("7a7e88"), "h": Color("22252b"), "i": Color("2f323a"), "j": Color("c9ced6"), "k": Color("2a2c33")}
	var SPR_SPEAKER := [
		".abbbbbbbbbbbbbbbbbbc.",
		".addddddeeeeeeddddddc.",
		".addddddddddddddddddc.",
		".addddddddaaadddddddc.",
		".adddddddafffaddddddc.",
		".addddddafffffadddddc.",
		".addddddaffgffadddddc.",
		".addddddafffffadddddc.",
		".adddddddafffaddddddc.",
		".addddddddaaadddddddc.",
		".addddddddddddddddddc.",
		".adddddddaaaaaddddddc.",
		".adddddaahhhhhaaddddc.",
		".addddaahhhhhhhaadddc.",
		".adddaahhhfffhhhaaddc.",
		".adddahhfffffffhhaddc.",
		".addahhhffiiiffhhhadc.",
		".addahhffieiiiffhhadc.",
		".addahhffiiiiiffhhadc.",
		".addahhffiiiiiffhhadc.",
		".addahhhffiiiffhhhadc.",
		".adddahhfffffffhhaddc.",
		".adddaahhhfffhhhaaddc.",
		".addddaahhhhhhhaadddc.",
		".adddddaahhhhhaaddddc.",
		".addddddjjjjjjddddddc.",
		".addddddddddddddddddc.",
		"..........bb..........",
		"..........bb..........",
		"..........bb..........",
		"..........bb..........",
		"..........ba..........",
		"........aaaaaaa.......",
		"....kkkkkkkkkkkkkkk...",
	]
	# sprite SUN (32x48)
	var PAL_SUN := {"a": Color("f2a31c"), "b": Color("ffd23f"), "c": Color("6a3a14"), "d": Color("a0632a"), "e": Color("2a6f33"), "f": Color("1f5226"), "g": Color("f2d6e0"), "h": Color("e3b8c8"), "i": Color("f8e6ee"), "j": Color("e9c8d6"), "k": Color("c99aaa")}
	var SPR_SUN := [
		"................................",
		"......................a.........",
		".................aabaabaaaa.....",
		"........a........aabbbbbbaa.....",
		"....aabaabaaaa...abbbccbbbb.....",
		"....aabbbbbbaa...abbccccbba.....",
		"....abbbccbbbb...bbccdcccbaa....",
		"....abbccccbba..aabccccdcbbaa...",
		"....bbccdcccbaa..abbcddcbba.....",
		"...aabccccdcbbaa.bbbbccbbba.....",
		"....abbcddcbba.a.aabbbbbbaa.....",
		"....bbbbccbaabaabaaaabaabaa.....",
		"....aabbbbbaabbbbbbaaaabaabaaaa.",
		".aabaabaaaaabbbccbbbbaabbbbbbaa.",
		".aabbbbbbaaabbccccbbaabbbccbbbb.",
		".abbbccbbbbbbccdcccbaabbccccbba.",
		".abbccccbbaabccccdcbbbbccdcccbaa",
		".bbccdcccbaabbcddcbbaabccccdcbba",
		"aabccccdcbbaabbccbbbaabbcddcbba.",
		".abbcddcbbaaabbbbbbaabbbbccbbba.",
		".bbbbccbbbaaaaabaabaaaabbbbbbaae",
		".aabbbbbbaaeeeeaaeeeeaaaabaabaae",
		".aaaabaabaaeeeeeaeeeeee.eaaeeee.",
		"..eeeaaeee..eeeefeeee..eeeaeeee.",
		"..eeeeaeee...eeefeee...eeeeeeee.",
		"...eeeegggggggggggggggggg.eeee..",
		"...e...ghggghggghggghgggg....e..",
		".......ghggghggghggghgggg.......",
		".......ghggghggghggghgggg.......",
		".......ghggghggghggghgggg.......",
		".......ghggghggghggghgggg.......",
		".....iiiiiiiiiiiiiiiiiiiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		".....iijiiiijiiiijiiiijiiii.....",
		"..gggggggggggggggggggggggggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..gghgggghgggghgggghgggghggggg..",
		"..kkkkkkkkkkkkkkkkkkkkkkkkkkkk..",
	]

	# sprite LOGO30 (30x21): số 3 + quả địa cầu + quỹ đạo + con trỏ của logo "30 years fit@hcmus" (chữ fit@hcmus vẽ bằng font ở draw_hall_b_stage)
	var PAL_LOGO30 := {"a": Color("2eaae4"), "b": Color("2882ca"), "c": Color("1e5faf"), "d": Color("1a4298")}
	var SPR_LOGO30 := [
		"..aaaaaaaaaaa.................",
		"..aaaaaaaaaaa......aaaaa...bbb",
		"..aaaaaaaaaaa....aaaaaaaaab..b",
		"..aaaaaaaaaaa...aaa....baaa..b",
		"..aaaaaaabbbb..aaa..ccc..bbb.b",
		"........abbba..aa..ccccc..bbb.",
		"......abbbbba.aa..c..c..c..bb.",
		"......abbbba..aa.cc..c..ccbbb.",
		"......abbbba..aa.ccccccccc.cc.",
		"......abbbbba.abbcc..c..c..cc.",
		"........acccb.bb..c..cddc.ccc.",
		".........bccc.bbb..cccddd.cc..",
		".........acccb.bbb...cddddcc..",
		".........acccb..bccc..dddcc...",
		".........acccb..bcccccccdd....",
		"...a.....ccccbbb....ccc..d....",
		"..bdbaaacdddb.................",
		"acdddddddddd..................",
		".bddddddddda..................",
		"..addddddc....................",
		"....abba......................",
	]

	# ---------- hàm vẽ cơ bản ----------
	# Lật dọc: mirror = true thì mọi hình chữ nhật được vẽ đối xứng qua giữa hội trường (sân khấu lên trên).
	# Vật đứng thẳng (người, sprite, chữ) vẽ ở chế độ "đứng": up_begin(cy) .. up_end() chỉ dịch dọc theo dy, không lật hình.
	var mirror := false
	var dy := 0.0

	func up_begin(cy: float) -> void:
		mirror = false
		dy = H.SIZE.y - 2.0 * cy

	func up_end() -> void:
		mirror = true
		dy = 0.0

	func rt(x: float, y: float, w: float, h: float) -> Rect2:
		if mirror:
			return Rect2(x, H.SIZE.y - y - h, w, h)
		return Rect2(x, y + dy, w, h)

	func pt(v: Vector2) -> Vector2:
		if mirror:
			return Vector2(v.x, H.SIZE.y - v.y)
		return Vector2(v.x, v.y + dy)

	func rc(x: float, y: float, w: float, h: float, c: Color) -> void:
		draw_rect(rt(x, y, w, h), c)

	func circ(center: Vector2, r: float, c: Color) -> void:
		draw_circle(pt(center), r, c)

	func poly(points: PackedVector2Array, c: Color) -> void:
		var out := PackedVector2Array()
		for v in points:
			out.append(pt(v))
		draw_colored_polygon(out, c)

	func ctext(t: String, x: float, y: float, w: float, size: int, c: Color) -> void:
		var f: Font = hall.game.font if hall.game.font != null else ThemeDB.fallback_font
		if mirror:
			draw_string(f, Vector2(x, H.SIZE.y - y + size * 0.75), t, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)
		else:
			draw_string(f, Vector2(x, y + dy), t, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)

	# chữ đặt theo toạ độ màn hình của hội trường đã lật (sy = đường chân chữ)
	func stext(t: String, x: float, sy: float, w: float, size: int, c: Color) -> void:
		var f: Font = hall.game.font if hall.game.font != null else ThemeDB.fallback_font
		draw_string(f, Vector2(x, sy), t, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)

	func shadow(p: Vector2, r: float) -> void:
		rc(p.x - r, p.y - 2.0, r * 2.0, 4.0, Color(0, 0, 0, 0.18))

	func _hb(a: float, b: float, salt: float = 0.0) -> int:
		return H.hash_at(a, b, salt)

	# vẽ một sprite: mỗi chuỗi là một hàng, gộp các điểm liền nhau cùng màu thành một hình chữ nhật
	func draw_sprite(x: float, y: float, rows: Array, pal: Dictionary) -> void:
		var was_mirror := mirror
		if was_mirror:
			up_begin(y + rows.size() * 0.5)
		for ry in rows.size():
			var row: String = rows[ry]
			var rx := 0
			while rx < row.length():
				var ch := row[rx]
				if ch == ".":
					rx += 1
					continue
				var run := 1
				while rx + run < row.length() and row[rx + run] == ch:
					run += 1
				rc(x + rx, y + ry, run, 1, pal[ch])
				rx += run
		if was_mirror:
			up_end()

	# đoá hoa pixel 5x5 (cánh + nhụy)
	func draw_bloom(cx: float, cy: float, col: Color, ctr: Color) -> void:
		rc(cx - 1, cy - 2, 3, 5, col)
		rc(cx - 2, cy - 1, 5, 3, col)
		rc(cx - 1, cy - 1, 3, 3, col.lightened(0.28))
		rc(cx, cy, 1, 1, ctr)
		rc(cx - 2, cy + 1, 5, 1, col.darkened(0.15))

	# lọ hoa trên bàn đoàn: x = mép trái (rộng 14), yb = đáy lọ
	func draw_bouquet(x: float, yb: float) -> void:
		var stem := Color("2a6f33")
		var leaf := Color("3b9a45")
		rc(x + 4, yb - 12, 1, 6, stem)
		rc(x + 7, yb - 12, 1, 6, stem)
		rc(x + 10, yb - 12, 1, 6, stem)
		rc(x + 1, yb - 9, 3, 2, leaf)
		rc(x + 11, yb - 9, 3, 2, leaf)
		rc(x + 2, yb - 8, 3, 1, stem)
		rc(x + 10, yb - 8, 3, 1, stem)
		draw_bloom(x + 7, yb - 17, Color("f5a623"), Color("8a4a00"))
		draw_bloom(x + 3, yb - 13, Color("e5322d"), Color("ffd23f"))
		draw_bloom(x + 11, yb - 13, Color("f06a8a"), Color("ffd23f"))
		draw_bloom(x + 7, yb - 12, Color("f4f4f4"), Color("f2c230"))
		# lọ sứ
		rc(x + 3, yb - 7, 8, 7, Color("e6ecf6"))
		rc(x + 3, yb - 7, 8, 1, Color("ffffff"))
		rc(x + 9, yb - 7, 2, 7, Color("c9d3e6"))
		rc(x + 4, yb - 4, 6, 1, Color("2f6fd0"))
		rc(x + 4, yb - 1, 6, 1, Color("9fb4d6"))
		rc(x + 2, yb, 10, 1, Color(0, 0, 0, 0.12))

	# Camera: bám người chơi, không lộ ra ngoài mép hội trường.
	func _origin() -> Vector2:
		var o := view.get_center() - Vector2(hall.pos.x, H.SIZE.y - hall.pos.y)
		if H.SIZE.x <= view.size.x:
			o.x = view.get_center().x - H.SIZE.x * 0.5
		else:
			o.x = clampf(o.x, view.end.x - H.SIZE.x, view.position.x)
		if H.SIZE.y <= view.size.y:
			o.y = view.get_center().y - H.SIZE.y * 0.5
		else:
			o.y = clampf(o.y, view.end.y - H.SIZE.y, view.position.y + 24.0)   # chừa 24px cho thanh tiêu đề phía trên
		# ngồi ghế (góc nhìn thứ nhất): camera ghim vào sân khấu ở mép trên hội trường, lệch nhẹ theo bên trái / phải của ghế
		if hall.seat_blend > 0.0:
			var fx := lerpf(hall.pos.x, H.SIZE.x * 0.5, 0.6)
			var so := Vector2(view.get_center().x - fx, view.position.y + 24.0)
			if H.SIZE.x <= view.size.x:
				so.x = o.x
			else:
				so.x = clampf(so.x, view.end.x - H.SIZE.x, view.position.x)
			o = o.lerp(so, hall.seat_blend)
		return o

	func _draw() -> void:
		if hall == null or not hall.inside:
			return
		mirror = false
		dy = 0.0
		view = Rect2(Vector2.ZERO, get_viewport_rect().size)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(view.grow(16.0), Color("14161a"))
		draw_set_transform(_origin(), 0.0, Vector2.ONE)
		mirror = true
		dy = 0.0
		draw_hall_b_walls()
		draw_hall_b_stage()
		draw_hall_b_tiers()
		draw_hall_b_head_tables()
		draw_hall_b_actors()
		mirror = false
		dy = 0.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var vs := view.size
		rc(0, 0, vs.x, 24, Color(0.03, 0.06, 0.1, 0.94))
		ctext("Hội trường B", 12, 17, 300, 11, Color("ffe28a"))
		if hall.seat_blend > 0.01:
			# mép bàn trước mặt người đang ngồi
			rc(0, vs.y - 32, vs.x, 14, Color(0.66, 0.33, 0.12, hall.seat_blend))
			rc(0, vs.y - 32, vs.x, 2, Color(0.79, 0.48, 0.23, hall.seat_blend))
			rc(0, vs.y - 20, vs.x, 2, Color(0.42, 0.2, 0.08, hall.seat_blend))
		rc(0, vs.y - 18, vs.x, 18, Color(0.03, 0.06, 0.1, 0.85))
		ctext("W A S D: di chuyển", 12, vs.y - 7, 160, 8, Color("e6e8eb"))
		ctext("Đến thảm đỏ ở cửa sau, bấm E để ra", vs.x - 190, vs.y - 7, 180, 8, Color("e6e8eb"))
		if hall.seat_idx >= 0:
			ctext("F: đứng dậy", vs.x * 0.5 - 100.0, vs.y - 7, 200, 8, Color("ffe28a"))
		elif hall.near_exit():
			ctext("E: ra ngoài", vs.x * 0.5 - 100.0, vs.y - 7, 200, 8, Color("ffe28a"))
		elif hall.sit_target >= 0:
			ctext("F: ngồi vào ghế trống", vs.x * 0.5 - 100.0, vs.y - 7, 200, 8, Color("ffe28a"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ---------- người: bê nguyên draw_person của characters.gd (áo polo trường, ba lô, bước chân) ----------
	# pos = chân người; seated = true thì bỏ chân/bóng (ngồi sau bàn). face: 0 nhìn xuống, 1 quay lưng, 2 trái, 3 phải.
	func draw_person(pos: Vector2, shirt: Color, hair: Color, skin: Color, face: int, step: float, uni: bool, long_hair: bool, pack: bool, seated: bool = false) -> void:
		var ol := Color("1a1a2e")
		var navy := Color("1b2f6e")
		var odd := int(step * 8.0) % 2 == 1
		var sw := 1.0 if odd else 0.0
		var bob := 1.0 if odd else 0.0
		if not seated:
			shadow(pos + Vector2(0, 1), 8.0)
			# chân và giày
			rc(pos.x - 5, pos.y - 7 + sw, 4, 7 - sw, ol)
			rc(pos.x + 1, pos.y - 7 + (1.0 - sw), 4, 7 - (1.0 - sw), ol)
			rc(pos.x - 4, pos.y - 6 + sw, 2, 4 - sw, Color("2b2f4a"))
			rc(pos.x + 2, pos.y - 6 + (1.0 - sw), 2, 4 - (1.0 - sw), Color("2b2f4a"))
			rc(pos.x - 4, pos.y - 2 + sw * 0.0, 3, 2, Color("f4f4f4"))
			rc(pos.x + 1, pos.y - 2, 3, 2, Color("f4f4f4"))
		var by := pos.y - bob
		# ba lô (phía sau lưng)
		if pack and face == 1:
			rc(pos.x - 6, by - 14, 12, 10, ol)
			rc(pos.x - 5, by - 13, 10, 8, Color("2f6bd0"))
			rc(pos.x - 5, by - 13, 10, 2, Color("5b8de8"))
		elif pack and face == 2:
			rc(pos.x + 3, by - 13, 4, 8, ol)
			rc(pos.x + 4, by - 12, 2, 6, Color("2f6bd0"))
		elif pack and face == 3:
			rc(pos.x - 7, by - 13, 4, 8, ol)
			rc(pos.x - 6, by - 12, 2, 6, Color("2f6bd0"))
		# thân
		rc(pos.x - 6, by - 14, 12, 10, ol)
		rc(pos.x - 8, by - 13, 2, 7, ol)
		rc(pos.x + 6, by - 13, 2, 7, ol)
		if uni:
			rc(pos.x - 5, by - 13, 10, 4, Color.WHITE)
			rc(pos.x - 5, by - 9, 10, 5, navy)
			rc(pos.x - 7, by - 12, 2, 6, navy)
			rc(pos.x + 5, by - 12, 2, 6, navy)
			rc(pos.x - 3, by - 14, 6, 2, navy)
			rc(pos.x - 3, by - 13, 6, 1, Color("dfe6ff"))
			rc(pos.x - 5, by - 5, 10, 1, navy.darkened(0.3))
			if face == 0:
				rc(pos.x, by - 13, 1, 5, navy)
				if hall.game.logo != null:
					draw_texture_rect(hall.game.logo, rt(pos.x + 1, by - 12, 4, 4), false)
				else:
					rc(pos.x + 1, by - 12, 3, 3, navy)
					rc(pos.x + 2, by - 11, 1, 1, Color.WHITE)
		else:
			rc(pos.x - 5, by - 13, 10, 8, shirt)
			rc(pos.x - 7, by - 12, 2, 6, shirt)
			rc(pos.x + 5, by - 12, 2, 6, shirt)
			rc(pos.x - 5, by - 13, 10, 2, shirt.lightened(0.2))
			rc(pos.x - 5, by - 6, 10, 1, shirt.darkened(0.25))
		rc(pos.x - 7, by - 7, 2, 2, skin)
		rc(pos.x + 5, by - 7, 2, 2, skin)
		# đầu
		rc(pos.x - 5, by - 22, 10, 9, ol)
		rc(pos.x - 4, by - 21, 8, 8, skin)
		rc(pos.x - 4, by - 21, 8, 3, hair)
		rc(pos.x - 3, by - 22, 3, 1, hair.lightened(0.3))
		if long_hair:
			rc(pos.x - 5, by - 21, 1, 9, hair)
			rc(pos.x + 4, by - 21, 1, 9, hair)
		if face == 1:
			rc(pos.x - 4, by - 21, 8, 8, hair)
			rc(pos.x - 3, by - 21, 3, 1, hair.lightened(0.3))
		elif face == 0:
			rc(pos.x - 3, by - 17, 1, 2, ol)
			rc(pos.x + 2, by - 17, 1, 2, ol)
			rc(pos.x - 3, by - 15, 1, 1, Color("e8a08a"))
			rc(pos.x + 2, by - 15, 1, 1, Color("e8a08a"))
			rc(pos.x - 1, by - 14, 2, 1, Color("a0522d"))
		elif face == 2:
			rc(pos.x - 3, by - 17, 1, 2, ol)
			rc(pos.x + 2, by - 21, 2, 6, hair)
		else:
			rc(pos.x + 2, by - 17, 1, 2, ol)
			rc(pos.x - 4, by - 21, 2, 6, hair)

	# sinh viên ngồi ở ghế p (góc trên trái ô ghế). Ghế nào có người do hash quyết định (xem H.seat_empty).
	func draw_student(p: Vector2, has_laptop: bool) -> void:
		var h := _hb(p.x, p.y, 1.0)
		var shirt := HB_NAVY
		var uni := true
		if h >= 62 and h < 76:
			shirt = Color("f1f1f1")
			uni = false
		elif h >= 76 and h < 86:
			shirt = Color("7f93b8")
			uni = false
		elif h >= 86 and h < 93:
			shirt = Color("8e2e36")
			uni = false
		elif h >= 93:
			shirt = Color("e8a0b8")
			uni = false
		var hair: Color = HB_HAIRS[_hb(p.x, p.y, 2.0) % HB_HAIRS.size()]
		var skin: Color = HB_SKINS[_hb(p.x, p.y, 3.0) % HB_SKINS.size()]
		var long_hair := _hb(p.x, p.y, 10.0) < 28
		var hand := 0.0
		if _hb(p.x, p.y, 5.0) < 9:
			hand = 3.0 + 2.5 * sin(hall.time * 6.0 + p.x)
		if not has_laptop and _hb(p.x, p.y, 4.0) < 45:
			# hộp quà tân sinh viên đặt trên bàn
			rc(p.x - 4, p.y + 17, 7, 5, HB_KRAFT)
			rc(p.x - 3, p.y + 18, 5, 2, Color("2b4fa0"))
			rc(p.x - 1, p.y + 17, 1, 5, Color("e8d9a8"))
		up_begin(p.y + 11.5)
		draw_person(p + Vector2(6.0, 22.0), shirt, hair, skin, 1, 0.0, uni, long_hair, false, true)
		if hand > 0.0:
			rc(p.x - 2, p.y + 9 - hand, 2, 6 + hand, shirt)
			rc(p.x - 2, p.y + 6 - hand, 2, 3, skin)
		up_end()

	# ghế thầy cô ở bàn đoàn (nhìn từ phía sau): lưng ghế bọc da đỏ đô có viền vàng + đinh tán, khung gỗ, tay vịn, đệm ngồi, chân ghế, thanh giằng và bóng đổ.
	# fx = tâm ghế theo x, fy = chân người ngồi (cùng toạ độ truyền vào draw_person). Vẽ SAU người nên lưng ghế che phần lưng dưới của áo.
	func draw_teacher_chair(fx: float, fy: float) -> void:
		var wood := Color("4a2c16")
		var wood_hi := Color("7a4d28")
		var leather := Color("8c2234")
		var leather_hi := Color("b0384a")
		var leather_lo := Color("6a1626")
		var gold := Color("e0b23a")
		# bóng đổ trên sàn
		rc(fx - 10, fy + 7, 20, 3, Color(0, 0, 0, 0.16))
		# chân ghế sau + thanh giằng + đế chân
		rc(fx - 7, fy + 3, 2, 5, wood)
		rc(fx - 7, fy + 3, 1, 5, wood_hi)
		rc(fx + 5, fy + 3, 2, 5, wood)
		rc(fx + 5, fy + 3, 1, 5, wood_hi)
		rc(fx - 5, fy + 6, 10, 1, wood)
		rc(fx - 8, fy + 7, 3, 1, Color("2b2b2b"))
		rc(fx + 5, fy + 7, 3, 1, Color("2b2b2b"))
		# đệm ngồi (mép trước nhìn thấy dưới lưng ghế)
		rc(fx - 8, fy, 16, 4, Color("2a1018"))
		rc(fx - 7, fy, 14, 3, leather)
		rc(fx - 7, fy, 14, 1, leather_hi)
		rc(fx - 7, fy + 3, 14, 1, gold)
		# tay vịn gỗ (bàn tay thầy cô đặt lên trên)
		rc(fx - 10, fy - 6, 4, 2, wood)
		rc(fx - 10, fy - 6, 4, 1, wood_hi)
		rc(fx - 9, fy - 4, 2, 4, wood)
		rc(fx + 6, fy - 6, 4, 2, wood)
		rc(fx + 6, fy - 6, 4, 1, wood_hi)
		rc(fx + 7, fy - 4, 2, 4, wood)
		# lưng ghế: khung gỗ bo góc, viền vàng, đệm bọc da, đường may, đinh tán
		rc(fx - 5, fy - 13, 10, 1, wood)
		rc(fx - 6, fy - 12, 12, 12, wood)
		rc(fx - 6, fy - 12, 12, 1, wood_hi)
		rc(fx - 5, fy - 11, 10, 1, gold)
		rc(fx - 5, fy - 10, 10, 8, leather)
		rc(fx - 5, fy - 10, 10, 1, leather_hi)
		rc(fx + 3, fy - 9, 2, 7, leather_lo)
		rc(fx, fy - 9, 1, 7, leather_lo)
		rc(fx - 4, fy - 9, 1, 6, leather_hi)
		rc(fx - 5, fy - 2, 10, 2, wood)
		for bx in [-3, 2]:
			rc(fx + bx, fy - 8, 1, 1, gold)
			rc(fx + bx, fy - 5, 1, 1, gold)
		rc(fx - 1, fy - 6, 1, 1, gold)
		rc(fx - 1, fy - 3, 1, 1, wood_hi)

	# ghế trống (có thể ngồi). target = đang được chọn: viền nhấp nháy + chữ "F: ngồi"
	func draw_chair(p: Vector2, target: bool) -> void:
		var ol := Color("1a1a2e")
		rc(p.x, p.y + 6, 12, 11, ol)
		rc(p.x + 1, p.y + 7, 10, 9, Color("5b78b8"))
		rc(p.x + 1, p.y + 7, 10, 2, Color("7f98d0"))
		rc(p.x + 2, p.y + 10, 8, 1, Color("4a639c"))
		rc(p.x + 1, p.y + 13, 10, 3, Color("3f5690"))
		rc(p.x + 1, p.y + 13, 10, 1, Color("5a73ad"))
		if target:
			var a := 0.6 + 0.4 * sin(hall.time * 8.0)
			draw_rect(rt(p.x - 2, p.y + 4, 16, 16), Color(1.0, 0.86, 0.25, a), false, 1.0)
			stext("F: ngồi", p.x - 14, H.SIZE.y - p.y - 22.0, 40, 6, Color("ffe28a"))

	# ---------- đồ trên bàn sinh viên: laptop, sổ, chai nước, ly trà sữa ----------
	func front_item(p: Vector2) -> int:
		var h := _hb(p.x, p.y, 6.0)
		if h < 32:
			return 1        # laptop bạc
		if h < 52:
			return 2        # laptop đen
		if h < 60:
			return 3        # sổ + bút
		return 0

	func draw_laptop(x: float, y: float, dark: bool, sticker: int) -> void:
		var lid := Color("2b2f3a") if dark else Color("c9ced6")
		rc(x, y, 12, 8, lid.darkened(0.3))
		rc(x + 1, y + 1, 10, 6, lid)
		rc(x + 1, y + 1, 10, 1, lid.lightened(0.2))
		rc(x + 5, y + 3, 2, 2, Color("aab2bd") if dark else Color("ffffff"))
		if sticker == 1:
			rc(x + 2, y + 5, 2, 1, Color("e8573a"))
		elif sticker == 2:
			rc(x + 8, y + 2, 2, 2, Color("3fa34d"))
		rc(x - 1, y + 8, 14, 2, Color("1b1d22") if dark else Color("8d949e"))
		rc(x - 1, y + 8, 14, 1, Color("3a3d45") if dark else Color("b9c0c9"))

	func draw_notebook(x: float, y: float) -> void:
		rc(x, y, 12, 6, Color("8a6d4b"))
		rc(x + 1, y, 5, 5, Color("f6f2e4"))
		rc(x + 6, y, 5, 5, Color("efe9d6"))
		rc(x + 6, y, 1, 5, Color("c9bfa3"))
		for k in 2:
			rc(x + 2, y + 1 + k * 2, 3, 1, Color("a9b4c8"))
			rc(x + 7, y + 1 + k * 2, 3, 1, Color("a9b4c8"))
		rc(x + 10, y - 3, 1, 6, Color("2f6fd0"))

	func draw_desk_items(p: Vector2, occupied: bool) -> void:
		var f := 0
		if occupied:
			f = front_item(p)
		var st := _hb(p.x, p.y, 7.0) % 6
		if f == 1:
			draw_laptop(p.x, p.y + 9, false, st if st < 3 else 0)
		elif f == 2:
			draw_laptop(p.x, p.y + 9, true, st if st < 3 else 0)
		elif f == 3:
			draw_notebook(p.x, p.y + 13)
		var h := _hb(p.x, p.y, 9.0)
		if occupied:
			if h < 36:
				draw_sprite(p.x + 15, p.y + 11, SPR_BOTTLE_S, PAL_BOTTLE)
			elif h < 48:
				draw_sprite(p.x + 15, p.y + 13, SPR_CUP, PAL_CUP)
		elif h < 10:
			draw_sprite(p.x + 4, p.y + 11, SPR_BOTTLE_S, PAL_BOTTLE)

	func draw_hall_b_desk(x: float, y: float, w: float) -> void:
		rc(x, y, w, 8, Color("a8531f"))
		rc(x, y, w, 2, Color("c97a3a"))
		rc(x, y + 7, w, 1, Color("6a3414"))
		for xx in range(int(x) + 36, int(x + w) - 8, 36):
			rc(xx, y + 2, 1, 5, Color("8a4318"))

	# ---------- tường, cửa, cửa sổ ----------
	func draw_hall_b_walls() -> void:
		var s := H.SIZE
		var blue := Color("bfe0ee")
		var light := Color("e6f5fa")
		rc(0, 0, s.x, s.y, Color("dcd6c2"))
		# tường sau + trần
		rc(0, 0, s.x, 44, blue)
		rc(0, 0, s.x, 5, Color("f4f1e6"))
		for i in 7:
			rc(30 + i * 80, 1, 36, 3, Color.WHITE)
		for xx in range(14, int(s.x) - 10, 28):
			rc(xx, 10, 3, 24, light)
		# cửa sổ khung gỗ trên cao
		for i in 5:
			if i == 2:
				continue
			var wx := 40.0 + i * 104.0
			rc(wx, 10, 64, 26, Color("b5651d"))
			for pr in 2:
				for pc in 2:
					var pane := Color("fdf3d6")
					if (i + pr + pc) % 3 == 0:
						pane = Color("cfe9b8")
					rc(wx + 3 + pc * 30, 12 + pr * 12, 28, 10, pane)
		rc(0, 38, s.x, 6, blue.darkened(0.1))
		# cửa ra (cửa sau hội trường) + bảng
		rc(230, 6, 100, 10, Color("1f2f5a"))
		ctext("HỘI TRƯỜNG B", 230, 14, 100, 7, Color("f2c230"))
		rc(266, 18, 28, 4, Color("2e9c5a"))
		rc(262, 22, 36, 22, Color("5a3a22"))
		rc(279, 22, 2, 22, Color("3a2412"))
		rc(264, 24, 14, 18, Color("7a5230"))
		rc(282, 24, 14, 18, Color("7a5230"))
		rc(H.EXIT.position.x, H.EXIT.position.y, H.EXIT.size.x, H.EXIT.size.y, Color("7a2a2a"))
		rc(H.EXIT.position.x, H.EXIT.position.y, H.EXIT.size.x, 1, Color("a84a4a"))
		# tường hai bên có khe sáng
		rc(0, 44, 22, s.y - 44, blue)
		rc(s.x - 22, 44, 22, s.y - 44, blue)
		rc(20, 44, 2, s.y - 44, blue.darkened(0.15))
		rc(s.x - 22, 44, 2, s.y - 44, blue.darkened(0.15))
		for yy in range(52, int(s.y) - 20, 24):
			rc(8, yy, 3, 14, light)
			rc(s.x - 11, yy, 3, 14, light)

	# ---------- các bậc khán phòng, bàn gỗ, sinh viên, ghế trống ----------
	func draw_hall_b_tiers() -> void:
		var w := H.SIZE.x - 44.0
		var seats := H.student_seats()
		for tier in range(H.TIERS - 1, -1, -1):   # từ sát sân khấu (trên màn hình) xuống phía cửa
			var y0 := H.TIER_Y0 + tier * H.TIER_H
			var tier_col := Color("ebe3cd") if tier % 2 == 0 else Color("e1d8bf")
			rc(22, y0, w, H.TIER_H, tier_col)
			rc(22, y0, w, 1, Color("c9c0a6"))
			# bậc thang giữa
			rc(H.AISLE_X, y0, H.AISLE_W, H.TIER_H, Color("cfc8b4"))
			for k in 4:
				rc(H.AISLE_X, y0 + k * 7, H.AISLE_W, 1, Color("b3ab95"))
				rc(H.AISLE_X, y0 + k * 7 + 1, H.AISLE_W, 1, Color(1, 1, 1, 0.25))
			# bàn gỗ nằm phía sân khấu của hàng ghế (vẽ đứng, chỉ dịch vị trí)
			up_begin(y0 + 21.0)
			draw_hall_b_desk(28, y0 + 17, 216)
			draw_hall_b_desk(316, y0 + 17, 216)
			up_end()
			# đồ trên bàn
			for n in range(tier * 18, tier * 18 + 18):
				var q := seats[n]
				draw_desk_items(q, (not H.seat_empty(q)) or n == hall.seat_idx)
			# người ngồi / ghế trống / người chơi đang ngồi (18 chỗ), ngồi sau bàn nên vẽ sau
			for n in range(tier * 18, tier * 18 + 18):
				var p := seats[n]
				if n == hall.seat_idx:
					draw_chair(p, false)
					up_begin(p.y + 11.5)
					draw_person(p + Vector2(6.0, 22.0), HB_NAVY, Color("16171c"), Color("f0c8a0"), 1, 0.0, true, false, false, true)
					up_end()
				elif H.seat_empty(p):
					draw_chair(p, n == hall.sit_target)
				else:
					draw_student(p, front_item(p) != 0)
			rc(22, y0 + 25, w, 3, Color(0, 0, 0, 0.1))

	# ---------- bàn đoàn trải khăn trắng + thầy cô + chai nước + hoa ----------
	func draw_hall_b_head_tables() -> void:
		var teachers := H.teacher_seats()
		up_begin(296.0)   # cả khối bàn đoàn (y 270-322) chỉ dịch lên vị trí lật, không lật hình
		for tx in [28.0, 328.0]:
			# mặt bàn trải khăn trắng
			rc(tx, 292, 204, 8, Color("ffffff"))
			rc(tx, 292, 204, 1, Color("e4e9ef"))
			rc(tx, 299, 204, 1, Color("dfe4ea"))
			# khăn rủ xuống phía trước, có nếp gấp
			rc(tx, 300, 204, 22, Color("f4f6f9"))
			for fx in range(int(tx) + 6, int(tx) + 202, 8):
				rc(fx, 300, 1, 21, Color("e1e6ec"))
				rc(fx + 1, 300, 1, 21, Color("fdfdfe"))
			rc(tx, 320, 204, 2, Color("cfd6dc"))
			rc(tx + 4, 322, 204, 3, Color(0, 0, 0, 0.15))
			# bảng tên thầy cô đặt trước mỗi chỗ
			for i in 7:
				var nx: float = tx + 8.0 + i * 28.0
				rc(nx + 1, 294, 10, 4, Color("fff7dc"))
				rc(nx + 1, 294, 10, 1, Color("d5dae2"))
				rc(nx + 3, 296, 6, 1, Color("1f2f5a"))
			# khoảng trống giữa các thầy cô: lọ hoa (k = 1, 4) hoặc hai chai nước
			for k in 6:
				var cx: float = tx + 28.0 + k * 28.0
				if k == 1 or k == 4:
					draw_bouquet(cx - 7.0, 299.0)
				elif tx > 300.0 and k == 5:
					draw_sprite(cx - 6.0, 288.0, SPR_BOTTLE_L, PAL_BOTTLE)
					rc(cx, 293, 7, 5, Color("4aa44f"))
					rc(cx + 1, 293, 5, 1, Color.WHITE)
				else:
					draw_sprite(cx - 6.0, 288.0, SPR_BOTTLE_L, PAL_BOTTLE)
					draw_sprite(cx + 1.0, 288.0, SPR_BOTTLE_L, PAL_BOTTLE)
		# thầy cô ngồi cùng hướng với sinh viên: quay lưng về khán phòng, nhìn lên sân khấu (ghế vẽ SAU người vì lưng ghế ở gần mình hơn)
		for i in teachers.size():
			var p := teachers[i]
			var shirt: Color = HB_TEACHER_SHIRTS[i % 7]
			var hair: Color = HB_HAIRS[_hb(p.x, p.y, 7.0) % 3]
			var skin: Color = HB_SKINS[_hb(p.x, p.y, 8.0) % HB_SKINS.size()]
			draw_person(p + Vector2(6.0, 39.0), shirt, hair, skin, 1, 0.0, false, (i % 7) == 2, false, true)
			draw_teacher_chair(p.x + 6.0, p.y + 39.0)
		up_end()

	# ---------- bảng We ♥ FIT + sân khấu ----------
	func draw_hall_b_stage() -> void:
		var s := H.SIZE
		var x0 := 22.0
		var w := s.x - 44.0
		var gold := Color("f2c230")
		var red := Color("c0262d")
		rc(x0, H.FRONT_Y, w, H.STAGE_Y - H.FRONT_Y, Color("e6dfca"))
		# bảng We ♥ FIT (đứng ở giữa lối đi)
		var sg := H.SIGN
		up_begin(sg.get_center().y)   # bảng đứng, mặt hướng về khán phòng
		rc(sg.position.x + 6, sg.end.y - 2, 3, 4, Color("5a3a22"))
		rc(sg.end.x - 9, sg.end.y - 2, 3, 4, Color("5a3a22"))
		rc(sg.position.x, sg.position.y, sg.size.x, sg.size.y - 2, Color("f4fbff"))
		rc(sg.position.x + 2, sg.position.y + 2, sg.size.x - 4, sg.size.y - 6, Color("2f6fd0"))
		circ(Vector2(sg.position.x + 8, sg.position.y + 8), 5.0, Color("bfe6f5"))
		rc(sg.position.x + 6, sg.position.y + 6, 1, 1, Color("2b2b2b"))
		rc(sg.position.x + 9, sg.position.y + 6, 1, 1, Color("2b2b2b"))
		ctext("We", sg.position.x + 14, sg.position.y + 13, 14, 8, Color.WHITE)
		circ(Vector2(sg.position.x + 33, sg.position.y + 8), 2.5, red)
		circ(Vector2(sg.position.x + 37, sg.position.y + 8), 2.5, red)
		poly(PackedVector2Array([Vector2(sg.position.x + 30.5, sg.position.y + 9.5), Vector2(sg.position.x + 39.5, sg.position.y + 9.5), Vector2(sg.position.x + 35, sg.position.y + 14)]), red)
		ctext("FIT", sg.position.x + 40, sg.position.y + 13, 22, 8, Color.WHITE)
		up_end()
		# sàn sân khấu
		rc(x0, H.STAGE_Y - 4, w, 4, Color(0, 0, 0, 0.12))
		rc(x0, H.STAGE_Y, w, H.WALL_Y - H.STAGE_Y, Color("c98a4b"))
		for yy in range(int(H.STAGE_Y) + 8, int(H.WALL_Y), 9):
			rc(x0, yy, w, 1, Color("a96d35"))
		rc(x0, H.STAGE_Y, w, 3, Color("e0a766"))
		# tường gỗ ốp lam
		var wy := H.WALL_Y
		var wh := s.y - wy
		up_begin(wy + wh * 0.5)   # tường sân khấu vẽ đứng: giữ nguyên thứ tự băng rôn / cờ / màn hình LED
		rc(x0, wy, w, wh, Color("a8602a"))
		for xx in range(int(x0), int(x0 + w), 8):
			rc(xx, wy, 1, wh, Color("8a4a1e"))
			rc(xx + 1, wy, 1, wh, Color("c0763a"))
		rc(x0, wy, w, 3, Color("6e3a16"))
		# băng rôn đỏ chữ vàng
		rc(70, wy + 4, 420, 14, red)
		rc(70, wy + 4, 420, 1, Color("e24a52"))
		rc(70, wy + 17, 420, 1, Color("7a1218"))
		ctext("ĐẢNG CỘNG SẢN VIỆT NAM QUANG VINH MUÔN NĂM", 70, wy + 14, 420, 8, gold)
		# cờ Đảng (búa liềm) + cờ Tổ quốc (sao vàng), treo trên thanh gỗ
		rc(76, wy + 19, 40, 2, Color("5a3a22"))
		rc(116, wy + 19, 40, 2, Color("5a3a22"))
		draw_sprite(78, wy + 21, SPR_FLAG_PARTY, PAL_FLAG_PARTY)
		draw_sprite(118, wy + 21, SPR_FLAG_NAT, PAL_FLAG_NAT)
		rc(80, wy + 47, 74, 2, Color(0, 0, 0, 0.14))
		# màn hình LED
		rc(166, wy + 20, 228, 46, Color("1a1f3a"))
		rc(168, wy + 22, 224, 42, Color("3b46c8"))
		for i in 9:
			var bh := 14 + (i * 7) % 13
			rc(172 + i * 24, wy + 64 - bh, 14, bh, Color("e86aa0") if i % 2 == 0 else Color("5aa5d6"))
		rc(186, wy + 25, 188, 36, Color(0.12, 0.14, 0.45, 0.62))
		ctext("THÂN CHÀO CÁC BẠN,", 168, wy + 33, 224, 6, Color.WHITE)
		ctext("TÂN SINH VIÊN K26", 168, wy + 45, 224, 10, Color.WHITE)
		ctext("KHOA CÔNG NGHỆ THÔNG TIN", 168, wy + 57, 224, 9, Color.WHITE)
		# băng rôn logo "30 years fit@hcmus" cỡ bằng lá cờ (36x26), treo trên thanh gỗ bên phải màn hình LED
		var lx := 402.0
		var ly := wy + 21.0
		rc(lx - 2, wy + 19, 40, 2, Color("5a3a22"))
		rc(lx, ly, 36, 26, Color.WHITE)
		rc(lx, ly + 25, 36, 1, Color("c9d3e6"))
		draw_sprite(lx + 3.0, ly + 1.0, SPR_LOGO30, PAL_LOGO30)
		ctext("fit@hcmus", lx, ly + 25, 36, 5, Color("1a45a0"))
		rc(lx + 2, ly + 28, 32, 2, Color(0, 0, 0, 0.14))
		up_end()
		# loa đứng (cabinet đen, loa treble + loa bass, chân đế)
		for sp in [H.SPEAKER_L, H.SPEAKER_R]:
			up_begin(sp.get_center().y)
			shadow(Vector2(sp.get_center().x, sp.end.y), 11.0)
			draw_sprite(sp.position.x, sp.end.y - 34.0, SPR_SPEAKER, PAL_SPEAKER)
			up_end()
		# tượng Bác bằng đồng vàng trên bệ gỗ đỏ, vòng hoa hồng trắng - cam
		var bu := H.BUST
		up_begin(bu.get_center().y)
		shadow(bu.get_center() + Vector2(3, 14), 18.0)
		draw_sprite(bu.get_center().x - 17.0, bu.end.y - 49.0, SPR_BUST, PAL_BUST)
		up_end()
		# lẵng hoa hướng dương
		var fl := H.FLOWER
		up_begin(fl.get_center().y)
		shadow(fl.get_center() + Vector2(3, 22), 20.0)
		draw_sprite(fl.position.x - 2.0, fl.end.y - 48.0, SPR_SUN, PAL_SUN)
		up_end()

	# ---------- MC, người chơi (sắp theo y), bong bóng thoại ----------
	func draw_hall_b_actors() -> void:
		var mc := H.MC_POS
		_draw_hall_b_mc(mc)        # MC đứng sau bục nên vẽ trước
		_draw_hall_b_podium()      # bục phát biểu: vòng hoa, biển xanh ngôi sao, micro
		_draw_hall_b_player()
		if hall.pos.distance_to(mc) < 60.0:
			var line: String = hall.MC_LINES[hall.mc_line]
			var bx := mc.x - 100.0
			var by := mc.y - 56.0
			up_begin(mc.y - 2.5)
			rc(bx, by, 200, 22, Color(1, 1, 1, 0.96))
			draw_rect(rt(bx, by, 200, 22), Color("2b2b2b"), false, 1.0)
			ctext(line, bx, by + 10, 200, 7, Color("2b2b2b"))
			ctext("E: nghe tiếp", bx, by + 19, 200, 5, Color("6a6a6a"))
			up_end()

	func _draw_hall_b_mc(mc: Vector2) -> void:
		up_begin(mc.y - 2.5)   # thầy MC đứng sau bục, quay mặt xuống khán phòng
		draw_person(mc, Color("2a5fc0"), Color("16171c"), Color("e6b98e"), 0, 0.0, false, false, false)
		up_end()

	func _draw_hall_b_podium() -> void:
		var po := H.PODIUM
		up_begin(po.get_center().y)
		shadow(po.get_center() + Vector2(3, 18), 22.0)
		draw_sprite(po.position.x, po.end.y - 44.0, SPR_PODIUM, PAL_PODIUM)
		up_end()

	func _draw_hall_b_player() -> void:
		if hall.seat_idx >= 0:
			return   # đang ngồi: được vẽ cùng hàng ghế
		var step := hall.time if hall.moving else 0.0
		var screen_face: int = [1, 0, 2, 3][hall.face]   # lật dọc: đi về phía sân khấu (lên màn hình) thì thấy lưng
		up_begin(hall.pos.y)
		draw_person(hall.pos, HB_NAVY, Color("16171c"), Color("f0c8a0"), screen_face, step, true, false, true)
		up_end()
