// lib/data/repositories/calendar_repository_impl.dart (Example Snippets)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mama_care/data/local/database_helper.dart'; // For local caching if any
import 'package:mama_care/domain/entities/calendar_notes_model.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/data/repositories/calendar_repository.dart';
import 'package:logger/logger.dart'; // Assuming logger
import 'package:injectable/injectable.dart';

@Injectable(as: CalendarRepository)
class CalendarRepositoryImpl implements CalendarRepository {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _localDb; // If you use local caching
  final Logger _logger;

  // Constants for Firestore collection/field names
  static const String _notesCollection =
      'calendar_notes'; // Or your actual name
  static const String _appointmentsCollection =
      'appointments'; // Or your actual name
  static const String _fieldUserId = 'userId';
  static const String _fieldDate = 'date'; // For notes
  static const String _fieldAppointmentDateTime =
      'appointmentDateTime'; // For appointments
  static const String _fieldPatientId = 'patientId';
  static const String _fieldDoctorId = 'doctorId';

  CalendarRepositoryImpl(this._firestore, this._localDb, this._logger);

  // --- Note Methods ---

  @override
  Future<List<CalendarNote>> getUserNotesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _logger.i(
      "Repo: Fetching notes for user $userId from $startDate to $endDate",
    );
    try {
      final querySnapshot =
          await _firestore
              .collection(_notesCollection)
              .where(_fieldUserId, isEqualTo: userId)
              .where(
                _fieldDate,
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                _fieldDate,
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              ) // Ensure endDate includes the whole day if needed
              .orderBy(_fieldDate)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CalendarNote.fromJson({
          ...data,
          'id': doc.id,
        }); // Assuming fromJson handles Timestamp for 'date'
      }).toList();
    } catch (e, s) {
      _logger.e(
        "Repo: Error fetching notes for date range",
        error: e,
        stackTrace: s,
      );
      throw Exception("Failed to get notes: $e");
    }
  }

  @override
  Future<CalendarNote> addNote(CalendarNote note) async {
    _logger.i("Repo: Adding note for user ${note.userId} on date ${note.date}");
    try {
      DocumentReference docRef;
      final Map<String, dynamic> noteData =
          note.toFirestore(); // Create a toFirestoreMap in CalendarNote

      if (note.id != null && note.id!.isNotEmpty) {
        // Update existing note if ID is provided (though createNote usually implies new)
        docRef = _firestore.collection(_notesCollection).doc(note.id);
        await docRef.set(
          noteData,
          SetOptions(merge: true),
        ); // Use set with merge for updates
      } else {
        // Add new note, Firestore generates ID
        docRef = await _firestore.collection(_notesCollection).add(noteData);
      }
      // Return the note with the potentially new/confirmed ID
      return note.copyWith(id: docRef.id);
    } catch (e, s) {
      _logger.e("Repo: Error adding note", error: e, stackTrace: s);
      throw Exception("Failed to save note: $e");
    }
  }

  @override
  Future<void> deleteNote(String noteId, String userId) async {
    _logger.i("Repo: Deleting note $noteId for user $userId");
    try {
      // Optional: Add an ownership check before deleting if necessary
      // final doc = await _firestore.collection(_notesCollection).doc(noteId).get();
      // if (doc.exists && doc.data()?['userId'] == userId) {
      //   await _firestore.collection(_notesCollection).doc(noteId).delete();
      // } else {
      //   throw Exception("Note not found or permission denied.");
      // }
      await _firestore.collection(_notesCollection).doc(noteId).delete();
    } catch (e, s) {
      _logger.e("Repo: Error deleting note $noteId", error: e, stackTrace: s);
      throw Exception("Failed to delete note: $e");
    }
  }

  // --- Appointment Methods ---

  @override
  Future<List<Appointment>> getUserAppointmentsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _logger.i(
      "Repo: Fetching appointments for user $userId from $startDate to $endDate",
    );
    try {
      // Appointments might involve the user as either patient or doctor
      final patientAppointmentsQuery = _firestore
          .collection(_appointmentsCollection)
          .where(_fieldPatientId, isEqualTo: userId)
          .where(
            _fieldAppointmentDateTime,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            _fieldAppointmentDateTime,
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );

      final doctorAppointmentsQuery = _firestore
          .collection(_appointmentsCollection)
          .where(_fieldDoctorId, isEqualTo: userId)
          .where(
            _fieldAppointmentDateTime,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            _fieldAppointmentDateTime,
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );

      final List<QuerySnapshot> snapshots = await Future.wait([
        patientAppointmentsQuery.get(),
        doctorAppointmentsQuery.get(),
      ]);

      final Set<String> uniqueAppointmentIds = {};
      final List<Appointment> allUserAppointments = [];

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          if (uniqueAppointmentIds.add(doc.id)) {
            // Avoid duplicates
            final data = doc.data() as Map<String, dynamic>;
            allUserAppointments.add(
              Appointment.fromMap({...data, 'id': doc.id}),
            );
          }
        }
      }
      allUserAppointments.sort(
        (a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime),
      );
      return allUserAppointments;
    } catch (e, s) {
      _logger.e(
        "Repo: Error fetching appointments for date range",
        error: e,
        stackTrace: s,
      );
      throw Exception("Failed to get appointments: $e");
    }
  }

  // Implement addAppointment, updateAppointment, deleteAppointment (with userId for ownership) similarly...
  // Remember to convert DateTime to Timestamp when writing to Firestore if fields are Timestamps.

  // --- Old Methods (Review if still needed or adapt/remove) ---
  @override
  Future<List<CalendarNote>> getNotesForDate(DateTime date) {
    // This would need a default user or be removed if all note fetching is user-specific
    _logger.w(
      "Repo: getNotesForDate (non-user-specific) called. Consider refactoring.",
    );
    // Example: return getUserNotesForDateRange("SOME_DEFAULT_OR_ANONYMOUS_USER_ID", startOfDay(date), endOfDay(date));
    return Future.value([]); // Placeholder
  }

  @override
  Future<List<CalendarNote>> getNotesForMonth(DateTime date) {
    _logger.w(
      "Repo: getNotesForMonth (non-user-specific) called. Consider refactoring.",
    );
    return Future.value([]); // Placeholder
  }

  @override
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) {
    _logger.w(
      "Repo: getAppointmentsForDate (non-user-specific) called. Consider refactoring.",
    );
    return Future.value([]); // Placeholder
  }

  @override
  Future<List<Appointment>> getAppointmentsForMonth(DateTime month) {
    _logger.w(
      "Repo: getAppointmentsForMonth (non-user-specific) called. Consider refactoring.",
    );
    return Future.value([]); // Placeholder
  }

  @override
  Future<Appointment> addAppointment(Appointment appointment) async {
    // Implement actual saving to Firestore, returning the appointment with an ID
    _logger.i(
      "Repo: Adding appointment for patient ${appointment.patientId}, doctor ${appointment.doctorId}",
    );
    try {
      final docRef = await _firestore
          .collection(_appointmentsCollection)
          .add(appointment.toFirestoreMap());
      return appointment.copyWith(id: docRef.id);
    } catch (e, s) {
      _logger.e("Repo: Error adding appointment", error: e, stackTrace: s);
      throw Exception("Failed to schedule appointment: $e");
    }
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    if (appointment.id == null)
      throw ArgumentError("Appointment ID cannot be null for update.");
    _logger.i("Repo: Updating appointment ${appointment.id}");
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointment.id)
          .update(appointment.toFirestoreMap());
    } catch (e, s) {
      _logger.e("Repo: Error updating appointment", error: e, stackTrace: s);
      throw Exception("Failed to update appointment: $e");
    }
  }

  @override
  Future<void> deleteAppointment(String appointmentId, String userId) async {
    _logger.i(
      "Repo: Deleting appointment $appointmentId (context user: $userId)",
    );
    try {
      // Optional: Add ownership check
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .delete();
    } catch (e, s) {
      _logger.e("Repo: Error deleting appointment", error: e, stackTrace: s);
      throw Exception("Failed to delete appointment: $e");
    }
  }
}
