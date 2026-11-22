using System.Net.Http.Json;
using System.Text.Json;
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
    public class SmartDroneOrderController : ControllerBase
    {
        private const double MaxWeightKg = 5.0;

        private readonly AppDbContext _context;
        private readonly IHttpClientFactory _httpFactory;
        private readonly IConfiguration _config;

        public SmartDroneOrderController(AppDbContext context, IHttpClientFactory httpFactory, IConfiguration config)
        {
            _context = context;
            _httpFactory = httpFactory;
            _config = config;
        }

        // 1. Tạo đơn hàng mới
        [HttpPost("create")]
        [Authorize(Roles = "Customer,SystemAdmin")]
        public async Task<IActionResult> CreateOrder([FromBody] OrderCreateRequestDto request)
        {
            if (request.PickupStationId == request.DropoffStationId)
                return BadRequest(new { message = "Trạm gửi và trạm nhận phải khác nhau." });
            if (request.PackageWeightKg <= 0 || request.PackageWeightKg > MaxWeightKg)
                return BadRequest(new { message = $"Khối lượng phải trong khoảng (0, {MaxWeightKg}] kg." });
            if (string.IsNullOrWhiteSpace(request.ReceiverName) ||
                string.IsNullOrWhiteSpace(request.ReceiverPhone) ||
                string.IsNullOrWhiteSpace(request.ReceiverAddress))
                return BadRequest(new { message = "Thiếu thông tin người nhận." });

            var points = await _context.Database.SqlQuery<StationPoint>(
                $"SELECT StationId, Latitude, Longitude FROM dbo.Stations WHERE StationId = {request.PickupStationId} OR StationId = {request.DropoffStationId}")
                .ToListAsync();
            var src = points.FirstOrDefault(p => p.StationId == request.PickupStationId);
            var dst = points.FirstOrDefault(p => p.StationId == request.DropoffStationId);
            if (src == null || dst == null)
                return BadRequest(new { message = "Trạm gửi hoặc trạm nhận không tồn tại." });

            var distanceKm = DistanceKm(src.Latitude, src.Longitude, dst.Latitude, dst.Longitude);
            var fee = Math.Round((15000m + (decimal)distanceKm * 5000m + (decimal)request.PackageWeightKg * 3000m) / 1000m) * 1000m;
            var eta = await GetEtaMinutes(distanceKm, request.PackageWeightKg);

            var userId = User.GetUserId();
            var customerId = (User.IsInRole("Customer") || request.CustomerId <= 0) ? userId : request.CustomerId;

            var order = new Order
            {
                TrackingCode = "DRN" + Guid.NewGuid().ToString("N")[..8].ToUpper(),
                CustomerId = customerId,
                PickupStationId = request.PickupStationId,
                DropoffStationId = request.DropoffStationId,
                ReceiverName = request.ReceiverName.Trim(),
                ReceiverPhone = request.ReceiverPhone.Trim(),
                ReceiverAddress = request.ReceiverAddress.Trim(),
                PackageWeightKg = request.PackageWeightKg,
                DeliveryFee = fee,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE dbo.Orders SET EstimatedMinutes = {eta} WHERE OrderId = {order.Id}");
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"INSERT INTO dbo.DeliveryHistory (OrderId, OldStatus, NewStatus, UpdatedBy, Note) VALUES ({order.Id}, NULL, N'Pending', {customerId}, N'Khach tao don')");

            return Ok(new
            {
                message = "Tạo đơn hàng thành công!",
                orderId = order.Id,
                trackingCode = order.TrackingCode,
                distanceKm = Math.Round(distanceKm, 2),
                deliveryFee = fee,
                estimatedMinutes = eta
            });
        }

        // 2. Xác nhận đã giao hàng: nhân viên trạm nhập OTP khách đọc
        [HttpPost("{id}/confirm-delivery")]
        [Authorize(Roles = "StationOperator,SystemAdmin")]
        public async Task<IActionResult> ConfirmDelivery(int id, [FromBody] OtpConfirmDto dto)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng trong cơ sở dữ liệu!" });

            if (order.Status != "InTransit")
                return BadRequest(new { message = $"Đơn đang ở trạng thái {order.Status}, chỉ xác nhận giao khi đơn đang InTransit." });

            var otp = await _context.Database
                .SqlQuery<string>($"SELECT OtpCode AS Value FROM dbo.Orders WHERE OrderId = {id}")
                .FirstOrDefaultAsync();

            if (string.IsNullOrWhiteSpace(dto.OtpCode) || dto.OtpCode.Trim() != otp)
                return BadRequest(new { message = "Mã OTP không đúng." });

            var userId = User.GetUserId();
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC dbo.sp_CapNhatTrangThaiDonHang @MaVanDon = {order.TrackingCode}, @TrangThaiMoi = N'Completed', @NguoiCapNhatId = {userId}, @GhiChu = N'Xac nhan giao hang bang OTP'");

            await _context.Entry(order).ReloadAsync();
            return Ok(new { message = "Xác nhận nhận hàng thành công, đơn hàng đã hoàn tất!", data = order });
        }

        // 3. Duyệt đơn bằng Stored Procedure
        [HttpPost("{id}/approve-sp")]
        [Authorize(Roles = "Dispatcher,SystemAdmin")]
        public async Task<IActionResult> ApproveOrderWithSp(int id)
        {
            try
            {
                var userId = User.GetUserId();
                await _context.Database.ExecuteSqlInterpolatedAsync(
                    $"EXEC dbo.sp_DuyetVaPhanCongDonHang @OrderId = {id}, @NguoiCapNhatId = {userId}");
                return Ok(new { message = $"Đã gọi Stored Procedure thành công cho đơn hàng #{id}!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi khi thực thi Stored Procedure", error = ex.Message });
            }
        }


                private static readonly Dictionary<string, string> StatusVi = new()
        {
            ["Pending"] = "Chờ duyệt", ["Approved"] = "Đã duyệt", ["Rejected"] = "Từ chối",
            ["Scheduled"] = "Đã xếp lịch", ["InTransit"] = "Đang giao", ["Completed"] = "Hoàn tất",
            ["Failed"] = "Thất bại", ["Cancelled"] = "Đã hủy"
        };

        // 4. Tóm tắt chuyến giao (gọi AI service, lỗi thì dùng bản dự phòng)
        [HttpGet("{id}/summary")]
        [Authorize(Roles = "Dispatcher,StationOperator,LogisticsManager,SystemAdmin")]
        public async Task<IActionResult> Summary(int id)
        {
            var rows = await _context.Database.SqlQuery<SummaryRow>($@"
                SELECT o.TrackingCode, o.Status,
                       s1.StationName AS FromName, s2.StationName AS ToName,
                       (SELECT TOP 1 d.Code FROM dbo.Drones d WHERE d.CurrentStationId = o.DepartureStationId ORDER BY d.Id) AS DroneCode,
                       (SELECT TOP 1 d.BatteryPct FROM dbo.Drones d WHERE d.CurrentStationId = o.DepartureStationId ORDER BY d.Id) AS BatteryPct,
                       (SELECT TOP 1 h.Note FROM dbo.DeliveryHistory h WHERE h.OrderId = o.OrderId ORDER BY h.UpdatedAt DESC, h.HistoryId DESC) AS LastNote
                FROM dbo.Orders o
                JOIN dbo.Stations s1 ON s1.StationId = o.DepartureStationId
                JOIN dbo.Stations s2 ON s2.StationId = o.ArrivalStationId
                WHERE o.OrderId = {id}").ToListAsync();

            var r = rows.FirstOrDefault();
            if (r == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng." });

            var statusVi = StatusVi.GetValueOrDefault(r.Status, r.Status);
            try
            {
                var client = _httpFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(3);
                var baseUrl = _config["AiService:BaseUrl"] ?? "http://localhost:8000";
                var res = await client.PostAsJsonAsync($"{baseUrl}/ai/summary", new
                {
                    order_code = r.TrackingCode,
                    status = statusVi,
                    pickup_station = r.FromName,
                    dropoff_station = r.ToName,
                    drone_code = r.DroneCode ?? "Chưa phân công",
                    battery_pct = r.BatteryPct ?? 100,
                    note = r.LastNote
                });
                if (res.IsSuccessStatusCode)
                {
                    using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
                    return Ok(new { summary = doc.RootElement.GetProperty("summary").GetString(), source = "ai-service" });
                }
            }
            catch { }

            return Ok(new
            {
                summary = $"Đơn {r.TrackingCode} đang ở trạng thái {statusVi}. Lộ trình: {r.FromName} đến {r.ToName}.",
                source = "fallback"
            });
        }

        // Gọi AI service; nếu lỗi thì tính ETA dự phòng để hệ thống vẫn chạy
        private async Task<int> GetEtaMinutes(double distanceKm, double weightKg)
        {
            var fallback = (int)Math.Ceiling(distanceKm / 45.0 * 60.0 + 2);
            try
            {
                var client = _httpFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(3);
                var baseUrl = _config["AiService:BaseUrl"] ?? "http://localhost:8000";
                var res = await client.PostAsJsonAsync($"{baseUrl}/ai/eta", new
                {
                    distance_km = distanceKm,
                    package_weight_kg = weightKg,
                    drone_battery_pct = 85,
                    weather_delay_min = 0,
                    station_delay_min = 2
                });
                if (!res.IsSuccessStatusCode) return fallback;

                using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
                return (int)Math.Ceiling(doc.RootElement.GetProperty("estimated_minutes").GetDouble());
            }
            catch
            {
                return fallback;
            }
        }

        private static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371.0;
            double dLat = (lat2 - lat1) * Math.PI / 180;
            double dLon = (lon2 - lon1) * Math.PI / 180;
            double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                       Math.Cos(lat1 * Math.PI / 180) * Math.Cos(lat2 * Math.PI / 180) *
                       Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        }
    }

        public class SummaryRow
    {
        public string TrackingCode { get; set; } = "";
        public string Status { get; set; } = "";
        public string FromName { get; set; } = "";
        public string ToName { get; set; } = "";
        public string? DroneCode { get; set; }
        public int? BatteryPct { get; set; }
        public string? LastNote { get; set; }
    }

    public class StationPoint
    {
        public int StationId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }

    public class OrderCreateRequestDto
    {
        public int CustomerId { get; set; }   // chỉ dùng khi SystemAdmin tạo hộ khách
        public int PickupStationId { get; set; }
        public int DropoffStationId { get; set; }
        public string ReceiverName { get; set; } = string.Empty;
        public string ReceiverPhone { get; set; } = string.Empty;
        public string ReceiverAddress { get; set; } = string.Empty;
        public double PackageWeightKg { get; set; }
    }

    public class OtpConfirmDto
    {
        public string? OtpCode { get; set; }
    }
}