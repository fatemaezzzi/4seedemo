"""
MODEL EVALUATION SCRIPT
=======================

Shows comprehensive accuracy metrics for any saved model.

Usage:
    python evaluate_model.py                    # Evaluate current best model
    python evaluate_model.py --model ./models/randomforest_model.pkl
    python evaluate_model.py --all              # Compare all models
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
from sklearn.model_selection import cross_val_score, StratifiedKFold


# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    DATA_DIR = './data'
    MODEL_DIRS = ['./models', './models_tuned', './models_advanced']
    RANDOM_STATE = 42
    TEST_SIZE = 0.2


# ============================================================================
# LOAD DATA
# ============================================================================

def load_test_data():
    """Load and prepare test data"""
    print("\n" + "="*80)
    print(" LOADING TEST DATA")
    print("="*80)
    
    # Import from train_model.py
    sys.path.insert(0, '.')
    from train_model_two import (
        find_and_load_data, create_target_variable,
        engineer_features, select_features,
        Config as TrainConfig
    )
    
    # Load and prepare data
    df = find_and_load_data(TrainConfig.DATA_DIR)
    df = create_target_variable(df)
    df = engineer_features(df)
    features = select_features(df, TrainConfig.EXCLUDE_FEATURES)
    
    # Split
    from sklearn.model_selection import train_test_split
    X = df[features]
    y = df['target']
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=Config.TEST_SIZE,
        random_state=Config.RANDOM_STATE, stratify=y
    )
    
    print(f"\n✅ Data loaded:")
    print(f"   Train: {len(X_train)} samples")
    print(f"   Test:  {len(X_test)} samples")
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
            
            # Ensure X_test has same features
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
        total_dropouts = y_test.sum()
        correctly_identified = cm[1,1]
        missed_dropouts = cm[1,0]
        false_alarms = cm[0,1]
        
        print(f"\n  ⚠️  Error Breakdown:")
        print(f"     Correctly identified dropouts: {correctly_identified} / {total_dropouts} ({correctly_identified/total_dropouts*100:.1f}%)")
        print(f"     Missed dropouts (False Neg):   {missed_dropouts} / {total_dropouts} ({missed_dropouts/total_dropouts*100:.1f}%)")
        print(f"     False alarms (False Pos):      {false_alarms}")
        
        # Real-world impact
        print(f"\n  🎯 Real-World Impact (if 1,000 at-risk students):")
        if total_dropouts > 0:
            catch_rate = correctly_identified / total_dropouts
            students_caught = int(1000 * catch_rate)
            students_missed = 1000 - students_caught
            print(f"     Would identify:  {students_caught} students")
            print(f"     Would miss:      {students_missed} students")
        
        # Additional details
        if show_details and roc_auc is not None:
            print(f"\n  📈 Probability Distribution:")
            print(f"     Dropout predictions (avg prob): {y_prob[y_test==1].mean():.3f}")
            print(f"     Graduate predictions (avg prob): {1-y_prob[y_test==0].mean():.3f}")
            
            # Check confidence
            confident_correct = ((y_prob > 0.8) & (y_test == 1)).sum() + \
                               ((y_prob < 0.2) & (y_test == 0)).sum()
            confident_wrong = ((y_prob > 0.8) & (y_test == 0)).sum() + \
                             ((y_prob < 0.2) & (y_test == 1)).sum()
            
            print(f"\n  🎯 Confidence Analysis:")
            print(f"     High-confidence correct: {confident_correct}")
            print(f"     High-confidence wrong:   {confident_wrong}")
        
        # Return metrics dict
        return {
            'model_path': model_path,
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'roc_auc': roc_auc,
            'confusion_matrix': cm
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
    
    print(f"\n📁 Found {len(all_models)} models:")
    for m in all_models:
        print(f"   {m}")
    
    # Evaluate each model
    results = []
    for model_path in all_models:
        metrics = evaluate_model(model_path, X_test, y_test, show_details=False)
        if metrics:
            results.append(metrics)
    
    # Create comparison table
    if results:
        print("\n" + "="*80)
        print(" COMPARISON SUMMARY")
        print("="*80)
        
        df = pd.DataFrame(results)
        df['model_name'] = df['model_path'].apply(lambda x: os.path.basename(x).replace('_model.pkl', ''))
        df = df.sort_values('f1', ascending=False)
        
        # Format columns
        display_df = df[['model_name', 'accuracy', 'precision', 'recall', 'f1', 'roc_auc']].copy()
        for col in ['accuracy', 'precision', 'recall', 'f1', 'roc_auc']:
            display_df[col] = display_df[col].apply(lambda x: f"{x*100:.2f}%" if pd.notna(x) else "N/A")
        
        print("\n" + display_df.to_string(index=False))
        
        # Highlight best
        best_model = df.iloc[0]
        print("\n" + "="*80)
        print(" 🏆 BEST MODEL")
        print("="*80)
        print(f"\n  Model:      {best_model['model_name']}")
        print(f"  Path:       {best_model['model_path']}")
        print(f"  Accuracy:   {best_model['accuracy']*100:.2f}%")
        print(f"  F1-Score:   {best_model['f1']*100:.2f}%")
        print(f"  Recall:     {best_model['recall']*100:.2f}%")
        if pd.notna(best_model['roc_auc']):
            print(f"  ROC-AUC:    {best_model['roc_auc']*100:.2f}%")


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
    X_train, X_test, y_train, y_test, features = load_test_data()
    
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
        ]
        
        print("\n🔍 Looking for best model...")
        for path in default_paths:
            if os.path.exists(path):
                print(f"✅ Found: {path}")
                evaluate_model(path, X_test, y_test, show_details=not args.no_details)
                break
        else:
            print("\n⚠️  No default model found. Options:")
            print("\n   1. Evaluate specific model:")
            print("      python evaluate_model.py --model ./models/yourmodel.pkl")
            print("\n   2. Compare all models:")
            print("      python evaluate_model.py --all")
            print("\n   3. Train a model first:")
            print("      python train_model.py")
    
    print("\n" + "="*80)
    print(" ✅ EVALUATION COMPLETE")
    print("="*80)


if __name__ == '__main__':
    main()