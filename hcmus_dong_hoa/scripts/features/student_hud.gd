extends "res://scripts/features/feature.gd"
# HUD sinh vien: thong tin can thiet, lich hoc, dong ho va nhan minimap.
# Chi sua giao dien trong feature; khong thay doi nhan vat, NPC hay ban do.
#
# GHI CHU KY THUAT (ban nang cap):
#  - Toan bo panel, thanh bar va chu duoc VE TRUC TIEP trong _on_draw() cua mot Control.
#    Truoc day chu dung Label; Label tu nong chieu cao theo font (tieng Viet co dau) nen
#    chu bi lech xuong va tran ra ngoai khung. Ve bang draw_string thi vi tri chinh xac.
#  - Chu tu thu nho / cat "..." neu qua rong, nen khong bao gio tran khung.

const Schedule := preload("res://scripts/features/schedule_data.gd")

const POPUP_TIME := 1.8
const PANEL_BG := Color(0.035, 0.075, 0.14, 0.96)
const PANEL_BORDER := Color("6d89ad")
const TEXT_MAIN := Color("f4f7ff")
const TEXT_MUTED := Color("b7c7dd")
const ACCENT := Color("75c8ff")
const GOLD := Color("ffdc75")
const GREEN := Color("42d879")
const AMBER := Color("ffb347")
const RED := Color("ff6b6b")
const BAR_BG := Color("101b2d")
const DIVIDER := Color(0.55, 0.72, 0.92, 0.22)

# Toa do tinh theo viewport goc 480 x 270 cua project.
const STATS_PANEL := Rect2(6, 5, 108, 31)
const SCHEDULE_PANEL := Rect2(6, 74, 108, 24)
const CLOCK_PANEL := Rect2(404, 5, 70, 15)
const MAP_TITLE_PANEL := Rect2(356, 38, 43, 9)

# Vi tri minimap do game goc ve (dung de dat chu cai toa nha).
const MINIMAP_ORIGIN := Vector2(356, 55)
const MINIMAP_WIDTH := 108.0

var debug_keys := true
var doors: Node            # building_doors.gd: biet nguoi choi dang o trong toa nha hay khong
var hud_hidden := false    # phim H: an han cac khung goc trai
var stats: Node
var wallet: Node
var font: Font
var canvas: Control
var popups: Array = []
var _style_cache: Dictionary = {}
# Gia tri hien thi cua thanh bar (muot dan toi gia tri that).
var _drl_shown := 0.0
var _gpa_shown := 0.0

func _ready() -> void:
	stats = game.stats
	font = game.font
	if stats != null and stats.has_signal("drl_changed"):
		stats.drl_changed.connect(_on_drl_changed)
	if stats != null and stats.has_signal("money_changed"):
		stats.money_changed.connect(_on_money_changed)
	_connect_wallet()
	_build_hud()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)

	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(canvas)
	canvas.draw.connect(_on_draw)
	if stats != null:
		_drl_shown = clampf(float(stats.drl_ratio()), 0.0, 1.0)
		_gpa_shown = clampf(float(stats.gpa_ratio()), 0.0, 1.0)

# ---------------------------------------------------------------------------
# Ham ve dung chung
# ---------------------------------------------------------------------------

func _flat_style(background: Color, border: Color, radius: int, shadow := true) -> StyleBoxFlat:
	var key := "%s|%s|%d|%s" % [background.to_html(true), border.to_html(true), radius, str(shadow)]
	if _style_cache.has(key):
		return _style_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0, 0, 0, 0.26)
		style.shadow_size = 2
		style.shadow_offset = Vector2(0, 1)
	style.set_content_margin_all(0)
	_style_cache[key] = style
	return style

func _draw_panel(rect: Rect2, background: Color, border: Color, radius: int) -> void:
	canvas.draw_style_box(_flat_style(background, border, radius), rect)

func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	canvas.draw_style_box(_flat_style(BAR_BG, Color(1, 1, 1, 0.08), 3, false), rect)
	var inner := rect.grow(-1.0)
	var width := inner.size.x * clampf(ratio, 0.0, 1.0)
	if width < 1.0:
		return
	# Do rong toi thieu bang chieu cao de bo goc khong bi meo.
	width = maxf(width, minf(inner.size.y, inner.size.x))
	canvas.draw_style_box(_flat_style(fill_color, Color(0, 0, 0, 0), 2, false), Rect2(inner.position, Vector2(width, inner.size.y)))

func _text_width(text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x

func _fit_text(text: String, width: float, size: int) -> String:
	if _text_width(text, size) <= width:
		return text
	var cut := text
	while cut.length() > 1 and _text_width(cut + "...", size) > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "..."

# Ve chu canh giua theo chieu doc trong rect. min_size < size cho phep tu thu nho chu truoc khi cat.
func _draw_text(text: String, rect: Rect2, color: Color, size := 6, align := HORIZONTAL_ALIGNMENT_LEFT, min_size := 0) -> void:
	var use_size := size
	var floor_size := min_size if min_size > 0 else size
	while use_size > floor_size and _text_width(text, use_size) > rect.size.x:
		use_size -= 1
	var shown := _fit_text(text, rect.size.x, use_size)
	var base := Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + float(use_size) * 0.36)
	canvas.draw_string(font, base + Vector2(1, 1), shown, align, rect.size.x, use_size, Color(0, 0, 0, 0.72))
	canvas.draw_string(font, base, shown, align, rect.size.x, use_size, color)

func _ratio_color(ratio: float, base: Color) -> Color:
	if ratio < 0.35:
		return RED
	if ratio < 0.6:
		return AMBER
	return base

# ---------------------------------------------------------------------------
# Du lieu
# ---------------------------------------------------------------------------

func _connect_wallet() -> void:
	if is_instance_valid(wallet) or stats == null:
		return
	for feature in game.features:
		if feature != self and feature.has_method("get_wallet_text") and feature.has_method("set_wallet_balance"):
			wallet = feature
			if stats.has_method("bind_wallet"):
				stats.call("bind_wallet", wallet)
			return

func _process(delta: float) -> void:
	_connect_wallet()
	for popup in popups:
		popup.t -= delta
	popups = popups.filter(func(popup): return popup.t > 0.0)
	if stats != null:
		var follow := minf(1.0, delta * 8.0)
		_drl_shown = lerpf(_drl_shown, clampf(float(stats.drl_ratio()), 0.0, 1.0), follow)
		_gpa_shown = lerpf(_gpa_shown, clampf(float(stats.gpa_ratio()), 0.0, 1.0), follow)
	if is_instance_valid(canvas):
		canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not debug_keys or stats == null:
		return
	# Khong kich hoat phim tat khi dang go chu hoac dang lam quiz.
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	if game.has_method("is_busy") and game.is_busy():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				hud_hidden = not hud_hidden
			KEY_1:
				stats.add_drl(1, "Đi học đúng giờ")
			KEY_2:
				stats.add_drl(-2, "Đi học trễ")
			KEY_3:
				stats.add_drl(5, "Hoạt động tình nguyện")
			KEY_4:
				game.skip_days(1)
			KEY_5:
				game.skip_days(7)

func _on_drl_changed(amount: int, reason: String) -> void:
	var text := "%s%d" % ["+" if amount > 0 else "-", absi(amount)]
	if reason != "":
		text += " " + reason
	_add_popup(text, Color(0.45, 1.0, 0.45) if amount > 0 else Color(1.0, 0.4, 0.4))

func _on_money_changed(amount: int, reason: String) -> void:
	var text := "%s%s" % ["+" if amount > 0 else "-", _format_money(absi(amount))]
	if reason != "":
		text += " " + reason
	_add_popup(text, Color("ffe28a") if amount > 0 else Color("ff9c8b"))

func _format_money(amount: int) -> String:
	var digits := str(maxi(amount, 0))
	var parts := ""
	while digits.length() > 3:
		parts = "." + digits.right(3) + parts
		digits = digits.substr(0, digits.length() - 3)
	return digits + parts + "đ"

func _add_popup(text: String, color: Color) -> void:
	while popups.size() >= 3:
		popups.pop_front()
	popups.append({"text": text, "color": color, "t": POPUP_TIME})

# ---------------------------------------------------------------------------
# Ve HUD
# ---------------------------------------------------------------------------

func _on_draw() -> void:
	var indoors := _is_indoors()
	if not hud_hidden:
		if indoors:
			_draw_stats_compact()
		else:
			_draw_stats()
			_draw_schedule()
	_draw_clock()
	_draw_popups()
	# Minimap chi co ngoai troi: trong phong khong ve chu cai toa nha va tieu de ban do.
	if not indoors:
		_draw_map_title()
		_draw_minimap_letters()

func _is_indoors() -> bool:
	# Bat ky module nao co bien "inside" dang true (building_doors, giang duong trong scripts/maps...).
	for feature in game.features:
		if feature != self and is_instance_valid(feature) and feature.get("inside") != null and bool(feature.get("inside")):
			return true
	return false

# Trong phong hoc: chi hien mot thanh nho de khong che goc tren ben trai.
func _draw_stats_compact() -> void:
	var rect := Rect2(6, 4, 98, 9)
	_draw_panel(rect, Color(0.035, 0.075, 0.14, 0.82), PANEL_BORDER, 4)
	var drl_text := "-"
	var gpa_text := "-"
	if stats != null:
		drl_text = str(stats.drl_text())
		gpa_text = str(stats.gpa_text())
	_draw_text("RL " + drl_text, Rect2(9, 4, 46, 9), TEXT_MAIN, 4)
	_draw_text("GPA " + gpa_text.get_slice("/", 0), Rect2(58, 4, 44, 9), TEXT_MAIN, 4)

func _draw_stats() -> void:
	_draw_panel(STATS_PANEL, PANEL_BG, PANEL_BORDER, 6)
	var drl_text := "..."
	var gpa_text := "..."
	if stats != null:
		drl_text = str(stats.drl_text())
		gpa_text = str(stats.gpa_text())
	var top := STATS_PANEL.position.y
	var row1 := top + 7.5
	var row2 := top + 16.0
	_draw_text("Rèn luyện", Rect2(10, row1 - 4, 32, 8), TEXT_MAIN, 5, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_draw_bar(Rect2(44, row1 - 2, 26, 4), _drl_shown, _ratio_color(_drl_shown, GREEN))
	_draw_text(drl_text, Rect2(73, row1 - 4, 38, 8), TEXT_MAIN, 5, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_draw_text("GPA", Rect2(10, row2 - 4, 32, 8), TEXT_MAIN, 5)
	_draw_bar(Rect2(44, row2 - 2, 26, 4), _gpa_shown, ACCENT)
	_draw_text(gpa_text, Rect2(73, row2 - 4, 38, 8), TEXT_MAIN, 5, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var divider_y := top + 21.5
	canvas.draw_line(Vector2(10, divider_y), Vector2(STATS_PANEL.end.x - 4, divider_y), DIVIDER, 1.0)
	var wallet_text := "Ví: Chưa khả dụng"
	if stats != null:
		wallet_text = "Ví: " + _format_money(int(stats.get("money")))
	_draw_text(wallet_text, Rect2(10, divider_y + 0.5, 100, 8), GOLD, 5, HORIZONTAL_ALIGNMENT_LEFT, 4)

func _draw_schedule() -> void:
	_draw_panel(SCHEDULE_PANEL, Color(0.035, 0.075, 0.14, 0.94), Color("536f94"), 5)
	var top := SCHEDULE_PANEL.position.y
	_draw_text("LỊCH HỌC", Rect2(10, top + 1.0, 60, 7), ACCENT, 4)
	var next_text := Schedule.next_class_text(game.day, game.game_min)
	var exam_text := Schedule.exam_text(Schedule.week_no(game.day))
	_draw_text(next_text, Rect2(10, top + 8.5, 100, 7), TEXT_MAIN, 4, HORIZONTAL_ALIGNMENT_LEFT, 3)
	_draw_text(exam_text, Rect2(10, top + 15.5, 100, 7), GOLD, 4, HORIZONTAL_ALIGNMENT_LEFT, 3)

func _draw_clock() -> void:
	_draw_panel(CLOCK_PANEL, PANEL_BG, PANEL_BORDER, 6)
	var minute := int(game.game_min)
	var date_text := "%s · T%d" % [Schedule.DAY_NAMES[Schedule.weekday(game.day)], Schedule.week_no(game.day)]
	_draw_text(date_text, Rect2(408, CLOCK_PANEL.position.y, 33, CLOCK_PANEL.size.y), TEXT_MUTED, 4, HORIZONTAL_ALIGNMENT_LEFT, 3)
	var time_text := "%02d:%02d" % [int(minute / 60.0), minute % 60]
	_draw_text(time_text, Rect2(441, CLOCK_PANEL.position.y, 29, CLOCK_PANEL.size.y), TEXT_MAIN, 6, HORIZONTAL_ALIGNMENT_RIGHT, 5)

func _draw_map_title() -> void:
	_draw_panel(MAP_TITLE_PANEL, PANEL_BG, Color("7897bd"), 5)
	_draw_text("BẢN ĐỒ", MAP_TITLE_PANEL, TEXT_MAIN, 5, HORIZONTAL_ALIGNMENT_CENTER, 4)

func _draw_popups() -> void:
	for i in popups.size():
		var popup: Dictionary = popups[i]
		var life := clampf(float(popup.t) / POPUP_TIME, 0.0, 1.0)
		var alpha := minf(1.0, life * 2.5)
		var color: Color = popup.color
		var text := _fit_text(str(popup.text), 170.0, 5)
		var width := _text_width(text, 5) + 8.0
		# Truot nhe tu duoi len khi moi xuat hien.
		var slide := (1.0 - minf(1.0, (POPUP_TIME - float(popup.t)) * 8.0)) * 3.0
		var rect := Rect2(120.0, 6.0 + i * 10.0 + slide, width, 9.0)
		canvas.draw_style_box(_flat_style(Color(0.02, 0.05, 0.1, 0.78 * alpha), Color(color.r, color.g, color.b, 0.55 * alpha), 4, false), rect)
		var base := Vector2(rect.position.x + 4.0, rect.position.y + rect.size.y * 0.5 + 1.8)
		canvas.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 5, Color(color.r, color.g, color.b, alpha))

func _draw_minimap_letters() -> void:
	var map_scale: float = MINIMAP_WIDTH / float(game.WORLD.x)
	for building in game.BUILDINGS:
		var building_name := str(building[0])
		if building_name.length() != 1:
			continue
		var cx: float = MINIMAP_ORIGIN.x + (float(building[1]) + float(building[3]) * 0.5) * map_scale
		var cy: float = MINIMAP_ORIGIN.y + (float(building[2]) + float(building[4]) * 0.5) * map_scale
		canvas.draw_string_outline(font, Vector2(cx - 5.0, cy + 2.5), building_name, HORIZONTAL_ALIGNMENT_CENTER, 10.0, 7, 1, Color(0, 0, 0, 0.8))
		canvas.draw_string(font, Vector2(cx - 5.0, cy + 2.5), building_name, HORIZONTAL_ALIGNMENT_CENTER, 10.0, 7, Color.WHITE)
