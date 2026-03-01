<<<<<<< HEAD
# 4See — Student Dropout Prediction App

> ⚠️ **Note:** Please ignore the `main` branch. It is not the source of truth for this project. All meaningful code lives in the branches described below.

---

## Branch Guide

| Branch | Contents |
|---|---|
| [`forsee-final`](../../tree/forsee-final) | ✅ **Main app code** — the primary Flutter app |
| [`website`](../../tree/website) | 🌐 Landing/marketing website code |
| [`backend`](../../tree/backend) | Backend code (supplementary) |
| [`frontend`](../../tree/frontend) | Frontend code (supplementary) |
| [`dataset`](../../tree/dataset) | 📊 Datasets used in the project — refer to the `/dataset` folder only; ignore other files in this branch |

---

## Project Structure

### `forsee-final` branch

#### `/forsee_demo_one` — Flutter App
The main mobile app directory built with Flutter/Dart.
- Handles UI, user input, and prediction display
- Connects to the deployed ML backend on Hugging Face Spaces
- Key file: `input_test_page.dart`
- Requires Firebase setup

#### `/4see-backend` — Backend / ML Model / Data Cleaning
Contains all Python backend code including:
- Model training scripts (`train_model.py`)
- Data cleaning pipelines
- Flask API (`flask_app_final.py`) for serving predictions
- Trained models stored in `/models`
- Datasets stored in `/data`

---

## Running the Project

### ML Model (Local)
```bash
# 1. Activate your virtual environment
# 2. Train the model
python train_model.py

# 3. Start the Flask API
python flask_app_final.py

# 4. Test endpoints via Postman (see flask_app_final.py for API routes)
```

### Deployed Model
The model is already hosted on Hugging Face Spaces:
🔗 **https://huggingface.co/spaces/sliverstream8/4seedemo**

The Flutter app points to this endpoint by default — no local backend setup needed to run the app.

### Flutter App
```bash
cd forsee_demo_one
flutter pub get
flutter run
```
> Make sure to configure your own Firebase credentials before running.

---

## Tech Stack
- **Mobile App:** Flutter (Dart)
- **Backend/API:** Python, Flask
- **ML:** Scikit-learn / custom dropout prediction model
- **Deployment:** Hugging Face Spaces
- **Auth/DB:** Firebase

## WEBSITE REPO LINK - https://github.com/krithikanaidu/4see-404Rescued
=======
