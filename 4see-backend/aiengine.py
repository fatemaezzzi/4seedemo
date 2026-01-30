import os
import json
import requests
from dotenv import load_dotenv

# Load key
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")

def get_student_advice(student_name, risk_level, academic_issues, quiz_flags):
    """
    Sends data to OpenRouter using standard HTTP requests.
    """
    
    url = "https://openrouter.ai/api/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://hackathon-app.com", 
    }

    system_prompt = """
    You are 'EduCare', an expert Indian School Counselor.
    Analyze the student data and provide actionable advice.
    Output MUST be strict JSON.
    """
    
    user_message = f"""
    Student: {student_name}
    Risk: {risk_level}
    Issues: {academic_issues}
    Mental Health Flags: {quiz_flags}
    
    Return JSON with keys: 
    - risk_summary (1 sentence)
    - teacher_action (immediate tip)
    - long_term_plan (bullet point)
    """

    # --- CRITICAL CHANGE: Using a more stable model ---
    payload = {
      "model": "microsoft/phi-4",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ],
        "response_format": {"type": "json_object"}
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        
        # This prints the REAL error if something goes wrong
        if response.status_code != 200:
            print(f"❌ API Error: {response.status_code}")
            print(f"🔍 Details: {response.text}")
            return {"error": "AI provider refused connection", "details": response.text}

        # Parse the answer
        result_json = response.json()
        content = result_json['choices'][0]['message']['content']
        return json.loads(content)

    except Exception as e:
        print(f"❌ Python Error: {e}")
        return {"error": "Internal Server Error", "details": str(e)}

# Test it
if __name__ == "__main__":
    print("Testing Lightweight AI connection...")
    # Make sure your .env file is loaded!
    if not API_KEY:
        print("❌ ERROR: API Key is missing. Check .env file.")
    else:
        test = get_student_advice("Rohan", "High", ["Absent"], {"ADHD": "High"})
        print(test)