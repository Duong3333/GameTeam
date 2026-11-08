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
- **XEM ĐỀ** mở trình xem nội dung toàn đề, có cuộn, chuyển câu, phóng to/thu nhỏ và bật/tắt toàn màn hình. Nội dung được dựng từ LaTeX/JSON nên chữ sắc nét khi phóng to; đây không phải PDF gốc và không bảo toàn tuyệt đối dàn trang. Project hiện không có PDF nguồn; muốn xem bản gốc cần bổ sung các PDF tương ứng.
- **Cơ sở lập trình:** nút **IDE / CODE** mở CodeEdit với số dòng, tô màu cú pháp C++, thụt lề, ô stdin và ô output/đáp án. Nút Run hiện từ chối thực thi vì project chưa có sandbox cách ly; không chạy mã người chơi bằng quyền của game. Nguồn không có test case an toàn nên test chưa được chạy. Câu yêu cầu kết quả chương trình nhập kết quả trong IDE; mã tự luận được lưu để chấm theo rubric hoặc kiểm tra thủ công.
- IDE có nền sáng, điều chỉnh cỡ chữ bằng **A− / A+**. Bài bỏ trống nhận 0 điểm ở phần có thể chấm tự động; tiêu chí không đủ dữ liệu đáng tin cậy vẫn được đánh dấu cần kiểm tra thủ công.
- **Vi tích phân:** nhập tối đa 4 chữ số vào bốn ô; dấu âm bật bằng nút **±** (hoặc phím `-`), dấu phẩy đặt tại vị trí con trỏ bằng phím `,`/`.`. Ví dụ nhập được `4,01` và `-0,01`; dấu phẩy được chuẩn hóa khi chấm. Câu hỏi chưa có dữ liệu chấm tự động đáng tin cậy vẫn cần kiểm tra thủ công.
- Chỉ kết quả số nguyên, số thập phân có dung sai nguồn, và output chương trình đã xác minh mới được chấm tự động. Không so khớp văn bản/biểu thức tự luận để suy đoán tính đúng; câu manual, code tự luận, biểu thức toán học và câu chưa xác minh được đánh dấu cần kiểm tra thủ công. Dữ liệu rubric mở rộng theo câu có thể khai báo `grading_rubric` gồm `id`, `label`, `weight`, `method`, `answer_type`, `accepted_answers`, `tolerance` và tùy chọn `response_line`. Hiện câu chưa có rubric đủ tin cậy không được tự chấm.
- Tỷ lệ tính trên tổng trọng số rubric có thể chấm được; điểm thang 10 và hệ số GPA nằm trong `quiz_exam_bank/grading_config.json`. GPA hiện tại của sinh viên vẫn tuân thủ quy tắc sẵn có: chỉ trừ 0.1 khi toàn bộ đề chấm được và điểm dưới 5/10.

## Tính năng được tích hợp
- Đếm ngược cho từng câu; thanh thời gian đổi màu khi gần hết giờ.
- Điểm thưởng theo tốc độ và combo khi trả lời đúng liên tiếp.
- Hiển thị đáp án nguồn và lời giải sau khi nộp câu hỏi.
- Màn hình tổng kết và xếp hạng sao.
- Cô Toán phản hồi bằng lời thoại.
- Nhấn **NỘP ĐÁP ÁN** để trả lời; **Enter/Space** để qua câu sau; **Esc** đóng bảng và giữ nguyên vòng để quay lại làm tiếp.

## File chính của quiz
- `scripts/features/math_quiz.gd`: tương tác NPC, bộ đếm giờ và luồng chơi.
- `scripts/features/quiz_pdf_viewer.gd`, `quiz_code_editor.gd`, `quiz_math_input.gd`, `quiz_result_screen.gd`: các giao diện xem đề, IDE, nhập đáp số ngắn và kết quả.
- `scripts/systems/math_questions.gd`: nạp đề JSON và chuyển LaTeX sang văn bản dễ đọc.
- `scripts/systems/quiz_grading_engine.gd`: chấm rubric có trọng số và quy đổi điểm.
- `scripts/systems/math_questions.gd` cũng chuyển LaTeX thông dụng (phân số, căn, chỉ số, ký hiệu và đoạn mã) thành dạng dễ đọc khi hiển thị trong game.
Quiz được đăng ký trong `scripts/features/registry.gd`. Các feature khác của bản GameTeam chính được giữ nguyên.

## Ngân hàng đề nguồn
- `quiz_exam_bank/`: ngân hàng LaTeX/JSON được đưa vào project, gồm 10 đề luyện tập (5 Cơ sở lập trình, 5 Vi tích phân 1), 50 câu hỏi và dữ liệu kiểm toán đáp án.
- `quiz_exam_bank/source_manifest.json` và `quiz_exam_bank/answer_audit.json`: ánh xạ nguồn và tình trạng xác minh đáp án.
- Tài liệu gốc ghi là **đề luyện tập**. Metadata phân loại nhóm ôn giữa kỳ và ngày thi theo xác nhận của người dùng; điều này không biến tài liệu thành đề thi chính thức.
- `answer_audit.json` ghi 49/50 câu đã xác minh; câu chưa xác minh và các câu có `grading_method: manual` không được tự chấm.
