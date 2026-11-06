## CẬP NHẬT QUY TRÌNH NGHIỆP VỤ & API SPECIFICATION 

### 1. Diễn giải chi tiết Quy trình nghiệp vụ 3 bước
- **Bước 1: Duyệt đơn hàng (Dispatcher Workflow):** 
  - Điều phối viên (Dispatcher) truy cập Web Portal, xem danh sách các đơn hàng có trạng thái `Pending`.
  - Dispatcher kiểm tra thông tin gói hàng và địa chỉ giao. Nếu thông tin hợp lệ, bấm **Approve** (Duyệt đơn). Nếu không hợp lệ (ví dụ: cấm bay, địa chỉ không rõ ràng), bấm **Reject** (Từ chối).
- **Bước 2: Gán trạm hạ cánh & Lịch giao (System / Backend Execution):**
  - Ngay sau khi đơn được bấm duyệt, Backend C# tự động truy vấn tìm Trạm cất cánh (`DepartureStation`) và Trạm hạ cánh (`ArrivalStation`) phù hợp nhất.
  - Hệ thống cập nhật trạng thái đơn thành `Approved`, gán ID của 2 trạm vào đơn hàng và sẵn sàng phân công Drone thực hiện lịch bay.
- **Bước 3: Xác nhận nhận/giao hàng tại trạm (Station Operator Flow):**
  - Khi Drone hạ cánh xuống trạm đích, hệ thống chuyển trạng thái đơn sang `In Transit` / `Arrived`.
  - Trạm trưởng (Station Operator) hoặc Người nhận quét mã **QR Code** hoặc nhập mã **OTP** (6 chữ số).
  - Hệ thống kiểm tra mã hợp lệ, mở hộc lấy hàng và chuyển trạng thái đơn hàng sang **`Completed`** (Hoàn thành).

---

### 2. Danh sách Endpoints API Specification (Swagger API Spec)
- `POST /api/orders/{id}/approve` : API duyệt đơn hàng dành cho Dispatcher (Chuyển trạng thái `Pending` -> `Approved`).
- `POST /api/orders/{id}/reject` : API từ chối đơn hàng (Chuyển trạng thái `Pending` -> `Rejected`).
- `GET /api/stations` : Lấy danh sách các trạm hạ cánh kèm vị trí tọa độ.
- `GET /api/stations/{id}/status` : Kiểm tra trạng thái hoạt động thực tế của trạm (`Available`, `Busy`, `Maintenance`).
- `POST /api/deliveries/confirm-otp` : API xác nhận mã OTP/QR để hoàn tất giao hàng tại trạm.
