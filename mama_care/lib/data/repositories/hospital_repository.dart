// lib/data/repositories/hospital_repository.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
// Removed @factoryMethod if not strictly needed for this pattern with Injectable
// import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/place_api/place_result.dart';

// @factoryMethod // Remove if not using this specific Injectable feature here
abstract class HospitalRepository {

  /// Fetches a list of nearby hospitals based on latitude/longitude and radius.
  Future<List<PlaceResult>> getHospitalList(
    LatLng latLng, {
    required double radius, // Make radius required or provide default here too
  });

  /// Toggles the favorite status of a given hospital.
  Future<PlaceResult> toggleFavorite(PlaceResult hospital);

  /// Fetches the list of hospitals marked as favorite.
  Future<List<PlaceResult>> getFavoriteHospitals();

}