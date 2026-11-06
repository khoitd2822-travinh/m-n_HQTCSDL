-- ============================================================================
-- BỘ DỮ LIỆU MẪU (MOCK DATA) CHO TRẠM VÀ TRẠNG THÁI ĐƠN HÀNG - 
-- ============================================================================
USE DroneDeliveryDB;
GO

-- 1. Dữ liệu mẫu cho các Trạm hạ cánh (Landing Stations)
INSERT INTO Stations (StationId, StationName, LocationAddress, Latitude, Longitude, Status)
VALUES 
(1, N'Trạm Khu Công Nghệ Cao', N'Lô E2a-7, Đường D1, TP. Thủ Đức', 10.8411, 106.8099, 'Available'),
(2, N'Trạm Ký túc xá Khu A', N'Khu phố 6, P. Linh Trung, TP. Thủ Đức', 10.8783, 106.8064, 'Available'),
(3, N'Trạm Công viên Central Park', N'208 Nguyễn Hữu Cảnh, Bình Thạnh', 10.7935, 106.7218, 'Busy');

-- 2. Dữ liệu mẫu kiểm thử luồng duyệt đơn (Pending -> Approved)
INSERT INTO Orders (OrderId, TrackingCode, CustomerId, DepartureStationId, ArrivalStationId, ReceiverName, ReceiverPhone, ReceiverAddress, PackageWeightKg, DeliveryFee, Status, CreatedDate)
VALUES 
(101, 'DRONE-2026-001', 1, 1, 2, N'Nguyen Van A', '0901234567', N'KTX Khu A ĐHQG', 2.5, 35000, 'Pending', GETDATE()),
(102, 'DRONE-2026-002', 2, 1, 3, N'Tran Thi B', '0912345678', N'Tòa Landmark 81', 1.2, 50000, 'Approved', GETDATE());
