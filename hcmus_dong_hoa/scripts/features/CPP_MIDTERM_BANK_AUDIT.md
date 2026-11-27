# Kiểm tra ngân hàng đề giữa kỳ Cơ sở lập trình

## Quy tắc sinh đề

- Mỗi đề có đúng 3 câu, tổng tối đa 10 điểm, thời gian 90 phút.
- Chọn đúng 3 nhóm chủ đề lớn khác nhau từ `LOOP`, `FUNCTION`, `ADVANCED_FUNCTION`, `ARRAY`, `STRUCT_FILE`.
- Mỗi đề có 1–2 câu thuộc hai nhóm khó `ARRAY` và `STRUCT_FILE` cộng lại; mỗi nhóm đóng góp tối đa một câu.
- Mỗi nhóm chỉ xuất hiện tối đa một lần trong cùng đề.
- Trong `FUNCTION`, chỉ chọn một trong `P1` hoặc `P2`.
- Trong `ARRAY`, chỉ chọn một trong `P1`, `P2`, `P3`.
- Trong `STRUCT_FILE`, chỉ chọn một phần đang đủ dữ liệu và có testcase.
- Điểm 3 câu lần lượt là 3, 3 và 4 theo thứ tự câu được sinh; tổng luôn bằng 10.
- Người chơi chỉ viết các định nghĩa hàm trong một vùng soạn thảo. Prototype, struct, thư viện được phép và `main()`/harness do hệ thống thêm vào.

## Ngân hàng hiện có sau khi rút gọn theo độ khó

| Nhóm | Câu hỏi đang bật | Testcase | Ghi chú
|---|---:|---:|---|
| Loop | 6 | 69 | Các hàm đơn, ngắn; giữ pool rộng. |
| Function P1 | 2 | 18 | Chỉ giữ tổ hợp và phương trình bậc hai. |
| Function P2 | 6 | 69 | Ưu tiên một hàm, code ngắn/trung bình; loại hồi quy và xoắn ốc dài. |
| Advanced Function | 4 | 26 | Tách thư viện thời gian thành 4 nhiệm vụ nhỏ; mỗi đề chọn một nhiệm vụ. |
| Array P1/P2/P3 | 3 | 40 | Mỗi P là một bài thư viện tổng hợp, giữ một lựa chọn. |
| Struct/File Part 3/4 | 2 | 17 | Mỗi Part giữ một bài; nội dung file I/O vốn dài và nhiều hàm. |
| **Tổng** | **23** | **239** | |

Mỗi câu có metadata `complexity` và `estimated_student_code_lines`. Câu càng dài/nhiều hàm/phụ thuộc thì pool được giới hạn nhỏ hơn. `display_prompt` là phần mô tả ngắn trên UI; prototype chỉ xuất hiện một lần, không lặp lại toàn bộ mô tả.

Đề thi lấy 3 câu từ 3 nhóm lớn khác nhau, tổng 10 điểm (3 + 3 + 4). Có 1–2 câu Array/Struct cộng lại; các P/Part trong cùng một nhóm lớn loại trừ nhau trong cùng một đề.

## Kiểm tra đầu ra

- Các câu trả về chuỗi (ước số, bảng số, xoắn ốc) được kiểm tra bằng so sánh chuỗi chính xác ngay trong C++ harness.
- Câu Struct/File kiểm tra nội dung file thực tế: thứ tự dòng, dấu phân cách, điểm có một chữ số thập phân, tìm kiếm phân biệt hoa/thường, file rỗng và trường hợp không tìm thấy.
- 4 nhiệm vụ thời gian mới có 26 testcase; đã biên dịch và chạy lại bằng GCC C++17: **26/26 đạt**.
- Các testcase giữ lại của ngân hàng cũ là tập con của 294 testcase đã được kiểm chứng ở bản trước; các câu bị loại khỏi pool không được sinh vào đề giữa kỳ.
- Testcase được dựng theo đặc tả; bài nộp Moodle không được dùng làm đáp án chuẩn.

## Nội dung tạm loại khỏi lựa chọn

1. `Tính toán biểu thức` (Function P1): bản văn bản được dán bị mất định dạng số mũ; công thức hiển thị và ví dụ không đủ để suy ra duy nhất biểu thức.
2. `Đọc số` (Function P1): quy tắc dùng `le` và cách đọc các nhóm 3 chữ số bằng 0 chưa được đặc tả đầy đủ.
3. `Phân số: so sánh và đọc/ghi file` (Struct/File): đề Part 2 phụ thuộc struct và API phân số của Part 1 nhưng các khai báo/hiện thực tiên quyết không có trong tài liệu được cung cấp.

Các câu này được giữ trong danh sách loại trừ để không vô tình xuất hiện trong đề. Có thể bổ sung sau khi có bản Markdown gốc/đầy đủ.

## Kết quả kiểm tra kỹ thuật

- Trước khi rút gọn, bộ 28 câu/294 testcase đã được kiểm thử bằng GCC C++17.
- Sau khi rút gọn, ngân hàng giữa kỳ còn 23 lựa chọn/239 testcase; 26 testcase của 4 nhiệm vụ thời gian mới đã được chạy lại và đạt toàn bộ. Các câu còn lại không thay đổi harness/expected so với bản đã kiểm thử.
- Logic chọn đề giữ nguyên: 3 nhóm lớn khác nhau, không trùng P trong cùng nhóm, tổng điểm luôn là 10.
- Chưa thể chạy Godot Editor/runtime hoặc xác nhận chạy trên Windows ngay trong môi trường dựng gói này. Vì vậy cần mở project trong Godot để kiểm tra tích hợp UI và thực hiện một lượt thi thử trên máy Windows có GCC.

## GCC offline

Gói có kèm `tools/install_gcc.ps1` và `tools/NOTICE.txt`. Script tải WinLibs GCC một lần trên máy Windows có Internet và cài vào `scripts/features/tools/gcc/`. Bản zip này không chứa binary GCC. Khi phát hành game, cần chép đầy đủ thư mục GCC cạnh bản game ở vị trí mà `cpp_local_gcc_provider.gd` tìm kiếm. Xem thêm `CPP_IDE_OFFLINE_SETUP.md`.

Lưu ý: timeout của runner không phải sandbox bảo mật đầy đủ; không dùng runner này để thực thi code không tin cậy trên máy chủ dùng chung.


## Điều chỉnh số câu khó và thời lượng (27/11/2026)
- Mỗi đề chọn đúng 3 nhóm lớn khác nhau.
- Trong đó có từ 1 đến 2 câu thuộc hai nhóm khó `ARRAY` và `STRUCT_FILE` cộng lại; mỗi nhóm chỉ đóng góp tối đa một câu.
- Các câu còn lại được chọn từ `LOOP`, `FUNCTION`, `ADVANCED_FUNCTION`.
- Thời lượng thi CSLT thực hành: 90 phút (5.400 giây).
