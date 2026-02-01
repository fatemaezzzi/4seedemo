from firebase_functions import https_fn, options
from firebase_admin import initialize_app
import numpy as np
import pickle
import json

# Initialize Firebase Admin
initialize_app()

# Load your trained model (you'll upload this file)
# Place your model.pkl in the functions folder
try:
    with open('model.pkl', 'rb') as f:
        model = pickle.load(f)
except:
    model = None

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["GET", "POST", "OPTIONS"],
    )
)
def predict(req: https_fn.Request) -> https_fn.Response:
    """HTTP Cloud Function for student dropout prediction"""

    # Handle OPTIONS request for CORS
    if req.method == 'OPTIONS':
        return https_fn.Response(
            "",
            status=204,
            headers={
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type',
            }
        )

    if req.method != 'POST':
        return https_fn.Response(
            json.dumps({"error": "Only POST requests are allowed"}),
            status=405,
            mimetype='application/json'
        )

    try:
        # Parse request data
        data = req.get_json()

        if not data or 'data' not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'data' field"}),
                status=400,
                mimetype='application/json'
            )

        features = data['data']

        # Extract features in the correct order
        feature_order = [
            'absences', 'G1', 'G2', 'failures', 'age',
            'Medu', 'Fedu', 'studytime', 'famsup', 'health',
            'Dalc', 'Walc', 'goout', 'famsize', 'Pstatus',
            'school', 'address', 'internet', 'schoolsup'
        ]

        feature_vector = [features.get(f, 0) for f in feature_order]
        feature_array = np.array([feature_vector])

        # Make prediction
        if model is None:
            # Fallback if model not loaded
            prediction = 0
            probability = 0.5
        else:
            prediction = model.predict(feature_array)[0]
            probability = model.predict_proba(feature_array)[0][1]

        # Determine risk level
        if probability > 0.7:
            risk_level = "HIGH"
            emoji = "🔴"
            recommendation = "Immediate intervention recommended"
        elif probability > 0.4:
            risk_level = "MEDIUM"
            emoji = "🟡"
            recommendation = "Monitor closely and provide support"
        else:
            risk_level = "LOW"
            emoji = "🟢"
            recommendation = "Continue current support level"

        # Analyze risk factors
        risk_factors = []
        if features.get('failures', 0) > 1:
            risk_factors.append("Multiple past failures")
        if features.get('absences', 0) > 10:
            risk_factors.append("High absence rate")
        if features.get('G1', 0) < 10 or features.get('G2', 0) < 10:
            risk_factors.append("Low grades in previous periods")
        if features.get('Dalc', 0) > 3 or features.get('Walc', 0) > 3:
            risk_factors.append("High alcohol consumption")
        if features.get('studytime', 0) < 2:
            risk_factors.append("Low study time")

        # Build response
        result = {
            "prediction": {
                "dropout": int(prediction),
                "dropout_probability": round(probability * 100, 2),
                "risk_score": round(probability, 3),
                "risk_level": risk_level,
                "emoji": emoji,
                "recommendation": recommendation,
                "confidence": "High" if abs(probability - 0.5) > 0.3 else "Medium"
            },
            "risk_factors": risk_factors if risk_factors else ["No major risk factors identified"],
            "input_data": features
        }

        return https_fn.Response(
            json.dumps(result),
            status=200,
            mimetype='application/json',
            headers={'Access-Control-Allow-Origin': '*'}
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            mimetype='application/json',
            headers={'Access-Control-Allow-Origin': '*'}
        )