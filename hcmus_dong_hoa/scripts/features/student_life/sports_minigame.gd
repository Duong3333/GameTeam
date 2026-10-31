extends CanvasLayer
## Lop boc mini-game, trao thuong vao StudentStats cua project hien tai.

const FootballGame := preload("res://scripts/features/student_life/sports/football_game.gd")
const BasketballGame := preload("res://scripts/features/student_life/sports/basketball_game.gd")

signal completed

var game
var clubs
var quests
var mode := "football"
var _mini_game: Node2D
var _result_label: Label
var _finished := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_mini_game = BasketballGame.new() if mode == "basketball" else FootballGame.new()
	if mode == "basketball":
		_mini_game.shot_window_multiplier = clubs.perk("shot_window") if clubs != null else 1.0
	else:
		_mini_game.kick_power_multiplier = clubs.perk("kick_power") if clubs != null else 1.0
	_mini_game.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_mini_game)
	_mini_game.finished.connect(_on_finished)
	_result_label = Label.new()
	_result_label.position = Vector2(0, 118)
	_result_label.size = Vector2(480, 40)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 20)
	_result_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_result_label.add_theme_constant_override("outline_size", 4)
	add_child(_result_label)

func _on_finished(won: bool, my_score: int, opp_score: int) -> void:
	if _finished:
		return
	_finished = true
	var title := "HOA" if my_score == opp_score else ("CHIEN THANG!" if won else "THUA ROI")
	_result_label.text = "%s  %d - %d" % [title, my_score, opp_score]
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	game.game_min += 30.0
	if won:
		var multiplier: float = float(clubs.perk("money_mult")) if clubs != null else 1.0
		game.stats.add_money(int(30000 * multiplier), "Thuong tran dau")
		game.stats.add_xp(20)
	else:
		game.stats.add_xp(5)
	if clubs != null and clubs.is_member("sports"):
		clubs.add_points("sports", 3 if won else 1)
	if quests != null:
		quests.report("sports_match", mode)
		if won:
			quests.report("sports_win", mode)
	completed.emit()
	queue_free()
