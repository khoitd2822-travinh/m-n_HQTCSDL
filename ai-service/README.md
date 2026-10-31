# SmartDroneDelivery AI Service (FastAPI)

## Cài đặt và chạy
Python 3.10+ được khuyến nghị.

```bash
python -m venv .venv
```
Windows: `.venv\Scripts\activate`  
macOS/Linux: `source .venv/bin/activate`

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```
Mở `http://127.0.0.1:8000/docs` để dùng Swagger UI.

## Endpoints
- `GET /health`
- `POST /api/v1/eta`
- `POST /api/v1/chat`
- `POST /api/v1/summary`

Ví dụ ETA:
```json
{"distance_km": 1.2, "drone_speed_kmh": 30, "station_delay_min": 1, "weather_delay_min": 0}
```

Ví dụ chatbot:
```json
{"message": "Đơn hàng của tôi đang ở đâu?", "order_id": "SD-1024"}
```

Ví dụ summary:
```json
{"order_id":"SD-1024","status":"In transit","origin_station":"Station A","destination_station":"Station B","drone_id":"DR-001","battery_pct":80,"notes":["Giao đúng lộ trình"]}
```

## Phạm vi hiện tại
Các endpoint chạy được nhưng chỉ là logic mẫu theo quy tắc/từ khóa/template. Chưa có mô hình AI đã huấn luyện, xác thực, database hoặc kết nối backend. CORS mở chỉ phù hợp môi trường phát triển; cần giới hạn origin khi triển khai thật.
