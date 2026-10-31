from pydantic import BaseModel, Field

class ETARequest(BaseModel):
    distance_km: float = Field(gt=0, le=1000, description="Khoảng cách đường bay dự kiến, km")
    drone_speed_kmh: float = Field(default=30, gt=0, le=200, description="Tốc độ giả định, km/h")
    station_delay_min: float = Field(default=0, ge=0, le=600)
    weather_delay_min: float = Field(default=0, ge=0, le=600)

class ETAResponse(BaseModel):
    eta_minutes: int
    method: str
    note: str

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    order_id: str | None = None

class ChatResponse(BaseModel):
    reply: str
    mode: str = "demo-rule-based"

class SummaryRequest(BaseModel):
    order_id: str
    status: str
    origin_station: str
    destination_station: str
    drone_id: str | None = None
    battery_pct: int | None = Field(default=None, ge=0, le=100)
    notes: list[str] = []

class SummaryResponse(BaseModel):
    summary: str
    mode: str = "demo-template"


class MockDataRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=500, description="Số bản ghi giả lập cần tạo")
    seed: int | None = Field(default=None, description="Seed tùy chọn để tái tạo dữ liệu")

class MockDeliveryRecord(BaseModel):
    record_id: str
    distance_km: float
    payload_weight_kg: float
    weather: str
    wind_speed_kmh: float
    rain_mm: float
    station_delay_min: float
    drone_speed_kmh: float
    eta_minutes: int

class MockDataResponse(BaseModel):
    count: int
    source: str
    records: list[MockDeliveryRecord]
