# Ghi chú thiết kế CSDL

## 1. Công nghệ
PostgreSQL 16 kèm PostGIS. Chọn PostGIS vì hệ thống cần lưu tọa độ trạm và vị trí drone, và cần truy vấn "trạm gần nhất" bằng chỉ mục không gian (GIST) thay vì tự tính khoảng cách trong code.

## 2. Các quyết định chính

| Quyết định | Lý do |
|---|---|
| Khóa chính BIGINT tự tăng (IDENTITY) | Đơn giản, dễ đọc khi gỡ lỗi, đủ cho quy mô đồ án |
| Trạng thái dùng kiểu ENUM | CSDL tự chặn giá trị sai, không phụ thuộc việc backend gõ đúng chuỗi |
| Một bảng `users` chứa cả 5 vai trò (cột `role`) | Cả 5 actor đều đăng nhập như nhau; phân quyền RBAC dựa vào `role` |
| Cột vị trí dùng `geography(Point, 4326)` | Tính khoảng cách theo mét trên mặt cầu, đúng với tọa độ GPS |
| `orders` tách riêng với `deliveries` | Đơn là yêu cầu của khách; chuyến giao là việc thực hiện bằng drone. Đơn bị từ chối sẽ không có chuyến giao |
| `packages` tách khỏi `orders` | Cho phép một đơn có nhiều gói hàng |
| `order_status_history` + trigger | Mọi lần đổi trạng thái đơn được tự ghi lại, làm nền cho Audit Log, không phụ thuộc backend có nhớ ghi hay không |
| `telemetry_logs` tách riêng | Dữ liệu GPS phát sinh rất nhiều theo thời gian, tách ra để không làm nặng bảng `deliveries`. Có chỉ mục theo `(delivery_id, recorded_at)` |
| Ảnh gói hàng chỉ lưu đường dẫn (`image_url`) | Tệp thật nằm trên MinIO, CSDL không lưu nhị phân |

## 3. Phi chuẩn hóa có chủ ý
Cột `orders.estimated_minutes` lưu kết quả dự đoán của dịch vụ AI tại thời điểm tạo đơn. Lưu lại để hiển thị nhanh và để so sánh với thời gian giao thực tế sau này, không phải tính lại mỗi lần xem.

## 4. Ràng buộc toàn vẹn
- `pickup_station_id` khác `dropoff_station_id`.
- Trọng lượng gói hàng và tải trọng drone phải lớn hơn 0.
- Pin từ 0 đến 100.
- Mỗi đơn có tối đa một chuyến giao; mỗi chuyến có tối đa một bản xác nhận OTP và một bản tóm tắt.

## 5. Chỉ mục
Chỉ mục GIST cho các cột vị trí; chỉ mục thường cho các cột hay lọc (`orders.customer_id`, `orders.status`, `deliveries.drone_id`).

## 6. Hạn chế đã biết
- `password_hash` trong dữ liệu mẫu chỉ là chuỗi giả; backend sẽ băm mật khẩu thật ở Tuần 3.
- Chưa có bảng thanh toán hoặc cột phí giao hàng, nên chưa thống kê được doanh thu. Chưa có bảng thông báo (push notification) và chưa có cột ghi thời điểm xác nhận lấy hàng. Các phần này sẽ bổ sung bằng `ALTER TABLE` khi tới tuần phát triển tương ứng.