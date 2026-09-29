from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import requests
import traceback
import os

# Try importing from local config.py (ignored by git), fallback to environment variables for deployment (Render)
try:
    import config
    WEATHER_API_KEY = getattr(config, "WEATHER_API_KEY", None)
    GEMINI_API_KEY = getattr(config, "GEMINI_API_KEY", None)
except ImportError:
    WEATHER_API_KEY = os.environ.get("WEATHER_API_KEY")
    GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

# Safety check to ensure the key exists
if not WEATHER_API_KEY:
    raise ValueError("⚠️ WEATHER_API_KEY is missing! Make sure it is defined in your config.py or environment variables.")

app = FastAPI(title="Mausam Intelligent Weather API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class UserInterest(BaseModel):
    persona: str = Field(default="Commuter")

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "message": "Mausam backend is running successfully!"
    }

@app.get("/api/set-interest")
@app.post("/api/set-interest")
def set_user_interest(payload: UserInterest = None, persona: str = Query(default="Commuter")):
    resolved_persona = payload.persona if payload and payload.persona else persona
    return {
        "status": "success",
        "message": f"Persona set to {resolved_persona}! Custom weather engine initialized.",
        "persona": resolved_persona
    }

@app.get("/api/dashboard/{persona}")
def get_dashboard_data(
    persona: str, 
    city: str = "Coimbatore", 
    lat: float = None, 
    lon: float = None, 
    lang: str = "en"
):
    resolved_city = city
    
    temp = 30.0
    feels_like = 32.0
    humidity = 65
    pressure = 1012
    wind_speed = 4.5
    visibility = 10.0
    condition = "Clear sky"

    try:
        if lat is not None and lon is not None:
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={WEATHER_API_KEY}&units=metric"
            try:
                nominatim_url = f"https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={lat}&lon={lon}"
                geo_response = requests.get(nominatim_url, headers={'User-Agent': 'MausamWeatherApp/1.0'}, timeout=3)
                geo_data = geo_response.json()
                address = geo_data.get('address', {})
                resolved_city = (
                    address.get('suburb') or 
                    address.get('neighbourhood') or 
                    address.get('city_district') or 
                    address.get('town') or 
                    address.get('city') or 
                    resolved_city
                )
            except Exception:
                pass
        else:
            url = f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric"
        
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            temp = data['main']['temp']
            feels_like = data['main']['feels_like']
            humidity = data['main']['humidity']
            pressure = data['main']['pressure']
            wind_speed = data['wind']['speed']
            visibility = data.get('visibility', 10000) / 1000
            condition = data['weather'][0]['description'].capitalize()
            if lat is None:
                resolved_city = data['name']
    except Exception as e:
        print(f"⚠️ Weather fetch warning: {e}")

    is_alert = False
    risk_level = "Low Risk"
    if wind_speed > 12 or humidity > 85 or temp > 38:
        is_alert = True
        risk_level = "High Weather Risk"
    elif wind_speed > 8 or humidity > 70:
        risk_level = "Moderate Risk"

    resolved_persona = persona if persona.lower() != "auto" else "Commuter"

    # Dynamic contextual smart insight generation
    smart_insight = f"Conditions are stable at {round(temp)}°C with {condition.lower()}."
    actionable_tip = "Enjoy your day and stay comfortable!"
    
    if "rain" in condition.lower() or "shower" in condition.lower() or humidity > 80:
        smart_insight = f"🌧️ Rain or high moisture detected ({humidity}% humidity). Wet roads expected!"
        actionable_tip = "Recommendation: Carry a raincoat or umbrella and consider leaving 15 minutes earlier."
    elif temp > 35:
        smart_insight = f"☀️ Intense heat warning! Temperature feels like {round(feels_like)}°C."
        actionable_tip = "Recommendation: Stay hydrated and avoid direct sunlight during peak afternoon hours."
    elif wind_speed > 8:
        smart_insight = f"💨 Strong winds blowing at {wind_speed} m/s."
        actionable_tip = "Recommendation: Secure loose outdoor items and ride carefully if traveling by bike."

    templates = {
        "Farmer": {
            "headline": "Optimal moisture window for fields" if humidity < 75 else "High humidity crop watch alert",
            "advice": f"Immediate Impact: Temperature at {round(temp)}°C affects soil evaporation rates. Key Risk Factor: Humidity levels around {humidity}% require careful irrigation tracking. Actionable Recommendation: Proceed with morning crop monitoring.",
            "plans": [
                "Check soil moisture levels before sunrise", 
                "Postpone heavy chemical spraying if wind picks up", 
                "Ensure proper drainage in low-lying sections",
                "Inspect greenhouse ventilation for trapped humidity"
            ]
        },
        "Fitness Enthusiast": {
            "headline": "Great conditions for your outdoor run" if temp < 32 else "High heat index — pace yourself",
            "advice": f"Immediate Impact: Current {condition.lower()} provides a training window. Key Risk Factor: UV index and humidity may cause early fatigue. Actionable Recommendation: Stay hydrated and adjust your pace.",
            "plans": [
                "Complete intense cardio before peak afternoon heat", 
                "Carry adequate electrolytes and water", 
                "Wear breathable fabrics for current humidity",
                "Opt for shaded park trails instead of open asphalt"
            ]
        },
        "Commuter": {
            "headline": "Smooth transit conditions expected today" if wind_speed < 8 else "Windy transit conditions — stay alert",
            "advice": f"Immediate Impact: Visibility is clear at {visibility} km with stable wind speeds. Key Risk Factor: Minor traffic congestion during peak hours. Actionable Recommendation: Leave slightly early for your commute.",
            "plans": [
                "Check live transit updates before leaving", 
                "Keep light rain gear handy just in case", 
                "Opt for standard routes to avoid delays",
                "Allow an extra 10 minutes for platform queues"
            ]
        },
        "Event Planner": {
            "headline": "Favorable weather for outdoor setups" if pressure > 1010 else "Unstable pressure — secure structures",
            "advice": f"Immediate Impact: Atmospheric pressure of {pressure} hPa supports outdoor arrangements. Key Risk Factor: Temperature shifts toward midday. Actionable Recommendation: Secure tents and check cooling stations.",
            "plans": [
                "Verify vendor arrival times early", 
                "Ensure shaded seating areas are ready", 
                "Monitor wind speeds near temporary structures",
                "Have a backup indoor cooling tent designated"
            ]
        },
        "Delivery Rider": {
            "headline": "Fast delivery window across the city",
            "advice": f"Immediate Impact: Road surface temperature is influenced by {round(temp)}°C air temp. Key Risk Factor: Visibility and wind resistance. Actionable Recommendation: Check tire grip and wear high-visibility gear.",
            "plans": [
                "Keep waterproof covers over your delivery box", 
                "Take 5-minute hydration breaks every hour", 
                "Check live map detours for peak rush hours",
                "Inspect rain gear before heading out"
            ]
        },
        "Student": {
            "headline": "Ideal campus walk weather ahead",
            "advice": f"Immediate Impact: Comfortable environment at {round(temp)}°C for lectures and outdoor study. Key Risk Factor: Sudden weather shifts by evening. Actionable Recommendation: Pack a lightweight jacket.",
            "plans": [
                "Charge your devices before heading to the library", 
                "Keep a compact umbrella in your backpack", 
                "Take a study break during peak sunlight hours",
                "Grab a warm beverage if heading out post-sunset"
            ]
        }
    }

    selected_template = templates.get(resolved_persona, templates["Commuter"])

    return {
        "location": resolved_city,
        "persona": resolved_persona,
        "temperature": f"{round(temp)}°C",
        "feels_like": f"{round(feels_like)}°C",
        "condition": condition,
        "humidity": f"{humidity}%",
        "wind_speed": f"{wind_speed} m/s",
        "visibility": f"{visibility} km",
        "pressure": f"{pressure} hPa",
        "headline": selected_template["headline"],
        "advice": selected_template["advice"],
        "smart_insight": smart_insight,
        "actionable_tip": actionable_tip,
        "plan_items": selected_template["plans"],
        "risk_level": risk_level,
        "is_alert": is_alert
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 10000))
    uvicorn.run(app, host="0.0.0.0", port=port)