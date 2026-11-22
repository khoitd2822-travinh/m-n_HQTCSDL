using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;
using SmartDroneDelivery.Api.Models;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrdersController(AppDbContext context)
        {
            _context = context;
        }

        // Nhân viên xem toàn bộ đơn hàng
        [HttpGet]
        [Authorize(Roles = "Dispatcher,StationOperator,LogisticsManager,SystemAdmin")]
        public async Task<IActionResult> GetOrders()
        {
            var orders = await _context.Orders.OrderByDescending(o => o.CreatedAt).ToListAsync();
            return Ok(orders);
        }

        // Khách xem đơn của chính mình (kèm mã OTP để đọc cho nhân viên trạm)
        [HttpGet("mine")]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> GetMyOrders()
        {
            var userId = User.GetUserId();
            var data = await _context.Database
                .SqlQuery<MyOrderDto>($"EXEC dbo.sp_XemDonHangCuaKhach @CustomerId = {userId}")
                .ToListAsync();
            return Ok(data);
        }
    }

    public class MyOrderDto
    {
        public int MaDon { get; set; }
        public string MaVanDon { get; set; } = string.Empty;
        public string TenNguoiNhan { get; set; } = string.Empty;
        public string DiaChiGiao { get; set; } = string.Empty;
        public double KhoiLuongKg { get; set; }
        public decimal PhiGiaoHang { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public int? ThoiGianDuKienPhut { get; set; }
        public string MaOtp { get; set; } = string.Empty;
        public DateTime NgayTao { get; set; }
    }
}