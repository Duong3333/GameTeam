# C++ IDE refactor — offline-first, online-ready

## Phạm vi bản này

- Mặc định dùng GCC cục bộ trên Windows và chuẩn C++17.
- Giao diện IDE không gọi GCC trực tiếp.
- Controller chọn bộ thực thi thông qua provider.
- Có HTTP provider làm khung tích hợp tương lai; chưa có server judge nên không bật mặc định.
- Workspace code/input vẫn lưu cục bộ theo ID câu hỏi.
- Không thay đổi rubric, ngân hàng testcase, quy tắc một lần thi hay cách tính GPA hiện tại.

## Sơ đồ file

- `quiz_code_editor.gd`: giao diện editor.
- `cpp_ide_controller.gd`: điều phối Run/Submit và lựa chọn backend.
- `cpp_execution_provider.gd`: hợp đồng chung giữa các bộ thực thi.
- `cpp_local_gcc_provider.gd`: biên dịch/chạy offline bằng GCC C++17.
- `cpp_remote_judge_provider.gd`: gửi request HTTPS tới dịch vụ judge tương lai.
- `programming_runner.gd`: lớp tương thích kế thừa Controller, để `math_quiz.gd` hiện tại vẫn khởi tạo `ProgrammingRunner.new()` được.
- `cpp_ide_save_manager.gd`: lưu workspace theo câu hỏi.
- `math_quiz.gd`: chỉ bổ sung context `action`, `question_id` và mã nguồn gốc để remote provider có đủ thông tin về sau.

## Chế độ hiện tại

Controller mặc định `backend_mode = 0` (`Local GCC`). Khi export Windows, cần đặt toàn bộ toolchain tại một trong các vị trí mà local provider tìm kiếm, ưu tiên:

`scripts/features/tools/gcc/bin/g++.exe`

Chạy thiết lập GCC một lần trên máy phát triển Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\features\tools\install_gcc.ps1
```

Gói feature không kèm binary GCC. Script trên tải bộ WinLibs chính thức và cài vào đúng đường dẫn ưu tiên. Bản export vẫn cần đóng gói thư mục compiler ở ngoài PCK để Windows chạy được `g++.exe`.

## Hợp đồng dịch vụ judge online tương lai

Remote provider gửi `POST` JSON đến `remote_endpoint` qua HTTPS:

```json
{
  "task_id": "CSLT_EXAM_001_Q02",
  "language": "cpp",
  "standard": "c++17",
  "action": "run",
  "source_code": "...mã nguồn sinh viên...",
  "stdin": "...input của lần chạy thử..."
}
```

`action` là `run` hoặc `submit`. Với `run`, dịch vụ dùng `task_id` để tạo harness phù hợp và chạy trên input được gửi. Với `submit`, dịch vụ phải tự nạp hidden testcases từ server-side question bank; không nhận expected output/testcase bí mật từ client. Dịch vụ trả về JSON tương thích:

```json
{
  "success": true,
  "stage": "completed",
  "message": "Chấm bài hoàn tất.",
  "stdout": "...",
  "stderr": "",
  "exit_code": 0,
  "grade": {
    "gradable": true,
    "needs_review": false,
    "earned_points": 2.0,
    "max_points": 2.0,
    "percentage": 100.0,
    "correct_testcases": 5,
    "total_testcases": 5,
    "criteria": [],
    "expected": "Testcase đúng: 5/5"
  }
}
```

`grade` phải được tính từ server-side testcase, không dùng điểm do client tự khai báo. Backend cần xác thực tài khoản, giới hạn tần suất, giới hạn kích thước mã, timeout, memory/output limit và chạy chương trình trong sandbox/worker cách ly. Không biên dịch hoặc chạy mã người chơi trong tiến trình Godot server chính.

Client hỗ trợ gửi `Authorization: Bearer <token>` khi Controller được cấp access token qua `set_remote_access_token()`. Không hard-code secret/API key trong project hoặc PCK. Nếu gọi API từ bản Web, backend phải cấu hình CORS cho đúng domain game và xử lý preflight request.

## Lưu ý khi bật online sau này

Bản hiện tại chỉ chuẩn bị giao diện provider và giao thức request/response; nó chưa phải dịch vụ chấm bài online hoàn chỉnh. Trước khi bật `backend_mode = 1`, cần triển khai API HTTPS, server-side question bank, worker sandbox và cơ chế lưu kết quả tài khoản. Đặc biệt, điểm thi/GPA/lượt thi phải được backend xác thực và lưu ở server; không coi dữ liệu do client gửi về là nguồn chính thức.

## Kiểm thử cần chạy trong Godot/Windows

1. Mở project và để Godot import các script feature mới.
2. Xác nhận `math_quiz.gd` vẫn khởi tạo `ProgrammingRunner` mà không cần sửa scene/registry.
3. Chạy bài C++17 mẫu và xác nhận Run hiển thị stdout, stderr và lỗi biên dịch.
4. Nộp bài có testcase; xác nhận số testcase và điểm giống bản hiện tại.
5. Đóng/mở IDE, xác nhận code và input được khôi phục theo câu hỏi.
6. Kiểm tra không có thay đổi ở GPA, số lượt thi hoặc dữ liệu câu hỏi.
7. Chỉ kiểm thử Remote provider với máy chủ staging có HTTPS và sandbox; không dùng máy chủ Godot chính để thực thi code không tin cậy.

## Giới hạn đã biết

Timeout trong runner hiện tại không tạo thành sandbox bảo mật tuyệt đối. Nó phù hợp làm runner cục bộ trong giai đoạn phát triển, không phải môi trường an toàn để nhận và thực thi mã từ người lạ trên server.
