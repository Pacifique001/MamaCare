// lib/domain/usecases/assign_nurse_usecase.dart
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart'; // Import Logger
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/data/repositories/nurse_repository.dart'; // Import Repository interface

@injectable
class AssignNurseUseCase {
  final NurseRepository _repository;
  final FirebaseAuth _auth; // Inject FirebaseAuth
  final Logger _logger; // Inject Logger

  AssignNurseUseCase(this._repository, this._auth, this._logger);

  /// Gets nurses available for assignment.
  Future<List<Nurse>> getAvailableNurses(String? contextId) async {
    _logger.d("UseCase: Getting available nurses (context: $contextId)");
    // Add any business logic here (e.g., check doctor's permissions?)
    return _repository.getAvailableNurses(contextId);
  }

  /// Assigns a nurse to a patient (contextId is assumed patientId).
  Future<void> assignNurse({required String patientId, required String nurseId}) async {
     _logger.i("UseCase: Assigning nurse $nurseId to patient $patientId");
     final doctorId = _auth.currentUser?.uid;
     if (doctorId == null) {
        _logger.e("UseCase: Cannot assign nurse, doctor not authenticated.");
        throw AuthException("Doctor authentication required to assign nurse.");
     }
     // Add business logic checks if needed (e.g., is nurse really available?)
      try {
        await _repository.assignNurseToContext(
            contextId: patientId, // Pass patientId as context
            nurseId: nurseId,
            doctorId: doctorId
        );
         _logger.i("UseCase: Assignment request sent to repository for nurse $nurseId / patient $patientId.");
      } catch(e) {
         _logger.e("UseCase: Error assigning nurse", error: e);
         // Re-throw or handle specific UseCase level errors
         rethrow;
      }
  }
}