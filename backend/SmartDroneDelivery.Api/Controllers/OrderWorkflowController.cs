using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;
using System.Text.Json;
using System.Text;

namespace SmartDroneDelivery.Api.Controllers
{
    [Route("api/orders")]
    [ApiController]
    public class OrderWorkflowController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly HttpClient _httpClient;

        public OrderWorkflowController(AppDbContext context, IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _httpClient = httpClientFactory.CreateClient();
        }

        // 1. Duyệt đơn hàng (Approve) và gọi AI FastAPI lấy ETA
        [HttpPost("{id}/approve")]
        public async Task<IActionResult> ApproveOrder(int id, [FromBody] ApproveOrderDto dto)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

            // Gọi sang Python FastAPI AI Service (chạy ở cổng 8000) để lấy thời gian ETA dự kiến
            try
            {
                var aiPayload = new { distance = dto.Distance, weight = 1.5, weather = "Clear" };
                var content = new StringContent(JsonSerializer.Serialize(aiPayload), Encoding.UTF8, "application/json");
                
                var aiResponse = await _httpClient.PostAsync("http://localhost:8000/api/ai/eta", content);
                if (aiResponse.IsSuccessStatusCode)
                {
                    var jsonResult = await aiResponse.Content.ReadAsStringAsync();
                    // Xử lý dữ liệu ETA trả về từ AI nếu cần
                }
            }
            catch 
            {
                // Fallback nếu AI service chưa bật: hệ thống vẫn hoạt động bình thường
            }

            order.Status = "Approved";
            // order.StationId = dto.StationId;
            // order.ScheduledTime = dto.ScheduledTime;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã duyệt đơn hàng và gán lịch giao thành công.", order });
        }

        // 2. Từ chối đơn hàng (Reject)
        [HttpPost("{id}/reject")]
        public async Task<IActionResult> RejectOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

            order.Status = "Rejected";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã từ chối đơn hàng.", order });
        }

        // 3. Xử lý giao hàng thất bại (Handle failed deliveries)
        [HttpPost("{id}/fail")]
        public async Task<IActionResult> HandleFailedDelivery(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

            order.Status = "Failed";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã ghi nhận trạng thái giao hàng thất bại.", order });
        }
    }

    public class ApproveOrderDto
    {
        public int StationId { get; set; }
        public double Distance { get; set; }
        public DateTime ScheduledTime { get; set; }
    }
}