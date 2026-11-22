//danh sach tai khoan va phan quyen theo role
USE DroneDeliveryDB;
GO

-- 1. Thêm cột mật khẩu vào bảng Users (nếu chưa có)
IF COL_LENGTH('Users', 'PasswordHash') IS NULL
BEGIN
    ALTER TABLE Users ADD PasswordHash VARCHAR(100) NOT NULL DEFAULT '123456';
END
GO

-- 2. Tạo dữ liệu chuẩn cho 6 tài khoản mẫu (đủ 5 Role) và Đơn hàng test
DELETE FROM Orders;
DELETE FROM Stations;
DELETE FROM Users;
GO

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserId, FullName, Email, PhoneNumber, UserRole, PasswordHash)
VALUES 
(1, N'Nguyễn Văn Chiến', 'customer1@gmail.com', '0901111111', 'Customer', '123456'),
(2, N'Trần Thị Hường',  'customer2@gmail.com', '0902222222', 'Customer', '123456'),
(3, N'Trầm Đồng Khởi',       'dispatcher@gmail.com','0903333333', 'Dispatcher', '123456'),
(4, N'Trần Tuần Khang',   'station@gmail.com',   '0904444444', 'StationOperator', '123456'),
(5, N'Trương Đình Khôi',      'manager@gmail.com',   '0905555555', 'LogisticsManager', '123456'),
(6, N'Đình Khôi Admin',    'admin@gmail.com',     '0906666666', 'SystemAdmin', '123456');
SET IDENTITY_INSERT Users OFF;
GO

INSERT INTO Stations (StationId, StationName, LocationAddress, Latitude, Longitude, Status)
VALUES 
(1, N'Trạm Khu Công Nghệ Cao', N'Lô E2a-7, TP. Thủ Đức', 10.8411, 106.8099, 'Available'),
(2, N'Trạm Ký túc xá Khu A', N'P. Linh Trung, TP. Thủ Đức', 10.8783, 106.8064, 'Available');
GO

INSERT INTO Orders (OrderId, TrackingCode, CustomerId, DepartureStationId, ArrivalStationId, ReceiverName, ReceiverPhone, ReceiverAddress, PackageWeightKg, DeliveryFee, Status, CreatedDate)
VALUES 
(101, 'DRONE-2026-001', 1, 1, 2, N'Nguyễn Văn Khách 1', '0901111111', N'KTX Khu A', 2.5, 35000, 'Pending', GETDATE()),
(102, 'DRONE-2026-002', 2, 2, 1, N'Trần Thị Khách 2',  '0902222222', N'Khu CNC',   1.2, 50000, 'Approved', GETDATE());
GO

-- 3. Stored Procedure 1: Đăng nhập & Chặn sai tài khoản/mật khẩu
CREATE OR ALTER PROCEDURE sp_DangNhap
    @Email VARCHAR(100),
    @Password VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND PasswordHash = @Password)
        SELECT UserId, FullName, Email, UserRole, N'Đăng nhập thành công' AS TrangThai
        FROM Users WHERE Email = @Email;
    ELSE
        RAISERROR(N'Lỗi 401: Sai email hoặc mật khẩu! Truy cập bị chặn.', 16, 1);
END;
GO

-- 4. Stored Procedure 2: Chức năng "Đơn hàng của tôi" (Chặn chưa đăng nhập & sai Role)
CREATE OR ALTER PROCEDURE sp_DonHangCuaToi
    @UserId INT
AS
BEGIN
    DECLARE @Role VARCHAR(30);
    SELECT @Role = UserRole FROM Users WHERE UserId = @UserId;

    IF @Role IS NULL
    BEGIN
        RAISERROR(N'Lỗi 401: Chưa đăng nhập! Truy cập bị chặn.', 16, 1);
        RETURN;
    END

    IF @Role <> 'Customer'
    BEGIN
        RAISERROR(N'Lỗi 403: Sai phân quyền (Role)! Chỉ Khách hàng mới có mục Đơn hàng của tôi.', 16, 1);
        RETURN;
    END

    SELECT OrderId, TrackingCode, ReceiverName, ReceiverAddress, DeliveryFee, Status, CreatedDate
    FROM Orders
    WHERE CustomerId = @UserId;
END;
GO

-- 5. Stored Procedure 3: Phân quyền duyệt đơn (Chặn Customer, chỉ cho Dispatcher/Admin)
CREATE OR ALTER PROCEDURE sp_KiemTraQuyenDuyetDon
    @UserId INT,
    @OrderId INT
AS
BEGIN
    DECLARE @Role VARCHAR(30);
    SELECT @Role = UserRole FROM Users WHERE UserId = @UserId;

    IF @Role IS NULL
    BEGIN
        RAISERROR(N'Lỗi 401: Chưa đăng nhập, bị chặn!', 16, 1);
        RETURN;
    END

    IF @Role NOT IN ('Dispatcher', 'SystemAdmin')
    BEGIN
        RAISERROR(N'Lỗi 403: Từ chối truy cập! Vai trò của bạn không có quyền duyệt đơn.', 16, 1);
        RETURN;
    END

    UPDATE Orders SET Status = 'Approved' WHERE OrderId = @OrderId;
    SELECT N'Duyệt đơn thành công!' AS KetQua, * FROM Orders WHERE OrderId = @OrderId;
END;
GO