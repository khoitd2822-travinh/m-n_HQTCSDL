USE DroneDeliveryDB;
GO

-- Xóa dữ liệu cũ (bảng con trước)
IF OBJECT_ID('dbo.DeliveryHistory', 'U') IS NOT NULL DELETE FROM dbo.DeliveryHistory;
DELETE FROM Orders;
DELETE FROM Drones;
DELETE FROM Stations;
DELETE FROM Users;
GO

DECLARE @pw VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', '123456'), 2);

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserId, FullName, Email, PhoneNumber, UserRole, PasswordHash)
VALUES
(1, N'Nguyễn Văn A',      'khachhang1@gmail.com',     '0901234567', 'Customer',         @pw),
(2, N'Trần Thị B',        'khachhang2@gmail.com',     '0912345678', 'Customer',         @pw),
(3, N'Điều phối viên',    'dispatcher@smartdrone.vn', '0900000003', 'Dispatcher',       @pw),
(4, N'Nhân viên trạm',    'operator@smartdrone.vn',   '0900000004', 'StationOperator',  @pw),
(5, N'Quản lý logistics', 'manager@smartdrone.vn',    '0900000005', 'LogisticsManager', @pw),
(6, N'Quản trị viên',     'admin@smartdrone.vn',      '0900000006', 'SystemAdmin',      @pw);
SET IDENTITY_INSERT Users OFF;
GO

SET IDENTITY_INSERT Stations ON;
INSERT INTO Stations (StationId, StationName, LocationAddress, Latitude, Longitude, Status)
VALUES
(1, N'Trạm Khu Công Nghệ Cao', N'Lô E2a-7, Đường D1, TP. Thủ Đức', 10.8411, 106.8099, 'Available'),
(2, N'Trạm Ký túc xá Khu A', N'Khu phố 6, P. Linh Trung, TP. Thủ Đức', 10.8783, 106.8064, 'Available'),
(3, N'Trạm Công viên Central Park', N'208 Nguyễn Hữu Cảnh, Bình Thạnh', 10.7935, 106.7218, 'Busy');
SET IDENTITY_INSERT Stations OFF;
GO

SET IDENTITY_INSERT Orders ON;
INSERT INTO Orders (OrderId, TrackingCode, CustomerId, DepartureStationId, ArrivalStationId, ReceiverName, ReceiverPhone, ReceiverAddress, PackageWeightKg, DeliveryFee, Status, CreatedDate)
VALUES
(101, 'DRONE-2026-001', 1, 1, 2, N'Nguyễn Văn A', '0901234567', N'KTX Khu A ĐHQG', 2.5, 35000, 'Pending', GETDATE()),
(102, 'DRONE-2026-002', 2, 1, 3, N'Trần Thị B', '0912345678', N'Tòa Landmark 81', 1.2, 50000, 'Approved', GETDATE());
SET IDENTITY_INSERT Orders OFF;
GO

INSERT INTO DeliveryHistory (OrderId, OldStatus, NewStatus, UpdatedBy, Note) VALUES
(101, NULL,      N'Pending',  1, N'Khach tao don'),
(102, NULL,      N'Pending',  2, N'Khach tao don'),
(102, N'Pending', N'Approved', 3, N'Dispatcher duyet don');
GO

SET IDENTITY_INSERT Orders ON;
INSERT INTO Orders (OrderId, TrackingCode, CustomerId, DepartureStationId, ArrivalStationId, ReceiverName, ReceiverPhone, ReceiverAddress, PackageWeightKg, DeliveryFee, Status, CreatedDate)
VALUES
(103, 'DRONE-2026-003', 1, 2, 1, N'Lê Văn C',    '0933333333', N'Cổng chính khuôn viên', 0.8, 20000, 'Completed', DATEADD(DAY, -1, GETDATE())),
(104, 'DRONE-2026-004', 2, 3, 1, N'Phạm Thị D',  '0944444444', N'Khu thư viện',          3.0, 45000, 'Failed',    DATEADD(DAY, -1, GETDATE())),
(105, 'DRONE-2026-005', 2, 1, 2, N'Hoàng Văn E', '0955555555', N'KTX Khu B',             1.5, 30000, 'Completed', DATEADD(DAY, -2, GETDATE()));
SET IDENTITY_INSERT Orders OFF;
GO

INSERT INTO Drones (Code, Status, BatteryPct, CurrentStationId, Latitude, Longitude) VALUES
('DRONE-01', 'Available', 95, 1, 10.8411, 106.8099),
('DRONE-02', 'Available', 88, 2, 10.8783, 106.8064);
GO

SELECT * FROM Users;
SELECT * FROM Stations;
SELECT * FROM Orders;
SELECT * FROM Drones;