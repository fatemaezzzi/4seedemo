# forsee_demo_one
A Flutter application that predicts student dropout risk using a machine learning model hosted on Hugging Face Spaces. The app stores student data and prediction history in Firebase Firestore.

## 🚀 Features

* **Student Management:** Add and view student profiles with academic data (Grades, Attendance, etc.).
* **Risk Prediction:** Integrates with a custom Python ML model via REST API.
* **Risk Analysis:** Visualizes risk levels (Low/Medium/High), dropout probability, and specific risk factors.
* **History:** Tracks historical predictions for each student in Firestore.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Firestore (Database)
* **ML API:** Hugging Face Spaces (Gradio)
* **Networking:** `http` package

---

## ⚙️ Setup & Installation

### 1. Prerequisites
* Flutter SDK installed (`flutter doctor`)
* Firebase project setup

### 2. Clone and Install
```bash
git clone https://github.com/fatemaezzzi/4seedemo
cd forsee_demo_one
flutter pub get