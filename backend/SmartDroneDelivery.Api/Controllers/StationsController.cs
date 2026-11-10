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

    // 1. Lấy danh sách toàn bộ trạm
    [HttpGet]
    public async Task<IActionResult> GetAllStations()
    {
        var stations = await _context.LandingStations.ToListAsync();
        return Ok(stations);
    }

    // 2. Thêm mới trạm hạ cánh
    [HttpPost]
    public async Task<IActionResult> CreateStation([FromBody] LandingStation station)
    {
        _context.LandingStations.Add(station);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Thêm trạm hạ cánh thành công", station });
    }

    // 3. Cập nhật thông tin trạm
    [HttpPut("{id}")]
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

    // 4. Xóa trạm hạ cánh
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteStation(int id)
    {
        var station = await _context.LandingStations.FindAsync(id);
        if (station == null) return NotFound(new { message = "Không tìm thấy trạm hạ cánh" });

        _context.LandingStations.Remove(station);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Đã xóa trạm hạ cánh thành công" });
    }
}