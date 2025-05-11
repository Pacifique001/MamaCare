// lib/presentation/viewmodel/appointment_detail_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart';
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/navigation/navigation_service.dart'; // For navigation
import 'package:mama_care/navigation/router.dart'; // For route names

@injectable
class AppointmentDetailViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final Logger _logger;
  // No direct navigation here, using NavigationService instead
  // final NavigationService _navigationService; // Inject if preferred over static access

  AppointmentDetailViewModel(
    this._appointmentUseCase,
    this._logger,
    // this._navigationService, // Inject if preferred
  ) {
    _logger.i("AppointmentDetailViewModel Initialized");
  }

  // --- State ---
  Appointment? _appointment;
  bool _isLoading = false;
  String? _loadingMessage; // Optional message during loading (e.g., "Cancelling...")
  String? _error;
  bool _isDisposed = false;

  // --- Getters ---
  Appointment? get appointment => _appointment;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage; // Expose loading message
  String? get error => _error;

  // --- Safe Notifier ---
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --- State Setters ---
  void _setLoading(bool value, {String? message}) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
    // Set loading message only when loading starts, clear when stops
    _loadingMessage = _isLoading ? message : null;
    // Clear error when loading starts for a new operation
    if (_isLoading) {
        _error = null;
    }
    _safeNotifyListeners();
  }

  void _setError(String? message) {
     if (_error == message || _isDisposed) return;
    _error = message;
    if(message != null) _logger.e("AppointmentDetailViewModel Error: $message");
    // Ensure loading is off if an error occurs
    if (_isLoading) {
        _isLoading = false;
        _loadingMessage = null;
    }
    _safeNotifyListeners();
  }

   void clearError() {
     if (_error != null) {
      _error = null;
      _safeNotifyListeners();
     }
   }
  
  // --- Data Fetching & Refreshing ---
  Future<void> fetchAppointmentDetails(String appointmentId) async {
    if (_isLoading || _isDisposed) return;

    _logger.d("Fetching details for appointment ID: $appointmentId");
    _setLoading(true, message: "Loading details..."); // Show loading message
    clearError(); // Use clearError method

    try {
      final fetchedAppointment = await _appointmentUseCase.getAppointmentById(appointmentId);

      if (!_isDisposed) {
        if (fetchedAppointment != null) {
           _logger.i("Successfully fetched appointment details: ${fetchedAppointment.id}");
          _appointment = fetchedAppointment;
        } else {
          _logger.w("Appointment with ID $appointmentId not found.");
          _setError("Appointment details could not be found.");
          _appointment = null;
        }
      }
    } on AppException catch (e) {
        _logger.e("AppException fetching appointment $appointmentId", error: e);
        if (!_isDisposed) _setError(e.message);
    }
    catch (e, stackTrace) {
      _logger.e("Error fetching appointment $appointmentId", error: e, stackTrace: stackTrace);
       if (!_isDisposed) _setError("An unexpected error occurred while loading details.");
    } finally {
      if (!_isDisposed) {
        _setLoading(false); // Turn off loading (also clears loadingMessage)
      }
    }
  }

  /// Refreshes the current appointment details.
  Future<void> refreshDetails() async {
      if (_appointment?.id == null || _isLoading || _isDisposed) {
          _logger.w("Cannot refresh details: No appointment loaded, already loading, or disposed.");
          return;
      }
      _logger.d("Refreshing details for appointment ID: ${_appointment!.id!}");
      // Re-use the fetch logic
      await fetchAppointmentDetails(_appointment!.id!);
  }

  // --- Actions ---

  /// Cancels the currently loaded appointment.
  /// Returns true on success, false on failure.
  Future<bool> cancelThisAppointment() async {
     if (_appointment == null || _isLoading || _isDisposed) {
         _logger.w("Cannot cancel: No appointment loaded, already loading, or disposed.");
         return false;
     }
     // Optional: Double-check if cancellable based on current state
     if (!(_appointment!.status.canBeCancelled)) {
         _logger.w("Attempted to cancel appointment ${_appointment!.id} with non-cancellable status ${_appointment!.status.name}");
         _setError("This appointment cannot be cancelled in its current state.");
         return false;
     }


     _setLoading(true, message: "Cancelling appointment...");
     clearError();

     try {
        await _appointmentUseCase.cancelAppointment(_appointment!.id!); // Assuming ID is non-null here
        _logger.i("Appointment cancelled successfully via UseCase: ${_appointment!.id!}");

        // Update local state to reflect cancellation immediately
        if(!_isDisposed) {
           _appointment = _appointment!.copyWith(status: AppointmentStatus.cancelled);
           _safeNotifyListeners(); // Update UI with new status
        }
        _setLoading(false);
        return true; // Indicate success
     } on AppException catch (e) {
          _logger.e("AppException cancelling appointment via ViewModel", error: e);
         if(!_isDisposed) _setError(e.message); // Use specific error message
         _setLoading(false);
         return false;
     }
     catch (e, s) {
         _logger.e("Error cancelling appointment via ViewModel", error: e, stackTrace: s);
         if(!_isDisposed) _setError("Could not cancel appointment. Please try again.");
         _setLoading(false);
         return false;
     }
  }

  /// Navigates to the reschedule screen for the current appointment.
  void navigateToReschedule() {
      if (_appointment?.id == null || _isDisposed) {
         _logger.e("Cannot navigate to reschedule: No appointment ID available or disposed.");
         // Optionally set an error message or handle silently
         _setError("Cannot reschedule appointment details.");
         return;
      }

      if (!(_appointment!.status.canBeRescheduled)) {
         _logger.w("Attempted to reschedule appointment ${_appointment!.id} with non-reschedulable status ${_appointment!.status.name}");
         _setError("This appointment cannot be rescheduled in its current state.");
         _safeNotifyListeners(); // Show the error
         return;
     }


      _logger.d("Navigating to reschedule screen for appointment: ${_appointment!.id!}");
      // Use the static NavigationService (or injected instance)
      NavigationService.navigateTo(
          NavigationRoutes.rescheduleAppointment,
          arguments: _appointment!.id!, // Pass the appointment ID
      );
  }

  // --- Dispose ---
  @override
  void dispose() {
    _logger.i("Disposing AppointmentDetailViewModel.");
    _isDisposed = true;
    super.dispose();
  }
}