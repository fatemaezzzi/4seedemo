"""
MODEL EVALUATION SCRIPT - FIXED FOR TRAIN_MODEL_TWO.PY
========================================================

Shows comprehensive accuracy metrics for any saved model.
Now properly synchronized with train_model_two.py feature engineering.

Usage:
    python evaluate_model_fixed.py                    # Evaluate current best model
    python evaluate_model_fixed.py --model ./models/randomforest_model.pkl
    python evaluate_model_fixed.py --all              # Compare all models
"""

import pandas as pd
import numpy as np
import joblib
import os
import sys
from pathlib import Path

from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, classification_report, confusion_matrix
)
from sklearn.model_selection import train_test_split


# ============================================================================
# CONFIGURATION (matches train_model_two.py)
# ============================================================================

class Config:
    DATA_DIR = './data'
    MODEL_DIR = './models'
    MODEL_DIRS = ['./models', './models_tuned', './models_advanced']
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 5
    
    EXCLUDE_FEATURES = []
    
    # Same weights as train_model_two.py
    W = {
        'G1': 0.18, 'G2': 0.18, 'G3': 0.18,
        'absences':  0.12,
        'failures':  0.07,
        'studytime': 0.05,
        'famrel':    0.03,
        'health':    0.03,
        'static_pool': 0.05,
    }
    
    RANGES = {
        'G1':        (0, 20),
        'G2':        (0, 20),
        'G3':        (0, 20),
        'absences':  (0, 75),
        'failures':  (0, 4),
        'studytime': (1, 4),
        'famrel':    (1, 5),
        'health':    (1, 5),
        'age':       (15, 70),
    }


# ============================================================================
# DATA LOADING (replicated from train_model_two.py)
# ============================================================================

def find_and_load_data(data_dir):
    """Find and load the dataset"""
    csv_files = list(Path(data_dir).rglob('*.csv'))
    
    for filepath in csv_files:
        for sep in [',', ';', '\t']:
            try:
                df = pd.read_csv(filepath, sep=sep)
                if 'Target' in df.columns and 'G1' in df.columns and 'G3' in df.columns:
                    print(f"✅ Loaded: {filepath.name}")
                    print(f"   Shape: {df.shape[0]} rows × {df.shape[1]} columns")
                    return df
            except Exception:
                continue
    
    raise FileNotFoundError("No suitable CSV with Target / G1 / G3 found.")


def create_target_variable(df):
    """Create target from pre-labeled Target column"""
    if 'Target' not in df.columns:
        raise ValueError("'Target' column missing from dataset.")
    
    df['target'] = df['Target'].astype(int)
    df = df.drop(columns=['Target'])
    return df


def _norm(val, lo, hi):
    """Normalize a single value to [0, 1]"""
    return max(0.0, min(1.0, (val - lo) / (hi - lo)))


def engineer_features(df):
    """
    Feature engineering - EXACT copy from train_model_two.py
    Creates all 58 features from 28 raw columns
    """
    d = df.copy()
    
    G1, G2, G3 = d['G1'], d['G2'], d['G3']
    
    # ── Tier A: HIGH priority (grades + attendance) ──────────────────────
    d['grade_trend_12'] = G2 - G1
    d['grade_trend_23'] = G3 - G2
    d['grade_trend_13'] = G3 - G1
    
    d['grade_avg_all'] = (G1 + G2 + G3) / 3.0
    d['grade_avg_12']  = (G1 + G2) / 2.0
    
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
    d['absence_x_grade']   = d['absences'] * (20 - d['grade_avg_all'])
    
    # ── Tier B: MEDIUM priority (behavioral / social) ─────────────────────
    d['has_failures']      = (d['failures'] > 0).astype(int)
    d['multiple_failures'] = (d['failures'] >= 2).astype(int)
    d['low_study']         = (d['studytime'] < 2).astype(int)
    
    d['failures_x_grade']    = d['failures'] * (20 - d['grade_avg_all'])
    d['study_effectiveness'] = d['studytime'] * d['grade_avg_all']
    d['social_health']       = d['famrel'] + d['health']
    d['social_academic_risk'] = ((d['famrel'] <= 2) & (d['grade_avg_all'] < 10)).astype(int)
    
    # ── Tier C: LOW priority composites ───────────────────────────────────
    d['financial_stress']      = ((d['Debtor'] == 1) | (d['Tuition fees up to date'] == 0)).astype(int)
    d['has_any_support']       = ((d['Scholarship holder'] == 1) | (d['schoolsup'] == 1) | (d['famsup'] == 1)).astype(int)
    d['parent_occupation_sum'] = d['Mjob'] + d['Fjob']
    
    # ── Tier D: weighted_risk_score ───────────────────────────────────────
    R = Config.RANGES
    W = Config.W
    
    def norm_series(series, lo, hi):
        return ((series - lo) / (hi - lo)).clip(0, 1)
    
    g1_risk     = 1 - norm_series(d['G1'],        *R['G1'])
    g2_risk     = 1 - norm_series(d['G2'],        *R['G2'])
    g3_risk     = 1 - norm_series(d['G3'],        *R['G3'])
    abs_risk    =     norm_series(d['absences'],  *R['absences'])
    fail_risk   =     norm_series(d['failures'],  *R['failures'])
    study_risk  = 1 - norm_series(d['studytime'], *R['studytime'])
    famrel_risk = 1 - norm_series(d['famrel'],    *R['famrel'])
    health_risk = 1 - norm_series(d['health'],    *R['health'])
    
    static_cols_risk = (
        norm_series(d['Debtor'],                         0, 1) +
        (1 - norm_series(d['Tuition fees up to date'],   0, 1)) +
        (1 - norm_series(d['Scholarship holder'],        0, 1)) +
        norm_series(d['Educational special needs'],      0, 1) +
        (1 - norm_series(d['schoolsup'],                 0, 1)) +
        (1 - norm_series(d['famsup'],                    0, 1)) +
        (1 - norm_series(d['paid'],                      0, 1)) +
        (1 - norm_series(d['activities'],                0, 1)) +
        (1 - norm_series(d['higher'],                    0, 1)) +
        (1 - norm_series(d['internet'],                  0, 1)) +
        norm_series(d['age'],                            *R['age'])
    ) / 11
    
    d['weighted_risk_score'] = (
        g1_risk     * W['G1']        +
        g2_risk     * W['G2']        +
        g3_risk     * W['G3']        +
        abs_risk    * W['absences']  +
        fail_risk   * W['failures']  +
        study_risk  * W['studytime'] +
        famrel_risk * W['famrel']    +
        health_risk * W['health']    +
        static_cols_risk * W['static_pool']
    )
    
    return d


def select_features(df, exclude_list):
    """Return all columns except 'target' and anything in exclude_list"""
    drop = {'target'} | set(exclude_list)
    features = [c for c in df.columns if c not in drop]
    return features


# ============================================================================
# LOAD TEST DATA
# ============================================================================

def load_test_data():
    """Load and prepare test data using exact train_model_two.py logic"""
    print("\n" + "="*80)
    print(" LOADING TEST DATA")
    print("="*80)
    
    # Load and prepare data
    df = find_and_load_data(Config.DATA_DIR)
    df = create_target_variable(df)
    df = engineer_features(df)
    features = select_features(df, Config.EXCLUDE_FEATURES)
    
    # Split (same random state as training)
    X = df[features]
    y = df['target']
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=Config.TEST_SIZE,
        random_state=Config.RANDOM_STATE, stratify=y
    )
    
    print(f"\n✅ Data loaded:")
    print(f"   Train: {len(X_train):,} samples")
    print(f"   Test:  {len(X_test):,} samples")
    print(f"   Features: {len(features)}")
    print(f"   Dropout rate: {y_test.mean()*100:.1f}%")
    
    return X_train, X_test, y_train, y_test, features


# ============================================================================
# EVALUATE SINGLE MODEL
# ============================================================================

def evaluate_model(model_path, X_test, y_test, show_details=True):
    """Evaluate a single model and show all metrics"""
    
    if not os.path.exists(model_path):
        print(f"\n❌ Model not found: {model_path}")
        return None
    
    print("\n" + "="*80)
    print(f" EVALUATING: {os.path.basename(model_path)}")
    print("="*80)
    
    try:
        # Load model, scaler, features
        model_dir = os.path.dirname(model_path)
        
        model = joblib.load(model_path)
        print(f"✅ Loaded model: {type(model).__name__}")
        
        # Load scaler
        scaler_path = os.path.join(model_dir, 'scaler.pkl')
        if os.path.exists(scaler_path):
            scaler = joblib.load(scaler_path)
            print(f"✅ Loaded scaler")
        else:
            scaler = None
            print(f"⚠️  No scaler found")
        
        # Load feature columns
        features_path = os.path.join(model_dir, 'feature_columns.pkl')
        if os.path.exists(features_path):
            feature_cols = joblib.load(features_path)
            print(f"✅ Loaded {len(feature_cols)} feature names")
            
            # Ensure X_test has same features in same order
            X_test_aligned = X_test[feature_cols]
        else:
            print(f"⚠️  No feature_columns.pkl found, using all features")
            X_test_aligned = X_test
        
        # Scale if scaler exists
        if scaler is not None:
            X_test_scaled = scaler.transform(X_test_aligned)
        else:
            X_test_scaled = X_test_aligned
        
        # Make predictions
        y_pred = model.predict(X_test_scaled)
        
        # Get probabilities if available
        if hasattr(model, 'predict_proba'):
            y_prob = model.predict_proba(X_test_scaled)[:, 1]
            has_proba = True
        else:
            y_prob = None
            has_proba = False
        
        # Calculate metrics
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, zero_division=0)
        recall = recall_score(y_test, y_pred, zero_division=0)
        f1 = f1_score(y_test, y_pred, zero_division=0)
        
        if has_proba:
            roc_auc = roc_auc_score(y_test, y_prob)
        else:
            roc_auc = None
        
        # Display results
        print("\n" + "─"*80)
        print(" PERFORMANCE METRICS")
        print("─"*80)
        
        print(f"\n  📊 Overall Performance:")
        print(f"     Accuracy:   {accuracy*100:6.2f}%")
        print(f"     Precision:  {precision*100:6.2f}%")
        print(f"     Recall:     {recall*100:6.2f}%")
        print(f"     F1-Score:   {f1*100:6.2f}%")
        if roc_auc is not None:
            print(f"     ROC-AUC:    {roc_auc*100:6.2f}%")
        
        # Confusion Matrix
        cm = confusion_matrix(y_test, y_pred)
        total = cm.sum()
        
        print(f"\n  📋 Confusion Matrix:")
        print(f"                    Predicted")
        print(f"                Graduate    Dropout")
        print(f"     Actual  ┌─────────────────────┐")
        print(f"     Graduate│ {cm[0,0]:7,}    {cm[0,1]:7,} │")
        print(f"     Dropout │ {cm[1,0]:7,}    {cm[1,1]:7,} │")
        print(f"             └─────────────────────┘")
        
        # Error analysis
        total_graduates = (y_test == 0).sum()
        total_dropouts = (y_test == 1).sum()
        correctly_identified = cm[1,1]
        missed_dropouts = cm[1,0]
        false_alarms = cm[0,1]
        
        print(f"\n  ⚠️  Error Breakdown:")
        print(f"     True Negatives (Correct Graduates):  {cm[0,0]:4,} / {total_graduates:4,} ({cm[0,0]/total_graduates*100:5.1f}%)")
        print(f"     True Positives (Caught Dropouts):    {correctly_identified:4,} / {total_dropouts:4,} ({correctly_identified/total_dropouts*100:5.1f}%)")
        print(f"     False Positives (False Alarms):      {false_alarms:4,} / {total_graduates:4,} ({false_alarms/total_graduates*100:5.1f}%)")
        print(f"     False Negatives (Missed Dropouts):   {missed_dropouts:4,} / {total_dropouts:4,} ({missed_dropouts/total_dropouts*100:5.1f}%)")
        
        # Real-world impact
        print(f"\n  🎯 Real-World Impact (if 1,000 at-risk students):")
        if total_dropouts > 0:
            catch_rate = correctly_identified / total_dropouts
            students_caught = int(1000 * catch_rate)
            students_missed = 1000 - students_caught
            print(f"     Would identify:  {students_caught:3,} students ({catch_rate*100:.1f}%)")
            print(f"     Would miss:      {students_missed:3,} students ({(1-catch_rate)*100:.1f}%)")
            
            # Cost analysis
            cost_per_dropout = 200000  # ₹2 lakh
            saved_value = students_caught * cost_per_dropout
            lost_value = students_missed * cost_per_dropout
            print(f"\n  💰 Economic Impact:")
            print(f"     Prevented dropout cost: ₹{saved_value:,} ({students_caught} × ₹2L)")
            print(f"     Missed opportunity:     ₹{lost_value:,} ({students_missed} × ₹2L)")
        
        # Additional details
        if show_details and roc_auc is not None:
            print(f"\n  📈 Probability Distribution:")
            dropout_probs = y_prob[y_test==1]
            graduate_probs = y_prob[y_test==0]
            print(f"     Dropouts (avg prediction):   {dropout_probs.mean():.3f}")
            print(f"     Graduates (avg prediction):  {graduate_probs.mean():.3f}")
            print(f"     Separation (ideal > 0.3):    {dropout_probs.mean() - graduate_probs.mean():.3f}")
            
            # Check confidence
            confident_correct = ((y_prob > 0.7) & (y_test == 1)).sum() + \
                               ((y_prob < 0.3) & (y_test == 0)).sum()
            confident_wrong = ((y_prob > 0.7) & (y_test == 0)).sum() + \
                             ((y_prob < 0.3) & (y_test == 1)).sum()
            
            print(f"\n  🎯 Confidence Analysis (threshold 0.7/0.3):")
            print(f"     High-confidence correct: {confident_correct:4,}")
            print(f"     High-confidence wrong:   {confident_wrong:4,}")
            
            if confident_wrong > 0:
                print(f"     Confidence accuracy:     {confident_correct/(confident_correct+confident_wrong)*100:.1f}%")
        
        # Feature importance if available
        if hasattr(model, 'feature_importances_') and show_details:
            importances = model.feature_importances_
            feature_cols = joblib.load(features_path)
            
            # Get top 10
            indices = np.argsort(importances)[::-1][:10]
            
            print(f"\n  🔝 Top 10 Most Important Features:")
            print(f"     {'#':>3}  {'Feature':<30} {'Importance':>10}")
            print(f"     {'─'*3}  {'─'*30} {'─'*10}")
            for rank, idx in enumerate(indices, 1):
                bar = '█' * int(importances[idx] * 200)
                print(f"     {rank:>3}  {feature_cols[idx]:<30} {importances[idx]:>10.4f}")
        
        # Return metrics dict
        return {
            'model_path': model_path,
            'model_name': os.path.basename(model_path).replace('_model.pkl', ''),
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'roc_auc': roc_auc,
            'confusion_matrix': cm,
            'total_dropouts': int(total_dropouts),
            'caught_dropouts': int(correctly_identified),
            'missed_dropouts': int(missed_dropouts),
            'false_alarms': int(false_alarms)
        }
        
    except Exception as e:
        print(f"\n❌ Error evaluating model: {e}")
        import traceback
        traceback.print_exc()
        return None


# ============================================================================
# COMPARE ALL MODELS
# ============================================================================

def compare_all_models(X_test, y_test):
    """Find and compare all available models"""
    
    print("\n" + "="*80)
    print(" COMPARING ALL AVAILABLE MODELS")
    print("="*80)
    
    # Find all .pkl files in model directories
    all_models = []
    for model_dir in Config.MODEL_DIRS:
        if os.path.exists(model_dir):
            for file in os.listdir(model_dir):
                if file.endswith('_model.pkl'):
                    model_path = os.path.join(model_dir, file)
                    all_models.append(model_path)
    
    if not all_models:
        print("\n❌ No models found in:")
        for d in Config.MODEL_DIRS:
            print(f"   {d}")
        return
    
    print(f"\n🔍 Found {len(all_models)} model(s):")
    for m in all_models:
        print(f"   {m}")
    
    # Evaluate each model
    results = []
    for model_path in all_models:
        print(f"\n{'─'*80}")
        metrics = evaluate_model(model_path, X_test, y_test, show_details=False)
        if metrics:
            results.append(metrics)
    
    # Create comparison table
    if results:
        print("\n" + "="*80)
        print(" COMPARISON SUMMARY")
        print("="*80)
        
        df = pd.DataFrame(results)
        df = df.sort_values('f1', ascending=False)
        
        # Format display
        print(f"\n{'Model':<25} {'Accuracy':>9} {'Precision':>10} {'Recall':>9} {'F1':>9} {'ROC-AUC':>9}")
        print("─" * 80)
        
        for _, row in df.iterrows():
            print(f"{row['model_name']:<25} "
                  f"{row['accuracy']*100:8.2f}% "
                  f"{row['precision']*100:9.2f}% "
                  f"{row['recall']*100:8.2f}% "
                  f"{row['f1']*100:8.2f}% "
                  f"{row['roc_auc']*100 if pd.notna(row['roc_auc']) else 0:8.2f}%")
        
        # Highlight best
        best_model = df.iloc[0]
        print("\n" + "="*80)
        print(" 🏆 BEST MODEL (by F1-Score)")
        print("="*80)
        print(f"\n  Model:           {best_model['model_name']}")
        print(f"  Path:            {best_model['model_path']}")
        print(f"  Accuracy:        {best_model['accuracy']*100:.2f}%")
        print(f"  Precision:       {best_model['precision']*100:.2f}%")
        print(f"  Recall:          {best_model['recall']*100:.2f}%")
        print(f"  F1-Score:        {best_model['f1']*100:.2f}%")
        if pd.notna(best_model['roc_auc']):
            print(f"  ROC-AUC:         {best_model['roc_auc']*100:.2f}%")
        print(f"\n  Dropouts caught: {best_model['caught_dropouts']}/{best_model['total_dropouts']} "
              f"({best_model['caught_dropouts']/best_model['total_dropouts']*100:.1f}%)")
        print(f"  Dropouts missed: {best_model['missed_dropouts']}/{best_model['total_dropouts']} "
              f"({best_model['missed_dropouts']/best_model['total_dropouts']*100:.1f}%)")
        print(f"  False alarms:    {best_model['false_alarms']}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Evaluate model accuracy')
    parser.add_argument('--model', type=str, help='Path to specific model to evaluate')
    parser.add_argument('--all', action='store_true', help='Compare all available models')
    parser.add_argument('--no-details', action='store_true', help='Skip detailed output')
    
    args = parser.parse_args()
    
    # Load test data
    try:
        X_train, X_test, y_train, y_test, features = load_test_data()
    except FileNotFoundError as e:
        print(f"\n❌ Error: {e}")
        print("\n💡 Make sure:")
        print("   1. Dataset is in ./data/ directory")
        print("   2. CSV file contains 'Target', 'G1', 'G2', 'G3' columns")
        return
    
    if args.all:
        # Compare all models
        compare_all_models(X_test, y_test)
    
    elif args.model:
        # Evaluate specific model
        evaluate_model(args.model, X_test, y_test, show_details=not args.no_details)
    
    else:
        # Evaluate default best model
        default_paths = [
            './models_advanced/advanced_ensemble.pkl',
            './models_tuned/stackingensemble_model.pkl',
            './models/randomforest_model.pkl',
            './models/gradientboosting_model.pkl',
            './models/logisticregression_model.pkl',
        ]
        
        print("\n🔍 Looking for best model...")
        for path in default_paths:
            if os.path.exists(path):
                print(f"✅ Found: {path}")
                evaluate_model(path, X_test, y_test, show_details=not args.no_details)
                break
        else:
            print("\n⚠️  No default model found. Options:")
            print("\n   1. Train models first:")
            print("      python train_model_two.py")
            print("\n   2. Evaluate specific model:")
            print("      python evaluate_model_fixed.py --model ./models/yourmodel.pkl")
            print("\n   3. Compare all models:")
            print("      python evaluate_model_fixed.py --all")
    
    print("\n" + "="*80)
    print(" ✅ EVALUATION COMPLETE")
    print("="*80)


if __name__ == '__main__':
    main()