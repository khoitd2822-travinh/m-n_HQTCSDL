using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProfileController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProfileController(AppDbContext context)
        {
            _context = context;
        }

        // Xem hồ sơ của chính mình
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var id = User.GetUserId();
            var rows = await _context.Database.SqlQuery<UserRow>($@"
                SELECT UserId AS Id, FullName, Email, PhoneNumber, UserRole AS Role, CreatedDate
                FROM dbo.Users WHERE UserId = {id}").ToListAsync();
            var u = rows.FirstOrDefault();
            return u == null ? NotFound(new { message = "Không tìm thấy tài khoản." }) : Ok(u);
        }

        // Sửa tên và số điện thoại
        [HttpPut("me")]
        public async Task<IActionResult> Update([FromBody] ProfileDto dto)
        {
            var name = (dto.FullName ?? "").Trim();
            var phone = (dto.PhoneNumber ?? "").Trim();
            if (name.Length < 2 || name.Length > 100)
                return BadRequest(new { message = "Họ tên phải từ 2 đến 100 ký tự." });
            if (phone.Length > 0 && !Regex.IsMatch(phone, @"^[0-9+ ]{9,15}$"))
                return BadRequest(new { message = "Số điện thoại không hợp lệ." });

            var id = User.GetUserId();
            var n = await _context.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE dbo.Users SET FullName = {name}, PhoneNumber = {phone} WHERE UserId = {id}");
            if (n == 0) return NotFound(new { message = "Không tìm thấy tài khoản." });
            return Ok(new { message = "Đã cập nhật hồ sơ.", fullName = name });
        }

        // Tự đổi mật khẩu (phải đúng mật khẩu cũ)
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] PasswordDto dto)
        {
            var oldPw = dto.OldPassword ?? "";
            var newPw = dto.NewPassword ?? "";
            if (newPw.Length < 6 || newPw.Length > 50)
                return BadRequest(new { message = "Mật khẩu mới phải từ 6 đến 50 ký tự." });
            if (!Regex.IsMatch(newPw, @"^[\x21-\x7E]+$"))
                return BadRequest(new { message = "Mật khẩu mới chỉ dùng chữ không dấu, số và ký tự thường gặp, không có khoảng trắng." });
            if (newPw == oldPw)
                return BadRequest(new { message = "Mật khẩu mới phải khác mật khẩu cũ." });

            var id = User.GetUserId();
            var n = await _context.Database.ExecuteSqlInterpolatedAsync($@"
                UPDATE dbo.Users
                SET PasswordHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST({newPw} AS VARCHAR(100))), 2)
                WHERE UserId = {id}
                  AND PasswordHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST({oldPw} AS VARCHAR(100))), 2)");
            if (n == 0) return BadRequest(new { message = "Mật khẩu cũ không đúng." });
            return Ok(new { message = "Đã đổi mật khẩu." });
        }
    }

    public class ProfileDto
    {
        public string? FullName { get; set; }
        public string? PhoneNumber { get; set; }
    }

    public class PasswordDto
    {
        public string? OldPassword { get; set; }
        public string? NewPassword { get; set; }
    }
}