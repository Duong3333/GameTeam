extends "res://scripts/features/feature.gd"
# CÂY RÚT TIỀN TỰ ĐỘNG ATM HCMUS — Module bản đồ riêng (scripts/maps/atm.gd)
# Đặt tại lối đi bộ trước Tòa C, chuẩn buồng ATM ngân hàng hiện đại tại cơ sở Linh Trung.
#
# Tính năng:
#   - Buồng ATM kính cường lực hiện đại, có hộp đèn biển hiệu "ATM" phát sáng.
#   - Đến gần bấm [E]: mở giao diện máy ATM rút tiền, nạp tiền, nhận học bổng sinh viên.
#   - Tự động liên kết và đồng bộ ví tiền người chơi với Căn tin & game.

const BOOTH_POS   := Vector2(540.0, 782.0)
const BOOTH_SIZE  := Vector2(36.0, 40.0)
const BOOTH_RECT  := Rect2(BOOTH_POS, BOOTH_SIZE)
const PROMPT_DIST := 32.0

# ─── GIAO DIỆN & TRẠNG THÁI ────────────────────────────────────────────────
var _ui_layer: CanvasLayer
var _panel_root: Control
var _lbl_title: Label
var _lbl_info: Label
var _lbl_balance: Label
var _lbl_msg: Label
var _btn_container: GridContainer
var _msg_timer: float = 0.0

# Tài khoản ngân hàng sinh viên
var bank_balance: int = 15000000 # 15 triệu đồng trong thẻ
var _has_received_scholarship: bool = false

func _ready() -> void:
	# Thêm va chạm để người chơi không đi xuyên qua buồng ATM
	if game != null and "solids" in game:
		game.solids.append(BOOTH_RECT)
	_build_ui()

func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0 and _lbl_msg != null:
			_lbl_msg.text = ""

	if not active:
		if not game.is_busy() and _is_player_near():
			# Người chơi đứng gần có thể bấm E
			pass
	else:
		_update_ui_balance()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		if not game.is_busy() and _is_player_near():
			if event is InputEventKey and event.pressed and not event.echo:
				if event.keycode == KEY_E:
					_open_atm()
					get_viewport().set_input_as_handled()
	else:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_ESCAPE, KEY_E:
					_close_atm()
					get_viewport().set_input_as_handled()
				KEY_1:
					_withdraw(50000)
					get_viewport().set_input_as_handled()
				KEY_2:
					_withdraw(100000)
					get_viewport().set_input_as_handled()
				KEY_3:
					_withdraw(200000)
					get_viewport().set_input_as_handled()
				KEY_4:
					_withdraw(500000)
					get_viewport().set_input_as_handled()
				KEY_5:
					_withdraw(1000000)
					get_viewport().set_input_as_handled()
				KEY_6:
					_deposit(200000)
					get_viewport().set_input_as_handled()
				KEY_7:
					_claim_scholarship()
					get_viewport().set_input_as_handled()

func _is_player_near() -> bool:
	if game == null or not ("player" in game):
		return false
	var booth_center := BOOTH_RECT.get_center() + Vector2(0, 10)
	return game.player.distance_to(booth_center) < PROMPT_DIST

# ─── MỞ / ĐÓNG ATM ─────────────────────────────────────────────────────────
func _open_atm() -> void:
	begin()
	_update_ui_balance()
	if _lbl_msg != null:
		_lbl_msg.text = "Chào mừng bạn đến với HCMUS Bank ATM!"
		_lbl_msg.modulate = Color("8fc9e6")
	_ui_layer.visible = true
	_play_sound("buy")

func _close_atm() -> void:
	_ui_layer.visible = false
	finish()
	_play_sound("cancel")

# ─── VẼ BUỒNG ATM LÊN BẢN ĐỒ ──────────────────────────────────────────────
func draw_front_layer() -> void:
	if game == null:
		return
	var bx := BOOTH_RECT.position.x
	var by := BOOTH_RECT.position.y
	var bw := BOOTH_RECT.size.x
	var bh := BOOTH_RECT.size.y

	# Chỉ vẽ khi nằm trong khung nhìn
	if "view" in game and not game.view.intersects(BOOTH_RECT.grow(50.0)):
		return

	# 1. Bóng đổ dưới chân buồng
	game.draw_rect(Rect2(bx - 2, by + bh - 2, bw + 4, 8), Color(0, 0, 0, 0.28))

	# 2. Bậc thềm đá hoa cương xám
	game.draw_rect(Rect2(bx - 3, by + bh - 4, bw + 6, 6), Color("505860"))
	game.draw_rect(Rect2(bx - 2, by + bh - 4, bw + 4, 2), Color("788088"))

	# 3. Thân buồng ATM: vách kim loại + kính cường lực
	game.draw_rect(Rect2(bx, by + 10, bw, bh - 14), Color("2b3842")) # khung nhôm đen
	# Vách kính cường lực xanh ngọc phản quang
	game.draw_rect(Rect2(bx + 2, by + 12, bw - 4, bh - 18), Color("3d8c82", 0.85))
	# Vệt sáng phản chiếu trên kính
	game.draw_line(Vector2(bx + 5, by + 14), Vector2(bx + 16, by + bh - 10), Color(1, 1, 1, 0.3), 1.5)

	# 4. Máy ATM bên trong buồng kính
	var mx := bx + 7.0
	var my := by + 15.0
	var mw := bw - 14.0
	# Thân cây máy
	game.draw_rect(Rect2(mx, my, mw, bh - 20), Color("808a94"))
	# Màn hình LCD phát sáng xanh dương
	game.draw_rect(Rect2(mx + 2, my + 3, mw - 4, 9), Color("1565c0"))
	game.draw_rect(Rect2(mx + 3, my + 4, mw - 6, 3), Color("64b5f6", 0.7))
	# Bàn phím số kim loại
	game.draw_rect(Rect2(mx + 3, my + 14, mw - 6, 4), Color("3a4048"))
	for dot in 3:
		game.draw_rect(Rect2(mx + 5 + dot * 4, my + 15, 2, 2), Color("d0d8e0"))
	# Khe nhét thẻ phát sáng xanh lá
	game.draw_rect(Rect2(mx + mw - 5, my + 10, 3, 1.5), Color("2ecc71"))
	# Khe trả tiền phía dưới
	game.draw_rect(Rect2(mx + 4, my + 19, mw - 8, 2), Color("1a1a1a"))

	# 5. Khung cửa và cột bo góc buồng
	game.draw_rect(Rect2(bx, by + 10, 2, bh - 14), Color("8a94a0"))
	game.draw_rect(Rect2(bx + bw - 2, by + 10, 2, bh - 14), Color("8a94a0"))

	# 6. HỘP ĐÈN BIỂN HIỆU TRÊN NÓC (Biển hiệu ATM Agribank/Vietcombank đỏ/xanh chuẩn)
	var sign_h := 13.0
	game.draw_rect(Rect2(bx - 2, by, bw + 4, sign_h), Color("c02828")) # nền đỏ ngân hàng
	game.draw_rect(Rect2(bx - 2, by, bw + 4, 2), Color("e74c3c"))     # viền sáng trên
	game.draw_rect(Rect2(bx - 2, by + sign_h - 1, bw + 4, 1), Color("8a1a1a")) # viền dưới
	# Viền vàng kim 2 bên
	game.draw_rect(Rect2(bx - 2, by, 2, sign_h), Color("f1c40f"))
	game.draw_rect(Rect2(bx + bw + 2, by, 2, sign_h), Color("f1c40f"))

	# Vẽ chữ "ATM" pixel art màu trắng sắc sảo ở giữa biển
	var ax := bx + 7.0
	var ay := by + 2.5
	_draw_pixel_atm_logo(ax, ay)


	# 8. Prompt tương tác [E] khi người chơi đứng gần
	if not active and _is_player_near() and not game.is_busy():
		var prompt_pos := Vector2(bx + bw * 0.5, by - 8.0)
		var pw := 52.0
		var ph := 14.0
		# Bong bóng thoại bo góc
		game.draw_rect(Rect2(prompt_pos.x - pw * 0.5, prompt_pos.y - ph, pw, ph), Color(0.1, 0.15, 0.22, 0.92))
		game.draw_rect(Rect2(prompt_pos.x - pw * 0.5, prompt_pos.y - ph, pw, ph), Color("8fc9e6"), false, 1.0)
		# Mũi nhọn chỉ xuống
		var tri := PackedVector2Array([
			Vector2(prompt_pos.x - 4, prompt_pos.y),
			Vector2(prompt_pos.x + 4, prompt_pos.y),
			Vector2(prompt_pos.x, prompt_pos.y + 3)
		])
		game.draw_colored_polygon(tri, Color(0.1, 0.15, 0.22, 0.92))
		# Text [E] Máy ATM
		if "font" in game and game.font != null:
			game.draw_string(game.font, Vector2(prompt_pos.x - 22, prompt_pos.y - 3), "[E] Máy ATM", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)

# ─── VẼ CHỮ "ATM" PIXEL ART ────────────────────────────────────────────────
func _draw_pixel_atm_logo(x: float, y: float) -> void:
	var c := Color.WHITE
	var S := 1.5

	# 'A' (5x6)
	var A_dots := [[1,0],[2,0],[3,0],[0,1],[4,1],[0,2],[1,2],[2,2],[3,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5]]
	for d in A_dots:
		game.draw_rect(Rect2(x + d[0] * S, y + d[1] * S, S, S), c)

	# 'T' (5x6)
	var tx := x + 6.0 * S + 2.0
	var T_dots := [[0,0],[1,0],[2,0],[3,0],[4,0],[2,1],[2,2],[2,3],[2,4],[2,5]]
	for d in T_dots:
		game.draw_rect(Rect2(tx + d[0] * S, y + d[1] * S, S, S), c)

	# 'M' (5x6)
	var mx := tx + 6.0 * S + 2.0
	var M_dots := [[0,0],[4,0],[0,1],[1,1],[3,1],[4,1],[0,2],[2,2],[4,2],[0,3],[4,3],[0,4],[4,4],[0,5],[4,5]]
	for d in M_dots:
		game.draw_rect(Rect2(mx + d[0] * S, y + d[1] * S, S, S), c)

# ─── TẠO GIAO DIỆN MÀN HÌNH MÁY ATM (UI) ──────────────────────────────────
func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 12
	_ui_layer.visible = false
	add_child(_ui_layer)

	# Nền làm mờ toàn màn hình
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.55)
	_ui_layer.add_child(backdrop)

	# Khung máy ATM trung tâm
	_panel_root = Panel.new()
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -175.0
	_panel_root.offset_right  =  175.0
	_panel_root.offset_top    = -125.0
	_panel_root.offset_bottom =  125.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d2338") # xanh dương đậm màn hình ATM
	style.border_color = Color("2e7cb8") # viền xanh kim loại
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panel_root.add_theme_stylebox_override("panel", style)
	_ui_layer.add_child(_panel_root)

	# Header ngân hàng
	var header := Label.new()
	header.text = "★ NGÂN HÀNG KHOA HỌC TỰ NHIÊN - HCMUS BANK ★"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.offset_left   = 10
	header.offset_right  = 340
	header.offset_top    = 8
	header.offset_bottom = 26
	header.add_theme_color_override("font_color", Color("ffd23f"))
	header.add_theme_font_size_override("font_size", 11)
	_panel_root.add_child(header)

	# Dòng thông tin thẻ
	_lbl_info = Label.new()
	_lbl_info.text = "Thẻ: SV ĐHQG-HCM  |  Trạng thái: Hợp lệ"
	_lbl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_info.offset_left   = 10
	_lbl_info.offset_right  = 340
	_lbl_info.offset_top    = 28
	_lbl_info.offset_bottom = 44
	_lbl_info.add_theme_color_override("font_color", Color("a0c0d8"))
	_lbl_info.add_theme_font_size_override("font_size", 9)
	_panel_root.add_child(_lbl_info)

	# Số dư ví & Số dư tài khoản
	_lbl_balance = Label.new()
	_lbl_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_balance.offset_left   = 10
	_lbl_balance.offset_right  = 340
	_lbl_balance.offset_top    = 46
	_lbl_balance.offset_bottom = 66
	_lbl_balance.add_theme_color_override("font_color", Color("55e670"))
	_lbl_balance.add_theme_font_size_override("font_size", 10)
	_panel_root.add_child(_lbl_balance)

	# Container các nút chức năng
	var grid := GridContainer.new()
	grid.columns = 2
	grid.offset_left   = 16
	grid.offset_top    = 70
	grid.offset_right  = 334
	grid.offset_bottom = 195
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	_panel_root.add_child(grid)

	_add_btn(grid, "[1] Rút 50.000đ", func(): _withdraw(50000))
	_add_btn(grid, "[2] Rút 100.000đ", func(): _withdraw(100000))
	_add_btn(grid, "[3] Rút 200.000đ", func(): _withdraw(200000))
	_add_btn(grid, "[4] Rút 500.000đ", func(): _withdraw(500000))
	_add_btn(grid, "[5] Rút 1.000.000đ", func(): _withdraw(1000000))
	_add_btn(grid, "[6] Nạp 200.000đ", func(): _deposit(200000))
	_add_btn(grid, "[7] Học bổng SV (+2tr)", func(): _claim_scholarship(), Color("ffd23f"))
	_add_btn(grid, "[ESC/E] Rút thẻ & Rời đi", func(): _close_atm(), Color("ff6b6b"))

	# Dòng thông báo giao dịch (Toast / Status)
	_lbl_msg = Label.new()
	_lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_msg.offset_left   = 10
	_lbl_msg.offset_right  = 340
	_lbl_msg.offset_top    = 202
	_lbl_msg.offset_bottom = 222
	_lbl_msg.add_theme_color_override("font_color", Color("8fc9e6"))
	_lbl_msg.add_theme_font_size_override("font_size", 9)
	_panel_root.add_child(_lbl_msg)

func _add_btn(parent: Node, text: String, callback: Callable, custom_color: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150, 24)
	btn.add_theme_font_size_override("font_size", 9)
	if custom_color != Color.WHITE:
		btn.add_theme_color_override("font_color", custom_color)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

# ─── ĐỒNG BỘ VÀ XỬ LÝ TIỀN TỆ ──────────────────────────────────────────────
func _get_wallet_money() -> int:
	var c := _find_canteen()
	if c != null and ("money" in c):
		return int(c.money)
	return 0

func _set_wallet_money(val: int) -> void:
	var c := _find_canteen()
	if c != null and ("money" in c):
		c.money = val
		if c.has_method("_eco_save"):
			c._eco_save()
		if "_wallet" in c and c._wallet != null and c.has_method("_fmt"):
			c._wallet.text = "Tiền: " + c._fmt(val)

func _find_canteen() -> Node:
	if game == null:
		return null
	for ch in game.get_children():
		if ch.get_script() != null and "canteen" in ch.get_script().resource_path.to_lower():
			return ch
	return null

func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	if n < 0:
		out = "-" + out
	return out + "đ"

func _update_ui_balance() -> void:
	if _lbl_balance != null:
		var wallet := _get_wallet_money()
		_lbl_balance.text = "Tiền trong ví: %s   |   Số dư thẻ ATM: %s" % [_fmt(wallet), _fmt(bank_balance)]

func _withdraw(amount: int) -> void:
	if bank_balance < amount:
		_say("Số dư trong thẻ ATM không đủ để rút %s!" % _fmt(amount), Color("ff6b6b"))
		_play_sound("cancel")
		return
	bank_balance -= amount
	var cur_wallet := _get_wallet_money()
	_set_wallet_money(cur_wallet + amount)
	_update_ui_balance()
	_say("Đã rút thành công %s từ ATM!" % _fmt(amount), Color("55e670"))
	_play_sound("buy")

func _deposit(amount: int) -> void:
	var cur_wallet := _get_wallet_money()
	if cur_wallet < amount:
		_say("Tiền mặt trong ví không đủ %s để nạp!" % _fmt(amount), Color("ff6b6b"))
		_play_sound("cancel")
		return
	_set_wallet_money(cur_wallet - amount)
	bank_balance += amount
	_update_ui_balance()
	_say("Đã nạp thành công %s vào thẻ ATM!" % _fmt(amount), Color("55e670"))
	_play_sound("buy")

func _claim_scholarship() -> void:
	if _has_received_scholarship:
		_say("Bạn đã nhận Học bổng Khuyến khích Học tập của học kỳ này rồi!", Color("ffd23f"))
		_play_sound("cancel")
		return
	var gpa := 3.5
	if game != null and ("gpa" in game):
		gpa = float(game.gpa)
	elif game != null and ("stats" in game) and game.stats != null and ("gpa" in game.stats):
		gpa = float(game.stats.gpa)

	if gpa < 3.2:
		_say("GPA của bạn hiện là %.2f/4.0 (Cần >= 3.2 để nhận học bổng)!" % gpa, Color("ff6b6b"))
		_play_sound("cancel")
		return

	_has_received_scholarship = true
	var bonus := 2000000
	bank_balance += bonus
	_update_ui_balance()
	_say("CHÚC MỪNG! Nhận Học bổng HCMUS Giỏi: +%s vào thẻ ATM!" % _fmt(bonus), Color("ffd23f"))
	_play_sound("buy")

func _say(msg: String, col: Color = Color.WHITE) -> void:
	if _lbl_msg != null:
		_lbl_msg.text = msg
		_lbl_msg.modulate = col
		_msg_timer = 4.0

func _play_sound(sfx_name: String) -> void:
	if game != null and ("audio" in game) and game.audio != null:
		if game.audio.has_method("play_sfx"):
			game.audio.play_sfx(sfx_name)
