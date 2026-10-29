extends "res://scripts/features/feature.gd"
# CHỨC NĂNG CÂU CÁ Ở HỒ SINH VIÊN
#
# Cách chơi:
#   1. Đi tới sát bờ hồ (góc đông nam bản đồ, dưới Nhà Điều hành bên phải), bấm E hoặc Space.
#   2. Thanh "Sức quăng" chạy qua lại: bấm E để quăng cần. Quăng càng xa càng dễ ra cá to, cá hiếm.
#   3. Chờ phao. Khi phao chìm và có dấu "!" thì bấm E ngay để móc cá (sớm hoặc trễ quá cá sẽ chạy mất).
#   4. Giữ E / Space để nâng vùng xanh lên, thả ra thì vùng xanh rơi xuống. Giữ con cá trong vùng xanh
#      cho thanh tiến độ đầy là bắt được. Cá ra khỏi vùng quá lâu thì cá sổng.
#   5. Q hoặc Esc: thu cần / hủy. B: mở Sổ cá (khi không đang câu).
#
# Chỗ cần sửa:
#   - ITEMS (bên dưới): danh sách cá và đồ vớt được (tên, độ hiếm, kích cỡ, độ khó, điểm).
#   - Hồ (vị trí, hình dạng) là LAKE trong scripts/data/game_data.gd; phần vẽ hồ là draw_lake() trong draw/scenery.gd.
#   - Âm thanh (tùy chọn, bỏ file vào assets/audio/): rod, cast, splash, bite, reel, catch, fail.

enum Phase { IDLE, AIM, FLY, WAIT, BITE, REEL, RESULT }

const NEAR_MARGIN := 28.0   # cách bờ hồ tối đa bao nhiêu px thì được bấm E
const BAR_LEN := 130.0      # chiều dài thanh trong trò kéo cá
const BITE_WINDOW := 1.15   # số giây để bấm E khi cá cắn câu
const RESULT_TIME := 3.2    # bảng kết quả tự đóng sau bấy nhiêu giây
const FLY_TIME := 0.5       # thời gian dây câu bay ra
const ROD_COL := Color(0.54, 0.35, 0.2)

# kind: 0 = cá, 1 = đồ vớt được (rác vui)
# w: độ phổ biến. far: hệ số nhân độ phổ biến khi quăng xa (>1: quăng xa dễ ra hơn, <1: hay ra ở gần bờ)
# min/max: cỡ cá (cm). spd: độ khó (cá di chuyển nhanh/khó giữ, 0.3 dễ - 1.6 rất khó). pts: điểm.
var ITEMS: Array = [
	{"name": "Cá rô phi", "kind": 0, "icon": "fish", "w": 30.0, "far": 0.6, "min": 15.0, "max": 32.0, "spd": 0.5, "pts": 10, "col": Color("8fa6a8"), "note": ""},
	{"name": "Cá trê", "kind": 0, "icon": "fish", "w": 22.0, "far": 0.8, "min": 25.0, "max": 45.0, "spd": 0.7, "pts": 14, "col": Color("5b5b66"), "note": ""},
	{"name": "Cá chép", "kind": 0, "icon": "fish", "w": 18.0, "far": 1.3, "min": 30.0, "max": 60.0, "spd": 0.9, "pts": 20, "col": Color("c9a15a"), "note": ""},
	{"name": "Cá diêu hồng", "kind": 0, "icon": "fish", "w": 10.0, "far": 1.5, "min": 25.0, "max": 50.0, "spd": 1.0, "pts": 28, "col": Color("ee7f6a"), "note": ""},
	{"name": "Cá lóc", "kind": 0, "icon": "fish", "w": 9.0, "far": 1.7, "min": 35.0, "max": 70.0, "spd": 1.2, "pts": 35, "col": Color("5d6b40"), "note": ""},
	{"name": "Cá koi vàng", "kind": 0, "icon": "koi", "w": 2.5, "far": 5.0, "min": 40.0, "max": 80.0, "spd": 1.6, "pts": 100, "col": Color("ffb347"), "note": ""},
	{"name": "Đôi dép tổ ong", "kind": 1, "icon": "sandal", "w": 7.0, "far": 0.3, "min": 0.0, "max": 0.0, "spd": 0.3, "pts": 1, "col": Color("6bbf59"), "note": "Ai bỏ quên đôi dép ở hồ vậy?"},
	{"name": "Lon nước ngọt", "kind": 1, "icon": "can", "w": 6.0, "far": 0.3, "min": 0.0, "max": 0.0, "spd": 0.3, "pts": 1, "col": Color("9fb3c8"), "note": "Nhớ bỏ rác đúng thùng nhé!"},
	{"name": "Bài kiểm tra 4 điểm", "kind": 1, "icon": "paper", "w": 3.0, "far": 0.5, "min": 0.0, "max": 0.0, "spd": 0.3, "pts": 0, "col": Color("f4f4f4"), "note": "Ai vứt bài kiểm tra này vậy?"},
	{"name": "Thẻ sinh viên cũ", "kind": 1, "icon": "card", "w": 3.0, "far": 0.5, "min": 0.0, "max": 0.0, "spd": 0.3, "pts": 2, "col": Color("3f6fd0"), "note": "Nhớ trả lại Phòng Công tác Sinh viên."},
]

var state: Phase = Phase.IDLE
var near := false           # đang đứng gần bờ hồ (hiện gợi ý bấm E)
var font: Font
var ui: Control             # lớp giao diện trên màn hình (vẽ bằng _draw_ui)

# quăng cần
var power := 0.0
var power_t := 0.0
var rod_sign := 1.0         # -1: cần chếch sang trái, 1: sang phải
var fly_t := 0.0
var cast_from := Vector2.ZERO
var cast_to := Vector2.ZERO # chỗ phao rơi
var shore_pt := Vector2.ZERO # điểm mép nước gần người nhất (phao được kéo về đây khi kéo cá)

# chờ cá, cá cắn
var wait_t := 0.0
var bite_delay := 3.0
var bite_t := 0.0
var nibble_t := 1.0
var dip_t := 0.0

# cá đang cắn câu
var item: Dictionary = {}
var item_q := 0.0           # 0..1: cá nhỏ -> to
var item_size := 0.0

# trò kéo cá
var zone_y := 0.0
var zone_v := 0.0
var zone_h := 40.0
var fish_y := 0.0
var fish_target := 0.0
var fish_timer := 0.0
var progress := 0.35

# kết quả
var result_ok := false
var result_t := 0.0
var result_title := ""
var result_line := ""
var result_extra := ""

# thống kê (chỉ lưu trong lúc chơi)
var counts: Dictionary = {}   # tên -> số lần câu được
var best: Dictionary = {}     # tên cá -> cỡ lớn nhất (cm)
var caught_total := 0
var score := 0
var show_bag := false

var splashes: Array = []

func _ready() -> void:
	font = game.font
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	ui = Control.new()
	ui.size = Vector2(480, 270)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.draw.connect(_draw_ui)

# ======================= BẮT ĐẦU / KẾT THÚC =======================

func begin() -> void:
	super()
	state = Phase.AIM
	power = 0.0
	power_t = 0.0
	show_bag = false
	_face_lake()
	game.audio.play_sfx("rod")

func finish() -> void:
	super()
	state = Phase.IDLE

# ======================= NHẬP LIỆU =======================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var code := k.physical_keycode
	var act := code == KEY_E or code == KEY_SPACE
	if not active:
		if code == KEY_B:
			show_bag = not show_bag
		elif act and _near_shore() and not show_bag:
			begin()
			get_viewport().set_input_as_handled()
		return
	if code == KEY_Q or code == KEY_ESCAPE:
		finish()
		get_viewport().set_input_as_handled()
	elif act:
		_on_action()
		get_viewport().set_input_as_handled()

func _on_action() -> void:
	match state:
		Phase.AIM:
			_throw()
		Phase.WAIT:
			_fail("Kéo sớm quá, cá chưa cắn!")
		Phase.BITE:
			_start_reel()
		Phase.RESULT:
			if result_t > 0.4:
				finish()

# ======================= CẬP NHẬT MỖI KHUNG HÌNH =======================

func _process(delta: float) -> void:
	near = (not active) and _near_shore()
	_update_splashes(delta)
	match state:
		Phase.AIM:
			power_t += delta
			power = (1.0 - cos(power_t * 3.4)) * 0.5
		Phase.FLY:
			fly_t += delta / FLY_TIME
			if fly_t >= 1.0:
				_land()
		Phase.WAIT:
			wait_t += delta
			dip_t = maxf(0.0, dip_t - delta)
			nibble_t -= delta
			if nibble_t <= 0.0:
				dip_t = 0.3
				nibble_t = randf_range(0.7, 1.8)
			if wait_t >= bite_delay:
				_bite()
		Phase.BITE:
			bite_t += delta
			if bite_t >= BITE_WINDOW:
				_fail("Chậm quá, cá chạy mất rồi!")
		Phase.REEL:
			_update_reel(delta)
		Phase.RESULT:
			result_t += delta
			if result_t >= RESULT_TIME:
				finish()
	ui.queue_redraw()

func _update_splashes(delta: float) -> void:
	for sp in splashes:
		sp["t"] = float(sp["t"]) + delta
	splashes = splashes.filter(func(sp): return float(sp["t"]) < 0.7)

func _add_splash(p: Vector2, big: float) -> void:
	splashes.append({"pos": p, "t": 0.0, "big": big})

# ======================= CÁC BƯỚC CÂU CÁ =======================

func _throw() -> void:
	var p: Vector2 = game.player
	cast_to = _cast_point(power)
	if absf(cast_to.x - p.x) > 4.0:
		rod_sign = -1.0 if cast_to.x < p.x else 1.0
	cast_from = _tip()
	shore_pt = _shore_point()
	fly_t = 0.0
	state = Phase.FLY
	game.audio.play_sfx("cast")

func _land() -> void:
	state = Phase.WAIT
	wait_t = 0.0
	bite_delay = randf_range(2.0, 6.0)
	nibble_t = randf_range(0.8, 1.6)
	dip_t = 0.0
	_roll_item()
	_add_splash(cast_to, 1.0)
	game.audio.play_sfx("splash")

func _bite() -> void:
	state = Phase.BITE
	bite_t = 0.0
	_add_splash(cast_to, 0.6)
	game.audio.play_sfx("bite")

func _start_reel() -> void:
	state = Phase.REEL
	var spd := float(item["spd"])
	zone_h = 46.0 - 9.0 * minf(spd, 1.6)
	zone_y = BAR_LEN - zone_h
	zone_v = 0.0
	fish_y = BAR_LEN * 0.5
	fish_target = fish_y
	fish_timer = 0.0
	progress = 0.35
	game.audio.play_sfx("reel")

func _update_reel(delta: float) -> void:
	var spd := float(item["spd"])
	var holding := Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_SPACE)
	# vùng xanh: giữ phím thì bay lên, thả ra thì rơi xuống
	if holding:
		zone_v -= 320.0 * delta
	else:
		zone_v += 260.0 * delta
	zone_v = clampf(zone_v, -150.0, 150.0)
	zone_y += zone_v * delta
	if zone_y < 0.0:
		zone_y = 0.0
		zone_v = absf(zone_v) * 0.3
	if zone_y > BAR_LEN - zone_h:
		zone_y = BAR_LEN - zone_h
		zone_v = -absf(zone_v) * 0.3
	# con cá: bơi lên xuống ngẫu nhiên
	fish_timer -= delta
	if fish_timer <= 0.0:
		fish_target = randf_range(8.0, BAR_LEN - 8.0)
		fish_timer = randf_range(0.45, 1.3)
	fish_y = move_toward(fish_y, fish_target, (35.0 + 45.0 * spd) * delta)
	# tiến độ
	var inside := fish_y >= zone_y and fish_y <= zone_y + zone_h
	if inside:
		progress += 0.3 * delta
	else:
		progress -= 0.14 * (0.6 + 0.4 * spd) * delta
	if randf() < delta * 4.0:
		_add_splash(_bob_pos() + Vector2(randf_range(-6.0, 6.0), randf_range(-3.0, 3.0)), 0.4)
	if progress >= 1.0:
		_success()
	elif progress <= 0.0:
		_fail("Cá giật đứt dây rồi!")

func _success() -> void:
	state = Phase.RESULT
	result_ok = true
	result_t = 0.0
	var iname: String = item["name"]
	var pts := int(item["pts"])
	counts[iname] = int(counts.get(iname, 0)) + 1
	if int(item["kind"]) == 0:
		pts = int(round(pts * (0.7 + 0.6 * item_q)))
		caught_total += 1
		var prev := float(best.get(iname, 0.0))
		var record := item_size > prev
		if record:
			best[iname] = item_size
		result_title = "Bắt được %s!" % iname
		result_line = "%.1f cm    +%d điểm" % [item_size, pts]
		if int(counts[iname]) == 1:
			result_extra = "Loài mới! Xem trong sổ cá [B]"
		elif record:
			result_extra = "Kỷ lục mới cho loài này!"
		else:
			result_extra = ""
	else:
		result_title = "Vớt được %s..." % iname
		result_line = str(item["note"])
		result_extra = "+%d điểm" % pts
	score += pts
	_add_splash(shore_pt, 1.2)
	game.audio.play_sfx("catch")

func _fail(msg: String) -> void:
	state = Phase.RESULT
	result_ok = false
	result_t = 0.0
	result_title = msg
	result_line = "Thử lại nào!"
	result_extra = ""
	game.audio.play_sfx("fail")

# chọn món cá cắn câu: quăng càng xa càng dễ ra cá hiếm/to, quăng gần hay ra rác
func _roll_item() -> void:
	var total := 0.0
	var ws: Array[float] = []
	for it in ITEMS:
		var w: float = float(it["w"]) * lerpf(1.0, float(it["far"]), power)
		ws.append(w)
		total += w
	var r := randf() * total
	var idx := 0
	for i in ws.size():
		r -= ws[i]
		if r <= 0.0:
			idx = i
			break
	item = ITEMS[idx]
	item_q = pow(randf(), lerpf(1.5, 0.8, power))
	item_size = snappedf(lerpf(float(item["min"]), float(item["max"]), item_q), 0.1)

# ======================= HÌNH HỌC CỦA HỒ =======================

func _lake() -> Rect2:
	return game.LAKE

func _near_shore() -> bool:
	var lake := _lake()
	var p: Vector2 = game.player
	var o := p - lake.get_center()
	var rx := lake.size.x * 0.5 + NEAR_MARGIN
	var ry := lake.size.y * 0.5 + NEAR_MARGIN
	return (o.x / rx) * (o.x / rx) + (o.y / ry) * (o.y / ry) <= 1.0

# giao của tia (xuất phát từ p, hướng u) với mặt hồ: trả về Vector2(t vào nước, t ra khỏi nước)
func _chord(p: Vector2, u: Vector2) -> Vector2:
	var lake := _lake()
	var o := p - lake.get_center()
	var rx := lake.size.x * 0.5
	var ry := lake.size.y * 0.5
	var a := (u.x / rx) * (u.x / rx) + (u.y / ry) * (u.y / ry)
	var b := 2.0 * ((o.x * u.x) / (rx * rx) + (o.y * u.y) / (ry * ry))
	var k := (o.x / rx) * (o.x / rx) + (o.y / ry) * (o.y / ry) - 1.0
	var disc := b * b - 4.0 * a * k
	if disc <= 0.0:
		return Vector2(10.0, 40.0)
	var sq := sqrt(disc)
	return Vector2((-b - sq) / (2.0 * a), (-b + sq) / (2.0 * a))

func _to_center() -> Vector2:
	var p: Vector2 = game.player
	return (_lake().get_center() - p).normalized()

# điểm phao rơi xuống nước theo sức quăng pw (0..1), luôn nằm trong hồ
func _cast_point(pw: float) -> Vector2:
	var p: Vector2 = game.player
	var u := _to_center()
	var ch := _chord(p, u)
	var t1 := maxf(ch.x, 6.0)
	var t2 := maxf(ch.y, t1 + 24.0)
	var d := t1 + minf((t2 - t1) * (0.15 + 0.65 * pw), 100.0)
	return p + u * d

func _shore_point() -> Vector2:
	var p: Vector2 = game.player
	var u := _to_center()
	var ch := _chord(p, u)
	return p + u * maxf(ch.x, 6.0)

func _face_lake() -> void:
	var p: Vector2 = game.player
	var u := _lake().get_center() - p
	if absf(u.x) > absf(u.y):
		game.facing = 2 if u.x < 0.0 else 3
	else:
		game.facing = 1 if u.y < 0.0 else 0
	rod_sign = -1.0 if u.x < 0.0 else 1.0

func _hand() -> Vector2:
	var p: Vector2 = game.player
	var f: int = game.facing
	if f == 2:
		return p + Vector2(-7.0, -7.0)
	if f == 3:
		return p + Vector2(7.0, -7.0)
	return p + Vector2(rod_sign * 7.0, -7.0)

func _tip() -> Vector2:
	return _hand() + Vector2(rod_sign * 9.0, -13.0)

func _bob_pos() -> Vector2:
	var clk: float = game.clock
	match state:
		Phase.FLY:
			var t := clampf(fly_t, 0.0, 1.0)
			return cast_from.lerp(cast_to, t) + Vector2(0.0, -sin(t * PI) * 30.0)
		Phase.WAIT:
			var dip := 0.0
			if dip_t > 0.0:
				dip = sin(dip_t / 0.3 * PI) * 2.5
			return cast_to + Vector2(0.0, sin(clk * 2.5) * 0.7 + dip)
		Phase.BITE:
			return cast_to + Vector2(sin(clk * 45.0) * 1.2, 2.0 + sin(clk * 30.0) * 1.5)
		Phase.REEL:
			return cast_to.lerp(shore_pt, progress * 0.8) + Vector2(sin(clk * 35.0), sin(clk * 28.0))
	return cast_to

# ======================= VẼ LÊN THẾ GIỚI (main.gd gọi mỗi khung hình) =======================

func draw_front_layer() -> void:
	if state == Phase.IDLE and splashes.is_empty():
		return
	var clk: float = game.clock
	if state != Phase.IDLE:
		var hand := _hand()
		var tip := _tip()
		if state == Phase.BITE:
			tip += Vector2(0.0, 2.0 + sin(clk * 40.0))
		elif state == Phase.REEL:
			tip += Vector2(-rod_sign * 3.0 * progress + sin(clk * 30.0), 0.0)
		game.draw_line(hand, tip, ROD_COL, 1.5)
		game.draw_circle(tip, 0.8, Color.WHITE)
		if state == Phase.AIM:
			_draw_aim(tip, clk)
		elif state != Phase.RESULT:
			var bob := _bob_pos()
			if state == Phase.WAIT or state == Phase.BITE or state == Phase.REEL:
				_draw_lure_shadow(bob, clk)
			var sag := 7.0
			if state == Phase.FLY:
				sag = 2.0
			elif state == Phase.REEL:
				sag = 2.0 + sin(clk * 20.0)
			_draw_line(tip, bob, sag)
			_draw_bobber(bob, clk)
		if state == Phase.BITE:
			var p: Vector2 = game.player
			game.ctext("!", p.x - 10.0, p.y - 38.0 - absf(sin(clk * 14.0)) * 2.0, 20.0, 16, Color("ff3b30"))
	for sp in splashes:
		_draw_splash(sp)

func _draw_aim(tip: Vector2, clk: float) -> void:
	var tp := _cast_point(power)
	for i in range(1, 9):
		var q := tip.lerp(tp, i / 9.0)
		game.rc(q.x, q.y, 1.0, 1.0, Color(1, 1, 1, 0.55))
	game.draw_arc(tp, 5.0 + sin(clk * 8.0), 0.0, TAU, 16, Color(1, 1, 1, 0.9), 1.0)
	game.draw_arc(tp, 2.0, 0.0, TAU, 8, Color("ffd23f"), 1.0)

func _draw_line(a: Vector2, b: Vector2, sag: float) -> void:
	var mid := (a + b) * 0.5 + Vector2(0.0, sag)
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	game.draw_polyline(pts, Color(1, 1, 1, 0.85), 1.0)

func _draw_bobber(b: Vector2, clk: float) -> void:
	game.draw_arc(b + Vector2(0.0, 1.0), 5.0 + sin(clk * 3.0), 0.0, TAU, 16, Color(1, 1, 1, 0.35), 1.0)
	game.draw_circle(b + Vector2(0.0, 1.5), 3.0, Color(0.1, 0.3, 0.5, 0.5))
	game.rc(b.x - 2.0, b.y - 4.0, 4.0, 3.0, Color("e5322d"))
	game.rc(b.x - 2.0, b.y - 1.0, 4.0, 2.0, Color.WHITE)

# bóng con cá bơi quanh phao, càng gần lúc cắn càng sát phao
func _draw_lure_shadow(bob: Vector2, clk: float) -> void:
	var a := 1.0
	if state == Phase.WAIT:
		a = clampf(wait_t / bite_delay, 0.0, 1.0)
	var ang := clk * 1.6
	var r := lerpf(34.0, 9.0, a)
	var pos := bob + Vector2.from_angle(ang) * r
	var xf := Transform2D(ang + PI * 0.5, pos)
	var wag := sin(clk * 8.0) * 1.5
	var body := PackedVector2Array()
	for i in 10:
		var t := TAU * i / 10.0
		body.append(Vector2(cos(t) * 6.0, sin(t) * 2.6))
	var tail := PackedVector2Array([Vector2(-5.0, 0.0), Vector2(-10.0, -3.0 + wag), Vector2(-10.0, 3.0 + wag)])
	var col := Color(0.05, 0.2, 0.4, 0.38)
	game.draw_colored_polygon(xf * body, col)
	game.draw_colored_polygon(xf * tail, col)

func _draw_splash(sp: Dictionary) -> void:
	var t := float(sp["t"]) / 0.7
	var pos: Vector2 = sp["pos"]
	var big := float(sp["big"])
	var r := (3.0 + 15.0 * t) * big
	game.draw_arc(pos, r, 0.0, TAU, 20, Color(1, 1, 1, 0.8 * (1.0 - t)), 1.0)
	if t < 0.6:
		for k in 5:
			var a := k * 1.256
			var d := pos + Vector2(cos(a) * r * 0.7, sin(a) * r * 0.3 - sin(t / 0.6 * PI) * 10.0 * big)
			game.rc(d.x, d.y, 1.5, 1.5, Color(1, 1, 1, 0.9))

# ======================= GIAO DIỆN TRÊN MÀN HÌNH =======================

func _txt(t: String, x: float, y: float, sz: int, col: Color) -> void:
	ui.draw_string(font, Vector2(x + 1.0, y + 1.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.6))
	ui.draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _ctxt(t: String, cx: float, y: float, sz: int, col: Color) -> void:
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_txt(t, cx - w * 0.5, y, sz, col)

func _draw_ui() -> void:
	if font == null:
		return
	if caught_total > 0 or near or active:
		var t := "Cá: %d    Điểm: %d" % [caught_total, score]
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 10.0
		ui.draw_rect(Rect2(4, 37, w, 13), Color(0.05, 0.1, 0.2, 0.6))
		_txt(t, 9.0, 47.0, 9, Color("ffd23f"))
	if show_bag and not active:
		_draw_bag()
		return
	match state:
		Phase.IDLE:
			if near:
				_prompt("[E] Câu cá ở hồ        [B] Sổ cá")
		Phase.AIM:
			_prompt("Bấm [E] để quăng cần         [Q] hủy")
			_power_meter()
		Phase.WAIT:
			_prompt("Chờ cá cắn câu...        [Q] thu cần")
		Phase.BITE:
			_prompt("CÁ CẮN CÂU! Bấm [E] ngay!", true)
		Phase.REEL:
			_prompt("Giữ [E] để nâng vùng xanh, bám theo con cá!")
			_reel_ui()
		Phase.RESULT:
			_result_ui()

func _prompt(text: String, alert: bool = false) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 14.0
	var x := 240.0 - w * 0.5
	var y := 232.0
	var bg := Color(0.05, 0.1, 0.2, 0.75)
	var clk: float = game.clock
	if alert and int(clk * 6.0) % 2 == 0:
		bg = Color(0.6, 0.1, 0.1, 0.85)
	ui.draw_rect(Rect2(x, y, w, 16.0), bg)
	ui.draw_rect(Rect2(x, y + 16.0, w, 1.0), Color("ffd23f"))
	_txt(text, x + 7.0, y + 12.0, 9, Color.WHITE)

func _power_meter() -> void:
	var x := 170.0
	var y := 212.0
	var w := 140.0
	ui.draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, 12.0), Color(0, 0, 0, 0.75))
	ui.draw_rect(Rect2(x, y, w, 8.0), Color("2a3a4a"))
	ui.draw_rect(Rect2(x, y, w * power, 8.0), Color("6bd36b").lerp(Color("ff5a4d"), power))
	for i in range(1, 4):
		ui.draw_rect(Rect2(x + w * i * 0.25 - 0.5, y, 1.0, 8.0), Color(1, 1, 1, 0.4))
	_ctxt("Sức quăng - quăng càng xa càng dễ ra cá to", 240.0, y - 5.0, 8, Color.WHITE)

func _reel_ui() -> void:
	var x := 24.0
	var y := 68.0
	ui.draw_rect(Rect2(x - 6.0, y - 16.0, 56.0, BAR_LEN + 24.0), Color(0.05, 0.1, 0.2, 0.7))
	_txt("CÂU", x, y - 5.0, 8, Color("ffd23f"))
	ui.draw_rect(Rect2(x, y, 20.0, BAR_LEN), Color("1d4f7a"))
	var inside := fish_y >= zone_y and fish_y <= zone_y + zone_h
	var zc := Color("5be36b") if inside else Color("3fa84d")
	ui.draw_rect(Rect2(x + 1.0, y + zone_y, 18.0, zone_h), Color(zc.r, zc.g, zc.b, 0.85))
	_icon(item, Vector2(x + 10.0, y + fish_y), 0.55)
	var px := x + 26.0
	ui.draw_rect(Rect2(px, y, 8.0, BAR_LEN), Color("22303d"))
	var ph := BAR_LEN * clampf(progress, 0.0, 1.0)
	ui.draw_rect(Rect2(px, y + BAR_LEN - ph, 8.0, ph), Color("ff5a4d").lerp(Color("6bd36b"), progress))

func _result_ui() -> void:
	var r := Rect2(96.0, 82.0, 288.0, 82.0)
	var edge := Color("ffd23f") if result_ok else Color("ff5a4d")
	ui.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.75))
	ui.draw_rect(r, Color(0.06, 0.12, 0.24, 0.95))
	ui.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), edge)
	if result_ok:
		ui.draw_rect(Rect2(r.position.x + 8.0, r.position.y + 14.0, 60.0, 54.0), Color(0.1, 0.3, 0.5, 0.6))
		_icon(item, Vector2(r.position.x + 38.0, r.position.y + 41.0), 1.8)
		var tx := r.position.x + 78.0
		_txt(result_title, tx, r.position.y + 26.0, 10, edge)
		_txt(result_line, tx, r.position.y + 42.0, 9, Color.WHITE)
		if result_extra != "":
			_txt(result_extra, tx, r.position.y + 57.0, 8, Color("bfe3ff"))
		_txt("[E] tiếp tục", r.end.x - 66.0, r.end.y - 5.0, 7, Color(1, 1, 1, 0.55))
	else:
		_ctxt(result_title, 240.0, r.position.y + 34.0, 10, edge)
		_ctxt(result_line, 240.0, r.position.y + 52.0, 9, Color.WHITE)
		_txt("[E] tiếp tục", r.end.x - 66.0, r.end.y - 5.0, 7, Color(1, 1, 1, 0.55))

func _draw_bag() -> void:
	var r := Rect2(120.0, 44.0, 240.0, 184.0)
	ui.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.75))
	ui.draw_rect(r, Color(0.06, 0.12, 0.24, 0.95))
	ui.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), Color("ffd23f"))
	_ctxt("SỔ CÂU CÁ", 240.0, r.position.y + 15.0, 10, Color("ffd23f"))
	var y := r.position.y + 22.0
	for it in ITEMS:
		var iname: String = it["name"]
		var n := int(counts.get(iname, 0))
		var cy := y + 8.0
		if n > 0:
			_icon(it, Vector2(r.position.x + 24.0, cy), 0.8)
			_txt(iname, r.position.x + 44.0, cy + 3.0, 8, Color.WHITE)
			var info := "x%d" % n
			if int(it["kind"]) == 0:
				info += "   tối đa %.1f cm" % float(best.get(iname, 0.0))
			_txt(info, r.position.x + 140.0, cy + 3.0, 8, Color("bfe3ff"))
		else:
			_txt("???", r.position.x + 44.0, cy + 3.0, 8, Color(1, 1, 1, 0.4))
		y += 15.0
	_ctxt("Tổng điểm: %d        [B] đóng" % score, 240.0, r.end.y - 6.0, 8, Color(1, 1, 1, 0.8))

# biểu tượng cá / đồ vớt được (vẽ trên lớp giao diện), p là tâm, s là tỉ lệ
func _icon(it: Dictionary, p: Vector2, s: float) -> void:
	var col: Color = it["col"]
	var kind: String = it["icon"]
	match kind:
		"fish", "koi":
			var body := PackedVector2Array()
			var belly := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				body.append(p + Vector2(cos(a) * 10.0, sin(a) * 5.5) * s)
				belly.append(p + Vector2(cos(a) * 8.0, 2.0 + sin(a) * 2.4) * s)
			var tail := PackedVector2Array([p + Vector2(-8.0, 0.0) * s, p + Vector2(-16.0, -6.0) * s, p + Vector2(-16.0, 6.0) * s])
			var fin := PackedVector2Array([p + Vector2(-3.0, -5.0) * s, p + Vector2(3.0, -5.0) * s, p + Vector2(0.0, -10.0) * s])
			ui.draw_colored_polygon(tail, col.darkened(0.25))
			ui.draw_colored_polygon(fin, col.darkened(0.25))
			ui.draw_colored_polygon(body, col)
			ui.draw_colored_polygon(belly, col.lightened(0.35))
			if kind == "koi":
				ui.draw_circle(p + Vector2(-2.0, -2.0) * s, 2.2 * s, Color("e5322d"))
				ui.draw_circle(p + Vector2(3.0, 1.0) * s, 1.8 * s, Color("e5322d"))
				ui.draw_circle(p + Vector2(-6.0, 1.5) * s, 1.4 * s, Color.WHITE)
			ui.draw_line(p + Vector2(3.0, -4.0) * s, p + Vector2(3.5, 4.0) * s, col.darkened(0.3), 1.0)
			ui.draw_circle(p + Vector2(6.0, -1.5) * s, 1.3 * s, Color.WHITE)
			ui.draw_circle(p + Vector2(6.3, -1.5) * s, 0.7 * s, Color.BLACK)
		"sandal":
			ui.draw_rect(Rect2(p + Vector2(-10.0, -3.0) * s, Vector2(20.0, 7.0) * s), col)
			ui.draw_rect(Rect2(p + Vector2(-10.0, 2.0) * s, Vector2(20.0, 2.0) * s), col.darkened(0.3))
			ui.draw_rect(Rect2(p + Vector2(-2.0, -5.0) * s, Vector2(6.0, 4.0) * s), col.lightened(0.25))
		"can":
			ui.draw_rect(Rect2(p + Vector2(-4.0, -6.0) * s, Vector2(8.0, 12.0) * s), col)
			ui.draw_rect(Rect2(p + Vector2(-4.0, -2.0) * s, Vector2(8.0, 4.0) * s), Color("e5322d"))
			ui.draw_rect(Rect2(p + Vector2(-4.0, -7.0) * s, Vector2(8.0, 1.5) * s), Color("dfe6ea"))
			ui.draw_rect(Rect2(p + Vector2(-4.0, 5.5) * s, Vector2(8.0, 1.5) * s), Color("dfe6ea"))
		"paper":
			ui.draw_rect(Rect2(p + Vector2(-7.0, -8.0) * s, Vector2(14.0, 16.0) * s), col)
			ui.draw_rect(Rect2(p + Vector2(-7.0, -8.0) * s, Vector2(14.0, 16.0) * s), Color("b8b8b8"), false, 1.0)
			for i in 3:
				ui.draw_rect(Rect2(p + Vector2(-5.0, -6.0 + i * 3.0) * s, Vector2(8.0, 1.0) * s), Color("c8c8c8"))
			ui.draw_string(font, p + Vector2(1.0, 7.0) * s, "4", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(6, int(9.0 * s)), Color("e5322d"))
		"card":
			ui.draw_rect(Rect2(p + Vector2(-9.0, -6.0) * s, Vector2(18.0, 12.0) * s), col)
			ui.draw_rect(Rect2(p + Vector2(-9.0, -6.0) * s, Vector2(18.0, 2.5) * s), Color("ffd23f"))
			ui.draw_rect(Rect2(p + Vector2(-8.0, -2.0) * s, Vector2(6.0, 7.0) * s), Color("dfe6ff"))
			ui.draw_rect(Rect2(p + Vector2(0.0, -2.0) * s, Vector2(8.0, 1.5) * s), Color.WHITE)
			ui.draw_rect(Rect2(p + Vector2(0.0, 1.0) * s, Vector2(8.0, 1.5) * s), Color.WHITE)
