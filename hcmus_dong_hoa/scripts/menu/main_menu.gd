extends Control
## Menu chính "Daily US" - pixel art (Godot 4.x) - bản tối ưu: không chạy code mỗi frame, dựng bảng phụ sau, tải game ở luồng nền.
## Đặt tại res://scripts/menu/main_menu.gd - node gốc của main_menu.tscn là Control.
## LOGO: kéo file logo vào ô "Logo" ở Inspector. Để trống thì tự tìm (chỉ quét 1 lần rồi nhớ đường dẫn).
## FONT: tự dùng res://font.ttf (cùng font với game) nếu có.

@export_file("*.tscn") var game_scene: String = "res://main.tscn"
@export var save_path: String = "user://save.json"
@export var logo: Texture2D
@export var mascot_left: Texture2D       ## ảnh to góc trái dưới. Để trống thì tự tìm left.png cạnh file script hoặc trong thư mục mascots/
@export var mascot_top_right: Texture2D  ## ảnh góc phải trên. Để trống thì tự tìm top_right.png cạnh file script
@export var mascot_gate: Texture2D       ## nhân vật đứng ở cổng. Để trống thì tự tìm gate.png cạnh file script (không có thì dùng nhân vật pixel)
@export var team_members: PackedStringArray = ["Phan Đăng Dương", "Phạm Lê Nhật Anh", "Huỳnh Quốc Bảo", "Trần Gia Hòa", "Lê Thanh Trọng Trân", "Đỗ Phú Lâm"]  ## tên các thành viên - điền ở Inspector, hiện trong mục Giới thiệu
@export var team_class: String = ""  ## lớp / môn học / GVHD (tuỳ chọn)

const TITLE_A := "DAILY"
const TITLE_B := "US"
const SUBTITLE := "Một ngày ở HCMUS - Đông Hòa"
const SCHOOL_1 := "ĐẠI HỌC QUỐC GIA TP. HỒ CHÍ MINH"
const SCHOOL_2 := "TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN"
const VERSION := "v0.1"
const SETTINGS_PATH := "user://settings.cfg"
const GATE_X := 0.80   # vị trí cổng trường theo chiều ngang (0..1)

const C_NAVY := Color("151b3c")
const C_NAVY2 := Color("232b5a")
const C_EDGE := Color("3d4a8c")
const C_GOLD := Color("f0b429")
const C_GOLD_LT := Color("ffe28a")
const C_WHITE := Color("ffffff")
const C_DARK := Color("0b0f26")

const LOGO_GUESSES := [
	"res://logo.png", "res://assets/logo.png", "res://assets/logo.svg",
	"res://images/logo.png", "res://art/logo.png", "res://assets/images/logo.png",
]

# ---- CỐT TRUYỆN KHI CHƠI MỚI (sửa chữ ở đây) ----
const STORY_NEW := [
	{"who": "Người dẫn chuyện", "text": "Đậu US rồi thì đời màu gì cũng được. Sáng thứ Hai, tuần đầu tiên của học kỳ, bạn đứng trước cổng trường mà vẫn chưa tin là mình đậu thật."},
	{"who": "Mục tiêu", "text": "Vào rồi thì phải học thôi: giữ GPA, tích lũy điểm rèn luyện và xoay xở từ chiếc ví 0đ. Tiền sinh hoạt sẽ về theo tuần; tiền thi lại thì không nằm trong ngân sách đâu nha."},
	{"who": "Bác bảo vệ", "text": "Em sinh viên mới hả? Tiết đầu của em là Thể dục ở Nhà TD, 8 giờ 20. Còn sớm thì đi dạo cho quen đường, đi lạc cũng đừng ngại hỏi, năm nhất ai mà chẳng lạc."},
	{"who": "Hướng dẫn", "text": "Dùng các phím dưới đây để di chuyển và tương tác. Chúc bạn một học kỳ qua môn hết, khỏi phải gặp lại ai trong phòng thi lần hai!",
		"keys": [["W A S D", "Di chuyển"], ["E", "Tương tác"], ["Tab", "Sổ tay"]]},
]

var _u := 1.0
var _p := 8.0
var _gw := 160
var _starting := false
var _game_requested := false
var _font: Font
var _logo_tex: Texture2D
var _cfg := ConfigFile.new()
var _save_timer: Timer
var _img: Image

var _menu_ui: Control
var _menu_box: VBoxContainer
var _buttons: Array[Button] = []
var _first_button: Button
var _dim: ColorRect
var _panels := {}
var _panel_focus := {}
var _btn_styles := {}
var _menu_styles := {}
var _vol_slider: HSlider
var _vol_label: Label
var _fs_check: CheckBox
var _beep: AudioStreamPlayer
var _beep_data := PackedVector2Array()
var _last_beep := 0

var _story_layer: Control
var _story_pages: Array = []
var _story_idx := 0
var _story_done: Callable
var _story_speaker: Label
var _story_text: Label
var _story_hint: Label
var _story_keys: HBoxContainer
var _story_tween: Tween
var _story_typing := false
var _story_last_chars := 0
var _tick_player: AudioStreamPlayer
var _tick_data := PackedVector2Array()
var _last_tick_ms := 0
var _blink: Tween


func _s(v: float) -> int:
	return int(round(v * _u))


func _ready() -> void:
	_u = clampf(get_viewport_rect().size.y / 720.0, 0.3, 2.0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = get_theme_default_font()
	if ResourceLoader.exists("res://font.ttf"):
		var f = load("res://font.ttf")
		if f is Font:
			_font = f
	var th := Theme.new()
	th.default_font = _font
	th.default_font_size = _s(20)
	theme = th

	_cfg.load(SETTINGS_PATH)
	_save_timer = Timer.new()
	_save_timer.wait_time = 0.5
	_save_timer.one_shot = true
	_save_timer.timeout.connect(func(): _cfg.save(SETTINGS_PATH))
	add_child(_save_timer)
	_logo_tex = _find_logo()

	_build_background()
	_menu_ui = Control.new()
	_menu_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_ui)
	_build_main_menu()
	_build_footer()
	_dim = ColorRect.new()
	_dim.color = Color(0.04, 0.06, 0.18, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	add_child(_dim)
	_apply_settings()
	_show_menu()
	_intro_animation()
	_build_rest_later()


## Dựng bảng phụ + âm thanh thử SAU khi menu đã hiện (không làm chậm lúc vào menu)
func _build_rest_later() -> void:
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_ensure_panels()


func _ensure_panels() -> void:
	if _panels.is_empty():
		_build_panels()
		_setup_beep()


# ============================================================ PIXEL ART (vẽ 1 lần vào ảnh nhỏ 90px cao)
func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	_img.fill_rect(Rect2i(int(floor(x)), int(floor(y)), int(ceil(w)), int(ceil(h))), c)


func _disc(cx: float, cy: float, rad: int, c: Color) -> void:
	for dy in range(-rad, rad + 1):
		var half := int(floor(sqrt(float(rad * rad - dy * dy)) + 0.5))
		_r(cx - half, cy + dy, half * 2 + 1, 1, c)


func _tree(x: float, y: float, rad: int, rng: RandomNumberGenerator) -> void:
	_r(x - 1, y + rad - 2, 3, 14, Color("6b4a35"))
	_disc(x, y, rad, Color("3a9248"))
	_disc(x - 1, y - 1, rad - 2, Color("4aa356"))
	var fl := Color("ff6a4d")
	for i in 10:
		_r(x + rng.randi_range(-rad + 2, rad - 2), y + rng.randi_range(-rad + 2, rad - 2), 1, 1, fl)


func _bake_scene() -> ImageTexture:
	var gw := float(_gw)
	_img = Image.create_empty(_gw, 90, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# trời
	var sky := [Color("6fc3ee"), Color("86cff2"), Color("9ddaf5"), Color("b4e4f8"), Color("c9ecf9"), Color("dcf3fa"), Color("ecf8f4"), Color("fbf3d6")]
	for i in 8:
		_r(0, i * 7, gw, 7, sky[i])
	var sx := floorf(gw * 0.86)
	_disc(sx, 15, 10, Color("c0e3e3"))
	_disc(sx, 15, 6, Color("fff1a0"))
	# tòa nhà xa
	var win := Color("c4d6f0")
	var x := 0.0
	while x < gw:
		var bw := float(rng.randi_range(8, 16))
		var bh := float(rng.randi_range(10, 24))
		_r(x, 56.0 - bh, bw, bh, Color("98b4dc"))
		_r(x + bw - 1, 56.0 - bh, 1, bh, Color("8aa5cf"))
		var wy := 56.0 - bh + 2.0
		while wy < 54.0:
			var wx := x + 2.0
			while wx < x + bw - 2.0:
				_r(wx, wy, 1, 1, win)
				wx += 3.0
			wy += 3.0
		x += bw + float(rng.randi_range(0, 2))
	# hàng cây xa
	x = 2.0
	while x < gw:
		_disc(x, 55, 4, Color("4aa356"))
		x += 9.0
	# bãi cỏ
	_r(0, 56, gw, 34, Color("5db35b"))
	var g_dark := Color("54a551")
	var g_light := Color("6cc069")
	for i in 260:
		_r(rng.randf() * gw, 57.0 + rng.randf() * 32.0, 2, 1, g_dark)
	for i in 120:
		_r(rng.randf() * gw, 57.0 + rng.randf() * 32.0, 1, 1, g_light)
	var cx := floorf(gw * GATE_X)
	# sân gạch
	_r(cx - 34, 58, 68, 16, Color("e4d3ab"))
	for gx in range(int(cx) - 34, int(cx) + 35, 5):
		_r(gx, 58, 1, 16, Color("d3c19a"))
	for gy in range(58, 75, 4):
		_r(cx - 34, gy, 68, 1, Color("d3c19a"))
	# vỉa hè + đường
	_r(0, 76, gw, 3, Color("b7bccb"))
	_r(0, 79, gw, 11, Color("586078"))
	for dx in range(2, _gw, 16):
		_r(dx, 85, 8, 1, Color("e8ebf5"))
	# luống hoa
	var cols := [Color("ff7aa8"), Color("ffd24d"), Color("ffffff"), Color("b78cff")]
	for bed in [Vector2(cx - 52, 66), Vector2(cx + 38, 66)]:
		_r(bed.x, bed.y, 14, 5, Color("3f8f48"))
		for i in 16:
			_r(bed.x + rng.randi_range(0, 13), bed.y + rng.randi_range(0, 4), 1, 1, cols[rng.randi() % 4])
	_tree(cx - 46, 40, 8, rng)
	_tree(cx + 48, 38, 9, rng)
	# Cổng trường HCMUS
	var x0 := cx - 18.0
	_r(x0 + 5, 58, 26, 16, Color("6b7389"))
	for i in 5:
		_r(x0 + 5, 61.0 + i * 3.0, 26, 1, Color("e6e9f5"))
	_r(cx - 1, 58, 1, 16, Color("e6e9f5"))
	for px in [x0, x0 + 31.0]:
		_r(px, 52, 5, 22, Color("a14a52"))
		_r(px, 52, 1, 22, Color("bb6068"))
		_r(px + 4, 52, 1, 22, Color("86393f"))
	_r(x0 - 1, 49, 38, 8, Color("3a6fc0"))
	_r(x0 - 1, 49, 38, 1, Color("6aa0ea"))
	_r(x0 - 1, 56, 38, 1, Color("2a528f"))
	# cột cờ + cờ đỏ sao vàng
	var fx := cx - 30.0
	_r(fx, 35, 1, 39, Color("dfe3f5"))
	_r(fx + 1, 35, 13, 9, Color("d62a35"))
	var star := ["..#..", "#####", ".###.", ".#.#.", "#...#"]
	for yy in 5:
		for xx in 5:
			if star[yy][xx] == "#":
				_r(fx + 5 + xx, 37 + yy, 1, 1, Color("ffdd33"))
	# chốt bảo vệ + thanh chắn
	var bx := cx + 24.0
	_r(bx, 64, 10, 10, Color("8fa0c8"))
	_r(bx - 1, 62, 12, 2, Color("4a5686"))
	_r(bx + 3, 66, 4, 3, Color("bfe3f5"))
	for i in 4:
		_r(cx + 17.0 + i * 2.0, 67, 2, 2, Color("e8ebf5") if i % 2 == 0 else Color("d0303c"))
	return ImageTexture.create_from_image(_img)


func _pixel_rect(tex: Texture2D, pos: Vector2, sz: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = pos
	tr.size = sz
	return tr


func _build_background() -> void:
	var vp := get_viewport_rect().size
	_p = vp.y / 90.0
	_gw = int(ceil(vp.x / _p))
	var bg := _pixel_rect(_bake_scene(), Vector2.ZERO, Vector2(_gw * _p, vp.y))
	bg.modulate = Color(0.86, 0.87, 0.9)   # thay cho lớp phủ tối toàn màn hình (đỡ 1 lượt vẽ full-screen)
	add_child(bg)

	# chữ HCMUS trên bảng cổng
	var gate_cx := floorf(_gw * GATE_X)
	var plate := Label.new()
	plate.text = "HCMUS"
	plate.position = Vector2((gate_cx - 19.0) * _p, 49.0 * _p)
	plate.size = Vector2(38.0 * _p, 8.0 * _p)
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_theme_font_size_override("font_size", int(5.6 * _p))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	# mây: 1 ảnh dùng chung, mỗi đám trôi bằng 1 tween (không chạy code mỗi frame)
	var ci := Image.create_empty(14, 5, false, Image.FORMAT_RGBA8)
	var wc := Color(1, 1, 1, 0.95)
	ci.fill_rect(Rect2i(3, 0, 6, 1), wc)
	ci.fill_rect(Rect2i(1, 1, 11, 1), wc)
	ci.fill_rect(Rect2i(0, 2, 14, 2), wc)
	ci.fill_rect(Rect2i(1, 4, 12, 1), Color("dfeaf5"))
	var ctex := ImageTexture.create_from_image(ci)
	for s in [[4.0, 1.6, 0.0], [14.0, 1.0, 55.0], [24.0, 1.3, 105.0], [8.0, 0.8, 130.0]]:
		var c := _pixel_rect(ctex, Vector2(s[2] * _p, s[0] * _p), Vector2(14.0 * _p, 5.0 * _p))
		add_child(c)
		_drift(c, s[1] * _p, vp.x)

	# ảnh nhân vật (mèo trái dưới / thỏ góc phải trên / thỏ ở cổng)
	var m_left := _find_mascot(mascot_left, "left")
	if m_left != null:
		var ml := _mascot_rect(m_left, vp.y * 0.48)
		ml.position = Vector2(vp.x * 0.03, 76.0 * _p - ml.size.y)
		add_child(ml)
	var m_tr := _find_mascot(mascot_top_right, "top_right")
	if m_tr != null:
		var mt := _mascot_rect(m_tr, vp.y * 0.25)
		var mt_y := vp.y * 0.03
		mt.position = Vector2(vp.x * 0.97 - mt.size.x, mt_y)
		add_child(mt)
		var sway := mt.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway.tween_property(mt, "position:y", mt_y + _p * 1.2, 1.6)
		sway.tween_property(mt, "position:y", mt_y, 1.6)

	_build_petals()

	var m_gate := _find_mascot(mascot_gate, "gate")
	if m_gate != null:
		var hero := _mascot_rect(m_gate, vp.y * 0.22)
		hero.position = Vector2(gate_cx * _p - hero.size.x * 0.5, 74.0 * _p - hero.size.y)
		add_child(hero)
		_breathe(hero)


func _find_mascot(given: Texture2D, file_name: String) -> Texture2D:
	if given != null:
		return given
	var base: String = get_script().resource_path.get_base_dir()
	for dir in [base, base + "/mascots"]:
		for ext in ["png", "webp", "jpg"]:
			var path := "%s/%s.%s" % [dir, file_name, ext]
			if ResourceLoader.exists(path):
				var r = load(path)
				if r is Texture2D:
					return r
	return null


func _mascot_rect(tex: Texture2D, height: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts := tex.get_size()
	tr.size = Vector2(height * ts.x / maxf(ts.y, 1.0), height)
	return tr


## Mây trôi: chạy nốt đoạn đầu, rồi lặp vô hạn từ mép trái sang mép phải
func _drift(c: Control, speed: float, w: float) -> void:
	var first := c.create_tween()
	first.tween_property(c, "position:x", w, maxf(0.1, (w - c.position.x) / speed))
	first.finished.connect(func():
		c.position.x = -c.size.x
		var lp := c.create_tween().set_loops()
		lp.tween_property(c, "position:x", w, (w + c.size.x) / speed)
		lp.tween_callback(func(): c.position.x = -c.size.x))


## "Thở": nhích lên xuống 2 lần/giây bằng tween
func _breathe(n: Control) -> void:
	var y0 := n.position.y
	var tw := n.create_tween().set_loops()
	tw.tween_callback(func(): n.position.y = y0 - _p)
	tw.tween_interval(0.5)
	tw.tween_callback(func(): n.position.y = y0)
	tw.tween_interval(0.5)


func _build_petals() -> void:
	var img := Image.create_empty(3, 3, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 0, 3, 2), Color("e8453c"))
	img.fill_rect(Rect2i(1, 2, 1, 1), Color("ff7a5c"))
	var tex := ImageTexture.create_from_image(img)
	var vp := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 16:
		var pt := _pixel_rect(tex, Vector2(rng.randf() * vp.x, rng.randf() * vp.y), Vector2(3, 3) * _p * 0.6)
		add_child(pt)
		var x0 := pt.position.x
		var dur := rng.randf_range(7.0, 12.0)
		var fall := create_tween().set_loops()
		fall.tween_property(pt, "position:y", vp.y + 20.0, dur * (vp.y + 20.0 - pt.position.y) / (vp.y + 40.0))
		fall.tween_callback(func(): pt.position.y = -20.0)
		fall.tween_property(pt, "position:y", vp.y + 20.0, dur)
		var sway := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var amp := rng.randf_range(30.0, 70.0) * _u
		sway.tween_property(pt, "position:x", x0 + amp, dur * 0.25)
		sway.tween_property(pt, "position:x", x0 - amp, dur * 0.5)
		sway.tween_property(pt, "position:x", x0, dur * 0.25)


# ============================================================ STYLE
func _outline(c: Control, col: Color, w: float) -> void:
	c.add_theme_color_override("font_outline_color", col)
	c.add_theme_constant_override("outline_size", _s(w))


func _pbox(bg: Color, border: Color, bw: float = 4, mh: float = 16, mv: float = 10, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(maxi(2, _s(bw)))
	sb.border_color = border
	sb.content_margin_left = _s(mh)
	sb.content_margin_right = _s(mh)
	sb.content_margin_top = _s(mv)
	sb.content_margin_bottom = _s(mv)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(_s(6), _s(6))
	return sb


func _label(text: String, size: float, color: Color = C_WHITE, outline: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _s(size))
	if color != C_WHITE:
		l.add_theme_color_override("font_color", color)
	if outline > 0.0:
		_outline(l, C_DARK, outline)
	return l


func _style_button(b: Button, font_size: float, primary: bool = false) -> void:
	if not _btn_styles.has(primary):   # tạo 1 lần, dùng chung cho mọi nút
		var hover := _pbox(C_GOLD, C_GOLD_LT, 3, 12, 8, false)
		_btn_styles[primary] = {
			"normal": _pbox(C_GOLD if primary else C_NAVY2, C_GOLD_LT if primary else C_EDGE, 3, 12, 8, false),
			"hover": hover, "focus": hover,
			"pressed": _pbox(Color("c8921a"), C_GOLD_LT, 3, 12, 8, false),
			"disabled": _pbox(Color("1a2045"), Color("2a3263"), 3, 12, 8, false),
		}
	for k in _btn_styles[primary]:
		b.add_theme_stylebox_override(k, _btn_styles[primary][k])
	b.add_theme_color_override("font_color", C_NAVY if primary else C_WHITE)
	for k in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, C_NAVY)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.28))
	b.add_theme_font_size_override("font_size", _s(font_size))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.mouse_entered.connect(func():
		if not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus())


# ---- logo: tìm 1 lần rồi nhớ (kể cả khi không có) trong settings.cfg ----
func _find_logo() -> Texture2D:
	if logo != null:
		return logo
	var saved := str(_cfg.get_value("ui", "logo_path", ""))
	var paths: Array = LOGO_GUESSES.duplicate()
	if saved != "" and saved != "none":
		paths.push_front(saved)
	for path in paths:
		if ResourceLoader.exists(path):
			var r = load(path)
			if r is Texture2D:
				return r
	if saved == "none":   # lần trước đã quét mà không thấy: khỏi quét lại (gán Logo ở Inspector nếu cần)
		return null
	var found := _scan_logo("res://", 0)
	_cfg.set_value("ui", "logo_path", found.resource_path if found != null else "none")
	_cfg.save(SETTINGS_PATH)
	return found


func _scan_logo(dir_path: String, depth: int) -> Texture2D:
	if depth > 3:
		return null
	var da := DirAccess.open(dir_path)
	if da == null:
		return null
	for f in da.get_files():
		var fname := f.trim_suffix(".import").trim_suffix(".remap")
		var low := fname.to_lower()
		if (low.ends_with(".png") or low.ends_with(".jpg") or low.ends_with(".webp") or low.ends_with(".svg")) \
				and (low.contains("logo") or low.contains("khtn")):
			var r = load(dir_path.path_join(fname))
			if r is Texture2D:
				return r
	for d in da.get_directories():
		if d.begins_with(".") or d == "addons":
			continue
		var t := _scan_logo(dir_path.path_join(d), depth + 1)
		if t != null:
			return t
	return null


# ============================================================ MENU CHÍNH
func _add_menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(_s(320), _s(46))
	_style_button(b, 22)
	if _menu_styles.is_empty():
		_menu_styles = {
			"normal": _flat(Color(C_NAVY2, 0.45)),
			"hover": _flat(C_GOLD, C_WHITE, 6),
			"pressed": _flat(Color("c8921a"), C_WHITE, 6),
			"disabled": _flat(Color(C_NAVY2, 0.2)),
		}
		_menu_styles["focus"] = _menu_styles["hover"]
	for k in _menu_styles:
		b.add_theme_stylebox_override(k, _menu_styles[k])
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	b.focus_entered.connect(func(): _pop_button(b, true))
	b.focus_exited.connect(func(): _pop_button(b, false))
	b.pressed.connect(cb)
	_menu_box.add_child(b)
	_buttons.append(b)
	return b


func _flat(bg: Color, accent: Color = Color(0, 0, 0, 0), bar: float = 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = _s(bar)
	sb.border_color = accent
	sb.content_margin_left = _s(16)
	sb.content_margin_right = _s(16)
	sb.content_margin_top = _s(6)
	sb.content_margin_bottom = _s(6)
	return sb


func _pop_button(b: Button, on: bool) -> void:
	if b.has_meta("pop"):
		var old = b.get_meta("pop")
		if old is Tween and old.is_valid():
			old.kill()
	var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2(1.04, 1.04) if on else Vector2.ONE, 0.14)
	b.set_meta("pop", tw)


func _wobble(l: Control, amp: float) -> void:
	l.resized.connect(func(): l.pivot_offset = l.size * 0.5)
	var tw := l.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(l, "rotation_degrees", amp, 1.4)
	tw.tween_property(l, "rotation_degrees", -amp, 2.8)
	tw.tween_property(l, "rotation_degrees", 0.0, 1.4)


func _title_label(text: String, color: Color) -> Label:
	var l := _label(text, 92, color, 12)
	l.add_theme_constant_override("shadow_offset_x", _s(5))
	l.add_theme_constant_override("shadow_offset_y", _s(5))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	return l


func _build_main_menu() -> void:
	# huy hiệu + tên trường (góc trên trái)
	var head := HBoxContainer.new()
	head.position = Vector2(_s(32), _s(22))
	head.add_theme_constant_override("separation", _s(12))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_ui.add_child(head)
	var ls := _s(58)
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color.WHITE
	bs.set_corner_radius_all(ls)
	bs.set_content_margin_all(_s(4))
	badge.add_theme_stylebox_override("panel", bs)
	badge.custom_minimum_size = Vector2(ls, ls)
	head.add_child(badge)
	if _logo_tex != null:
		var tr := TextureRect.new()
		tr.texture = _logo_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.add_child(tr)
	else:
		var fb := _label("KHTN", 15, Color("3a6fc0"))
		fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(fb)
	var sv := VBoxContainer.new()
	sv.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(sv)
	sv.add_child(_label(SCHOOL_1, 12, C_WHITE, 4))
	sv.add_child(_label(SCHOOL_2, 15, C_GOLD_LT, 4))

	# tên game: chữ to ở trên cùng
	var tb := VBoxContainer.new()
	tb.anchor_right = 1.0
	tb.anchor_top = 0.14
	tb.anchor_bottom = 0.40
	tb.alignment = BoxContainer.ALIGNMENT_CENTER
	tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_ui.add_child(tb)
	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", _s(28))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tb.add_child(title)
	var ta := _title_label(TITLE_A, C_WHITE)
	var tu := _title_label(TITLE_B, C_GOLD)
	title.add_child(ta)
	title.add_child(tu)
	_wobble(ta, 1.2)
	_wobble(tu, -1.6)
	var sub := _label(SUBTITLE, 22, C_GOLD_LT, 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tb.add_child(sub)
	var bar := ColorRect.new()
	bar.color = C_GOLD
	bar.custom_minimum_size = Vector2(_s(380), maxi(3, _s(4)))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tb.add_child(bar)

	# các chức năng: nằm chính giữa màn hình
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.anchor_top = 0.41
	cc.offset_top = 0
	cc.offset_bottom = -_s(56)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_ui.add_child(cc)
	var mp := PanelContainer.new()
	var mps := StyleBoxFlat.new()
	mps.bg_color = Color(C_DARK, 0.6)
	mps.border_width_top = _s(4)
	mps.border_width_bottom = _s(4)
	mps.border_color = C_GOLD
	mps.content_margin_left = _s(18)
	mps.content_margin_right = _s(18)
	mps.content_margin_top = _s(16)
	mps.content_margin_bottom = _s(16)
	mps.shadow_color = Color(0, 0, 0, 0.35)
	mps.shadow_size = _s(10)
	mp.add_theme_stylebox_override("panel", mps)
	cc.add_child(mp)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", _s(6))
	mp.add_child(_menu_box)

	var cont := _add_menu_button("Tiếp tục", func(): _start_game("continue"))   # không có cốt truyện, vào thẳng game
	cont.visible = FileAccess.file_exists(save_path)
	var new_btn := _add_menu_button("Chơi mới", _on_new_game)
	_add_menu_button("Cài đặt", func(): _show_panel("settings"))
	_add_menu_button("Hướng dẫn", func(): _show_panel("help"))
	_add_menu_button("Giới thiệu", func(): _show_panel("about"))
	_add_menu_button("Thoát", func(): _show_panel("quit"))
	_first_button = cont if cont.visible else new_btn


func _corner_label(text: String, size: float, outline: float, l: float, r: float, align: int, anchor_l: float, anchor_r: float) -> void:
	var lb := _label(text, size, C_WHITE, outline)
	lb.horizontal_alignment = align
	lb.anchor_left = anchor_l
	lb.anchor_right = anchor_r
	lb.anchor_top = 1.0
	lb.anchor_bottom = 1.0
	lb.offset_left = l
	lb.offset_right = r
	lb.offset_top = -_s(44)
	lb.offset_bottom = -_s(10)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_ui.add_child(lb)


func _build_footer() -> void:
	_corner_label("↑ ↓: chọn     Enter: xác nhận     Esc: quay lại     F11: toàn màn hình", 19, 6, _s(46), -_s(30), HORIZONTAL_ALIGNMENT_LEFT, 0.0, 1.0)
	_corner_label(VERSION, 18, 5, -_s(120), -_s(24), HORIZONTAL_ALIGNMENT_RIGHT, 1.0, 1.0)


# ============================================================ BẢNG PHỤ
func _body_label(text: String) -> Label:
	var l := _label(text, 21)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _make_panel(id: String, title_text: String, content: Control, show_back: bool = true, focus_btn: Button = null) -> void:
	var overlay := CenterContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_s(600), 0)
	panel.add_theme_stylebox_override("panel", _pbox(C_NAVY, C_GOLD, 4, 32, 26))
	overlay.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", _s(16))
	panel.add_child(vb)
	var t := _label(title_text, 40, C_GOLD, 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var line := ColorRect.new()
	line.color = C_EDGE
	line.custom_minimum_size = Vector2(0, maxi(2, _s(3)))
	vb.add_child(line)
	vb.add_child(content)
	var focus_target := focus_btn
	if show_back:
		var back := Button.new()
		back.text = "Quay lại"
		back.custom_minimum_size = Vector2(0, _s(46))
		_style_button(back, 20)
		back.pressed.connect(_show_menu)
		vb.add_child(back)
		focus_target = back
	_panels[id] = overlay
	_panel_focus[id] = focus_target


func _build_panels() -> void:
	# --- Cài đặt ---
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", _s(14))
	var row := HBoxContainer.new()
	vb.add_child(row)
	var l1 := _label("Âm lượng", 22)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l1)
	var vol0 := float(_cfg.get_value("audio", "volume", 0.8))
	_vol_label = _label("%d%%" % int(round(vol0 * 100.0)), 22, C_GOLD)
	row.add_child(_vol_label)

	_vol_slider = HSlider.new()
	_vol_slider.max_value = 1.0
	_vol_slider.step = 0.05
	_vol_slider.set_value_no_signal(vol0)
	_vol_slider.custom_minimum_size = Vector2(0, _s(30))
	var sl := StyleBoxFlat.new()
	sl.bg_color = C_DARK
	sl.set_border_width_all(maxi(2, _s(2)))
	sl.border_color = C_EDGE
	sl.content_margin_top = _s(5)
	sl.content_margin_bottom = _s(5)
	var ga := StyleBoxFlat.new()
	ga.bg_color = C_GOLD
	ga.content_margin_top = _s(5)
	ga.content_margin_bottom = _s(5)
	_vol_slider.add_theme_stylebox_override("slider", sl)
	_vol_slider.add_theme_stylebox_override("grabber_area", ga)
	_vol_slider.add_theme_stylebox_override("grabber_area_highlight", ga)
	_vol_slider.value_changed.connect(_on_volume_changed)
	vb.add_child(_vol_slider)

	_fs_check = CheckBox.new()
	_fs_check.text = "Toàn màn hình  (F11)"
	_fs_check.set_pressed_no_signal(bool(_cfg.get_value("video", "fullscreen", false)))
	_fs_check.add_theme_font_size_override("font_size", _s(22))
	_fs_check.toggled.connect(func(on: bool):
		_set_fullscreen(on)
		_queue_save())
	vb.add_child(_fs_check)

	_make_panel("settings", "Cài đặt", vb)

	# --- Hướng dẫn / Giới thiệu ---
	_make_panel("help", "Hướng dẫn", _body_label("W A S D  :  di chuyển\nE  :  tương tác\nTab  :  mở sổ tay\nEsc  :  tạm dừng\n\nMục tiêu: sống sót một ngày ở HCMUS - đi học đúng giờ, giữ GPA, rèn luyện và cân đối tiền bạc."))
	var about := "Daily US\n%s\n\nPhiên bản %s  -  Làm bằng Godot Engine" % [SUBTITLE, VERSION]
	if not team_members.is_empty():
		about += "\n\nNhóm thực hiện:\n" + "\n".join(team_members)
	if team_class != "":
		about += "\n\n" + team_class
	_make_panel("about", "Giới thiệu", _body_label(about))

	# --- Thoát ---
	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", _s(20))
	qv.add_child(_body_label("Bạn có chắc muốn thoát game không?"))
	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override("separation", _s(14))
	qv.add_child(qrow)
	var stay: Button
	for spec in [["Ở lại", true, _show_menu], ["Thoát", false, func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = spec[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, _s(48))
		_style_button(b, 20, spec[1])
		b.pressed.connect(spec[2])
		qrow.add_child(b)
		if spec[1]:
			stay = b
	_make_panel("quit", "Thoát game", qv, false, stay)


# ============================================================ CỐT TRUYỆN (chỉ khi Chơi mới)
func _build_story() -> void:
	_story_layer = Control.new()
	_story_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_layer.visible = false
	_story_layer.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_story_advance())
	add_child(_story_layer)

	var skip := _label("Esc: bỏ qua", 19, C_WHITE, 6)
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -_s(260)
	skip.offset_right = -_s(26)
	skip.anchor_top = 1.0
	skip.anchor_bottom = 1.0
	skip.offset_top = -_s(52)
	skip.offset_bottom = -_s(18)
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(skip)

	_story_keys = HBoxContainer.new()
	_story_keys.alignment = BoxContainer.ALIGNMENT_CENTER
	_story_keys.add_theme_constant_override("separation", _s(18))
	_story_keys.anchor_left = 0.06
	_story_keys.anchor_right = 0.94
	_story_keys.anchor_top = 0.40
	_story_keys.anchor_bottom = 0.60
	_story_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(_story_keys)

	var box := PanelContainer.new()
	box.anchor_left = 0.06
	box.anchor_right = 0.94
	box.anchor_top = 0.05
	box.anchor_bottom = 0.34
	box.add_theme_stylebox_override("panel", _pbox(C_NAVY, C_GOLD, 4, 30, 18))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", _s(10))
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vb)

	_story_speaker = _label("", 20, C_NAVY)
	_story_speaker.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_story_speaker.add_theme_stylebox_override("normal", _pbox(C_GOLD, C_GOLD_LT, 3, 14, 4, false))
	vb.add_child(_story_speaker)

	_story_text = _label("", 24)
	_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_story_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_story_text)

	_story_hint = _label("", 16, C_GOLD_LT)
	_story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_story_hint)


func _keycap(key_text: String, desc: String) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _pbox(C_NAVY2, C_GOLD, 3, 20, 12))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", _s(4))
	pc.add_child(vb)
	var k := _label(key_text, 30, C_GOLD, 6)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(k)
	var d := _label(desc, 18)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(d)
	return pc


func _play_story(pages: Array, done: Callable) -> void:
	if _story_layer == null:
		_build_story()
	_story_pages = pages
	_story_idx = 0
	_story_done = done
	get_viewport().gui_release_focus()
	_set_menu_focus(false)
	_menu_ui.visible = false
	_dim.visible = false
	_story_layer.visible = true
	if _blink == null:
		_blink = create_tween().set_loops()
		_blink.tween_property(_story_hint, "modulate:a", 0.25, 0.6)
		_blink.tween_property(_story_hint, "modulate:a", 1.0, 0.6)
	_show_story_page()


func _show_story_page() -> void:
	var pg: Dictionary = _story_pages[_story_idx]
	var txt: String = pg.get("text", "")
	_story_speaker.text = str(pg.get("who", ""))
	_story_text.text = txt
	_story_text.visible_ratio = 0.0
	_story_hint.text = "Nhấn Enter để bắt đầu!" if _story_idx >= _story_pages.size() - 1 else "Nhấn Enter / Space / Click để tiếp tục"
	for c in _story_keys.get_children():
		c.queue_free()
	if pg.has("keys"):
		for k in pg["keys"]:
			_story_keys.add_child(_keycap(str(k[0]), str(k[1])))
	_story_typing = true
	_story_last_chars = 0
	if _tick_player == null:
		_setup_type_tick()
	if _story_tween:
		_story_tween.kill()
	_story_tween = create_tween()
	_story_tween.tween_method(_on_story_type_step.bind(txt), 0.0, 1.0, maxf(0.3, txt.length() * 0.028))
	_story_tween.finished.connect(func(): _story_typing = false)


func _on_story_type_step(ratio: float, txt: String) -> void:
	_story_text.visible_ratio = ratio
	var chars := int(floor(ratio * float(txt.length())))
	if chars > _story_last_chars:
		_story_last_chars = chars
		if chars > 0 and chars <= txt.length():
			var ch := txt.substr(chars - 1, 1)
			if ch != " " and ch != "\n" and ch != "\t":
				_play_type_tick()


func _setup_type_tick() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 11025.0
	gen.buffer_length = 0.1
	_tick_player = AudioStreamPlayer.new()
	_tick_player.stream = gen
	add_child(_tick_player)
	var n := int(gen.mix_rate * 0.022)
	_tick_data.resize(n)
	for i in n:
		var env := 1.0 - float(i) / float(n)
		var smp := sin(TAU * 860.0 * float(i) / gen.mix_rate) * 0.15 * env * env
		_tick_data[i] = Vector2(smp, smp)


func _play_type_tick() -> void:
	if _tick_player == null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_tick_ms < 48:
		return
	_last_tick_ms = now
	if not _tick_player.playing:
		_tick_player.play()
	var pb := _tick_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb != null and pb.can_push_buffer(_tick_data.size()):
		pb.push_buffer(_tick_data)


func _story_advance() -> void:
	if _story_typing:
		if _story_tween:
			_story_tween.kill()
		_story_text.visible_ratio = 1.0
		_story_typing = false
		return
	_story_idx += 1
	if _story_idx >= _story_pages.size():
		_end_story()
	else:
		_show_story_page()


func _end_story() -> void:
	if _starting:
		return
	if _story_tween:
		_story_tween.kill()
	_story_done.call()


# ============================================================ ĐIỀU HƯỚNG
func _set_menu_focus(on: bool) -> void:
	for b in _buttons:
		b.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE


func _show_menu() -> void:
	for p in _panels.values():
		p.visible = false
	_dim.visible = false
	_set_menu_focus(true)
	if _first_button:
		_first_button.grab_focus()


func _show_panel(id: String) -> void:
	_ensure_panels()
	_dim.visible = true
	_set_menu_focus(false)
	for k in _panels:
		_panels[k].visible = (k == id)
	var overlay: Control = _panels[id]
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.15)
	var fb: Button = _panel_focus[id]
	if fb:
		fb.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _story_layer != null and _story_layer.visible:
		if event.is_action_pressed("ui_cancel"):
			_end_story()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_story_advance()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and _dim.visible:
		_show_menu()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_ensure_panels()
		_fs_check.button_pressed = not _fs_check.button_pressed
		get_viewport().set_input_as_handled()


# ============================================================ HÀNH ĐỘNG
func _on_new_game() -> void:
	_preload_game()   # tải game ngầm trong lúc người chơi đọc cốt truyện
	_play_story(STORY_NEW, func():
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		_start_game("new"))


func _preload_game() -> void:
	if not _game_requested and ResourceLoader.exists(game_scene):
		_game_requested = true
		ResourceLoader.load_threaded_request(game_scene)


func _start_game(mode: String) -> void:
	if _starting:
		return
	if not ResourceLoader.exists(game_scene):
		push_error("Không tìm thấy scene game: %s (chỉnh 'Game Scene' ở Inspector của MainMenu)" % game_scene)
		return
	_starting = true
	Engine.set_meta("daily_us_start_mode", mode)   # game đọc: Engine.get_meta("daily_us_start_mode")
	_preload_game()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	await tw.finished
	var packed := ResourceLoader.load_threaded_get(game_scene) as PackedScene
	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(game_scene)


func _set_volume(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(bus, v <= 0.0)
	if _vol_label != null:
		_vol_label.text = "%d%%" % int(round(v * 100.0))


func _on_volume_changed(v: float) -> void:
	_set_volume(v)
	var now := Time.get_ticks_msec()
	if v > 0.0 and now - _last_beep > 200:
		_last_beep = now
		_beep.play()
		(_beep.get_stream_playback() as AudioStreamGeneratorPlayback).push_buffer(_beep_data)
	_queue_save()


func _set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


# ============================================================ ÂM THANH THỬ (tạo sẵn 1 lần)
func _setup_beep() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 11025.0
	gen.buffer_length = 0.2
	_beep = AudioStreamPlayer.new()
	_beep.stream = gen
	add_child(_beep)
	var n := int(gen.mix_rate * 0.1)
	_beep_data.resize(n)
	for i in n:
		var smp := sin(TAU * 660.0 * float(i) / gen.mix_rate) * 0.35 * (1.0 - float(i) / float(n))
		_beep_data[i] = Vector2(smp, smp)


# ============================================================ LƯU CÀI ĐẶT (gộp, không ghi đĩa mỗi lần kéo)
func _queue_save() -> void:
	_cfg.set_value("audio", "volume", _vol_slider.value)
	_cfg.set_value("video", "fullscreen", _fs_check.button_pressed)
	_save_timer.start()


func _apply_settings() -> void:
	_set_volume(float(_cfg.get_value("audio", "volume", 0.8)))
	if bool(_cfg.get_value("video", "fullscreen", false)):
		_set_fullscreen(true)


# ============================================================ HIỆU ỨNG VÀO
func _intro_animation() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.6)
	for i in _buttons.size():
		_buttons[i].modulate.a = 0.0
		tw.tween_property(_buttons[i], "modulate:a", 1.0, 0.25).set_delay(0.25 + i * 0.07)
