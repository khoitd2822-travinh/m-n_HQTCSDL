# SmartDroneDelivery

**Nền tảng quản lý giao hàng bằng drone tích hợp AI** (AI-powered Drone Delivery Management Platform)

Hệ thống quản lý nghiệp vụ giao hàng bằng drone (không điều khiển drone): từ tạo đơn, duyệt, lấy hàng, giao, theo dõi đến xác nhận giao bằng OTP. Có dịch vụ AI hỗ trợ ước tính thời gian, tóm tắt chuyến giao và trợ lý cho khách hàng.

## 1. Thành phần

| Thư mục | Nội dung | Công nghệ |
|---|---|---|
| `backend/` | Web API, phân quyền 5 vai trò | ASP.NET Core, EF Core, JWT |
| `web/` | Giao diện Điều phối, Quản lý, Nhân viên trạm, Quản trị, Khách hàng | HTML, CSS, JavaScript |
| `mobile/customer_app/` | Ứng dụng khách hàng | Flutter |
| `mobile/station_operator_app/` | Ứng dụng nhân viên trạm | Flutter |
| `ai-service/` | ETA, tóm tắt, trợ lý AI | Python, FastAPI |
| `database/` | Schema, stored procedure, view, dữ liệu mẫu | SQL Server (T-SQL) |
| `docs/` | Sơ đồ, thiết kế CSDL, quy trình, đặc tả API, ảnh chụp | Markdown, PNG |
| `docker-compose.yml` | Triển khai toàn bộ hệ thống | Docker |

## 2. Chức năng chính

- **Người dùng**: đăng nhập JWT, phân quyền theo vai trò (Customer, Dispatcher, StationOperator, LogisticsManager, SystemAdmin), hồ sơ cá nhân, tự đổi mật khẩu, quên mật khẩu (mã xác nhận giả lập SMS).
- **Khách hàng**: tạo đơn (phí và thời gian dự kiến do server tính), hủy đơn khi chờ duyệt, xem lịch sử đơn, theo dõi drone trên bản đồ (chỉ đơn của mình), trợ lý AI.
- **Điều phối viên**: duyệt hoặc từ chối đơn, xếp lịch giao, bắt đầu giao, xem tóm tắt AI, xem bản đồ.
- **Nhân viên trạm**: xác nhận lấy hàng (bắt buộc trước khi giao), nhập OTP xác nhận giao, ghi nhận giao thất bại, đổi trạng thái trạm.
- **Quản lý và Quản trị**: thống kê theo trạng thái, trạm, ngày; quản trị xem danh sách người dùng.
- **Người nhận**: tra mã OTP bằng mã vận đơn và số điện thoại (giả lập SMS).
- **Huy hiệu** số đơn cần xử lý trên tab Đơn hàng của nhân viên.

Vòng đời đơn: `Pending → Approved → (Scheduled) → lấy hàng → InTransit → Completed`; nhánh phụ: `Rejected`, `Cancelled`, `Failed`.

## 3. Chạy bằng Docker (khuyên dùng)

Yêu cầu: Docker Desktop.

```bash
docker compose up -d --build
docker compose ps
```

Đợi khoảng 1 đến 2 phút để SQL Server khởi động và nạp dữ liệu (service `db-init` tự chạy 3 file SQL rồi dừng, trạng thái `exited 0` là bình thường).

| Dịch vụ | Địa chỉ |
|---|---|
| Web | http://localhost:8080/smartdrone_web_dashboard.html |
| Backend API (Swagger) | http://localhost:5139/swagger |
| AI service | http://localhost:8000/docs |

Tắt hệ thống: `docker compose down`.

> Mỗi lần `docker compose up`, dữ liệu được nạp lại về dữ liệu mẫu ban đầu.

## 4. Chạy thủ công (phát triển)

1. **Cơ sở dữ liệu**: SQL Server (hoặc SQL Express). Chạy lần lượt `database/01_schema.sql`, `02_procedures.sql`, `03_mock_data.sql`. Chuỗi kết nối nằm trong `backend/SmartDroneDelivery.Api/appsettings.json`.
2. **Backend**:
   ```bash
   cd backend/SmartDroneDelivery.Api
   dotnet run
   ```
   Chạy tại http://localhost:5139.
3. **AI service**:
   ```bash
   cd ai-service
   pip install -r requirements.txt
   uvicorn main:app --port 8000
   ```
4. **Web**: mở `web/smartdrone_web_dashboard.html` bằng Live Server (hoặc bất kỳ web server tĩnh).
5. **App Flutter**:
   ```bash
   cd mobile/customer_app
   flutter run -d web-server --web-port 5000
   cd ../station_operator_app
   flutter run -d web-server --web-port 5001
   ```

Kiểm thử giao diện: `flutter test` trong từng thư mục app.

## 5. Tài khoản demo

Mật khẩu tất cả: `123456`

| Vai trò | Email |
|---|---|
| Khách hàng | khachhang1@gmail.com, khachhang2@gmail.com |
| Điều phối viên | dispatcher@smartdrone.vn |
| Nhân viên trạm | operator@smartdrone.vn |
| Quản lý logistics | manager@smartdrone.vn |
| Quản trị viên | admin@smartdrone.vn |

## 6. Kịch bản demo nhanh

1. Khách hàng tạo đơn (ghi nhận phí, thời gian dự kiến), thử hủy một đơn.
2. Điều phối viên duyệt đơn, bấm **Tóm tắt AI**.
3. Điều phối viên thử **Bắt đầu giao** ngay: hệ thống báo chưa lấy hàng.
4. Nhân viên trạm **Xác nhận lấy hàng**, rồi bắt đầu giao.
5. Mở **Bản đồ** (điều phối) và tab **Theo dõi** (app khách): drone bay. Khách khác không thấy.
6. Người nhận tra OTP ở trang đăng nhập, đọc cho nhân viên trạm; nhân viên nhập OTP, đơn Hoàn tất.
7. Xem **Lịch sử** đơn, **Tổng quan**, tab **Người dùng** (Admin).

## 7. Tài liệu

Xem thư mục `docs/`: `diagrams/` (ERD, class, sequence, use case, kiến trúc), `database-design.md`, `quy-trinh-nghiep-vu.md`, `ai_api_examples.json`, `api-spec/`, `screenshots/`.

## 8. Hạn chế và hướng phát triển

- Dùng **SQL Server** thay cho PostgreSQL trong đề cương, vì logic nghiệp vụ viết bằng stored procedure T-SQL.
- Dịch vụ AI dựa trên **luật và mẫu câu** (chưa phải mô hình học máy); kiến trúc sẵn sàng thay bằng mô hình thật.
- OTP và quên mật khẩu **giả lập SMS** bằng trang tra cứu; bản thật cần cổng SMS hoặc email.
- Chuyến bay là **mô phỏng theo thời gian**, cập nhật bằng polling mỗi 2 giây; chưa có SignalR và MinIO.
- Mật khẩu băm SHA-256 không salt, CORS mở, khóa JWT và mật khẩu DB đặt trong cấu hình demo. Bản thật cần bcrypt/Argon2, giới hạn CORS và biến môi trường.
- Drone chưa gắn với từng đơn cụ thể; chưa có thanh toán, thông báo đẩy, sửa đơn.