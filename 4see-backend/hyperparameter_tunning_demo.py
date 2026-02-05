"""
QUICK DEMO: Hyperparameter Tuning (5-10 minutes)
=================================================

Reduced-iteration version for quick demonstration.
Shows the process without waiting hours.

For production, use: hyperparameter_tuning.py (full version)
"""

import pandas as pd
import numpy as np
import sys
import warnings

# Import from the full version but override config
sys.path.insert(0, '.')
warnings.filterwarnings('ignore')

from hyperparameter_tunning import (
    load_and_prepare_data, prepare_train_test,
    run_random_search, evaluate_all_models,
    save_best_models, Config
)

# ============================================================================
# DEMO CONFIGURATION (much faster)
# ============================================================================

class DemoConfig:
    """Overrides for quick demo"""
    DATA_DIR = './data'
    MODEL_DIR = './models_demo'
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 3              # Reduced from 5
    
    # Only run Random Search (fastest method)
    RUN_GRID_SEARCH = False
    RUN_RANDOM_SEARCH = True
    RUN_OPTUNA = False        # Would add 30+ min
    RUN_ENSEMBLE = True       # Quick, uses existing models
    
    # Reduced iterations
    N_ITER_RANDOM = 10        # Reduced from 50 (10× faster)
    N_TRIALS_OPTUNA = 0       # Skip


# Monkey-patch Config
Config.DATA_DIR = DemoConfig.DATA_DIR
Config.MODEL_DIR = DemoConfig.MODEL_DIR
Config.RANDOM_STATE = DemoConfig.RANDOM_STATE
Config.TEST_SIZE = DemoConfig.TEST_SIZE
Config.CV_FOLDS = DemoConfig.CV_FOLDS
Config.RUN_GRID_SEARCH = DemoConfig.RUN_GRID_SEARCH
Config.RUN_RANDOM_SEARCH = DemoConfig.RUN_RANDOM_SEARCH
Config.RUN_OPTUNA = DemoConfig.RUN_OPTUNA
Config.RUN_ENSEMBLE = DemoConfig.RUN_ENSEMBLE
Config.N_ITER_RANDOM = DemoConfig.N_ITER_RANDOM


# ============================================================================
# SIMPLIFIED ENSEMBLE (faster)
# ============================================================================

def create_quick_ensemble(base_models, X_train, y_train):
    """Quick voting ensemble only (no stacking)"""
    from sklearn.ensemble import VotingClassifier
    from sklearn.model_selection import StratifiedKFold, cross_val_score
    import time
    
    print("\n" + "="*80)
    print(" ENSEMBLE: VOTING CLASSIFIER (Quick)")
    print("="*80)
    
    models_list = [(name, model['model']) for name, model in base_models.items()]
    
    print("\n🗳️  Voting Ensemble (soft voting)...")
    start = time.time()
    voting = VotingClassifier(estimators=models_list, voting='soft', n_jobs=-1)
    voting.fit(X_train, y_train)
    
    cv = StratifiedKFold(n_splits=Config.CV_FOLDS, shuffle=True, 
                         random_state=Config.RANDOM_STATE)
    voting_score = cross_val_score(voting, X_train, y_train, cv=cv, 
                                   scoring='f1', n_jobs=-1).mean()
    
    result = {
        'model': voting,
        'cv_score': voting_score,
        'time': time.time() - start
    }
    print(f"   CV F1: {voting_score:.4f}")
    print(f"   Time: {result['time']:.1f}s")
    
    return {'VotingEnsemble': result}


# ============================================================================
# DEMO MAIN
# ============================================================================

def main():
    print("\n" + "="*80)
    print(" 🚀 QUICK DEMO: HYPERPARAMETER TUNING")
    print("="*80)
    print("\n⚡ DEMO MODE:")
    print("   - RandomSearch only (10 iterations vs 50)")
    print("   - 3-fold CV (vs 5-fold)")
    print("   - No Grid/Optuna (saves 90% of time)")
    print("   - Estimated time: 5-10 minutes\n")
    print("   For FULL tuning, run: python hyperparameter_tuning.py")
    print("="*80)
    
    # Load data
    print("\n📊 Loading data...")
    X, y, feature_names = load_and_prepare_data()
    X_train, X_test, y_train, y_test, scaler = prepare_train_test(X, y)
    
    # Store models
    all_models = {}
    
    # Random Search only
    print("\n🎲 Running RandomizedSearchCV (10 iterations per model)...")
    random_results = run_random_search(X_train, y_train)
    all_models.update({f"Random_{k}": v for k, v in random_results.items()})
    
    # Quick ensemble
    print("\n🔗 Creating ensemble...")
    ensemble_results = create_quick_ensemble(random_results, X_train, y_train)
    all_models.update(ensemble_results)
    
    # Evaluate
    results_df = evaluate_all_models(all_models, X_test, y_test)
    
    # Save
    save_best_models(all_models, scaler, feature_names, results_df)
    
    print("\n" + "="*80)
    print(" ✅ DEMO COMPLETE!")
    print("="*80)
    print(f"\n📊 COMPARISON WITH BASELINE:")
    print(f"   Baseline (no tuning):  ~87.3% accuracy, ~78.0% F1")
    print(f"   After demo tuning:     ~{results_df.iloc[0]['Accuracy']*100:.1f}% accuracy, "
          f"~{results_df.iloc[0]['F1']*100:.1f}% F1")
    print(f"\n   Improvement: +{(results_df.iloc[0]['Accuracy']-0.873)*100:.1f}% accuracy")
    print(f"\n💡 TIP: For even better results (2-5% more improvement):")
    print(f"   Run the full version: python hyperparameter_tuning.py")
    print(f"   - Optuna Bayesian optimization (smartest search)")
    print(f"   - More iterations (50-100 per model)")
    print(f"   - Stacking ensemble (final polish)")


if __name__ == '__main__':
    main()