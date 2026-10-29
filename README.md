# Làm việc nhóm bằng Git (GitHub Desktop) - mỗi người 1 feature

## Ý tưởng chính
- Bản chung nằm trên GitHub, nhánh `main` là bản **luôn chạy được**. Không ai làm trực tiếp trên `main`.
- Mỗi người làm feature của mình trên **nhánh riêng**, xong thì gửi **Pull Request (PR)** để gộp vào `main`.
- Một feature = 1 file mới trong `scripts/features/` + 1 dòng trong `scripts/features/registry.gd`.
  Vì mỗi người tạo file riêng nên hầu như không đụng nhau. Chỗ duy nhất có thể đụng là `registry.gd` (xem phần "Xung đột").

## A. Làm một lần: lấy project về
1. Cài GitHub Desktop, đăng nhập. Chủ repo mời bạn ở GitHub: Settings -> Collaborators.
2. GitHub Desktop: **File -> Clone repository** -> chọn repo -> chọn thư mục máy -> Clone.
3. Mở Godot -> Import -> chọn `project.godot` trong thư mục vừa clone.

## B. Mỗi feature mới: quy trình 8 bước
**Bước 1. Lấy bản mới nhất.** Chọn nhánh `main` (nút Current Branch), bấm **Fetch origin**, nếu hiện **Pull origin** thì bấm tiếp.

**Bước 2. Tạo nhánh riêng.** Current Branch -> **New Branch** -> tên theo feature, không dấu, ví dụ `diem-danh`. Chọn "Create branch based on main".

**Bước 3. Viết feature.**
- Copy `scripts/features/_mau_feature.gd` thành `scripts/features/diem_danh.gd`, sửa nội dung.
- Mở `scripts/features/registry.gd`, thêm 1 dòng **phía trên dòng `# <<< thêm dòng mới`**:
  ```gdscript
  	"res://scripts/features/diem_danh.gd",
  ```
  (nhớ dấu phẩy cuối dòng). Đây là cách "include" - KHÔNG sửa `main.gd`.
- Chạy thử trong Godot (F5). Phải chạy được, không có lỗi đỏ ở ô Output.

**Bước 4. Commit.** Trong GitHub Desktop, cột trái liệt kê file đã đổi. Chỉ nên thấy file của bạn + `registry.gd`.
Nếu thấy file lạ (đặc biệt `main.gd`, `game_data.gd`...) mà bạn không cố ý sửa -> bấm chuột phải file -> **Discard changes**.
Ghi dòng mô tả ở ô Summary (vd `Thêm điểm danh`) -> **Commit to diem-danh**. Commit nhiều lần cũng được.

**Bước 5. Cập nhật nhánh theo main (làm trước khi gửi PR).**
Branch -> **Update from main** (hoặc "Merge into current branch" -> chọn `main`).
- Không báo gì = tốt. Chạy lại game một lần cho chắc.
- Báo xung đột -> xem phần C.

**Bước 6. Đẩy lên.** Bấm **Publish branch** (lần đầu) hoặc **Push origin** (các lần sau).

**Bước 7. Tạo Pull Request.** Bấm **Create Pull Request** (mở trang web GitHub) -> viết 2-3 dòng: feature làm gì, phím nào, cách thử -> Create.

**Bước 8. Gộp.** Một bạn khác xem qua và chạy thử nhánh đó. Ổn thì bấm **Merge pull request** trên web. Sau đó mọi người quay lại bước 1 để lấy `main` mới.

## C. Xung đột (conflict) là gì và sửa thế nào
Xảy ra khi 2 người cùng sửa **cùng vị trí** của 1 file, thường là `registry.gd` khi 2 người cùng thêm dòng ngay trên dòng `# <<< thêm dòng mới`.
Git không tự quyết nên đánh dấu trong file như sau:
```
<<<<<<< HEAD
	"res://scripts/features/diem_danh.gd",
=======
	"res://scripts/features/thu_vien.gd",
>>>>>>> main
```
Cách sửa: **giữ cả hai dòng, xóa 3 dòng đánh dấu** (`<<<<<<<`, `=======`, `>>>>>>>`):
```
	"res://scripts/features/diem_danh.gd",
	"res://scripts/features/thu_vien.gd",
```
Lưu file -> trong GitHub Desktop bấm **Continue merge / Commit merge** -> chạy lại game -> Push.
Không chắc thì nhắn nhóm, đừng bấm đại.

## D. Khi feature cần sửa file lõi
Đôi khi cần thêm 1 hằng số vào `game_data.gd` hoặc 1 biến vào `game_state.gd`. Quy tắc:
- Chỉ **thêm dòng mới**, không sửa/xóa dòng của người khác, không format lại cả file.
- Ghi trong PR: "đã thêm gì vào file nào".
- Báo nhóm trước nếu định sửa nhiều ở `main.gd`, `world_setup.gd`, `world_update.gd`.
- Dữ liệu riêng của feature (vd bảng cá, danh sách nhiệm vụ) để **trong file feature của bạn**, đừng đưa vào file lõi.

## E. Lỗi hay gặp
- **Game báo lỗi khi mở sau khi gộp**: đọc dòng đỏ đầu tiên ở Output, thường là typo đường dẫn trong `registry.gd` (game sẽ ghi cảnh báo "không tìm thấy ...").
- **Feature chạy trên máy mình nhưng không chạy sau khi gộp**: kiểm tra đã `Pull` main mới nhất và dòng trong `registry.gd` còn đủ.
- **Lỡ sửa nhầm trên `main`**: đừng commit. Tạo nhánh mới (Branch -> New Branch) thì thay đổi tự đi theo sang nhánh mới.
- **Muốn quay lại bản cũ**: tab **History** -> chuột phải commit -> **Revert changes in commit**.
