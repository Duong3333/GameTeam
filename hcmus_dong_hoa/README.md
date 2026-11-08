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
- Chơi đơn hoặc online: chọn chế độ qua nút ở góc trên trái; form tạo/tham gia phòng chỉ hiện trong Multiplayer. Chế độ online đồng bộ di chuyển nhân vật; xem `HUONG_DAN.md` để biết cách kết nối.
- Luyện tập Quiz Toán: đến NPC Cô Toán (có dấu ?) và nhấn E; hai kỳ thi giữa kỳ chỉ mở từ đúng thầy trong tuần thi của môn.
- Bản thử chỉ đồng bộ vị trí/hướng nhân vật; các tính năng còn lại chưa chia sẻ giữa người chơi. Chơi khác mạng cần chạy relay server trên máy chủ có IP công khai và mở **UDP 2456** trên máy chủ; người chơi không cần mở cổng trên router. Cách chạy xem `HUONG_DAN.md`.
- Hướng dẫn chi tiết: `HUONG_DAN.md`, `HUONG_DAN_QUIZ.md` và `HUONG_DAN_HOC_MATH_QUIZ.md`.
