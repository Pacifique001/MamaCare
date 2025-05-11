// lib/domain/usecases/nurse_assignment_management_usecase.dart

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/nurse_repository.dart'; // Import Nurse Repository
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/entities/patient_summary.dart';

@injectable
class NurseAssignmentManagementUseCase {
  final NurseRepository _nurseRepository;
  // Inject PatientRepository if needed to get summaries by ID list
  // final PatientRepository _patientRepository;
  final Logger _logger;

  // Update constructor if PatientRepository is injected
  NurseAssignmentManagementUseCase(this._nurseRepository, this._logger);

  /// Gets the profile of the nurse being managed.
  Future<Nurse?> getNurseProfile(String nurseId) async {
     _logger.d("UseCase: Getting nurse profile for management: $nurseId");
     if (nurseId.isEmpty) return null;
      try {
        // Use the repository method directly
        return await _nurseRepository.getNurseById(nurseId);
      } catch (e) {
        _logger.e("UseCase: Failed to get nurse profile for mgmt $nurseId.", error: e);
        rethrow; // Let ViewModel handle repository exception
      }
  }

  /// Gets a list of patient summaries assigned to a specific nurse.
  Future<List<PatientSummary>> getAssignedPatients(String nurseId) async {
    _logger.d("UseCase: Getting assigned patients for nurse $nurseId");
     if (nurseId.isEmpty) return [];
      try {
        // This assumes NurseRepository can fetch the summaries directly or indirectly
        return await _nurseRepository.getAssignedPatients(nurseId);
      } catch (e) {
         _logger.e("UseCase: Failed to get assigned patients for $nurseId.", error: e);
         rethrow;
      }
  }

  /// Unassigns a specific patient from a specific nurse.
  Future<void> unassignPatient({required String nurseId, required String patientId}) async {
    _logger.i("UseCase: Unassigning patient $patientId from nurse $nurseId");
    if (nurseId.isEmpty || patientId.isEmpty) {
       throw ArgumentError("Nurse ID and Patient ID cannot be empty for unassignment.");
    }
    try {
        await _nurseRepository.unassignPatient(nurseId: nurseId, patientId: patientId);
        _logger.i("UseCase: Unassignment request sent to repository for nurse $nurseId / patient $patientId.");
    } catch (e) {
       _logger.e("UseCase: Error unassigning patient $patientId from nurse $nurseId", error: e);
       rethrow;
    }
  }
}