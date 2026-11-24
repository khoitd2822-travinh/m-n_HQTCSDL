# Quy trình nghiệp vụ và danh sách API

## 1. Vòng đời đơn hàng
Pending → Approved → (Scheduled) → [lấy hàng] → InTransit → Completed
Nhánh phụ: Pending → Rejected (điều phối từ chối), Pending → Cancelled (khách hủy), Approved/Scheduled/InTransit → Failed (giao thất bại).

## 2. Các bước
1. **Khách tạo đơn**: chọn trạm gửi, trạm nhận (không được là trạm đang bảo trì), nhập người nhận và khối lượng (tối đa 5 kg). Backend tính phí theo khoảng cách (Haversine) và gọi AI service lấy thời gian dự kiến (có công thức dự phòng). Đơn có mã OTP 6 số.
2. **Điều phối viên duyệt hoặc từ chối** đơn Pending. Có thể **xếp lịch** giao (Approved → Scheduled).
3. **Nhân viên trạm xác nhận lấy hàng** tại trạm gửi (ghi vào lịch sử). Bước này bắt buộc trước khi bắt đầu giao.
4. **Bắt đầu giao** (Dispatcher hoặc Station Operator): đơn sang InTransit, drone bay mô phỏng theo thời gian; điều phối và khách theo dõi trên bản đồ.
5. **Giao và xác nhận**: người nhận tra mã OTP (giả lập SMS gửi về số điện thoại người nhận), đọc cho nhân viên trạm; nhân viên nhập mã, đơn chuyển sang Completed. Nếu không giao được, ghi Giao thất bại.
6. **Theo dõi và thống kê**: lịch sử đổi trạng thái của từng đơn; dashboard thống kê theo trạng thái, trạm, ngày; tóm tắt AI cho từng đơn; trợ lý AI cho khách.

## 3. Phân quyền
Customer, Dispatcher, StationOperator, LogisticsManager, SystemAdmin (JWT, kiểm tra theo vai trò ở từng endpoint). Khách chỉ thấy đơn và chuyến bay của chính mình.

## 4. Danh sách API chính
| Phương thức | Đường dẫn | Mô tả |
|---|---|---|
| POST | /api/Auth/login | Đăng nhập, trả JWT |
| POST | /api/PasswordReset/request, /confirm | Quên mật khẩu (mã giả lập SMS) |
| GET/PUT | /api/Profile/me | Xem, sửa hồ sơ |
| POST | /api/Profile/change-password | Tự đổi mật khẩu |
| GET | /api/Users | Danh sách người dùng (Admin, chỉ xem) |
| GET | /api/Stations | Danh sách trạm |
| PUT | /api/Stations/{id}/status | Đổi trạng thái trạm |
| GET | /api/Orders, /api/Orders/mine | Đơn của nhân viên / của khách |
| POST | /api/SmartDroneOrder/create | Tạo đơn |
| POST | /api/orders/{id}/approve, reject, schedule, pickup, start, fail, cancel | Chuyển trạng thái đơn |
| GET | /api/orders/{id}/history | Lịch sử đơn |
| POST | /api/SmartDroneOrder/{id}/confirm-delivery | Nhập OTP, hoàn tất đơn |
| POST | /api/SmartDroneOrder/receiver-otp | Người nhận tra OTP |
| GET | /api/SmartDroneOrder/{id}/summary | Tóm tắt AI |
| POST | /api/SmartDroneOrder/chat | Trợ lý AI cho khách |
| GET | /api/Flights | Vị trí drone đang bay |
| GET | /api/Dashboard/by-status, by-day, by-station | Thống kê |