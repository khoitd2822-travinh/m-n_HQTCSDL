-- =====================================================
-- SmartDroneDelivery - CSDL (PostgreSQL 14+ & PostGIS)
-- =====================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------- ENUM ----------
CREATE TYPE user_role AS ENUM
    ('Customer', 'Dispatcher', 'StationOperator', 'LogisticsManager', 'SystemAdmin');

CREATE TYPE station_status AS ENUM ('Available', 'Busy', 'Maintenance');

CREATE TYPE drone_status AS ENUM ('Idle', 'InFlight', 'Charging', 'Maintenance');

CREATE TYPE order_status AS ENUM
    ('Pending', 'Approved', 'Rejected', 'Scheduled', 'InTransit',
     'ArrivedAtStation', 'Delivered', 'Failed', 'Cancelled');

CREATE TYPE delivery_status AS ENUM ('Scheduled', 'InFlight', 'Completed', 'Failed');

-- ---------- BANG ----------
CREATE TABLE users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role          user_role    NOT NULL DEFAULT 'Customer',
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label        VARCHAR(50),
    address_text VARCHAR(255) NOT NULL,
    location     geography(Point, 4326),
    is_default   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE landing_stations (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    address_text VARCHAR(255),
    location     geography(Point, 4326) NOT NULL,
    status       station_status NOT NULL DEFAULT 'Available',
    capacity     INT NOT NULL DEFAULT 2 CHECK (capacity > 0),
    operator_id  BIGINT REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE drones (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code               VARCHAR(30) NOT NULL UNIQUE,
    model              VARCHAR(50),
    max_payload_kg     NUMERIC(5,2) NOT NULL CHECK (max_payload_kg > 0),
    battery_pct        INT NOT NULL DEFAULT 100 CHECK (battery_pct BETWEEN 0 AND 100),
    status             drone_status NOT NULL DEFAULT 'Idle',
    current_station_id BIGINT REFERENCES landing_stations(id) ON DELETE SET NULL
);

CREATE TABLE orders (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id        BIGINT NOT NULL REFERENCES users(id),
    pickup_station_id  BIGINT NOT NULL REFERENCES landing_stations(id),
    dropoff_station_id BIGINT NOT NULL REFERENCES landing_stations(id),
    status             order_status NOT NULL DEFAULT 'Pending',
    estimated_minutes  INT CHECK (estimated_minutes >= 0),  -- phi chuan hoa co chu y: luu ket qua AI
    reject_reason      VARCHAR(255),
    note               VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_diff_station CHECK (pickup_station_id <> dropoff_station_id)
);

CREATE TABLE packages (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    description VARCHAR(255),
    weight_kg   NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0),
    image_url   VARCHAR(500)   -- duong dan doi tuong tren MinIO
);

CREATE TABLE deliveries (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       BIGINT NOT NULL UNIQUE REFERENCES orders(id),
    drone_id       BIGINT REFERENCES drones(id),
    dispatcher_id  BIGINT REFERENCES users(id),
    status         delivery_status NOT NULL DEFAULT 'Scheduled',
    scheduled_at   TIMESTAMPTZ,
    started_at     TIMESTAMPTZ,
    completed_at   TIMESTAMPTZ,
    failure_reason VARCHAR(255)
);

CREATE TABLE delivery_confirmations (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id  BIGINT NOT NULL UNIQUE REFERENCES deliveries(id) ON DELETE CASCADE,
    otp_code     VARCHAR(10) NOT NULL,
    confirmed_by BIGINT REFERENCES users(id),   -- station operator
    confirmed_at TIMESTAMPTZ
);

CREATE TABLE telemetry_logs (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id BIGINT NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    location    geography(Point, 4326) NOT NULL,
    altitude_m  NUMERIC(6,1),
    battery_pct INT CHECK (battery_pct BETWEEN 0 AND 100),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_status_history (   -- Audit log trang thai don
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    old_status order_status,
    new_status order_status NOT NULL,
    changed_by BIGINT REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    note       VARCHAR(255)
);

CREATE TABLE chat_messages (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender     VARCHAR(10) NOT NULL CHECK (sender IN ('user', 'assistant')),
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE delivery_summaries (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id  BIGINT NOT NULL UNIQUE REFERENCES deliveries(id) ON DELETE CASCADE,
    summary_text TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- INDEX ----------
CREATE INDEX idx_addresses_location ON addresses USING GIST (location);
CREATE INDEX idx_stations_location  ON landing_stations USING GIST (location);
CREATE INDEX idx_telemetry_location ON telemetry_logs USING GIST (location);

CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_deliveries_drone   ON deliveries (drone_id);
CREATE INDEX idx_telemetry_delivery ON telemetry_logs (delivery_id, recorded_at);
CREATE INDEX idx_history_order      ON order_status_history (order_id, changed_at);
CREATE INDEX idx_chat_user          ON chat_messages (user_id, created_at);

-- ---------- TRIGGER: tu dong ghi audit log khi doi trang thai don ----------
CREATE OR REPLACE FUNCTION fn_log_order_status() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO order_status_history(order_id, old_status, new_status, changed_by)
        VALUES (NEW.id, NULL, NEW.status, NEW.customer_id);
    ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
        NEW.updated_at := now();
        INSERT INTO order_status_history(order_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_status_ins
    AFTER INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_log_order_status();

CREATE TRIGGER trg_orders_status_upd
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_log_order_status();

-- ---------- DU LIEU MAU ----------
INSERT INTO users (full_name, email, phone, password_hash, role) VALUES
 ('Nguyen Van A', 'customer@demo.vn',   '0900000001', 'hash_demo', 'Customer'),
 ('Tran Thi B',   'dispatcher@demo.vn', '0900000002', 'hash_demo', 'Dispatcher'),
 ('Le Van C',     'operator1@demo.vn',  '0900000003', 'hash_demo', 'StationOperator'),
 ('Pham Thi D',   'operator2@demo.vn',  '0900000004', 'hash_demo', 'StationOperator'),
 ('Hoang Van E',  'manager@demo.vn',    '0900000005', 'hash_demo', 'LogisticsManager'),
 ('Admin',        'admin@demo.vn',      '0900000006', 'hash_demo', 'SystemAdmin');

INSERT INTO addresses (user_id, label, address_text, location, is_default) VALUES
 (1, 'Nha', 'Quan Thu Duc, TP.HCM',
  ST_SetSRID(ST_MakePoint(106.7717, 10.8500), 4326)::geography, TRUE);

-- ST_MakePoint(kinh do, vi do)
INSERT INTO landing_stations (name, address_text, location, status, capacity, operator_id) VALUES
 ('Tram A - Cong chinh',  'Cong chinh khuon vien',
  ST_SetSRID(ST_MakePoint(106.7700, 10.8510), 4326)::geography, 'Available', 2, 3),
 ('Tram B - Ky tuc xa',   'Khu ky tuc xa',
  ST_SetSRID(ST_MakePoint(106.7780, 10.8470), 4326)::geography, 'Available', 2, 4),
 ('Tram C - Thu vien',    'Khu giang duong',
  ST_SetSRID(ST_MakePoint(106.7740, 10.8530), 4326)::geography, 'Busy', 1, NULL);

INSERT INTO drones (code, model, max_payload_kg, battery_pct, status, current_station_id) VALUES
 ('DR-001', 'Quadcopter X1', 2.50, 100, 'Idle',     1),
 ('DR-002', 'Quadcopter X1', 2.50,  80, 'Charging', 2);

INSERT INTO orders (customer_id, pickup_station_id, dropoff_station_id, estimated_minutes, note) VALUES
 (1, 1, 2, 6, 'Giao tai lieu'),
 (1, 2, 1, 5, 'Giao thuoc');

INSERT INTO packages (order_id, description, weight_kg) VALUES
 (1, 'Tai lieu hoc tap', 0.50),
 (2, 'Hop thuoc',        0.30);

-- Duyet don 1 va tao chuyen giao (trigger se ghi audit log)
UPDATE orders SET status = 'Approved' WHERE id = 1;

INSERT INTO deliveries (order_id, drone_id, dispatcher_id, status, scheduled_at)
VALUES (1, 1, 2, 'Scheduled', now() + interval '10 minutes');

UPDATE orders SET status = 'Scheduled' WHERE id = 1;


