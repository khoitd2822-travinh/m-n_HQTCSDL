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
        [HttpPost("{id}/start")]
        [Authorize(Roles = "Dispatcher,StationOperator,SystemAdmin")]
        public Task<IActionResult> StartDelivery(int id)
            => ChangeStatus(id, new[] { "Approved", "Scheduled" }, "InTransit",
                "Drone bat dau giao hang", "Drone đã xuất phát.");

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
}