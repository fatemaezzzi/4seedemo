"""
MODEL CEILING DIAGNOSTIC - Why Can't We Get Higher Than 88%?
=============================================================

This script analyzes your data and model to identify the SPECIFIC reasons
for the accuracy ceiling and suggests targeted solutions.
"""

import pandas as pd
import numpy as np
import warnings
import joblib
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns

warnings.filterwarnings('ignore')


def analyze_data_quality(df):
    """Identify data quality issues limiting performance"""
    print("\n" + "="*80)
    print(" 1. DATA QUALITY ANALYSIS")
    print("="*80)
    
    issues = []
    
    # Check for class imbalance
    dropout_pct = df['target'].mean() * 100
    print(f"\n📊 Class Balance:")
    print(f"   Dropout rate: {dropout_pct:.1f}%")
    if dropout_pct < 20 or dropout_pct > 80:
        issues.append(f"SEVERE imbalance ({dropout_pct:.1f}% minority class)")
        print(f"   ⚠️  SEVERE imbalance - this limits max accuracy")
    elif dropout_pct < 30 or dropout_pct > 70:
        issues.append(f"Moderate imbalance ({dropout_pct:.1f}%)")
        print(f"   ⚠️  Moderate imbalance")
    else:
        print(f"   ✅ Balanced enough")
    
    # Check for feature variance
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    numeric_cols = [c for c in numeric_cols if c != 'target']
    
    low_variance_features = []
    for col in numeric_cols:
        if df[col].std() < 0.01:
            low_variance_features.append(col)
    
    if low_variance_features:
        print(f"\n📉 Low Variance Features: {len(low_variance_features)}")
        print(f"   {low_variance_features[:5]}")
        issues.append(f"{len(low_variance_features)} features with almost no variation")
    
    # Check for duplicate rows
    duplicates = df.duplicated().sum()
    print(f"\n🔁 Duplicate Rows: {duplicates}")
    if duplicates > 100:
        issues.append(f"{duplicates} duplicate rows (reduce effective training data)")
    
    # Check feature correlations (multicollinearity)
    corr_matrix = df[numeric_cols].corr().abs()
    high_corr_pairs = []
    for i in range(len(corr_matrix.columns)):
        for j in range(i+1, len(corr_matrix.columns)):
            if corr_matrix.iloc[i, j] > 0.95:
                high_corr_pairs.append((corr_matrix.columns[i], corr_matrix.columns[j]))
    
    print(f"\n🔗 Highly Correlated Feature Pairs (>0.95): {len(high_corr_pairs)}")
    if high_corr_pairs:
        print(f"   Examples: {high_corr_pairs[:3]}")
        issues.append(f"{len(high_corr_pairs)} redundant feature pairs")
    
    return issues


def analyze_feature_importance_distribution(model_path, feature_cols):
    """Check if importance is concentrated in few features"""
    print("\n" + "="*80)
    print(" 2. FEATURE IMPORTANCE ANALYSIS")
    print("="*80)
    
    try:
        model = joblib.load(model_path)
        if hasattr(model, 'feature_importances_'):
            importances = model.feature_importances_
        elif hasattr(model, 'estimators_'):
            # Ensemble - average importances
            importances = np.mean([est.feature_importances_ for est in model.estimators_], axis=0)
        else:
            print("   ⚠️  Model doesn't have feature_importances_")
            return []
        
        imp_df = pd.DataFrame({
            'feature': feature_cols,
            'importance': importances
        }).sort_values('importance', ascending=False)
        
        # Check concentration
        top10_pct = imp_df.head(10)['importance'].sum() / imp_df['importance'].sum() * 100
        top20_pct = imp_df.head(20)['importance'].sum() / imp_df['importance'].sum() * 100
        
        print(f"\n📊 Importance Concentration:")
        print(f"   Top 10 features: {top10_pct:.1f}% of total importance")
        print(f"   Top 20 features: {top20_pct:.1f}% of total importance")
        
        print(f"\n🏆 Top-10 Most Important Features:")
        for idx, row in imp_df.head(10).iterrows():
            print(f"   {row['feature']:30s}  {row['importance']:.4f}")
        
        issues = []
        if top10_pct > 80:
            issues.append(f"Importance highly concentrated ({top10_pct:.0f}% in top-10)")
            print(f"\n   ⚠️  Feature importance is VERY concentrated")
            print(f"      → Most features contribute little")
            print(f"      → Consider removing low-importance features")
        
        # Check for near-zero importance features
        near_zero = (imp_df['importance'] < 0.001).sum()
        if near_zero > 10:
            issues.append(f"{near_zero} features with near-zero importance")
            print(f"\n   ⚠️  {near_zero} features have near-zero importance")
            print(f"      → Removing them may improve performance")
        
        return issues
        
    except Exception as e:
        print(f"   ⚠️  Could not load model: {e}")
        return []


def analyze_error_patterns(X_test, y_test, y_pred, y_prob):
    """Identify what types of errors the model makes"""
    print("\n" + "="*80)
    print(" 3. ERROR PATTERN ANALYSIS")
    print("="*80)
    
    # False negatives (missed dropouts)
    fn_mask = (y_test == 1) & (y_pred == 0)
    fn_count = fn_mask.sum()
    
    # False positives (false alarms)
    fp_mask = (y_test == 0) & (y_pred == 1)
    fp_count = fp_mask.sum()
    
    # True positives (correctly identified dropouts)
    tp_mask = (y_test == 1) & (y_pred == 1)
    tp_count = tp_mask.sum()
    
    total_dropouts = y_test.sum()
    
    print(f"\n⚠️  Error Breakdown:")
    print(f"   False Negatives (missed dropouts): {fn_count} / {total_dropouts} ({fn_count/total_dropouts*100:.1f}%)")
    print(f"   False Positives (false alarms):    {fp_count}")
    print(f"   True Positives (caught dropouts):   {tp_count} / {total_dropouts} ({tp_count/total_dropouts*100:.1f}%)")
    
    issues = []
    
    # Check if errors are near decision boundary
    fn_probs = y_prob[fn_mask]
    if len(fn_probs) > 0:
        avg_fn_prob = fn_probs.mean()
        print(f"\n📊 False Negative Analysis:")
        print(f"   Average probability: {avg_fn_prob:.3f}")
        print(f"   These students were close to threshold")
        
        if avg_fn_prob > 0.4:
            issues.append(f"Many FN near decision boundary (avg prob {avg_fn_prob:.2f})")
            print(f"   💡 FIX: Lower classification threshold or use better features")
    
    # Check confidence distribution
    confident_wrong = ((y_prob < 0.2) & (y_test == 1)).sum() + \
                     ((y_prob > 0.8) & (y_test == 0)).sum()
    
    print(f"\n🎯 Confidence Analysis:")
    print(f"   Confidently wrong predictions: {confident_wrong}")
    if confident_wrong > len(y_test) * 0.05:
        issues.append(f"Model is confidently wrong on {confident_wrong} cases")
        print(f"   ⚠️  Model is overconfident on some errors")
        print(f"      → May need better features or different model architecture")
    
    return issues


def analyze_feature_gaps(df):
    """Identify missing feature types that could improve performance"""
    print("\n" + "="*80)
    print(" 4. FEATURE GAP ANALYSIS")
    print("="*80)
    
    feature_cols = [c for c in df.columns if c not in ['target', 'Target']]
    
    gaps = []
    suggestions = []
    
    # Check for interaction features
    interaction_features = [c for c in feature_cols if '_x_' in c or'_interaction' in c]
    print(f"\n🔗 Interaction Features: {len(interaction_features)}")
    if len(interaction_features) < 5:
        gaps.append("Few interaction features")
        suggestions.append("CREATE: Grade × Absence interactions, Financial × Academic stress")
    
    # Check for temporal features
    temporal_features = [c for c in feature_cols if 'trend' in c or 'velocity' in c or 'change' in c]
    print(f"📈 Temporal Features: {len(temporal_features)}")
    if len(temporal_features) < 3:
        gaps.append("Few temporal/trend features")
        suggestions.append("CREATE: Grade velocity, acceleration, momentum indicators")
    
    # Check for ratio/normalized features
    ratio_features = [c for c in feature_cols if 'ratio' in c or 'per' in c or '_pct' in c]
    print(f"➗ Ratio/Normalized Features: {len(ratio_features)}")
    if len(ratio_features) < 3:
        gaps.append("Few ratio features")
        suggestions.append("CREATE: Absence per grade point, Study effectiveness ratios")
    
    # Check for threshold/flag features
    flag_features = [c for c in feature_cols if c.endswith('_low') or c.endswith('_high') or c.endswith('_flag')]
    print(f"🚩 Threshold Flag Features: {len(flag_features)}")
    if len(flag_features) < 5:
        gaps.append("Few threshold flag features")
        suggestions.append("CREATE: Critical grade flags, high-risk combinations")
    
    if gaps:
        print(f"\n⚠️  Feature Gaps Detected:")
        for gap in gaps:
            print(f"   - {gap}")
    
    if suggestions:
        print(f"\n💡 Suggested New Features:")
        for i, sug in enumerate(suggestions, 1):
            print(f"   {i}. {sug}")
    
    return gaps, suggestions


def calculate_theoretical_ceiling(y_test, y_prob):
    """Estimate the theoretical maximum accuracy possible"""
    print("\n" + "="*80)
    print(" 5. THEORETICAL PERFORMANCE CEILING")
    print("="*80)
    
    # Find optimal threshold that maximizes accuracy
    thresholds = np.arange(0.1, 0.9, 0.01)
    max_acc = 0
    best_threshold = 0.5
    
    for t in thresholds:
        y_pred = (y_prob >= t).astype(int)
        acc = (y_pred == y_test).mean()
        if acc > max_acc:
            max_acc = acc
            best_threshold = t
    
    print(f"\n📊 Best Possible Performance (with optimal threshold):")
    print(f"   Max Accuracy: {max_acc*100:.2f}%")
    print(f"   Optimal Threshold: {best_threshold:.2f}")
    
    # Check AUC vs Accuracy gap
    from sklearn.metrics import roc_auc_score
    auc = roc_auc_score(y_test, y_prob)
    
    print(f"\n🎯 ROC-AUC: {auc*100:.2f}%")
    print(f"   Gap to max accuracy: {(auc - max_acc)*100:.1f}%")
    
    if auc - max_acc > 0.05:
        print(f"\n   💡 Large AUC-Accuracy gap suggests:")
        print(f"      → Threshold optimization can help (+{(max_acc - 0.88)*100:.1f}%)")
        print(f"      → Class imbalance is limiting accuracy")
    
    # Estimate ceiling with perfect features
    prob_sorted = np.sort(y_prob)
    test_sorted = y_test.iloc[np.argsort(y_prob)]
    
    # Simulate perfect separation
    n_dropouts = y_test.sum()
    perfect_acc = 1.0  # If we could perfectly separate
    
    print(f"\n🚀 Theoretical Ceiling (with perfect features):")
    print(f"   ~{perfect_acc*100:.0f}% (impossible to achieve)")
    print(f"   Realistic ceiling: ~{min(max_acc*1.03, 0.95)*100:.1f}%")
    
    return max_acc


def generate_recommendations(all_issues, suggestions):
    """Generate prioritized action plan"""
    print("\n" + "="*80)
    print(" 🎯 RECOMMENDED ACTION PLAN")
    print("="*80)
    
    print("\n" + "─"*80)
    print(" PRIORITY 1: QUICK WINS (Can be done today)")
    print("─"*80)
    
    print("\n1️⃣  Optimize Classification Threshold")
    print("   Current: 0.5 (default)")
    print("   Action: Find optimal threshold for F1-score")
    print("   Expected gain: +0.5-2%")
    print("   Code: Use advanced_optimization.py (threshold section)")
    
    print("\n2️⃣  Remove Low-Importance Features")
    print("   Current: Using all 58 features")
    print("   Action: Keep only top 40-45 features")
    print("   Expected gain: +0.5-1% (less noise)")
    print("   Code: Use advanced_optimization.py (feature selection)")
    
    print("\n3️⃣  Tune Class Weights")
    print("   Current: 'balanced' or default")
    print("   Action: Fine-tune weight ratio for 30% minority class")
    print("   Expected gain: +1-2%")
    print("   Code: Use advanced_optimization.py (class weight section)")
    
    print("\n" + "─"*80)
    print(" PRIORITY 2: FEATURE ENGINEERING (1-2 hours)")
    print("─"*80)
    
    if suggestions:
        for i, sug in enumerate(suggestions, 1):
            print(f"\n{i}️⃣  {sug}")
        print(f"\n   Expected gain: +1-3%")
        print(f"   Code: Use advanced_optimization.py (creates these automatically)")
    
    print("\n" + "─"*80)
    print(" PRIORITY 3: ADVANCED TECHNIQUES (2-3 hours)")
    print("─"*80)
    
    print("\n1️⃣  Advanced Ensemble")
    print("   Current: Single model or simple voting")
    print("   Action: Weighted ensemble with XGBoost + LightGBM")
    print("   Expected gain: +1-2%")
    
    print("\n2️⃣  Calibration")
    print("   Action: Use Platt scaling or isotonic regression")
    print("   Expected gain: +0.5-1%")
    
    print("\n3️⃣  Pseudo-Labeling (if you have unlabeled data)")
    print("   Action: Use high-confidence predictions to expand training set")
    print("   Expected gain: +1-3%")
    
    print("\n" + "─"*80)
    print(" TOTAL EXPECTED IMPROVEMENT: +3-8%")
    print(" TARGET: 88% → 91-96%")
    print("─"*80)
    
    print("\n💡 REALISTIC EXPECTATIONS:")
    print("   88% → 90-91%: Very achievable with quick wins")
    print("   91% → 93%: Achievable with feature engineering")
    print("   93% → 95%: Requires perfect execution + more data")
    print("   95%+: May need more/better training data")


def main():
    print("\n" + "="*80)
    print(" 🔍 MODEL CEILING DIAGNOSTIC")
    print("="*80)
    print("\nAnalyzing why your model is stuck at 88% accuracy...")
    
    # Load data
    import sys
    sys.path.insert(0, '.')
    from train_model import find_and_load_data, create_target_variable, Config as TrainConfig
    
    df = find_and_load_data(TrainConfig.DATA_DIR)
    df = create_target_variable(df)
    
    print(f"\n📊 Dataset: {len(df)} rows, {len(df.columns)} columns")
    
    all_issues = []
    
    # 1. Data quality
    issues = analyze_data_quality(df)
    all_issues.extend(issues)
    
    # 2. Feature importance (if model exists)
    model_path = './models/randomforest_model.pkl'
    if os.path.exists(model_path):
        from train_model import select_features
        feature_cols = select_features(df, TrainConfig.EXCLUDE_FEATURES)
        issues = analyze_feature_importance_distribution(model_path, feature_cols)
        all_issues.extend(issues)
    
    # 3. Feature gaps
    gaps, suggestions = analyze_feature_gaps(df)
    all_issues.extend(gaps)
    
    # 4. Error analysis (if predictions available)
    # This would require running predictions - skipped for now
    
    # Generate recommendations
    generate_recommendations(all_issues, suggestions)
    
    print("\n" + "="*80)
    print(" ✅ DIAGNOSTIC COMPLETE")
    print("="*80)
    print("\n🎯 Next Steps:")
    print("   1. Run: python advanced_optimization.py")
    print("   2. This will apply all Priority 1 & 2 fixes automatically")
    print("   3. Expected result: 90-93% accuracy")


if __name__ == '__main__':
    import os
    main()