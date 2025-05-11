import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/video_model.dart';
import 'package:mama_care/data/repositories/video_repository.dart';

@injectable
class VideoUseCase {
  final VideoRepository _repository;

  VideoUseCase(this._repository);

  // Get all videos
  Future<List<VideoModel>> getVideos() async {
    return await _repository.getVideos();
  }

  // Search videos by query
  Future<List<VideoModel>> searchVideos(String query) async {
    return await _repository.searchVideos(query);
  }

  // Get video by ID
  Future<VideoModel?> getVideoById(String id) async {
    return await _repository.getVideoById(id);
  }

  // Toggle favorite status
  Future<VideoModel> toggleFavorite(VideoModel video) async {
    return await _repository.toggleFavorite(video);
  }

  // Get favorite videos
  Future<List<VideoModel>> getFavoriteVideos() async {
    return await _repository.getFavoriteVideos();
  }

  // Get recommended videos
  Future<List<VideoModel>> getRecommendedVideos() async {
    return await _repository.getRecommendedVideos();
  }

  // Get videos by category
  Future<List<VideoModel>> getVideosByCategory(String category) async {
    return await _repository.getVideosByCategory(category);
  }

  // Add new video (admin functionality)
  Future<VideoModel> addVideo(VideoModel video) async {
    return await _repository.addVideo(video);
  }

  // Update video (admin functionality)
  Future<VideoModel> updateVideo(VideoModel video) async {
    return await _repository.updateVideo(video);
  }

  // Delete video (admin functionality)
  Future<void> deleteVideo(String id) async {
    return await _repository.deleteVideo(id);
  }
}