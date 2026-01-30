import requests
import json

# This mimics exactly what your Flutter App will send
url = "http://127.0.0.1:5000/get-ai-advice"

payload = {
    "name": "Rohan",
    "risk_level": "High",
    "academic_issues": ["Absent", "Failing Math"],
    "quiz_flags": {"ADHD": "High Risk"}
}

try:
    print(f"📡 Sending data to {url}...")
    response = requests.post(url, json=payload)
    
    # Check if successful
    if response.status_code == 200:
        print("\n✅ SUCCESS! AI Response:")
        print(json.dumps(response.json(), indent=2))
    else:
        print(f"\n❌ Error {response.status_code}:")
        print(response.text)

except Exception as e:
    print(f"\n❌ Connection Failed: {e}")
    print("👉 Make sure 'python flask_app_final.py' is running in another terminal!")