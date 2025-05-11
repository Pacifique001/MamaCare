import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart'; // Import Logger
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/data/repositories/video_repository.dart'; // Interface path
import 'package:mama_care/domain/entities/video_model.dart';
import 'package:mama_care/core/error/exceptions.dart'; // Custom exceptions
import 'package:sqflite/sqflite.dart' as sqflite; // <--- IMPORT WITH PREFIX
// Removed unused use case import: import 'package:mama_care/domain/usecases/video_usecase.dart';

@Injectable(as: VideoRepository)
class VideoRepositoryImpl implements VideoRepository {
  final Dio _dio; // Injected
  final DatabaseHelper _databaseHelper; // Injected
  final Logger _logger; // Injected
  final FirebaseAuth _auth; // Inject FirebaseAuth

  final String _apiBaseUrl = "/api/videos"; // Example - Replace if needed

  VideoRepositoryImpl(
    this._dio,
    this._databaseHelper,
    this._logger,
    this._auth,
  );

  String? get _userId => _auth.currentUser?.uid;

  // Helper to handle Dio errors
  Exception _handleDioError(DioException e, String operation) {
    _logger.e(
      "DioError during $operation",
      error: e.message,
      stackTrace: e.stackTrace,
    );
    if (e.response != null) {
      if (e.response?.statusCode == 404)
        return DataNotFoundException("$operation target not found.");
      // Include more specific error details if available from backend response
      String apiMsg =
          e.response?.data is Map
              ? (e.response?.data['message'] ??
                  e.message ??
                  'Unknown API Error')
              : (e.message ?? 'Unknown API Error');
      return ApiException(
        "API Error ($operation): ${e.response?.statusCode} - $apiMsg",
        statusCode: e.response?.statusCode,
        cause: e,
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(
        "Network error during $operation. Please check connection.",
        cause: e,
      );
    }
    // Use the original error message if available for other Dio errors
    return ApiException(
      "An unexpected network error occurred during $operation: ${e.message}",
      cause: e,
    );
  }

  // Helper to save multiple videos to local DB
  Future<void> _cacheVideosLocally(List<VideoModel> videos) async {
    if (videos.isEmpty) return;
    _logger.d("Caching ${videos.length} videos locally...");
    try {
      await _databaseHelper.transaction((txn) async {
        final batch = txn.batch();
        for (var video in videos) {
          batch.insert(
            'app_videos',
            video.toJson(), // Assuming VideoModel has toJson()
            // --- FIX: Use prefix for ConflictAlgorithm ---
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        _logger.d("Finished caching ${videos.length} videos.");
      });
      // --- FIX: Catch specific sqflite exception ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Error caching videos locally (DB Error)",
        error: e,
        stackTrace: stackTrace,
      );
      // Throwing here might stop the flow after a successful API call. Decide if that's desired.
      // throw DatabaseException("Failed to cache video data.", cause: e, stackTrace: stackTrace);
      // Or just log the error and continue
    } catch (e, stackTrace) {
      _logger.e(
        "Error caching videos locally (Other Error)",
        error: e,
        stackTrace: stackTrace,
      );
      // throw DataProcessingException("Could not cache video data.", cause: e, stackTrace: stackTrace);
    }
  }

  // Helper to save a single video
  Future<void> _cacheSingleVideoLocally(VideoModel video) async {
    _logger.d("Caching single video locally: ${video.id}");
    try {
      await _databaseHelper.insert(
        'app_videos',
        video.toJson(),
        // --- FIX: Use prefix for ConflictAlgorithm ---
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      _logger.d("Single video ${video.id} cached.");
      // --- FIX: Catch specific sqflite exception ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Error caching single video ${video.id} (DB Error)",
        error: e,
        stackTrace: stackTrace,
      );
      // throw DatabaseException("Failed to cache video.", cause: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      _logger.e(
        "Error caching single video ${video.id} (Other Error)",
        error: e,
        stackTrace: stackTrace,
      );
      // throw DataProcessingException("Could not cache video.", cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<VideoModel>> getVideos() async {
    _logger.d("Repository: Getting videos...");
    try {
      _logger.d("Checking local DB for videos...");
      // --- FIX: Catch specific sqflite exception for DB query ---
      final localMaps = await _databaseHelper.query(
        'app_videos',
        orderBy: 'publishedAt DESC',
      );
      if (localMaps.isNotEmpty) {
        _logger.i("Returning ${localMaps.length} videos from local DB.");
        return localMaps.map((map) => VideoModel.fromJson(map)).toList();
      }

      _logger.i("No videos in local DB, fetching from API: $_apiBaseUrl");
      final response = await _dio.get(_apiBaseUrl);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> videoData = response.data['data'] ?? response.data;
        final videos =
            videoData
                .map(
                  (data) => VideoModel.fromJson(data as Map<String, dynamic>),
                )
                .toList();
        _logger.i("Fetched ${videos.length} videos from API.");
        await _cacheVideosLocally(videos);
        return videos;
      } else {
        _logger.e(
          "API error fetching videos: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to load videos.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "fetching videos");
      // --- FIX: Catch specific sqflite exception HERE as well ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Error fetching videos from DB",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        'Could not load videos from local storage.',
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      // Catch other errors like parsing errors
      _logger.e("Error fetching videos", error: e, stackTrace: stackTrace);
      throw DataProcessingException(
        'Could not process video data.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<VideoModel>> searchVideos(String query) async {
    // ... (logging, empty query check) ...
    try {
      // --- FIX: Catch specific sqflite exception for DB search ---
      final localMaps = await _databaseHelper.searchVideos(query.trim());
      if (localMaps.isNotEmpty) {
        // ... (logging, mapping, return) ...
        return localMaps.map((map) => VideoModel.fromJson(map)).toList();
      }

      // ... (API call logic) ...
      final response = await _dio.get(
        '$_apiBaseUrl/search',
        queryParameters: {'q': query.trim()},
      );
      if (response.statusCode == 200 && response.data != null) {
        // ... (mapping, logging, return) ...
        final List<dynamic> videoData = response.data['data'] ?? response.data;
        return videoData
            .map((data) => VideoModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        _logger.e(
          "API error searching videos: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Video search failed.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "searching videos");
      // --- FIX: Catch specific sqflite exception HERE ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Error searching videos in DB",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        'Local video search failed.',
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e("Error searching videos", error: e, stackTrace: stackTrace);
      throw DataProcessingException(
        'Could not process video search results.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<VideoModel?> getVideoById(String id) async {
    // Kept nullable return type
    _logger.d("Repository: Getting video by ID '$id'");
    try {
      // --- FIX: Catch specific sqflite exception for DB query ---
      final localMap = await _databaseHelper.getVideoById(id);
      if (localMap != null) {
        _logger.i("Returning video ID '$id' from local DB.");
        return VideoModel.fromJson(localMap);
      }

      // ... (API call logic) ...
      final response = await _dio.get('$_apiBaseUrl/$id');
      if (response.statusCode == 200 && response.data != null) {
        // ... (mapping, cache, return) ...
        final videoData = response.data['data'] ?? response.data;
        final video = VideoModel.fromJson(videoData as Map<String, dynamic>);
        await _cacheSingleVideoLocally(video);
        return video;
      } else if (response.statusCode == 404) {
        _logger.w("Video ID '$id' not found on API (404).");
        return null;
      } else {
        _logger.e(
          "API error fetching video $id: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to load video details.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.w("Video ID '$id' not found (Dio 404).");
        return null;
      }
      throw _handleDioError(e, "fetching video $id");
      // --- FIX: Catch specific sqflite exception HERE ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Error fetching video $id from DB",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        'Could not load video $id from local storage.',
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e("Error fetching video $id", error: e, stackTrace: stackTrace);
      throw DataProcessingException(
        'Could not process video data for $id.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<VideoModel> toggleFavorite(VideoModel video) async {
    if (_userId == null) throw AuthException("User not logged in.");
    _logger.d(
      "Repository: Toggling favorite for video: ${video.id}, User: $_userId",
    );
    final bool newFavoriteState = !video.isFavorite;

    try {
      // --- FIX: Catch specific sqflite exception for DB update ---
      await _databaseHelper.setVideoFavorite(
        _userId!,
        video.id,
        newFavoriteState,
      );

      // Optional API Sync logic remains the same...

      return video.copyWith(isFavorite: newFavoriteState);

      // --- FIX: Catch specific sqflite exception and re-throw custom ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Database error toggling favorite for video ${video.id}",
        error: e,
        stackTrace: stackTrace,
      );
      // Throw *your* custom DatabaseException
      throw DatabaseException(
        "Failed to update favorite status locally.",
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      // Catch other errors (like potential API sync errors if uncommented)
      _logger.e(
        "Unexpected error toggling favorite for video ${video.id}",
        error: e,
        stackTrace: stackTrace,
      );
      // Determine appropriate exception type based on where the error originated
      if (e is DioException)
        throw _handleDioError(e, "syncing favorite status");
      throw DataProcessingException(
        "Could not update favorite status.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<VideoModel>> getFavoriteVideos() async {
    if (_userId == null) throw AuthException("User not logged in.");
    _logger.d("Repository: Getting favorite videos for user $_userId");

    try {
      // --- FIX: Catch specific sqflite exception for DB query ---
      final favoriteMaps = await _databaseHelper.getFavoriteVideos(_userId!);
      _logger.i(
        "Found ${favoriteMaps.length} favorite videos locally for user $_userId.",
      );
      return favoriteMaps.map((map) => VideoModel.fromJson(map)).toList();

      // --- FIX: Catch specific sqflite exception and re-throw custom ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Database error fetching favorite videos for user $_userId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Could not load favorite videos locally.",
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Error fetching favorite videos for user $_userId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        "Could not load favorite videos.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<VideoModel>> getRecommendedVideos() async {
    _logger.d("Repository: Getting recommended videos");
    try {
      // --- FIX: Catch specific sqflite exception for DB query ---
      final recommendedMaps = await _databaseHelper.getRecommendedVideos();
      _logger.i("Found ${recommendedMaps.length} recommended videos locally.");
      return recommendedMaps.map((map) => VideoModel.fromJson(map)).toList();

      // Optional API logic remains the same...

      // --- FIX: Catch specific sqflite exception and re-throw custom ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Database error fetching recommended videos",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Could not load recommended videos from local storage.",
        cause: e,
        stackTrace: stackTrace,
      );
      // Keep DioException catch if using API Option 2
    } on DioException catch (e) {
      throw _handleDioError(e, "fetching recommended videos");
    } catch (e, stackTrace) {
      _logger.e(
        "Error fetching recommended videos",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        'Could not load recommended videos.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<VideoModel>> getVideosByCategory(String category) async {
    _logger.d("Repository: Getting videos for category '$category'");
    try {
      // --- FIX: Catch specific sqflite exception for DB query ---
      final localMaps = await _databaseHelper.getVideosByCategory(category);
      if (localMaps.isNotEmpty) {
        _logger.i(
          "Returning ${localMaps.length} videos for category '$category' from local DB.",
        );
        return localMaps.map((map) => VideoModel.fromJson(map)).toList();
      }

      // ... (API call logic remains the same) ...
      final response = await _dio.get('$_apiBaseUrl/category/$category');
      if (response.statusCode == 200 && response.data != null) {
        // ... (mapping, cache, return) ...
        final List<dynamic> videoData = response.data['data'] ?? response.data;
        final videos =
            videoData
                .map(
                  (data) => VideoModel.fromJson(data as Map<String, dynamic>),
                )
                .toList();
        await _cacheVideosLocally(videos);
        return videos;
      } else {
        _logger.e(
          "API error fetching category $category: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to load videos for category $category.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "fetching category $category");
      // --- FIX: Catch specific sqflite exception HERE ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Database error fetching category $category",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Could not load videos for category $category locally.",
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Error fetching category $category",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        'Could not process videos for category $category.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  // --- Admin/CMS Operations (Error handling added) ---

  @override
  Future<VideoModel> addVideo(VideoModel video) async {
    // ... (logging, warning) ...
    try {
      // ... (API call) ...
      final response = await _dio.post(_apiBaseUrl, data: video.toJson());
      if (response.statusCode == 201 && response.data != null) {
        // ... (mapping) ...
        final createdVideoData = response.data['data'] ?? response.data;
        final createdVideo = VideoModel.fromJson(
          createdVideoData as Map<String, dynamic>,
        );
        await _cacheSingleVideoLocally(
          createdVideo,
        ); // Includes its own error handling
        return createdVideo;
      } else {
        _logger.e(
          "API error adding video: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to add video.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "adding video");
      // No specific sqflite exception needed here unless caching throws and isn't caught internally
    } catch (e, stackTrace) {
      _logger.e("Error adding video", error: e, stackTrace: stackTrace);
      throw DataProcessingException(
        'Could not add video.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<VideoModel> updateVideo(VideoModel video) async {
    // ... (logging, warning) ...
    try {
      // ... (API call) ...
      final response = await _dio.put(
        '$_apiBaseUrl/${video.id}',
        data: video.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        // ... (mapping) ...
        final updatedVideoData = response.data['data'] ?? response.data;
        final updatedVideo = VideoModel.fromJson(
          updatedVideoData as Map<String, dynamic>,
        );
        await _cacheSingleVideoLocally(
          updatedVideo,
        ); // Includes its own error handling
        return updatedVideo;
      } else {
        _logger.e(
          "API error updating video ${video.id}: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to update video.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "updating video ${video.id}");
      // No specific sqflite exception needed here unless caching throws and isn't caught internally
    } catch (e, stackTrace) {
      _logger.e(
        "Error updating video ${video.id}",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        'Could not update video.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteVideo(String id) async {
    // ... (logging, warning) ...
    try {
      // ... (API call) ...
      final response = await _dio.delete('$_apiBaseUrl/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.i("Video deleted successfully via API: $id");
        // --- FIX: Catch specific sqflite exception for DB delete ---
        _logger.d("Deleting video $id from local DB.");
        await _databaseHelper.delete(
          'app_videos',
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        _logger.e(
          "API error deleting video $id: ${response.statusCode} - ${response.statusMessage}",
        );
        throw ApiException(
          'Failed to delete video.',
          statusCode: response.statusCode,
          cause: response.statusMessage,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "deleting video $id");
      // --- FIX: Catch specific sqflite exception HERE ---
    } on sqflite.DatabaseException catch (e, stackTrace) {
      _logger.e(
        "Database error deleting video $id",
        error: e,
        stackTrace: stackTrace,
      );
      // Decide if API call should be reverted or just log local failure
      throw DatabaseException(
        "Failed to delete video locally after successful API deletion.",
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e("Error deleting video $id", error: e, stackTrace: stackTrace);
      throw DataProcessingException(
        'Could not delete video.',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}


// --- IMPORTANT: Update VideoRepository Interface ---
// You MUST update the interface in lib/data/repositories/video_repository.dart
// to match the implementation's getVideoById signature:

// abstract class VideoRepository {
//   // ... other methods
//   Future<VideoModel?> getVideoById(String id); // <-- Change to nullable Future<VideoModel?>
//   // ... other methods
// }