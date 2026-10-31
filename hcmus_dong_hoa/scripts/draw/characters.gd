extends "res://scripts/draw/structures.gd"
# NHÂN VẬT: người (người chơi + NPC), bóng thoại, xe máy.

# nhân vật pixel: áo polo trường (cổ xanh navy sọc trắng, vai trắng, thân và tay navy, logo ngực)
func draw_person(pos: Vector2, shirt: Color, hair: Color, face: int, step: float, uni: bool, long_hair: bool, pack: bool) -> void:
	var skin := Color("f1c27d")
	var ol := Color("1a1a2e")
	var navy := Color("1b2f6e")
	var odd := int(step * 8.0) % 2 == 1
	var sw := 1.0 if odd else 0.0
	var bob := 1.0 if odd else 0.0
	shadow(pos + Vector2(0, 1), 8.0)
	# chân và giày
	rc(pos.x - 5, pos.y - 7 + sw, 4, 7 - sw, ol)
	rc(pos.x + 1, pos.y - 7 + (1.0 - sw), 4, 7 - (1.0 - sw), ol)
	rc(pos.x - 4, pos.y - 6 + sw, 2, 4 - sw, Color("2b2f4a"))
	rc(pos.x + 2, pos.y - 6 + (1.0 - sw), 2, 4 - (1.0 - sw), Color("2b2f4a"))
	rc(pos.x - 4, pos.y - 2 + sw * 0.0, 3, 2, Color("f4f4f4"))
	rc(pos.x + 1, pos.y - 2, 3, 2, Color("f4f4f4"))
	var by := pos.y - bob
	# ba lô (phía sau lưng)
	if pack and face == 1:
		rc(pos.x - 6, by - 14, 12, 10, ol)
		rc(pos.x - 5, by - 13, 10, 8, Color("2f6bd0"))
		rc(pos.x - 5, by - 13, 10, 2, Color("5b8de8"))
	elif pack and face == 2:
		rc(pos.x + 3, by - 13, 4, 8, ol)
		rc(pos.x + 4, by - 12, 2, 6, Color("2f6bd0"))
	elif pack and face == 3:
		rc(pos.x - 7, by - 13, 4, 8, ol)
		rc(pos.x - 6, by - 12, 2, 6, Color("2f6bd0"))
	# thân
	rc(pos.x - 6, by - 14, 12, 10, ol)
	rc(pos.x - 8, by - 13, 2, 7, ol)
	rc(pos.x + 6, by - 13, 2, 7, ol)
	if uni:
		rc(pos.x - 5, by - 13, 10, 4, Color.WHITE)
		rc(pos.x - 5, by - 9, 10, 5, navy)
		rc(pos.x - 7, by - 12, 2, 6, navy)
		rc(pos.x + 5, by - 12, 2, 6, navy)
		rc(pos.x - 3, by - 14, 6, 2, navy)
		rc(pos.x - 3, by - 13, 6, 1, Color("dfe6ff"))
		rc(pos.x - 5, by - 5, 10, 1, navy.darkened(0.3))
		if face == 0:
			rc(pos.x, by - 13, 1, 5, navy)
			if logo != null:
				draw_texture_rect(logo, Rect2(pos.x + 1, by - 12, 4, 4), false)
			else:
				rc(pos.x + 1, by - 12, 3, 3, navy)
				rc(pos.x + 2, by - 11, 1, 1, Color.WHITE)
	else:
		rc(pos.x - 5, by - 13, 10, 8, shirt)
		rc(pos.x - 7, by - 12, 2, 6, shirt)
		rc(pos.x + 5, by - 12, 2, 6, shirt)
		rc(pos.x - 5, by - 13, 10, 2, shirt.lightened(0.2))
		rc(pos.x - 5, by - 6, 10, 1, shirt.darkened(0.25))
	rc(pos.x - 7, by - 7, 2, 2, skin)
	rc(pos.x + 5, by - 7, 2, 2, skin)
	# đầu
	rc(pos.x - 5, by - 22, 10, 9, ol)
	rc(pos.x - 4, by - 21, 8, 8, skin)
	rc(pos.x - 4, by - 21, 8, 3, hair)
	rc(pos.x - 3, by - 22, 3, 1, hair.lightened(0.3))
	if long_hair:
		rc(pos.x - 5, by - 21, 1, 9, hair)
		rc(pos.x + 4, by - 21, 1, 9, hair)
	if face == 1:
		rc(pos.x - 4, by - 21, 8, 8, hair)
		rc(pos.x - 3, by - 21, 3, 1, hair.lightened(0.3))
	elif face == 0:
		rc(pos.x - 3, by - 17, 1, 2, ol)
		rc(pos.x + 2, by - 17, 1, 2, ol)
		rc(pos.x - 3, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x + 2, by - 15, 1, 1, Color("e8a08a"))
		rc(pos.x - 1, by - 14, 2, 1, Color("a0522d"))
	elif face == 2:
		rc(pos.x - 3, by - 17, 1, 2, ol)
		rc(pos.x + 2, by - 21, 2, 6, hair)
	else:
		rc(pos.x + 2, by - 17, 1, 2, ol)
		rc(pos.x - 4, by - 21, 2, 6, hair)

func draw_speech(n: Dictionary) -> void:
	var w := font.get_string_size(n.say, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8.0
	rc(n.pos.x - w / 2.0 - 1, n.pos.y - 39, w + 2, 14, Color("333333"))
	rc(n.pos.x - w / 2.0, n.pos.y - 38, w, 12, Color.WHITE)
	rc(n.pos.x - 1, n.pos.y - 26, 3, 3, Color.WHITE)
	draw_string(font, Vector2(n.pos.x - w / 2.0 + 4.0, n.pos.y - 29), n.say, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)

func draw_quiz_marker(n: Dictionary) -> void:
	ctext("Thầy Toán", n.pos.x - 25, n.pos.y - 27, 50, 8, Color("7fe0a0"))
	ctext("?", n.pos.x - 6, n.pos.y - 34 + sin(clock * 4.0) * 2.0, 12, 11, Color("ffd23f"))

func draw_bike(b: Dictionary) -> void:
	var x: float = b.x
	var y: float = b.y
	if not view.grow(20.0).has_point(Vector2(x, y)):
		return
	shadow(Vector2(x + 8, y + 7), 10.0)
	rc(x, y, 14, 4, b.col)
	rc(x + 2, y - 1, 8, 2, b.col.lightened(0.3))
	rc(x, y + 3, 4, 4, Color.BLACK)
	rc(x + 10, y + 3, 4, 4, Color.BLACK)
	rc(x + 1, y + 4, 2, 2, Color("9aa3ad"))
	rc(x + 11, y + 4, 2, 2, Color("9aa3ad"))
	rc(x + 5, y - 8, 4, 8, Color("e8e8e8"))
	rc(x + 5, y - 12, 4, 4, Color("f1c27d"))
	rc(x + 4, y - 14, 6, 3, Color("cc2b2b"))
