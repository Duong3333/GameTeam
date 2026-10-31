# Một ngày ở HCMUS - cơ sở Đông Hòa (Godot 4.7)

## Chạy game
1. Mở Godot 4.7, bấm Import, chọn file `project.godot` trong thư mục này.
2. Bấm nút Play (hoặc F5). Dùng **W A S D** để đi, **E** để vào/ra cửa khi đứng gần công trình hoặc câu cá khi đứng sát hồ đài phun nước, **B** để mở sổ cá.
3. Khi Godot lần đầu mở có thể mất vài giây để nhập (import) file font.
4. Nếu có lỗi đỏ ở ô Output, chép nguyên dòng lỗi gửi lại để sửa.

## Có gì trong game
- Bản đồ theo sơ đồ cơ sở: Tòa A, B, C, D, E (dãy phía tây), đài phun nước và vườn, Tòa F, G (phía đông), Nhà Thể Dục, Nhà Điều hành ở phía nam, bãi giữ xe, cổng trường ở Đường T1.
- Nhà Điều hành có dòng chữ vàng "TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN" và "UNIVERSITY OF SCIENCE", có bậc thềm và hoa cảnh. Các tòa còn lại giống nhau (tường vàng, mái đỏ), chỉ khác chữ cái.
- Nhân vật mặc áo polo trường: cổ xanh sọc trắng, vai trắng, thân và tay xanh navy, có logo ở ngực.
- Sinh viên đi lại và nói chuyện, xe máy chạy trên đường nội bộ, đồng hồ 7:00 - 17:00.
- **Hồ đài phun nước** (giữa các tòa nhà) là nơi câu cá. Đứng sát bờ rồi bấm **E** để câu cá (xem mục "Câu cá").
- Có thể đi vào **Tòa A-F, Nhà Thể Dục, Nhà Điều hành và Căn tin** bằng cách đến gần cửa rồi bấm **E**. Đi đến cửa phía dưới bên trong và bấm **E** để quay ra.
- Đi gần tòa nhà hoặc quầy nào thì góc trên bên trái hiện tên và mô tả.

## Cấu trúc thư mục
```
main.gd                    điều phối chính (_ready, _process, _draw)
main.tscn, project.godot   scene và cấu hình
font.ttf
scripts/
  data/game_data.gd        BẢN ĐỒ: BUILDINGS, KIOSKS, ZONES, PALMS, câu NPC (LINES)  <- sửa bản đồ ở đây
  core/game_state.gd       các biến dùng chung (vị trí người chơi, NPC, giờ...)
  core/world_update.gd     mỗi khung hình: va chạm, di chuyển, NPC, xe máy, ánh sáng, HUD
  core/world_setup.gd      dựng thế giới lúc bắt đầu (cây, NPC, đèn, camera, HUD)
  draw/pen.gd              bút vẽ cơ bản (hình chữ nhật pixel, bóng, chữ)
  draw/scenery.gd          cỏ, đường, bãi xe, đài phun nước, cổng, cây, đèn, ghế
  draw/structures.gd       tòa nhà, Nhà Điều hành, quầy nhỏ
  draw/characters.gd       người, NPC thường, bóng thoại, xe máy
  draw/newcharacters.gd    5 NPC có tên, hội thoại, chuyển động (lớp kế thừa)
  draw/overlay.gd          sắp xếp chiều sâu, mây, cánh phượng, bản đồ nhỏ
  systems/audio_manager.gd phát âm thanh (thiếu file thì im lặng, không lỗi)
  features/registry.gd     DANH SÁCH feature, thêm feature mới = thêm 1 dòng ở đây
  features/_mau_feature.gd file mẫu để copy khi làm feature mới (không chạy trong game)
  features/feature.gd      lớp nền cho chức năng mới (câu cá, điểm danh, ...)
  features/fishing.gd      CHỨC NĂNG CÂU CÁ (quăng cần, chờ cá, kéo cá, sổ cá, điểm)
  features/building_doors.gd đi vào / ra tòa nhà, nhà thể dục, nhà điều hành, căn tin
  features/math_quiz.gd    quiz toán với NPC Cô Toán
  systems/math_questions.gd ngân hàng và bộ tạo câu hỏi quiz
assets/
  audio/                   bỏ file âm thanh vào đây
  hcmus_logo.png           (tùy chọn) logo thật, xem mục bên dưới
```
Các file trong `scripts/data`, `core`, `draw` nối với nhau theo thứ tự từ trên xuống: mỗi file kế thừa file đứng trước (xem dòng `extends` đầu file). Vì vậy một hàm chỉ gọi được hàm nằm ở file **cùng tầng hoặc phía trên**. Thêm hàm vẽ mới thì đặt vào đúng file theo nhóm.

## Câu cá
Đứng sát bờ hồ đài phun nước (góc trên bên trái sẽ hiện tên "Đài phun nước và vườn điều") rồi:
1. Bấm **E** (hoặc Space) để lấy cần. Thanh "Sức quăng" chạy qua lại, bấm **E** để quăng. Quăng càng xa càng dễ ra cá to, cá hiếm (cá koi vàng chỉ xuất hiện ở xa).
2. Chờ phao. Phao rung nhẹ là cá chỉ "thử" (đừng kéo). Khi phao chìm mạnh và có dấu **!** trên đầu thì bấm **E** ngay (chậm quá hoặc sớm quá cá sẽ chạy mất).
3. Giữ **E** để nâng vùng xanh lên, thả ra thì vùng xanh rơi xuống. Giữ con cá trong vùng xanh cho thanh tiến độ đầy là bắt được. Cá nhanh hơn thì khó hơn.
4. **Q** hoặc **Esc** để thu cần giữa chừng. **B** mở Sổ cá: số lượng từng loại, cỡ lớn nhất, tổng điểm.

Vớt được cá thì có điểm (cá to hơn điểm cao hơn); đôi khi vớt trúng đồ linh tinh như dép tổ ong, lon nước, thẻ sinh viên cũ.

## Đi vào / ra công trình
Đến gần cửa phía trước của Tòa A-F, Nhà Thể Dục, Nhà Điều hành hoặc một trong các quầy Nhà ăn rồi bấm **E**. Bên trong dùng **W A S D** để đi; đến gần cửa ở cạnh dưới phòng và bấm **E** để trở lại đúng vị trí bên ngoài. Tọa độ cửa được tạo từ kích thước trong `BUILDINGS`, `DIEUHANH` và các quầy Nhà ăn ở `scripts/data/game_data.gd`, nên cửa đi theo khi công trình được dời.

Muốn chỉnh:
- Thêm/sửa loại cá: bảng `ITEMS` ở đầu `scripts/features/fishing.gd` (tên, độ hiếm, cỡ, độ khó, điểm, màu).
- Chỉnh vùng câu cá: hằng `FISH_POND` trong `scripts/data/game_data.gd` (hình elip nội tiếp khung này, hiện trùng với mặt nước đài phun nước `FOUNT`). Phần vẽ đài phun nước nằm trong `draw_ground()` của `scripts/draw/scenery.gd`.
- Âm thanh (tùy chọn): bỏ file tên `rod`, `cast`, `splash`, `bite`, `reel`, `catch`, `fail` vào `assets/audio/`.

## Chỉnh bản đồ
Mở `scripts/data/game_data.gd`: mỗi dòng trong `BUILDINGS` là một tòa (tên, x, y, rộng, cao, màu tường, màu mái, mô tả).
`KIOSKS` là các quầy nhỏ (nhà ăn, quầy giáo trình...), `ZONES` là các khu vực hiện tên, `LINES` là các câu NPC hay nói, `FISH_POND` là vùng hồ nước dùng để câu cá (đài phun nước).

## Thêm âm thanh
Bỏ file `.ogg` / `.wav` / `.mp3` vào `assets/audio/`, rồi gọi bằng tên file (không cần đuôi):
```gdscript
audio.play_sfx("click")   # hiệu ứng, phát assets/audio/click.ogg
audio.play_music("nen")   # nhạc nền, phát assets/audio/nen.ogg
audio.stop_music()
```
Muốn nhạc lặp lại: chọn file trong Godot, tab Import, bật Loop, bấm Reimport.

## Thêm chức năng mới (điểm danh, học thư viện, tập thể dục, nói chuyện NPC...)
1. Tạo file mới trong `scripts/features/`, ví dụ `fishing.gd`:
```gdscript
extends "res://scripts/features/feature.gd"

func begin() -> void:
	super()                       # bật chế độ bận: người chơi đứng yên
	game.audio.play_sfx("splash")

func finish() -> void:
	super()
```
2. Đăng ký bằng 1 dòng trong `scripts/features/registry.gd` (KHÔNG sửa main.gd):
```gdscript
	"res://scripts/features/fishing.gd",
```
3. Gọi `begin()` khi người chơi bấm phím hoặc đứng đúng chỗ, gọi `finish()` khi xong.
4. Muốn vẽ thêm lên thế giới thì ghi đè `draw_front_layer()` (main.gd tự gọi); muốn vẽ giao diện cố định trên màn hình thì làm giống `fishing.gd` (CanvasLayer + Control).

Ví dụ hoàn chỉnh: `scripts/features/fishing.gd`.
Chức năng là một Node nên tự có `_process(delta)` và `_unhandled_input(event)`. Trong `game` có `game.player`, `game.audio`, `game.npcs`, `game.game_min`...

## Thay logo bằng ảnh thật
Chép ảnh logo trường (vuông, 32x32 hoặc 64x64) vào thư mục `assets`, đặt tên `hcmus_logo.png`.

## Quy ước để dễ nâng cấp map / NPC / âm thanh / skin sau này
1. **Không gắn cứng tọa độ trong feature.** Vị trí, khu vực nào cũng khai báo trong `data/game_data.gd` (như `FISH_POND` cho câu cá) rồi feature đọc lại. Đổi map thì feature tự đi theo.
2. **Dữ liệu riêng của feature để trong file feature** (bảng cá, danh sách nhiệm vụ...), không đưa vào file lõi.
3. **Âm thanh gọi theo tên ngay từ bây giờ** (`game.audio.play_sfx("tên")`). Chưa có file thì game vẫn chạy; sau này chỉ cần thả file vào `assets/audio/`.
4. **Tên cố định thì giữ nguyên**: tên âm thanh, tên khu vực. Đừng đổi giữa chừng.
5. **Đồ họa (`scripts/draw/`) giao cho 1 người phụ trách.** Chỉ sửa bên trong hàm, không đổi tên hàm hay tham số vì các file kế thừa nhau theo chuỗi và feature có gọi `rc(...)`, `ctext(...)`.
6. **Giai đoạn cải tiến lớn (map, NPC, skin)** làm sau khi các feature đã gộp vào `main`, giao cho 1-2 người; các bạn khác tạm không sửa file lõi trong thời gian đó.

## Làm việc nhóm bằng Git
Xem `HUONG_DAN_GIT.md`.


## Quiz Toán
- Đến NPC **Cô Toán** có dấu `?` cạnh Tòa F, nhấn **E** để bắt đầu quiz. Không có màn hình chọn độ khó.
- Mỗi lượt luôn có 5 câu: câu 1-2 là số học cơ bản; câu 3-5 lấy từ Vi tích phân và tăng dần độ khó.
- Điểm quiz dưới 5/10 bị trừ 0,10 GPA.
- Xem `HUONG_DAN_QUIZ.md` và `HUONG_DAN_HOC_MATH_QUIZ.md` để biết cách chơi và cách đọc code.
