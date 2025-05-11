// lib/presentation/viewmodel/nurse_detail_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/usecases/nurse_detail_usecase.dart'; // Assuming this exists

@injectable
class NurseDetailViewModel extends ChangeNotifier {
  final NurseDetailUseCase _useCase;
  final Logger _logger;
  final String nurseId; // Passed during creation

  NurseDetailViewModel(
    this._useCase,
    this._logger,
    @factoryParam this.nurseId, // Use factoryParam for ID
  ) {
    _logger.i("NurseDetailViewModel initialized for nurse: $nurseId");
    fetchNurseDetails(); // Load data on init
  }

  // --- State ---
  Nurse? _nurse;
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  Nurse? get nurse => _nurse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Private State Setters ---
  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { if (_error == message) return; _error = message; if (message != null) _logger.e("NurseDetailViewModel Error: $message"); notifyListeners(); }
  void _clearError() => _setError(null);

  // --- Data Fetching ---
  Future<void> fetchNurseDetails() async {
    _logger.d("VM: Fetching details for nurse $nurseId");
    _setLoading(true);
    _clearError();
    try {
      _nurse = await _useCase.getNurseProfile(nurseId);
      if (_nurse == null) {
          _setError("Nurse profile not found.");
          _logger.w("VM: Nurse profile not found for $nurseId");
      } else {
           _logger.i("VM: Nurse details fetched successfully for ${nurse!.name}");
      }
    } catch (e, s) {
       _logger.e("VM: Failed to fetch nurse details for $nurseId", error: e, stackTrace: s);
       _setError(e is AppException ? e.message : "Could not load nurse details.");
       _nurse = null;
    } finally {
      _setLoading(false);
    }
  }

  // Add methods for actions if needed (e.g., edit nurse profile - requires permissions)
}

// --- TODO: Create NurseDetailUseCase ---
// Uses NurseRepository.getNurseById()