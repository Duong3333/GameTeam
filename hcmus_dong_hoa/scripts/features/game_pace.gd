extends "res://scripts/features/feature.gd"
# NHỊP THỜI GIAN CỦA GAME (làm chậm đồng hồ để người chơi có thời gian khám phá).
#
# main.gd (file lõi, không được sửa) tăng game.game_min mỗi khung hình theo TIME_SCALE.
# Feature này đứng sau main trong cây node nên mỗi khung hình nó đo lượng thời gian vừa trôi,
# rồi co lại theo NORMAL_PACE; khi đang làm quiz / bài tập thì chậm thêm QUIZ_SLOWDOWN lần.
# Đổi hai hằng số dưới đây để chỉnh nhịp, không cần sửa nơi khác.

const NORMAL_PACE := 0.25      # 1.0 = tốc độ gốc (1 giây thật = TIME_SCALE phút game). 0.25 -> 1 ngày game dài khoảng 13 phút thật
const QUIZ_SLOWDOWN := 10.0    # đang làm quiz / bài tập: chậm hơn bình thường 10 lần
const DAY_START := 7.0 * 60.0  # main.gd đặt lại 07:00 khi sang ngày mới
const DAY_END := 17.0 * 60.0
const MAX_NATURAL_STEP := 1.5  # phút game / khung hình; lớn hơn coi là bị nhảy giờ (tua ngày, ngủ...) thì không co lại

var _prev_min := -1.0
var _prev_day := -1

func _process(_delta: float) -> void:
	var day := int(game.day)
	var minute := float(game.game_min)
	if _prev_day < 0:
		_sync(day, minute)
		return
	var advanced := -1.0
	if day == _prev_day:
		advanced = minute - _prev_min
	elif day == _prev_day + 1 and minute < _prev_min:
		advanced = (DAY_END - _prev_min) + (minute - DAY_START)   # main.gd vừa sang ngày mới
	if advanced <= 0.0 or advanced > MAX_NATURAL_STEP:
		_sync(day, minute)
		return
	var scaled := _prev_min + advanced * _current_pace()
	if scaled >= DAY_END:
		game.day = _prev_day + 1
		game.game_min = DAY_START + (scaled - DAY_END)
	else:
		game.day = _prev_day
		game.game_min = scaled
	_sync(int(game.day), float(game.game_min))

func _sync(day: int, minute: float) -> void:
	_prev_day = day
	_prev_min = minute

func _current_pace() -> float:
	return NORMAL_PACE / QUIZ_SLOWDOWN if _quiz_open() else NORMAL_PACE

# Có quiz / bài tập nào đang mở không (math_quiz.gd: thi, quiz tiết học, bài tập; npc_random_quiz.gd: mini quiz).
func _quiz_open() -> bool:
	for feature in game.features:
		if feature == self or feature.get("active") != true:
			continue
		if feature.has_method("start_round") or _is_mini_quiz(feature):
			return true
	return false

func _is_mini_quiz(feature: Node) -> bool:
	var attached_script: Variant = feature.get_script()
	return attached_script is Script and str(attached_script.resource_path).ends_with("/npc_random_quiz.gd")
