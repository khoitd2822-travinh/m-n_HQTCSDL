using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;
using SmartDroneDelivery.Api.Models;

namespace SmartDroneDelivery.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StationsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StationsController(AppDbContext context)
        {
            _context = context;
        }

        // 1. Lấy danh sách tất cả các trạm hạ cánh
        [HttpGet]
        public async Task<ActionResult<IEnumerable<LandingStation>>> GetStations()
        {
            return await _context.LandingStations.ToListAsync();
        }

        // 2. Cập nhật trạng thái trạm (Free / Busy / Maintenance)
        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateStationStatus(int id, [FromBody] string status)
        {
            var station = await _context.LandingStations.FindAsync(id);
            if (station == null) return NotFound(new { message = "Không tìm thấy trạm hạ cánh." });

            station.Status = status;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật trạng thái trạm thành công.", station });
        }

        // 3. Tìm trạm trống gần nhất dựa trên tọa độ giao hàng
        [HttpGet("nearest")]
        public async Task<ActionResult<LandingStation>> GetNearestStation([FromQuery] double targetLat, [FromQuery] double targetLng)
        {
            var stations = await _context.LandingStations
                .Where(s => s.Status == "Free")
                .ToListAsync();

            if (!stations.Any()) return NotFound(new { message = "Hiện không có trạm hạ cánh nào trống." });

            // Tính khoảng cách tối ưu để chọn trạm gần nhất
            var nearestStation = stations.OrderBy(s => 
                Math.Pow(s.Latitude - targetLat, 2) + Math.Pow(s.Longitude - targetLng, 2)
            ).FirstOrDefault();

            return Ok(nearestStation);
        }
    }
}