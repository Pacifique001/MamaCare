// lib/domain/usecases/profile_use_case.dart

import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/profile_repository.dart';
// Removed UserModel import
import 'package:mama_care/domain/entities/pregnancy_details.dart';

@injectable
class ProfileUseCase {
  final ProfileRepository _repository;

  ProfileUseCase(this._repository);

  // Keep only pregnancy related methods
  Future<PregnancyDetails?> getPregnancyDetails(String userId) async {
    // Add error handling if desired
    try {
      return await _repository.getPregnancyDetails(userId);
    } catch (e) {
      print("Error fetching pregnancy details in UseCase: $e"); // Use logger
      return null;
    }
  }

  Future<void> savePregnancyDetails(PregnancyDetails details) async {
    // Add validation or business logic if needed
    await _repository.savePregnancyDetails(details);
  }

   Future<void> deletePregnancyDetails(String userId) async {
    await _repository.deletePregnancyDetails(userId);
  }
}