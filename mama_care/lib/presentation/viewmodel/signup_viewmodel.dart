// lib/presentation/viewmodel/signup_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/user_role.dart'; // Import UserRole
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel

@injectable
class SignupViewModel extends ChangeNotifier {
  // Dependencies
  final AuthViewModel _authViewModel; // Inject the central AuthViewModel
  final Logger _logger;

  // State specific to the signup process
  bool _isSigningUp = false;
  String? _signupError; // Store specific signup errors

  SignupViewModel(this._authViewModel, this._logger) {
    _logger.i("SignupViewModel initialized.");
    // Optional: Listen to AuthViewModel if needed, but direct calls are often sufficient.
    // _authViewModel.addListener(_handleAuthViewModelChanges);
  }

  // Getters for UI binding
  bool get isSigningUp => _isSigningUp;
  String? get signupError => _signupError;

  // --- Private State Setters ---
  void _setLoading(bool value) {
    // Use the specific _isSigningUp flag for this ViewModel's loading state
    if (_isSigningUp == value) return;
    _isSigningUp = value;
    notifyListeners(); // Notify UI about signup-specific loading
  }

  void _setError(String? message) {
    // Use the specific _signupError for this ViewModel
    if (_signupError == message) return;
    _signupError = message;
    if (message != null) {
      _logger.w("SignupViewModel Error: $message");
    }
    // We notify explicitly when setting/clearing error in this VM
    notifyListeners();
  }

  /// Clears the signup-specific error message.
  void clearSignupError() {
    if (_signupError != null) {
      _setError(null); // Calls notifyListeners
    }
  }

  /// Initiates the signup process via AuthViewModel.
  /// Returns the result Map from AuthViewModel.
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    String? phoneNumber, // Keep phone optional for now
    String? profileImageUrl,
    required UserRole initialRole,
  }) async {
    _logger.i("Signup requested - Email: $email, Role: ${initialRole.name}");
    _setLoading(true);
    _setError(null); // Clear previous signup-specific error

    // Basic local validation before calling AuthViewModel
    if (email.trim().isEmpty || password.isEmpty || name.trim().isEmpty) {
      const errorMsg = "Name, email, and password cannot be empty.";
      _setError(errorMsg);
      _setLoading(false);
      return {'status': 'error', 'message': errorMsg}; // Return error map
    }
    // Add password confirmation check here if applicable in UI

    try {
      // Call the central AuthViewModel to handle the actual signup logic
      final Map<String, dynamic> result = await _authViewModel.signUpWithEmail(
        email: email.trim(),
        password: password, // Don't trim password
        name: name.trim(),
        phoneNumber:
            phoneNumber?.trim().isEmpty ?? true
                ? null
                : phoneNumber!.trim(), // Handle empty phone
        profileImageUrl: profileImageUrl,
        initialRole: initialRole,
      );

      if (result['status'] == 'success_needs_verification') {
        _logger.i(
          "Signup initiated successfully via AuthViewModel for $email.",
        );
        // No local error to set
      } else {
        // AuthViewModel encountered an error, store its message locally
        final errMsg = result['message'] ?? 'Signup failed via AuthViewModel.';
        _setError(errMsg);
        _logger.w("Signup failed (via AuthViewModel): $errMsg");
      }

      _setLoading(false); // Stop signup-specific loading
      return result; // --- FORWARD THE ENTIRE RESULT MAP ---
    } on ArgumentError catch (e) {
      // Catch validation errors *before* calling AuthViewModel
      _logger.w("Signup input validation error: ${e.message}");
      _setError(e.message);
      _setLoading(false);
      return {'status': 'error', 'message': e.message}; // Return error map
    } catch (e, stackTrace) {
      // Catch unexpected errors during the call to AuthViewModel
      _logger.e(
        'Unexpected error during signup call',
        error: e,
        stackTrace: stackTrace,
      );
      final errorMsg = "An unexpected error occurred during signup.";
      _setError(errorMsg);
      _setLoading(false);
      // Return an error map consistent with AuthViewModel's format
      return {'status': 'error', 'message': errorMsg};
    }
    // No finally block needed for loading state, handled in try/catch
  }

  @override
  void dispose() {
    _logger.i("Disposing SignupViewModel.");
    // Remove listener if added:
    // _authViewModel.removeListener(_handleAuthViewModelChanges);
    super.dispose();
  }
}
