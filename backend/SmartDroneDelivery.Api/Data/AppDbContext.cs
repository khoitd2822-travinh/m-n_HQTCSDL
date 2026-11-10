using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SmartDroneDelivery.Api.Models;

namespace SmartDroneDelivery.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<LandingStation> LandingStations { get; set; }
        public DbSet<Drone> Drones { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<Order>().ToTable("Orders");
            modelBuilder.Entity<LandingStation>().ToTable("Stations");
            modelBuilder.Entity<Drone>().ToTable("Drones");
        }
    }

    [Table("Orders")]
    public class Order
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("OrderId")]
        public int Id { get; set; }

        [Column("TrackingCode")]
        public string TrackingCode { get; set; } = string.Empty;

        [Column("CustomerId")]
        public int? CustomerId { get; set; }

        [Column("DepartureStationId")]
        public int? PickupStationId { get; set; }

        [Column("ArrivalStationId")]
        public int? DropoffStationId { get; set; }

        [Column("ReceiverName")]
        public string ReceiverName { get; set; } = string.Empty;

        [Column("ReceiverPhone")]
        public string ReceiverPhone { get; set; } = string.Empty;

        [Column("ReceiverAddress")]
        public string ReceiverAddress { get; set; } = string.Empty;

        [Column("PackageWeightKg")]
        public double PackageWeightKg { get; set; }

        [Column("DeliveryFee", TypeName = "decimal(18,2)")]
        public decimal DeliveryFee { get; set; }

        [Column("Status")]
        public string Status { get; set; } = "Draft";

        [Column("CreatedDate")]
        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;

        // DB không có cột này -> không lưu vào DB
        [NotMapped]
        public decimal EstimatedMinutes { get; set; }
    }

    [Table("Drones")]
    public class Drone
    {
        [Key]
        [Column("Id")]
        public int Id { get; set; }

        [Column("Code")]
        public string Code { get; set; } = string.Empty;

        [Column("Status")]
        public string Status { get; set; } = "Available";
    }
}