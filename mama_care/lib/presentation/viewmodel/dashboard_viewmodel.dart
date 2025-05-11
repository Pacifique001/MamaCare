import 'package:flutter/foundation.dart'; // Use foundation for ChangeNotifier
import 'package:injectable/injectable.dart'; // Assuming injectable setup
import 'package:logger/logger.dart'; // Assuming logger is injected
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/domain/usecases/dashboard_use_case.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/navigation/navigation_service.dart'; // Assuming NavigationService exists
import 'package:mama_care/navigation/router.dart';
// Remove direct FirebaseAuth import if not strictly needed here anymore
// import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException;
import 'package:mama_care/core/error/exceptions.dart'; // Import custom exceptions

@injectable // Make ViewModel injectable
class DashboardViewModel extends ChangeNotifier {
  // --- Dependencies (Injected) ---
  final DashboardUseCase _useCase;
  final DatabaseHelper _database;
  final Logger _logger;
  // Remove FirebaseAuth dependency if userId is always passed in
  // final FirebaseAuth _auth;

  // --- State ---
  UserModel? _user;
  PregnancyDetails? _pregnancyDetails;
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false; // Flag to prevent calls after dispose

  // --- Constructor ---
  DashboardViewModel(
    this._useCase,
    this._database,
    this._logger,
    
  ) {
    _logger.i("DashboardViewModel initialized.");
    
  }

  // --- Getters ---
  UserModel? get user => _user;
  PregnancyDetails? get pregnancyDetails => _pregnancyDetails;

  int get currentWeek {
    return _calculateWeekFromDueDate() ?? 1; // Provide default
  }

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Safely notify listeners only if the ViewModel hasn't been disposed.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --- Private State Setters ---
  void _setLoading(bool value) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
    _logger.d("Dashboard loading state: $_isLoading");
    _safeNotifyListeners();
  }

  void _setError(String? message) {
    if (_error == message || _isDisposed) return;
    _error = message;
    if (message != null) {
      _logger.e("DashboardViewModel Error: $message");
    } else {
      _logger.d("DashboardViewModel error cleared.");
    }
    _safeNotifyListeners();
  }

  void _clearError() => _setError(null);

  // --- Core Data Loading ---

  /// Loads all essential data for the dashboard for the specified user.
  /// Call this on view init or refresh.
  ///
  /// Requires the [userId] of the currently authenticated user.
  Future<void> loadData({required String userId}) async {
    // <-- ADDED required userId parameter
    // Prevent loading if already loading or disposed
    if (_isLoading || _isDisposed) return;

    _logger.i(
      'Dashboard loading data for user: $userId...',
    ); // Log received userId
    _setLoading(true);
    _clearError();

    // Removed internal fetching and null check for userId, as it's now required

    try {
      // Run operations concurrently for faster loading, passing the userId
      final results = await Future.wait([
        _fetchUserDetails(userId), // Pass userId
        _fetchPregnancyDetails(userId), // Pass userId
        _fetchAppointments(userId), // Pass userId (renamed for clarity)
      ]);

      // Results from Future.wait are in order. Since methods modify state directly,
      // we don't strictly need to assign from results here, but it's good practice
      // if methods were changed to return values.
      // Example: _user = results[0] as UserModel?;

      _logger.i('Dashboard data loaded successfully for user: $userId.');
    } catch (e, stackTrace) {
      _logger.e(
        'Dashboard data loading failed for user $userId',
        error: e,
        stackTrace: stackTrace,
      );
      _handleError(
        _parseError(e),
        error: e,
        stackTrace: stackTrace,
      ); // Pass original error info
      // Ensure state is cleared on critical load failure
      _user = null;
      _pregnancyDetails = null;
      _appointments = [];
      _safeNotifyListeners(); // Ensure UI reflects cleared state
    } finally {
      _setLoading(false); // Ensure loading state is always turned off
    }
  }

  /// Fetches user details for the given userId.
  Future<void> _fetchUserDetails(String userId) async {
    _logger.d('Fetching user details for $userId...');
    try {
      _user = await _useCase.getUserDetails(userId);
      _logger.d('User details fetched: ${_user?.name}');
      // No need to notify here, loadData completion handles it
    } on AuthException catch (e) {
      _logger.e('Auth error fetching user details', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Failed to fetch user details', error: e);
      throw DataProcessingException("Could not load user profile.", cause: e);
    }
  }

  /// Fetches pregnancy details for the given userId from UseCase/DB.
  Future<void> _fetchPregnancyDetails(String userId) async {
    _logger.d('Fetching pregnancy details for $userId...');
    try {
      // Attempt to fetch from remote/use case first
      final remoteDetails = await _useCase.getPregnancyDetails(userId);

      if (remoteDetails != null) {
        _logger.d('Pregnancy details fetched from source.');
        _pregnancyDetails = remoteDetails;
        // Save/update the fetched details to the local database
        await _database.upsertPregnancyDetail(
          _pregnancyDetails!.toJson(), // Pass userId if toJson needs it
        );
        _logger.d('Pregnancy details saved locally.');
      } else {
        _logger.w('No remote pregnancy details found, attempting local load.');
        final localDetailsMap = await _database.getPregnancyDetails(userId);
        if (localDetailsMap != null) {
          _pregnancyDetails = PregnancyDetails.fromJson(localDetailsMap);
          _logger.i('Loaded pregnancy details from local DB.');
        } else {
          _logger.i('No pregnancy details found locally either.');
          _pregnancyDetails = null;
        }
      }
      // No need to notify here, loadData completion handles it
    } on DatabaseException catch (e) {
      _logger.e('Database error related to pregnancy details', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Failed to fetch or save pregnancy details', error: e);
      throw DataProcessingException(
        "Could not load pregnancy information.",
        cause: e,
      );
    }
  }

  /// Fetches appointments for the given userId.
  Future<void> _fetchAppointments(String userId) async {
    // Renamed for clarity
    _logger.d('Fetching appointments for $userId...');
    try {
      // Assuming use case needs userId for filtering/fetching
      _appointments = (await _useCase.getAppointments(userId))!;
      _logger.d('Appointments fetched: ${_appointments.length}');
      // No need to notify here, loadData completion handles it
    } catch (e) {
      _logger.e('Failed to fetch appointments', error: e);
      throw DataProcessingException("Could not load appointments.", cause: e);
    }
  }

  // --- Navigation ---
  // (Navigation methods remain the same)
  void navigateToAddAppointment() {
    _logger.d('Navigating to Add Appointment screen.');
    NavigationService.navigateTo(NavigationRoutes.addAppointment);
  }

  void navigateToPregnancyDetails() {
    _logger.d('Navigating to Pregnancy Details screen.');
    NavigationService.navigateTo(NavigationRoutes.pregnancy_detail);
  }

  void navigateToRoute(String routeName, {Object? arguments}) {
    _logger.d('Navigating to route: $routeName with args: $arguments');
    NavigationService.navigateTo(routeName, arguments: arguments);
  }

  // --- Error Parsing & Handling ---
  // (_parseError, _handleError remain the same)
  String _parseError(dynamic error) {
    _logger.e("Parsing error for UI display", error: error);
    if (error is AppException) {
      return error.message;
    }
    // Add specific error type checks if needed (e.g., FirebaseException, DioError)
    // if (error is FirebaseAuthException) {
    //   return error.message ?? "An authentication error occurred.";
    // }
    if (error is Exception) {
      return "An unexpected error occurred. Please try again.";
    }
    return "An unknown error occurred.";
  }

  void _handleError(
    String message, {
    bool isFatal = false,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Log with original error and stacktrace if available
    _logger.e(
      "DashboardViewModel Error: $message",
      error: error,
      stackTrace: stackTrace,
    );
    _setError(message); // Update the UI-facing error message
    if (isFatal) {
      _user = null;
      _pregnancyDetails = null;
      _appointments = [];
      _safeNotifyListeners(); // Update UI to reflect cleared state
    }
    _setLoading(false); // Ensure loading is stopped
  }

  // --- Calculation ---
  int? _calculateWeekFromDueDate() {
    // (Keep the same implementation)
    final detailsDueDate = _pregnancyDetails?.dueDate;
    if (detailsDueDate == null) return null;
    final lmpDate = detailsDueDate.subtract(const Duration(days: 280));
    final today = DateTime.now();
    if (lmpDate.isAfter(today)) return 1;
    final pregnancyDuration = today.difference(lmpDate);
    final calculatedWeek = (pregnancyDuration.inDays ~/ 7) + 1;
    return calculatedWeek.clamp(1, 42);
  }

  // --- Dispose ---
  @override
  void dispose() {
    _logger.i("Disposing DashboardViewModel.");
    _isDisposed = true; // Set flag
    super.dispose();
  }
}
