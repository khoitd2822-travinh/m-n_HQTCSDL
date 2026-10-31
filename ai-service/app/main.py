from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from .schemas import ETARequest, ETAResponse, ChatRequest, ChatResponse, SummaryRequest, SummaryResponse, MockDataRequest, MockDataResponse, MockDeliveryRecord
import random

app = FastAPI(title="SmartDroneDelivery AI Service", version="0.1.0", description="Starter API for ETA, customer chatbot and delivery summaries.")

# Development setting for local integration. Restrict allowed origins before production deployment.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=False, allow_methods=["*"], allow_headers=["*"])

@app.get("/health", tags=["system"])
def health():
    return {"status": "ok", "service": "smartdrone-ai-service", "version": "0.1.0"}

@app.post("/api/v1/eta", response_model=ETAResponse, tags=["AI - ETA"])
def estimate_eta(payload: ETARequest):
    """Rule-based estimate only; replace with a trained model and real telemetry later."""
    flight_minutes = (payload.distance_km / payload.drone_speed_kmh) * 60
    total = round(flight_minutes + payload.station_delay_min + payload.weather_delay_min)
    return ETAResponse(eta_minutes=max(1, total), method="rule-based-baseline", note="Ước tính demo, chưa được huấn luyện/kiểm chứng trên dữ liệu giao hàng thực tế.")

@app.post("/api/v1/chat", response_model=ChatResponse, tags=["AI - Chatbot"])
def chat(payload: ChatRequest):
    """Keyword-based placeholder. Connect order service/LLM for production responses."""
    message = payload.message.lower()
    if any(word in message for word in ["ở đâu", "trạng thái", "đơn hàng", "order"]):
        reply = f"Bạn hãy kiểm tra trạng thái đơn {payload.order_id} trong mục Đơn hàng. Đây là chatbot demo nên chưa truy vấn dữ liệu trực tiếp."
    elif any(word in message for word in ["bao lâu", "eta", "mấy phút", "khi nào"]):
        reply = "Thời gian giao dự kiến sẽ được hiển thị tại chi tiết đơn hàng sau khi hệ thống ETA được kết nối."
    else:
        reply = "Xin chào! Tôi là chatbot demo SmartDrone. Bạn có thể hỏi về trạng thái đơn hàng hoặc thời gian giao dự kiến."
    return ChatResponse(reply=reply)

@app.post("/api/v1/summary", response_model=SummaryResponse, tags=["AI - Summary"])
def summarize(payload: SummaryRequest):
    """Template summary placeholder; replace with an LLM or summarization model later."""
    parts = [f"Đơn {payload.order_id} hiện ở trạng thái {payload.status}.", f"Lộ trình: {payload.origin_station} đến {payload.destination_station}."]
    if payload.drone_id:
        parts.append(f"Drone phụ trách: {payload.drone_id}.")
    if payload.battery_pct is not None:
        parts.append(f"Dung lượng pin hiện ghi nhận: {payload.battery_pct}%.")
    if payload.notes:
        parts.append("Ghi chú: " + "; ".join(payload.notes) + ".")
    return SummaryResponse(summary=" ".join(parts))


@app.get("/api/v1/mock-data", response_model=MockDataResponse, tags=["Data - Simulation"])
def get_mock_data(count: int = Query(default=10, ge=1, le=500), seed: int | None = Query(default=None)):
    """Generate reproducible or random synthetic delivery features for ETA experiments."""
    return _generate_mock_records(count, seed)

@app.post("/api/v1/mock-data", response_model=MockDataResponse, tags=["Data - Simulation"])
def create_mock_data(payload: MockDataRequest):
    """Generate synthetic distance, payload, weather and ETA records; no database writes."""
    return _generate_mock_records(payload.count, payload.seed)

def _generate_mock_records(count: int, seed: int | None):
    rng = random.Random(seed)
    records = []
    weather_options = ["clear", "cloudy", "light_rain", "windy"]
    weather_delay = {"clear": 0, "cloudy": 1, "light_rain": 4, "windy": 5}
    for i in range(count):
        distance = round(rng.uniform(0.5, 12.0), 2)
        weight = round(rng.uniform(0.1, 4.5), 2)
        weather = rng.choice(weather_options)
        wind = round(rng.uniform(0, 35), 1)
        rain = round(rng.uniform(0, 8), 1) if weather == "light_rain" else 0.0
        station_delay = round(rng.uniform(0, 5), 1)
        speed = round(rng.uniform(22, 42), 1)
        extra_weather = weather_delay[weather] + (2 if wind > 25 else 0)
        eta = max(1, round(distance / speed * 60 + station_delay + extra_weather))
        records.append(MockDeliveryRecord(record_id=f"SIM-{i+1:04d}", distance_km=distance, payload_weight_kg=weight, weather=weather, wind_speed_kmh=wind, rain_mm=rain, station_delay_min=station_delay, drone_speed_kmh=speed, eta_minutes=eta))
    return MockDataResponse(count=len(records), source="synthetic-random-demo", records=records)
