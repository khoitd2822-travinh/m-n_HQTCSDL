USE DroneDeliveryDB;
GO

-- ============================================================
-- SMART DRONE DELIVERY
-- STORED PROCEDURES, VIEWS VA LICH SU VAN CHUYEN
-- SQL SERVER
-- ============================================================


-- ============================================================
-- 0. TAO BANG LICH SU VAN CHUYEN NEU CHUA TON TAI
-- ============================================================

IF OBJECT_ID('dbo.DeliveryHistory', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DeliveryHistory
    (
        HistoryId INT IDENTITY(1,1) PRIMARY KEY,
        OrderId INT NOT NULL,
        OldStatus NVARCHAR(30) NULL,
        NewStatus NVARCHAR(30) NOT NULL,
        UpdatedBy INT NULL,
        Note NVARCHAR(255) NULL,
        UpdatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_DeliveryHistory_UpdatedAt
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_DeliveryHistory_Orders
            FOREIGN KEY (OrderId)
            REFERENCES dbo.Orders(OrderId),

        CONSTRAINT FK_DeliveryHistory_Users
            FOREIGN KEY (UpdatedBy)
            REFERENCES dbo.Users(UserId)
    );
END;
GO


-- ============================================================
-- 1. STORED PROCEDURES QUAN LY DON HANG
-- ============================================================

-- 1.1. XEM DANH SACH DON HANG

CREATE OR ALTER PROCEDURE dbo.sp_XemDanhSachDonHang
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId AS [Ma Don],
        o.TrackingCode AS [Ma Van Don],
        c.FullName AS [Ten Khach Hang],
        s.StationName AS [Tram Gui],
        o.ReceiverName AS [Ten Nguoi Nhan],
        o.ReceiverPhone AS [SDT Nguoi Nhan],
        o.ReceiverAddress AS [Dia Chi Nhan],
        o.PackageWeightKg AS [Khoi Luong (Kg)],
        o.DeliveryFee AS [Phi Giao Hang],
        o.Status AS [Trang Thai],
        o.CreatedDate AS [Ngay Tao]
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c
        ON o.CustomerId = c.UserId
    LEFT JOIN dbo.Stations AS s
        ON o.DepartureStationId = s.StationId
    ORDER BY o.CreatedDate DESC;
END;
GO


-- 1.2. XEM CHI TIET DON HANG THEO MA VAN DON

CREATE OR ALTER PROCEDURE dbo.sp_XemChiTietDonHang
    @MaVanDon NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId AS MaDon,
        o.TrackingCode AS MaVanDon,
        c.FullName AS TenKhachHang,
        c.PhoneNumber AS SDTKhachHang,
        o.ReceiverName AS TenNguoiNhan,
        o.ReceiverPhone AS SDTNguoiNhan,
        o.ReceiverAddress AS DiaChiGiao,
        o.PackageWeightKg AS KhoiLuongKg,
        o.DeliveryFee AS PhiGiaoHang,
        o.Status AS TrangThai,
        o.CreatedDate AS NgayTao
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c
        ON o.CustomerId = c.UserId
    WHERE o.TrackingCode = @MaVanDon;
END;
GO


-- 1.3. TIM KIEM DON HANG

CREATE OR ALTER PROCEDURE dbo.sp_TimKiemDonHang
    @TuKhoa NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId AS MaDon,
        o.TrackingCode AS MaVanDon,
        c.FullName AS TenKhachHang,
        o.ReceiverAddress AS DiaChiGiao,
        o.PackageWeightKg AS KhoiLuongKg,
        o.Status AS TrangThai,
        o.CreatedDate AS NgayTao
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c
        ON o.CustomerId = c.UserId
    WHERE
        o.TrackingCode LIKE N'%' + @TuKhoa + N'%'
        OR c.FullName LIKE N'%' + @TuKhoa + N'%'
        OR o.ReceiverAddress LIKE N'%' + @TuKhoa + N'%'
    ORDER BY o.CreatedDate DESC;
END;
GO


-- ============================================================
-- 2. STORED PROCEDURES LICH SU VAN CHUYEN
-- ============================================================

-- 2.1. XEM LICH SU VAN CHUYEN THEO MA VAN DON

CREATE OR ALTER PROCEDURE dbo.sp_XemLichSuVanChuyen
    @MaVanDon NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.TrackingCode AS MaVanDon,
        h.OldStatus AS TrangThaiCu,
        h.NewStatus AS TrangThaiMoi,
        h.UpdatedAt AS ThoiGianCapNhat,
        u.FullName AS NguoiCapNhat,
        h.Note AS GhiChu
    FROM dbo.Orders AS o
    INNER JOIN dbo.DeliveryHistory AS h
        ON o.OrderId = h.OrderId
    LEFT JOIN dbo.Users AS u
        ON h.UpdatedBy = u.UserId
    WHERE o.TrackingCode = @MaVanDon
    ORDER BY h.UpdatedAt ASC, h.HistoryId ASC;
END;
GO


-- 2.2. CAP NHAT TRANG THAI VA LUU LICH SU

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTrangThaiDonHang
    @MaVanDon NVARCHAR(50),
    @TrangThaiMoi NVARCHAR(30),
    @NguoiCapNhatId INT = NULL,
    @GhiChu NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrderId INT;
    DECLARE @TrangThaiCu NVARCHAR(30);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @OrderId = OrderId,
            @TrangThaiCu = Status
        FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
        WHERE TrackingCode = @MaVanDon;

        IF @OrderId IS NULL
        BEGIN
            THROW 50001, N'Khong tim thay don hang.', 1;
        END;

        IF @NguoiCapNhatId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @NguoiCapNhatId)
        BEGIN
            THROW 50002, N'Nguoi cap nhat khong ton tai.', 1;
        END;

        -- Danh sach nay phai khop CHECK constraint cua bang Orders
        IF @TrangThaiMoi NOT IN
        (
            N'Pending',
            N'Approved',
            N'Rejected',
            N'Scheduled',
            N'InTransit',
            N'Completed',
            N'Failed'
        )
        BEGIN
            THROW 50003, N'Trang thai don hang khong hop le.', 1;
        END;

        IF @TrangThaiCu <> @TrangThaiMoi
        BEGIN
            UPDATE dbo.Orders
            SET Status = @TrangThaiMoi
            WHERE OrderId = @OrderId;

            INSERT INTO dbo.DeliveryHistory
            (
                OrderId,
                OldStatus,
                NewStatus,
                UpdatedBy,
                Note,
                UpdatedAt
            )
            VALUES
            (
                @OrderId,
                @TrangThaiCu,
                @TrangThaiMoi,
                @NguoiCapNhatId,
                @GhiChu,
                SYSDATETIME()
            );
        END;

        COMMIT TRANSACTION;

        SELECT
            @MaVanDon AS MaVanDon,
            @TrangThaiCu AS TrangThaiCu,
            @TrangThaiMoi AS TrangThaiMoi,
            N'Cap nhat trang thai thanh cong.' AS ThongBao;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


-- 2.3. DUYET DON HANG THEO OrderId (API approve-sp goi procedure nay)

CREATE OR ALTER PROCEDURE dbo.sp_DuyetVaPhanCongDonHang
    @OrderId INT,
    @NguoiCapNhatId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaVanDon NVARCHAR(50);

    SELECT @MaVanDon = TrackingCode
    FROM dbo.Orders
    WHERE OrderId = @OrderId;

    IF @MaVanDon IS NULL
        THROW 50001, N'Khong tim thay don hang.', 1;

    EXEC dbo.sp_CapNhatTrangThaiDonHang
        @MaVanDon = @MaVanDon,
        @TrangThaiMoi = N'Approved',
        @NguoiCapNhatId = @NguoiCapNhatId,
        @GhiChu = N'Duyet don hang qua API';
END;
GO


-- ============================================================
-- 3. VIEWS THONG KE DON HANG
-- ============================================================

CREATE OR ALTER VIEW dbo.vw_ThongKeTheoTrangThai
AS
SELECT
    Status AS TrangThai,
    COUNT(*) AS TongSoDon,
    SUM
    (
        CASE
            WHEN Status = N'Completed'
                THEN COALESCE(DeliveryFee, 0)
            ELSE 0
        END
    ) AS DoanhThuDonThanhCong
FROM dbo.Orders
GROUP BY Status;
GO


CREATE OR ALTER VIEW dbo.vw_ThongKeDonHangTheoNgay
AS
SELECT
    CAST(CreatedDate AS DATE) AS Ngay,
    COUNT(*) AS TongSoDonTrongNgay,
    SUM(COALESCE(DeliveryFee, 0)) AS TongPhiGiaoHang,
    SUM
    (
        CASE
            WHEN Status = N'Completed'
                THEN COALESCE(DeliveryFee, 0)
            ELSE 0
        END
    ) AS DoanhThuDonThanhCong
FROM dbo.Orders
GROUP BY CAST(CreatedDate AS DATE);
GO


CREATE OR ALTER VIEW dbo.vw_ThongKeDonTheoTram
AS
SELECT
    s.StationId AS MaTram,
    s.StationName AS TenTram,
    COUNT(o.OrderId) AS SoLuongDonGui
FROM dbo.Stations AS s
LEFT JOIN dbo.Orders AS o
    ON s.StationId = o.DepartureStationId
GROUP BY
    s.StationId,
    s.StationName;
GO


-- ============================================================
-- 4. CAC CAU LENH KIEM TRA (chay tung lenh khi can)
-- ============================================================

-- EXEC dbo.sp_XemDanhSachDonHang;
-- EXEC dbo.sp_XemChiTietDonHang @MaVanDon = N'DRONE-2026-001';
-- EXEC dbo.sp_TimKiemDonHang @TuKhoa = N'DRONE-2026-001';
-- EXEC dbo.sp_XemLichSuVanChuyen @MaVanDon = N'DRONE-2026-001';
-- EXEC dbo.sp_CapNhatTrangThaiDonHang
--     @MaVanDon = N'DRONE-2026-001',
--     @TrangThaiMoi = N'Approved',
--     @NguoiCapNhatId = 1,
--     @GhiChu = N'Don hang da duoc duyet';
-- EXEC dbo.sp_DuyetVaPhanCongDonHang @OrderId = 101;
-- SELECT * FROM dbo.vw_ThongKeTheoTrangThai;
-- SELECT * FROM dbo.vw_ThongKeDonHangTheoNgay;
-- SELECT * FROM dbo.vw_ThongKeDonTheoTram;
GO