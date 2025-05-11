import 'package:mama_care/domain/entities/article_model.dart';
import 'package:injectable/injectable.dart';

@factoryMethod
abstract class ArticleRepository {
  Future<List<ArticleModel>> getArticles();
  Future<ArticleModel> getArticleById(String id);
  Future<List<ArticleModel>> searchArticles(String query);
  Future<ArticleModel> toggleBookmark(ArticleModel article);
  Future<List<ArticleModel>> getBookmarkedArticles();
}