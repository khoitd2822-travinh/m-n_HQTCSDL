USE DroneDeliveryDB;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XemLichSuVanChuyen
    @MaVanDon NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.TrackingCode AS MaVanDon,
        h.OldStatus    AS TrangThaiCu,
        h.NewStatus    AS TrangThaiMoi,
        h.UpdatedAt    AS ThoiGianCapNhat,
        u.FullName     AS NguoiCapNhat,
        h.Note         AS GhiChu
    FROM dbo.Orders AS o
    INNER JOIN dbo.DeliveryHistory AS h ON o.OrderId = h.OrderId
    LEFT JOIN dbo.Users AS u ON h.UpdatedBy = u.UserId
    WHERE o.TrackingCode = @MaVanDon
    ORDER BY h.UpdatedAt ASC, h.HistoryId ASC;
END;
GO

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

        SELECT @OrderId = OrderId, @TrangThaiCu = Status
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
        (N'Pending', N'Approved', N'Rejected', N'Scheduled', N'InTransit', N'Completed', N'Failed')
        BEGIN
            THROW 50003, N'Trang thai don hang khong hop le.', 1;
        END;

        IF @TrangThaiCu <> @TrangThaiMoi
        BEGIN
            UPDATE dbo.Orders SET Status = @TrangThaiMoi WHERE OrderId = @OrderId;

            INSERT INTO dbo.DeliveryHistory (OrderId, OldStatus, NewStatus, UpdatedBy, Note, UpdatedAt)
            VALUES (@OrderId, @TrangThaiCu, @TrangThaiMoi, @NguoiCapNhatId, @GhiChu, SYSDATETIME());
        END;

        COMMIT TRANSACTION;

        SELECT
            @MaVanDon     AS MaVanDon,
            @TrangThaiCu  AS TrangThaiCu,
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

-- API approve-sp goi procedure nay
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

CREATE OR ALTER PROCEDURE dbo.sp_XemDanhSachDonHang
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId        AS [Ma Don],
        o.TrackingCode   AS [Ma Van Don],
        c.FullName       AS [Ten Khach Hang],
        s.StationName    AS [Tram Gui],
        o.ReceiverName   AS [Ten Nguoi Nhan],
        o.ReceiverPhone  AS [SDT Nguoi Nhan],
        o.ReceiverAddress AS [Dia Chi Nhan],
        o.PackageWeightKg AS [Khoi Luong (Kg)],
        o.DeliveryFee    AS [Phi Giao Hang],
        o.Status         AS [Trang Thai],
        o.CreatedDate    AS [Ngay Tao]
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c ON o.CustomerId = c.UserId
    LEFT JOIN dbo.Stations AS s ON o.DepartureStationId = s.StationId
    ORDER BY o.CreatedDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XemChiTietDonHang
    @MaVanDon NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId        AS MaDon,
        o.TrackingCode   AS MaVanDon,
        c.FullName       AS TenKhachHang,
        c.PhoneNumber    AS SDTKhachHang,
        o.ReceiverName   AS TenNguoiNhan,
        o.ReceiverPhone  AS SDTNguoiNhan,
        o.ReceiverAddress AS DiaChiGiao,
        o.PackageWeightKg AS KhoiLuongKg,
        o.DeliveryFee    AS PhiGiaoHang,
        o.Status         AS TrangThai,
        o.CreatedDate    AS NgayTao
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c ON o.CustomerId = c.UserId
    WHERE o.TrackingCode = @MaVanDon;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TimKiemDonHang
    @TuKhoa NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId        AS MaDon,
        o.TrackingCode   AS MaVanDon,
        c.FullName       AS TenKhachHang,
        o.ReceiverAddress AS DiaChiGiao,
        o.PackageWeightKg AS KhoiLuongKg,
        o.Status         AS TrangThai,
        o.CreatedDate    AS NgayTao
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Users AS c ON o.CustomerId = c.UserId
    WHERE o.TrackingCode LIKE N'%' + @TuKhoa + N'%'
       OR c.FullName LIKE N'%' + @TuKhoa + N'%'
       OR o.ReceiverAddress LIKE N'%' + @TuKhoa + N'%'
    ORDER BY o.CreatedDate DESC;
END;
GO

-- MOI: don hang cua mot khach (cho man hinh Customer tren mobile)
CREATE OR ALTER PROCEDURE dbo.sp_XemDonHangCuaKhach
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        o.OrderId         AS MaDon,
        o.TrackingCode    AS MaVanDon,
        o.ReceiverName    AS TenNguoiNhan,
        o.ReceiverAddress AS DiaChiGiao,
        o.PackageWeightKg AS KhoiLuongKg,
        o.DeliveryFee     AS PhiGiaoHang,
        o.Status          AS TrangThai,
        o.EstimatedMinutes AS ThoiGianDuKienPhut,
        o.OtpCode         AS MaOtp,
        o.CreatedDate     AS NgayTao
    FROM dbo.Orders AS o
    WHERE o.CustomerId = @CustomerId
    ORDER BY o.CreatedDate DESC;
END;
GO

CREATE OR ALTER VIEW dbo.vw_ThongKeDonHangTheoNgay
AS
SELECT
    CAST(CreatedDate AS DATE) AS Ngay,
    COUNT(*) AS TongSoDonTrongNgay,
    SUM(COALESCE(DeliveryFee, 0)) AS TongPhiGiaoHang,
    SUM(CASE WHEN Status = N'Completed' THEN COALESCE(DeliveryFee, 0) ELSE 0 END) AS DoanhThuDonThanhCong
FROM dbo.Orders
GROUP BY CAST(CreatedDate AS DATE);
GO

CREATE OR ALTER VIEW dbo.vw_ThongKeDonTheoTram
AS
SELECT
    s.StationId   AS MaTram,
    s.StationName AS TenTram,
    COUNT(o.OrderId) AS SoLuongDonGui
FROM dbo.Stations AS s
LEFT JOIN dbo.Orders AS o ON s.StationId = o.DepartureStationId
GROUP BY s.StationId, s.StationName;
GO

CREATE OR ALTER VIEW dbo.vw_ThongKeTheoTrangThai
AS
SELECT
    Status AS TrangThai,
    COUNT(*) AS TongSoDon,
    SUM(CASE WHEN Status = N'Completed' THEN COALESCE(DeliveryFee, 0) ELSE 0 END) AS DoanhThuDonThanhCong
FROM dbo.Orders
GROUP BY Status;
GO