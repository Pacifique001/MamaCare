// lib/domain/usecases/calendar_use_case.dart

import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/calendar_notes_model.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/data/repositories/calendar_repository.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Assuming AuthViewModel for user info
// You might prefer an abstract AuthService that AuthViewModel implements if you want to decouple further

@injectable
class CalendarUseCase {
  final CalendarRepository _repository;
  final AuthViewModel _authViewModel; // Inject AuthViewModel or an AuthService

  CalendarUseCase(this._repository, this._authViewModel);

  // --- Helper methods for auth state (provided by injected AuthViewModel) ---
  bool isUserAuthenticated() {
    return _authViewModel.isAuthenticated; // Or _authService.isAuthenticated
  }

  String? getCurrentUserId() {
    return _authViewModel
        .currentUser
        ?.uid; // Or _authService.getCurrentUserId()
  }

  // --- Note Methods ---
  Future<List<CalendarNote>> getNotesForDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) {
    // Ensure userId is passed to repository
    return _repository.getUserNotesForDateRange(userId, startDate, endDate);
  }

  // Old methods - decide if they are still needed or should be removed/refactored
  // Future<List<CalendarNote>> getDailyNotes(DateTime date) => _repository.getNotesForDate(date);
  // Future<List<CalendarNote>> getMonthlyNotes(DateTime date) => _repository.getNotesForMonth(date);

  Future<CalendarNote> createNote(CalendarNote note) {
    // The `note` object should already contain the `userId`.
    // The repository's addNote should use that.
    if (note.userId.isEmpty) {
      throw ArgumentError(
        "Cannot create note: userId is missing in the note object.",
      );
    }
    return _repository.addNote(note);
  }

  Future<void> deleteNote(String noteId, String userId) {
    // Pass userId to repository for potential ownership check before deletion
    return _repository.deleteNote(noteId, userId);
  }

  // --- Appointment Methods ---
  Future<List<Appointment>> getAppointmentsForDateRange(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) {
    // Ensure userId is passed to repository
    return _repository.getUserAppointmentsForDateRange(
      userId,
      startDate,
      endDate,
    );
  }

  // Old methods - decide if they are still needed or should be removed/refactored
  // Future<List<Appointment>> getDailyAppointments(DateTime date) => _repository.getAppointmentsForDate(date);
  // Future<List<Appointment>> getMonthlyAppointments(DateTime month) => _repository.getAppointmentsForMonth(month);

  Future<Appointment> addAppointment(Appointment appointment) {
    // The `appointment` object should contain relevant user IDs (patientId, doctorId).
    if (appointment.patientId.isEmpty && appointment.doctorId.isEmpty) {
      throw ArgumentError(
        "Cannot add appointment: At least one user ID (patient or doctor) must be present.",
      );
    }
    return _repository.addAppointment(appointment);
  }

  Future<void> updateAppointment(Appointment appointment) {
    // Similar to add, ensure userId context is within the appointment object
    return _repository.updateAppointment(appointment);
  }

  Future<void> deleteAppointment(String appointmentId, String userId) {
    // Pass userId for ownership or permission checks
    return _repository.deleteAppointment(appointmentId, userId);
  }
}
