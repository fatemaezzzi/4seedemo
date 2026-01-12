"""
Student Dropout Prediction - Complete Training Pipeline
========================================================
This script consolidates all training steps from the Jupyter notebook
into a single, production-ready Python file.

Usage:
    python train_model.py
"""

import pandas as pd
import numpy as np
import os
import warnings
from pathlib import Path

from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                            f1_score, roc_auc_score, confusion_matrix, 
                            classification_report)
import joblib

warnings.filterwarnings('ignore')

# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    """Configuration settings for the training pipeline"""
    DATA_DIR = './data'
    MODEL_DIR = './models'
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 5
    
    # Model hyperparameters (optimized)
    RF_PARAMS = {
        'n_estimators': 200,
        'max_depth': 15,
        'min_samples_split': 5,
        'min_samples_leaf': 2,
        'max_features': 'sqrt',
        'bootstrap': True,
        'random_state': RANDOM_STATE,
        'n_jobs': -1,
        'class_weight': 'balanced'  # Important for imbalanced data
    }
    
    # Target variable thresholds
    DROPOUT_THRESHOLDS = {
        'critical_grade': 10,      # G3 < 10 = high risk
        'borderline_grade': 12,    # G3 < 12 = medium risk
        'high_absences': 15,       # absences > 15
        'multiple_failures': 1     # failures > 1
    }

# ============================================================================
# DATA LOADING
# ============================================================================

def find_and_load_data(data_dir):
    """
    Automatically find and load student performance data
    
    Args:
        data_dir: Directory containing CSV files
        
    Returns:
        DataFrame with loaded data or None if not found
    """
    print("\n" + "="*80)
    print("STEP 1: DATA LOADING")
    print("="*80)
    
    csv_files = list(Path(data_dir).rglob('*.csv'))
    print(f"\nFound {len(csv_files)} CSV files")
    
    for filepath in csv_files:
        for separator in [';', ',', '\t']:
            try:
                df = pd.read_csv(filepath, sep=separator)
                
                # Check if this file has the required 'G3' column
                if 'G3' in df.columns:
                    print(f"✅ Loaded: {filepath}")
                    print(f"   Shape: {df.shape[0]} rows × {df.shape[1]} columns")
                    print(f"   Columns: {list(df.columns)[:10]}...")
                    return df
            except Exception as e:
                continue
    
    print("❌ ERROR: Could not find file with 'G3' column")
    return None

# ============================================================================
# FEATURE ENGINEERING
# ============================================================================

def create_dropout_target(df, thresholds):
    """
    Create dropout target using weighted risk calculation
    
    This function implements a sophisticated risk assessment that considers:
    1. Academic performance (G3 grades)
    2. Historical failures
    3. Attendance patterns
    4. Study engagement
    5. Family and social support
    
    Args:
        df: Input DataFrame
        thresholds: Dictionary of risk thresholds
        
    Returns:
        Series with binary dropout labels (0=continue, 1=dropout)
    """
    def calculate_risk_score(row):
        score = 0.0
        
        # ACADEMIC FACTORS (Weight: 0.6)
        g3 = row.get('G3', 20)
        if g3 < thresholds['critical_grade']:
            score += 0.35  # Critical failure
        elif g3 < thresholds['borderline_grade']:
            score += 0.15  # Borderline performance
            
        failures = row.get('failures', 0)
        if failures > thresholds['multiple_failures']:
            score += 0.25
        elif failures == 1:
            score += 0.10
        
        # ENGAGEMENT FACTORS (Weight: 0.25)
        absences = row.get('absences', 0)
        if absences > thresholds['high_absences']:
            score += 0.15
        elif absences > 10:
            score += 0.05
            
        studytime = row.get('studytime', 2)
        if studytime < 2:
            score += 0.10
        
        # SUPPORT FACTORS (Weight: 0.15)
        famsup = row.get('famsup', 'yes')
        if famsup in ['no', 0, '0']:
            score += 0.08
            
        health = row.get('health', 5)
        if health <= 2:
            score += 0.07
        
        # Return binary classification
        return 1 if score >= 0.5 else 0
    
    return df.apply(calculate_risk_score, axis=1)

def select_features(df):
    """
    Select relevant features for modeling
    
    Returns:
        List of feature column names available in the dataset
    """
    # Comprehensive feature list
    desired_features = [
        # Academic performance
        'G1', 'G2', 'G3', 'failures', 'absences', 'studytime',
        
        # Demographics
        'age', 'sex', 'address', 'famsize', 'Pstatus',
        
        # Family background
        'Medu', 'Fedu', 'Mjob', 'Fjob', 'guardian',
        
        # Support and resources
        'famsup', 'schoolsup', 'paid', 'internet',
        
        # Social and lifestyle
        'activities', 'nursery', 'higher', 'romantic',
        'famrel', 'freetime', 'goout', 'Dalc', 'Walc', 'health',
        
        # School
        'school', 'reason', 'traveltime'
    ]
    
    # Keep only features that exist in the dataset
    available_features = [f for f in desired_features if f in df.columns]
    
    print(f"\n📊 Selected {len(available_features)} features")
    return available_features

# ============================================================================
# DATA PREPROCESSING
# ============================================================================

def preprocess_data(df, feature_columns, target_column='target'):
    """
    Preprocess data for machine learning
    
    Steps:
    1. Handle missing values
    2. Encode categorical variables
    3. Scale numerical features
    
    Args:
        df: Input DataFrame
        feature_columns: List of feature names
        target_column: Name of target variable
        
    Returns:
        X_train, X_test, y_train, y_test, scaler, encoders
    """
    print("\n" + "="*80)
    print("STEP 2: DATA PREPROCESSING")
    print("="*80)
    
    # Create working copy
    df_model = df[feature_columns + [target_column]].copy()
    
    # Handle missing values
    numerical_cols = df_model.select_dtypes(include=[np.number]).columns
    categorical_cols = df_model.select_dtypes(include=['object']).columns
    
    df_model[numerical_cols] = df_model[numerical_cols].fillna(
        df_model[numerical_cols].median()
    )
    df_model[categorical_cols] = df_model[categorical_cols].fillna(
        df_model[categorical_cols].mode().iloc[0]
    )
    
    print(f"✅ Handled missing values")
    
    # Encode categorical variables
    label_encoders = {}
    for col in categorical_cols:
        if col != target_column:
            le = LabelEncoder()
            df_model[col] = le.fit_transform(df_model[col].astype(str))
            label_encoders[col] = le
    
    print(f"✅ Encoded {len(label_encoders)} categorical features")
    
    # Separate features and target
    X = df_model.drop(target_column, axis=1)
    y = df_model[target_column]
    
    # Train-test split with stratification
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, 
        test_size=Config.TEST_SIZE, 
        random_state=Config.RANDOM_STATE,
        stratify=y
    )
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    print(f"\n📊 Data split:")
    print(f"   Training: {X_train.shape[0]} samples")
    print(f"   Testing: {X_test.shape[0]} samples")
    print(f"   Class distribution (train): {np.bincount(y_train)}")
    
    return X_train_scaled, X_test_scaled, y_train, y_test, scaler, label_encoders

# ============================================================================
# MODEL TRAINING
# ============================================================================

def train_models(X_train, y_train):
    """
    Train multiple models for comparison
    
    Returns:
        Dictionary of trained models
    """
    print("\n" + "="*80)
    print("STEP 3: MODEL TRAINING")
    print("="*80)
    
    models = {}
    
    # 1. Random Forest (Primary model)
    print("\n🌲 Training Random Forest...")
    rf = RandomForestClassifier(**Config.RF_PARAMS)
    rf.fit(X_train, y_train)
    models['RandomForest'] = rf
    print("   ✅ Complete")
    
    # 2. Gradient Boosting
    print("\n🚀 Training Gradient Boosting...")
    gb = GradientBoostingClassifier(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=5,
        random_state=Config.RANDOM_STATE
    )
    gb.fit(X_train, y_train)
    models['GradientBoosting'] = gb
    print("   ✅ Complete")
    
    # 3. Logistic Regression (Baseline)
    print("\n📈 Training Logistic Regression...")
    lr = LogisticRegression(
        max_iter=1000,
        random_state=Config.RANDOM_STATE,
        class_weight='balanced'
    )
    lr.fit(X_train, y_train)
    models['LogisticRegression'] = lr
    print("   ✅ Complete")
    
    return models

# ============================================================================
# MODEL EVALUATION
# ============================================================================

def evaluate_models(models, X_train, X_test, y_train, y_test):
    """
    Comprehensive model evaluation with cross-validation
    
    Returns:
        Dictionary of evaluation metrics for each model
    """
    print("\n" + "="*80)
    print("STEP 4: MODEL EVALUATION")
    print("="*80)
    
    results = {}
    
    for name, model in models.items():
        print(f"\n{'='*80}")
        print(f"{name}")
        print(f"{'='*80}")
        
        # Cross-validation on training data
        cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True, 
                            random_state=Config.RANDOM_STATE)
        cv_scores = cross_val_score(model, X_train, y_train, cv=cv, scoring='f1')
        
        # Test set predictions
        y_pred = model.predict(X_test)
        y_proba = model.predict_proba(X_test)[:, 1]
        
        # Calculate metrics
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
        
        # Print results
        print(f"\n📊 Cross-Validation F1: {metrics['cv_f1_mean']:.4f} ± {metrics['cv_f1_std']:.4f}")
        print(f"\n🎯 Test Set Performance:")
        print(f"   Accuracy:  {metrics['accuracy']:.4f}")
        print(f"   Precision: {metrics['precision']:.4f}")
        print(f"   Recall:    {metrics['recall']:.4f}")
        print(f"   F1-Score:  {metrics['f1']:.4f}")
        print(f"   ROC-AUC:   {metrics['roc_auc']:.4f}")
        
        print(f"\n📋 Confusion Matrix:")
        cm = confusion_matrix(y_test, y_pred)
        print(f"   TN: {cm[0,0]:4d}  FP: {cm[0,1]:4d}")
        print(f"   FN: {cm[1,0]:4d}  TP: {cm[1,1]:4d}")
    
    return results

# ============================================================================
# MODEL PERSISTENCE
# ============================================================================

def save_models(models, scaler, feature_columns, results):
    """
    Save trained models and artifacts
    """
    print("\n" + "="*80)
    print("STEP 5: SAVING MODELS")
    print("="*80)
    
    os.makedirs(Config.MODEL_DIR, exist_ok=True)
    
    # Find best model based on F1 score
    best_model_name = max(results, key=lambda x: results[x]['f1'])
    best_model = models[best_model_name]
    
    # Save all models
    for name, model in models.items():
        model_path = os.path.join(Config.MODEL_DIR, f'{name.lower()}_model.pkl')
        joblib.dump(model, model_path)
        print(f"✅ Saved: {model_path}")
    
    # Save scaler and feature names
    joblib.dump(scaler, os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(feature_columns, os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    
    print(f"\n🏆 Best Model: {best_model_name}")
    print(f"   F1-Score: {results[best_model_name]['f1']:.4f}")
    print(f"   ROC-AUC:  {results[best_model_name]['roc_auc']:.4f}")

# ============================================================================
# MAIN PIPELINE
# ============================================================================

def main():
    """Main training pipeline"""
    print("\n" + "="*80)
    print("STUDENT DROPOUT PREDICTION - MODEL TRAINING")
    print("="*80)
    
    # Load data
    df = find_and_load_data(Config.DATA_DIR)
    if df is None:
        raise Exception("Could not load data")
    
    # Create target variable
    print("\n🎯 Creating target variable...")
    df['target'] = create_dropout_target(df, Config.DROPOUT_THRESHOLDS)
    print(f"   Dropout: {(df['target']==1).sum()} students")
    print(f"   Continue: {(df['target']==0).sum()} students")
    
    # Select features
    feature_columns = select_features(df)
    
    # Preprocess data
    X_train, X_test, y_train, y_test, scaler, encoders = preprocess_data(
        df, feature_columns
    )
    
    # Train models
    models = train_models(X_train, y_train)
    
    # Evaluate models
    results = evaluate_models(models, X_train, X_test, y_train, y_test)
    
    # Save models
    save_models(models, scaler, feature_columns, results)
    
    print("\n" + "="*80)
    print("✅ TRAINING COMPLETE!")
    print("="*80)

if __name__ == "__main__":
    main()