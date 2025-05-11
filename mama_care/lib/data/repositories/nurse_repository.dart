// lib/data/repositories/nurse_repository.dart
import 'package:mama_care/domain/entities/nurse.dart';
import 'package:mama_care/domain/entities/patient_summary.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/user_model.dart';

@factoryMethod
abstract class NurseRepository {
  /// Fetches a list of nurses available for assignment.
  /// May optionally filter based on context (e.g., doctorId, location).
  Future<List<Nurse>> getAvailableNurses(String? contextId);
  

  /// Fetches a specific doctor's profile by their ID.
  Future<Nurse?> getNurseById(String nurseId);

  /// Fetches summaries of patients assigned to a specific nurse.
  Future<List<PatientSummary>> getAssignedPatients(String nurseId); // <-- ADDED

  /// Unassigns a patient from a nurse. Handles relevant data updates.
  Future<void> unassignPatient({required String nurseId, required String patientId});

  //Future<Nurse?> getCurrentNurseProfile(String nurseId);
  /// Assigns a specific nurse to a context (e.g., patient or appointment).
  /// The implementation handles updating relevant documents (e.g., creating
  /// a NurseAssignment record, updating patient/appointment docs, updating nurse doc).
  Future<void> assignNurseToContext({
      required String contextId, // Could be patientId or appointmentId
      required String nurseId,
      required String doctorId, // ID of the doctor performing assignment
   });

  Future<UserModel?> getNurseProfile(String nurseId);

  getNurseUpcomingAppointments(String nurseId) {}

   // Add other nurse-related methods if needed (e.g., getNurseProfile)
   
}