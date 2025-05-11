// lib/data/repositories/nurse_assignment_repository.dart (NEW FILE or existing repo file)

import 'package:mama_care/domain/entities/nurse_assignment.dart';

abstract class NurseAssignmentRepository {
  /// Fetches all assignments made by or involving a specific doctor.
  Future<List<NurseAssignment>> getAssignmentsForDoctor(String doctorId);

   /// Creates a new nurse assignment record.
  /// Returns the ID of the newly created assignment document.
  Future<String> createAssignment(NurseAssignment assignment); // <<< ADDED

  /// Deletes a specific nurse assignment record by its ID.
  Future<void> deleteAssignment(String assignmentId); // <<< ADDED

}