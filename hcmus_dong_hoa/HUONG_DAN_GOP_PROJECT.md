# Ghi chú gộp ba nguồn project

Project này được ghép từ:
- `GameTeam-da923`: giữ bản đồ, câu cá, cửa công trình và năm nhân vật có tên.
- `GameTeam-Quiz`: lấy Quiz Toán và ngân hàng câu hỏi (feature nhảy múa đã được gỡ bỏ).
- Các file rời đi kèm: dùng `main.gd`, `main.tscn`, `project.godot`, font và tài liệu nhóm làm file cấu hình/đầu vào của project.

## Các điểm tích hợp quan trọng
1. `scripts/draw/newcharacters.gd` chỉ giữ chuỗi kế thừa tương thích sau `characters.gd`; NPC có tên được tạo, cập nhật và vẽ duy nhất bởi feature `scripts/features/newcharacters.gd`.
2. `maps/campus_overlay.gd` vẽ NPC thường và NPC quiz; feature NPC có tên vẽ lớp riêng để tránh tạo/vẽ trùng.
3. `maps/campus_data.gd` giữ `get_doorways()` của bản GameTeam và thêm `QUIZ_NPC_POS` của bản Quiz.
4. `maps/campus_setup.gd` tạo NPC quiz; `maps/campus_update.gd` không cho NPC quiz tự đi lang thang.
5. `features/registry.gd` đăng ký gameplay dùng chung; `maps/registry.gd` đăng ký module nội dung bản đồ như phòng lab B4.2. Module bản đồ được tải trước khi dựng va chạm và minimap.

## Mở project
Mở Godot 4.7 -> Import -> chọn `project.godot` trong thư mục `hcmus_dong_hoa` -> F5.

Lưu ý: chạy thử project bằng Godot 4.7 sau khi gộp thay đổi để xác nhận runtime.
