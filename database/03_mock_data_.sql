-- ============================================================================
-- SmartDroneDelivery - BỘ DỮ LIỆU MẪU (MOCK DATA) TUẦN 4
-- Hệ quản trị CSDL: Microsoft SQL Server (T-SQL)
-- ============================================================================

USE DroneDeliveryDB;
GO

-- 1. TỰ ĐỘNG KHỞI TẠO CẤU TRÚC BẢNG (NẾU CHƯA CÓ)
IF OBJECT_ID('dbo.Orders', 'U') IS NULL AND OBJECT_ID('dbo.Stations', 'U') IS NULL
BEGIN
    -- Tạo bảng Users
    IF OBJECT_ID('dbo.Users', 'U') IS NULL
    CREATE TABLE Users (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        FullName NVARCHAR(100) NOT NULL,
        Email VARCHAR(100) UNIQUE NOT NULL,
        PhoneNumber VARCHAR(20),
        UserRole VARCHAR(30) NOT NULL,
        CreatedDate DATETIME DEFAULT GETDATE()
    );

    -- Tạo bảng Stations
    CREATE TABLE Stations (
        StationId INT PRIMARY KEY,
        StationName NVARCHAR(100) NOT NULL,
        LocationAddress NVARCHAR(255) NOT NULL,
        Latitude FLOAT NOT NULL,
        Longitude FLOAT NOT NULL,
        Status VARCHAR(20) NOT NULL DEFAULT 'Available'
    );

    -- Tạo bảng Orders
    CREATE TABLE Orders (
        OrderId INT PRIMARY KEY,
        TrackingCode VARCHAR(50) UNIQUE NOT NULL,
        CustomerId INT NULL FOREIGN KEY REFERENCES Users(UserId),
        DepartureStationId INT NULL FOREIGN KEY REFERENCES Stations(StationId),
        ArrivalStationId INT NULL FOREIGN KEY REFERENCES Stations(StationId),
        ReceiverName NVARCHAR(100) NOT NULL,
        ReceiverPhone VARCHAR(20) NOT NULL,
        ReceiverAddress NVARCHAR(255) NOT NULL,
        PackageWeightKg FLOAT NOT NULL,
        DeliveryFee DECIMAL(18,2) NOT NULL,
        Status VARCHAR(30) NOT NULL DEFAULT 'Pending',
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

-- 2. DỌN DẸP DỮ LIỆU CŨ TRÁNH LỖI TRÙNG KHÓA (PRIMARY KEY / FOREIGN KEY)
DELETE FROM Orders;
DELETE FROM Stations;
DELETE FROM Users;
GO

-- 3. CHÈN DỮ LIỆU MẪU KHÁCH HÀNG (CỐ ĐỊNH UserId = 1 và 2)
SET IDENTITY_INSERT Users ON;

INSERT INTO Users (UserId, FullName, Email, PhoneNumber, UserRole)
VALUES 
(1, N'Nguyễn Văn A', 'khachhang1@gmail.com', '0901234567', 'Customer'),
(2, N'Trần Thị B', 'khachhang2@gmail.com', '0912345678', 'Customer');

SET IDENTITY_INSERT Users OFF;
GO

-- 4. CHÈN DỮ LIỆU MẪU TRẠM HẠ CÁNH (LANDING STATIONS)
INSERT INTO Stations (StationId, StationName, LocationAddress, Latitude, Longitude, Status)
VALUES 
(1, N'Trạm Khu Công Nghệ Cao', N'Lô E2a-7, Đường D1, TP. Thủ Đức', 10.8411, 106.8099, 'Available'),
(2, N'Trạm Ký túc xá Khu A', N'Khu phố 6, P. Linh Trung, TP. Thủ Đức', 10.8783, 106.8064, 'Available'),
(3, N'Trạm Công viên Central Park', N'208 Nguyễn Hữu Cảnh, Bình Thạnh', 10.7935, 106.7218, 'Busy');
GO

-- 5. CHÈN DỮ LIỆU MẪU ĐƠN HÀNG (LUỒNG PENDING -> APPROVED)
INSERT INTO Orders (OrderId, TrackingCode, CustomerId, DepartureStationId, ArrivalStationId, ReceiverName, ReceiverPhone, ReceiverAddress, PackageWeightKg, DeliveryFee, Status, CreatedDate)
VALUES 
(101, 'DRONE-2026-001', 1, 1, 2, N'Nguyễn Văn A', '0901234567', N'KTX Khu A ĐHQG', 2.5, 35000, 'Pending', GETDATE()),
(102, 'DRONE-2026-002', 2, 1, 3, N'Trần Thị B', '0912345678', N'Tòa Landmark 81', 1.2, 50000, 'Approved', GETDATE());
GO

-- 6. KHUYẾN MÃI: HIỂN THỊ KẾT QUẢ KIỂM TRA TRỰC QUAN
SELECT * FROM Users;
SELECT * FROM Stations;
SELECT * FROM Orders;
