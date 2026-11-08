extends Node
# LỚP NỀN CHO GAMEPLAY DÙNG CHUNG VÀ MODULE BẢN ĐỒ CÓ TƯƠNG TÁC.
#
# Cách thêm một chức năng mới:
#   1. Tạo script kế thừa lớp này:
#        extends "res://scripts/features/feature.gd"
#        func begin() -> void:
#            super()                        # bật active -> người chơi đứng yên
#            game.audio.play_sfx("splash")
#        func finish() -> void:
#            super()
#      Chức năng là một Node nên tự có _process(delta) và _unhandled_input(event);
#      nhớ kiểm tra "if not active: return" ở đầu các hàm đó.
#   2. Đăng ký gameplay dùng chung trong scripts/features/registry.gd;
#      module riêng của công trình/khu vực đăng ký trong scripts/maps/registry.gd.
#   3. Gọi begin() khi người chơi bấm phím / đứng đúng chỗ, gọi finish() khi xong.
#   4. (Tùy chọn) Muốn vẽ thêm thứ gì lên thế giới (cần câu, hiệu ứng...) thì ghi đè draw_front_layer().
#      Hàm này được main.gd gọi trong _draw(), sau khi vẽ người và cây; dùng game.draw_line(...), game.rc(...), game.ctext(...).
#      Muốn vẽ giao diện cố định trên màn hình thì tạo CanvasLayer + Control.

var game: Node2D     # tham chiếu tới Main, main.gd gán khi đăng ký (dùng game.player, game.audio, ...)
var active := false  # true = đang chạy; khi đó người chơi không di chuyển được

func begin() -> void:
	active = true

func finish() -> void:
	active = false

# Vẽ lên thế giới, sau người/cây (ghi đè nếu cần). Được gọi mỗi khung hình trong main.gd -> _draw().
func draw_front_layer() -> void:
	pass
