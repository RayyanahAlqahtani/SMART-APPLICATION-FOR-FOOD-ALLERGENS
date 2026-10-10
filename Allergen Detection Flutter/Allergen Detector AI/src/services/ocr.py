import google.generativeai as genai
import os
import io
import re
import json
import time
from PIL import Image

def _configure_genai():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return False
    genai.configure(api_key=api_key)
    return True

def analyze_image(image_bytes, user_allergens=None):
    if not _configure_genai():
        return {"error": "API Key missing"}

    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        image = Image.open(io.BytesIO(image_bytes))
        
        allergens_str = ", ".join(user_allergens) if user_allergens else "common allergens"

        prompt = f"""
        1. Extract all text from the 'Ingredients' section of this image.
        2. Identify if any of these allergens are present: {allergens_str}.
        3. Even if the exact word isn't there, look for scientific derivatives.
        4. Classify the product as 'Safe' or 'Not Safe' based on the requested allergens.
        5. Assign a confidence score (0.0 to 1.0) based on how clearly you can identify the ingredients and allergens.
        6. Return a JSON object with this EXACT structure:
        {{
            "status": "Safe" | "Not Safe",
            "color": "green" | "red",
            "confidence": 0.95,
            "detected_allergens": [
                {{
                    "word": "term found",
                    "category": "allergen group",
                    "risk": "High/Medium/Low"
                }}
            ],
            "raw_text": "full extracted ingredients list"
        }}
        Only return the JSON object. Do not wrap it in markdown block quotes.
        """
        
        text = ""
        for attempt in range(3):
            try:
                response = model.generate_content([prompt, image])
                text = response.text
                break
            except Exception as e:
                if attempt == 2:
                    raise e
                time.sleep(2 ** attempt)
        
        json_str = re.sub(r'```json|```', '', text).strip()
        
        try:
            result = json.loads(json_str)
            if "confidence" not in result:
                result["confidence"] = 0.5
            return result
        except json.JSONDecodeError:
            return {
                "status": "Unknown",
                "color": "gray",
                "confidence": 0.5,
                "detected_allergens": [],
                "raw_text": text,
                "error": "Failed to parse API response"
            }

    except Exception as e:
        return {"error": str(e)}

def extract_text(image_bytes):
    return analyze_image(image_bytes)
