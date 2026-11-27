# Chính sách rút gọn ngân hàng đề Cơ sở lập trình

Đề giữa kỳ vẫn có 3 câu thuộc 3 nhóm lớn khác nhau, tổng 10 điểm. Các P trong cùng nhóm lớn là loại trừ nhau.

## Pool hiện hành
- Loop: giữ 6 câu đơn hàm, ngắn.
- Function P1: giữ 2 câu đại diện (tổ hợp, phương trình bậc hai).
- Function P2: giữ 6 câu đơn hàm/ngắn; loại hồi quy và các bài xoắn ốc dài khỏi pool giữa kỳ.
- Advanced Function: chia bài thư viện thời gian thành 4 nhiệm vụ nhỏ; đề chỉ lấy 1 nhiệm vụ.
- Array và Struct/File được xem là nhóm khó: mỗi đề chỉ có 1–2 câu thuộc hai nhóm này cộng lại. Nếu cả hai nhóm cùng xuất hiện thì mỗi nhóm đóng góp đúng 1 câu. Mỗi đề vẫn có đúng 3 câu từ 3 nhóm lớn khác nhau; các câu còn lại lấy từ Loop, Function hoặc Advanced Function. Mỗi P/Part của Array và Struct/File là một nhiệm vụ tổng hợp riêng, không ghép nhiều P trong cùng đề.

Thời gian thi giữa kỳ Cơ sở lập trình thực hành là 90 phút (5.400 giây). Đồng hồ được lấy từ cấu hình đề; `math_quiz.gd` dùng 90 phút làm mặc định riêng cho mã môn CSLT nếu cấu hình thiếu thời lượng. Kỳ thi Vi tích phân giữ thời lượng cấu hình riêng.

Mỗi câu có metadata `complexity` và `estimated_student_code_lines`. Pool nhỏ hơn khi mã cần viết dài hoặc có nhiều hàm phụ thuộc. `display_prompt` là mô tả rút gọn dùng trong UI; prototypes vẫn được hiển thị riêng.

# Chính sách testcase
Expected output phải được suy ra từ đặc tả và kiểm tra độc lập; không dùng bài nộp Moodle của người chơi làm đáp án chuẩn. Câu có đặc tả chưa rõ phải để disabled hoặc nằm trong excluded list.
