
import joblib
import numpy as np
import os

class DropoutPredictor:
    def __init__(self, model_dir='./models'):
        self.model = joblib.load(os.path.join(model_dir, 'randomforest_model.pkl'))
        self.scaler = joblib.load(os.path.join(model_dir, 'scaler.pkl'))
        self.feature_names = joblib.load(os.path.join(model_dir, 'feature_columns.pkl'))

    def predict(self, data_dict):
        # Align features to ensure the 19-parameter order is correct
        input_values = [data_dict.get(f, 0) for f in self.feature_names]
        X = np.array(input_values).reshape(1, -1)
        X_scaled = self.scaler.transform(X)

        # Get raw probability
        proba = self.model.predict_proba(X_scaled)[0]
        risk_score = float(proba[1])

        # Apply the 3-level parametric thresholds
        # Using specific emoji strings that work in UTF-8
        if risk_score >= 0.7:
            risk_level, emoji = 'HIGH', '🔴'
        elif risk_score >= 0.4:
            risk_level, emoji = 'MEDIUM', '🟡'
        else:
            risk_level, emoji = 'LOW', '🟢'

        return {
            'risk_level': risk_level,
            'risk_score': round(risk_score, 3),
            'emoji': emoji,
            'confidence': f"{max(proba) * 100:.1f}%"
        }
