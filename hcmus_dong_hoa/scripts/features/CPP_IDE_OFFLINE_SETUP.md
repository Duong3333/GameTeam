# IDE C++17 — thiết lập offline trên Windows

1. Giữ `backend_mode = 0` trong `cpp_ide_controller.gd` (mặc định).
2. Trên máy phát triển Windows, chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\features\tools\install_gcc.ps1
```

3. Xác nhận compiler nằm tại `scripts/features/tools/gcc/bin/g++.exe`.
4. Khi export game, đóng gói cả thư mục `scripts/features/tools/gcc/` ngoài PCK, cạnh file thực thi game.
5. Mở quiz C++ và thử Run/Submit.

Gói này không chứa binary GCC. Script thiết lập tải WinLibs GCC/MinGW-w64 chính thức một lần trên máy Windows có Internet. Sau khi cài và đóng gói đầy đủ, game có thể gọi compiler cục bộ mà không cần kết nối mạng.

Xem `CPP_IDE_ARCHITECTURE.md` để biết kiến trúc provider và giao thức remote judge dự kiến.

Lưu ý: timeout không phải sandbox hoàn chỉnh. Không dùng runner cục bộ này làm dịch vụ thực thi code cho nhiều người chơi trên server.
