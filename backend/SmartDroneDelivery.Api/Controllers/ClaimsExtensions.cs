using System.Security.Claims;

namespace SmartDroneDelivery.Api.Controllers;

public static class ClaimsExtensions
{
    // Lấy UserId của người đang đăng nhập từ JWT
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var v = user.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? user.FindFirstValue("nameid")
                ?? user.FindFirstValue("sub");
        return int.TryParse(v, out var id) ? id : 0;
    }
}