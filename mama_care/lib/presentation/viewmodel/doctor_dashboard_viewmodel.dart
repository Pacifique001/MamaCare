// lib/presentation/viewmodel/doctor_dashboard_viewmodel.dart

import 'dart:async'; // Import for StreamSubscription if using streams
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/nurse_assignment_repository.dart'; // Import Nurse Assignment Repo
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import Enum
//import 'package:mama_care/data/repositories/appointment_repository.dart'; // Import Appointment Repo interface
import 'package:mama_care/domain/entities/nurse_assignment.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import custom exceptions
// Removed locator import - dependencies should be injected
// import 'package:mama_care/injection.dart';
// Removed AuthViewModel import - ID should be passed in
// import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';

@injectable // Marks class for dependency injection
class DoctorDashboardViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final AuthViewModel _authViewModel;
  final NurseAssignmentRepository
  _nurseAssignmentRepository; // Injected Nurse Repo
  final Logger _logger;

  // --- State Variables ---
  List<Appointment> _appointments =
      []; // Stores all fetched appointments for the current doctor
  List<NurseAssignment> _nurseAssignments =
      []; // Stores nurse assignments for the current doctor
  AppointmentStatus?
  _selectedStatusFilter; // Nullable enum for filtering appointments, null means 'all'
  bool _isLoadingAppointments =
      false; // Loading state specifically for appointments
  bool _isLoadingAssignments =
      false; // Loading state specifically for assignments
  String? _appointmentsError; // Error message related to appointments
  String? _assignmentsError; // Error message related to assignments
  String?
  _currentDoctorId; // Store the doctor ID this VM is currently managing data for
  bool _isLoading = false;
  String? _error;
  // --- Optional: Stream Subscriptions if using streams ---
  // StreamSubscription? _appointmentSubscription;
  // StreamSubscription? _assignmentSubscription;

  // --- Constructor ---
  DoctorDashboardViewModel(
    this._appointmentUseCase,
    this._authViewModel,
    this._nurseAssignmentRepository, // Inject assignment repository
    this._logger,
  ) {
    _logger.i("DoctorDashboardViewModel initialized.");
    // Initial data load is now triggered EXPLICITLY by the View/Screen using loadData(doctorId)
    _authViewModel.addListener(_handleAuthChange);
    // Attempt initial load if already logged in as a doctor
    _handleAuthChange();
  }

  // --- Getters ---
  AppointmentStatus? get selectedFilterStatus => _selectedStatusFilter;
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<NurseAssignment> get nurseAssignments =>
      List.unmodifiable(_nurseAssignments);
  // Combined loading state for general UI feedback
  bool get isLoading => _isLoadingAppointments || _isLoadingAssignments;
  // Combined error message (prioritizes appointment errors for display)
  String? get error => _appointmentsError ?? _assignmentsError;
  bool get hasAnyAppointments => _appointments.isNotEmpty;

  void _handleAuthChange() {
    final bool wasDoctor =
        _appointments.isNotEmpty ||
        _isLoading ||
        _error != null; // Heuristic: Was this VM active?
    final bool isDoctor =
        _authViewModel.isAuthenticated &&
        _authViewModel.localUser?.role == UserRole.doctor;

    if (!isDoctor && wasDoctor) {
      // User logged out or changed role - clear data
      _logger.w(
        "Auth state changed (not a logged-in doctor), clearing doctor appointments.",
      );
      _appointments = [];
      _error = null;
      _selectedStatusFilter = null; // Reset filter
      _setLoading(false); // Ensure loading stops
      notifyListeners();
    } else if (isDoctor &&
        _appointments.isEmpty &&
        !_isLoading &&
        _error == null) {
      // User is now a doctor, and we haven't loaded data yet (or cleared it)
      _logger.i(
        "Auth state shows logged-in doctor, triggering appointment load.",
      );
      loadDoctorAppointments; // Trigger load
    } else if (isDoctor && !wasDoctor) {
      // Became a doctor but maybe data is loading or error exists, trigger load anyway if not loading
      if (!_isLoading) {
        _logger.i(
          "Auth state changed to doctor, ensuring data load is triggered.",
        );
        loadDoctorAppointments;
      }
    }
  }

  /// Returns a filtered list of appointments based on the selected status filter.
  List<Appointment> get filteredAppointments {
    if (_selectedStatusFilter == null) {
      return List.unmodifiable(_appointments); // Return all if no filter is set
    }
    // Filter the master list based on the current filter status
    return _appointments
        .where((a) => a.status == _selectedStatusFilter)
        .toList();
  }

  // --- State Setters (Private Helpers) ---
  // Sets loading state for either appointments or assignments and notifies listeners
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_error == message)
      return; // Avoid redundant notifications if message is same
    _error = message;
    if (message != null) {
      _logger.e("DoctorAppointmentsViewModel Error: $message");
    }
    // Always notify when error state changes (setting or clearing)
    notifyListeners();
  }

  /// Clears both error messages.
  void clearError() {
    bool changed = false;
    if (_appointmentsError != null) {
      _appointmentsError = null;
      changed = true;
    }
    if (_assignmentsError != null) {
      _assignmentsError = null;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  // --- Public Data Loading and Actions ---

  /// Loads initial data (appointments and nurse assignments) for the specified doctor ID.
  /// Should be called by the Screen/View when it initializes or has the doctor ID.
  Future<void> loadData(String doctorId) async {
    // Store the doctor ID for potential use in other methods like filtering
    _currentDoctorId = doctorId;
    _logger.i(
      "DoctorDashboardViewModel: Loading initial data for doctor $doctorId",
    );

    // Reset state before loading new data
    _appointments = [];
    _nurseAssignments = [];
    _selectedStatusFilter = null; // Default to 'all' on load
    clearError(); // Clear any previous errors
    _setLoading(true);
    _setLoading(true);
    // No need to notify here, loading flags will update UI

    // Fetch data concurrently for efficiency
    try {
      final results = await Future.wait([
        loadDoctorAppointments(), // Returns Future<void>
        _loadNurseAssignments(doctorId), // Returns Future<void>
      ]);
      _logger.i(
        "DoctorDashboardViewModel: Initial data load complete for doctor $doctorId",
      );
    } catch (e) {
      // Errors are set and logged within the individual load methods.
      // Main loading state will be handled by finally blocks in those methods.
      _logger.e(
        "DoctorDashboardViewModel: Error during concurrent data load.",
        error: e,
      );
    }
    // Loading flags are managed by the individual load methods' finally blocks.
  }

  /// Loads appointments for the currently authenticated doctor.
  /// Applies the [_selectedStatusFilter].
  Future<void> loadDoctorAppointments() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) {
      _logger.d("ViewModel: Load already in progress, skipping.");
      return;
    }

    _setLoading(true);
    _setError(null); // Clear previous errors before loading

    try {
      _logger.d(
        "ViewModel: Loading doctor appointments with status filter: ${_selectedStatusFilter?.name ?? 'all'}",
      );

      // Ensure user is authenticated and is a doctor
      final currentUser = _authViewModel.localUser;
      if (currentUser == null) {
        throw AuthException("You must be logged in to view appointments.");
      }
      if (currentUser.role != UserRole.doctor) {
        throw AuthException("Only doctors can view this appointment list.");
      }

      _logger.d(
        "ViewModel: User verified as doctor (${currentUser.id}). Fetching appointments...",
      );

      // Call the use case, passing the doctor's ID and the current status filter (which can be null)
      _appointments = await _appointmentUseCase.getDoctorAppointments(
        currentUser.id,
        status: _selectedStatusFilter,
      );

      _logger.i(
        "ViewModel: Loaded ${_appointments.length} appointments for doctor ${currentUser.id}.",
      );
      _error = null; // Explicitly clear error on success
    } on AuthException catch (e) {
      // Catch specific auth errors
      _logger.w("ViewModel: Auth error loading appointments: ${e.message}");
      _setError(e.message);
      _appointments = []; // Clear data on auth error
    } catch (e, stackTrace) {
      // Catch other potential errors (API, DB, DataProcessing)
      _logger.e(
        "ViewModel: Failed to load appointments",
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ApiException ||
          e is DatabaseException ||
          e is DataProcessingException) {
        _setError(
          "Failed to load appointments. Please try again later. (${e.runtimeType})",
        );
      } else {
        _setError("An unexpected error occurred while loading appointments.");
      }
      _appointments = []; // Clear data on any error
    } finally {
      _setLoading(false); // Ensure loading indicator is turned off
    }
  }

  /// Fetches nurse assignments specifically for the given doctor ID.
  Future<void> _loadNurseAssignments(String doctorId) async {
    _setLoading(true); // Set loading for assignments
    _setError(null); // Clear previous assignment error
    try {
      _logger.d("ViewModel: Fetching nurse assignments for doctor $doctorId");
      _nurseAssignments = await _nurseAssignmentRepository
          .getAssignmentsForDoctor(doctorId);
      _logger.i(
        "ViewModel: Loaded ${_nurseAssignments.length} nurse assignments for doctor $doctorId.",
      );
      _setError(null); // Clear error on success
    } catch (e, s) {
      _logger.e(
        "ViewModel: Error loading nurse assignments for doctor $doctorId",
        error: e,
        stackTrace: s,
      );
      _setError("Failed to load nurse assignments: ${e.toString()}");
      _nurseAssignments = []; // Clear list on error
    } finally {
      _setLoading(false); // Ensure loading stops for assignments
    }
  }

  /// Sets the appointment status filter and reloads *only* the appointments list.
  /// Pass `null` to show appointments of all statuses.
  Future<void> setStatusFilter(AppointmentStatus? status) async {
    // Check if the filter actually changed
    if (_selectedStatusFilter == status) return;

    _selectedStatusFilter = status;
    _logger.i(
      "Status filter changed to: ${_selectedStatusFilter?.name ?? 'all'}",
    );
    // Notify UI immediately about the filter change (e.g., update chip selection)
    notifyListeners();

    // Reload the appointments with the new filter
    await loadDoctorAppointments();
  }

  /// Updates the status of a specific appointment.
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    _logger.d(
      "ViewModel: Requesting status update for appointment $appointmentId to ${newStatus.name}",
    );
    _setLoading(true); // Indicate busy state
    clearError(); // Clear previous errors

    try {
      // Ensure user is still an authenticated doctor
      final currentUser = _authViewModel.localUser;
      if (currentUser == null || currentUser.role != UserRole.doctor) {
        throw AuthException("Action denied: User is not a logged-in doctor.");
      }

      // Find the appointment locally for optimistic update and checks
      final appointmentIndex = _appointments.indexWhere(
        (apt) => apt.id == appointmentId,
      );
      if (appointmentIndex == -1) {
        // Optionally: Could try fetching the appointment directly if not found locally
        // final fetchedAppointment = await _appointmentUseCase.getAppointmentById(appointmentId);
        // if (fetchedAppointment == null) { ... }
        _logger.w(
          "ViewModel: Cannot update status - Appointment $appointmentId not found in the current view model list.",
        );
        throw DataProcessingException(
          "Appointment not found in the list.",
        ); // Indicate local state issue
      }
      final appointment = _appointments[appointmentIndex];

      // --- Optional: Add Business Logic Check ---
      // Example: Prevent updating already completed/cancelled appointments
      if (appointment.status == AppointmentStatus.completed ||
          appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.declined) {
        throw InvalidOperationException(
          "Cannot update status of an appointment that is already ${appointment.status.name}.",
        );
      }
      // ------------------------------------------

      // Call the use case to persist the status change
      await _appointmentUseCase.updateAppointmentStatus(
        appointmentId,
        newStatus,
      );

      // Update local state optimistically / upon success
      _appointments[appointmentIndex] = appointment.copyWith(
        status: newStatus,
        // Assume updatedAt is handled by the backend/repository via server timestamp
      );
      _logger.i(
        "ViewModel: Successfully updated appointment $appointmentId status to ${newStatus.name}",
      );

      _setLoading(false);
      notifyListeners(); // Update UI with the changed appointment
      return true; // Indicate success
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on DataProcessingException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } on InvalidOperationException catch (e) {
      _setError(e.message); // Show specific business logic error
      _setLoading(false);
      return false;
    } catch (e, stackTrace) {
      _logger.e(
        "ViewModel: Error updating appointment status for $appointmentId",
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Failed to update status. Please try again."); // Generic error
      _setLoading(false);
      return false; // Indicate failure
    }
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _logger.i("Disposing DoctorDashboardViewModel.");
    // Cancel any active stream subscriptions if they were used
    //_appointmentSubscription?.cancel();
    //_assignmentSubscription?.cancel();
    super.dispose();
  }
}



