extends "res://scripts/draw/overlay.gd"
# MAIN - điều phối chính của game. Toàn bộ logic nằm ở các file phía trên (xem HUONG_DAN.md):
#   data/game_data.gd -> core/game_state.gd -> core/world_update.gd -> core/world_setup.gd
#   -> draw/pen.gd -> draw/scenery.gd -> draw/structures.gd -> draw/characters.gd -> draw/overlay.gd -> main.gd
# Mỗi file kế thừa file đứng trước nó, nên các hàm gọi nhau bình thường.

const Feature := preload("res://scripts/features/feature.gd")
const AudioManager := preload("res://scripts/systems/audio_manager.gd")

func _ready() -> void:
	setup_world()
	audio = AudioManager.new()
	add_child(audio)
	setup_features()

func _physics_process(delta: float) -> void:
	if not is_busy():
		update_player(delta)
	update_npcs(delta)

func _process(delta: float) -> void:
	game_min += delta
	if game_min >= 17.0 * 60.0:
		game_min = 7.0 * 60.0
	cam.position = player
	clock += delta
	update_ambient(delta)
	update_bikes(delta)
	update_daylight()
	update_hud()
	queue_redraw()

func _draw() -> void:
	var cc := cam.get_screen_center_position()
	view = Rect2(cc - Vector2(262, 152), Vector2(524, 304))
	draw_ground()
	draw_dieuhanh()
	for b in BUILDINGS:
		draw_building(b)
	for k in KIOSKS:
		draw_kiosk(k)
	for bk in bikes:
		draw_bike(bk)
	draw_sorted_items()
	draw_sky_effects()
	draw_minimap()

# ---------- Chức năng mở rộng (câu cá, đánh nhau, điểm danh, ...) ----------
func setup_features() -> void:
	# Chưa có chức năng nào. Khi tạo file mới trong scripts/features/, đăng ký ở đây, ví dụ:
	#   add_feature(preload("res://scripts/features/fishing.gd").new())
	pass

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
