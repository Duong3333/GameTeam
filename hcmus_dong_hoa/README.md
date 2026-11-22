# Một ngày ở HCMUS - Đông Hòa

Game 2D góc nhìn từ trên xuống, vẽ bằng code, về một ngày của sinh viên ở khuôn viên HCMUS - Đông Hòa. Làm bằng **Godot 4.7** (cả nhóm dùng cùng phiên bản này).

## Chạy game
1. Cài Godot 4.7.
2. Mở Godot -> Import -> chọn `project.godot` trong thư mục này.
3. Bấm F5.

## Tài liệu cho nhóm
- [HUONG_DAN.md](HUONG_DAN.md): cấu trúc code, cách thêm chức năng, âm thanh, quy ước chung.
- [HUONG_DAN_GIT.md](HUONG_DAN_GIT.md): quy trình làm việc nhóm bằng Git (mỗi người một nhánh, một feature).

## Thêm chức năng mới trong 3 bước
1. Copy `scripts/features/_mau_feature.gd` thành file mới trong `scripts/features/`.
2. Thêm 1 dòng vào `scripts/features/registry.gd`.
3. Chạy thử, rồi tạo Pull Request.

## Bản đồ và module bản đồ
Toàn bộ mã khuôn viên gốc (dữ liệu, khởi tạo, cập nhật, cảnh và công trình) nằm trong `scripts/maps/campus_*.gd`. Nội dung riêng của từng tòa/khu vực như phòng lab B4.2 cũng nằm trong `scripts/maps/` và đăng ký trong `scripts/maps/registry.gd`. Cơ chế gameplay dùng chung như cửa ra vào vẫn ở `scripts/features/`.

## Các chức năng đã tích hợp
- Nhân vật có tên: Thầy LTC, Thầy LĐK, Bác bảo vệ, Bác giữ xe và Cô lao công. Đến gần, nhấn E để trò chuyện.
- Lịch game hiển thị theo thứ và tuần học. Kỳ giữa kỳ diễn ra trong tuần 8–9: Cơ sở lập trình với Thầy LĐK ở tuần 8, Vi tích phân 1 với Thầy LTC ở tuần 9. Mỗi lần thi chọn ngẫu nhiên một đề của môn.
- Chế độ Admin: nhấn **Esc** trong game, chọn **Thời gian**; bảng tua thời gian gọn ở giữa màn hình cho phép chọn tuần, thứ, giờ.
- Đi vào / ra công trình: đến cửa và nhấn E.
- Đánh trêu NPC: đứng gần NPC, nhấn **H** để đánh trêu hoặc giữ để đấm liên hoàn; NPC khóc hoặc giận, bấm **C** để nhân vật của bạn khóc.
- Luyện tập Quiz Toán: đến NPC Cô Toán (có dấu ?) và nhấn E; hai kỳ thi giữa kỳ chỉ mở từ đúng thầy trong tuần thi của môn.
- Hướng dẫn chi tiết: `HUONG_DAN.md`, `HUONG_DAN_QUIZ.md` và `HUONG_DAN_HOC_MATH_QUIZ.md`.
