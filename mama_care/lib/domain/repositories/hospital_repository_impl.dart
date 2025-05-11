// lib/data/repositories/hospital_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/hospital_repository.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/place_api/geometry.dart';
import 'package:mama_care/domain/entities/place_api/location.dart';
import 'package:mama_care/domain/entities/place_api/photo.dart';
import 'package:mama_care/domain/entities/place_api/place_result.dart';
import 'package:mama_care/domain/entities/place_api/places_nearby_response.dart';
import 'package:mama_care/core/error/exceptions.dart';
// import 'package:mama_care/utils/asset_helper.dart'; // API key is from dotenv
import 'package:sqflite/sqflite.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel to get userId

@Injectable(as: HospitalRepository)
class HospitalRepositoryImpl implements HospitalRepository {
  final Dio _dio;
  final DatabaseHelper _databaseHelper;
  final Logger _logger;
  final AuthViewModel _authViewModel; // Inject AuthViewModel

  static const String _baseUrl = "https://maps.googleapis.com/maps/api/place";
  static final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  // These constants should ideally come from DatabaseHelper to ensure consistency
  static const String _hospitalsTableName =
      DatabaseHelper.favoriteHospitalsTable; // Use constant from DB Helper
  static const String _colGooglePlaceId = DatabaseHelper.colGooglePlaceId;
  static const String _colUserId = DatabaseHelper.colUserId;
  static const String _colName = DatabaseHelper.colName;
  static const String _colVicinity = DatabaseHelper.colVicinity;
  static const String _colLatitude = DatabaseHelper.colLatitude;
  static const String _colLongitude = DatabaseHelper.colLongitude;
  static const String _colRating =
      DatabaseHelper.colRating; // Add if/when schema updated
  static const String _colImageUrl =
      DatabaseHelper.colImageUrl; // Add if/when schema updated
  static const String _colAddedAt =
      DatabaseHelper.colAddedAt; // Add if/when schema updated

  HospitalRepositoryImpl(
    this._dio,
    this._databaseHelper,
    this._logger,
    this._authViewModel,
  ) {
    // Add AuthViewModel to constructor
    _logger.i("HospitalRepositoryImpl initialized.");
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.e("CRITICAL: GOOGLE_MAPS_API_KEY is not set in .env file!");
    }
  }

  // REMOVED _ensureFavoritesTable() as DatabaseHelper should handle this.

  @override
  Future<List<PlaceResult>> getHospitalList(
    LatLng latLng, {
    required double radius,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.e("Cannot fetch hospitals: API Key is missing.");
      throw ApiException("API Key not configured.", statusCode: 500);
    }
    final url = '$_baseUrl/nearbysearch/json';
    final params = {
      'location': '${latLng.latitude},${latLng.longitude}',
      'radius': radius.round(),
      'type': 'hospital',
      'key': _apiKey,
      'fields':
          'place_id,name,geometry,vicinity,rating,opening_hours,photos,formatted_phone_number,user_ratings_total', // Request more fields
    };

    _logger.d(
      "Repository: Fetching hospitals from API for ${latLng.latitude},${latLng.longitude} with radius $radius",
    );

    try {
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final placesResponse = PlacesNearbyResponse.fromJson(responseData);

        if (placesResponse.status == 'OK') {
          _logger.i(
            "Repository: Found ${placesResponse.results.length} hospitals via API.",
          );
          // Fetch favorites for the current user to mark them
          final String? currentUserId = _authViewModel.localUser?.id;
          Set<String> favoritePlaceIds = {};
          if (currentUserId != null) {
            final favorites =
                await getFavoriteHospitals(); // This will now use the current user's ID
            favoritePlaceIds = favorites.map((f) => f.placeId!).toSet();
          } else {
            _logger.w(
              "No logged-in user, cannot determine favorite hospitals.",
            );
          }

          return placesResponse.results.map((result) {
            return result.copyWith(
              isFavorite: favoritePlaceIds.contains(result.placeId),
            );
          }).toList();
        } else if (placesResponse.status == 'ZERO_RESULTS') {
          _logger.w("Repository: Google Places API returned ZERO_RESULTS.");
          return [];
        } else {
          _logger.e(
            "Repository: Google Places API Error: ${placesResponse.status} - ${placesResponse.errorMessage}",
          );
          throw ApiException(
            placesResponse.errorMessage ??
                'Google Places API error: ${placesResponse.status}',
            statusCode: response.statusCode,
          );
        }
      } else {
        _logger.e(
          "Repository: Invalid response from Google Places API. Status: ${response.statusCode}",
        );
        throw ApiException(
          'Invalid response from Google Places API',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e("Repository: Dio error fetching hospitals", error: e);
      _handleDioException(e); // Keep this if it's a well-defined helper
      throw NetworkException('Network error fetching hospitals.', cause: e);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error fetching hospitals",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        'Could not process hospital data.',
        cause: e,
      );
    }
  }

  // --- Favorite Management ---

  @override
  Future<PlaceResult> toggleFavorite(PlaceResult hospital) async {
    final String? currentUserId = _authViewModel.localUser?.id;
    if (currentUserId == null) {
      _logger.e("Cannot toggle favorite: User not logged in.");
      throw AuthException("User not logged in. Cannot manage favorites.");
    }
    if (hospital.placeId == null) {
      _logger.e("Cannot toggle favorite: Hospital placeId is null.");
      throw ArgumentError("Hospital placeId cannot be null.");
    }

    _logger.d(
      "Repository: Toggling favorite for Hospital ID: ${hospital.placeId} for User ID: $currentUserId",
    );
    final db = await _databaseHelper.database;
    final bool currentlyFavorite = await _isFavorite(
      hospital.placeId!,
      currentUserId,
    );
    final bool newFavoriteStatus = !currentlyFavorite;

    try {
      if (newFavoriteStatus) {
        await db.insert(
          _hospitalsTableName,
          {
            _colUserId: currentUserId,
            _colGooglePlaceId: hospital.placeId, // Corrected column name
            _colName: hospital.name,
            _colVicinity:
                hospital
                    .vicinity, // Use 'vicinity' to match DB schema's colVicinity
            _colLatitude: hospital.location?.latitude,
            _colLongitude: hospital.location?.longitude,
            // The following columns are NOT in your current DB schema for 'favorite_hospitals'
            // Add them to DatabaseHelper and do a DB migration (uninstall/reinstall app) if you need them.
            _colRating: hospital.rating,
            _colImageUrl:
                hospital.photos?.isNotEmpty == true
                    ? _buildPhotoUrl(
                      hospital.photos!.first.photoReference!,
                    ) // Ensure photoReference not null
                    : null,
            _colAddedAt: DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm:
              ConflictAlgorithm
                  .replace, // This relies on UNIQUE constraint (userId, googlePlaceId)
        );
        _logger.i(
          "Repository: Added ${hospital.name} to favorites for user $currentUserId.",
        );
      } else {
        final count = await db.delete(
          _hospitalsTableName,
          where:
              '$_colGooglePlaceId = ? AND $_colUserId = ?', // Corrected column names
          whereArgs: [hospital.placeId, currentUserId],
        );
        _logger.i(
          "Repository: Removed ${hospital.name} from favorites for user $currentUserId (rows deleted: $count).",
        );
      }
      return hospital.copyWith(isFavorite: newFavoriteStatus);
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to toggle favorite status in DB for ${hospital.placeId} (User: $currentUserId)",
        error: e,
        stackTrace: stackTrace,
      );
      throw ("Could not update favorite status.", cause: e);
    }
  }

  @override
  Future<List<PlaceResult>> getFavoriteHospitals() async {
    final String? currentUserId = _authViewModel.localUser?.id;
    if (currentUserId == null) {
      _logger.w("Cannot get favorites: User not logged in.");
      return []; // Return empty list if no user is logged in
    }

    _logger.d(
      "Repository: Getting favorite hospitals from local DB for User ID: $currentUserId.",
    );
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _hospitalsTableName,
        where: '$_colUserId = ?', // Filter by current user
        whereArgs: [currentUserId],
        orderBy: '$_colName ASC',
      );

      final favorites =
          maps.map((map) {
            String? photoRefIfStored =
                map[_colImageUrl] as String?; // If you store photoReference

            return PlaceResult(
              placeId:
                  map[_colGooglePlaceId] as String, // Corrected column name
              name: map[_colName] as String?,
              vicinity:
                  map[_colVicinity]
                      as String?, // Map back using DB schema's colVicinity
              geometry:
                  (map[_colLatitude] != null && map[_colLongitude] != null)
                      ? Geometry(
                        location: Location(
                          latitude: map[_colLatitude] as double,
                          longitude: map[_colLongitude] as double,
                        ),
                      )
                      : null,
              rating: map[_colRating] as double?, // Add if/when schema updated
              photos:
                  photoRefIfStored != null
                      ? [Photo(photoReference: photoRefIfStored)]
                      : null, // Add if/when schema updated for imageUrl
              isFavorite: true, // It's from the favorites table
            );
          }).toList();

      _logger.i(
        "Repository: Fetched ${favorites.length} favorite hospitals from DB for user $currentUserId.",
      );
      return favorites;
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to get favorite hospitals from DB for user $currentUserId",
        error: e,
        stackTrace: stackTrace,
      );
      throw ("Could not fetch favorite hospitals.", cause: e);
    }
  }

  Future<bool> _isFavorite(String googlePlaceId, String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      _hospitalsTableName,
      where:
          '$_colGooglePlaceId = ? AND $_colUserId = ?', // Corrected column names
      whereArgs: [googlePlaceId, userId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // This helper is fine, but ensure _apiKey is loaded.
  String? _buildPhotoUrl(String? photoReference, {int maxWidth = 400}) {
    if (_apiKey == null ||
        _apiKey!.isEmpty ||
        photoReference == null ||
        photoReference.isEmpty) {
      _logger.w(
        "Cannot build photo URL: API Key or photoReference is missing.",
      );
      return null;
    }
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_apiKey';
  }

  void _handleDioException(DioException e) {
    String errorType = "DioException";
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorType = "Timeout";
    } else if (e.type == DioExceptionType.cancel) {
      errorType = "Request Cancelled";
    } else if (e.type == DioExceptionType.connectionError) {
      errorType = "Connection Error";
    } else if (e.type == DioExceptionType.badResponse) {
      errorType = "Bad Response (${e.response?.statusCode})";
    }
    _logger.w(
      "$errorType: Request to ${e.requestOptions.path} failed. ${e.message}",
    );
    if (e.response != null) {
      _logger.w("Response Data: ${e.response?.data}");
    }
  }
}
