// lib/presentation/viewmodel/reschedule_viewmodel.dart
import 'package:flutter/material.dart'; // Import for TimeOfDay
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/usecases/appointment_usecase.dart';
import 'package:mama_care/core/error/exceptions.dart';

@injectable
class RescheduleViewModel extends ChangeNotifier {
  final AppointmentUseCase _appointmentUseCase;
  final Logger _logger;

  RescheduleViewModel(this._appointmentUseCase, this._logger) {
    _logger.i("RescheduleViewModel Initialized");
  }

  // --- State ---
  String? _appointmentId;
  Appointment? _originalAppointment; // Store original details
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  String? _loadingMessage;
  String? _error;
  bool _isDisposed = false;

  // --- Getters ---
  Appointment? get originalAppointment => _originalAppointment;
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
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
    _loadingMessage = _isLoading ? message : null;
    if (_isLoading) _error = null; // Clear error when loading starts
    _safeNotifyListeners();
  }

  void _setError(String? message) {
     if (_error == message || _isDisposed) return;
    _error = message;
    if(message != null) _logger.e("RescheduleViewModel Error: $message");
    if (_isLoading) { // Ensure loading stops if error occurs
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

   // --- Initialization & Selection ---
   Future<void> initialize(String appointmentId) async {
     if (_isLoading || _isDisposed) return;
     _appointmentId = appointmentId;
     _logger.d("Initializing RescheduleViewModel for appointment ID: $appointmentId");
     _setLoading(true, message: "Loading current details...");
     clearError();

     try {
       final fetchedAppointment = await _appointmentUseCase.getAppointmentById(appointmentId);
        if (!_isDisposed) {
          if (fetchedAppointment != null) {
             _originalAppointment = fetchedAppointment;
             // Pre-fill date/time based on original appointment
             final originalDateTime = fetchedAppointment.dateTime.toDate();
             _selectedDate = DateTime(originalDateTime.year, originalDateTime.month, originalDateTime.day);
             _selectedTime = TimeOfDay.fromDateTime(originalDateTime);
             _logger.i("Loaded original appointment details for rescheduling.");
          } else {
             _logger.e("Failed to load original appointment $appointmentId for rescheduling.");
             _setError("Could not load original appointment details.");
             _originalAppointment = null;
          }
       }
     } catch (e, s) {
       _logger.e("Error initializing RescheduleViewModel", error: e, stackTrace: s);
        if (!_isDisposed) _setError("Failed to load appointment details.");
     } finally {
        if (!_isDisposed) _setLoading(false);
     }
   }

   void selectDate(DateTime date) {
     if (_isDisposed) return;
     // Keep only the date part
     _selectedDate = DateTime(date.year, date.month, date.day);
     _logger.d("Reschedule date selected: $_selectedDate");
     _safeNotifyListeners();
   }

    void selectTime(TimeOfDay time) {
     if (_isDisposed) return;
     _selectedTime = time;
      _logger.d("Reschedule time selected: $_selectedTime");
     _safeNotifyListeners();
   }

  // --- Reschedule Action ---
  Future<bool> confirmReschedule() async {
    if (_appointmentId == null || _isLoading || _isDisposed) return false;

    // Validation
    if (_selectedDate == null || _selectedTime == null) {
      _setError("Please select both a new date and time.");
       _safeNotifyListeners(); // Show error in UI
      return false;
    }

    // Combine Date and Time
    final DateTime newDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Optional: Prevent rescheduling to the exact same time
    if (_originalAppointment != null && newDateTime.isAtSameMomentAs(_originalAppointment!.dateTime.toDate())) {
        _setError("Please select a different date or time.");
        _safeNotifyListeners();
        return false;
    }

    _setLoading(true, message: "Rescheduling...");
    clearError();

    try {
        await _appointmentUseCase.rescheduleAppointment(_appointmentId!, newDateTime);
        _logger.i("Reschedule successful for appointment $_appointmentId via UseCase.");
        _setLoading(false);
        return true; // Indicate success
    } on AppException catch(e) {
         _logger.e("AppException rescheduling appointment $_appointmentId", error: e);
         if(!_isDisposed) _setError(e.message);
         _setLoading(false);
         return false;
    } catch (e, s) {
         _logger.e("Error rescheduling appointment $_appointmentId", error: e, stackTrace: s);
         if(!_isDisposed) _setError("An unexpected error occurred during rescheduling.");
         _setLoading(false);
         return false;
    }
  }


  // --- Dispose ---
  @override
  void dispose() {
    _logger.i("Disposing RescheduleViewModel.");
    _isDisposed = true;
    super.dispose();
  }
}