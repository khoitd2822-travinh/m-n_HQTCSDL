-- 1. Thêm dữ liệu mẫu cho bảng users (Đủ 5 phân quyền)
INSERT INTO users (full_name, email, password_hash, phone, role, is_active) VALUES
('System Admin', 'admin@smartdrone.com', 'hashed_password_1', '0901111111', 'Admin', true),
('Dispatcher Nam', 'dispatcher@smartdrone.com', 'hashed_password_2', '0902222222', 'Dispatcher', true),
('Station Operator An', 'operator@smartdrone.com', 'hashed_password_3', '0903333333', 'StationOperator', true),
('Logistics Manager Hùng', 'manager@smartdrone.com', 'hashed_password_4', '0904444444', 'LogisticsManager', true),
('Customer Lan', 'customer@smartdrone.com', 'hashed_password_5', '0905555555', 'Customer', true);

-- 2. Thêm dữ liệu mẫu cho bảng landing_stations (Tọa độ PostGIS: Longitude Latitude)
INSERT INTO landing_stations (name, address_text, location, status, capacity, operator_id) VALUES
('Trạm A - Khu Công Nghệ Cao', 'Lô T2, Đường D1, TP. Thủ Đức', 'POINT(106.794 10.845)', 'Available', 5, 3),
('Trạm B - Ký Túc Xá Khu B', 'Đông Hòa, Dĩ An, Bình Dương', 'POINT(106.805 10.880)', 'Available', 3, 3),
('Trạm C - Vinhomes Grand Park', 'Long Thạnh Mỹ, TP. Thủ Đức', 'POINT(106.840 10.841)', 'Available', 10, 3);

-- 3. Thêm dữ liệu mẫu cho bảng drones
INSERT INTO drones (code, model, max_payload_kg, battery_pct, status, current_station_id) VALUES
('DRONE-01', 'DJI FlyCart 30', 10.0, 100.0, 'Idle', 1),
('DRONE-02', 'DJI FlyCart 30', 10.0, 85.0, 'Idle', 1),
('DRONE-03', 'Custom Delivery Drone', 5.0, 92.0, 'Idle', 2);