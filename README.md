# SmartDroneDelivery

Nền tảng quản lý giao hàng bằng drone tích hợp AI (AI-powered Drone Delivery Management Platform).
Đồ án môn **Hệ quản trị cơ sở dữ liệu**.

## Công nghệ

ASP.NET Core Web API, ReactJS, Flutter, PostgreSQL + PostGIS, SignalR, Docker, MinIO, Python FastAPI.

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---|---|
| `backend/` | ASP.NET Core Web API |
| `web/` | Web portal (ReactJS) |
| `mobile/` | Ứng dụng di động (Flutter) |
| `ai-service/` | Dịch vụ AI (FastAPI) |
| `database/` | Script SQL tạo CSDL và dữ liệu mẫu |
| `docs/` | SRS, sơ đồ thiết kế, API spec |

## Chạy CSDL trên máy

Yêu cầu: Docker Desktop.

```bash
docker compose up -d
```

Thông tin kết nối: host `localhost`, port `5432`, database `smartdrone`, user `postgres`, password `123456`.

Muốn nạp lại CSDL từ file SQL (xóa dữ liệu cũ):

```bash
docker compose down -v
docker compose up -d
```

## Thành viên nhóm

| STT | Họ và tên | Vai trò |
|:---:|---|---|
| 1 | Trầm Đồng Khởi | Thành viên |
| 2 | Trần Tuấn Khang | Thành viên |
| 3 | Trương Đình Khôi | Thành viên |
| 4 | Huỳnh Tiến Đạt | Thành viên |
| 5 | Nguyễn Văn Thiên Phước | Thành viên |
