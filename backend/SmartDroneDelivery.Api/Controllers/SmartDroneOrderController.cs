using SmartDroneDelivery.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;

[ApiController]
[Route("api/[controller]")]
public class SmartDroneOrderController : ControllerBase
{
    private readonly AppDbContext _context;

    public SmartDroneOrderController(AppDbContext context)
    {
        _context = context;
    }

    // 1. Tạo đơn hàng mới và lưu vào DB
    [HttpPost("create")]
    public async Task<IActionResult> CreateOrder([FromBody] OrderCreateRequestDto request)
    {
        var order = new Order
        {
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        return Ok(new { 
            message = "Tạo đơn hàng thành công và đã lưu vào cơ sở dữ liệu!", 
            data = order 
        });
    }

    // 2. Xác nhận đơn hàng
    [HttpPost("{id}/confirm-delivery")]
    public async Task<IActionResult> ConfirmDelivery(int id, [FromBody] OtpConfirmDto dto)
    {
        var order = await _context.Orders.FindAsync(id);
        if (order == null)
        {
            return NotFound(new { message = "Không tìm thấy đơn hàng trong cơ sở dữ liệu!" });
        }

        order.Status = "Completed";
        await _context.SaveChangesAsync();

        return Ok(new { 
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
            // Thực thi Stored Procedure sp_DuyetVaPhanCongDonHang trong PostgreSQL
            await _context.Database.ExecuteSqlRawAsync("CALL sp_DuyetVaPhanCongDonHang({0})", id);

            return Ok(new { message = $"Đã gọi Stored Procedure thành công cho đơn hàng #{id}!" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = "Lỗi khi thực thi Stored Procedure", error = ex.Message });
        }
    }
}

public class OrderCreateRequestDto {
    public string? CustomerName { get; set; }
    public string? ItemName { get; set; }
    public decimal Weight { get; set; }
}

public class OtpConfirmDto {
    public string? OtpCode { get; set; }
}