// lib/presentation/viewmodel/nurse_dashboard_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // Use UserModel
import 'package:mama_care/domain/entities/patient_summary.dart'; // Keep if used internally by repo/usecase
import 'package:mama_care/data/repositories/nurse_repository.dart'; // Assuming this exists
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'package:mama_care/core/error/exceptions.dart';

@injectable
class NurseDashboardViewModel extends ChangeNotifier {
  final NurseRepository _repository;
  final FirebaseAuth _auth;
  final Logger _logger;

  // State
  UserModel? _nurseProfile; // Use UserModel for consistency
  List<PatientSummary> _assignedPatients = []; // Usecase might return Summary
  List<Appointment> _upcomingAppointments = [];
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;


  NurseDashboardViewModel(this._repository, this._auth, this._logger) {
    _logger.i("NurseDashboardViewModel initialized.");
    // Data loading should be triggered by the View
  }

  // Getters
  UserModel? get nurseProfile => _nurseProfile;
  List<PatientSummary> get assignedPatients => List.unmodifiable(_assignedPatients);
  List<Appointment> get upcomingAppointments => List.unmodifiable(_upcomingAppointments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Safely notify listeners only if the ViewModel hasn't been disposed.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
     _logger.d("Nurse Dashboard loading state: $_isLoading");
    _safeNotifyListeners();
  }



  // --- ADD THIS METHOD ---
  /// Clears the current error message.
  void clearError() {
    _setError(null); // Call the internal setter with null
  }
  // ----------------------

  /// Loads all necessary data for the nurse dashboard.
  Future<void> loadInitialData() async { // Renamed for clarity
     if (_isLoading || _isDisposed) return;

     final nurseId = _auth.currentUser?.uid;
     if (nurseId == null) {
        _setError("Cannot load data: Nurse not authenticated.", isFatal: true);
        return;
     }

     _logger.i("Nurse dashboard loading initial data for nurse $nurseId...");
     _setLoading(true);
     clearError(); // Clear previous errors on new load

     try {
         // Fetch data concurrently
         await Future.wait([
            _fetchNurseProfile(nurseId),
            _fetchAssignedPatients(nurseId),
            _fetchUpcomingAppointments(nurseId),
         ]);
          _logger.i("Nurse dashboard initial data loaded successfully.");

     } catch (e, stackTrace) {
         _logger.e("Failed to load initial nurse dashboard data", error: e, stackTrace: stackTrace);
         _setError(_parseError(e), error: e, stackTrace: stackTrace, isFatal: _nurseProfile == null); // Error is fatal only if profile failed
     } finally {
        _setLoading(false);
     }
  }

  /// Refreshes all dashboard data.
  Future<void> refreshData() async {
     // This can simply call loadInitialData again
     await loadInitialData();
  }


  Future<void> _fetchNurseProfile(String nurseId) async {
     _logger.d("Fetching profile for nurse $nurseId...");
     try {
        _nurseProfile = (await _repository.getNurseProfile(nurseId)) as UserModel?; // Assume repo returns UserModel
        // No notifyListeners needed here, handled by loadInitialData completion
     } catch (e) {
        _logger.e("Failed to fetch nurse profile", error: e);
        throw DataProcessingException("Could not load nurse profile.", cause: e); // Throw specific error
     }
  }

   Future<void> _fetchAssignedPatients(String nurseId) async {
      _logger.d("Fetching assigned patients for nurse $nurseId...");
     try {
        _assignedPatients = await _repository.getAssignedPatients(nurseId); // Assume returns List<PatientSummary>
         _logger.d("Fetched ${_assignedPatients.length} assigned patients.");
         // No notifyListeners needed here
     } catch (e) {
        _logger.e("Failed to fetch assigned patients", error: e);
        throw DataProcessingException("Could not load assigned patients.", cause: e);
     }
   }

   Future<void> _fetchUpcomingAppointments(String nurseId) async {
      _logger.d("Fetching upcoming appointments for nurse $nurseId...");
     try {
        _upcomingAppointments = await _repository.getNurseUpcomingAppointments(nurseId); // Assume returns List<Appointment>
         _logger.d("Fetched ${_upcomingAppointments.length} upcoming appointments.");
         // No notifyListeners needed here
     } catch (e) {
        _logger.e("Failed to fetch upcoming nurse appointments", error: e);
        throw DataProcessingException("Could not load schedule.", cause: e);
     }
   }

  // --- Error Parsing ---
   String _parseError(dynamic error) {
     if (error is AppException) {
        return error.message;
     }
     // Add more specific error parsing if needed
     return "An unexpected error occurred. Please try again.";
   }

   // Overload setError to handle fatal flag easily
   void _setError(String? message, {bool isFatal = false, Object? error, StackTrace? stackTrace}) {
     if (_error == message || _isDisposed) return;
     _error = message;
     if (message != null) {
       _logger.e("NurseDashboardViewModel Error: $message", error: error, stackTrace: stackTrace);
     } else {
       _logger.d("NurseDashboardViewModel error cleared.");
     }

     if (isFatal) {
         // Clear crucial data if the error prevents core functionality
         _nurseProfile = null;
         _assignedPatients = [];
         _upcomingAppointments = [];
     }
     _safeNotifyListeners();
   }

  @override
  void dispose() {
    _logger.i("Disposing NurseDashboardViewModel.");
    _isDisposed = true;
    super.dispose();
  }
}