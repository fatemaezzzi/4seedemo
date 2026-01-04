from flask import Flask, request, jsonify
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler

app = Flask(__name__)

# ==========================================
# 1. TRAIN MODEL ON STARTUP (With 9 Features)
# ==========================================
print("⏳ Generating synthetic data and training model...")

# Define the 9 features in specific order
features_list = [
    "absences", "G1", "G2", "G3", "studytime", "failures", 
    "family support", "health", "parent status"
]

# Generate realistic synthetic data for training
np.random.seed(42)
n_samples = 1000
X = np.zeros((n_samples, 9))

# Randomize data with realistic ranges
X[:, 0] = np.random.randint(0, 93, n_samples)   # absences
X[:, 1:4] = np.random.randint(0, 20, (n_samples, 3)) # Grades G1, G2, G3
X[:, 4] = np.random.randint(1, 5, n_samples)    # studytime
X[:, 5] = np.random.randint(0, 4, n_samples)    # failures
X[:, 6] = np.random.randint(0, 2, n_samples)    # famsup (0 or 1)
X[:, 7] = np.random.randint(1, 6, n_samples)    # health (1-5)
X[:, 8] = np.random.randint(0, 2, n_samples)    # Pstatus (0 or 1)

# Logic: High risk if low grades OR high absences OR (bad health & no support)
y = ((X[:, 3] < 10) | (X[:, 0] > 20) | ((X[:, 7] < 2) & (X[:, 6] == 0))).astype(int)

# Train
scaler = StandardScaler().fit(X)
model = RandomForestClassifier(n_estimators=100, random_state=42).fit(scaler.transform(X), y)
print("✅ Model trained on 9 features!")

# ==========================================
# 2. API ENDPOINTS
# ==========================================

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()
        
        # Extract features by name (safest for App connection)
        # We default to reasonable values (0) if a key is missing
        input_vector = [
            float(data.get("absences", 0)),
            float(data.get("G1", 0)),
            float(data.get("G2", 0)),
            float(data.get("G3", 0)),
            float(data.get("studytime", 1)),
            float(data.get("failures", 0)),
            float(data.get("famsup", 0)),   # New
            float(data.get("health", 3)),   # New
            float(data.get("Pstatus", 1))   # New
        ]
        
        # Scale & Predict
        X_new = scaler.transform(np.array(input_vector).reshape(1, -1))
        risk_prob = model.predict_proba(X_new)[0][1]
        
        return jsonify({
            "dropout_risk_score": float(risk_prob),
            "risk_label": "HIGH" if risk_prob > 0.5 else "LOW",
            "prediction": int(risk_prob > 0.5)
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "active", 
        "features_required": features_list,
        "feature_count": len(features_list)
    })

if __name__ == "__main__":
    print("🚀 API running on port 5000")
    app.run(host="0.0.0.0", port=5000)