USE DroneDeliveryDB;
GO

-- Xóa dữ liệu cũ (bảng con trước)
IF OBJECT_ID('dbo.DeliveryHistory', 'U') IS NOT NULL DELETE FROM dbo.DeliveryHistory;
DELETE FROM Orders;
DELETE FROM Drones;
DELETE FROM Stations;
DELETE FROM Users;
GO

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserId, FullName, Email, PhoneNumber, UserRole)
VALUES
(1, N'Nguyễn Văn A', 'khachhang1@gmail.com', '0901234567', 'Customer'),
(2, N'Trần Thị B', 'khachhang2@gmail.com', '0912345678', 'Customer');
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

INSERT INTO Drones (Code, Status) VALUES ('DRONE-01', 'Available'), ('DRONE-02', 'Available');
GO

SELECT * FROM Users;
SELECT * FROM Stations;
SELECT * FROM Orders;
SELECT * FROM Drones;