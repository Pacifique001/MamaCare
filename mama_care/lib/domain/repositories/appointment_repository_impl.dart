// lib/data/repositories/appointment_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart'; // Your custom exceptions
import 'package:mama_care/data/local/database_helper.dart'; // If caching
import 'package:mama_care/data/repositories/appointment_repository.dart'; // The abstract class
import 'package:mama_care/domain/entities/appointment.dart'; // Your Appointment entity
import 'package:mama_care/domain/entities/appointment_status.dart'; // Your Status enum and helpers

@Injectable(as: AppointmentRepository) // Implement the interface
class AppointmentRepositoryImpl implements AppointmentRepository {
  final FirebaseFirestore _firestore;

  final Logger _logger;

  // Firestore Collection Reference
  late final CollectionReference _appointmentsCollectionRef;

  // Firestore Field Constants (Good Practice)
  static const String _fieldPatientId = 'patientId';
  static const String _fieldDoctorId = 'doctorId';
  static const String _fieldDateTime = 'dateTime'; // Firestore Timestamp
  static const String _fieldStatus = 'status'; // String representation of enum
  static const String _fieldUpdatedAt = 'updatedAt'; // Firestore Server Timestamp

  AppointmentRepositoryImpl(
    this._firestore,
    this._logger,
    
  ) {
    // Initialize collection reference once
    _appointmentsCollectionRef = _firestore.collection('appointments');
    _logger.i("AppointmentRepositoryImpl initialized.");
  }

  /// Creates a new appointment document in Firestore.
  @override
  Future<String> createAppointment(Appointment appointment) async {
    _logger.d(
      "Repository: Creating appointment for patient ${appointment.patientId} with doctor ${appointment.doctorId}",
    );
    try {
      // Get map for Firestore, ensuring server timestamps are set
      final dataMap = appointment.toMapForCreation();
      final docRef = await _appointmentsCollectionRef.add(dataMap);
      _logger.i("Repository: Created appointment with ID ${docRef.id}");

      return docRef.id;
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error creating appointment",
        error: e.code, // Log code for specific errors
        stackTrace: stackTrace,
      );
      throw ApiException("Failed to create appointment: ${e.message}", cause: e.code);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error creating appointment",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException("Could not save appointment data.", cause: e);
    }
  }

  /// Fetches a single appointment by its Firestore document ID.
  @override
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    _logger.d("Repository: Fetching appointment by ID: $appointmentId");
    if (appointmentId.isEmpty) {
      _logger.w("getAppointmentById called with empty ID.");
      return null;
    }
    try {
  
      final docSnapshot = await _appointmentsCollectionRef.doc(appointmentId).get();

      if (docSnapshot.exists) {
        _logger.i("Repository: Found appointment $appointmentId in Firestore.");
        final appointment = Appointment.fromFirestore(docSnapshot);
      
        return appointment;
      } else {
        _logger.w("Repository: Appointment with ID $appointmentId not found in Firestore.");
        return null;
      }
    } on FirebaseException catch (e, s) {
      _logger.e(
        "Repository: Firestore error fetching appointment $appointmentId",
        error: e.code,
        stackTrace: s,
      );
      throw ApiException("Error retrieving appointment details: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e(
        "Repository: Unexpected error fetching appointment $appointmentId",
        error: e,
        stackTrace: s,
      );
      ;
       return null; // Indicate not found on unexpected errors too? Or rethrow.
    }
  }

  /// Fetches appointments where the given ID matches the patientId.
  @override
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
  }) async {
    _logger.d(
      "Repository: Fetching appointments for patient $patientId${status != null ? ' with status: ${status.name}' : ''}",
    );
    if (patientId.isEmpty) {
      _logger.w("getPatientAppointments called with empty patientId.");
      return [];
    }
    try {
      

      Query query = _appointmentsCollectionRef.where(
        _fieldPatientId, // Use constant
        isEqualTo: patientId,
      );

      if (status != null) {
        query = query.where(
          _fieldStatus, // Use constant
          isEqualTo: status.name, // Store enum name string
        );
      }

   
      query = query.orderBy(_fieldDateTime, descending: true); // Use constant

      final querySnapshot = await query.get();
      _logger.i("Repository: Fetched ${querySnapshot.docs.length} raw docs for patient $patientId");

      final appointments = querySnapshot.docs
          .map((doc) => _safeParseAppointment(doc)) // Use safe parsing helper
          .whereType<Appointment>() // Filter out nulls from parsing errors
          .toList();

     

      _logger.i("Repository: Parsed ${appointments.length} appointments for patient $patientId");
      return appointments;
    } on FirebaseException catch (e, s) {
      _logger.e("Repository: Firestore error fetching patient appointments for $patientId", error: e.code, stackTrace: s);
      throw ApiException("Error fetching appointments: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e("Repository: Unexpected error fetching patient appointments for $patientId", error: e, stackTrace: s);
      throw DataProcessingException("Could not retrieve appointment data.", cause: e);
    }
  }

  /// Fetches appointments where the given ID matches the doctorId.
  @override
  Future<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    AppointmentStatus? status,
  }) async {
     _logger.d(
      "Repository: Fetching appointments for doctor $doctorId${status != null ? ' with status: ${status.name}' : ''}",
    );
    if (doctorId.isEmpty) {
      _logger.w("getDoctorAppointments called with empty doctorId.");
      return [];
    }
    try {
     
      Query query = _appointmentsCollectionRef.where(
        _fieldDoctorId, // Use constant
        isEqualTo: doctorId,
      );
      if (status != null) {
        query = query.where(
          _fieldStatus, // Use constant
          isEqualTo: status.name, // Store enum name string
        );
      }
      // Order (e.g., upcoming first)
      query = query.orderBy(_fieldDateTime, descending: false); // Use constant

      final querySnapshot = await query.get();
       _logger.i("Repository: Fetched ${querySnapshot.docs.length} raw docs for doctor $doctorId");

      final appointments = querySnapshot.docs
          .map((doc) => _safeParseAppointment(doc)) // Use safe parsing helper
          .whereType<Appointment>() // Filter out nulls
          .toList();

       
      _logger.i("Repository: Parsed ${appointments.length} appointments for doctor $doctorId");
      return appointments;
    } on FirebaseException catch (e, s) {
      _logger.e("Repository: Firestore error fetching doctor appointments for $doctorId", error: e.code, stackTrace: s);
      throw ApiException("Error fetching appointments: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e("Repository: Unexpected error fetching doctor appointments for $doctorId", error: e, stackTrace: s);
      throw DataProcessingException("Could not retrieve appointment data.", cause: e);
    }
  }

  /// Fetches all appointments related to a user (as patient OR doctor).
  @override
  Future<List<Appointment>> getUserAppointments(String userId) async {
    _logger.d("Repository: Fetching all appointments related to user ID: $userId");
    if (userId.isEmpty) {
      _logger.w("getUserAppointments called with empty userId.");
      return [];
    }

    try {
     
      // Fetch patient and doctor appointments separately
      final patientQuery = _appointmentsCollectionRef.where(
        _fieldPatientId, // Use constant
        isEqualTo: userId,
      );
      final doctorQuery = _appointmentsCollectionRef.where(
        _fieldDoctorId, // Use constant
        isEqualTo: userId,
      );

      // Execute queries concurrently
      final List<QuerySnapshot> snapshots = await Future.wait([
        patientQuery.get(),
        doctorQuery.get(),
      ]);

      final Set<String> uniqueIds = {}; // Prevent duplicates if user is both patient and doctor in same appt (unlikely)
      final List<Appointment> allAppointments = [];

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          if (uniqueIds.add(doc.id)) { // Only add if ID hasn't been seen
              final appointment = _safeParseAppointment(doc); // Use safe parsing
              if (appointment != null) {
                  allAppointments.add(appointment);
              }
          }
        }
      }

      // Sort the combined list (e.g., most recent first)
      allAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

     
      _logger.i("Repository: Fetched ${allAppointments.length} total appointments related to user $userId");
      return allAppointments;
    } on FirebaseException catch (e, s) {
      _logger.e("Repository: Firestore error fetching user appointments for $userId", error: e.code, stackTrace: s);
      throw ApiException("Error fetching your appointments: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e("Repository: Unexpected error fetching user appointments for $userId", error: e, stackTrace: s);
      throw DataProcessingException("Could not retrieve your appointment data.", cause: e);
    }
  }


  /// Updates only the status and updatedAt fields of an appointment.
  @override
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    _logger.d("Repository: Updating status for appointment $appointmentId to ${status.name}");
    if (appointmentId.isEmpty) {
      throw ArgumentError("Appointment ID cannot be empty for status update.");
    }
    final docRef = _appointmentsCollectionRef.doc(appointmentId);

    try {
      final updateData = {
        _fieldStatus: status.name, // Use enum name string
        _fieldUpdatedAt: FieldValue.serverTimestamp(),
      };
      await docRef.update(updateData);
      _logger.i("Repository: Status updated successfully for $appointmentId in Firestore.");

      

    } on FirebaseException catch (e, s) {
      _logger.e("Repository: Firestore error updating status for $appointmentId", error: e.code, stackTrace: s);
      // Check for NOT_FOUND error
      if (e.code == 'not-found') {
          throw DataNotFoundException("Appointment to update not found.");
      }
      throw ApiException("Error updating appointment status: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e("Repository: Unexpected error updating status for $appointmentId", error: e, stackTrace: s);
      throw DataProcessingException("Could not update appointment status.", cause: e);
    }
  }

  /// Updates the dateTime and updatedAt fields of an appointment.
  @override
  Future<void> updateAppointmentDateTime(String appointmentId, Timestamp newTimestamp) async {
    _logger.d("Repository: Updating dateTime for appointment '$appointmentId'");
     if (appointmentId.isEmpty) {
      throw ArgumentError("Appointment ID cannot be empty for dateTime update.");
    }
    final docRef = _appointmentsCollectionRef.doc(appointmentId);

    try {
      final updateData = {
        _fieldDateTime: newTimestamp,
        _fieldUpdatedAt: FieldValue.serverTimestamp(),
        // Optional: Consider if status should change automatically on reschedule
        _fieldStatus: AppointmentStatus.pending.name,
      };

      await docRef.update(updateData);
      _logger.i("Repository: Successfully updated appointment '$appointmentId' dateTime in Firestore.");

      
    } on FirebaseException catch (e, stackTrace) {
       _logger.e("Repository: Firestore error updating appointment '$appointmentId' dateTime", error: e.code, stackTrace: stackTrace);
        if (e.code == 'not-found') {
          throw DataNotFoundException("Appointment to update not found.");
       }
       throw ApiException("Failed to update appointment time: ${e.message}", cause: e.code);
    } catch (e, stackTrace) {
       _logger.e("Repository: Unexpected error updating appointment '$appointmentId' dateTime", error: e, stackTrace: stackTrace);
       throw DataProcessingException("An unexpected error occurred while rescheduling.", cause: e);
    }
  }


  /// Deletes an appointment document from Firestore.
  @override
  Future<void> deleteAppointment(String appointmentId) async {
    _logger.d("Repository: Deleting appointment $appointmentId");
    if (appointmentId.isEmpty) {
      throw ArgumentError("Appointment ID cannot be empty for deletion.");
    }
    final docRef = _appointmentsCollectionRef.doc(appointmentId);

    try {
      await docRef.delete();
      _logger.i("Repository: Deleted appointment $appointmentId from Firestore.");



    } on FirebaseException catch (e, s) {
      _logger.e("Repository: Firestore error deleting appointment $appointmentId", error: e.code, stackTrace: s);
       if (e.code == 'not-found') {
           _logger.w("Attempted to delete appointment $appointmentId which was already deleted or never existed.");
           return; // Or throw DataNotFoundException if deletion must target existing doc
       }
      throw ApiException("Error deleting appointment: ${e.message}", cause: e.code);
    } catch (e, s) {
      _logger.e("Repository: Unexpected error deleting appointment $appointmentId", error: e, stackTrace: s);
      throw DataProcessingException("Could not delete appointment.", cause: e);
    }
  }

  // --- Helper Methods ---

  /// Safely parses a Firestore document, logging errors instead of throwing.
  Appointment? _safeParseAppointment(DocumentSnapshot doc) {
    try {
      return Appointment.fromFirestore(doc);
    } catch (e, s) {
      _logger.e("Error parsing appointment document ${doc.id}", error: e, stackTrace: s);
      return null; // Return null on parsing error
    }
  }
  @override
  Future<void> updateAppointment(Appointment appointment) async {
    _logger.d("Repository: Updating full appointment ${appointment.id}");
    if (appointment.id == null || appointment.id!.isEmpty) {
      throw ArgumentError("Appointment ID is required for updates.");
    }
    try {
      // Prepare data, ensuring updatedAt is set
      final dataToUpdate =
          appointment.toMapForCreation(); // Re-use creation map temporarily
      dataToUpdate['updatedAt'] =
          FieldValue.serverTimestamp(); // Override with server timestamp

      // Remove createdAt if it exists in the map to prevent overwriting
      dataToUpdate.remove('createdAt');

      await _appointmentsCollectionRef.doc(appointment.id).update(dataToUpdate);
      _logger.i("Repository: Updated appointment ${appointment.id}");
    } on FirebaseException catch (e, s) {
      _logger.e(
        "Repository: Firestore error updating appointment ${appointment.id}",
        error: e,
        stackTrace: s,
      );
      throw ApiException("Error updating appointment.", cause: e);
    } catch (e, s) {
      _logger.e(
        "Repository: Unexpected error updating appointment ${appointment.id}",
        error: e,
        stackTrace: s,
      );
      throw DataProcessingException("Could not update appointment.", cause: e);
    }
  }
 

}

