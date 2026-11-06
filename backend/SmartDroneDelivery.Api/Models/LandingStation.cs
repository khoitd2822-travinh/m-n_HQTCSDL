namespace SmartDroneDelivery.Api.Models
{
    public class LandingStation
    {
        public int Id { get; set; }
        public string StationName { get; set; } = string.Empty;
        public double Latitude { get; set; }  // Vĩ độ
        public double Longitude { get; set; } // Kinh độ
        public string Status { get; set; } = "Free"; // "Free" (Trống), "Busy" (Bận), "Maintenance" (Bảo trì)
        public int Capacity { get; set; } = 5; // Sức chứa drone tối đa tại trạm
    }
}