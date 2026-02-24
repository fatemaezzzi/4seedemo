"""
ADVANCED OPTIMIZATION & TUNING — 4SEE PIPELINE
================================================
Synchronized with train_model_two.py feature engineering.

Capabilities:
  1. Hyperparameter Tuning (RandomizedSearchCV) for RF and GB.
  2. Ensemble Learning (VotingClassifier, StackingClassifier).
  3. Saves the "Best of the Best" model for final deployment.
"""

import pandas as pd
import numpy as np
import os
import joblib
import warnings
from pathlib import Path
from time import time

from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import (
    train_test_split, cross_val_score, StratifiedKFold, RandomizedSearchCV
)
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier, 
    VotingClassifier, StackingClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import f1_score, classification_report

try:
    from imblearn.over_sampling import SMOTE
    _HAS_SMOTE = True
except ImportError:
    from sklearn.utils import resample as _resample
    _HAS_SMOTE = False

warnings.filterwarnings('ignore')


# ============================================================================
# 1. CONFIGURATION (MUST MATCH train_model_two.py)
# ============================================================================

class Config:
    DATA_DIR      = './data'
    MODEL_DIR     = './models_tuned'  # Saving to a separate folder
    RANDOM_STATE  = 42
    TEST_SIZE     = 0.2
    CV_FOLDS      = 5
    EXCLUDE_FEATURES = []

    # Priority weights (for engineering)
    W = {
        'G1': 0.18, 'G2': 0.18, 'G3': 0.18,
        'absences':  0.12, 'failures':  0.07, 'studytime': 0.05,
        'famrel':    0.03, 'health':    0.03, 'static_pool': 0.05,
    }

    RANGES = {
        'G1': (0, 20), 'G2': (0, 20), 'G3': (0, 20),
        'absences': (0, 75), 'failures': (0, 4),
        'studytime': (1, 4), 'famrel': (1, 5), 'health': (1, 5), 'age': (15, 70),
    }

    # ── HYPERPARAMETER GRIDS ─────────────────────────────────────────────
    # Ranges for RandomizedSearchCV to explore
    
    RF_GRID = {
        'n_estimators': [200, 300, 500],
        'max_depth': [10, 20, 30, None],
        'min_samples_split': [5, 10, 15],
        'min_samples_leaf': [2, 4, 8],
        'max_features': ['sqrt', 'log2'],
        'class_weight': ['balanced', 'balanced_subsample'],
        'bootstrap': [True]
    }

    GB_GRID = {
        'n_estimators': [100, 200, 300],
        'learning_rate': [0.01, 0.05, 0.1],
        'max_depth': [3, 5, 8],
        'min_samples_split': [5, 10],
        'min_samples_leaf': [2, 4],
        'subsample': [0.8, 0.9, 1.0]
    }


# ============================================================================
# 2. FEATURE ENGINEERING (EXACT COPY OF train_model_two.py)
# ============================================================================

def _norm(series, lo, hi):
    return ((series - lo) / (hi - lo)).clip(0, 1)

def engineer_features(df):
    """
    Recreates the exact 58 features from the training pipeline.
    """
    d = df.copy()
    
    # Tier A
    d['grade_trend_12'] = d['G2'] - d['G1']
    d['grade_trend_23'] = d['G3'] - d['G2']
    d['grade_trend_13'] = d['G3'] - d['G1']
    d['grade_avg_all'] = (d['G1'] + d['G2'] + d['G3']) / 3
    d['grade_avg_12']  = (d['G1'] + d['G2']) / 2
    d['grade_min']   = d[['G1', 'G2', 'G3']].min(axis=1)
    d['grade_max']   = d[['G1', 'G2', 'G3']].max(axis=1)
    d['grade_range'] = d['grade_max'] - d['grade_min']
    d['drop_12']         = (d['G2'] < d['G1']).astype(int)
    d['drop_23']         = (d['G3'] < d['G2']).astype(int)
    d['consecutive_drop'] = (d['drop_12'] & d['drop_23']).astype(int)
    LOW = 8
    d['g1_low']         = (d['G1'] < LOW).astype(int)
    d['g2_low']         = (d['G2'] < LOW).astype(int)
    d['g3_low']         = (d['G3'] < LOW).astype(int)
    d['all_grades_low'] = (d['g1_low'] & d['g2_low'] & d['g3_low']).astype(int)
    d['any_grade_zero'] = ((d['G1'] == 0) | (d['G2'] == 0) | (d['G3'] == 0)).astype(int)
    d['absence_high']      = (d['absences'] > 10).astype(int)
    d['absence_very_high'] = (d['absences'] > 25).astype(int)
    d['absence_x_grade'] = d['absences'] * (20 - d['grade_avg_all'])

    # Tier B
    d['has_failures']      = (d['failures'] > 0).astype(int)
    d['multiple_failures'] = (d['failures'] >= 2).astype(int)
    d['low_study']         = (d['studytime'] < 2).astype(int)
    d['failures_x_grade']  = d['failures'] * (20 - d['grade_avg_all'])
    d['study_effectiveness'] = d['studytime'] * d['grade_avg_all']
    d['social_health'] = d['famrel'] + d['health']
    d['social_academic_risk'] = ((d['famrel'] <= 2) & (d['grade_avg_all'] < 10)).astype(int)

    # Tier C
    d['financial_stress'] = ((d['Debtor'] == 1) | (d['Tuition fees up to date'] == 0)).astype(int)
    d['has_any_support'] = ((d['Scholarship holder'] == 1) | (d['schoolsup'] == 1) | (d['famsup'] == 1)).astype(int)
    d['parent_occupation_sum'] = d['Mjob'] + d['Fjob']

    # Tier D (Weighted Risk Score)
    R, W = Config.RANGES, Config.W
    g1_risk      = 1 - _norm(d['G1'],        *R['G1'])
    g2_risk      = 1 - _norm(d['G2'],        *R['G2'])
    g3_risk      = 1 - _norm(d['G3'],        *R['G3'])
    abs_risk     =     _norm(d['absences'],  *R['absences'])
    fail_risk    =     _norm(d['failures'],  *R['failures'])
    study_risk   = 1 - _norm(d['studytime'], *R['studytime'])
    famrel_risk  = 1 - _norm(d['famrel'],    *R['famrel'])
    health_risk  = 1 - _norm(d['health'],    *R['health'])
    
    static_cols_risk = (
        _norm(d['Debtor'], 0, 1) + (1 - _norm(d['Tuition fees up to date'], 0, 1)) +
        (1 - _norm(d['Scholarship holder'], 0, 1)) + _norm(d['Educational special needs'], 0, 1) +
        (1 - _norm(d['schoolsup'], 0, 1)) + (1 - _norm(d['famsup'], 0, 1)) +
        (1 - _norm(d['paid'], 0, 1)) + (1 - _norm(d['activities'], 0, 1)) +
        (1 - _norm(d['higher'], 0, 1)) + (1 - _norm(d['internet'], 0, 1)) +
        _norm(d['age'], *R['age'])
    ) / 11

    d['weighted_risk_score'] = (
        g1_risk * W['G1'] + g2_risk * W['G2'] + g3_risk * W['G3'] +
        abs_risk * W['absences'] + fail_risk * W['failures'] +
        study_risk * W['studytime'] + famrel_risk * W['famrel'] +
        health_risk * W['health'] + static_cols_risk * W['static_pool']
    )

    return d

def load_and_prep_data():
    """Standard Loading & Preprocessing wrapper"""
    print("  Loading data...")
    # Find CSV
    csv_files = list(Path(Config.DATA_DIR).rglob('*.csv'))
    df = None
    for f in csv_files:
        try:
            temp = pd.read_csv(f, sep=None, engine='python')
            if 'Target' in temp.columns and 'G1' in temp.columns:
                df = temp; break
        except: continue
    
    if df is None: raise FileNotFoundError("Dataset not found")

    # Target
    df['target'] = df['Target'].astype(int)
    df = df.drop(columns=['Target'])

    # Engineer
    df = engineer_features(df)
    
    # Select Features
    drop_cols = {'target'} | set(Config.EXCLUDE_FEATURES)
    features = [c for c in df.columns if c not in drop_cols]
    
    # Preprocessing
    work = df[features + ['target']].copy()
    
    # Nulls & Encoding
    for c in work.select_dtypes(include=[np.number]).columns:
        work[c].fillna(work[c].median(), inplace=True)
    
    label_encoders = {}
    for c in work.select_dtypes(include=['object']).columns:
        work[c].fillna(work[c].mode()[0], inplace=True)
        le = LabelEncoder()
        work[c] = le.fit_transform(work[c].astype(str))
        label_encoders[c] = le

    # Split & Scale
    X = work.drop(columns=['target'])
    y = work['target']
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=Config.TEST_SIZE, stratify=y, random_state=Config.RANDOM_STATE
    )

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s  = scaler.transform(X_test)

    # SMOTE
    if _HAS_SMOTE:
        smote = SMOTE(random_state=Config.RANDOM_STATE)
        X_train_s, y_train = smote.fit_resample(X_train_s, y_train)
        print(f"  SMOTE applied. Train shape: {X_train_s.shape}")

    return X_train_s, X_test_s, y_train, y_test, scaler, label_encoders, features


# ============================================================================
# 3. ADVANCED OPTIMIZATION LOGIC
# ============================================================================

def tune_model(model, param_grid, X_train, y_train, name):
    """Runs RandomizedSearchCV to find best params"""
    print(f"\n⚡ Tuning {name}...")
    start = time()
    
    search = RandomizedSearchCV(
        model, param_grid, 
        n_iter=15,  # Try 15 random combinations
        scoring='f1', 
        cv=3, 
        n_jobs=-1, 
        random_state=Config.RANDOM_STATE,
        verbose=1
    )
    search.fit(X_train, y_train)
    
    print(f"  Best F1: {search.best_score_:.4f}")
    print(f"  Time: {time() - start:.1f}s")
    return search.best_estimator_

def main():
    print("\n" + "=" * 60)
    print(" 🚀 4SEE ADVANCED OPTIMIZATION ")
    print("=" * 60)
    
    # 1. Load Data
    X_train, X_test, y_train, y_test, scaler, le, feats = load_and_prep_data()
    
    os.makedirs(Config.MODEL_DIR, exist_ok=True)
    
    # 2. Tune Random Forest
    rf_base = RandomForestClassifier(random_state=Config.RANDOM_STATE)
    best_rf = tune_model(rf_base, Config.RF_GRID, X_train, y_train, "Random Forest")
    
    # 3. Tune Gradient Boosting
    gb_base = GradientBoostingClassifier(random_state=Config.RANDOM_STATE)
    best_gb = tune_model(gb_base, Config.GB_GRID, X_train, y_train, "Gradient Boosting")
    
    # 4. Create Ensembles
    print(f"\n🤝 Building Ensembles...")
    
    # Voting Classifier (Soft)
    voting_clf = VotingClassifier(
        estimators=[
            ('rf', best_rf),
            ('gb', best_gb),
            ('lr', LogisticRegression(class_weight='balanced', max_iter=2000))
        ],
        voting='soft', n_jobs=-1
    )
    voting_clf.fit(X_train, y_train)
    
    # Stacking Classifier (Meta-learner)
    stacking_clf = StackingClassifier(
        estimators=[
            ('rf', best_rf),
            ('gb', best_gb)
        ],
        final_estimator=LogisticRegression(),
        cv=3, n_jobs=-1
    )
    stacking_clf.fit(X_train, y_train)

    # 5. Final Evaluation & Selection
    models = {
        'Tuned_RandomForest': best_rf,
        'Tuned_GradientBoosting': best_gb,
        'VotingEnsemble': voting_clf,
        'StackingEnsemble': stacking_clf
    }
    
    print("\n" + "=" * 60)
    print(" 🏆 FINAL RESULTS (Test Set)")
    print("=" * 60)
    
    best_score = 0
    best_model_name = ""
    best_model_obj = None

    for name, model in models.items():
        y_pred = model.predict(X_test)
        f1 = f1_score(y_test, y_pred)
        print(f"  {name:<25} F1: {f1:.4f}")
        
        if f1 > best_score:
            best_score = f1
            best_model_name = name
            best_model_obj = model
            
    print("\n" + "=" * 60)
    print(f" WINNER: {best_model_name} (F1 = {best_score:.4f})")
    print("=" * 60)
    
    # 6. Save Artifacts (Compatible with evaluate_model.py)
    # Note: We save to 'models_tuned' to avoid overwriting base models
    joblib.dump(best_model_obj, os.path.join(Config.MODEL_DIR, f"{best_model_name.lower()}_model.pkl"))
    joblib.dump(scaler, os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(feats,  os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    joblib.dump(le,     os.path.join(Config.MODEL_DIR, 'label_encoders.pkl'))
    
    print(f"\n✅ Optimized model saved to: {Config.MODEL_DIR}/{best_model_name.lower()}_model.pkl")
    print("   You can now run: python evaluate_model_fixed.py --model ./models_tuned/your_model_name.pkl")

if __name__ == "__main__":
    main()