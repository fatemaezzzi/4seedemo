"""
4See - Student Dropout Prediction System
=========================================
Interactive Gradio interface for HuggingFace Spaces

This app provides an AI-powered early warning system to predict student dropout risk
based on the ABC Model: Attendance, Behavior, and Course Performance.
"""

import gradio as gr
import joblib
import numpy as np
import pandas as pd
from pathlib import Path
import json
from typing import Dict, Tuple, List

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

# Raw input columns expected from users
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

# Default values for missing inputs
RAW_DEFAULTS = {
    "Course": 9500,
    "Daytime/evening attendance": 1,
    "Previous qualification": 1,
    "Mjob": 5,
    "Fjob": 5,
    "Educational special needs": 0,
    "Debtor": 0,
    "Tuition fees up to date": 1,
    "sex": 1,
    "Scholarship holder": 0,
    "age": 22,
    "G1": 11,
    "G2": 10,
    "G3": 10,
    "famsize": 1,
    "Pstatus": 1,
    "guardian": 0,
    "studytime": 2,
    "failures": 1,
    "schoolsup": 1,
    "famsup": 0,
    "paid": 1,
    "activities": 1,
    "higher": 0,
    "internet": 0,
    "famrel": 4,
    "health": 3,
    "absences": 6,
}

# Priority weights
WEIGHTS = {
    "G1": 0.18, "G2": 0.18, "G3": 0.18,
    "absences": 0.12,
    "failures": 0.07,
    "studytime": 0.05,
    "famrel": 0.03,
    "health": 0.03,
    "static_pool": 0.05,
}

# Normalization ranges
RANGES = {
    "G1": (0, 20),
    "G2": (0, 20),
    "G3": (0, 20),
    "absences": (0, 75),
    "failures": (0, 4),
    "studytime": (1, 4),
    "famrel": (1, 5),
    "health": (1, 5),
    "age": (15, 70),
}

# ============================================================================
# FEATURE ENGINEERING
# ============================================================================

def _norm(val, lo, hi):
    """Clip-normalize a single value to [0, 1]."""
    return max(0.0, min(1.0, (val - lo) / (hi - lo)))


def engineer_features(raw: dict) -> dict:
    """
    Takes the 28 raw columns and returns a flat dict with all 58 features
    the model expects.
    """
    d = dict(raw)
    G1, G2, G3 = d["G1"], d["G2"], d["G3"]

    # Tier A: HIGH priority (grades + attendance)
    d["grade_trend_12"] = G2 - G1
    d["grade_trend_23"] = G3 - G2
    d["grade_trend_13"] = G3 - G1
    d["grade_avg_all"] = (G1 + G2 + G3) / 3.0
    d["grade_avg_12"] = (G1 + G2) / 2.0
    d["grade_min"] = min(G1, G2, G3)
    d["grade_max"] = max(G1, G2, G3)
    d["grade_range"] = d["grade_max"] - d["grade_min"]
    d["drop_12"] = int(G2 < G1)
    d["drop_23"] = int(G3 < G2)
    d["consecutive_drop"] = int(d["drop_12"] and d["drop_23"])

    LOW = 8
    d["g1_low"] = int(G1 < LOW)
    d["g2_low"] = int(G2 < LOW)
    d["g3_low"] = int(G3 < LOW)
    d["all_grades_low"] = int(d["g1_low"] and d["g2_low"] and d["g3_low"])
    d["any_grade_zero"] = int(G1 == 0 or G2 == 0 or G3 == 0)

    d["absence_high"] = int(d["absences"] > 10)
    d["absence_very_high"] = int(d["absences"] > 25)
    d["absence_x_grade"] = d["absences"] * (20 - d["grade_avg_all"])

    # Tier B: MEDIUM priority
    d["has_failures"] = int(d["failures"] > 0)
    d["multiple_failures"] = int(d["failures"] >= 2)
    d["low_study"] = int(d["studytime"] < 2)
    d["failures_x_grade"] = d["failures"] * (20 - d["grade_avg_all"])
    d["study_effectiveness"] = d["studytime"] * d["grade_avg_all"]
    d["social_health"] = d["famrel"] + d["health"]
    d["social_academic_risk"] = int(d["famrel"] <= 2 and d["grade_avg_all"] < 10)

    # Tier C: LOW priority
    d["financial_stress"] = int(d["Debtor"] == 1 or d["Tuition fees up to date"] == 0)
    d["has_any_support"] = int(d["Scholarship holder"] == 1 or d["schoolsup"] == 1 or d["famsup"] == 1)
    d["parent_occupation_sum"] = d["Mjob"] + d["Fjob"]

    # Tier D: weighted_risk_score
    g1_risk = 1 - _norm(G1, *RANGES["G1"])
    g2_risk = 1 - _norm(G2, *RANGES["G2"])
    g3_risk = 1 - _norm(G3, *RANGES["G3"])
    abs_risk = _norm(d["absences"], *RANGES["absences"])
    fail_risk = _norm(d["failures"], *RANGES["failures"])
    study_risk = 1 - _norm(d["studytime"], *RANGES["studytime"])
    famrel_risk = 1 - _norm(d["famrel"], *RANGES["famrel"])
    health_risk = 1 - _norm(d["health"], *RANGES["health"])

    static_risk = (
        _norm(d["Debtor"], 0, 1)
        + (1 - _norm(d["Tuition fees up to date"], 0, 1))
        + (1 - _norm(d["Scholarship holder"], 0, 1))
        + _norm(d["Educational special needs"], 0, 1)
        + (1 - _norm(d["schoolsup"], 0, 1))
        + (1 - _norm(d["famsup"], 0, 1))
        + (1 - _norm(d["paid"], 0, 1))
        + (1 - _norm(d["activities"], 0, 1))
        + (1 - _norm(d["higher"], 0, 1))
        + (1 - _norm(d["internet"], 0, 1))
        + _norm(d["age"], *RANGES["age"])
    ) / 11.0

    d["weighted_risk_score"] = (
        WEIGHTS["G1"] * g1_risk
        + WEIGHTS["G2"] * g2_risk
        + WEIGHTS["G3"] * g3_risk
        + WEIGHTS["absences"] * abs_risk
        + WEIGHTS["failures"] * fail_risk
        + WEIGHTS["studytime"] * study_risk
        + WEIGHTS["famrel"] * famrel_risk
        + WEIGHTS["health"] * health_risk
        + WEIGHTS["static_pool"] * static_risk
    )

    return d


# ============================================================================
# MODEL LOADING
# ============================================================================

class PredictionService:
    """Handles model loading and prediction."""
    
    def __init__(self, model_dir: str = "./models"):
        """Load all required models and artifacts."""
        self.model_dir = Path(model_dir)
        
        # Load models
        self.rf_model = joblib.load(self.model_dir / "randomforest_model.pkl")
        self.gb_model = joblib.load(self.model_dir / "gradientboosting_model.pkl")
        self.lr_model = joblib.load(self.model_dir / "logisticregression_model.pkl")
        
        # Load preprocessing artifacts
        self.scaler = joblib.load(self.model_dir / "scaler.pkl")
        self.feature_columns = joblib.load(self.model_dir / "feature_columns.pkl")
        self.label_encoders = joblib.load(self.model_dir / "label_encoders.pkl")
        
        # Load metadata
        try:
            self.metadata = joblib.load(self.model_dir / "model_metadata.pkl")
            self.best_model_name = self.metadata.get("best_model", "RandomForest")
        except:
            self.best_model_name = "RandomForest"
        
        # Set best model
        model_map = {
            "RandomForest": self.rf_model,
            "GradientBoosting": self.gb_model,
            "LogisticRegression": self.lr_model,
        }
        self.best_model = model_map.get(self.best_model_name, self.rf_model)
        
        print(f"✅ Models loaded successfully. Best model: {self.best_model_name}")
    
    def predict(self, raw_data: dict) -> Tuple[str, float, dict, str]:
        """
        Predict dropout risk for a student.
        
        Returns:
            - risk_level: "HIGH", "MEDIUM", or "LOW"
            - risk_score: probability (0-1)
            - risk_factors: dict of identified issues
            - recommendations: intervention suggestions
        """
        # Fill missing values with defaults
        for col in RAW_INPUT_COLUMNS:
            if col not in raw_data or raw_data[col] is None:
                raw_data[col] = RAW_DEFAULTS[col]
        
        # Engineer features
        full_features = engineer_features(raw_data)
        
        # Create feature vector in correct order
        feature_vector = []
        for col in self.feature_columns:
            feature_vector.append(full_features.get(col, 0))
        
        # Scale features
        X = np.array(feature_vector).reshape(1, -1)
        X_scaled = self.scaler.transform(X)
        
        # Predict
        risk_prob = self.best_model.predict_proba(X_scaled)[0][1]
        
        # Determine risk level
        if risk_prob >= 0.7:
            risk_level = "HIGH"
        elif risk_prob >= 0.4:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"
        
        # Identify risk factors
        risk_factors = self._identify_risk_factors(raw_data, full_features)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(risk_level, risk_factors, raw_data)
        
        return risk_level, risk_prob, risk_factors, recommendations
    
    def _identify_risk_factors(self, raw: dict, engineered: dict) -> dict:
        """Identify specific risk factors for the student."""
        factors = {}
        
        # Academic performance
        if engineered["grade_avg_all"] < 10:
            factors["Low Academic Performance"] = f"Average grade: {engineered['grade_avg_all']:.1f}/20"
        
        if engineered["consecutive_drop"]:
            factors["Declining Grades"] = "Grades dropping consistently across semesters"
        
        # Attendance
        if raw["absences"] > 25:
            factors["Very High Absences"] = f"{raw['absences']} days absent"
        elif raw["absences"] > 10:
            factors["High Absences"] = f"{raw['absences']} days absent"
        
        # Behavioral
        if raw["failures"] >= 2:
            factors["Multiple Failures"] = f"{raw['failures']} previous failures"
        elif raw["failures"] > 0:
            factors["Previous Failure"] = f"{raw['failures']} previous failure(s)"
        
        if raw["studytime"] < 2:
            factors["Low Study Time"] = "Less than 2 hours of study per week"
        
        # Social/Family
        if raw["famrel"] <= 2:
            factors["Poor Family Relations"] = "Low family relationship quality"
        
        if engineered["financial_stress"]:
            factors["Financial Stress"] = "Debtor or tuition fees not up to date"
        
        if not engineered["has_any_support"]:
            factors["Lack of Support"] = "No scholarship, school support, or family support"
        
        return factors
    
    def _generate_recommendations(self, risk_level: str, factors: dict, raw: dict) -> str:
        """Generate tiered intervention recommendations."""
        recommendations = []
        
        if risk_level == "HIGH":
            recommendations.append("🚨 **URGENT INTERVENTION REQUIRED**\n")
            recommendations.append("**Immediate Actions:**")
            recommendations.append("1. Schedule emergency meeting with student and parents/guardians")
            recommendations.append("2. Develop Individual Education Plan (IEP)")
            recommendations.append("3. Refer to school counselor and external support services")
            recommendations.append("4. Implement daily check-ins and progress monitoring")
            
        elif risk_level == "MEDIUM":
            recommendations.append("⚠️ **TARGETED INTERVENTION RECOMMENDED**\n")
            recommendations.append("**Actions to Take:**")
            recommendations.append("1. Set up weekly check-in meetings")
            recommendations.append("2. Arrange peer mentoring or tutoring sessions")
            recommendations.append("3. Contact parents/guardians to discuss concerns")
            
        else:
            recommendations.append("✅ **STUDENT ON TRACK**\n")
            recommendations.append("**Continue Universal Strategies:**")
            recommendations.append("1. Maintain positive reinforcement")
            recommendations.append("2. Regular monitoring of attendance and grades")
        
        # Specific interventions based on risk factors
        if factors:
            recommendations.append("\n**Specific Interventions Based on Risk Factors:**")
            
            if "Low Academic Performance" in factors or "Declining Grades" in factors:
                recommendations.append("• Academic: One-on-one tutoring in struggling subjects")
                recommendations.append("• Academic: Supplemental learning resources and materials")
            
            if "High Absences" in factors or "Very High Absences" in factors:
                recommendations.append("• Attendance: Investigate root causes of absences")
                recommendations.append("• Attendance: Implement attendance improvement plan")
            
            if "Multiple Failures" in factors or "Previous Failure" in factors:
                recommendations.append("• Academic: Review and address learning gaps")
                recommendations.append("• Academic: Consider alternative learning strategies")
            
            if "Low Study Time" in factors:
                recommendations.append("• Behavioral: Teach time management and study skills")
                recommendations.append("• Behavioral: Create structured study schedule")
            
            if "Poor Family Relations" in factors:
                recommendations.append("• Social: Family counseling or mediation services")
                recommendations.append("• Social: Build positive adult relationships at school")
            
            if "Financial Stress" in factors:
                recommendations.append("• Financial: Connect with financial aid resources")
                recommendations.append("• Financial: Explore scholarship opportunities")
            
            if "Lack of Support" in factors:
                recommendations.append("• Support: Enroll in peer mentoring program")
                recommendations.append("• Support: Connect with community support services")
        
        return "\n".join(recommendations)


# ============================================================================
# INITIALIZE SERVICE
# ============================================================================

# Try to load models
try:
    prediction_service = PredictionService("./models")
    MODEL_LOADED = True
except Exception as e:
    print(f"⚠️ Warning: Could not load models - {e}")
    MODEL_LOADED = False
    prediction_service = None


# ============================================================================
# GRADIO INTERFACE FUNCTIONS
# ============================================================================

def predict_single_student(
    course, attendance_type, prev_qual, mjob, fjob, special_needs,
    debtor, tuition_paid, sex, scholarship, age,
    g1, g2, g3, famsize, pstatus, guardian,
    studytime, failures, schoolsup, famsup, paid,
    activities, higher, internet, famrel, health, absences
):
    """Handle single student prediction from Gradio interface."""
    
    if not MODEL_LOADED:
        return (
            "⚠️ Model not loaded",
            0.0,
            "Models are not available. Please ensure model files are in the ./models directory.",
            ""
        )
    
    # Create input dictionary
    student_data = {
        "Course": course,
        "Daytime/evening attendance": attendance_type,
        "Previous qualification": prev_qual,
        "Mjob": mjob,
        "Fjob": fjob,
        "Educational special needs": special_needs,
        "Debtor": debtor,
        "Tuition fees up to date": tuition_paid,
        "sex": sex,
        "Scholarship holder": scholarship,
        "age": age,
        "G1": g1,
        "G2": g2,
        "G3": g3,
        "famsize": famsize,
        "Pstatus": pstatus,
        "guardian": guardian,
        "studytime": studytime,
        "failures": failures,
        "schoolsup": schoolsup,
        "famsup": famsup,
        "paid": paid,
        "activities": activities,
        "higher": higher,
        "internet": internet,
        "famrel": famrel,
        "health": health,
        "absences": absences,
    }
    
    try:
        risk_level, risk_score, risk_factors, recommendations = prediction_service.predict(student_data)
        
        # Format risk factors
        if risk_factors:
            factors_text = "\n".join([f"• **{k}**: {v}" for k, v in risk_factors.items()])
        else:
            factors_text = "No significant risk factors identified."
        
        # Create risk indicator
        if risk_level == "HIGH":
            risk_indicator = "🔴 HIGH RISK"
            risk_color = "red"
        elif risk_level == "MEDIUM":
            risk_indicator = "🟡 MEDIUM RISK"
            risk_color = "orange"
        else:
            risk_indicator = "🟢 LOW RISK"
            risk_color = "green"
        
        return (
            risk_indicator,
            round(risk_score * 100, 1),
            factors_text,
            recommendations
        )
    
    except Exception as e:
        return (
            "⚠️ Error",
            0.0,
            f"An error occurred: {str(e)}",
            ""
        )


def predict_batch_csv(file):
    """Handle batch prediction from uploaded CSV file."""
    
    if not MODEL_LOADED:
        return "⚠️ Models not loaded. Please ensure model files are available."
    
    try:
        # Read CSV
        df = pd.read_csv(file.name)
        
        results = []
        for idx, row in df.iterrows():
            # Convert row to dict
            student_data = row.to_dict()
            
            # Predict
            risk_level, risk_score, risk_factors, _ = prediction_service.predict(student_data)
            
            # Add results
            results.append({
                "Student_ID": row.get("Student_ID", f"Student_{idx+1}"),
                "Risk_Level": risk_level,
                "Risk_Score": round(risk_score * 100, 1),
                "Key_Risk_Factors": ", ".join(risk_factors.keys()) if risk_factors else "None"
            })
        
        # Create results dataframe
        results_df = pd.DataFrame(results)
        
        # Save to CSV
        output_path = "/tmp/prediction_results.csv"
        results_df.to_csv(output_path, index=False)
        
        # Create summary
        summary = f"""
## Batch Prediction Summary

**Total Students Analyzed:** {len(results_df)}

**Risk Distribution:**
- 🔴 HIGH Risk: {len(results_df[results_df['Risk_Level'] == 'HIGH'])} students ({len(results_df[results_df['Risk_Level'] == 'HIGH'])/len(results_df)*100:.1f}%)
- 🟡 MEDIUM Risk: {len(results_df[results_df['Risk_Level'] == 'MEDIUM'])} students ({len(results_df[results_df['Risk_Level'] == 'MEDIUM'])/len(results_df)*100:.1f}%)
- 🟢 LOW Risk: {len(results_df[results_df['Risk_Level'] == 'LOW'])} students ({len(results_df[results_df['Risk_Level'] == 'LOW'])/len(results_df)*100:.1f}%)

Download the detailed results file below.
        """
        
        return summary, output_path
    
    except Exception as e:
        return f"❌ Error processing file: {str(e)}", None


# ============================================================================
# SAMPLE DATA GENERATORS
# ============================================================================

def load_low_risk_sample():
    """Load low-risk sample data."""
    return (
        9500, 1, 1, 8, 7, 0, 0, 1, 1, 1, 18,
        16, 17, 15, 1, 1, 0, 3, 0, 1, 1, 1,
        1, 1, 1, 5, 5, 2
    )

def load_medium_risk_sample():
    """Load medium-risk sample data."""
    return (
        9147, 1, 1, 4, 3, 0, 1, 0, 0, 0, 20,
        10, 9, 8, 1, 1, 0, 2, 1, 0, 0, 0,
        0, 0, 1, 3, 3, 14
    )

def load_high_risk_sample():
    """Load high-risk sample data."""
    return (
        9853, 0, 9, 1, 1, 1, 1, 0, 1, 0, 35,
        2, 0, 0, 0, 0, 2, 1, 3, 0, 0, 0,
        0, 0, 0, 1, 1, 40
    )


# ============================================================================
# GRADIO UI
# ============================================================================

# Custom CSS
custom_css = """
.risk-high {background-color: #fee; border-left: 5px solid #f00;}
.risk-medium {background-color: #ffe; border-left: 5px solid #fa0;}
.risk-low {background-color: #efe; border-left: 5px solid #0f0;}
.container {max-width: 1200px; margin: auto;}
"""

# Create Gradio interface
with gr.Blocks(css=custom_css, title="4See - Student Dropout Prediction") as demo:
    
    gr.Markdown("""
    # 🎓 4See - AI-Powered Student Dropout Prediction System
    
    ### Stop Counting Dropouts. Start Creating Success Stories.
    
    This system uses the **ABC Model** (Attendance, Behavior, Course Performance) to predict student dropout risk
    and provide actionable intervention strategies.
    
    ---
    """)
    
    with gr.Tabs():
        
        # ===== TAB 1: SINGLE STUDENT PREDICTION =====
        with gr.Tab("📊 Single Student Analysis"):
            gr.Markdown("### Enter student information to get dropout risk assessment")
            
            with gr.Row():
                with gr.Column():
                    gr.Markdown("#### 📚 **Academic Information**")
                    course = gr.Number(label="Course Code", value=9500)
                    g1 = gr.Slider(0, 20, value=11, step=1, label="Grade 1 (G1) - First Period")
                    g2 = gr.Slider(0, 20, value=10, step=1, label="Grade 2 (G2) - Second Period")
                    g3 = gr.Slider(0, 20, value=10, step=1, label="Grade 3 (G3) - Final Grade")
                    failures = gr.Slider(0, 4, value=0, step=1, label="Number of Past Failures")
                    studytime = gr.Slider(1, 4, value=2, step=1, label="Weekly Study Time (1=<2h, 4=>10h)")
                    
                    gr.Markdown("#### 🏫 **Attendance & Behavior**")
                    absences = gr.Slider(0, 75, value=6, step=1, label="Number of Absences")
                    attendance_type = gr.Radio([0, 1], value=1, label="Attendance Type (0=Evening, 1=Daytime)")
                
                with gr.Column():
                    gr.Markdown("#### 👨‍👩‍👧 **Family & Social**")
                    mjob = gr.Slider(1, 10, value=5, step=1, label="Mother's Job (1-10 scale)")
                    fjob = gr.Slider(1, 10, value=5, step=1, label="Father's Job (1-10 scale)")
                    famrel = gr.Slider(1, 5, value=4, step=1, label="Family Relationship Quality (1=Poor, 5=Excellent)")
                    famsize = gr.Radio([0, 1], value=1, label="Family Size (0=≤3, 1=>3)")
                    pstatus = gr.Radio([0, 1], value=1, label="Parent Status (0=Apart, 1=Together)")
                    guardian = gr.Radio([0, 1, 2], value=0, label="Guardian (0=Mother, 1=Father, 2=Other)")
                    
                    gr.Markdown("#### 💰 **Financial & Support**")
                    debtor = gr.Radio([0, 1], value=0, label="Is Debtor? (0=No, 1=Yes)")
                    tuition_paid = gr.Radio([0, 1], value=1, label="Tuition Up to Date? (0=No, 1=Yes)")
                    scholarship = gr.Radio([0, 1], value=0, label="Has Scholarship? (0=No, 1=Yes)")
                    schoolsup = gr.Radio([0, 1], value=1, label="School Support? (0=No, 1=Yes)")
                    famsup = gr.Radio([0, 1], value=0, label="Family Support? (0=No, 1=Yes)")
                    paid = gr.Radio([0, 1], value=1, label="Paid Extra Classes? (0=No, 1=Yes)")
                
                with gr.Column():
                    gr.Markdown("#### 👤 **Personal Information**")
                    age = gr.Slider(15, 70, value=22, step=1, label="Age")
                    sex = gr.Radio([0, 1], value=1, label="Sex (0=Female, 1=Male)")
                    prev_qual = gr.Number(label="Previous Qualification Code", value=1)
                    special_needs = gr.Radio([0, 1], value=0, label="Educational Special Needs? (0=No, 1=Yes)")
                    
                    gr.Markdown("#### 🎯 **Activities & Aspirations**")
                    activities = gr.Radio([0, 1], value=1, label="Extra-curricular Activities? (0=No, 1=Yes)")
                    higher = gr.Radio([0, 1], value=0, label="Wants Higher Education? (0=No, 1=Yes)")
                    internet = gr.Radio([0, 1], value=0, label="Has Internet Access? (0=No, 1=Yes)")
                    health = gr.Slider(1, 5, value=3, step=1, label="Health Status (1=Poor, 5=Excellent)")
            
            with gr.Row():
                predict_btn = gr.Button("🔍 Analyze Student Risk", variant="primary", size="lg")
            
            with gr.Row():
                gr.Markdown("### Quick Load Sample Data:")
                low_btn = gr.Button("✅ Low Risk Sample", size="sm")
                med_btn = gr.Button("⚠️ Medium Risk Sample", size="sm")
                high_btn = gr.Button("🚨 High Risk Sample", size="sm")
            
            gr.Markdown("---")
            gr.Markdown("### 📋 **Prediction Results**")
            
            with gr.Row():
                with gr.Column(scale=1):
                    risk_output = gr.Textbox(label="Risk Level", interactive=False, lines=1)
                    score_output = gr.Number(label="Risk Score (%)", interactive=False)
                
                with gr.Column(scale=2):
                    factors_output = gr.Markdown(label="Identified Risk Factors")
            
            recommendations_output = gr.Markdown(label="Intervention Recommendations")
            
            # Connect buttons
            predict_btn.click(
                fn=predict_single_student,
                inputs=[
                    course, attendance_type, prev_qual, mjob, fjob, special_needs,
                    debtor, tuition_paid, sex, scholarship, age,
                    g1, g2, g3, famsize, pstatus, guardian,
                    studytime, failures, schoolsup, famsup, paid,
                    activities, higher, internet, famrel, health, absences
                ],
                outputs=[risk_output, score_output, factors_output, recommendations_output]
            )
            
            # Sample data buttons
            low_btn.click(
                fn=load_low_risk_sample,
                outputs=[
                    course, attendance_type, prev_qual, mjob, fjob, special_needs,
                    debtor, tuition_paid, sex, scholarship, age,
                    g1, g2, g3, famsize, pstatus, guardian,
                    studytime, failures, schoolsup, famsup, paid,
                    activities, higher, internet, famrel, health, absences
                ]
            )
            
            med_btn.click(
                fn=load_medium_risk_sample,
                outputs=[
                    course, attendance_type, prev_qual, mjob, fjob, special_needs,
                    debtor, tuition_paid, sex, scholarship, age,
                    g1, g2, g3, famsize, pstatus, guardian,
                    studytime, failures, schoolsup, famsup, paid,
                    activities, higher, internet, famrel, health, absences
                ]
            )
            
            high_btn.click(
                fn=load_high_risk_sample,
                outputs=[
                    course, attendance_type, prev_qual, mjob, fjob, special_needs,
                    debtor, tuition_paid, sex, scholarship, age,
                    g1, g2, g3, famsize, pstatus, guardian,
                    studytime, failures, schoolsup, famsup, paid,
                    activities, higher, internet, famrel, health, absences
                ]
            )
        
        # ===== TAB 2: BATCH PREDICTION =====
        with gr.Tab("📁 Batch Analysis"):
            gr.Markdown("""
            ### Upload a CSV file to analyze multiple students at once
            
            Your CSV file should contain columns matching the student data format.
            Download the template below to see the required format.
            """)
            
            csv_input = gr.File(label="Upload Student Data CSV", file_types=[".csv"])
            batch_btn = gr.Button("🔍 Analyze Batch", variant="primary", size="lg")
            
            batch_summary = gr.Markdown(label="Batch Analysis Summary")
            batch_output = gr.File(label="Download Results")
            
            batch_btn.click(
                fn=predict_batch_csv,
                inputs=[csv_input],
                outputs=[batch_summary, batch_output]
            )
        
        # ===== TAB 3: ABOUT =====
        with gr.Tab("ℹ️ About"):
            gr.Markdown("""
            ## About 4See - Student Dropout Prediction System
            
            ### 🎯 Mission
            Our mission is to shift from reactive problem-solving to proactive student support, ensuring no student falls through the cracks.
            
            ### 🧠 The ABC Model
            Our AI analyzes three core pillars of student success:
            
            - **📚 Attendance**: Patterns of absenteeism and attendance trends
            - **👤 Behavior**: Disciplinary incidents, study habits, and social integration
            - **📊 Course Performance**: Academic grades, grade trends, and failures
            
            ### 🔍 Risk Levels
            
            - **🔴 HIGH RISK** (70%+): Urgent intervention required - student at critical risk of dropping out
            - **🟡 MEDIUM RISK** (40-70%): Targeted intervention recommended - early warning signs present
            - **🟢 LOW RISK** (<40%): Student on track - continue universal support strategies
            
            ### 💡 Features
            
            1. **Predictive Intelligence**: 85%+ accuracy using localized dropout patterns
            2. **Tiered Interventions**: Universal, Targeted, and Tailored action plans
            3. **Early Warning**: Identify at-risk students 3-6 months before dropout
            4. **Actionable Insights**: Specific recommendations for each student
            
            ### 🏆 Impact Goal
            Identify 80%+ of potential dropouts 3-6 months before they actually leave school
            
            ### 👥 Team 404 Rescued
            - **Fatema Ezzi** - Team Leader
            - **Krithika Naidu** - Team Member
            - **Kanksha Mhatre** - Team Member
            - **Deep Gada** - Team Member
            
            **Institution**: K.J. Somaiya Polytechnic, Mumbai
            
            **Problem Statement**: TFC 01 - Proactive Education Assistant for Reducing Primary Dropouts
            
            ---
            
            ### 📖 References
            
            This system is based on research-backed methodologies:
            - ABC Model for Early Warning Systems
            - Machine Learning approaches for educational data mining
            - Evidence-based intervention frameworks
            
            ### 🔒 Privacy & Ethics
            - Student data is processed securely
            - Predictions are tools to support, not label, students
            - Designed to empower educators, not replace human judgment
            
            ### 📞 Support
            For questions or feedback about this system, please contact the development team.
            """)
    
    gr.Markdown("""
    ---
    <center>
    <p style="color: #666; font-size: 0.9em;">
    © 2025 Team 404 Rescued | K.J. Somaiya Polytechnic, Mumbai<br>
    Built for VES Technothon 2025 | Powered by AI for Social Good
    </p>
    </center>
    """)


# ============================================================================
# LAUNCH
# ============================================================================

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",
        server_port=7860,
        share=False,
        show_error=True
    )


#-----------------OTHER VERSION OF app.py-------------------------------------

# """
# 4See - Student Dropout Prediction System (Single Semester Mode)
# ================================================================
# SIMPLIFIED for teachers - focuses on CURRENT semester performance

# Key Philosophy:
# - Teachers input CURRENT semester data (required)
# - Previous semester data is OPTIONAL (if available)
# - Model works with whatever data you have!

# This matches real teaching scenarios where:
# - New students have no history
# - Teachers track current performance
# - Historical data improves accuracy but isn't required
# """

# import gradio as gr
# import joblib
# import numpy as np
# import pandas as pd
# from pathlib import Path
# from typing import Tuple, Dict, Optional

# # ============================================================================
# # CONFIGURATION
# # ============================================================================

# RAW_INPUT_COLUMNS = [
#     "Course", "Daytime/evening attendance", "Previous qualification",
#     "Mjob", "Fjob", "Educational special needs", "Debtor",
#     "Tuition fees up to date", "sex", "Scholarship holder", "age",
#     "G1", "G2", "G3",  # G3 = current, G2 = previous, G1 = older
#     "famsize", "Pstatus", "guardian", "studytime", "failures",
#     "schoolsup", "famsup", "paid", "activities", "higher", "internet",
#     "famrel", "health", "absences",
# ]

# RAW_DEFAULTS = {
#     "Course": 9500, "Daytime/evening attendance": 1, "Previous qualification": 1,
#     "Mjob": 5, "Fjob": 5, "Educational special needs": 0, "Debtor": 0,
#     "Tuition fees up to date": 1, "sex": 1, "Scholarship holder": 0, "age": 22,
#     "G1": 10, "G2": 10, "G3": 10,
#     "famsize": 1, "Pstatus": 1, "guardian": 0, "studytime": 2, "failures": 1,
#     "schoolsup": 1, "famsup": 0, "paid": 1, "activities": 1, "higher": 0,
#     "internet": 0, "famrel": 4, "health": 3, "absences": 6,
# }

# WEIGHTS = {
#     "G1": 0.18, "G2": 0.18, "G3": 0.18, "absences": 0.12,
#     "failures": 0.07, "studytime": 0.05, "famrel": 0.03,
#     "health": 0.03, "static_pool": 0.05,
# }

# RANGES = {
#     "G1": (0, 20), "G2": (0, 20), "G3": (0, 20), "absences": (0, 75),
#     "failures": (0, 4), "studytime": (1, 4), "famrel": (1, 5),
#     "health": (1, 5), "age": (15, 70),
# }

# # ============================================================================
# # HELPER FUNCTIONS
# # ============================================================================

# def smart_grade_filling(current_grade: float, 
#                        previous_grade: Optional[float] = None,
#                        older_grade: Optional[float] = None) -> Tuple[float, float, float]:
#     """
#     Smart filling strategy for grades:
#     - G3 (most recent) = current_grade (REQUIRED)
#     - G2 (previous) = previous_grade if available, else current_grade
#     - G1 (older) = older_grade if available, else G2
    
#     This ensures the model always has 3 values but prioritizes real data.
    
#     Examples:
#         (12, None, None) → (12, 12, 12) - Only current available
#         (12, 14, None) → (14, 14, 12) - Current + previous available
#         (12, 14, 16) → (16, 14, 12) - All three available
#     """
#     g3 = float(current_grade)  # Most recent (required)
    
#     if previous_grade is not None and previous_grade > 0:
#         g2 = float(previous_grade)
#     else:
#         g2 = g3  # Use current if no previous
    
#     if older_grade is not None and older_grade > 0:
#         g1 = float(older_grade)
#     else:
#         g1 = g2  # Use previous (or current) if no older
    
#     return (g1, g2, g3)


# def _norm(val, lo, hi):
#     """Clip-normalize a single value to [0, 1]."""
#     return max(0.0, min(1.0, (val - lo) / (hi - lo)))


# def engineer_features(raw: dict) -> dict:
#     """Engineer all 58 features from 28 raw inputs."""
#     d = dict(raw)
#     G1, G2, G3 = d["G1"], d["G2"], d["G3"]

#     # Tier A: Grade features
#     d["grade_trend_12"] = G2 - G1
#     d["grade_trend_23"] = G3 - G2
#     d["grade_trend_13"] = G3 - G1
#     d["grade_avg_all"] = (G1 + G2 + G3) / 3.0
#     d["grade_avg_12"] = (G1 + G2) / 2.0
#     d["grade_min"] = min(G1, G2, G3)
#     d["grade_max"] = max(G1, G2, G3)
#     d["grade_range"] = d["grade_max"] - d["grade_min"]
#     d["drop_12"] = int(G2 < G1)
#     d["drop_23"] = int(G3 < G2)
#     d["consecutive_drop"] = int(d["drop_12"] and d["drop_23"])

#     LOW = 8
#     d["g1_low"] = int(G1 < LOW)
#     d["g2_low"] = int(G2 < LOW)
#     d["g3_low"] = int(G3 < LOW)
#     d["all_grades_low"] = int(d["g1_low"] and d["g2_low"] and d["g3_low"])
#     d["any_grade_zero"] = int(G1 == 0 or G2 == 0 or G3 == 0)
#     d["absence_high"] = int(d["absences"] > 10)
#     d["absence_very_high"] = int(d["absences"] > 25)
#     d["absence_x_grade"] = d["absences"] * (20 - d["grade_avg_all"])

#     # Tier B: Behavioral
#     d["has_failures"] = int(d["failures"] > 0)
#     d["multiple_failures"] = int(d["failures"] >= 2)
#     d["low_study"] = int(d["studytime"] < 2)
#     d["failures_x_grade"] = d["failures"] * (20 - d["grade_avg_all"])
#     d["study_effectiveness"] = d["studytime"] * d["grade_avg_all"]
#     d["social_health"] = d["famrel"] + d["health"]
#     d["social_academic_risk"] = int(d["famrel"] <= 2 and d["grade_avg_all"] < 10)

#     # Tier C: Static
#     d["financial_stress"] = int(d["Debtor"] == 1 or d["Tuition fees up to date"] == 0)
#     d["has_any_support"] = int(d["Scholarship holder"] == 1 or d["schoolsup"] == 1 or d["famsup"] == 1)
#     d["parent_occupation_sum"] = d["Mjob"] + d["Fjob"]

#     # Tier D: Weighted risk score
#     g1_risk = 1 - _norm(G1, *RANGES["G1"])
#     g2_risk = 1 - _norm(G2, *RANGES["G2"])
#     g3_risk = 1 - _norm(G3, *RANGES["G3"])
#     abs_risk = _norm(d["absences"], *RANGES["absences"])
#     fail_risk = _norm(d["failures"], *RANGES["failures"])
#     study_risk = 1 - _norm(d["studytime"], *RANGES["studytime"])
#     famrel_risk = 1 - _norm(d["famrel"], *RANGES["famrel"])
#     health_risk = 1 - _norm(d["health"], *RANGES["health"])

#     static_risk = (
#         _norm(d["Debtor"], 0, 1) + (1 - _norm(d["Tuition fees up to date"], 0, 1)) +
#         (1 - _norm(d["Scholarship holder"], 0, 1)) + _norm(d["Educational special needs"], 0, 1) +
#         (1 - _norm(d["schoolsup"], 0, 1)) + (1 - _norm(d["famsup"], 0, 1)) +
#         (1 - _norm(d["paid"], 0, 1)) + (1 - _norm(d["activities"], 0, 1)) +
#         (1 - _norm(d["higher"], 0, 1)) + (1 - _norm(d["internet"], 0, 1)) +
#         _norm(d["age"], *RANGES["age"])
#     ) / 11.0

#     d["weighted_risk_score"] = (
#         WEIGHTS["G1"] * g1_risk + WEIGHTS["G2"] * g2_risk + WEIGHTS["G3"] * g3_risk +
#         WEIGHTS["absences"] * abs_risk + WEIGHTS["failures"] * fail_risk +
#         WEIGHTS["studytime"] * study_risk + WEIGHTS["famrel"] * famrel_risk +
#         WEIGHTS["health"] * health_risk + WEIGHTS["static_pool"] * static_risk
#     )

#     return d

# # ============================================================================
# # MODEL SERVICE
# # ============================================================================

# class PredictionService:
#     def __init__(self, model_dir: str = "./models"):
#         self.model_dir = Path(model_dir)
#         self.rf_model = joblib.load(self.model_dir / "randomforest_model.pkl")
#         self.gb_model = joblib.load(self.model_dir / "gradientboosting_model.pkl")
#         self.lr_model = joblib.load(self.model_dir / "logisticregression_model.pkl")
#         self.scaler = joblib.load(self.model_dir / "scaler.pkl")
#         self.feature_columns = joblib.load(self.model_dir / "feature_columns.pkl")
#         self.label_encoders = joblib.load(self.model_dir / "label_encoders.pkl")
        
#         try:
#             self.metadata = joblib.load(self.model_dir / "model_metadata.pkl")
#             self.best_model_name = self.metadata.get("best_model", "RandomForest")
#         except:
#             self.best_model_name = "RandomForest"
        
#         model_map = {
#             "RandomForest": self.rf_model,
#             "GradientBoosting": self.gb_model,
#             "LogisticRegression": self.lr_model,
#         }
#         self.best_model = model_map.get(self.best_model_name, self.rf_model)
#         print(f"✅ Models loaded. Best: {self.best_model_name}")
    
#     def predict(self, raw_data: dict) -> Tuple[str, float, dict, str]:
#         for col in RAW_INPUT_COLUMNS:
#             if col not in raw_data or raw_data[col] is None:
#                 raw_data[col] = RAW_DEFAULTS[col]
        
#         full_features = engineer_features(raw_data)
#         feature_vector = [full_features.get(col, 0) for col in self.feature_columns]
#         X = np.array(feature_vector).reshape(1, -1)
#         X_scaled = self.scaler.transform(X)
        
#         risk_prob = self.best_model.predict_proba(X_scaled)[0][1]
        
#         if risk_prob >= 0.7:
#             risk_level = "HIGH"
#         elif risk_prob >= 0.4:
#             risk_level = "MEDIUM"
#         else:
#             risk_level = "LOW"
        
#         risk_factors = self._identify_risk_factors(raw_data, full_features)
#         recommendations = self._generate_recommendations(risk_level, risk_factors)
        
#         return risk_level, risk_prob, risk_factors, recommendations
    
#     def _identify_risk_factors(self, raw: dict, eng: dict) -> dict:
#         factors = {}
        
#         if eng["grade_avg_all"] < 10:
#             factors["Low Academic Performance"] = f"Average: {eng['grade_avg_all']:.1f}/20"
#         if eng["consecutive_drop"]:
#             factors["Declining Grades"] = "Performance dropping over time"
#         if eng["grade_trend_23"] < -2:
#             factors["Recent Grade Drop"] = f"Dropped {abs(eng['grade_trend_23']):.1f} points recently"
#         if raw["absences"] > 25:
#             factors["Very High Absences"] = f"{raw['absences']} days"
#         elif raw["absences"] > 10:
#             factors["High Absences"] = f"{raw['absences']} days"
#         if raw["failures"] >= 2:
#             factors["Multiple Failures"] = f"{raw['failures']} failures"
#         elif raw["failures"] > 0:
#             factors["Previous Failure"] = "1 failure"
#         if raw["studytime"] < 2:
#             factors["Low Study Time"] = "<2 hours/week"
#         if raw["famrel"] <= 2:
#             factors["Poor Family Relations"] = "Low relationship quality"
#         if eng["financial_stress"]:
#             factors["Financial Stress"] = "Payment issues"
#         if not eng["has_any_support"]:
#             factors["Lack of Support"] = "No support systems"
        
#         return factors
    
#     def _generate_recommendations(self, risk_level: str, factors: dict) -> str:
#         recs = []
        
#         if risk_level == "HIGH":
#             recs.append("🚨 **URGENT INTERVENTION REQUIRED**\n")
#             recs.append("**Immediate Actions:**")
#             recs.append("1. Emergency meeting with student and parents")
#             recs.append("2. Develop Individual Education Plan")
#             recs.append("3. Refer to counselor and support services")
#             recs.append("4. Implement daily check-ins")
#         elif risk_level == "MEDIUM":
#             recs.append("⚠️ **TARGETED INTERVENTION RECOMMENDED**\n")
#             recs.append("**Actions:**")
#             recs.append("1. Weekly check-in meetings")
#             recs.append("2. Arrange tutoring or mentoring")
#             recs.append("3. Contact parents to discuss concerns")
#         else:
#             recs.append("✅ **STUDENT ON TRACK**\n")
#             recs.append("**Continue:**")
#             recs.append("1. Positive reinforcement")
#             recs.append("2. Regular monitoring")
        
#         if factors:
#             recs.append("\n**Specific Interventions:**")
#             if any("Academic" in k or "Declining" in k or "Drop" in k for k in factors):
#                 recs.append("• Academic: One-on-one tutoring")
#             if "Absences" in str(factors):
#                 recs.append("• Attendance: Investigate root causes")
#             if "Failure" in str(factors):
#                 recs.append("• Learning: Address knowledge gaps")
#             if "Study" in str(factors):
#                 recs.append("• Habits: Teach time management")
#             if "Family" in str(factors):
#                 recs.append("• Social: Family counseling")
#             if "Financial" in str(factors):
#                 recs.append("• Financial: Aid resources")
#             if "Support" in str(factors):
#                 recs.append("• Support: Mentoring program")
        
#         return "\n".join(recs)

# # Initialize
# try:
#     prediction_service = PredictionService("./models")
#     MODEL_LOADED = True
# except Exception as e:
#     print(f"⚠️ Models not loaded: {e}")
#     MODEL_LOADED = False
#     prediction_service = None

# # ============================================================================
# # GRADIO INTERFACE
# # ============================================================================

# def predict_student(
#     # Grades (current required, historical optional)
#     current_grade, has_previous, previous_grade, has_older, older_grade,
#     # Other inputs
#     course, attendance_type, prev_qual, mjob, fjob, special_needs,
#     debtor, tuition_paid, sex, scholarship, age,
#     famsize, pstatus, guardian, studytime, failures,
#     schoolsup, famsup, paid, activities, higher, internet,
#     famrel, health, absences
# ):
#     """Predict with flexible grade history."""
    
#     if not MODEL_LOADED:
#         return "⚠️ Model not loaded", 0.0, "Models unavailable", ""
    
#     # Handle grade inputs
#     prev_val = previous_grade if has_previous else None
#     older_val = older_grade if has_older else None
    
#     g1, g2, g3 = smart_grade_filling(current_grade, prev_val, older_val)
    
#     student_data = {
#         "Course": course, "Daytime/evening attendance": attendance_type,
#         "Previous qualification": prev_qual, "Mjob": mjob, "Fjob": fjob,
#         "Educational special needs": special_needs, "Debtor": debtor,
#         "Tuition fees up to date": tuition_paid, "sex": sex,
#         "Scholarship holder": scholarship, "age": age,
#         "G1": g1, "G2": g2, "G3": g3,
#         "famsize": famsize, "Pstatus": pstatus, "guardian": guardian,
#         "studytime": studytime, "failures": failures,
#         "schoolsup": schoolsup, "famsup": famsup, "paid": paid,
#         "activities": activities, "higher": higher, "internet": internet,
#         "famrel": famrel, "health": health, "absences": absences,
#     }
    
#     try:
#         risk_level, risk_score, risk_factors, recommendations = prediction_service.predict(student_data)
        
#         factors_text = "\n".join([f"• **{k}**: {v}" for k, v in risk_factors.items()]) if risk_factors else "No significant risk factors"
        
#         if risk_level == "HIGH":
#             risk_indicator = "🔴 HIGH RISK"
#         elif risk_level == "MEDIUM":
#             risk_indicator = "🟡 MEDIUM RISK"
#         else:
#             risk_indicator = "🟢 LOW RISK"
        
#         # Show what data was used
#         grade_info = f"\n\n**📊 Grade Data Used:**\n"
#         if has_previous and has_older:
#             grade_info += f"• Older Grade: {g1:.1f}\n• Previous Grade: {g2:.1f}\n• Current Grade: {g3:.1f}\n"
#             grade_info += "*Full trend analysis available*"
#         elif has_previous:
#             grade_info += f"• Previous Grade: {g2:.1f}\n• Current Grade: {g3:.1f}\n"
#             grade_info += "*Recent trend analysis available*"
#         else:
#             grade_info += f"• Current Grade Only: {g3:.1f}\n"
#             grade_info += "*Limited trend data - prediction based on current performance*"
        
#         return risk_indicator, round(risk_score * 100, 1), factors_text + grade_info, recommendations
    
#     except Exception as e:
#         return "⚠️ Error", 0.0, f"Error: {str(e)}", ""


# def toggle_previous_grade(has_previous):
#     return gr.update(visible=has_previous)

# def toggle_older_grade(has_older):
#     return gr.update(visible=has_older)

# # Sample data
# def load_current_only_sample():
#     """New student - only current semester data."""
#     return (12, False, 10, False, 10,
#             9500, 1, 1, 5, 5, 0, 0, 1, 1, 0, 18,
#             1, 1, 0, 2, 0, 1, 1, 1, 1, 1, 1, 4, 4, 5)

# def load_with_history_sample():
#     """Student with declining performance history."""
#     return (10, True, 13, True, 16,
#             9147, 1, 1, 4, 3, 0, 1, 0, 0, 0, 20,
#             1, 1, 0, 2, 1, 0, 0, 0, 0, 0, 1, 3, 3, 14)

# def load_high_risk_sample():
#     """High risk student."""
#     return (2, True, 5, True, 8,
#             9853, 0, 9, 1, 1, 1, 1, 0, 1, 0, 35,
#             0, 0, 2, 1, 3, 0, 0, 0, 0, 0, 0, 1, 1, 40)

# # ============================================================================
# # UI
# # ============================================================================

# with gr.Blocks(title="4See - Simple Semester Mode") as demo:
    
#     gr.Markdown("""
#     # 🎓 4See - Student Dropout Prediction (Simplified)
    
#     ### ✨ **Focus on Current Semester - Add History If Available**
    
#     **Perfect for teachers:** Enter current semester data, optionally add previous grades if you have them.
    
#     ---
#     """)
    
#     with gr.Row():
#         with gr.Column(scale=2):
            
#             # GRADES SECTION - Simplified!
#             with gr.Group():
#                 gr.Markdown("### 📚 **Academic Performance**")
                
#                 gr.Markdown("""
#                 **Current Semester (Required)** - Enter the student's most recent grade
#                 """)
                
#                 current_grade = gr.Slider(
#                     0, 20, value=12, step=0.5,
#                     label="📝 Current Semester Grade (0-20 scale)",
#                     info="Most recent grade - REQUIRED"
#                 )
                
#                 gr.Markdown("---")
#                 gr.Markdown("**📅 Historical Grades (Optional - Improves Accuracy)**")
                
#                 has_previous = gr.Checkbox(
#                     label="✓ I have data from the previous semester",
#                     value=False
#                 )
                
#                 previous_grade = gr.Slider(
#                     0, 20, value=10, step=0.5,
#                     label="Previous Semester Grade",
#                     visible=False,
#                     info="One semester before current"
#                 )
                
#                 has_older = gr.Checkbox(
#                     label="✓ I have data from an older semester",
#                     value=False
#                 )
                
#                 older_grade = gr.Slider(
#                     0, 20, value=10, step=0.5,
#                     label="Older Semester Grade",
#                     visible=False,
#                     info="Two semesters before current"
#                 )
                
#                 # Toggle visibility
#                 has_previous.change(
#                     fn=toggle_previous_grade,
#                     inputs=[has_previous],
#                     outputs=[previous_grade]
#                 )
                
#                 has_older.change(
#                     fn=toggle_older_grade,
#                     inputs=[has_older],
#                     outputs=[older_grade]
#                 )
                
#                 course = gr.Number(label="Course/Class Code", value=9500)
#                 failures = gr.Slider(0, 4, value=0, step=1, label="Past Failures")
#                 studytime = gr.Slider(1, 4, value=2, step=1, label="Study Time (1=<2h, 2=2-5h, 3=5-10h, 4=>10h)")

#                 mental_health = gr.Number(label="Mental Health Analysis Score", value=62)
                
#                 behaviour_assesment = gr.Number(label="Behaviour Analysis Score", value="36")

                
            
#             # Attendance
#             with gr.Group():
#                 gr.Markdown("### 🏫 **Attendance & Behavior**")
#                 absences = gr.Slider(0, 75, value=6, step=1, label="Absences This Semester")
#                 attendance_type = gr.Radio([0, 1], value=1, label="Class Type (0=Evening, 1=Daytime)")
        
#         with gr.Column(scale=1):
            
#             # Demographics
#             with gr.Group():
#                 gr.Markdown("### 👤 **Student Information**")
#                 age = gr.Slider(15, 70, value=18, step=1, label="Age")
#                 sex = gr.Radio([0, 1], value=1, label="Sex (0=F, 1=M)")
#                 prev_qual = gr.Number(label="Previous Qualification", value=1)
#                 special_needs = gr.Radio([0, 1], value=0, label="Special Needs?")
            
#             # Family
#             with gr.Group():
#                 gr.Markdown("### 👨‍👩‍👧 **Family**")
#                 mjob = gr.Slider(1, 10, value=5, step=1, label="Mother's Job (1-10)")
#                 fjob = gr.Slider(1, 10, value=5, step=1, label="Father's Job (1-10)")
#                 famrel = gr.Slider(1, 5, value=4, step=1, label="Family Relations (1-5)")
#                 famsize = gr.Radio([0, 1], value=1, label="Size (0=≤3, 1=>3)")
#                 pstatus = gr.Radio([0, 1], value=1, label="Parents (0=Apart, 1=Together)")
#                 guardian = gr.Radio([0, 1, 2], value=0, label="Guardian (0=Mom, 1=Dad, 2=Other)")
#                 health = gr.Slider(1, 5, value=4, step=1, label="Health (1-5)")
            
#             # Support
#             with gr.Group():
#                 gr.Markdown("### 💰 **Financial & Support**")
#                 debtor = gr.Radio([0, 1], value=0, label="Debtor?")
#                 tuition_paid = gr.Radio([0, 1], value=1, label="Tuition Paid?")
#                 scholarship = gr.Radio([0, 1], value=0, label="Scholarship?")
#                 schoolsup = gr.Radio([0, 1], value=1, label="School Support?")
#                 famsup = gr.Radio([0, 1], value=0, label="Family Support?")
#                 paid = gr.Radio([0, 1], value=1, label="Extra Classes?")
#                 activities = gr.Radio([0, 1], value=1, label="Activities?")
#                 higher = gr.Radio([0, 1], value=0, label="Wants Higher Ed?")
#                 internet = gr.Radio([0, 1], value=0, label="Internet?")
    
#     with gr.Row():
#         predict_btn = gr.Button("🔍 Analyze Student Risk", variant="primary", size="lg")
    
#     with gr.Row():
#         gr.Markdown("### 📝 **Load Sample Data:**")
#         sample1_btn = gr.Button("📖 Current Semester Only (New Student)", size="sm")
#         sample2_btn = gr.Button("📊 With Performance History (Declining)", size="sm")
#         sample3_btn = gr.Button("🚨 High Risk Student", size="sm")
    
#     gr.Markdown("---")
    
#     with gr.Row():
#         risk_output = gr.Textbox(label="Risk Level", interactive=False)
#         score_output = gr.Number(label="Risk Score (%)", interactive=False)
    
#     factors_output = gr.Markdown(label="Risk Factors & Data Used")
#     recommendations_output = gr.Markdown(label="Intervention Recommendations")
    
#     # All inputs
#     all_inputs = [
#         current_grade, has_previous, previous_grade, has_older, older_grade,
#         course, attendance_type, prev_qual, mjob, fjob, special_needs,
#         debtor, tuition_paid, sex, scholarship, age,
#         famsize, pstatus, guardian, studytime, failures,
#         schoolsup, famsup, paid, activities, higher, internet,
#         famrel, health, absences
#     ]
    
#     # Connect
#     predict_btn.click(
#         fn=predict_student,
#         inputs=all_inputs,
#         outputs=[risk_output, score_output, factors_output, recommendations_output]
#     )
    
#     sample1_btn.click(fn=load_current_only_sample, outputs=all_inputs)
#     sample2_btn.click(fn=load_with_history_sample, outputs=all_inputs)
#     sample3_btn.click(fn=load_high_risk_sample, outputs=all_inputs)
    
#     gr.Markdown("""
#     ---
#     ### 💡 **How It Works**
    
#     **Minimum Required:** Just current semester grade + attendance/behavior
    
#     **Optional But Better:** Add previous semester data if available
    
#     **Best:** Include older semester data for full trend analysis
    
#     The model intelligently handles whatever data you provide!
    
#     ---
#     <center>© 2025 Team 404 Rescued | K.J. Somaiya Polytechnic</center>
#     """)

# if __name__ == "__main__":
#     demo.launch(server_name="0.0.0.0", server_port=7860, share=False)