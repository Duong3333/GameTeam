# Godot cho người mới - đủ để làm việc với project này

Project dùng **Godot 4.7** và ngôn ngữ **GDScript** (cú pháp gần giống Python). Phần lớn game được vẽ bằng code, nên bạn gần như không cần dùng công cụ kéo thả của Godot.

## 1. Mở và chạy game
1. Mở Godot -> **Import** -> chọn file `project.godot` -> Import & Edit.
2. Lần đầu Godot tự tạo thư mục `.godot/` (không đưa lên Git, đã có trong `.gitignore`), mất vài giây.
3. Bấm **F5** (nút Play ở góc trên phải) để chạy game. Dùng **W A S D** để đi.
4. Thoát game: đóng cửa sổ game hoặc bấm nút Stop (hình vuông).

## 2. Giao diện cần biết
- **Script** (nút trên cùng giữa): màn hình sửa code. Bạn chủ yếu làm việc ở đây.
- **FileSystem** (khung dưới trái): danh sách file project. Bấm đúp một file `.gd` để mở.
- **Output** (khung dưới): chữ do `print()` in ra và **lỗi đỏ**. Có lỗi thì xem ở đây trước.
- **Debugger -> Errors** (cạnh Output): lỗi lúc đang chạy, kèm file và số dòng. Bấm vào để nhảy tới dòng đó.

## 3. Phím tắt hữu ích
| Phím | Việc |
|---|---|
| F5 | Chạy game |
| Ctrl+S | Lưu file (nhớ lưu rồi mới F5) |
| Ctrl+Shift+F | Tìm chữ trong toàn bộ project |
| Ctrl+Click vào tên hàm | Nhảy tới nơi hàm được viết |
| Ctrl+K | Comment / bỏ comment dòng đang chọn |

## 4. Đọc code theo thứ tự
1. `HUONG_DAN.md` - tổng quan và cấu trúc thư mục.
2. `scripts/features/student_stats.gd` - file ngắn nhất, dễ hiểu nhất.
3. `scripts/features/student_hud.gd` - cách vẽ giao diện góc trái trên.
4. `scripts/features/fishing.gd` - feature lớn, đọc sau cùng.
5. `main.gd` - nơi điều phối: mỗi khung hình gọi `_process` rồi `_draw`.

Mỗi lần đọc một file, tự hỏi: *file này lấy dữ liệu từ đâu, và nó làm đổi gì trên màn hình?*

## 5. GDScript - chỉ cần nhận ra những thứ này
```gdscript
var diem := 10              # biến
const TOC_DO := 3.0         # hằng số (không đổi)

func cong_diem(n: int) -> void:   # hàm
	diem += n                      # thụt đầu dòng bằng TAB
	if diem > 100:
		diem = 100
	print("Điểm: ", diem)          # in ra ô Output

for i in 5:                        # lặp 5 lần
	print(i)

signal da_doi(gia_tri)            # tín hiệu: báo "có chuyện xảy ra"
da_doi.emit(5)                     # phát tín hiệu
```
- `_ready()` chạy **1 lần** khi nút bắt đầu. `_process(delta)` chạy **mỗi khung hình**. `_unhandled_input(event)` chạy khi bấm phím.
- `extends "đường_dẫn.gd"` = "kế thừa file kia, dùng được hàm và biến của nó".
- `game.player`, `game.stats`... trong feature là các thứ lấy từ `main.gd`.
- Lỗi hay gặp nhất: **thụt dòng sai** (trộn dấu cách và TAB), hoặc **gõ sai tên biến**.

## 6. Thử sửa để học (an toàn, đổi xong chạy lại là thấy)
- `scripts/data/game_data.gd`: đổi `TIME_SCALE` để ngày trôi nhanh/chậm hơn.
- `scripts/features/student_stats.gd`: đổi `gpa` và `drl` ban đầu.
- Chạy game, bấm phím **1 / 2 / 3** để cộng trừ điểm rèn luyện, **4 / 5** để sang ngày / tuần sau.

## 7. Làm một feature mới
1. Copy `scripts/features/_mau_feature.gd` thành file mới, ví dụ `diem_danh.gd`.
2. Sửa nội dung file.
3. Thêm 1 dòng vào `scripts/features/registry.gd`.
4. F5 chạy thử. Làm việc nhóm bằng Git: xem `HUONG_DAN_GIT.md`.

## 8. Khi gặp lỗi
1. Đọc **dòng đỏ đầu tiên** ở Output hoặc Debugger. Nó thường ghi rõ file và số dòng.
2. Nếu báo `Invalid access ... on a base object of type 'Nil'` nghĩa là biến đó đang **rỗng**, chưa được tạo. Kiểm tra lại thứ tự khởi tạo.
3. Nếu báo `Identifier ... not declared` là gõ sai tên hoặc chưa khai báo biến/hàm.
4. Vẫn không rõ: chép nguyên dòng lỗi và file liên quan để hỏi nhóm hoặc AI.
