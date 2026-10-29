extends Node
# LỚP NỀN CHO MỌI CHỨC NĂNG (câu cá, đánh nhau, điểm danh, học thư viện, tập thể dục, nói chuyện với NPC...).
#
# Cách thêm 1 chức năng mới, ví dụ câu cá:
#   1. Tạo scripts/features/fishing.gd:
#        extends "res://scripts/features/feature.gd"
#        func begin() -> void:
#            super()                        # bật active -> người chơi đứng yên
#            game.audio.play_sfx("splash")
#        func finish() -> void:
#            super()
#      Chức năng là một Node nên tự có _process(delta) và _unhandled_input(event);
#      nhớ kiểm tra "if not active: return" ở đầu các hàm đó.
#   2. Đăng ký trong main.gd, hàm setup_features():
#        add_feature(preload("res://scripts/features/fishing.gd").new())
#   3. Gọi begin() khi người chơi bấm phím / đứng đúng chỗ, gọi finish() khi xong.

var game: Node2D     # tham chiếu tới Main, main.gd gán khi đăng ký (dùng game.player, game.audio, ...)
var active := false  # true = đang chạy; khi đó người chơi không di chuyển được

func begin() -> void:
	active = true

func finish() -> void:
	active = false
