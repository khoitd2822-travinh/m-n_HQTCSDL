using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;

namespace SmartDroneDelivery.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    public record LoginBody(string? Username, string? Email, string? Password);

    private readonly IConfiguration _config;
    public AuthController(IConfiguration config) => _config = config;

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginBody req)
    {
        var login = (req.Email ?? req.Username ?? "").Trim();
        if (login == "" || string.IsNullOrEmpty(req.Password))
            return BadRequest(new { message = "Thiếu tài khoản hoặc mật khẩu." });

        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(req.Password)));

        await using var conn = new SqlConnection(_config.GetConnectionString("DefaultConnection"));
        await conn.OpenAsync();
        await using var cmd = new SqlCommand(
            "SELECT UserId, FullName, Email, UserRole FROM Users WHERE Email = @e AND PasswordHash = @h", conn);
        cmd.Parameters.AddWithValue("@e", login);
        cmd.Parameters.AddWithValue("@h", hash);

        await using var rd = await cmd.ExecuteReaderAsync();
        if (!await rd.ReadAsync())
            return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu." });

        var userId = rd.GetInt32(0);
        var fullName = rd.GetString(1);
        var email = rd.GetString(2);
        var role = rd.GetString(3);

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Name, fullName),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Role, role)
        };
        var jwt = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return Ok(new
        {
            token = new JwtSecurityTokenHandler().WriteToken(jwt),
            userId, fullName, email, role
        });
    }
}