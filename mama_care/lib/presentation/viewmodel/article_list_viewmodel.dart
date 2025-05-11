// lib/presentation/viewmodel/article_list_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart'; // Import custom exceptions
import 'package:mama_care/domain/usecases/article_usecase.dart';
import 'package:mama_care/domain/entities/article_model.dart';
//import 'package:mama_care/data/local/database_helper.dart';
//import 'package:mama_care/utils/asset_helper.dart';

@injectable
class ArticleListViewModel extends ChangeNotifier {
  final ArticleUseCase _articleUseCase;
  final Logger _logger; // Inject Logger
  // Removed: final DatabaseHelper _databaseHelper;

  ArticleListViewModel(this._articleUseCase, this._logger) {
    _logger.i("ArticleListViewModel initialized");
    // Load initial articles or placeholder data
    _loadInitialOrPlaceholderData();
  }

  List<ArticleModel> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;

  // Removed unused _articleData and articleList

  List<ArticleModel> get articles =>
      List.unmodifiable(_articles); // Return unmodifiable
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;

  // --- Private State Setters ---
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    if (message != null) _logger.e("ArticleListVM Error: $message");
    notifyListeners();
  }

  void _clearError() => _setError(null);

  // --- Data Fetching ---

  /// Loads initial data - attempts fetch, falls back to placeholders if fetch fails initially.
  Future<void> _loadInitialOrPlaceholderData() async {
    _logger.i("Loading initial/placeholder articles...");
    _setLoading(true);
    _clearError();
    _searchQuery = null;
    try {
      _articles = await _articleUseCase.getArticles();
      _logger.i("Fetched ${_articles.length} articles successfully.");
      if (_articles.isEmpty) {
        _logger.w("No articles fetched from source, loading placeholders.");
        _articles =
            _getPlaceholderArticles(); // Load placeholders if fetch returns empty
      }
    } catch (e, s) {
      _logger.e(
        "Failed to load initial articles, using placeholders.",
        error: e,
        stackTrace: s,
      );
      _setError(
        'Could not load articles. Showing examples.',
      ); // Inform user about placeholders
      _articles = _getPlaceholderArticles(); // Load placeholders on error
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches all articles from the repository.
  Future<void> fetchArticles() async {
    _logger.i("Fetching articles...");
    _setLoading(true);
    _clearError();
    _searchQuery = null;
    try {
      _articles = await _articleUseCase.getArticles();
      _logger.i("Fetched ${_articles.length} articles successfully.");
      if (_articles.isEmpty) {
        _logger.w("No articles found from source.");
        // Optionally set a specific message for empty results vs error
        // _setError("No articles available at the moment.");
      }
    } on AppException catch (e) {
      _logger.e("Error fetching articles", error: e);
      _setError(e.message);
      _articles = [];
    } catch (e, s) {
      _logger.e("Unexpected error fetching articles", error: e, stackTrace: s);
      _setError('Failed to load articles.');
      _articles = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Searches articles via the repository.
  Future<void> searchArticles(String query) async {
    final trimmedQuery = query.trim();
    _logger.i("Searching articles for: '$trimmedQuery'");
    _setLoading(true);
    _clearError();
    _searchQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      _logger.w("Search query empty, fetching all articles.");
      await fetchArticles(); // Fetch all if query is cleared
      return;
    }

    try {
      _articles = await _articleUseCase.searchArticles(trimmedQuery);
      _logger.i(
        "Search found ${_articles.length} articles for '$trimmedQuery'.",
      );
      if (_articles.isEmpty) {
        _logger.w("No articles found for search query '$trimmedQuery'.");
        // Optionally set message: _setError("No results found for '$trimmedQuery'.");
      }
    } on AppException catch (e) {
      _logger.e("Error searching articles", error: e);
      _setError(e.message);
      _articles = [];
    } catch (e, s) {
      _logger.e("Unexpected error searching articles", error: e, stackTrace: s);
      _setError('Article search failed.');
      _articles = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the article list.
  Future<void> refreshArticles() async {
    _logger.i("Refreshing article list...");
    await fetchArticles(); // Simply re-run the fetch logic
  }

  /// Toggles bookmark status and updates the local list. Returns success bool.
  Future<bool> toggleBookmark(ArticleModel articleToToggle) async {
    final articleId = articleToToggle.id;
    _logger.d("Toggling bookmark for article: $articleId");
    // Find index before potential async gap
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) {
      _logger.w(
        "Cannot toggle bookmark, article $articleId not found in current list.",
      );
      return false;
    }

    // Optimistic UI update (optional)
    // _articles[index] = articleToToggle.copyWith(isBookmarked: !articleToToggle.isBookmarked);
    // notifyListeners();

    try {
      // Use the article object itself
      final updatedArticle = await _articleUseCase.toggleBookmark(
        articleToToggle,
      );
      // Update the list with the confirmed state
      _articles[index] = updatedArticle;
      _logger.i("Bookmark status updated successfully for $articleId");
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e(
        "Failed to toggle bookmark for $articleId",
        error: e,
        stackTrace: s,
      );
      _setError('Failed to update bookmark status.'); // Set error for UI
      // Revert optimistic update if implemented
      // _articles[index] = articleToToggle;
      notifyListeners();
      return false;
    }
  }

  /// Fetches only bookmarked articles.
  Future<List<ArticleModel>> getBookmarkedArticles() async {
    _logger.d("Fetching bookmarked articles...");
    try {
      // Consider adding loading/error state specific to this action if needed
      return await _articleUseCase.getBookmarkedArticles();
    } catch (e, s) {
      _logger.e("Failed to get bookmarked articles", error: e, stackTrace: s);
      _setError('Failed to load bookmarked articles.'); // Set error for UI
      return []; // Return empty list on error
    }
  }

  // --- Placeholder Data with Online Image URLs ---
  List<ArticleModel> _getPlaceholderArticles() {
    DateTime now = DateTime.now();
    return [
      ArticleModel(
        id: 'placeholder-1',
        title: 'Maintaining a Healthy Pregnancy',
        content:
            'Nutrition Tips and Strategies for Expectant Mothers - covers nutrients like folic acid and iron, managing morning sickness, and healthy recipes...',
        author: 'Dr. Anya Sharma',
        imageUrl:
            'https://images.pexels.com/photos/3958958/pexels-photo-3958958.jpeg?auto=compress&cs=tinysrgb&w=600',
        publishDate: now.subtract(const Duration(days: 2)),
        tags: ['nutrition', 'health', 'trimester 1'],
        isBookmarked: false,
      ),
      ArticleModel(
        id: 'placeholder-2',
        title: 'Prenatal Yoga: A Gentle Guide',
        content:
            'Benefits of prenatal yoga, safe modifications for a growing belly, and poses to relieve back pain and improve well-being...',
        author: 'MamaCare Wellness',
        imageUrl:
            'https://images.pexels.com/photos/3771045/pexels-photo-3771045.jpeg?auto=compress&cs=tinysrgb&w=600',
        publishDate: now.subtract(const Duration(days: 5)),
        tags: ['exercise', 'yoga', 'wellness', 'trimester 2'],
        isBookmarked: true,
      ),
      ArticleModel(
        id: 'placeholder-3',
        title: 'Prenatal Yoga: Helping Women During Pregnancy',
        content:
            '''Pregnancy is a beautiful phase of life. It’s a joyful time that is filled with excitement and anticipation. Despite the joy you feel, it can also be an overwhelming time filled with heightened emotions – both positive and negative

          Prenatal yoga helps you manage and prepare the body and mind for birth. It helps manage physical changes happening during pregnancy and makes sure the mind, body, and soul feel strong, healthy, and calm. Beyond the physical benefits of staying fit and relaxed, prenatal yoga may improve your mental health during pregnancy, including anxiety, depression, and stress.

          Whether or not you’ve attended a yoga class or tried it at home, prenatal yoga helps women have a powerful and beautiful birth experience. It allows you to focus on yourself and the connection with your baby.''',
        author: 'Community Midwives',
        imageUrl:
            'https://xeroshoes.com/wp-content/uploads/2024/03/safe-prenatal-yoga-poses-1024x683.jpg',
        publishDate: now.subtract(const Duration(days: 10)),
        tags: ['labor', 'delivery', 'preparation', 'trimester 3'],
        isBookmarked: false,
      ),
      ArticleModel(
        id: 'placeholder-4',
        title: 'Mental Health During Pregnancy',
        content:
            'Managing stress and anxiety, the importance of self-care, mindfulness techniques, and when to seek professional help...',
        author: 'Dr. Ben Carter',
        imageUrl:
            'https://images.pexels.com/photos/4101143/pexels-photo-4101143.jpeg?auto=compress&cs=tinysrgb&w=600',
        publishDate: now.subtract(const Duration(days: 15)),
        tags: ['mental health', 'wellness', 'stress'],
        isBookmarked: false,
      ),
    ];
  }
}
