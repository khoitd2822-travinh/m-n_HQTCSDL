using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "SystemAdmin")]
    public class UsersController : ControllerBase
    {
        private static readonly string[] Roles =
            { "Customer", "Dispatcher", "StationOperator", "LogisticsManager", "SystemAdmin" };

        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // Danh sách người dùng (không trả mật khẩu)
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var rows = await _context.Database.SqlQuery<UserRow>($@"
                SELECT UserId AS Id, FullName, Email, PhoneNumber, UserRole AS Role, CreatedDate
                FROM dbo.Users ORDER BY UserId").ToListAsync();
            return Ok(rows);
        }

        // Đổi vai trò
        [HttpPut("{id}/role")]
        public async Task<IActionResult> ChangeRole(int id, [FromBody] RoleDto dto)
        {
            if (dto.Role == null || !Roles.Contains(dto.Role))
                return BadRequest(new { message = "Vai trò không hợp lệ." });
            if (id == User.GetUserId())
                return BadRequest(new { message = "Không thể tự đổi vai trò của chính mình." });

            var n = await _context.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE dbo.Users SET UserRole = {dto.Role} WHERE UserId = {id}");
            if (n == 0) return NotFound(new { message = "Không tìm thấy người dùng." });
            return Ok(new { message = "Đã đổi vai trò." });
        }

    }

    public class RoleDto
    {
        public string? Role { get; set; }
    }

    public class UserRow
    {
        public int Id { get; set; }
        public string FullName { get; set; } = "";
        public string Email { get; set; } = "";
        public string? PhoneNumber { get; set; }
        public string Role { get; set; } = "";
        public DateTime? CreatedDate { get; set; }
    }
}