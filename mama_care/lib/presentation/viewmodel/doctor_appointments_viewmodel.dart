// lib/presentation/viewmodel/doctor_appointments_viewmodel.dart

import 'dart:async';
import 'dart:convert'; // For jsonEncode
import 'dart:io'; // For Platform checks
import 'package:flutter/foundation.dart'; // For kIsWeb, ChangeNotifier
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart'; // For formatting dates in notification body
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import Enum
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/domain/entities/user_role.dart';
// ***** IMPORT YOUR CUSTOM EXCEPTIONS *****
import 'package:mama_care/core/error/exceptions.dart';

// Using http package directly for this example.
import 'package:http/http.dart' as http;

// Helper extension (can be moved to a utility file)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

@injectable
class DoctorAppointmentsViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final AuthViewModel _authViewModel;
  final Logger _logger;
  // If using an injected http client:
  // final http.Client _httpClient;

  // --- State ---
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  AppointmentStatus? _selectedStatusFilter; // Nullable for 'all'
  final bool _isDisposed = false;

  // Base URL for backend
  late final String _backendBaseUrl;

  // --- Getters ---
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppointmentStatus? get selectedStatusFilter => _selectedStatusFilter;

  // --- Constructor ---
  DoctorAppointmentsViewModel(
    this._appointmentUseCase,
    this._authViewModel,
    this._logger,
    // Inject dependencies if needed:
    // this._httpClient,
  ) {
    _logger.i("DoctorAppointmentsViewModel initialized");
    _configureBackendUrl(); // Configure backend URL
    _authViewModel.addListener(_handleAuthChange); // Listen to auth changes
    _handleAuthChange(); // Check initial auth state
  }

  // Helper to configure backend URL based on platform (for development)
  void _configureBackendUrl() {
    if (kIsWeb) {
      // Running on web, use your network IP for consistent access
      _backendBaseUrl = "http://192.168.1.98:8000";
    } else if (Platform.isAndroid) {
      // Use your actual local network IP instead of 10.0.2.2 (Android emulator)
      _backendBaseUrl = "http://192.168.1.98:8000";
    } else if (Platform.isIOS) {
      // Use your actual local network IP instead of localhost
      _backendBaseUrl = "http://192.168.1.98:8000";
    } else {
      // Other platforms (desktop, etc.)
      _backendBaseUrl = "http://192.168.1.98:8000";
    }

    // Default for desktop/other

    _logger.i(
      "Backend Base URL configured: $_backendBaseUrl (Ensure this is correct for your environment)",
    );
  }

  // --- Auth State Listener ---
  void _handleAuthChange() {
    final bool wasActive =
        _appointments.isNotEmpty || _isLoading || _error != null;
    final bool isCurrentlyDoctor =
        _authViewModel.isAuthenticated &&
        _authViewModel.localUser?.role == UserRole.doctor;

    _logger.d(
      "Handling Auth Change: isCurrentlyDoctor=$isCurrentlyDoctor, wasActive=$wasActive, IsLoading: $_isLoading",
    );

    if (!isCurrentlyDoctor && wasActive) {
      _logger.w(
        "Auth state changed (not a logged-in doctor), clearing doctor appointments state.",
      );
      _appointments = [];
      _error = null;
      _selectedStatusFilter = null;
      _setLoading(false);
      notifyListeners();
    } else if (isCurrentlyDoctor &&
        (_appointments.isEmpty || !wasActive) &&
        !_isLoading &&
        _error == null) {
      _logger.i(
        "Auth state shows logged-in doctor, triggering appointment load.",
      );
      loadDoctorAppointments();
    } else {
      _logger.d(
        "Auth state change handled, no immediate action required based on current state.",
      );
    }
  }

  // --- Private State Setters ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_error == message) return;
    _error = message;
    if (message != null)
      _logger.e("DoctorAppointmentsViewModel Error: $message");
    else
      _logger.d("DoctorAppointmentsViewModel Error cleared.");
    notifyListeners();
  }

  void clearError() => _setError(null);

  // --- Public Methods ---

  /// Sets the status filter and triggers reloading of appointments.
  Future<void> setStatusFilter(AppointmentStatus? status) async {
    if (_selectedStatusFilter == status) return;
    _selectedStatusFilter = status;
    _logger.i(
      "Status filter changed to: ${_selectedStatusFilter?.name ?? 'all'}",
    );
    notifyListeners();
    await loadDoctorAppointments();
  }

  /// Loads appointments for the currently authenticated doctor.
  Future<void> loadDoctorAppointments() async {
    if (_isLoading) {
      _logger.d("ViewModel: Load already in progress, skipping.");
      return;
    }
    _setLoading(true);
    _setError(null);

    try {
      _logger.d(
        "ViewModel: Loading doctor appointments with filter: ${_selectedStatusFilter?.name ?? 'all'}",
      );
      final currentUser = _authViewModel.localUser;
      if (currentUser == null)
        throw AuthException("You must be logged in to view appointments.");
      if (currentUser.role != UserRole.doctor)
        throw AuthException("Only doctors can view this appointment list.");
      _logger.d(
        "ViewModel: User verified as doctor (${currentUser.id}). Fetching appointments...",
      );

      _appointments = await _appointmentUseCase.getDoctorAppointments(
        currentUser.id,
        status: _selectedStatusFilter,
      );
      _logger.i(
        "ViewModel: Loaded ${_appointments.length} appointments for doctor ${currentUser.id}.",
      );
      _error = null;

      // *** Catch specific AuthException ***
    } on AuthException catch (e) {
      _logger.w("ViewModel: Auth error loading appointments: ${e.message}");
      _setError(e.message);
      _appointments = [];
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Failed to load appointments",
        error: e,
        stackTrace: stackTrace,
      );
      _setError(
        "Failed to load appointments. Please check your connection and try again.",
      );
      _appointments = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the status of a specific appointment and triggers a notification to the patient.
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus, {
    String? cancellationReason, // Optional reason
  }) async {
    _logger.d(
      "ViewModel: Requesting BACKEND status update for appointment $appointmentId to ${newStatus.name}",
    );
    _setLoading(true);
    clearError();

    try {
      final currentUser = _authViewModel.localUser;
      if (currentUser == null || currentUser.role != UserRole.doctor) {
        throw AuthException("Action denied: User is not a logged-in doctor.");
      }

      // --- Call Backend Endpoint ---
      final url = Uri.parse(
        '$_backendBaseUrl/update-appointment-status',
      ); // Use the PUT endpoint
      final headers = {"Content-Type": "application/json"};
      final body = jsonEncode({
        "appointment_id": appointmentId,
        "new_status": newStatus.name, // Send enum name as string
        "doctor_id":
            currentUser.id, // Optional: Send doctor ID for verification
        "cancellation_reason": cancellationReason, // Optional
      });

      _logger.d("Calling backend PUT $url with body: $body");
      final response = await http
          .put(url, headers: headers, body: body) // Use PUT
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i(
          "Backend status update successful for $appointmentId: ${response.statusCode} - ${response.body}",
        );
        // Backend handled the update and the notification sending.
        // We just need to refresh the local list to show the change.
        await loadDoctorAppointments(); // Reload the list to reflect the change
        _setLoading(false);
        return true;
      } else {
        // Backend returned an error
        _logger.e(
          "Backend status update failed: ${response.statusCode} - ${response.body}",
        );
        String errorMessage = "Failed to update appointment status.";
        try {
          // Try to parse backend error
          final responseBody = jsonDecode(response.body);
          errorMessage = responseBody['detail'] ?? errorMessage;
        } catch (_) {} // Ignore parsing errors
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      // Catch network errors, timeouts, etc.
      _logger.e(
        "ViewModel: Error calling backend to update status for $appointmentId",
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Failed to update status. Please check your connection.");
      _setLoading(false);
      return false;
    }
  }
Future<bool> deleteAppointment(String appointmentId) async {
     if (appointmentId.isEmpty || _isLoading || _isDisposed) return false;

     _logger.d("ViewModel: Attempting to delete appointment $appointmentId");
     _setLoading(true); // Use the existing loading state setter
     clearError();

     try {
       await _appointmentUseCase.deleteAppointment(appointmentId);
       _logger.i("ViewModel: Appointment $appointmentId deleted successfully via UseCase.");

       // Remove the appointment from the local list for immediate UI update
       if (!_isDisposed) {
          final index = _appointments.indexWhere((a) => a.id == appointmentId);
          if (index != -1) {
             _appointments.removeAt(index);
             _safeNotifyListeners(); // Update the list UI
          }
       }
       _setLoading(false);
       return true; // Indicate success

     } on AppException catch (e) {
       _logger.e("ViewModel: Failed to delete appointment $appointmentId", error: e);
       if (!_isDisposed) _setError(e.message);
       _setLoading(false);
       return false;
     } catch (e, s) {
       _logger.e("ViewModel: Unexpected error deleting appointment $appointmentId", error: e, stackTrace: s);
        if (!_isDisposed) _setError("Could not delete the appointment. Please try again.");
       _setLoading(false);
       return false;
     }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  // --- Cleanup ---
  @override
  void dispose() {
    _logger.i("Disposing DoctorAppointmentsViewModel.");
    _authViewModel.removeListener(_handleAuthChange);
    super.dispose();
  }
}
