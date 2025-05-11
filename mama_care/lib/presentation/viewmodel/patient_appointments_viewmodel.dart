// lib/presentation/viewmodel/patient_appointments_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import Enum and helpers
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel
import 'package:mama_care/domain/entities/user_role.dart'; // Import UserRole enum
import 'package:mama_care/core/error/exceptions.dart'; // Import custom exceptions
// Removed Firestore/FirebaseAuth imports, handled by AuthViewModel

@injectable
class PatientAppointmentsViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final AuthViewModel
  _authViewModel; // Inject AuthViewModel (ensure it's a singleton)
  final Logger _logger;

  // --- State Variables ---
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  AppointmentStatus?
  _selectedStatusFilter; // Use nullable enum for filter, null = 'all'

  // --- Getters ---
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppointmentStatus? get selectedStatusFilter => _selectedStatusFilter;

  // --- Constructor ---
  PatientAppointmentsViewModel(
    this._appointmentUseCase,
    this._authViewModel, // Receive the singleton AuthViewModel instance
    this._logger,
  ) {
    _logger.i("PatientAppointmentsViewModel initialized");
    // Listen to auth changes to load/clear data
    _authViewModel.addListener(_handleAuthChange);
    // Initial load if already logged in as patient
    _handleAuthChange(); // Call initially
  }

  // --- Auth Listener ---
  void _handleAuthChange() {
    final bool wasPatient =
        _appointments.isNotEmpty || _isLoading || _error != null;
    final bool isPatient =
        _authViewModel.isAuthenticated &&
        _authViewModel.localUser?.role == UserRole.patient;

    if (!isPatient && wasPatient) {
      _logger.w(
        "Auth state changed (not a logged-in patient), clearing patient appointments.",
      );
      _appointments = [];
      _error = null;
      _selectedStatusFilter = null; // Reset filter
      _setLoading(false);
      notifyListeners();
    } else if (isPatient &&
        _appointments.isEmpty &&
        !_isLoading &&
        _error == null) {
      _logger.i(
        "Auth state shows logged-in patient, triggering appointment load.",
      );
      loadPatientAppointments();
    } else if (isPatient && !wasPatient && !_isLoading) {
      _logger.i(
        "Auth state changed to patient, ensuring data load is triggered.",
      );
      loadPatientAppointments();
    }
  }

  // --- State Helpers ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_error == message) return;
    _error = message;
    if (message != null)
      _logger.e("PatientAppointmentsViewModel Error: $message");
    notifyListeners();
  }

  void clearError() => _setError(null);

  // --- Public Methods ---

  /// Sets the filter status and reloads appointments. Pass null for 'all'.
  Future<void> setStatusFilter(AppointmentStatus? status) async {
    if (_selectedStatusFilter == status) return; // No change

    _selectedStatusFilter = status;
    _logger.i(
      "Status filter changed to: ${_selectedStatusFilter?.name ?? 'all'}",
    );
    notifyListeners(); // Update UI filter selection
    await loadPatientAppointments(); // Reload with new filter
  }

  /// Loads appointments for the currently logged-in patient.
  Future<void> loadPatientAppointments() async {
    if (_isLoading) return;

    _setLoading(true);
    _setError(null);

    try {
      _logger.d(
        "ViewModel: Loading patient appointments with status: ${_selectedStatusFilter?.name ?? 'all'}",
      );

      // Get current user (patient) from AuthViewModel
      final currentUser =
          _authViewModel.localUser; // Use the synced local user data
      if (currentUser == null) {
        throw AuthException("You must be logged in to view appointments.");
      }

      _logger.d("ViewModel: Current user role: ${currentUser.role}");

      // Verify user is a patient using the enum
      if (currentUser.role != UserRole.patient) {
        throw AuthException("Only patients can view this appointment list.");
      }

      _logger.d(
        "ViewModel: User verified as patient (${currentUser.id}). Fetching appointments...",
      );

      // Get appointments using the UseCase, passing the patient's ID and the enum status filter
      _appointments = await _appointmentUseCase.getPatientAppointments(
        currentUser.id, // Use the ID from UserModel
        status: _selectedStatusFilter, // Pass nullable enum
      );

      _logger.i(
        "ViewModel: Loaded ${_appointments.length} appointments for patient ${currentUser.id}.",
      );
      _error = null; // Clear error on success
    } on AuthException catch (e) {
      _logger.w("ViewModel: Auth error loading appointments: ${e.message}");
      _setError(e.message);
      _appointments = [];
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Error loading appointments",
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ApiException ||
          e is DatabaseException ||
          e is DataProcessingException) {
        _setError("Failed to load appointments: ${e.toString()}");
      } else {
        _setError("An unexpected error occurred while loading appointments.");
      }
      _appointments = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Cancels a specific appointment.
  Future<bool> cancelAppointment(String appointmentId) async {
    if (_isLoading) return false; // Prevent action while already busy

    _logger.d(
      "ViewModel: Requesting cancellation for appointment $appointmentId",
    );
    _setLoading(true);
     clearError();

    try {
      // Verify user is still a logged-in patient
      final currentUser = _authViewModel.localUser;
      if (currentUser == null || currentUser.role != UserRole.patient) {
        throw AuthException("Action denied. Only the patient can cancel.");
      }

      // Find the appointment locally first for checks and potential optimistic update
      final appointmentIndex = _appointments.indexWhere(
        (apt) => apt.id == appointmentId,
      );
      if (appointmentIndex == -1) {
        // If not found locally, maybe try fetching it? Or just error out.
        _logger.w(
          "ViewModel: Cannot cancel - Appointment $appointmentId not found in local list.",
        );
        throw DataNotFoundException("Appointment not found.");
      }
      final appointment = _appointments[appointmentIndex];

      // Double-check ownership (although backend rules are primary)
      if (appointment.patientId != currentUser.id) {
        throw AuthException(
          "Permission denied: You can only cancel your own appointments.",
        );
      }

      // Call the UseCase to perform the cancellation (which updates status)
      await _appointmentUseCase.cancelAppointment(appointmentId);

      // Update local state optimistically/on success
      _appointments[appointmentIndex] = appointment.copyWith(
        status: AppointmentStatus.cancelled, // Update status to cancelled
        // updatedAt handled by repository/backend
      );
      _logger.i("ViewModel: Successfully cancelled appointment $appointmentId");

      _setLoading(false);
      notifyListeners(); // Update UI
      return true; // Indicate success
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on DataNotFoundException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on InvalidOperationException catch (e) {
      // Catch if UseCase prevents cancelling (e.g., already completed)
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Error cancelling appointment $appointmentId",
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Failed to cancel appointment: ${e.toString()}");
      _setLoading(false);
      return false; // Indicate failure
    }
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _logger.i("Disposing PatientAppointmentsViewModel.");
    _authViewModel.removeListener(_handleAuthChange); // Remove listener
    super.dispose();
  }
}

// Remove the incorrect extension on User:
// extension on User {
//   get role => null;
// }
