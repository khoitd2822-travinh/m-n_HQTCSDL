# Ghi chú thiết kế CSDL

## 1. Công nghệ
SQL Server (chạy bằng SQL Express khi phát triển, container `mssql/server:2022` khi triển khai Docker). Đề cương đề xuất PostgreSQL, nhóm chọn SQL Server vì logic nghiệp vụ quan trọng được viết bằng stored procedure T-SQL (đổi trạng thái đơn kèm ghi lịch sử trong một transaction) và các view thống kê.

## 2. Các bảng
| Bảng | Vai trò |
|---|---|
| `Users` | Một bảng cho cả 5 vai trò (cột `UserRole`), mật khẩu băm SHA-256 |
| `Stations` | Trạm hạ cánh: tên, địa chỉ, tọa độ (`Latitude`, `Longitude`), trạng thái |
| `Orders` | Đơn giao hàng: người nhận, khối lượng, phí, trạng thái, `EstimatedMinutes`, `OtpCode` |
| `Drones` | Drone: mã, pin, trạm đang đậu, tọa độ |
| `DeliveryHistory` | Nhật ký mọi lần đổi trạng thái (trạng thái cũ/mới, người đổi, ghi chú, thời điểm) |

## 3. Các quyết định chính
| Quyết định | Lý do |
|---|---|
| Khóa chính INT IDENTITY | Đơn giản, dễ gỡ lỗi, đủ cho quy mô đồ án |
| Trạng thái là VARCHAR + CHECK constraint | CSDL chặn giá trị sai (Pending, Approved, Rejected, Scheduled, InTransit, Completed, Failed, Cancelled) |
| Một bảng `Users` cho 5 vai trò | Mọi actor đăng nhập như nhau; phân quyền RBAC theo `UserRole` trong JWT |
| Đổi trạng thái qua `sp_CapNhatTrangThaiDonHang` | Cập nhật đơn và ghi `DeliveryHistory` trong cùng một transaction, có khóa dòng |
| `OtpCode` sinh bằng DEFAULT trong CSDL | Mỗi đơn có mã 6 số ngẫu nhiên ngay khi tạo |
| Xác nhận lấy hàng ghi vào `DeliveryHistory` | Không thêm trạng thái mới; backend kiểm tra đã có bản ghi lấy hàng trước khi cho bắt đầu giao |
| Khoảng cách và vị trí drone tính trong backend | Công thức Haversine và nội suy theo thời gian từ lúc bắt đầu giao; chưa lưu vị trí theo thời gian |

## 4. Phi chuẩn hóa có chủ ý
`Orders.EstimatedMinutes` lưu kết quả ước tính của AI service tại thời điểm tạo đơn, để hiển thị nhanh và so sánh với thực tế sau này.

## 5. Procedure và view
- Procedure: `sp_CapNhatTrangThaiDonHang`, `sp_DuyetVaPhanCongDonHang`, `sp_XemDonHangCuaKhach`, `sp_XemChiTietDonHang`, `sp_XemDanhSachDonHang`, `sp_TimKiemDonHang`, `sp_XemLichSuVanChuyen`.
- View thống kê: `vw_ThongKeDonHangTheoNgay`, `vw_ThongKeDonTheoTram`, `vw_ThongKeTheoTrangThai`.

## 6. Hạn chế đã biết
- Mật khẩu băm SHA-256 không có salt; bản thật cần bcrypt hoặc Argon2.
- Mỗi đơn một gói hàng; chưa có bảng thanh toán, thông báo, nhật ký GPS (telemetry).
- Drone chưa gắn với đơn cụ thể; tóm tắt AI lấy drone đang đậu ở trạm gửi.
- Chưa có MinIO để lưu ảnh xác nhận giao.