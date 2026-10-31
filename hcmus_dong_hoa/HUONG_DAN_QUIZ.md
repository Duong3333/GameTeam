# Hướng dẫn Quiz Toán - GameTeam

## Cách chạy
1. Giải nén file ZIP của dự án.
2. Mở Godot 4.x, import `hcmus_dong_hoa/project.godot`.
3. Chạy project bằng F5 (hoặc chạy `main.tscn` nếu mở trực tiếp scene).

## Cách bắt đầu
- Di chuyển bằng W/A/S/D tới NPC áo tím **Cô Toán** cạnh **Tòa F** và nhấn **E**.
- Chọn **BẮT ĐẦU QUIZ**. Người chơi không chọn độ khó; cấu trúc câu hỏi được quyết định tự động.

## Cấu trúc quiz
- Mỗi vòng luôn có **5 câu**.
- Câu 1-2 là phép cộng, trừ, nhân hoặc chia hết cơ bản.
- Câu 3 là câu Vi tích phân mức cơ bản; câu 4 nâng lên vận dụng đạo hàm/tích phân; câu 5 khó hơn, tập trung vào đổi biến hoặc tích phân từng phần.
- Câu Vi tích phân được chọn ngẫu nhiên trong ngân hàng theo các mức độ và chủ đề của `Giáo trình Vi tích phân 1 - HCMUS`; nguồn tham khảo được hiển thị cùng câu hỏi.

## Tính năng được tích hợp
- Đếm ngược cho từng câu; thanh thời gian đổi màu khi gần hết giờ.
- Điểm thưởng theo tốc độ và combo khi trả lời đúng liên tiếp.
- Hiển thị giải thích ngắn sau khi trả lời câu hỏi.
- Màn hình tổng kết và xếp hạng sao.
- Cô Toán phản hồi bằng lời thoại.
- Đáp án có thể chọn bằng chuột hoặc phím **1-4 / A-D**; **Enter/Space** để qua câu; **Esc** đóng bảng và giữ nguyên vòng để quay lại làm tiếp.

## File chính của quiz
- `scripts/features/math_quiz.gd`: tương tác NPC, giao diện, bộ đếm giờ, điểm số và luồng chơi.
- `scripts/systems/math_questions.gd`: sinh phép tính và ngân hàng câu hỏi THPT/Vi tích phân.
Quiz được đăng ký trong `scripts/features/registry.gd`. Các feature khác của bản GameTeam chính được giữ nguyên.
