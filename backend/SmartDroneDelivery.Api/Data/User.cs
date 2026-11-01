namespace SmartDroneDelivery.Api.Data
{
    // 5 Roles theo đúng đề bài yêu cầu
    public static class UserRoles
    {
        public const string Customer = "Customer";
        public const string Dispatcher = "Dispatcher";
        public const string StationOperator = "StationOperator";
        public const string LogisticsManager = "LogisticsManager";
        public const string SystemAdmin = "SystemAdministrator";
    }

    public class User
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Role { get; set; } = UserRoles.Customer; // Default Role
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}