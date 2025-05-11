import os
import joblib
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException, Depends, Request
from pydantic import BaseModel, Field, validator
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any, Union

# --- Configuration ---
PIPELINE_FILENAME = 'maternal_risk_pipeline.joblib'
LABEL_ENCODER_FILENAME = 'risk_level_label_encoder.joblib'
FEATURES_FILENAME = 'risk_model_features.joblib'

# --- Load Models and Encoders ---
# Attempt to load files relative to the script's location
script_dir = os.path.dirname(__file__)  # Get directory where script is running
pipeline_path = os.path.join(script_dir, PIPELINE_FILENAME)
encoder_path = os.path.join(script_dir, LABEL_ENCODER_FILENAME)
features_path = os.path.join(script_dir, FEATURES_FILENAME)

loaded_pipeline = None
loaded_label_encoder = None
loaded_features = None
model_load_error = None

try:
    print(f"Attempting to load pipeline from: {pipeline_path}")
    if os.path.exists(pipeline_path):
        loaded_pipeline = joblib.load(pipeline_path)
        print("Pipeline loaded successfully.")
    else:
        model_load_error = f"Pipeline file not found: {pipeline_path}"
        print(model_load_error)

    print(f"Attempting to load label encoder from: {encoder_path}")
    if os.path.exists(encoder_path):
        loaded_label_encoder = joblib.load(encoder_path)
        print("Label encoder loaded successfully.")
    else:
        model_load_error = f"Label encoder file not found: {encoder_path}"
        print(model_load_error)

    print(f"Attempting to load feature list from: {features_path}")
    if os.path.exists(features_path):
        loaded_features = joblib.load(features_path)
        print(f"Expected features loaded: {loaded_features}")
    else:
        model_load_error = f"Features file not found: {features_path}"
        print(model_load_error)

    if not all([loaded_pipeline, loaded_label_encoder, loaded_features]):
         print("Error: One or more model components failed to load. Check paths and file integrity.")
         if model_load_error is None:  # If specific file wasn't flagged, set a general error
             model_load_error = "One or more model components failed to load."

except Exception as e:
    model_load_error = f"An unexpected error occurred during model loading: {e}"
    print(model_load_error)
    # Reset loaded components on unexpected error
    loaded_pipeline = None
    loaded_label_encoder = None
    loaded_features = None

# --- Pydantic Models for Input/Output Validation ---
class PredictionInput(BaseModel):
    # Match the exact names and types from your Flutter ViewModel input
    # Added validators for basic range checks
    age: int = Field(..., example=30)
    systolicBP: int = Field(..., alias='systolicBP', example=120)
    diastolicBP: int = Field(..., alias='diastolicBP', example=80)
    bs: float = Field(..., alias='bs', example=7.5)  # Blood Sugar
    bodyTemp: float = Field(..., alias='bodyTemp', example=98.6)  # Body Temperature F
    heartRate: int = Field(..., alias='heartRate', example=75)

    @validator('age')
    def age_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('Age must be positive')
        if v < 10 or v > 90:  # Example reasonable range
            print(f"Warning: Received unusual Age: {v}")
        return v

    @validator('systolicBP')
    def sbp_range(cls, v):
        if v < 40 or v > 250:  # Example reasonable range
            print(f"Warning: Received unusual SystolicBP: {v}")
        return v

    @validator('diastolicBP')
    def dbp_range(cls, v):
        if v < 30 or v > 150:  # Example reasonable range
            print(f"Warning: Received unusual DiastolicBP: {v}")
        return v

    @validator('bs')
    def bs_range(cls, v):
        if v < 1 or v > 30:  # Example reasonable range (units dependent)
            print(f"Warning: Received unusual BS: {v}")
        return v

    @validator('bodyTemp')
    def temp_range(cls, v):
         # Convert Celsius to Fahrenheit if temp seems low (common mistake)
         if v < 50:  # Very unlikely F temp, possibly C?
             temp_f = (v * 9/5) + 32
             print(f"Warning: Received low BodyTemp {v}. Assuming Celsius, converted to {temp_f:.1f} F.")
             v = round(temp_f, 1)
         if v < 90 or v > 110:  # Example reasonable Fahrenheit range
             print(f"Warning: Received unusual BodyTemp (F): {v}")
         return v

    @validator('heartRate')
    def hr_range(cls, v):
        if v < 30 or v > 200:  # Example reasonable range
            print(f"Warning: Received unusual HeartRate: {v}")
        return v

    class Config:
        allow_population_by_field_name = True  # Allows using aliases like 'bs'
        anystr_strip_whitespace = True  # Remove leading/trailing whitespace from strings

class PredictionOutput(BaseModel):
    predicted_risk_level: str = Field(..., example="mid risk")
    advice_message: str = Field(..., example="Your risk level is moderate...")
    probabilities: Dict[str, float] = Field(..., example={"low risk": 0.2, "mid risk": 0.6, "high risk": 0.2})


# --- Health Advice Messages (Enhanced) ---
HEALTH_ADVICE = {
    "low risk": (
        "Prediction: Low Risk.\n\n"
        "This is positive news! To maintain this:\n"
        "• Continue with your regular prenatal check-ups.\n"
        "• Eat a balanced diet rich in fruits, vegetables, lean protein, and whole grains.\n"
        "• Stay hydrated by drinking plenty of water.\n"
        "• Engage in moderate exercise as approved by your doctor (e.g., walking, swimming).\n"
        "• Get adequate rest and manage stress levels.\n"
        "• Monitor for any new symptoms and report them to your provider."
    ),
    "mid risk": (
        "Prediction: Moderate Risk.\n\n"
        "This suggests paying closer attention to your health. Key recommendations:\n"
        "• Strictly follow your healthcare provider's advice regarding diet, activity, and any prescribed medications.\n"
        "• Attend *all* scheduled prenatal appointments; more frequent visits might be needed.\n"
        "• Monitor your blood pressure and blood sugar at home if recommended by your doctor.\n"
        "• Be vigilant for warning signs: severe headaches, vision changes (blurriness, spots), significant swelling (hands, face), abdominal pain, or reduced fetal movement. Report these immediately.\n"
        "• Discuss stress management techniques with your provider."
    ),
    "high risk": (
        "Prediction: High Risk.\n\n"
        "This requires careful management and close monitoring. Please prioritize the following:\n"
        "• Adhere strictly to the management plan created by your healthcare team. This is crucial.\n"
        "• Attend all appointments, including any specialist consultations recommended.\n"
        "• Follow specific dietary and activity restrictions given by your doctor precisely.\n"
        "• Take all prescribed medications exactly as directed.\n"
        "• Report *any* concerning symptoms immediately to your provider or seek emergency care. These include severe headaches, vision problems, shortness of breath, chest pain, severe abdominal pain, sudden swelling, or changes in fetal movement.\n"
        "• Ensure you have a plan for urgent medical attention if needed."
    )
}

# --- FastAPI App Initialization ---
# Add description and contact info for documentation
description = """
MamaCare API helps predict maternal health risk based on key indicators.
Upload patient data to receive a risk level prediction and relevant health advice.

**Disclaimer:** This prediction is based on a machine learning model and is **not** a substitute for professional medical diagnosis or advice. Always consult with a qualified healthcare provider for any health concerns or before making any decisions related to your health or treatment.
"""

app = FastAPI(
    title="MamaCare Maternal Risk Predictor",
    description=description,
    version="1.1.0",
    contact={
        "name": "Developer Name/Team",  # Optional: Add your name/contact
        "url": "http://example.com/contact",  # Optional
        "email": "developer@example.com",  # Optional
    },
    openapi_tags=[  # Define tags for better Swagger UI organization
        {"name": "Health Check", "description": "Check API status."},
        {"name": "Prediction", "description": "Predict maternal health risk."},
    ]
)


# --- CORS Middleware ---
# More specific origins are better for production
origins = [
    "http://localhost",
    "http://localhost:8000",  # Common local dev ports
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8000",
    # Add your Flutter app's deployed URL here eventually
    # Example: "https://your-flutter-app.web.app"
]

app.add_middleware(
    CORSMiddleware,
    # allow_origins=origins,  # Use specific origins in production
    allow_origins=["*"],  # Allow all for easier initial testing
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # Be specific about allowed methods
    allow_headers=["*"],  # Allow common headers
)

# --- Helper Function to Check Model Loading (Dependency) ---
async def get_model_components():
    """Dependency to provide loaded model components or raise an error."""
    if model_load_error or not all([loaded_pipeline, loaded_label_encoder, loaded_features]):
        print(f"Model Check Failed: {model_load_error}")  # Log error server-side
        raise HTTPException(
            status_code=503,  # Service Unavailable
            detail=f"Model components are not available. Server error: {model_load_error}"
        )
    return {
        "pipeline": loaded_pipeline,
        "encoder": loaded_label_encoder,
        "features": loaded_features
    }

# --- API Endpoints ---
@app.get("/", tags=["Health Check"])
async def read_root(request: Request):
    """
    Basic health check endpoint. Returns API status and documentation link.
    """
    return {
        "status": "MamaCare API is running!",
        "docs_url": str(request.url_for('swagger_ui_html')),  # Provides link to Swagger UI
        "redoc_url": str(request.url_for('redoc_html')),  # Provides link to ReDoc
        "model_status": "Loaded" if model_load_error is None else f"Error ({model_load_error})"
        }

@app.post("/predict",
          response_model=PredictionOutput,
          tags=["Prediction"],
          summary="Predict Maternal Health Risk",
          description="Receives maternal health indicators and returns a predicted risk level ('low risk', 'mid risk', 'high risk') along with health advice and class probabilities.")
async def predict_risk(
    input_data: PredictionInput,
    model_components: dict = Depends(get_model_components)  # Use the dependency
    ):
    """
    Processes the input data and returns the maternal health risk prediction.

    - **Input Data:** Requires Age, SystolicBP, DiastolicBP, BS, BodyTemp, HeartRate.
    - **Output:** Predicted risk level, health advice, and probabilities for each risk class.
    """
    pipeline = model_components["pipeline"]
    encoder = model_components["encoder"]
    features = model_components["features"]

    try:
        # 1. Create dictionary mapping expected feature names (keys)
        #    to values from the validated input_data object (values)
        input_dict_for_df = {
            'Age': [input_data.age],                      # Use input_data.age (lowercase)
            'SystolicBP': [input_data.systolicBP],        # Use input_data.systolicBP
            'DiastolicBP': [input_data.diastolicBP],      # Use input_data.diastolicBP
            'BS': [input_data.bs],                        # Use input_data.bs
            'BodyTemp': [input_data.bodyTemp],            # Use input_data.bodyTemp (gets the validated/converted value)
            'HeartRate': [input_data.heartRate]           # Use input_data.heartRate
        }

        # Create DataFrame using the correctly mapped dictionary
        # The keys ('Age', 'SystolicBP', etc.) now match loaded_features
        input_df = pd.DataFrame.from_dict(input_dict_for_df)

        # Ensure columns are in the exact order model expects
        # This reorders the DataFrame columns based on the loaded list, just in case
        input_df = input_df[features]  # Use the features list loaded from the dependency

        # 2. Make Prediction (Encoded) & Get Probabilities
        pred_encoded = pipeline.predict(input_df)
        pred_proba = pipeline.predict_proba(input_df)

        # 3. Decode Prediction
        pred_label = encoder.inverse_transform(pred_encoded)[0]  # Get the string label

        # 4. Get Probabilities into a nice dictionary format
        probabilities_dict = {class_name: round(prob, 4) for class_name, prob in zip(encoder.classes_, pred_proba[0])}

        # 5. Get Corresponding Health Advice
        advice = HEALTH_ADVICE.get(pred_label, "Consult your healthcare provider for personalized advice.")  # Use the updated default

        # 6. Return Results
        return PredictionOutput(
            predicted_risk_level=pred_label,
            advice_message=advice,
            probabilities=probabilities_dict
        )

    except AttributeError as ae:  # Specifically catch attribute errors if they occur elsewhere
        print(f"AttributeError during prediction data handling: {ae}")
        raise HTTPException(status_code=500, detail="Internal error processing input attributes.")
    except Exception as e:
        print(f"Prediction Error: {e}")  # Log the error for debugging
        # Don't expose detailed internal errors to the client
        raise HTTPException(status_code=500, detail=f"An internal error occurred during prediction.")

# --- Optional: Add uvicorn runner for local testing ---
# This allows running 'python main.py' directly
if __name__ == "__main__":
    import uvicorn
    print("--- Starting MamaCare FastAPI Server Locally ---")
    print("Access documentation at http://127.0.0.1:8000/docs")
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)  # reload=True is useful for development