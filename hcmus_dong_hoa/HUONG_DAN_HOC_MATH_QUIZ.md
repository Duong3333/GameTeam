# Học code Math Quiz từng bước

Tài liệu này giải thích phần quiz theo cách đơn giản. Bạn không cần hiểu toàn bộ project cùng lúc.

## 1. Các file cần đọc trước

- `scripts/systems/math_questions.gd`: nạp đề JSON, kiểm tra trạng thái xác minh và chấm câu trả lời an toàn.
- `scripts/systems/quiz_grading_engine.gd`: áp dụng rubric có trọng số và quy đổi điểm.
- `scripts/features/math_quiz.gd`: chạy vòng quiz, nhận thao tác người chơi, tính điểm, trừ GPA và hiển thị giao diện.
- `scripts/features/quiz_code_editor.gd`, `quiz_math_input.gd`, `quiz_pdf_viewer.gd`, `quiz_result_screen.gd`: giao diện riêng theo môn và màn hình kết quả.

Một cách ghi nhớ nhanh: **math_questions tạo nội dung; math_quiz điều khiển trò chơi**.

## 2. Luồng chạy của một vòng quiz

1. Người chơi đến gần Cô Toán và nhấn `E`.
2. `start_round()` đặt lại điểm và combo, rồi tải ngẫu nhiên một đề giữa kỳ của môn đã chọn.
3. `next_question()` hiển thị lần lượt 5 câu của đề đó.
4. C++ dùng IDE riêng; Vi tích phân nhập đáp số bằng tối đa bốn chữ số, có thể thêm dấu âm và dấu phẩy thập phân. Người chơi nộp câu trả lời từ màn hình tương ứng.
5. `quiz_grading_engine.gd` chỉ chấm kết quả số hoặc output chính xác có nguồn đã xác minh. Câu manual, code tự luận và biểu thức đại số cần kiểm tra thủ công; không chạy code người chơi.
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
  "points": 2.0,
  "verified": true,
  "source_file": "...",
  "source_page": 1
}
```

Rubric nhiều tiêu chí có thể được khai báo trực tiếp trong câu hỏi:

```json
"grading_rubric": [
  {
    "id": "result",
    "label": "Kết quả",
    "weight": 1.0,
    "method": "exact",
    "answer_type": "decimal",
    "accepted_answers": ["2.5"],
    "tolerance": 0.0,
    "response_line": 0
  }
]
```

`response_line` là chỉ số dòng từ 0; `exact` hỗ trợ số nguyên, số thập phân và output `code_output`; `numeric_tolerance` chỉ hỗ trợ số thập phân. Tiêu chí không đủ dữ liệu sẽ không được tính và được đánh dấu cần rà soát. Trình chấm không dùng `eval`, không chạy code người chơi và không kết luận biểu thức toán học đúng bằng so sánh chuỗi.

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

Giá trị `0.1` nghĩa là trừ 0,10 GPA. Trong `apply_gpa_penalty()`, quiz chỉ bị phạt khi điểm thang 10 thấp hơn 5. Điểm rubric bằng tổng điểm tiêu chí đạt chia tổng trọng số tiêu chí chấm được; chỉ trừ GPA hiện tại khi toàn bộ đề đủ dữ liệu chấm.

Hệ số quy đổi nằm trong `quiz_exam_bank/grading_config.json` (`scale_10`, `gpa_multiplier`, `gpa_max`); thay đổi tại đây mà không cần sửa giao diện.

## 7. Đọc các hàm quan trọng theo thứ tự

### Trong `math_questions.gd`

- `load_random_exam()` — nạp ngẫu nhiên một đề trong nhóm đã chọn.

### Trong `quiz_grading_engine.gd`

- `grade_question()` — chấm rubric và trả về tiêu chí đạt/chưa thể đánh giá.
- `grade_to_ten()` / `grade_to_gpa()` — áp dụng bảng quy đổi.

`grade_answer()` trong `math_questions.gd` giữ lại như wrapper tương thích với bộ chấm mới.

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
6. Xác nhận code người chơi không bị thực thi; câu manual cần rà soát không làm giảm GPA; kiểm tra tỷ lệ và quy đổi bằng cấu hình.

Nếu Godot báo lỗi, mở **Debugger → Errors** và đọc dòng đầu tiên báo lỗi cú pháp. Lỗi ở một script được preload có thể làm script khác báo lỗi dây chuyền.
