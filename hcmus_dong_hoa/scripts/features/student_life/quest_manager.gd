extends Node
## Nhiem vu sinh vien. Su dung game.day va game.stats; khong tao dong ho/TKB moi.

signal quests_changed
signal quest_completed(quest: Dictionary)

const DAILY_POOL := [
	{"title": "Van dong nhe", "desc": "Hoan thanh mot tran the thao.", "event": "sports_match", "required": 1, "reward": {"xp": 25, "money": 10000}},
	{"title": "Chien thang ngot ngao", "desc": "Thang mot tran the thao.", "event": "sports_win", "required": 1, "reward": {"xp": 30, "money": 15000}},
	{"title": "Sinh hoat sinh vien", "desc": "Tham gia mot buoi sinh hoat CLB.", "event": "club_activity", "required": 1, "reward": {"xp": 20, "money": 8000}},
]

var game
var clubs
var quests: Array = []
var _last_day := -1

func _ready() -> void:
	if clubs != null:
		clubs.club_joined.connect(_on_club_joined)
		clubs.club_left.connect(_on_club_left)
	_last_day = game.day
	generate_daily()

func _process(_delta: float) -> void:
	if game.day != _last_day:
		_last_day = game.day
		generate_daily()

func generate_daily() -> void:
	quests.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(game.day) * 7919 + 17
	var pool: Array = DAILY_POOL.duplicate(true)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = pool[i]
		pool[i] = pool[j]
		pool[j] = temp
	for i in mini(3, pool.size()):
		_add(pool[i])
	if clubs != null:
		for id in clubs.joined:
			_add_club_quest(id)
	quests_changed.emit()

func _add(template: Dictionary, scope: String = "daily") -> void:
	var quest: Dictionary = template.duplicate(true)
	quest["id"] = "q_%d_%d" % [game.day, quests.size()]
	quest["scope"] = scope
	quest["progress"] = 0
	quest["done"] = false
	quest["target"] = str(quest.get("target", ""))
	quests.append(quest)

func _add_club_quest(id: String) -> void:
	if not clubs.CLUBS.has(id):
		return
	var event := str(clubs.CLUBS[id].event)
	for quest in quests:
		if quest.get("club", "") == id:
			return
	_add({"title": "Sinh hoat %s" % clubs.CLUBS[id].name, "desc": "Tham gia mot buoi sinh hoat CLB.", "event": event, "target": id, "required": 1, "reward": {"xp": 20, "money": 10000, "club_points": 5}}, "club")
	quests[-1]["club"] = id

func _on_club_joined(id: String) -> void:
	_add_club_quest(id)
	quests_changed.emit()

func _on_club_left(id: String) -> void:
	quests = quests.filter(func(q): return q.get("club", "") != id)
	quests_changed.emit()

func report(event: String, target: String = "", amount: int = 1) -> void:
	var changed := false
	for quest in quests:
		if quest.done or quest.event != event:
			continue
		if quest.target != "" and quest.target != target:
			continue
		quest.progress = mini(int(quest.required), int(quest.progress) + amount)
		changed = true
		if quest.progress >= quest.required:
			_complete(quest)
	if changed:
		quests_changed.emit()

func _complete(quest: Dictionary) -> void:
	quest.done = true
	var reward: Dictionary = quest.reward
	var money_mult: float = float(clubs.perk("money_mult")) if clubs != null else 1.0
	var xp_mult: float = float(clubs.perk("xp_mult")) if clubs != null else 1.0
	game.stats.add_money(int(reward.get("money", 0) * money_mult), "Thuong nhiem vu")
	game.stats.add_xp(int(reward.get("xp", 0) * xp_mult))
	var club_id := str(quest.get("club", ""))
	if club_id != "" and clubs != null:
		clubs.add_points(club_id, int(reward.get("club_points", 0)))
	quest_completed.emit(quest)

func summary_text() -> String:
	var lines := PackedStringArray(["NHIEM VU - Ngay %d" % (game.day + 1), ""])
	for quest in quests:
		var status := "XONG" if quest.done else "%d/%d" % [quest.progress, quest.required]
		lines.append("[%s] %s" % [status, quest.title])
		lines.append("  %s" % quest.desc)
	return "\n".join(lines)
