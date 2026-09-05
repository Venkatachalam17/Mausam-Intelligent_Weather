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
def get_dashboard_data(persona: str, city: str = "Coimbatore"):
    api_key = "181e14f619b9946b6fae721dbe3c5cf4"
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
            visibility = data.get('visibility', 10000) / 1000 # in km
            condition = data['weather'][0]['description'].capitalize()
            resolved_city = data['name']
        else:
            return {"error": "City not found!"}
    except Exception:
        return {"error": "Failed to fetch weather data."}

    # Intelligent Risk calculation based on actual weather metrics
    is_alert = False
    risk_level = "Low Risk"
    if wind_speed > 12 or humidity > 85 or temp > 38:
        is_alert = True
        risk_level = "High Weather Risk"
    elif wind_speed > 8 or humidity > 70:
        risk_level = "Moderate Risk"

    # Default fallback description if API fails or blocks
    ai_text = f"As a {persona} in {resolved_city}, expect {condition.lower()} with a temperature of {round(temp)}°C (feels like {round(feels_like)}°C). Wind speeds are at {wind_speed} m/s with {humidity}% humidity. Plan your schedule accordingly to stay ahead of local atmospheric shifts!"

    try:
        response_ai = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=f"""You are the core intelligence of the Mausam weather app. Provide a detailed, professional, yet punchy advisory for a {persona} currently in {resolved_city}. 
            Live Conditions:
            - Temperature: {temp}°C (Feels like {feels_like}°C)
            - Condition: {condition}
            - Humidity: {humidity}%
            - Wind Speed: {wind_speed} m/s
            - Pressure: {pressure} hPa
            - Risk Level: {risk_level}

            Give a comprehensive 3-part breakdown:
            1. Immediate Impact on your activities.
            2. Key Risk Factor to watch out for.
            3. Actionable Recommendation.
            Keep it clean, highly descriptive, and tailored directly to their persona."""
        )
        if response_ai.text:
            ai_text = response_ai.text.strip()
    except Exception as e:
        print(f"GEMINI API ERROR: {e}")

    return {
        "location": resolved_city,
        "temperature": f"{round(temp)}°C",
        "feels_like": f"{round(feels_like)}°C",
        "condition": condition,
        "humidity": f"{humidity}%",
        "wind_speed": f"{wind_speed} m/s",
        "visibility": f"{visibility} km",
        "pressure": f"{pressure} hPa",
        "advice": ai_text,
        "risk_level": risk_level,
        "is_alert": is_alert
    }