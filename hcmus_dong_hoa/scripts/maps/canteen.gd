extends "res://scripts/features/feature.gd"
signal money_changed(amount: int, reason: String)
# CĂN TIN HCMUS ĐÔNG HÒA (toàn bộ nằm trong file này).
#
# Ngoài trời : tòa căn tin kem có cửa kính, mái hiên xanh, bảng "CĂN TIN HCMUS", sân sỏi trắng xám với bàn ghế sắt đen
#              (tay vịn cam), mái che kính + cờ đuôi nheo, cây cọ. Nằm phía bắc các tòa C/D, sân kết thúc ở y=180.
# Bên trong  : quầy bán hàng có menu, tủ kính, nhân viên áo xanh, khu thanh toán; khu ăn uống bàn gỗ cam + ghế sắt xám,
#              cột trắng, đèn trần; sinh viên ngồi ăn, trò chuyện, xếp hàng, đi giữa các bàn.
# Tương tác  : phím E (một lần bấm chỉ làm MỘT việc, xem _pick_action): đóng/tiếp hội thoại > đứng dậy > NPC (trò chuyện)
#              > ghế (ngồi) > cửa (vào / ra). Q hoặc Esc đóng hội thoại.
#              Đã bỏ cho người chơi: dùng bàn, đặt / lấy đồ, thực đơn, mua đồ, máy nước, cốc nhựa, thùng rác, ăn uống.
#              (NPC vẫn ngồi, ăn, bỏ rác như cũ để căn tin có không khí. Biến money vẫn giữ vì ATM dùng làm ví tiền.)
# Đăng ký   : 1 dòng trong scripts/maps/registry.gd. Không có script phụ nào khác.
#
# Dùng lại của game: BUILDINGS (va chạm, minimap, tên khu vực), ZONES, solids, trees, draw_person/draw_speech/rc/ctext/
# shadow/paved/hedge/draw_tree/draw_kiosk, begin()/finish()/active của feature.gd, is_busy().
# Ví chung của game được giữ tại đây; StudentStats, HUD, ATM và mini quiz NPC dùng cùng số dư.
#   Bắt đầu với 0đ; nhận +500.000đ mỗi tuần mới trong game.

# ---------- Tiến độ triển khai (giai đoạn) ----------
# 2: vị trí, nền sân, đăng ký module, cửa vào/ra (nội thất tạm), kiosk Nhà ăn cũ trong sân đã bị xóa khỏi KIOSKS (campus_data.gd).
# 3: kiến trúc và không gian ngoài trời (mặt tiền, bàn ghế sân, mái che, dây cờ, cây).
# 3b: hoàn thiện sân: va chạm bàn/ghế/cột/chậu khớp hình, y-sort (tán dù che người đứng phía sau), ngồi ghế ngoài sân
#     (E ngồi, E hoặc phím di chuyển để đứng dậy), NPC sân tự tìm ghế, ngồi, đứng dậy, dạo, rời đi,
#     bàn đặt tối đa 5 món (E ở bàn; T khi đang ngồi). Giao diện bàn: W S chọn, A D đổi cột, E đặt/lấy, Q đóng.
# 4 (đã bật, 4A): nội thất đầy đủ (sàn, tường, cửa kính, trần, đèn, quạt, quầy, tủ kính, menu, bàn ghế, cầu thang) - chưa có NPC/mua bán.
# 5: NPC + hội thoại | 6: ngồi ghế + cửa hàng (code các phần này đã có sẵn bên dưới, bật dần theo STAGE).
const STAGE := 6

# ---------- Ngoài trời (tọa độ thế giới) ----------
# Khu canteen nằm phía bắc các tòa C/D; toàn bộ sân kết thúc trước y=180 để không đè lên mái tòa.
const BUILDING := Rect2(566, 0, 140, 96)
const YARD := Rect2(384, 96, 338, 84)
const DOOR_OUT := Vector2(636, 106)
const SPAWN_OUT := Vector2(636, 122)
const CANOPY := Rect2(664, 100, 58, 80)      # mái che kính phía đông: nền x 664-722, y 100-180 (cột cao 34px)
const CANOPY_H := 34.0
const POSTS := [Vector2(664, 100), Vector2(720, 100), Vector2(664, 180), Vector2(720, 180)]
const PARASOLS := [Vector2(440, 120), Vector2(440, 172)]   # chân cột dù xanh lớn (dù cao 40px)
const POTS := [Vector2(618, 101), Vector2(654, 101)]
const DOOR_RANGE := 28.0
const SEAT_RANGE := 24.0
const TALK_RANGE := 26.0
const TABLE_RANGE := 18.0       # từ chân người tới mép bàn để bấm E dùng bàn
const TABLE_MAX := 5            # số món tối đa trên một bàn
const SIT_GRACE := 0.3          # vừa ngồi xong chưa cho đứng dậy bằng phím di chuyển
const YARD_NPC_SPEED := 24.0
const NAV_CELL := 4.0           # lưới tìm đường cho NPC sân: mỗi ô 4px, ô bị chặn theo đúng game.blocked()
const NAV_RECT := Rect2(372, 88, 360, 108)
const NAV_DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
const YARD_WALK := Rect2(388, 100, 330, 76)   # NPC sân chỉ được đứng/đi trong khung sân sỏi
const BIG_TREE := Vector2(528, 98)            # gốc cây lớn thay hai cây cọ cũ (x 500 và 558)
# trọng số hành vi [ngồi, nói chuyện, đi dạo, đứng nghỉ] theo tính cách NPC
const KIND_W := {"sitter": [0.60, 0.10, 0.15, 0.15], "social": [0.25, 0.40, 0.15, 0.20], "roamer": [0.20, 0.10, 0.55, 0.15]}
# 5 ô trên mặt bàn (tâm x, đáy y so với tâm bàn): 3 ô hàng trước, 2 ô hàng sau, không ô nào đè lên ô khác
const SLOTS := [Vector2(-8, 4), Vector2(0, 4), Vector2(8, 4), Vector2(-4, -1), Vector2(4, -1)]
const ITEM_CATS := ["Đồ ăn", "Nước uống", "Học tập", "Thiết bị", "Cá nhân"]
const ITEM_LIST := ["com_ga", "com_suon", "mi_xao", "banh_mi", "banh_ngot", "hop_com", "do_an_nhe", "chai_nuoc", "nuoc_suoi", "ly_nuoc", "ca_phe", "tra", "tra_dao", "tra_tac", "coc_nhua", "coc_nuoc", "coc_da_dung", "binh_nuoc", "binh_nuoc_day",
	"sach", "vo", "giay", "but", "laptop", "dien_thoai", "may_tinh_bang", "hop_but", "tui_nho"]
# 4C: danh sách đầy đủ id vật phẩm (món cửa hàng, cốc, bình) để túi đồ và giao diện bàn dùng chung
const ITEM_ALL := ["com_ga", "com_suon", "mi_xao", "tra_dao", "tra_tac", "nuoc_suoi", "coc_nhua", "coc_nuoc", "coc_da_dung", "binh_nuoc", "binh_nuoc_day"]
# Hình pixel của vật phẩm: [x, y, rộng, cao, màu], gốc = giữa đáy món đồ, y âm = đi lên. Một nguồn dùng cho cả mặt bàn lẫn giao diện.
const ITEMS := {
	"banh_mi": {"n": "Bánh mì", "c": 0, "px": [[-2, -4, 5, 1, "e6b866"], [-3, -3, 7, 2, "d9a04a"], [-2, -1, 5, 1, "a8702a"], [-1, -3, 1, 1, "f4dca0"], [1, -3, 1, 1, "f4dca0"], [3, -2, 1, 1, "7bb04a"]]},
	"banh_ngot": {"n": "Bánh ngọt", "c": 0, "px": [[-3, -1, 7, 1, "f5f5f5"], [-2, -4, 5, 3, "f3d29a"], [-2, -3, 5, 1, "c0793a"], [-2, -5, 5, 1, "f08aa8"], [0, -6, 1, 1, "d4221e"]]},
	"hop_com": {"n": "Hộp cơm", "c": 0, "px": [[-3, -3, 7, 3, "e9e9e9"], [-3, -5, 7, 2, "3a9a48"], [-3, -5, 7, 1, "5fc06a"], [0, -5, 1, 5, "2c6f35"], [-3, -1, 7, 1, "c9c9c9"]]},
	"do_an_nhe": {"n": "Đồ ăn nhẹ", "c": 0, "px": [[-2, -5, 5, 5, "d4221e"], [-2, -6, 5, 1, "f1c40f"], [-1, -4, 3, 2, "ffde3a"], [-2, -1, 5, 1, "a01a16"]]},
	"chai_nuoc": {"n": "Chai nước", "c": 1, "px": [[0, -8, 1, 2, "2f6bd0"], [-1, -6, 3, 6, "bfe6ff"], [-1, -3, 3, 2, "2f6bd0"], [-1, -5, 1, 3, "ffffff"]]},
	"ly_nuoc": {"n": "Ly nước", "c": 1, "px": [[-2, -5, 4, 5, "cdeeff"], [-2, -3, 4, 3, "8ecbf0"], [-2, -5, 4, 1, "ffffff"], [1, -7, 1, 3, "e74c3c"]]},
	"ca_phe": {"n": "Cà phê", "c": 1, "px": [[-3, -1, 7, 1, "f0f0f0"], [-2, -4, 5, 3, "ffffff"], [-2, -4, 5, 1, "5a3416"], [3, -3, 1, 2, "dcdcdc"], [-1, -7, 1, 2, "ffffffaa"], [1, -6, 1, 2, "ffffff88"]]},
	"tra": {"n": "Trà", "c": 1, "px": [[-2, -5, 4, 5, "d9e8a8"], [-2, -4, 4, 4, "9bb83a"], [-2, -5, 4, 1, "f3f7d8"], [1, -8, 1, 3, "ffffff"], [2, -8, 2, 1, "c0392b"]]},
	"sach": {"n": "Sách", "c": 2, "px": [[-3, -4, 7, 4, "2f5fb8"], [-3, -1, 7, 1, "f5ecd0"], [-3, -4, 1, 4, "1d3f80"], [-1, -3, 4, 1, "ffd23f"]]},
	"vo": {"n": "Vở", "c": 2, "px": [[-2, -5, 5, 5, "c0392b"], [-3, -4, 1, 1, "dddddd"], [-3, -2, 1, 1, "dddddd"], [-1, -4, 3, 2, "f5f5f5"], [0, -3, 2, 1, "7a7a7a"]]},
	"giay": {"n": "Giấy", "c": 2, "px": [[-3, -1, 7, 1, "c8c8c8"], [-3, -2, 7, 1, "ffffff"], [-2, -3, 6, 1, "ececec"], [-2, -2, 3, 1, "7a7a7a"]]},
	"but": {"n": "Bút", "c": 2, "px": [[-3, -1, 6, 1, "2f6bd0"], [3, -1, 1, 1, "222222"], [-3, -2, 2, 1, "1d3f80"]]},
	"laptop": {"n": "Laptop", "c": 3, "px": [[-3, -6, 7, 4, "2b2f38"], [-2, -5, 5, 2, "7ec8f0"], [-3, -2, 7, 2, "aeb4bd"], [-2, -2, 5, 1, "7d838c"]]},
	"dien_thoai": {"n": "Điện thoại", "c": 3, "px": [[-2, -3, 5, 3, "2a2f38"], [-1, -3, 3, 2, "7ec8f0"], [-1, -3, 1, 1, "b8e4f8"], [2, -1, 1, 1, "888888"]]},
	"may_tinh_bang": {"n": "Máy tính bảng", "c": 3, "px": [[-3, -4, 7, 4, "c9ced6"], [-2, -3, 5, 2, "4ea1d8"], [-2, -3, 2, 1, "9ad0ee"]]},
	"hop_but": {"n": "Hộp bút", "c": 4, "px": [[-3, -3, 7, 3, "3a9a8c"], [-3, -2, 7, 1, "1f6d62"], [-2, -5, 1, 2, "f1c40f"], [0, -5, 1, 2, "e74c3c"], [2, -4, 1, 1, "2f6bd0"]]},
	"com_ga": {"n": "Cơm gà", "c": 0, "px": [[-3, -3, 7, 3, "e9e9e9"], [-3, -5, 7, 2, "3a9a48"], [-3, -5, 7, 1, "5fc06a"], [0, -5, 1, 5, "2c6f35"], [-3, -1, 7, 1, "c9c9c9"]]},
	"com_suon": {"n": "Cơm sườn", "c": 0, "px": [[-3, -3, 7, 3, "e9e9e9"], [-3, -5, 7, 2, "3a9a48"], [-3, -5, 7, 1, "5fc06a"], [0, -5, 1, 5, "2c6f35"], [-3, -1, 7, 1, "c9c9c9"]]},
	"mi_xao": {"n": "Mì xào", "c": 0, "px": [[-2, -5, 5, 5, "d4221e"], [-2, -6, 5, 1, "f1c40f"], [-1, -4, 3, 2, "ffde3a"], [-2, -1, 5, 1, "a01a16"]]},
	"tra_dao": {"n": "Trà đào", "c": 1, "px": [[-2, -5, 4, 5, "d9e8a8"], [-2, -4, 4, 4, "9bb83a"], [-2, -5, 4, 1, "f3f7d8"], [1, -8, 1, 3, "ffffff"], [2, -8, 2, 1, "c0392b"]]},
	"tra_tac": {"n": "Trà tắc", "c": 1, "px": [[-2, -5, 4, 5, "cdeeff"], [-2, -3, 4, 3, "8ecbf0"], [-2, -5, 4, 1, "ffffff"], [1, -7, 1, 3, "e74c3c"]]},
	"nuoc_suoi": {"n": "Nước suối", "c": 1, "px": [[0, -8, 1, 2, "2f6bd0"], [-1, -6, 3, 6, "bfe6ff"], [-1, -3, 3, 2, "2f6bd0"], [-1, -5, 1, 3, "ffffff"]]},
	"coc_nhua": {"n": "Cốc nhựa", "c": 1, "px": [[-2, -5, 4, 5, "e9f2f8"], [-2, -5, 4, 1, "ffffff"], [1, -4, 1, 4, "c3d6e2"]]},
	"coc_nuoc": {"n": "Cốc nước", "c": 1, "px": [[-2, -5, 4, 5, "e9f2f8"], [-2, -3, 4, 3, "8ecbf0"], [-2, -5, 4, 1, "ffffff"]]},
	"coc_da_dung": {"n": "Cốc đã dùng", "c": 1, "px": [[-2, -4, 4, 4, "cfd8de"], [-2, -4, 4, 1, "e4ebef"], [-1, -2, 2, 1, "9aa6ae"]]},
	"binh_nuoc": {"n": "Bình nước", "c": 1, "px": [[0, -8, 1, 2, "3b6fb0"], [-1, -6, 3, 6, "d7e8f2"], [-1, -3, 3, 2, "3b6fb0"]]},
	"binh_nuoc_day": {"n": "Bình có nước", "c": 1, "px": [[0, -8, 1, 2, "3b6fb0"], [-1, -6, 3, 6, "8ecbf0"], [-1, -3, 3, 2, "3b6fb0"]]},
	"tui_nho": {"n": "Túi nhỏ", "c": 4, "px": [[-3, -4, 7, 4, "a0522d"], [-3, -4, 7, 2, "8b4513"], [0, -3, 1, 2, "e6c84a"], [-2, -6, 1, 2, "6b3410"], [2, -6, 1, 2, "6b3410"], [-2, -7, 5, 1, "6b3410"]]},
}
# ---------- Bên trong (khung 480x270) ----------
const VIEW := Vector2(480, 270)
const FLOOR_BOTTOM := 258.0
const DOOR_IN := Vector2(412, 252)
const START_POS := Vector2(412, 236)
const COUNTER := Rect2(14, 66, 222, 30)
const WALK_SPEED := 70.0
const NPC_SPEED := 20.0
const MAX_QTY := 9
const BAG_CAP := 24              # sức chứa túi đồ (tổng số món)
const START_ITEMS := ["sach", "vo", "giay", "but", "laptop", "dien_thoai", "may_tinh_bang", "hop_but", "tui_nho"]
const NOT_EDIBLE := ["coc_nhua", "coc_da_dung", "binh_nuoc"]
const USE_MAP := {"coc_nuoc": "coc_da_dung", "binh_nuoc_day": "binh_nuoc"}   # đồ uống còn vỏ sau khi dùng
const START_MONEY := 0           # bắt đầu học kỳ với ví trống
const WEEKLY_MONEY := 500000     # tiền sinh hoạt mỗi tuần trong game
const PAYMENT := true            # giai đoạn 5: mua hàng tính tiền thật
const SHOW_WALLET_UI := false     # Ẩn khung ví trên HUD; không tắt hệ thống thanh toán
const BUY_LOCK := 0.25           # giây khoá giữa hai lần mua: nhấn/giữ phím liên tục không nhân đôi giao dịch
const SAVE_PATH := "user://canteen_economy.cfg"
const Schedule := preload("res://scripts/features/schedule_data.gd")
const STAFF_Y := 65.0
const SERVE_SLOT := Vector2(126, 102)   # chỗ khách đứng mua ngay trước thu ngân; hàng xếp dọc xuống dưới
const QUEUE_STEP := 14.0
const QUEUE_MAX := 2   # hàng chờ mua tối đa (trước đây 5)
const AI_STEP := 1.0 / 30.0   # AI NPC căn tin chạy 30 lần/giây thay vì mỗi khung hình (giảm tải CPU)
const AI_FAR := 450.0         # người chơi ở xa căn tin hơn mức này (và không ở trong nhà): nhân viên / khách ngồi sân tạm nghỉ
const VIS_MAX := 2     # số khách vãng lai trong căn tin cùng lúc (trước đây 6)
const VIS_SPEED := 26.0
const BIN_USE := Vector2(33, 160)
const CUP_POS := Vector2(284, 86)
const WATER_USE := Vector2(262, 96)
const CUP_USE := Vector2(284, 96)
const UTIL_RANGE := 18.0
const FILL_TIME := 1.1
const CUP_MAX := 10
const CUP_REFILL := 30.0
const WCELL := 10.0
const WF_RADIUS := 75
const WF_STEP := 350
const IG := 4.0
const IG_ORG := Vector2(14.0, 62.0)
const ICON_OF := {"com_ga": "hop_com", "com_suon": "hop_com", "mi_xao": "hop_com", "banh_mi": "banh_mi", "tra_dao": "tra", "tra_tac": "ly_nuoc", "nuoc_suoi": "chai_nuoc"}
const STAFF_GREET := [
	"Chào em! Căn tin có cơm, mì, bánh mì và nước uống. Em cần gì cứ hỏi nhé.",
	"Xin chào! Em muốn xem thực đơn hay cần tư vấn món nào không?",
	"Chào em, hôm nay căn tin đông lắm. Chọn món rồi tìm chỗ ngồi nhé!",
]
const ASK_LINES := [
	"Cơm gà và cơm sườn là hai món bán chạy nhất. Em cần ăn nhanh thì có mì xào.",
	"Bánh mì hợp để ăn nhẹ giữa buổi. Trà đào, trà tắc mát lạnh, nước suối lúc nào cũng có.",
	"Cạnh quầy có cốc nhựa và máy nước. Em lấy cốc rồi tự lấy nước nhé, dùng xong bỏ cốc vào thùng rác.",
	"Muốn ngồi ăn thì cứ chọn bàn trống trong nhà hoặc ngoài sân. Bấm T khi ngồi để đặt đồ lên bàn.",
]
const TEACHER_LINES := ["Cho thầy một ly nước nhé.", "Hôm nay căn tin đông sinh viên quá.", "Nghỉ giải lao một chút rồi vào lớp.", "Ở đây trà mát lắm."]
const MENU := [
	{"id": "com_ga", "name": "Cơm gà", "price": 25000},
	{"id": "com_suon", "name": "Cơm sườn", "price": 30000},
	{"id": "mi_xao", "name": "Mì xào", "price": 25000},
	{"id": "banh_mi", "name": "Bánh mì", "price": 15000},
	{"id": "tra_dao", "name": "Trà đào", "price": 15000},
	{"id": "tra_tac", "name": "Trà tắc", "price": 10000},
	{"id": "nuoc_suoi", "name": "Nước suối", "price": 8000},
]
const STUDENT_LINES := [
	"Bạn ăn gì hôm nay?", "Căn tin đông ghê!", "Bạn muốn ngồi chung bàn không?", "Mình vừa học xong tiết buổi sáng.",
	"Món cơm ở đây khá ngon!", "Trà đào ở đây mát lắm.", "Chiều nay mình có tiết thực hành.", "Bánh mì ở đây giòn ghê.",
	"Sắp thi giữa kỳ rồi, lo quá...", "Mình hay ngồi sân ngoài, thoáng mát.", "Nhớ dọn khay khi ăn xong nha!",
	"Hôm nay có cơm sườn, mình gọi liền.", "Ăn xong mình lên thư viện học bài.", "Gió ngoài sân mát thật đấy.",
]
const STAFF_LINES := [
	"Xin chào! Bạn muốn mua gì?", "Hôm nay có nhiều món ngon lắm.", "Bạn chọn món trên menu nhé!",
	"Cơm gà hôm nay mới nấu, còn nóng đó!", "Trà đào mát lạnh, bạn thử không?", "Cảm ơn bạn, chúc ngon miệng!",
]
const NAMES := ["Minh", "Lan", "Hùng", "Trang", "Khoa", "Ngọc", "Phúc", "Thảo", "Bảo", "Vy", "Đạt", "Mai", "Long", "Hà", "Tuấn", "Linh"]
const SHIRTS := [Color("e07a5f"), Color("81b29a"), Color("f2cc8f"), Color("3d5a80"), Color("e8e8e8"), Color("8e5bd0"), Color("2f6bd0"), Color("d4a5a5")]
const HAIRS := [Color("1b1b1b"), Color("3b2a1a"), Color("5a3a22"), Color("1b1b1b"), Color("7a4a2a")]
const C_WALL := Color("f1e8cc")
const C_GRAVEL := Color("c4c6c9")
const C_IRON := Color("23252b")
const C_IRON_HI := Color("3d4048")
const C_ARM := Color("c8742e")
const C_WOOD := Color("c98a4b")
const C_WOOD_DK := Color("8a5a2c")
const C_GREEN := Color("4f7a2a")
const C_AWN_DK := Color("2e6f32")
const C_AWN_LT := Color("58a850")
const C_STEEL := Color("2f343c")
const C_STEEL_HI := Color("5b636e")
const C_STAFF := Color("2f8f4a")

var inside := false
var needs_outdoor_npcs := true   # khách căn tin là NPC ngoài trời (game.npcs): main.gd vẫn phải cập nhật NPC khi đang ở trong căn tin
var money := 0               # số dư hiện tại (không bao giờ âm), đổi qua _money_add / _money_spend
var _paid_weeks: Array = []  # các tuần trong game đã nhận tiền sinh hoạt
var _buy_lock := 0.0
var _eco_t := 0.0
var _eco_sig := ""           # dấu vết dữ liệu đã lưu lần cuối, để chỉ ghi file khi có thay đổi
var _eco_ready := false
var _layer: CanvasLayer
var _painter: Node2D
var _ui: CanvasLayer
var _wallet: Label
var _pos := START_POS
var _face := 1
var _anim := 0.0
var _clock := 0.0
var _ai_acc := 0.0
var _fade := 0.0
var _closing := false
var _sit_t := 0.0              # thời gian đã ngồi (chống đứng dậy ngay khi vừa ngồi)
var _seated := -1            # chỉ số ghế người chơi đang ngồi (-1 = đứng)
var _tables: Array = []      # {a, c(Vector2), hw(float)}
var _seats: Array = []       # {a, c, pos, face, stand, side, taken("" | "npc" | "player"), res(NPC đang giữ chỗ, -1 = không), tab}
var _isolid: Array = []      # vật cản trong nhà
var _npcs: Array = []
var _rng := RandomNumberGenerator.new()
var _dlg_open := false
var _dlg_npc := -1
var _dlg_n := 0
var _dlg_root: Control
var _dlg_name: Label
var _dlg_text: Label
var _dlg_hint: Label
var _toast: Label
var _toast_t := 0.0
var _inv: Dictionary = {}     # túi đồ người chơi: id -> số lượng (dùng chung cho cửa hàng, bàn, cốc, máy nước)
var _dlg_btn: Button
var _tops: Array = []          # mỗi bàn: 5 ô vật phẩm (id món hoặc ""), giữ nguyên trong cả phiên chơi
var _nav_w := 0
var _nav_h := 0
var _nav_block := PackedByteArray()
var _nav_main := PackedByteArray()   # 1 = ô thông với cửa chính (tránh túi kín giữa ghế và cột dù)

var _trash := 0              # rác ăn uống đang cầm
var _cup_stock := CUP_MAX
var _fill_t := 0.0
var _fill_kind := ""
var _bin_t := 0.0
var _bin_i := 2
var _cash_i := 1
var _queue: Array = []
var _serving := -1
var _vid := 1000
var _visit_cd := 6.0
var _wv: Array = []
var _vis_gone: Array = []
var _wf := PackedInt32Array()
var _wf_w := 0
var _wf_h := 0
var _wf_q: Array = []
var _wf_i := 0
var _wf_ready := false
var _ig_w := 0
var _ig_h := 0
var _ig_blk := PackedByteArray()

func _ready() -> void:
	_rng.seed = 2468
	# Đăng ký trước setup_collision(): va chạm, minimap, tên khu vực tự có từ BUILDINGS / ZONES.
	game.BUILDINGS.append(["CĂN TIN", BUILDING.position.x, BUILDING.position.y, BUILDING.size.x, BUILDING.size.y, C_WALL, Color("4f7a2a"), "Căn tin HCMUS - cơm, mì, bánh mì, trà. Bấm E ở cửa để vào."])
	game.ZONES.append(["Sân căn tin HCMUS - bàn ghế sắt ngoài trời", Rect2(368, 0, 366, 180)])
	if STAGE >= 3:
		_build_outdoor()
	if STAGE >= 4:
		_build_indoor()
	if STAGE >= 5:
		_spawn_npcs()
	_eco_init()   # sau khi _tops đã có (bàn ngoài sân / trong nhà) và trước khi dựng giao diện
	_build_overlay_nodes()
	if STAGE >= 6:
		_build_ui()
	if STAGE >= 3:
		call_deferred("_late_init")   # sau setup_collision(): lưới tìm đường cần va chạm đầy đủ

# ======================= DỰNG BÀN GHẾ =======================

# sides: danh sách [side, dx]; side N/S/W/E là vị trí ghế so với bàn
func _add_table(a: String, tx: float, ty: float, hw: float, sides: Array) -> void:
	var ti := _tables.size()
	_tables.append({"a": a, "c": Vector2(tx, ty), "hw": hw})
	_tops.append(["", "", "", "", ""])
	var tsolid := Rect2(tx - hw - 1.0, ty - 6.0, hw * 2.0 + 2.0, 18.0)
	if a == "out":
		game.solids.append(tsolid)
	else:
		_isolid.append(tsolid)
	var wx := hw + 7.0
	for s in sides:
		var side: String = s[0]
		var dx: float = s[1]
		var c := Vector2(tx, ty)
		var p := Vector2(tx, ty)
		var f := 0
		var st := Vector2(tx, ty)
		var cs := Rect2(0, 0, 0, 0)   # vùng chân ghế: phần ghế chạm đất (chỗ ngồi + chân + gốc lưng ghế)
		match side:
			"N":
				c = Vector2(tx + dx, ty - 14.0)
				p = Vector2(tx + dx, ty - 2.0)    # đã tính sẵn phần bàn che chân người ngồi
				f = 0
				st = Vector2(tx + dx, ty - 27.0)
				cs = Rect2(c.x - 8.0, c.y - 4.0, 16.0, 10.0)
			"S":
				c = Vector2(tx + dx, ty + 14.0)
				p = Vector2(tx + dx, ty + 17.0)
				f = 1
				st = Vector2(tx + dx, ty + 27.0)
				cs = Rect2(c.x - 8.0, c.y - 2.0, 16.0, 9.0)
			"W":
				c = Vector2(tx - wx, ty + 2.0)
				p = Vector2(tx - wx, ty + 6.0)
				f = 3
				st = Vector2(c.x - 17.0, ty + 8.0)
				cs = Rect2(c.x - 9.0, c.y - 1.0, 15.0, 9.0)
			_:
				c = Vector2(tx + wx, ty + 2.0)
				p = Vector2(tx + wx, ty + 6.0)
				f = 2
				st = Vector2(c.x + 17.0, ty + 8.0)
				cs = Rect2(c.x - 6.0, c.y - 1.0, 15.0, 9.0)
		_seats.append({"a": a, "c": c, "pos": p, "face": f, "stand": st, "side": side, "taken": "", "res": -1, "tab": ti})
		if a == "out":
			game.solids.append(cs)
		else:
			_isolid.append(cs)

func _build_outdoor() -> void:
	# cụm tây 2x2 (dưới dù xanh), cụm giữa 2 bàn, cụm đông dưới mái kính. Hàng trên: ghế W E S (S nhìn ra lối đi);
	# hàng dưới: ghế W E N. Chừa khoảng trống x 554-598 ở hàng dưới cho lối đi từ khe C-D, và đường từ cửa chính đi xuống.
	for tx in [410.0, 470.0]:
		_add_table("out", tx, 112.0, 12.0, [["W", 0.0], ["E", 0.0], ["S", 0.0]])
		_add_table("out", tx, 172.0, 12.0, [["W", 0.0], ["E", 0.0], ["N", 0.0]])
	for tx in [530.0, 590.0]:
		_add_table("out", tx, 112.0, 12.0, [["W", 0.0], ["E", 0.0], ["S", 0.0]])
	_add_table("out", 694.0, 112.0, 12.0, [["W", 0.0], ["E", 0.0], ["S", 0.0]])
	_add_table("out", 636.0, 172.0, 12.0, [["W", 0.0], ["E", 0.0], ["N", 0.0]])
	# cây cọ hai góc trái: vào game.trees để game tự vẽ theo chiều sâu và tự thêm va chạm
	# (hai cây cọ cũ ở x 500 và x 558 đã bỏ, thay bằng một cây lớn BIG_TREE vẽ trong _draw_big_tree)
	for t in [[378, 104, 2], [378, 176, 2]]:
		game.trees.append(t)
	game.solids.append(Rect2(BIG_TREE.x - 5.0, BIG_TREE.y - 4.0, 10, 5))   # chỉ gốc thân cây có va chạm, tán lá đi xuyên được
	# cột mái kính, cột dù, chậu cây: vật cản nhỏ ở chân
	for q in POSTS:
		game.solids.append(Rect2(q.x - 2.0, q.y - 2.0, 4, 3))
	for q in PARASOLS:
		game.solids.append(Rect2(q.x - 2.0, q.y - 2.0, 5, 3))   # đế dù (tán dù ở trên cao: đi bên dưới được)
	for q in POTS:
		game.solids.append(Rect2(q.x - 5.0, q.y - 4.0, 10, 5))  # chậu (tán lá ở trên cao)

func _build_indoor() -> void:
	_isolid.append(COUNTER)
	for t in [[74.0, 172.0], [166.0, 172.0], [74.0, 232.0], [166.0, 232.0], [300.0, 118.0], [392.0, 118.0], [300.0, 190.0], [392.0, 190.0]]:
		_add_table("in", t[0], t[1], 22.0, [["N", -10.0], ["N", 10.0], ["S", -10.0], ["S", 10.0]])
	for pc in [Vector2(240, 128), Vector2(240, 212)]:
		_isolid.append(Rect2(pc.x - 6.0, pc.y - 6.0, 12.0, 6.0))
	_isolid.append(Rect2(330, 56, 96, 8))   # chân cầu thang
	for q in IN_PLANTS:
		_isolid.append(Rect2(q.x - 6.0, q.y - 5.0, 12, 6))
	_isolid.append(Rect2(IN_BINS.x - 6.0, IN_BINS.y - 5.0, 28, 6))
	_isolid.append(Rect2(IN_WATER.x - 7.0, 66.0, 14, IN_WATER.y - 66.0 + 1.0))
	_isolid.append(Rect2(CUP_POS.x - 8.0, 66.0, 16, CUP_POS.y - 66.0 + 1.0))   # tủ cốc nhựa cạnh máy nước
	_build_in_grid()

# ======================= NPC =======================

func _new_npc(a: String, pos: Vector2, mode: String, face: int, nm: String) -> Dictionary:
	var lines: Array = []
	var pool: Array = STUDENT_LINES.duplicate()
	if mode == "staff":
		pool = STAFF_LINES.duplicate()
	for i in pool.size():
		var j := _rng.randi_range(0, pool.size() - 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	for i in mini(4, pool.size()):
		lines.append(pool[i])
	var staff := mode == "staff"
	return {"a": a, "name": nm, "staff": staff, "pos": pos, "face": face, "anim": 0.0,
		"shirt": C_STAFF if staff else SHIRTS[_rng.randi_range(0, SHIRTS.size() - 1)],
		"hair": HAIRS[_rng.randi_range(0, HAIRS.size() - 1)], "uni": (not staff) and _rng.randf() < 0.5,
		"long": _rng.randf() < 0.4, "pack": (not staff) and _rng.randf() < 0.6, "mode": mode, "seat": -1,
		"lines": lines, "line_i": 0, "say": "", "say_t": 0.0, "timer": _rng.randf_range(2.0, 9.0), "talk": 0.0,
		"route": [], "ri": 0, "rdir": 1, "stuck": 0.0, "home": pos, "eat": _rng.randf() * 3.0}

func _rand_name() -> String:
	return "Bạn " + str(NAMES[_rng.randi_range(0, NAMES.size() - 1)])

func _spawn_npcs() -> void:
	# 4C: trong nhà chỉ có nhân viên sau quầy; khách là NPC của trường đi vào (xem _vis_*).
	var staff_names := ["Cô Hoa (bếp)", "Cô Lan (thu ngân)"]   # trước đây có thêm Chú Tâm (bếp)
	var sx := [60.0, 126.0]
	for i in 2:
		var s := _new_npc("in", Vector2(sx[i], STAFF_Y), "staff", 0, staff_names[i])
		_npcs.append(s)
	_cash_i = 1

func _seat_some(ids: Array, count: int) -> void:
	for i in ids.size():
		var j := _rng.randi_range(0, ids.size() - 1)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	for k in mini(count, ids.size()):
		var si: int = ids[k]
		var s: Dictionary = _seats[si]
		var n := _new_npc(s.a, s.pos, "sit", s.face, _rand_name())
		n.seat = si
		s["taken"] = "npc"
		_npcs.append(n)

func _blocked_a(a: String, p: Vector2) -> bool:
	if a == "out":
		return game.blocked(p)
	return _in_blocked(p)

func _in_blocked(p: Vector2) -> bool:
	if p.x < 14.0 or p.x > VIEW.x - 14.0 or p.y < 66.0 or p.y > FLOOR_BOTTOM - 2.0:
		return true
	var hit := Rect2(p.x - 4.0, p.y - 4.0, 8.0, 4.0)
	for s in _isolid:
		if hit.intersects(s):
			return true
	return false

# điểm đứng được gần p nhất (tránh đứng dậy trong vật cản)
func _find_free(a: String, p: Vector2) -> Vector2:
	if not _blocked_a(a, p):
		return p
	var r := 4.0
	while r < 70.0:
		for k in 12:
			var c := p + Vector2.from_angle(k * TAU / 12.0) * r
			if not _blocked_a(a, c):
				return c
		r += 4.0
	return p

func _pp() -> Vector2:
	return _pos if inside else game.player

func _agent_near(n: Dictionary, np: Vector2) -> bool:
	var old: Vector2 = n.pos
	for o in _npcs:
		if o == n or o.a != n.a:
			continue
		var op: Vector2 = o.pos
		var dn := np.distance_to(op)
		if dn < 10.0 and dn < old.distance_to(op):
			return true
	if (n.a == "in") == inside:
		var pp := _pp()
		var dp := np.distance_to(pp)
		if dp < 11.0 and dp < old.distance_to(pp):
			return true
	return false

func _update_npcs(delta: float) -> void:
	_visit_tick(delta)
	_util_tick(delta)
	# nhân viên và khách ngồi sân chỉ cần chạy khi người chơi đủ gần để nhìn thấy; khách vãng lai ("vis") luôn chạy
	var near: bool = inside or _dlg_open or game.player.distance_to(BUILDING.get_center()) < AI_FAR
	for k in _npcs.size():
		var n: Dictionary = _npcs[k]
		n.say_t = maxf(float(n.say_t) - delta, 0.0)
		n.eat = float(n.eat) + delta
		if _dlg_open and k == _dlg_npc:
			n.talk = 1.0   # đang trò chuyện với người chơi: đứng yên tại chỗ
			continue
		if float(n.talk) > 0.0:
			n.talk = float(n.talk) - delta
			continue
		n.timer = float(n.timer) - delta
		var chatty: bool = n.mode != "walk"
		if float(n.timer) <= 0.0:
			n.timer = _rng.randf_range(7.0, 16.0)
			if chatty and _rng.randf() < 0.5 and not n.lines.is_empty():
				n.say = n.lines[_rng.randi_range(0, n.lines.size() - 1)]
				n.say_t = 2.6
		match n.mode:
			"walk":
				_walk_npc(n, delta)
			"staff":
				if near:
					_sway_staff(n, delta)
			"diner":
				if near:
					_diner_update(n, delta)
			"vis":
				_vis_update(n, delta)
	if not _vis_gone.is_empty():
		for gn in _vis_gone:
			var idx := -1
			for k in _npcs.size():
				if _npcs[k].mode == "vis" and int(_npcs[k].id) == int(gn.id):
					idx = k
			if idx >= 0:
				if _dlg_open and _dlg_npc == idx:
					_close_dialog()
				elif _dlg_open and _dlg_npc > idx:
					_dlg_npc -= 1
				_npcs.remove_at(idx)
		_vis_gone.clear()

func _sway_staff(n: Dictionary, delta: float) -> void:
	var hx: float = n.home.x
	var tx: float = hx + sin(_clock * 0.4 + hx) * 20.0
	if n.name.contains("thu ngân"):
		tx = hx
	var p: Vector2 = n.pos
	var dx := tx - p.x
	if absf(dx) > 1.0:
		p.x += signf(dx) * minf(absf(dx), 12.0 * delta)
		n.anim = float(n.anim) + delta
		n.face = 3 if dx > 0.0 else 2
		n.pos = p
	else:
		n.face = 0

func _walk_npc(n: Dictionary, delta: float) -> void:
	var route: Array = n.route
	if route.size() < 2:
		return
	var tgt: Vector2 = route[int(n.ri) % route.size()]
	var p: Vector2 = n.pos
	var d := tgt - p
	if d.length() < 2.0:
		var nx := int(n.ri) + int(n.rdir)
		if nx < 0 or nx >= route.size():
			n.rdir = -int(n.rdir)
			nx = int(n.ri) + int(n.rdir)
		n.ri = nx
		return
	var np := p + d.normalized() * NPC_SPEED * delta
	if _blocked_a(n.a, np) or _agent_near(n, np):
		n.stuck = float(n.stuck) + delta
		if float(n.stuck) > 1.5:
			n.stuck = 0.0
			n.rdir = -int(n.rdir)
			n.ri = clampi(int(n.ri) + int(n.rdir), 0, route.size() - 1)
		return
	n.stuck = 0.0
	n.pos = np
	n.anim = float(n.anim) + delta
	if absf(d.x) > absf(d.y):
		n.face = 2 if d.x < 0.0 else 3
	else:
		n.face = 1 if d.y < 0.0 else 0

func _dlg_key(code: int) -> bool:
	if code == KEY_ESCAPE or code == KEY_Q:
		_close_dialog()
		return true
	if code == KEY_E or code == KEY_ENTER or code == KEY_KP_ENTER:
		_dlg_advance()
		return true
	return false

# Chỉ còn làm nắp thùng rác (NPC khách bỏ rác) tự đóng lại
func _util_tick(delta: float) -> void:
	_bin_t = maxf(_bin_t - delta, 0.0)

# ======================= 4C: KHÁCH TỪ SÂN TRƯỜNG VÀO CĂN TIN =======================
# Khách là chính NPC của game (game.npcs): đi theo lưới dẫn đường tới cửa căn tin; vào trong thì được cất khỏi game.npcs
# và đại diện bằng một NPC trong nhà (cùng dáng, liên kết n.ref). Ra cửa thì đưa đúng NPC đó trở lại game.npcs.

func _wf_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / WCELL), int(p.y / WCELL))

func _wf_pos(c: Vector2i) -> Vector2:
	return Vector2((float(c.x) + 0.5) * WCELL, (float(c.y) + 0.5) * WCELL)

func _wf_ok(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= _wf_w or c.y >= _wf_h:
		return false
	var v: int = _wf[c.y * _wf_w + c.x]
	if v == -2:
		return false
	if v >= 0:
		return true
	if game.blocked(_wf_pos(c)):
		_wf[c.y * _wf_w + c.x] = -2
		return false
	return true

func _wf_begin() -> void:
	_wf_w = int(game.WORLD.x / WCELL)
	_wf_h = int(game.WORLD.y / WCELL)
	_wf = PackedInt32Array()
	_wf.resize(_wf_w * _wf_h)
	_wf.fill(-1)
	_wf_q = []
	_wf_i = 0
	var s := _wf_cell(SPAWN_OUT)
	var found := false
	for r in range(0, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector2i(s.x + dx, s.y + dy)
				if not found and _wf_ok(c):
					_wf[c.y * _wf_w + c.x] = 0
					_wf_q.append(c)
					found = true

func _wf_step(budget: int) -> void:
	var n := 0
	while _wf_i < _wf_q.size() and n < budget:
		var c: Vector2i = _wf_q[_wf_i]
		_wf_i += 1
		n += 1
		var d: int = _wf[c.y * _wf_w + c.x]
		if d >= WF_RADIUS:
			continue
		for dd in NAV_DIRS:
			var dv: Vector2i = dd
			var q := Vector2i(c.x + dv.x, c.y + dv.y)
			if not _wf_ok(q) or _wf[q.y * _wf_w + q.x] != -1:
				continue
			if dv.x != 0 and dv.y != 0:
				if not (_wf_ok(Vector2i(c.x + dv.x, c.y)) and _wf_ok(Vector2i(c.x, c.y + dv.y))):
					continue
			_wf[q.y * _wf_w + q.x] = d + 1
			_wf_q.append(q)
	if _wf_i >= _wf_q.size():
		_wf_ready = true

func _wf_dist(p: Vector2) -> int:
	var c := _wf_cell(p)
	if c.x < 0 or c.y < 0 or c.x >= _wf_w or c.y >= _wf_h:
		return -1
	return int(_wf[c.y * _wf_w + c.x])

# ô kế tiếp trên đường tới cửa (null nếu đứng ngoài vùng dẫn đường)

func _wf_next(p: Vector2) -> Variant:
	var c := _wf_cell(p)
	var d := _wf_dist(p)
	if d < 0:
		return null
	if d == 0:
		return DOOR_OUT
	var best := d
	var bp := Vector2.ZERO
	for dd in NAV_DIRS:
		var dv: Vector2i = dd
		var q := Vector2i(c.x + dv.x, c.y + dv.y)
		if q.x < 0 or q.y < 0 or q.x >= _wf_w or q.y >= _wf_h:
			continue
		var v: int = _wf[q.y * _wf_w + q.x]
		if v < 0 or v >= best:
			continue
		if dv.x != 0 and dv.y != 0:
			if _wf[c.y * _wf_w + c.x + dv.x] < 0 or _wf[(c.y + dv.y) * _wf_w + c.x] < 0:
				continue
		best = v
		bp = _wf_pos(q)
	if best == d:
		return null
	return bp

func _visit_tick(delta: float) -> void:
	if STAGE < 6:
		return
	if not _wf_ready:
		if _wf_w == 0:
			_wf_begin()
		_wf_step(WF_STEP)
		return
	_visit_cd -= delta
	if _visit_cd <= 0.0:
		_visit_cd = _rng.randf_range(10.0, 26.0)
		_visit_start()
	for k in range(_wv.size() - 1, -1, -1):
		_wv_update(_wv[k], delta)

func _visit_start() -> void:
	var inn := 0
	for o in _npcs:
		if o.mode == "vis":
			inn += 1
	if inn + _wv.size() >= VIS_MAX or _queue.size() + _wv.size() >= QUEUE_MAX:
		return
	var cands: Array = []
	for o in game.npcs:
		if o.get("quiz", false) or o.has("role") or o.has("visit"):
			continue
		if _wf_dist(o.pos) >= 0:
			cands.append(o)
	if cands.is_empty():
		return
	var pick: Dictionary = cands[_rng.randi_range(0, cands.size() - 1)]
	_vid += 1
	pick["visit"] = _vid
	pick["v_stuck"] = 0.0
	pick["v_t"] = 0.0
	pick["v_last"] = pick.pos
	_wv.append(pick)

func _wv_index(o: Dictionary) -> int:
	for k in _wv.size():
		if int(_wv[k].visit) == int(o.visit):
			return k
	return -1

func _gn_index(o: Dictionary) -> int:
	for k in game.npcs.size():
		if int(game.npcs[k].get("visit", -1)) == int(o.visit):
			return k
	return -1

func _wv_cancel(o: Dictionary) -> void:
	var k := _wv_index(o)
	if k >= 0:
		_wv.remove_at(k)
	o.erase("visit")
	o.erase("v_stuck")
	o.erase("v_t")
	o.erase("v_last")
	o.dir = Vector2.ZERO
	o.timer = 0.0

func _wv_update(o: Dictionary, delta: float) -> void:
	o.timer = 99999.0   # game không tự đổi hướng NPC này nữa
	o.v_t = float(o.v_t) + delta
	var p: Vector2 = o.pos
	if p.distance_to(DOOR_OUT) < 12.0:
		if _spot_clear(START_POS, -1):
			_vis_enter(o)
		else:
			o.dir = Vector2.ZERO   # lối vào đang có người: đứng chờ ở cửa
			o.v_stuck = 0.0
		return
	if float(o.v_t) > 160.0:
		_wv_cancel(o)
		return
	if p.distance_to(o.v_last) > 3.0:
		o.v_last = p
		o.v_stuck = 0.0
	else:
		o.v_stuck = float(o.v_stuck) + delta
		if float(o.v_stuck) > 6.0:
			_wv_cancel(o)
			return
	var nx = _wf_next(p)
	var t: Vector2 = DOOR_OUT
	if nx != null:
		t = nx
	elif p.distance_to(SPAWN_OUT) > 40.0:
		_wv_cancel(o)
		return
	var d := t - p
	if d.length() > 0.5:
		o.dir = d.normalized()
	else:
		o.dir = Vector2.ZERO

func _vis_enter(o: Dictionary) -> void:
	var k := _gn_index(o)
	if k >= 0:
		game.npcs.remove_at(k)
	var wk := _wv_index(o)
	if wk >= 0:
		_wv.remove_at(wk)
	var teacher: bool = (not bool(o.uni)) and (not bool(o.pack))
	var nm := _rand_name()
	if teacher:
		nm = ("Thầy " if _rng.randf() < 0.5 else "Cô ") + str(NAMES[_rng.randi_range(0, NAMES.size() - 1)])
	var n := _new_npc("in", START_POS, "vis", 1, nm)
	n.shirt = o.shirt
	n.hair = o.hair
	n.uni = o.uni
	n.long = o.long
	n.pack = o.pack
	if teacher:
		n.lines = TEACHER_LINES.duplicate()
	n["id"] = int(o.visit)
	n["ref"] = o
	n["teacher"] = teacher
	n["take"] = _rng.randf() < (0.35 if teacher else 0.2)
	n["ph"] = "arrive"
	n["ph_t"] = 0.0
	n["path"] = []
	n["pi"] = 0
	n["goal"] = Vector2(-99, -99)
	n["fail"] = 0
	n["bump"] = 0
	n["stuck"] = 0.0
	n["retry_t"] = 0.0
	n["ghost"] = 0.0
	n["life"] = 0.0
	n["item"] = ""
	n["food"] = ""
	n["trash"] = false
	n["tseat"] = -1
	_npcs.append(n)

func _vis_leave(n: Dictionary) -> void:
	_vis_release_seat(n)
	_queue_remove(int(n.id))
	if _serving == int(n.id):
		_serving = -1
	var ref: Dictionary = n.ref
	for key in ["visit", "v_stuck", "v_t", "v_last"]:
		ref.erase(key)
	ref.dir = Vector2.ZERO
	ref.timer = 0.0
	ref.anim = 0.0
	ref.face = 0
	ref.say = ""
	ref.say_t = 0.0
	ref.pos = _find_free("out", SPAWN_OUT + Vector2(float(int(n.id) % 3 - 1) * 12.0, 0.0))
	game.npcs.append(ref)
	n.ph = "gone"
	_vis_gone.append(n)

func _queue_remove(id: int) -> void:
	var k := _queue.find(id)
	if k >= 0:
		_queue.remove_at(k)

func _q_slot(n: Dictionary) -> Vector2:
	var r := _queue.find(int(n.id))
	if r < 0:
		r = 0
	return SERVE_SLOT + Vector2(0.0, QUEUE_STEP * float(r))

func _vis_phase(n: Dictionary, ph: String) -> void:
	n.ph = ph
	n.path = []
	n.pi = 0
	n.fail = 0
	n.bump = 0
	n.stuck = 0.0
	n.retry_t = 0.0

func _spot_clear(p: Vector2, id: int) -> bool:
	for o in _npcs:
		if o.mode == "vis" and int(o.id) != id and int(o.seat) < 0 and o.pos.distance_to(p) < 12.0:
			return false
	if inside and _pos.distance_to(p) < 12.0:
		return false
	return true

func _vis_release_seat(n: Dictionary) -> void:
	var si := int(n.seat)
	if si >= 0 and si < _seats.size():
		_seats[si]["taken"] = ""
		n.pos = _find_free("in", _seats[si].stand)
		n.seat = -1
	var ts := int(n.tseat)
	if ts >= 0 and ts < _seats.size() and int(_seats[ts].res) == int(n.id):
		_seats[ts]["res"] = -1
	n.tseat = -1
	n.food = ""

func _vis_pick_seat(n: Dictionary) -> int:
	var cands: Array = []
	var friends: Array = []
	for i in _seats.size():
		var s: Dictionary = _seats[i]
		if str(s.a) != "in" or not _seat_free(i):
			continue
		cands.append(i)
		for j in _seats.size():
			var o: Dictionary = _seats[j]
			if j != i and int(o.tab) == int(s.tab) and (str(o.taken) == "npc" or int(o.res) >= 0):
				friends.append(i)
				break
	var pool: Array = cands
	if not bool(n.teacher) and not friends.is_empty() and _rng.randf() < 0.7:
		pool = friends
	if pool.is_empty():
		return -1
	return int(pool[_rng.randi_range(0, pool.size() - 1)])

func _vis_avoid(n: Dictionary) -> Array:
	var out: Array = []
	for o in _npcs:
		if o.mode == "vis" and int(o.id) != int(n.id) and int(o.seat) < 0:
			out.append(o.pos)
	if inside:
		out.append(_pos)
	return out

func _vis_agent_near(n: Dictionary, np: Vector2) -> bool:
	var old: Vector2 = n.pos
	for o in _npcs:
		if o.mode != "vis" or int(o.id) == int(n.id) or int(o.seat) >= 0:
			continue
		var op: Vector2 = o.pos
		var dn := np.distance_to(op)
		if dn < 9.0 and dn < old.distance_to(op):
			return true
	if inside:
		var dp := np.distance_to(_pos)
		if dp < 10.0 and dp < old.distance_to(_pos):
			return true
	return false

# đi tới goal theo đường BFS; trả về true khi đã tới

func _vis_walk(n: Dictionary, goal: Vector2, delta: float) -> bool:
	if n.pos.distance_to(goal) < 1.5:
		return true
	n.retry_t = maxf(float(n.retry_t) - delta, 0.0)
	n.ghost = maxf(float(n.ghost) - delta, 0.0)
	var g0: Vector2 = n.goal
	if n.path.is_empty() or g0.distance_to(goal) > 1.5:
		if float(n.retry_t) > 0.0:
			return false
		n.goal = goal
		n.path = _in_path(n.pos, goal, _vis_avoid(n))
		n.pi = 0
		if n.path.is_empty():
			n.fail = int(n.fail) + 1
			n.retry_t = 1.5
			return false
	var path: Array = n.path
	var i := int(n.pi)
	if i >= path.size():
		return n.pos.distance_to(goal) < 2.5
	var tgt: Vector2 = path[i]
	var p: Vector2 = n.pos
	var d := tgt - p
	var dist := d.length()
	if dist < 0.8:
		n.pi = i + 1
		return false
	var np := p + d / dist * minf(VIS_SPEED * delta, dist)
	if _in_blocked(np) or (float(n.ghost) <= 0.0 and _vis_agent_near(n, np)):
		n.stuck = float(n.stuck) + delta
		if float(n.stuck) > 2.5:
			n.stuck = 0.0
			n.ghost = 2.5   # kẹt người: tạm xuyên qua nhau để gỡ thế bí
			n.path = []
			n.bump = int(n.bump) + 1
			if int(n.bump) >= 6:
				n.fail = 3
		return false
	n.stuck = 0.0
	n.pos = np
	n.anim = float(n.anim) + delta
	if absf(d.x) > absf(d.y):
		n.face = 2 if d.x < 0.0 else 3
	else:
		n.face = 1 if d.y < 0.0 else 0
	return false

func _vis_fallback(n: Dictionary) -> void:
	match str(n.ph):
		"toexit":
			if int(n.fail) >= 10:
				_vis_leave(n)
		"toseat":
			_vis_release_seat(n)
			_vis_phase(n, "toexit")   # không tới được chỗ ngồi: mang đồ đi
		"totrash":
			n.trash = false
			_vis_phase(n, "toexit")
		_:
			_queue_remove(int(n.id))
			_vis_phase(n, "toexit")

func _vis_pick_item(n: Dictionary) -> String:
	var pool := ["com_ga", "com_suon", "mi_xao", "banh_mi", "tra_dao", "tra_tac"]
	if bool(n.teacher):
		pool = ["nuoc_suoi", "tra_tac", "banh_mi"]
	return str(pool[_rng.randi_range(0, pool.size() - 1)])

func _vis_update(n: Dictionary, delta: float) -> void:
	if str(n.ph) == "gone":
		return
	n.life = float(n.life) + delta
	if float(n.life) > 480.0:
		_vis_leave(n)
		return
	n.ph_t = float(n.ph_t) - delta
	match str(n.ph):
		"arrive":
			if _spot_clear(START_POS, int(n.id)):
				if _queue.size() < QUEUE_MAX:
					_queue.append(int(n.id))
					_vis_phase(n, "toq")
				else:
					_vis_phase(n, "toexit")
		"toq":
			if _vis_walk(n, _q_slot(n), delta):
				_vis_phase(n, "queue")
				n.ph_t = 90.0
				n.face = 1
		"queue":
			var slot := _q_slot(n)
			if n.pos.distance_to(slot) > 2.5:
				_vis_phase(n, "toq")   # hàng nhích lên
			else:
				n.face = 1
				var cashier: Dictionary = _npcs[_cash_i]
				if _queue.find(int(n.id)) == 0 and _serving < 0 and float(cashier.talk) <= 0.0:
					_serving = int(n.id)
					_vis_phase(n, "buy")
					n.ph_t = _rng.randf_range(2.4, 3.6)
					cashier.talk = float(n.ph_t)
					cashier.face = 0
				elif float(n.ph_t) <= 0.0:
					_vis_phase(n, "toexit")
					_queue_remove(int(n.id))
		"buy":
			if float(n.ph_t) <= 0.0:
				_queue_remove(int(n.id))
				_serving = -1
				n.item = _vis_pick_item(n)
				var si := -1
				if not bool(n.take):
					si = _vis_pick_seat(n)
				if si < 0:
					_vis_phase(n, "toexit")
				else:
					_seats[si]["res"] = int(n.id)
					n.tseat = si
					_vis_phase(n, "toseat")
		"toseat":
			var ts := int(n.tseat)
			if ts < 0 or int(_seats[ts].res) != int(n.id):
				_vis_phase(n, "toexit")
			elif _vis_walk(n, _seat_goal(ts), delta):
				var s: Dictionary = _seats[ts]
				s["taken"] = "npc"
				s["res"] = -1
				n.seat = ts
				n.pos = s.pos
				n.face = int(s.face)
				n.food = n.item
				n.item = ""
				n.tseat = -1
				_vis_phase(n, "sit")
				n.ph_t = _rng.randf_range(18.0, 40.0) if bool(n.teacher) else _rng.randf_range(25.0, 55.0)
		"sit":
			if float(n.ph_t) <= 0.0:
				_vis_release_seat(n)
				n.trash = true
				_vis_phase(n, "totrash")
		"totrash":
			var bp := BIN_USE + Vector2(float(int(n.id) % 3 - 1) * 8.0, 0.0)
			if _vis_walk(n, bp, delta):
				_vis_phase(n, "dump")
				n.ph_t = 0.9
				n.face = 1
				_bin_t = 0.7
				_bin_i = int(n.id) % 3
		"dump":
			if float(n.ph_t) <= 0.0:
				n.trash = false
				_vis_phase(n, "toexit")
		"toexit":
			if _vis_walk(n, Vector2(412, 250), delta):
				_vis_leave(n)
	if str(n.ph) != "gone" and int(n.fail) >= 3:
		_vis_fallback(n)

# ---------- đường đi trong nhà: BFS trên lưới 4px ----------

func _build_in_grid() -> void:
	_ig_w = int((VIEW.x - 28.0) / IG) + 1
	_ig_h = int((FLOOR_BOTTOM - IG_ORG.y) / IG) + 1
	_ig_blk = PackedByteArray()
	_ig_blk.resize(_ig_w * _ig_h)
	for j in range(_ig_h):
		for i in range(_ig_w):
			var gp := IG_ORG + Vector2(float(i) * IG, float(j) * IG)
			var bl := _in_blocked(gp)
			for off in [Vector2(1.5, 1.5), Vector2(-1.5, 1.5), Vector2(1.5, -1.5), Vector2(-1.5, -1.5)]:
				if not bl and _in_blocked(gp + off):
					bl = true   # điểm sát mép vật cản coi như bị chặn để đường đi không cạ vào vật
			_ig_blk[j * _ig_w + i] = 1 if bl else 0

func _ig_cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori((p.x - IG_ORG.x) / IG + 0.5), 0, _ig_w - 1), clampi(floori((p.y - IG_ORG.y) / IG + 0.5), 0, _ig_h - 1))

func _ig_pos(c: Vector2i) -> Vector2:
	return IG_ORG + Vector2(float(c.x) * IG, float(c.y) * IG)

func _ig_near(c: Vector2i, blk: PackedByteArray) -> Vector2i:
	if blk[c.y * _ig_w + c.x] == 0:
		return c
	for r in range(1, 7):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := Vector2i(c.x + dx, c.y + dy)
				if q.x < 0 or q.y < 0 or q.x >= _ig_w or q.y >= _ig_h:
					continue
				if blk[q.y * _ig_w + q.x] == 0:
					return q
	return Vector2i(-1, -1)

func _in_path(a: Vector2, b: Vector2, avoid: Array = []) -> Array:
	var blk := _ig_blk.duplicate()
	var sc0 := _ig_cell(a)
	var gc0 := _ig_cell(b)
	for ap in avoid:
		var ac := _ig_cell(ap)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var q := Vector2i(ac.x + dx, ac.y + dy)
				if q.x < 0 or q.y < 0 or q.x >= _ig_w or q.y >= _ig_h:
					continue
				if _ig_pos(q).distance_to(ap) <= 6.0 and not (q.x == sc0.x and q.y == sc0.y) and not (q.x == gc0.x and q.y == gc0.y):
					if _ig_blk[q.y * _ig_w + q.x] == 0:
						blk[q.y * _ig_w + q.x] = 1
	var sc := _ig_near(sc0, _ig_blk)
	var gc := _ig_near(gc0, blk)
	if sc.x < 0 or gc.x < 0:
		return []
	var total := _ig_w * _ig_h
	var prev := PackedInt32Array()
	prev.resize(total)
	prev.fill(-2)
	var si := sc.y * _ig_w + sc.x
	var gi := gc.y * _ig_w + gc.x
	prev[si] = -1
	var queue: Array = [sc]
	var head := 0
	var found := si == gi
	while head < queue.size() and not found:
		var c: Vector2i = queue[head]
		head += 1
		for dd in NAV_DIRS:
			var dv: Vector2i = dd
			var q := Vector2i(c.x + dv.x, c.y + dv.y)
			if q.x < 0 or q.y < 0 or q.x >= _ig_w or q.y >= _ig_h:
				continue
			var qi := q.y * _ig_w + q.x
			if prev[qi] != -2 or blk[qi] != 0:
				continue
			if dv.x != 0 and dv.y != 0:
				if blk[c.y * _ig_w + c.x + dv.x] != 0 or blk[(c.y + dv.y) * _ig_w + c.x] != 0:
					continue
			prev[qi] = c.y * _ig_w + c.x
			if qi == gi:
				found = true
				break
			queue.append(q)
	if not found:
		return []
	var pts: Array = []
	var cur := gi
	while cur != si:
		pts.append(_ig_pos(Vector2i(cur % _ig_w, int((cur - cur % _ig_w) / float(_ig_w)))))
		cur = prev[cur]
	pts.reverse()
	# bỏ điểm thẳng hàng
	var out: Array = []
	var last_dir := Vector2.ZERO
	for k in pts.size():
		var from_p: Vector2 = a if k == 0 else pts[k - 1]
		var dir: Vector2 = (pts[k] - from_p).normalized()
		if k > 0 and dir.distance_to(last_dir) < 0.01:
			var li := out.size() - 1
			out[li] = pts[k]
		else:
			out.append(pts[k])
		last_dir = dir
	if not _in_blocked(b):
		out.append(b)
	return out

func _draw_cups(p: Node2D, q: Vector2) -> void:
	p.shadow(Vector2(q.x, q.y + 1.0), 10.0)
	# tủ gỗ nhỏ
	p.rc(q.x - 8.0, q.y - 12.0, 16, 13, C_WOOD_DK.darkened(0.2))
	p.rc(q.x - 7.0, q.y - 11.0, 14, 11, C_WOOD)
	p.rc(q.x - 8.0, q.y - 13.0, 16, 2, C_WOOD.lightened(0.25))
	p.rc(q.x, q.y - 11.0, 1, 11, C_WOOD_DK)
	p.rc(q.x - 2.0, q.y - 6.0, 1, 2, Color("e6c84a"))
	p.rc(q.x + 2.0, q.y - 6.0, 1, 2, Color("e6c84a"))
	# biển cốc nhựa trên cửa tủ
	p.rc(q.x - 5.0, q.y - 9.0, 3, 3, Color("e9f2f8"))
	p.rc(q.x + 3.0, q.y - 9.0, 3, 3, Color("e9f2f8"))
	# hai chồng cốc nhựa: cao thấp theo số cốc còn lại
	var h := maxi(2, int(float(_cup_stock) * 0.9) + 1)
	for t in 2:
		var x0 := q.x - 6.0 + float(t) * 7.0
		p.rc(x0, q.y - 13.0 - float(h), 5, h, Color("e9f2f8"))
		p.rc(x0 + 3.0, q.y - 13.0 - float(h), 2, h, Color("c3d6e2"))
		for k in range(0, h, 2):
			p.rc(x0, q.y - 13.0 - float(k), 5, 1, Color("b4cbd8"))
		p.rc(x0 - 1.0, q.y - 14.0 - float(h), 7, 1, Color("ffffff"))
	if _cup_stock <= 0:
		p.rc(q.x - 6.0, q.y - 14.0, 12, 1, Color("c0392b"))

func _draw_staff_extras(g, n: Dictionary) -> void:
	var p: Vector2 = n.pos
	var face := int(n.face)
	g.rc(p.x - 5.0, p.y - 25.0, 10, 3, Color("f4f4f0"))
	g.rc(p.x - 5.0, p.y - 25.0, 10, 1, Color("ffffff"))
	if face != 1:
		g.rc(p.x - 4.0, p.y - 12.0, 8, 8, Color("f4f4f0"))
		g.rc(p.x - 4.0, p.y - 12.0, 8, 1, Color("c8c8c0"))
		g.rc(p.x - 1.0, p.y - 10.0, 2, 2, Color("2f8f4a"))

func _paint_staff(p: Node2D) -> void:
	for n in _npcs:
		if str(n.a) == "in" and bool(n.staff):
			_draw_walker(p, n)

func _draw_diner_food(g, ti: int, occ: Dictionary) -> void:
	var t: Dictionary = _tables[ti]
	var c: Vector2 = t.c
	for si in _seats.size():
		var s: Dictionary = _seats[si]
		if int(s.tab) != ti or not occ.has(si):
			continue
		var n: Dictionary = _npcs[int(occ[si])]
		var f := str(n.get("food", ""))
		if f == "" or not ICON_OF.has(f):
			continue
		var ox := clampf(float(s.c.x) - c.x, -14.0, 14.0)
		var oy := 2.0 if str(s.side) == "N" else 8.0
		_draw_item(g, str(ICON_OF[f]), c.x + ox, c.y + oy)

func _inv_total() -> int:
	var n := 0
	for k in _inv:
		n += int(_inv[k])
	return n

func _inv_has(id: String) -> int:
	return int(_inv.get(id, 0))

# chỉ thêm khi còn chỗ trong túi; trả về false (không đổi gì) nếu đầy

func _inv_add(id: String, n: int = 1) -> bool:
	if n <= 0 or not ITEMS.has(id) or _inv_total() + n > BAG_CAP:
		return false
	_inv[id] = _inv_has(id) + n
	return true

func _inv_remove(id: String, n: int = 1) -> bool:
	if _inv_has(id) < n:
		return false
	_inv[id] = _inv_has(id) - n
	if int(_inv[id]) <= 0:
		_inv.erase(id)
	return true

func begin() -> void:
	super()

func finish() -> void:
	super()

# active = true khi bất cứ phần nào của căn tin đang giữ người chơi (trong nhà, hội thoại, cửa hàng, đang ngồi)
func _sync_active() -> void:
	var want := inside or _dlg_open or _seated >= 0
	if want and not active:
		begin()
	elif not want and active:
		finish()

func _refresh_hud() -> void:
	if game.hud != null:
		game.hud.visible = not inside

func _sfx(nm: String) -> void:
	if game.audio != null:
		game.audio.play_sfx(nm)

func _fmt(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out + "đ"

func _face_toward(from: Vector2, to: Vector2) -> int:
	var d := to - from
	if absf(d.x) > absf(d.y):
		return 2 if d.x < 0.0 else 3
	return 1 if d.y < 0.0 else 0

# ======================= NODE CHẠY LÚC RUNTIME (tạo đúng một lần trong _ready) =======================

func _build_overlay_nodes() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 5   # trên thế giới, dưới thanh HUD và sổ tay
	_layer.visible = false
	add_child(_layer)
	var script: Script = load("res://scripts/draw/characters.gd")
	_painter = script.new()
	_painter.font = game.font
	_painter.logo = game.logo
	_layer.add_child(_painter)
	_painter.draw.connect(_paint)

func _flat(fill: Color, border: Color, bw: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	return sb

func _lbl(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, col: Color, al: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	# font và cỡ chữ phải có TRƯỚC khi đặt size: Control ép size >= kích thước tối thiểu theo cỡ chữ mặc định (16)
	l.add_theme_font_override("font", game.font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.clip_text = false   # dấu tiếng Việt của font.ttf cao hơn ascent: cắt sẽ mất dấu
	l.horizontal_alignment = al
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = text
	parent.add_child(l)
	# size đặt SAU add_child: trước khi vào cây, Godot chưa nạp theme override (font 8) và ép size theo font mặc định 16
	l.position = pos
	l.size = sz
	return l

func _panel(parent: Control, r: Rect2, fill: Color, border: Color) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	p.add_theme_stylebox_override("panel", _flat(fill, border))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _btn(parent: Control, text: String, r: Rect2, cb: Callable, fs: int = 8) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE   # không cướp phím E / Enter / Space của game
	b.add_theme_font_override("font", game.font)
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_stylebox_override("normal", _flat(Color("2d4a7a"), Color("0f1b33")))
	b.add_theme_stylebox_override("hover", _flat(Color("3f66a8"), Color("0f1b33")))
	b.add_theme_stylebox_override("pressed", _flat(Color("1d3050"), Color("0f1b33")))
	b.add_theme_stylebox_override("disabled", _flat(Color("444444"), Color("222222")))
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	# size đặt SAU add_child: trước khi vào cây, Godot ép size theo font 16 và stylebox mặc định (nút cao ~30)
	b.position = r.position
	b.size = r.size
	return b

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 8
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	# ví tiền (góc trên phải, dưới thanh minimap không bị che)
	# Có thể ẩn riêng giao diện ví; PAYMENT vẫn bật cho các giao dịch.
	if PAYMENT and SHOW_WALLET_UI:
		_panel(root, Rect2(336, 2, 140, 15), Color(0.05, 0.08, 0.14, 0.85), Color("e0b020"))
		_wallet = _lbl(root, "", Vector2(338, 2), Vector2(136, 15), 8, Color("ffe28a"), HORIZONTAL_ALIGNMENT_CENTER)
	# thông báo nổi
	_toast = _lbl(root, "", Vector2(90, 20), Vector2(300, 14), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_toast.visible = false
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	_build_dialog_ui(root)

# ---------- hệ thống căn chỉnh chung (toạ độ viewport 480x270) ----------
# Mọi giao diện căn tin dùng chung: khung 400 rộng, lề 8, thanh tiêu đề 20, nút cao 16.
# Hộp chữ luôn cao hơn dòng chữ của font.ttf (dấu tiếng Việt cao vượt ascent) nên không bật clip_text.
const UI_X := 40.0
const UI_W := 400.0
const UI_PAD := 8.0
const UI_BAR := 20.0
const UI_BTN_H := 16.0
const UI_BTN_W := 36.0
const UI_BTN_CLOSE_W := 72.0
const UI_GAP := 4.0
const UI_FRAME := Color(0.06, 0.09, 0.16, 0.98)
const UI_ZONE := Color(0.03, 0.05, 0.1, 0.9)
const TBL_ROW_H := 24.0

# khung chính + thanh tiêu đề; trả về nhãn tiêu đề
func _ui_frame(parent: Control, y: float, h: float, tfs: int) -> Label:
	_panel(parent, Rect2(UI_X, y, UI_W, h), UI_FRAME, Color("e0b020"))
	_panel(parent, Rect2(UI_X, y, UI_W, UI_BAR), Color("1b2f6e"), Color("e0b020"))
	return _lbl(parent, "", Vector2(UI_X, y), Vector2(UI_W, UI_BAR), tfs, Color("ffe28a"), HORIZONTAL_ALIGNMENT_CENTER)

# một nhãn nằm trọn trong một ô chữ nhật
func _lblr(parent: Control, text: String, r: Rect2, fs: int, col: Color, al: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return _lbl(parent, text, r.position, r.size, fs, col, al)

# nút căn giữa theo chiều dọc trong một dải [y, y+h]
func _btn_in(parent: Control, text: String, x: float, y: float, w: float, h: float, cb: Callable, fs: int = 8) -> Button:
	return _btn(parent, text, Rect2(x, y + floorf((h - UI_BTN_H) / 2.0), w, UI_BTN_H), cb, fs)

func _build_dialog_ui(root: Control) -> void:
	_dlg_root = Control.new()
	_dlg_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dlg_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_root.visible = false
	root.add_child(_dlg_root)
	# vùng: thẻ tên / lời thoại / dải dưới (hướng dẫn + nút đóng)
	var px := 30.0
	var pw := 420.0
	var ix := px + UI_PAD
	var iw := pw - 2.0 * UI_PAD
	var py := 180.0
	_panel(_dlg_root, Rect2(px, py, pw, 76.0), UI_FRAME, Color("e0b020"))
	_panel(_dlg_root, Rect2(ix, py - 8.0, 140, 16), Color("1b2f6e"), Color("e0b020"))
	_dlg_name = _lblr(_dlg_root, "", Rect2(ix, py - 8.0, 140, 16), 9, Color("ffe28a"), HORIZONTAL_ALIGNMENT_CENTER)
	var ty := py + 12.0
	_dlg_text = _lblr(_dlg_root, "", Rect2(ix, ty, iw, 36), 9, Color.WHITE)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var fy := ty + 36.0 + UI_GAP
	_dlg_hint = _lblr(_dlg_root, "", Rect2(ix, fy, iw - UI_BTN_CLOSE_W - UI_GAP, UI_BTN_H), 7, Color("9fd3f0"))
	_dlg_btn = _btn(_dlg_root, "Đóng (Esc)", Rect2(ix + iw - UI_BTN_CLOSE_W, fy, UI_BTN_CLOSE_W, UI_BTN_H), _close_dialog, 7)

# ======================= PHÍM E: MỘT LẦN BẤM = MỘT VIỆC =======================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var code: int = k.physical_keycode
	# 2) hội thoại đang mở: E tiếp / đóng, Q đóng
	if _dlg_open:
		if _dlg_key(code):
			get_viewport().set_input_as_handled()
		return
	if code != KEY_E:
		return
	if _closing:
		get_viewport().set_input_as_handled()
		return
	# tính năng khác (quiz, câu cá, phòng B4.2...) đang chạy thì nhường
	if not active and game.is_busy():
		return
	var act := _pick_action()
	if act.is_empty():
		if inside:
			get_viewport().set_input_as_handled()
		return
	_do_action(act)
	get_viewport().set_input_as_handled()

# Thứ tự ưu tiên: hội thoại / đang đóng (chặn hết) > đang ngồi (đứng dậy) > NPC (nói chuyện) > ghế (ngồi) > cửa (vào / ra).
# NPC và ghế so theo khoảng cách; ngang nhau thì NPC thắng.
func _pick_action() -> Dictionary:
	if _dlg_open or _closing:
		return {}
	if _seated >= 0:
		return {"kind": "stand"}
	var a := "in" if inside else "out"
	var pp := _pp()
	var ni := _npc_near(a)
	var si := _seat_near(a)
	if ni >= 0 or si >= 0:
		var nd := 9999.0
		var sd := 9999.0
		if ni >= 0:
			nd = pp.distance_to(_talk_pt(_npcs[ni]))
		if si >= 0:
			sd = _seat_dist(si, pp)
		if ni >= 0 and nd <= sd:
			return {"kind": "talk", "i": ni}
		return {"kind": "sit", "i": si}
	if inside:
		if _pos.distance_to(DOOR_IN) < 26.0:
			return {"kind": "exit"}
	elif game.player.distance_to(DOOR_OUT) < DOOR_RANGE:
		return {"kind": "enter"}
	return {}

func _do_action(act: Dictionary) -> void:
	match str(act.kind):
		"stand":
			_stand_up()
		"talk":
			_open_dialog(int(act.i))
		"sit":
			_sit(int(act.i))
		"enter":
			_enter_inside()
		"exit":
			_closing = true

func _prompt_text() -> String:
	var act := _pick_action()
	if act.is_empty():
		return ""
	match str(act.kind):
		"stand":
			return "E: Đứng dậy"
		"talk":
			return "E: Trò chuyện"
		"sit":
			return "E: Ngồi"
		"enter":
			return "E: Vào căn tin"
		"exit":
			return "E: Ra ngoài"
	return ""

# ======================= VÀO / RA =======================

func _enter_inside() -> void:
	inside = true
	_closing = false
	_pos = START_POS
	_face = 1
	_fade = 1.0
	_layer.visible = true
	_refresh_hud()
	_sync_active()
	_sfx("click")

func _leave_inside() -> void:
	inside = false
	_closing = false
	_layer.visible = false
	game.player = _find_free("out", SPAWN_OUT)
	game.facing = 0
	_refresh_hud()
	_sync_active()

# ======================= GHẾ =======================

func _talk_pt(n: Dictionary) -> Vector2:
	if bool(n.staff):
		return Vector2(float(n.pos.x), COUNTER.end.y + 6.0)
	return n.pos

func _npc_near(a: String) -> int:
	if STAGE < 5:
		return -1   # hội thoại / mua đồ thuộc giai đoạn 5-6
	var best := -1
	var bd := TALK_RANGE
	var pp := _pp()
	for i in _npcs.size():
		var n: Dictionary = _npcs[i]
		if n.a != a:
			continue
		if a == "out" and n.mode == "diner":
			continue
		var d := pp.distance_to(_talk_pt(n))
		if d < bd:
			bd = d
			best = i
	return best

func _seat_dist(i: int, pp: Vector2) -> float:
	var s: Dictionary = _seats[i]
	return minf(pp.distance_to(s.stand), pp.distance_to(s.c))

func _seat_near(a: String) -> int:
	if a == "in" and STAGE < 6:
		return -1   # ghế trong nhà dùng được từ giai đoạn 6; ghế ngoài sân dùng được ngay
	var best := -1
	var bd := SEAT_RANGE
	var pp := _pp()
	for i in _seats.size():
		var s: Dictionary = _seats[i]
		if s.a != a or not _seat_free(i):
			continue
		var d := _seat_dist(i, pp)
		if d < bd:
			bd = d
			best = i
	return best

func _sit(i: int) -> void:
	var s: Dictionary = _seats[i]
	if not _seat_free(i) or _seated >= 0:
		return
	s["taken"] = "player"
	_seated = i
	_sit_t = 0.0
	if inside:
		_pos = s.pos
		_face = s.face
	else:
		game.player = s.pos
		game.facing = s.face
	_sync_active()
	_sfx("click")

func _stand_up() -> void:
	if _seated < 0:
		return
	var s: Dictionary = _seats[_seated]
	s["taken"] = ""
	var a := "in" if inside else "out"
	var p: Vector2 = _find_free(a, s.stand)
	if not inside:
		p = _seat_goal(_seated)   # điểm đứng nằm trong vùng thông ra lối đi
	if inside:
		_pos = p
		_face = 0
	else:
		game.player = p
		game.facing = 0
	_seated = -1
	_sync_active()

func _move_key_down() -> bool:
	return (
		Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	)

# ======================= HỘI THOẠI =======================

func _open_dialog(i: int) -> void:
	var n: Dictionary = _npcs[i]
	_dlg_open = true
	_dlg_npc = i
	_dlg_n = 0
	n.talk = 10.0
	if int(n.seat) < 0:
		n.face = _face_toward(n.pos, _pp())
	_dlg_name.text = str(n.name)
	_dlg_root.visible = true
	_show_line()
	_sync_active()
	_sfx("click")

func _show_line() -> void:
	var n: Dictionary = _npcs[_dlg_npc]
	var lines: Array = n.lines
	_dlg_text.text = str(lines[(int(n.line_i) + _dlg_n) % lines.size()])
	_dlg_n += 1
	_dlg_hint.text = "E: Đóng" if _dlg_n >= lines.size() else "E: Tiếp"

func _dlg_advance() -> void:
	var n: Dictionary = _npcs[_dlg_npc]
	if _dlg_n >= n.lines.size():
		_close_dialog()
	else:
		_show_line()

func _close_dialog() -> void:
	if not _dlg_open:
		return
	if _dlg_npc >= 0 and _dlg_npc < _npcs.size():
		var n: Dictionary = _npcs[_dlg_npc]
		n.line_i = int(n.line_i) + _dlg_n
		n.talk = 1.0
	_dlg_open = false
	_dlg_npc = -1
	_dlg_root.visible = false
	_sync_active()

# ======================= CỬA HÀNG =======================

# ---------- giai đoạn 5: tiền, tiền sinh hoạt tuần, lưu / tải ----------

func _money_refresh() -> void:
	if _wallet != null:
		_wallet.text = "Tiền: " + _fmt(money)

func get_wallet_text() -> String:
	return _fmt(money)

func set_wallet_balance(balance: int, reason: String = "") -> void:
	var target := maxi(balance, 0)
	var delta := target - money
	if delta > 0:
		_money_add(delta, reason)
	elif delta < 0:
		_money_spend(-delta, reason)
	_eco_save()

# Điểm nối tương thích với vòng quay thưởng của mini quiz NPC.
func add_quiz_reward(amount: int) -> String:
	if amount <= 0:
		return ""
	_money_add(amount, "Thưởng mini quiz NPC")
	_eco_save()
	return _fmt(amount)

func _money_add(n: int, reason: String = "") -> void:
	if n <= 0:
		return
	money += n
	_money_refresh()
	money_changed.emit(n, reason)

# trả về false (và không đổi gì) nếu số tiền không hợp lệ hoặc không đủ
func _money_spend(n: int, reason: String = "") -> bool:
	if n <= 0 or n > money:
		return false
	money -= n
	_money_refresh()
	money_changed.emit(-n, reason)
	return true

func _week_now() -> int:
	return Schedule.week_no(int(game.day))

func _eco_init() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH) and cfg.load(SAVE_PATH) == OK:
		_eco_load(cfg)
	else:
		# chưa có bản lưu = game mới: cấp tiền đầu và đồ ban đầu đúng một lần; tuần hiện tại tính là đã nhận
		money = START_MONEY
		for sid in START_ITEMS:
			_inv[sid] = 1
		_paid_weeks = [_week_now()]
	_eco_ready = true
	_money_refresh()
	_eco_save()

func _eco_load(cfg: ConfigFile) -> void:
	var m: Variant = cfg.get_value("eco", "money", null)
	var save_version := int(cfg.get_value("eco", "version", 0))
	if save_version < 4:
		money = START_MONEY   # reset số dư một lần khi nâng lên bản mới (tránh giữ tiền test cũ 3.2M)
	elif m == null:
		money = START_MONEY
	else:
		money = maxi(int(m), 0)
	_paid_weeks = []
	var pw: Variant = cfg.get_value("eco", "paid_weeks", [])
	if pw is Array:
		for w in pw:
			if not _paid_weeks.has(int(w)):
				_paid_weeks.append(int(w))
	if save_version < 4 and not _paid_weeks.has(_week_now()):
		_paid_weeks.append(_week_now())  # không cộng trợ cấp tuần ngay khi mở bản mới
	if _paid_weeks.is_empty():
		_paid_weeks.append(_week_now())   # không rõ đã nhận tuần nào: không trả bù, tránh nhận trùng
	_trash = maxi(int(cfg.get_value("eco", "trash", 0)), 0)
	var inv: Variant = cfg.get_value("eco", "inv", null)
	if inv is Dictionary:
		for k in inv:
			var id := str(k)
			var c := int(inv[k])
			if ITEMS.has(id) and c > 0 and _inv_total() + c <= BAG_CAP:
				_inv[id] = c
	else:
		for sid in START_ITEMS:
			_inv[sid] = 1

func _eco_signature() -> String:
	return "%d|%s|%s|%s|%d" % [money, str(_paid_weeks), str(_inv), str(_tops), _trash]

func _eco_save() -> void:
	if not _eco_ready:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("eco", "version", 4)
	cfg.set_value("eco", "money", money)
	cfg.set_value("eco", "paid_weeks", _paid_weeks.duplicate())
	cfg.set_value("eco", "inv", _inv.duplicate())
	cfg.set_value("eco", "tops", _tops.duplicate(true))
	cfg.set_value("eco", "trash", _trash)
	if cfg.save(SAVE_PATH) == OK:
		_eco_sig = _eco_signature()
	else:
		push_warning("canteen: không ghi được " + SAVE_PATH)

# mỗi khung hình: khoá mua, kiểm tra tuần mới; mỗi 0,5 giây ghi file nếu dữ liệu có thay đổi
func _eco_tick(delta: float) -> void:
	_buy_lock = maxf(_buy_lock - delta, 0.0)
	var w := _week_now()
	if not _paid_weeks.has(w):
		_paid_weeks.append(w)
		_money_add(WEEKLY_MONEY)
		if _toast != null:
			_toast_msg("Bạn đã nhận " + _fmt(WEEKLY_MONEY) + " tiền sinh hoạt tuần mới!")
		_eco_save()
	_eco_t += delta
	if _eco_t >= 0.5:
		_eco_t = 0.0
		if _eco_signature() != _eco_sig:
			_eco_save()

func _exit_tree() -> void:
	_eco_save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_eco_save()

func _toast_msg(t: String) -> void:
	_toast.text = t
	_toast.visible = true
	_toast_t = 2.5

# ---------- giao diện bàn: túi đồ <-> mặt bàn dùng chung một nguồn dữ liệu (_inv / _tops) ----------

# ======================= MỖI KHUNG HÌNH =======================

func _process(delta: float) -> void:
	_clock += delta
	_eco_tick(delta)
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.visible = false
	_ai_acc += delta
	if _ai_acc >= AI_STEP:
		_update_npcs(_ai_acc)
		_ai_acc = 0.0
	# đang ngồi: bấm phím di chuyển để đứng dậy (người chơi không chạy khi đang ngồi vì active = true)
	if _seated >= 0 and not _dlg_open:
		_sit_t += delta
		if _sit_t > SIT_GRACE and _move_key_down():
			_stand_up()
	if not inside:
		return
	if _closing:
		_fade = minf(_fade + delta * 4.0, 1.0)
		if _fade >= 1.0:
			_leave_inside()
			return
	else:
		_fade = maxf(_fade - delta * 3.0, 0.0)
		if _seated < 0 and not _dlg_open:
			_walk(delta)
	_painter.queue_redraw()

func _walk(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if v == Vector2.ZERO:
		return
	v = v.normalized() * WALK_SPEED * delta
	_face = _face_toward(Vector2.ZERO, v)
	_anim += delta
	var a := _pos + Vector2(v.x, 0.0)
	if _in_blocked(a):
		a = _pos
	var b := a + Vector2(0.0, v.y)
	if _in_blocked(b):
		b = a
	_pos = b

# ======================= VẼ DÙNG CHUNG: BÀN, GHẾ, NGƯỜI NGỒI =======================
# g = Node2D vẽ (game ngoài trời, _painter trong nhà); cả hai dùng chung rc() / draw_person() của game.

func _occ_map(a: String) -> Dictionary:
	var m := {}
	for i in _npcs.size():
		var n: Dictionary = _npcs[i]
		if n.a == a and int(n.seat) >= 0:
			m[int(n.seat)] = i
	return m

func _seat_sort_y(s: Dictionary) -> float:
	var c: Vector2 = s.c
	match str(s.side):
		"N":
			return c.y - 2.0
		"S":
			return c.y + 8.0   # đáy vùng chân ghế là c.y + 7; người đứng phía trước (chân y >= c.y + 11) phải vẽ sau ghế
	return c.y + 4.0

func _draw_table(g, t: Dictionary, ti: int) -> void:
	var c: Vector2 = t.c
	var hw: float = t.hw
	g.shadow(Vector2(c.x + 2.0, c.y + 12.0), hw + 4.0)
	if str(t.a) == "out":
		var top := C_IRON if ti % 2 == 0 else Color("5a3a22")
		g.rc(c.x - hw + 1.0, c.y + 5.0, 2, 7, C_IRON)
		g.rc(c.x + hw - 3.0, c.y + 5.0, 2, 7, C_IRON)
		g.rc(c.x - hw - 1.0, c.y - 6.0, hw * 2.0 + 2.0, 12, C_IRON)
		g.rc(c.x - hw, c.y - 5.0, hw * 2.0, 8, top)
		g.rc(c.x - hw, c.y - 5.0, hw * 2.0, 1, top.lightened(0.35))
		g.rc(c.x - hw, c.y + 3.0, hw * 2.0, 2, C_IRON_HI)
		for i in range(int(-hw) + 3, int(hw) - 2, 5):
			g.rc(c.x + i, c.y - 3.0, 2, 1, top.lightened(0.15))
	else:
		g.rc(c.x - hw + 2.0, c.y + 6.0, 3, 6, C_IRON)
		g.rc(c.x + hw - 5.0, c.y + 6.0, 3, 6, C_IRON)
		g.rc(c.x - hw - 1.0, c.y - 6.0, hw * 2.0 + 2.0, 14, C_WOOD_DK.darkened(0.25))
		g.rc(c.x - hw, c.y - 5.0, hw * 2.0, 8, C_WOOD)
		g.rc(c.x - hw, c.y - 5.0, hw * 2.0, 1, C_WOOD.lightened(0.25))
		g.rc(c.x - hw, c.y + 3.0, hw * 2.0, 4, C_WOOD_DK)
		g.rc(c.x - hw, c.y + 6.0, hw * 2.0, 1, C_WOOD_DK.darkened(0.3))
	# đĩa / ly trên bàn ở chỗ có người ngồi
	for s in _seats:
		if int(s.tab) != ti or str(s.taken) == "" or _tbl_count(ti) > 0:   # có đồ trên bàn thì không vẽ đĩa minh họa (tránh chồng lên món đồ)
			continue
		var sc: Vector2 = s.c
		var px := clampf(sc.x, c.x - hw + 5.0, c.x + hw - 5.0)
		var py := c.y - 2.0
		if str(s.side) == "N":
			py = c.y - 3.0
		elif str(s.side) == "S":
			py = c.y + 1.0
		g.rc(px - 3.0, py, 6, 3, Color("f4f4f4"))
		g.rc(px - 2.0, py, 4, 1, Color("d9a441") if ti % 2 == 0 else Color("c0392b"))
		g.rc(px + 3.0, py - 2.0, 2, 3, Color("bfe6ff"))
	if str(t.a) == "out":
		_draw_table_items(g, c, ti)

# part 0 = phần nằm sau người ngồi, part 1 = phần nằm trước (tay vịn, lưng ghế nhìn từ phía sau)
func _draw_chair(g, s: Dictionary, part: int) -> void:
	var c: Vector2 = s.c
	var out := str(s.a) == "out"
	var fr: Color = C_IRON if out else Color("7d828b")
	var hi: Color = C_IRON_HI if out else Color("a3a8b1")
	var arm: Color = C_ARM
	var seat: Color = fr if out else C_WOOD
	var seat_hi: Color = hi if out else C_WOOD.lightened(0.2)
	match str(s.side):
		"N":
			if part == 0:
				g.shadow(Vector2(c.x, c.y + 6.0), 8.0)
				g.rc(c.x - 8.0, c.y - 13.0, 16, 10, fr)
				g.rc(c.x - 7.0, c.y - 12.0, 14, 8, hi)
				for i in 3:
					g.rc(c.x - 7.0, c.y - 11.0 + i * 3.0, 14, 1, fr)
				g.rc(c.x - 7.0, c.y - 2.0, 14, 7, fr)
				g.rc(c.x - 6.0, c.y - 1.0, 12, 4, seat)
			elif out:
				g.rc(c.x - 9.0, c.y - 6.0, 3, 9, arm)
				g.rc(c.x + 6.0, c.y - 6.0, 3, 9, arm)
				g.rc(c.x - 9.0, c.y - 6.0, 3, 1, arm.lightened(0.3))
				g.rc(c.x + 6.0, c.y - 6.0, 3, 1, arm.lightened(0.3))
		"S":
			if part == 0:
				g.shadow(Vector2(c.x, c.y + 6.0), 8.0)
				g.rc(c.x - 7.0, c.y - 1.0, 14, 7, fr)
				g.rc(c.x - 6.0, c.y, 12, 4, seat)
			else:
				g.rc(c.x - 8.0, c.y - 10.0, 16, 10, fr)
				g.rc(c.x - 7.0, c.y - 9.0, 14, 2, hi)
				for i in 2:
					g.rc(c.x - 7.0, c.y - 6.0 + i * 3.0, 14, 1, hi)
				if out:
					g.rc(c.x - 9.0, c.y - 7.0, 3, 8, arm)
					g.rc(c.x + 6.0, c.y - 7.0, 3, 8, arm)
		_:
			var dirx := -1.0 if str(s.side) == "W" else 1.0   # phía lưng ghế
			if part == 0:
				g.shadow(Vector2(c.x, c.y + 8.0), 8.0)
				var bx := c.x + dirx * 7.0 - 2.0
				g.rc(bx, c.y - 10.0, 4, 17, fr)
				g.rc(bx + (1.0 if dirx < 0.0 else 0.0), c.y - 9.0, 3, 15, hi)
				g.rc(c.x - 6.0, c.y + 1.0, 12, 6, fr)
				g.rc(c.x - 5.0, c.y + 2.0, 10, 3, seat)
				g.rc(c.x - 5.0, c.y + 2.0, 10, 1, seat_hi)
			else:
				g.rc(c.x - 6.0, c.y + 2.0, 12, 4, fr)
				if out:
					g.rc(c.x - 6.0, c.y - 4.0, 12, 2, arm)
					g.rc(c.x - 6.0, c.y - 4.0, 12, 1, arm.lightened(0.3))

# người ngồi: dùng đúng draw_person() của game
func _draw_sitter(g, s: Dictionary, who: Variant) -> void:
	var p: Vector2 = s.pos
	if who == null:
		g.draw_person(p, Color.WHITE, Color("1b1b1b"), int(s.face), 0.0, true, false, false)
		g.ctext("Bạn", p.x - 15.0, p.y - 28.0, 30, 8, Color("ffd23f"))
		return
	var n: Dictionary = who
	var step := 0.0
	if int(float(n.eat)) % 7 < 2:
		step = float(n.eat) * 0.35   # lúc đang ăn thì nhún nhẹ
	g.draw_person(p, n.shirt, n.hair, int(s.face), step, n.uni, n.long, false)
	if float(n.say_t) > 0.0:
		g.draw_speech(n)

func _draw_seat_unit(g, si: int, occ: Dictionary) -> void:
	var s: Dictionary = _seats[si]
	_draw_chair(g, s, 0)
	if int(_seated) == si:
		_draw_sitter(g, s, null)
	elif occ.has(si):
		_draw_sitter(g, s, _npcs[int(occ[si])])
	_draw_chair(g, s, 1)

func _draw_walker(g, n: Dictionary) -> void:
	var step: float = float(n.anim)
	g.draw_person(n.pos, n.shirt, n.hair, int(n.face), step, n.uni, n.long, n.pack)
	if bool(n.staff):
		_draw_staff_extras(g, n)
	var it := str(n.get("item", ""))
	if it != "" and ICON_OF.has(it):
		_draw_item(g, str(ICON_OF[it]), float(n.pos.x) + 8.0, float(n.pos.y) - 6.0)
	if float(n.say_t) > 0.0:
		g.draw_speech(n)
	if bool(n.staff) and _pp().distance_to(n.pos) < 70.0:
		g.ctext(str(n.name), float(n.pos.x) - 30.0, float(n.pos.y) - 28.0, 60, 7, Color("c8f7c5"))

# ======================= GIAI ĐOẠN 2: NỀN SÂN, CỬA, NỘI THẤT TẠM =======================

# Phòng trong nhà tạm thời (giai đoạn 4 sẽ thay bằng quầy, bàn ghế...). Đã có đủ: vào, đi lại, cửa ra, mờ dần.
# ======================= GIAI ĐOẠN 4A: NỘI THẤT =======================
# Phòng 480x270 nhìn từ phía trước: trần trắng (đèn âm, quạt đen) y 0-14, tường kem y 14-58 (menu, cửa sổ kính, cầu thang),
# sàn gạch xám y 58-258, tường trước y 258-270 có cửa kính ra vào. Quầy phục vụ + tủ kính ở bên trái, hai cụm bàn ăn, cầu thang đen ở góc phải.
# Va chạm lấy từ _isolid (xem _build_indoor); vật đứng được vẽ theo y chân (tables, ghế, cột, chậu cây, người chơi).
const WALL_BASE := 58.0
const CEIL_H := 14.0
const FANS := [Vector2(72, 14), Vector2(180, 14), Vector2(296, 14), Vector2(440, 14)]
const LIGHTS_X := [30, 90, 150, 210, 270, 330, 390, 450]
const IN_PILLARS := [Vector2(240, 128), Vector2(240, 212)]
const IN_PLANTS := [Vector2(454, 82), Vector2(26, 246), Vector2(456, 246)]
const IN_BINS := Vector2(24, 150)
const IN_WATER := Vector2(262, 86)
const STAIR := Rect2(330, 22, 96, 42)         # đế cầu thang y 64; lên tới y 22
const BOARD := Rect2(24, 20, 202, 35)         # bảng menu
const MENU_COLS := [
	["CƠM - MÌ", [["Cơm gà", "25K", 0], ["Cơm sườn", "30K", 1], ["Mì xào", "25K", 2]]],
	["ĂN NHẸ", [["Bánh mì", "15K", 3], ["Xôi mặn", "12K", 4], ["Bánh bao", "12K", 5]]],
	["NƯỚC", [["Trà đào", "15K", 6], ["Trà tắc", "10K", 7], ["Nước suối", "8K", 8]]],
]

func _paint() -> void:
	var p := _painter
	p.rc(0, 0, VIEW.x, VIEW.y, Color("23262e"))
	_paint_floor(p)
	_paint_back_wall(p)
	_paint_staff(p)
	_paint_counter(p)
	_paint_stairs(p)
	_paint_side_and_front(p)
	_paint_room_items(p)
	_paint_ceiling_fans(p)
	_paint_prompt_inside(p)
	if _fade > 0.0:
		p.rc(0, 0, VIEW.x, VIEW.y, Color(0, 0, 0, _fade))

# ---------- sàn: gạch xám 24px có ron, góc sáng, vết xước; viền khảm quanh hai cụm bàn ----------
func _paint_floor(p: Node2D) -> void:
	for ty in range(58, 262, 24):
		for tx in range(0, 480, 24):
			var odd := int((tx + ty) / 24.0) % 2 == 0
			p.rc(tx, ty, 24, 24, Color("cdd0d4") if odd else Color("c4c8cd"))
			p.rc(tx, ty, 24, 1, Color("dfe2e5"))
			p.rc(tx, ty, 1, 24, Color("dfe2e5"))
			p.rc(tx + 23, ty, 1, 24, Color("a9aeb5"))
			p.rc(tx, ty + 23, 24, 1, Color("a9aeb5"))
			var h: int = p.hs(tx, ty)
			if h < 40:
				p.rc(tx + 4 + h % 13, ty + 5 + (h * 7) % 12, 3, 1, Color("b6bbc1"))
			if h > 82:
				p.rc(tx + 9 + h % 7, ty + 12 + h % 5, 1, 2, Color("b9bec4"))
	# bóng chân tường sau
	p.rc(0, 58, 480, 3, Color(0, 0, 0, 0.16))
	p.rc(0, 61, 480, 3, Color(0, 0, 0, 0.07))
	# viền khảm quanh hai cụm bàn ăn
	for r in [Rect2(40, 138, 176, 116), Rect2(262, 92, 166, 130)]:
		p.rc(r.position.x, r.position.y, r.size.x, 1, Color("9aa0a8"))
		p.rc(r.position.x, r.end.y, r.size.x, 1, Color("9aa0a8"))
		p.rc(r.position.x, r.position.y, 1, r.size.y, Color("9aa0a8"))
		p.rc(r.end.x, r.position.y, 1, r.size.y + 1.0, Color("9aa0a8"))
		p.rc(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 3.0, 1, Color("e6e8ea"))
		p.rc(r.position.x + 2.0, r.position.y + 2.0, 1, r.size.y - 3.0, Color("e6e8ea"))

# ---------- trần, đèn âm, tường sau, cửa sổ kính, đồng hồ, bảng menu ----------
func _paint_back_wall(p: Node2D) -> void:
	# tường kem
	p.rc(0, CEIL_H, 480, 44, C_WALL)
	p.rc(0, 46, 480, 12, C_WALL.darkened(0.07))      # ốp lưng tường
	p.rc(0, 46, 480, 1, C_WALL.darkened(0.2))
	p.rc(0, 56, 480, 2, Color("8a8470"))              # len chân tường
	# trần trắng, khe tấm trần, đèn âm trần
	p.rc(0, 0, 480, CEIL_H, Color("f4f4f1"))
	for x in range(0, 480, 40):
		p.rc(x, 0, 1, CEIL_H, Color("e2e2dc"))
	p.rc(0, 12, 480, 2, Color("cfcfc8"))
	for lx in LIGHTS_X:
		p.rc(lx - 12, 3, 24, 7, Color("bdbdb5"))
		p.rc(lx - 11, 4, 22, 5, Color("fffbe0"))
		p.rc(lx - 11, 4, 22, 1, Color("ffffff"))
		# quầng sáng nhẹ lên tường dưới đèn
		p.rc(lx - 13, 14, 26, 2, Color(1.0, 0.98, 0.8, 0.22))
		p.rc(lx - 9, 16, 18, 2, Color(1.0, 0.98, 0.8, 0.12))
	# cửa sổ kính lớn: giữa quầy và cầu thang, và góc phải
	_in_window(p, 244.0, 26.0, 78.0, 26.0)
	_in_window(p, 436.0, 26.0, 36.0, 26.0)
	# cột ốp hai bên cầu thang
	p.rc(324, CEIL_H, 5, 44, Color("d8cdaf"))
	p.rc(427, CEIL_H, 5, 44, Color("d8cdaf"))
	p.rc(324, CEIL_H, 1, 44, Color("efe6cc"))
	p.rc(427, CEIL_H, 1, 44, Color("efe6cc"))
	# đồng hồ treo tường
	p.draw_circle(Vector2(235, 36), 7.0, Color("2f343c"))
	p.draw_circle(Vector2(235, 36), 6.0, Color("f6f2e6"))
	p.rc(235, 31, 1, 5, Color("2f343c"))
	p.rc(235, 36, 4, 1, Color("2f343c"))
	p.rc(235, 36, 1, 1, Color("c0392b"))
	_paint_menu_board(p)

func _in_window(p: Node2D, x: float, y: float, w: float, h: float) -> void:
	p.rc(x - 2.0, y - 2.0, w + 4.0, h + 4.0, C_STEEL)
	p.rc(x, y, w, h, Color("9bd0ea"))
	p.rc(x, y, w, h * 0.5, Color("c4e6f6"))
	p.rc(x, y + h - 2.0, w, 2, Color("6fa6c6"))
	var n := maxi(int(w / 26.0), 1)
	for i in range(1, n):
		p.rc(x + w * i / n - 1.0, y, 2, h, C_STEEL)
	p.rc(x, y + h * 0.5 - 1.0, w, 1, C_STEEL_HI)
	for i in range(0, int(w) - 8, 18):
		p.draw_line(Vector2(x + 8.0 + i, y + h - 2.0), Vector2(x + 16.0 + i, y + 2.0), Color(1, 1, 1, 0.28), 2.0)
	p.rc(x - 3.0, y + h + 2.0, w + 6.0, 2, Color("b9ae8c"))   # bệ cửa sổ

func _in_txt(p: Node2D, t: String, x: float, y: float, sz: int, col: Color, right_x: float = -1.0) -> void:
	var w: float = game.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var tx := x
	if right_x >= 0.0:
		tx = right_x - w
	p.ctext(t, tx, y, w + 2.0, sz, col)

# Bảng menu lớn: khung gỗ, nền xanh đậm, ba cột (cơm - mì, ăn nhẹ, nước) mỗi món có hình minh họa nhỏ, tên món và giá (nghìn đồng).
# Chỉ là hình ảnh (chưa nối hệ thống gọi món).
func _paint_menu_board(p: Node2D) -> void:
	var r := BOARD
	p.rc(r.position.x - 3.0, r.position.y - 3.0, r.size.x + 6.0, r.size.y + 6.0, Color("5a3a22"))
	p.rc(r.position.x - 3.0, r.position.y - 3.0, r.size.x + 6.0, 1, Color("8a5a2c"))
	p.rc(r.position.x - 3.0, r.position.y - 3.0, 1, r.size.y + 6.0, Color("7a4f28"))
	p.rc(r.position.x, r.position.y, r.size.x, r.size.y, Color("17402a"))
	p.rc(r.position.x, r.position.y, r.size.x, 1, Color("245a3a"))
	# viền phấn mảnh bên trong bảng
	p.rc(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0, 1, Color("2a6a46"))
	p.rc(r.position.x + 2.0, r.end.y - 3.0, r.size.x - 4.0, 1, Color("2a6a46"))
	p.rc(r.position.x + 2.0, r.position.y + 2.0, 1, r.size.y - 4.0, Color("2a6a46"))
	p.rc(r.end.x - 3.0, r.position.y + 2.0, 1, r.size.y - 4.0, Color("2a6a46"))
	# biển tên "THỰC ĐƠN" treo ở giữa mép trên
	p.rc(103, 14, 44, 10, Color("7d1f1f"))
	p.rc(104, 15, 42, 8, Color("a82a2a"))
	p.ctext("THỰC ĐƠN", 103, 22, 44, 7, Color("ffe28a"))
	var colw := r.size.x / 3.0
	for ci in MENU_COLS.size():
		var col: Array = MENU_COLS[ci]
		var cx := r.position.x + colw * ci
		if ci > 0:
			p.rc(cx, r.position.y + 5.0, 1, r.size.y - 9.0, Color("2f6b49"))
		_in_txt(p, str(col[0]), cx + 4.0, r.position.y + 9.0, 7, Color("ffd23f"))
		p.rc(cx + 4.0, r.position.y + 11.0, colw - 9.0, 1, Color("ffd23f"))
		var rows: Array = col[1]
		for ri in rows.size():
			var by := r.position.y + 19.0 + ri * 7.0
			_menu_icon(p, int(rows[ri][2]), cx + 2.0, by - 6.0)
			_in_txt(p, str(rows[ri][0]), cx + 10.0, by, 7, Color("f6f2e6"))
			_in_txt(p, str(rows[ri][1]), 0.0, by, 6, Color("9fe3a8"), cx + colw - 3.0)

# Hình minh họa món 7x6px trên bảng menu: 0 cơm gà, 1 cơm sườn, 2 mì xào, 3 bánh mì, 4 xôi, 5 bánh bao, 6 trà đào, 7 trà tắc, 8 nước suối
func _menu_icon(p: Node2D, kind: int, x: float, y: float) -> void:
	match kind:
		0, 1:
			p.rc(x, y + 4.0, 7, 2, Color("f4f4f4"))
			p.rc(x + 1.0, y + 5.0, 5, 1, Color("cfd3d8"))
			p.rc(x + 1.0, y + 2.0, 4, 2, Color("fffdf2"))
			if kind == 0:
				p.rc(x + 4.0, y + 1.0, 3, 3, Color("c27a2e"))
				p.rc(x + 4.0, y + 1.0, 3, 1, Color("e5a85a"))
			else:
				p.rc(x + 4.0, y + 1.0, 3, 3, Color("8a4a28"))
				p.rc(x + 4.0, y + 1.0, 3, 1, Color("b8703a"))
				p.rc(x, y + 3.0, 1, 1, Color("4f9a3a"))
		2:
			p.rc(x, y + 4.0, 7, 2, Color("f4f4f4"))
			p.rc(x + 1.0, y + 1.0, 5, 3, Color("e8c04a"))
			p.rc(x + 1.0, y + 2.0, 5, 1, Color("c99a2a"))
			p.rc(x + 2.0, y, 1, 1, Color("4f9a3a"))
			p.rc(x + 4.0, y + 1.0, 1, 1, Color("c0392b"))
		3:
			p.rc(x, y + 2.0, 7, 3, Color("d9a05b"))
			p.rc(x + 1.0, y + 1.0, 5, 1, Color("edc27f"))
			p.rc(x + 1.0, y + 5.0, 5, 1, Color("b87a36"))
			p.rc(x + 2.0, y + 2.0, 1, 2, Color("b87a36"))
			p.rc(x + 4.0, y + 2.0, 1, 2, Color("b87a36"))
		4:
			p.rc(x + 1.0, y + 3.0, 5, 3, Color("c0392b"))
			p.rc(x + 1.0, y + 3.0, 5, 1, Color("e06a5a"))
			p.rc(x + 1.0, y + 1.0, 5, 2, Color("f2d98c"))
			p.rc(x + 2.0, y + 1.0, 1, 1, Color("c27a2e"))
			p.rc(x + 4.0, y + 2.0, 1, 1, Color("c27a2e"))
		5:
			p.rc(x + 1.0, y + 1.0, 5, 4, Color("f6f2e6"))
			p.rc(x + 2.0, y, 3, 1, Color("f6f2e6"))
			p.rc(x + 3.0, y + 1.0, 1, 2, Color("d8d2c0"))
			p.rc(x + 1.0, y + 5.0, 5, 1, Color("c9a05a"))
		6, 7:
			var body := Color("ffb98a") if kind == 6 else Color("f2e27a")
			p.rc(x + 1.0, y + 1.0, 5, 1, Color("ffffff"))
			p.rc(x + 2.0, y + 2.0, 3, 4, body)
			p.rc(x + 2.0, y + 2.0, 1, 4, body.lightened(0.3))
			p.rc(x + 3.0, y + 4.0, 2, 1, Color("ff9a7a") if kind == 6 else Color("7ac143"))
			p.rc(x + 5.0, y, 1, 3, Color("c0392b"))
		_:
			p.rc(x + 3.0, y, 1, 1, Color("2f6bd0"))
			p.rc(x + 2.0, y + 1.0, 3, 5, Color("9fd3f0"))
			p.rc(x + 2.0, y + 3.0, 3, 1, Color("ffffff"))
			p.rc(x + 2.0, y + 1.0, 1, 5, Color("cdeefa"))

# ---------- quầy phục vụ, tủ kính trưng bày, máy tính tiền ----------
# Thứ tự trên mặt quầy từ trái sang phải (người mua đi từ trái): khay + muỗng đũa, tủ kính món mặn, tủ kính bánh, tủ nước, máy tính tiền.
func _paint_counter(p: Node2D) -> void:
	var c := COUNTER
	var x0 := c.position.x
	var x1 := c.end.x
	# ốp gạch trắng sau quầy
	p.rc(x0, 58, c.size.x, 8, Color("ecece6"))
	for i in range(int(x0), int(x1), 6):
		p.rc(i, 58, 1, 8, Color("d4d4cc"))
	p.rc(x0, 62, c.size.x, 1, Color("d4d4cc"))
	# mặt đá quầy + thanh ray thép để khay
	p.rc(x0, c.position.y, c.size.x, 12, Color("dcd7ca"))
	p.rc(x0, c.position.y, c.size.x, 1, Color("f4f1e8"))
	p.rc(x0 - 2.0, c.position.y + 10.0, c.size.x + 4.0, 3, Color("c3c8d0"))
	p.rc(x0 - 2.0, c.position.y + 10.0, c.size.x + 4.0, 1, Color("f0f2f4"))
	p.rc(x0 - 2.0, c.position.y + 12.0, c.size.x + 4.0, 1, Color("8a909a"))
	# mặt trước xanh lá có ô ốp nổi, chân đế tối
	p.rc(x0, c.position.y + 13.0, c.size.x, 15, C_STAFF)
	p.rc(x0, c.position.y + 13.0, c.size.x, 1, C_STAFF.lightened(0.3))
	for i in range(int(x0) + 4, int(x1) - 6, 38):
		p.rc(i, c.position.y + 16.0, 34, 9, C_STAFF.darkened(0.18))
		p.rc(i + 1.0, c.position.y + 17.0, 32, 1, C_STAFF.lightened(0.15))
		p.rc(i, c.position.y + 25.0, 34, 1, C_STAFF.lightened(0.1))
	p.rc(x0, c.end.y - 2.0, c.size.x, 2, Color("1f2329"))
	p.rc(x0 - 2.0, c.end.y, c.size.x + 4.0, 2, Color(0, 0, 0, 0.2))
	# logo trường giữa mặt trước quầy (nếu có), biển chỉ dẫn hai đầu
	if p.logo != null:
		p.draw_texture_rect(p.logo, Rect2(x0 + 105.0, c.position.y + 15.0, 11, 11), false)
	_front_plaque(p, x0 + 3.0, c.position.y + 16.0, 44.0, "LẤY KHAY")
	_front_plaque(p, x1 - 50.0, c.position.y + 16.0, 48.0, "THANH TOÁN")
	# các thiết bị trên mặt quầy
	_paint_trays(p, 16.0, 77.0)
	_paint_case(p, 42.0, 77.0, 88.0, 0)
	_paint_case(p, 134.0, 77.0, 38.0, 1)
	_paint_drink_fridge(p, 176.0, 77.0, 28.0)
	_paint_register(p, 208.0, 77.0)

func _front_plaque(p: Node2D, x: float, y: float, w: float, t: String) -> void:
	p.rc(x, y, w, 9, Color("f4f1e8"))
	p.rc(x, y, w, 1, Color("ffffff"))
	p.rc(x, y + 8.0, w, 1, Color("b9b4a6"))
	p.rc(x + 1.0, y + 1.0, w - 2.0, 7, Color("1f6b3a"))
	p.ctext(t, x, y + 7.0, w, 6, Color("f6f2e6"))

# Một đĩa món mặn 10x6px (phần ăn y..y+3, đĩa y+4..y+5): 0 cơm sườn, 1 gà chiên, 2 rau xào, 3 trứng ốp, 4 cá chiên, 5 thịt kho, 6 canh
func _paint_dish(p: Node2D, kind: int, x: float, y: float) -> void:
	match kind % 7:
		0:
			p.rc(x + 1.0, y + 1.0, 5, 3, Color("fffdf2"))
			p.rc(x + 1.0, y + 3.0, 5, 1, Color("e6e0c8"))
			p.rc(x + 6.0, y + 1.0, 3, 3, Color("8a4a28"))
			p.rc(x + 6.0, y + 1.0, 3, 1, Color("b8703a"))
			p.rc(x, y + 2.0, 1, 2, Color("4f9a3a"))
		1:
			p.rc(x + 1.0, y + 1.0, 4, 3, Color("c27a2e"))
			p.rc(x + 1.0, y + 1.0, 4, 1, Color("e5a85a"))
			p.rc(x + 5.0, y + 2.0, 2, 1, Color("f6f2e6"))
			p.rc(x + 6.0, y + 1.0, 3, 3, Color("b8691f"))
			p.rc(x + 6.0, y + 1.0, 3, 1, Color("e5a85a"))
		2:
			p.rc(x + 1.0, y + 1.0, 8, 3, Color("3f8f34"))
			p.rc(x + 2.0, y + 1.0, 2, 1, Color("7ac143"))
			p.rc(x + 6.0, y + 2.0, 1, 1, Color("e0782a"))
			p.rc(x + 4.0, y + 3.0, 1, 1, Color("2a6a22"))
		3:
			p.rc(x + 1.0, y + 2.0, 8, 2, Color("f6f2e6"))
			p.rc(x + 2.0, y + 1.0, 3, 2, Color("f2c230"))
			p.rc(x + 6.0, y + 1.0, 2, 2, Color("f2c230"))
		4:
			p.rc(x + 1.0, y + 1.0, 7, 3, Color("d98a3a"))
			p.rc(x + 8.0, y + 1.0, 1, 3, Color("b8691f"))
			p.rc(x + 2.0, y + 2.0, 1, 1, Color("23262e"))
			p.rc(x + 4.0, y + 1.0, 1, 3, Color("b8691f"))
			p.rc(x + 1.0, y + 1.0, 7, 1, Color("f0b060"))
		5:
			p.rc(x + 1.0, y + 1.0, 8, 3, Color("6b3a1e"))
			p.rc(x + 3.0, y + 1.0, 2, 2, Color("f6f2e6"))
			p.rc(x + 6.0, y + 1.0, 2, 2, Color("f6f2e6"))
			p.rc(x + 1.0, y + 1.0, 8, 1, Color("8a5a2c"))
		_:
			p.rc(x + 1.0, y + 1.0, 8, 3, Color("c0392b"))
			p.rc(x + 1.0, y + 1.0, 8, 1, Color("e06a5a"))
			p.rc(x + 3.0, y + 2.0, 1, 1, Color("4f9a3a"))
			p.rc(x + 6.0, y + 2.0, 1, 1, Color("4f9a3a"))
	p.rc(x, y + 4.0, 10, 1, Color("ffffff"))
	p.rc(x + 1.0, y + 5.0, 8, 1, Color("c3c8ce"))

# Món bánh 12x6px: 0 bánh mì, 1 bánh bao đôi, 2 bánh ngọt có cherry, 3 bánh quy socola
func _paint_bakery(p: Node2D, kind: int, x: float, y: float) -> void:
	match kind % 4:
		0:
			p.rc(x, y + 2.0, 12, 3, Color("d9a05b"))
			p.rc(x + 1.0, y + 1.0, 10, 1, Color("edc27f"))
			p.rc(x + 1.0, y + 5.0, 10, 1, Color("b87a36"))
			for i in [3, 6, 9]:
				p.rc(x + i, y + 2.0, 1, 2, Color("b87a36"))
		1:
			for i in 2:
				p.rc(x + 1.0 + i * 6.0, y + 2.0, 5, 4, Color("f6f2e6"))
				p.rc(x + 2.0 + i * 6.0, y + 1.0, 3, 1, Color("f6f2e6"))
				p.rc(x + 3.0 + i * 6.0, y + 2.0, 1, 2, Color("d8d2c0"))
				p.rc(x + 1.0 + i * 6.0, y + 5.0, 5, 1, Color("c9a05a"))
		2:
			p.rc(x + 1.0, y + 3.0, 10, 3, Color("f2b6c4"))
			p.rc(x + 1.0, y + 3.0, 10, 1, Color("fbd7e0"))
			p.rc(x + 1.0, y + 5.0, 10, 1, Color("e08aa0"))
			p.rc(x + 5.0, y + 1.0, 2, 2, Color("c0392b"))
		_:
			for i in 2:
				p.rc(x + 1.0 + i * 6.0, y + 2.0, 5, 3, Color("c98a4b"))
				p.rc(x + 1.0 + i * 6.0, y + 2.0, 5, 1, Color("6b3a1e"))
				p.rc(x + 2.0 + i * 6.0, y + 3.0, 1, 1, Color("6b3a1e"))
	p.rc(x, y + 6.0, 12, 1, Color("c3c8ce"))

# Tủ kính: x = mép trái, yb = mép dưới thân tủ; kind 0 = món mặn (đèn hâm nóng), kind 1 = bánh
func _paint_case(p: Node2D, x: float, yb: float, w: float, kind: int) -> void:
	var top := yb - 19.0
	p.rc(x - 1.0, top - 1.0, w + 2.0, 22, C_STEEL)
	p.rc(x, top + 1.0, w, 13, Color("d3ecf7"))
	p.rc(x, top + 1.0, w, 1, Color("fff1c0"))      # đèn hâm nóng
	p.rc(x, top + 6.0, w, 1, C_STEEL_HI)           # kệ giữa
	# món ăn trên hai kệ
	if kind == 0:
		var n := int((w - 4.0) / 12.0)
		for row in 2:
			for i in range(n):
				_paint_dish(p, i * 2 + row * 3, x + 3.0 + i * 12.0, top + 1.0 + row * 6.0)
	else:
		for row in 2:
			for i in 2:
				_paint_bakery(p, i + row * 2, x + 3.0 + i * 17.0, top + 0.0 + row * 6.0)
	# phản chiếu kính
	for i in range(0, int(w) - 10, 22):
		p.draw_line(Vector2(x + 8.0 + i, top + 12.0), Vector2(x + 11.0 + i, top + 2.0), Color(1, 1, 1, 0.28), 2.0)
	p.rc(x, top + 14.0, w, 4, C_STEEL_HI)
	p.rc(x, top + 17.0, w, 1, C_STEEL)
	# thẻ giá nhỏ ở mép dưới tủ
	for i in range(int((w - 4.0) / 12.0)):
		p.rc(x + 5.0 + i * 12.0, top + 15.0, 5, 2, Color("ffd23f") if i % 2 == 0 else Color("ffffff"))

# Tủ nước: trà đào, trà tắc (ly có nắp và ống hút) và chai nước suối
func _paint_drink_fridge(p: Node2D, x: float, yb: float, w: float) -> void:
	var top := yb - 19.0
	p.rc(x - 1.0, top - 1.0, w + 2.0, 22, C_STEEL)
	p.rc(x - 1.0, top - 1.0, w + 2.0, 3, Color("2f6bd0"))
	p.rc(x, top + 2.0, w, 12, Color("cfe7f3"))
	p.rc(x, top + 7.0, w, 1, C_STEEL_HI)
	for i in 4:
		_paint_drink(p, 0 if i % 2 == 0 else 1, x + 2.0 + i * 6.0, top + 3.0)
	for i in 4:
		_paint_drink(p, 2, x + 2.0 + i * 6.0, top + 8.0)
	p.draw_line(Vector2(x + 6.0, top + 12.0), Vector2(x + 9.0, top + 3.0), Color(1, 1, 1, 0.3), 2.0)
	p.rc(x, top + 14.0, w, 4, C_STEEL_HI)
	p.rc(x, top + 17.0, w, 1, C_STEEL)

# kind 0 = trà đào (cam), 1 = trà tắc (vàng chanh), 2 = chai nước suối; kích thước 4x5px
func _paint_drink(p: Node2D, kind: int, x: float, y: float) -> void:
	if kind == 2:
		p.rc(x + 1.0, y, 2, 1, Color("2f6bd0"))
		p.rc(x, y + 1.0, 4, 4, Color("9fd3f0"))
		p.rc(x, y + 2.0, 4, 1, Color("ffffff"))
		return
	var body := Color("ffb98a") if kind == 0 else Color("f2e27a")
	p.rc(x, y, 4, 1, Color("ffffff"))
	p.rc(x, y + 1.0, 4, 4, body)
	p.rc(x, y + 1.0, 1, 4, body.lightened(0.3))
	p.rc(x + 3.0, y - 1.0, 1, 2, Color("c0392b"))

# Khay xếp chồng (xanh lá, cam) và ống muỗng đũa ở đầu quầy
func _paint_trays(p: Node2D, x: float, yb: float) -> void:
	for i in 5:
		p.rc(x, yb - 2.0 - i * 2.0, 20, 2, Color("2f8f4a") if i % 2 == 0 else Color("c8742e"))
		p.rc(x, yb - 2.0 - i * 2.0, 20, 1, Color(1, 1, 1, 0.25))
	p.rc(x + 21.0, yb - 8.0, 4, 8, Color("c3c8d0"))
	p.rc(x + 21.0, yb - 8.0, 4, 1, Color("f0f2f4"))
	p.rc(x + 22.0, yb - 11.0, 1, 3, Color("8a909a"))
	p.rc(x + 24.0, yb - 10.0, 1, 2, Color("c8742e"))

func _paint_register(p: Node2D, x: float, yb: float) -> void:
	p.rc(x, yb - 9.0, 24, 9, Color("3a3f47"))
	p.rc(x, yb - 9.0, 24, 1, Color("5b636e"))
	p.rc(x + 2.0, yb - 20.0, 14, 10, Color("23262e"))
	p.rc(x + 3.0, yb - 19.0, 12, 8, Color("1f6b3a"))
	p.rc(x + 5.0, yb - 17.0, 8, 1, Color("9fe3a8"))
	p.rc(x + 5.0, yb - 14.0, 5, 1, Color("9fe3a8"))
	p.rc(x + 8.0, yb - 11.0, 2, 2, Color("23262e"))
	p.rc(x + 17.0, yb - 15.0, 6, 6, Color("f4f4f0"))     # giấy hóa đơn
	p.rc(x + 18.0, yb - 13.0, 4, 1, Color("c3c8ce"))
	p.rc(x + 18.0, yb - 11.0, 3, 1, Color("c3c8ce"))
	for i in 4:
		p.rc(x + 2.0 + i * 4.0, yb - 8.0, 3, 2, Color("8a909a"))   # bàn phím

# ---------- cầu thang đen có tay vịn ----------
# Bậc đi lên phía sau: mỗi bậc cao 5px trên màn hình (mặt bậc 3px + cổ bậc 2px), hẹp dần lên trên để có phối cảnh.
func _paint_stairs(p: Node2D) -> void:
	var s := STAIR
	# hốc cầu thang: nền tối, bóng đổ
	p.rc(s.position.x, s.position.y - 2.0, s.size.x, s.size.y + 2.0, Color("15161a"))
	p.rc(s.position.x + 6.0, s.position.y - 2.0, s.size.x - 12.0, 8, Color("0b0b0e"))
	# biển "TẦNG 2"
	p.rc(366, 15, 24, 8, Color("1f6b3a"))
	p.rc(367, 16, 22, 6, Color("2f8f4a"))
	p.ctext("TẦNG 2", 366, 22, 24, 6, Color("f6f2e6"))
	var steps := 8
	for k in range(steps - 1, -1, -1):
		var inset := k * 0.7
		var x := s.position.x + 5.0 + inset
		var w := s.size.x - 10.0 - inset * 2.0
		var ty := 64.0 - 5.0 * (k + 1)
		# cổ bậc (mặt đứng, đen)
		p.rc(x, ty + 3.0, w, 2, Color("101114"))
		# mặt bậc (xám đậm), mép bậc sáng
		p.rc(x, ty, w, 3, Color("3a3d45"))
		p.rc(x, ty, w, 1, Color("2c2e35"))
		p.rc(x + 1.0, ty + 2.0, w - 2.0, 1, Color("6e737d"))
		# dải chống trượt vàng ở mép bậc
		p.rc(x + 3.0, ty + 2.0, w - 6.0, 1, Color("c9a63c") if k % 2 == 0 else Color("6e737d"))
	# thành bậc hai bên (đen) và tay vịn kim loại nghiêng theo phối cảnh
	for side in [0, 1]:
		var xb := s.position.x + 3.0 if side == 0 else s.end.x - 5.0
		var xt := xb + (3.5 if side == 0 else -3.5)
		p.draw_line(Vector2(xb + 1.0, 62.0), Vector2(xt + 1.0, 26.0), Color("101114"), 4.0)
		# thanh đứng (baluster) mỗi bậc
		for k in range(steps):
			var f := float(k) / steps
			var bx := lerpf(xb, xt, f) + 1.0
			var by := 62.0 - 5.0 * k
			p.rc(bx, by - 9.0, 1, 9, Color("8a909a"))
		# tay vịn
		p.draw_line(Vector2(xb + 1.0, 52.0), Vector2(xt + 1.0, 16.0), Color("c3c8d0"), 2.0)
		p.draw_line(Vector2(xb, 52.0), Vector2(xt, 16.0), Color("f0f2f4"), 1.0)
		# trụ đầu cầu thang
		var nx := xb - 1.0
		p.rc(nx, 49.0, 5, 15, Color("23262e"))
		p.rc(nx, 49.0, 5, 2, Color("c3c8d0"))
		p.rc(nx + 1.0, 51.0, 1, 12, Color("5b636e"))
	# bóng đổ chân cầu thang xuống sàn
	p.rc(s.position.x - 2.0, 64.0, s.size.x + 4.0, 4, Color(0, 0, 0, 0.25))

# ---------- tường hai bên và tường trước có cửa kính ra vào ----------
func _paint_side_and_front(p: Node2D) -> void:
	# tường bên: dải kính đứng, khung thép
	for x in [0, 470]:
		p.rc(x, 58, 10, 200, C_WALL.darkened(0.12))
		for y in range(66, 250, 46):
			p.rc(x + 2, y, 6, 38, C_STEEL)
			p.rc(x + 3, y + 1, 4, 36, Color("9bd0ea"))
			p.rc(x + 3, y + 1, 4, 12, Color("c4e6f6"))
	p.rc(10, 58, 1, 200, Color(0, 0, 0, 0.12))
	p.rc(469, 58, 1, 200, Color(0, 0, 0, 0.12))
	# tường trước: chân tường, dải kính thấp, khung thép
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 12, Color("4a4f5a"))
	p.rc(0, FLOOR_BOTTOM, VIEW.x, 2, Color("2f343c"))
	for x in range(8, 380, 52):
		p.rc(x, FLOOR_BOTTOM + 3.0, 48, 7, C_STEEL)
		p.rc(x + 1.0, FLOOR_BOTTOM + 4.0, 46, 5, Color("9bd0ea"))
		p.rc(x + 1.0, FLOOR_BOTTOM + 4.0, 46, 2, Color("c4e6f6"))
	for x in range(448, 470, 52):
		p.rc(x, FLOOR_BOTTOM + 3.0, 20, 7, C_STEEL)
		p.rc(x + 1.0, FLOOR_BOTTOM + 4.0, 18, 5, Color("9bd0ea"))
	# cửa ra vào đôi bằng kính (x 394-430), tay nắm thép, thảm chùi chân bên trong
	p.rc(392, FLOOR_BOTTOM - 1.0, 40, 13, C_STEEL)
	p.rc(394, FLOOR_BOTTOM + 1.0, 17, 11, Color("9fd3f0"))
	p.rc(413, FLOOR_BOTTOM + 1.0, 17, 11, Color("9fd3f0"))
	p.rc(394, FLOOR_BOTTOM + 1.0, 17, 4, Color("d0eefb"))
	p.rc(413, FLOOR_BOTTOM + 1.0, 17, 4, Color("d0eefb"))
	p.rc(411, FLOOR_BOTTOM + 1.0, 2, 11, Color("1f2329"))
	p.rc(408, FLOOR_BOTTOM + 5.0, 2, 5, C_STEEL_HI)
	p.rc(414, FLOOR_BOTTOM + 5.0, 2, 5, C_STEEL_HI)
	p.rc(392, FLOOR_BOTTOM - 1.0, 40, 1, C_STEEL_HI)
	p.rc(394, 242, 36, 14, Color("2f343c"))
	p.rc(395, 243, 34, 12, Color("3d4048"))
	for i in range(397, 428, 4):
		p.rc(i, 244, 2, 10, Color("23262e"))

# ---------- vật có chiều sâu: bàn, ghế, cột, chậu cây, thùng rác, bình nước, người chơi ----------
func _paint_room_items(p: Node2D) -> void:
	var items: Array = []
	for ti in _tables.size():
		if str(_tables[ti].a) == "in":
			items.append([float(_tables[ti].c.y) + 12.0, 0, ti])
	for si in _seats.size():
		if str(_seats[si].a) == "in":
			items.append([_seat_sort_y(_seats[si]), 1, si])
	for q in IN_PILLARS:
		items.append([q.y, 2, q])
	for q in IN_PLANTS:
		items.append([q.y, 3, q])
	items.append([IN_BINS.y, 4, IN_BINS])
	items.append([IN_WATER.y, 5, IN_WATER])
	items.append([CUP_POS.y, 6, CUP_POS])
	for ni in _npcs.size():
		var vn: Dictionary = _npcs[ni]
		if str(vn.a) == "in" and not bool(vn.staff) and int(vn.seat) < 0 and str(vn.mode) == "vis":
			items.append([float(vn.pos.y), 7, ni])
	if _seated < 0:
		items.append([_pos.y, 9, null])
	var occ := _occ_map("in")
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				var t: Dictionary = _tables[int(it[2])]
				_draw_table(p, t, int(it[2]))
				_draw_table_props(p, t)
				_draw_table_items(p, t.c, int(it[2]))
				_draw_diner_food(p, int(it[2]), occ)
			1:
				_draw_seat_unit(p, int(it[2]), occ)
			2:
				_draw_pillar(p, it[2])
			3:
				_draw_in_plant(p, it[2])
			4:
				_draw_bins(p, it[2])
			5:
				_draw_water(p, it[2])
			6:
				_draw_cups(p, it[2])
			7:
				_draw_walker(p, _npcs[int(it[2])])
			9:
				p.draw_person(_pos, Color.WHITE, Color("1b1b1b"), _face, _anim, true, false, true)
				p.ctext("Bạn", _pos.x - 15.0, _pos.y - 28.0, 30, 8, Color("ffd23f"))

# đồ dùng nhỏ trên bàn ăn: hộp khăn giấy, ống đũa, chai nước chấm
func _draw_table_props(p: Node2D, t: Dictionary) -> void:
	var c: Vector2 = t.c
	p.rc(c.x - 5.0, c.y - 5.0, 8, 4, Color("f4f4f0"))
	p.rc(c.x - 5.0, c.y - 5.0, 8, 1, Color("2f8f4a"))
	p.rc(c.x + 8.0, c.y - 6.0, 3, 4, Color("e8e8e8"))
	p.rc(c.x + 8.0, c.y - 8.0, 1, 3, Color("c8742e"))
	p.rc(c.x + 10.0, c.y - 8.0, 1, 3, Color("c8742e"))
	p.rc(c.x - 13.0, c.y - 6.0, 2, 4, Color("c0392b"))
	p.rc(c.x - 10.0, c.y - 6.0, 2, 4, Color("d4a017"))

# cột vuông ốp trắng: đế tối, thân sáng/tối hai mặt, đầu cột; cao tới trần
func _draw_pillar(p: Node2D, q: Vector2) -> void:
	p.shadow(Vector2(q.x + 2.0, q.y + 1.0), 9.0)
	p.rc(q.x - 8.0, q.y - 4.0, 16, 5, Color("8a8470"))
	p.rc(q.x - 6.0, q.y - 44.0, 12, 41, Color("f4f1e6"))
	p.rc(q.x + 2.0, q.y - 44.0, 4, 41, Color("cfc9b4"))
	p.rc(q.x - 6.0, q.y - 44.0, 1, 41, Color("ffffff"))
	p.rc(q.x - 8.0, q.y - 48.0, 16, 5, Color("d8cdaf"))
	p.rc(q.x - 8.0, q.y - 48.0, 16, 1, Color("efe6cc"))

func _draw_in_plant(p: Node2D, q: Vector2) -> void:
	p.shadow(Vector2(q.x + 1.0, q.y + 1.0), 8.0)
	p.rc(q.x - 6.0, q.y - 9.0, 12, 10, Color("a8582b"))
	p.rc(q.x - 7.0, q.y - 10.0, 14, 3, Color("c8742e"))
	p.rc(q.x - 6.0, q.y - 7.0, 12, 1, Color("8a4a24"))
	p.draw_circle(Vector2(q.x, q.y - 17.0), 8.0, Color("2f7d33"))
	p.draw_circle(Vector2(q.x - 5.0, q.y - 21.0), 5.0, Color("4fb552"))
	p.draw_circle(Vector2(q.x + 5.0, q.y - 22.0), 5.0, Color("3e9a42"))
	p.draw_circle(Vector2(q.x, q.y - 26.0), 4.0, Color("6cc970"))

func _draw_bins(p: Node2D, q: Vector2) -> void:
	p.shadow(Vector2(q.x + 8.0, q.y + 1.0), 13.0)
	var cols := [Color("2f8f4a"), Color("2f6bd0"), Color("5b636e")]
	for i in 3:
		var bx := q.x - 5.0 + i * 9.0
		var c: Color = cols[i]
		var open := _bin_t > 0.0 and i == _bin_i
		p.rc(bx, q.y - 11.0, 8, 12, c)
		p.rc(bx + 1.0, q.y - 11.0, 1, 12, c.lightened(0.18))
		p.rc(bx + 7.0, q.y - 11.0, 1, 12, c.darkened(0.25))
		p.rc(bx, q.y, 8, 1, c.darkened(0.35))
		# biểu tượng ở mặt trước: i=0 lá (hữu cơ), i=1 mũi tên tái chế, i=2 thùng rác
		var w := Color("f4f4f0")
		match i:
			0:
				p.rc(bx + 3.0, q.y - 7.0, 2, 1, w)
				p.rc(bx + 2.0, q.y - 6.0, 4, 2, w)
				p.rc(bx + 3.0, q.y - 4.0, 2, 1, w)
			1:
				p.rc(bx + 2.0, q.y - 7.0, 4, 1, w)
				p.rc(bx + 2.0, q.y - 6.0, 1, 3, w)
				p.rc(bx + 5.0, q.y - 5.0, 1, 3, w)
				p.rc(bx + 2.0, q.y - 3.0, 4, 1, w)
			_:
				p.rc(bx + 2.0, q.y - 7.0, 4, 1, w)
				p.rc(bx + 3.0, q.y - 8.0, 2, 1, w)
				p.rc(bx + 2.0, q.y - 6.0, 4, 4, w)
				p.rc(bx + 3.0, q.y - 5.0, 1, 2, c)
				p.rc(bx + 5.0, q.y - 5.0, 1, 2, c)
		# nắp thùng
		if open:
			p.rc(bx + 1.0, q.y - 12.0, 6, 1, Color(0, 0, 0, 0.55))
			p.rc(bx - 1.0, q.y - 17.0, 10, 2, c.darkened(0.3))
			p.rc(bx - 1.0, q.y - 17.0, 10, 1, c.lightened(0.25))
			p.rc(bx + 8.0, q.y - 15.0, 1, 4, c.darkened(0.45))
		else:
			p.rc(bx - 1.0, q.y - 14.0, 10, 3, c.darkened(0.3))
			p.rc(bx - 1.0, q.y - 14.0, 10, 1, c.lightened(0.25))
			p.rc(bx + 3.0, q.y - 15.0, 2, 1, c.darkened(0.45))

func _draw_water(p: Node2D, q: Vector2) -> void:
	p.shadow(Vector2(q.x, q.y + 1.0), 10.0)
	var fill := _fill_t > 0.0
	# thân máy
	p.rc(q.x - 7.0, q.y - 18.0, 14, 20, Color("c9d0d8"))
	p.rc(q.x - 6.0, q.y - 18.0, 12, 19, Color("e4e8ec"))
	p.rc(q.x - 6.0, q.y - 18.0, 12, 1, Color("ffffff"))
	p.rc(q.x + 4.0, q.y - 17.0, 2, 18, Color("c3c9d1"))
	# bình nước lớn phía trên (có bọt khi đang lấy nước)
	p.rc(q.x - 5.0, q.y - 30.0, 10, 12, Color("8fcbe8"))
	p.rc(q.x - 5.0, q.y - 30.0, 10, 1, Color("c6e6f4"))
	p.rc(q.x - 4.0, q.y - 29.0, 2, 9, Color("cdeefa"))
	p.rc(q.x - 2.0, q.y - 32.0, 4, 2, Color("6aa9c8"))
	if fill:
		var by := q.y - 20.0 - float(int(_clock * 10.0) % 8)
		p.rc(q.x + 1.0, by, 1, 1, Color("ffffff"))
	# bảng nút: lạnh (xanh), nóng (đỏ), đèn báo
	p.rc(q.x - 5.0, q.y - 15.0, 10, 5, Color("5b636e"))
	p.rc(q.x - 4.0, q.y - 14.0, 3, 3, Color("2f6bd0"))
	p.rc(q.x + 1.0, q.y - 14.0, 3, 3, Color("c0392b"))
	p.rc(q.x - 1.0, q.y - 14.0, 1, 1, Color("6cf08a") if fill else Color("2f7d33"))
	# vòi nước
	p.rc(q.x - 1.0, q.y - 10.0, 3, 2, Color("3b4048"))
	p.rc(q.x, q.y - 8.0, 1, 1, Color("8fcbe8") if fill else Color("3b4048"))
	# khu vực hứng nước (hốc tối) + chỗ đặt cốc
	p.rc(q.x - 5.0, q.y - 8.0, 10, 7, Color("2b3139"))
	p.rc(q.x - 5.0, q.y - 8.0, 10, 1, Color("1b1f24"))
	p.rc(q.x - 3.0, q.y - 2.0, 6, 1, Color("3f4650"))
	# khay hứng nước nhỏ giọt (có lưới)
	p.rc(q.x - 6.0, q.y - 1.0, 12, 3, Color("7d838c"))
	p.rc(q.x - 6.0, q.y - 1.0, 12, 1, Color("aeb4bd"))
	for k in range(-5, 5, 2):
		p.rc(q.x + k, q.y, 1, 1, Color("4a5058"))
	if fill:
		# cốc/bình đặt vào chỗ hứng, dòng nước chảy từ vòi
		if _fill_kind == "binh_nuoc":
			p.rc(q.x - 2.0, q.y - 7.0, 4, 6, Color("bfe6ff"))
			p.rc(q.x - 1.0, q.y - 8.0, 2, 1, Color("2f6bd0"))
		else:
			p.rc(q.x - 2.0, q.y - 6.0, 5, 5, Color("e9f2f8"))
			p.rc(q.x - 2.0, q.y - 6.0, 5, 1, Color("ffffff"))
		var lvl := clampf(1.0 - _fill_t / FILL_TIME, 0.0, 1.0)
		p.rc(q.x - 1.0, q.y - 1.0 - 4.0 * lvl, 3, 4.0 * lvl, Color("5fb6e8"))
		for k in 3:
			var dy := float((int(_clock * 14.0) + k * 2) % 6)
			p.rc(q.x, q.y - 8.0 + dy, 1, 2, Color("8fd6ff"))
		p.rc(q.x - 1.0, q.y - 3.0, 3, 1, Color("c6ecff"))

# ---------- quạt trần đen (xoay), vẽ sau cùng vì ở trên cao ----------
func _paint_ceiling_fans(p: Node2D) -> void:
	for q in FANS:
		p.rc(q.x - 1.0, CEIL_H, 2, 3, Color("2a2a2e"))
		p.rc(q.x - 4.0, CEIL_H + 2.0, 8, 3, Color("17181b"))
		p.rc(q.x - 3.0, CEIL_H + 2.0, 6, 1, Color("3a3d45"))
		var ang: float = float(_clock) * 5.0 + float(q.x)
		for k in 4:
			var a: float = ang + float(k) * PI / 2.0
			var e := Vector2(q.x + cos(a) * 20.0, CEIL_H + 4.0 + sin(a) * 3.0)
			p.draw_line(Vector2(q.x, CEIL_H + 4.0), e, Color("17181b"), 3.0)
			p.draw_line(Vector2(q.x, CEIL_H + 3.0), Vector2(e.x, e.y - 1.0), Color(0.35, 0.37, 0.42, 0.6), 1.0)

func _paint_prompt_inside(p: Node2D) -> void:
	if _closing:
		return
	var text := _prompt_text()
	if text == "":
		return
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var cx := clampf(_pos.x, w / 2.0 + 3.0, VIEW.x - w / 2.0 - 3.0)
	var py := maxf(_pos.y - 56.0, 18.0)
	p.rc(cx - w / 2.0 - 1.0, py, w + 2.0, 14, Color("333333"))
	p.rc(cx - w / 2.0, py + 1.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	p.ctext(text, cx - w / 2.0, py + 10.0, w, 8, Color("ffd23f"))

# Vẽ lên thế giới sau cây/người của game: nền sân sỏi, thềm cửa, rồi vẽ lại vật đứng trong sân đúng thứ tự y.
func draw_front_layer() -> void:
	_draw_front_body()
	# Sân sỏi, mái kính và các vật vẽ lại ở trên che mất một phần khung "Bấm [E] để vào tòa B4.2" (tòa kề sân):
	# khung đó được vẽ lại ở đây, sau mọi thứ của căn tin
	for f in game.features:
		if f != self and f.has_method("draw_door_prompt"):
			f.prompt_deferred = true
			f.draw_door_prompt()

func _draw_front_body() -> void:
	if not game.view.intersects(YARD.merge(BUILDING).grow(60.0)):
		return
	_paint_yard_ground()
	_paint_facade()
	if STAGE >= 3:
		_paint_roof_layer()   # bóng dù, mái kính, dây cờ: vẽ TRƯỚC người nên không che nhân vật
	_repaint_yard_items()
	_paint_prompt_outdoor()

func _paint_yard_ground() -> void:
	var r := YARD.intersection(game.view)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	game.rc(r.position.x, r.position.y, r.size.x, r.size.y, C_GRAVEL)
	var x0 := int(r.position.x) - int(r.position.x) % 3
	var y0 := int(r.position.y) - int(r.position.y) % 3
	for gy in range(y0, int(r.end.y), 3):
		for gx in range(x0, int(r.end.x), 3):
			var h: int = game.hs(gx, gy)
			if h < 22:
				game.rc(gx, gy, 2, 1, Color("e6e7e9"))
			elif h < 44:
				game.rc(gx, gy + 1, 1, 2, Color("9fa2a7"))
			elif h < 52:
				game.rc(gx, gy, 2, 2, Color("b3b5ba"))
	# viền đá: mép trái, mép dưới, mép phải của sân
	var curb := Color("d9d5c9")
	var curb_dk := Color("8d8a80")
	game.rc(YARD.position.x, YARD.position.y, 2, YARD.size.y, curb)
	game.rc(YARD.position.x + 2.0, YARD.position.y, 1, YARD.size.y, curb_dk)
	game.rc(YARD.position.x, YARD.end.y - 3.0, YARD.size.x, 3, curb)
	game.rc(YARD.position.x, YARD.end.y - 1.0, YARD.size.x, 1, curb_dk)
	game.rc(YARD.end.x - 2.0, YARD.position.y, 2, YARD.size.y, curb)
	# thềm lát gạch trước cửa chính
	var ax := DOOR_OUT.x - 22.0
	game.rc(ax, YARD.position.y, 44, 28, Color("d9d0b8"))
	for i in range(0, 44, 11):
		game.rc(ax + i, YARD.position.y, 1, 28, Color("b9b09a"))
	for j in range(0, 28, 9):
		game.rc(ax, YARD.position.y + j, 44, 1, Color("b9b09a"))
	game.rc(ax, YARD.position.y + 28.0, 44, 2, Color(0, 0, 0, 0.18))
	game.rc(ax - 1.0, YARD.position.y, 1, 29, curb_dk)
	game.rc(ax + 44.0, YARD.position.y, 1, 29, curb_dk)

# Sân sỏi đã đè lên mọi thứ game vẽ trước đó trong vùng này -> vẽ lại (cùng hàm vẽ của game) theo thứ tự y.
func _repaint_yard_items() -> void:
	var area := YARD.grow(36.0)
	var items: Array = []
	for t in game.trees:
		if area.has_point(Vector2(t[0], t[1])):
			items.append([float(t[1]), 0, t])
	for l in game.lamps:
		if l is Vector2 and area.has_point(l):
			items.append([l.y, 1, l])
	for b in game.benches:
		var bench_pos: Vector2
		if b is Vector2:
			bench_pos = b
		elif b is Dictionary:
			var bench_value: Variant = b.get("pos")
			if bench_value is Vector2:
				bench_pos = bench_value
			elif bench_value is Dictionary:
				bench_pos = Vector2(float(bench_value.get("x", 0.0)), float(bench_value.get("y", 0.0)))
			else:
				continue
		else:
			continue
		if area.has_point(bench_pos):
			items.append([bench_pos.y, 2, bench_pos if b is Dictionary else b])
	for o in game.npcs:
		if not o.has("role"):
			var npc_pos: Variant = o.get("pos")
			var pos: Vector2
			if npc_pos is Vector2:
				pos = npc_pos
			elif npc_pos is Dictionary:
				pos = Vector2(float(npc_pos.get("x", 0.0)), float(npc_pos.get("y", 0.0)))
			else:
				continue
			if area.has_point(pos):
				items.append([pos.y, 3, o])
	var multiplayer_manager: Variant = game.get("multiplayer_manager")
	if multiplayer_manager != null and multiplayer_manager.has_method("get_other_players"):
		var remote_players: Dictionary = multiplayer_manager.get_other_players()
		for remote in remote_players.values():
			if remote is Dictionary and remote.has("pos"):
				var remote_pos: Variant = remote["pos"]
				var pos: Vector2
				if remote_pos is Vector2:
					pos = remote_pos
				elif remote_pos is Dictionary:
					pos = Vector2(float(remote_pos.get("x", 0.0)), float(remote_pos.get("y", 0.0)))
				else:
					continue
				if area.has_point(pos):
					remote["pos"] = pos
					items.append([pos.y, 5, remote])
	var player_pos: Variant = game.get("player")
	if player_pos is Vector2 and area.has_point(player_pos) and _seated < 0:
		items.append([player_pos.y, 4, null])
	elif player_pos is Dictionary:
		var px: Vector2 = Vector2(float(player_pos.get("x", 0.0)), float(player_pos.get("y", 0.0)))
		if area.has_point(px) and _seated < 0:
			items.append([px.y, 4, null])
	if STAGE >= 3:
		for ti in _tables.size():
			if str(_tables[ti].a) == "out":
				items.append([float(_tables[ti].c.y) + 12.0, 6, ti])
		for si in _seats.size():
			if str(_seats[si].a) == "out":
				items.append([_seat_sort_y(_seats[si]), 7, si])
		for q in POSTS:
			items.append([q.y, 8, q])
		for q in PARASOLS:
			items.append([q.y, 9, q])
			items.append([q.y + 0.5, 12, q])   # tán dù: vẽ sau cột, che người đứng phía sau nó
		for q in POTS:
			items.append([q.y, 10, q])
		items.append([BIG_TREE.y, 13, BIG_TREE])
		# Dây cờ nằm trên cao (CANOPY_H) nên nhìn trên màn hình nó ở y = y đất - CANOPY_H. Người có CHÂN thấp hơn dây (y chân lớn hơn)
		# đứng trước dây, người có chân cao hơn dây đứng sau dây (dây che đầu/thân). Vì vậy khóa sắp xếp là y màn hình của dây.
		items.append([CANOPY.position.y - CANOPY_H + 2.5, 14, 0])   # cạnh sau mái kính + dây cờ
		items.append([CANOPY.end.y - CANOPY_H + 2.5, 14, 1])        # cạnh trước mái kính + dây cờ
		var sn := _side_bunting_n()
		var s_top := CANOPY.position.y - CANOPY_H + 4.0
		var s_bot := CANOPY.end.y - CANOPY_H
		for j in range(sn):
			items.append([s_top + (float(j) + 0.5) / sn * (s_bot - s_top), 15, j])   # dây dọc: từng đoạn theo y màn hình của đoạn
	for n in _npcs:
		if str(n.a) == "out" and int(n.seat) < 0:
			var npc_pos: Variant = n.get("pos")
			var pos: Vector2
			if npc_pos is Vector2:
				pos = npc_pos
			elif npc_pos is Dictionary:
				pos = Vector2(float(npc_pos.get("x", 0.0)), float(npc_pos.get("y", 0.0)))
			else:
				continue
			if area.has_point(pos):
				items.append([pos.y, 11, n])
	var occ := _occ_map("out")
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				game.draw_tree(it[2])
			1:
				game.draw_lamp(it[2])
			2:
				game.draw_bench(it[2])
			3:
				var o: Dictionary = it[2]
				game.draw_person(o.pos, o.shirt, o.hair, o.face, o.anim, o.uni, o.long, o.pack)
				if o.get("quiz", false):
					game.draw_quiz_marker(o)
				if o.say_t > 0.0:
					game.draw_speech(o)
			4:
				var draw_player_pos: Variant = game.get("player")
				var px: Vector2
				if draw_player_pos is Vector2:
					px = draw_player_pos
				elif draw_player_pos is Dictionary:
					px = Vector2(float(draw_player_pos.get("x", 0.0)), float(draw_player_pos.get("y", 0.0)))
				else:
					continue
				game.draw_person(px, Color.WHITE, Color("1b1b1b"), game.facing, game.anim, true, false, true)
				game.ctext("Bạn", px.x - 15.0, px.y - 28.0, 30, 8, Color("ffd23f"))
			6:
				_draw_table(game, _tables[int(it[2])], int(it[2]))
			7:
				_draw_seat_unit(game, int(it[2]), occ)
			8:
				_draw_post(it[2])
			9:
				_draw_parasol_pole(it[2])
			10:
				_draw_pot(it[2])
			11:
				_draw_walker(game, it[2])
			12:
				_paint_parasol(it[2])
			13:
				_draw_big_tree(it[2])
			14:
				_paint_canopy_edge(int(it[2]) == 1)
			15:
				_paint_side_bunting(int(it[2]))
			5:
				var remote: Dictionary = it[2]
				var remote_pos: Variant = remote.get("pos")
				var pos: Vector2
				if remote_pos is Vector2:
					pos = remote_pos
				elif remote_pos is Dictionary:
					pos = Vector2(float(remote_pos.get("x", 0.0)), float(remote_pos.get("y", 0.0)))
				else:
					continue
				game.draw_person(pos, Color("7dc8ff"), Color("3b2a1a"), remote.facing, remote.anim, true, false, false)
				var peer_id: int = remote.get("id", 0)
				game.ctext("Chủ phòng" if peer_id == 1 else "Người chơi %d" % peer_id, pos.x - 36.0, pos.y - 28.0, 72, 8, Color("9fe3ff"))

# Khung chỉ dẫn phím E phía trên đầu người chơi (ngoài trời): "E: Vào căn tin", sau này cả "E: Ngồi" / "E: Trò chuyện"...
func _paint_prompt_outdoor() -> void:
	if inside or _closing:
		return
	if game.is_busy() and not active:
		return
	var text := _prompt_text()
	if text == "":
		return
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
	var px: float = game.player.x
	var py: float = game.player.y - 46.0
	game.rc(px - w / 2.0 - 1.0, py - 10.0, w + 2.0, 14, Color("333333"))
	game.rc(px - w / 2.0, py - 9.0, w, 12, Color(0.08, 0.1, 0.18, 0.92))
	game.ctext(text, px - w / 2.0, py, w, 8, Color("ffd23f"))

# ======================= GIAI ĐOẠN 3: MẶT TIỀN, MÁI CHE, CÂY CẢNH =======================

# Khung kính: viền thép, kính xanh nhạt có vệt phản chiếu.
func _glass(x: float, y: float, w: float, h: float) -> void:
	game.rc(x - 1.0, y - 1.0, w + 2.0, h + 2.0, C_STEEL)
	game.rc(x, y, w, h, Color("9bd0ea"))
	game.rc(x, y, w, h * 0.45, Color("c4e6f6"))
	game.rc(x, y + h - 2.0, w, 2, Color("6fa6c6"))
	for i in range(0, int(w) - 6, 12):
		game.rc(x + 4.0 + i, y + 2.0, 2, maxf(h - 6.0, 1.0), Color(1, 1, 1, 0.22))
		game.rc(x + 7.0 + i, y + 2.0, 1, maxf(h - 6.0, 1.0), Color(1, 1, 1, 0.12))

# Cảnh nhìn xuyên cửa kính tầng trệt: bên trái là quầy bán hàng (bảng menu đỏ, tủ kính, nhân viên), bên phải là khu bàn ăn.
func _window_interior(x: float, y: float, w: float, h: float, counter: bool) -> void:
	game.rc(x, y, w, h, Color("e4d9bb"))
	game.rc(x, y, w, 3, Color("bfb592"))
	for i in range(0, int(w) - 8, 14):
		game.rc(x + 5.0 + i, y + 3.0, 4, 1, Color.WHITE)
	if counter:
		game.rc(x + 2.0, y + 4.0, w - 4.0, 7, Color("b8332a"))
		for i in range(0, int(w) - 8, 9):
			game.rc(x + 4.0 + i, y + 5.0, 6, 4, Color("f2c14e"))
			game.rc(x + 5.0 + i, y + 6.0, 4, 2, Color("fbf3d0"))
		game.rc(x + 11.0, y + 13.0, 7, 7, C_STAFF)
		game.rc(x + 12.0, y + 10.0, 5, 3, Color("f1c27d"))
		game.rc(x + 12.0, y + 9.0, 5, 2, Color("e6c229"))
		game.rc(x, y + h - 9.0, w, 9, Color("b77b45"))
		game.rc(x, y + h - 9.0, w, 2, Color("e3b27a"))
		game.rc(x + w - 16.0, y + h - 15.0, 14, 6, Color("bfe6ff"))
		game.rc(x + w - 16.0, y + h - 15.0, 14, 1, Color.WHITE)
		game.rc(x + 22.0, y + h - 13.0, 6, 4, Color("e8e8e8"))
	else:
		game.rc(x, y + h - 4.0, w, 4, Color("c7c0aa"))
		for k in 2:
			var tx := x + 6.0 + k * 17.0
			game.rc(tx, y + h - 13.0, 14, 3, Color("c98a4b"))
			game.rc(tx + 1.0, y + h - 10.0, 2, 6, C_IRON)
			game.rc(tx + 11.0, y + h - 10.0, 2, 6, C_IRON)
			game.rc(tx + 2.0, y + h - 19.0, 4, 3, Color("f1c27d"))
			game.rc(tx + 1.0, y + h - 16.0, 6, 4, SHIRTS[(k * 3 + 1) % SHIRTS.size()])
			game.rc(tx + 8.0, y + h - 18.0, 4, 3, Color("f1c27d"))
			game.rc(tx + 8.0, y + h - 15.0, 6, 4, SHIRTS[(k * 3 + 4) % SHIRTS.size()])
			game.rc(tx - 2.0, y + h - 14.0, 2, 8, Color("7d828b"))

func _planter(x: float, y: float, w: float) -> void:
	game.rc(x, y, w, 8, Color("5a3a22"))
	game.rc(x, y, w, 2, Color("8a5a2c"))
	game.rc(x + 1.0, y + 2.0, w - 2.0, 5, Color("6f4a2a"))
	for i in range(3, int(w) - 2, 6):
		game.draw_circle(Vector2(x + i, y - 2.0), 4.0, Color("2f7d33"))
		game.draw_circle(Vector2(x + i - 1.0, y - 4.0), 3.0, Color("4fb552"))
		game.rc(x + i + 1.0, y - 5.0, 1, 1, Color("ffd23f") if i % 4 == 0 else Color("ff7a8a"))

# Mặt tiền: tường trắng kem, ban công lan can sắt, bảng hiệu, mái hiên xanh, cửa kính lớn, cột, chậu cây.
# Hình dáng theo ảnh thật: khối hai tầng, tầng trên có cửa kính phản chiếu và ban công, tầng trệt kính lớn.
func _paint_facade() -> void:
	var r := BUILDING
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var b := r.end.y
	var cream_hi := Color("faf5e3")
	var cream_dk := Color("d6cba8")
	game.rc(x - 2.0, b, w + 4.0, 5, Color(0, 0, 0, 0.16))
	game.rc(x, y, w, r.size.y, C_WALL)
	game.rc(x, y, 3, r.size.y, cream_hi)
	game.rc(x + w - 5.0, y, 5, r.size.y, C_WALL.darkened(0.1))
	# mái đua
	game.rc(x - 2.0, y - 1.0, w + 4.0, 6, cream_hi)
	game.rc(x - 2.0, y + 5.0, w + 4.0, 2, cream_dk)
	game.rc(x, y + 7.0, w, 3, Color(0, 0, 0, 0.12))
	# ban công trái: mái hiên xanh nhỏ, cây, lan can sắt
	game.rc(x + 4.0, y + 16.0, 22, 30, cream_dk)
	game.rc(x + 7.0, y + 20.0, 8, 12, C_STEEL)
	game.rc(x + 8.0, y + 21.0, 6, 10, Color("7fb0cf"))
	for i in range(0, 26, 7):
		var ac := C_AWN_DK if int(i / 7.0) % 2 == 0 else C_AWN_LT
		game.rc(x + 2.0 + i, y + 11.0, 7, 6, ac)
		game.rc(x + 2.0 + i, y + 16.0, 7, 2, ac.darkened(0.25))
	game.draw_circle(Vector2(x + 9.0, y + 34.0), 4.0, Color("2f7d33"))
	game.draw_circle(Vector2(x + 17.0, y + 33.0), 5.0, Color("3f9a42"))
	game.draw_circle(Vector2(x + 22.0, y + 35.0), 3.0, Color("2f7d33"))
	game.rc(x + 3.0, y + 34.0, 24, 2, C_STEEL)
	for i in range(0, 22, 3):
		game.rc(x + 4.0 + i, y + 36.0, 1, 10, C_STEEL)
	game.rc(x + 3.0, y + 44.0, 24, 2, C_STEEL)
	# bảng hiệu CĂN TIN US (nền xanh lá, chữ kem, logo trường giữ nguyên bên trái; chữ căn giữa bảng, không đè logo)
	game.rc(x + 29.0, y + 11.0, 82, 16, Color("12331c"))
	game.rc(x + 30.0, y + 12.0, 80, 14, Color("1f6b3a"))
	game.rc(x + 30.0, y + 12.0, 80, 1, Color("3f9a5a"))
	var sign_text := "CĂN TIN US"
	var sign_w: float = game.font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var sign_left := x + 30.0
	if game.logo != null:
		game.draw_texture_rect(game.logo, Rect2(x + 33.0, y + 14.0, 10, 10), false)
		sign_left = x + 46.0   # chữ không được bắt đầu trước mép phải của logo
	var sign_x := maxf(x + 70.0 - sign_w / 2.0, sign_left)
	game.ctext(sign_text, sign_x - 1.0, y + 23.0, sign_w + 2.0, 8, Color("fbf3d0"))
	# cửa sổ dải dài dưới bảng hiệu và cửa sổ lớn bên phải (kính phản chiếu như ảnh)
	_glass(x + 30.0, y + 30.0, 80, 14)
	for k in range(1, 4):
		game.rc(x + 30.0 + k * 20.0, y + 30.0, 1, 14, C_STEEL)
	_glass(x + 116.0, y + 14.0, 16, 30)
	game.rc(x + 116.0, y + 28.0, 16, 1, C_STEEL)
	# sàn tầng và mái hiên xanh sọc
	game.rc(x, y + 46.0, w, 2, cream_dk)
	game.rc(x - 2.0, y + 48.0, w + 4.0, 2, Color(1, 1, 1, 0.3))
	# tầng trệt: cột nhà, cửa kính lớn có cảnh quầy / khu bàn ăn phía trong
	game.rc(x + 44.0, y + 62.0, 14, 34, C_WALL)
	game.rc(x + 82.0, y + 62.0, 14, 34, C_WALL)
	game.rc(x + 44.0, y + 62.0, 2, 34, cream_hi)
	game.rc(x + 82.0, y + 62.0, 2, 34, cream_hi)
	game.rc(x + 56.0, y + 62.0, 2, 34, cream_dk)
	game.rc(x + 94.0, y + 62.0, 2, 34, cream_dk)
	_window_interior(x + 6.0, y + 64.0, 38, 28, true)
	_window_interior(x + 96.0, y + 64.0, 38, 28, false)
	for wx in [x + 6.0, x + 96.0]:
		game.rc(wx, y + 64.0, 38, 28, Color(0.62, 0.82, 0.95, 0.20))
		for i in range(0, 34, 12):
			game.rc(wx + 5.0 + i, y + 66.0, 2, 22, Color(1, 1, 1, 0.20))
			game.rc(wx + 8.0 + i, y + 66.0, 1, 22, Color(1, 1, 1, 0.10))
		game.draw_rect(Rect2(wx - 1.0, y + 63.0, 40, 30), C_STEEL, false, 1.0)
		game.rc(wx + 18.0, y + 64.0, 1, 28, C_STEEL)
	# cửa chính hai cánh kính, tay nắm thép, đèn tường hai bên
	var dx := x + 58.0
	game.rc(dx - 1.0, y + 61.0, 26, 36, C_STEEL)
	game.rc(dx + 1.0, y + 64.0, 10, 32, Color("9bd0ea"))
	game.rc(dx + 13.0, y + 64.0, 10, 32, Color("9bd0ea"))
	game.rc(dx + 1.0, y + 64.0, 10, 12, Color("c4e6f6"))
	game.rc(dx + 13.0, y + 64.0, 10, 12, Color("c4e6f6"))
	game.rc(dx + 11.0, y + 64.0, 2, 32, C_STEEL)
	game.rc(dx + 1.0, y + 69.0, 22, 1, C_STEEL)
	game.rc(dx + 8.0, y + 78.0, 1, 9, Color("d8d8d8"))
	game.rc(dx + 15.0, y + 78.0, 1, 9, Color("d8d8d8"))
	game.rc(dx + 3.0, y + 66.0, 2, 26, Color(1, 1, 1, 0.22))
	game.rc(dx + 16.0, y + 66.0, 2, 26, Color(1, 1, 1, 0.22))
	for lx in [x + 50.0, x + 88.0]:
		game.rc(lx, y + 68.0, 4, 6, C_STEEL)
		game.rc(lx + 1.0, y + 69.0, 2, 4, Color("ffe28a"))
	# chân tường và chậu cây hai bên cửa
	game.rc(x, b - 5.0, w, 5, Color("8f8f88"))
	game.rc(x, b - 5.0, w, 1, Color("b5b5ad"))
	_planter(x + 8.0, y + 87.0, 24)
	_planter(x + 108.0, y + 87.0, 24)
	# mái hiên xanh sọc nhô ra phía trước (vẽ sau cùng để đè lên cột và kính)
	for i in range(0, int(w) + 4, 7):
		var col := C_AWN_DK if int(i / 7.0) % 2 == 0 else C_AWN_LT
		game.rc(x - 2.0 + i, y + 50.0, 7, 9, col)
		game.rc(x - 2.0 + i, y + 59.0, 7, 3, col.darkened(0.25))
		game.rc(x - 1.0 + i, y + 62.0, 5, 1, col.darkened(0.45))
	game.rc(x - 2.0, y + 50.0, w + 4.0, 1, Color(1, 1, 1, 0.3))
	game.rc(x, y + 63.0, w, 4, Color(0, 0, 0, 0.20))
	# thềm cửa: bậc đá và thảm chùi chân
	game.rc(dx - 4.0, b, 32, 2, Color("c9c2ae"))
	game.rc(dx - 2.0, b + 2.0, 28, 2, Color("b5ae9a"))
	game.rc(dx + 1.0, b + 5.0, 22, 3, Color("6b4a2e"))
	game.draw_rect(r, Color("2b2b2b"), false, 1.0)

# Vẽ TRƯỚC người/bàn ghế: bóng dù và mái kính phía đông (trong suốt) cùng dây cờ, nên không che ai.
# Tán dù là vật có chiều sâu: vẽ trong _repaint_yard_items (kiểu 12) để che người đi phía sau và không che người đứng phía trước.
func _paint_roof_layer() -> void:
	for pp in PARASOLS:
		_paint_parasol_shadow(pp)
	_paint_glass_canopy()

func _paint_parasol_shadow(base: Vector2) -> void:
	game.draw_colored_polygon(game.lake_poly(base + Vector2(8.0, 4.0), 34.0, 10.0, 20), Color(0, 0, 0, 0.14))

func _paint_parasol(base: Vector2) -> void:
	var c := base + Vector2(0.0, -40.0)
	var peak := c + Vector2(0.0, -6.0)
	var n := 10
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var tri := PackedVector2Array([peak, c + Vector2(cos(a0) * 34.0, sin(a0) * 11.0), c + Vector2(cos(a1) * 34.0, sin(a1) * 11.0)])
		game.draw_colored_polygon(tri, C_AWN_DK if k % 2 == 0 else C_AWN_LT)
	# mép dù rủ xuống ở nửa phía trước
	for k in range(0, 5):
		var b0 := PI * k / 5.0
		var b1 := PI * (k + 1) / 5.0
		var p0 := c + Vector2(cos(b0) * 34.0, sin(b0) * 11.0)
		var p1 := c + Vector2(cos(b1) * 34.0, sin(b1) * 11.0)
		var quad := PackedVector2Array([p0, p1, p1 + Vector2(0.0, 3.0), p0 + Vector2(0.0, 3.0)])
		game.draw_colored_polygon(quad, C_AWN_DK.darkened(0.2) if k % 2 == 0 else C_AWN_LT.darkened(0.2))
	var rim: PackedVector2Array = game.lake_poly(c, 34.0, 11.0, 28)
	rim.append(rim[0])
	game.draw_polyline(rim, Color("1b4a22"), 1.0)
	game.rc(peak.x - 1.0, peak.y - 3.0, 3, 3, Color("c8c8c8"))
	game.rc(peak.x, peak.y - 5.0, 1, 2, Color("8d949c"))

# Mái che kính khung thép: kính xanh nhạt trong suốt, rui, dây cờ đuôi nheo đỏ sao vàng.
# Phần kính và hai cạnh bên vẽ ở lớp nền (trong suốt). Cạnh sau và cạnh trước (xà thép + dây cờ) là vật có chiều sâu:
# vẽ trong _repaint_yard_items (kiểu 14), nên dây cờ phía trước che người đứng sau nó và không che người đứng trước nó.
func _paint_glass_canopy() -> void:
	var x := CANOPY.position.x
	var top := CANOPY.position.y - CANOPY_H
	var bottom := CANOPY.end.y - CANOPY_H
	var w := CANOPY.size.x
	var h := bottom - top
	game.rc(x, top, w, h, Color(0.62, 0.82, 0.95, 0.13))
	for i in range(0, int(w), 14):
		game.rc(x + i, top, 1, h, Color(0.16, 0.19, 0.22, 0.55))
	for j in range(0, int(h), 21):
		game.rc(x, top + j, w, 1, Color(0.16, 0.19, 0.22, 0.45))
	for i in 3:
		game.draw_line(Vector2(x + 8.0 + i * 20.0, top + 4.0), Vector2(x + 2.0 + i * 20.0, top + 30.0), Color(1, 1, 1, 0.18), 2.0)
	game.rc(x, top, 2, h, C_STEEL)
	game.rc(x + w - 2.0, top, 2, h, C_STEEL)

# Dây cờ cạnh trái (dọc): chia thành từng đoạn, mỗi đoạn là một vật có chiều sâu riêng (kiểu 15)
func _side_bunting_n() -> int:
	var top := CANOPY.position.y - CANOPY_H + 4.0
	var bottom := CANOPY.end.y - CANOPY_H
	return maxi(int(Vector2(0.0, top).distance_to(Vector2(0.0, bottom)) / 7.0), 2)

func _paint_side_bunting(j: int) -> void:
	var top := CANOPY.position.y - CANOPY_H + 4.0
	var bottom := CANOPY.end.y - CANOPY_H
	var x := CANOPY.position.x + 1.0
	_bunting_part(Vector2(x, top), Vector2(x, bottom), 0.0, j, _side_bunting_n())

# front = false: cạnh sau (y đất 152); front = true: cạnh trước (y đất 236)
func _paint_canopy_edge(front: bool) -> void:
	var x := CANOPY.position.x
	var w := CANOPY.size.x
	if front:
		var bottom := CANOPY.end.y - CANOPY_H
		game.rc(x, bottom - 1.0, w, 2, C_STEEL)
		game.rc(x, bottom + 1.0, w, 2, Color(0, 0, 0, 0.18))
		_paint_bunting(Vector2(x, bottom + 2.0), Vector2(x + w, bottom + 2.0), 4.0)
	else:
		var top := CANOPY.position.y - CANOPY_H
		game.rc(x, top, w, 2, C_STEEL)
		_paint_bunting(Vector2(x, top + 2.0), Vector2(x + w, top + 2.0), 3.0)

# Dây cờ đuôi nheo: từng lá cờ đỏ có sao vàng, võng nhẹ giữa hai điểm treo.
func _paint_bunting(a: Vector2, b: Vector2, sag: float) -> void:
	var n := maxi(int(a.distance_to(b) / 7.0), 2)
	for j in range(n):
		_bunting_part(a, b, sag, j, n)

# Đoạn thứ j (0..n-1) của dây: một đoạn dây + một lá cờ (hình dạng và màu y như trước)
func _bunting_part(a: Vector2, b: Vector2, sag: float, j: int, n: int) -> void:
	var t0 := float(j) / n
	var t1 := float(j + 1) / n
	var p0 := a.lerp(b, t0) + Vector2(0.0, sag * 4.0 * t0 * (1.0 - t0))
	var p1 := a.lerp(b, t1) + Vector2(0.0, sag * 4.0 * t1 * (1.0 - t1))
	game.draw_line(p0, p1, Color("3a2a1a"), 1.0)
	var t2 := (j + 0.5) / n
	var q := a.lerp(b, t2) + Vector2(0.0, sag * 4.0 * t2 * (1.0 - t2))
	game.rc(q.x - 2.0, q.y + 1.0, 5, 2, Color("d4221e"))
	game.rc(q.x - 1.0, q.y + 3.0, 3, 2, Color("d4221e"))
	game.rc(q.x, q.y + 5.0, 1, 1, Color("d4221e"))
	game.rc(q.x, q.y + 2.0, 1, 1, Color("ffde3a"))

# Cây lớn: gốc bè, thân to sần, hai cành chẻ đỡ tán nhiều tầng (3 cụm dưới, 1 tầng giữa, 1 chỏm), 4 sắc xanh + lá lẻ.
# q = điểm chân (giữa gốc). Thứ tự vẽ từ sau ra trước nên tán dưới và thân luôn nằm trước tán trên.
func _draw_big_tree(q: Vector2) -> void:
	if not game.view.grow(90.0).has_point(q):
		return
	var bark_dk := Color("3b2716")
	var bark := Color("5e4129")
	var bark_lt := Color("86603a")
	game.shadow(q + Vector2(7.0, 1.0), 26.0)
	_leaf_blob(q.x + 2.0, q.y - 66.0, 17.0, 9.0, 3)
	_leaf_blob(q.x - 1.0, q.y - 54.0, 26.0, 11.0, 5)
	# cành chẻ từ ngọn thân ra hai bên
	for sd in [-1.0, 1.0]:
		for k in range(0, 13):
			var bx: float = q.x + sd * (3.0 + k)
			var by: float = q.y - 38.0 - floorf(k * 0.9)
			var th := 2 if k < 8 else 1
			game.rc(bx - (1.0 if sd < 0.0 else 0.0), by, 2, th + 1, bark if sd < 0.0 else bark_dk)
	# thân cây (từ gốc bè lên ngọn)
	for j in range(0, 44):
		var hw := 4
		if j < 7:
			hw = 4 + int((7 - j) / 2.0)
		elif j > 34:
			hw = 4 - int((j - 34) / 5.0)
		var ry: float = q.y - j - 1.0
		var lx: float = q.x - hw
		game.rc(lx, ry, hw * 2, 1, bark)
		game.rc(lx, ry, 2, 1, bark_lt)
		game.rc(q.x + hw - 2.0, ry, 2, 1, bark_dk)
		var h: int = game.hs(j, 17)
		if h < 26:
			game.rc(lx + 2.0 + (h % maxi(hw * 2 - 5, 1)), ry, 1, 2, bark_dk)
	game.rc(q.x - 9.0, q.y - 2.0, 5, 2, bark)
	game.rc(q.x + 5.0, q.y - 2.0, 5, 2, bark_dk)
	game.rc(q.x - 7.0, q.y - 4.0, 3, 2, bark_lt)
	game.rc(q.x + 5.0, q.y - 4.0, 3, 2, bark)
	# ba cụm tán tầng dưới: hai bên chừa khe cho thân đi lên
	_leaf_blob(q.x - 19.0, q.y - 37.0, 16.0, 10.0, 7)
	_leaf_blob(q.x + 19.0, q.y - 38.0, 16.0, 10.0, 9)
	_leaf_blob(q.x + 1.0, q.y - 46.0, 13.0, 7.0, 11)

# Một cụm lá: elip nhiều lớp xanh (tối ở đáy, sáng ở nửa trên bên trái), mép lởm chởm, lá lẻ theo hash nên đứng yên khi di chuyển.
func _leaf_blob(cx: float, cy: float, rx: float, ry: float, sv: int) -> void:
	var dk := Color("1d5526")
	var md := Color("2f7d33")
	var lt := Color("4fb552")
	var hi := Color("86d96b")
	for yy in range(int(cy - ry), int(cy + ry) + 1):
		var t: float = (float(yy) - cy) / ry
		var half: float = rx * sqrt(maxf(1.0 - t * t, 0.0)) + float(game.hs(yy, sv) % 3) - 1.0
		if half < 2.0:
			continue
		var x0 := int(round(cx - half))
		var wd := int(round(half * 2.0))
		game.rc(x0, yy, wd, 1, dk)
		if t < 0.6:
			game.rc(x0 + 1, yy, maxi(wd - 3, 1), 1, md)
		if t < 0.2:
			game.rc(x0 + 3, yy, maxi(int(wd * 0.6), 1), 1, lt)
		if t < -0.35:
			game.rc(x0 + 4, yy, maxi(int(wd * 0.3), 1), 1, hi)
		for i in range(0, wd, 3):
			var hv: int = game.hs(i + yy * 7, sv)
			if hv < 16 and t < 0.5:
				game.rc(x0 + i, yy, 2, 1, lt)
			elif hv > 90 and t < 0.3:
				game.rc(x0 + i, yy, 1, 1, hi)
			elif hv >= 44 and hv < 50 and t > 0.1:
				game.rc(x0 + i, yy, 2, 1, dk)

func _draw_post(q: Vector2) -> void:
	game.shadow(q + Vector2(3.0, 1.0), 5.0)
	game.rc(q.x - 2.0, q.y - 2.0, 4, 3, C_STEEL)
	game.rc(q.x - 1.0, q.y - CANOPY_H, 2, CANOPY_H - 1.0, C_STEEL)
	game.rc(q.x - 1.0, q.y - CANOPY_H, 1, CANOPY_H - 1.0, C_STEEL_HI)
	game.rc(q.x - 2.0, q.y - CANOPY_H - 1.0, 4, 2, C_STEEL)

func _draw_parasol_pole(q: Vector2) -> void:
	game.shadow(q + Vector2(2.0, 1.0), 5.0)
	game.rc(q.x - 3.0, q.y - 2.0, 7, 3, C_STEEL)
	game.rc(q.x - 1.0, q.y - 40.0, 2, 39, Color("3a3f4a"))
	game.rc(q.x - 1.0, q.y - 40.0, 1, 39, C_STEEL_HI)

func _draw_pot(q: Vector2) -> void:
	game.shadow(q + Vector2(1.0, 1.0), 7.0)
	game.rc(q.x - 4.0, q.y - 6.0, 8, 7, Color("5a3a22"))
	game.rc(q.x - 5.0, q.y - 7.0, 10, 2, Color("b5651d"))
	game.rc(q.x - 4.0, q.y - 5.0, 8, 5, Color("c9772b"))
	game.rc(q.x - 4.0, q.y - 5.0, 2, 5, Color("e09a52"))
	game.draw_circle(Vector2(q.x, q.y - 12.0), 6.0, Color("236b2b"))
	game.draw_circle(Vector2(q.x - 4.0, q.y - 10.0), 4.0, Color("2f8a38"))
	game.draw_circle(Vector2(q.x + 4.0, q.y - 10.0), 4.0, Color("2f8a38"))
	game.draw_circle(Vector2(q.x, q.y - 15.0), 4.0, Color("4fb552"))
	game.rc(q.x + 2.0, q.y - 14.0, 1, 1, Color("ff7a8a"))

# ======================= GIAI ĐOẠN 3b: SÂN NGOÀI TƯƠNG TÁC =======================

func _seat_free(i: int) -> bool:
	return str(_seats[i].taken) == "" and int(_seats[i].res) < 0

func _late_init() -> void:
	_build_nav()
	_spawn_yard_npcs()
	_rng.randomize()

# ---------- bàn: tìm bàn gần nhất, số món ----------

# ======================= 4C: DỤNG CỤ (máy nước, cốc, thùng rác, ăn uống) =======================

func _tbl_count(ti: int) -> int:
	if ti < 0 or ti >= _tops.size():
		return 0
	var n := 0
	for id in _tops[ti]:
		if str(id) != "":
			n += 1
	return n

# ---------- vẽ vật phẩm trên mặt bàn ----------

func _draw_item(g, id: String, x: float, y: float) -> void:
	if not ITEMS.has(id):
		return
	var d: Dictionary = ITEMS[id]
	g.rc(x - 3.0, y, 7, 1, Color(0, 0, 0, 0.22))
	for r in d.px:
		g.rc(x + float(r[0]), y + float(r[1]), float(r[2]), float(r[3]), Color(str(r[4])))

# hàng sau (ô 3, 4) vẽ trước rồi mới tới hàng trước (ô 0, 1, 2)
func _draw_table_items(g, c: Vector2, ti: int) -> void:
	if ti < 0 or ti >= _tops.size():
		return
	var slots: Array = _tops[ti]
	for k in [3, 4, 0, 1, 2]:
		var id := str(slots[k])
		if id != "":
			var o: Vector2 = SLOTS[k]
			_draw_item(g, id, c.x + o.x, c.y + o.y)

# ---------- giao diện bàn ----------

# ---------- lưới tìm đường cho NPC sân ----------

func _build_nav() -> void:
	_nav_w = int(NAV_RECT.size.x / NAV_CELL)
	_nav_h = int(NAV_RECT.size.y / NAV_CELL)
	_nav_block = PackedByteArray()
	_nav_block.resize(_nav_w * _nav_h)
	for j in _nav_h:
		for i in _nav_w:
			_nav_block[j * _nav_w + i] = 1 if game.blocked(_cell_pos(Vector2i(i, j))) else 0
	_flood_main()
	_assign_seat_goals()

# đánh dấu mọi ô đi tới được từ điểm xuất hiện trước cửa
func _flood_main() -> void:
	_nav_main = PackedByteArray()
	_nav_main.resize(_nav_w * _nav_h)
	var s := _nearest_free_cell(_cell_of(SPAWN_OUT))
	if s.x < 0:
		return
	var queue: Array = [s]
	_nav_main[s.y * _nav_w + s.x] = 1
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for dd in NAV_DIRS:
			var dv: Vector2i = dd
			var q := Vector2i(c.x + dv.x, c.y + dv.y)
			if not _nav_free(q) or _nav_main[q.y * _nav_w + q.x] == 1:
				continue
			if dv.x != 0 and dv.y != 0 and not (_nav_free(Vector2i(c.x + dv.x, c.y)) and _nav_free(Vector2i(c.x, c.y + dv.y))):
				continue
			_nav_main[q.y * _nav_w + q.x] = 1
			queue.append(q)

# điểm đứng của mỗi ghế ngoài sân: ưu tiên stand, nếu rơi vào túi kín thì lấy điểm gần ghế nhất nằm trong vùng đi được
func _assign_seat_goals() -> void:
	for i in _seats.size():
		var s: Dictionary = _seats[i]
		if str(s.a) != "out":
			continue
		var sc: Vector2 = s.c
		var cands: Array = [s.stand]
		for r in [12.0, 16.0, 20.0, 24.0, 28.0]:
			for k in 16:
				cands.append(sc + Vector2.from_angle(k * TAU / 16.0) * r)
		var goal: Vector2 = _find_free("out", s.stand)
		for cp in cands:
			var p: Vector2 = cp
			if game.blocked(p):
				continue
			var cc := _cell_of(p)
			if _nav_free(cc) and _nav_main[cc.y * _nav_w + cc.x] == 1:
				goal = p
				break
		s["goal"] = goal

func _seat_goal(si: int) -> Vector2:
	var s: Dictionary = _seats[si]
	if s.has("goal"):
		return s.goal
	return _find_free(str(s.a), s.stand)

func _cell_of(p: Vector2) -> Vector2i:
	var cx := clampi(int((p.x - NAV_RECT.position.x) / NAV_CELL), 0, _nav_w - 1)
	var cy := clampi(int((p.y - NAV_RECT.position.y) / NAV_CELL), 0, _nav_h - 1)
	return Vector2i(cx, cy)

func _cell_pos(c: Vector2i) -> Vector2:
	return NAV_RECT.position + (Vector2(c) + Vector2(0.5, 0.5)) * NAV_CELL

func _nav_free(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= _nav_w or c.y >= _nav_h:
		return false
	if _nav_block[c.y * _nav_w + c.x] != 0:
		return false
	return YARD_WALK.has_point(_cell_pos(c))   # NPC không đi ra ngoài sân (không sang B4.2, không ra mép bản đồ)

func _nearest_free_cell(c: Vector2i) -> Vector2i:
	if _nav_free(c):
		return c
	for r in range(1, 9):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := Vector2i(c.x + dx, c.y + dy)
				if _nav_free(q):
					return q
	return Vector2i(-1, -1)

# BFS 8 hướng (chéo chỉ khi hai ô kề đều trống): trả về danh sách điểm đi qua, [] nếu không có đường
func _find_path(a: Vector2, b: Vector2, avoid: Array = []) -> Array:
	var out: Array = []
	if _nav_block.is_empty():
		return out
	var s := _nearest_free_cell(_cell_of(a))
	var t := _nearest_free_cell(_cell_of(b))
	if s.x < 0 or t.x < 0:
		return out
	var prev := PackedInt32Array()
	prev.resize(_nav_w * _nav_h)
	prev.fill(-2)
	var sid := s.y * _nav_w + s.x
	var tid := t.y * _nav_w + t.x
	prev[sid] = -1
	var queue: Array = [sid]
	var head := 0
	while head < queue.size() and prev[tid] == -2:
		var cur: int = queue[head]
		head += 1
		var cx := cur % _nav_w
		var cy := floori(float(cur) / float(_nav_w))
		for dd in NAV_DIRS:
			var dv: Vector2i = dd
			var q := Vector2i(cx + dv.x, cy + dv.y)
			if not _nav_free(q):
				continue
			if dv.x != 0 and dv.y != 0:
				if not (_nav_free(Vector2i(cx + dv.x, cy)) and _nav_free(Vector2i(cx, cy + dv.y))):
					continue
			# đi vòng qua người đang đứng (trừ ô gần điểm xuất phát và ô đích)
			if not avoid.is_empty() and not (q.x == t.x and q.y == t.y) and absi(q.x - s.x) + absi(q.y - s.y) > 3 and _cell_avoided(q, avoid):
				continue
			var qid := q.y * _nav_w + q.x
			if prev[qid] != -2:
				continue
			prev[qid] = cur
			queue.append(qid)
	if prev[tid] == -2:
		return out
	var ids: Array = []
	var k := tid
	while k != -1:
		ids.append(k)
		k = prev[k]
	ids.reverse()
	for id in ids:
		var n := int(id)
		out.append(_cell_pos(Vector2i(n % _nav_w, floori(float(n) / float(_nav_w)))))
	if not game.blocked(b):
		out.append(b)
	return out

# điểm ngẫu nhiên trong sân: không bị chặn, nối được với cửa chính (không rơi vào túi kín), không sát người khác
func _cell_avoided(c: Vector2i, avoid: Array) -> bool:
	var p := _cell_pos(c)
	for a in avoid:
		var ap: Vector2 = a
		if p.distance_to(ap) < 8.0:
			return true
	return false

# vị trí những người khác trong sân (NPC đang đứng/đi và người chơi)
func _others_pos(n: Dictionary) -> Array:
	return _others_pos_ex(int(n.id))

func _others_pos_ex(ex_id: int) -> Array:
	var out: Array = []
	for o in _npcs:
		if str(o.a) == "out" and int(o.get("id", -1)) != ex_id and int(o.seat) < 0:
			out.append(o.pos)
	out.append(game.player)
	return out

# đứng nghỉ mà bị ai đó đứng sát (dưới 9px): bước tránh ra, không kẹt đối đầu như hai người chắn đường nhau
func _diner_separate(n: Dictionary, delta: float) -> void:
	var p: Vector2 = n.pos
	for q in _others_pos(n):
		var op: Vector2 = q
		var dd := p.distance_to(op)
		if dd < 9.0:
			var away := Vector2(1.0, 0.0)
			if dd > 0.01:
				away = (p - op).normalized()
			var np := p + away * YARD_NPC_SPEED * delta
			if not game.blocked(np) and YARD_WALK.has_point(np):
				n.pos = np
				n.anim = float(n.anim) + delta
			return

func _random_free_spot(from: Vector2 = Vector2.ZERO, min_d: float = 0.0, ex_id: int = -1) -> Vector2:
	if _nav_main.is_empty():
		return SPAWN_OUT
	var best := SPAWN_OUT
	var best_d := -1.0
	var found := 0
	for k in 60:
		var p := Vector2(_rng.randf_range(YARD_WALK.position.x + 4.0, YARD_WALK.end.x - 4.0), _rng.randf_range(YARD_WALK.position.y + 4.0, YARD_WALK.end.y - 4.0))
		if game.blocked(p):
			continue
		var cc := _cell_of(p)
		if not _nav_free(cc) or _nav_main[cc.y * _nav_w + cc.x] != 1:
			continue
		if min_d > 0.0 and p.distance_to(from) < min_d:
			continue
		if _spot_crowded(p, ex_id):
			continue
		# chọn chỗ thưa người nhất trong vài ứng viên để NPC rải đều trong sân, không tụ thành cụm
		var sparse := 1000.0
		for q in _others_pos_ex(ex_id):
			var qp: Vector2 = q
			sparse = minf(sparse, p.distance_to(qp))
		if sparse > best_d:
			best_d = sparse
			best = p
		found += 1
		if found >= 5:
			break
	if found > 0:
		return best
	return _find_free("out", SPAWN_OUT)

# có người (NPC sân khác hoặc người chơi) đứng quá gần p không
func _spot_crowded(p: Vector2, ex_id: int = -1) -> bool:
	for o in _npcs:
		if str(o.a) != "out" or int(o.get("id", -1)) == ex_id or int(o.seat) >= 0:
			continue
		var op: Vector2 = o.pos
		if p.distance_to(op) < 14.0:
			return true
	return p.distance_to(game.player) < 14.0

# ---------- NPC sân: ngồi ăn, đứng dậy, tìm ghế trống, đứng nói chuyện, dạo quanh sân ----------
# Pha (n.ph): sit = đang ngồi | idle = đứng nghỉ | go = đang đi theo đường | settle = đến nơi, sắp ngồi
# NPC không bao giờ rời sân hay bị ẩn: mọi đường đi nằm trong YARD_WALK, và _diner_guard đưa NPC về lại sân nếu lệch tọa độ.
# Tính cách (n.kind): sitter hay ngồi, social hay đứng nói chuyện, roamer hay đi dạo (xem KIND_W); thời gian mỗi pha đều ngẫu nhiên.
# Ghế được giữ chỗ (seat.res) từ lúc NPC bắt đầu đi tới, nên người chơi và NPC khác không chiếm cùng một ghế.

func _spawn_yard_npcs() -> void:
	var out_ids: Array = []
	for i in _seats.size():
		if str(_seats[i].a) == "out":
			out_ids.append(i)
	for i in out_ids.size():
		var j := _rng.randi_range(0, out_ids.size() - 1)
		var tmp = out_ids[i]
		out_ids[i] = out_ids[j]
		out_ids[j] = tmp
	var kinds := ["sitter", "social", "sitter", "roamer", "social", "roamer", "roamer", "sitter"]
	for k in mini(2, out_ids.size()):   # khách ngồi sân: 2 (trước đây 4)
		var si: int = out_ids[k]
		var s: Dictionary = _seats[si]
		var n := _new_diner(s.pos, int(s.face))
		n.kind = kinds[k]
		n.seat = si
		n.last = si
		n.ph = "sit"
		n.ph_t = _rng.randf_range(5.0, 30.0)
		s["taken"] = "npc"
		_npcs.append(n)
	for k in 1:   # khách đi lại ngoài sân: 1 (trước đây 4)
		var w := _new_diner(_random_free_spot(), _rng.randi_range(0, 3))
		w.kind = kinds[4 + k]
		w.ph = "idle"
		w.ph_t = _rng.randf_range(0.5, 9.0)
		_npcs.append(w)

func _new_diner(pos: Vector2, face: int) -> Dictionary:
	var n := _new_npc("out", pos, "diner", face, _rand_name())
	n["id"] = _npcs.size()
	n["kind"] = "roamer"
	n["ph"] = "idle"
	n["ph_t"] = 1.0
	n["tseat"] = -1      # đích: >= 0 là ghế, -1 là đi dạo, -3 là đi tới chỗ nói chuyện
	n["last"] = -1       # ghế vừa rời (không chọn lại ngay)
	n["partner"] = -1
	n["path"] = []
	n["pi"] = 0
	n["goal"] = pos
	n["retry"] = 0
	n["go_t"] = 0.0
	n["fail"] = 0
	n["cd"] = 0.0        # hồi chiêu nói chuyện: > 0 thì không bắt chuyện và không bị bạn khác bắt chuyện (mỗi cuộc chỉ 2 người)
	n["still_t"] = 0.0   # thời gian đứng không nhúc nhích (không tính lúc ngồi): quá lâu thì hủy mục tiêu, đi chỗ khác
	n["lastp"] = pos
	return n

func _diner_update(n: Dictionary, delta: float) -> void:
	_diner_guard(n)
	n.cd = maxf(float(n.cd) - delta, 0.0)
	_diner_watchdog(n, delta)
	n.ph_t = float(n.ph_t) - delta
	match str(n.ph):
		"sit":
			if float(n.ph_t) <= 0.0:
				_diner_rise(n)
		"idle":
			_diner_separate(n, delta)
			if float(n.ph_t) <= 0.0:
				_diner_decide(n)
		"go":
			_diner_follow(n, delta)
		"settle":
			if float(n.ph_t) <= 0.0:
				_diner_sit_down(n)

# NPC không ngồi mà đứng yên quá 20 giây (kẹt giữa nhiều người, mục tiêu không tới được, chờ chỗ...): hủy mục tiêu cũ,
# nhả ghế đang giữ chỗ và chọn một điểm khác xa chỗ đang đứng. Không dịch chuyển tức thời.
func _diner_watchdog(n: Dictionary, delta: float) -> void:
	if str(n.ph) == "sit" or int(n.seat) >= 0:
		n.still_t = 0.0
		n.lastp = n.pos
		return
	var lp: Vector2 = n.lastp
	var p: Vector2 = n.pos
	if p.distance_to(lp) > 0.5:
		n.still_t = 0.0
		n.lastp = p
		return
	n.still_t = float(n.still_t) + delta
	if float(n.still_t) < 20.0:
		return
	n.still_t = 0.0
	_diner_release(n)
	n.partner = -1
	n.cd = 0.0
	for k in 4:
		if _diner_go(n, _random_free_spot(p, 70.0 - 15.0 * k, int(n.id)), -1):
			return
	n.ph = "idle"
	n.ph_t = _rng.randf_range(1.0, 3.0)

# số NPC sân khác đang ĐỨNG (không đi, không ngồi) trong bán kính r quanh p: người đang đi ngang qua không tính là đám đông
func _crowd_near(p: Vector2, r: float, ex_id: int) -> int:
	var c := 0
	for o in _npcs:
		if str(o.a) != "out" or int(o.get("id", -1)) == ex_id or int(o.seat) >= 0 or str(o.ph) == "go":
			continue
		var qp: Vector2 = o.pos
		if p.distance_to(qp) < r:
			c += 1
	return c

# lưới an toàn: tọa độ hỏng (NaN) hoặc lệch ra ngoài sân thì đưa về một điểm đứng hợp lệ, nhả ghế đang giữ chỗ
func _diner_guard(n: Dictionary) -> void:
	if int(n.seat) >= 0:
		return
	var p: Vector2 = n.pos
	if is_finite(p.x) and is_finite(p.y) and YARD.grow(6.0).has_point(p):
		return
	_diner_release(n)
	n.pos = _random_free_spot(Vector2.ZERO, 0.0, int(n.id))
	n.ph = "idle"
	n.ph_t = _rng.randf_range(1.0, 3.0)

# đứng dậy khỏi ghế: trả ghế, đặt NPC ở điểm đứng bên cạnh (không chui qua bàn)
func _diner_rise(n: Dictionary) -> void:
	var si := int(n.seat)
	if si < 0:
		n.ph = "idle"
		return
	var s: Dictionary = _seats[si]
	s["taken"] = ""
	n.seat = -1
	n.last = si
	var sc: Vector2 = s.c
	n.pos = _seat_goal(si)
	n.face = _face_toward(sc, n.pos)
	n.ph = "idle"
	n.ph_t = _rng.randf_range(1.5, 3.5)

func _diner_go(n: Dictionary, goal: Vector2, tseat: int) -> bool:
	var path := _find_path(n.pos, goal, _others_pos(n))
	if path.is_empty():
		path = _find_path(n.pos, goal)
	if path.is_empty():
		return false
	n.path = path
	n.pi = 0
	n.goal = goal
	n.tseat = tseat
	n.stuck = 0.0
	n.retry = 0
	n.go_t = 0.0
	n.ph = "go"
	if tseat >= 0:
		_seats[tseat]["res"] = int(n.id)
	return true

# chọn việc kế tiếp theo tính cách: ngồi / nói chuyện / đi dạo / đứng nghỉ
func _diner_decide(n: Dictionary) -> void:
	var w: Array = KIND_W[str(n.kind)]
	var r := _rng.randf()
	var acc := 0.0
	var pick := 3
	for i in w.size():
		acc += float(w[i])
		if r < acc:
			pick = i
			break
	# đang đứng trong đám đông (từ 2 người khác trong 28px): tách ra, đi tới chỗ thưa người
	if _crowd_near(n.pos, 28.0, int(n.id)) >= 2:
		pick = 2
	var ok := false
	match pick:
		0:
			ok = _diner_try_seat(n)
		1:
			ok = _diner_try_chat(n)
		2:
			ok = _diner_try_wander(n)
		_:
			n.face = _rng.randi_range(0, 3)   # đứng nghỉ, xoay người nhìn quanh
			n.ph_t = _rng.randf_range(5.0, 12.0)
			return
	if ok:
		n.fail = 0
		return
	n.fail = int(n.fail) + 1
	if int(n.fail) >= 4:   # nhiều lần không tìm được đường: đứng sai chỗ (ví dụ sát vật cản), dời tới điểm thông thoáng
		n.fail = 0
		n.pos = _random_free_spot(Vector2.ZERO, 0.0, int(n.id))
	n.ph = "idle"
	n.ph_t = _rng.randf_range(2.0, 6.0)

# ghế trống gần (chọn ngẫu nhiên 2 ghế, lấy ghế gần hơn)
func _diner_try_seat(n: Dictionary) -> bool:
	var open_seats: Array = []
	for i in _seats.size():
		if str(_seats[i].a) == "out" and _seat_free(i) and i != int(n.last):
			open_seats.append(i)
	if open_seats.is_empty():
		return false
	var a: int = open_seats[_rng.randi_range(0, open_seats.size() - 1)]
	var b: int = open_seats[_rng.randi_range(0, open_seats.size() - 1)]
	var pa: Vector2 = _seats[a].c
	var pb: Vector2 = _seats[b].c
	var si := a if n.pos.distance_to(pa) <= n.pos.distance_to(pb) else b
	return _diner_go(n, _seat_goal(si), si)

func _diner_try_wander(n: Dictionary) -> bool:
	return _diner_go(n, _random_free_spot(n.pos, 40.0, int(n.id)), -1)

# đi tới đứng cạnh một bạn đang đứng nghỉ để nói chuyện
func _diner_try_chat(n: Dictionary) -> bool:
	var cand: Array = []
	for c in _npcs:
		if c.mode == "diner" and str(c.a) == "out" and int(c.id) != int(n.id) and int(c.seat) < 0 and str(c.ph) == "idle" and float(c.cd) <= 0.0 and _crowd_near(c.pos, 28.0, int(c.id)) < 2:
			cand.append(c)
	if float(n.cd) > 0.0:
		return false
	if cand.is_empty():
		return false
	var o: Dictionary = cand[_rng.randi_range(0, cand.size() - 1)]
	var op: Vector2 = o.pos
	for k in 12:
		var p := op + Vector2.from_angle(_rng.randf() * TAU) * 16.0
		if game.blocked(p) or _spot_crowded(p, int(n.id)):
			continue
		var cc := _cell_of(p)
		if not _nav_free(cc) or _nav_main[cc.y * _nav_w + cc.x] != 1:
			continue
		if _diner_go(n, p, -3):
			n.partner = int(o.id)
			n.cd = 40.0   # giữ chỗ cuộc trò chuyện: bạn khác không chen vào, cả hai không bắt chuyện thêm
			o.cd = 40.0
			return true
	return false

func _diner_release(n: Dictionary) -> void:
	var ts := int(n.tseat)
	if ts >= 0 and int(_seats[ts].res) == int(n.id):
		_seats[ts]["res"] = -1
	n.tseat = -1

func _diner_follow(n: Dictionary, delta: float) -> void:
	var path: Array = n.path
	n.go_t = float(n.go_t) + delta
	if float(n.go_t) > 45.0:   # đi quá lâu (kẹt vì người khác): bỏ cuộc, nhả ghế đã giữ chỗ
		_diner_release(n)
		n.ph = "idle"
		n.ph_t = _rng.randf_range(1.5, 3.0)
		return
	if int(n.pi) >= path.size():
		_diner_arrive(n)
		return
	var tgt: Vector2 = path[int(n.pi)]
	var p: Vector2 = n.pos
	var d := tgt - p
	if d.length() < 1.2:
		n.pi = int(n.pi) + 1
		return
	# bước không vượt quá khoảng cách còn lại: khung hình giật (delta lớn) không làm NPC lao qua điểm rồi dao động tại chỗ
	var np := p + d.normalized() * minf(YARD_NPC_SPEED * delta, d.length())
	if game.blocked(np) or _agent_near(n, np):
		# chỉ bị người chắn (không phải vật cản): lách sang bên thay vì đứng đối đầu
		if not game.blocked(np):
			var dir := d.normalized()
			var perp := Vector2(-dir.y, dir.x)
			if int(n.id) % 2 == 1:
				perp = -perp
			for sg in [1.0, -1.0]:
				var alt: Vector2 = p + (dir * 0.4 + perp * sg).normalized() * minf(YARD_NPC_SPEED * delta, 4.0)
				if not game.blocked(alt) and YARD_WALK.has_point(alt) and not _agent_near(n, alt):
					n.pos = alt
					n.anim = float(n.anim) + delta
					n.face = _face_toward(Vector2.ZERO, d)
					n.stuck = 0.0
					return
		n.stuck = float(n.stuck) + delta
		if float(n.stuck) > 1.0:
			n.stuck = 0.0
			_diner_repath(n)
		return
	n.stuck = 0.0
	n.pos = np
	n.anim = float(n.anim) + delta
	n.face = _face_toward(Vector2.ZERO, d)

# bị chặn quá 1 giây (người chơi hoặc NPC khác đứng chắn): tìm lại đường, quá 2 lần thì bỏ cuộc
func _diner_repath(n: Dictionary) -> void:
	n.retry = int(n.retry) + 1
	var goal: Vector2 = n.goal
	var path := _find_path(n.pos, goal, _others_pos(n))
	if path.is_empty():
		path = _find_path(n.pos, goal)
	if int(n.retry) > 2 or path.is_empty():
		_diner_release(n)
		n.ph = "idle"
		n.ph_t = _rng.randf_range(1.5, 3.0)
		return
	n.path = path
	n.pi = 0

func _diner_arrive(n: Dictionary) -> void:
	var ts := int(n.tseat)
	if ts >= 0:
		var sc: Vector2 = _seats[ts].c
		n.face = _face_toward(n.pos, sc)
		n.ph = "settle"
		n.ph_t = 0.4
	elif ts == -3:
		n.tseat = -1
		n.ph = "idle"
		n.ph_t = _rng.randf_range(6.0, 12.0)
		var pid := int(n.partner)
		n.partner = -1
		n.cd = _rng.randf_range(25.0, 45.0)
		for o in _npcs:
			if o.mode == "diner" and int(o.id) == pid:
				var op: Vector2 = o.pos
				n.face = _face_toward(n.pos, op)
				if str(o.ph) == "idle" and int(o.seat) < 0:
					o.face = _face_toward(op, n.pos)
					o.ph_t = maxf(float(o.ph_t), n.ph_t)   # cả hai đứng lại nói chuyện cùng nhau
					o.timer = _rng.randf_range(1.2, 2.6)    # bạn kia đáp lại sau chút
					o.cd = _rng.randf_range(25.0, 45.0)
				break
		if not n.lines.is_empty():
			n.say = n.lines[_rng.randi_range(0, n.lines.size() - 1)]
			n.say_t = 2.6
	else:
		n.tseat = -1
		n.ph = "idle"
		n.ph_t = _rng.randf_range(2.0, 6.0)

func _diner_sit_down(n: Dictionary) -> void:
	var ts := int(n.tseat)
	if ts < 0 or str(_seats[ts].taken) != "":
		_diner_release(n)
		n.ph = "idle"
		n.ph_t = 1.5
		return
	var s: Dictionary = _seats[ts]
	s["taken"] = "npc"
	s["res"] = -1
	n.seat = ts
	n.tseat = -1
	n.pos = s.pos
	n.face = int(s.face)
	n.eat = 0.0
	n.ph = "sit"
	n.ph_t = _rng.randf_range(25.0, 55.0) if str(n.kind) == "sitter" else _rng.randf_range(14.0, 35.0)
