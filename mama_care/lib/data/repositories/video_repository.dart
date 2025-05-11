import 'package:mama_care/domain/entities/video_model.dart';
import 'package:injectable/injectable.dart';

@factoryMethod
abstract class VideoRepository {
  Future<List<VideoModel>> getVideos();
  Future<List<VideoModel>> searchVideos(String query);
  Future<VideoModel?> getVideoById(String id);
  Future<VideoModel> toggleFavorite(VideoModel video);
  Future<List<VideoModel>> getFavoriteVideos();
  Future<List<VideoModel>> getRecommendedVideos();
  Future<List<VideoModel>> getVideosByCategory(String category);
  Future<VideoModel> addVideo(VideoModel video);
  Future<VideoModel> updateVideo(VideoModel video);
  Future<void> deleteVideo(String id);
}