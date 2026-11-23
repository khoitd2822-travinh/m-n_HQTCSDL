using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

namespace SmartDroneDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class PasswordResetController : ControllerBase
    {
        private record Pending(string Code, DateTime Expires, int Tries);
        private static readonly ConcurrentDictionary<string, Pending> Codes = new();

        private readonly AppDbContext _context;
        public PasswordResetController(AppDbContext context) { _context = context; }

        // Bước 1: kiểm tra email + số điện thoại, tạo mã (giả lập SMS)
        [HttpPost("request")]
        public async Task<IActionResult> RequestCode([FromBody] ResetRequestDto dto)
        {
            var email = (dto.Email ?? "").Trim().ToLowerInvariant();
            var phone = (dto.Phone ?? "").Trim();
            var n = await _context.Database.SqlQuery<int>(
                $"SELECT COUNT(*) AS Value FROM dbo.Users WHERE Email = {email} AND PhoneNumber = {phone}")
                .FirstOrDefaultAsync();
            if (n == 0)
                return BadRequest(new { message = "Email hoặc số điện thoại không khớp với tài khoản." });

            var code = RandomNumberGenerator.GetInt32(0, 1000000).ToString("D6");
            Codes[email] = new Pending(code, DateTime.Now.AddMinutes(5), 0);
            return Ok(new
            {
                message = "Đã gửi mã xác nhận (giả lập SMS).",
                demoCode = code // bản thật: gửi SMS/email, không trả về ở đây
            });
        }

        // Bước 2: nhập mã + mật khẩu mới
        [HttpPost("confirm")]
        public async Task<IActionResult> Confirm([FromBody] ResetConfirmDto dto)
        {
            var email = (dto.Email ?? "").Trim().ToLowerInvariant();
            var newPw = dto.NewPassword ?? "";
            if (newPw.Length < 6 || newPw.Length > 50 || !Regex.IsMatch(newPw, @"^[\x21-\x7E]+$"))
                return BadRequest(new { message = "Mật khẩu mới từ 6 đến 50 ký tự, không dấu, không khoảng trắng." });

            if (!Codes.TryGetValue(email, out var p) || p.Expires < DateTime.Now)
            {
                Codes.TryRemove(email, out _);
                return BadRequest(new { message = "Mã không tồn tại hoặc đã hết hạn. Hãy yêu cầu mã mới." });
            }
            if (p.Code != (dto.Code ?? "").Trim())
            {
                if (p.Tries + 1 >= 5) Codes.TryRemove(email, out _);
                else Codes[email] = p with { Tries = p.Tries + 1 };
                return BadRequest(new { message = "Mã xác nhận không đúng." });
            }

            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                UPDATE dbo.Users
                SET PasswordHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST({newPw} AS VARCHAR(100))), 2)
                WHERE Email = {email}");
            Codes.TryRemove(email, out _);
            return Ok(new { message = "Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới." });
        }
    }

    public class ResetRequestDto
    {
        public string? Email { get; set; }
        public string? Phone { get; set; }
    }

    public class ResetConfirmDto
    {
        public string? Email { get; set; }
        public string? Code { get; set; }
        public string? NewPassword { get; set; }
    }
}