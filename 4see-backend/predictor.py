import joblib
import numpy as np
import os

class DropoutPredictor:
    def __init__(self, model_dir='./models'):
        # Check if files exist before loading to avoid silent failures
        model_path = os.path.join(model_dir, 'randomforest_model.pkl')
        scaler_path = os.path.join(model_dir, 'scaler.pkl')
        feat_path = os.path.join(model_dir, 'feature_columns.pkl')

        if not all(os.path.exists(p) for p in [model_path, scaler_path, feat_path]):
            raise FileNotFoundError(f"One or more model files missing in {model_dir}")

        self.model = joblib.load(model_path)
        self.scaler = joblib.load(scaler_path)
        self.feature_names = joblib.load(feat_path)

    def predict(self, data_dict):
        # Match input features to the 19 features from training
        input_values = [data_dict.get(f, 0) for f in self.feature_names]
        input_array = np.array(input_values).reshape(1, -1)
        
        scaled_data = self.scaler.transform(input_array)
        probs = self.model.predict_proba(scaled_data)[0]
        risk_score = float(probs[1])

        # 3-Level Logic
        if risk_score >= 0.7: status, emoji = "HIGH", "🔴"
        elif risk_score >= 0.4: status, emoji = "MEDIUM", "🟡"
        else: status, emoji = "LOW", "🟢"

        return {
            "risk_level": status,
            "risk_score": round(risk_score, 3),
            "emoji": emoji,
            "confidence": f"{max(probs) * 100:.1f}%"
        }