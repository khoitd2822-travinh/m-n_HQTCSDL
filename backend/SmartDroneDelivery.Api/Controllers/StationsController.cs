using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;
using SmartDroneDelivery.Api.Models;

[Route("api/[controller]")]
[ApiController]
public class StationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public StationsController(AppDbContext context)
    {
        _context = context;
    }

    // 1. Danh sách trạm (giữ mở để app Flutter đang chạy không bị ảnh hưởng)
    [HttpGet]
    public async Task<IActionResult> GetAllStations()
    {
        var stations = await _context.LandingStations.ToListAsync();
        return Ok(stations);
    }

    // 2. Thêm trạm: chỉ Quản lý và Admin
    [HttpPost]
    [Authorize(Roles = "LogisticsManager,SystemAdmin")]
    public async Task<IActionResult> CreateStation([FromBody] LandingStation station)
    {
        _context.LandingStations.Add(station);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Thêm trạm hạ cánh thành công", station });
    }

    // 3. Sửa thông tin trạm: chỉ Quản lý và Admin
    [HttpPut("{id}")]
    [Authorize(Roles = "LogisticsManager,SystemAdmin")]
    public async Task<IActionResult> UpdateStation(int id, [FromBody] LandingStation updatedStation)
    {
        var station = await _context.LandingStations.FindAsync(id);
        if (station == null) return NotFound(new { message = "Không tìm thấy trạm hạ cánh" });

        station.StationName = updatedStation.StationName;
        station.LocationAddress = updatedStation.LocationAddress;
        station.Latitude = updatedStation.Latitude;
        station.Longitude = updatedStation.Longitude;
        station.Status = updatedStation.Status;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Cập nhật trạm thành công", station });
    }

    // 3b. MỚI: chỉ đổi trạng thái trạm (Sẵn sàng / Bận / Bảo trì)
    [HttpPut("{id}/status")]
    [Authorize(Roles = "StationOperator,Dispatcher,LogisticsManager,SystemAdmin")]
    public async Task<IActionResult> ChangeStationStatus(int id, [FromBody] StationStatusDto dto)
    {
        var allowed = new[] { "Available", "Busy", "Maintenance" };
        if (dto.Status == null || !allowed.Contains(dto.Status))
            return BadRequest(new { message = "Trạng thái trạm không hợp lệ." });

        var station = await _context.LandingStations.FindAsync(id);
        if (station == null) return NotFound(new { message = "Không tìm thấy trạm hạ cánh" });

        station.Status = dto.Status;
        await _context.SaveChangesAsync();
        return Ok(new { message = "Đã đổi trạng thái trạm.", station });
    }

    // 4. Xóa trạm: chỉ Admin
    [HttpDelete("{id}")]
    [Authorize(Roles = "SystemAdmin")]
    public async Task<IActionResult> DeleteStation(int id)
    {
        var station = await _context.LandingStations.FindAsync(id);
        if (station == null) return NotFound(new { message = "Không tìm thấy trạm hạ cánh" });

        _context.LandingStations.Remove(station);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Đã xóa trạm hạ cánh thành công" });
    }
}

public class StationStatusDto
{
    public string? Status { get; set; }
}