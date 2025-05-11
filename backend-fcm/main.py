import os
from typing import Dict, List, Optional

import firebase_admin
from firebase_admin import credentials, exceptions, messaging, firestore
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from enum import Enum
import logging

# --- Configuration & Initialization ---

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
load_dotenv()

firebase_initialized = False
firebase_init_error = None
db = None

try:
    # Check if default app already exists to prevent errors on reload
    if not firebase_admin._apps:
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if not cred_path:
            raise ValueError("GOOGLE_APPLICATION_CREDENTIALS environment variable not set.")
        if not os.path.exists(cred_path):
            raise FileNotFoundError(f"Service account key file not found at: {cred_path}")

        logger.debug("Default Firebase app not found, attempting initialization...")
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully.")
        firebase_initialized = True
        db = firestore.client()  # Initialize Firestore client AFTER successful init
    else:
        logger.info("Default Firebase app already initialized. Skipping initialization.")
        firebase_initialized = True  # Assume it was initialized successfully before
        if not db:  # Ensure db is assigned if we skipped init but need the client
            db = firestore.client()

except Exception as e:
    firebase_init_error = e
    logger.fatal(f"Error during Firebase Admin SDK setup: {e}", exc_info=True)
    firebase_initialized = False
    db = None


# --- Pydantic Models ---
class TargettedNotificationPayload(BaseModel):
    token: str = Field(..., description="The FCM registration token of the target device.")
    title: str = Field(..., description="The title of the notification.")
    body: str = Field(..., description="The body content of the notification.")
    data: Optional[Dict[str, str]] = Field(None, description="Optional key-value data payload (all values must be strings).")


class DoctorAppointmentNotificationPayload(BaseModel):
    doctor_id: str = Field(..., description="The user ID of the doctor to notify.")
    title: str = Field(..., description="The title of the notification.")
    body: str = Field(..., description="The body content of the notification.")
    data: Optional[Dict[str, str]] = Field(None, description="Optional key-value data payload (all values must be strings).")


class AppointmentStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SCHEDULED = "scheduled" # Assuming you might have this from Flutter logs elsewhere
    COMPLETED = "completed"
    DECLINED_DOCTOR = "declined_doctor"
    CANCELLED_PATIENT = "cancelled_patient"
    DECLINED = "declined" # *** ADD THIS LINE *** 
    # Add other statuses as needed


class UpdateAppointmentStatusPayload(BaseModel):
    appointment_id: str = Field(..., description="The ID of the appointment being updated.")
    new_status: AppointmentStatus = Field(..., description="The new status for the appointment.")
    # Optional: Include doctor_id for verification/logging
    doctor_id: Optional[str] = Field(None, description="ID of the doctor performing the action.")
    # Optional: Include cancellation reason etc.
    cancellation_reason: Optional[str] = Field(None, description="Reason for cancellation.")


# --- FastAPI Application ---
app = FastAPI(
    title="FCM Notification Sender",
    description="API to send Firebase Cloud Messages using a Service Account.",
    version="1.0.0",
)


# --- Helper Functions ---
async def get_user_fcm_tokens(user_id: str, user_type: str = "user") -> List[str]:
    """
    Retrieves FCM token(s) for a given user ID from Firestore.
    
    Args:
        user_id: The ID of the user whose tokens should be retrieved
        user_type: Type of user for logging (e.g., "doctor", "patient")
        
    Returns:
        List[str]: List of valid FCM tokens for the user
    """
    if not db:
        logger.error(f"Firestore client not initialized. Cannot get {user_type} tokens.")
        return []
        
    try:
        # IMPORTANT: Adjust 'users' and 'fcmTokens' if your collection/field names differ
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()  # Using sync get

        if user_doc.exists:
            user_data = user_doc.to_dict()
            tokens = user_data.get('fcmTokens')  # Adjust field name if needed
            
            if isinstance(tokens, list):
                valid_tokens = [token for token in tokens if token and isinstance(token, str)]
                if not valid_tokens:
                    logger.warning(f"No valid FCM tokens found in list for {user_type} {user_id}.")
                    return []
                logger.debug(f"Found {len(valid_tokens)} FCM token(s) for {user_type} {user_id}.")
                return valid_tokens
            elif isinstance(tokens, str) and tokens:
                logger.debug(f"Found single FCM token string for {user_type} {user_id}.")
                return [tokens]
            else:
                logger.warning(f"'fcmTokens' field is missing or not a list/string for {user_type} {user_id}.")
                return []
        else:
            logger.warning(f"{user_type.capitalize()} user document not found for ID: {user_id}")
            return []
    except Exception as e:
        logger.error(f"Error fetching tokens for {user_type} {user_id} from Firestore: {e}", exc_info=True)
        return []


async def get_doctor_fcm_tokens(doctor_id: str) -> List[str]:
    """
    Retrieves FCM token(s) for a given doctor ID from Firestore.
    """
    return await get_user_fcm_tokens(doctor_id, "doctor")


async def get_patient_fcm_tokens(patient_id: str) -> List[str]:
    """
    Retrieves FCM token(s) for a given patient ID from Firestore.
    """
    return await get_user_fcm_tokens(patient_id, "patient")


async def remove_unregistered_token(user_id: str, invalid_token: str) -> bool:
    """
    Removes an invalid/unregistered FCM token from a user's document in Firestore.
    
    Args:
        user_id: The ID of the user whose token should be removed
        invalid_token: The invalid token to remove
        
    Returns:
        bool: True if token was successfully removed, False otherwise
    """
    if not db:
        logger.error("Firestore client not initialized. Cannot remove token.")
        return False
    
    try:
        # Get the user document reference
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            logger.warning(f"Cannot remove token: User document not found for ID: {user_id}")
            return False
            
        user_data = user_doc.to_dict()
        tokens = user_data.get('fcmTokens')
        
        # Handle different token storage formats
        if isinstance(tokens, list):
            if invalid_token in tokens:
                # Remove the invalid token from the list
                tokens.remove(invalid_token)
                # Update the user document with the filtered tokens list
                user_ref.update({'fcmTokens': tokens})
                logger.debug(f"Successfully removed invalid token for user {user_id}")
                return True
            else:
                logger.warning(f"Token {invalid_token[:10]}... not found in user {user_id}'s tokens list")
                return False
                
        elif isinstance(tokens, str) and tokens == invalid_token:
            # If it's a single string token and it matches the invalid one, set to empty string or remove field
            user_ref.update({'fcmTokens': firestore.DELETE_FIELD})
            logger.info(f"Removed only FCM token for user {user_id}")
            return True
            
        else:
            logger.warning(f"Cannot remove token: Unexpected fcmTokens format for user {user_id}")
            return False
            
    except Exception as e:
        logger.error(f"Error removing invalid token for user {user_id}: {e}", exc_info=True)
        return False


async def send_notifications_to_user(user_id: str, user_type: str, title: str, body: str, 
                                     data: Optional[Dict[str, str]] = None,
                                     high_priority: bool = False) -> Dict:
    """
    Sends notifications to all tokens of a user with proper error handling.
    
    Args:
        user_id: The ID of the user to notify
        user_type: Type of user ("doctor", "patient", etc.) for logging
        title: Notification title
        body: Notification body
        data: Optional data payload
        high_priority: Whether to send as high priority notification
        
    Returns:
        Dict: Results summary
    """
    if not firebase_initialized:
        logger.error(f"Cannot send notifications to {user_type} {user_id}: Firebase not initialized")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail="Firebase services not initialized"
        )
    
    # Get tokens based on user_type
    tokens = []
    if user_type == "doctor":
        tokens = await get_doctor_fcm_tokens(user_id)
    elif user_type == "patient":
        tokens = await get_patient_fcm_tokens(user_id)
    else:
        tokens = await get_user_fcm_tokens(user_id, user_type)
        
    if not tokens:
        logger.warning(f"No valid FCM tokens found for {user_type} {user_id}")
        return {
            "status": "no_target",
            "message": f"No FCM tokens available for {user_type} {user_id}"
        }
    
    # Create notification object
    notification = messaging.Notification(title=title, body=body)
    
    # Platform-specific configurations
    android_config = None
    apns_config = None
    if high_priority:
        android_config = messaging.AndroidConfig(priority='high')
        apns_config = messaging.APNSConfig(headers={'apns-priority': '10'})
    
    # Track results
    success_count = 0
    failure_count = 0
    tokens_removed = 0
    
    # Send to each token
    for token in tokens:
        message = messaging.Message(
            notification=notification,
            token=token,
            data=data,
            android=android_config,
            apns=apns_config
        )
        
        try:
            response = messaging.send(message)
            success_count += 1
            logger.debug(f"Successfully sent notification to {user_type} {user_id} token {token[-10:]}...")
        except messaging.UnregisteredError:
            logger.warning(f"Unregistered token for {user_type} {user_id}: {token[-10:]}...")
            failure_count += 1
            
            # Try to remove the invalid token
            if await remove_unregistered_token(user_id, token):
                tokens_removed += 1
        except exceptions.FirebaseError as e:
            logger.error(f"Firebase error sending to {user_type} {user_id}: {e}")
            failure_count += 1
        except Exception as e:
            logger.error(f"Unexpected error sending to {user_type} {user_id}: {e}", exc_info=True)
            failure_count += 1
    
    # Determine overall status
    final_status = "success"
    if success_count == 0 and failure_count > 0:
        final_status = "failure"
    elif failure_count > 0:
        final_status = "partial_success"
        
    return {
        "status": final_status,
        "success_count": success_count,
        "failure_count": failure_count, 
        "tokens_targeted": len(tokens),
        "tokens_removed": tokens_removed
    }


# --- API Endpoints ---
@app.get("/", tags=["Health Check"])
async def read_root():
    """Health check endpoint to verify service status."""
    init_status = "Initialized" if firebase_initialized else f"Initialization FAILED: {firebase_init_error}"
    db_status = "Connected" if db else "Not Connected"
    return {
        "status": "Server running", 
        "firebase_admin_status": init_status, 
        "firestore_status": db_status
    }


@app.post("/send-notification-direct", tags=["Notifications"])
async def send_fcm_notification_direct(payload: TargettedNotificationPayload):
    """Sends a notification to a specific device token using FCM."""
    if not firebase_initialized:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail=f"Firebase Admin SDK not initialized: {firebase_init_error}"
        )

    message = messaging.Message(
        notification=messaging.Notification(title=payload.title, body=payload.body),
        token=payload.token,
        data=payload.data if payload.data else None,
    )
    try:
        response = messaging.send(message)
        logger.info(f"Successfully sent direct message to token {payload.token[:10]}...: {response}")
        return {"status": "success", "message_id": response}
    except messaging.UnregisteredError as e:
        logger.warning(f"Device token is unregistered or invalid: {payload.token}. Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Device token is unregistered or invalid: {e}"
        )
    except messaging.InvalidArgumentError as e:
        logger.error(f"Invalid argument provided for FCM message: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Invalid argument provided for FCM message: {e}"
        )
    except exceptions.FirebaseError as e:
        logger.error(f"Firebase error sending direct FCM message: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Firebase error sending notification: {e}"
        )
    except Exception as e:
        logger.error(f"An unexpected error occurred sending direct notification: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"An unexpected server error occurred: {e}"
        )


@app.post("/notify-doctor-appointment", tags=["Notifications"])
async def notify_doctor_appointment(payload: DoctorAppointmentNotificationPayload):
    """
    Notifies a specific doctor about a new appointment request.
    Looks up the doctor's FCM token(s) from Firestore and sends individual messages.
    """
    return await send_notifications_to_user(
        user_id=payload.doctor_id,
        user_type="doctor",
        title=payload.title,
        body=payload.body,
        data=payload.data
    )


@app.put("/update-appointment-status", tags=["Appointments"])
async def update_appointment_status(payload: UpdateAppointmentStatusPayload):
    """
    Updates the status of an appointment and notifies the patient.
    """
    if not firebase_initialized or not db:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail="Backend services not fully initialized."
        )

    appointment_ref = db.collection('appointments').document(payload.appointment_id)

    try:
        # --- Step 1: Update Firestore Appointment Status ---
        logger.info(f"Updating status for appointment {payload.appointment_id} to {payload.new_status.value}")
        appointment_snapshot = appointment_ref.get()
        if not appointment_snapshot.exists:
            logger.error(f"Appointment {payload.appointment_id} not found.")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="Appointment not found."
            )

        appointment_data = appointment_snapshot.to_dict()
        patient_id = appointment_data.get('patientId')  # Get patient ID from appointment
        doctor_id_original = appointment_data.get('doctorId')  # Get doctor ID

        if not patient_id:
            logger.error(f"Patient ID missing in appointment data for {payload.appointment_id}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail="Appointment data incomplete."
            )

        # Optional: Verify doctor ID matches if provided in payload
        if payload.doctor_id and payload.doctor_id != doctor_id_original:
            logger.warning(f"Doctor ID mismatch: expected {doctor_id_original}, got {payload.doctor_id}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Not authorized to update this appointment."
            )

        update_data = {
            'status': payload.new_status.value,
            'statusLastUpdatedAt': firestore.SERVER_TIMESTAMP,  # Track update time
        }
        if payload.cancellation_reason:
            update_data['cancellationReason'] = payload.cancellation_reason

        appointment_ref.update(update_data)
        logger.info(f"Successfully updated status for appointment {payload.appointment_id}.")

        # --- Step 2: Prepare notification content ---
        doctor_name = appointment_data.get('doctorName', 'your doctor')
        notif_title = f"Appointment {payload.new_status.name.capitalize()}"  # e.g., Appointment Confirmed
        notif_body = f"Your appointment with Dr. {doctor_name} has been {payload.new_status.value}."
        
        if payload.new_status == AppointmentStatus.DECLINED_DOCTOR and payload.cancellation_reason:
            notif_body += f" Reason: {payload.cancellation_reason}"

        # Data payload for patient app interaction
        data_payload_patient = {
            "type": "appointment_update",
            "appointmentId": payload.appointment_id,
            "newStatus": payload.new_status.value,
            "route": f"/appointments/detail/{payload.appointment_id}"  # Example route
        }

        # --- Step 3: Send notification to patient ---
        notification_result = await send_notifications_to_user(
            user_id=patient_id,
            user_type="patient",
            title=notif_title,
            body=notif_body,
            data=data_payload_patient,
            high_priority=True
        )
        
        # Return combined result
        return {
            "status": "success",
            "message": f"Appointment status updated to {payload.new_status.value}",
            "notification_result": notification_result
        }

    except HTTPException:
        raise  # Re-raise HTTP exceptions directly
    except Exception as e:
        logger.error(f"Error updating appointment status for {payload.appointment_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Failed to update appointment status: {e}"
        )

# --- Run command ---
# uvicorn main:app --reload --host 0.0.0.0 --port 8000