"""
Student Dropout Prediction — 4See ML Pipeline
================================================
Priority logic applied throughout:

    HIGH   (Dynamic, equal weight)  → G1, G2, G3, absences
    MEDIUM (Dynamic behavioral)     → failures, studytime, famrel, health
    LOW    (Static context)         → Course, age, sex, Debtor, Scholarship, …

    weighted_risk_score — a single engineered feature that pre-computes
       the full priority hierarchy so the model has an explicit "hint".

Changes from the previous version
──────────────────────────────────
  • G3 is NO LONGER excluded — it is a core HIGH-priority input.
  • Target comes from the pre-labeled 'Target' column (1 = Dropout).
  • Feature engineering rewritten from scratch using only columns that
    actually exist in student_dropout_master_dataset.csv.  Old references
    to Dalc, Walc, Medu, Fedu, goout (wrong dataset) are removed.
  • All 28 feature columns feed the model.  Dynamic columns appear in many
    engineered features so the model sees them repeatedly; static columns
    are kept as-is plus a few lightweight composites.
"""

import pandas as pd
import numpy as np
import os
import warnings
from pathlib import Path

from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import (
    train_test_split, cross_val_score, StratifiedKFold
)
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    f1_score, roc_auc_score, confusion_matrix
)
try:
    from imblearn.over_sampling import SMOTE
    _HAS_SMOTE = True
except ImportError:                             # fallback when imblearn missing
    from sklearn.utils import resample as _resample
    _HAS_SMOTE = False

import joblib

warnings.filterwarnings('ignore')


# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    DATA_DIR      = './data'
    MODEL_DIR     = './models'
    RANDOM_STATE  = 42
    TEST_SIZE     = 0.2
    CV_FOLDS      = 5

    # Nothing excluded — G3 is now a feature, Target is handled separately
    EXCLUDE_FEATURES = []

    # ── Priority weights for the manual risk-score feature ──────────────
    # Sum = 1.0.  Dynamic features dominate; static features share a small
    # pool that is split evenly across however many static columns exist.
    #
    #   G1 = G2 = G3 = 0.18   (equal, highest)
    #   absences            = 0.12
    #   failures            = 0.07
    #   studytime           = 0.05
    #   famrel              = 0.03
    #   health              = 0.03
    #   static_pool         = 0.05  (split across ~15 static columns)
    # ────────────────────────────────────────────────────────────────────
    W = {
        'G1': 0.18, 'G2': 0.18, 'G3': 0.18,
        'absences':  0.12,
        'failures':  0.07,
        'studytime': 0.05,
        'famrel':    0.03,
        'health':    0.03,
        'static_pool': 0.05,        # divided equally among static columns
    }

    # Actual min/max from the dataset (used for normalization)
    RANGES = {
        'G1':        (0, 20),
        'G2':        (0, 20),
        'G3':        (0, 20),
        'absences':  (0, 75),
        'failures':  (0, 4),        # capped at 4 in source
        'studytime': (1, 4),
        'famrel':    (1, 5),
        'health':    (1, 5),
        'age':       (15, 70),
    }

    # Model hyperparameters
    RF_PARAMS = {
        'n_estimators': 300,
        'max_depth': 20,
        'min_samples_split': 10,
        'min_samples_leaf': 4,
        'max_features': 'sqrt',
        'bootstrap': True,
        'random_state': 42,
        'n_jobs': -1,
        'class_weight': 'balanced_subsample',
        'criterion': 'gini',
    }

    GB_PARAMS = {
        'n_estimators': 200,
        'learning_rate': 0.05,
        'max_depth': 6,
        'min_samples_split': 10,
        'min_samples_leaf': 4,
        'subsample': 0.8,
        'random_state': 42,
    }


# ============================================================================
# HELPERS
# ============================================================================

def _norm(series, lo, hi):
    """Normalize a Series to [0, 1] given known bounds."""
    return ((series - lo) / (hi - lo)).clip(0, 1)


# ============================================================================
# STEP 1 — DATA LOADING
# ============================================================================

def find_and_load_data(data_dir):
    print("\n" + "=" * 70)
    print(" STEP 1: DATA LOADING")
    print("=" * 70)

    csv_files = list(Path(data_dir).rglob('*.csv'))
    print(f"\n  Searching {data_dir} … found {len(csv_files)} CSV file(s)")

    for filepath in csv_files:
        for sep in [',', ';', '\t']:
            try:
                df = pd.read_csv(filepath, sep=sep)
                if 'Target' in df.columns and 'G1' in df.columns and 'G3' in df.columns:
                    print(f"\n  Loaded : {filepath.name}")
                    print(f"     Shape : {df.shape[0]} rows × {df.shape[1]} columns")
                    print(f"     Columns: {list(df.columns)}")
                    return df
            except Exception:
                continue

    raise FileNotFoundError("No suitable CSV with Target / G1 / G3 found.")


# ============================================================================
# STEP 2 — TARGET VARIABLE
# ============================================================================

def create_target_variable(df):
    """
    Use the pre-labeled 'Target' column.
      Target = 1  →  Dropout   (high risk)
      Target = 0  →  Graduate  (low risk)
    """
    print("\n" + "=" * 70)
    print(" STEP 2: TARGET VARIABLE")
    print("=" * 70)

    if 'Target' not in df.columns:
        raise ValueError("'Target' column missing from dataset.")

    df['target'] = df['Target'].astype(int)
    df = df.drop(columns=['Target'])

    n_dropout  = df['target'].sum()
    n_total    = len(df)
    pct        = n_dropout / n_total * 100

    print(f"\n  Source   : pre-labeled 'Target' column")
    print(f"  Dropout  : {n_dropout:,} ({pct:.1f} %)")
    print(f"  Graduate : {n_total - n_dropout:,} ({100 - pct:.1f} %)")
    if pct < 25 or pct > 75:
        print(f"  Imbalanced — SMOTE will be applied during preprocessing.")

    return df


# ============================================================================
# STEP 3 — FEATURE ENGINEERING
# ============================================================================

def engineer_features(df):
    """
    Three-tier feature engineering following the priority logic.

    Tier A  (HIGH)   — G1, G2, G3, absences
        Creates ~18 features.  These columns appear in many derived
        features so tree models see them at every split opportunity.

    Tier B  (MEDIUM) — failures, studytime, famrel, health
        Creates ~7 features.

    Tier C  (LOW)    — every other column (static context)
        Kept as raw inputs.  Three lightweight composites added:
        financial_stress, has_any_support, parent_occupation_sum.

    Tier D  (COMPOSITE)
        weighted_risk_score — a single [0, 1] feature that manually
        encodes the full priority hierarchy.  Acts as a strong signal
        for the model without replacing the individual features.
    """
    print("\n" + "=" * 70)
    print(" STEP 3: FEATURE ENGINEERING")
    print("=" * 70)

    d = df.copy()

    # ─────────────────────────────────────────────────────────────────
    # TIER A — HIGH PRIORITY  (G1, G2, G3, absences)
    # ─────────────────────────────────────────────────────────────────
    print("\nTier A — HIGH priority (grades + attendance)")

    # ── Semester-to-semester trends ──
    d['grade_trend_12'] = d['G2'] - d['G1']       # positive = improving
    d['grade_trend_23'] = d['G3'] - d['G2']
    d['grade_trend_13'] = d['G3'] - d['G1']       # full arc

    # ── Averages (G1 = G2 = G3 weight, per user logic) ──
    d['grade_avg_all'] = (d['G1'] + d['G2'] + d['G3']) / 3
    d['grade_avg_12']  = (d['G1'] + d['G2']) / 2

    # ── Spread / volatility ──
    d['grade_min']   = d[['G1', 'G2', 'G3']].min(axis=1)
    d['grade_max']   = d[['G1', 'G2', 'G3']].max(axis=1)
    d['grade_range'] = d['grade_max'] - d['grade_min']

    # ── Decline flags ──
    d['drop_12']         = (d['G2'] < d['G1']).astype(int)
    d['drop_23']         = (d['G3'] < d['G2']).astype(int)
    d['consecutive_drop'] = (d['drop_12'] & d['drop_23']).astype(int)

    # ── Low-grade flags (threshold 8 / 20) ──
    LOW = 8
    d['g1_low']         = (d['G1'] < LOW).astype(int)
    d['g2_low']         = (d['G2'] < LOW).astype(int)
    d['g3_low']         = (d['G3'] < LOW).astype(int)
    d['all_grades_low'] = (d['g1_low'] & d['g2_low'] & d['g3_low']).astype(int)
    d['any_grade_zero'] = ((d['G1'] == 0) | (d['G2'] == 0) | (d['G3'] == 0)).astype(int)

    # ── Attendance ──
    d['absence_high']      = (d['absences'] > 10).astype(int)
    d['absence_very_high'] = (d['absences'] > 25).astype(int)

    # ── Key cross-feature: absences × academic weakness ──
    # Higher value = more absences combined with lower grades = worst combo
    d['absence_x_grade'] = d['absences'] * (20 - d['grade_avg_all'])

    tier_a = 18
    print(f"     → {tier_a} features created")

    # ─────────────────────────────────────────────────────────────────
    # TIER B — MEDIUM PRIORITY  (failures, studytime, famrel, health)
    # ─────────────────────────────────────────────────────────────────
    print("\n Tier B — MEDIUM priority (behavioral / social)")

    d['has_failures']      = (d['failures'] > 0).astype(int)
    d['multiple_failures'] = (d['failures'] >= 2).astype(int)
    d['low_study']         = (d['studytime'] < 2).astype(int)

    # Interaction: past failures × current academic weakness
    d['failures_x_grade']  = d['failures'] * (20 - d['grade_avg_all'])

    # Study effectiveness: does study time translate to results?
    d['study_effectiveness'] = d['studytime'] * d['grade_avg_all']

    # Social-health composite (both on 1–5 scale)
    d['social_health'] = d['famrel'] + d['health']

    # Weak social + weak academics
    d['social_academic_risk'] = (
        (d['famrel'] <= 2).astype(int) &
        (d['grade_avg_all'] < 10).astype(int)
    ).astype(int)

    tier_b = 7
    print(f"     → {tier_b} features created")

    # ─────────────────────────────────────────────────────────────────
    # TIER C — LOW PRIORITY  (static context)
    # Raw columns kept as-is; add three composites.
    # ─────────────────────────────────────────────────────────────────
    print("\nTier C — LOW priority (static composites)")

    # Financial pressure flag
    d['financial_stress'] = (
        (d['Debtor'] == 1) | (d['Tuition fees up to date'] == 0)
    ).astype(int)

    # Any support network present
    d['has_any_support'] = (
        (d['Scholarship holder'] == 1) |
        (d['schoolsup'] == 1) |
        (d['famsup'] == 1)
    ).astype(int)

    # Combined parental occupation signal
    d['parent_occupation_sum'] = d['Mjob'] + d['Fjob']

    tier_c = 3
    print(f"     → {tier_c} composites created  (all other static columns kept raw)")

    # ─────────────────────────────────────────────────────────────────
    # TIER D — WEIGHTED RISK SCORE  (priority-encoded composite)
    # ─────────────────────────────────────────────────────────────────
    print("\nTier D — weighted_risk_score")

    R = Config.RANGES
    W = Config.W

    # Each component normalised to [0, 1] then flipped so
    # "higher value = higher dropout risk"
    g1_risk      = 1 - _norm(d['G1'],        *R['G1'])
    g2_risk      = 1 - _norm(d['G2'],        *R['G2'])
    g3_risk      = 1 - _norm(d['G3'],        *R['G3'])
    abs_risk     =     _norm(d['absences'],  *R['absences'])
    fail_risk    =     _norm(d['failures'],  *R['failures'])
    study_risk   = 1 - _norm(d['studytime'], *R['studytime'])
    famrel_risk  = 1 - _norm(d['famrel'],    *R['famrel'])
    health_risk  = 1 - _norm(d['health'],    *R['health'])

    # Static pool: average risk across all static binary / categorical cols
    static_cols_risk = (
        _norm(d['Debtor'],                         0, 1) +
        (1 - _norm(d['Tuition fees up to date'],   0, 1)) +
        (1 - _norm(d['Scholarship holder'],        0, 1)) +
        _norm(d['Educational special needs'],      0, 1) +
        (1 - _norm(d['schoolsup'],                 0, 1)) +
        (1 - _norm(d['famsup'],                    0, 1)) +
        (1 - _norm(d['paid'],                      0, 1)) +
        (1 - _norm(d['activities'],                0, 1)) +
        (1 - _norm(d['higher'],                    0, 1)) +
        (1 - _norm(d['internet'],                  0, 1)) +
        _norm(d['age'],                            *R['age'])
    ) / 11   # average → keeps it in [0, 1]

    d['weighted_risk_score'] = (
        g1_risk     * W['G1']        +
        g2_risk     * W['G2']        +
        g3_risk     * W['G3']        +
        abs_risk    * W['absences']  +
        fail_risk   * W['failures']  +
        study_risk  * W['studytime']+
        famrel_risk * W['famrel']    +
        health_risk * W['health']    +
        static_cols_risk * W['static_pool']
    )

    print(f"     range: [{d['weighted_risk_score'].min():.3f}, "
          f"{d['weighted_risk_score'].max():.3f}]")

    # ─────────────────────────────────────────────────────────────────
    total_new = tier_a + tier_b + tier_c + 1   # +1 for weighted_risk_score
    print(f"\nSummary: {len(df.columns)} original → "
          f"{len(d.columns)} total  (+{total_new} engineered)")

    return d


# ============================================================================
# STEP 4 — FEATURE SELECTION
# ============================================================================

def select_features(df, exclude_list):
    """Return all columns except 'target' and anything in exclude_list."""
    print("\n" + "=" * 70)
    print(" STEP 4: FEATURE SELECTION")
    print("=" * 70)

    drop = {'target'} | set(exclude_list)
    features = [c for c in df.columns if c not in drop]

    # ── Classify by tier for the printout ──
    high_keys   = {'G1', 'G2', 'G3', 'absences'}
    med_keys    = {'failures', 'studytime', 'famrel', 'health'}

    high  = [f for f in features if f in high_keys or
             any(k in f for k in ('grade', 'drop_', 'absence', 'g1_', 'g2_', 'g3_', 'all_grades', 'any_grade'))]
    med   = [f for f in features if f not in high and (f in med_keys or
             any(k in f for k in ('fail', 'study', 'social')))]
    low   = [f for f in features if f not in high and f not in med]

    print(f"\nHIGH   ({len(high):2d} features)")
    print(f"     {high}")
    print(f"MEDIUM ({len(med):2d} features)")
    print(f"     {med}")
    print(f"LOW    ({len(low):2d} features)")
    print(f"     {low}")
    print(f"\n  Total: {len(features)} features")

    return features


# ============================================================================
# STEP 5 — PREPROCESSING
# ============================================================================

def preprocess_data(df, feature_columns, use_smote=True):
    """
    1. Null handling  (safety net — dataset has zero nulls)
    2. Categorical encoding  (safety net — all columns are numeric)
    3. Train / test split  (stratified)
    4. StandardScaler
    5. SMOTE if class ratio < 0.25 or > 0.75
    """
    print("\n" + "=" * 70)
    print(" STEP 5: PREPROCESSING")
    print("=" * 70)

    work = df[feature_columns + ['target']].copy()

    # 1. Nulls
    null_total = work.isnull().sum().sum()
    if null_total > 0:
        print(f"\n  Filling {null_total} nulls …")
        for c in work.select_dtypes(include=[np.number]).columns:
            work[c].fillna(work[c].median(), inplace=True)
        for c in work.select_dtypes(include=['object']).columns:
            work[c].fillna(work[c].mode()[0], inplace=True)
    else:
        print("\nZero nulls — nothing to fill")

    # 2. Categorical encode (safety net)
    cat_cols = work.select_dtypes(include=['object']).columns.tolist()
    label_encoders = {}
    if cat_cols:
        print(f"\n  Encoding {len(cat_cols)} categorical column(s) …")
        for c in cat_cols:
            le = LabelEncoder()
            work[c] = le.fit_transform(work[c].astype(str))
            label_encoders[c] = le
    else:
        print("All columns numeric — no encoding needed")

    # 3. Split
    X = work.drop(columns=['target'])
    y = work['target']

    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=Config.TEST_SIZE,
        random_state=Config.RANDOM_STATE,
        stratify=y
    )
    print(f"\n  Split  → Train: {len(X_train):,}  |  Test: {len(X_test):,}  "
          f"|  Features: {X_train.shape[1]}")

    # 4. Scale
    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s  = scaler.transform(X_test)
    print("StandardScaler applied")

    # 5. SMOTE
    ratio = y_train.sum() / len(y_train)
    if use_smote and (ratio < 0.25 or ratio > 0.75):
        print(f"\nOversampling minority class  (dropout ratio = {ratio:.2%})")
        if _HAS_SMOTE:
            smote = SMOTE(random_state=Config.RANDOM_STATE, k_neighbors=5)
            X_train_s, y_train = smote.fit_resample(X_train_s, y_train)
        else:
            # sklearn fallback: duplicate minority rows to match majority
            import pandas as _pd
            y_s = pd.Series(y_train)
            maj_idx = y_s[y_s == 0].index
            min_idx = y_s[y_s == 1].index
            X_min  = X_train_s[min_idx] if hasattr(X_train_s, '__getitem__') else X_train_s[min_idx]
            y_min  = y_s.loc[min_idx]
            X_up, y_up = _resample(
                X_min, y_min,
                replace=True,
                n_samples=len(maj_idx) - len(min_idx),
                random_state=Config.RANDOM_STATE
            )
            X_train_s = np.vstack([X_train_s, X_up])
            y_train   = pd.concat([y_s, pd.Series(y_up)], ignore_index=True)
        print(f"     After  → {X_train_s.shape[0]:,} samples  "
              f"|  ratio = {y_train.sum() / len(y_train):.2%}")
    else:
        print(f"\nSMOTE skipped — ratio {ratio:.2%} is acceptable")

    print(f"\n  Final  → Train: Dropout {y_train.sum():,} / Graduate "
          f"{len(y_train) - y_train.sum():,}")
    print(f"           Test : Dropout {y_test.sum():,}  / Graduate "
          f"{len(y_test) - y_test.sum():,}")

    return (X_train_s, X_test_s, y_train, y_test,
            scaler, label_encoders, X.columns.tolist())


# ============================================================================
# STEP 6 — MODEL TRAINING
# ============================================================================

def train_models(X_train, y_train):
    print("\n" + "=" * 70)
    print(" STEP 6: MODEL TRAINING")
    print("=" * 70)
    print(f"\n  Samples: {X_train.shape[0]:,}  |  Features: {X_train.shape[1]}")

    models = {}

    print("\nRandom Forest …", end=" ", flush=True)
    rf = RandomForestClassifier(**Config.RF_PARAMS)
    rf.fit(X_train, y_train)
    models['RandomForest'] = rf
    print("done")

    print("Gradient Boosting …", end=" ", flush=True)
    gb = GradientBoostingClassifier(**Config.GB_PARAMS)
    gb.fit(X_train, y_train)
    models['GradientBoosting'] = gb
    print("done")

    print("Logistic Regression …", end=" ", flush=True)
    lr = LogisticRegression(
        max_iter=2000, random_state=Config.RANDOM_STATE,
        class_weight='balanced', C=0.1
    )
    lr.fit(X_train, y_train)
    models['LogisticRegression'] = lr
    print("done")

    return models


# ============================================================================
# STEP 7 — EVALUATION
# ============================================================================

def evaluate_models(models, X_train, X_test, y_train, y_test, feature_names):
    print("\n" + "=" * 70)
    print(" STEP 7: MODEL EVALUATION")
    print("=" * 70)

    results = {}

    for name, model in models.items():
        print(f"\n  ── {name} ──")

        # Cross-validation
        cv = StratifiedKFold(
            n_splits=Config.CV_FOLDS, shuffle=True,
            random_state=Config.RANDOM_STATE
        )
        cv_f1 = cross_val_score(
            model, X_train, y_train, cv=cv, scoring='f1', n_jobs=-1
        )

        y_pred  = model.predict(X_test)
        y_prob  = model.predict_proba(X_test)[:, 1]

        m = {
            'cv_f1_mean':  cv_f1.mean(),
            'cv_f1_std':   cv_f1.std(),
            'accuracy':    accuracy_score(y_test, y_pred),
            'precision':   precision_score(y_test, y_pred, zero_division=0),
            'recall':      recall_score(y_test, y_pred, zero_division=0),
            'f1':          f1_score(y_test, y_pred, zero_division=0),
            'roc_auc':     roc_auc_score(y_test, y_prob),
        }
        results[name] = m

        print(f"     CV F1          {m['cv_f1_mean']:.4f} ± {m['cv_f1_std']:.4f}")
        print(f"     Accuracy       {m['accuracy']:.4f}")
        print(f"     Precision      {m['precision']:.4f}")
        print(f"     Recall         {m['recall']:.4f}")
        print(f"     F1             {m['f1']:.4f}")
        print(f"     ROC-AUC        {m['roc_auc']:.4f}")

        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        print(f"\n     Confusion Matrix")
        print(f"                  Pred-Grad  Pred-Drop")
        print(f"     Actual-Grad  {cm[0,0]:7,}   {cm[0,1]:7,}")
        print(f"     Actual-Drop  {cm[1,0]:7,}   {cm[1,1]:7,}")

        # Feature importance (tree models only)
        if hasattr(model, 'feature_importances_'):
            imp = model.feature_importances_
            idx = np.argsort(imp)[::-1]

            print(f"\n     Top-15 Feature Importances")
            print(f"     {'#':>3}  {'Feature':<32} {'Importance':>10}  Bar")
            print(f"     {'─'*3}  {'─'*32} {'─'*10}  {'─'*20}")
            for rank, i in enumerate(idx[:15], 1):
                bar = '█' * int(imp[i] * 300)
                print(f"     {rank:>3}  {feature_names[i]:<32} {imp[i]:>10.4f}  {bar}")

    return results


# ============================================================================
# STEP 8 — SAVE ARTIFACTS
# ============================================================================

def save_models(models, scaler, feature_columns, label_encoders, results):
    print("\n" + "=" * 70)
    print(" STEP 8: SAVING ARTIFACTS")
    print("=" * 70)

    os.makedirs(Config.MODEL_DIR, exist_ok=True)

    for name, model in models.items():
        path = os.path.join(Config.MODEL_DIR, f'{name.lower()}_model.pkl')
        joblib.dump(model, path)
        print(f" {name.lower()}_model.pkl")

    joblib.dump(scaler,          os.path.join(Config.MODEL_DIR, 'scaler.pkl'))
    joblib.dump(feature_columns, os.path.join(Config.MODEL_DIR, 'feature_columns.pkl'))
    joblib.dump(label_encoders,  os.path.join(Config.MODEL_DIR, 'label_encoders.pkl'))

    best = max(results, key=lambda k: results[k]['f1'])
    metadata = {
        'best_model':   best,
        'performance':  results,
        'features':     feature_columns,
        'weights':      Config.W,
    }
    joblib.dump(metadata, os.path.join(Config.MODEL_DIR, 'model_metadata.pkl'))
    print("  ✅ scaler / feature_columns / label_encoders / model_metadata")

    print(f"\n  🏆 Best model : {best}")
    print(f"     F1         : {results[best]['f1']:.4f}")
    print(f"     ROC-AUC    : {results[best]['roc_auc']:.4f}")
    print(f"     Precision  : {results[best]['precision']:.4f}")
    print(f"     Recall     : {results[best]['recall']:.4f}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    print("\n" + "=" * 70)
    print(" 4SEE — STUDENT DROPOUT PREDICTION PIPELINE")
    print("=" * 70)
    print("  HIGH   → G1, G2, G3 (equal), absences")
    print("  MEDIUM → failures, studytime, famrel, health")
    print("  LOW    → static context (Course, age, sex, …)")
    print("  weighted_risk_score encodes the full hierarchy")
    print("=" * 70)

    try:
        df       = find_and_load_data(Config.DATA_DIR)
        df       = create_target_variable(df)
        df       = engineer_features(df)
        features = select_features(df, Config.EXCLUDE_FEATURES)

        (X_train, X_test, y_train, y_test,
         scaler, encoders, final_feats) = preprocess_data(df, features)

        models  = train_models(X_train, y_train)
        results = evaluate_models(models, X_train, X_test,
                                  y_train, y_test, final_feats)
        save_models(models, scaler, final_feats, encoders, results)

        print("\n" + "=" * 70)
        print("PIPELINE COMPLETE")
        print("=" * 70)
        print(f"  Students  : {len(df):,}")
        print(f"  Features  : {len(final_feats)}")
        print(f"  Artifacts : {Config.MODEL_DIR}/")

    except Exception as e:
        print(f"\n  ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise


if __name__ == "__main__":
    main()