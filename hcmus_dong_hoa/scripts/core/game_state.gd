extends "res://scripts/maps/campus_data.gd"
# TRẠNG THÁI GAME - các biến dùng chung cho mọi file phía dưới (vị trí người chơi, NPC, giờ, camera...).

var solids: Array = []
var trees: Array = []   # [x, y, loại] 0 thường, 1 phượng, 2 cọ
var tufts: Array = []
var npcs: Array = []
var bikes: Array = []
var player := Vector2(740, 940)
var facing := 1
var anim := 0.0
var game_min := 7.0 * 60.0
var logo: Texture2D = null
var font: Font
var cam: Camera2D
var hud: Label          # dòng tên khu vực (dưới thanh chỉ số)
var day := 0            # số ngày đã trôi (0 = Thứ 2 của tuần 1)
var stats: Node          # StudentStats: GPA và điểm rèn luyện
var tint: ColorRect
var clock := 0.0
var view := Rect2()
var flowers: Array = []
var petals: Array = []
var lamps: Array = []
var benches: Array = []
var clouds: Array = []
var rng: RandomNumberGenerator
var audio: Node          # AudioManager (scripts/systems/audio_manager.gd)
var features: Array = [] # gameplay dùng chung và module bản đồ đã đăng ký
