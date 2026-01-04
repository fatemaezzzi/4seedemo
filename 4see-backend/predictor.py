
import joblib
import numpy as np
class DropoutPredictor:
    def __init__(self):
        self.model = joblib.load('models/randomforest_model.pkl')
        self.scaler = joblib.load('models/scaler.pkl')
        self.features = joblib.load('models/feature_columns.pkl')
    def predict(self, features):
        if len(features) != 19: raise ValueError("Need 19 features")
        X = np.array(features).reshape(1,-1)
        X_scaled = self.scaler.transform(X)
        pred = self.model.predict(X_scaled)[0]
        proba = self.model.predict_proba(X_scaled)[0]
        return {"dropout_risk": float(proba[1]), "prediction": int(pred)}
