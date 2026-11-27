extends RefCounted
# NGAN HANG CAU HOI MINI C++.
# Chu de tham khao W3Schools C++ Tutorial / Exercises.
# Cau hoi trong game duoc bien soan lai, khong sao chep nguyen van quiz cua W3Schools.

const QUESTIONS := [
	# -------------------- MULTIPLE CHOICE --------------------
	{
		"id": "mcq_output_01", "type": "multiple_choice", "topic": "Output",
		"prompt": "Bạn muốn in giá trị của biến total ra màn hình. Câu lệnh nào phù hợp?",
		"code": "int total = 25;",
		"options": ["cin >> total;", "cout << total;", "print(total);", "output(total);"],
		"answer": 1,
		"explanation": "cout dùng để xuất dữ liệu; toán tử << đưa dữ liệu tới cout."
	},
	{
		"id": "mcq_type_01", "type": "multiple_choice", "topic": "Data types",
		"prompt": "Kiểu dữ liệu nào phù hợp để lưu một số thực như 3.75?",
		"code": "",
		"options": ["int", "char", "double", "bool"],
		"answer": 2,
		"explanation": "double lưu số thực với độ chính xác kép."
	},
	{
		"id": "mcq_operator_01", "type": "multiple_choice", "topic": "Operators",
		"prompt": "Toán tử nào dùng để so sánh hai giá trị có bằng nhau hay không?",
		"code": "",
		"options": ["=", "==", "!=", "%"],
		"answer": 1,
		"explanation": "== là toán tử so sánh bằng; = là toán tử gán."
	},
	{
		"id": "mcq_input_01", "type": "multiple_choice", "topic": "User input",
		"prompt": "Để đọc một số nguyên từ bàn phím vào biến n, bạn dùng câu lệnh nào?",
		"code": "int n;",
		"options": ["cout << n;", "cin >> n;", "cin << n;", "read(n);"],
		"answer": 1,
		"explanation": "cin kết hợp với >> để nhận dữ liệu từ bàn phím."
	},
	{
		"id": "mcq_array_01", "type": "multiple_choice", "topic": "Arrays",
		"prompt": "Với mảng int a[4] = {8, 6, 4, 2}; phần tử đầu tiên có chỉ số nào?",
		"code": "",
		"options": ["0", "1", "3", "4"],
		"answer": 0,
		"explanation": "Chỉ số mảng trong C++ bắt đầu từ 0, nên phần tử đầu tiên là a[0]."
	},
	{
		"id": "mcq_function_01", "type": "multiple_choice", "topic": "Functions",
		"prompt": "Từ khóa nào dùng để trả kết quả từ một hàm về nơi gọi hàm?",
		"code": "",
		"options": ["break", "continue", "return", "using"],
		"answer": 2,
		"explanation": "return kết thúc hàm và có thể gửi một giá trị về nơi gọi."
	},

	# -------------------- REORDER CODE --------------------
	{
		"id": "order_main_01", "type": "reorder", "topic": "Syntax / Output",
		"prompt": "Sắp xếp các dòng sau để tạo chương trình C++ in ra số 7.",
		"lines": ["#include <iostream>", "using namespace std;", "int main() {", "    cout << 7;", "    return 0;", "}"],
		"explanation": "Một chương trình cơ bản cần khai báo thư viện, khai báo main, thực hiện lệnh rồi kết thúc hàm."
	},
	{
		"id": "order_if_01", "type": "reorder", "topic": "If / Else",
		"prompt": "Sắp xếp các dòng để kiểm tra x có phải số dương hay không.",
		"lines": ["int x = 8;", "if (x > 0) {", "    cout << \"So duong\";", "}"],
		"explanation": "Lệnh if đứng trước khối lệnh được thực hiện khi điều kiện đúng."
	},
	{
		"id": "order_loop_01", "type": "reorder", "topic": "For loop",
		"prompt": "Sắp xếp các dòng để in các số từ 0 đến 2 bằng vòng lặp for.",
		"lines": ["for (int i = 0; i < 3; i++) {", "    cout << i;", "}"],
		"explanation": "Vòng for gồm phần khởi tạo, điều kiện, bước cập nhật và thân vòng lặp."
	},
	{
		"id": "order_function_01", "type": "reorder", "topic": "Functions",
		"prompt": "Sắp xếp các dòng để tạo hàm add trả về tổng hai số nguyên.",
		"lines": ["int add(int a, int b) {", "    return a + b;", "}"],
		"explanation": "Phần khai báo hàm đứng trước thân hàm; return trả tổng về nơi gọi."
	},
	{
		"id": "order_input_01", "type": "reorder", "topic": "User input / Output",
		"prompt": "Sắp xếp các dòng để nhập tuổi rồi in tuổi vừa nhập.",
		"lines": ["int age;", "cin >> age;", "cout << age;"],
		"explanation": "Khai báo biến trước, sau đó nhận dữ liệu bằng cin và xuất bằng cout."
	},
	{
		"id": "order_array_01", "type": "reorder", "topic": "Arrays / Loops",
		"prompt": "Sắp xếp các dòng để duyệt và in 3 phần tử của mảng a.",
		"lines": ["int a[3] = {2, 4, 6};", "for (int i = 0; i < 3; i++) {", "    cout << a[i];", "}"],
		"explanation": "Khai báo mảng trước, sau đó dùng vòng lặp và chỉ số i để truy cập từng phần tử."
	},

	# -------------------- FILL IN THE BLANK --------------------
	{
		"id": "fill_type_01", "type": "fill_blank", "topic": "Variables / Data types",
		"prompt": "Điền từ khóa còn thiếu để khai báo biến nguyên age.",
		"code": "____ age = 20;",
		"answers": ["int"],
		"explanation": "int là kiểu dữ liệu số nguyên trong C++."
	},
	{
		"id": "fill_output_01", "type": "fill_blank", "topic": "Output",
		"prompt": "Điền toán tử còn thiếu để đưa chuỗi ra cout.",
		"code": "cout ____ \"Hello\";",
		"answers": ["<<"],
		"explanation": "Toán tử << chuyển dữ liệu tới luồng xuất cout."
	},
	{
		"id": "fill_input_01", "type": "fill_blank", "topic": "User input",
		"prompt": "Điền toán tử còn thiếu để nhận dữ liệu vào biến n.",
		"code": "cin ____ n;",
		"answers": [">>"],
		"explanation": "Toán tử >> đọc dữ liệu từ cin vào biến n."
	},
	{
		"id": "fill_loop_01", "type": "fill_blank", "topic": "For loop",
		"prompt": "Điền biểu thức cập nhật để i tăng thêm 1 sau mỗi vòng lặp.",
		"code": "for (int i = 0; i < 5; ____ )",
		"answers": ["i++", "++i"],
		"explanation": "i++ hoặc ++i đều tăng i thêm 1 trong phần cập nhật của vòng for."
	},
	{
		"id": "fill_if_01", "type": "fill_blank", "topic": "If / Else",
		"prompt": "Điền toán tử để điều kiện đúng khi score lớn hơn hoặc bằng 5.",
		"code": "if (score ____ 5) {",
		"answers": [">="],
		"explanation": ">= nghĩa là lớn hơn hoặc bằng."
	},
	{
		"id": "fill_array_01", "type": "fill_blank", "topic": "Arrays",
		"prompt": "Điền chỉ số để truy cập phần tử đầu tiên của mảng.",
		"code": "int a[3] = {4, 5, 6};\ncout << a[____];",
		"answers": ["0"],
		"explanation": "Mảng C++ bắt đầu đánh chỉ số từ 0."
	}
]

static func all_questions() -> Array:
	return QUESTIONS.duplicate(true)
