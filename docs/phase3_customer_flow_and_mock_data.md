# Phần 3 — Customer Flutter và dữ liệu giả lập ETA

## Customer App đã có
- Đăng nhập/đăng ký demo (chưa có xác thực backend).
- Tạo đơn hàng: chọn điểm lấy/giao từ danh sách địa điểm.
- Màn hình bản đồ minh họa; chưa dùng bản đồ trực tuyến hoặc GPS.
- Lịch sử đơn hàng trong bộ nhớ phiên chạy; dữ liệu mất khi khởi động lại.
- Nhập mô tả gói hàng và tải trọng.

## FastAPI dữ liệu giả lập
- `GET /api/v1/mock-data?count=10&seed=42` tạo dữ liệu mẫu.
- `POST /api/v1/mock-data` với JSON `{"count": 10, "seed": 42}` tạo dữ liệu mẫu.
- Các trường gồm khoảng cách, tải trọng, thời tiết, gió, mưa, thời gian xử lý, tốc độ drone và ETA mẫu.
- Dữ liệu sinh ngẫu nhiên, không ghi vào database và không đại diện cho chuyến bay thực.

## Chạy API
Tại thư mục `ai-service`, tạo và kích hoạt môi trường ảo, cài `requirements.txt`, sau đó chạy:

```bash
python -m uvicorn app.main:app --reload
```

Mở `http://127.0.0.1:8000/docs` để thử endpoint mock-data.

## Chạy Customer App
Tại thư mục `mobile/customer_app` chạy:

```bash
flutter create --platforms=web,android .
flutter pub get
flutter run -d chrome
```

Nếu Flutter hỏi ghi đè `lib/main.dart`, giữ lại file mã nguồn hiện tại.

## GitHub
Sao chép `mobile/customer_app/lib/main.dart` vào cùng đường dẫn trong repo; cập nhật `ai-service/app/main.py` và `ai-service/app/schemas.py`; thêm `docs/phase3_customer_flow_and_mock_data.md`. Không ghi đè file của nhóm nếu họ đã sửa—hãy so sánh và gộp thay đổi.
