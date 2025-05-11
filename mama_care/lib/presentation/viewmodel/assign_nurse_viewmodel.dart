// lib/presentation/viewmodel/assign_nurse_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/usecases/assign_nurse_usecase.dart';
import 'package:mama_care/core/error/exceptions.dart';

@injectable
class AssignNurseViewModel extends ChangeNotifier {
  final AssignNurseUseCase _assignNurseUseCase;
  final Logger _logger;

  AssignNurseViewModel(this._assignNurseUseCase, this._logger);

  List<Nurse> _availableNurses = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedNurseId;

  List<Nurse> get availableNurses => List.unmodifiable(_availableNurses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedNurseId => _selectedNurseId;

  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { if (_error == message) return; _error = message; if (message != null) _logger.e("AssignNurseViewModel Error: $message"); notifyListeners(); }
  void _clearError() => _setError(null);

  /// Sets the currently selected nurse ID in the UI.
  void selectNurse(String? nurseId) {
    // Allow deselecting by passing null or tapping again?
    // For radio buttons, usually only selection is needed.
    if (_selectedNurseId != nurseId) {
      _selectedNurseId = nurseId;
      _logger.d("Nurse selected: $nurseId");
      notifyListeners();
    }
  }

  /// Loads the list of nurses available for assignment.
  Future<void> loadAvailableNurses(String? contextId) async {
     _logger.i("VM: Loading available nurses (context: $contextId)...");
     _setLoading(true);
     _clearError();
     _selectedNurseId = null; // Clear selection on reload
     try {
        _availableNurses = await _assignNurseUseCase.getAvailableNurses(contextId);
        _logger.i("VM: Loaded ${_availableNurses.length} available nurses.");
     } catch(e, s) {
        _logger.e("VM: Failed to load available nurses", error: e, stackTrace: s);
        _setError(e is AppException ? e.message : "Could not load available nurses.");
        _availableNurses = []; // Ensure list is empty on error
     } finally {
        _setLoading(false);
     }
  }

  /// Assigns the selected nurse to the given context (patientId).
  /// Returns true on success, false on failure.
  Future<bool> assignSelectedNurseToContext(String contextId) async {
      if (_selectedNurseId == null) {
         _setError("Please select a nurse before assigning.");
         return false;
      }
      _logger.i("VM: Assigning selected nurse $_selectedNurseId to context $contextId");
      _setLoading(true);
      _clearError();
      try {
         await _assignNurseUseCase.assignNurse(patientId: contextId, nurseId: _selectedNurseId!);
         _logger.i("VM: Nurse assigned successfully via UseCase.");
          _setLoading(false);
         return true; // Indicate success to the View
      } catch (e, s) {
         _logger.e("VM: Failed to assign nurse", error: e, stackTrace: s);
          _setError(e is AppException ? e.message : "Assignment failed.");
          _setLoading(false);
         return false; // Indicate failure to the View
      }
  }
}