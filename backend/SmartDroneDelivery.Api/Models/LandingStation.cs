using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartDroneDelivery.Api.Models
{
    [Table("Stations")]
    public class LandingStation
    {
        [Key]
        public int StationId { get; set; }

        [MaxLength(100)]
        public string StationName { get; set; } = string.Empty;

        [MaxLength(255)]
        public string LocationAddress { get; set; } = string.Empty;

        public double Latitude { get; set; }
        public double Longitude { get; set; }

        [MaxLength(20)]
        public string Status { get; set; } = string.Empty;
    }
}