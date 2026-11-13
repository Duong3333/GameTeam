extends "res://scripts/features/feature.gd"
# CHẠY NHANH: giữ Shift khi đi (W A S D) để chạy nhanh hơn 1.6 lần ngoài khuôn viên.
# Không sửa file lõi: game vẫn tự đi theo SPEED, file này chỉ cộng THÊM một đoạn đường cùng hướng
# (qua game.move_entity nên vẫn va chạm với tòa nhà, cây, vật cản như bình thường) và quay bước chân nhanh hơn.
# Trong phòng của từng tòa (Thư viện...) Shift do chính phòng đó xử lý. Khi đang chơi nhiều người thì không dùng
# (multiplayer_manager tự điều khiển di chuyển).

const RUN_MULT := 1.6

func _physics_process(delta: float) -> void:
	if game.is_busy():
		return
	if game.multiplayer_manager != null and game.multiplayer_manager.is_connected_to_session():
		return
	if not Input.is_physical_key_pressed(KEY_SHIFT):
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if v == Vector2.ZERO:
		return
	var extra: Vector2 = v.normalized() * game.SPEED * (RUN_MULT - 1.0) * delta
	game.player = game.move_entity(game.player, extra)
	game.anim += delta * (RUN_MULT - 1.0)
