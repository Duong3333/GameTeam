# Quy tắc lượt thi chính thức

## Phạm vi

Lượt thi được quản lý riêng theo cặp `mã môn + loại kỳ thi` (ví dụ `CSLT_midterm`, `VTP1_final`). Vì vậy, thi giữa kỳ một môn không khóa môn khác hoặc kỳ thi cuối kỳ.

## Khi nào một lượt được tính?

- Chỉ sau khi đề đã tải hợp lệ và quiz đã chuyển thành công sang màn hình `PLAY` mới ghi `used = true`.
- Mở game, đi lại trong campus, nói chuyện với giảng viên hoặc xem menu ôn tập không tự tiêu tốn lượt thi.
- Ngay khi màn hình làm bài đã mở, trạng thái `in_progress` được ghi xuống `user://official_exam_attempts.json` trước khi trả quyền điều khiển cho người chơi.
- Thoát bằng ESC/nút đóng trong lúc làm bài đổi trạng thái thành `abandoned`, nhưng vẫn giữ `used = true`. Đóng game đột ngột cũng vẫn bị khóa vì `in_progress` đã được lưu.
- Nộp xong đổi trạng thái thành `completed`; `used` vẫn là `true`. Không có nút làm lại.

## Khởi đầu một game mới và tiếp tục game cũ

Menu chính của project đặt `Engine` metadata `daily_us_start_mode` thành `new` hoặc `continue`.
- `new`: xóa lịch sử lượt thi của playthrough cũ để nhân vật/game save mới có lượt thi riêng.
- `continue`: giữ nguyên lịch sử, nên đóng/mở game hoặc tiếp tục save không cấp lại lượt thi.

Không tự reset khi metadata không tồn tại (ví dụ chạy thẳng scene từ editor), để tránh vô tình mở lại lượt thi đã sử dụng.

## Kiểm thử hồi quy cần chạy trong Godot

1. Chọn Chơi mới, đi đến tuần thi nhưng chưa nói chuyện với giảng viên; thoát/mở lại bằng Tiếp tục: kỳ thi vẫn khả dụng.
2. Bắt đầu thi giữa kỳ CSLT, nhấn ESC: NPC báo đã sử dụng lượt; không thể bắt đầu lại.
3. Bắt đầu thi giữa kỳ, đóng game ngay trong lúc làm: vào lại bằng Tiếp tục vẫn bị khóa.
4. Hoàn thành bài thi: vẫn bị khóa sau khi vào lại.
5. Thi CSLT giữa kỳ không khóa VTP1 giữa kỳ hoặc VTP1 cuối kỳ.
6. Chọn Chơi mới: lịch sử của playthrough trước được reset; lượt thi khả dụng ở đúng tuần thi.
7. Làm quiz thư viện/quiz trên lớp: không tạo bản ghi lượt thi chính thức.

Lưu ý: kiểm thử hồi quy trên cần được chạy trong Godot thực tế. Môi trường tạo patch này không có Godot runtime.
