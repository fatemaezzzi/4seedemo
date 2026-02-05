"""
Production-Ready Flask API for Student Dropout Prediction — 4See
=================================================================

Matches the 58-feature model produced by train_model.py.

The Flutter app only needs to send the 28 RAW columns.  This API
derives all 29 engineered features (grade trends, risk flags,
weighted_risk_score …) before scaling and predicting, so the app
never has to know about internal feature engineering.

Endpoints
---------
    GET   /              API info
    GET   /health        Liveness check
    GET   /features      Raw columns the app must send
    POST  /predict       Single-student prediction
    POST  /batch         Multi-student prediction
    GET   /test          Quick smoke-test with 3 sample profiles
    POST  /get-ai-advice LLM-generated intervention advice
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os
import logging
from datetime import datetime

# Guard the LLM helper — only crashes at call-time if the file is missing
try:
    from aiengine import get_student_advice   # pragma: no cover
    _HAS_AI = True
except ImportError:                           # pragma: no cover
    _HAS_AI = False

# ============================================================================
# CONFIGURATION
# ============================================================================

app  = Flask(__name__)
CORS(app)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

MODEL_DIR = './models'

# ── Columns the Flutter app must send (the 28 raw inputs) ───────────────────
RAW_INPUT_COLUMNS = [
    "Course",
    "Daytime/evening attendance",
    "Previous qualification",
    "Mjob", "Fjob",
    "Educational special needs",
    "Debtor",
    "Tuition fees up to date",
    "sex",
    "Scholarship holder",
    "age",
    "G1", "G2", "G3",
    "famsize", "Pstatus", "guardian",
    "studytime", "failures",
    "schoolsup", "famsup", "paid",
    "activities", "higher", "internet",
    "famrel", "health", "absences",
]

# ── Sensible per-column defaults (dataset means / modes) ─────────────────────
# Used when a raw column is missing from the request — avoids the old blanket-0
# which was wrong for columns like studytime (1–4) or famrel (1–5).
RAW_DEFAULTS = {
    "Course":                         9500,   # Nursing (most common)
    "Daytime/evening attendance":     1,      # Daytime
    "Previous qualification":         1,      # Secondary education
    "Mjob":                           5,      # mean ≈ 5
    "Fjob":                           5,
    "Educational special needs":      0,
    "Debtor":                         0,
    "Tuition fees up to date":        1,
    "sex":                            1,      # Male (slight majority)
    "Scholarship holder":             0,
    "age":                            22,     # dataset mean
    "G1":                             11,     # dataset mean ≈ 10.75
    "G2":                             10,
    "G3":                             10,
    "famsize":                        1,
    "Pstatus":                        1,      # Living together
    "guardian":                       0,      # Mother
    "studytime":                      2,      # 2–5 h
    "failures":                       1,      # dataset mean ≈ 0.77 → round up
    "schoolsup":                      1,
    "famsup":                         0,
    "paid":                           1,
    "activities":                     1,
    "higher":                         0,
    "internet":                       0,
    "famrel":                         4,      # dataset mean ≈ 4.03
    "health":                         3,      # dataset mean ≈ 3.30
    "absences":                       6,      # dataset mean ≈ 5.50
}

# ── Priority weights (same as train_model.py Config.W) ─────────────────────
WEIGHTS = {
    "G1": 0.18, "G2": 0.18, "G3": 0.18,
    "absences":  0.12,
    "failures":  0.07,
    "studytime": 0.05,
    "famrel":    0.03,
    "health":    0.03,
    "static_pool": 0.05,
}

# ── Normalisation bounds (same as train_model.py Config.RANGES) ─────────────
RANGES = {
    "G1":        (0, 20),
    "G2":        (0, 20),
    "G3":        (0, 20),
    "absences":  (0, 75),
    "failures":  (0, 4),
    "studytime": (1, 4),
    "famrel":    (1, 5),
    "health":    (1, 5),
    "age":       (15, 70),
}


# ============================================================================
# FEATURE ENGINEERING  (mirrors train_model.py engineer_features exactly)
# ============================================================================

def _norm(val, lo, hi):
    """Clip-normalise a single value to [0, 1]."""
    return max(0.0, min(1.0, (val - lo) / (hi - lo)))


def engineer_features(raw: dict) -> dict:
    """
    Takes the 28 raw columns and returns a flat dict with all 58 features
    the model expects.  Raw values are kept as-is; engineered values are
    appended.
    """
    d = dict(raw)          # shallow copy — don't mutate caller's dict

    G1, G2, G3 = d["G1"], d["G2"], d["G3"]

    # ── Tier A: HIGH priority (grades + attendance) ──────────────────────
    d["grade_trend_12"] = G2 - G1
    d["grade_trend_23"] = G3 - G2
    d["grade_trend_13"] = G3 - G1

    d["grade_avg_all"] = (G1 + G2 + G3) / 3.0
    d["grade_avg_12"]  = (G1 + G2) / 2.0

    d["grade_min"]   = min(G1, G2, G3)
    d["grade_max"]   = max(G1, G2, G3)
    d["grade_range"] = d["grade_max"] - d["grade_min"]

    d["drop_12"]          = int(G2 < G1)
    d["drop_23"]          = int(G3 < G2)
    d["consecutive_drop"] = int(d["drop_12"] and d["drop_23"])

    LOW = 8
    d["g1_low"]         = int(G1 < LOW)
    d["g2_low"]         = int(G2 < LOW)
    d["g3_low"]         = int(G3 < LOW)
    d["all_grades_low"] = int(d["g1_low"] and d["g2_low"] and d["g3_low"])
    d["any_grade_zero"] = int(G1 == 0 or G2 == 0 or G3 == 0)

    d["absence_high"]      = int(d["absences"] > 10)
    d["absence_very_high"] = int(d["absences"] > 25)
    d["absence_x_grade"]   = d["absences"] * (20 - d["grade_avg_all"])

    # ── Tier B: MEDIUM priority (behavioral / social) ─────────────────────
    d["has_failures"]      = int(d["failures"] > 0)
    d["multiple_failures"] = int(d["failures"] >= 2)
    d["low_study"]         = int(d["studytime"] < 2)

    d["failures_x_grade"]    = d["failures"] * (20 - d["grade_avg_all"])
    d["study_effectiveness"] = d["studytime"] * d["grade_avg_all"]
    d["social_health"]       = d["famrel"] + d["health"]
    d["social_academic_risk"] = int(d["famrel"] <= 2 and d["grade_avg_all"] < 10)

    # ── Tier C: LOW priority composites ───────────────────────────────────
    d["financial_stress"]      = int(d["Debtor"] == 1 or d["Tuition fees up to date"] == 0)
    d["has_any_support"]       = int(d["Scholarship holder"] == 1 or d["schoolsup"] == 1 or d["famsup"] == 1)
    d["parent_occupation_sum"] = d["Mjob"] + d["Fjob"]

    # ── Tier D: weighted_risk_score ───────────────────────────────────────
    g1_risk     = 1 - _norm(G1,                *RANGES["G1"])
    g2_risk     = 1 - _norm(G2,                *RANGES["G2"])
    g3_risk     = 1 - _norm(G3,                *RANGES["G3"])
    abs_risk    =     _norm(d["absences"],     *RANGES["absences"])
    fail_risk   =     _norm(d["failures"],     *RANGES["failures"])
    study_risk  = 1 - _norm(d["studytime"],    *RANGES["studytime"])
    famrel_risk = 1 - _norm(d["famrel"],       *RANGES["famrel"])
    health_risk = 1 - _norm(d["health"],       *RANGES["health"])

    # Static pool: average of 11 binary / categorical risk signals
    static_risk = (
          _norm(d["Debtor"],                         0, 1)
        + (1 - _norm(d["Tuition fees up to date"],  0, 1))
        + (1 - _norm(d["Scholarship holder"],       0, 1))
        + _norm(d["Educational special needs"],     0, 1)
        + (1 - _norm(d["schoolsup"],                0, 1))
        + (1 - _norm(d["famsup"],                   0, 1))
        + (1 - _norm(d["paid"],                     0, 1))
        + (1 - _norm(d["activities"],               0, 1))
        + (1 - _norm(d["higher"],                   0, 1))
        + (1 - _norm(d["internet"],                 0, 1))
        + _norm(d["age"],                           *RANGES["age"])
    ) / 11.0

    d["weighted_risk_score"] = (
          g1_risk     * WEIGHTS["G1"]
        + g2_risk     * WEIGHTS["G2"]
        + g3_risk     * WEIGHTS["G3"]
        + abs_risk    * WEIGHTS["absences"]
        + fail_risk   * WEIGHTS["failures"]
        + study_risk  * WEIGHTS["studytime"]
        + famrel_risk * WEIGHTS["famrel"]
        + health_risk * WEIGHTS["health"]
        + static_risk * WEIGHTS["static_pool"]
    )

    return d


# ============================================================================
# PREDICTION SERVICE
# ============================================================================

class PredictionService:
    def __init__(self, model_dir):
        self.model_dir = model_dir
        self.model = None
        self.scaler = None
        self.feature_names = None
        self._load_artifacts()

    def predict(self, raw_data: dict):
        """
        Full pipeline: validate → fill defaults → engineer → order →
        scale → predict → build response.
        """
        try:
            ok, err = self.validate_input(raw_data)
            if not ok:
                return {"status": "error", "message": err}, 400

            # 1. Fill missing raw columns with defaults
            filled = {col: raw_data.get(col, RAW_DEFAULTS.get(col, 0))
                      for col in RAW_INPUT_COLUMNS}

            # 2. Derive all 29 engineered features
            full = engineer_features(filled)

            # 3. Order into a single-row DataFrame matching the model's columns
            import pandas as pd
            vector = pd.DataFrame(
                [[full.get(f, 0.0) for f in self.feature_names]],
                columns=self.feature_names,
                dtype=np.float64,
            )

            # 4. Scale → predict
            scaled      = self.scaler.transform(vector)
            prediction  = self.model.predict(scaled)[0]
            probs       = self.model.predict_proba(scaled)[0]
            risk_score  = float(probs[1])          # P(Dropout)

            # 5. Three-tier classification
            if risk_score >= 0.7:
                risk_level, emoji = "HIGH",   "🔴"
                recommendation     = "Immediate intervention required"
            elif risk_score >= 0.4:
                risk_level, emoji = "MEDIUM", "🟡"
                recommendation     = "Monitor closely and provide support"
            else:
                risk_level, emoji = "LOW",    "🟢"
                recommendation     = "Continue current support"

            # 6. Human-readable risk factors
            factors = self._get_risk_factors(filled)

            return {
                "status": "success",
                "prediction": {
                    "risk_level":          risk_level,
                    "risk_score":          round(risk_score, 3),
                    "dropout_probability": round(risk_score * 100, 1),
                    "continue_probability":round(float(probs[0]) * 100, 1),
                    "confidence":          f"{max(probs) * 100:.1f}%",
                    "emoji":               emoji,
                    "recommendation":      recommendation,
                },
                "risk_factors":  factors,
                "features_used": len([k for k in raw_data if k in RAW_DEFAULTS]),
                "timestamp":     datetime.now().isoformat(),
            }, 200

        except Exception as e:
            logger.error(f"Prediction error: {e}", exc_info=True)
            return {"status": "error", "message": f"Prediction failed: {e}"}, 500
        
    def validate_input(self, data):
        if not data or not isinstance(data, dict):
            return False, "Data must be a non-empty JSON object."

        # At least one of G1/G2/G3/absences must be present (HIGH priority)
        high_present = {"G1", "G2", "G3", "absences"} & set(data.keys())
        if not high_present:
            return False, (
                "At least one HIGH-priority field required: G1, G2, G3, absences"
            )

        # Type-check every recognised key
        for key in data:
            if key in RAW_DEFAULTS and not isinstance(data[key], (int, float)):
                return False, f"'{key}' must be numeric (got {type(data[key]).__name__})"

        return True, None

    @staticmethod
    def _get_risk_factors(d: dict) -> list:
        """
        Return plain-English risk factor strings based on the filled raw values.
        Checks are ordered by priority tier (HIGH → MEDIUM → LOW).
        """
        factors = []

        # ── HIGH: grades ──
        g1, g2, g3 = d["G1"], d["G2"], d["G3"]
        avg = (g1 + g2 + g3) / 3.0

        if g1 == 0 or g2 == 0 or g3 == 0:
            factors.append("One or more semester grades are zero")
        elif avg < 8:
            factors.append("Very low academic performance (avg < 8 / 20)")
        elif avg < 10:
            factors.append("Below-average academic performance (avg < 10 / 20)")

        if g2 < g1 and g3 < g2:
            factors.append("Consecutive grade decline across all three semesters")
        elif g2 < g1 or g3 < g2:
            factors.append("Grade decline detected between semesters")

        # ── HIGH: attendance ──
        absences = d["absences"]
        if absences > 25:
            factors.append("Very high absences (> 25 days)")
        elif absences > 10:
            factors.append("High absences (> 10 days)")

        # ── MEDIUM: failures & study ──
        failures = d["failures"]
        if failures >= 2:
            factors.append("Multiple past class failures")
        elif failures == 1:
            factors.append("One past class failure")

        if d["studytime"] < 2:
            factors.append("Low weekly study time (< 2 h)")

        # ── MEDIUM: social / health ──
        if d["famrel"] <= 2:
            factors.append("Poor family relationship quality")
        if d["health"] <= 2:
            factors.append("Poor health status")

        # ── LOW: financial / support ──
        if d["Debtor"] == 1:
            factors.append("Student has outstanding debt")
        if d["Tuition fees up to date"] == 0:
            factors.append("Tuition fees are NOT up to date")
        if d["Scholarship holder"] == 0 and d["schoolsup"] == 0 and d["famsup"] == 0:
            factors.append("No scholarship or support network active")

        return factors if factors else ["No major risk factors identified"]

    def _load_artifacts(self):
        # Priority 1: High-performance Ensembles from tuning
        # Priority 2: Individual Tuned Models
        # Priority 3: Original Base Models
        model_priority = [
            "stackingensemble_model.pkl", 
            "votingensemble_model.pkl",
            "optuna_randomforest_model.pkl",
            "random_randomforest_model.pkl",
            "randomforest_model.pkl"
        ]
        
        for name in model_priority:
            path = os.path.join(self.model_dir, name)
            if os.path.exists(path):
                self.model = joblib.load(path)
                logger.info(f"✅ Loaded optimal model: {name}")
                break
        
        if self.model is None:
            raise FileNotFoundError(f"No valid models found in {self.model_dir}")

        # Load tuned scaler and features
        self.scaler = joblib.load(os.path.join(self.model_dir, "scaler.pkl"))
        self.feature_names = joblib.load(os.path.join(self.model_dir, "feature_columns.pkl"))
        logger.info(f"✅ Using {len(self.feature_names)} features for prediction")

    # Inside the PredictionService class in flask_app_final.py
    def get_model_info(self):
        """Retrieves accuracy and tuning details from metadata."""
        try:
            metadata_path = os.path.join(self.model_dir, "model_metadata.pkl")
            if os.path.exists(metadata_path):
                metadata = joblib.load(metadata_path)
                return {
                    "status": "success",
                    "model_name": metadata.get('best_model'),
                    "performance_metrics": metadata.get('performance'),
                    "tuning_methods_used": metadata.get('tuning_methods'),
                    "feature_count": len(metadata.get('features', [])),
                    "last_tuned": datetime.fromtimestamp(os.path.getmtime(metadata_path)).isoformat()
                }
            return {"status": "error", "message": "Metadata file not found."}
        except Exception as e:
            return {"status": "error", "message": str(e)}

# ============================================================================
# INITIALISE SERVICE
# ============================================================================

try:
    prediction_service = PredictionService(MODEL_DIR)
except Exception as e:
    logger.error(f"Failed to initialize prediction service: {e}")
    prediction_service = None


# ============================================================================
# ENDPOINTS
# ============================================================================

@app.route('/model-info', methods=['GET'])
def model_info():
    """
    Returns the performance summary of the current tuned model.
    Data is pulled from the hyperparameter tuning metadata.
    """
    if prediction_service is None:
        return jsonify({"status": "error", "message": "Service not initialized"}), 503
    
    info = prediction_service.get_model_info()
    return jsonify(info)

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "name":    "4See — Student Dropout Prediction API",
        "version": "3.0",
        "status":  "running",
        "endpoints": {
            "/":              "API info (this page)",
            "/health":        "Liveness check (GET)",
            "/features":      "Raw columns the app must send (GET)",
            "/predict":       "Single-student prediction (POST)",
            "/batch":         "Multi-student prediction (POST)",
            "/test":          "Smoke-test with sample profiles (GET)",
            "/get-ai-advice": "LLM intervention advice (POST)",
        }
    })


@app.route('/health', methods=['GET'])
def health_check():
    if prediction_service is None:
        return jsonify({
            "status":       "unhealthy",
            "model_loaded": False,
            "error":        "Prediction service not initialized"
        }), 503

    return jsonify({
        "status":         "healthy",
        "model_loaded":   True,
        "model_type":     type(prediction_service.model).__name__,
        "features_count": len(prediction_service.feature_names),
        "timestamp":      datetime.now().isoformat(),
    })


@app.route('/features', methods=['GET'])
def get_features():
    """
    Returns the 28 RAW columns the Flutter app must send.
    Engineered features are computed server-side — the app doesn't need them.
    """
    if prediction_service is None:
        return jsonify({"error": "Service not initialized"}), 503

    return jsonify({
        "raw_inputs": RAW_INPUT_COLUMNS,
        "raw_count":  len(RAW_INPUT_COLUMNS),
        "note": (
            "Send only these 28 columns.  The API derives all internal "
            "features automatically.  Missing columns use sensible defaults."
        ),
        "defaults": RAW_DEFAULTS,
    })


@app.route('/predict', methods=['POST'])
def predict():
    """
    Single-student prediction.

    Body:
        { "data": { "G1": 12, "G2": 10, "G3": 8, "absences": 15, … } }

    The top-level "data" key is optional — root-level fields work too.
    """
    if prediction_service is None:
        return jsonify({"status": "error",
                        "message": "Prediction service not initialized"}), 503

    try:
        body = request.get_json(force=True)
    except Exception as e:
        return jsonify({"status": "error", "message": f"Invalid JSON: {e}"}), 400

    if not body:
        return jsonify({"status": "error", "message": "Empty body"}), 400

    student = body.get("data", body)          # accept both wrappers
    result, code = prediction_service.predict(student)

    if result.get("status") == "success":
        logger.info(
            f"Prediction → {result['prediction']['risk_level']} "
            f"(score {result['prediction']['risk_score']})"
        )

    return jsonify(result), code


@app.route('/batch', methods=['POST'])
def batch_predict():
    """
    Multi-student prediction.

    Body:
        { "students": [ {"id": "S001", "data": {...}}, … ] }
    """
    if prediction_service is None:
        return jsonify({"status": "error",
                        "message": "Prediction service not initialized"}), 503

    try:
        body     = request.get_json(force=True)
        students = body.get("students", [])

        if not students:
            return jsonify({"status": "error",
                            "message": "No students provided"}), 400

        results = []
        for s in students:
            sid  = s.get("id", "unknown")
            data = s.get("data", {})
            res, _ = prediction_service.predict(data)
            res["student_id"] = sid
            results.append(res)

        # Quick summary counts
        counts = {"HIGH": 0, "MEDIUM": 0, "LOW": 0}
        for r in results:
            if r.get("status") == "success":
                counts[r["prediction"]["risk_level"]] += 1

        return jsonify({
            "status":      "success",
            "count":       len(results),
            "summary":     counts,
            "predictions": results,
        })

    except Exception as e:
        logger.error(f"Batch error: {e}", exc_info=True)
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/test', methods=['GET'])
def test_prediction():
    """
    Three realistic sample profiles exercising LOW / MEDIUM / HIGH risk.
    All values match the columns and ranges in the actual dataset.
    """
    if prediction_service is None:
        return jsonify({"error": "Service not initialized"}), 503

    samples = {
        "low_risk": {
            # Strong grades, few absences, good support network
            "Course": 9500, "Daytime/evening attendance": 1,
            "Previous qualification": 1,
            "Mjob": 8, "Fjob": 7,
            "Educational special needs": 0,
            "Debtor": 0, "Tuition fees up to date": 1,
            "sex": 1, "Scholarship holder": 1,
            "age": 18,
            "G1": 16, "G2": 17, "G3": 15,
            "famsize": 1, "Pstatus": 1, "guardian": 0,
            "studytime": 3, "failures": 0,
            "schoolsup": 1, "famsup": 1, "paid": 1,
            "activities": 1, "higher": 1, "internet": 1,
            "famrel": 5, "health": 5, "absences": 2,
        },
        "medium_risk": {
            # Middling grades, moderate absences, limited support
            "Course": 9147, "Daytime/evening attendance": 1,
            "Previous qualification": 1,
            "Mjob": 4, "Fjob": 3,
            "Educational special needs": 0,
            "Debtor": 1, "Tuition fees up to date": 0,
            "sex": 0, "Scholarship holder": 0,
            "age": 20,
            "G1": 10, "G2": 9, "G3": 8,
            "famsize": 1, "Pstatus": 1, "guardian": 0,
            "studytime": 2, "failures": 1,
            "schoolsup": 0, "famsup": 0, "paid": 0,
            "activities": 0, "higher": 0, "internet": 1,
            "famrel": 3, "health": 3, "absences": 14,
        },
        "high_risk": {
            # Very low / zero grades, high absences, no support, debt
            "Course": 9853, "Daytime/evening attendance": 0,
            "Previous qualification": 9,
            "Mjob": 1, "Fjob": 1,
            "Educational special needs": 1,
            "Debtor": 1, "Tuition fees up to date": 0,
            "sex": 1, "Scholarship holder": 0,
            "age": 35,
            "G1": 2, "G2": 0, "G3": 0,
            "famsize": 0, "Pstatus": 0, "guardian": 2,
            "studytime": 1, "failures": 3,
            "schoolsup": 0, "famsup": 0, "paid": 0,
            "activities": 0, "higher": 0, "internet": 0,
            "famrel": 1, "health": 1, "absences": 40,
        },
    }

    results = {}
    for name, data in samples.items():
        res, _ = prediction_service.predict(data)
        results[name] = res

    return jsonify({
        "message": "Smoke-test with 3 sample profiles",
        "results": results,
    })


@app.route('/get-ai-advice', methods=['POST'])
def generate_advice():
    """Forward to the LLM helper for intervention suggestions."""
    if not _HAS_AI:
        return jsonify({
            "status":  "error",
            "message": "aiengine module not available — cannot generate advice."
        }), 503

    data   = request.get_json(force=True) or {}
    name   = data.get("name", "Student")
    risk   = data.get("risk_level", "Medium")
    issues = data.get("academic_issues", [])
    quiz   = data.get("quiz_flags", {})

    ai_response = get_student_advice(name, risk, issues, quiz)
    return jsonify(ai_response)


# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(e):
    return jsonify({
        "status":  "error",
        "message": "Endpoint not found",
        "available": ["/", "/health", "/features", "/predict", "/batch", "/test"]
    }), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({"status": "error", "message": "Method not allowed"}), 405

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"status": "error", "message": "Internal server error"}), 500


# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    # Point to the NEW tuned models directory
    TUNED_MODEL_DIR = './models_tuned'
    try:
        prediction_service = PredictionService(TUNED_MODEL_DIR)
    except Exception as e:
        logger.error(f"Failed to load tuned models: {e}")
        # Fallback to original models if tuning failed
        prediction_service = PredictionService('./models')
    
    app.run(host='0.0.0.0', port=5000)