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
Toàn bộ mã khuôn viên gốc (dữ liệu, khởi tạo, cập nhật, cảnh và công trình) nằm trong `scripts/maps/campus_*.gd`. Nội dung riêng của từng tòa/khu vực như phòng lab B4.2 cũng nằm trong `scripts/maps/` và đăng ký trong `scripts/maps/registry.gd`. Cơ chế gameplay dùng chung (như câu cá hoặc cửa ra vào) vẫn ở `scripts/features/`.

## Các chức năng đã tích hợp
- Nhân vật có tên: Thầy LTC, Thầy LĐK, Bác bảo vệ, Bác giữ xe và Cô lao công. Đến gần, nhấn E để trò chuyện.
- Đi vào / ra công trình: đến cửa và nhấn E.
- Câu cá: đứng sát hồ đài phun nước giữa các tòa nhà và nhấn E; nhấn B để mở sổ cá.
- Quiz Toán: đến NPC Cô Toán (có dấu ?) và nhấn E.
- Hướng dẫn chi tiết: `HUONG_DAN_QUIZ.md` và `HUONG_DAN_HOC_MATH_QUIZ.md`.
