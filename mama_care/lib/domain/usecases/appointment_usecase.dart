// lib/domain/usecases/appointment_usecase.dart

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp
import 'package:mama_care/data/repositories/appointment_repository.dart';
import 'package:mama_care/data/repositories/user_repository.dart'; // Assuming UserRepository exists and provides getUserById
// Removed DoctorRepository import, assuming doctors are fetched via UserRepository
// import 'package:mama_care/data/repositories/doctor_repository.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import Enum
import 'package:mama_care/domain/entities/user_model.dart'; // Assuming UserModel is used for both patients and doctors
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/user_role.dart'; // Import custom exceptions for better error handling

@injectable
class AppointmentUseCase {
  final AppointmentRepository _appointmentRepository;
  // We need a way to get user details (patient and doctor) by ID
  final UserRepository _userRepository;
  final Logger _logger;

  AppointmentUseCase(
    this._appointmentRepository,
    this._userRepository, // Inject UserRepository
    this._logger,
  );

  /// Creates a new appointment request after fetching patient and doctor names.
  Future<Appointment> requestAppointment({
    required String patientId,
    required String doctorId,
    required String reason,
    required DateTime dateTime, // Accept DateTime from UI/ViewModel
    String? notes,
  }) async {
    _logger.d(
      "UseCase: Requesting new appointment for patient '$patientId' with doctor '$doctorId'",
    );
    try {
      // Fetch patient details to get the name
      final patient = await _userRepository.getUserById(patientId);
      if (patient == null) {
        _logger.e("UseCase: Patient with ID '$patientId' not found.");
        throw DataNotFoundException(
          "Patient details could not be found.",
        ); // Use specific exception
      }

      // Fetch doctor details to get the name (using UserRepository)
      final doctor = await _userRepository.getUserById(doctorId);
      if (doctor == null) {
        _logger.e("UseCase: Doctor with ID '$doctorId' not found.");
        throw DataNotFoundException(
          "Selected doctor could not be found.",
        ); // Use specific exception
      }
      // Optional: Check if the fetched doctor actually has the 'doctor' role
      if (doctor.role != UserRole.doctor) {
        _logger.e(
          "UseCase: User with ID '$doctorId' is not a doctor (role: ${doctor.role}).",
        );
        throw InvalidArgumentException("Selected user is not a valid doctor.");
      }

      // Create the Appointment entity with denormalized names and correct types
      final appointment = Appointment(
        patientId: patientId,
        doctorId: doctorId,
        patientName: patient.name, // Denormalized name
        doctorName: doctor.name, // Denormalized name
        dateTime: Timestamp.fromDate(
          dateTime,
        ), // Convert input DateTime to Firestore Timestamp
        reason: reason.trim(),
        notes:
            notes?.trim().isEmpty ?? true
                ? null
                : notes!.trim(), // Handle empty notes
        status: AppointmentStatus.pending, // Initial status using Enum
        createdAt:
            Timestamp.now(), // Use current Timestamp (repo will use server time)
        // updatedAt will be set by the repository on creation/update
      );

      _logger.d("UseCase: Calling repository to create appointment...");
      // Call the repository to create the appointment in Firestore
      final appointmentId = await _appointmentRepository.createAppointment(
        appointment,
      );
      _logger.i("UseCase: Successfully created appointment '$appointmentId'.");

      final createdAppointment = await _appointmentRepository
          .getAppointmentById(appointmentId);
      if (createdAppointment == null) {
        _logger.e(
          "UseCase: Failed to fetch created appointment $appointmentId immediately after creation.",
        );
        // Fallback: return the object we tried to create, ID might be wrong if repo didn't return it correctly
        // Or throw a specific error
        throw DomainException(
          "Failed to confirm appointment creation details.",
        );
      }
      return createdAppointment; // <<< RETURN CREATED OBJECT
    } on AppException catch (e) {
      _logger.e("UseCase: Failed to request appointment ($e)");
      rethrow;
    } catch (e, s) {
      _logger.e(
        "UseCase: Unexpected error requesting appointment",
        error: e,
        stackTrace: s,
      );
      throw DomainException(
        "Could not complete appointment request.",
        cause: e,
      );
    }
  }

  /// Gets appointments for a specific patient, optionally filtered by status.
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
  }) async {
    _logger.d(
      "UseCase: Getting appointments for patient '$patientId' (status: ${status?.name ?? 'all'})",
    );
    try {
      // Directly call repository method, passing the enum status
      final appointments = await _appointmentRepository.getPatientAppointments(
        patientId,
        status: status,
      );
      _logger.i(
        "UseCase: Retrieved ${appointments.length} appointments for patient '$patientId'.",
      );
      return appointments;
    } catch (e, stackTrace) {
      _logger.e(
        "UseCase: Failed to get patient appointments for '$patientId'",
        error: e,
        stackTrace: stackTrace,
      );
      // Rethrow allows specific repository exceptions (ApiException, etc.) to pass through
      rethrow;
    }
  }

  /// Gets appointments for a specific doctor, optionally filtered by status.
  Future<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    AppointmentStatus? status,
  }) async {
    _logger.d(
      "UseCase: Getting appointments for doctor '$doctorId' (status: ${status?.name ?? 'all'})",
    );
    try {
      // Directly call repository method, passing the enum status
      final appointments = await _appointmentRepository.getDoctorAppointments(
        doctorId,
        status: status,
      );
      _logger.i(
        "UseCase: Retrieved ${appointments.length} appointments for doctor '$doctorId'.",
      );
      return appointments;
    } catch (e, stackTrace) {
      _logger.e(
        "UseCase: Failed to get doctor appointments for '$doctorId'",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Gets all appointments associated with a user (as patient or doctor).
  Future<List<Appointment>> getUserAppointments(String userId) async {
    _logger.d("UseCase: Getting all appointments for user '$userId'");
    try {
      final appointments = await _appointmentRepository.getUserAppointments(
        userId,
      );
      _logger.i(
        "UseCase: Retrieved ${appointments.length} total appointments for user '$userId'.",
      );
      return appointments;
    } catch (e, stackTrace) {
      _logger.e(
        "UseCase: Failed to get user appointments for '$userId'",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates the status of an existing appointment.
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    _logger.d(
      "UseCase: Updating appointment '$appointmentId' status to ${status.name}",
    );
    try {
      // Optional: Add business logic here, e.g.,
      // - Check if the status transition is valid (e.g., can't go from completed to pending).
      // - Check if the user performing the action has the permission (e.g., only doctor can confirm).
      //   (Though ownership checks might be better handled in the repository or security rules).

       final currentAppointment = await _appointmentRepository.getAppointmentById(appointmentId);
       if (currentAppointment == null) throw DataNotFoundException("Appointment to update not found.");
       if (!_isValidStatusTransition(currentAppointment.status, status)) {
          throw InvalidArgumentException("Invalid status transition from ${currentAppointment.status.name} to ${status.name}");
       }

      // Call repository to update the status
      await _appointmentRepository.updateAppointmentStatus(
        appointmentId,
        status,
      ); // Pass Enum
      _logger.i(
        "UseCase: Successfully updated appointment '$appointmentId' status to ${status.name}",
      );
    } catch (e, stackTrace) {
      _logger.e(
        "UseCase: Failed to update status for appointment '$appointmentId'",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    _logger.d("UseCase: Deleting appointment '$appointmentId'");
     if (appointmentId.isEmpty) {
       throw InvalidArgumentException("Appointment ID cannot be empty for deletion.");
    }
    try {
      // Optional: Fetch appointment to check status/permissions before deleting
       final appointment = await _appointmentRepository.getAppointmentById(appointmentId);
       if (appointment == null) throw DataNotFoundException("Appointment to delete not found.");
       if (!appointment.status.canBeDeletedByDoctor) { // Check if deletion is allowed based on status
          throw InvalidOperationException("Appointment cannot be deleted in its current state (${appointment.status.displayName}).");
       }

      // Call repository to perform the deletion
      await _appointmentRepository.deleteAppointment(appointmentId);
      _logger.i("UseCase: Successfully deleted appointment '$appointmentId'.");

    } on AppException catch(e) {
        _logger.e("UseCase: Failed to delete appointment $appointmentId ($e)");
        rethrow;
    } catch (e, stackTrace) {
      _logger.e("UseCase: Unexpected error deleting appointment $appointmentId", error: e, stackTrace: stackTrace);
      throw DomainException("Could not delete the appointment.", cause: e);
    }
  }

  /// Cancels an appointment (typically initiated by a patient).
  Future<void> cancelAppointment(String appointmentId) async {
    _logger.d("UseCase: Cancelling appointment '$appointmentId'");
    try {
      // Fetch the appointment to check its current status
      final appointment = await _appointmentRepository.getAppointmentById(
        appointmentId,
      );
      if (appointment == null) {
        throw DataNotFoundException("Appointment to cancel not found.");
      }

      // Business logic: Check if the appointment is in a cancellable state
      if (appointment.status == AppointmentStatus.completed ||
          appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.declined) {
        _logger.w(
          "UseCase: Attempted to cancel appointment ${appointment.id} with non-cancellable status ${appointment.status.name}",
        );
        // Use a specific exception type if available
        throw InvalidOperationException(
          "Cannot cancel an appointment that is already ${appointment.status.name}.",
        );
      }

      // Call repository to update the status to cancelled
      await _appointmentRepository.updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.cancelled,
      );
      _logger.i("UseCase: Cancelled appointment '$appointmentId'");
    } on DataNotFoundException catch (e) {
      // Catch specific exceptions
      _logger.e(
        "UseCase: Failed to cancel appointment $appointmentId",
        error: e,
      );
      rethrow;
    } on InvalidOperationException catch (e) {
      _logger.e(
        "UseCase: Failed to cancel appointment $appointmentId",
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      // Catch general errors
      _logger.e(
        "UseCase: Unexpected error cancelling appointment $appointmentId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DomainException("Could not cancel the appointment.", cause: e);
    }
  }

  Future<Appointment?> getAppointmentById(String appointmentId) async {
    _logger.d("UseCase: Getting appointment details for ID '$appointmentId'");
    try {
      final appointment = await _appointmentRepository.getAppointmentById(
        appointmentId,
      );
      if (appointment == null) {
        _logger.w(
          "UseCase: Appointment with ID '$appointmentId' not found by repository.",
        );
        return null; // Or throw DataNotFoundException("Appointment not found.");
      }
      _logger.i("UseCase: Retrieved appointment details for '$appointmentId'.");
      return appointment;
    } catch (e, stackTrace) {
      _logger.e(
        "UseCase: Failed to get appointment by ID '$appointmentId'",
        error: e,
        stackTrace: stackTrace,
      );
      // Rethrow allows specific repository exceptions to pass through
      rethrow;
    }
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDateTime,
  ) async {
    _logger.d(
      "UseCase: Rescheduling appointment '$appointmentId' to $newDateTime",
    );

    // Basic validation
    if (appointmentId.isEmpty) {
      throw InvalidArgumentException("Appointment ID cannot be empty.");
    }
    // Optional: Check if newDateTime is in the past (UI should prevent this ideally)
    if (newDateTime.isBefore(DateTime.now())) {
      throw InvalidArgumentException("Cannot reschedule to a past date/time.");
    }

    try {
      // Optional: Fetch original to perform business logic checks
      final originalAppointment = await _appointmentRepository
          .getAppointmentById(appointmentId);
      if (originalAppointment == null) {
        throw DataNotFoundException("Appointment to reschedule not found.");
      }
      if (!originalAppointment.status.canBeRescheduled) {
        // Use extension method
        throw InvalidOperationException(
          "Appointment cannot be rescheduled in its current state (${originalAppointment.status.displayName}).",
        );
      }

      // Convert DateTime to Firestore Timestamp before passing to repository
      final Timestamp newTimestamp = Timestamp.fromDate(newDateTime);

      // Call repository to update the date/time
      await _appointmentRepository.updateAppointmentDateTime(
        appointmentId,
        newTimestamp,
      );
      _logger.i(
        "UseCase: Successfully rescheduled appointment '$appointmentId'.",
      );
    } on AppException catch (e) {
      // Catch specific exceptions first
      _logger.e(
        "UseCase: Failed to reschedule appointment $appointmentId ($e)",
      );
      rethrow; // Let specific errors bubble up
    } catch (e, stackTrace) {
      // Catch unexpected errors
      _logger.e(
        "UseCase: Unexpected error rescheduling appointment $appointmentId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DomainException("Could not reschedule the appointment.", cause: e);
    }
  }

  // Optional: Helper for status transition logic
   bool _isValidStatusTransition(AppointmentStatus from, AppointmentStatus to) {
      // Implement rules here, e.g.
      if (from == AppointmentStatus.completed) return false; // Cannot change from completed
      if (from == AppointmentStatus.cancelled && to != AppointmentStatus.pending) return false; // Maybe allow re-pending?
      // ... other rules
      return true;
   }
}
