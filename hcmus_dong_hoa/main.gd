extends "res://scripts/maps/campus_overlay.gd"
# MAIN - điều phối chính của game. Toàn bộ logic nằm ở các file phía trên (xem HUONG_DAN.md):
#   maps/campus_data.gd -> core/game_state.gd -> maps/campus_update.gd -> maps/campus_setup.gd
#   -> draw/pen.gd -> maps/campus_scenery.gd -> maps/campus_structures.gd -> draw/characters.gd
#   -> draw/newcharacters.gd -> maps/campus_overlay.gd -> main.gd
# Mỗi file kế thừa file đứng trước nó, nên các hàm gọi nhau bình thường.

const Feature := preload("res://scripts/features/feature.gd")
const AudioManager := preload("res://scripts/systems/audio_manager.gd")
const Registry := preload("res://scripts/features/registry.gd")
const MapRegistry := preload("res://scripts/maps/registry.gd")
const StudentStats := preload("res://scripts/features/student_stats.gd")

func _ready() -> void:
	setup_world()
	stats = StudentStats.new()   # phải tạo TRƯỚC setup_features(): student_hud đọc game.stats trong _ready()
	add_child(stats)
	audio = AudioManager.new()
	add_child(audio)
	audio.play_music("xuongrongpiano")
	setup_features()

func _physics_process(delta: float) -> void:
	if not is_busy():
		update_player(delta)
	update_npcs(delta)

func _process(delta: float) -> void:
	game_min += delta * TIME_SCALE
	if game_min >= 17.0 * 60.0:
		game_min = 7.0 * 60.0
		day += 1
	cam.position = player
	clock += delta
	update_ambient(delta)
	update_bikes(delta)
	update_daylight()
	update_hud()
	queue_redraw()

# Tua nhanh để thử/demo: sang n ngày sau, bắt đầu lại từ 7:00
func skip_days(n: int) -> void:
	day += n
	game_min = 7.0 * 60.0

# ---------- Chức năng mở rộng (câu cá, điểm danh, ...) ----------
func setup_features() -> void:
	_load_registry(Registry.LIST, "features/registry.gd")

func setup_map_modules() -> void:
	_load_registry(MapRegistry.LIST, "maps/registry.gd")

func _load_registry(paths: Array, registry_name: String) -> void:
	for path in paths:
		if not ResourceLoader.exists(path):
			push_warning("%s: không tìm thấy %s" % [registry_name, path])
			continue
		var script: Script = load(path)
		if not script.can_instantiate():
			push_error("%s: không thể khởi tạo %s" % [registry_name, path])
			continue
		add_feature(script.new())

func add_feature(f: Feature) -> void:
	f.game = self
	features.append(f)
	add_child(f)

# true khi có chức năng đang chạy -> người chơi đứng yên (NPC và xe máy vẫn chạy)
func is_busy() -> bool:
	for f in features:
		if f.active:
			return true
	return false
