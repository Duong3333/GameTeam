# QUIZ THEO TIET HOC – GAMETEAM (Godot 4.7)

## 1. Cach hoat dong

Quiz tren lop duoc gan voi **thoi khoa bieu + phong hoc + trang thai ngoi vao ban**, khong tim NPC giao vien va khong can NPC cua mon hoc.

1. Nguoi choi vao mot phong co ho tro cho ngoi.
2. Nguoi choi bam `E` de ngoi vao ban.
3. `class_attendance.gd` doc `game.day`, `game.game_min`, thoi khoa bieu va ma phong.
4. `course_quiz_catalog.gd` doi buoi hoc thanh ma mon hoc.
5. `class_quiz_question_bank.gd` boc 5 cau cua mon do bang `load_session_round`: moi tuan mot bo cau khac nhau (xem muc 3b).
6. `math_quiz.gd` mo Quiz tren lop.
7. Moi tiet chi duoc bat dau mot lan trong mot ngay game; dong mo lai ket qua khong tao luot moi.

Quiz tiet hoc chi cho phep:
- `multiple_choice`: chon A/B/C/D.
- `short_answer`: nhap cau tra loi bang ban phim.

**Khong co Essay/IDE trong Quiz tiet hoc, ke ca Cơ sở lập trình thực hành.**

## 2. Phan biet Quiz tiet hoc va thi

- Quiz tiet hoc: chi ABCD va tra loi ngan cho tat ca cac mon.
- Tuan giua ky/cuoi ky: `class_attendance.gd` khong tu dong phat Quiz tiet hoc thong thuong.
- Luong thi rieng hien co trong `math_quiz.gd` duoc giu nguyen. Trong luong thi, IDE C++ chi duoc mo voi de CSLT co `answer_type=short_code` va `official_exam_round=true`.
- Cac bo de `02_De_luyen_tap.zip`/`03_Dap_an.zip` trong project la de luyen tap duoc gan voi ky thi trong game; khong duoc goi chung la de thi chinh thuc cua truong.

## 3. Danh sach ngan hang Quiz tren lop

Du lieu nam trong `class_quiz_question_bank.json`:

| Course code | Mon hoc | So cau | Dang cau hoi |
|---|---|---:|---|
| `DISCRETE` | Toán rời rạc | 70 | ABCD + trả lời ngắn |
| `INTRO_IT` | Nhập môn Công nghệ Thông tin | 70 | ABCD |
| `CSLT_THEORY` | Cơ sở lập trình lý thuyết | 110 | ABCD + trả lời ngắn |
| `CSLT_PRACTICAL` | Cơ sở lập trình thực hành | 70 | ABCD + trả lời ngắn |
| `VTP1` | Vi tích phân 1 - Lý thuyết | 70 | ABCD + trả lời ngắn |
| `VTP1_PRACTICAL` | Vi tích phân 1B - Thực hành | 70 | Trả lời ngắn |

Moi tiet lay 5 cau. Cau hoi duoc viet lai theo dang co the cham tu dong, khong chep nguyen van ca de thi.

Tat ca cau hoi trong file JSON hien co duoc danh dau `verified_ai`: dap an do AI giai va doi chieu lai, khong dong nghia voi dap an chinh thuc do giang vien ban hanh.

## 3b. Moi tuan mot bo cau khac nhau

- Moi tiet hoc co mot khoa buoi, vi du `CLASS:VTP1:W5` (mon + tuan tuyet doi cua game = `game.day / 7`). Bai tap ve nha co khoa `HW:<ma bai tap>`.
- Cung khoa buoi thi luon ra dung bo 5 cau da boc lan dau, nen ra vao lop nhieu lan trong tuan khong doi de.
- Tuan moi thi boc cac cau CHUA dung cua mon do. Hoc ky co 13 tuan hoc (tru tuan thi 8-9 va 16-17) nen moi ngan hang >= 65 cau de khong lap trong ca hoc ky. Dung het ngan hang thi bat dau vong moi.
- Lich su luu o `user://class_quiz_history.json` (giu nguyen khi tat mo game). Muon thu lai tu dau: xoa file do hoac goi `ClassQuestionBank.reset_history()`.
- Bai tap ve nha CSLT ly thuyet dung chung ngan hang voi quiz tren lop nen ngan hang nay co 110 cau.
- Cau moi do du an sinh theo mau; dap an lay tu ket qua chay that (g++), tinh bang sympy/mpmath, hoac liet ke vet can bang Python. Truong `verification_method` cua tung cau ghi ro cach kiem tra; cac cau khai niem Nhap mon CNTT la kien thuc chuan, chua kiem bang chuong trinh va nen duoc giang vien duyet.

## 4. Anh xa mon hoc voi lich/phong trong project tham chieu

- Toan roi rac LT: Tòa D / room key `D_TRR`.
- Toan roi rac TH: Nha Dieu hanh / room key `NDH`.
- Vi tich phan LT: Tòa F / room key `F_VTP`.
- Vi tich phan TH: Tòa B / room key `B`.
- CSLT ly thuyet: Tòa F / room key `F_CSLT`.
- CSLT thuc hanh: Tòa D / room key `D_TRR` hoac module lab B4.2 neu dang mo.
- Nhap mon CNTT LT: Tòa E / room key `E`.
- Nhap mon CNTT TH: Tòa D / room key `D_TRR`.

Thoi khoa bieu la nguon quyet dinh mon hoc. Vi mot phong co the duoc tai su dung cho nhieu tiet, khong phan loai mon dua tren dong chu trang tri trong phong.

**Luu y map:** Trong project tham chieu, `phong_hoc.gd` goi `_lab_f.open_lab("D_CSLT")`, nhung `b42_lab.gd` hien khong co ham `open_lab()`. Day la phu thuoc nam ngoai `scripts/features/`, nen patch feature-only khong sua no. Khi phong lab khong mo duoc, co che fallback cho Quiz CSLT thuc hanh o phong D (`D_TRR`) van duoc giu.

## 5. File feature lien quan

- `class_attendance.gd`: phat hien ngoi vao ban, tiet hoc hien tai, khoa input phong trong luc Quiz mo; giu homework CSLT ly thuyet.
- `course_quiz_catalog.gd`: anh xa buoi hoc/thoi khoa bieu/phong sang course code.
- `class_quiz_question_bank.gd`: doc, kiem tra va lay ngau nhien cau hoi tu JSON.
- `class_quiz_question_bank.json`: 131 câu hỏi cho 6 ngân hàng môn học.
- `math_quiz.gd`: giao dien, nhap tra loi, cham diem, ket qua; class mode khong mo IDE.
- `quiz_pdf_viewer.gd`: nut Xem de, cuon/zoom, hien ca cac phuong an ABCD.

`math_quiz.gd` va `class_attendance.gd` da co trong `scripts/features/registry.gd` cua project tham chieu. Hai script catalog/question-bank la module `RefCounted`, duoc preload, khong can them vao registry.

## 6. Cach them mon hoc moi

1. Them mot course code va ten trong `course_quiz_catalog.gd`.
2. Them mot entry trong `courses` cua `class_quiz_question_bank.json`.
3. Moi question phai co `id` duy nhat, `type` la `multiple_choice` hoac `short_answer`, `official_answer`, `accepted_answers`, `verified`, `answer_status`, `points`, `solution_latex` va `source_reference`.
4. Them quy tac phong/loai tiet trong `resolve_course_code()`.
5. Khong can NPC giao vien. Chi can phong co cac thuoc tinh `inside`, `_seated` va ma phong duoc nhan dien.
6. Khong them `short_code` vao ngan hang Quiz tiet hoc.

## 7. Gioi han kiem thu

Đã kiểm tra JSON, mã môn, số lượng câu, loại câu, khóa đáp án và đường dẫn preload bằng kiểm tra tĩnh. Mỗi tiết lấy tối đa 5 câu và chỉ chấp nhận hai loại câu hỏi trên. Các đề thi chính thức có đồng hồ tổng 60 phút; ô thời gian tiếp tục chạy khi người chơi xem phản hồi giữa các câu. Hết giờ sẽ tự kết thúc đề.

Moi truong tao patch khong co Godot 4.7 executable, nen chua the chay F5/runtime. Can import va test trong Godot 4.7 tren may nguoi dung.


## 8. Bổ sung ngân hàng đề theo nguồn môn học

- Mỗi ngân hàng lớp có 20 câu cho DISCRETE, VTP1, CSLT_THEORY, CSLT_PRACTICAL và INTRO_IT; VTP1_PRACTICAL có 31 câu trả lời ngắn.
- Vi tích phân LT (F / `F_VTP`) dùng `VTP1`; Vi tích phân TH (B / `B`) dùng `VTP1_PRACTICAL`.
- Tất cả đề thi Vi tích phân giữa kỳ từ `quiz_exam_bank` sử dụng trường `short_answer` lồng trong câu hỏi làm prompt và đáp án; giao diện thi chính thức dùng ô nhập bàn phím, không hiển thị ABCD.
- Cuối kỳ Vi tích phân sử dụng `vtp1_final_exam_bank.json`: 5 đề luyện tập mô phỏng, mỗi đề 5 câu trả lời ngắn. Đây không phải đề chính thức HCMUS.
- Chỉ luồng thi chính thức Cơ sở lập trình thực hành (`CSLT`, `answer_type=short_code`) mở IDE; không biến Quiz trên lớp thành bài nộp code.
- Đề giữa kỳ CSLT và VTP1 có sẵn trong `quiz_exam_bank` của project đầy đủ vẫn được giữ nguyên. Patch này không sửa `scripts/systems/` hoặc `quiz_exam_bank/` ngoài `scripts/features/`.


## 9. Nguồn tham khảo và phạm vi

- Vi tích phân 1B/Thực hành Vi tích phân 1B: theo đề cương công khai của Bộ môn Giải tích HCMUS; sách nền `Giáo trình Vi tích phân 1 - HCMUS`, bản 15/08/2025. Dạng bài thực hành được đề cương dẫn từ J. Stewart, *Calculus* (2012).
- Nguồn luyện tập phụ trợ: OpenStax Calculus và MIT OCW 18.01 (Problem Sets, solutions, exams). Các câu trong bank được biên soạn mới.
- Toán rời rạc: bộ tài liệu PDF của người dùng, chương 1–7.
- Cơ sở lập trình: bộ đề luyện tập C++ trong project và cppreference để đối chiếu quy tắc ngôn ngữ.
- Nhập môn CNTT: hai đề Project 1/2 chỉ hỗ trợ câu hỏi về nội dung yêu cầu dự án; kiến thức nền được ghi rõ là tham khảo ngoài.
- Mọi câu mới có `answer_status=verified_ai`, không được hiểu là đáp án chính thức của giảng viên. Metadata theo từng câu ghi tên nguồn/chương/mục và URL khi có.


## 9. Hình thức thi Vi tích phân và nguồn đề

- Thi giữa kỳ Vi tích phân dùng trường `short_answer` đã có trong từng câu của 5 bộ đề luyện tập gốc; giao diện nhập bàn phím, không dùng ABCD hoặc IDE.
- Thi cuối kỳ Vi tích phân chọn ngẫu nhiên một trong 5 bộ đề mô phỏng trong `vtp1_final_exam_bank.json`; mỗi bộ 5 câu trả lời ngắn. Đây là đề luyện tập do dự án biên soạn, không phải đề chính thức HCMUS.
- Các kỳ thi chính thức sử dụng đồng hồ tổng `duration_seconds` (3600 giây); Quiz ôn tập giữ 180 giây cho mỗi câu.
- Cơ sở lập trình TH là môn duy nhất dùng IDE/nộp code trong kỳ thi.
- Nội dung Vi tích phân bám theo phạm vi Vi tích phân 1B của HCMUS; OpenStax và MIT OCW chỉ là nguồn tham khảo cho dạng bài và cách luyện tập.
