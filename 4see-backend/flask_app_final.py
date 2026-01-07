from flask import Flask, request, jsonify
from predictor import DropoutPredictor # Import your new class

app = Flask(__name__)

# Load the real predictor once on startup
predictor = DropoutPredictor(model_dir='./models')

@app.route("/predict", methods=["POST"])
def predict():
    # Expecting a JSON dictionary of student features
    # Example: {"data": {"absences": 25, "G1": 8, ...}}
    student_data = request.json.get("data")
    
    if not student_data:
        return jsonify({"error": "No student data provided"}), 400
        
    result = predictor.predict(student_data)
    
    if result["status"] == "error":
        return jsonify(result), 500
        
    return jsonify(result)

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy", 
        "model_loaded": True,
        "features_required": predictor.feature_names
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)