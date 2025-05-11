// lib/data/repositories/doctor_repository.dart

//import 'package:mama_care/domain/entities/doctor.dart'; // Import the Doctor entity
import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/user_model.dart';

/// Abstract interface for accessing Doctor data.
///
@factoryMethod
abstract class DoctorRepository {
  /// Fetches a list of doctors available for selection (e.g., for appointments).
  ///
  /// May include filtering logic based on criteria like specialty, location,
  /// or doctor availability if needed in the future, passed via optional parameters.
  /// Get available doctors with optional specialty filter
  Future<List<UserModel>> getAvailableDoctors({String? specialtyFilter});
  
  /// Get a specific doctor by ID
  Future<UserModel?> getDoctorById(String doctorId);
  // Add other methods related to doctors if needed, e.g.:
  // Future<List<Doctor>> searchDoctors(String query);
}