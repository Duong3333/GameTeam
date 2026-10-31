extends Node
## Quan ly CLB, diem CLB, cap bac va uu dai. Dung game.stats/game.game_min cua project.

signal club_joined(id: String)
signal club_left(id: String)
signal points_changed(id: String)
signal rank_up(id: String, title: String)

const MAX_CLUBS := 2
const ACTIVITY_MINUTES := 30
const ACTIVITY_ENERGY := 15
const ACTIVITY_POINTS := 5
const RANKS := [
	{"points": 0, "title": "Thanh vien", "bonus": 0},
	{"points": 40, "title": "Thanh vien tich cuc", "bonus": 20000},
	{"points": 120, "title": "Cot can", "bonus": 50000},
	{"points": 250, "title": "Pho chu nhiem", "bonus": 100000},
]
const CLUBS := {
	"coding": {"name": "CLB Lap trinh", "desc": "Giai thuat toan, lam project va thi hackathon.", "event": "club_code"},
	"sports": {"name": "CLB The thao", "desc": "Tap luyen va thi dau giao huu.", "event": "club_sport"},
	"music": {"name": "CLB Am nhac", "desc": "Tap dan, hat va bieu dien.", "event": "club_music"},
}

var game
var quest_manager
var joined: Array[String] = []
var points: Dictionary = {}

func is_member(id: String) -> bool:
	return id in joined

func join(id: String) -> String:
	if not CLUBS.has(id):
		return "CLB khong ton tai."
	if is_member(id):
		return "Ban da tham gia CLB nay."
	if joined.size() >= MAX_CLUBS:
		return "Chi duoc tham gia toi da %d CLB." % MAX_CLUBS
	joined.append(id)
	points[id] = int(points.get(id, 0))
	club_joined.emit(id)
	return "Da gia nhap %s!" % CLUBS[id].name

func leave(id: String) -> void:
	if is_member(id):
		joined.erase(id)
		club_left.emit(id)

func interact(id: String) -> String:
	if not is_member(id):
		return join(id)
	return do_activity(id)

func do_activity(id: String) -> String:
	if not CLUBS.has(id) or not is_member(id):
		return "Ban chua tham gia CLB nay."
	if not game.stats.spend_energy(ACTIVITY_ENERGY, "Sinh hoat CLB"):
		return "Ban qua met. Hay nghi ngoi de hoi nang luong."
	game.game_min += ACTIVITY_MINUTES
	add_points(id, ACTIVITY_POINTS)
	if quest_manager != null:
		quest_manager.report(str(CLUBS[id].event), id)
		quest_manager.report("club_activity", id)
	return "Sinh hoat %s (+%d diem CLB, -%d nang luong)." % [CLUBS[id].name, ACTIVITY_POINTS, ACTIVITY_ENERGY]

func add_points(id: String, amount: int) -> void:
	if amount <= 0 or not is_member(id):
		return
	var before := rank_index(id)
	points[id] = int(points.get(id, 0)) + amount
	var after := rank_index(id)
	points_changed.emit(id)
	for rank in range(before + 1, after + 1):
		game.stats.add_money(int(RANKS[rank].bonus), "Thuong len cap CLB")
		rank_up.emit(id, str(RANKS[rank].title))

func rank_index(id: String) -> int:
	var result := 0
	var value := int(points.get(id, 0))
	for i in RANKS.size():
		if value >= int(RANKS[i].points):
			result = i
	return result

func rank_title(id: String) -> String:
	return str(RANKS[rank_index(id)].title)

func points_to_next(id: String) -> int:
	var rank := rank_index(id)
	if rank >= RANKS.size() - 1:
		return -1
	return int(RANKS[rank + 1].points) - int(points.get(id, 0))

func perk(perk_name: String) -> float:
	var result := 1.0
	for id in joined:
		var rank := rank_index(id)
		if perk_name == "money_mult" and id == "music":
			result += 0.10 * rank
		elif perk_name == "xp_mult" and id == "coding":
			result += 0.10 * rank
		elif perk_name == "kick_power" and id == "sports":
			result += 0.08 * rank
		elif perk_name == "shot_window" and id == "sports":
			result += 0.15 * rank
	return result

func to_dict() -> Dictionary:
	return {"joined": joined.duplicate(), "points": points.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	joined.clear()
	for id in data.get("joined", []):
		if CLUBS.has(id):
			joined.append(id)
	points = data.get("points", {}).duplicate(true)
