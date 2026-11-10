IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DroneDeliveryDB')
BEGIN
    CREATE DATABASE DroneDeliveryDB;
END
GO

USE DroneDeliveryDB;
GO

-- Xóa bảng theo thứ tự khóa ngoại (bảng con trước)
IF OBJECT_ID('dbo.DeliveryHistory', 'U') IS NOT NULL DROP TABLE dbo.DeliveryHistory;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Drones', 'U') IS NOT NULL DROP TABLE dbo.Drones;
IF OBJECT_ID('dbo.Stations', 'U') IS NOT NULL DROP TABLE dbo.Stations;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(20),
    UserRole VARCHAR(30) NOT NULL CHECK (UserRole IN ('Customer', 'Dispatcher', 'StationOperator', 'LogisticsManager', 'SystemAdmin')),
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Stations (
    StationId INT IDENTITY(1,1) PRIMARY KEY,
    StationName NVARCHAR(100) NOT NULL,
    LocationAddress NVARCHAR(255) NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Available', 'Busy', 'Maintenance')) DEFAULT 'Available'
);

CREATE TABLE Orders (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
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

CREATE TABLE Drones (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code VARCHAR(50) NOT NULL UNIQUE,
    Status VARCHAR(30) NOT NULL DEFAULT 'Available'
);
GO