# Ngân hàng đề Quiz

## 1. Phạm vi và nguồn

Ngân hàng được tạo **chỉ từ hai tệp người dùng cung cấp**:

- `02_De_luyen_tap.zip`: 10 đề luyện tập, gồm 5 đề Cơ sở lập trình và 5 đề Vi tích phân 1.
- `03_Dap_an.zip`: 10 tài liệu đáp án, ghép theo cùng môn và cùng số đề.

Mỗi đề có PDF và tệp LaTeX `.tex`. Không sử dụng Internet, Google Drive hay nguồn thứ ba. Tài liệu gốc tự ghi chú là tài liệu biên soạn độc lập, không phải đề thi chính thức của trường. Trong JSON, `answer_status: "official"` chỉ có nghĩa là đáp án được trích từ file đáp án đi kèm trong bộ tài liệu, không khẳng định đây là đáp án chính thức do trường ban hành.

Các bộ đề luyện tập được gán cho lịch thi trong game theo cấu hình hiện tại: Cơ sở lập trình tuần 8, Vi tích phân 1 tuần 9. Phân loại được ghi trong `source_manifest.json` và từng file JSON câu hỏi; tên nguồn vẫn được giữ nguyên là đề luyện tập. Hiện không có đề cuối kỳ trong bộ dữ liệu.

## 2. Thống kê

- Số đề: **10**.
- Số câu trích xuất: **50** (5 câu/đề).
- Có lời giải trong file đáp án: **50**.
- `answer_status=official`: **50**.
- `answer_status=ai_solved`: **0**.
- Đã xác minh: **49**.
- Chưa xác minh / có vấn đề: **1**.
- Thiếu đáp án (`missing`): **0**.
- Đủ điều kiện tự chấm theo quy tắc an toàn: **4**.
- Chỉ chấm thủ công/không tính điểm trong game: **46**.

Chi tiết và ngoại lệ được ghi trong `answer_audit.json`.

## 3. Cấu trúc

```text
quiz_exam_bank/
├── README.md
├── source_manifest.json
├── answer_audit.json
├── latex/
│   ├── exam_001.tex ... exam_010.tex
├── questions/
│   ├── exam_001.json ... exam_010.json
└── assets/
    ├── formulas/       # Công thức được lưu bằng LaTeX trong JSON và .tex
    ├── images/         # Logo được trích từ PDF gốc
    └── original_tex/    # Bản .tex nguồn đề và đáp án để kiểm toán
```

`exam_001` đến `exam_005` là Cơ sở lập trình Đề 01-05; `exam_006` đến `exam_010` là Vi tích phân 1 Đề 01-05. Ánh xạ đầy đủ nằm trong `source_manifest.json`.

## 4. Cấu trúc mỗi câu hỏi

Các trường cốt lõi:

- `id`: mã ổn định, ví dụ `CSLT_EXAM_001_Q01`.
- `question_text`: văn bản đọc được, giữ nội dung công thức ở dạng gần văn bản.
- `question_latex`: nội dung câu hỏi gốc ở dạng LaTeX, giữ biểu thức và code listing.
- `answer_type`: `integer`, `decimal`, `text`, `expression`, `code_output`, hoặc `short_code`.
- `official_answer`: đáp án ngắn / mã tham khảo lấy từ file đáp án. Với câu code, lưu code tham khảo nguyên văn từ `lstlisting`.
- `accepted_answers`: các đáp án chấp nhận được đã nêu rõ; với `short_code` để rỗng vì có nhiều lời giải đúng và cần chấm theo tiêu chí.
- `solution_latex`: lời giải gốc trích từ file đáp án.
- `grading_method`: `exact` chỉ dùng cho kết quả đầu ra có thể so sánh chính xác; `manual` dùng cho code, lập luận và biểu thức cần xét tương đương.
- `tolerance`: mặc định 0; không tự đặt dung sai cho câu gần đúng.
- `answer_status`: trạng thái nguồn đáp án (`official`, `ai_solved`, `verified_ai`, `missing`).
- `answer_source`, `source_file`, `source_page`, `verified`: dấu vết nguồn và trạng thái kiểm chứng.
- `grading_rubric` (tùy chọn): danh sách tiêu chí có `id`, `label`, `weight`, `method`, đáp án được chấp nhận và kiểu câu trả lời. Có thể dùng `response_line` (chỉ số dòng từ 0) cho bài trình bày nhiều dòng. Chỉ tiêu chí có dữ liệu hỗ trợ được phép chấm tự động; tiêu chí thiếu đáp án đáng tin cậy phải để kiểm tra thủ công.

Có thêm `source_pdf`, `answer_pdf`, `answer_page` để truy nguyên về trang PDF chính xác. Những trường bổ sung như `verification_note` và `ai_review_latex` giải thích các ngoại lệ.

Các quy tắc quy đổi điểm được cấu hình trong `grading_config.json`: `scale_10`, `gpa_multiplier` và `gpa_max`. Trình chấm hiện hỗ trợ nhiều đáp án số được khai báo, dung sai số và output C++ đã biết. Số thập phân nhập bằng dấu phẩy hoặc dấu chấm, dấu trừ Unicode và khoảng trắng đầu/cuối đều được chuẩn hóa trước khi so sánh; không so sánh văn bản/biểu thức để đoán tính tương đương và không thực thi mã người chơi. Nếu câu hỏi chưa có rubric đủ tin cậy, hệ thống đánh dấu cần rà soát thay vì cho điểm.

## 5. Lưu ý về đáp án sai trong nguồn

`VTP1_EXAM_005_Q01` có lỗi trong file đáp án gốc. Nguồn cho rằng không tồn tại cặp `(a,b)` vì ghi đạo hàm phải của `x^2+b` tại `x=1` là `2+b`. Đạo hàm đúng là `2x`, nên tại `x=1` bằng `2`. Kết hợp điều kiện liên tục `b=a+1` với điều kiện khả vi `a=2`, suy ra **`(a,b)=(2,3)`**.

Vì yêu cầu bảo toàn nguồn, `official_answer` và `solution_latex` vẫn giữ nội dung đáp án gốc; `verified=false` báo lỗi nguồn; đáp án hiệu chỉnh được lưu riêng trong `ai_review_latex` với `ai_review_status=verified_ai`. Không được ghi đè lời giải gốc hoặc tự đổi trạng thái nguồn thành `official` cho phần hiệu chỉnh.

## 6. Kiểm thử C++ và chấm tự động

Đã lấy 22 code listing tham khảo trong các file đáp án, ghép vào đơn vị biên dịch kiểm tra, biên dịch bằng `g++ -std=c++11 -Wall -Wextra -pedantic`, rồi chạy các smoke test cho hàm và kết quả mẫu; biên dịch và kiểm thử đều đạt. Đây là kiểm tra mã tham khảo từ tài liệu, không phải thực thi mã người chơi gửi.

Không nên chấm `short_code` bằng so khớp chuỗi. Dùng test case cố định / rubric hoặc chấm thủ công. Không thực thi mã C++ tùy ý của người chơi. Với câu Vi tích phân, `grading_method=manual` cho biểu thức và bài nhiều bước; chỉ bật so khớp biểu thức tương đương sau khi bộ so sánh đại số được kiểm chứng trên từng dạng bài. Không biến câu `missing` thành câu tự chấm; hiện tại không có câu missing.

## 7. LaTeX

Mười tệp trong `latex/` là mã nguồn đề gốc được đưa vào bộ ngân hàng; chỉ đường dẫn logo bị thiếu trong ZIP đã được đổi sang `assets/images/institution_logo.png`. Các câu được trích vào JSON giữ biểu thức LaTeX và môi trường code listing. Có thể biên dịch các tệp đề bằng XeLaTeX từ thư mục gốc gói.

Trong game, `question_latex` và `solution_latex` được chuyển sang ký hiệu dễ đọc để tránh hiện dấu `$` và lệnh LaTeX. Nút **XEM ĐỀ** mở trình xem cuộn và phóng to nội dung câu hỏi, từng câu một. Đây là phương án dựng lại từ văn bản/vector, không bảo toàn dàn trang nguyên bản; các PDF nguồn không được lưu trong thư mục ngân hàng của project.
