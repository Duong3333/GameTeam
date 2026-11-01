# Hướng dẫn Quiz Toán - GameTeam

## Cách chạy
1. Giải nén file ZIP của dự án.
2. Mở Godot 4.x, import `hcmus_dong_hoa/project.godot`.
3. Chạy project bằng F5 (hoặc chạy `main.tscn` nếu mở trực tiếp scene).

## Cách bắt đầu
- Di chuyển bằng W/A/S/D tới NPC áo tím **Cô Toán** cạnh **Tòa F** và nhấn **E**.
- Chọn **Cơ sở lập trình** hoặc **Vi tích phân 1** để lấy ngẫu nhiên một đề giữa kỳ thuộc đúng môn.

## Cấu trúc quiz
- Mỗi vòng tải một đề ngẫu nhiên có **5 câu**, giữ nguyên thứ tự câu trong đề.
- Lịch game hiển thị theo **thứ · tuần**. Hai tuần giữa kỳ là tuần **8–9**: Thầy LĐK thi Cơ sở lập trình trong tuần 8, Thầy LTC thi Vi tích phân 1 trong tuần 9. Trong tuần thi, tới gần đúng thầy và nhấn **E** để bắt đầu.
- Mỗi lần vào thi sẽ chọn ngẫu nhiên một trong các đề luyện tập của đúng môn.
- Cô Toán vẫn cho chọn đề để luyện tập độc lập, không gắn với lịch thi của hai thầy.
- Nhấn **Esc** để mở menu tạm dừng, chọn **Thời gian** để mở bảng Admin nhỏ giữa màn hình; chọn tuần, thứ, giờ và nhấn **CHUYỂN TỚI**. Bảng sẽ tạm dừng game; nhấn **ĐÓNG** để quay lại menu Esc.
- Hiện chưa có dữ liệu đề cuối kỳ nên game không hiển thị lựa chọn cuối kỳ.
- Người chơi nhập câu trả lời ngắn. Chỉ câu có đáp án đã xác minh và `grading_method: exact` mới được tự chấm; câu thủ công đã xác minh sẽ hiện đáp án/lời giải nhưng không tính điểm. Câu chưa xác minh chỉ hiện cảnh báo, không tiết lộ đáp án nguồn.
- Công thức trong câu hỏi và lời giải được chuyển sang ký hiệu dễ đọc thay vì hiện mã LaTeX; nhấn **XEM ĐỀ** để mở nội dung câu hỏi ở khung lớn và cuộn khi cần. Khung này trình bày lại dữ liệu LaTeX, không phải ảnh quét nguyên bản của đề.
- Hiện có 4/50 câu đủ điều kiện tự chấm; 46 câu còn lại không tính điểm tự động. Điểm cuối lượt chỉ tính trên câu được chấm; GPA chỉ bị trừ nếu toàn bộ đề tự chấm được, nên ngân hàng hiện tại không làm giảm GPA.
- Không thực thi code người chơi; đầu ra C++ được so sánh sau khi chuẩn hóa khoảng trắng và vẫn giữ nguyên thứ tự dòng.

## Tính năng được tích hợp
- Đếm ngược cho từng câu; thanh thời gian đổi màu khi gần hết giờ.
- Điểm thưởng theo tốc độ và combo khi trả lời đúng liên tiếp.
- Hiển thị đáp án nguồn và lời giải sau khi nộp câu hỏi.
- Màn hình tổng kết và xếp hạng sao.
- Cô Toán phản hồi bằng lời thoại.
- Nhấn **NỘP ĐÁP ÁN** để trả lời; **Enter/Space** để qua câu sau; **Esc** đóng bảng và giữ nguyên vòng để quay lại làm tiếp.

## File chính của quiz
- `scripts/features/math_quiz.gd`: tương tác NPC, giao diện, bộ đếm giờ, điểm số và luồng chơi.
- `scripts/systems/math_questions.gd`: nạp đề JSON đúng môn/kỳ thi và chấm câu có thể tự động xác minh.
- `scripts/systems/math_questions.gd` cũng chuyển LaTeX thông dụng (phân số, căn, chỉ số, ký hiệu và đoạn mã) thành dạng dễ đọc khi hiển thị trong game.
Quiz được đăng ký trong `scripts/features/registry.gd`. Các feature khác của bản GameTeam chính được giữ nguyên.

## Ngân hàng đề nguồn
- `quiz_exam_bank/`: ngân hàng LaTeX/JSON được đưa vào project, gồm 10 đề luyện tập (5 Cơ sở lập trình, 5 Vi tích phân 1), 50 câu hỏi và dữ liệu kiểm toán đáp án.
- `quiz_exam_bank/source_manifest.json` và `quiz_exam_bank/answer_audit.json`: ánh xạ nguồn và tình trạng xác minh đáp án.
- Tài liệu gốc ghi là **đề luyện tập**. Metadata phân loại nhóm ôn giữa kỳ và ngày thi theo xác nhận của người dùng; điều này không biến tài liệu thành đề thi chính thức.
- `answer_audit.json` ghi 49/50 câu đã xác minh; câu chưa xác minh và các câu có `grading_method: manual` không được tự chấm.
