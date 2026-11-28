---
title: HCMUS CSLT Online Judge
emoji: 💻
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
---

# Online Judge Server (C++17) cho bản Web Godot

Server FastAPI này nhận mã C++17 từ `cpp_remote_judge_provider.gd` trong game Godot, biên dịch bằng `g++ -std=c++17` trong thư mục tạm cách ly và trả kết quả về để game chấm điểm.

## 1. Chạy thử local (trên máy phát triển)
```bash
cd online_judge_server
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8000
```
Mặc định file `hcmus_dong_hoa/judge_config.json` đang trỏ tới `http://localhost:8000/api/judge`.

## 2. Deploy bằng Docker (khi đưa game lên Web)
```bash
docker build -t cslt-online-judge .
docker run -d -p 8000:8000 --memory=256m --cpus=1 --name cslt-judge cslt-online-judge
```
Có thể deploy trực tiếp Dockerfile này lên **Render**, **Railway**, **Fly.io** hoặc VPS có HTTPS (Nginx reverse proxy).

## 3. Cấu hình URL trong game trước khi Export Web
Mở `hcmus_dong_hoa/judge_config.json` và đổi `remote_endpoint` thành URL HTTPS của server đã deploy:
```json
{
  "remote_endpoint": "https://your-judge-domain.com/api/judge",
  "timeout_seconds": 30.0,
  "force_remote_on_desktop": false
}
```
Khi chạy bản Web (`OS.has_feature("web")`), game sẽ tự động bật chế độ **Online Judge**.
