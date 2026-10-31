# Học code Math Quiz từng bước

Tài liệu này giải thích phần quiz theo cách đơn giản. Bạn không cần hiểu toàn bộ project cùng lúc.

## 1. Hai file cần đọc trước

- `scripts/systems/math_questions.gd`: tạo câu hỏi, đáp án, lời giải và nguồn tham khảo.
- `scripts/features/math_quiz.gd`: chạy vòng quiz, nhận thao tác người chơi, tính điểm, trừ GPA và hiển thị giao diện.

Một cách ghi nhớ nhanh: **math_questions tạo nội dung; math_quiz điều khiển trò chơi**.

## 2. Luồng chạy của một vòng quiz

1. Người chơi đến gần Cô Toán và nhấn `E`.
2. `start_round()` đặt lại điểm và combo; mỗi lượt có đúng 5 câu.
3. `next_question()` gọi `MathQuestions.generate(...)` để tạo câu hỏi.
4. Người chơi chọn A/B/C/D hoặc nhấn phím 1/2/3/4.
5. `choose()` kiểm tra đáp án. Nếu đúng, `points_for_answer()` tính điểm thưởng; nếu sai, `wrong_answer()` hiển thị đáp án đúng.
6. `finish_answer()` mở nút sang câu tiếp theo.
7. Sau câu cuối, `end_round()` tính điểm trên thang 10 và xét GPA.

## 3. Cách chọn loại câu hỏi

Trong `math_questions.gd`, hãy tìm hàm `generate()`:

- Câu 1-2: phép cộng/trừ/nhân/chia cơ bản.
- Câu 3: chọn ngẫu nhiên câu Vi tích phân mức cơ bản.
- Câu 4: chọn câu mức vận dụng đạo hàm/tích phân.
- Câu 5: chọn câu khó hơn về đổi biến hoặc tích phân từng phần.

Mỗi câu trong `CALCULUS_QUESTIONS` cần có trường `difficulty`: `1` cho câu 3, `2` cho câu 4, `3` cho câu 5.

## 4. Cấu trúc một câu hỏi trong ngân hàng

Mỗi câu là một `Dictionary`, tương tự một nhóm trường dữ liệu:

```gdscript
{
	"text": "Câu hỏi hiển thị",
	"answer": "Đáp án đúng",
	"options": ["Đáp án A", "Đáp án B", "Đáp án C", "Đáp án D"],
	"kind": "Chủ đề toán",
	"difficulty": 1,
	"source": "Nguồn tham khảo",
	"explanation": "Giải thích đáp án"
}
```

Các đáp án trong `options` sẽ được trộn ngẫu nhiên. Vì vậy `math_questions.gd` tự tìm vị trí đáp án đúng và trả về khóa `correct`. Khi thêm câu mới, nhớ đảm bảo `answer` phải trùng chính xác với một phần tử trong `options`.

## 5. Thay đổi mức điểm

Trong `math_quiz.gd`, mở `points_for_answer()`:

- `base_points`: điểm nền theo số thứ tự câu.
- `time_bonus`: điểm thưởng dựa trên thời gian còn lại.
- `combo_bonus`: điểm thưởng khi trả lời đúng liên tiếp.

Tổng điểm bằng ba khoản trên cộng lại.

## 6. Thay đổi mức trừ GPA

Tìm hằng số ở đầu `math_quiz.gd`:

```gdscript
const GPA_PENALTY := 0.1
```

Giá trị `0.1` nghĩa là trừ 0,10 GPA. Trong `apply_gpa_penalty()`, quiz chỉ bị phạt khi điểm thang 10 thấp hơn 5. Điểm quiz được tính theo tỷ lệ số câu đúng, không phải theo điểm thưởng tốc độ/combo.

Ví dụ: đúng 2 trên 5 câu thì điểm quiz là `2 / 5 * 10 = 4.0`, nên bị trừ GPA. GPA được `StudentStats.set_gpa()` giới hạn trong khoảng 0.0–4.0.

## 7. Đọc các hàm quan trọng theo thứ tự

### Trong `math_questions.gd`

- `round_length()` — trả về 5 câu mỗi lượt.
- `generate()` — chọn loại câu theo số thứ tự.
- `_make_arithmetic()` — tạo phép tính số học.
- `_pick_from_bank()` — chọn câu trong ngân hàng và trộn đáp án.
- `_pack_numeric()` — tạo 4 lựa chọn cho câu số học.

### Trong `math_quiz.gd`

- `start_round()` — đặt lại biến đầu vòng.
- `next_question()` — hiển thị câu kế tiếp.
- `choose()` — nhận câu trả lời.
- `points_for_answer()` — tính điểm.
- `end_round()` — kết thúc và hiển thị kết quả.
- `apply_gpa_penalty()` — xét trừ GPA.
- `get_rank_for_accuracy()` — đổi tỷ lệ đúng thành hạng và số sao.

## 8. Cách tự kiểm tra trên Godot

1. Mở `project.godot` bằng đúng phiên bản Godot mà project của bạn dùng.
2. Nhấn F6 hoặc F5 để chạy.
3. Đến gần Cô Toán và nhấn `E`.
4. Kiểm tra mỗi lượt luôn có 5 câu; câu 1-2 là số học và câu 3-5 là Vi tích phân tăng dần độ khó.
5. Thử trả lời đúng, sai và để hết giờ.
6. Chơi một vòng có tỷ lệ đúng dưới 50% để kiểm tra GPA giảm, rồi chơi vòng đạt ít nhất 50% để kiểm tra không bị trừ.

Nếu Godot báo lỗi, mở **Debugger → Errors** và đọc dòng đầu tiên báo lỗi cú pháp. Lỗi ở một script được preload có thể làm script khác báo lỗi dây chuyền.
