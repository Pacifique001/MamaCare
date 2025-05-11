import 'dart:async';
import 'package:flutter/foundation.dart'; // Use foundation for ChangeNotifier
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/usecases/pregnancy_detail_use_case.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // To get userId

@injectable
class PregnancyDetailViewModel extends ChangeNotifier {
  final PregnancyDetailUseCase _pregnancyDetailUseCase;
  final AuthViewModel _authViewModel;
  final Logger _logger;

  // --- State Variables ---
  DateTime? _selectedStartingDate; // Store as DateTime?
  double? _babyHeight;
  double? _babyWeight;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false; // Dispose flag

  // --- Constructor ---
  PregnancyDetailViewModel(
    this._pregnancyDetailUseCase,
    this._authViewModel,
    this._logger,
  ) {
    _logger.i("PregnancyDetailViewModel initialized.");
    // Initialize with existing data if user is editing? (See loadExistingData method)
  }

  // --- Getters ---
  DateTime? get startingDate => _selectedStartingDate;
  double? get babyHeight => _babyHeight;
  double? get babyWeight => _babyWeight;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Safe Notifier ---
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --- State Mutators ---
  void _setLoading(bool value) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  void _setErrorMessage(String? message) {
    if (_errorMessage == message || _isDisposed) return;
    _errorMessage = message;
    if (message != null) {
      _logger.e("PregnancyDetailViewModel Error: $message");
    }
    // Don't notify here, let the calling action decide if UI update is needed
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotifyListeners(); // Notify if UI needs to remove error display
    }
  }

  void onStartingDayChanged(DateTime newDate) {
    if (_selectedStartingDate == newDate || _isDisposed) return;
    _selectedStartingDate = newDate;
    _logger.d("Starting date selection updated: $_selectedStartingDate");
    _safeNotifyListeners();
  }

  void onBabyHeightChanged(double height) {
    if (_babyHeight == height || _isDisposed) return;
    _babyHeight = height;
    _logger.d("Baby height updated: $_babyHeight");
    _safeNotifyListeners();
  }

  void onBabyWeightChanged(double weight) {
    if (_babyWeight == weight || _isDisposed) return;
    _babyWeight = weight;
    _logger.d("Baby weight updated: $_babyWeight");
    _safeNotifyListeners();
  }

  // --- Load Existing Data (Optional - For Editing) ---
  Future<void> loadExistingData() async {
    final userId = _authViewModel.currentUser?.uid; // Or localUser?.id
    if (userId == null || userId.isEmpty) {
      _logger.w("Cannot load existing data, user not identified.");
      return;
    }
    _setLoading(true);
    clearError();
    try {
      final existingDetails = await _pregnancyDetailUseCase.getPregnancyDetails(
        userId,
      );
      if (existingDetails != null && !_isDisposed) {
        _logger.i("Loaded existing pregnancy details for user $userId");
        _selectedStartingDate = existingDetails.startingDay; // DateTime?
        _babyHeight = existingDetails.babyHeight;
        _babyWeight = existingDetails.babyWeight;
        // Don't overwrite dueDate directly, it's calculated
        _safeNotifyListeners(); // Update UI with loaded data
      } else if (!_isDisposed) {
        _logger.i("No existing pregnancy details found for user $userId");
      }
    } catch (e, s) {
      _logger.e(
        "Failed to load existing pregnancy details",
        error: e,
        stackTrace: s,
      );
      _setErrorMessage("Could not load existing details.");
      _safeNotifyListeners(); // Show error if needed
    } finally {
      _setLoading(false);
    }
  }

  // --- Save/Add Data ---
  Future<bool> addOrUpdatePregnancyDetail() async {
    // Renamed for clarity
    final userId = _authViewModel.currentUser?.uid; // Or localUser?.id

    // --- Input Validation ---
    if (userId == null || userId.isEmpty) {
      _setErrorMessage("Cannot save details: User not identified.");
      _logger.e("addOrUpdatePregnancyDetail failed: User ID is null or empty.");
      return false;
    }
    if (_selectedStartingDate == null) {
      _setErrorMessage("Please select the first day of your last period.");
      _logger.e(
        "addOrUpdatePregnancyDetail failed: _selectedStartingDate is null.",
      );
      return false;
    }
    if (_babyHeight == null || _babyHeight! <= 0) {
      _setErrorMessage("Please enter a valid baby height.");
      _logger.e(
        "addOrUpdatePregnancyDetail failed: Invalid height ($_babyHeight).",
      );
      return false;
    }
    if (_babyWeight == null || _babyWeight! <= 0) {
      _setErrorMessage("Please enter a valid baby weight.");
      _logger.e(
        "addOrUpdatePregnancyDetail failed: Invalid weight ($_babyWeight).",
      );
      return false;
    }
    // --- End Validation ---

    _setLoading(true);
    clearError(); // Clear previous errors

    try {
      final DateTime startDate = _selectedStartingDate!;
      // Standard gestation is 280 days (40 weeks) from LMP (startDate)
      final DateTime estimatedDueDate = startDate.add(
        const Duration(days: 280),
      );

      // Dynamic calculation (consider removing these fields from Entity/DB)
      // final Duration difference = DateTime.now().difference(startDate);
      // final int currentWeek = difference.isNegative ? 0 : (difference.inDays / 7).floor();
      // final int daysIntoWeek = difference.isNegative ? 0 : (difference.inDays % 7);

      final details = PregnancyDetails(
        userId: userId,
        startingDay: startDate, // Pass DateTime
        dueDate: estimatedDueDate, // Pass calculated DateTime
        babyHeight: _babyHeight!,
        babyWeight: _babyWeight!,
        // Remove these if calculated dynamically elsewhere (e.g., DashboardViewModel)
        // weeksPregnant: currentWeek,
        // daysPregnant: daysIntoWeek,
      );

      _logger.d(
        "Attempting to save/update PregnancyDetails via UseCase: ${details.toJson()}",
      );

      // UseCase handles deciding whether to add or update based on its logic
      // (or Repository could handle this via upsert)
      // Assuming addPregnancyDetail in UseCase/Repo handles upsert logic
      await _pregnancyDetailUseCase.addPregnancyDetail(details);

      _logger.i(
        "Pregnancy details saved/updated successfully via UseCase for user $userId.",
      );
      _setLoading(false);
      return true; // Indicate success
    } catch (e, stackTrace) {
      _logger.e(
        "Failed to save/update pregnancy details",
        error: e,
        stackTrace: stackTrace,
      );
      _setErrorMessage(
        "Failed to save details. Please check connection and try again.",
      );
      _setLoading(false);
      return false; // Indicate failure
    }
  }

  @override
  void dispose() {
    _logger.i("Disposing PregnancyDetailViewModel.");
    _isDisposed = true; // Set flag
    super.dispose();
  }
}
