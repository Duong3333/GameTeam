extends "res://scripts/features/feature.gd"
## Diem vao 3 he thong doi song sinh vien. Phim tat: F1 nhiem vu, F2 CLB,
## F3 bong da, F4 bong ro. TKB va dong ho van doc tu game.day/game.game_min.

const QuestManagerScript := preload("res://scripts/features/student_life/quest_manager.gd")
const ClubManagerScript := preload("res://scripts/features/student_life/club_manager.gd")
const SportsScript := preload("res://scripts/features/student_life/sports_minigame.gd")

var quests
var clubs
var layer: CanvasLayer
var panel: PanelContainer
var panel_body: VBoxContainer
var sports_running := false

func _ready() -> void:
	clubs = ClubManagerScript.new()
	clubs.game = game
	add_child(clubs)
	quests = QuestManagerScript.new()
	quests.game = game
	quests.clubs = clubs
	add_child(quests)
	quests.quest_completed.connect(_on_quest_completed)
	clubs.rank_up.connect(_on_rank_up)
	_build_ui()

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	panel = PanelContainer.new()
	panel.position = Vector2(65, 28)
	panel.size = Vector2(350, 214)
	panel.visible = false
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	panel_body = VBoxContainer.new()
	panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel_body)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE and panel.visible:
		_close_panel()
		get_viewport().set_input_as_handled()
		return
	if active or sports_running:
		return
	match key.keycode:
		KEY_F1:
			_show_quests()
			get_viewport().set_input_as_handled()
		KEY_F2:
			_show_clubs()
			get_viewport().set_input_as_handled()
		KEY_F3:
			_start_sports("football")
			get_viewport().set_input_as_handled()
		KEY_F4:
			_start_sports("basketball")
			get_viewport().set_input_as_handled()
		KEY_F5:
			game.stats.add_energy(40, "Nghi ngoi")
			game.game_min += 60.0
			get_viewport().set_input_as_handled()
		KEY_F6:
			if game.stats.spend_money(10000, "Mua bua an"):
				game.stats.add_energy(30, "An uong")
			get_viewport().set_input_as_handled()

func _show_quests() -> void:
	_open_panel("NHIEM VU HOM NAY")
	_add_label(quests.summary_text())

func _show_clubs() -> void:
	_open_panel("CAU LAC BO")
	_add_label("Ban co the tham gia toi da 2 CLB. Sinh hoat ton 15 nang luong va 30 phut.")
	for id in clubs.CLUBS:
		var data: Dictionary = clubs.CLUBS[id]
		_add_label("%s | %s | %d diem | %s" % [data.name, "Da tham gia" if clubs.is_member(id) else "Chua tham gia", int(clubs.points.get(id, 0)), clubs.rank_title(id) if clubs.is_member(id) else ""])
		var action := Button.new()
		action.text = "Sinh hoat" if clubs.is_member(id) else "Tham gia"
		action.pressed.connect(_on_club_action.bind(id))
		panel_body.add_child(action)
		if clubs.is_member(id):
			var leave_button := Button.new()
			leave_button.text = "Roi CLB"
			leave_button.pressed.connect(_on_club_leave.bind(id))
			panel_body.add_child(leave_button)

func _open_panel(title: String) -> void:
	_clear_panel()
	panel.visible = true
	active = true
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_body.add_child(heading)
	var close_button := Button.new()
	close_button.text = "Dong (Esc)"
	close_button.pressed.connect(_close_panel)
	panel_body.add_child(close_button)

func _close_panel() -> void:
	panel.visible = false
	active = false

func _clear_panel() -> void:
	for child in panel_body.get_children():
		panel_body.remove_child(child)
		child.queue_free()

func _add_label(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(label)

func _on_club_action(id: String) -> void:
	var message: String = str(clubs.interact(id))

	quests.report("club_activity")
	quests.report(str(clubs.CLUBS[id].event), id)

	_show_clubs()
	_add_label(message)

func _on_club_leave(id: String) -> void:
	clubs.leave(id)
	_show_clubs()
	_add_label("Da roi CLB.")

func _start_sports(mode: String) -> void:
	if not game.stats.spend_energy(20, "Tham gia tran the thao"):
		_open_panel("BAN DANG MET")
		_add_label("Can it nhat 20 nang luong de thi dau. Hay nghi ngoi hoac an uong.")
		return
	sports_running = true
	active = true
	var match_scene := SportsScript.new()
	match_scene.game = game
	match_scene.clubs = clubs
	match_scene.quests = quests
	match_scene.mode = mode
	match_scene.completed.connect(_on_sports_completed)
	get_tree().current_scene.add_child(match_scene)

func _on_sports_completed() -> void:
	sports_running = false
	active = false

func _on_quest_completed(quest: Dictionary) -> void:
	game.stats.add_drl(1, "Hoan thanh nhiem vu")
	print("Hoan thanh nhiem vu: ", quest.get("title", ""))

func _on_rank_up(id: String, title: String) -> void:
	print("%s len cap: %s" % [clubs.CLUBS[id].name, title])
