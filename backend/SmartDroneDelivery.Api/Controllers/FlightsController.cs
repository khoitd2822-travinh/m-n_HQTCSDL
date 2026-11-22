using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FlightsController : ControllerBase
    {
        // Thời gian một chuyến bay giả lập (giây). Chỉnh cho hợp với buổi demo.
        private const double FlightSeconds = 60;

        private readonly AppDbContext _context;

        public FlightsController(AppDbContext context)
        {
            _context = context;
        }

        // Danh sách các chuyến đang bay kèm vị trí drone hiện tại
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var rows = await _context.Database.SqlQuery<FlightRow>($@"
                SELECT o.OrderId, o.TrackingCode,
                       s1.StationName AS FromName, s1.Latitude AS FromLat, s1.Longitude AS FromLng,
                       s2.StationName AS ToName,   s2.Latitude AS ToLat,   s2.Longitude AS ToLng,
                       (SELECT MAX(h.UpdatedAt) FROM dbo.DeliveryHistory h
                         WHERE h.OrderId = o.OrderId AND h.NewStatus = N'InTransit') AS StartedAt
                FROM dbo.Orders o
                JOIN dbo.Stations s1 ON s1.StationId = o.DepartureStationId
                JOIN dbo.Stations s2 ON s2.StationId = o.ArrivalStationId
                WHERE o.Status = N'InTransit'").ToListAsync();
            
            if (User.IsInRole("Customer"))
            {
                var userId = User.GetUserId();
                var mine = await _context.Database
                    .SqlQuery<MyOrderDto>($"EXEC dbo.sp_XemDonHangCuaKhach @CustomerId = {userId}")
                    .ToListAsync();
                var myIds = mine.Select(m => m.MaDon).ToHashSet();
                rows = rows.Where(r => myIds.Contains(r.OrderId)).ToList();
            }

            var now = DateTime.Now;
            var result = rows.Select(r =>
            {
                var elapsed = r.StartedAt.HasValue ? (now - r.StartedAt.Value).TotalSeconds : 0;
                var p = Math.Clamp(elapsed / FlightSeconds, 0, 1);
                return new
                {
                    r.OrderId,
                    r.TrackingCode,
                    origin = new { name = r.FromName, lat = r.FromLat, lng = r.FromLng },
                    destination = new { name = r.ToName, lat = r.ToLat, lng = r.ToLng },
                    progress = Math.Round(p, 3),
                    lat = r.FromLat + (r.ToLat - r.FromLat) * p,
                    lng = r.FromLng + (r.ToLng - r.FromLng) * p,
                    arrived = p >= 1,
                    remainingSeconds = (int)Math.Ceiling(Math.Max(0, FlightSeconds - elapsed))
                };
            });
            return Ok(result);
        }
    }

    public class FlightRow
    {
        public int OrderId { get; set; }
        public string TrackingCode { get; set; } = "";
        public string FromName { get; set; } = "";
        public double FromLat { get; set; }
        public double FromLng { get; set; }
        public string ToName { get; set; } = "";
        public double ToLat { get; set; }
        public double ToLng { get; set; }
        public DateTime? StartedAt { get; set; }
    }
}