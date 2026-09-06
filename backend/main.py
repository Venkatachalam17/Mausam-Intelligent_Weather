from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import requests
from google import genai
from config import GEMINI_API_KEY

app = FastAPI(title="Mausam Gemini-Powered Intelligent Weather API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the official Google GenAI client securely using config.py
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
    
    lang_map = {
        "en": "English",
        "ta": "Tamil",
        "hi": "Hindi"
    }
    selected_language = lang_map.get(lang, "English")
    
    # Defaults in case OpenWeatherMap fails
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

    # Robust Auto-adaptive persona detection if persona is set to 'Auto'
    resolved_persona = persona
    if persona.lower() == "auto":
        try:
            persona_res = client.models.generate_content(
                model='gemini-2.5-flash',  # 🚀 Updated to correct working model name
                contents=f"""Analyze the live weather in {resolved_city}: Temp {temp}°C, Condition {condition}, Humidity {humidity}%. 
                Select the single most fitting persona for these conditions from this exact list: 'Farmer', 'Fitness Enthusiast', 'Event Planner', 'Commuter'.
                CRITICAL: Return ONLY the persona name, nothing else."""
            )
            detected = persona_res.text.strip()
            for p in ['Farmer', 'Fitness Enthusiast', 'Event Planner', 'Commuter']:
                if p.lower() in detected.lower():
                    resolved_persona = p
                    break
            if resolved_persona.lower() == "auto":
                resolved_persona = "Commuter"
        except Exception:
            resolved_persona = "Commuter"

    ai_advice = f"As a {resolved_persona} in {resolved_city}, expect {condition.lower()} with {round(temp)}°C."
    ai_headline = "A workable day for your schedule"
    ai_plan_1 = "Review conditions before midday."
    ai_plan_2 = "A good window for outdoor activities."
    ai_plan_3 = "Weather conditions are manageable."

    try:
        response_ai = client.models.generate_content(
            model='gemini-2.5-flash',  # 🚀 Updated to correct working model name
            contents=f"""You are the core intelligence of the Mausam weather app. Provide weather details for a {resolved_persona} in {resolved_city}.
            Live Conditions: Temperature: {temp}°C, Condition: {condition}, Humidity: {humidity}%, Wind Speed: {wind_speed} m/s.
            
            CRITICAL: Provide your response strictly in the following format, entirely written in {selected_language}:
            HEADLINE: [A short 3-6 word punchy sentence suitable for the persona based on weather]
            ADVICE: [Detailed 3-part advisory: 1. Immediate Impact, 2. Key Risk Factor, 3. Actionable Recommendation]
            PLAN1: [First action item for the day]
            PLAN2: [Second action item for the day]
            PLAN3: [Third action item for the day]"""
        )
        text = response_ai.text.strip()
        for line in text.split('\n'):
            if line.startswith("HEADLINE:"):
                ai_headline = line.replace("HEADLINE:", "").strip()
            elif line.startswith("ADVICE:"):
                ai_advice = line.replace("ADVICE:", "").strip()
            elif line.startswith("PLAN1:"):
                ai_plan_1 = line.replace("PLAN1:", "").strip()
            elif line.startswith("PLAN2:"):
                ai_plan_2 = line.replace("PLAN2:", "").strip()
            elif line.startswith("PLAN3:"):
                ai_plan_3 = line.replace("PLAN3:", "").strip()
    except Exception as e:
        print(f"🔥 GEMINI API ERROR: {e}")

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
        "headline": ai_headline,
        "advice": ai_advice,
        "plan_items": [ai_plan_1, ai_plan_2, ai_plan_3],
        "risk_level": risk_level,
        "is_alert": is_alert
    }