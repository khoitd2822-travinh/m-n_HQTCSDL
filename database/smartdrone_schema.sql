-- ============================================================================
-- SmartDroneDelivery - KHỞI TẠO CSDL TRÊN SQL SERVER (T-SQL)
-- ============================================================================

-- 1. Tạo Database nếu chưa có
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DroneDeliveryDB')
BEGIN
    CREATE DATABASE DroneDeliveryDB;
END
GO

USE DroneDeliveryDB;
GO

-- 2. Xóa bảng cũ nếu đã tồn tại (Xóa theo thứ tự khóa ngoại)
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Stations', 'U') IS NOT NULL DROP TABLE dbo.Stations;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

-- 3. Tạo bảng Người dùng (Users)
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(20),
    UserRole VARCHAR(30) NOT NULL CHECK (UserRole IN ('Customer', 'Dispatcher', 'StationOperator', 'LogisticsManager', 'SystemAdmin')),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- 4. Tạo bảng Trạm hạ cánh (Stations)
CREATE TABLE Stations (
    StationId INT PRIMARY KEY,
    StationName NVARCHAR(100) NOT NULL,
    LocationAddress NVARCHAR(255) NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Available', 'Busy', 'Maintenance')) DEFAULT 'Available'
);

-- 5. Tạo bảng Đơn hàng giao bằng Drone (Orders)
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
    Status VARCHAR(30) NOT NULL CHECK (Status IN ('Pending', 'Approved', 'Rejected', 'Scheduled', 'InTransit', 'Completed', 'Failed')) DEFAULT 'Pending',
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO
