"""
REDESIGNED Student Dropout Prediction - Production ML Pipeline
===============================================================
This script creates a proper ML model that:
1. Uses ALL features equally (no hardcoded if-else)
2. Generates weighted risk scores from model probabilities
3. Removes data leakage (NO G3 in features)
4. Implements proper feature engineering
5. Handles class imbalance

Author: ML Engineering Team
"""

import pandas as pd
import numpy as np
import os
import warnings
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                            f1_score, roc_auc_score, confusion_matrix, 
                            classification_report, roc_curve)
from imblearn.over_sampling import SMOTE
import joblib

warnings.filterwarnings('ignore')

# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    """Configuration for the ML pipeline"""
    DATA_DIR = './data'
    MODEL_DIR = './models'
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 5
    
    # CRITICAL: Features to EXCLUDE (to prevent data leakage)
    EXCLUDE_FEATURES = ['G3']  # G3 is the final grade - we can't use it!
    
    # Model hyperparameters (tuned for student dropout)
    RF_PARAMS = {
        'n_estimators': 300,
        'max_depth': 20,
        'min_samples_split': 10,
        'min_samples_leaf': 4,
        'max_features': 'sqrt',
        'bootstrap': True,
        'random_state': RANDOM_STATE,
        'n_jobs': -1,
        'class_weight': 'balanced_subsample',
        'criterion': 'gini'
    }
    
    GB_PARAMS = {
        'n_estimators': 200,
        'learning_rate': 0.05,
        'max_depth': 6,
        'min_samples_split': 10,
        'min_samples_leaf': 4,
        'subsample': 0.8,
        'random_state': RANDOM_STATE
    }
    
    # Target creation strategy
    TARGET_STRATEGY = 'grade_based'  # Options: 'grade_based', 'multi_factor'
    GRADE_THRESHOLD = 10  # G3 < 10 indicates dropout risk

# ============================================================================
# DATA LOADING
# ============================================================================

def find_and_load_data(data_dir):
    """Load student performance data"""
    print("\n" + "="*80)
    print("STEP 1: DATA LOADING")
    print("="*80)
    
    csv_files = list(Path(data_dir).rglob('*.csv'))
    print(f"\nSearching for CSV files in {data_dir}...")
    print(f"Found {len(csv_files)} CSV files")
    
    for filepath in csv_files:
        for separator in [',', ';', '\t']:
            try:
                df = pd.read_csv(filepath, sep=separator)
                
                # Check for required columns
                if 'G3' in df.columns and 'G1' in df.columns and 'G2' in df.columns and 'Target' in df.columns:
                    print(f"\n✅ Loaded: {filepath.name}")
                    print(f"   Shape: {df.shape[0]} rows × {df.shape[1]} columns")
                    print(f"   Columns: {list(df.columns)}")
                    return df
            except Exception as e:
                continue
    
    print("❌ ERROR: Could not find suitable data file")
    return None

# ============================================================================
# TARGET VARIABLE CREATION
# ============================================================================

def create_target_variable(df, strategy='grade_based'):
    """
    Create target variable WITHOUT using G3 as a feature
    
    Strategy 1: Grade-based (simple, effective)
    - Use G3 to create target, then REMOVE it from features
    - dropout = 1 if G3 < threshold, else 0
    
    Strategy 2: Multi-factor (complex, considers multiple signals)
    - Combines G1, G2, failures, absences
    - More nuanced but requires careful tuning
    
    Args:
        df: Input DataFrame
        strategy: 'grade_based' or 'multi_factor'
    
    Returns:
        DataFrame with 'target' column added
    """
    print("\n" + "="*80)
    print("STEP 2: TARGET VARIABLE CREATION")
    print("="*80)
    
    if strategy == 'grade_based':
        # Simple and effective: G3 < 10 indicates dropout risk
        df['target'] = (df['G3'] < Config.GRADE_THRESHOLD).astype(int)
        print(f"\n📊 Strategy: Grade-based (G3 < {Config.GRADE_THRESHOLD})")
        
    elif strategy == 'multi_factor':
        # Complex: Multiple factors indicate dropout risk
        def calculate_dropout_risk(row):
            risk_score = 0
            
            # Poor academic trajectory
            if row.get('G1', 10) < 10:
                risk_score += 1
            if row.get('G2', 10) < 10:
                risk_score += 1
            
            # History of failures
            if row.get('failures', 0) >= 2:
                risk_score += 2
            elif row.get('failures', 0) == 1:
                risk_score += 1
            
            # High absences
            if row.get('absences', 0) > 15:
                risk_score += 1
            
            # Low study time
            if row.get('studytime', 2) < 2:
                risk_score += 1
            
            # Final grade confirms dropout
            if row.get('G3', 10) < Config.GRADE_THRESHOLD:
                risk_score += 2
            
            return 1 if risk_score >= 4 else 0
        
        df['target'] = df.apply(calculate_dropout_risk, axis=1)
        print(f"\n📊 Strategy: Multi-factor risk assessment")
    
    # Report class distribution
    dropout_count = df['target'].sum()
    continue_count = len(df) - dropout_count
    dropout_pct = (dropout_count / len(df)) * 100
    
    print(f"\n📈 Target Distribution:")
    print(f"   Dropout (1):  {dropout_count:4d} students ({dropout_pct:.1f}%)")
    print(f"   Continue (0): {continue_count:4d} students ({100-dropout_pct:.1f}%)")
    
    if dropout_pct < 20 or dropout_pct > 80:
        print(f"   ⚠️  WARNING: Imbalanced dataset - will use SMOTE")
    
    return df

# ============================================================================
# FEATURE ENGINEERING
# ============================================================================

def engineer_features(df):
    """
    Create derived features that capture important patterns
    """
    print("\n" + "="*80)
    print("STEP 3: FEATURE ENGINEERING")
    print("="*80)
    
    df_eng = df.copy()
    
    # ---------------------------------------------------------
    # 🛠️ FIX: Convert binary 'yes'/'no' columns to 1/0 first
    # ---------------------------------------------------------
    binary_mapping = {'yes': 1, 'no': 0}
    cols_to_convert = ['higher', 'famsup', 'schoolsup', 'paid']
    
    for col in cols_to_convert:
        if col in df_eng.columns and df_eng[col].dtype == 'object':
            print(f"   Converting '{col}' from yes/no to 1/0 for calculations...")
            df_eng[col] = df_eng[col].map(binary_mapping)
            # Fill any NaNs that resulted from mapping (just in case) with 0
            df_eng[col] = df_eng[col].fillna(0).astype(int)
    # ---------------------------------------------------------

    # Academic trend features
    df_eng['grade_improvement'] = df_eng['G2'] - df_eng['G1']
    df_eng['grade_average'] = (df_eng['G1'] + df_eng['G2']) / 2
    df_eng['grade_volatility'] = abs(df_eng['G2'] - df_eng['G1'])
    
    # Combined risk indicators
    df_eng['total_alcohol'] = df_eng['Dalc'] + df_eng['Walc']
    df_eng['parent_education'] = df_eng['Medu'] + df_eng['Fedu']
    
    # Engagement score (Now this will work because 'higher' is numeric)
    df_eng['engagement_score'] = (
        df_eng['studytime'] * 2 +  
        (5 - df_eng.get('goout', 3)) + 
        df_eng.get('higher', 1) * 2  
    )
    
    # Support score (Now this will work because famsup/schoolsup/paid are numeric)
    df_eng['support_score'] = (
        df_eng.get('famsup', 0) * 2 +
        df_eng.get('schoolsup', 0) +
        df_eng.get('paid', 0)
    )
    
    # Risk indicators (binary flags)
    df_eng['high_absences'] = (df_eng['absences'] > 10).astype(int)
    df_eng['has_failures'] = (df_eng['failures'] > 0).astype(int)
    df_eng['low_study'] = (df_eng['studytime'] < 2).astype(int)
    df_eng['high_alcohol'] = (df_eng['total_alcohol'] > 4).astype(int)
    
    # Interaction features
    df_eng['study_health'] = df_eng['studytime'] * df_eng['health']
    df_eng['parent_support'] = df_eng['parent_education'] * df_eng.get('famsup', 0)
    
    print(f"\n✅ Created {len(df_eng.columns) - len(df.columns)} new features")
    
    return df_eng

def select_features(df, exclude_list):
    """
    Select all relevant features, excluding those in exclude_list
    
    Returns:
        List of feature names
    """
    # Start with all columns except target and excluded features
    all_features = [col for col in df.columns if col not in ['target'] + exclude_list]
    
    print(f"\n📋 Feature Selection:")
    print(f"   Total features: {len(all_features)}")
    print(f"   Excluded: {exclude_list}")
    
    return all_features

# ============================================================================
# DATA PREPROCESSING
# ============================================================================

def preprocess_data(df, feature_columns, use_smote=True):
    """
    Preprocess data with proper handling of imbalanced classes
    
    Steps:
    1. Handle missing values
    2. Encode categorical variables
    3. Split data
    4. Scale features
    5. Apply SMOTE if needed
    """
    print("\n" + "="*80)
    print("STEP 4: DATA PREPROCESSING")
    print("="*80)
    
    # Create working copy
    df_model = df[feature_columns + ['target']].copy()
    
    # 1. Handle missing values
    print("\n🔧 Handling missing values...")
    numerical_cols = df_model.select_dtypes(include=[np.number]).columns.tolist()
    categorical_cols = df_model.select_dtypes(include=['object']).columns.tolist()
    
    # Remove 'target' from numerical_cols if present
    if 'target' in numerical_cols:
        numerical_cols.remove('target')
    
    for col in numerical_cols:
        if df_model[col].isnull().any():
            df_model[col].fillna(df_model[col].median(), inplace=True)
    
    for col in categorical_cols:
        if df_model[col].isnull().any():
            df_model[col].fillna(df_model[col].mode()[0], inplace=True)
    
    print(f"   ✅ Filled missing values in {len(numerical_cols)} numerical, {len(categorical_cols)} categorical columns")
    
    # 2. Encode categorical variables
    print("\n🔤 Encoding categorical variables...")
    label_encoders = {}
    for col in categorical_cols:
        le = LabelEncoder()
        df_model[col] = le.fit_transform(df_model[col].astype(str))
        label_encoders[col] = le
    
    print(f"   ✅ Encoded {len(label_encoders)} categorical features")
    
    # 3. Separate features and target
    X = df_model.drop('target', axis=1)
    y = df_model['target']
    
    # 4. Train-test split (stratified to maintain class balance)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, 
        test_size=Config.TEST_SIZE, 
        random_state=Config.RANDOM_STATE,
        stratify=y
    )
    
    print(f"\n📊 Train-Test Split:")
    print(f"   Training set: {X_train.shape[0]} samples")
    print(f"   Test set: {X_test.shape[0]} samples")
    print(f"   Features: {X_train.shape[1]}")
    
    # 5. Scale features
    print("\n⚖️  Scaling features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    print(f"   ✅ Applied StandardScaler")
    
    # 6. Handle class imbalance with SMOTE
    if use_smote:
        dropout_ratio = y_train.sum() / len(y_train)
        if dropout_ratio < 0.3 or dropout_ratio > 0.7:
            print(f"\n🔄 Applying SMOTE (original ratio: {dropout_ratio:.2%})...")
            smote = SMOTE(random_state=Config.RANDOM_STATE, k_neighbors=5)
            X_train_scaled, y_train = smote.fit_resample(X_train_scaled, y_train)
            print(f"   ✅ New training set: {X_train_scaled.shape[0]} samples")
            print(f"   ✅ New class ratio: {y_train.sum() / len(y_train):.2%}")
    
    # Print final class distribution
    print(f"\n📈 Final Class Distribution:")
    print(f"   Train - Dropout: {y_train.sum()}, Continue: {len(y_train) - y_train.sum()}")
    print(f"   Test  - Dropout: {y_test.sum()}, Continue: {len(y_test) - y_test.sum()}")
    
    return X_train_scaled, X_test_scaled, y_train, y_test, scaler, label_encoders, X_train.columns.tolist()

# ============================================================================
# MODEL TRAINING
# ============================================================================

def train_models(X_train, y_train):
    """Train multiple models for comparison"""
    print("\n" + "="*80)
    print("STEP 5: MODEL TRAINING")
    print("="*80)
    
    models = {}
    
    # 1. Random Forest (Best for this task)
    print("\n🌲 Training Random Forest Classifier...")
    rf = RandomForestClassifier(**Config.RF_PARAMS)
    rf.fit(X_train, y_train)
    models['RandomForest'] = rf
    print("   ✅ Training complete")
    
    # 2. Gradient Boosting
    print("\n🚀 Training Gradient Boosting Classifier...")
    gb = GradientBoostingClassifier(**Config.GB_PARAMS)
    gb.fit(X_train, y_train)
    models['GradientBoosting'] = gb
    print("   ✅ Training complete")
    
    # 3. Logistic Regression (Baseline)
    print("\n📈 Training Logistic Regression...")
    lr = LogisticRegression(
        max_iter=2000,
        random_state=Config.RANDOM_STATE,
        class_weight='balanced',
        C=0.1
    )
    lr.fit(X_train, y_train)
    models['LogisticRegression'] = lr
    print("   ✅ Training complete")
    
    return models

# ============================================================================
# MODEL EVALUATION
# ============================================================================

def evaluate_models(models, X_train, X_test, y_train, y_test, feature_names):
    """Comprehensive evaluation with feature importance"""
    print("\n" + "="*80)
    print("STEP 6: MODEL EVALUATION")
    print("="*80)
    
    results = {}
    
    for name, model in models.items():
        print(f"\n{'='*80}")
        print(f"📊 {name}")
        print(f"{'='*80}")
        
        # Cross-validation
        cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True, 
                            random_state=Config.RANDOM_STATE)
        cv_scores = cross_val_score(model, X_train, y_train, cv=cv, 
                                    scoring='f1', n_jobs=-1)
        
        # Predictions
        y_pred = model.predict(X_test)
        y_proba = model.predict_proba(X_test)[:, 1]
        
        # Metrics
        metrics = {
            'cv_f1_mean': cv_scores.mean(),
            'cv_f1_std': cv_scores.std(),
            'accuracy': accuracy_score(y_test, y_pred),
            'precision': precision_score(y_test, y_pred, zero_division=0),
            'recall': recall_score(y_test, y_pred, zero_division=0),
            'f1': f1_score(y_test, y_pred, zero_division=0),
            'roc_auc': roc_auc_score(y_test, y_proba)
        }
        
        results[name] = metrics
        
        # Print metrics
        print(f"\n🎯 Cross-Validation:")
        print(f"   F1-Score: {metrics['cv_f1_mean']:.4f} ± {metrics['cv_f1_std']:.4f}")
        
        print(f"\n🎯 Test Set Performance:")
        print(f"   Accuracy:  {metrics['accuracy']:.4f}")
        print(f"   Precision: {metrics['precision']:.4f}")
        print(f"   Recall:    {metrics['recall']:.4f}")
        print(f"   F1-Score:  {metrics['f1']:.4f}")
        print(f"   ROC-AUC:   {metrics['roc_auc']:.4f}")
        
        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        print(f"\n📋 Confusion Matrix:")
        print(f"                Predicted")
        print(f"              Continue  Dropout")
        print(f"   Continue  {cm[0,0]:6d}   {cm[0,1]:6d}")
        print(f"   Dropout   {cm[1,0]:6d}   {cm[1,1]:6d}")
        
        # Feature importance (for tree-based models)
        if hasattr(model, 'feature_importances_'):
            importances = model.feature_importances_
            indices = np.argsort(importances)[::-1]
            
            print(f"\n🔍 Top 10 Most Important Features:")
            for i, idx in enumerate(indices[:10], 1):
                print(f"   {i:2d}. {feature_names[idx]:20s}: {importances[idx]:.4f}")
    
    return results

# ============================================================================
# MODEL PERSISTENCE
# ============================================================================

def save_models(models, scaler, feature_columns, label_encoders, results):
    """Save all model artifacts"""
    print("\n" + "="*80)
    print("STEP 7: SAVING MODEL ARTIFACTS")
    print("="*80)
    
    os.makedirs(Config.MODEL_DIR, exist_ok=True)
    
    # Find best model
    best_model_name = max(results, key=lambda x: results[x]['f1'])
    
    # Save all models
    for name, model in models.items():
        filename = f'{name.lower()}_model.pkl'
        filepath = os.path.join(Config.MODEL_DIR, filename)
        joblib.dump(model, filepath)
        print(f"✅ Saved: {filename}")
    
    # Save preprocessing artifacts
    joblib.dump(scaler, os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(feature_columns, os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    joblib.dump(label_encoders, os.path.join(Config.MODEL_DIR, 'label_encoders.pkl'))
    
    print(f"\n✅ Saved preprocessing artifacts:")
    print(f"   - scaler.pkl")
    print(f"   - feature_columns.pkl")
    print(f"   - label_encoders.pkl")
    
    # Save model metadata
    metadata = {
        'best_model': best_model_name,
        'performance': results,
        'features': feature_columns,
        'target_strategy': Config.TARGET_STRATEGY,
        'grade_threshold': Config.GRADE_THRESHOLD
    }
    joblib.dump(metadata, os.path.join(Config.MODEL_DIR, 'model_metadata.pkl'))
    
    print(f"\n🏆 Best Model: {best_model_name}")
    print(f"   F1-Score:  {results[best_model_name]['f1']:.4f}")
    print(f"   ROC-AUC:   {results[best_model_name]['roc_auc']:.4f}")
    print(f"   Precision: {results[best_model_name]['precision']:.4f}")
    print(f"   Recall:    {results[best_model_name]['recall']:.4f}")

# ============================================================================
# MAIN PIPELINE
# ============================================================================

def main():
    """Execute complete training pipeline"""
    print("\n" + "="*80)
    print("🎓 STUDENT DROPOUT PREDICTION - REDESIGNED ML PIPELINE")
    print("="*80)
    print("This model uses ALL features equally and learns patterns from data")
    print("No hardcoded rules - pure machine learning!")
    print("="*80)
    
    try:
        # Step 1: Load data
        df = find_and_load_data(Config.DATA_DIR)
        if df is None:
            raise Exception("Failed to load data")
        
        # Step 2: Create target variable
        df = create_target_variable(df, strategy=Config.TARGET_STRATEGY)
        
        # Step 3: Feature engineering
        df = engineer_features(df)
        
        # Step 4: Select features (EXCLUDE G3!)
        feature_columns = select_features(df, Config.EXCLUDE_FEATURES)
        
        # Step 5: Preprocess data
        X_train, X_test, y_train, y_test, scaler, encoders, final_features = preprocess_data(
            df, feature_columns, use_smote=True
        )
        
        # Step 6: Train models
        models = train_models(X_train, y_train)
        
        # Step 7: Evaluate models
        results = evaluate_models(models, X_train, X_test, y_train, y_test, final_features)
        
        # Step 8: Save models
        save_models(models, scaler, final_features, encoders, results)
        
        print("\n" + "="*80)
        print("✅ PIPELINE COMPLETE!")
        print("="*80)
        print("\nNext steps:")
        print("1. Upload all .pkl files from ./models/ to Hugging Face")
        print("2. Use the generated app.py for deployment")
        print("3. Test with real student data")
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        raise

if __name__ == "__main__":
    main()