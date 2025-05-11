// lib/data/repositories/nurse_assignment_repository_impl.dart (NEW FILE or existing repo impl file)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/data/repositories/nurse_assignment_repository.dart';
import 'package:mama_care/domain/entities/nurse_assignment.dart';

@Injectable(as: NurseAssignmentRepository) // Implement the interface
class NurseAssignmentRepositoryImpl implements NurseAssignmentRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  // Reference to the Firestore collection where assignments are stored
  late final CollectionReference _assignmentsCollection = _firestore.collection(
    'nurse_assignments',
  ); // Choose a collection name

  NurseAssignmentRepositoryImpl(this._firestore, this._logger) {
    _logger.i("NurseAssignmentRepositoryImpl initialized.");
  }

  /// Fetches assignments where the given ID matches the doctorId.
  @override
  Future<List<NurseAssignment>> getAssignmentsForDoctor(String doctorId) async {
    _logger.d("Repository: Fetching nurse assignments for doctor $doctorId");
    if (doctorId.isEmpty) {
      _logger.w("getAssignmentsForDoctor called with empty doctorId.");
      return [];
    }
    try {
      // Query documents where the 'doctorId' field matches the provided ID
      final querySnapshot =
          await _assignmentsCollection
              .where('doctorId', isEqualTo: doctorId)
              .orderBy(
                'assignedAt',
                descending: true,
              ) // Order by assignment date, newest first
              .get();

      // Map Firestore documents to NurseAssignment entities
      final assignments =
          querySnapshot.docs
              .map((doc) {
                try {
                  return NurseAssignment.fromFirestore(doc);
                } catch (e, s) {
                  _logger.e(
                    "Error parsing nurse assignment document ${doc.id}",
                    error: e,
                    stackTrace: s,
                  );
                  return null; // Skip documents that fail to parse
                }
              })
              .whereType<NurseAssignment>()
              .toList(); // Filter out nulls

      _logger.i(
        "Repository: Fetched ${assignments.length} nurse assignments for doctor $doctorId",
      );
      return assignments;
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error fetching nurse assignments for $doctorId",
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException("Error fetching nurse assignments.", cause: e);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error fetching nurse assignments for $doctorId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        "Could not process nurse assignment data.",
        cause: e,
      );
    }
  }

  @override
  Future<String> createAssignment(NurseAssignment assignment) async {
    _logger.d(
      "Repository: Creating nurse assignment: Patient ${assignment.patientId} -> Nurse ${assignment.nurseId} by Doctor ${assignment.doctorId}",
    );
    try {
      // Use the specific map conversion for creation which sets server timestamp
      final dataMap = assignment.toMapForCreation();
      final docRef = await _assignmentsCollection.add(dataMap);
      _logger.i("Repository: Created nurse assignment with ID ${docRef.id}");
      return docRef.id; // Return the new document ID
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error creating nurse assignment",
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException("Error saving assignment.", cause: e);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error creating nurse assignment",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        "Could not create assignment data.",
        cause: e,
      );
    }
  }
  // ------------------------------------------

  // --- ADDED deleteAssignment Implementation ---
  @override
  Future<void> deleteAssignment(String assignmentId) async {
    _logger.d("Repository: Deleting nurse assignment $assignmentId");
    if (assignmentId.isEmpty) {
      throw ArgumentError("Assignment ID cannot be empty for deletion.");
    }
    try {
      await _assignmentsCollection.doc(assignmentId).delete();
      _logger.i("Repository: Deleted nurse assignment $assignmentId");
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error deleting assignment $assignmentId",
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException("Error deleting assignment.", cause: e);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error deleting assignment $assignmentId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException("Could not delete assignment.", cause: e);
    }
  }

  // ------------------------------------------
}
