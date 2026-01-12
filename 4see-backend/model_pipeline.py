import pandas as pd
import numpy as np
import os
import joblib
import warnings
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score

warnings.filterwarnings('ignore')

# ==========================================
# CONFIGURATION
# ==========================================
DATA_DIR = './data'
MODEL_DIR = './models'
os.makedirs(MODEL_DIR, exist_ok=True)

# ✅ ALL 19 FEATURES
FEATURE_COLUMNS = [
    'absences', 'G1', 'G2', 'G3', 'failures', 'age',
    'Medu', 'Fedu', 'famsize', 'Pstatus', 'famsup',
    'studytime', 'goout', 'Dalc', 'Walc', 'health',
    'school', 'address', 'internet'
]

# ==========================================
# 1. SOPHISTICATED RISK LOGIC
# ==========================================
def calculate_comprehensive_risk(row):
    """
    AGGRESSIVE Logic: Quickly flags students as high risk.
    Returns 1 (Dropout) if score >= 0.5, else 0.
    """
    risk_points = 0.0
    
    # --- A. ACADEMIC (The "Kill Switch") ---
    # If grades are extremely low, immediate high risk.
    if row['G3'] < 8: 
        risk_points += 0.6  # HUGE PENALTY (Immediate Dropout Territory)
    elif row['G3'] < 10: 
        risk_points += 0.35
    
    # Failures: Cap at 3 for calculation logic, but penalize heavily
    fails = min(row['failures'], 3)
    if fails > 0: 
        risk_points += (fails * 0.15)  # +0.15 per failure (was 0.05)
    
    # --- B. BEHAVIOR ---
    # Absences: Harsh penalty for chronic absenteeism
    if row['absences'] > 20: 
        risk_points += 0.4  # (was 0.15)
    elif row['absences'] > 10: 
        risk_points += 0.2
    
    # --- C. SUPPORT & HEALTH ---
    if row.get('famsup', 'yes') == 'no': risk_points += 0.1
    if row['studytime'] < 2: risk_points += 0.1
    
    # --- FINAL THRESHOLD ---
    # Lowered threshold slightly to catch more students
    return 1 if risk_points >= 0.5 else 0

# ==========================================
# 2. DATA PIPELINE
# ==========================================
def run_pipeline():
    print("🚀 Starting 19-Feature Training Pipeline...")
    
    # 1. Load Data (Merge all CSVs)
    dataframes = []
    for root, _, files in os.walk(DATA_DIR):
        for file in files:
            if file.endswith('.csv'):
                try:
                    path = os.path.join(root, file)
                    # Attempt load
                    df_temp = pd.read_csv(path, sep=None, engine='python')
                    
                    # Ensure G3 exists
                    if 'G3' in df_temp.columns:
                        # Ensure all 19 columns exist (fill missing with defaults)
                        for col in FEATURE_COLUMNS:
                            if col not in df_temp.columns:
                                df_temp[col] = 0 # Default padding
                        
                        dataframes.append(df_temp)
                        print(f"  ✅ Loaded: {file}")
                except:
                    pass
    
    if not dataframes:
        print("❌ No data found in ./data folder.")
        return

    full_df = pd.concat(dataframes, ignore_index=True)
    
    # 2. Apply Target Logic
    print("⚖️  Applying Weighted Risk Logic...")
    full_df['target'] = full_df.apply(calculate_comprehensive_risk, axis=1)
    
    print(f"  📊 Distribution: {sum(full_df['target']==0)} Continue vs {sum(full_df['target']==1)} Dropout")

    # 3. Preprocessing
    X = full_df[FEATURE_COLUMNS].copy()
    y = full_df['target']

    # Encode Strings (yes/no, GP/MS) to numbers
    le = LabelEncoder()
    for col in X.select_dtypes(include='object').columns:
        X[col] = le.fit_transform(X[col].astype(str))

    # Split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # 4. Train Model
    print("🧠 Training Random Forest...")
    model = RandomForestClassifier(n_estimators=200, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"✅ Training Complete. Accuracy: {acc:.2%}")

    # 5. Save Artifacts
    joblib.dump(model, os.path.join(MODEL_DIR, 'randomforest_model.pkl'))
    joblib.dump(FEATURE_COLUMNS, os.path.join(MODEL_DIR, 'feature_columns.pkl'))
    # Save a dummy scaler if needed by legacy code, or fit a real one
    scaler = StandardScaler().fit(X_train)
    joblib.dump(scaler, os.path.join(MODEL_DIR, 'scaler.pkl'))
    
    print("💾 Models saved successfully.")

if __name__ == "__main__":
    run_pipeline()