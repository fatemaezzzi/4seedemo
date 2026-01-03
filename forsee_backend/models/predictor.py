
import joblib, numpy as np
class DropoutPredictor:
    def __init__(self, model_dir='./models'):
        self.model = joblib.load(f'{model_dir}/randomforest_model.pkl')
        self.scaler = joblib.load(f'{model_dir}/scaler.pkl')
    def predict(self, features):
        X = np.array(features).reshape(1, -1)
        X_scaled = self.scaler.transform(X)
        pred = self.model.predict(X_scaled)[0]
        proba = self.model.predict_proba(X_scaled)[0]
        return {
            'prediction': int(pred),
            'probability_dropout': float(proba[1]),
            'risk_level': 'HIGH' if pred == 1 else 'LOW'
        }
