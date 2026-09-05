from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
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
    persona: str

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "message": "Mausam backend is running successfully!"
    }

@app.post("/api/set-interest")
def set_user_interest(data: UserInterest):
    return {
        "status": "success",
        "message": f"Persona set to {data.persona}! Custom weather engine initialized.",
        "persona": data.persona
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
    
    if lat is not None and lon is not None:
        url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
        try:
            nominatim_url = f"https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={lat}&lon={lon}"
            geo_response = requests.get(nominatim_url, headers={'User-Agent': 'MausamWeatherApp/1.0'})
            geo_data = geo_response.json()
            address = geo_data.get('address', {})
            resolved_city = (
                address.get('suburb') or 
                address.get('neighbourhood') or 
                address.get('city_district') or 
                address.get('town') or 
                address.get('city') or 
                "Coimbatore"
            )
        except Exception:
            resolved_city = "Coimbatore"
    else:
        url = f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"
    
    try:
        response = requests.get(url)
        data = response.json()
        if response.status_code == 200:
            temp = data['main']['temp']
            feels_like = data['main']['feels_like']
            humidity = data['main']['humidity']
            pressure = data['main']['pressure']
            wind_speed = data['wind']['speed']
            visibility = data.get('visibility', 10000) / 1000
            condition = data['weather'][0]['description'].capitalize()
            if lat is None:
                resolved_city = data['name']
        else:
            return {"error": "Location not found!"}
    except Exception:
        return {"error": "Failed to fetch weather data."}

    is_alert = False
    risk_level = "Low Risk"
    if wind_speed > 12 or humidity > 85 or temp > 38:
        is_alert = True
        risk_level = "High Weather Risk"
    elif wind_speed > 8 or humidity > 70:
        risk_level = "Moderate Risk"

    # Ask Gemini to return a JSON-like structured response or translated UI labels along with advice
    ai_advice = f"As a {persona} in {resolved_city}, expect {condition.lower()} with {temp}°C."
    ai_headline = f"A workable day for your fields"
    ai_plan_1 = "Review irrigation needs before midday."
    ai_plan_2 = "A good window for field work."
    ai_plan_3 = "Wind conditions are manageable."

    try:
        response_ai = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=f"""You are the core intelligence of the Mausam weather app. Provide weather details for a {persona} in {resolved_city}.
            Live Conditions: Temperature: {temp}°C, Condition: {condition}, Humidity: {humidity}%, Wind Speed: {wind_speed} m/s.
            
            CRITICAL: Provide your response strictly in the following format, entirely written in {selected_language}:
            HEADLINE: [A short 3-6 word punchy sentence suitable for the persona based on weather]
            ADVICE: [Detailed 3-part advisory: 1. Immediate Impact, 2. Key Risk Factor, 3. Actionable Recommendation]
            PLAN1: [First action item for the day]
            PLAN2: [Second action item for the day]
            PLAN3: [Third action item for the day]"""
        )
        text = response_ai.text.strip()
        # Simple line parser
        lines = text.split('\n')
        for line in lines:
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