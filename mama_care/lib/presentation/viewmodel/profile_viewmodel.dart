// lib/presentation/viewmodel/profile_viewmodel.dart

import 'dart:io'; // For File type if handling image upload

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/domain/usecases/profile_use_case.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Inject AuthViewModel
//import 'package:mama_care/core/error/exceptions.dart'; // For exceptions

enum ViewState { initial, loading, success, error }

@injectable
class ProfileViewModel extends ChangeNotifier {
  final ProfileUseCase _profileUseCase;
  final AuthViewModel _authViewModel; // Inject AuthViewModel
  final Logger _logger;

  // State specific to Profile Screen
  PregnancyDetails? _pregnancyDetails;
  ViewState _viewState = ViewState.initial;
  String? _errorMessage;

  // State for Editing User Profile
  bool _isEditing = false;
  bool _isLoadingProfileData = false;

  // Controllers for editable fields - initialize when editing starts
  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  // Add email controller ONLY if you intend to handle email change flow (complex)
  TextEditingController? _emailController;
  String? _selectedImageFilePath; // For image picker result

  ProfileViewModel(this._profileUseCase, this._authViewModel, this._logger) {
    _logger.i("ProfileViewModel initialized.");
    // Listen to AuthViewModel to get User ID when available
    _authViewModel.addListener(_onAuthChange);
    // Initial load attempt (might do nothing if user isn't logged in yet)
    _loadInitialData();
  }

  // Getters
  PregnancyDetails? get pregnancyDetails => _pregnancyDetails;
  ViewState get viewState => _viewState;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;
  TextEditingController? get nameController => _nameController;
  TextEditingController? get phoneController => _phoneController;
  TextEditingController? get emailController => _emailController;
  String? get selectedImageFilePath => _selectedImageFilePath;
  bool get isLoading => _isLoadingProfileData;

  // --- Listener for Auth Changes ---
  void _onAuthChange() {
    // If user logs out while profile is shown, potentially clear data
    if (!_authViewModel.isAuthenticated && _viewState != ViewState.initial) {
      _logger.w("User logged out, clearing profile data.");
      _pregnancyDetails = null;
      _setViewState(ViewState.initial); // Reset state
      _endEditing(saveChanges: false); // Cancel editing if active
    }
    // If user logs IN and data hasn't loaded, trigger load
    else if (_authViewModel.isAuthenticated &&
        _viewState == ViewState.initial) {
      _loadInitialData();
    }
  }

  // --- Data Loading ---
  Future<void> _loadInitialData() async {
    final userId = _authViewModel.localUser?.id;
    if (userId == null || userId.isEmpty) {
      _logger.i(
        "ProfileViewModel: Cannot load initial data, user not logged in.",
      );
      // Ensure state is initial if no user
      if (_viewState != ViewState.initial) _setViewState(ViewState.initial);
      return;
    }
    // Load both user (already in AuthVM) and pregnancy details
    await getPregnancyDetails();
  }

  Future<void> getPregnancyDetails() async {
    final userId = _authViewModel.localUser?.id;
    if (userId == null || userId.isEmpty) {
      _setError("Cannot load details: User not logged in.");
      return;
    }

    _setViewState(ViewState.loading);
    _clearError();

    try {
      _pregnancyDetails = await _profileUseCase.getPregnancyDetails(userId);
      _logger.i(
        _pregnancyDetails != null
            ? "Pregnancy details loaded successfully for user $userId."
            : "No pregnancy details found for user $userId.",
      );
      _setViewState(ViewState.success); // Set success even if details are null
    } catch (e, s) {
      _logger.e("Failed to load pregnancy details", error: e, stackTrace: s);
      _setError('Failed to load pregnancy details: ${e.toString()}');
      _pregnancyDetails = null; // Ensure null on error
    }
  }

  Future<void> refreshData() async {
    // Reload pregnancy details, user data is handled by AuthViewModel automatically
    final userId = _authViewModel.localUser?.id;
    if (userId == null || userId.isEmpty) {
      _logger.w("Cannot refresh profile data, user not logged in.");
      return;
    }
    _logger.d("Refreshing profile data (Pregnancy Details)...");
    // Keep existing data while loading for smoother refresh
    // final currentDetails = _pregnancyDetails;
    // _setViewState(ViewState.loading); // Or show subtle loading indicator
    try {
      await getPregnancyDetails(); // Refetch
    } catch (e) {
      // _pregnancyDetails = currentDetails; // Restore on error if needed
      _logger.e("Refresh failed: $e");
      _setError("Failed to refresh data."); // Show error state
    }
  }

  // --- Editing Logic ---

  void startEditing() {
    if (_authViewModel.localUser == null)
      return; // Should not happen if UI allows editing

    _logger.d("Starting profile edit.");
    _isEditing = true;
    _selectedImageFilePath = null; // Clear selected image path
    // Initialize controllers with current user data from AuthViewModel
    _nameController = TextEditingController(
      text: _authViewModel.localUser!.name,
    );
    _phoneController = TextEditingController(
      text: _authViewModel.localUser!.phoneNumber,
    );
    _emailController = TextEditingController(
      text: _authViewModel.localUser!.email,
    ); // If allowing email edit

    notifyListeners();
  }

  void cancelEditing() {
    _logger.d("Cancelling profile edit.");
    _endEditing(saveChanges: false);
  }

  // Called by UI when an image is picked
  void setImageFilePath(String? path) {
    if (_isEditing) {
      _selectedImageFilePath = path;
      notifyListeners(); // Update UI to show preview maybe
    }
  }

  Future<bool> saveUserProfileChanges() async {
    if (!_isEditing || _authViewModel.localUser == null) return false;
    if (_nameController == null || _phoneController == null) return false;

    _logger.i("Attempting to save profile changes via AuthViewModel...");
    // DO NOT set loading state on AuthViewModel here. AuthViewModel manages its own.
    // _authViewModel.setLoading(true); // REMOVE THIS
    _authViewModel.clearError(); // Clear potential previous global errors
    _clearError(); // Clear potential previous profile-specific errors

    // --- Call AuthViewModel to handle the update ---
    // AuthViewModel.updateUserProfile will set its own isLoading flag internally
    final result = await _authViewModel.updateUserProfile(
      name: _nameController!.text.trim(),
      email: _authViewModel.localUser!.email, // Pass current email
      phoneNumber: _phoneController!.text.trim(),
      localImageFilePath: _selectedImageFilePath,
    );

    // AuthViewModel.updateUserProfile will set its loading to false internally
    // _authViewModel.setLoading(false); // REMOVE THIS

    if (result['status'] == 'success') {
      _logger.i("Profile update successful via AuthViewModel.");
      _endEditing(saveChanges: true); // Exit edit mode (calls notifyListeners)
      return true;
    } else {
      final errorMsg = result['message'] ?? "Failed to save profile.";
      _logger.e("Profile update failed: $errorMsg");
      // Set the error message *on this ProfileViewModel* so the ProfileView can display it
      _setError(errorMsg); // Calls notifyListeners
      // NOTE: We *don't* exit edit mode on failure, user can retry or cancel
      return false;
    }
  }

  // Helper to clean up editing state
  void _endEditing({required bool saveChanges}) {
    _isEditing = false;
    _selectedImageFilePath = null;
    _nameController?.dispose();
    _nameController = null;
    _phoneController?.dispose();
    _phoneController = null;
    _emailController?.dispose();
    _emailController = null;
    notifyListeners();
  }

  // --- State Management Helpers ---

  void _setLoading(bool value) {
    if (_isLoadingProfileData == value) return;
    _isLoadingProfileData = value;
    // Also update ViewState if loading starts/stops when initial/error
    if (value &&
        (_viewState == ViewState.initial || _viewState == ViewState.error)) {
      _viewState = ViewState.loading;
    } else if (!value && _viewState == ViewState.loading) {
      // Revert to initial if still no data, otherwise stay success/error
      _viewState =
          _pregnancyDetails != null ? ViewState.success : ViewState.initial;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _logger.e("ProfileViewModel Error: $message"); // Log error when set
    _setViewState(ViewState.error); // Set state and notify
  }

  void _setViewState(ViewState state) {
    if (_viewState == state) return;
    _viewState = state;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // If ViewState was error, reset it (e.g., back to success if data exists)
      if (_viewState == ViewState.error) {
        _setViewState(
          _pregnancyDetails != null ? ViewState.success : ViewState.initial,
        );
      } else {
        notifyListeners(); // Just notify if only clearing message without state change
      }
    }
  }

  @override
  void dispose() {
    _logger.i("Disposing ProfileViewModel.");
    // Clean up controllers if the VM is disposed while editing
    _nameController?.dispose();
    _phoneController?.dispose();
    _emailController?.dispose();
    _authViewModel.removeListener(_onAuthChange); // Remove listener
    super.dispose();
  }
}
