extends RefCounted
# NGÂN HÀNG ĐỀ ĐỘC LẬP: CƠ SỞ LẬP TRÌNH (LÝ THUYẾT) - chỉ ABCD (multiple_choice) và trả lời ngắn (fill_blank).
# Không có tự luận: tự luận C++ chỉ dành cho Cơ sở lập trình THỰC HÀNH (luồng quiz lập trình của math_quiz.gd).
#
# Nguồn: chủ đề lấy theo mục lục học liệu mở learncpp.com (Arrays, Functions, Recursion, Pointers, Loops, Scope);
# câu hỏi được soạn lại, không sao chép nguyên văn. Trường "source" chỉ ghi CHỦ ĐỀ tham khảo, chưa trích dẫn số trang.
# "answer_status":
#   verified_by_compile  = đáp án được kiểm bằng chương trình C++ thật (g++ 13.3, -std=c++17) khớp với đáp án trong ngân hàng
#   needs_review         = câu khái niệm không kiểm bằng biên dịch được, cần người có chuyên môn duyệt trước khi dùng chính thức
#
# TODO_LINK_NPC:CSLT_THEORY - hiện ngân hàng này chỉ được class_attendance.gd dùng cho tiết lý thuyết ở phòng F_CSLT.
# Khi có NPC giảng viên lý thuyết CSLT, AI sau nối tại đây (hàm all_questions / random_round); không tạo NPC khi chưa được yêu cầu.

const COURSE_ID := "CSLT_THEORY"

const QUESTIONS := [
	{
		"id": "th_arr_01",
		"type": "multiple_choice",
		"topic": "Mảng",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int a[5] = {10, 20, 30, 40, 50};\ncout << a[2];",
		"options": ["20", "30", "40", "Lỗi biên dịch"],
		"answer": 1,
		"explanation": "Chỉ số mảng bắt đầu từ 0 nên a[2] là phần tử thứ ba, bằng 30.",
		"source": "learncpp.com — chủ đề Arrays",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_arr_02",
		"type": "multiple_choice",
		"topic": "Mảng",
		"prompt": "Với khai báo int a[5]; các chỉ số hợp lệ của mảng là gì?",
		"code": "int a[5];",
		"options": ["1 đến 5", "0 đến 5", "0 đến 4", "1 đến 4"],
		"answer": 2,
		"explanation": "Mảng 5 phần tử có chỉ số từ 0 đến 4.",
		"source": "learncpp.com — chủ đề Arrays",
		"answer_status": "needs_review"
	},
	{
		"id": "th_arr_03",
		"type": "multiple_choice",
		"topic": "Mảng",
		"prompt": "Với int a[5]; việc truy cập a[5] dẫn tới điều gì?",
		"code": "int a[5] = {1, 2, 3, 4, 5};\nint x = a[5];",
		"options": ["Luôn nhận giá trị 0", "Hành vi không xác định (undefined behavior)", "Trình biên dịch luôn báo lỗi", "Tự động mở rộng mảng"],
		"answer": 1,
		"explanation": "C++ không kiểm tra biên của mảng thô; truy cập ngoài biên là hành vi không xác định.",
		"source": "learncpp.com — chủ đề Arrays",
		"answer_status": "needs_review"
	},
	{
		"id": "th_arr_04",
		"type": "multiple_choice",
		"topic": "Mảng",
		"prompt": "Biểu thức nào cho số phần tử của mảng arr (kiểu int arr[6])?",
		"code": "int arr[6];",
		"options": ["sizeof(arr)", "sizeof(arr) / sizeof(arr[0])", "sizeof(arr[0])", "arr.size()"],
		"answer": 1,
		"explanation": "Tổng kích thước chia kích thước một phần tử cho ra số phần tử (6).",
		"source": "learncpp.com — chủ đề Arrays",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_fn_01",
		"type": "multiple_choice",
		"topic": "Hàm",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "void inc(int x) { x++; }\nint main() {\n  int n = 5;\n  inc(n);\n  cout << n;\n}",
		"options": ["5", "6", "0", "Lỗi biên dịch"],
		"answer": 0,
		"explanation": "Tham số truyền theo giá trị nên hàm chỉ tăng bản sao; n vẫn là 5.",
		"source": "learncpp.com — chủ đề Functions",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_fn_02",
		"type": "multiple_choice",
		"topic": "Hàm",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "void inc(int& x) { x++; }\nint main() {\n  int n = 5;\n  inc(n);\n  cout << n;\n}",
		"options": ["5", "6", "0", "Lỗi biên dịch"],
		"answer": 1,
		"explanation": "Tham chiếu int& cho phép hàm sửa trực tiếp biến n, nên n thành 6.",
		"source": "learncpp.com — chủ đề Functions",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_fn_03",
		"type": "multiple_choice",
		"topic": "Hàm",
		"prompt": "Kiểu trả về nào dùng cho hàm không trả về giá trị?",
		"code": "",
		"options": ["null", "void", "empty", "int"],
		"answer": 1,
		"explanation": "Hàm không trả về giá trị được khai báo với kiểu void.",
		"source": "learncpp.com — chủ đề Functions",
		"answer_status": "needs_review"
	},
	{
		"id": "th_rec_01",
		"type": "multiple_choice",
		"topic": "Đệ quy",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int f(int n) {\n  if (n <= 1) return 1;\n  return n * f(n - 1);\n}\nint main() { cout << f(4); }",
		"options": ["10", "16", "24", "120"],
		"answer": 2,
		"explanation": "f(4) = 4 * 3 * 2 * 1 = 24.",
		"source": "learncpp.com — chủ đề Recursion",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_rec_02",
		"type": "multiple_choice",
		"topic": "Đệ quy",
		"prompt": "Vai trò của điều kiện dừng (base case) trong hàm đệ quy là gì?",
		"code": "",
		"options": ["Tăng tốc độ chạy", "Chấm dứt chuỗi lời gọi đệ quy", "Khai báo biến toàn cục", "Giảm dung lượng mã nguồn"],
		"answer": 1,
		"explanation": "Thiếu điều kiện dừng, hàm gọi chính nó mãi cho tới khi tràn ngăn xếp.",
		"source": "learncpp.com — chủ đề Recursion",
		"answer_status": "needs_review"
	},
	{
		"id": "th_ptr_01",
		"type": "multiple_choice",
		"topic": "Con trỏ",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int x = 7;\nint* p = &x;\n*p = 9;\ncout << x;",
		"options": ["7", "9", "Địa chỉ của x", "Lỗi biên dịch"],
		"answer": 1,
		"explanation": "*p = 9 ghi vào ô nhớ mà p trỏ tới, cũng chính là biến x.",
		"source": "learncpp.com — chủ đề Pointers",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_ptr_02",
		"type": "multiple_choice",
		"topic": "Con trỏ",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int a[3] = {1, 2, 3};\nint* p = a;\ncout << *(p + 1);",
		"options": ["1", "2", "3", "Địa chỉ phần tử a[1]"],
		"answer": 1,
		"explanation": "p trỏ tới a[0]; p + 1 trỏ tới a[1], giá trị là 2.",
		"source": "learncpp.com — chủ đề Pointers",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_ptr_03",
		"type": "multiple_choice",
		"topic": "Con trỏ",
		"prompt": "Giải tham chiếu (dereference) con trỏ null như int* p = nullptr; cout << *p; gây ra điều gì?",
		"code": "int* p = nullptr;\ncout << *p;",
		"options": ["In ra 0", "Hành vi không xác định (thường làm chương trình sập)", "Luôn báo lỗi khi biên dịch", "In ra chuỗi rỗng"],
		"answer": 1,
		"explanation": "Giải tham chiếu con trỏ null là hành vi không xác định.",
		"source": "learncpp.com — chủ đề Pointers (null pointers)",
		"answer_status": "needs_review"
	},
	{
		"id": "th_loop_01",
		"type": "multiple_choice",
		"topic": "Vòng lặp",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int s = 0;\nfor (int i = 1; i <= 4; i++) s += i;\ncout << s;",
		"options": ["4", "6", "10", "24"],
		"answer": 2,
		"explanation": "1 + 2 + 3 + 4 = 10.",
		"source": "learncpp.com — chủ đề Loops",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_scope_01",
		"type": "multiple_choice",
		"topic": "Phạm vi",
		"prompt": "Đoạn code in ra giá trị nào?",
		"code": "int x = 1;\n{\n  int x = 2;\n}\ncout << x;",
		"options": ["1", "2", "3", "Lỗi biên dịch"],
		"answer": 0,
		"explanation": "x trong khối {} chỉ tồn tại trong khối đó; x ngoài khối vẫn là 1.",
		"source": "learncpp.com — chủ đề Scope",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_arr_01",
		"type": "fill_blank",
		"topic": "Mảng",
		"prompt": "Điền chỉ số để in phần tử cuối (giá trị 8).",
		"code": "int a[4] = {5, 6, 7, 8};\ncout << a[____];",
		"answers": ["3"],
		"explanation": "Mảng 4 phần tử có chỉ số 0..3; phần tử cuối là a[3].",
		"source": "learncpp.com — chủ đề Arrays",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_rec_01",
		"type": "fill_blank",
		"topic": "Đệ quy",
		"prompt": "Hàm fib(0)=0, fib(1)=1, fib(n)=fib(n-1)+fib(n-2). Giá trị fib(5) là bao nhiêu?",
		"code": "int fib(int n) {\n  if (n <= 1) return n;\n  return fib(n - 1) + fib(n - 2);\n}",
		"answers": ["5"],
		"explanation": "Dãy: 0, 1, 1, 2, 3, 5 nên fib(5) = 5.",
		"source": "learncpp.com — chủ đề Recursion",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_ptr_01",
		"type": "fill_blank",
		"topic": "Con trỏ",
		"prompt": "Đoạn code in ra giá trị nào? (nhập số)",
		"code": "int x = 4;\nint* p = &x;\n*p = *p * 3;\ncout << x;",
		"answers": ["12"],
		"explanation": "*p * 3 = 12 được ghi lại vào x.",
		"source": "learncpp.com — chủ đề Pointers",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_ptr_02",
		"type": "fill_blank",
		"topic": "Con trỏ",
		"prompt": "Điền toán tử lấy địa chỉ của biến x.",
		"code": "int x = 5;\nint* p = ____x;",
		"answers": ["&"],
		"explanation": "Toán tử & lấy địa chỉ của biến.",
		"source": "learncpp.com — chủ đề Pointers",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_loop_01",
		"type": "fill_blank",
		"topic": "Vòng lặp",
		"prompt": "Đoạn code in ra giá trị nào? (nhập số)",
		"code": "int c = 0;\nfor (int i = 0; i < 10; i += 3) c++;\ncout << c;",
		"answers": ["4"],
		"explanation": "i nhận các giá trị 0, 3, 6, 9 nên vòng lặp chạy 4 lần.",
		"source": "learncpp.com — chủ đề Loops",
		"answer_status": "verified_by_compile"
	},
	{
		"id": "th_s_fn_01",
		"type": "fill_blank",
		"topic": "Hàm",
		"prompt": "Đoạn code in ra giá trị nào? (nhập số)",
		"code": "void sw(int& a, int& b) {\n  int t = a; a = b; b = t;\n}\nint main() {\n  int a = 1, b = 2;\n  sw(a, b);\n  cout << a;\n}",
		"answers": ["2"],
		"explanation": "Hàm hoán đổi hai biến qua tham chiếu nên a nhận giá trị 2.",
		"source": "learncpp.com — chủ đề Functions",
		"answer_status": "verified_by_compile"
	},
]

static func all_questions() -> Array:
	return QUESTIONS.duplicate(true)

# Chọn ngẫu nhiên "count" câu, luôn có ít nhất 1 câu trả lời ngắn nếu ngân hàng có.
static func random_round(count: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = all_questions()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var picked: Array = []
	for q in pool:
		if picked.size() >= count:
			break
		picked.append(q)
	var has_short := false
	for q in picked:
		if str(q.get("type", "")) == "fill_blank":
			has_short = true
	if not has_short and not picked.is_empty():
		for q in pool:
			if str(q.get("type", "")) == "fill_blank":
				picked[picked.size() - 1] = q
				break
	return picked
