# Ghi chú gộp ba nguồn project

Project này được ghép từ:
- `GameTeam-da923`: giữ bản đồ, câu cá, cửa công trình và năm nhân vật có tên.
- `GameTeam-Quiz`: lấy Quiz Toán, ngân hàng câu hỏi và feature nhảy múa.
- Các file rời đi kèm: dùng `main.gd`, `main.tscn`, `project.godot`, font và tài liệu nhóm làm file cấu hình/đầu vào của project.

## Các điểm tích hợp quan trọng
1. `scripts/draw/newcharacters.gd` được đưa vào chuỗi kế thừa sau `characters.gd`, vì script này ghi đè `spawn_npcs()` và `update_npcs()` và gọi `super()`. Không đăng ký nó trong `registry.gd`.
2. `maps/campus_overlay.gd` vẽ NPC thường và NPC quiz; feature NPC có tên vẽ lớp riêng để tránh tạo/vẽ trùng và giữ đúng phương án của cả hai nhánh.
3. `maps/campus_data.gd` giữ `get_doorways()` của bản GameTeam và thêm `QUIZ_NPC_POS` của bản Quiz.
4. `maps/campus_setup.gd` tạo NPC quiz; `maps/campus_update.gd` không cho NPC quiz tự đi lang thang.
5. `features/registry.gd` đăng ký gameplay dùng chung; `maps/registry.gd` đăng ký module nội dung bản đồ như phòng lab B4.2. Module bản đồ được tải trước khi dựng va chạm và minimap.

## Mở project
Mở Godot 4.7 -> Import -> chọn `project.godot` trong thư mục `hcmus_dong_hoa` -> F5.

Lưu ý: sau khi gộp thay đổi, cần chạy thử project bằng Godot 4.7 để xác nhận runtime. Nếu máy hiện tại không có Godot, hãy kiểm tra các file và đường dẫn tài nguyên trước khi mở trên máy khác.
