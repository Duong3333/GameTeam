extends "res://scripts/features/feature.gd"
# NHÀ TẬP LUYỆN THỂ DỤC THỂ THAO HCMUS (ngoài trời + nhà thi đấu bên trong, chưa có NPC).
#
# Ngoài trời : tòa nhà dài màu kem vàng, mái tôn dốc xanh xám, biển chữ lớn, ô thoáng và cửa đôi ở giữa. Nằm phía sau
#              (phía bắc) khoảng giữa Tòa E và Tòa F, đáy y = 252 cùng mức với Tòa B4.2.
#              Đứng gần lối vào (948, 260) hiện "E: Vào Nhà tập luyện thể dục thể thao", bấm E để vào.
# Bên trong  : nhà thi đấu rộng 640 px (màn hình 480x270 cuộn ngang theo người chơi): giàn kèo thép trên mái, tường
#              ngọc lam, sàn xanh có vạch sân bóng chuyền + bóng rổ, lưới bóng chuyền, 2 rổ bóng rổ, thảm võ, khung thành mini,
#              bảng ảnh MEMORIES. Đi bằng W A S D, bấm E gần cửa (góc trái phía dưới) để ra ngoài, trở lại đúng (948, 260).
#              Hai ghế dài phía dưới sảnh: bấm E gần ghế để ngồi (đứng yên, quay mặt về phía sân), bấm E lần nữa để đứng dậy.
#              Bóng (rổ, chuyền, đá) nằm rải rác trong sảnh: bấm E gần bóng để nhặt, E để đặt xuống; F ném (bóng rổ/chuyền) hoặc
#              sút (bóng đá) theo hướng đang quay mặt, giữ F lâu hơn thì mạnh hơn. Bóng bay theo đường cong, nảy khi chạm sàn,
#              va vào tường/ghế/NPC và bị lưới chặn nếu bay thấp; bay cao hơn lưới thì qua lưới (thứ tự vẽ theo vị trí thật so với lưới).
#
# ĐĂNG KÝ: 1 dòng ở cuối danh sách trong scripts/maps/registry.gd:
#     "res://scripts/maps/nha_the_duc.gd", # Nhà tập luyện Thể dục Thể thao
#
# Dữ liệu và va chạm ngoài trời: ô "NHÀ THỂ DỤC" có sẵn trong BUILDINGS của scripts/maps/campus_data.gd (Rect2(850, 140, 196, 112)).
# Giữ nguyên tên để thời khóa biểu (schedule_data.gd) vẫn khớp. Cửa "gym" chung của features/building_doors.gd bị gỡ
# (xem _detach_generic_gym_door) nên chỉ có một phím E vào nhà tập.
#
# Cách làm giống b42_lab.gd / nha_dieu_hanh.gd: begin()/finish() của feature.gd (active = true thì người chơi ngoài trời
# đứng yên và game.is_busy() = true), CanvasLayer 5 vẽ sảnh bằng Node2D dùng characters.gd, người chơi vẽ bằng draw_person() của game.

# Khối tòa nhà: khớp với ô "NHÀ THỂ DỤC" trong campus_data.gd
# Nhà thể dục được đặt cạnh bãi xe số 2 ở phía bắc khuôn viên.
const RECT := Rect2(1422, 51, 280, 125)
const ENTRANCE := Vector2(1562, 183)
const DOOR_RANGE := 34.0                 # đứng cách lối vào tối đa bấm E mới được (px)
const WALL_COL := Color("efdc96")        # tường kem vàng
const ROOF_COL := Color("5a7396")        # mái tôn xanh xám
const FACADE_LINE := Color("2b2b2b")      # viền đen mặt tiền (cùng tông viền các tòa nhà khác), chạy theo đường bao từng chi tiết
const ENTER_TEXT := "E: Vào Nhà tập luyện thể dục thể thao"
const C_GOLD := Color("ffd23f")

# ---------- Nhà thi đấu bên trong (hệ tọa độ sảnh; sảnh rộng hơn màn hình nên cuộn ngang) ----------
const VIEW := Vector2(480, 270)
const HALL_W := 640.0
const FLOOR_TOP := 74.0                  # mép trên sàn (chân tường ngọc lam)
const FLOOR_BOTTOM := 258.0              # mép dưới sàn
const WALK_TOP := 82.0                   # giới hạn đi lên phía bắc (bàn chân)
const START_POS := Vector2(58, 238)      # chỗ xuất hiện khi vừa vào
const EXIT_POS := Vector2(58, 252)       # đứng gần đây bấm E để ra
const EXIT_RANGE := 26.0
const WALK_SPEED := 70.0                 # giống người chơi ngoài trời
const NET_RECT := Rect2(204, 160, 232, 6)       # lưới bóng chuyền (vùng chắn ở mặt sàn)
const GOAL_RECT := Rect2(526, 229, 64, 5)       # khung thành mini
const RACK_RECT := Rect2(598, 142, 24, 10)      # xe đựng bóng
const COOLER_RECT := Rect2(112, 238, 12, 8)     # bình nước
const BENCH_RECTS := [Rect2(176, 244, 64, 7), Rect2(404, 244, 64, 7)]
const BENCH_SEATS := 3                   # số chỗ ngồi trên mỗi ghế dài (cách nhau SEAT_GAP px, bắt đầu từ mép ghế + SEAT_GAP)
const SEAT_GAP := 16.0
const SEAT_RANGE := 22.0                 # đứng cách tâm chỗ ngồi tối đa bấm E mới ngồi được (từ phía sân hoặc phía tường đều được)
const SEAT_NPC_CLEAR := 12.0             # chỗ ngồi coi như bị chiếm nếu có NPC đứng gần hơn mức này

# ---------- Bóng: nhặt, đặt, ném, sút (độ cao z và vận tốc tính bằng px, px/s) ----------
const BALL_R := 3.0                      # bán kính vẽ và va chạm của quả bóng
const BALL_GRAVITY := 260.0              # gia tốc rơi (px/s^2)
const BALL_PICK_RANGE := 16.0            # đứng cách bóng tối đa bấm E mới nhặt được
const BALL_NET_H := 42.0                 # tâm bóng phải cao hơn mức này mới bay qua lưới (lưới cao khoảng 40 px)
const BALL_HIT_H := 26.0                 # vật cản thấp hơn mức này (tủ nước, khung thành, NPC...) mới chặn bóng, bay cao hơn thì qua
const BALL_CEIL := 130.0                 # trần: bóng không bay cao hơn mức này
const BALL_XMIN := 12.0                  # biên sảnh cho bóng (tường trái/phải/trên/dưới)
const BALL_YMIN := 78.0
const BALL_YMAX := 255.0
const THROW_VZ := 165.0                  # vận tốc bay lên khi ném bóng rổ/bóng chuyền
const THROW_HAND_Z := 20.0               # độ cao tay lúc ném
const THROW_SPEED_MIN := 55.0            # vận tốc ngang khi ném nhẹ (bấm nhanh F)
const THROW_SPEED_MAX := 130.0           # vận tốc ngang khi ném hết lực (giữ F đủ CHARGE_TIME)
const KICK_SPEED_MIN := 110.0
const KICK_SPEED_MAX := 230.0
const KICK_LIFT := 55.0                  # độ nảy lên của cú sút
const CHARGE_TIME := 0.7                 # giữ F bao lâu thì đủ lực (giây)
const BALL_KINDS := {
	"basket": {"bounce": 0.62, "roll": 3.0, "name": "bóng rổ"},
	"volley": {"bounce": 0.50, "roll": 3.4, "name": "bóng chuyền"},
	"foot": {"bounce": 0.45, "roll": 1.8, "name": "bóng đá"},
}
# Vị trí ban đầu của các quả bóng (bốn quả đầu là bóng sàn cũ, hai quả sau thêm cho phía sau lưới và gần rổ phải)
const BALL_SPOTS := [[Vector2(468, 204), "foot"], [Vector2(555, 214), "foot"], [Vector2(322, 214), "volley"],
	[Vector2(110, 134), "basket"], [Vector2(300, 128), "volley"], [Vector2(505, 120), "basket"]]
const MAT_RECT := Rect2(26, 154, 120, 72)       # thảm võ (đi qua được)
const HOOP_XS := [162.0, 478.0]                 # tâm rổ bóng rổ trên tường phía bắc
const COL_XS := [18.0, 210.0, 430.0, 622.0]     # tâm 4 cột thép xanh
const LAMP_XS := [100.0, 250.0, 320.0, 390.0, 540.0]
const WIN_XS := [28.0, 58.0, 88.0, 118.0, 500.0, 530.0, 560.0, 590.0]   # ô cửa sổ cao (rộng 26)
const CONES := [Vector2(452, 222), Vector2(472, 222), Vector2(492, 222), Vector2(512, 222)]
const C_LINE_VB := Color("eef4fb")       # vạch bóng chuyền (trắng)
const C_LINE_BB := Color("f5c84a")       # vạch bóng rổ (vàng)
const C_NAVY := Color("1f3a8a")
const C_TURQ := Color("26b4cf")
const C_OUTLINE := Color("1a1a2e")
const HEART_PATTERN := ["..##.##..", ".#######.", ".#######.", "..#####..", "...###...", "....#...."]
const HALL_NAME := "NHÀ TẬP LUYỆN THỂ DỤC THỂ THAO"

# ---------- NPC trong nhà tập: SỬA TÊN / VỊ TRÍ / LỜI THOẠI Ở ĐÂY ----------
# Mỗi phần tử của mảng *_LINES là một câu; bấm E để sang câu tiếp, hết câu cuối thì đóng hộp thoại.
const NPC_TALK_RANGE := 30.0             # đứng cách NPC tối đa (px) thì bấm E nói chuyện được
const TYPE_SPEED := 46.0                 # số ký tự hiện ra mỗi giây trong hộp thoại
const DIALOGUE_PAGE_LINES := 3           # tối đa số dòng chữ trong một khung; câu dài hơn tự chia thành nhiều trang
const NPC_VO_NAME := "Thầy dạy võ"
const NPC_VO_POS := Vector2(86, 188)     # giữa thảm võ
const NPC_VO_FACE := 0                   # hướng đứng ban đầu: 0 xuống, 1 lên, 2 trái, 3 phải
const NPC_VO_LINES := [
	"Chào em! Võ đường của trường luôn mở cửa cho ai muốn rèn luyện thân thể và ý chí.",
	"Học võ không phải để đánh nhau, mà để tự tin, kiên trì và biết giữ gìn bản thân.",
	"Hít thở sâu, hạ trọng tâm, giữ lưng thẳng. Căn bản vững thì đòn mới mạnh!",
	"Nhớ đi tập đều nhé, điểm rèn luyện cũng cần lắm đó. Thầy chờ em trên thảm!",
]
const NPC_BD_NAME := "Thầy dạy bóng đá"
const NPC_BD_POS := Vector2(506, 196)    # gần mấy chiếc cọc tập và khung thành mini
const NPC_BD_FACE := 3                   # hướng mặt khung thành, quả bóng luôn nằm ở phía trước bên phải
const NPC_BD_LINES := [
	"Chào em! Hôm nay thầy cho cả lớp chạy khởi động hai vòng sân rồi mới đá bóng nhé.",
	"Bóng đá là môn đồng đội: chuyền sớm, di chuyển liên tục, đừng ôm bóng một mình.",
	"Khởi động cho kỹ vào, chấn thương là mất cả học kỳ đó em!",
	"Giải bóng đá của khoa sắp tới rồi, ghi danh vào đội đi. Thầy đang thiếu một tiền vệ!",
]

var inside := false
var _layer: CanvasLayer
var _painter: Node2D           # Node2D dùng script vẽ của game (characters.gd) để vẽ sảnh (cuộn theo _cam_x)
var _ui: Node2D                # Node2D thứ hai cho lớp cố định trên màn hình (biển tên, mờ dần)
var _pos := START_POS          # vị trí nhân vật trong sảnh (bàn chân)
var _face := 1                 # 0 xuống, 1 lên, 2 trái, 3 phải (giống game.facing)
var _anim := 0.0
var _clock := 0.0
var _cam_x := 0.0
var _fade := 0.0
var _closing := false
var _banner := 0.0             # thời gian còn lại của biển tên khi mới vào
var _lock_until := 0           # chặn vào lại ngay sau khi vừa ra (ms)
var _solid: Array = []         # vật cản trong sảnh
var _npcs: Array = []          # NPC trong nhà tập
var _seats: Array = []         # chỗ ngồi trên hai ghế dài (pos = chỗ ngồi, stand/south = chỗ đứng lên, taken = đang có người ngồi)
var _seat := -1                # chỉ số chỗ đang ngồi, -1 = đang đứng
var _sit_from := START_POS     # vị trí trước khi ngồi (dự phòng khi đứng dậy)
var _solid_h: Array = []       # độ cao chặn bóng của từng phần tử trong _solid (song song với _solid)
var _balls: Array = []         # các quả bóng: kind, pos (vị trí trên sàn), z (độ cao), vel, vz, moving
var _held := -1                # chỉ số quả bóng đang cầm, -1 = tay không
var _charging := false         # đang giữ F để lấy lực
var _charge := 0.0
var _act_kind := ""            # tư thế hành động: "throw", "kick", "pick"
var _act_t := 0.0
var _act_dur := 0.3
var _dlg := false              # đang mở hộp thoại (khi đó người chơi đứng yên)
var _dlg_i := -1               # chỉ số NPC đang nói chuyện (chỉ một cuộc hội thoại tại một thời điểm)
var _dlg_line := 0             # câu thoại hiện tại
var _dlg_shown := 0.0          # số ký tự đã hiện (hiệu ứng gõ chữ)
var _dlg_cool := 0.0           # thời gian chờ sau khi đóng hộp thoại (chống bấm E lặp)
var _dlg_lines: Array = []     # các dòng của trang đang hiện
var _dlg_pages: Array = []     # câu hiện tại đã tự xuống dòng, chia theo trang
var _dlg_page := 0

func _ready() -> void:
	_ensure_building_entry()
	_build_hall()
	_layer = CanvasLayer.new()
	_layer.layer = 5   # trên thế giới, dưới các thanh HUD và sổ tay (6-8)
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint_world)
	_ui = script.new()
	_ui.font = game.font
	_ui.logo = game.logo
	_layer.add_child(_ui)
	_ui.draw.connect(_paint_ui)
	# features/building_doors.gd được nạp SAU module bản đồ nên chưa tồn tại lúc này -> gỡ cửa chung ở cuối khung hình.
	call_deferred("_detach_generic_gym_door")

# Ô "NHÀ THỂ DỤC" đã có trong campus_data.gd; chỉ thêm lại nếu ai đó lỡ xóa (tránh mất va chạm), không tạo trùng.
func _ensure_building_entry() -> void:
	for b in game.BUILDINGS:
		if str(b[0]) == "NHÀ THỂ DỤC":
			return
	game.BUILDINGS.append(["NHÀ THỂ DỤC", RECT.position.x, RECT.position.y, RECT.size.x, RECT.size.y, WALL_COL, ROOF_COL, "Nhà tập luyện Thể dục Thể thao - sân tập trong nhà."])

# Gỡ cửa "gym" chung khỏi building_doors.gd (cùng cách nha_dieu_hanh.gd gỡ cửa "office").
func _detach_generic_gym_door() -> void:
	for f in game.features:
		if f == self:
			continue
		var list: Variant = f.get("doors")
		if list is Array:
			for i in range(list.size() - 1, -1, -1):
				var d: Variant = list[i]
				if d is Dictionary and str(d.get("kind", "")) == "gym":
					list.remove_at(i)

# Vật cản trong sảnh (hộp chạm ở mặt sàn)
func _build_hall() -> void:
	_solid.clear()
	_solid_h.clear()
	_npcs.clear()
	_seats.clear()
	_add_solid(NET_RECT, BALL_NET_H)
	_add_solid(GOAL_RECT, BALL_HIT_H)
	_add_solid(RACK_RECT, 18.0)
	_add_solid(COOLER_RECT, BALL_HIT_H)
	for r in BENCH_RECTS:
		_add_solid(r, 12.0)
		for k in BENCH_SEATS:
			var sx: float = r.position.x + SEAT_GAP * (k + 1)
			# pos: ngồi trên mặt ghế (người vẽ trước, mặt ghế vẽ sau che phần chân); stand: chỗ đứng lên phía sân; south: phía tường
			_seats.append({"pos": Vector2(sx, r.end.y - 5.0), "center": Vector2(sx, r.get_center().y),
				"stand": Vector2(sx, r.position.y - 5.0), "south": Vector2(sx, r.end.y + 5.0), "taken": false})
	_add_npc("thay_vo", NPC_VO_NAME, NPC_VO_POS, NPC_VO_FACE, NPC_VO_LINES)
	_add_npc("thay_bong_da", NPC_BD_NAME, NPC_BD_POS, NPC_BD_FACE, NPC_BD_LINES)
	_init_balls()

# Thêm một vật cản: r cho người chơi, h là độ cao chặn bóng
func _add_solid(r: Rect2, h: float) -> void:
	_solid.append(r)
	_solid_h.append(h)

func _add_npc(id: String, npc_name: String, p: Vector2, face: int, lines: Array) -> void:
	_npcs.append({"id": id, "name": npc_name, "pos": p, "home_face": face, "face": face,
		"lines": lines.duplicate(), "idle_t": randf() * 4.0, "look_t": 0.0, "calm": 0.0})
	_add_solid(Rect2(p.x - 8.0, p.y - 4.0, 16.0, 6.0), BALL_HIT_H)   # NPC đứng yên nên là vật cản (rộng bằng thân + tay để người chơi không đè lên sprite)

func _near_entrance() -> bool:
	return game.player.distance_to(ENTRANCE) < DOOR_RANGE

# Có tính năng khác (ví dụ sổ tay Tab) đang mở không: khi đó không đi và không nhận E trong sảnh
func _other_busy() -> bool:
	for f in game.features:
		if f != self and f.active:
			return true
	return false

# ======================= VÀO / RA =======================

func begin() -> void:
	super()
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_anim = 0.0
	_fade = 1.0
	_banner = 3.5
	_release_seat()
	_reset_ball_state()
	_close_dialogue(false)
	_cam_x = clampf(START_POS.x - VIEW.x / 2.0, 0.0, HALL_W - VIEW.x)
	_painter.position = Vector2(roundf(-_cam_x), 0.0)
	_layer.visible = true
	game.hud.visible = false   # ẩn dòng tên khu vực của thế giới ngoài trời khi đang ở trong nhà tập

func finish() -> void:
	super()
	inside = false
	_closing = false
	_release_seat()
	_reset_ball_state()
	_close_dialogue(false)
	_layer.visible = false
	game.hud.visible = true
	_lock_until = Time.get_ticks_msec() + 400
	# Trở lại đúng lối vào ngoài trời (948, 260), quay mặt xuống.
	if not game.blocked(ENTRANCE):
		game.player = ENTRANCE
	game.facing = 0
	if game.cam != null:
		game.cam.position = game.player
		game.cam.reset_smoothing()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	# F: bắt đầu lấy lực để ném / sút quả bóng đang cầm (nhả F thì bóng bay đi, xem _process)
	if k.pressed and not k.echo and k.physical_keycode == KEY_F:
		if inside and _can_act_ball():
			_charging = true
			_charge = 0.0
			get_viewport().set_input_as_handled()
		return
	if not k.pressed or k.echo or k.physical_keycode != KEY_E:
		return
	if inside:
		if _closing or _other_busy():
			return
		if _dlg:
			_advance_dialogue()
		elif _seat >= 0:
			_stand_up()   # đang ngồi: E để đứng dậy (khi đang ngồi không thoại, không ra cửa được)
		elif _dlg_cool <= 0.0:
			var i := _npc_near()
			if i >= 0:
				_open_dialogue(i)
			elif _pos.distance_to(EXIT_POS) < EXIT_RANGE:
				_closing = true   # mờ dần rồi ra ngoài (xem _process)
			elif _held >= 0:
				_put_down_ball()   # đang cầm bóng: E để đặt xuống (không ngồi khi đang cầm bóng)
			else:
				var bi := _ball_near()
				if bi >= 0:
					_pick_up_ball(bi)
				else:
					var si := _seat_near()
					if si >= 0:
						_sit(si)
		get_viewport().set_input_as_handled()
	elif not game.is_busy() and Time.get_ticks_msec() >= _lock_until and _near_entrance():
		begin()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not inside:
		return
	_clock += delta
	_banner = maxf(_banner - delta, 0.0)
	_dlg_cool = maxf(_dlg_cool - delta, 0.0)
	_update_npcs(delta)
	_update_dialogue(delta)
	_act_t = maxf(_act_t - delta, 0.0)
	if _act_t <= 0.0:
		_act_kind = ""
	_update_balls(delta)
	if _charging:
		if not _can_act_ball():
			_charging = false
		else:
			_charge = minf(_charge + delta, CHARGE_TIME)
			if not Input.is_physical_key_pressed(KEY_F):   # nhả F: ném / sút
				_release_ball()
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			finish()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		if not _dlg and _seat < 0 and not _other_busy():   # đang thoại hoặc đang ngồi thì người chơi đứng yên
			_walk(delta)
	var target := clampf(_pos.x - VIEW.x / 2.0, 0.0, HALL_W - VIEW.x)
	_cam_x = lerpf(_cam_x, target, clampf(delta * 8.0, 0.0, 1.0))
	_painter.position = Vector2(roundf(-_cam_x), 0.0)
	_painter.queue_redraw()
	_ui.queue_redraw()

# ======================= BÓNG: NHẶT, ĐẶT, NÉM, SÚT =======================

func _init_balls() -> void:
	_balls.clear()
	for spot in BALL_SPOTS:
		var bp: Vector2 = spot[0]
		# pos là điểm bóng chạm sàn (tâm bóng vẽ cao hơn BALL_R), nên cộng BALL_R để giữ nguyên chỗ nhìn thấy của bóng sàn cũ
		_balls.append({"kind": str(spot[1]), "pos": Vector2(bp.x, bp.y + BALL_R), "z": 0.0, "vel": Vector2.ZERO, "vz": 0.0, "moving": false})

func _ball_dir() -> Vector2:
	if _face == 0:
		return Vector2(0, 1)
	if _face == 1:
		return Vector2(0, -1)
	if _face == 2:
		return Vector2(-1, 0)
	return Vector2(1, 0)

# Chỉ ném/sút được khi đang cầm bóng, đứng (không ngồi, không thoại, không ra cửa, không có sổ tay mở)
func _can_act_ball() -> bool:
	return _held >= 0 and _seat < 0 and not _dlg and not _closing and not _other_busy()

func _start_act(kind: String, dur: float) -> void:
	_act_kind = kind
	_act_dur = dur
	_act_t = dur

# Rời nhà tập / vào lại: thả quả bóng đang cầm xuống sàn và hủy lấy lực
func _reset_ball_state() -> void:
	if _held >= 0:
		_put_down_ball()
	_charging = false
	_charge = 0.0
	_act_kind = ""
	_act_t = 0.0

# Vị trí bóng (điểm chạm sàn) bị chặn ở độ cao z? Chỉ vật cản thấp hơn z mới chặn; ngoài biên sảnh luôn chặn
func _ball_blocked(bp: Vector2, z: float) -> bool:
	if bp.x < BALL_XMIN or bp.x > HALL_W - BALL_XMIN or bp.y < BALL_YMIN or bp.y > BALL_YMAX:
		return true
	for k in _solid.size():
		if z < float(_solid_h[k]):
			var rr: Rect2 = _solid[k]
			if rr.grow(BALL_R).has_point(bp):
				return true
	return false

# Quả bóng nhặt được gần nhất (đang nằm yên hoặc lăn rất chậm, sát sàn) trong tầm BALL_PICK_RANGE, -1 nếu không có
func _ball_near() -> int:
	var best := -1
	var bd := BALL_PICK_RANGE
	for i in _balls.size():
		if i == _held:
			continue
		var b: Dictionary = _balls[i]
		var v: Vector2 = b.vel
		if float(b.z) > 8.0 or v.length() > 40.0:
			continue
		var bp: Vector2 = b.pos
		var d := _pos.distance_to(bp)
		if d < bd:
			bd = d
			best = i
	return best

func _pick_up_ball(i: int) -> void:
	var b: Dictionary = _balls[i]
	b.moving = false
	b.vel = Vector2.ZERO
	b.vz = 0.0
	b.z = 0.0
	_held = i   # đang cầm thì không nhặt thêm quả khác (xem _unhandled_input)
	_start_act("pick", 0.22)

# Đặt bóng xuống sàn trước mặt (hoặc ngay chân / hai bên nếu trước mặt bị vật cản); kẹt hết thì để vật lý đẩy ra
func _put_down_ball() -> void:
	var b: Dictionary = _balls[_held]
	var dir := _ball_dir()
	var spot := _pos + dir * 9.0
	var found := false
	var cands: Array = [spot, _pos + dir * 5.0, _pos, _pos + Vector2(9, 0), _pos + Vector2(-9, 0), _pos + Vector2(0, 9), _pos + Vector2(0, -9)]
	for c in cands:
		if not _ball_blocked(c, 0.0):
			spot = c
			found = true
			break
	b.pos = spot
	b.z = 0.0
	b.vel = Vector2.ZERO
	b.vz = 0.0
	b.moving = not found
	_held = -1
	_charging = false
	_charge = 0.0

# Nhả F: bóng rổ / bóng chuyền được ném theo đường cong, bóng đá được sút. Hướng theo mặt người chơi, lực theo thời gian giữ F.
func _release_ball() -> void:
	if _held < 0:
		return
	var b: Dictionary = _balls[_held]
	var power := clampf(_charge / CHARGE_TIME, 0.0, 1.0)
	var dir := _ball_dir()
	var kick := str(b.kind) == "foot"
	var z0 := 2.0 if kick else THROW_HAND_Z
	var start := _pos + dir * (10.0 if kick else 6.0)
	if _ball_blocked(start, z0):
		start = _pos   # đứng sát vật cản: thả bóng từ chân/tay thay vì từ phía trước
		var back := 0.0
		while _ball_blocked(start, z0) and back < 12.0:   # vẫn kẹt (đứng sát lưới): lùi điểm thả ra phía sau người chơi
			back += 2.0
			start = _pos - dir * back
	var spd := lerpf(KICK_SPEED_MIN, KICK_SPEED_MAX, power) if kick else lerpf(THROW_SPEED_MIN, THROW_SPEED_MAX, power)
	var vz := KICK_LIFT * (0.6 + 0.8 * power) if kick else THROW_VZ
	if not kick:
		var a := _net_assist(start, dir, z0, spd)
		spd = a.x
		vz = a.y
	b.pos = start
	b.z = z0
	b.vel = dir * spd
	b.vz = vz
	b.moving = true
	_held = -1
	_charging = false
	_charge = 0.0
	_start_act("kick" if kick else "throw", 0.28)

# Ném về phía lưới (đứng trong khoảng giữa hai cọc): chọn vận tốc ngang và vz vừa đủ để tâm bóng cao hơn lưới suốt đoạn bóng đi qua
# vùng lưới (±6 px quanh mặt phẳng lưới). Đứng sát lưới thì ném thành đường vòng cung gần như thẳng đứng thay vì đập vào lưới.
func _net_assist(start: Vector2, dir: Vector2, z0: float, spd: float) -> Vector2:
	if dir.y == 0.0:
		return Vector2(spd, THROW_VZ)
	var plane := NET_RECT.position.y + NET_RECT.size.y * 0.5
	var d := (plane - start.y) * dir.y
	if d <= 0.0 or start.x < NET_RECT.position.x or start.x > NET_RECT.end.x:
		return Vector2(spd, THROW_VZ)
	var need := BALL_NET_H + 3.0
	var sp := spd
	for i in 24:
		var t1 := maxf(d - 6.0, 0.0) / sp
		var t2 := (d + 6.0) / sp
		var need1 := (need - z0 + 0.5 * BALL_GRAVITY * t1 * t1) / maxf(t1, 0.001)
		var need2 := (need - z0 + 0.5 * BALL_GRAVITY * t2 * t2) / t2
		var v := maxf(maxf(need1, need2), THROW_VZ)
		if v <= 260.0:
			return Vector2(sp, v)
		sp *= 0.8
	return Vector2(spd, THROW_VZ)

func _update_balls(delta: float) -> void:
	var steps := 2 if delta > 0.02 else 1
	var dt := minf(delta, 0.05) / steps
	for i in _balls.size():
		if i == _held:
			continue
		var b: Dictionary = _balls[i]
		if not b.moving:
			continue
		for s in steps:
			_step_ball(b, dt)

# Một bước vật lý nhẹ: rơi + nảy khi chạm sàn (mỗi loại bóng nảy khác nhau), lăn chậm dần, bật khỏi tường sảnh,
# va chạm vật cản chỉ khi bóng thấp hơn vật đó; lưới chặn bóng thấp hơn BALL_NET_H và hút hết lực (bóng rơi xuống sát lưới).
func _step_ball(b: Dictionary, dt: float) -> void:
	var kd: Dictionary = BALL_KINDS[str(b.kind)]
	var v: Vector2 = b.vel
	var z: float = b.z
	var vz: float = b.vz
	var bp: Vector2 = b.pos
	vz -= BALL_GRAVITY * dt
	z += vz * dt
	bp += v * dt
	var bounced := false
	if z > BALL_CEIL:
		z = BALL_CEIL
		vz = -absf(vz) * 0.4
	if z <= 0.0:
		z = 0.0
		if vz < -28.0:
			vz = -vz * float(kd.bounce)
			v *= 0.82
			bounced = true
		else:
			vz = 0.0
	if z == 0.0 and vz == 0.0 and not bounced:
		v *= exp(-float(kd.roll) * dt)
	# tường sảnh
	if bp.x < BALL_XMIN:
		bp.x = BALL_XMIN
		v.x = absf(v.x) * 0.55
	elif bp.x > HALL_W - BALL_XMIN:
		bp.x = HALL_W - BALL_XMIN
		v.x = -absf(v.x) * 0.55
	if bp.y < BALL_YMIN:
		bp.y = BALL_YMIN
		v.y = absf(v.y) * 0.55
	elif bp.y > BALL_YMAX:
		bp.y = BALL_YMAX
		v.y = -absf(v.y) * 0.55
	# vật cản (lưới, ghế, tủ nước, khung thành, giá bóng, NPC): đẩy bóng ra khỏi cạnh gần nhất và phản xạ vận tốc
	for k in _solid.size():
		var h := float(_solid_h[k])
		if z >= h:
			continue
		var rr: Rect2 = _solid[k]
		rr = rr.grow(BALL_R)
		if not rr.has_point(bp):
			continue
		var dl := bp.x - rr.position.x
		var dr := rr.end.x - bp.x
		var dtp := bp.y - rr.position.y
		var dbt := rr.end.y - bp.y
		var m := minf(minf(dl, dr), minf(dtp, dbt))
		var damp := 0.5
		if h >= BALL_NET_H:
			damp = 0.2
			vz *= 0.6
		if m == dl:
			bp.x = rr.position.x - 0.01
			v.x = -absf(v.x) * damp
		elif m == dr:
			bp.x = rr.end.x + 0.01
			v.x = absf(v.x) * damp
		elif m == dtp:
			bp.y = rr.position.y - 0.01
			v.y = -absf(v.y) * damp
		else:
			bp.y = rr.end.y + 0.01
			v.y = absf(v.y) * damp
	if z == 0.0 and vz == 0.0 and v.length() < 6.0:
		v = Vector2.ZERO
		b.moving = false
	b.vel = v
	b.z = z
	b.vz = vz
	b.pos = bp

# ---- vẽ bóng, tư thế và gợi ý ----

# Bóng trên sàn / đang bay: bóng đổ nằm trên sàn (nhỏ và nhạt dần khi bóng lên cao), thân bóng vẽ cao hơn điểm chạm sàn z + BALL_R.
# Bóng được sắp cùng người và vật dụng theo y của điểm chạm sàn nên tự đứng trước / sau lưới theo vị trí thật.
func _paint_ball_obj(p: Node2D, i: int) -> void:
	var b: Dictionary = _balls[i]
	var bp: Vector2 = b.pos
	var z: float = b.z
	var sw := maxf(1.5, 3.5 - z / 25.0)
	var sa := clampf(0.28 - z / 400.0, 0.1, 0.28)
	p.rc(roundf(bp.x - sw), roundf(bp.y) - 1.0, roundf(sw * 2.0), 2, Color(0, 0, 0, sa))
	_paint_ball_body(p, Vector2(roundf(bp.x), roundf(bp.y - BALL_R - z)), BALL_R, str(b.kind))

# Tâm quả bóng đang cầm: bóng rổ / bóng chuyền ôm trước ngực (giơ cao dần khi lấy lực), bóng đá để dưới chân phía trước
func _held_ball_center(kind: String, base: Vector2) -> Vector2:
	var x := base.x
	var y := base.y
	if kind == "foot":
		if _face == 0:
			return Vector2(x + 3.0, y + 1.0)
		if _face == 1:
			return Vector2(x + 6.0, y - 3.0)
		if _face == 2:
			return Vector2(x - 8.0, y - 1.0)
		return Vector2(x + 8.0, y - 1.0)
	var lift := 0.0
	if _charging:
		lift = lerpf(0.0, 18.0, clampf(_charge / CHARGE_TIME, 0.0, 1.0))
	if _face == 0:
		return Vector2(x, y - 8.0 - lift)
	if _face == 2:
		return Vector2(x - 7.0, y - 9.0 - lift)
	return Vector2(x + 7.0, y - 9.0 - lift)

func _paint_held_ball(p: Node2D, base: Vector2) -> void:
	var b: Dictionary = _balls[_held]
	var kind := str(b.kind)
	var c := _held_ball_center(kind, base)
	if _act_kind == "pick" and _act_t > 0.0 and _act_dur > 0.0:
		var u := 1.0 - _act_t / _act_dur
		var bp: Vector2 = b.pos
		c = Vector2(bp.x, bp.y - BALL_R).lerp(c, smoothstep(0.0, 1.0, u))   # bóng đi từ sàn lên tay / chân
	_paint_ball_body(p, Vector2(roundf(c.x), roundf(c.y)), BALL_R, kind)

# Cú sút: chân đưa ra phía trước theo hướng mặt, mạnh nhất ở giữa cú sút
func _paint_kick_leg(p: Node2D, u: float) -> void:
	var reach := roundf(sin(PI * u) * 6.0)
	if reach < 1.0:
		return
	var x := _pos.x
	var y := _pos.y
	var ol := C_OUTLINE
	var navy := Color("2b2f4a")
	var shoe := Color("f4f4f4")
	if _face == 2:
		p.rc(x - 3.0 - reach, y - 6.0, reach + 3.0, 4, ol)
		p.rc(x - 2.0 - reach, y - 5.0, reach + 2.0, 2, navy)
		p.rc(x - 5.0 - reach, y - 5.0, 3, 3, shoe)
	elif _face == 3:
		p.rc(x, y - 6.0, reach + 3.0, 4, ol)
		p.rc(x, y - 5.0, reach + 2.0, 2, navy)
		p.rc(x + 2.0 + reach, y - 5.0, 3, 3, shoe)
	elif _face == 0:
		p.rc(x + 1.0, y - 2.0, 4, reach + 2.0, ol)
		p.rc(x + 2.0, y - 2.0, 2, reach + 1.0, navy)
		p.rc(x + 1.0, y + reach - 1.0, 4, 3, shoe)
	else:
		p.rc(x + 1.0, y - 8.0 - reach, 4, reach + 3.0, ol)
		p.rc(x + 2.0, y - 8.0 - reach, 2, reach + 2.0, navy)
		p.rc(x + 1.0, y - 9.0 - reach, 4, 3, shoe)

# Thanh lực khi giữ F
func _paint_charge_bar(p: Node2D) -> void:
	if not _charging:
		return
	var pw := clampf(_charge / CHARGE_TIME, 0.0, 1.0)
	var bx := roundf(_pos.x) - 13.0
	var by := roundf(_pos.y) - 42.0
	p.rc(bx - 1.0, by - 1.0, 28, 6, C_OUTLINE)
	p.rc(bx, by, 26, 4, Color("3a3f4a"))
	p.rc(bx, by, roundf(26.0 * pw), 4, Color("ffd23f") if pw < 0.95 else Color("ff7a3a"))

# Gợi ý phím: nhặt bóng khi đứng gần bóng, hoặc cách ném / sút khi đang cầm bóng
func _paint_ball_prompt(p: Node2D) -> void:
	if _closing or _dlg or _seat >= 0 or _npc_near() >= 0 or _pos.distance_to(EXIT_POS) < EXIT_RANGE:
		return
	if _held >= 0:
		var act := "Sút" if str(_balls[_held].kind) == "foot" else "Ném"
		p.ctext("[F] %s (giữ F = mạnh hơn)   [E] Đặt xuống" % act, _pos.x - 110.0, _pos.y - 44.0, 220, 8, Color.WHITE)
		return
	var bi := _ball_near()
	if bi >= 0:
		var kd: Dictionary = BALL_KINDS[str(_balls[bi].kind)]
		p.ctext("[E] Nhặt " + str(kd.name), _pos.x - 60.0, _pos.y - 44.0, 120, 8, Color.WHITE)

# ======================= GHẾ DÀI: NGỒI / ĐỨNG DẬY =======================

# Chỗ ngồi hợp lệ gần người chơi nhất trong tầm SEAT_RANGE (-1 nếu không có)
func _seat_near() -> int:
	var best := -1
	var bd := SEAT_RANGE
	for i in _seats.size():
		var c: Vector2 = _seats[i].center
		var d := _pos.distance_to(c)
		if d < bd and _seat_free(i):
			bd = d
			best = i
	return best

# Chỗ ngồi bị chiếm nếu đã có người ngồi hoặc có NPC đứng sát chỗ đó
func _seat_free(i: int) -> bool:
	var s: Dictionary = _seats[i]
	if s.taken:
		return false
	var sp: Vector2 = s.pos
	for n in _npcs:
		var np: Vector2 = n.pos
		if np.distance_to(sp) < SEAT_NPC_CLEAR:
			return false
	return true

# Ngồi xuống: dời người chơi lên mặt ghế, quay mặt về phía sân. Cùng cách với ghế trong b42_lab.gd: không đổi sprite,
# người chơi được sắp theo y nên vẽ trước ghế (y ngồi < đáy ghế), mặt ghế vẽ sau che phần chân.
func _sit(i: int) -> void:
	var s: Dictionary = _seats[i]
	_sit_from = _pos
	s.taken = true
	_seat = i
	_pos = s.pos
	_face = 1
	_anim = 0.0

# Đứng dậy: ưu tiên chỗ đứng phía sân (và hai bên), rồi phía tường, cuối cùng là chỗ đứng trước khi ngồi
func _stand_up() -> void:
	var s: Dictionary = _seats[_seat]
	var sp: Vector2 = s.stand
	var south: Vector2 = s.south
	var spot := _sit_from
	var spot_face := 0
	var cands: Array = [sp, sp + Vector2(-10, 0), sp + Vector2(10, 0), sp + Vector2(-20, 0), sp + Vector2(20, 0), south]
	for c in cands:
		if not _blocked(c):
			spot = c
			spot_face = 0 if c == south else 1
			break
	_pos = spot
	_face = spot_face
	_release_seat()

func _release_seat() -> void:
	if _seat >= 0 and _seat < _seats.size():
		_seats[_seat].taken = false
	_seat = -1

# Gợi ý phím khi đứng gần ghế hoặc đang ngồi
func _paint_seat_prompt(p: Node2D) -> void:
	if _closing or _dlg:
		return
	if _seat >= 0:
		p.ctext("[E] Đứng dậy", _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)
	elif _held < 0 and _npc_near() < 0 and _ball_near() < 0 and _seat_near() >= 0:
		p.ctext("[E] Ngồi", _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)

# ======================= NPC VÀ HỘP THOẠI =======================

func _npc_face(d: Vector2) -> int:
	if absf(d.x) > absf(d.y):
		return 2 if d.x < 0.0 else 3
	return 1 if d.y < 0.0 else 0

# NPC gần người chơi nhất trong tầm nói chuyện (-1 nếu không có). Mỗi NPC độc lập, chỉ NPC gần nhất được chọn.
func _npc_near() -> int:
	var best := -1
	var bd := NPC_TALK_RANGE
	for i in _npcs.size():
		var c: Vector2 = _npcs[i].pos
		var d := _pos.distance_to(c)
		if d < bd:
			bd = d
			best = i
	return best

func _update_npcs(delta: float) -> void:
	for i in _npcs.size():
		var n: Dictionary = _npcs[i]
		n.idle_t += delta
		# đang thoại thì các động tác idle mạnh (đấm, đứng tấn, cúi chào) tắt dần mượt thay vì dừng đột ngột
		n.calm = move_toward(float(n.calm), 1.0 if (_dlg and _dlg_i == i) else 0.0, delta * 4.0)
		if n.look_t > 0.0:
			n.look_t -= delta
			if n.look_t <= 0.0 and not (_dlg and _dlg_i == i):
				n.face = n.home_face   # nói chuyện xong một lúc thì quay về hướng cũ

func _open_dialogue(i: int) -> void:
	var first: Array = _npcs[i].lines
	if first.is_empty():
		return
	_dlg = true
	_dlg_i = i
	_dlg_line = 0
	var n: Dictionary = _npcs[i]
	n.face = _npc_face(_pos - n.pos)   # NPC quay mặt về phía người chơi
	_set_dialogue_line()

func _set_dialogue_line() -> void:
	var lines: Array = _npcs[_dlg_i].lines
	var wrapped := _wrap(str(lines[_dlg_line]), VIEW.x - 52.0)
	_dlg_pages = []
	for i in range(0, wrapped.size(), DIALOGUE_PAGE_LINES):
		_dlg_pages.append(wrapped.slice(i, i + DIALOGUE_PAGE_LINES))
	if _dlg_pages.is_empty():
		_dlg_pages.append([])
	_dlg_page = 0
	_dlg_lines = _dlg_pages[0]
	_dlg_shown = 0.0

func _dialogue_chars() -> int:
	var total := 0
	for l in _dlg_lines:
		total += str(l).length()
	return total

# Bấm E: đang gõ chữ thì hiện đủ trang ngay; đã hiện đủ thì sang trang/câu sau, hết câu cuối thì đóng hộp thoại.
func _advance_dialogue() -> void:
	if int(_dlg_shown) < _dialogue_chars():
		_dlg_shown = float(_dialogue_chars())
		return
	if _dlg_page + 1 < _dlg_pages.size():
		_dlg_page += 1
		_dlg_lines = _dlg_pages[_dlg_page]
		_dlg_shown = 0.0
		return
	var lines: Array = _npcs[_dlg_i].lines
	if _dlg_line + 1 < lines.size():
		_dlg_line += 1
		_set_dialogue_line()
	else:
		_close_dialogue(true)

func _close_dialogue(cooldown: bool) -> void:
	if _dlg and _dlg_i >= 0 and _dlg_i < _npcs.size():
		_npcs[_dlg_i].look_t = 5.0
	_dlg = false
	_dlg_i = -1
	_dlg_line = 0
	_dlg_shown = 0.0
	_dlg_lines = []
	_dlg_pages = []
	_dlg_page = 0
	_dlg_cool = 0.25 if cooldown else 0.0

func _update_dialogue(delta: float) -> void:
	if not _dlg:
		return
	_dlg_shown = minf(_dlg_shown + delta * TYPE_SPEED, float(_dialogue_chars()))

func _text_w(t: String) -> float:
	return _painter.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x

# Tự xuống dòng theo độ rộng chữ (cỡ 8), giống wrap_text() của newcharacters.gd; từ dài hơn cả dòng thì cắt cứng
func _wrap(t: String, max_w: float) -> Array:
	var out: Array = []
	var cur := ""
	for word in t.split(" ", false):
		var w: String = word
		while _text_w(w) > max_w and w.length() > 1:
			var k := w.length() - 1
			while k > 1 and _text_w(w.substr(0, k)) > max_w:
				k -= 1
			if cur != "":
				out.append(cur)
				cur = ""
			out.append(w.substr(0, k))
			w = w.substr(k)
		var test := w if cur == "" else cur + " " + w
		if cur != "" and _text_w(test) > max_w:
			out.append(cur)
			cur = w
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out

# ======================= VẼ SẢNH =======================

func _paint_world() -> void:
	var p := _painter
	p.rc(0, 0, HALL_W, VIEW.y, Color("1b2230"))
	_paint_roof(p)
	_paint_back_wall(p)
	_paint_floor(p)
	_paint_markings(p)
	_paint_mats(p)
	_paint_lights(p)
	_paint_exit_door(p)
	for cp in CONES:
		_paint_cone(p, cp)
	# vật dụng và người chơi sắp theo y để che nhau đúng
	var items: Array = []
	# lưới sắp theo mặt phẳng giữa của nó: bóng ở phía nam (y lớn hơn) vẽ sau lưới = trước lưới, bóng ở phía bắc vẽ trước lưới = sau lưới
	items.append([NET_RECT.position.y + NET_RECT.size.y * 0.5, 0, null])
	items.append([GOAL_RECT.end.y, 1, null])
	items.append([RACK_RECT.end.y, 2, null])
	items.append([COOLER_RECT.end.y, 3, null])
	for r in BENCH_RECTS:
		items.append([r.end.y, 4, r])
	for i in _npcs.size():
		items.append([_npcs[i].pos.y, 5, i])
	for i in _balls.size():
		if i != _held:
			items.append([_balls[i].pos.y, 7, i])
	items.append([_pos.y, 6, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				_paint_net(p)
			1:
				_paint_goal(p)
			2:
				_paint_rack(p)
			3:
				_paint_cooler(p)
			4:
				_paint_bench(p, it[2])
			5:
				_paint_npc(p, it[2])
			7:
				_paint_ball_obj(p, it[2])
			_:
				_paint_player(p)
	_paint_motes(p)
	_paint_npc_prompt(p)
	# gợi ý "[E] Ra ngoài" khi đứng gần cửa
	if not _closing and not _dlg and _seat < 0 and _npc_near() < 0 and _pos.distance_to(EXIT_POS) < EXIT_RANGE:
		p.ctext("[E] Ra ngoài", _pos.x - 40.0, _pos.y - 44.0, 80, 8, Color.WHITE)
	_paint_seat_prompt(p)
	_paint_ball_prompt(p)

# Lớp cố định trên màn hình: biển tên khi mới vào và mờ dần
func _paint_ui() -> void:
	var p := _ui
	_paint_banner(p)
	if _dlg and _dlg_i >= 0 and _dlg_i < _npcs.size():
		_paint_dialogue(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# ======================= DI CHUYỂN TRONG SẢNH =======================

func _walk(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
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

# cùng cách tính với game.blocked(): chân nhân vật là hộp 8x4
func _blocked(p: Vector2) -> bool:
	if p.x < 14.0 or p.x > HALL_W - 14.0 or p.y < WALK_TOP or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _solid:
		if hit.intersects(s):
			return true
	return false

# ======================= CÁC HÀM VẼ SẢNH =======================

# ---- Mái: tôn tối, xà gồ, giàn kèo thép ----
func _paint_roof(p: Node2D) -> void:
	p.rc(0, 0, HALL_W, 22, Color("2d3646"))
	for yy in [4, 10, 16]:
		p.rc(0, yy, HALL_W, 1, Color("3b465a"))
	for xx in range(0, int(HALL_W), 7):
		p.rc(xx, 0, 1, 20, Color(0, 0, 0, 0.12))
	for i in COL_XS.size() - 1:
		_paint_truss(p, COL_XS[i], COL_XS[i + 1])

# Giàn kèo tam giác có thanh bụng zigzag (một nhịp giữa hai cột)
func _paint_truss(p: Node2D, x0: float, x1: float) -> void:
	var xm := (x0 + x1) / 2.0
	var hw := (x1 - x0) / 2.0
	var main := Color("0f141d")
	var web := Color("5b6781")
	var step := 12.0
	var x := x0
	while x + step <= x1:
		var xc := x + step / 2.0
		var yc := 21.0 - 19.0 * (1.0 - absf(xc - xm) / hw)
		p.draw_line(Vector2(x, 21), Vector2(xc, yc + 1.0), web, 1.0)
		p.draw_line(Vector2(xc, yc + 1.0), Vector2(x + step, 21), web, 1.0)
		x += step
	p.draw_line(Vector2(x0, 21), Vector2(xm, 2), main, 2.0)
	p.draw_line(Vector2(xm, 2), Vector2(x1, 21), main, 2.0)
	p.draw_line(Vector2(xm - 1.0, 2), Vector2(xm - 1.0, 21), Color("2c3546"), 1.0)
	p.rc(x0, 20, x1 - x0, 2, main)
	p.rc(x0, 20, x1 - x0, 1, Color("3a4558"))

# ---- Tường phía bắc: tường trắng, cửa sổ cao, biển, rổ, cột, dải ngọc lam, bảng MEMORIES ----
func _paint_back_wall(p: Node2D) -> void:
	p.rc(0, 22, HALL_W, 36, Color("dfe5ea"))
	for xx in range(0, int(HALL_W), 24):
		p.rc(xx, 22, 1, 36, Color("cdd4da"))
	p.rc(0, 22, HALL_W, 2, Color("b9c3cc"))
	for wx in WIN_XS:
		_paint_window(p, wx)
	# dải ngọc lam phía dưới tường
	p.rc(0, 58, HALL_W, 16, C_TURQ)
	p.rc(0, 58, HALL_W, 2, Color("7fdbe8"))
	p.rc(0, 60, HALL_W, 1, Color("1c8fa8"))
	for xx in range(0, int(HALL_W), 16):
		p.rc(xx, 61, 1, 11, Color("20a3bb"))
	p.rc(0, 72, HALL_W, 2, Color("1a7f96"))
	_paint_sign_plate(p)
	for hx in HOOP_XS:
		_paint_hoop(p, hx)
	_paint_clock(p, 192.0, 40.0)
	_paint_memories(p)
	_paint_side_frames(p)
	_paint_storage_door(p, 566.0)
	for cx in COL_XS:
		_paint_column(p, cx)
	# tường bên trái / phải
	p.rc(0, 0, 8, VIEW.y, Color("4a4f5b"))
	p.rc(HALL_W - 8.0, 0, 8, VIEW.y, Color("4a4f5b"))
	p.rc(8, 22, 2, 236, Color(0, 0, 0, 0.18))
	p.rc(HALL_W - 10.0, 22, 2, 236, Color(0, 0, 0, 0.18))

func _paint_window(p: Node2D, wx: float) -> void:
	p.rc(wx - 1, 23, 28, 12, Color("8f9aa6"))
	p.rc(wx, 24, 26, 10, Color("bfe3f2"))
	p.rc(wx, 24, 26, 3, Color("e2f4fb"))
	p.rc(wx + 12, 24, 2, 10, Color("8f9aa6"))
	p.rc(wx + 3, 29, 6, 1, Color(1, 1, 1, 0.7))
	p.rc(wx + 16, 30, 6, 1, Color(1, 1, 1, 0.5))

func _paint_column(p: Node2D, cx: float) -> void:
	p.rc(cx - 4, 20, 8, 54, C_NAVY)
	p.rc(cx - 4, 20, 2, 54, Color("3552b5"))
	p.rc(cx + 2, 20, 2, 54, Color("142a66"))
	p.rc(cx - 6, 70, 12, 4, Color("8f9aa6"))
	p.rc(cx - 6, 70, 12, 1, Color("c6ced6"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, 24), Vector2(cx - 12, 20), Vector2(cx - 4, 20)]), C_NAVY)
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx + 4, 24), Vector2(cx + 12, 20), Vector2(cx + 4, 20)]), C_NAVY)

func _paint_sign_plate(p: Node2D) -> void:
	p.rc(27, 36, 96, 23, Color("6b7480"))
	p.rc(28, 37, 94, 21, C_NAVY)
	p.rc(28, 37, 94, 1, Color("3552b5"))
	p.draw_rect(Rect2(30, 39, 90, 17), C_GOLD, false, 1.0)
	p.ctext("NHÀ TẬP LUYỆN", 28, 47, 94, 8, Color.WHITE)
	p.ctext("THỂ DỤC THỂ THAO", 28, 55, 94, 8, C_GOLD)

func _paint_hoop(p: Node2D, hx: float) -> void:
	p.rc(hx - 1, 24, 2, 6, Color("5a606c"))
	p.rc(hx - 13, 28, 26, 16, Color("5a606c"))
	p.rc(hx - 12, 29, 24, 14, Color("f4f6f8"))
	p.rc(hx - 12, 29, 24, 2, Color("ffffff"))
	p.draw_rect(Rect2(hx - 5, 34, 10, 7), Color("c0392b"), false, 1.0)
	p.rc(hx - 8, 44, 16, 2, Color("e86a1f"))
	p.rc(hx - 8, 44, 16, 1, Color("ff9a3c"))
	for i in 4:
		p.draw_line(Vector2(hx - 7 + i * 5, 46), Vector2(hx - 4 + i * 3, 53), Color(1, 1, 1, 0.85), 1.0)
		p.draw_line(Vector2(hx - 2 + i * 3, 46), Vector2(hx - 7 + i * 5 + 4, 53), Color(1, 1, 1, 0.55), 1.0)
	p.rc(hx - 4, 53, 8, 1, Color(1, 1, 1, 0.8))

# Đồng hồ treo tường chạy theo giờ trong game (game.game_min)
func _paint_clock(p: Node2D, cx: float, cy: float) -> void:
	p.draw_circle(Vector2(cx, cy), 9.0, Color("5a606c"))
	p.draw_circle(Vector2(cx, cy), 8.0, Color("f4f6f8"))
	for i in 12:
		var a := TAU * i / 12.0
		var v := Vector2.from_angle(a)
		p.rc(cx + v.x * 6.0 - 0.5, cy + v.y * 6.0 - 0.5, 1, 1, Color("3a3f4a"))
	var minutes: float = game.game_min
	var ma := fmod(minutes, 60.0) / 60.0 * TAU - PI / 2.0
	var ha := fmod(minutes / 60.0, 12.0) / 12.0 * TAU - PI / 2.0
	p.draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.from_angle(ha) * 4.0, Color("1a1a2e"), 1.0)
	p.draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.from_angle(ma) * 6.0, Color("c0392b"), 1.0)
	p.rc(cx - 1, cy - 1, 2, 2, Color("1a1a2e"))

# Cửa đôi tới kho dụng cụ (trang trí) trên tường phía bắc
func _paint_storage_door(p: Node2D, dx: float) -> void:
	p.rc(dx - 2, 37, 38, 37, Color("2b2f3a"))
	p.rc(dx, 39, 16, 35, Color("8a9099"))
	p.rc(dx + 18, 39, 16, 35, Color("8a9099"))
	p.rc(dx, 39, 16, 2, Color("b4bac2"))
	p.rc(dx + 18, 39, 16, 2, Color("b4bac2"))
	p.rc(dx + 16, 39, 2, 35, Color("2b2f3a"))
	p.rc(dx + 11, 54, 2, 6, Color("d8dde2"))
	p.rc(dx + 21, 54, 2, 6, Color("d8dde2"))
	p.rc(dx + 3, 44, 10, 8, Color("a9d4e6"))
	p.rc(dx + 21, 44, 10, 8, Color("a9d4e6"))

# ---- Bảng ảnh MEMORIES (nổi bật giữa tường, lấy cảm hứng từ hai ảnh chụp tập thể) ----
func _paint_memories(p: Node2D) -> void:
	# quầng sáng sau bảng
	p.draw_colored_polygon(PackedVector2Array([Vector2(214, 24), Vector2(426, 24), Vector2(446, 74), Vector2(194, 74)]), Color(1, 0.98, 0.85, 0.07))
	# nền xanh nhạt có tia nắng
	p.rc(216, 22, 208, 50, Color("8fc3ec"))
	for i in 7:
		p.rc(220 + i * 30, 22, 14, 50, Color(1, 1, 1, 0.07))
	# khung polaroid trắng
	p.rc(224, 25, 194, 47, Color(0, 0, 0, 0.25))
	p.rc(223, 24, 194, 47, Color("c7d3e6"))
	p.rc(224, 25, 192, 45, Color("fdfdfd"))
	_paint_crowd_photo(p, 229.0, 29.0)
	_paint_lineup_photo(p, 322.0, 29.0)
	p.ctext("Memories", 224, 68, 192, 10, Color("1f3f9a"))
	# trang trí: ngôi sao, trái tim, tia sáng như ảnh gốc
	_pixel_heart(p, 404.0, 18.0, Color("f3b6cf"), Color("a8141f"))
	_star(p, Vector2(232, 66), 6.0, Color("c0262d"), Color("ffffff"))
	_star(p, Vector2(408, 66), 6.0, Color("ffd23f"), Color("ffffff"))
	_star(p, Vector2(226, 27), 5.0, Color("4aa44f"), Color("ffffff"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(237, 24), Vector2(238.5, 27), Vector2(241, 28.5), Vector2(238.5, 30), Vector2(237, 33), Vector2(235.5, 30), Vector2(233, 28.5), Vector2(235.5, 27)]), Color("ffffff"))
	# hai đèn rọi phía trên bảng
	for lx in [250.0, 390.0]:
		p.rc(lx - 6, 22, 12, 2, Color("3a4152"))
		p.rc(lx - 4, 24, 8, 2, Color("fff6c2"))

# Ảnh 1: cả nhà tập đông đúc, ngồi và đứng, nhìn từ cuối sảnh (89x30)
func _paint_crowd_photo(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y, 89, 30, Color("dde4ea"))
	p.rc(x, y, 89, 9, Color("3e4c63"))
	p.draw_line(Vector2(x, y + 8), Vector2(x + 44, y + 1), Color("1b2433"), 1.0)
	p.draw_line(Vector2(x + 44, y + 1), Vector2(x + 89, y + 8), Color("1b2433"), 1.0)
	p.rc(x, y + 9, 89, 8, Color("e4e9ee"))
	p.rc(x, y + 15, 89, 4, C_TURQ)
	p.rc(x, y + 19, 89, 11, Color("2d6db5"))
	p.rc(x, y + 26, 89, 4, Color("245a9c"))
	var cols := [Color("1b2f6e"), Color("1b1b1b"), Color("f2f2f2"), Color("2f6bd0"), Color("5a3a22")]
	for i in 100:
		var dx := 8.0 + float((p.hs(i, 11) + p.hs(i * 3, 7)) % 70)
		var dy := 14.0 + float(p.hs(i * 5, 3) % 14)
		var c: Color = cols[p.hs(i, 29) % cols.size()]
		p.rc(x + dx, y + dy, 2, 2, c)
	for i in 8:
		p.rc(x + 30.0 + i * 4.0, y + 12.0, 2, 4, Color("f2f2f2") if i % 2 == 0 else Color("1b1b1b"))
	p.ctext("It-gether", x + 50, y + 29, 36, 6, Color.WHITE)

# Ảnh 2: hàng người đứng chụp chung, bên trái có standee xanh nhạt (89x30)
func _paint_lineup_photo(p: Node2D, x: float, y: float) -> void:
	p.rc(x, y, 89, 30, Color("e6eaee"))
	p.rc(x + 2, y + 2, 8, 17, Color("9fd0ee"))
	p.rc(x + 3, y + 5, 6, 8, Color("f1e3a6"))
	p.rc(x, y + 11, 89, 6, C_TURQ)
	p.rc(x, y + 17, 89, 13, Color("2d6db5"))
	p.rc(x + 60, y + 2, 1, 10, Color("8f9aa6"))
	var bodies := [Color("f2f2f2"), Color("3a3f4a"), Color("2f6bd0"), Color("1b2f6e"), Color("7a7f88"), Color("2f6bd0"), Color("f2f2f2")]
	for i in 13:
		var fx := x + 12.0 + i * 5.2
		var by := y + 27.0
		p.rc(fx, by - 12.0, 3, 3, Color("f1c27d"))
		p.rc(fx, by - 12.0, 3, 1, Color("1b1b1b"))
		p.rc(fx - 1.0, by - 9.0, 5, 6, bodies[i % bodies.size()])
		p.rc(fx, by - 3.0, 3, 3, Color("23262e"))
	p.ctext("It-gether", x + 50, y + 29, 36, 6, Color.WHITE)

# Các khung ảnh nhỏ cùng chủ đề trên tường bên phải
func _paint_side_frames(p: Node2D) -> void:
	for k in 2:
		var fx := 500.0 + k * 28.0
		p.rc(fx - 1, 37, 26, 20, Color("5a4026"))
		p.rc(fx, 38, 24, 18, Color("f4f4f4"))
		p.rc(fx + 1, 39, 22, 11, Color("e1e8ee"))
		p.rc(fx + 1, 46, 22, 2, C_TURQ)
		p.rc(fx + 1, 48, 22, 7, Color("2d6db5"))
		for i in 6:
			var c := Color("1b2f6e") if (i + k) % 2 == 0 else Color("f2f2f2")
			p.rc(fx + 3.0 + i * 3.2, 44.0, 2, 6, c)
			p.rc(fx + 3.0 + i * 3.2, 42.0, 2, 2, Color("f1c27d"))
		p.rc(fx + 4, 56, 16, 1, Color(0, 0, 0, 0.25))

func _pixel_heart(p: Node2D, x: float, y: float, fill: Color, edge: Color) -> void:
	for r in HEART_PATTERN.size():
		var row: String = HEART_PATTERN[r]
		for c in row.length():
			if row[c] == "#":
				p.rc(x + c * 2.0 - 1.0, y + r * 2.0 - 1.0, 4, 4, edge)
	for r in HEART_PATTERN.size():
		var row: String = HEART_PATTERN[r]
		for c in row.length():
			if row[c] == "#":
				p.rc(x + c * 2.0, y + r * 2.0, 2, 2, fill)

func _star(p: Node2D, c: Vector2, r: float, fill: Color, edge: Color) -> void:
	p.draw_colored_polygon(_star_poly(c, r + 1.5, (r + 1.5) * 0.45), edge)
	p.draw_colored_polygon(_star_poly(c, r, r * 0.45), fill)

func _star_poly(c: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r_out if i % 2 == 0 else r_in
		pts.append(c + Vector2.from_angle(a) * rr)
	return pts

# ---- Sàn xanh, vạch sân, thảm võ, ánh sáng ----
func _paint_floor(p: Node2D) -> void:
	for i in range(0, int(HALL_W), 20):
		p.rc(i, FLOOR_TOP, 20, FLOOR_BOTTOM - FLOOR_TOP, Color("2c6ab8") if (i / 20) % 2 == 0 else Color("2a64ae"))
	p.rc(0, FLOOR_TOP, HALL_W, 8, Color(1, 1, 1, 0.07))
	p.rc(0, FLOOR_TOP + 8.0, HALL_W, 40, Color(1, 1, 1, 0.03))
	p.rc(0, 228, HALL_W, FLOOR_BOTTOM - 228.0, Color(0, 0, 0, 0.12))
	# mép chân tường phía nam
	p.rc(0, FLOOR_BOTTOM, HALL_W, VIEW.y - FLOOR_BOTTOM, Color("3a4352"))
	p.rc(0, FLOOR_BOTTOM, HALL_W, 2, Color("232a35"))
	# phản chiếu cửa sổ trên sàn bóng
	for wx in WIN_XS:
		p.rc(wx + 8.0, FLOOR_TOP + 4.0, 10, 2, Color(1, 1, 1, 0.1))

func _paint_markings(p: Node2D) -> void:
	# sân bóng chuyền: viền, vạch giữa (dưới lưới) và 2 vạch 3 m
	var vb := C_LINE_VB
	p.draw_rect(Rect2(210, 100, 220, 128), vb, false, 2.0)
	p.draw_line(Vector2(210, 164), Vector2(430, 164), vb, 2.0)
	p.draw_line(Vector2(210, 142), Vector2(430, 142), vb, 1.0)
	p.draw_line(Vector2(210, 186), Vector2(430, 186), vb, 1.0)
	# sân bóng rổ: khu vực dưới mỗi rổ, vòng ném phạt và vạch 3 điểm
	for hx in HOOP_XS:
		p.draw_rect(Rect2(hx - 18, FLOOR_TOP, 36, 40), C_LINE_BB, false, 1.0)
		p.draw_arc(Vector2(hx, FLOOR_TOP + 40.0), 14.0, 0.0, PI, 20, C_LINE_BB, 1.0)
		p.draw_arc(Vector2(hx, FLOOR_TOP), 44.0, 0.0, PI, 32, C_LINE_BB, 1.0)
		p.draw_circle(Vector2(hx, FLOOR_TOP + 8.0), 2.0, C_LINE_BB)

# Thảm võ tatami đỏ nơi thầy dạy võ đứng
func _paint_mats(p: Node2D) -> void:
	var r := MAT_RECT
	p.rc(r.position.x - 2, r.position.y - 2, r.size.x + 4, r.size.y + 4, Color("e8e8e8"))
	for i in 5:
		for j in 3:
			var c := Color("c0392b") if (i + j) % 2 == 0 else Color("b03226")
			var tx := r.position.x + i * 24.0
			var ty := r.position.y + j * 24.0
			p.rc(tx, ty, 24, 24, c)
			p.rc(tx, ty, 24, 1, Color("d9544a"))
			p.rc(tx, ty + 23.0, 24, 1, Color("8e2a20"))
			p.rc(tx, ty, 1, 24, Color("8e2a20"))
	p.draw_rect(Rect2(r.position.x + 36, r.position.y + 12, 48, 48), Color("f2f2f2"), false, 1.0)

# Đèn thả từ giàn kèo, quầng sáng trên sàn và các dải nắng chiếu qua cửa sổ cao
func _paint_lights(p: Node2D) -> void:
	for hx in LAMP_XS:
		p.rc(hx - 8, 20, 16, 2, Color("cfd6dd"))
		p.rc(hx - 6, 22, 12, 2, Color("fff6c2"))
		p.draw_colored_polygon(PackedVector2Array([Vector2(hx - 5, 24), Vector2(hx + 5, 24), Vector2(hx + 46, 120), Vector2(hx - 46, 120)]), Color(1, 0.97, 0.8, 0.045))
		p.draw_colored_polygon(_ellipse(Vector2(hx, 168), 42.0, 12.0, 20), Color(1, 0.97, 0.85, 0.05))
	for wx in WIN_XS:
		p.draw_colored_polygon(PackedVector2Array([Vector2(wx, FLOOR_TOP + 2.0), Vector2(wx + 24.0, FLOOR_TOP + 2.0), Vector2(wx + 96.0, 188), Vector2(wx + 70.0, 188)]), Color(1, 1, 0.92, 0.045))

func _ellipse(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

# Hạt bụi bay trong ánh sáng
func _paint_motes(p: Node2D) -> void:
	for i in 16:
		var mx := 40.0 + fmod(i * 53.0 + sin(_clock * 0.4 + i) * 10.0, HALL_W - 80.0)
		var my := 90.0 + fmod(i * 37.0 + _clock * (3.0 + (i % 3)), 150.0)
		p.rc(mx, my, 1, 1, Color(1, 1, 0.9, 0.35))

# Cửa ra ở góc trái phía dưới
func _paint_exit_door(p: Node2D) -> void:
	p.rc(38, FLOOR_BOTTOM, 40, 12, Color("2b2b2b"))
	p.rc(40, FLOOR_BOTTOM + 1.0, 36, 11, Color("8a5a32"))
	p.rc(58, FLOOR_BOTTOM + 1.0, 2, 11, Color("3a2412"))
	p.rc(52, FLOOR_BOTTOM + 5.0, 2, 2, Color("e8d28a"))
	p.rc(64, FLOOR_BOTTOM + 5.0, 2, 2, Color("e8d28a"))
	p.rc(46, FLOOR_BOTTOM - 6.0, 24, 6, Color("1f7a3a"))
	p.ctext("LỐI RA", 46, FLOOR_BOTTOM - 1.0, 24, 6, Color.WHITE)

# ---- Vật dụng thể thao (sắp theo y cùng nhân vật) ----
func _paint_net(p: Node2D) -> void:
	var r := NET_RECT
	var y0 := r.end.y - 40.0
	p.rc(r.position.x, r.end.y - 2.0, r.size.x, 4, Color(0, 0, 0, 0.18))
	# lưới
	var nx0 := r.position.x + 5.0
	var nx1 := r.end.x - 5.0
	for xx in range(int(nx0), int(nx1), 4):
		p.rc(xx, y0 + 2.0, 1, 18, Color(0.1, 0.12, 0.2, 0.6))
	for yy in range(int(y0) + 2, int(y0) + 20, 4):
		p.rc(nx0, yy, nx1 - nx0, 1, Color(0.1, 0.12, 0.2, 0.6))
	p.rc(nx0, y0, nx1 - nx0, 3, Color("f4f6f8"))
	p.rc(nx0, y0 + 19.0, nx1 - nx0, 2, Color("f4f6f8"))
	# hai trụ thép
	for px in [r.position.x, r.end.x - 5.0]:
		p.rc(px - 1, y0 - 4.0, 7, 44, C_OUTLINE)
		p.rc(px, y0 - 3.0, 5, 42, Color("9aa3ad"))
		p.rc(px, y0 - 3.0, 2, 42, Color("c6ced6"))
		p.rc(px - 2, r.end.y - 2.0, 9, 3, Color("5a606c"))
	# cột ăng-ten đỏ trắng
	for i in 4:
		p.rc(nx0 + 12.0, y0 - 10.0 + i * 3.0, 2, 3, Color("c0392b") if i % 2 == 0 else Color.WHITE)
		p.rc(nx1 - 14.0, y0 - 10.0 + i * 3.0, 2, 3, Color("c0392b") if i % 2 == 0 else Color.WHITE)

func _paint_goal(p: Node2D) -> void:
	var r := GOAL_RECT
	var x0 := r.position.x
	var x1 := r.end.x
	var yb := r.end.y
	var yt := yb - 30.0
	p.rc(x0, yb - 1.0, x1 - x0, 3, Color(0, 0, 0, 0.18))
	for xx in range(int(x0) + 2, int(x1), 4):
		p.rc(xx, yt + 2.0, 1, 27, Color(1, 1, 1, 0.35))
	for yy in range(int(yt) + 2, int(yb) - 2, 4):
		p.rc(x0 + 2.0, yy, x1 - x0 - 4.0, 1, Color(1, 1, 1, 0.35))
	p.rc(x0, yt, 4, 31, Color("f4f6f8"))
	p.rc(x1 - 4.0, yt, 4, 31, Color("f4f6f8"))
	p.rc(x0, yt, x1 - x0, 4, Color("f4f6f8"))
	p.rc(x0, yt + 3.0, x1 - x0, 1, Color("b4bac2"))

func _paint_rack(p: Node2D) -> void:
	var r := RACK_RECT
	var x := r.position.x
	var y := r.end.y
	p.rc(x, y - 1.0, r.size.x, 3, Color(0, 0, 0, 0.18))
	p.rc(x, y - 16.0, 2, 16, Color("5a606c"))
	p.rc(x + r.size.x - 2.0, y - 16.0, 2, 16, Color("5a606c"))
	p.rc(x, y - 4.0, r.size.x, 2, Color("8f9aa6"))
	p.rc(x, y - 10.0, r.size.x, 2, Color("8f9aa6"))
	for i in 3:
		p.draw_circle(Vector2(x + 6.0 + i * 6.0, y - 14.0), 3.0, Color("e86a1f"))
		p.draw_circle(Vector2(x + 6.0 + i * 6.0, y - 7.0), 3.0, Color("f4f6f8") if i % 2 == 0 else Color("ffd23f"))
	p.rc(x + 2, y - 3.0, 3, 3, Color("1a1a2e"))
	p.rc(x + r.size.x - 5.0, y - 3.0, 3, 3, Color("1a1a2e"))

func _paint_cooler(p: Node2D) -> void:
	var r := COOLER_RECT
	var x := r.position.x
	var y := r.end.y
	p.rc(x - 1, y - 1.0, r.size.x + 2.0, 3, Color(0, 0, 0, 0.18))
	p.rc(x, y - 18.0, 12, 18, Color("d8dde2"))
	p.rc(x, y - 18.0, 12, 2, Color("ffffff"))
	p.rc(x + 1, y - 26.0, 10, 9, Color("8fd3f0"))
	p.rc(x + 1, y - 26.0, 10, 2, Color("c8ecf8"))
	p.rc(x + 4, y - 12.0, 4, 2, Color("2f6bd0"))

func _paint_bench(p: Node2D, r: Rect2) -> void:
	p.rc(r.position.x, r.end.y - 1.0, r.size.x, 3, Color(0, 0, 0, 0.18))
	p.rc(r.position.x + 3, r.end.y - 6.0, 3, 6, Color("5a4026"))
	p.rc(r.end.x - 6.0, r.end.y - 6.0, 3, 6, Color("5a4026"))
	p.rc(r.position.x, r.end.y - 9.0, r.size.x, 4, Color("c19660"))
	p.rc(r.position.x, r.end.y - 9.0, r.size.x, 1, Color("d9b07c"))
	p.rc(r.position.x, r.end.y - 5.0, r.size.x, 1, Color("8a6238"))

func _paint_cone(p: Node2D, c: Vector2) -> void:
	p.rc(c.x - 4, c.y - 1.0, 8, 2, Color("2b2f3a"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 3, c.y - 1), Vector2(c.x + 3, c.y - 1), Vector2(c.x, c.y - 9)]), Color("f07a1e"))
	p.rc(c.x - 1, c.y - 5.0, 2, 1, Color.WHITE)

# Vài quả bóng nằm trên sàn (trang trí)
# Vài quả bóng nằm trên sàn (trang trí) dùng chung hàm này
func _paint_ball(p: Node2D, c: Vector2, r: float, kind: String) -> void:
	p.rc(c.x - r, c.y + r - 1.0, r * 2.0, 2, Color(0, 0, 0, 0.22))
	_paint_ball_body(p, c, r, kind)

# Thân quả bóng không kèm bóng đổ (bóng đang bay thì bóng đổ nằm riêng trên sàn)
func _paint_ball_body(p: Node2D, c: Vector2, r: float, kind: String) -> void:
	match kind:
		"basket":
			p.draw_circle(c, r, Color("e86a1f"))
			p.rc(c.x - r, c.y - 0.5, r * 2.0, 1, Color("5a2a0a"))
			p.rc(c.x - 0.5, c.y - r, 1, r * 2.0, Color("5a2a0a"))
		"volley":
			p.draw_circle(c, r, Color("f4f6f8"))
			p.rc(c.x - r, c.y - 1.0, r * 2.0, 1, Color("2f6bd0"))
			p.rc(c.x - r + 1.0, c.y + 1.0, r * 2.0 - 2.0, 1, Color("ffd23f"))
		_:
			p.draw_circle(c, r, Color("f4f6f8"))
			p.rc(c.x - 1.0, c.y - 1.0, 2, 2, Color("1a1a2e"))
			p.rc(c.x - r, c.y - 0.5, 1, 1, Color("1a1a2e"))
			p.rc(c.x + r - 1.0, c.y - 0.5, 1, 1, Color("1a1a2e"))
# Nhân vật dùng đúng hàm draw_person() của game (áo polo trường, animation đi bộ)
func _paint_player(p: Node2D) -> void:
	var u := 0.0
	if _act_t > 0.0 and _act_dur > 0.0:
		u = 1.0 - _act_t / _act_dur
	var dpos := _pos
	if _act_kind == "throw":
		dpos.y -= roundf(sin(PI * u) * 3.0)   # nhảy nhẹ khi ném
	elif _act_kind == "pick" and u < 0.6:
		dpos.y += 1.0   # cúi xuống nhặt
	# đang ngồi thì dùng nhịp bước 0 (không để chân/thân dừng lệch giữa bước đi)
	p.draw_person(dpos, Color.WHITE, Color("1b1b1b"), _face, 0.0 if _seat >= 0 else _anim, true, false, true)
	if _act_kind == "kick":
		_paint_kick_leg(p, u)
	if _held >= 0 and _seat < 0:
		_paint_held_ball(p, dpos)
	p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, C_GOLD)
	_paint_charge_bar(p)

# Biển tên hiện ra vài giây khi mới bước vào
func _paint_banner(p: Node2D) -> void:
	if _banner <= 0.0 or _closing:
		return
	var a := clampf(_banner, 0.0, 1.0)
	var w: float = p.font.get_string_size(HALL_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 16.0
	p.rc(240.0 - w / 2.0 - 1.0, 70, w + 2.0, 15, Color(0.2, 0.2, 0.2, a))
	p.rc(240.0 - w / 2.0, 71, w, 13, Color(0.08, 0.1, 0.18, 0.92 * a))
	p.ctext(HALL_NAME, 240.0 - w / 2.0, 81, w, 8, Color(1.0, 0.82, 0.25, a))

# ======================= VẼ NPC VÀ HỘP THOẠI =======================

func _paint_npc(p: Node2D, i: int) -> void:
	var n: Dictionary = _npcs[i]
	var pos: Vector2 = n.pos
	var face: int = n.face
	var t: float = n.idle_t
	if str(n.id) == "thay_vo":
		_paint_martial_teacher(p, pos, face, t, float(n.calm))
	else:
		_paint_football_teacher(p, pos, face, t)

# Tên và gợi ý phím E của NPC gần nhất, vẽ SAU khi đã sắp y để không bị vật khác đè lên
func _paint_npc_prompt(p: Node2D) -> void:
	if _dlg or _closing or _seat >= 0:
		return
	var i := _npc_near()
	if i < 0:
		return
	var n: Dictionary = _npcs[i]
	var pos: Vector2 = n.pos
	var ty := pos.y - 36.0
	p.ctext(str(n.name), pos.x - 50.0, ty - 8.0, 100, 8, C_GOLD)
	p.ctext("[E] Nói chuyện", pos.x - 50.0, ty + 1.0, 100, 8, Color.WHITE)

# Cửa sổ nội suy mượt: 0 -> 1 trong `rise` giây, giữ `hold` giây, rồi 1 -> 0 trong `fall` giây, bắt đầu tại t0
func _window(t: float, t0: float, rise: float, hold: float, fall: float) -> float:
	var u := t - t0
	if u <= 0.0 or u >= rise + hold + fall:
		return 0.0
	if u < rise:
		return smoothstep(0.0, 1.0, u / rise)
	if u < rise + hold:
		return 1.0
	return smoothstep(0.0, 1.0, 1.0 - (u - rise - hold) / fall)

# Thầy dạy võ: tóc bạc, võ phục trắng, đai đen, chân trần. Idle (chu kỳ 9 giây, chuyển động mượt):
# thở nhẹ -> hạ tấn và đứng tấn -> 4 đòn đấm luân phiên hai tay -> thu thế -> cúi chào ôm quyền. `calm` = 0..1 tắt dần khi đang thoại.
func _paint_martial_teacher(p: Node2D, pos: Vector2, face: int, t: float, calm: float) -> void:
	var ol := C_OUTLINE
	var white := Color("f1f0f0")
	var shade := Color("c5c3c3")
	var skin := Color("fcc08e")
	var skin_d := Color("e8955a")
	var hair := Color("bdbdc2")
	var hair_hi := Color("dcdcdf")
	var belt := Color("141418")
	var w := 1.0 - calm
	var cyc := fmod(t, 9.0)
	var stance_k := _window(cyc, 0.3, 0.45, 2.9, 0.45) * w
	var bow_k := _window(cyc, 5.2, 0.5, 1.0, 0.5) * w
	var punch_e := 0.0
	var punch_side := 1.0
	for k in 4:
		var e := _window(cyc, 1.0 + 0.7 * k, 0.12, 0.1, 0.2)
		if e > punch_e:
			punch_e = e
			punch_side = 1.0 if k % 2 == 0 else -1.0
	punch_e *= w
	var crouch := roundf(stance_k)
	var bow := roundf(bow_k)
	var bob := 0.0
	if stance_k < 0.05 and bow_k < 0.05 and int(t * 1.6) % 2 == 1:
		bob = 1.0
	var by := pos.y - bob + crouch + bow
	var hy := by + bow   # đầu cúi thêm một nhịp khi chào
	var salute := bow_k > 0.3
	var side := face >= 2
	var dirx := -1.0 if face == 2 else 1.0
	p.shadow(pos + Vector2(0, 1), 8.0)
	# chân (quần võ trắng, có nếp) và bàn chân trần; đứng tấn thì hai chân dang dần ra
	var spread := roundf(stance_k * 2.0)
	var lx := pos.x - 5.0 - spread
	var rx := pos.x + 1.0 + spread
	p.rc(lx, pos.y - 7, 4, 7, ol)
	p.rc(rx, pos.y - 7, 4, 7, ol)
	p.rc(lx + 1, pos.y - 6, 2, 4, white)
	p.rc(rx + 1, pos.y - 6, 2, 4, white)
	p.rc(lx + 1, pos.y - 6, 1, 4, shade)
	p.rc(rx + 2, pos.y - 6, 1, 4, shade)
	p.rc(lx + 1, pos.y - 2, 3, 2, skin)
	p.rc(rx, pos.y - 2, 3, 2, skin)
	p.rc(lx + 1, pos.y - 1, 3, 1, skin_d)
	p.rc(rx, pos.y - 1, 3, 1, skin_d)
	# thân, tay áo
	p.rc(pos.x - 6, by - 14, 12, 10, ol)
	p.rc(pos.x - 8, by - 13, 2, 7, ol)
	p.rc(pos.x + 6, by - 13, 2, 7, ol)
	p.rc(pos.x - 5, by - 13, 10, 8, white)
	p.rc(pos.x - 5, by - 13, 2, 8, shade)
	p.rc(pos.x - 7, by - 12, 2, 6, white)
	p.rc(pos.x + 5, by - 12, 2, 6, white)
	p.rc(pos.x - 7, by - 12, 1, 6, shade)
	if side:
		var sx := pos.x - 2.0
		p.rc(sx - 1, by - 12, 4, 6, ol)
		p.rc(sx, by - 11, 2, 4, white)
		p.rc(sx, by - 7, 2, 2, skin)
	elif not salute:
		p.rc(pos.x - 7, by - 7, 2, 2, skin)
		p.rc(pos.x + 5, by - 7, 2, 2, skin)
	# cổ áo võ phục bắt chéo
	if face != 1:
		p.rc(pos.x - 1, by - 13, 2, 1, skin)
		p.rc(pos.x - 2, by - 13, 1, 1, shade)
		p.rc(pos.x - 1, by - 12, 1, 1, shade)
		p.rc(pos.x, by - 11, 1, 1, shade)
		p.rc(pos.x + 1, by - 10, 1, 1, shade)
		p.rc(pos.x + 1, by - 13, 1, 1, shade)
		p.rc(pos.x, by - 12, 1, 1, shade)
		p.rc(pos.x - 1, by - 11, 1, 1, shade)
		p.rc(pos.x - 2, by - 10, 1, 1, shade)
	# ôm quyền: hai tay chắp trước ngực
	if salute:
		p.rc(pos.x - 6, by - 11, 12, 4, ol)
		p.rc(pos.x - 5, by - 10, 10, 2, white)
		p.rc(pos.x - 2, by - 10, 4, 3, skin)
		p.rc(pos.x - 2, by - 8, 4, 1, skin_d)
	# đai đen
	p.rc(pos.x - 5, by - 7, 10, 2, belt)
	if face == 0:
		p.rc(pos.x - 1, by - 7, 2, 2, Color("2a2a30"))
		p.rc(pos.x - 2, by - 5, 1, 3, belt)
		p.rc(pos.x + 1, by - 5, 1, 3, belt)
	# đòn đấm: tay duỗi dần ra phía trước rồi thu về (độ dài theo punch_e)
	if punch_e > 0.05:
		var reach := roundf(punch_e * 7.0)
		if side:
			var py := by - 10.0
			var ax := pos.x + dirx * reach
			p.rc(minf(pos.x, ax) - 1.0, py - 1.0, reach + 2.0, 4, ol)
			p.rc(minf(pos.x, ax), py, reach, 2, white)
			p.rc(ax + (dirx * 2.0 - 1.0), py - 1.0, 3, 3, skin)
		else:
			var fx := pos.x + 3.0 * punch_side
			var grow := roundf(punch_e)
			p.rc(fx - 2.0, by - 13.0, 5, 6.0 + grow, ol)
			p.rc(fx - 1.0, by - 12.0, 3, 3, white)
			p.rc(fx - 1.0, by - 9.0, 3, 3.0 + grow, skin)
	# đầu: da sáng, tóc bạc vuốt gọn, lông mày xám, nụ cười hiền
	p.rc(pos.x - 5, hy - 22, 10, 9, ol)
	p.rc(pos.x - 4, hy - 21, 8, 8, skin)
	p.rc(pos.x - 3, hy - 23, 6, 1, ol)
	p.rc(pos.x - 3, hy - 22, 6, 1, hair_hi)
	if face == 1:
		p.rc(pos.x - 4, hy - 21, 8, 8, hair)
		p.rc(pos.x - 3, hy - 21, 3, 1, hair_hi)
		p.rc(pos.x - 2, hy - 15, 4, 2, hair.darkened(0.2))
	else:
		p.rc(pos.x - 4, hy - 21, 8, 3, hair)
		p.rc(pos.x - 3, hy - 21, 4, 1, hair_hi)
		if face == 0:
			p.rc(pos.x - 4, hy - 18, 1, 3, hair)
			p.rc(pos.x + 3, hy - 18, 1, 3, hair)
			p.rc(pos.x - 3, hy - 19, 2, 1, Color("4a4a50"))
			p.rc(pos.x + 1, hy - 19, 2, 1, Color("4a4a50"))
			p.rc(pos.x - 3, hy - 17, 1, 2, ol)
			p.rc(pos.x + 2, hy - 17, 1, 2, ol)
			p.rc(pos.x - 3, hy - 15, 1, 1, Color("f4a07a"))
			p.rc(pos.x + 2, hy - 15, 1, 1, Color("f4a07a"))
			p.rc(pos.x - 1, hy - 14, 2, 1, Color("a8512a"))
		else:
			var ex := pos.x - 3.0 if face == 2 else pos.x + 2.0
			var mx := pos.x - 3.0 if face == 2 else pos.x + 1.0
			var back_x := pos.x + 2.0 if face == 2 else pos.x - 4.0
			p.rc(back_x, hy - 21, 2, 7, hair)
			p.rc(ex, hy - 19, 2, 1, Color("4a4a50"))
			p.rc(ex, hy - 17, 1, 2, ol)
			p.rc(mx, hy - 14, 2, 1, Color("a8512a"))
# Thầy dạy bóng đá: áo khoác thể thao xanh lục sọc trắng, quần dài thể thao, giày trắng, còi đeo cổ.
# Idle: thở nhẹ và tâng bóng theo vòng 0,9 giây: bóng bay lên theo parabol rồi rơi xuống đúng mũi giày phải;
# chân phải nhấc lên và duỗi mũi giày chạm bóng ở đáy vòng. Bóng đổ nằm riêng trên sàn, nhỏ dần khi bóng lên cao.
func _paint_football_teacher(p: Node2D, pos: Vector2, face: int, t: float) -> void:
	var ol := C_OUTLINE
	var green := Color("1f7a5a")
	var green_d := Color("165a42")
	var green_hi := Color("2f9b74")
	var stripe := Color("f2ede0")
	var under := Color("efe8d8")
	var pants := Color("1a6a4e")
	var skin := Color("d9a066")
	var skin_d := Color("b97a45")
	var hair := Color("2a1f1a")
	var hair_hi := Color("4a382c")
	var shoe := Color("f4f1ea")
	var sole := Color("b8b4aa")
	var u := fmod(t, 0.9) / 0.9
	var h := 4.0 * u * (1.0 - u) * 13.0                       # độ cao quả bóng so với mũi giày (0 -> 13 px)
	var ball := Vector2(pos.x + 8.0 + roundf(sin(u * TAU)), pos.y - 4.0 - h)
	var lift := h < 6.0                                        # chân phải nhấc lên khi bóng sắp rơi xuống
	var touch := h < 3.0                                       # mũi giày duỗi ra chạm bóng
	var bob := 1.0 if int(t * 1.6) % 2 == 1 else 0.0
	var by := pos.y - bob
	p.shadow(pos + Vector2(0, 1), 8.0)
	# chân: quần thể thao dài có sọc trắng bên hông, giày trắng
	var lx := pos.x - 5.0
	var rx := pos.x + 1.0
	p.rc(lx, pos.y - 7, 4, 7, ol)
	p.rc(rx, pos.y - 7, 4, 7, ol)
	p.rc(lx + 1, pos.y - 6, 2, 4, pants)
	p.rc(rx + 1, pos.y - 6, 2, 4, pants)
	if face != 2 and face != 3:
		p.rc(lx + 1, pos.y - 6, 1, 4, stripe)
		p.rc(rx + 2, pos.y - 6, 1, 4, stripe)
	p.rc(lx + 1, pos.y - 2, 3, 2, shoe)
	p.rc(lx + 1, pos.y - 1, 3, 1, sole)
	var ry := pos.y - 3.0 if lift else pos.y - 2.0
	p.rc(rx, ry, 3, 2, shoe)
	p.rc(rx, ry + 1.0, 3, 1, sole)
	if touch:
		p.rc(rx + 3.0, ry, 2, 2, shoe)    # mũi giày duỗi tới sát quả bóng
		p.rc(rx + 3.0, ry + 1.0, 2, 1, sole)
	# thân: áo khoác xanh, sọc trắng vai và tay, cổ áo thun trắng, khóa kéo
	p.rc(pos.x - 6, by - 14, 12, 10, ol)
	p.rc(pos.x - 8, by - 13, 2, 7, ol)
	p.rc(pos.x + 6, by - 13, 2, 7, ol)
	p.rc(pos.x - 5, by - 13, 10, 8, green)
	p.rc(pos.x - 5, by - 13, 10, 2, green_hi)
	p.rc(pos.x - 5, by - 6, 10, 1, green_d)
	p.rc(pos.x - 7, by - 12, 2, 6, green)
	p.rc(pos.x + 5, by - 12, 2, 6, green)
	p.rc(pos.x - 7, by - 12, 1, 6, stripe)
	p.rc(pos.x + 6, by - 12, 1, 6, stripe)
	p.rc(pos.x - 7, by - 8, 2, 1, green_d)
	p.rc(pos.x + 5, by - 8, 2, 1, green_d)
	if face >= 2:
		var sx := pos.x - 2.0
		p.rc(sx - 1, by - 12, 4, 6, ol)
		p.rc(sx, by - 11, 2, 4, green)
		p.rc(sx, by - 11, 1, 4, stripe)
		p.rc(sx, by - 7, 2, 2, skin)
	else:
		p.rc(pos.x - 7, by - 7, 2, 2, skin)
		p.rc(pos.x + 5, by - 7, 2, 2, skin)
		p.rc(pos.x - 5, by - 13, 1, 3, stripe)
		p.rc(pos.x + 4, by - 13, 1, 3, stripe)
	if face == 0:
		p.rc(pos.x - 2, by - 13, 4, 3, under)
		p.rc(pos.x - 3, by - 13, 1, 3, green_d)
		p.rc(pos.x + 2, by - 13, 1, 3, green_d)
		p.rc(pos.x, by - 10, 1, 5, green_d)
		p.rc(pos.x - 2, by - 13, 1, 4, Color("f2c230"))
		p.rc(pos.x + 1, by - 13, 1, 4, Color("f2c230"))
		p.rc(pos.x - 1, by - 9, 2, 2, Color("d4dbe2"))
		p.rc(pos.x - 1, by - 8, 2, 1, Color("8f9aa6"))
	elif face == 1:
		p.rc(pos.x - 2, by - 13, 4, 1, under)
	# đầu: da rám nắng, tóc đen rối, cười tươi
	p.rc(pos.x - 5, by - 22, 10, 9, ol)
	p.rc(pos.x - 4, by - 21, 8, 8, skin)
	p.rc(pos.x - 4, by - 22, 2, 1, hair)
	p.rc(pos.x + 1, by - 22, 3, 1, hair)
	if face == 1:
		p.rc(pos.x - 4, by - 21, 8, 8, hair)
		p.rc(pos.x - 3, by - 21, 3, 1, hair_hi)
	else:
		p.rc(pos.x - 4, by - 21, 8, 3, hair)
		p.rc(pos.x - 2, by - 21, 3, 1, hair_hi)
		if face == 0:
			p.rc(pos.x - 4, by - 18, 1, 2, hair)
			p.rc(pos.x + 3, by - 18, 1, 2, hair)
			p.rc(pos.x - 3, by - 19, 2, 1, ol)
			p.rc(pos.x + 1, by - 19, 2, 1, ol)
			p.rc(pos.x - 3, by - 17, 1, 2, ol)
			p.rc(pos.x + 2, by - 17, 1, 2, ol)
			p.rc(pos.x - 3, by - 15, 1, 1, skin_d)
			p.rc(pos.x + 2, by - 15, 1, 1, skin_d)
			p.rc(pos.x - 1, by - 14, 3, 1, Color("8a3a22"))
			p.rc(pos.x - 2, by - 15, 1, 1, Color("8a3a22"))
			p.rc(pos.x + 2, by - 15, 1, 1, Color("8a3a22"))
		else:
			var ex := pos.x - 3.0 if face == 2 else pos.x + 2.0
			var mx := pos.x - 3.0 if face == 2 else pos.x + 1.0
			var back_x := pos.x + 2.0 if face == 2 else pos.x - 4.0
			p.rc(back_x, by - 21, 2, 7, hair)
			p.rc(ex, by - 19, 2, 1, ol)
			p.rc(ex, by - 17, 1, 2, ol)
			p.rc(mx, by - 14, 2, 1, Color("8a3a22"))
	# bóng đổ trên sàn (nhỏ dần khi bóng lên cao) rồi quả bóng, vẽ sau sprite để thấy rõ chỗ chạm mũi giày
	var sw := maxf(1.0, 3.0 - h / 5.0)
	p.rc(ball.x - sw, pos.y, sw * 2.0, 1, Color(0, 0, 0, 0.25))
	_paint_ball_body(p, ball, 3.0, "foot")

# Hộp thoại: khung tối viền vàng, tên NPC, chữ gõ dần, gợi ý phím E
func _paint_dialogue(p: Node2D) -> void:
	var n: Dictionary = _npcs[_dlg_i]
	var bx := 16.0
	var by := 190.0
	var bw := VIEW.x - 32.0
	var bh := 58.0
	p.rc(bx - 1, by - 1, bw + 2, bh + 2, Color("333333"))
	p.rc(bx, by, bw, bh, Color(0.08, 0.1, 0.18, 0.95))
	p.draw_rect(Rect2(bx + 1, by + 1, bw - 2, bh - 2), C_GOLD, false, 1.0)
	# thẻ tên
	var nm := str(n.name)
	var nw: float = p.font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16.0
	p.rc(bx + 7, by - 10, nw + 2, 14, Color("333333"))
	p.rc(bx + 8, by - 9, nw, 12, Color(0.12, 0.16, 0.3, 1.0))
	p.draw_string(p.font, Vector2(bx + 16, by), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_GOLD)
	# nội dung trang hiện tại (hiện dần từng ký tự); dòng cách nhau 12 px để dấu tiếng Việt không dính dòng trên
	var left := int(_dlg_shown)
	for i in _dlg_lines.size():
		if left <= 0:
			break
		var line: String = _dlg_lines[i]
		var shown := line.substr(0, mini(left, line.length()))
		left -= line.length()
		p.draw_string(p.font, Vector2(bx + 10, by + 17.0 + i * 12.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	# gợi ý phím (nằm dưới dòng chữ cuối: tối đa 3 dòng ở y = by + 41, gợi ý ở y = by + 53)
	var done := int(_dlg_shown) >= _dialogue_chars()
	var lines: Array = n.lines
	var more := _dlg_page + 1 < _dlg_pages.size() or _dlg_line + 1 < lines.size()
	var hint := "[E] Bỏ qua"
	if done:
		hint = "[E] Tiếp tục" if more else "[E] Đóng"
	if not done or int(_clock * 2.0) % 2 == 0:
		p.draw_string(p.font, Vector2(bx, by + bh - 5.0), hint, HORIZONTAL_ALIGNMENT_RIGHT, bw - 8.0, 8, Color("ffe28a"))

# ======================= VẼ TÒA NHÀ NGOÀI TRỜI =======================

# Vẽ sau khi game đã vẽ cây/người. Để nhân vật và cây đứng TRƯỚC tòa nhà không bị mặt tiền đè lên,
# ta vẽ lại chúng (cùng hàm vẽ của game) ngay sau mặt tiền.
func draw_front_layer() -> void:
	if not game.view.intersects(RECT.grow(60.0)):
		return
	_paint_facade()
	_repaint_front_items()
	if not game.is_busy() and _near_entrance():
		_paint_tag(ENTER_TEXT, C_GOLD)

# Khung chỉ dẫn phía trên đầu người chơi (cùng kiểu với b42_lab.gd)
func _paint_tag(text: String, col: Color) -> void:
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(text, px - w / 2.0, py, w, 8, col)

func _repaint_front_items() -> void:
	var area := Rect2(RECT.position.x - 40.0, RECT.end.y - 4.0, RECT.size.x + 80.0, 100.0)
	var items: Array = []
	for t in game.trees:
		if area.has_point(Vector2(t[0], t[1])):
			items.append([float(t[1]), 0, t])
	for l in game.lamps:
		if area.has_point(l):
			items.append([l.y, 1, l])
	for b in game.benches:
		var bench_pos: Vector2 = game.get_bench_position(b)
		if area.has_point(bench_pos):
			items.append([bench_pos.y, 2, b])
	for o in game.npcs:
		if not o.has("role") and area.has_point(o.pos):
			items.append([o.pos.y, 3, o])
	if area.has_point(game.player):
		items.append([game.player.y, 4, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				game.draw_tree(it[2])
			1:
				game.draw_lamp(it[2])
			2:
				game.draw_bench(it[2])
			3:
				var o: Dictionary = it[2]
				game.draw_person(o.pos, o.shirt, o.hair, o.face, o.anim, o.uni, o.long, o.pack)
				if o.say_t > 0.0:
					game.draw_speech(o)
			4:
				game.draw_person(game.player, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
				game.ctext("Bạn", game.player.x - 15, game.player.y - 28, 30, 8, C_GOLD)

# Mặt tiền: tường kem vàng, mái tôn xanh xám dốc, biển chữ lớn, ô thoáng hai bên, cửa đôi ở giữa.
# Viền đen (FACADE_LINE) chạy theo ĐÚNG đường bao từng chi tiết (mái, trụ góc, chân tường, ô thoáng, cửa, bậc thềm, cọc lưới),
# không còn một khung chữ nhật bao cả tòa nhà. Mọi hình đều vẽ bằng ô nguyên pixel (không draw_line/đa giác chéo) nên các mép
# khớp nhau, không hở, không lệch nửa pixel. Phần phủ kín toàn bộ ô BUILDINGS để che hẳn hình giữ chỗ của game gốc ở bên dưới.
func _paint_facade() -> void:
	var r := RECT
	var x := int(r.position.x)
	var y := int(r.position.y)
	var w := int(r.size.x)
	var end_y := int(r.end.y)
	var cx := int(r.get_center().x)
	# tường
	game.rc(x, y + 18, w, end_y - y - 18, WALL_COL)
	for k in 5:   # vệt ố loang trên tường (tọa độ nguyên)
		game.rc(x + 14 + int(game.hs(k, 5) * 1.5), y + 40 + game.hs(k, 9) % 18, 2, 8 + game.hs(k, 3) % 14, Color(0.45, 0.35, 0.1, 0.07))
	# trụ góc hai bên (sáng bên trái, tối bên phải)
	game.rc(x - 3, y + 6, 6, end_y - y - 6, WALL_COL.lightened(0.1))
	game.rc(x + w - 3, y + 6, 6, end_y - y - 6, WALL_COL.darkened(0.12))
	# chân tường bê tông xám chạy suốt giữa hai trụ
	game.rc(x - 3, end_y - 14, w + 6, 14, Color("a59f92"))
	game.rc(x - 3, end_y - 14, w + 6, 2, Color("8a8478"))
	for k in 9:
		game.rc(x + 6 + game.hs(k, 17) % (w - 14), end_y - 12 + game.hs(k, 4) % 8, 4, 2, Color("8a8478"))
	# viền trụ góc và đường chân tường sát mặt đất
	_pilaster_edges(x - 3, y + 6, end_y)
	_pilaster_edges(x + w - 3, y + 6, end_y)
	game.rc(x - 4, end_y, w + 8, 1, FACADE_LINE)
	# mái tôn dốc (có viền đen theo đường mái) và bóng mái đổ xuống tường
	_paint_roof_slab(x, y, w)
	# biển chữ lớn trên tường
	game.ctext("TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN", x, y + 45, w, 8, Color("1d3f8c"))
	game.ctext("NHÀ TẬP LUYỆN", x, y + 59, w, 11, Color("9b2a1e"))
	game.ctext("THỂ DỤC - THỂ THAO", x, y + 73, w, 11, Color("9b2a1e"))
	# ô thoáng (khung đỏ nâu, nan ngang xám) hai bên cửa, đứng trên chân tường
	for px in [x + 14, x + w - 44]:
		game.rc(px - 1, y + 77, 32, 22, FACADE_LINE)
		game.rc(px, y + 78, 30, 20, Color("b04a37"))
		game.rc(px + 2, y + 80, 26, 16, Color("8f959c"))
		for k in 4:
			game.rc(px + 2, y + 82 + k * 4, 26, 1, Color("6a7078"))
		game.rc(px + 2, y + 80, 26, 2, Color("b4bac2"))
	# cọc lưới bóng chuyền dựa chân tường (như trong ảnh thực tế)
	game.rc(x + w - 11, end_y - 39, 5, 39, FACADE_LINE)
	game.rc(x + w - 10, end_y - 38, 3, 38, Color("9aa3ad"))
	game.rc(x + w - 10, end_y - 38, 1, 38, Color("c6ced6"))
	# bụi cây thấp hai bên lối vào, kết thúc đúng mép sân lát gạch (cx ± 44)
	game.hedge(x - 2, end_y, cx - 44 - (x - 2))
	game.hedge(cx + 44, end_y, x + w + 2 - (cx + 44))
	# cửa đôi ở giữa: khung xanh có biển "LỐI VÀO" liền phía trên, hai cánh kính
	game.rc(cx - 18, end_y - 33, 36, 33, FACADE_LINE)
	game.rc(cx - 17, end_y - 32, 34, 32, Color("2e4a7d"))
	game.rc(cx - 17, end_y - 32, 34, 1, Color("5a7bb0"))
	game.ctext("LỐI VÀO", cx - 17, end_y - 24, 34, 7, Color.WHITE)
	game.rc(cx - 17, end_y - 22, 34, 1, Color("1f3560"))
	game.rc(cx - 15, end_y - 21, 14, 21, Color("9fd3f0"))
	game.rc(cx + 1, end_y - 21, 14, 21, Color("9fd3f0"))
	game.rc(cx - 15, end_y - 21, 14, 3, Color("c8e8f7"))
	game.rc(cx + 1, end_y - 21, 14, 3, Color("c8e8f7"))
	game.rc(cx - 1, end_y - 21, 2, 21, Color("1f3560"))
	game.rc(cx - 4, end_y - 12, 2, 5, Color("e8d28a"))
	game.rc(cx + 2, end_y - 12, 2, 5, Color("e8d28a"))
	# bậc thềm (có viền)
	game.rc(cx - 23, end_y + 3, 46, 4, FACADE_LINE)
	game.rc(cx - 22, end_y + 3, 44, 3, Color("b3ad9e"))
	game.rc(cx - 20, end_y, 40, 3, FACADE_LINE)
	game.rc(cx - 19, end_y, 38, 3, Color("d2ccbe"))

# Viền hai bên của một trụ góc rộng 6 px (cột viền ngoài và cột viền trong) và hàng viền chân trụ
func _pilaster_edges(px: int, top: int, bottom: int) -> void:
	game.rc(px - 1, top, 1, bottom - top + 1, FACADE_LINE)
	game.rc(px + 6, top, 1, bottom - top + 1, FACADE_LINE)
	game.rc(px - 1, bottom, 8, 1, FACADE_LINE)

# Cao độ mép trên của mái ở cột thứ i (dốc 16 px trên toàn bề rộng, trái cao phải thấp)
func _roof_top(y: int, i: int, cols: int) -> int:
	return y - 18 + int(roundf(i * 16.0 / cols))

# Tấm mái: chia thành các đoạn cùng độ cao mép trên để vẽ ít lệnh nhất, mỗi đoạn là một dải hình chữ nhật nên không hở
func _paint_roof_slab(x: int, y: int, w: int) -> void:
	var x0 := x - 5   # mái nhô ra 5 px mỗi bên
	var cols := w + 10
	var run_start := 0
	var run_top := _roof_top(y, 0, cols)
	for i in range(1, cols + 1):
		var t := _roof_top(y, i, cols) if i < cols else run_top - 999
		if t != run_top:
			_roof_run(x0 + run_start, i - run_start, run_top, x, w)
			run_start = i
			run_top = t
	# hai đầu mái
	game.rc(x0 - 1, _roof_top(y, 0, cols) - 1, 1, 38, FACADE_LINE)
	game.rc(x0 + cols, _roof_top(y, cols - 1, cols) - 1, 1, 38, FACADE_LINE)

# Một đoạn mái rộng n px, mép trên ở hàng top: viền đen, hai hàng sáng, thân tôn có gân, diềm xanh, viền đen dưới, bóng đổ lên tường
func _roof_run(xa: int, n: int, top: int, wall_x: int, wall_w: int) -> void:
	var bot := top + 36
	game.rc(xa, top - 1, n, 1, FACADE_LINE)
	game.rc(xa, top, n, 1, Color("9bb0cb"))
	game.rc(xa, top + 1, n, 1, Color("7d95b5"))
	game.rc(xa, top + 2, n, bot - top - 5, ROOF_COL)
	for xx in range(xa, xa + n):
		if (xx - (wall_x - 5)) % 5 == 2:
			game.rc(xx, top + 2, 1, bot - top - 5, Color(0.1, 0.18, 0.3, 0.32))
	game.rc(xa, bot - 3, n, 3, Color("2e4a7d"))
	game.rc(xa, bot, n, 1, Color("1f3560"))
	game.rc(xa, bot + 1, n, 1, FACADE_LINE)
	var sa := maxi(xa, wall_x)
	var sb := mini(xa + n, wall_x + wall_w)
	if sb > sa:
		game.rc(sa, bot + 2, sb - sa, 6, Color(0, 0, 0, 0.16))
