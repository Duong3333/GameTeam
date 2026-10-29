extends "res://scripts/draw/overlay.gd"
# MAIN - điều phối chính của game. Toàn bộ logic nằm ở các file phía trên (xem HUONG_DAN.md):
#   data/game_data.gd -> core/game_state.gd -> core/world_update.gd -> core/world_setup.gd
#   -> draw/pen.gd -> draw/scenery.gd -> draw/structures.gd -> draw/characters.gd -> draw/overlay.gd -> main.gd
# Mỗi file kế thừa file đứng trước nó, nên các hàm gọi nhau bình thường.

const Feature := preload("res://scripts/features/feature.gd")
const AudioManager := preload("res://scripts/systems/audio_manager.gd")
const StudentStats := preload("res://scripts/features/student_stats.gd")

func _ready() -> void:
	setup_world()
	stats = StudentStats.new()   # phải tạo TRƯỚC setup_features(): student_hud đọc game.stats trong _ready()
	add_child(stats)
	audio = AudioManager.new()
	add_child(audio)
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
	for f in features:
		f.draw_front_layer()
	draw_sky_effects()
	draw_minimap()

# Tua nhanh để thử/demo: sang n ngày sau, bắt đầu lại từ 7:00
func skip_days(n: int) -> void:
	day += n
	game_min = 7.0 * 60.0

# ---------- Chức năng mở rộng (câu cá, đánh nhau, điểm danh, ...) ----------
func setup_features() -> void:
	# Mỗi chức năng mới là 1 file trong scripts/features/, đăng ký ở đây:
	add_feature(preload("res://scripts/features/fishing.gd").new())   # câu cá ở Hồ sinh viên
	add_feature(preload("res://scripts/features/student_hud.gd").new())    # 2 thanh GPA/rèn luyện, đồng hồ
	add_feature(preload("res://scripts/features/student_panel.gd").new())  # sổ tay (Tab)

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
