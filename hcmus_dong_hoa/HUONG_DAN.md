# Một ngày ở HCMUS - cơ sở Đông Hòa (Godot 4.7)

## Chạy game
1. Mở Godot 4.7, bấm Import, chọn file `project.godot` trong thư mục này.
2. Bấm nút Play (hoặc F5). Dùng **W A S D** hoặc các phím **mũi tên** để đi, **E** để vào/ra cửa khi đứng gần công trình.
3. Khi Godot lần đầu mở có thể mất vài giây để nhập (import) file font.
4. Nếu có lỗi đỏ ở ô Output, chép nguyên dòng lỗi gửi lại để sửa.

## Có gì trong game
- Bản đồ theo sơ đồ cơ sở: Tòa A, B, C, D, E (dãy phía tây), đài phun nước và vườn, Tòa F, G (phía đông), Nhà Thể Dục, Nhà Điều hành ở phía nam, bãi giữ xe, cổng trường ở Đường T1.
- Nhà Điều hành có dòng chữ vàng "TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN" và "UNIVERSITY OF SCIENCE", có bậc thềm và hoa cảnh. Các tòa còn lại giống nhau (tường vàng, mái đỏ), chỉ khác chữ cái.
- Nhân vật mặc áo polo trường: cổ xanh sọc trắng, vai trắng, thân và tay xanh navy, có logo ở ngực.
- Sinh viên đi lại và nói chuyện, xe máy chạy trên đường nội bộ, đồng hồ 7:00 - 17:00.
- **Hồ đài phun nước** nằm giữa các tòa nhà.
- Có thể đi vào **Tòa A-F, Nhà Thể Dục, Nhà Điều hành và Căn tin** bằng cách đến gần cửa rồi bấm **E**. Đi đến cửa phía dưới bên trong và bấm **E** để quay ra.
- Đi gần tòa nhà hoặc quầy nào thì góc trên bên trái hiện tên và mô tả.

## Cấu trúc thư mục
```
main.gd                    điều phối chính (_ready, _process); kế thừa renderer từ maps/campus_overlay.gd
main.tscn, project.godot   scene và cấu hình
font.ttf
scripts/
  core/game_state.gd       trạng thái dùng chung (vị trí người chơi, NPC, giờ...)
  maps/registry.gd         danh sách module bổ sung cho bản đồ
  maps/campus_data.gd      dữ liệu khuôn viên gốc: BUILDINGS, KIOSKS, ZONES, PALMS...
  maps/campus_update.gd    cập nhật thế giới khuôn viên
  maps/campus_setup.gd     dựng va chạm, cây, NPC và cảnh khuôn viên
  maps/campus_scenery.gd   cảnh nền, đường, bãi xe, cổng
  maps/ho_nuoc.gd          hồ cảnh quan nhiều tầng, cầu nhỏ và đài phun nước
  maps/campus_structures.gd tòa nhà, Nhà Điều hành, quầy nhỏ
  maps/campus_overlay.gd  minimap, hiệu ứng và sắp xếp lớp vẽ khuôn viên
  maps/b42_lab.gd          module Tòa B4.2 và phòng lab
  draw/pen.gd              bút vẽ cơ bản (hình chữ nhật pixel, bóng, chữ)
  draw/characters.gd       người, NPC thường, bóng thoại, xe máy
  draw/newcharacters.gd    lớp chuyển tiếp; NPC có tên do features/newcharacters.gd quản lý
  systems/audio_manager.gd phát âm thanh (thiếu file thì im lặng, không lỗi)
  features/registry.gd     registry gameplay dùng chung (quiz, HUD...)
  features/_mau_feature.gd file mẫu để copy khi làm feature mới (không chạy trong game)
  features/feature.gd      lớp nền cho chức năng mới
  features/building_doors.gd đi vào / ra tòa nhà, nhà thể dục, nhà điều hành, căn tin
  features/math_quiz.gd    quiz luyện tập và kỳ thi với NPC
  features/admin_time.gd   công cụ admin tua tuần, thứ và giờ trong game
  features/danhnhau.gd     bấm H chọc/trêu NPC (không đối kháng)
  features/khoc.gd         cơ chế khóc dùng chung cho người chơi và NPC
  features/daily_summary.gd tổng kết GPA và điểm rèn luyện, tự mở khi sang ngày mới hoặc nhấn F9
  systems/math_questions.gd ngân hàng và bộ tạo câu hỏi quiz
assets/
  audio/                   bỏ file âm thanh vào đây
  hcmus_logo.png           (tùy chọn) logo thật, xem mục bên dưới
```
Bản đồ gốc và module mở rộng đều nằm trong `scripts/maps/`. Các script `campus_*` tạo thành chuỗi kế thừa của khuôn viên ban đầu; `maps/registry.gd` chỉ đăng ký các module bổ sung như B4.2. Gameplay tổng quát vẫn nằm trong `scripts/features/`.

## Quy tắc đăng ký (registry)
Registry là danh sách đường dẫn để game tự nạp script lúc khởi động. Chọn registry theo **phạm vi sử dụng**, không chỉ theo việc script có vẽ lên bản đồ hay không:

| Loại nội dung | Đặt file tại | Đăng ký tại | Ví dụ |
|---|---|---|---|
| Gameplay dùng chung, có thể dùng ở nhiều nơi | `scripts/features/` | `scripts/features/registry.gd` | quiz, HUD, cửa ra vào dùng chung |
| Nội dung chỉ thuộc một tòa/khu vực cụ thể | `scripts/maps/` | `scripts/maps/registry.gd` | Tòa B4.2 và phòng lab |

Khi thêm module:
1. Tạo file `.gd` trong đúng thư mục và kế thừa lớp nền phù hợp (feature thường dùng `scripts/features/feature.gd`).
2. Mở đúng registry, kiểm tra đường dẫn chưa có rồi thêm **một dòng mới ngay trước dấu `]` cuối danh sách**. Giữ nguyên các dòng khác, không thay cả danh sách hoặc sắp xếp lại.
   ```gdscript
   "res://scripts/features/ten_feature.gd",
   ```
   Với nội dung bản đồ, dùng đường dẫn `res://scripts/maps/ten_module.gd` trong `maps/registry.gd`.
3. Nếu module bản đồ thêm tòa nhà thường, thêm dữ liệu vào `game.BUILDINGS` trong `_ready()`; hệ thống nền sẽ tự lấy dữ liệu để dựng va chạm và minimap. Tránh thêm va chạm lần thứ hai cho cùng tòa.
4. Chạy game và kiểm tra Output. Đường dẫn trong registry phải khớp chính xác tên file.

Khi nhiều người cùng thêm module vào registry, có thể xảy ra conflict. Giữ lại **tất cả đường dẫn khác nhau còn hợp lệ**, xóa các dấu `<<<<<<<`, `=======`, `>>>>>>>`, rồi kiểm tra không có đường dẫn trùng hoặc trỏ tới file không tồn tại. Không xóa entry của người khác để hết conflict.

## Đi vào / ra công trình
Đến gần cửa phía trước của Tòa A-F, Nhà Thể Dục, Nhà Điều hành hoặc một trong các quầy Nhà ăn rồi bấm **E**. Bên trong dùng **W A S D** để đi; đến gần cửa ở cạnh dưới phòng và bấm **E** để trở lại đúng vị trí bên ngoài. Tọa độ cửa được tạo từ kích thước trong `BUILDINGS`, `DIEUHANH` và các quầy Nhà ăn ở `scripts/maps/campus_data.gd`, nên cửa đi theo khi công trình được dời.

## Chỉnh bản đồ
Mở `scripts/maps/campus_data.gd`: mỗi dòng trong `BUILDINGS` là một tòa (tên, x, y, rộng, cao, màu tường, màu mái, mô tả).
`KIOSKS` là các quầy nhỏ (nhà ăn, quầy giáo trình...), `ZONES` là các khu vực hiện tên, `LINES` là các câu NPC hay nói.

## Thêm âm thanh
Bỏ file `.ogg` / `.wav` / `.mp3` vào `assets/audio/`, rồi gọi bằng tên file (không cần đuôi):
```gdscript
audio.play_sfx("click")   # hiệu ứng, phát assets/audio/click.ogg
audio.play_music("nen")   # nhạc nền, phát assets/audio/nen.ogg
audio.stop_music()
```
Muốn nhạc lặp lại: chọn file trong Godot, tab Import, bật Loop, bấm Reimport.

## Thêm chức năng mới (điểm danh, học thư viện, tập thể dục, nói chuyện NPC...)
1. Tạo file mới trong `scripts/features/`:
```gdscript
extends "res://scripts/features/feature.gd"

func begin() -> void:
	super()                       # bật chế độ bận: người chơi đứng yên


func finish() -> void:
	super()
```
2. Đăng ký gameplay dùng chung trong `scripts/features/registry.gd` (KHÔNG sửa main.gd):
```gdscript
	"res://scripts/features/ten_feature.gd",
```
3. Gọi `begin()` khi người chơi bấm phím hoặc đứng đúng chỗ, gọi `finish()` khi xong.
4. Muốn vẽ thêm lên thế giới thì ghi đè `draw_front_layer()` (renderer khuôn viên tự gọi); muốn vẽ giao diện cố định trên màn hình thì tạo `CanvasLayer` + `Control`.
Chức năng là một Node nên tự có `_process(delta)` và `_unhandled_input(event)`. Trong `game` có `game.player`, `game.audio`, `game.npcs`, `game.game_min`...

## Thêm công trình/khu vực bản đồ riêng
Nội dung riêng của một công trình (ví dụ phòng bên trong Tòa B4.2) đặt trong một module tại `scripts/maps/`, đăng ký trong `scripts/maps/registry.gd`:
1. Tạo module kế thừa `scripts/features/feature.gd` để có thể dùng tương tác, cập nhật và vẽ.
2. Nếu công trình dùng hệ thống tòa nhà chung, thêm dữ liệu vào `game.BUILDINGS` trong `_ready()`. Map modules được khởi tạo trước khi dựng va chạm, minimap và NPC; vì thế dữ liệu tòa nhà sẽ được các hệ thống đó nhận tự động.
3. Chỉ thêm va chạm riêng cho các vật thể không nằm trong `BUILDINGS`. Cơ chế tổng quát như cửa đi vào công trình thuộc `scripts/features/` và dùng dữ liệu bản đồ chung.

## Thay logo bằng ảnh thật
Chép ảnh logo trường (vuông, 32x32 hoặc 64x64) vào thư mục `assets`, đặt tên `hcmus_logo.png`.

## Quy ước để dễ nâng cấp map / NPC / âm thanh / skin sau này
1. **Không gắn cứng tọa độ trong gameplay dùng chung.** Vị trí đặc thù của module đặt trong `scripts/maps/`; dữ liệu khuôn viên ban đầu nằm trong `scripts/maps/campus_data.gd`.
2. **Dữ liệu riêng của feature để trong file feature** (bảng cá, danh sách nhiệm vụ...), không đưa vào file lõi.
3. **Âm thanh gọi theo tên ngay từ bây giờ** (`game.audio.play_sfx("tên")`). Chưa có file thì game vẫn chạy; sau này chỉ cần thả file vào `assets/audio/`.
4. **Tên cố định thì giữ nguyên**: tên âm thanh, tên khu vực. Đừng đổi giữa chừng.
5. **Đồ họa (`scripts/draw/`) giao cho 1 người phụ trách.** Chỉ sửa bên trong hàm, không đổi tên hàm hay tham số vì các file kế thừa nhau theo chuỗi và feature có gọi `rc(...)`, `ctext(...)`.
6. **Giai đoạn cải tiến lớn (map, NPC, skin)** làm sau khi các feature đã gộp vào `main`, giao cho 1-2 người; các bạn khác tạm không sửa file lõi trong thời gian đó.

## Làm việc nhóm bằng Git
Xem `HUONG_DAN_GIT.md`.

## Đánh trêu chọc NPC và nhân vật khóc
- Đứng gần NPC rồi bấm **H** để đánh trêu; giữ H để đấm liên hoàn bằng hai tay.
- NPC bị đánh có thể khóc hoặc giận. NPC giận đủ số cú đánh sẽ nói một tràng rồi bỏ đi tạm thời và xuất hiện lại; Cô Toán không biến mất.
- Bấm **C** để nhân vật của bạn khóc, bấm lại để nín. Nhân vật cũng tự khóc khi GPA bị tụt.
- Code ở `scripts/features/danhnhau.gd` và `scripts/features/khoc.gd`. Cả hai feature được đăng ký sau `newcharacters.gd` trong `scripts/features/registry.gd`.
- Đây là tính năng trêu vui: không có máu, sát thương hoặc chế độ đối kháng.

## Quiz ôn đề
- Đến NPC **Cô Toán** có dấu `?` cạnh Tòa F, nhấn **E** để mở quiz rồi chọn Cơ sở lập trình hoặc Vi tích phân 1.
- Ngày trong game hiển thị theo **thứ · tuần**. Hai tuần thi giữa kỳ là tuần 8–9: Thầy LĐK tổ chức thi Cơ sở lập trình ở tuần 8; Thầy LTC tổ chức thi Vi tích phân 1 ở tuần 9. Trong tuần thi, tới gần đúng thầy và nhấn **E** để bắt đầu.
- Mỗi lần vào thi, game chọn ngẫu nhiên một đề gồm 5 câu của đúng môn; Cô Toán vẫn dùng để luyện tập.
- Nhấn **Esc** để mở menu tạm dừng, chọn **Thời gian** để mở bảng Admin nhỏ giữa màn hình; chọn tuần, thứ, giờ rồi nhấn **CHUYỂN TỚI**. Bảng thời gian tạm dừng game; nhấn **ĐÓNG** để quay lại menu Esc.
- Chỉ câu đã xác minh với `grading_method: exact` được tự chấm. GPA chỉ bị trừ nếu toàn bộ đề tự chấm được; ngân hàng hiện tại còn câu chấm thủ công nên không làm giảm GPA.
- Xem `HUONG_DAN_QUIZ.md` và `HUONG_DAN_HOC_MATH_QUIZ.md` để biết cách chơi và cách đọc code.

## Nền tĩnh khuôn viên
- Nền không chuyển động như cỏ, đường, tòa nhà và kiosk được vẽ trên node nền tĩnh, chỉ vẽ lại khi camera gần ra khỏi vùng đệm đã lưu.
- Đài phun nước, cây, NPC, người chơi, mây và minimap vẫn được vẽ ở lớp động.
