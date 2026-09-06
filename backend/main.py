from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import requests
import traceback
import os
from google import genai

# Read API key directly from environment for Render safety
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

app = FastAPI(title="Mausam Gemini-Powered Intelligent Weather API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = genai.Client(api_key=GEMINI_API_KEY)

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

@app.get("/api/chat")
def weather_chat(message: str = Query(default="Hello")):
    try:
        # Updated to gemini-3.6-flash as requested by the API error response
        response_ai = client.models.generate_content(
            model='gemini-3.6-flash', 
            contents=f"You are Mausam AI, a friendly weather assistant. Answer this user question concisely and helpfully: {message}"
        )
        reply = response_ai.text.strip()
    except Exception as e:
        print("🔥 FULL EXCEPTION TRACEBACK:")
        traceback.print_exc()
        reply = f"DEBUG ERROR: {str(e)}"
    
    return {"reply": reply}

@app.get("/api/dashboard/{persona}")
def get_dashboard_data(
    persona: str, 
    city: str = "Coimbatore", 
    lat: float = None, 
    lon: float = None, 
    lang: str = "en"
):
    api_key = "181e14f619b9946b6fae721dbe3c5cf4"
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
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
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
            url = f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"
        
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

    templates = {
        "Farmer": {
            "headline": "Optimal moisture window for fields",
            "advice": f"Immediate Impact: Temperature at {round(temp)}°C affects soil evaporation rates. Key Risk Factor: Humidity levels around {humidity}% require careful irrigation tracking. Actionable Recommendation: Proceed with morning crop monitoring.",
            "plans": ["Check soil moisture levels before sunrise", "Postpone heavy chemical spraying if wind picks up", "Ensure proper drainage in low-lying sections"]
        },
        "Fitness Enthusiast": {
            "headline": "Great conditions for your outdoor run",
            "advice": f"Immediate Impact: Current {condition.lower()} provides a comfortable training window. Key Risk Factor: UV index and humidity may cause early fatigue. Actionable Recommendation: Stay hydrated and pace your session.",
            "plans": ["Complete intense cardio before peak afternoon heat", "Carry adequate electrolytes and water", "Wear breathable fabrics for current humidity"]
        },
        "Commuter": {
            "headline": "Smooth transit conditions expected today",
            "advice": f"Immediate Impact: Visibility is clear at {visibility} km with stable wind speeds. Key Risk Factor: Minor traffic congestion during peak hours. Actionable Recommendation: Leave slightly early for your commute.",
            "plans": ["Check live transit updates before leaving", "Keep light rain gear handy just in case", "Opt for standard routes to avoid delays"]
        },
        "Event Planner": {
            "headline": "Favorable weather for outdoor setups",
            "advice": f"Immediate Impact: Stable atmospheric pressure of {pressure} hPa supports outdoor arrangements. Key Risk Factor: Temperature shifts toward midday. Actionable Recommendation: Secure tents and check cooling stations.",
            "plans": ["Verify vendor arrival times early", "Ensure shaded seating areas are ready", "Monitor wind speeds near temporary structures"]
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
        "plan_items": selected_template["plans"],
        "risk_level": risk_level,
        "is_alert": is_alert
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 10000))
    uvicorn.run(app, host="0.0.0.0", port=port)