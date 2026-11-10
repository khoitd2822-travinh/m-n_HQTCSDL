using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartDroneDelivery.Api.Data
{
    [Table("Users")]
    public class User
    {
        [Key]
        public int UserId { get; set; }

        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;

        [MaxLength(20)]
        public string PhoneNumber { get; set; } = string.Empty;

        [MaxLength(30)]
        public string UserRole { get; set; } = string.Empty;

        public DateTime? CreatedDate { get; set; }
    }
}