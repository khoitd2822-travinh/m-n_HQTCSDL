using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [Route("api/orders")]
    [ApiController]
    [Authorize]
    public class OrderWorkflowController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrderWorkflowController(AppDbContext context)
        {
            _context = context;
        }

        // 1. Duyệt đơn (Pending -> Approved)
        [HttpPost("{id}/approve")]
        [Authorize(Roles = "Dispatcher,SystemAdmin")]
        public Task<IActionResult> ApproveOrder(int id)
            => ChangeStatus(id, new[] { "Pending" }, "Approved",
                "Duyet don hang", "Đã duyệt đơn hàng.");

        // 2. Từ chối đơn (Pending -> Rejected), có thể kèm lý do
        [HttpPost("{id}/reject")]
        [Authorize(Roles = "Dispatcher,SystemAdmin")]
        public Task<IActionResult> RejectOrder(int id,
            [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] StatusNoteDto? dto = null)
            => ChangeStatus(id, new[] { "Pending" }, "Rejected",
                dto?.Note ?? "Tu choi don hang", "Đã từ chối đơn hàng.");

        // 3. Bắt đầu giao (Approved/Scheduled -> InTransit)
                // Ghi chú đánh dấu đã lấy hàng (lưu trong bảng lịch sử)
        private const string PickupNote = "Da lay hang tai tram";

        // 3a. MỚI: Xác nhận lấy hàng tại trạm gửi (không đổi trạng thái đơn)
        [HttpPost("{id}/pickup")]
        [Authorize(Roles = "StationOperator,SystemAdmin")]
        public async Task<IActionResult> ConfirmPickup(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng." });
            if (order.Status != "Approved" && order.Status != "Scheduled")
                return BadRequest(new { message = $"Đơn đang ở trạng thái {order.Status}, không thể xác nhận lấy hàng." });
            if (await HasPickup(id))
                return BadRequest(new { message = "Đơn này đã được xác nhận lấy hàng rồi." });

            var userId = User.GetUserId();
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"INSERT INTO dbo.DeliveryHistory (OrderId, OldStatus, NewStatus, UpdatedBy, Note) VALUES ({id}, {order.Status}, {order.Status}, {userId}, {PickupNote})");
            return Ok(new { message = "Đã xác nhận lấy hàng tại trạm gửi." });
        }

        // 3b. Bắt đầu giao (Approved/Scheduled -> InTransit), bắt buộc đã lấy hàng
        [HttpPost("{id}/start")]
        [Authorize(Roles = "Dispatcher,StationOperator,SystemAdmin")]
        public async Task<IActionResult> StartDelivery(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order != null
                && (order.Status == "Approved" || order.Status == "Scheduled")
                && !await HasPickup(id))
                return BadRequest(new { message = "Chưa xác nhận lấy hàng tại trạm gửi. Nhân viên trạm cần bấm \"Xác nhận lấy hàng\" trước." });

            return await ChangeStatus(id, new[] { "Approved", "Scheduled" }, "InTransit",
                "Drone bat dau giao hang", "Drone đã xuất phát.");
        }

        // 4. Giao thất bại (-> Failed)
        [HttpPost("{id}/fail")]
        [Authorize(Roles = "Dispatcher,StationOperator,SystemAdmin")]
        public Task<IActionResult> HandleFailedDelivery(int id,
            [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] StatusNoteDto? dto = null)
            => ChangeStatus(id, new[] { "Approved", "Scheduled", "InTransit" }, "Failed",
                dto?.Note ?? "Giao hang that bai", "Đã ghi nhận giao hàng thất bại.");

        // 5. Khách tự hủy đơn của mình khi đang Chờ duyệt
        [HttpPost("{id}/cancel")]
        [Authorize(Roles = "Customer")]
        public async Task<IActionResult> CancelOrder(int id)
        {
            var userId = User.GetUserId();
            var mine = await _context.Database
                .SqlQuery<MyOrderDto>($"EXEC dbo.sp_XemDonHangCuaKhach @CustomerId = {userId}")
                .ToListAsync();
            if (!mine.Any(m => m.MaDon == id))
                return NotFound(new { message = "Không tìm thấy đơn hàng của bạn." });

            return await ChangeStatus(id, new[] { "Pending" }, "Cancelled",
                "Khach huy don", "Đã hủy đơn hàng.");
        }

                // 6. Xếp lịch giao (Approved -> Scheduled), ghi giờ vào ghi chú lịch sử
        [HttpPost("{id}/schedule")]
        [Authorize(Roles = "Dispatcher,SystemAdmin")]
        public Task<IActionResult> ScheduleOrder(int id,
            [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] StatusNoteDto? dto = null)
            => ChangeStatus(id, new[] { "Approved" }, "Scheduled",
                dto?.Note ?? "Xep lich giao", "Đã xếp lịch giao.");

        // 7. Lịch sử đổi trạng thái của một đơn
        [HttpGet("{id}/history")]
        public async Task<IActionResult> History(int id)
        {
            if (User.IsInRole("Customer"))
            {
                var userId = User.GetUserId();
                var mine = await _context.Database
                    .SqlQuery<MyOrderDto>($"EXEC dbo.sp_XemDonHangCuaKhach @CustomerId = {userId}")
                    .ToListAsync();
                if (!mine.Any(m => m.MaDon == id))
                    return NotFound(new { message = "Không tìm thấy đơn hàng của bạn." });
            }

            var rows = await _context.Database.SqlQuery<HistoryRow>($@"
                SELECT h.OldStatus, h.NewStatus, h.UpdatedAt, u.FullName AS UpdatedByName, h.Note
                FROM dbo.DeliveryHistory h
                LEFT JOIN dbo.Users u ON u.UserId = h.UpdatedBy
                WHERE h.OrderId = {id}
                ORDER BY h.UpdatedAt, h.HistoryId").ToListAsync();
            return Ok(rows);
        }

                private async Task<bool> HasPickup(int orderId)
        {
            var n = await _context.Database
                .SqlQuery<int>($"SELECT COUNT(*) AS Value FROM dbo.DeliveryHistory WHERE OrderId = {orderId} AND Note = {PickupNote}")
                .FirstOrDefaultAsync();
            return n > 0;
        }


        private async Task<IActionResult> ChangeStatus(
            int id, string[] allowedFrom, string newStatus, string note, string okMessage)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng." });

            if (!allowedFrom.Contains(order.Status))
                return BadRequest(new
                {
                    message = $"Đơn đang ở trạng thái {order.Status}, không thể chuyển sang {newStatus}."
                });

            var userId = User.GetUserId();
            try
            {
                await _context.Database.ExecuteSqlInterpolatedAsync(
                    $"EXEC dbo.sp_CapNhatTrangThaiDonHang @MaVanDon = {order.TrackingCode}, @TrangThaiMoi = {newStatus}, @NguoiCapNhatId = {userId}, @GhiChu = {note}");
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Không đổi được trạng thái.", error = ex.Message });
            }

            await _context.Entry(order).ReloadAsync();
            return Ok(new { message = okMessage, order });
        }
    }

    public class StatusNoteDto
    {
        public string? Note { get; set; }
    }
        public class HistoryRow
    {
        public string? OldStatus { get; set; }
        public string NewStatus { get; set; } = "";
        public DateTime UpdatedAt { get; set; }
        public string? UpdatedByName { get; set; }
        public string? Note { get; set; }
    }
}