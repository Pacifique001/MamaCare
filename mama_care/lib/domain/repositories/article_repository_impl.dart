import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/article_repository.dart';
import 'package:mama_care/domain/entities/article_model.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@Injectable(as: ArticleRepository)
class ArticleRepositoryImpl implements ArticleRepository {
  final DatabaseHelper _databaseHelper;
  final FirebaseMessaging _firebaseMessaging;

  ArticleRepositoryImpl(this._databaseHelper, this._firebaseMessaging);

  @override
  Future<List<ArticleModel>> getArticles() async {
    final results = await _databaseHelper.query('articles');
    return results.map((e) => ArticleModel.fromJson(e)).toList();
  }

  @override
  Future<ArticleModel> getArticleById(String id) async {
    final results = await _databaseHelper.query(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) {
      throw Exception('Article not found');
    }
    return ArticleModel.fromJson(results.first);
  }

  @override
  Future<List<ArticleModel>> searchArticles(String query) async {
    final results = await _databaseHelper.query(
      'articles',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
    );
    return results.map((e) => ArticleModel.fromJson(e)).toList();
  }

  @override
  Future<ArticleModel> toggleBookmark(ArticleModel article) async {
    final updatedArticle = article.copyWith(isBookmarked: !article.isBookmarked);
    await _databaseHelper.update(
      'articles',
      updatedArticle.toJson(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
    return updatedArticle;
  }

  @override
  Future<List<ArticleModel>> getBookmarkedArticles() async {
    final results = await _databaseHelper.query(
      'articles',
      where: 'isBookmarked = ?',
      whereArgs: [1],
    );
    return results.map((e) => ArticleModel.fromJson(e)).toList();
  }
}