using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartDroneDelivery.Api.Data
{
    [Table("Users")]
    public class User
    {
        [Key]
        [Column("UserId")]
        public int Id { get; set; }

        [Column("Username")]
        public string Username { get; set; } = string.Empty;

        [Column("PasswordHash")]
        public string PasswordHash { get; set; } = string.Empty;

        
        [Column("UserRole")]
        public string? UserRole { get; set; } = "Customer";
    }
}