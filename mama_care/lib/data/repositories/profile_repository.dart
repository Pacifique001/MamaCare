// lib/data/repositories/profile_repository.dart

import 'package:injectable/injectable.dart';
import '../../domain/entities/pregnancy_details.dart';
// Removed UserModel import

@factoryMethod // Keep if needed for injectable setup
abstract class ProfileRepository {
  // Keep only pregnancy related methods (or rename repo if it ONLY handles pregnancy)
  Future<PregnancyDetails?> getPregnancyDetails(String userId); // Pass userId
  Future<void> savePregnancyDetails(PregnancyDetails details);
  Future<void> deletePregnancyDetails(String userId); // Method to delete
}

