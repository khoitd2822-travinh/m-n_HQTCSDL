from datetime import datetime
from typing import Optional
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="SmartDrone AI Service", version="0.1.0",
              description="Demo endpoints for ETA estimation, customer chatbot, and delivery summaries.")

# Cho phép trang web và app Flutter (chạy trên trình duyệt) gọi trực tiếp sang dịch vụ này
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

DRONE_SPEED_KMH = 45  # tốc độ bay giả định, khớp với công thức dự phòng của backend


class ETARequest(BaseModel):
    distance_km: float = Field(gt=0, description="Estimated route distance in kilometers")
    package_weight_kg: float = Field(default=0.5, ge=0)
    drone_battery_pct: int = Field(default=100, ge=0, le=100)
    weather_delay_min: int = Field(default=0, ge=0)
    station_delay_min: int = Field(default=1, ge=0)


class ChatRequest(BaseModel):
    message: str
    order_status: Optional[str] = "Unknown"
    estimated_minutes: Optional[int] = None


class SummaryRequest(BaseModel):
    order_code: str
    status: str
    pickup_station: str
    dropoff_station: str
    drone_code: str = "Not assigned"
    battery_pct: int = 100
    note: Optional[str] = None
    estimated_minutes: Optional[int] = None
    actual_minutes: Optional[int] = None


STATUS_VI = {"Pending": "chờ duyệt", "Approved": "đã duyệt", "Rejected": "bị từ chối",
             "Scheduled": "đã xếp lịch", "InTransit": "đang giao", "Completed": "hoàn tất",
             "Failed": "thất bại", "Cancelled": "đã hủy"}


@app.get("/")
def root():
    return {"service": "SmartDrone AI Service", "status": "running",
            "endpoints": ["/ai/eta", "/ai/chat", "/ai/summary", "/docs"]}

@app.get("/health")
def health():
    return {"status": "ok", "service": "smartdrone-ai-service"}

@app.post("/ai/eta")
def estimate_eta(data: ETARequest):
    # Baseline demo formula, not a trained ML model.
    # Replace this formula with a model trained on historical deliveries later.
    flight_minutes = (data.distance_km / DRONE_SPEED_KMH) * 60
    weight_delay = max(0, data.package_weight_kg - 1.0) * 1.5
    battery_delay = 5 if data.drone_battery_pct < 30 else (2 if data.drone_battery_pct < 50 else 0)
    eta = round(flight_minutes + weight_delay + battery_delay +
                data.weather_delay_min + data.station_delay_min)
    return {"estimated_minutes": max(1, eta),
            "method": "baseline_rule",
            "explanation": "Ước tính demo dựa trên khoảng cách, tải trọng, pin, thời tiết và thời gian xử lý tại trạm.",
            "disclaimer": "Đây là ước tính mẫu, chưa phải dự đoán ML đã được huấn luyện."}


@app.post("/ai/chat")
def chatbot(data: ChatRequest):
    message = data.message.lower()
    if any(word in message for word in ["đơn", "order", "trạng thái", "status", "giao đến đâu"]):
        eta_text = f" Thời gian dự kiến còn khoảng {data.estimated_minutes} phút." if data.estimated_minutes is not None else ""
        answer = f"Trạng thái đơn hiện tại là: {data.order_status}.{eta_text} Bạn có thể kiểm tra lại trong mục Đơn hàng."
    elif any(word in message for word in ["trạm", "station", "drone", "pin"]):
        answer = "Bạn hãy mở mục Trạm gần đây hoặc thông tin chuyến giao để xem trạm, drone và tình trạng pin. Nếu là nhân viên trạm, hãy kiểm tra bảng điều khiển trạm."
    elif any(word in message for word in ["xin chào", "hello", "hi"]):
        answer = "Xin chào! Tôi là trợ lý SmartDrone. Bạn muốn kiểm tra đơn hàng, thời gian giao dự kiến hay thông tin trạm?"
    else:
        answer = "Mình có thể hỗ trợ kiểm tra trạng thái đơn hàng, thời gian giao dự kiến và thông tin trạm/drone. Bạn vui lòng nói rõ nội dung cần kiểm tra nhé."
    return {"reply": answer, "mode": "demo_rules",
            "note": "Chatbot hiện dùng quy tắc từ khóa; có thể thay bằng mô hình ngôn ngữ khi nhóm tích hợp AI thật."}


@app.post("/ai/summary")
def summarize(data: SummaryRequest):
    parts = [f"Đơn {data.order_code} {STATUS_VI.get(data.status, data.status)}.",
             f"Lộ trình: {data.pickup_station} đến {data.dropoff_station}."]

    if data.actual_minutes is not None:
        text = f"Thời gian giao thực tế: {data.actual_minutes} phút"
        if data.estimated_minutes is not None:
            diff = data.actual_minutes - data.estimated_minutes
            if diff > 0:
                text += f", chậm hơn dự kiến {diff} phút"
            elif diff < 0:
                text += f", nhanh hơn dự kiến {-diff} phút"
            else:
                text += ", đúng như dự kiến"
        parts.append(text + ".")
    elif data.estimated_minutes is not None:
        parts.append(f"Thời gian dự kiến: {data.estimated_minutes} phút.")

    # Chỉ nhắc drone và pin khi đơn đang giao và đã có drone được phân công
    if data.status == "InTransit" and data.drone_code not in ("Not assigned", "Chưa phân công", ""):
        if data.battery_pct < 30:
            advice = "Pin thấp, cần kiểm tra."
        elif data.battery_pct < 50:
            advice = "Pin ở mức trung bình, nên theo dõi."
        else:
            advice = "Pin tốt."
        parts.append(f"Drone {data.drone_code}, pin {data.battery_pct}%. {advice}")

    if data.note:
        parts.append(f"Ghi chú: {data.note}.")

    return {"summary": " ".join(parts), "created_at": datetime.now().isoformat(timespec="seconds"),
            "method": "template_summary",
            "disclaimer": "Tóm tắt demo được tạo theo mẫu, chưa sử dụng mô hình sinh ngôn ngữ."}