import pandas as pd

# Load the files
features = pd.read_csv('student_features.csv')
target = pd.read_csv('student_target.csv')

# Combine side-by-side (axis=1)
# This assumes the rows are in the exact same order (row 1 in features = row 1 in target)
df_combined = pd.concat([features, target], axis=1)

# CLEANING: Remove duplicate columns if they exist
# This keeps only the first appearance of a column name
df_combined = df_combined.loc[:, ~df_combined.columns.duplicated()]

df_combined.to_csv('combined_higher_ed_students.csv', index=False)