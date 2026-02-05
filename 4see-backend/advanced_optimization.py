"""
ADVANCED MODEL OPTIMIZATION - Breaking the 88% Accuracy Ceiling
================================================================

Your hyperparameter tuning got you to 87-88% accuracy.
To go higher, we need to address the REAL bottlenecks:

1. Feature Engineering     - Create better predictive features
2. Feature Selection       - Remove noise, keep signal
3. Class Weight Tuning     - Handle 30% dropout imbalance better
4. Threshold Optimization  - Optimize decision boundary
5. Advanced Ensembles      - Weighted voting, neural meta-learner
6. Data Quality            - Fix inconsistencies, add domain features

Expected improvement: +2-4% (88% → 90-92%)
"""

import pandas as pd
import numpy as np
import warnings
import joblib
import os
from pathlib import Path

from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier,
    VotingClassifier, StackingClassifier, ExtraTreesClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, roc_curve, classification_report, confusion_matrix
)
from sklearn.feature_selection import (
    SelectKBest, f_classif, RFE, RFECV,
    mutual_info_classif, SelectFromModel
)

warnings.filterwarnings('ignore')

# Try importing advanced libraries
try:
    import xgboost as xgb
    HAS_XGB = True
except ImportError:
    HAS_XGB = False

try:
    import lightgbm as lgb
    HAS_LGB = True
except ImportError:
    HAS_LGB = False


# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    DATA_DIR = './data'
    MODEL_DIR = './models_advanced'
    RANDOM_STATE = 42
    TEST_SIZE = 0.2
    CV_FOLDS = 5


# ============================================================================
# ADVANCED FEATURE ENGINEERING
# ============================================================================


def create_advanced_features(df):
    """
    Create domain-specific interaction features that capture complex patterns
    """
    print("\n" + "="*80)
    print(" ADVANCED FEATURE ENGINEERING")
    print("="*80)
    
    df = df.copy()
    original_count = len([c for c in df.columns if c != 'target'])

    df['grade_avg_all'] = df[['G1', 'G2', 'G3']].mean(axis=1)
    
    # ── 1. ACADEMIC TRAJECTORY FEATURES ──────────────────────────────────
    print("\n📚 Creating academic trajectory features...")
    
    # Grade velocity (acceleration/deceleration)
    df['grade_velocity_early'] = df['G2'] - df['G1']
    df['grade_velocity_late'] = df['G3'] - df['G2']
    df['grade_acceleration'] = df['grade_velocity_late'] - df['grade_velocity_early']
    
    # Momentum indicators
    df['improving_trend'] = ((df['G2'] > df['G1']) & (df['G3'] > df['G2'])).astype(int)
    df['declining_trend'] = ((df['G2'] < df['G1']) & (df['G3'] < df['G2'])).astype(int)
    df['unstable_grades'] = (abs(df['G2'] - df['G1']) + abs(df['G3'] - df['G2']) > 8).astype(int)
    
    # Performance consistency
    df['grade_std'] = df[['G1', 'G2', 'G3']].std(axis=1)
    df['grade_cv'] = df['grade_std'] / (df[['G1', 'G2', 'G3']].mean(axis=1) + 1e-6)  # Coefficient of variation
    
    # Critical thresholds
    df['any_failing_grade'] = ((df['G1'] < 10) | (df['G2'] < 10) | (df['G3'] < 10)).astype(int)
    df['all_passing_grades'] = ((df['G1'] >= 10) & (df['G2'] >= 10) & (df['G3'] >= 10)).astype(int)
    df['critical_final_grade'] = (df['G3'] < 8).astype(int)
    
    # ── 2. ATTENDANCE PATTERN FEATURES ───────────────────────────────────
    print("📅 Creating attendance pattern features...")
    
    # Absence severity levels
    df['absence_severity'] = pd.cut(
        df['absences'],
        bins=[-1, 5, 10, 20, float('inf')],
        labels=[0, 1, 2, 3],
        include_lowest=True
    )

    df['absence_severity'] = (
        df['absence_severity']
        .cat.add_categories([-1])
        .fillna(-1)
        .astype(int)
    )

    
    # Interaction: absences hurt low performers more
    df['absence_academic_risk'] = df['absences'] * (20 - df['grade_avg_all'])
    df['absence_per_grade_point'] = df['absences'] / (df['grade_avg_all'] + 1)
    
    # ── 3. BEHAVIORAL & SOCIAL FEATURES ──────────────────────────────────
    print("👥 Creating behavioral interaction features...")
    
    # Multi-factor risk
    df['triple_risk'] = ((df['failures'] > 0) & 
                         (df['absences'] > 10) & 
                         (df['grade_avg_all'] < 10)).astype(int)
    
    # Support deficit
    df['total_support'] = df['schoolsup'] + df['famsup'] + df['Scholarship holder']
    df['no_support_high_risk'] = ((df['total_support'] == 0) & 
                                   (df['grade_avg_all'] < 10)).astype(int)
    
    # Study effectiveness (interaction)
    df['study_grade_ratio'] = df['grade_avg_all'] / (df['studytime'] + 1)
    df['low_effort_low_result'] = ((df['studytime'] < 2) & 
                                    (df['grade_avg_all'] < 10)).astype(int)
    
    # Social health composite
    df['social_isolation_score'] = (5 - df['famrel']) + (5 - df['health'])
    df['isolated_struggling'] = ((df['famrel'] <= 2) & (df['grade_avg_all'] < 10)).astype(int)
    
    # ── 4. FINANCIAL STRESS INDICATORS ───────────────────────────────────
    print("💰 Creating financial stress features...")
    
    # Financial burden score
    df['financial_burden'] = df['Debtor'] + (1 - df['Tuition fees up to date'])
    df['financial_academic_stress'] = df['financial_burden'] * (20 - df['grade_avg_all'])
    
    # Economic disadvantage composite
    df['economic_disadvantage'] = (
        (df['Scholarship holder'] == 0) & 
        (df['Debtor'] == 1) & 
        (df['Tuition fees up to date'] == 0)
    ).astype(int)
    
    # ── 5. DEMOGRAPHIC RISK FACTORS ──────────────────────────────────────
    print("👤 Creating demographic interaction features...")
    
    # Age-related risk (older students in primary dropout more)
    df['age_risk'] = (df['age'] > 25).astype(int)
    df['age_academic_interaction'] = df['age'] * (20 - df['grade_avg_all']) / 100
    
    # Parent occupation strength (higher Mjob/Fjob = better support)
    df['parent_support_strength'] = (df['Mjob'] + df['Fjob']) / 10
    df['parent_occupation_sum'] = df['Mjob'] + df['Fjob']
    df['weak_parent_support'] = (df['parent_occupation_sum'] < 4).astype(int)

    
    # ── 6. COURSE-SPECIFIC RISK ──────────────────────────────────────────
    print("🎓 Creating course difficulty interactions...")
    
    # Course difficulty proxy (some courses have higher dropout rates)
    # This will be learned from data during training
    df['course_grade_interaction'] = df['Course'] * df['grade_avg_all'] / 10000
    
    # ── 7. CRITICAL COMBINATIONS ─────────────────────────────────────────
    print("⚠️  Creating critical risk combinations...")
    
    # The "perfect storm" features
    df['catastrophic_risk'] = (
        (df['grade_avg_all'] < 8) &
        (df['absences'] > 20) &
        (df['failures'] >= 2) &
        (df['total_support'] == 0)
    ).astype(int)
    
    df['early_warning_cluster'] = (
        (df['G1'] < 10) &
        (df['absences'] > 10) &
        (df['studytime'] < 2)
    ).astype(int)
    
    new_count = len([c for c in df.columns if c != 'target']) - original_count
    print(f"\n✅ Created {new_count} advanced features")
    print(f"   Total features now: {len([c for c in df.columns if c != 'target'])}")
    
    return df


# ============================================================================
# FEATURE SELECTION WITH MULTIPLE METHODS
# ============================================================================

def advanced_feature_selection(X_train, y_train, X_test, n_features=45):
    """
    Use multiple feature selection methods and combine results
    """
    print("\n" + "="*80)
    print(" ADVANCED FEATURE SELECTION")
    print("="*80)
    
    feature_scores = {}
    feature_names = X_train.columns.tolist()
    
    # ── Method 1: Mutual Information ─────────────────────────────────────
    print("\n1️⃣  Mutual Information (non-linear dependencies)...")
    mi_scores = mutual_info_classif(X_train, y_train, random_state=Config.RANDOM_STATE)
    mi_ranks = pd.Series(mi_scores, index=feature_names).sort_values(ascending=False)
    feature_scores['mi'] = mi_ranks
    print(f"   Top-5: {mi_ranks.head().to_dict()}")
    
    # ── Method 2: Random Forest Importance ───────────────────────────────
    print("\n2️⃣  Random Forest Feature Importance...")
    rf_selector = RandomForestClassifier(
        n_estimators=200, max_depth=15, 
        random_state=Config.RANDOM_STATE, n_jobs=-1
    )
    rf_selector.fit(X_train, y_train)
    rf_ranks = pd.Series(rf_selector.feature_importances_, index=feature_names).sort_values(ascending=False)
    feature_scores['rf'] = rf_ranks
    print(f"   Top-5: {rf_ranks.head().to_dict()}")
    
    # ── Method 3: L1 Regularization (Lasso) ──────────────────────────────
    print("\n3️⃣  L1 Regularization (Lasso)...")
    from sklearn.linear_model import LassoCV
    lasso = LassoCV(cv=5, random_state=Config.RANDOM_STATE, n_jobs=-1)
    lasso.fit(X_train, y_train)
    lasso_ranks = pd.Series(np.abs(lasso.coef_), index=feature_names).sort_values(ascending=False)
    feature_scores['lasso'] = lasso_ranks
    print(f"   Top-5: {lasso_ranks.head().to_dict()}")
    
    # ── Method 4: Recursive Feature Elimination ──────────────────────────
    if HAS_XGB:
        print("\n4️⃣  RFE with XGBoost...")
        xgb_model = xgb.XGBClassifier(n_estimators=100, random_state=Config.RANDOM_STATE)
        rfe = RFE(estimator=xgb_model, n_features_to_select=n_features, step=5)
        rfe.fit(X_train, y_train)
        rfe_selected = [feature_names[i] for i, selected in enumerate(rfe.support_) if selected]
        print(f"   Selected {len(rfe_selected)} features")
    
    # ── Combine Rankings (Borda Count) ───────────────────────────────────
    print("\n🔗 Combining rankings with Borda count...")
    combined_scores = pd.Series(0.0, index=feature_names)
    
    for method, ranks in feature_scores.items():
        # Convert ranks to scores (higher rank = higher score)
        normalized = (ranks - ranks.min()) / (ranks.max() - ranks.min() + 1e-6)
        combined_scores += normalized
    
    combined_scores = combined_scores.sort_values(ascending=False)
    
    # Select top N features
    selected_features = combined_scores.head(n_features).index.tolist()
    
    print(f"\n✅ Selected {n_features} best features:")
    print(f"   Top-10: {selected_features[:10]}")
    
    # Filter datasets
    X_train_selected = X_train[selected_features]
    X_test_selected = X_test[selected_features]
    
    return X_train_selected, X_test_selected, selected_features, combined_scores


# ============================================================================
# OPTIMAL THRESHOLD FINDING
# ============================================================================

def find_optimal_threshold(model, X_val, y_val, metric='f1'):
    """
    Find the probability threshold that maximizes the chosen metric
    Default 0.5 is often not optimal!
    """
    print("\n" + "="*80)
    print(" THRESHOLD OPTIMIZATION")
    print("="*80)
    
    y_prob = model.predict_proba(X_val)[:, 1]
    
    thresholds = np.arange(0.1, 0.9, 0.01)
    scores = []
    
    for threshold in thresholds:
        y_pred = (y_prob >= threshold).astype(int)
        
        if metric == 'f1':
            score = f1_score(y_val, y_pred, zero_division=0)
        elif metric == 'accuracy':
            score = accuracy_score(y_val, y_pred)
        elif metric == 'recall':
            score = recall_score(y_val, y_pred, zero_division=0)
        else:
            score = precision_score(y_val, y_pred, zero_division=0)
        
        scores.append(score)
    
    best_idx = np.argmax(scores)
    best_threshold = thresholds[best_idx]
    best_score = scores[best_idx]
    
    print(f"\n📊 Optimizing for: {metric.upper()}")
    print(f"   Default threshold (0.5): {metric} = {scores[40]:.4f}")
    print(f"   Optimal threshold ({best_threshold:.2f}): {metric} = {best_score:.4f}")
    print(f"   Improvement: +{(best_score - scores[40])*100:.2f}%")
    
    return best_threshold


# ============================================================================
# CLASS WEIGHT OPTIMIZATION
# ============================================================================

def optimize_class_weights(X_train, y_train, X_val, y_val):
    """
    Fine-tune class weights beyond just 'balanced'
    """
    print("\n" + "="*80)
    print(" CLASS WEIGHT OPTIMIZATION")
    print("="*80)
    
    # Try different class weight ratios
    dropout_count = y_train.sum()
    graduate_count = len(y_train) - dropout_count
    base_ratio = graduate_count / dropout_count
    
    print(f"\n📊 Class distribution:")
    print(f"   Graduates: {graduate_count} ({graduate_count/len(y_train)*100:.1f}%)")
    print(f"   Dropouts:  {dropout_count} ({dropout_count/len(y_train)*100:.1f}%)")
    print(f"   Base ratio: 1:{base_ratio:.2f}")
    
    # Test multiple weight configurations
    weight_configs = [
        None,                                          # No weighting
        'balanced',                                    # Sklearn auto
        {0: 1.0, 1: base_ratio},                      # Inverse proportion
        {0: 1.0, 1: base_ratio * 0.8},                # Slightly less
        {0: 1.0, 1: base_ratio * 1.2},                # Slightly more
        {0: 1.0, 1: base_ratio * 1.5},                # More aggressive
        {0: 1.0, 1: 3.0},                             # Fixed 3x
        {0: 1.0, 1: 4.0},                             # Fixed 4x
    ]
    
    results = []
    
    print("\n🔍 Testing weight configurations...")
    for i, weights in enumerate(weight_configs):
        rf = RandomForestClassifier(
            n_estimators=200, max_depth=20,
            class_weight=weights,
            random_state=Config.RANDOM_STATE, n_jobs=-1
        )
        rf.fit(X_train, y_train)
        y_pred = rf.predict(X_val)
        
        f1 = f1_score(y_val, y_pred, zero_division=0)
        recall = recall_score(y_val, y_pred, zero_division=0)
        precision = precision_score(y_val, y_pred, zero_division=0)
        
        results.append({
            'weights': str(weights),
            'f1': f1,
            'recall': recall,
            'precision': precision
        })
    
    df_results = pd.DataFrame(results).sort_values('f1', ascending=False)
    print("\n" + df_results.to_string(index=False))
    
    best_weights = eval(df_results.iloc[0]['weights'])
    print(f"\n✅ Best class weights: {best_weights}")
    
    return best_weights


# ============================================================================
# ADVANCED ENSEMBLE
# ============================================================================

def create_advanced_ensemble(X_train, y_train, best_weights, selected_features):
    """
    Create a sophisticated ensemble with diverse models
    """
    print("\n" + "="*80)
    print(" ADVANCED ENSEMBLE CREATION")
    print("="*80)
    
    models = []
    
    # Model 1: RandomForest (optimized)
    print("\n1️⃣  RandomForest (depth=25, trees=400)...")
    rf = RandomForestClassifier(
        n_estimators=400, max_depth=25, min_samples_split=8,
        min_samples_leaf=3, max_features='sqrt',
        class_weight=best_weights, random_state=Config.RANDOM_STATE, n_jobs=-1
    )
    models.append(('rf', rf))
    
    # Model 2: ExtraTrees (more randomness)
    print("2️⃣  ExtraTrees (extra randomization)...")
    et = ExtraTreesClassifier(
        n_estimators=400, max_depth=25, min_samples_split=8,
        class_weight=best_weights, random_state=Config.RANDOM_STATE, n_jobs=-1
    )
    models.append(('et', et))
    
    # Model 3: GradientBoosting (sequential learning)
    print("3️⃣  GradientBoosting (lr=0.05, depth=6)...")
    gb = GradientBoostingClassifier(
        n_estimators=300, learning_rate=0.05, max_depth=6,
        subsample=0.8, random_state=Config.RANDOM_STATE
    )
    models.append(('gb', gb))
    
    # Model 4: XGBoost (if available)
    if HAS_XGB:
        print("4️⃣  XGBoost (scale_pos_weight tuned)...")
        scale_pos_weight = (len(y_train) - y_train.sum()) / y_train.sum()
        xgb_model = xgb.XGBClassifier(
            n_estimators=300, learning_rate=0.05, max_depth=6,
            scale_pos_weight=scale_pos_weight * 1.2,
            colsample_bytree=0.8, subsample=0.8,
            random_state=Config.RANDOM_STATE
        )
        models.append(('xgb', xgb_model))
    
    # Model 5: LightGBM (if available)
    if HAS_LGB:
        print("5️⃣  LightGBM (fast boosting)...")
        lgb_model = lgb.LGBMClassifier(
            n_estimators=300, learning_rate=0.05, max_depth=6,
            class_weight=best_weights,
            random_state=Config.RANDOM_STATE, n_jobs=-1, verbose=-1
        )
        models.append(('lgb', lgb_model))
    
    # Create weighted voting ensemble
    print("\n🗳️  Creating Weighted Voting Ensemble...")
    voting = VotingClassifier(
        estimators=models,
        voting='soft',  # Use probability averaging
        weights=[1.2, 1.0, 1.3, 1.5, 1.4][:len(models)],  # XGB/LGB get more weight
        n_jobs=-1
    )
    
    print(f"   Ensemble size: {len(models)} models")
    return voting, models


# ============================================================================
# MAIN OPTIMIZATION PIPELINE
# ============================================================================

def main():
    print("\n" + "="*80)
    print(" 🚀 ADVANCED MODEL OPTIMIZATION")
    print("="*80)
    print("\nGoing beyond hyperparameter tuning to break the 88% ceiling...")
    
    # Load data (reuse train_model.py pipeline)
    import sys
    sys.path.insert(0, '.')
    from train_model import find_and_load_data, create_target_variable, Config as TrainConfig
    
    df = find_and_load_data(TrainConfig.DATA_DIR)
    df = create_target_variable(df)
    
    # Apply ADVANCED feature engineering
    df = create_advanced_features(df)
    
    # Prepare train/test split
    feature_cols = [c for c in df.columns if c not in ['target', 'Target']]
    X = df[feature_cols]
    y = df['target']
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=Config.TEST_SIZE,
        random_state=Config.RANDOM_STATE, stratify=y
    )
    
    # Further split train into train/val for threshold optimization
    X_train, X_val, y_train, y_val = train_test_split(
        X_train, y_train, test_size=0.2,
        random_state=Config.RANDOM_STATE, stratify=y_train
    )
    
    print(f"\n📊 Data splits:")
    print(f"   Train: {len(X_train)}")
    print(f"   Val:   {len(X_val)}")
    print(f"   Test:  {len(X_test)}")
    
    # Keep raw for trees
    X_train_raw = X_train.copy()
    X_val_raw = X_val.copy()
    X_test_raw = X_test.copy()

    # Scaled copy ONLY for feature selection (Lasso, MI)
    scaler = StandardScaler()
    X_train_scaled = pd.DataFrame(
        scaler.fit_transform(X_train_raw),
        columns=X_train_raw.columns,
        index=X_train_raw.index
    )
    X_val_scaled = pd.DataFrame(
        scaler.transform(X_val_raw),
        columns=X_val_raw.columns,
        index=X_val_raw.index
    )
    X_test_scaled = pd.DataFrame(
        scaler.transform(X_test_raw),
        columns=X_test_raw.columns,
        index=X_test_raw.index
    )
    
    # ── Feature selection happens on SCALED data ─────────────────────
    _, _, selected_features, feature_scores = advanced_feature_selection(
        X_train_scaled, y_train, X_test_scaled, n_features=50
    )

    # ── But we use RAW data for models (trees hate scaling) ──────────
    X_train_selected = X_train_raw[selected_features]
    X_val_selected   = X_val_raw[selected_features]
    X_test_selected  = X_test_raw[selected_features]

    
    # Optimize class weights
    best_weights = optimize_class_weights(
        X_train_selected, y_train, X_val_selected, y_val
    )
    
    # Create advanced ensemble
    ensemble, base_models = create_advanced_ensemble(
        X_train_selected, y_train, best_weights, selected_features
    )
    
    print("\n🏋️  Training ensemble...")
    ensemble.fit(X_train_selected, y_train)
    
    # Find optimal threshold
    optimal_threshold = find_optimal_threshold(
        ensemble, X_val_selected, y_val, metric='f1'
    )
    
    # Final evaluation on test set
    print("\n" + "="*80)
    print(" FINAL EVALUATION")
    print("="*80)
    
    y_prob_test = ensemble.predict_proba(X_test_selected)[:, 1]
    
    # Predictions with default threshold (0.5)
    y_pred_default = ensemble.predict(X_test_selected)
    
    # Predictions with optimized threshold
    y_pred_optimized = (y_prob_test >= optimal_threshold).astype(int)
    
    # Compare
    print("\n📊 DEFAULT THRESHOLD (0.5):")
    print(f"   Accuracy:  {accuracy_score(y_test, y_pred_default):.4f}")
    print(f"   Precision: {precision_score(y_test, y_pred_default, zero_division=0):.4f}")
    print(f"   Recall:    {recall_score(y_test, y_pred_default, zero_division=0):.4f}")
    print(f"   F1-Score:  {f1_score(y_test, y_pred_default, zero_division=0):.4f}")
    print(f"   ROC-AUC:   {roc_auc_score(y_test, y_prob_test):.4f}")
    
    print(f"\n📊 OPTIMIZED THRESHOLD ({optimal_threshold:.2f}):")
    acc_opt = accuracy_score(y_test, y_pred_optimized)
    prec_opt = precision_score(y_test, y_pred_optimized, zero_division=0)
    rec_opt = recall_score(y_test, y_pred_optimized, zero_division=0)
    f1_opt = f1_score(y_test, y_pred_optimized, zero_division=0)
    
    print(f"   Accuracy:  {acc_opt:.4f}  (+{(acc_opt - accuracy_score(y_test, y_pred_default))*100:+.2f}%)")
    print(f"   Precision: {prec_opt:.4f}")
    print(f"   Recall:    {rec_opt:.4f}  (+{(rec_opt - recall_score(y_test, y_pred_default, zero_division=0))*100:+.2f}%)")
    print(f"   F1-Score:  {f1_opt:.4f}  (+{(f1_opt - f1_score(y_test, y_pred_default, zero_division=0))*100:+.2f}%)")
    print(f"   ROC-AUC:   {roc_auc_score(y_test, y_prob_test):.4f}")
    
    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred_optimized)
    print(f"\n   Confusion Matrix:")
    print(f"                Pred-Grad  Pred-Drop")
    print(f"   Actual-Grad  {cm[0,0]:7,}   {cm[0,1]:7,}")
    print(f"   Actual-Drop  {cm[1,0]:7,}   {cm[1,1]:7,}")
    
    # Save models
    os.makedirs(Config.MODEL_DIR, exist_ok=True)
    
    joblib.dump(ensemble, os.path.join(Config.MODEL_DIR, 'advanced_ensemble.pkl'))
    joblib.dump(scaler, os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(selected_features, os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    joblib.dump({
        'threshold': optimal_threshold,
        'class_weights': best_weights,
        'feature_scores': feature_scores,
        'base_models': [name for name, _ in base_models]
    }, os.path.join(Config.MODEL_DIR, 'model_metadata.pkl'))
    
    print(f"\n✅ Models saved to {Config.MODEL_DIR}/")
    print("\n" + "="*80)
    print(" 🎯 OPTIMIZATION COMPLETE!")
    print("="*80)
    print(f"\n🏆 FINAL RESULTS:")
    print(f"   Accuracy:  {acc_opt*100:.2f}%")
    print(f"   F1-Score:  {f1_opt*100:.2f}%")
    print(f"   Recall:    {rec_opt*100:.2f}% (catching at-risk students)")


if __name__ == '__main__':
    main()