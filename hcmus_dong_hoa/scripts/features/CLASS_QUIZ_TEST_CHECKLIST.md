# CHECKLIST TEST QUIZ THEO TIET HOC

Chay trong Godot 4.7 sau khi copy patch vao project.

## A. Kich hoat theo thoi khoa bieu va cho ngoi

- [ ] Ngoai thoi gian hoc: vao phong va ngoi, Quiz khong tu mo.
- [ ] Dung gio + dung phong + ngoi vao ban: Quiz cua mon tu mo.
- [ ] Dung gio nhung dang dung: Quiz khong tu mo.
- [ ] Sai toa/phong: Quiz khong tu mo.
- [ ] Ra ket qua va dong: khong the lam lai trong cung tiet.
- [ ] Het tiet: neu Quiz con dang lam, he thong tu dong chot luot; sau khi dong ket qua, input phong duoc mo lai.

## B. Cac buoi hoc duoc anh xa

- [ ] Toan roi rac LT: D / `D_TRR`.
- [ ] Toan roi rac TH: Nha Dieu hanh / `NDH`.
- [ ] Vi tich phan LT: F / `F_VTP`.
- [ ] Vi tich phan TH: B / `B`.
- [ ] CSLT ly thuyet: F / `F_CSLT`.
- [ ] CSLT thuc hanh: D / `D_TRR` hoac lab B4.2 neu mo duoc.
- [ ] Nhap mon CNTT LT: E / `E`.
- [ ] Nhap mon CNTT TH: D / `D_TRR`.

## C. Hinh thuc cau hoi tren lop

- [ ] Chi co ABCD va tra loi ngan.
- [ ] Khong co nut IDE/Code trong Quiz tren lop, ke ca CSLT thuc hanh.
- [ ] ABCD co du 4 phuong an trong giao dien lam bai.
- [ ] Khong the nop cau ABCD neu chua chon phuong an (tru truong hop het gio).
- [ ] Nut Xem de hien noi dung cau hoi va ca phuong an ABCD.
- [ ] Zoom chu trong Xem de hoat dong.
- [ ] Tra loi ngan nhan duoc ban phim va cham theo `accepted_answers`/`tolerance`.

## D. Phan biet thi

- [ ] Tuan giua ky/cuoi ky khong bat dau Quiz tiet hoc thong thuong.
- [ ] Luong thi rieng van duoc giu rieng.
- [ ] IDE C++ chi xuat hien trong luong thi rieng CSLT khi cau co `answer_type=short_code`.
- [ ] Khong co Essay cho Quiz tren lop cua bat ky mon nao.

## E. Kiem tra ket qua va homework

- [ ] Moi luot co 5 cau duoc lay ngau nhien tu dung ngan hang mon hoc.
- [ ] Ket qua hien so cau dung, diem va GPA theo cau hinh hien co.
- [ ] Sau tiet CSLT ly thuyet, homework duoc giao theo logic feature hien tai.
- [ ] Homework khong bi giao lap khi vao lai cung tiet.

Neu co loi, gui nguyen van dong dau tien trong Godot Output/Debugger va ten file/dong bao loi. Khong chi gui anh neu co the copy text loi.


## F. Vi tích phân TH / kỳ thi cuối kỳ mới

- [ ] Vi tích phân LT tại F / `F_VTP` tải bank `VTP1`.
- [ ] Vi tích phân TH tại B / `B` tải bank riêng `VTP1_PRACTICAL`.
- [ ] VTP1_PRACTICAL chỉ sinh câu short-answer; không có ABCD/IDE.
- [ ] Thi giữa kỳ VTP1 dùng câu hỏi con `short_answer`, ô nhập bàn phím và chấm theo đáp án số/tolerance.
- [ ] Thi cuối kỳ VTP1 trong tuần 16/17 tải một trong 5 đề tại `vtp1_final_exam_bank.json`, mỗi đề 5 câu short-answer.
- [ ] Đề cuối kỳ mới hiển thị rõ là đề luyện tập mô phỏng, không phải đề chính thức.
- [ ] Làm sai/đúng đều tính điểm theo cấu hình chấm hiện có; không chạy IDE trong VTP1.
- [ ] NPC Thầy LTC chỉ kích hoạt đề cuối kỳ VTP1; các luồng NPC/midterm khác giữ nguyên.
- [ ] Kiểm tra `CSLT_P_009`: lựa chọn B phải được chấm đúng khi người chơi chọn B.


## G. Rà soát nguồn và số lượng mới

- [ ] Tổng ngân hàng trên lớp: DISCRETE 20, VTP1 20, VTP1_PRACTICAL 31, CSLT_THEORY 20, CSLT_PRACTICAL 20, INTRO_IT 20 (131 câu).
- [ ] Mỗi câu VTP có source_metadata trỏ về mục phù hợp của giáo trình HCMUS và đề cương 1B/TH 1B.
- [ ] VTP giữa kỳ: tất cả câu được dựng lại từ trường `short_answer`; nhập câu trả lời bằng bàn phím và đối chiếu accepted_answers.
- [ ] VTP cuối kỳ: tải một trong năm bộ đề mô phỏng, 5 câu, không xuất hiện lựa chọn ABCD.
- [ ] Câu Fourier chỉ là phần mở rộng/nâng cao trong chương trình 1B, không nhầm sang 2B.
- [ ] Timer tổng 60 phút áp dụng cho mọi kỳ thi chính thức; đồng hồ tiếp tục chạy khi đang xem phản hồi và tự kết thúc đề khi hết giờ.
