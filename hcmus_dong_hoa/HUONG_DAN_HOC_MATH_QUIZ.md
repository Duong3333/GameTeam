# Học code Math Quiz từng bước

Tài liệu này giải thích phần quiz theo cách đơn giản. Bạn không cần hiểu toàn bộ project cùng lúc.

## 1. Hai file cần đọc trước

- `scripts/systems/math_questions.gd`: nạp đề JSON, kiểm tra trạng thái xác minh và chấm câu trả lời an toàn.
- `scripts/features/math_quiz.gd`: chạy vòng quiz, nhận thao tác người chơi, tính điểm, trừ GPA và hiển thị giao diện.

Một cách ghi nhớ nhanh: **math_questions tạo nội dung; math_quiz điều khiển trò chơi**.

## 2. Luồng chạy của một vòng quiz

1. Người chơi đến gần Cô Toán và nhấn `E`.
2. `start_round()` đặt lại điểm và combo, rồi tải ngẫu nhiên một đề giữa kỳ của môn đã chọn.
3. `next_question()` hiển thị lần lượt 5 câu của đề đó.
4. Người chơi nhập câu trả lời ngắn và nhấn **NỘP ĐÁP ÁN**.
5. `submit_answer()` chỉ tự chấm câu đã xác minh với `grading_method: exact`. Câu thủ công đã xác minh hiện đáp án/lời giải nhưng không tính điểm; câu chưa xác minh chỉ hiện cảnh báo.
6. `finish_answer()` mở nút sang câu tiếp theo.
7. Sau câu cuối, `end_round()` tính điểm trên thang 10 và xét GPA.

## 3. Cách chọn đề

Trong `math_questions.gd`, `EXAM_PATHS` ánh xạ mã môn tới các tệp JSON. `load_random_exam()` chỉ tải đề có đúng `subject_code` và `exam_type`; hiện tất cả đề trong ngân hàng thuộc nhóm `midterm`. Không tự thêm đề cuối kỳ nếu chưa có nguồn tương ứng.

## 4. Cấu trúc một câu hỏi trong ngân hàng

Mỗi câu được đọc trực tiếp từ một phần tử JSON:

```gdscript
{
  "id": "CSLT_EXAM_001_Q01",
  "question_text": "Nội dung để hiển thị",
  "answer_type": "code_output",
  "accepted_answers": ["3 5 11"],
  "grading_method": "exact",
  "verified": true,
  "source_file": "...",
  "source_page": 1
}
```

Trình chấm không dùng `eval` hoặc chạy code người chơi. C++ `code_output` được so sánh theo từng dòng sau khi chuẩn hóa khoảng trắng; thứ tự dòng được giữ nguyên. Biểu thức chỉ so khớp với đáp án đã liệt kê, không dùng bộ biến đổi đại số.

## 5. Thay đổi mức điểm

Trong `math_quiz.gd`, mở `points_for_answer()`:

- `base_points`: điểm nền theo trường `points` của câu hỏi.
- `time_bonus`: điểm thưởng dựa trên thời gian còn lại.
- `combo_bonus`: điểm thưởng khi trả lời đúng liên tiếp.

Tổng điểm bằng ba khoản trên cộng lại; điểm nền lấy từ trường `points` của câu hỏi.

## 6. Thay đổi mức trừ GPA

Tìm hằng số ở đầu `math_quiz.gd`:

```gdscript
const GPA_PENALTY := 0.1
```

Giá trị `0.1` nghĩa là trừ 0,10 GPA. Trong `apply_gpa_penalty()`, quiz chỉ bị phạt khi điểm thang 10 thấp hơn 5. Điểm quiz được tính theo tỷ lệ câu đúng trong số câu được tự chấm, không tính câu cần chấm thủ công. Chỉ trừ GPA khi toàn bộ đề được tự chấm; đề có câu thủ công hoặc chưa xác minh sẽ không ảnh hưởng GPA.

GPA được `StudentStats.set_gpa()` giới hạn trong khoảng 0.0–4.0.

## 7. Đọc các hàm quan trọng theo thứ tự

### Trong `math_questions.gd`

- `load_random_exam()` — nạp ngẫu nhiên một đề trong nhóm đã chọn.
- `grade_answer()` — chấm câu đã xác minh theo kiểu đáp án được hỗ trợ.
- `_normalize_output()` — chuẩn hóa khoảng trắng mà không đổi thứ tự dòng C++.

### Trong `math_quiz.gd`

- `start_round()` — đặt lại biến đầu vòng.
- `next_question()` — hiển thị câu kế tiếp.
- `submit_answer()` — nhận và chấm hoặc đánh dấu câu cần xem thủ công.
- `points_for_answer()` — tính điểm.
- `end_round()` — kết thúc và hiển thị kết quả.
- `apply_gpa_penalty()` — xét trừ GPA.
- `get_rank_for_accuracy()` — đổi tỷ lệ đúng thành hạng và số sao.

## 8. Cách tự kiểm tra trên Godot

1. Mở `project.godot` bằng đúng phiên bản Godot mà project của bạn dùng.
2. Nhấn F6 hoặc F5 để chạy.
3. Đến gần Cô Toán và nhấn `E`.
4. Chọn từng môn; xác nhận đề được lấy từ đúng nhóm giữa kỳ và có 5 câu theo thứ tự gốc.
5. Thử câu `code_output` đúng/sai, câu `manual`, và câu chưa xác minh; chỉ câu đủ điều kiện mới được tính điểm.
6. Xác nhận code người chơi không bị thực thi và đề có câu chưa chấm tự động không làm giảm GPA.

Nếu Godot báo lỗi, mở **Debugger → Errors** và đọc dòng đầu tiên báo lỗi cú pháp. Lỗi ở một script được preload có thể làm script khác báo lỗi dây chuyền.
