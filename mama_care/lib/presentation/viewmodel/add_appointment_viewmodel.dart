// lib/presentation/viewmodel/add_appointment_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/domain/usecases/doctor_usecase.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/core/error/exceptions.dart';

// ADD: Import an HTTP client or your API service
// Make sure to add 'http: ^1.1.0' (or latest) to pubspec.yaml
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode
import 'dart:io'; // For checking platform for base URL

@injectable
class AddAppointmentViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final DoctorUseCase _doctorUseCase;
  final AuthViewModel _authViewModel;
  final Logger _logger;

  // --- State Variables ---
  List<UserModel> _availableDoctors = [];
  bool _isLoading = false;
  bool _isLoadingDoctors = false;
  String? _error;

  // Base URL for your FastAPI backend
  // Updated to use your actual local network IP address
  late final String _backendBaseUrl;

  AddAppointmentViewModel(
    this._appointmentUseCase,
    this._doctorUseCase,
    this._authViewModel,
    this._logger,
  ) {
    _logger.i("AddAppointmentViewModel initialized.");
    _configureBackendUrl(); // Configure URL based on platform
    loadAvailableDoctors();
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
    // For production, you would use an environment variable or config service
    _logger.i("Backend Base URL configured: $_backendBaseUrl");
  }

  // --- Getters ---
  List<UserModel> get availableDoctors => List.unmodifiable(_availableDoctors);
  bool get isLoading => _isLoading;
  bool get isLoadingDoctors => _isLoadingDoctors;
  String? get error => _error;

  // --- Private State Mutators ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingDoctors(bool loading) {
    if (_isLoadingDoctors == loading) return;
    _isLoadingDoctors = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _updateErrorState(message);
  }

  void _updateErrorState(String? message) {
    if (_error == message) return;
    _error = message;
    if (message != null) {
      _logger.e("AddAppointmentViewModel Error: $message");
    }
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // --- Data Loading ---
  Future<void> loadAvailableDoctors({String? specialtyFilter}) async {
    _setLoadingDoctors(true);
    _setError(null); // Clear previous errors before loading

    try {
      _logger.d("ViewModel: Loading available doctors...");
      _availableDoctors = await _doctorUseCase.getAvailableDoctors(
        specialtyFilter: specialtyFilter,
      );
      _logger.i(
        "ViewModel: Loaded ${_availableDoctors.length} available doctors.",
      );

      if (_availableDoctors.isEmpty) {
        _logger.w("ViewModel: No available doctors found matching criteria.");
      } else {
        _error = null; // Ensure error is null on success
      }
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Error loading available doctors",
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Failed to load available doctors. Please try again later.");
      _availableDoctors = []; // Ensure the list is empty on error
    } finally {
      _setLoadingDoctors(false); // Ensure loading indicator stops
    }
  }

  // --- Core Action Method ---
  Future<Appointment?> saveAppointment({
    required String doctorId,
    required String reason,
    required DateTime dateTime,
    String? notes,
  }) async {
    if (_isLoading) return null;
    _setLoading(true);
    _setError(null);

    Appointment? createdAppointment;

    try {
      _logger.d("ViewModel: Saving appointment request -> Doctor $doctorId");

      final currentUser = _authViewModel.localUser;
      if (currentUser == null) {
        throw AuthException("You must be logged in to request an appointment.");
      }
      if (currentUser.role != UserRole.patient) {
        throw AuthException(
          "Action not allowed: Only patients can request appointments.",
        );
      }

      createdAppointment = await _appointmentUseCase.requestAppointment(
        patientId: currentUser.id,
        doctorId: doctorId,
        reason: reason,
        dateTime: dateTime,
        notes: notes,
      );

      _logger.i(
        "ViewModel: Appointment request successful. ID: ${createdAppointment?.id}",
      );

      // Call backend API to notify the doctor
      if (createdAppointment != null) {
        // Run this asynchronously and don't block the UI return
        _notifyDoctorViaBackend(createdAppointment).catchError((e, s) {
          // Log error from the async notification call, but don't surface to user here
          _logger.e(
            "Error in background notification call",
            error: e,
            stackTrace: s,
          );
        });
      }

      _setLoading(false);
      return createdAppointment; // Return success even if notification call fails later
    } on AuthException catch (e) {
      _logger.w("ViewModel: Auth error saving appointment - ${e.message}");
      _setError(e.message);
      _setLoading(false);
      return null;
    } on DataNotFoundException catch (e) {
      _logger.w(
        "ViewModel: Data not found error saving appointment - ${e.message}",
      );
      _setError(e.message);
      _setLoading(false);
      return null;
    } on InvalidArgumentException catch (e) {
      _logger.w(
        "ViewModel: Invalid argument error saving appointment - ${e.message}",
      );
      _setError(e.message);
      _setLoading(false);
      return null;
    } on DomainException catch (e) {
      _logger.e(
        "ViewModel: Domain error saving appointment - ${e.message}",
        error: e.cause,
      );
      _setError(e.message);
      _setLoading(false);
      return null;
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Unexpected error saving appointment",
        error: e,
        stackTrace: stackTrace,
      );
      _setError("An unexpected error occurred. Please try again.");
      _setLoading(false);
      return null;
    }
  }

  // Call Backend API to Notify Doctor
  Future<void> _notifyDoctorViaBackend(Appointment appointment) async {
    _logger.i(
      "Sending notification request to backend for Doctor ${appointment.doctorId} regarding appointment ${appointment.id}",
    );

    final url = Uri.parse('$_backendBaseUrl/notify-doctor-appointment');
    final headers = {"Content-Type": "application/json"};
    // Ensure all values in the 'data' map are strings, as required by FCM
    final Map<String, String> dataPayload = {
      "type": "appointment_request",
      "appointmentId": appointment.id!,
      "patientId": appointment.patientId,
      "route":
          "/appointments/detail/${appointment.id}", // Example route for doctor app
    };

    final body = jsonEncode({
      "doctor_id": appointment.doctorId, // Send doctor's ID
      "title": "New Appointment Request",
      "body":
          '${appointment.patientName ?? 'A patient'} requested an appointment for ${DateFormat.yMd().add_jm().format(appointment.appointmentDateTime)}.', // Handle potential null patientName
      "data": dataPayload, // Use the validated string map
    });

    try {
      // Set a timeout for the request
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i("Backend notification request successful: ${response.body}");
        // Optionally parse response.body if needed (e.g., success/failure counts)
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] != 'success' &&
            responseBody['status'] != 'no_target') {
          _logger.w(
            "Backend indicated potential issue sending notification: ${response.body}",
          );
        }
      } else {
        _logger.e(
          "Backend notification request failed: ${response.statusCode} - ${response.body}",
        );
        // Do not set UI error here, appointment save was successful.
      }
    } catch (e, s) {
      _logger.e(
        "Error sending notification request to backend (Network/Timeout/etc)",
        error: e,
        stackTrace: s,
      );
      // Do not set UI error here.
    }
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _logger.i("Disposing AddAppointmentViewModel.");
    super.dispose();
  }
}
