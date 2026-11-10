using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        // Thống kê số đơn và doanh thu theo trạng thái
        [HttpGet("by-status")]
        public async Task<IActionResult> GetByStatus()
        {
            var data = await _context.Database
                .SqlQuery<ThongKeTrangThaiDto>($"SELECT * FROM dbo.vw_ThongKeTheoTrangThai")
                .ToListAsync();
            return Ok(data);
        }

        // Thống kê theo ngày
        [HttpGet("by-day")]
        public async Task<IActionResult> GetByDay()
        {
            var data = await _context.Database
                .SqlQuery<ThongKeNgayDto>($"SELECT * FROM dbo.vw_ThongKeDonHangTheoNgay ORDER BY Ngay DESC")
                .ToListAsync();
            return Ok(data);
        }

        // Thống kê số đơn gửi đi từ mỗi trạm
        [HttpGet("by-station")]
        public async Task<IActionResult> GetByStation()
        {
            var data = await _context.Database
                .SqlQuery<ThongKeTramDto>($"SELECT * FROM dbo.vw_ThongKeDonTheoTram")
                .ToListAsync();
            return Ok(data);
        }

        // Lịch sử vận chuyển theo mã vận đơn
        [HttpGet("history/{trackingCode}")]
        public async Task<IActionResult> GetHistory(string trackingCode)
        {
            var data = await _context.Database
                .SqlQuery<LichSuDto>($"EXEC dbo.sp_XemLichSuVanChuyen {trackingCode}")
                .ToListAsync();
            return Ok(data);
        }
    }

    public class ThongKeTrangThaiDto
    {
        public string TrangThai { get; set; } = string.Empty;
        public int TongSoDon { get; set; }
        public decimal DoanhThuDonThanhCong { get; set; }
    }

    public class ThongKeNgayDto
    {
        public DateTime Ngay { get; set; }
        public int TongSoDonTrongNgay { get; set; }
        public decimal TongPhiGiaoHang { get; set; }
        public decimal DoanhThuDonThanhCong { get; set; }
    }

    public class ThongKeTramDto
    {
        public int MaTram { get; set; }
        public string TenTram { get; set; } = string.Empty;
        public int SoLuongDonGui { get; set; }
    }

    public class LichSuDto
    {
        public string MaVanDon { get; set; } = string.Empty;
        public string? TrangThaiCu { get; set; }
        public string TrangThaiMoi { get; set; } = string.Empty;
        public DateTime ThoiGianCapNhat { get; set; }
        public string? NguoiCapNhat { get; set; }
        public string? GhiChu { get; set; }
    }
}