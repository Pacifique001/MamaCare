// lib/presentation/viewmodel/calendar_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mama_care/domain/entities/calendar_notes_model.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/usecases/calendar_use_case.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart';

class CalendarViewModel extends ChangeNotifier {
  final CalendarUseCase _useCase;
  final AuthViewModel _authViewModel; // <<< INJECTED AuthViewModel
  final Logger _logger = locator<Logger>();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<dynamic> _allEvents = [];
  bool _isLoading = false;
  String? _error;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  CalendarViewModel(this._useCase, this._authViewModel) {
    // <<< MODIFIED CONSTRUCTOR
    _logger.i("CalendarViewModel initialized. Selected date: $_selectedDate");

    if (_authViewModel.isAuthenticated) {
      // loadDataForSelectedDate(); // Be careful with async calls in constructor
    }
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CalendarFormat get calendarFormat => _calendarFormat;

  List<dynamic> get eventsForSelectedDate {
    return _allEvents.where((event) {
      if (event is CalendarNote) return isSameDay(event.date, _selectedDate);
      if (event is Appointment)
        return isSameDay(event.appointmentDateTime, _selectedDate);
      return false;
    }).toList();
  }

  List<dynamic> getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      if (event is CalendarNote) return isSameDay(event.date, day);
      if (event is Appointment)
        return isSameDay(event.appointmentDateTime, day);
      return false;
    }).toList();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return; // Avoid unnecessary notifications
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_error == message) return; // Avoid unnecessary notifications
    _error = message;
    notifyListeners();
  }

  void updateSelectedDate(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDate, selectedDay)) {
      _logger.d("Selected date updated to: $selectedDay");
      _selectedDate = selectedDay;
      _focusedDate = focusedDay;
      loadDataForSelectedDate();
      notifyListeners();
    }
  }

  void updateFocusedDate(DateTime focusedDay) {
    if (!isSameDay(_focusedDate, focusedDay)) {
      _logger.d("Focused date updated to: $focusedDay (page changed)");
      _focusedDate = focusedDay;
      notifyListeners();
    }
  }

  void setCalendarFormat(CalendarFormat format) {
    if (_calendarFormat != format) {
      _logger.d("Calendar format changed to: $format");
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void goToToday() {
    _logger.d("Navigating calendar to today");
    final today = DateTime.now();
    if (!isSameDay(_selectedDate, today)) {
      _selectedDate = today;
      loadDataForSelectedDate();
    }
    _focusedDate = today;
    notifyListeners();
  }

  Future<void> loadDataForSelectedDate({String? userIdOverride}) async {
    // Now use the injected _authViewModel
    final String? currentUserId =
        userIdOverride ??
        _authViewModel.currentUser?.uid; // <<< USE _authViewModel

    if (currentUserId == null) {
      _logger.w(
        "Cannot load calendar data: User ID is null. User might not be authenticated.",
      );
      _allEvents = []; // Clear events if user is not authenticated
      _setError("Please log in to see calendar events.");
      _setLoading(false); // Ensure loading is stopped
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      if (_useCase.isUserAuthenticated()) {
        // Assuming CalendarUseCase has AuthViewModel and this method
        final String actualUserId =
            _useCase.getCurrentUserId()!; // UseCase provides the ID

        final fetchedNotes = await _useCase.getNotesForDateRange(
          _selectedDate.subtract(const Duration(days: 35)),
          _selectedDate.add(const Duration(days: 35)),
          actualUserId,
        );
        final fetchedAppointments = await _useCase.getAppointmentsForDateRange(
          _selectedDate.subtract(const Duration(days: 35)),
          _selectedDate.add(const Duration(days: 35)),
          actualUserId,
        );

        _allEvents = [...fetchedNotes, ...fetchedAppointments];
        _logger.i(
          "Loaded ${_allEvents.length} total events for date range around $_selectedDate for user $actualUserId",
        );
      } else {
        _logger.w(
          "Cannot load calendar data: user not authenticated (checked via UseCase).",
        );
        _allEvents = [];
        _setError("Please log in to see calendar events.");
      }
    } catch (e, s) {
      // Added stackTrace
      _logger.e(
        "Error loading data for selected date: $_selectedDate",
        error: e,
        stackTrace: s,
      );
      _setError(
        "Failed to load events. Please try again.",
      ); // User-friendly error
      _allEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addNote(String noteText, String userIdFromUI) async {
    final String? authenticatedUserId = _authViewModel.currentUser?.uid;
    if (authenticatedUserId == null || authenticatedUserId != userIdFromUI) {
      _logger.e(
        "Auth mismatch or not authenticated during addNote. UI User: $userIdFromUI, VM Auth User: $authenticatedUserId",
      );
      _setError("Authentication error. Please re-login and try again.");
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      final newNote = CalendarNote(
        // id: null, // Let repository/backend handle ID generation
        userId: authenticatedUserId,
        date: _selectedDate,
        note: noteText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _useCase.createNote(newNote);
      _logger.i(
        "Added note: '$noteText' for date: $_selectedDate for user $authenticatedUserId",
      );
      await loadDataForSelectedDate(
        userIdOverride: authenticatedUserId,
      ); // Refresh list for the current user
    } catch (e, s) {
      _logger.e("Error adding note", error: e, stackTrace: s);
      _setError("Failed to save note. Please try again.");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final String? currentUserId = _authViewModel.currentUser?.uid;
    if (currentUserId == null) {
      _logger.w("Cannot delete note: User not authenticated.");
      _setError("Please log in to perform this action.");
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _useCase.deleteNote(noteId, currentUserId);
      _logger.i("Deleted note ID: $noteId for user $currentUserId");
      _allEvents.removeWhere(
        (event) => event is CalendarNote && event.id == noteId,
      );
      notifyListeners();
      await loadDataForSelectedDate(
        userIdOverride: currentUserId,
      ); // Refresh list
    } catch (e, s) {
      _logger.e("Error deleting note", error: e, stackTrace: s);
      _setError("Failed to delete note. Please try again.");
    } finally {
      _setLoading(false);
    }
  }
}
