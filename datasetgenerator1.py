import random
import csv

random.seed(42)
N = 10000

father_income_map = {
    "Daily Wage Worker": (60000, 120000),
    "Farmer": (70000, 150000),
    "Private Employee": (150000, 500000),
    "Government Employee": (250000, 700000),
    "Business": (200000, 1300000),
    "Unemployed": (30000, 60000)
}

mother_income_map = {
    "Homemaker": (0, 0),
    "Daily Wage Worker": (40000, 80000),
    "Private Employee": (120000, 500000),
    "Government Employee": (200000, 700000),
    "Business": (150000, 1200000),
    "Unemployed": (20000, 40000)
}

def clamp(x, lo, hi):
    return max(lo, min(hi, x))

rows = []

for i in range(1, N + 1):
    gender = random.choice(["Male", "Female"])
    age = random.randint(6, 21)
    marital_status = "Single"

    father_occ = random.choice(list(father_income_map))
    mother_occ = random.choice(list(mother_income_map))

    family_income = (
        random.randint(*father_income_map[father_occ]) +
        random.randint(*mother_income_map[mother_occ])
    )

    motivation = random.choices(
        ["Low", "Medium", "High"],
        weights=[0.25, 0.45, 0.30]
    )[0]

    health = random.choices(
        ["Poor", "Average", "Good"],
        weights=[0.15, 0.50, 0.35]
    )[0]

    scholarship = "Yes" if family_income < 150000 and random.random() < 0.6 else "No"
    tuition = "Yes" if family_income > 120000 or scholarship == "Yes" else random.choice(["Yes", "No"])
    internet = "Yes" if family_income > 100000 else random.choice(["Yes", "No"])

    distance = round(random.uniform(0.5, 15), 1)

    attendance = 85
    if distance > 8:
        attendance -= 10
    if health == "Poor":
        attendance -= 10
    if motivation == "High":
        attendance += 10

    attendance = clamp(int(random.gauss(attendance, 8)), 40, 100)

    disciplinary = random.randint(0, 2) if attendance > 75 else random.randint(2, 8)

    study_hours = 2.5
    if motivation == "High":
        study_hours += 1.5
    if motivation == "Low":
        study_hours -= 1.0
    if internet == "No":
        study_hours -= 0.5

    study_hours = round(clamp(study_hours + random.uniform(-0.5, 0.5), 0.5, 6.0), 1)

    base_score = (
        study_hours * 10 +
        attendance * 0.4 -
        disciplinary * 3
    )

    sem1 = clamp(int(random.gauss(base_score, 8)), 25, 100)
    sem2 = clamp(int(random.gauss(sem1 + 2, 6)), 25, 100)
    avg_marks = int((sem1 + sem2) / 2)

    if avg_marks < 40:
        prev_result = "Fail"
    elif avg_marks < 60:
        prev_result = "Pass"
    else:
        prev_result = f"{avg_marks}%"

    rows.append([
        f"S{i:05d}", gender, age, marital_status,
        father_occ, mother_occ, family_income,
        tuition, scholarship, attendance,
        disciplinary, avg_marks,
        sem1, sem2, distance,
        internet, study_hours,
        prev_result, motivation, health
    ])

with open("indian_student_dropout_dataset5.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Student_ID","Gender","Age","Marital_Status",
        "Father_Occupation","Mother_Occupation","Family_Income",
        "Tuition_Fees_UpToDate","Scholarship_Holder",
        "Attendance_Percentage","Disciplinary_Incidents",
        "Course_Marks_Avg","Semester_One_Marks","Semester_Two_Marks",
        "Distance_From_School_km","Internet_Access",
        "Study_Hours_Per_Day","Previous_Year_Result",
        "Motivation","Health"
    ])
    writer.writerows(rows)

print("CSV generated successfully.")
