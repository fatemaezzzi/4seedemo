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
<<<<<<< HEAD
# forc

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# Current File structure to follow

### Main Model Code 
    - from claude-model branch refer /4see-backend folder 
    - run train_model.py
    - models will be in the /models directory and /data will have datasets
    - once you are done training follow these steps  
        1. run flask_app_final.py from your terminal (make sure you activate your virtual environment)
        2. use POSTMAN to check the api endpoints - check the flask_app_final.py for API information
    - 

    - if you want to use the already deployed model - https://huggingface.co/spaces/sliverstream8/4seedemo
    - just directly use this when you are using flutter app

### Flutter App
    - check /forsee_demo_one folder in the root directory for flutter files
    - refer input_test_page.dart also setup your firebase code 
    - the backend is already running on the huggingface space 
>>>>>>> ba1a6e8d8be9a6df069da0d6c7e39f87b1fc3832
>>>>>>> 4c359a36ba1c85875b39182862641a3c28a7b383
