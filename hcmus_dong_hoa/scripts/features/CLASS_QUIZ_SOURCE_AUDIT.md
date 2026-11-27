# AUDIT NGUON CAU HOI – QUIZ TREN LOP

## 1. Nguon tai lieu nguoi dung da cung cap va co the doc trong project

### Toan roi rac

- `Đề bài tập môn toán rời rac(1).zip`: 7 file bai tap theo chuong, 7 file ly thuyet theo chuong va 1 tai lieu tong hop.
- `drive-download-20261121T140349Z-1-001.zip`: 7 PDF `In_Chuong` tuong ung cac chuong 1, 2, 3, 4, 5, 6 va 7.
- Cac chu de trong ngan hang duoc phan bo tren: co so logic, tap hop/anh xa, phuong phap dem, he thuc de quy, so nguyen, quan he, ham Boolean.

### Vi tich phan 1

- `Giáo trình Vi tích phân 1 - HCMUS.pdf`: tai lieu nen tang ve gioi han, ham so lien tuc, dao ham va ung dung, nguyen ham/tich phan va chuoi.
- Bo de luyen tap va dap an da nam trong project: `quiz_exam_bank/source_manifest.json` ghi nguon `02_De_luyen_tap.zip` va `03_Dap_an.zip`, gom 5 de CSLT + 5 de VTP1, moi de 5 cau.
- `quiz_exam_bank/answer_audit.json`: 50 cau da ghép dap an; 49 duoc xac minh, 1 lỗi đáp án nguồn VTP1_EXAM_005_Q01 da duoc ghi nhan va co phuong an sua rieng. 46 cau trong bo de luyen tap can cham/kiem tra thu cong; khong duoc tu dong coi la san sang cham.

### Cơ sở lập trình

- Su dung noi dung hoc tap va dang bai tu 5 bo de CSLT va dap an co trong project.
- Ngan hang tren lop tach thanh ly thuyet va thuc hanh, nhung ca hai chi co ABCD/tra loi ngan.
- Bai viet code C++/IDE/testcase chi nam trong luong thi rieng cua Cơ sở lập trình thực hành, khong nam trong Quiz tiet hoc.

### Nhap mon CNTT

- `NM CNTT_Project 1.pdf` va `NM CNTT_Project 2.pdf` la tai lieu yeu cau do an, khong phai giao trinh day du.
- Ngan hang cau hoi Nhap mon CNTT duoc xay dung o muc nhap mon, dua tren cac muc tieu trong hai file va tai lieu tham khao ben ngoai ve he thong thong tin, SDLC, du lieu, mang va kiem soat truy cap.

## 2. Nguon tham khao cong khai da dung de doi chieu chu de

- Open Book Project – Discrete Mathematics: https://open-book-project.github.io/mathematics/discrete_mathematics/index.html
- Discrete Mathematics, OpenMathBooks: https://discrete.openmathbooks.org/dmoi2/
- University of Houston – Discrete Mathematics course topics: https://www.uh.edu/nsm/math/undergraduate/courses-donotpublish-tccns/math3336/
- OpenStax – Foundations of Information Systems, Chapter 1: https://openstax.org/books/foundations-information-systems/pages/1-introduction
- OpenStax – Data types, DBMS and data management: https://openstax.org/books/foundations-information-systems/pages/3-1-data-types-database-management-systems-and-tools-for-managing-data
- OpenStax – Data governance and quality: https://openstax.org/books/foundations-information-systems/pages/2-1-practices-and-frameworks-for-data-management
- cppreference – C++ basic concepts: https://en.cppreference.com/w/cpp/language/basics
- cppreference – Increment/decrement operators: https://en.cppreference.com/w/cpp/language/operator_incdec
- OpenStax – Calculus Volume 1: https://openstax.org/books/calculus-volume-1

Cau hoi trong JSON la cau hoi luyen tap duoc bien soan lai; khong sao chep nguyen van mot bo de hay mot sach.

## 3. Ba thu muc Google Drive ve de thi da duoc nguoi dung neu

- Cơ sở lập trình (giữa kỳ/cuối kỳ): https://drive.google.com/drive/folders/1pKqZiQDEiFr-YBFSDY0VzysupDqH96ZZ
- Vi tích phân 1 (cuối kỳ): https://drive.google.com/drive/folders/1OCt6eMfCcehuPHZiGs_8m6fQM6z6Mnd1
- Vi tích phân 1 (giữa kỳ): https://drive.google.com/drive/folders/1xjIgMt_hgCBCmb8wqSpyXQ3A3LUE4zy

**Trang folder Google Drive co the mo nhung danh sach file/bytes ben trong khong truy cap duoc trong moi truong tao patch nay.** Vi vay noi dung cac folder nay CHUA duoc nhap vao ngan hang, va khong duoc xem 10 de luyen tap co san la de giua ky/cuoi ky chinh thuc. Khi nguoi dung tai len cac file PDF/ZIP tu ba folder tren, can tao nhom `midterm`/`final` rieng va cap nhat manifest, giu nguyen nguon goc dap an.

## 4. Trang thai dap an

- Bank ban dau gom 50 cau. Sau lan mo rong hien tai, bank co 131 cau; tat ca cau moi co `answer_status=verified_ai`, `verified=true`, do dap an duoc giai/doi chieu lai cho muc dich luyen tap.
- Day khong phai xac nhan cua giang vien.
- Khong tu dong chuyen `verified_ai` thanh `official`.
- Cau short-answer chi chap nhan cac dang da khai bao trong `accepted_answers`; khong dung so sanh van ban gan dung de tu doan y nghia.
- ABCD duoc cham theo `correct_option`.

## 5. Danh sach file ngan hang

`class_quiz_question_bank.json` bản đầu có 5 môn × 10 câu = 50 câu. Bản hiện tại có 6 ngân hàng, tổng 131 câu. Mỗi tiết lấy 5 câu ngẫu nhiên. Tất cả câu Quiz trên lớp chỉ dùng `multiple_choice` hoặc `short_answer`; không có `short_code`, Essay hay code submission trong Quiz tiết học.


## 6. Nguồn và phần bổ sung trong lần cập nhật này

### Vi tích phân 1B và Thực hành Vi tích phân 1B

- Nguồn chương trình chính: Bộ môn Giải tích, HCMUS, trang “Đại cương ngành khác ngành Toán”, mục “VI TÍCH PHÂN 1B” và “THỰC HÀNH VI TÍCH 1B”.
- Phạm vi 1B/TH 1B gồm: tập hợp, ánh xạ, dãy và chuỗi số; liên tục; đạo hàm, Taylor/Maclaurin, Hôpital, khảo sát hàm và cực trị; tích phân một biến, Newton–Leibniz, đổi biến, từng phần, tích phân suy rộng, chuỗi lũy thừa, Abel, miền/bán kính hội tụ và Fourier.
- Đề cương thực hành HCMUS ghi bài tập tham khảo từ J. Stewart, *Calculus* (2012), đối chiếu các chương/section tương ứng: Appendix A; Chương 1; 11.1; 11.2–11.11; 1 và 2.1–2.5; 2.1/2.8; 3–4; 5, 7, 8; 7.8; Chương 11.
- Nguồn câu hỏi luyện tập bổ sung: OpenStax Calculus (Vol. 1/2) và MIT OpenCourseWare 18.01 Single Variable Calculus (problem sets, practice exams và solutions). Chỉ dùng để tham khảo dạng bài và kiểm tra mức độ; câu trong bank là câu mới được biên soạn lại, không sao chép nguyên văn.
- Không đưa nội dung Vi tích phân 2B vào ngân hàng 1B: đạo hàm riêng, tích phân nhiều lớp, tích phân đường/mặt và phương trình vi phân không thuộc bank này.

### Các môn còn lại

- Toán rời rạc: dùng bộ PDF người dùng cung cấp Chương 1–7 (cơ sở logic; tập hợp và ánh xạ; phương pháp đếm; hệ thức đệ quy; số nguyên; quan hệ; hàm/đại số Boolean). Các câu bổ sung được phân chủ đề theo các chương này.
- Cơ sở lập trình: giữ nguyên 5 đề luyện tập CSLT hiện có trong `quiz_exam_bank`; câu hỏi trên lớp được biên soạn mới theo dạng C++ cơ bản, vòng lặp, hàm, tham chiếu, con trỏ, mảng và đọc kết quả. Chỉ thi thực hành CSLT mới dùng IDE và test case.
- Nhập môn CNTT: Project 1/2 chỉ là đề cương yêu cầu đồ án, không được coi là giáo trình lý thuyết. Các câu bổ sung về website bán hàng, OCR, keyword extraction và bộ dữ liệu kiểm thử được giới hạn đúng các yêu cầu thể hiện trong hai đề; nội dung nền khác phải được ghi là tham khảo ngoài.

### Nguyên tắc trạng thái đáp án

- Các câu mới có `answer_status=verified_ai`, `verified=true`; đây là đáp án do hệ thống tự giải/kiểm tra, không phải đáp án chính thức của giảng viên.
- Các câu lấy cảm hứng từ nguồn được diễn đạt mới, không sao chép một khối đề/bài tập có bản quyền.
- Bank lớp sau khi hoàn thiện: DISCRETE 20; VTP1 20; VTP1_PRACTICAL 31; CSLT_THEORY 20; CSLT_PRACTICAL 20; INTRO_IT 20 (tổng 131 câu).
- Đề cuối kỳ Vi tích phân: 5 đề luyện tập mô phỏng × 5 câu = 25 câu; tất cả dùng trả lời ngắn và đáp án số kiểm tra được. Bộ đề mô phỏng không phải đề chính thức của HCMUS. Timer tổng 60 phút áp dụng cho các kỳ thi chính thức Vi tích phân theo cấu hình ngân hàng; thi giữa kỳ Cơ sở lập trình thực hành dùng 90 phút. Đồng hồ tiếp tục chạy khi người chơi đang xem phản hồi và tự kết thúc đề khi hết giờ. Quiz luyện tập vẫn giữ 180 giây mỗi câu.
- Các đề luyện tập CSLT/VTP1 cũ trong `quiz_exam_bank` vẫn là nguồn riêng: 10 đề × 5 câu = 50 câu; không đổi nhãn thành đề chính thức HCMUS và không thay đổi đáp án nguồn.

## 7. Nguồn công khai được đối chiếu

- HCMUS – Bộ môn Giải tích, “Đại cương ngành khác ngành Toán”, mục Vi tích phân 1B và Thực hành Vi tích phân 1B: https://sites.google.com/view/math-hcmus-edu-vn-giaitich/trang-ch%E1%BB%A7/%C4%91%C3%A0o-t%E1%BA%A1o-%C4%91%E1%BA%A1i-h%E1%BB%8Dc/%C4%91%E1%BA%A1i-c%C6%B0%C6%A1ng-ng%C3%A0nh-kh%C3%A1c-to%C3%A1n
- OpenStax Calculus: https://openstax.org/details/books/calculus-volume-1 (CC BY 4.0; Vol. 1/2 được dùng cho các chủ đề phù hợp, không lấy chủ đề nhiều biến/vi tích phân 2B).
- MIT OpenCourseWare 18.01 Single Variable Calculus – Assignments: https://ocw.mit.edu/courses/18-01-single-variable-calculus-fall-2005/pages/assignments/
- MIT OpenCourseWare 18.01 Single Variable Calculus – Exams: https://ocw.mit.edu/courses/18-01-single-variable-calculus-fall-2005/pages/exams/ (tham khảo dạng thi và lời giải; không sao chép đề).
- cppreference – C++ language reference: https://en.cppreference.com/w/cpp/language/

## 8. Lỗi answer key cũ đã được sửa

- `CSLT_P_009` trước đây lưu `correct_option="5"`, trong khi giao diện ABCD chỉ nhận A/B/C/D. Câu hỏi cho kết quả 5; đáp án đúng nằm ở lựa chọn B. Đã sửa `correct_option`, `official_answer` và `accepted_answers` về `B`, đồng thời cập nhật lời giải. Đây là sửa lỗi dữ liệu chứ không đổi câu hỏi.


## 9. Metadata nguồn theo từng câu

`class_quiz_question_bank.json` hiện ghi `source_metadata` cho từng câu: tài liệu chính, chương/mục (với VTP ghi số trang in trong giáo trình HCMUS khi xác định được), URL đề cương hoặc tài liệu tham khảo ngoài, và ghi chú câu hỏi được biên soạn mới. Với các Project 1/2 của Nhập môn CNTT, metadata nhấn mạnh đây là đề cương đồ án, không phải giáo trình lý thuyết.
