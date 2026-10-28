using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema; // Thêm thư viện này để dùng [Column]

namespace SmartDroneDelivery.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<Package> Packages { get; set; }
        public DbSet<LandingStation> LandingStations { get; set; }
        public DbSet<Drone> Drones { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);           
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Order>()
                .Property(o => o.Status)
                .HasColumnType("order_status");
            modelBuilder.Entity<Package>().ToTable("packages");
            modelBuilder.Entity<LandingStation>().ToTable("landing_stations");
            modelBuilder.Entity<Drone>().ToTable("drones");
        }
    }

    [Table("packages")]
    public class Package
    {
        [Column("id")]
        public int Id { get; set; }
        [Column("weight_kg")]
        public decimal WeightKg { get; set; }
        [Column("dimensions")]
        public string Dimensions { get; set; } = string.Empty;
        [Column("description")]
        public string Description { get; set; } = string.Empty;
        [Column("image_url")]
        public string? ImageUrl { get; set; }
    }

    [Table("orders")]
    public class Order
    {
        [Column("id")]
        public int Id { get; set; }
        
        [Column("customer_id")]
        public int CustomerId { get; set; }
        
        [Column("pickup_station_id")]
        public int PickupStationId { get; set; }
        
        [Column("dropoff_station_id")]
        public int DropoffStationId { get; set; }
        
        
        [Column("status")]
        public string Status { get; set; } = "Draft";
        
        [Column("estimated_minutes")]
        public decimal EstimatedMinutes { get; set; }
        
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("landing_stations")]
    public class LandingStation
    {
        [Column("id")]
        public int Id { get; set; }
        [Column("name")]
        public string Name { get; set; } = string.Empty;
        [Column("status")]
        public string Status { get; set; } = string.Empty;
        [Column("capacity")]
        public int Capacity { get; set; }
    }

    [Table("drones")]
    public class Drone
    {
        [Column("id")]
        public int Id { get; set; }
        [Column("code")]
        public string Code { get; set; } = string.Empty;
        [Column("status")]
        public string Status { get; set; } = string.Empty;
    }
}