# Ghi chú gộp ba nguồn project

Project này được ghép từ:
- `GameTeam-da923`: giữ bản đồ, câu cá, cửa công trình và năm nhân vật có tên.
- `GameTeam-Quiz`: lấy Quiz Toán, ngân hàng câu hỏi và feature nhảy múa.
- Các file rời đi kèm: dùng `main.gd`, `main.tscn`, `project.godot`, font và tài liệu nhóm làm file cấu hình/đầu vào của project.

## Các điểm tích hợp quan trọng
1. `scripts/draw/newcharacters.gd` được đưa vào chuỗi kế thừa sau `characters.gd`, vì script này ghi đè `spawn_npcs()` và `update_npcs()` và gọi `super()`. Không đăng ký nó trong `registry.gd`.
2. `overlay.gd` kế thừa `newcharacters.gd` và phân biệt NPC có `role`, NPC quiz và NPC thường khi vẽ.
3. `game_data.gd` giữ `get_doorways()` của bản GameTeam và thêm `QUIZ_NPC_POS` của bản Quiz.
4. `world_setup.gd` tạo NPC quiz; `world_update.gd` không cho NPC quiz tự đi lang thang.
5. `registry.gd` bật lại câu cá và đăng ký HUD, sổ tay, cửa công trình, nhảy múa, Quiz Toán.

## Mở project
Mở Godot 4.7 -> Import -> chọn `project.godot` trong thư mục `hcmus_dong_hoa` -> F5.

Lưu ý: môi trường xử lý hiện tại không có Godot 4.7 để chạy game trực tiếp, vì vậy project đã được kiểm tra tĩnh về file, đường dẫn tài nguyên và các phần gộp, nhưng cần mở bằng Godot trên máy bạn để xác nhận runtime.
