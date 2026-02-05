"""
Advanced Hyperparameter Tuning for Student Dropout Prediction
===============================================================

This script demonstrates multiple hyperparameter optimization techniques:

1. GridSearchCV      - Exhaustive search (slow but thorough)
2. RandomizedSearchCV - Random sampling (faster, good coverage)
3. Optuna            - Bayesian optimization (smart, adaptive)
4. Ensemble Stacking - Combine multiple models for best results

Expected improvements: 2-5% accuracy increase (87% → 89-92%)

Usage:
    python hyperparameter_tuning.py

Output:
    - Best models saved to ./models_tuned/
    - Detailed performance comparison report
    - Feature importance analysis
"""

import pandas as pd
import numpy as np
import os
import warnings
import joblib
import time
from pathlib import Path

from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import (
    train_test_split, GridSearchCV, RandomizedSearchCV,
    StratifiedKFold, cross_val_score
)
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier,
    VotingClassifier, StackingClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    f1_score, roc_auc_score, classification_report,
    confusion_matrix
)

# Optional: Optuna for Bayesian optimization
try:
    import optuna
    from optuna.samplers import TPESampler
    HAS_OPTUNA = True
except ImportError:
    HAS_OPTUNA = False
    print("⚠️  Optuna not installed. Install with: pip install optuna")
    print("   Skipping Bayesian optimization.\n")

# Optional: XGBoost and LightGBM for advanced models
try:
    import xgboost as xgb
    HAS_XGBOOST = True
except ImportError:
    HAS_XGBOOST = False
    print("⚠️  XGBoost not installed. Install with: pip install xgboost")

try:
    import lightgbm as lgb
    HAS_LIGHTGBM = True
except ImportError:
    HAS_LIGHTGBM = False
    print("⚠️  LightGBM not installed. Install with: pip install lightgbm")

warnings.filterwarnings('ignore')


# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    DATA_DIR = './data'
    MODEL_DIR = './models_tuned'
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 5
    
    # Tuning methods to run
    RUN_GRID_SEARCH = True
    RUN_RANDOM_SEARCH = True
    RUN_OPTUNA = True
    RUN_ENSEMBLE = True
    
    # Number of iterations for random/optuna search
    N_ITER_RANDOM = 100
    N_TRIALS_OPTUNA = 200


# ============================================================================
# LOAD DATA (reuse from train_model.py)
# ============================================================================

def load_and_prepare_data():
    """Load data and apply same preprocessing as train_model.py"""
    print("\n" + "="*80)
    print(" LOADING DATA")
    print("="*80)
    
    # Import the feature engineering from train_model.py
    import sys
    sys.path.insert(0, '.')
    try:
        from train_model_two import (
            find_and_load_data, create_target_variable,
            engineer_features, select_features, Config as TrainConfig
        )
    except ImportError:
        print("❌ Cannot import from train_model_two.py")
        print("   Make sure train_model_two.py is in the same directory.")
        raise
    
    # Use the same pipeline
    df = find_and_load_data(TrainConfig.DATA_DIR)
    df = create_target_variable(df)
    df = engineer_features(df)
    features = select_features(df, TrainConfig.EXCLUDE_FEATURES)
    
    # Prepare X and y
    X = df[features].copy()
    y = df['target'].copy()
    
    print(f"\n✅ Data loaded: {X.shape[0]} samples, {X.shape[1]} features")
    print(f"   Class distribution: {y.sum()} dropout / {len(y) - y.sum()} graduate")
    
    return X, y, features


def prepare_train_test(X, y):
    """Split and scale data"""
    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=Config.TEST_SIZE,
        random_state=Config.RANDOM_STATE,
        stratify=y
    )
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    print(f"\n✅ Split: Train={len(X_train)}, Test={len(X_test)}")
    
    return X_train_scaled, X_test_scaled, y_train, y_test, scaler


# ============================================================================
# HYPERPARAMETER SEARCH SPACES
# ============================================================================

def get_param_grids():
    """Define search spaces for each model"""
    
    # RandomForest - Grid Search (exhaustive but smaller space)
    rf_grid = {
        'n_estimators': [200, 300, 400],
        'max_depth': [15, 20, 25, 30],
        'min_samples_split': [5, 10, 15],
        'min_samples_leaf': [2, 4, 6],
        'max_features': ['sqrt', 'log2'],
        'class_weight': ['balanced', 'balanced_subsample'],
    }
    
    # RandomForest - Random Search (larger space, more exploration)
    rf_random = {
        'n_estimators': [100, 200, 300, 400, 500],
        'max_depth': [10, 15, 20, 25, 30, None],
        'min_samples_split': [2, 5, 10, 15, 20],
        'min_samples_leaf': [1, 2, 4, 6, 8],
        'max_features': ['sqrt', 'log2', 0.5, 0.7],
        'bootstrap': [True, False],
        'class_weight': ['balanced', 'balanced_subsample'],
        'criterion': ['gini', 'entropy'],
    }
    
    # GradientBoosting - Grid Search
    gb_grid = {
        'n_estimators': [100, 200, 300],
        'learning_rate': [0.01, 0.05, 0.1],
        'max_depth': [3, 5, 7],
        'min_samples_split': [10, 20],
        'min_samples_leaf': [4, 8],
        'subsample': [0.8, 0.9, 1.0],
    }
    
    # GradientBoosting - Random Search
    gb_random = {
        'n_estimators': [50, 100, 150, 200, 250, 300],
        'learning_rate': [0.001, 0.01, 0.05, 0.1, 0.2],
        'max_depth': [3, 4, 5, 6, 7, 8],
        'min_samples_split': [5, 10, 15, 20, 25],
        'min_samples_leaf': [2, 4, 6, 8, 10],
        'subsample': [0.6, 0.7, 0.8, 0.9, 1.0],
        'max_features': ['sqrt', 'log2', None],
    }
    
    # LogisticRegression - Grid Search
    lr_grid = {
        'C': [0.001, 0.01, 0.1, 1, 10],
        'penalty': ['l1', 'l2'],
        'solver': ['liblinear', 'saga'],
        'class_weight': ['balanced', None],
        'max_iter': [1000, 2000],
    }
    
    return {
        'rf_grid': rf_grid,
        'rf_random': rf_random,
        'gb_grid': gb_grid,
        'gb_random': gb_random,
        'lr_grid': lr_grid,
    }


# ============================================================================
# METHOD 1: GRID SEARCH CV
# ============================================================================

def run_grid_search(X_train, y_train):
    """Exhaustive grid search for best parameters"""
    print("\n" + "="*80)
    print(" METHOD 1: GRID SEARCH CV (Exhaustive)")
    print("="*80)
    
    params = get_param_grids()
    cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True, 
                         random_state=Config.RANDOM_STATE)
    
    results = {}
    
    # RandomForest
    print("\n🌲 RandomForest Grid Search...")
    start = time.time()
    rf = RandomForestClassifier(random_state=Config.RANDOM_STATE, n_jobs=-1)
    grid_rf = GridSearchCV(
        rf, params['rf_grid'], cv=cv, scoring='f1',
        n_jobs=-1, verbose=1
    )
    grid_rf.fit(X_train, y_train)
    results['RandomForest'] = {
        'model': grid_rf.best_estimator_,
        'params': grid_rf.best_params_,
        'cv_score': grid_rf.best_score_,
        'time': time.time() - start
    }
    print(f"   Best F1: {grid_rf.best_score_:.4f}")
    print(f"   Best params: {grid_rf.best_params_}")
    print(f"   Time: {results['RandomForest']['time']:.1f}s")
    
    # GradientBoosting
    print("\n🚀 GradientBoosting Grid Search...")
    start = time.time()
    gb = GradientBoostingClassifier(random_state=Config.RANDOM_STATE)
    grid_gb = GridSearchCV(
        gb, params['gb_grid'], cv=cv, scoring='f1',
        n_jobs=-1, verbose=1
    )
    grid_gb.fit(X_train, y_train)
    results['GradientBoosting'] = {
        'model': grid_gb.best_estimator_,
        'params': grid_gb.best_params_,
        'cv_score': grid_gb.best_score_,
        'time': time.time() - start
    }
    print(f"   Best F1: {grid_gb.best_score_:.4f}")
    print(f"   Best params: {grid_gb.best_params_}")
    print(f"   Time: {results['GradientBoosting']['time']:.1f}s")
    
    # LogisticRegression
    print("\n📈 LogisticRegression Grid Search...")
    start = time.time()
    lr = LogisticRegression(random_state=Config.RANDOM_STATE)
    grid_lr = GridSearchCV(
        lr, params['lr_grid'], cv=cv, scoring='f1',
        n_jobs=-1, verbose=1
    )
    grid_lr.fit(X_train, y_train)
    results['LogisticRegression'] = {
        'model': grid_lr.best_estimator_,
        'params': grid_lr.best_params_,
        'cv_score': grid_lr.best_score_,
        'time': time.time() - start
    }
    print(f"   Best F1: {grid_lr.best_score_:.4f}")
    print(f"   Best params: {grid_lr.best_params_}")
    print(f"   Time: {results['LogisticRegression']['time']:.1f}s")
    
    return results


# ============================================================================
# METHOD 2: RANDOMIZED SEARCH CV
# ============================================================================

def run_random_search(X_train, y_train):
    """Random parameter sampling for faster exploration"""
    print("\n" + "="*80)
    print(" METHOD 2: RANDOMIZED SEARCH CV (Faster)")
    print("="*80)
    
    params = get_param_grids()
    cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True,
                         random_state=Config.RANDOM_STATE)
    
    results = {}
    
    # RandomForest
    print(f"\n🌲 RandomForest Random Search ({Config.N_ITER_RANDOM} iterations)...")
    start = time.time()
    rf = RandomForestClassifier(random_state=Config.RANDOM_STATE, n_jobs=-1)
    random_rf = RandomizedSearchCV(
        rf, params['rf_random'], n_iter=Config.N_ITER_RANDOM,
        cv=cv, scoring='f1', n_jobs=-1, verbose=1,
        random_state=Config.RANDOM_STATE
    )
    random_rf.fit(X_train, y_train)
    results['RandomForest'] = {
        'model': random_rf.best_estimator_,
        'params': random_rf.best_params_,
        'cv_score': random_rf.best_score_,
        'time': time.time() - start
    }
    print(f"   Best F1: {random_rf.best_score_:.4f}")
    print(f"   Best params: {random_rf.best_params_}")
    print(f"   Time: {results['RandomForest']['time']:.1f}s")
    
    # GradientBoosting
    print(f"\n🚀 GradientBoosting Random Search ({Config.N_ITER_RANDOM} iterations)...")
    start = time.time()
    gb = GradientBoostingClassifier(random_state=Config.RANDOM_STATE)
    random_gb = RandomizedSearchCV(
        gb, params['gb_random'], n_iter=Config.N_ITER_RANDOM,
        cv=cv, scoring='f1', n_jobs=-1, verbose=1,
        random_state=Config.RANDOM_STATE
    )
    random_gb.fit(X_train, y_train)
    results['GradientBoosting'] = {
        'model': random_gb.best_estimator_,
        'params': random_gb.best_params_,
        'cv_score': random_gb.best_score_,
        'time': time.time() - start
    }
    print(f"   Best F1: {random_gb.best_score_:.4f}")
    print(f"   Best params: {random_gb.best_params_}")
    print(f"   Time: {results['GradientBoosting']['time']:.1f}s")
    
    return results


# ============================================================================
# METHOD 3: OPTUNA (BAYESIAN OPTIMIZATION)
# ============================================================================

def run_optuna_tuning(X_train, y_train):
    """Bayesian optimization with Optuna (smartest search)"""
    if not HAS_OPTUNA:
        print("\n⚠️  Optuna not available - skipping Bayesian optimization")
        return {}
    
    print("\n" + "="*80)
    print(" METHOD 3: OPTUNA BAYESIAN OPTIMIZATION (Smartest)")
    print("="*80)
    
    cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True,
                         random_state=Config.RANDOM_STATE)
    results = {}
    
    # ── RandomForest Objective ───────────────────────────────────────────
    def objective_rf(trial):
        params = {
            'n_estimators': trial.suggest_int('n_estimators', 100, 500),
            'max_depth': trial.suggest_int('max_depth', 10, 30),
            'min_samples_split': trial.suggest_int('min_samples_split', 2, 20),
            'min_samples_leaf': trial.suggest_int('min_samples_leaf', 1, 10),
            'max_features': trial.suggest_categorical('max_features', 
                                                      ['sqrt', 'log2', 0.5, 0.7]),
            'bootstrap': trial.suggest_categorical('bootstrap', [True, False]),
            'class_weight': trial.suggest_categorical('class_weight',
                                                      ['balanced', 'balanced_subsample']),
            'criterion': trial.suggest_categorical('criterion', ['gini', 'entropy']),
            'random_state': Config.RANDOM_STATE,
            'n_jobs': -1,
        }
        
        rf = RandomForestClassifier(**params)
        scores = cross_val_score(rf, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1)
        return scores.mean()
    
    print(f"\n🌲 RandomForest Optuna ({Config.N_TRIALS_OPTUNA} trials)...")
    start = time.time()
    study_rf = optuna.create_study(
        direction='maximize',
        sampler=TPESampler(seed=Config.RANDOM_STATE)
    )
    study_rf.optimize(objective_rf, n_trials=Config.N_TRIALS_OPTUNA, show_progress_bar=True)
    
    # Train final model with best params
    best_rf = RandomForestClassifier(**study_rf.best_params, random_state=Config.RANDOM_STATE, n_jobs=-1)
    best_rf.fit(X_train, y_train)
    
    results['RandomForest'] = {
        'model': best_rf,
        'params': study_rf.best_params,
        'cv_score': study_rf.best_value,
        'time': time.time() - start,
        'n_trials': len(study_rf.trials)
    }
    print(f"   Best F1: {study_rf.best_value:.4f}")
    print(f"   Best params: {study_rf.best_params}")
    print(f"   Time: {results['RandomForest']['time']:.1f}s")
    
    # ── GradientBoosting Objective ───────────────────────────────────────
    def objective_gb(trial):
        params = {
            'n_estimators': trial.suggest_int('n_estimators', 50, 300),
            'learning_rate': trial.suggest_float('learning_rate', 0.001, 0.3, log=True),
            'max_depth': trial.suggest_int('max_depth', 3, 10),
            'min_samples_split': trial.suggest_int('min_samples_split', 5, 25),
            'min_samples_leaf': trial.suggest_int('min_samples_leaf', 2, 12),
            'subsample': trial.suggest_float('subsample', 0.6, 1.0),
            'max_features': trial.suggest_categorical('max_features', ['sqrt', 'log2', None]),
            'random_state': Config.RANDOM_STATE,
        }
        
        gb = GradientBoostingClassifier(**params)
        scores = cross_val_score(gb, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1)
        return scores.mean()
    
    print(f"\n🚀 GradientBoosting Optuna ({Config.N_TRIALS_OPTUNA} trials)...")
    start = time.time()
    study_gb = optuna.create_study(
        direction='maximize',
        sampler=TPESampler(seed=Config.RANDOM_STATE)
    )
    study_gb.optimize(objective_gb, n_trials=Config.N_TRIALS_OPTUNA, show_progress_bar=True)
    
    best_gb = GradientBoostingClassifier(**study_gb.best_params, random_state=Config.RANDOM_STATE)
    best_gb.fit(X_train, y_train)
    
    results['GradientBoosting'] = {
        'model': best_gb,
        'params': study_gb.best_params,
        'cv_score': study_gb.best_value,
        'time': time.time() - start,
        'n_trials': len(study_gb.trials)
    }
    print(f"   Best F1: {study_gb.best_value:.4f}")
    print(f"   Best params: {study_gb.best_params}")
    print(f"   Time: {results['GradientBoosting']['time']:.1f}s")
    
    # ── XGBoost if available ─────────────────────────────────────────────
    if HAS_XGBOOST:
        def objective_xgb(trial):
            params = {
                'n_estimators': trial.suggest_int('n_estimators', 50, 300),
                'learning_rate': trial.suggest_float('learning_rate', 0.001, 0.3, log=True),
                'max_depth': trial.suggest_int('max_depth', 3, 10),
                'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
                'subsample': trial.suggest_float('subsample', 0.6, 1.0),
                'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
                'gamma': trial.suggest_float('gamma', 0, 5),
                'reg_alpha': trial.suggest_float('reg_alpha', 0, 1),
                'reg_lambda': trial.suggest_float('reg_lambda', 0, 1),
                'random_state': Config.RANDOM_STATE,
                'use_label_encoder': False,
                'eval_metric': 'logloss',
            }
            
            xgb_clf = xgb.XGBClassifier(**params)
            scores = cross_val_score(xgb_clf, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1)
            return scores.mean()
        
        print(f"\n⚡ XGBoost Optuna ({Config.N_TRIALS_OPTUNA} trials)...")
        start = time.time()
        study_xgb = optuna.create_study(direction='maximize', sampler=TPESampler(seed=Config.RANDOM_STATE))
        study_xgb.optimize(objective_xgb, n_trials=Config.N_TRIALS_OPTUNA, show_progress_bar=True)
        
        best_xgb = xgb.XGBClassifier(**study_xgb.best_params, random_state=Config.RANDOM_STATE)
        best_xgb.fit(X_train, y_train)
        
        results['XGBoost'] = {
            'model': best_xgb,
            'params': study_xgb.best_params,
            'cv_score': study_xgb.best_value,
            'time': time.time() - start,
            'n_trials': len(study_xgb.trials)
        }
        print(f"   Best F1: {study_xgb.best_value:.4f}")
        print(f"   Time: {results['XGBoost']['time']:.1f}s")
    
    return results


# ============================================================================
# METHOD 4: ENSEMBLE STACKING
# ============================================================================

def create_ensemble(base_models, X_train, y_train):
    """Create voting and stacking ensembles from best models"""
    print("\n" + "="*80)
    print(" METHOD 4: ENSEMBLE METHODS (Combining Best Models)")
    print("="*80)
    
    models_list = [(name, model['model']) for name, model in base_models.items()]
    
    # Voting Classifier (soft voting for probabilities)
    print("\n🗳️  Voting Ensemble (soft voting)...")
    start = time.time()
    voting = VotingClassifier(
        estimators=models_list,
        voting='soft',
        n_jobs=-1
    )
    voting.fit(X_train, y_train)
    
    cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True, random_state=Config.RANDOM_STATE)
    voting_score = cross_val_score(voting, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1).mean()
    
    voting_result = {
        'model': voting,
        'cv_score': voting_score,
        'time': time.time() - start
    }
    print(f"   CV F1: {voting_score:.4f}")
    print(f"   Time: {voting_result['time']:.1f}s")
    
    # Stacking Classifier (meta-learner)
    print("\n📚 Stacking Ensemble (LogisticRegression meta-learner)...")
    start = time.time()
    stacking = StackingClassifier(
        estimators=models_list,
        final_estimator=LogisticRegression(
            max_iter=2000,
            random_state=Config.RANDOM_STATE,
            class_weight='balanced'
        ),
        cv=5,
        n_jobs=-1
    )
    stacking.fit(X_train, y_train)
    
    stacking_score = cross_val_score(stacking, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1).mean()
    
    stacking_result = {
        'model': stacking,
        'cv_score': stacking_score,
        'time': time.time() - start
    }
    print(f"   CV F1: {stacking_score:.4f}")
    print(f"   Time: {stacking_result['time']:.1f}s")
    
    return {
        'VotingEnsemble': voting_result,
        'StackingEnsemble': stacking_result
    }


# ============================================================================
# EVALUATION
# ============================================================================

def evaluate_all_models(all_models, X_test, y_test):
    """Comprehensive evaluation of all tuned models"""
    print("\n" + "="*80)
    print(" FINAL EVALUATION ON TEST SET")
    print("="*80)
    
    results = []
    
    for name, model_dict in all_models.items():
        model = model_dict['model']
        
        # Predictions
        y_pred = model.predict(X_test)
        y_prob = model.predict_proba(X_test)[:, 1]
        
        # Metrics
        metrics = {
            'Model': name,
            'Accuracy': accuracy_score(y_test, y_pred),
            'Precision': precision_score(y_test, y_pred, zero_division=0),
            'Recall': recall_score(y_test, y_pred, zero_division=0),
            'F1': f1_score(y_test, y_pred, zero_division=0),
            'ROC-AUC': roc_auc_score(y_test, y_prob),
            'CV_F1': model_dict.get('cv_score', 0),
        }
        results.append(metrics)
        
        # Print
        print(f"\n{'─'*80}")
        print(f"📊 {name}")
        print(f"{'─'*80}")
        print(f"   Accuracy:  {metrics['Accuracy']:.4f}")
        print(f"   Precision: {metrics['Precision']:.4f}")
        print(f"   Recall:    {metrics['Recall']:.4f}")
        print(f"   F1-Score:  {metrics['F1']:.4f}")
        print(f"   ROC-AUC:   {metrics['ROC-AUC']:.4f}")
        print(f"   CV F1:     {metrics['CV_F1']:.4f}")
        
        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        print(f"\n   Confusion Matrix:")
        print(f"                Pred-Grad  Pred-Drop")
        print(f"   Actual-Grad  {cm[0,0]:7,}   {cm[0,1]:7,}")
        print(f"   Actual-Drop  {cm[1,0]:7,}   {cm[1,1]:7,}")
    
    # Summary table
    df_results = pd.DataFrame(results)
    df_results = df_results.sort_values('F1', ascending=False)
    
    print("\n" + "="*80)
    print(" PERFORMANCE COMPARISON")
    print("="*80)
    print(df_results.to_string(index=False))
    
    return df_results


# ============================================================================
# SAVE BEST MODEL
# ============================================================================

def save_best_models(all_models, scaler, feature_names, results_df):
    """Save the top-3 models"""
    print("\n" + "="*80)
    print(" SAVING BEST MODELS")
    print("="*80)
    
    os.makedirs(Config.MODEL_DIR, exist_ok=True)
    
    # Sort by F1 score
    top_3 = results_df.nlargest(3, 'F1')
    
    for idx, row in top_3.iterrows():
        model_name = row['Model']
        model = all_models[model_name]['model']
        
        # Save model
        safe_name = model_name.lower().replace(' ', '_')
        model_path = os.path.join(Config.MODEL_DIR, f'{safe_name}_model.pkl')
        joblib.dump(model, model_path)
        print(f"✅ Saved: {safe_name}_model.pkl (F1={row['F1']:.4f})")
    
    # Save scaler and metadata
    joblib.dump(scaler, os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(feature_names, os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    
    metadata = {
        'best_model': top_3.iloc[0]['Model'],
        'performance': results_df.to_dict('records'),
        'features': feature_names,
        'tuning_methods': {
            'grid_search': Config.RUN_GRID_SEARCH,
            'random_search': Config.RUN_RANDOM_SEARCH,
            'optuna': Config.RUN_OPTUNA,
            'ensemble': Config.RUN_ENSEMBLE,
        }
    }
    joblib.dump(metadata, os.path.join(Config.MODEL_DIR, 'model_metadata.pkl'))
    
    print(f"\n✅ Saved scaler, feature_columns, and metadata")
    print(f"\n🏆 BEST MODEL: {metadata['best_model']}")
    print(f"   F1-Score: {top_3.iloc[0]['F1']:.4f}")
    print(f"   Accuracy: {top_3.iloc[0]['Accuracy']:.4f}")
    print(f"   ROC-AUC:  {top_3.iloc[0]['ROC-AUC']:.4f}")


# ============================================================================
# MAIN PIPELINE
# ============================================================================

def main():
    print("\n" + "="*80)
    print(" 🎯 HYPERPARAMETER TUNING PIPELINE")
    print("="*80)
    print(f"\n⚙️  Configuration:")
    print(f"   Grid Search:      {'✅' if Config.RUN_GRID_SEARCH else '❌'}")
    print(f"   Random Search:    {'✅' if Config.RUN_RANDOM_SEARCH else '❌'}")
    print(f"   Optuna (Bayesian):{'✅' if Config.RUN_OPTUNA else '❌'}")
    print(f"   Ensemble:         {'✅' if Config.RUN_ENSEMBLE else '❌'}")
    print(f"   CV Folds:         {Config.CV_FOLDS}")
    print(f"   Random State:     {Config.RANDOM_STATE}")
    
    # Load data
    X, y, feature_names = load_and_prepare_data()
    X_train, X_test, y_train, y_test, scaler = prepare_train_test(X, y)
    
    # Store all models
    all_models = {}
    
    # Method 1: Grid Search
    if Config.RUN_GRID_SEARCH:
        grid_results = run_grid_search(X_train, y_train)
        all_models.update({f"Grid_{k}": v for k, v in grid_results.items()})
    
    # Method 2: Random Search
    if Config.RUN_RANDOM_SEARCH:
        random_results = run_random_search(X_train, y_train)
        all_models.update({f"Random_{k}": v for k, v in random_results.items()})
    
    # Method 3: Optuna
    if Config.RUN_OPTUNA:
        optuna_results = run_optuna_tuning(X_train, y_train)
        all_models.update({f"Optuna_{k}": v for k, v in optuna_results.items()})
    
    # Method 4: Ensemble (use best models from previous steps)
    if Config.RUN_ENSEMBLE and all_models:
        # Pick best RF and GB from all methods
        best_models = {}
        for name, model_dict in all_models.items():
            base_name = name.split('_', 1)[1] if '_' in name else name
            if base_name not in best_models or model_dict['cv_score'] > best_models[base_name]['cv_score']:
                best_models[base_name] = model_dict
        
        ensemble_results = create_ensemble(best_models, X_train, y_train)
        all_models.update(ensemble_results)
    
    # Evaluate all
    results_df = evaluate_all_models(all_models, X_test, y_test)
    
    # Save best
    save_best_models(all_models, scaler, feature_names, results_df)
    
    print("\n" + "="*80)
    print(" ✅ TUNING COMPLETE!")
    print("="*80)
    print(f"\n📁 Models saved to: {Config.MODEL_DIR}/")
    print(f"   Use the best model in your Flask API for production.")


if __name__ == '__main__':
    main()