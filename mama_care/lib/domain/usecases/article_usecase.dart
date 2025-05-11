import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/article_model.dart';
import 'package:mama_care/data/repositories/article_repository.dart';

@injectable
class ArticleUseCase {
  final ArticleRepository _repository;

  ArticleUseCase(this._repository);

  Future<List<ArticleModel>> getArticles() async {
    return await _repository.getArticles();
  }

  Future<ArticleModel> getArticleById(String id) async {
    return await _repository.getArticleById(id);
  }

  Future<List<ArticleModel>> searchArticles(String query) async {
    return await _repository.searchArticles(query);
  }

  Future<ArticleModel> toggleBookmark(ArticleModel article) async {
    return await _repository.toggleBookmark(article);
  }

  Future<List<ArticleModel>> getBookmarkedArticles() async {
    return await _repository.getBookmarkedArticles();
  }
}