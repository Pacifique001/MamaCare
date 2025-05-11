// lib/data/repositories/calendar_repository.dart
import 'package:mama_care/domain/entities/calendar_notes_model.dart';
import 'package:mama_care/domain/entities/appointment.dart';

abstract class CalendarRepository {
  // --- Note Methods ---
  // Keep existing ones if they are used elsewhere for non-user-specific contexts
  // or if they internally handle user context (though less explicit)
  Future<List<CalendarNote>> getNotesForDate(DateTime date);
  Future<List<CalendarNote>> getNotesForMonth(DateTime date);

  // NEW: User-specific and date-range methods for notes
  Future<List<CalendarNote>> getUserNotesForDateRange(String userId, DateTime startDate, DateTime endDate);
  Future<CalendarNote> addNote(CalendarNote note); // Assuming this already handles userId via note.userId
  Future<void> deleteNote(String noteId, String userId); // Add userId for ownership check

  // --- Appointment Methods ---
  Future<List<Appointment>> getAppointmentsForDate(DateTime date);
  Future<List<Appointment>> getAppointmentsForMonth(DateTime month);

  // NEW: User-specific and date-range methods for appointments
  Future<List<Appointment>> getUserAppointmentsForDateRange(String userId, DateTime startDate, DateTime endDate);
  Future<Appointment> addAppointment(Appointment appointment); // Assuming this handles userId via appointment.userId
  Future<void> updateAppointment(Appointment appointment);  // Assuming this handles userId
  Future<void> deleteAppointment(String appointmentId, String userId); // Add userId for ownership
}