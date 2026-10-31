extends "res://scripts/features/feature.gd"
# Điều khiển toàn bộ vòng Quiz của Cô Toán.
#
# Nếu mới học code, hãy đọc các hàm theo thứ tự:
# 1. start_round()       - bắt đầu một vòng mới.
# 2. next_question()     - yêu cầu MathQuestions tạo câu kế tiếp.
# 3. choose()            - xử lý khi người chơi chọn đáp án.
# 4. finish_answer()     - hiện nút sang câu tiếp theo.
# 5. end_round()         - tính kết quả và cập nhật GPA.
#
# MathQuestions (math_questions.gd) chỉ lo tạo câu hỏi và đáp án.
# File này lo luồng chơi, giao diện và phản hồi cho người chơi.

const MathQuestions := preload("res://scripts/systems/math_questions.gd")
const INTERACT_RANGE := 36.0
const LETTERS := ["A", "B", "C", "D"]
const PANEL_SIZE := Vector2(440, 252)
const GPA_PENALTY := 0.1

enum State { MENU, PLAY, RESULT }

var npc: Dictionary = {}
var question: Dictionary = {}
var state: int = State.MENU
var question_no := 0
var round_len := 5
var score := 0
var correct_count := 0
var streak := 0
var best_streak := 0
var answered := false
var time_left := 0.0
var time_limit := 20.0
var was_near := false
var prev_mouse_mode := Input.MOUSE_MODE_VISIBLE

var prompt_layer: CanvasLayer
var prompt: Label
var root: Control
var panel: Panel
var title_label: Label
var close_btn: Button
var menu_box: Control
var play_box: Control
var result_box: Control
var info_label: Label
var score_label: Label
var streak_label: Label
var time_bg: ColorRect
var time_fill: ColorRect
var question_label: Label
var source_label: Label
var result_label: Label
var next_btn: Button
var answer_btns: Array = []
var res_rank_label: Label
var res_star_label: Label
var res_stat_label: Label

# Mau giao dien HUD navy - vang cua game.
var c_bg := Color(0.05, 0.1, 0.2, 0.98)
var c_gold := Color("ffd23f")
var c_option := Color(0.13, 0.22, 0.42)
var c_option_hover := Color(0.2, 0.33, 0.6)
var c_option_off := Color(0.1, 0.14, 0.24)
var c_green := Color(0.16, 0.6, 0.28)
var c_red := Color(0.78, 0.2, 0.2)

func _ready() -> void:
	for n in game.npcs:
		if n.get("quiz", false):
			npc = n
	build_prompt()
	build_ui()
	root.visible = false
	show_state(State.MENU)

# ---------- Tuong tac NPC ----------
func is_near() -> bool:
	if npc.is_empty():
		return false
	var p: Vector2 = game.player
	var q: Vector2 = npc.pos
	return p.distance_to(q) <= INTERACT_RANGE

func _process(delta: float) -> void:
	if not npc.is_empty() and float(npc.get("say_t", 0.0)) > 0.0:
		npc.say_t -= delta
	var near := is_near()
	prompt.visible = near and not active and not game.is_busy()
	if prompt.visible:
		prompt.text = "Nhấn E để làm quiz toán"
	if near and not active:
		var d: Vector2 = game.player - npc.pos
		if absf(d.x) > absf(d.y):
			npc.face = 2 if d.x < 0.0 else 3
		else:
			npc.face = 1 if d.y < 0.0 else 0
		if not was_near:
			npc_say(greeting())
	was_near = near
	if active and state == State.PLAY and not answered:
		time_left -= delta
		update_time_bar()
		if time_left <= 0.0:
			time_up()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if active:
		handle_key(k)
		get_viewport().set_input_as_handled()
	elif (k.keycode == KEY_E or k.physical_keycode == KEY_E) and is_near() and not game.is_busy():
		begin()
		get_viewport().set_input_as_handled()

func handle_key(k: InputEventKey) -> void:
	if k.keycode == KEY_ESCAPE:
		finish()
		return
	if state == State.MENU:
		if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			start_round()
	elif state == State.PLAY:
		var idx := -1
		match k.keycode:
			KEY_1, KEY_KP_1, KEY_A:
				idx = 0
			KEY_2, KEY_KP_2, KEY_B:
				idx = 1
			KEY_3, KEY_KP_3, KEY_C:
				idx = 2
			KEY_4, KEY_KP_4, KEY_D:
				idx = 3
		if idx >= 0:
			if not answered and not answer_btns[idx].disabled:
				choose(idx)
		elif k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and answered:
			next_question()
	elif state == State.RESULT:
		if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_R]:
			start_round()

func begin() -> void:
	super()
	prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.visible = false
	root.visible = true
	pop_in()

func finish() -> void:
	super()
	root.visible = false
	Input.mouse_mode = prev_mouse_mode
	if state == State.PLAY:
		npc_say("Em cứ đi dạo, quay lại làm tiếp nhé!")

# ---------- Luong quiz ----------
func show_state(s: int) -> void:
	state = s
	menu_box.visible = (s == State.MENU)
	play_box.visible = (s == State.PLAY)
	result_box.visible = (s == State.RESULT)
	title_label.text = "KẾT QUẢ QUIZ" if s == State.RESULT else "QUIZ TOÁN HỌC"

func start_round() -> void:
	round_len = MathQuestions.round_length()
	question_no = 0
	score = 0
	correct_count = 0
	streak = 0
	best_streak = 0
	question = {}
	answered = false
	show_state(State.PLAY)
	next_question()
	pop_in()

func next_question() -> void:
	if question_no >= round_len:
		end_round()
		return
	var previous_text := str(question.get("text", ""))
	question = MathQuestions.generate(question_no + 1, previous_text)
	question_no += 1
	answered = false
	time_limit = MathQuestions.time_limit_for(question_no)
	time_left = time_limit
	question_label.text = str(question.text)
	question_label.add_theme_font_size_override("font_size", 17 if question_no == 5 else (18 if question_no == 4 else 22))
	if question_no >= 3:
		source_label.text = "Nguồn: " + str(question.source)
	else:
		source_label.text = "Dạng: " + str(question.kind)
	for i in 4:
		var b: Button = answer_btns[i]
		b.text = "%s.  %s" % [LETTERS[i], str(question.options[i])]
		b.disabled = false
		b.add_theme_font_size_override("font_size", 10 if question_no == 5 else 11)
		paint_disabled(b, c_option_off)
	result_label.text = "Chọn đáp án (phím 1-4 hoặc A-D)."
	result_label.add_theme_color_override("font_color", Color("dfe6ff"))
	next_btn.visible = false
	update_info()
	update_time_bar()

func choose(i: int) -> void:
	if answered:
		return
	answered = true
	for b in answer_btns:
		b.disabled = true
	var correct: int = int(question.correct)
	if i == correct:
		streak += 1
		best_streak = maxi(best_streak, streak)
		correct_count += 1
		var gain := points_for_answer()
		score += gain
		paint_disabled(answer_btns[i], c_green)
		var msg := "Chính xác! +%d điểm." % gain
		if streak >= 3:
			msg += " Combo x%d!" % streak
		result_label.text = msg + " " + str(question.get("explanation", ""))
		result_label.add_theme_color_override("font_color", Color("7dffa0"))
		float_text("+%d" % gain, Color("7dffa0"))
		npc_say(["Giỏi lắm!", "Chuẩn rồi!", "Tuyệt vời!", "Nhanh quá!"][randi() % 4] if streak < 3 else "Combo x%d! Quá đỉnh!" % streak)
		flash(answer_btns[i])
	else:
		wrong_answer(i)
	finish_answer()

# i=-1 khi het gio.
func wrong_answer(i: int) -> void:
	streak = 0
	var correct: int = int(question.correct)
	if i >= 0:
		paint_disabled(answer_btns[i], c_red)
	paint_disabled(answer_btns[correct], c_green)
	var head := "Sai rồi!" if i >= 0 else "Hết giờ!"
	result_label.text = "%s Đáp án đúng: %s. %s" % [head, str(question.answer), str(question.get("explanation", ""))]
	result_label.add_theme_color_override("font_color", Color("ff8080"))
	npc_say(["Không sao, thử lại nhé!", "Cẩn thận hơn nào!", "Tiếc quá!"][randi() % 3])
	shake()

func time_up() -> void:
	if answered:
		return
	answered = true
	for b in answer_btns:
		b.disabled = true
	wrong_answer(-1)
	finish_answer()

func finish_answer() -> void:
	next_btn.text = "Xem kết quả (Enter)" if question_no >= round_len else "Câu tiếp theo (Enter)"
	next_btn.visible = true
	update_info()

# Tính điểm cho một câu trả lời đúng.
# Điểm = điểm nền + thưởng thời gian + thưởng combo.
func points_for_answer() -> int:
	var base_points := 8
	if question_no == 4:
		base_points = 18 # Câu Vi tích phân vận dụng có điểm nền cao hơn.
	elif question_no == 5:
		base_points = 30 # Câu Vi tích phân có điểm nền cao nhất.

	var time_bonus := int(ceil(10.0 * time_left / maxf(time_limit, 1.0)))
	var combo_bonus := 0
	if streak >= 5:
		combo_bonus = 10
	elif streak >= 3:
		combo_bonus = 5

	return base_points + time_bonus + combo_bonus

# Kết thúc lượt chơi: tính điểm, cập nhật GPA và hiện kết quả.
func end_round() -> void:
	# Điểm quiz thang 10 được tính theo tỷ lệ số câu trả lời đúng.
	var accuracy := float(correct_count) / float(maxi(round_len, 1))
	var quiz_grade := accuracy * 10.0
	var gpa_deducted := apply_gpa_penalty(quiz_grade)
	var rank_data := get_rank_for_accuracy(accuracy)
	var rank_text := str(rank_data["text"])
	var stars := int(rank_data["stars"])

	# Cập nhật phần đầu màn hình kết quả.
	res_rank_label.text = rank_text
	res_star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)

	var gpa_message := "GPA: -%.2f (điểm quiz dưới 5/10)" % GPA_PENALTY
	if not gpa_deducted:
		gpa_message = "GPA: không bị trừ"

	res_stat_label.text = "Điểm quiz: %.1f/10 (điểm thưởng: %d)\nĐúng: %d/%d câu (%d%%)\nCombo dài nhất: %d\nVòng này: %d câu\n%s" % [
		quiz_grade,
		score,
		correct_count,
		round_len,
		int(round(accuracy * 100.0)),
		best_streak,
		round_len,
		gpa_message
	]

	show_state(State.RESULT)

	if gpa_deducted:
		npc_say("Điểm quiz dưới 5/10, GPA bị trừ %.2f. Cố gắng hơn nhé!" % GPA_PENALTY)
	elif stars >= 2:
		npc_say("Làm tốt lắm!")
	else:
		npc_say("Lần sau sẽ tốt hơn!")

	pop_in()

# Trừ GPA khi điểm quiz thấp hơn 5/10.
# StudentStats tự giới hạn GPA trong khoảng 0.0 đến 4.0.
func apply_gpa_penalty(quiz_grade: float) -> bool:
	if quiz_grade >= 5.0:
		return false

	if game.stats != null and game.stats.has_method("set_gpa"):
		game.stats.set_gpa(float(game.stats.gpa) - GPA_PENALTY)

	return true

# Trả về lời nhận xét và số sao dựa trên tỷ lệ câu đúng.
func get_rank_for_accuracy(accuracy: float) -> Dictionary:
	if accuracy >= 0.9:
		return {"text": "Thủ khoa Toán học!", "stars": 3}
	if accuracy >= 0.7:
		return {"text": "Sinh viên giỏi!", "stars": 2}
	if accuracy >= 0.5:
		return {"text": "Khá lắm!", "stars": 1}
	return {"text": "Cố gắng thêm nhé!", "stars": 0}

func update_info() -> void:
	info_label.text = "Câu %d/%d" % [question_no, round_len]
	score_label.text = "Điểm: %d" % score
	streak_label.text = "Combo x%d" % streak if streak >= 2 else ""

func update_time_bar() -> void:
	var ratio := clampf(time_left / maxf(time_limit, 1.0), 0.0, 1.0)
	time_fill.size.x = time_bg.size.x * ratio
	if ratio > 0.5:
		time_fill.color = Color("4fd16b")
	elif ratio > 0.25:
		time_fill.color = Color("f0b429")
	else:
		time_fill.color = Color("e5484d")

# ---------- Loi thoai NPC ----------
func npc_say(text: String) -> void:
	if npc.is_empty():
		return
	npc.say = text
	npc.say_t = 2.6

func greeting() -> String:
	return "Giờ thi tới rồi, giờ thi tời rồi"

# ---------- Hieu ung ----------
func pop_in() -> void:
	panel.pivot_offset = PANEL_SIZE / 2.0
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.14)
	tw.tween_property(panel, "modulate:a", 1.0, 0.14)

func shake() -> void:
	var x0 := (480.0 - PANEL_SIZE.x) / 2.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "position:x", x0 - 4.0, 0.04)
	tw.tween_property(panel, "position:x", x0 + 4.0, 0.06)
	tw.tween_property(panel, "position:x", x0 - 2.0, 0.05)
	tw.tween_property(panel, "position:x", x0, 0.04)

func flash(b: Button) -> void:
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.07)
	tw.tween_property(b, "scale", Vector2.ONE, 0.09)

func float_text(t: String, col: Color) -> void:
	var l := make_text(panel, Rect2(PANEL_SIZE.x - 84, 55, 70, 20), 13, col)
	l.text = t
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", 35.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(l.queue_free)

# ---------- Dung giao dien ----------
func build_prompt() -> void:
	prompt_layer = CanvasLayer.new()
	prompt_layer.layer = 7
	add_child(prompt_layer)
	prompt = game.make_label(prompt_layer, Vector2(0, 214), 11)
	prompt.text = "Nhấn E để làm quiz toán"
	prompt.add_theme_color_override("font_color", c_gold)
	prompt.custom_minimum_size = Vector2(480, 16)
	prompt.size = Vector2(480, 16)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.visible = false

func build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	root = Control.new()
	root.size = Vector2(480, 270)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	panel = Panel.new()
	panel.position = (Vector2(480, 270) - PANEL_SIZE) / 2.0
	panel.size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", make_style(c_bg, c_gold, 2))
	root.add_child(panel)
	title_label = make_text(panel, Rect2(0, 4, PANEL_SIZE.x, 20), 14, c_gold)
	close_btn = make_button(panel, Rect2(PANEL_SIZE.x - 25, 4, 18, 18), "X", 10, c_red, Color(0.95, 0.35, 0.35))
	close_btn.pressed.connect(finish)
	build_menu()
	build_play()
	build_result()

func build_menu() -> void:
	menu_box = Control.new()
	menu_box.size = PANEL_SIZE
	menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(menu_box)
	var sub := make_text(menu_box, Rect2(16, 34, PANEL_SIZE.x - 32, 34), 11, Color.WHITE)
	sub.text = "Mỗi vòng có 5 câu: câu 1-2 số học, câu 3-5 Vi tích phân tăng dần độ khó."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var start_btn := make_button(menu_box, Rect2(105, 105, 230, 36), "BẮT ĐẦU QUIZ  (Enter)", 12, Color(0.16, 0.5, 0.28), Color(0.22, 0.65, 0.36))
	start_btn.pressed.connect(start_round)
	var hint := make_text(menu_box, Rect2(16, 160, PANEL_SIZE.x - 32, 30), 9, Color("9fb0d8"))
	hint.text = "1-4 hoặc A-D: chọn đáp án    Esc: đóng"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_play() -> void:
	play_box = Control.new()
	play_box.size = PANEL_SIZE
	play_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(play_box)
	score_label = make_text(play_box, Rect2(12, 24, 96, 14), 10, c_gold)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label = make_text(play_box, Rect2(145, 24, 120, 14), 10, Color("dfe6ff"))
	streak_label = make_text(play_box, Rect2(PANEL_SIZE.x - 126, 24, 110, 14), 10, Color("ff9f43"))
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_bg = ColorRect.new()
	time_bg.color = Color(0.02, 0.05, 0.12)
	time_bg.position = Vector2(20, 42)
	time_bg.size = Vector2(PANEL_SIZE.x - 40, 6)
	play_box.add_child(time_bg)
	time_fill = ColorRect.new()
	time_fill.color = Color("4fd16b")
	time_fill.size = time_bg.size
	time_bg.add_child(time_fill)
	question_label = make_text(play_box, Rect2(18, 53, PANEL_SIZE.x - 36, 44), 21, Color.WHITE)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_stylebox_override("normal", make_style(Color(0.02, 0.05, 0.12), Color(0.3, 0.4, 0.65), 1))
	source_label = make_text(play_box, Rect2(18, 99, PANEL_SIZE.x - 36, 14), 8, Color("9fb0d8"))
	source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 4:
		var x := 20.0 + float(i % 2) * 200.0
		var y := 117.0 + float(floori(i / 2.0)) * 34.0
		var b := make_button(play_box, Rect2(Vector2(x, y), Vector2(190, 30)), "", 11, c_option, c_option_hover)
		b.pressed.connect(choose.bind(i))
		answer_btns.append(b)
	result_label = make_text(play_box, Rect2(12, 184, PANEL_SIZE.x - 24, 31), 8, Color.WHITE)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	next_btn = make_button(play_box, Rect2(20, 219, PANEL_SIZE.x - 40, 22), "Câu tiếp theo  (Enter)", 9, Color(0.75, 0.55, 0.1), Color(0.9, 0.7, 0.2))
	next_btn.pressed.connect(next_question)
	next_btn.visible = false

func build_result() -> void:
	result_box = Control.new()
	result_box.size = PANEL_SIZE
	result_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(result_box)
	res_rank_label = make_text(result_box, Rect2(0, 31, PANEL_SIZE.x, 21), 15, Color.WHITE)
	res_star_label = make_text(result_box, Rect2(0, 54, PANEL_SIZE.x, 32), 26, c_gold)
	res_stat_label = make_text(result_box, Rect2(24, 88, PANEL_SIZE.x - 48, 82), 11, Color("dfe6ff"))
	var again := make_button(result_box, Rect2(45, 201, 165, 27), "Chơi lại  (Enter)", 11, Color(0.16, 0.5, 0.28), Color(0.22, 0.65, 0.36))
	again.pressed.connect(start_round)
	var quit := make_button(result_box, Rect2(228, 201, 165, 27), "Đóng", 11, c_red, Color(0.95, 0.35, 0.35))
	quit.pressed.connect(finish)

func make_style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(2)
	return s

func make_text(parent: Control, r: Rect2, sz: int, col: Color) -> Label:
	var l: Label = game.make_label(parent, r.position, sz)
	l.add_theme_constant_override("outline_size", 2)
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = r.size
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func make_button(parent: Control, r: Rect2, txt: String, sz: int, col: Color, hover: Color) -> Button:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", game.font)
	b.add_theme_font_size_override("font_size", sz)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(key, Color.WHITE)
	b.add_theme_stylebox_override("normal", make_style(col, c_gold, 1))
	b.add_theme_stylebox_override("hover", make_style(hover, Color.WHITE, 1))
	b.add_theme_stylebox_override("pressed", make_style(col.darkened(0.25), c_gold, 1))
	b.add_theme_stylebox_override("disabled", make_style(c_option_off, Color(0.3, 0.35, 0.5), 1))
	parent.add_child(b)
	return b

func paint_disabled(b: Button, col: Color) -> void:
	var border := c_gold if col != c_option_off else Color(0.3, 0.35, 0.5)
	b.add_theme_stylebox_override("disabled", make_style(col, border, 1))
