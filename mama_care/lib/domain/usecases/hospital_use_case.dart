// lib/domain/usecases/hospital_use_case.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/hospital_repository.dart';
// Removed direct Hospital entity import if PlaceResult is used consistently
// import 'package:mama_care/domain/entities/place_api/hospital.dart';
import 'package:mama_care/domain/entities/place_api/place_result.dart'; // Use PlaceResult

@injectable
class HospitalUseCase {
  final HospitalRepository _hospitalRepository;

  HospitalUseCase(this._hospitalRepository);

  /// Gets nearby hospitals using the repository, accepting an optional radius.
  Future<List<PlaceResult>> getHospitalList(
    LatLng location, {
    double radius = 2000.0, // Default radius if not provided (e.g., 2km)
  }) async {
    // Add any business logic here if needed before calling the repository
    // e.g., validating the radius, applying default if invalid.
    if (radius <= 0) {
       radius = 2000.0; // Ensure a positive radius
    }

    // Pass the location and radius to the repository method
    return await _hospitalRepository.getHospitalList(
      location,
      radius: radius, // Pass the named parameter
    );
  }

  /// Toggles the favorite status of a hospital.
  Future<PlaceResult> toggleFavorite(PlaceResult hospital) async {
     // Business logic for toggling? (Usually just pass through)
     // Here you could add checks, like ensuring the user is logged in, etc.
     return await _hospitalRepository.toggleFavorite(hospital);
  }

   /// Gets the list of favorited hospitals.
  Future<List<PlaceResult>> getFavoriteHospitals() async {
     // Business logic? (e.g., check user permissions)
     return await _hospitalRepository.getFavoriteHospitals();
  }
}