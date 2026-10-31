extends RefCounted
# Ngan hang cau hoi Quiz GameTeam.
# Cau 1-2 la so hoc co ban; cau 3-5 la cac cau Vi tich phan tang dan do kho.
# Cac cau Vi tich phan duoc bien soan moi dua tren chu de/muc trong giao trinh, khong chep nguyen van.

const CALCULUS_QUESTIONS := [
	{
		"text": "Tính lim(x→2) (x² - 4)/(x - 2).",
		"answer": "4",
		"options": ["4", "0", "2", "-2"],
		"kind": "Giới hạn",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, §2.1 - Giới hạn hàm số (tr. 31-34)",
		"explanation": "Phân tích x² - 4 = (x - 2)(x + 2); khi x khác 2, biểu thức bằng x + 2 nên giới hạn là 4."
	},
	{
		"text": "Tính lim(x→0) sin(x)/x.",
		"answer": "1",
		"options": ["1", "0", "-1", "Không tồn tại"],
		"kind": "Giới hạn lượng giác",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, Chương 2 - Giới hạn của hàm số",
		"explanation": "Đây là giới hạn lượng giác cơ bản: lim sin(x)/x = 1 khi x tiến đến 0 (x tính bằng radian)."
	},
	{
		"text": "Cho f(x)=x³ - 2x. Tính f'(2).",
		"answer": "10",
		"options": ["10", "8", "12", "4"],
		"kind": "Đạo hàm",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, §3.2.3 - Đạo hàm hàm sơ cấp (tr. 68)",
		"explanation": "f'(x)=3x²-2, do đó f'(2)=3·4-2=10."
	},
	{
		"text": "Tính đạo hàm của f(x)=ln(x) tại x=e.",
		"answer": "1/e",
		"options": ["1/e", "e", "0", "1"],
		"kind": "Đạo hàm hàm logarit",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, §3.2.3 - Đạo hàm hàm sơ cấp (tr. 68)",
		"explanation": "Vì (ln x)'=1/x với x>0 nên f'(e)=1/e."
	},
	{
		"text": "Nếu f(x)=sin(x), giá trị f'(π/3) bằng bao nhiêu?",
		"answer": "1/2",
		"options": ["1/2", "√3/2", "-1/2", "1"],
		"kind": "Đạo hàm lượng giác",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, §3.2.3 - Đạo hàm hàm sơ cấp (tr. 68)",
		"explanation": "f'(x)=cos(x), vì vậy f'(π/3)=cos(π/3)=1/2."
	},
	{
		"text": "Cho f(x)=e^(2x). Tính f'(0).",
		"answer": "2",
		"options": ["2", "1", "0", "e"],
		"kind": "Quy tắc đạo hàm hàm hợp",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §3.2.1 - Đạo hàm hàm hợp (tr. 65)",
		"explanation": "Theo quy tắc hàm hợp, f'(x)=2e^(2x), nên f'(0)=2."
	},
	{
		"text": "Độ dốc tiếp tuyến của y=x² tại x=3 là bao nhiêu?",
		"answer": "6",
		"options": ["6", "3", "9", "2"],
		"kind": "Tiếp tuyến và đạo hàm",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §3.1 - Đạo hàm (tr. 56-64)",
		"explanation": "Độ dốc tiếp tuyến bằng đạo hàm tại điểm đó. Với y=x² thì y'=2x, tại x=3 được 6."
	},
	{
		"text": "Tính ∫ từ 0 đến 2 của x dx.",
		"answer": "2",
		"options": ["2", "1", "4", "0"],
		"kind": "Tích phân xác định",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2 - Định lý cơ bản và Newton-Leibniz (tr. 121-125)",
		"explanation": "Một nguyên hàm của x là x²/2. Thay cận: 2²/2 - 0²/2 = 2."
	},
	{
		"text": "Tìm một nguyên hàm của 3x² + 2.",
		"answer": "x³ + 2x + C",
		"options": ["x³ + 2x + C", "3x + 2 + C", "x³ + 2 + C", "6x + C"],
		"kind": "Nguyên hàm",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2.1 - Nguyên hàm (tr. 121)",
		"explanation": "Lấy nguyên hàm từng hạng: ∫3x² dx=x³ và ∫2 dx=2x; thêm hằng số C."
	},
	{
		"text": "Tính ∫ từ 0 đến π của sin(x) dx.",
		"answer": "2",
		"options": ["2", "0", "1", "-2"],
		"kind": "Tích phân xác định",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2.2 - Công thức Newton-Leibniz (tr. 123)",
		"explanation": "Một nguyên hàm của sin(x) là -cos(x). Giá trị tích phân là -cos(π)-[-cos(0)]=2."
	},
	{
		"text": "Tính ∫ x cos(x) dx.",
		"answer": "x sin(x) + cos(x) + C",
		"options": ["x sin(x) + cos(x) + C", "x cos(x) + sin(x) + C", "sin(x) + C", "x sin(x) - cos(x) + C"],
		"kind": "Tích phân từng phần",
		"difficulty": 3,
		"source": "Giáo trình Vi tích phân 1, §5.3.2 - Tích phân từng phần (tr. 133-135)",
		"explanation": "Đặt u=x, dv=cos(x)dx. Khi đó ∫x cos(x)dx=x sin(x)-∫sin(x)dx=x sin(x)+cos(x)+C."
	},
	{
		"text": "Tính ∫ từ 0 đến 1 của (2x + 1) dx.",
		"answer": "2",
		"options": ["2", "1", "3", "1/2"],
		"kind": "Tích phân xác định",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2 - Tính chất tích phân và Newton-Leibniz (tr. 119-125)",
		"explanation": "Nguyên hàm là x²+x. Thay cận 1 và 0 được (1+1)-0=2."
	},
	{
		"text": "Tính lim(x→1) (x² - 1)/(x - 1).",
		"answer": "2",
		"options": ["2", "1", "0", "Không tồn tại"],
		"kind": "Giới hạn",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, §2.1 - Tính chất giới hạn (tr. 34-38)",
		"explanation": "Ta có x²-1=(x-1)(x+1), nên biểu thức bằng x+1 khi x khác 1; giới hạn bằng 2."
	},
	{
		"text": "Tính lim(x→0) (e^x - 1)/x.",
		"answer": "1",
		"options": ["1", "0", "e", "-1"],
		"kind": "Giới hạn và đạo hàm",
		"difficulty": 1,
		"source": "Giáo trình Vi tích phân 1, Chương 2-3 - Giới hạn và định nghĩa đạo hàm",
		"explanation": "Giới hạn này bằng đạo hàm của e^x tại 0; (e^x)'=e^x và e^0=1."
	},
	{
		"text": "Tìm giá trị nhỏ nhất của f(x)=x² - 4x + 1 trên ℝ.",
		"answer": "-3",
		"options": ["-3", "-4", "1", "0"],
		"kind": "Ứng dụng đạo hàm / cực trị",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §4.1-4.2 - Cực trị và tính chất hàm số (tr. 77-100)",
		"explanation": "Viết f(x)=(x-2)²-3. Vì bình phương không âm nên giá trị nhỏ nhất là -3 tại x=2."
	},
	{
		"text": "Theo công thức Newton-Leibniz, nếu F'=f thì ∫ từ a đến b f(x)dx bằng gì?",
		"answer": "F(b) - F(a)",
		"options": ["F(b) - F(a)", "F(a) + F(b)", "f(b) - f(a)", "F'(b) - F'(a)"],
		"kind": "Định lý cơ bản của vi tích phân",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2.2 - Công thức Newton-Leibniz (tr. 123)",
		"explanation": "Nếu F là một nguyên hàm của f trên [a,b], thì tích phân xác định bằng F(b)-F(a)."
	},
	{
		"text": "Tính đạo hàm của f(x)=ln(1+x²) tại x=1.",
		"answer": "1",
		"options": ["1", "2", "1/2", "0"],
		"kind": "Đạo hàm hàm hợp",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §3.2.1-3.2.3 - Hàm hợp và hàm sơ cấp (tr. 65-70)",
		"explanation": "f'(x)=2x/(1+x²). Thay x=1 được f'(1)=2/2=1."
	},
	{
		"text": "Tính ∫ từ 1 đến e của 1/x dx.",
		"answer": "1",
		"options": ["1", "e - 1", "0", "ln(2)"],
		"kind": "Tích phân xác định",
		"difficulty": 2,
		"source": "Giáo trình Vi tích phân 1, §5.2 - Nguyên hàm và Newton-Leibniz (tr. 121-125)",
		"explanation": "Nguyên hàm của 1/x trên x>0 là ln(x), nên kết quả ln(e)-ln(1)=1."
	},
	{
		"text": "Tính ∫ từ 0 đến 1 của 2x·e^(x²) dx.",
		"answer": "e - 1",
		"options": ["e - 1", "e", "1", "0"],
		"kind": "Tích phân đổi biến",
		"difficulty": 3,
		"source": "Giáo trình Vi tích phân 1 - Phương pháp đổi biến trong tích phân",
		"explanation": "Đặt u=x², du=2x dx. Đổi cận từ x=0,1 thành u=0,1, tích phân bằng ∫₀¹e^u du=e-1."
	},
	{
		"text": "Tính ∫ từ 0 đến π của x·sin(x) dx.",
		"answer": "π",
		"options": ["π", "0", "1", "2π"],
		"kind": "Tích phân từng phần",
		"difficulty": 3,
		"source": "Giáo trình Vi tích phân 1, §5.3.2 - Tích phân từng phần (tr. 133-135)",
		"explanation": "Đặt u=x, dv=sin(x)dx. Khi đó tích phân bằng [-x cos(x)]₀^π + ∫₀^π cos(x)dx = π."
	},
	{
		"text": "Tìm ∫ x·e^x dx.",
		"answer": "e^x(x - 1) + C",
		"options": ["e^x(x - 1) + C", "x·e^x + C", "e^x + C", "e^x(x + 1) + C"],
		"kind": "Tích phân từng phần",
		"difficulty": 3,
		"source": "Giáo trình Vi tích phân 1, §5.3.2 - Tích phân từng phần (tr. 133-135)",
		"explanation": "Đặt u=x, dv=e^x dx. Theo từng phần, ∫x·e^x dx=x·e^x-∫e^x dx=e^x(x-1)+C."
	}
]

# Mỗi vòng luôn có 5 câu.
static func round_length() -> int:
	return 5

# Thời gian trả lời tăng dần theo độ khó của câu hỏi.
static func time_limit_for(question_no: int) -> float:
	if question_no <= 2:
		return 16.0
	if question_no == 3:
		return 22.0
	if question_no == 4:
		return 35.0
	return 50.0

# Câu 1-2 là số học cơ bản; câu 3-5 lần lượt lấy từ các mức Vi tích phân.
static func generate(question_no: int, avoid_text: String = "") -> Dictionary:
	if question_no <= 2:
		return _make_arithmetic(avoid_text)
	var difficulty := question_no - 2
	var questions: Array = []
	for item in CALCULUS_QUESTIONS:
		if int(item["difficulty"]) == difficulty:
			questions.append(item)
	return _pick_from_bank(questions, avoid_text)

# Tạo câu cộng, trừ, nhân hoặc chia hết.
# Tách bước chọn phép tính khỏi bước tạo 4 đáp án để code dễ theo dõi hơn.
static func _make_arithmetic(avoid_text: String = "") -> Dictionary:
	var question: Dictionary = {}

	for attempt in 12:
		var a := 0
		var b := 0
		var answer := 0
		var operation := "+"

		# 1. Chọn phép tính và tạo các số phù hợp.
		match randi_range(0, 3):
			0:
				a = randi_range(0, 30)
				b = randi_range(0, 30)
				operation = "+"
				answer = a + b
			1:
				a = randi_range(0, 30)
				b = randi_range(0, a) # Đảm bảo kết quả phép trừ không âm.
				operation = "-"
				answer = a - b
			2:
				a = randi_range(2, 12)
				b = randi_range(2, 9)
				operation = "×"
				answer = a * b
			_:
				b = randi_range(2, 10)
				answer = randi_range(2, 12) # Thương được chọn trước để phép chia luôn chia hết.
				a = b * answer
				operation = "÷"

		# 2. Đổi ký hiệu phép tính thành tên để hiển thị cho người chơi.
		var operation_name := ""
		match operation:
			"+":
				operation_name = "Phép cộng"
			"-":
				operation_name = "Phép trừ"
			"×":
				operation_name = "Phép nhân"
			_:
				operation_name = "Phép chia hết"

		# 3. Tạo nội dung câu hỏi và lời giải.
		var question_text := "%d %s %d = ?" % [a, operation, b]
		var explanation := "%d %s %d = %d." % [a, operation, b, answer]
		question = _pack_numeric(
			question_text,
			answer,
			"Số học cơ bản",
			operation_name,
			explanation
		)

		# Nếu câu giống câu ngay trước đó, thử tạo câu khác.
		if str(question["text"]) != avoid_text:
			return question

	# Sau tối đa 12 lần thử, trả về câu vừa tạo để tránh vòng lặp vô hạn.
	return question

# Chọn ngẫu nhiên một câu trong ngân hàng, rồi trộn thứ tự các đáp án.
static func _pick_from_bank(bank: Array, avoid_text: String = "") -> Dictionary:
	if bank.is_empty():
		return {}

	var shuffled_questions: Array = bank.duplicate(true)
	shuffled_questions.shuffle()
	var selected_question: Dictionary = {}

	# Ưu tiên câu không trùng với câu ngay trước đó.
	for item in shuffled_questions:
		if str(item["text"]) != avoid_text:
			selected_question = item.duplicate(true)
			break

	# Nếu không tìm được câu khác, dùng câu đầu tiên trong danh sách đã trộn.
	if selected_question.is_empty():
		selected_question = shuffled_questions[0].duplicate(true)

	var options: Array = selected_question["options"].duplicate()
	options.shuffle()

	# Trả về một bộ dữ liệu thống nhất để math_quiz.gd hiển thị và chấm điểm.
	return {
		"text": str(selected_question["text"]),
		"options": options,
		"correct": options.find(str(selected_question["answer"])),
		"answer": str(selected_question["answer"]),
		"kind": str(selected_question["kind"]),
		"source": str(selected_question["source"]),
		"explanation": str(selected_question["explanation"]),
	}

# Tạo 4 đáp án cho câu số học: 1 đáp án đúng và 3 đáp án sai.
static func _pack_numeric(text: String, answer: int, kind: String, source: String, explanation: String) -> Dictionary:
	var options: Array[String] = [str(answer)]
	var offsets := [-10, -7, -5, -3, -2, -1, 1, 2, 3, 5, 7, 10]
	offsets.shuffle()

	# Tạo đáp án sai bằng cách cộng/trừ một số nhỏ vào đáp án đúng.
	for offset in offsets:
		var candidate: int = answer + offset
		if candidate >= 0 and not options.has(str(candidate)):
			options.append(str(candidate))
		if options.size() == 4:
			break

	# Trường hợp đặc biệt vẫn thiếu đáp án, thêm số lớn hơn đáp án đúng.
	var next_wrong_answer := answer + 11
	while options.size() < 4:
		if not options.has(str(next_wrong_answer)):
			options.append(str(next_wrong_answer))
		next_wrong_answer += 1

	# Trộn đáp án để vị trí đáp án đúng không cố định.
	options.shuffle()
	return {
		"text": text,
		"options": options,
		"correct": options.find(str(answer)),
		"answer": str(answer),
		"kind": kind,
		"source": source,
		"explanation": explanation,
	}
