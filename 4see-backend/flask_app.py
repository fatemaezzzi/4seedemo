code = '''
from flask import Flask, request, jsonify
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler

app = Flask(__name__)

print("Creating model...")
features = ["absences", "G1", "G2", "G3", "studytime", "failures"]
X = np.random.rand(1000, 6)
y = (X[:,3] < 0.5).astype(int)
scaler = StandardScaler().fit(X)
model = RandomForestClassifier(n_estimators=50).fit(scaler.transform(X), y)

@app.route("/predict", methods=["POST"])
def predict():
    data = request.json["features"]
    if len(data) != 6:
        return jsonify({"error": "Need 6 features"}), 400
    X_scaled = scaler.transform(np.array(data).reshape(1,-1))
    risk = model.predict_proba(X_scaled)[0][1]
    return jsonify({"dropout_risk": float(risk), "prediction": int(risk>0.5)})

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "features": features})

if __name__ == "__main__":
    print("API ready! POST to /predict")
    app.run(host="0.0.0.0", port=5000)
'''

with open("flask_app_final.py", "w", encoding="utf-8") as f:
    f.write(code)

print("Created flask_app_final.py")
exec(open("flask_app_final.py", encoding="utf-8").read())

