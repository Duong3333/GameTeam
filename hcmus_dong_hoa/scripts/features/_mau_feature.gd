extends "res://scripts/features/feature.gd"
# FILE MẪU - copy file này, đổi tên (vd diem_danh.gd), sửa nội dung, rồi thêm 1 dòng vào registry.gd.
# File này KHÔNG được đăng ký nên không chạy trong game.
#
# Những thứ dùng được từ game:
#   game.player (vị trí), game.stats.add_drl(+1, "lý do"), game.game_min, game.day, game.audio.play_sfx("tên")

func _ready() -> void:
	pass   # chạy 1 lần khi feature được thêm vào game (tạo UI ở đây nếu cần)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F:   # ví dụ: bấm F
			print("Feature mẫu: đã bấm F")

func _process(_delta: float) -> void:
	pass   # chạy mỗi khung hình; nhớ kiểm tra "if not active: return" nếu chỉ chạy khi đang bật
