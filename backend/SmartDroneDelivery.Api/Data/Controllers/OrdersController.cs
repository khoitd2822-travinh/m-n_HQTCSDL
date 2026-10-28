using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrdersController(AppDbContext context)
        {
            _context = context;
        }

        // GET /api/orders: Lấy danh sách toàn bộ đơn hàng
        [HttpGet]
        public async Task<IActionResult> GetOrders()
        {
            var orders = await _context.Orders.OrderByDescending(o => o.CreatedAt).ToListAsync();
            return Ok(orders);
        }

        // POST /api/orders: Tạo đơn hàng mới từ phía Client/Mobile
        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] Order order)
        {
            // Thiết lập giá trị mặc định khi tạo mới
            order.CreatedAt = DateTime.UtcNow;
            if (string.IsNullOrEmpty(order.Status))
            {
                order.Status = "Pending";
            }

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Tạo đơn hàng thành công!", 
                orderId = order.Id,
                data = order 
            });
        }
    }
}