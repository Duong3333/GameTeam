extends "res://scripts/features/feature.gd"
# ĐÁNH TRÊU CHỌC NPC - chỉ để vui: không có máu, không sát thương, không phải game đối kháng.
#
# Cách chơi: đứng gần một NPC rồi bấm H. Nhân vật tung một cú đánh (cánh tay vươn ra từ vai, có "BỐP!").
# GIỮ phím H để đấm liên hoàn: hai tay đấm luân phiên, mỗi cú đều trúng NPC gần nhất trong tầm.
# Khi đấm, tay đang buông của nhân vật được ẩn đi (game.hidden_arms, xem draw/characters.gd) để chỉ còn đúng 2 tay.
# Nếu chưa có hidden_arms trong game_state.gd thì vẫn chạy nhưng nhìn ngang sẽ thấy dư một tay.
# NPC bị đánh sẽ phản ứng theo MỘT trong HAI cách (ngẫu nhiên, xác suất CRY_CHANCE):
#   - KHÓC: nước mắt, vũng nước, đứng khóc một lúc (nhờ features/khoc.gd). Đánh tiếp vẫn khóc và NPC đứng yên tại chỗ.
#   - GIẬN: mặt đỏ bừng, hiện dấu giận, nói câu giận. Đánh tới lần thứ 3-4 thì NPC nói một tràng rồi
#           hầm hầm bỏ đi, biến mất vài giây, sau đó xuất hiện lại (NPC có tên về đúng chỗ đứng của mình).
#           Riêng Cô Toán không biến mất (quiz cần cô đứng yên), nói hết tràng rồi nguôi tại chỗ.
# Đang giận/khóc mà bị đánh tiếp thì giữ nguyên cách phản ứng đó. Hết giận/nín thì lần sau tung lại.
# Áp dụng cho sinh viên thường, Cô Toán và các NPC có tên (Thầy LTC, Thầy LĐK, bác bảo vệ, bác giữ xe, cô lao công).
# Chỉ chạy ngoài khuôn viên và trong Căn tin. Các tính năng khác đang bận vẫn chặn đánh, trừ khi đang ở trong Căn tin.
# Chơi online: hiệu ứng chỉ hiện ở máy của bạn (NPC vốn chưa đồng bộ giữa người chơi).
#
# Chỉnh cho hợp ý: các hằng số bên dưới (phím, tầm với, xác suất khóc, số cú đánh làm NPC bỏ đi...) và bảng câu thoại REACTIONS.
# Phụ thuộc mềm: nếu khoc.gd chưa đăng ký thì NPC luôn giận, game vẫn chạy bình thường.
# Đăng ký SAU newcharacters.gd trong scripts/features/registry.gd để hiệu ứng vẽ đè lên NPC có tên.

const POKE_KEY := KEY_H

const POKE_RANGE := 28.0        # NPC cách chân người chơi tối đa bấy nhiêu px thì đánh trúng
const POKE_COOLDOWN := 0.24     # giãn cách giữa hai cú đánh (giây); giữ phím thì cứ chừng này giây đấm một cú
const SWING_TIME := 0.22        # thời gian cánh tay vươn ra rồi thu về (nên nhỏ hơn POKE_COOLDOWN để các cú không chồng nhau)
const IMPACT_TIME := 0.34       # thời gian hiệu ứng "BỐP!"
const FREEZE_TIME := 1.6        # NPC đứng yên bấy nhiêu giây sau khi bị đánh
const KNOCKBACK_SPEED := 80.0   # NPC bị đẩy lùi (px/giây), giảm dần nhanh nên chỉ lùi vài px
const KNOCKBACK_DRAG := 640.0
const CRY_CHANCE := 0.5         # xác suất NPC khóc (còn lại là giận): 0.0 = luôn giận, 1.0 = luôn khóc
const CRY_TIME := 7.0           # NPC khóc bấy nhiêu giây
const ANGRY_TIME := 3.5         # NPC giận (mặt đỏ) bấy nhiêu giây sau cú đánh cuối
const LEAVE_HITS_MIN := 3       # đánh NPC đang giận từ 3 tới 4 cú (mỗi NPC bốc ngẫu nhiên) thì NPC nói một tràng rồi bỏ đi
const LEAVE_HITS_MAX := 4
const RANT_BEAT_TIME := 2.2     # mỗi câu trong "tràng" hiện bấy nhiêu giây
const LEAVE_WALK := 2.2         # NPC hầm hầm bước đi bấy nhiêu giây rồi biến mất
const AWAY_MIN := 5.0           # NPC vắng mặt từ 5 tới 8 giây rồi xuất hiện lại
const AWAY_MAX := 8.0
const PUFF_TIME := 0.5          # thời gian làn khói lúc biến mất/xuất hiện

const ROLE_SCRIPT := "res://scripts/features/newcharacters.gd"
const CANTEEN_SCRIPT := "res://scripts/maps/canteen.gd"
const OUTLINE := Color("1a1a2e")
const NAVY := Color("1b2f6e")
const SKIN := Color("f1c27d")
const SKIN_LIGHT := Color("f8dba6")
const SKIN_DARK := Color("c98e5a")
const CUFF := Color("f4f4f4")
const ANGRY_RED := Color(0.93, 0.14, 0.1)

const IMPACT_WORDS := ["BỐP!", "CỐC!", "BỘP!", "PẶC!"]

# Câu thoại theo vai:
#   angry = câu giận lúc bị đánh, cry = câu khóc,
#   rant  = các "tràng" nói liên tiếp trước khi bỏ đi (mỗi tràng là một danh sách câu, bốc ngẫu nhiên 1 tràng).
# Mỗi lần chọn ngẫu nhiên 1 câu (không lặp câu vừa nói). Vai nào thiếu mục nào thì dùng mục của "default".
# NPC thường chỉ hiện 1 dòng nên giữ câu ngắn (khoảng 30 ký tự); NPC có tên tự xuống dòng nên có thể dài hơn.
# Khóa là id vai trong newcharacters.gd ("thay_ltc"...), "quiz" là Cô Toán, "default" là sinh viên thường.
const REACTIONS := {
	"default": {
		"angry": ["Ê! Làm gì đó hả?", "Đau nha! Chọc hoài!", "Rảnh quá ha?", "Đừng có đụng vào tui!", "Ơ hay! Bị gì vậy?", "Tui giận thiệt đó nha!"],
		"cry": ["Hức... đau thiệt đó...", "Huhu, sao đánh tui...", "Hu hu... tui có làm gì đâu...", "Hức hức... tui méc cô đó...", "Đau quá à... huhu"],
		"rant": [
			["Thôi tui hết chịu nổi rồi!", "Đi chỗ khác chơi nha!", "Hứ!"],
			["Chán ghê, đánh hoài à!", "Tui đi chỗ khác đây!", "Đừng có theo tui nha!"],
			["Biết vậy ở nhà ngủ cho rồi!", "Hứ, tui đi đây!"],
		],
	},
	"quiz": {
		"angry": ["Này! Em giỡn mặt với cô hả?", "Cô cho thêm bài tập giờ!", "Trời đất, nghịch quá!"],
		"cry": ["Hức... cô buồn quá đi...", "Huhu... sao em lại vậy...", "Hức... cô dạy em tận tình mà..."],
		"rant": [
			["Được rồi, em nghịch quá!", "Cô giận thiệt rồi đó nha!", "Lát cô cho thêm bài tập!"],
		],
	},
	"thay_ltc": {
		"angry": ["Này em, giỡn vừa thôi nha!", "Ê ê, thầy trừ điểm bây giờ đó!", "Thầy mà giận là ghê lắm nha."],
		"cry": ["Hức... thầy dạy dễ vậy mà...", "Huhu... thầy tủi thân quá...", "Hức... thầy đâu có làm gì em..."],
		"rant": [
			["Em nghịch quá rồi đó nha!", "Thầy không giảng nữa, thầy đi!", "Mai gặp lại, thầy trừ điểm."],
		],
	},
	"thay_ldk": {
		"angry": ["Ủa em, làm gì thầy vậy?", "Thầy khóa Moodles của em giờ!", "Thôi nha, thầy giận thiệt đó."],
		"cry": ["Hức... Moodles sập luôn rồi...", "Huhu... thầy buồn lắm đó...", "Hức... sao em lại đánh thầy..."],
		"rant": [
			["Thôi, thầy cho mấy em tự học đi!", "Thầy ra ngoài uống ly cà phê.", "Nhớ làm bài trên Moodles nha."],
		],
	},
	"bao_ve": {
		"angry": ["Ê! Đứng lại! Thẻ sinh viên đâu?", "Giỡn kiểu gì vậy hả?", "Bác ghi tên bây giờ đó!"],
		"cry": ["Hức... bác già rồi mà...", "Huhu... bác canh cổng cả ngày...", "Hức... sao lại đánh bác..."],
		"rant": [
			["Được rồi! Bác không thèm chấp!", "Bác đi tuần một vòng đây.", "Đừng để bác bắt gặp nữa!"],
		],
	},
	"giu_xe": {
		"angry": ["Ê, đánh bác hả? Bác không giữ xe nữa à!", "Ủa gì vậy ta? Coi chừng bác tính tiền!", "Nghịch vừa thôi chú em!"],
		"cry": ["Hức... bác chỉ giữ xe thôi mà...", "Huhu... sao lại đánh bác..."],
		"rant": [
			["Thôi bác hết chịu nổi rồi!", "Bác đi uống ly trà đá cái đã.", "Xe tự giữ nha chú em!"],
		],
	},
	"lao_cong": {
		"angry": ["Ơ! Cô vừa lau xong đó!", "Cô quơ chổi giờ đó nha!", "Mấy đứa này hư thiệt!"],
		"cry": ["Hức... cô lau cả buổi mà...", "Huhu... cô có làm gì con đâu..."],
		"rant": [
			["Trời ơi, hết nói nổi mấy đứa này!", "Cô đi lấy cây chổi khác.", "Đừng có làm bẩn nữa đó!"],
		],
	},
}

var _cooldown := 0.0
var _swing_t := -1.0              # >= 0: đang tung cú đánh
var _swing_dir := Vector2.DOWN
var _arm_side := 1.0              # tay đang đấm: -1 = tay trái, +1 = tay phải; đổi tay sau mỗi cú
var _impacts: Array = []          # hiệu ứng chữ "BỐP!" đang hiện: {"pos", "t", "word"}
var _puffs: Array = []            # làn khói lúc NPC biến mất/xuất hiện: {"pos", "t"}
var _away: Array = []             # NPC đang biến mất: {"npc", "t"} (NPC thường bị gỡ khỏi game.npcs, NPC có tên đặt hidden)
var _roles: Variant = null        # feature NPC có tên (tìm khi cần)

# ---------- Nhập liệu ----------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.physical_keycode != POKE_KEY:
		return
	if (game.is_busy() and not _inside_canteen()) or _cooldown > 0.0:
		return
	poke()
	get_viewport().set_input_as_handled()

# Tung một cú đánh: có NPC trong tầm thì quay sang NPC gần nhất và đánh trúng, không thì đấm gió.
func poke() -> void:
	_cooldown = POKE_COOLDOWN
	_swing_dir = _face_vec(int(game.facing))
	var target: Variant = _find_target()
	if target != null:
		var to: Vector2 = target["pos"] - game.player
		game.facing = _face_index(to)
		_swing_dir = _face_vec(int(game.facing))
	_arm_side = -_arm_side   # đấm luân phiên hai tay
	_swing_t = 0.0
	_sync_arm()
	if target != null:
		_hit(target)

# Ẩn tay đang buông ở phía đấm trong lúc ra đòn (tay đấm vẽ ở _draw_hand thay cho nó); hết đòn thì hiện lại
func _sync_arm() -> void:
	if not ("hidden_arms" in game):
		return
	if _swing_t < 0.0:
		game.hidden_arms = 0
	else:
		game.hidden_arms = 1 if _arm_side < 0.0 else 2

func _find_target() -> Variant:
	var best: Variant = null
	var best_d := POKE_RANGE
	var player: Vector2 = _player_pos()
	for n in _all_npcs():
		if n.get("hidden", false):
			continue
		if n.get("mode") == "staff":
			continue
		var d: float = n["pos"].distance_to(player)
		if d <= best_d:
			best = n
			best_d = d
	return best

# Mọi NPC đang hiện: sinh viên thường + NPC có tên (lấy từ features/newcharacters.gd, tìm theo đường dẫn script)
func _all_npcs() -> Array:
	var out: Array = game.npcs.duplicate()
	if _roles == null:
		for f in game.features:
			var s: Script = f.get_script()
			if s != null and s.resource_path == ROLE_SCRIPT:
				_roles = f
				break
	if _roles != null:
		var named: Array = _roles.get("_npcs")
		out.append_array(named)
	var canteen := _canteen()
	if canteen != null:
		var local_npcs: Array = canteen.get("_npcs")
		out.append_array(local_npcs)
	return out

func _canteen() -> Node:
	for f in game.features:
		var s: Script = f.get_script()
		if s != null and s.resource_path == CANTEEN_SCRIPT:
			return f
	for f in game.get_children():
		var s: Script = f.get_script()
		if s != null and s.resource_path == CANTEEN_SCRIPT:
			return f
	return null

func _inside_canteen() -> bool:
	var canteen := _canteen()
	return canteen != null and bool(canteen.get("inside"))

func _player_pos() -> Vector2:
	var canteen := _canteen()
	if canteen != null and bool(canteen.get("inside")):
		var pos: Variant = canteen.get("_pos")
		if pos is Vector2:
			return pos
	return game.player

func _is_canteen_npc(n: Dictionary) -> bool:
	var canteen := _canteen()
	if canteen == null:
		return false
	for other in canteen.get("_npcs"):
		if is_same(other, n):
			return true
	return false

func _cry_feature() -> Variant:
	for f in game.features:
		if f.has_method("start_crying"):
			return f
	return null

# ---------- Phản ứng của NPC ----------
func _fx(n: Dictionary) -> Dictionary:
	if not n.has("fx"):
		n["fx"] = {"hit_t": 0.0, "angry_t": 0.0, "kb": Vector2.ZERO, "hits": 0, "limit": randi_range(LEAVE_HITS_MIN, LEAVE_HITS_MAX),
			"leaving": false, "phase": "", "rant": [], "walk_t": 0.0, "flee": Vector2.ZERO}
	return n["fx"]

func _hit(n: Dictionary) -> void:
	var fx := _fx(n)
	var player: Vector2 = _player_pos()
	var away: Vector2 = n["pos"] - player
	away = away.normalized() if away.length() > 0.5 else _swing_dir
	fx["hit_t"] = IMPACT_TIME
	fx["kb"] = away * KNOCKBACK_SPEED
	if not bool(fx["leaving"]):   # NPC đang bỏ đi thì chỉ bị đẩy một chút, không đổi phản ứng
		n["face"] = _face_index(-away)   # NPC quay sang nhìn người chơi
		_freeze(n, FREEZE_TIME)
		# Giận hay khóc: đang khóc/đang giận thì giữ nguyên, còn không thì tung xúc xắc
		var cry_f: Variant = _cry_feature()
		var cry := false
		if cry_f != null:
			if cry_f.is_crying(n):
				cry = true
			elif not _is_canteen_npc(n) and float(fx["angry_t"]) <= 0.0:
				cry = randf() < CRY_CHANCE
		if cry:
			cry_f.start_crying(n, CRY_TIME)
			fx["angry_t"] = 0.0
			_say(n, "cry")
		else:
			fx["angry_t"] = ANGRY_TIME
			fx["hits"] = int(fx["hits"]) + 1
			if int(fx["hits"]) >= int(fx["limit"]):
				_start_leave(n, fx)
			else:
				_say(n, "angry")
	game.audio.play_sfx("poke")
	var spot: Vector2 = n["pos"] + Vector2(randf_range(-3.0, 3.0), -12.0 + randf_range(-3.0, 3.0))
	_impacts.append({"pos": spot, "t": 0.0, "word": str(IMPACT_WORDS.pick_random())})

# NPC đứng yên một lúc: NPC thường không chọn hướng đi mới, NPC có tên dùng cờ "talk" của newcharacters.gd
func _freeze(n: Dictionary, t: float) -> void:
	n["dir"] = Vector2.ZERO
	if n.has("role"):
		n["talk"] = maxf(float(n["talk"]), t)
	else:
		n["timer"] = maxf(float(n["timer"]), t)

func _role_of(n: Dictionary) -> String:
	var role := str(n.get("role", ""))
	if role == "" and n.get("quiz", false):
		role = "quiz"
	return role

# Danh sách câu của vai theo loại (angry/cry/rant); thiếu thì dùng của "default"
func _pool(n: Dictionary, kind: String) -> Array:
	var rs: Dictionary = REACTIONS.get(_role_of(n), REACTIONS["default"])
	var pool: Array = rs.get(kind, REACTIONS["default"][kind])
	return pool

func _say(n: Dictionary, kind: String) -> void:
	var lines := _pool(n, kind)
	var line := str(lines.pick_random())
	for _i in 4:   # tránh nói lại đúng câu vừa nói
		if line != str(n.get("say", "")):
			break
		line = str(lines.pick_random())
	_say_text(n, line, 2.6 if kind == "cry" else 2.2)

func _say_text(n: Dictionary, text: String, t: float) -> void:
	n["say"] = text
	n["say_t"] = t

# ---------- NPC nói một tràng rồi bỏ đi ----------
func _start_leave(n: Dictionary, fx: Dictionary) -> void:
	if n.get("mode") == "staff":
		fx["leaving"] = true
		fx["phase"] = "rant"
		var rants := _pool(n, "rant")
		var pick: Array = rants.pick_random()
		fx["rant"] = pick.duplicate()
		n["say_t"] = 0.0
		return
	var rants := _pool(n, "rant")
	var pick: Array = rants.pick_random()
	fx["rant"] = pick.duplicate()
	fx["leaving"] = true
	fx["phase"] = "rant"
	n["say_t"] = 0.0   # để câu đầu của tràng hiện ngay

func _update_leaving(n: Dictionary, fx: Dictionary, delta: float) -> void:
	fx["angry_t"] = maxf(float(fx["angry_t"]), 0.8)   # mặt vẫn đỏ suốt lúc bỏ đi
	if str(fx["phase"]) == "rant":
		_freeze(n, 0.3)
		if float(n["say_t"]) > 0.0:
			return
		var beats: Array = fx["rant"]
		if not beats.is_empty():
			_say_text(n, str(beats.pop_front()), RANT_BEAT_TIME)
		elif n.get("quiz", false) or n.get("mode") == "staff":
			fx["leaving"] = false   # Cô Toán không đi đâu: nói hết tràng thì nguôi dần
			fx["angry_t"] = 1.0
			fx["hits"] = 0
			fx["limit"] = randi_range(LEAVE_HITS_MIN, LEAVE_HITS_MAX)
		else:
			fx["phase"] = "walk"
			fx["walk_t"] = LEAVE_WALK
			fx["flee"] = _flee_dir(n)
	else:
		# hầm hầm bước đi bằng chính cơ chế đi của NPC (có hoạt ảnh bước chân), ta chỉ đặt hướng và chặn việc đổi hướng
		fx["walk_t"] = float(fx["walk_t"]) - delta
		n["dir"] = fx["flee"]
		n["timer"] = 1.0
		if n.has("role"):
			n["talk"] = 0.0
		if float(fx["walk_t"]) <= 0.0:
			_vanish(n)

# Hướng bỏ đi: ra xa người chơi theo trục chính; vướng thì thử trục kia
func _flee_dir(n: Dictionary) -> Vector2:
	var pos: Vector2 = n["pos"]
	var d: Vector2 = pos - game.player
	var primary: Vector2 = _face_vec(_face_index(d))
	var side := Vector2(-primary.y, primary.x)
	for c in [primary, side, -side, -primary]:
		if not game.blocked(pos + c * 16.0):
			return c
	return primary

func _vanish(n: Dictionary) -> void:
	_puffs.append({"pos": n["pos"], "t": 0.0})
	n.erase("fx")
	n["dir"] = Vector2.ZERO
	n["say_t"] = 0.0
	var canteen := _canteen()
	if canteen != null and _is_canteen_npc(n):
		n["canteen_away"] = true
		var local_npcs: Array = canteen.get("_npcs")
		for i in local_npcs.size():
			if is_same(local_npcs[i], n):
				local_npcs.remove_at(i)
				break
	elif n.has("role"):
		n["hidden"] = true   # newcharacters.gd bỏ qua NPC hidden (không cập nhật, không vẽ, không nói chuyện được)
	else:
		for i in game.npcs.size():
			if is_same(game.npcs[i], n):
				game.npcs.remove_at(i)
				break
	_away.append({"npc": n, "t": randf_range(AWAY_MIN, AWAY_MAX)})

func _return_npc(n: Dictionary) -> void:
	var canteen := _canteen()
	if canteen != null and n.get("canteen_away", false):
		n.erase("canteen_away")
		var local_npcs: Array = canteen.get("_npcs")
		local_npcs.append(n)
	elif n.has("role"):
		n["pos"] = n["home"]   # NPC có tên về đúng chỗ đứng của mình
		n["hidden"] = false
	else:
		game.npcs.append(n)
	n["face"] = 0
	_freeze(n, 1.5)
	_puffs.append({"pos": n["pos"], "t": 0.0})
	_fx(n)   # có fx thì bóng thoại của NPC được đếm giờ và dọn đúng cách

# ---------- Cập nhật ----------
func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _swing_t >= 0.0:
		_swing_t += delta
		if _swing_t >= SWING_TIME:
			_swing_t = -1.0
			_sync_arm()
	# giữ phím H: cứ hết giãn cách là đấm tiếp (đấm liên hoàn)
	if _cooldown <= 0.0 and (not game.is_busy() or _inside_canteen()) and Input.is_physical_key_pressed(POKE_KEY):
		poke()
	for it in _impacts:
		it["t"] = float(it["t"]) + delta
	_impacts = _impacts.filter(func(it): return float(it["t"]) < IMPACT_TIME)
	for p in _puffs:
		p["t"] = float(p["t"]) + delta
	_puffs = _puffs.filter(func(q): return float(q["t"]) < PUFF_TIME)
	var i := _away.size() - 1
	while i >= 0:
		var e: Dictionary = _away[i]
		e["t"] = float(e["t"]) - delta
		if float(e["t"]) <= 0.0:
			_away.remove_at(i)
			_return_npc(e["npc"])
		i -= 1
	for n in _all_npcs():
		var fx: Variant = n.get("fx")
		if fx != null:
			_update_npc(n, fx, delta)

func _update_npc(n: Dictionary, fx: Dictionary, delta: float) -> void:
	# Cô Toán không được update_npcs() xử lý nên không tự tắt bóng thoại: tự đếm ở đây
	if n.get("quiz", false) and float(n["say_t"]) > 0.0:
		n["say_t"] = float(n["say_t"]) - delta
	fx["hit_t"] = maxf(0.0, float(fx["hit_t"]) - delta)
	fx["angry_t"] = maxf(0.0, float(fx["angry_t"]) - delta)
	var kb: Vector2 = fx["kb"]
	if kb.length() > 1.0:
		n["pos"] = game.move_entity(n["pos"], kb * delta)   # đẩy lùi có va chạm, không xuyên tường
		fx["kb"] = kb.move_toward(Vector2.ZERO, KNOCKBACK_DRAG * delta)
	else:
		fx["kb"] = Vector2.ZERO
	if bool(fx["leaving"]):
		_update_leaving(n, fx, delta)
	elif float(fx["angry_t"]) > 0.0:
		_freeze(n, 0.3)   # NPC giận đứng yên cho tới khi nguôi (NPC khóc đã được khoc.gd giữ đứng yên)
	elif float(fx["hit_t"]) <= 0.0 and float(n["say_t"]) <= 0.0 and fx["kb"] == Vector2.ZERO:
		n.erase("fx")   # NPC đã nguôi hẳn, dọn trạng thái

# ---------- Vẽ ----------
func draw_front_layer() -> void:
	var view: Rect2 = game.view.grow(30.0)
	for n in _all_npcs():
		var fx: Variant = n.get("fx")
		if fx == null or n.get("hidden", false) or not view.has_point(n["pos"]):
			continue
		var angry_t: float = fx["angry_t"]
		if angry_t > 0.0:
			_draw_red_face(n, clampf(angry_t / 0.8, 0.0, 1.0))   # đỏ bừng ngay, nguôi thì nhạt dần
			_draw_anger_mark(n["pos"])
	for it in _impacts:
		_draw_impact(it)
	for p in _puffs:
		_draw_puff(p)
	if _swing_t >= 0.0:
		_draw_hand()
	elif not game.is_busy():   # gợi ý phím khi đứng gần NPC (vẽ dưới chân để không đè bóng thoại)
		var near: Variant = _find_target()
		if near != null:
			var near_pos: Vector2 = near["pos"]
			game.ctext("[H] Đánh", near_pos.x - 30.0, near_pos.y + 11.0, 60.0, 8, Color(1, 1, 1, 0.75))

# Mặt đỏ: phủ màu đỏ trong suốt lên vùng da mặt (dưới tóc), nhấp nhô nhẹ. Quay lưng thì không thấy mặt nên bỏ qua.
func _draw_red_face(n: Dictionary, k: float) -> void:
	var face: int = int(n["face"])
	if face == 1:
		return
	var pos: Vector2 = n["pos"]
	var by: float = pos.y - _bob_npc(n)
	var x0: float = pos.x - 4.0
	var w := 8.0
	if face == 2:
		w = 6.0          # nhìn trái: tóc nằm ở nửa phải đầu
	elif face == 3:
		x0 = pos.x - 2.0 # nhìn phải: tóc nằm ở nửa trái đầu
		w = 6.0
	var a: float = (0.55 + 0.1 * sin(float(game.clock) * 12.0)) * k
	game.rc(x0, by - 18.0, w, 5, Color(ANGRY_RED, a))

# Độ nhún của thân (cùng công thức với draw_role_npc / draw_person) để lớp phủ khớp đúng vị trí mặt.
func _bob_npc(n: Dictionary) -> float:
	var anim: float = n["anim"]
	if not n.has("role"):
		return 1.0 if int(anim * 8.0) % 2 == 1 else 0.0
	var moving: bool = n["dir"] != Vector2.ZERO
	var ph: int = (int(anim * 8.0) % 4) if moving else 0
	if ph == 1 or ph == 3:
		return 1.0
	if not moving and int(float(n["idle_t"]) * 1.6) % 2 == 1:
		return 1.0
	return 0.0

func _bob_player() -> float:
	return 1.0 if int(float(game.anim) * 8.0) % 2 == 1 else 0.0

# Dấu giận (4 góc đỏ) bên phải đầu, nhấp nháy to nhỏ
func _draw_anger_mark(pos: Vector2) -> void:
	var s: float = 6.0 if int(game.clock * 8.0) % 2 == 0 else 5.0
	var x: float = pos.x + 7.0
	var y: float = pos.y - 26.0
	var col := Color("e5322d")
	var corners := [[x, y, 1.0, 1.0], [x + s - 1.0, y, -1.0, 1.0], [x, y + s - 1.0, 1.0, -1.0], [x + s - 1.0, y + s - 1.0, -1.0, -1.0]]
	for c in corners:
		var cx: float = c[0]
		var cy: float = c[1]
		var dx: float = c[2]
		var dy: float = c[3]
		game.rc(cx, cy, 1, 1, col)
		game.rc(cx + dx, cy, 1, 1, col)
		game.rc(cx, cy + dy, 1, 1, col)

# Tia sáng nổ ra tại chỗ trúng + chữ "BỐP!" bay lên và mờ dần
func _draw_impact(it: Dictionary) -> void:
	var p: Vector2 = it["pos"].round()
	var k: float = clampf(float(it["t"]) / IMPACT_TIME, 0.0, 1.0)
	var a: float = 1.0 - k
	var gold := Color(1.0, 0.85, 0.2, a)
	var r: float = roundf(2.0 + 5.0 * k)
	game.rc(p.x - 1.0, p.y - 1.0, 2, 2, Color(1, 1, 1, a))
	game.rc(p.x - r - 2.0, p.y, 2, 1, gold)
	game.rc(p.x + r, p.y, 2, 1, gold)
	game.rc(p.x, p.y - r - 2.0, 1, 2, gold)
	game.rc(p.x, p.y + r, 1, 2, gold)
	var d: float = roundf(r * 0.7)
	game.rc(p.x - d, p.y - d, 1, 1, gold)
	game.rc(p.x + d, p.y - d, 1, 1, gold)
	game.rc(p.x - d, p.y + d, 1, 1, gold)
	game.rc(p.x + d, p.y + d, 1, 1, gold)
	game.ctext(str(it["word"]), p.x - 24.0, p.y - 8.0 - 10.0 * k, 48.0, 8, Color(1.0, 0.82, 0.25, a))

# Làn khói tròn nở ra rồi tan: lúc NPC biến mất và lúc xuất hiện lại
func _draw_puff(p: Dictionary) -> void:
	var pos: Vector2 = p["pos"]
	var k: float = clampf(float(p["t"]) / PUFF_TIME, 0.0, 1.0)
	var a: float = 1.0 - k
	var r: float = 3.0 + 9.0 * k
	game.rc(roundf(pos.x - 4.0), roundf(pos.y - 14.0), 8, 8, Color(0.92, 0.92, 0.96, 0.45 * a))
	for i in 8:
		var q: Vector2 = pos + Vector2(0.0, -10.0) + Vector2.from_angle(i * TAU / 8.0) * Vector2(r, r * 0.85)
		game.rc(roundf(q.x) - 1.0, roundf(q.y) - 1.0, 3, 3, Color(0.95, 0.95, 0.98, 0.8 * a))

# Cú đánh: cánh tay vươn ra từ VAI, thay thế đúng cánh tay đang buông (đã ẩn qua game.hidden_arms) nên không mọc thêm tay,
# ruột áo navy + cổ tay áo trắng + bàn tay có đổ bóng; vươn nhanh, thu về chậm; có bóng mờ phía sau và vệt gió cong
func _draw_hand() -> void:
	var t: float = clampf(_swing_t / SWING_TIME, 0.0, 1.0)
	var player: Vector2 = game.player
	var by: float = player.y - _bob_player()
	var origin := Vector2(player.x + _arm_side * 6.0, by - 9.0)   # vai của tay đang đấm (tay buông tương ứng đã bị ẩn)
	var out: float = _reach(t)
	var tip := (origin + _swing_dir * (3.0 + 9.0 * out)).round()
	var a := origin.round()
	var perp := Vector2(-_swing_dir.y, _swing_dir.x)
	# bóng mờ của bàn tay ở hai vị trí trước đó (chỉ lúc đang vươn ra)
	if t < 0.5:
		for i in 2:
			var tt: float = maxf(t - 0.07 * (i + 1), 0.0)
			var ghost := (origin + _swing_dir * (3.0 + 9.0 * _reach(tt))).round()
			_draw_hand_shape(ghost, 0.28 - 0.1 * i, false)
	# cánh tay: viền ngoài 4px, ruột áo 2px
	_bar(a, tip - _swing_dir * 2.0, 4.0, OUTLINE)
	_bar(a, tip - _swing_dir * 2.0, 2.0, NAVY)
	# cổ tay áo trắng
	_bar(tip - _swing_dir * 3.0, tip - _swing_dir * 3.0, 4.0, OUTLINE)
	_bar(tip - _swing_dir * 3.0, tip - _swing_dir * 3.0, 2.0, CUFF)
	_draw_hand_shape(tip, 1.0, true)
	# vệt gió cong phía trước bàn tay lúc ra đòn mạnh nhất
	if out > 0.55:
		for i in range(-2, 3):
			var q: Vector2 = (tip + _swing_dir * (6.0 - absf(i) * 1.5) + perp * (i * 2.5)).round()
			game.rc(q.x, q.y, 1, 1, Color(1, 1, 1, 0.85 * out))

# 0 -> 1 nhanh, giữ một chút rồi về 0 chậm hơn
func _reach(t: float) -> float:
	if t < 0.35:
		return sin(t / 0.35 * PI * 0.5)
	return cos((t - 0.35) / 0.65 * PI * 0.5)

# Bàn tay nắm lại: viền bo góc, da có sáng/tối, vạch đốt ngón ở phía trước
func _draw_hand_shape(c: Vector2, alpha: float, detail: bool) -> void:
	game.rc(c.x - 2.0, c.y - 1.0, 5, 3, Color(OUTLINE, alpha))
	game.rc(c.x - 1.0, c.y - 2.0, 3, 5, Color(OUTLINE, alpha))
	game.rc(c.x - 1.0, c.y - 1.0, 3, 3, Color(SKIN, alpha))
	if detail:
		game.rc(c.x - 1.0, c.y - 1.0, 1, 1, SKIN_LIGHT)
		game.rc(c.x + 1.0, c.y + 1.0, 1, 1, SKIN_DARK)
		var front := c + _swing_dir
		var side := Vector2(-_swing_dir.y, _swing_dir.x)
		for i in range(-1, 2):
			var kpos: Vector2 = front + side * i
			game.rc(kpos.x, kpos.y, 1, 1, SKIN_DARK)

# Thanh chữ nhật nối a -> b (cùng trục) với độ dày w, căn giữa theo trục vuông góc
func _bar(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var h := w / 2.0
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(h, h)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(h, h)
	game.rc(lo.x, lo.y, hi.x - lo.x, hi.y - lo.y, col)

# ---------- Hướng ----------
# 0 = xuống, 1 = lên, 2 = trái, 3 = phải (giống người chơi và NPC)
func _face_vec(i: int) -> Vector2:
	match i:
		0:
			return Vector2.DOWN
		1:
			return Vector2.UP
		2:
			return Vector2.LEFT
	return Vector2.RIGHT

func _face_index(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 2 if v.x < 0.0 else 3
	return 1 if v.y < 0.0 else 0
