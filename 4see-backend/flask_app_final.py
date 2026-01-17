"""
Production-Ready Flask API for Student Dropout Prediction
==========================================================

Features:
- Robust error handling
- Input validation
- Detailed logging
- Health check endpoint
- CORS support for mobile apps
- Proper HTTP status codes

Usage:
    python flask_app_final.py
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os
import logging
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================

app = Flask(__name__)
CORS(app)  # Enable CORS for mobile app access

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

MODEL_DIR = './models'

# ============================================================================
# LOAD MODEL ON STARTUP
# ============================================================================

class PredictionService:
    """Handles model loading and prediction logic"""
    
    def __init__(self, model_dir):
        self.model_dir = model_dir
        self.model = None
        self.scaler = None
        self.feature_names = None
        self.load_models()
    
    def load_models(self):
        """Load all required model artifacts"""
        try:
            # Try different model files (in order of preference)
            model_files = [
                'randomforest_model.pkl',
                'gradientboosting_model.pkl',
                'logisticregression_model.pkl'
            ]
            
            model_loaded = False
            for model_file in model_files:
                model_path = os.path.join(self.model_dir, model_file)
                if os.path.exists(model_path):
                    self.model = joblib.load(model_path)
                    logger.info(f"✅ Loaded model: {model_file}")
                    model_loaded = True
                    break
            
            if not model_loaded:
                raise FileNotFoundError("No model file found")
            
            # Load scaler
            scaler_path = os.path.join(self.model_dir, 'scaler.pkl')
            self.scaler = joblib.load(scaler_path)
            logger.info("✅ Loaded scaler")
            
            # Load feature names
            features_path = os.path.join(self.model_dir, 'feature_columns.pkl')
            self.feature_names = joblib.load(features_path)
            logger.info(f"✅ Loaded {len(self.feature_names)} feature names")
            
            logger.info("🚀 Prediction service ready!")
            
        except Exception as e:
            logger.error(f"❌ Error loading models: {str(e)}")
            raise
    
    def validate_input(self, data):
        """
        Validate input data
        
        Returns:
            (is_valid, error_message)
        """
        if not data:
            return False, "No data provided"
        
        if not isinstance(data, dict):
            return False, "Data must be a JSON object"
        
        # Check if at least some required features are present
        provided_features = set(data.keys())
        required_features = set(self.feature_names)
        
        # Allow partial data (will fill missing with defaults)
        if len(provided_features & required_features) == 0:
            return False, f"No valid features found. Expected features: {self.feature_names[:5]}..."
        
        # Validate data types
        for key, value in data.items():
            if key in self.feature_names:
                if not isinstance(value, (int, float)):
                    return False, f"Feature '{key}' must be numeric, got {type(value).__name__}"
        
        return True, None
    
    def predict(self, data):
        """
        Make prediction with proper error handling
        
        Args:
            data: Dictionary of student features
            
        Returns:
            Dictionary with prediction results or error
        """
        try:
            # Validate input
            is_valid, error_msg = self.validate_input(data)
            if not is_valid:
                return {"status": "error", "message": error_msg}, 400
            
            # Prepare input array (use 0 as default for missing features)
            input_values = [data.get(feature, 0) for feature in self.feature_names]
            X = np.array(input_values).reshape(1, -1)
            
            # Scale features
            X_scaled = self.scaler.transform(X)
            
            # Get predictions
            prediction = self.model.predict(X_scaled)[0]
            probabilities = self.model.predict_proba(X_scaled)[0]
            risk_score = float(probabilities[1])
            
            # Determine risk level with 3-tier system
            if risk_score >= 0.7:
                risk_level = "HIGH"
                emoji = "🔴"
                recommendation = "Immediate intervention required"
            elif risk_score >= 0.4:
                risk_level = "MEDIUM"
                emoji = "🟡"
                recommendation = "Monitor closely and provide support"
            else:
                risk_level = "LOW"
                emoji = "🟢"
                recommendation = "Continue current support"
            
            # Get feature importance for this prediction
            top_factors = self._get_top_risk_factors(data, X_scaled[0])
            
            # Prepare response
            response = {
                "status": "success",
                "prediction": {
                    "risk_level": risk_level,
                    "risk_score": round(risk_score, 3),
                    "dropout_probability": round(risk_score * 100, 1),
                    "continue_probability": round(probabilities[0] * 100, 1),
                    "confidence": f"{max(probabilities) * 100:.1f}%",
                    "emoji": emoji,
                    "recommendation": recommendation
                },
                "risk_factors": top_factors,
                "features_used": len([v for v in input_values if v != 0]),
                "timestamp": datetime.now().isoformat()
            }
            
            return response, 200
            
        except Exception as e:
            logger.error(f"Prediction error: {str(e)}")
            return {
                "status": "error",
                "message": f"Prediction failed: {str(e)}"
            }, 500
    
    def _get_top_risk_factors(self, data, scaled_features):
        """
        Identify top risk factors for this student
        
        Returns:
            List of risk factor descriptions
        """
        factors = []
        
        # Check academic performance
        g1 = data.get('G1', 0)
        g2 = data.get('G2', 0)
        if g1 < 10 or g2 < 10:
            factors.append("Low academic performance")
        
        # Check attendance
        absences = data.get('absences', 0)
        if absences > 15:
            factors.append("High number of absences")
        elif absences > 10:
            factors.append("Moderate absences")
        
        # Check failures
        failures = data.get('failures', 0)
        if failures >= 2:
            factors.append("Multiple past failures")
        elif failures == 1:
            factors.append("One past failure")
        
        # Check study time
        studytime = data.get('studytime', 2)
        if studytime < 2:
            factors.append("Low study time")
        
        # Check family support
        famsup = data.get('famsup', 1)
        if famsup == 0:
            factors.append("Limited family support")
        
        # Check health
        health = data.get('health', 5)
        if health <= 2:
            factors.append("Poor health status")
        
        # Check alcohol consumption
        dalc = data.get('Dalc', 1)
        walc = data.get('Walc', 1)
        if (dalc + walc) > 6:
            factors.append("High alcohol consumption")
        
        return factors if factors else ["No major risk factors identified"]

# Initialize prediction service
try:
    prediction_service = PredictionService(MODEL_DIR)
except Exception as e:
    logger.error(f"Failed to initialize prediction service: {str(e)}")
    prediction_service = None

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/', methods=['GET'])
def home():
    """API documentation endpoint"""
    return jsonify({
        "name": "Student Dropout Prediction API",
        "version": "2.0",
        "status": "running",
        "endpoints": {
            "/": "API documentation (this page)",
            "/health": "Health check",
            "/predict": "Make prediction (POST)",
            "/features": "List required features (GET)",
            "/test": "Test with sample data (GET)"
        }
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for monitoring"""
    if prediction_service is None:
        return jsonify({
            "status": "unhealthy",
            "model_loaded": False,
            "error": "Prediction service not initialized"
        }), 503
    
    return jsonify({
        "status": "healthy",
        "model_loaded": True,
        "model_type": type(prediction_service.model).__name__,
        "features_count": len(prediction_service.feature_names),
        "timestamp": datetime.now().isoformat()
    })

@app.route('/features', methods=['GET'])
def get_features():
    """Return list of required features"""
    if prediction_service is None:
        return jsonify({"error": "Service not initialized"}), 503
    
    return jsonify({
        "features": prediction_service.feature_names,
        "count": len(prediction_service.feature_names),
        "description": "These are the features the model expects. Missing features will be filled with 0."
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Main prediction endpoint
    
    Expected JSON format:
    {
        "data": {
            "absences": 10,
            "G1": 12,
            "G2": 13,
            "failures": 0,
            ...
        }
    }
    """
    if prediction_service is None:
        return jsonify({
            "status": "error",
            "message": "Prediction service not initialized"
        }), 503
    
    # Get JSON data
    try:
        request_data = request.get_json()
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Invalid JSON: {str(e)}"
        }), 400
    
    if not request_data:
        return jsonify({
            "status": "error",
            "message": "No JSON data provided"
        }), 400
    
    # Extract student data
    student_data = request_data.get('data', request_data)
    
    # Make prediction
    result, status_code = prediction_service.predict(student_data)
    
    # Log prediction
    if result.get('status') == 'success':
        logger.info(f"Prediction: {result['prediction']['risk_level']} "
                   f"(score: {result['prediction']['risk_score']})")
    
    return jsonify(result), status_code

@app.route('/test', methods=['GET'])
def test_prediction():
    """Test endpoint with sample data"""
    if prediction_service is None:
        return jsonify({"error": "Service not initialized"}), 503
    
    # Sample student profiles
    samples = {
        "low_risk": {
            "absences": 2, "G1": 15, "G2": 15, "failures": 0, "age": 17,
            "Medu": 4, "Fedu": 4, "studytime": 3, "famsup": 1, "health": 5,
            "Dalc": 1, "Walc": 1, "goout": 2, "famsize": 1, "Pstatus": 1,
            "school": 0, "address": 1, "internet": 1, "schoolsup": 0
        },
        "medium_risk": {
            "absences": 12, "G1": 11, "G2": 10, "failures": 1, "age": 18,
            "Medu": 2, "Fedu": 2, "studytime": 2, "famsup": 0, "health": 3,
            "Dalc": 2, "Walc": 3, "goout": 4, "famsize": 0, "Pstatus": 1,
            "school": 0, "address": 1, "internet": 1, "schoolsup": 0
        },
        "high_risk": {
            "absences": 25, "G1": 8, "G2": 7, "failures": 2, "age": 19,
            "Medu": 1, "Fedu": 1, "studytime": 1, "famsup": 0, "health": 2,
            "Dalc": 4, "Walc": 4, "goout": 5, "famsize": 0, "Pstatus": 0,
            "school": 0, "address": 0, "internet": 0, "schoolsup": 1
        }
    }
    
    results = {}
    for profile_name, profile_data in samples.items():
        result, _ = prediction_service.predict(profile_data)
        results[profile_name] = result
    
    return jsonify({
        "message": "Test predictions with sample profiles",
        "results": results
    })

@app.route('/batch', methods=['POST'])
def batch_predict():
    """
    Batch prediction endpoint for multiple students
    
    Expected JSON format:
    {
        "students": [
            {"id": "001", "data": {...}},
            {"id": "002", "data": {...}}
        ]
    }
    """
    if prediction_service is None:
        return jsonify({"error": "Service not initialized"}), 503
    
    try:
        request_data = request.get_json()
        students = request_data.get('students', [])
        
        if not students:
            return jsonify({
                "status": "error",
                "message": "No students provided"
            }), 400
        
        results = []
        for student in students:
            student_id = student.get('id', 'unknown')
            student_data = student.get('data', {})
            
            result, _ = prediction_service.predict(student_data)
            result['student_id'] = student_id
            results.append(result)
        
        return jsonify({
            "status": "success",
            "count": len(results),
            "predictions": results
        })
        
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(e):
    return jsonify({
        "status": "error",
        "message": "Endpoint not found",
        "available_endpoints": ["/", "/health", "/predict", "/features", "/test"]
    }), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({
        "status": "error",
        "message": "Method not allowed for this endpoint"
    }), 405

@app.errorhandler(500)
def internal_error(e):
    return jsonify({
        "status": "error",
        "message": "Internal server error"
    }), 500

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    if prediction_service is None:
        logger.error("Cannot start server: Prediction service failed to initialize")
        logger.error("Make sure model files exist in ./models/")
        exit(1)
    
    logger.info("="*80)
    logger.info("🚀 Starting Flask API Server")
    logger.info("="*80)
    logger.info(f"Model: {type(prediction_service.model).__name__}")
    logger.info(f"Features: {len(prediction_service.feature_names)}")
    logger.info(f"Endpoints available at http://localhost:5000")
    logger.info("="*80)
    
    # Run server
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True  # Set to True for development
    )