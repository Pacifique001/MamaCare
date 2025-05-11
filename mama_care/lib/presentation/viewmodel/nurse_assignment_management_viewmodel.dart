// lib/presentation/viewmodel/nurse_assignment_management_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/entities/patient_summary.dart'; // TODO: Create PatientSummary entity
import 'package:mama_care/domain/usecases/nurse_assignment_management_usecase.dart'; // TODO: Create UseCase

@injectable
class NurseAssignmentManagementViewModel extends ChangeNotifier {
  final NurseAssignmentManagementUseCase _useCase;
  final Logger _logger;
  final String nurseId; // Passed during creation

  NurseAssignmentManagementViewModel(
    this._useCase,
    this._logger,
    @factoryParam this.nurseId, // Use factoryParam
  ) {
    _logger.i("NurseAssignmentManagementViewModel initialized for nurse: $nurseId");
    loadAssignments(); // Load data on init
  }

  // --- State ---
  Nurse? _nurseProfile; // Store nurse details
  List<PatientSummary> _assignedPatients = []; // List of assigned patient summaries
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  Nurse? get nurseProfile => _nurseProfile;
  List<PatientSummary> get assignedPatients => List.unmodifiable(_assignedPatients);
  bool get isLoading => _isLoading;
  String? get error => _error;

 // --- Private State Setters ---
  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { if (_error == message) return; _error = message; if (message != null) _logger.e("NurseAssignMgmtVM Error: $message"); notifyListeners(); }
  void _clearError() => _setError(null);

  // --- Data Fetching ---
  Future<void> loadAssignments() async {
    _logger.d("VM: Loading assignments for nurse $nurseId");
    _setLoading(true);
    _clearError();
    try {
      // Fetch nurse profile and assigned patients (maybe concurrently)
      final results = await Future.wait([
          _useCase.getNurseProfile(nurseId),
          _useCase.getAssignedPatients(nurseId),
      ]);
      _nurseProfile = results[0] as Nurse?;
      _assignedPatients = results[1] as List<PatientSummary>? ?? [];

      if (_nurseProfile == null) {
         _logger.w("VM: Nurse profile not found during assignment load for $nurseId");
         // Set error or handle based on requirements
         _setError("Could not load nurse profile.");
      } else {
         _logger.i("VM: Loaded ${assignedPatients.length} assignments for nurse ${nurseProfile!.name}");
      }

    } catch (e, s) {
       _logger.e("VM: Failed to load assignments for nurse $nurseId", error: e, stackTrace: s);
       _setError(e is AppException ? e.message : "Could not load assignments.");
       _nurseProfile = null;
       _assignedPatients = []; // Clear list on error
    } finally {
      _setLoading(false);
    }
  }

  // --- Actions ---
  Future<bool> unassignPatient(String patientId) async {
      _logger.i("VM: Requesting unassignment of patient $patientId from nurse $nurseId");
      _setLoading(true); // Indicate loading during action
      _clearError();
      try {
        await _useCase.unassignPatient(nurseId: nurseId, patientId: patientId);
        _logger.i("VM: Unassignment successful for patient $patientId.");
        // Refresh the list after unassignment
        await loadAssignments(); // Reload data
        return true;
      } catch (e, s) {
         _logger.e("VM: Failed to unassign patient $patientId", error: e, stackTrace: s);
         _setError(e is AppException ? e.message : "Failed to unassign patient.");
         _setLoading(false); // Stop loading on error
         return false;
      }
      // Loading state is handled by the loadAssignments call after success/failure
  }

  // --- Navigation ---
  // Add navigation methods if needed (e.g., to patient detail)
}