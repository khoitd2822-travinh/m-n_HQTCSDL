using Microsoft.EntityFrameworkCore;
using SmartDroneDelivery.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Cấu hình kết nối PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Cho phép Live Server (127.0.0.1:5500 hoặc localhost:5500) gọi API thoải mái
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Cấu hình phân quyền chi tiết dựa trên Role (RBAC)
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CustomerPolicy", policy => policy.RequireRole("Customer"));
    options.AddPolicy("DispatcherPolicy", policy => policy.RequireRole("Dispatcher", "Admin"));
    options.AddPolicy("OperatorPolicy", policy => policy.RequireRole("StationOperator", "Admin"));
    options.AddPolicy("LogisticsManagerPolicy", policy => policy.RequireRole("LogisticsManager", "Admin"));
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.UseCors("AllowAll");
app.MapControllers();

app.Run();