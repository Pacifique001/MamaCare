// presentation/viewmodel/video_list_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/video_model.dart';
import 'package:mama_care/data/local/database_helper.dart'; // Keep for favorites
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/foundation.dart'; // For ChangeNotifier mounting check (optional)

class VideoListViewModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper; // Keep for favorites

  // --- Keep track if disposed ---
  bool _isDisposed = false;

  VideoListViewModel(this._databaseHelper);

  // --- Hardcoded Video Data ---
  final List<VideoModel> _hardcodedVideos = [
    const VideoModel(
      id: 'vid_001',
      title: 'Prenatal Yoga Basics',
      description:
          'Gentle yoga poses suitable for all trimesters. Improves flexibility and relaxation.',
      thumbnailUrl:
          'https://media.istockphoto.com/id/626414164/photo/yoga-for-the-pregnant.jpg?s=2048x2048&w=is&k=20&c=EOviZFTaG1Krv02xzdJsJJQ3EHWJJof8NNMCiNTAf30=',
      url: 'https://www.youtube.com/watch?v=B87FpWtkIKA',
      category: 'Yoga & Fitness',
    ),
    const VideoModel(
      id: 'vid_002',
      title: 'Healthy Eating During Pregnancy',
      description:
          'Learn about essential nutrients and meal planning for a healthy pregnancy diet.',
      thumbnailUrl:
          'https://media.istockphoto.com/id/1505884159/photo/pregnant-woman-making-salad-in-her-kitchen-healthcare.jpg?s=2048x2048&w=is&k=20&c=QHZ7_BdlTLlHKIBJ81ND0yysauxwEvZ3m-KDlZVU-9M=',
      url: 'https://www.youtube.com/watch?v=0ohxOQPlzy4',
      category: 'Nutrition',
    ),
    const VideoModel(
      id: 'vid_003',
      title: 'Preparing for Labor',
      description:
          'Tips and techniques to prepare your body and mind for childbirth.',
      thumbnailUrl:
          'https://media.istockphoto.com/id/1299850715/photo/pregnant-woman-packing-bag-for-maternity-hospital-making-notes-checking-list-in-diary.jpg?s=2048x2048&w=is&k=20&c=YuoAGV-Xq5eXv3yUUp0Wtgp-iagtKCdsoQCJ5rQfEO0=',
      url: 'https://www.youtube.com/watch?v=Q6213lkGvyc',
      category: 'Labor & Delivery',
    ),
    const VideoModel(
      id: 'vid_004',
      title: 'Postpartum Recovery Tips',
      description:
          'Guidance on physical and emotional recovery after childbirth.',
      thumbnailUrl:
          'https://media.istockphoto.com/id/1208244890/photo/mother-holding-baby-in-medical-appointment.jpg?s=2048x2048&w=is&k=20&c=FrgeYf6VG5LJuUCA_KY8jgXbiLcGsJnOkYYidqOCVz4=',
      url: 'https://www.youtube.com/watch?v=dHdh3eNZnW8',
      category: 'Postpartum',
    ),
  ];

  // State variables
  List<VideoModel> _videos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Safely notify listeners only if the ViewModel hasn't been disposed.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --- UPDATED: Requires userId ---
  // Load videos (from hardcoded list + check favorites for the given user)
  Future<void> loadVideos({required String userId}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners(); // Notify loading start

    try {
      // Get favorite videos *specifically for this user*
      final favoriteVideoMaps = await _databaseHelper.getFavoriteVideos(userId);
      // Extract just the IDs for efficient checking
      final favoriteIds =
          favoriteVideoMaps.map((map) => map['id'] as String).toSet();

      // Map hardcoded videos and update favorite status based on DB result
      _videos =
          _hardcodedVideos.map((video) {
            return video.copyWith(isFavorite: favoriteIds.contains(video.id));
          }).toList();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load video data or favorites: ${e.toString()}';
      _videos = List.from(
        _hardcodedVideos.map((v) => v.copyWith(isFavorite: false)),
      );
      debugPrint("Error loading videos/favorites: $e");
    } finally {
      _isLoading = false;
      _safeNotifyListeners(); // Notify loading end and data update/error
    }
  }

  // Search videos (filters the current list, preserves user's favorites)
  void searchVideos(String query) {
    if (query.isEmpty) {
      // Rebuild from original list, preserving current favorites
      final currentFavorites = Map.fromEntries(
        _videos.where((v) => v.isFavorite).map((v) => MapEntry(v.id, true)),
      );
      _videos =
          _hardcodedVideos.map((video) {
            return video.copyWith(
              isFavorite: currentFavorites[video.id] ?? false,
            );
          }).toList();
    } else {
      final lowerCaseQuery = query.toLowerCase();
      final currentFavorites = Map.fromEntries(
        _videos.where((v) => v.isFavorite).map((v) => MapEntry(v.id, true)),
      );
      _videos =
          _hardcodedVideos
              .where((video) {
                return video.title.toLowerCase().contains(lowerCaseQuery) ||
                    video.description.toLowerCase().contains(lowerCaseQuery) ||
                    video.category.toLowerCase().contains(lowerCaseQuery);
              })
              .map((filteredVideo) {
                return filteredVideo.copyWith(
                  isFavorite: currentFavorites[filteredVideo.id] ?? false,
                );
              })
              .toList();
    }
    _safeNotifyListeners();
  }

  // --- UPDATED: Requires userId ---
  // Refresh videos (calls loadVideos with userId)
  Future<void> refreshVideos({required String userId}) async {
    // Don't necessarily set loading true here, loadVideos will handle it
    await loadVideos(userId: userId);
  }

  // Get video by ID (searches the current list)
  VideoModel? getVideoById(String id) {
    return _videos.firstWhereOrNull((video) => video.id == id);
  }

  // --- UPDATED: Requires userId ---
  // Toggle video favorite status (interacts with DatabaseHelper for the given user)
  Future<void> toggleFavorite({
    required String userId,
    required String videoId,
  }) async {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index == -1) {
      _errorMessage = 'Video not found to toggle favorite.';
      _safeNotifyListeners();
      return; // Video not found
    }

    final video = _videos[index];
    final newFavoriteStatus = !video.isFavorite;

    // Update UI optimistically
    _videos[index] = video.copyWith(isFavorite: newFavoriteStatus);
    _safeNotifyListeners(); // Update UI immediately

    try {
      // Call DatabaseHelper with all required parameters
      await _databaseHelper.setVideoFavorite(
        userId, // Pass the user ID
        videoId,
        newFavoriteStatus, // Pass the new boolean status
      );

      _errorMessage = null; // Clear error on success
    } catch (e) {
      _errorMessage = 'Failed to update favorite status: ${e.toString()}';
      debugPrint("Error updating favorite: $e");
      // Revert UI change on failure
      _videos[index] = video.copyWith(
        isFavorite: video.isFavorite,
      ); // Revert to original status
      _safeNotifyListeners(); // Update UI again to show the reverted state
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed
    super.dispose();
  }
}
