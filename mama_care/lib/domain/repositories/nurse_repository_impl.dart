// lib/data/repositories/nurse_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
// Ensure correct imports for your entities and abstract repository
import 'package:mama_care/data/repositories/nurse_repository.dart'; // Interface
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/entities/nurse_assignment.dart'; // Keep if used
import 'package:mama_care/domain/entities/patient_summary.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // Import UserModel
import 'package:uuid/uuid.dart';

@Injectable(as: NurseRepository)
class NurseRepositoryImpl implements NurseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger;
  final Uuid _uuid;

  // --- Base Collection References ---
  late final CollectionReference _usersCollection = _firestore.collection('users');
  // No separate _nursesCollection or _patientsCollection based on .where()
  late final CollectionReference _assignmentsCollection = _firestore.collection('nurse_assignments'); // If you have a dedicated assignments collection
  late final CollectionReference _appointmentsCollection = _firestore.collection('appointments');

  NurseRepositoryImpl(this._firestore, this._auth, this._logger, this._uuid);

  @override
  Future<List<Nurse>> getAvailableNurses(String? contextId) async {
    _logger.d("Repository: Fetching available nurses (context: $contextId)...");
    try {
      // Query users collection, filtering for nurses with capacity
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'nurse')
          .where('currentPatientLoad', isLessThan: 5) // Example capacity
          .orderBy('name')
          .get();

      // Map results using Nurse.fromFirestore
      final nurses = querySnapshot.docs.map((doc) {
          // Ensure your Nurse.fromFirestore correctly handles the Map<String, dynamic> data
          return Nurse.fromFirestore((doc.data() as Map<String, dynamic>..['id'] = doc.id) as DocumentSnapshot<Object?>);
      }).toList();

      _logger.i("Repository: Fetched ${nurses.length} available nurses.");
      return nurses;
    } catch (e, stackTrace) {
      _logger.e("Repository: Error fetching available nurses", error: e, stackTrace: stackTrace);
      throw ApiException("Could not load available nurses.", cause: e);
    }
  }

  @override
  Future<void> assignNurseToContext({
    required String contextId, // Assuming patientId
    required String nurseId,
    required String doctorId,
  }) async {
    _logger.i("Repository: Assigning nurse $nurseId to patient $contextId by doctor $doctorId");
    final patientId = contextId;
    final WriteBatch batch = _firestore.batch();
    try {
      // --- Use _usersCollection for both refs ---
      final patientRef = _usersCollection.doc(patientId);
      // Check if patient exists and is a patient? (Optional safety check)
      // final patientDoc = await patientRef.get();
      // if (!patientDoc.exists || (patientDoc.data() as Map?)?['role'] != 'patient') {
      //    throw NotFoundException("Patient with ID $patientId not found or invalid role.");
      // }

      // Check if nurse exists and is a nurse? (Optional safety check)
      final nurseRef = _usersCollection.doc(nurseId);
      // final nurseDoc = await nurseRef.get();
      // if (!nurseDoc.exists || (nurseDoc.data() as Map?)?['role'] != 'nurse') {
      //    throw NotFoundException("Nurse with ID $nurseId not found or invalid role.");
      // }

      // Update Patient
      batch.update(patientRef, {'assignedNurseId': nurseId});
      _logger.d("Batch: Updated patient $patientId with nurse $nurseId");

      // Update Nurse Load
      batch.update(nurseRef, {'currentPatientLoad': FieldValue.increment(1)});
      _logger.d("Batch: Incremented patient load for nurse $nurseId");

      // Optional: Create Assignment Record
      // final assignmentId = _uuid.v4();
      // final assignmentRef = _assignmentsCollection.doc(assignmentId);
      // final newAssignment = NurseAssignment(id: assignmentId, nurseId: nurseId, patientId: patientId, doctorId: doctorId, assignedAt: DateTime.now() );
      // batch.set(assignmentRef, newAssignment.toFirestoreMap());
      // _logger.d("Batch: Added NurseAssignment record $assignmentId");

      await batch.commit();
      _logger.i("Repository: Successfully assigned nurse $nurseId to patient $patientId.");
    } on FirebaseException catch (e, stackTrace) {
      _logger.e("Repository: Firestore error assigning nurse $nurseId", error: e, stackTrace: stackTrace);
      throw ApiException("Failed to complete nurse assignment.", statusCode: e.code.hashCode, cause: e);
    } catch (e, stackTrace) {
      _logger.e("Repository: Unexpected error assigning nurse $nurseId", error: e, stackTrace: stackTrace);
      throw DataProcessingException("Could not process assignment.", cause: e);
    }
  }

   // --- IMPLEMENTED: getNurseProfile (Returns UserModel) ---
   @override
   Future<UserModel?> getNurseProfile(String nurseId) async {
     _logger.d("Repository: Fetching nurse profile (UserModel) for ID: $nurseId");
     if (nurseId.isEmpty) {
       _logger.w("Cannot fetch profile for empty nurseId.");
       return null;
     }
     try {
       final doc = await _usersCollection.doc(nurseId).get();

       if (doc.exists && doc.data() != null) {
         final data = doc.data() as Map<String, dynamic>;
         if (data['role'] == 'nurse') {
           _logger.i("Repository: Found nurse profile for $nurseId.");
           // *** ENSURE UserModel.fromMap correctly handles data ***
           return UserModel.fromMap(data..['id'] = doc.id);
         } else {
           _logger.w("Repository: User $nurseId found but is not a nurse (role: ${data['role']}).");
           return null;
         }
       } else {
         _logger.w("Repository: Nurse profile with ID $nurseId not found in Firestore.");
         return null;
       }
     } on FirebaseException catch (e, stackTrace) {
         _logger.e("Repository: Firestore error fetching nurse profile $nurseId", error: e, stackTrace: stackTrace);
         throw ApiException("Error fetching nurse profile.", statusCode: e.code.hashCode, cause: e);
     } catch (e, stackTrace) {
        _logger.e("Repository: Unexpected error fetching nurse profile $nurseId", error: e, stackTrace: stackTrace);
        throw DataProcessingException("Could not process nurse profile data.", cause: e);
     }
   }

   // --- Implementation of getNurseById (Returns Nurse entity) ---
   @override
   Future<Nurse?> getNurseById(String nurseId) async {
      _logger.d("Repository: Fetching nurse entity by ID: $nurseId");
      if (nurseId.isEmpty) return null;
      try {
        // Fetch from _usersCollection
        final doc = await _usersCollection.doc(nurseId).get();
        if (doc.exists && doc.data() != null && (doc.data()! as Map)['role'] == 'nurse') {
            // *** ENSURE Nurse.fromFirestore correctly handles data ***
             return Nurse.fromFirestore((doc.data() as Map<String, dynamic>..['id'] = doc.id) as DocumentSnapshot<Object?>);
        } else {
            _logger.w("Repository: Nurse with ID $nurseId not found or role is not 'nurse'.");
            return null;
        }
      } catch (e, stackTrace) {
         _logger.e("Repository: Error fetching nurse $nurseId", error: e, stackTrace: stackTrace);
        throw ApiException("Could not load nurse details.", cause: e);
      }
   }


  // --- IMPLEMENTATION for getAssignedPatients ---
  @override
  Future<List<PatientSummary>> getAssignedPatients(String nurseId) async {
    _logger.d("Repository: Fetching assigned patients (summary) for nurse $nurseId");
    if (nurseId.isEmpty) return [];
    try {
      // Query users collection
      final patientSnapshot = await _usersCollection
          .where('role', isEqualTo: 'patient')
          .where('assignedNurseId', isEqualTo: nurseId)
          .orderBy('name')
          .get();

      // Map using PatientSummary.fromMap (ensure it exists and is correct)
      final patients = patientSnapshot.docs
          .map((doc) => PatientSummary.fromMap(doc.data() as Map<String, dynamic>..['id'] = doc.id))
          .toList();
      _logger.i("Repository: Found ${patients.length} patients assigned to nurse $nurseId.");
      return patients;
    } on FirebaseException catch (e, stackTrace) {
        _logger.e("Repository: Firestore error fetching assigned patients for nurse $nurseId", error: e, stackTrace: stackTrace);
        throw ApiException("Error loading assigned patients.", statusCode: e.code.hashCode, cause: e);
    } catch (e, stackTrace) {
      _logger.e("Repository: Unexpected error fetching assigned patients for nurse $nurseId", error: e, stackTrace: stackTrace);
      throw DataProcessingException("Could not process assigned patient data.", cause: e);
    }
  }

   // --- IMPLEMENTATION for getNurseUpcomingAppointments ---
   @override
   Future<List<Object>> getNurseUpcomingAppointments(String nurseId) async {
     _logger.d("Repository: Fetching upcoming appointments for nurse $nurseId");
     if (nurseId.isEmpty) return [];
     final now = Timestamp.now();
     try {
       // Query appointments collection
       final querySnapshot = await _appointmentsCollection
           .where('nurseId', isEqualTo: nurseId)
           .where('status', whereIn: ['confirmed', 'pending'])
           .where('scheduledTime', isGreaterThanOrEqualTo: now)
           .orderBy('scheduledTime', descending: false)
           .limit(20)
           .get();

       // Map using Appointment.fromMap (ensure it exists and is correct)
       final appointments = querySnapshot.docs
           .map((doc) => Appointment.fromFirestore((doc.data() as Map<String, dynamic>..['id'] = doc.id) as DocumentSnapshot<Object?>))
           .toList();
       _logger.i("Repository: Found ${appointments.length} upcoming appointments for nurse $nurseId.");
       return appointments;
     } on FirebaseException catch (e, stackTrace) {
        _logger.e("Repository: Firestore error fetching appointments for nurse $nurseId", error: e, stackTrace: stackTrace);
        throw ApiException("Error loading schedule.", statusCode: e.code.hashCode, cause: e);
     } catch (e, stackTrace) {
       _logger.e("Repository: Unexpected error fetching appointments for nurse $nurseId", error: e, stackTrace: stackTrace);
       throw DataProcessingException("Could not process schedule data.", cause: e);
     }
   }


  @override
  Future<void> unassignPatient({required String nurseId, required String patientId}) async {
    _logger.i("Repository: Unassigning patient $patientId from nurse $nurseId");
    if (nurseId.isEmpty || patientId.isEmpty) {
       throw ArgumentError("Nurse ID and Patient ID cannot be empty for unassignment.");
    }

    final WriteBatch batch = _firestore.batch();
    try {
      // Use _usersCollection for references
      final patientRef = _usersCollection.doc(patientId);
      final nurseRef = _usersCollection.doc(nurseId);

      // Perform safety checks before batching (optional but recommended)
      final nurseDoc = await nurseRef.get();
      if (!nurseDoc.exists || (nurseDoc.data() as Map?)?['role'] != 'nurse') {
          throw DataNotFoundException("Cannot unassign: Nurse $nurseId not found or invalid.");
      }
      final patientDoc = await patientRef.get();
       if (!patientDoc.exists || (patientDoc.data() as Map?)?['role'] != 'patient') {
          throw DataNotFoundException("Cannot unassign: Patient $patientId not found or invalid.");
       }
       // Ensure the patient is actually assigned to this nurse before proceeding
       if ((patientDoc.data() as Map?)?['assignedNurseId'] != nurseId) {
           _logger.w("Patient $patientId is not currently assigned to nurse $nurseId. Aborting unassignment batch.");
           return; // Or throw a specific exception
       }


      // 1. Update Patient
      batch.update(patientRef, {'assignedNurseId': FieldValue.delete()});
      _logger.d("Batch: Removing assignedNurseId from patient $patientId");

      // 2. Update Nurse Load
      batch.update(nurseRef, {'currentPatientLoad': FieldValue.increment(-1)});
      _logger.d("Batch: Decremented patient load for nurse $nurseId");

      // 3. Delete assignment record (if using _assignmentsCollection)
      // final assignmentQuery = await _assignmentsCollection
      //    .where('nurseId', isEqualTo: nurseId).where('patientId', isEqualTo: patientId).limit(1).get();
      // if (assignmentQuery.docs.isNotEmpty) {
      //    batch.delete(assignmentQuery.docs.first.reference);
      //    _logger.d("Batch: Deleting NurseAssignment record ${assignmentQuery.docs.first.id}");
      // }

      await batch.commit();
      _logger.i("Repository: Successfully unassigned patient $patientId from nurse $nurseId.");

    } on FirebaseException catch (e, stackTrace) {
       _logger.e("Repository: Firestore error unassigning patient", error: e, stackTrace: stackTrace);
       throw ApiException("Failed to unassign patient.", statusCode: e.code.hashCode, cause: e);
    } catch (e, stackTrace) {
      _logger.e("Repository: Unexpected error unassigning patient", error: e, stackTrace: stackTrace);
      throw DataProcessingException("Could not complete patient unassignment.", cause: e);
    }
  }
  // getCurrentNurseProfile implementation was removed as it seems redundant with getNurseProfile
  // If it's required by the abstract NurseRepository interface, re-add it, potentially just calling getNurseProfile:
   //@override
   //Future<UserModel?> getCurrentNurseProfile(String nurseId) async {
    //  return getNurseProfile(nurseId);
  // }

}
