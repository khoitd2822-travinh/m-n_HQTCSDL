using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;
using System;
using System.Threading.Tasks;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SmartDroneOrderController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SmartDroneOrderController(AppDbContext context)
        {
            _context = context;
        }

        // 1. Tạo đơn hàng mới
        [HttpPost("create")]
        public async Task<IActionResult> CreateOrder([FromBody] OrderCreateRequestDto request)
        {
            var order = new Order
        {
            TrackingCode = "DRN" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
            CustomerId = request.CustomerId,
            PickupStationId = request.PickupStationId,
            DropoffStationId = request.DropoffStationId,
            ReceiverName = request.ReceiverName,
            ReceiverPhone = request.ReceiverPhone,
            ReceiverAddress = request.ReceiverAddress,
            PackageWeightKg = request.PackageWeightKg,
            DeliveryFee = request.DeliveryFee,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        return Ok(new {
            message = "Tạo đơn hàng thành công!",
            orderId = order.Id,
            trackingCode = order.TrackingCode,
            data = order
        });
    }

        // 2. Xác nhận đã giao hàng
        [HttpPost("{id}/confirm-delivery")]
        public async Task<IActionResult> ConfirmDelivery(int id, [FromBody] OtpConfirmDto dto)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn hàng trong cơ sở dữ liệu!" });
            }

    // TODO: kiểm tra dto.OtpCode trước khi hoàn tất đơn
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC dbo.sp_CapNhatTrangThaiDonHang @MaVanDon = {order.TrackingCode}, @TrangThaiMoi = N'Completed', @GhiChu = N'Xac nhan giao hang'");

            await _context.Entry(order).ReloadAsync();

            return Ok(new
        {
            message = "Xác nhận nhận hàng thành công, đơn hàng đã hoàn tất!",
            data = order
        });
    }

        // 3. Gọi Stored Procedure duyệt và phân công đơn hàng
        [HttpPost("{id}/approve-sp")]
        public async Task<IActionResult> ApproveOrderWithSp(int id)
        {
            try
            {
                await _context.Database.ExecuteSqlInterpolatedAsync(
                    $"EXEC sp_DuyetVaPhanCongDonHang {id}");

                return Ok(new { message = $"Đã gọi Stored Procedure thành công cho đơn hàng #{id}!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi khi thực thi Stored Procedure", error = ex.Message });
            }
        }
    }

    public class OrderCreateRequestDto
    {
        public int CustomerId { get; set; }
        public int PickupStationId { get; set; }
        public int DropoffStationId { get; set; }
        public string ReceiverName { get; set; } = string.Empty;
        public string ReceiverPhone { get; set; } = string.Empty;
        public string ReceiverAddress { get; set; } = string.Empty;
        public double PackageWeightKg { get; set; }
        public decimal DeliveryFee { get; set; }
        public decimal EstimatedMinutes { get; set; }
    }

    public class OtpConfirmDto
    {
        public string? OtpCode { get; set; }
    }
}