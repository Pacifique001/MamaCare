// lib/presentation/viewmodel/article_viewmodel.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/usecases/article_usecase.dart';
import 'package:mama_care/domain/entities/article_model.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus

@injectable
class ArticleViewModel extends ChangeNotifier {
  final ArticleUseCase _articleUseCase;
  final Logger _logger; // Inject Logger
  final String articleId;

  ArticleViewModel(
    this._articleUseCase,
    this._logger,
    @factoryParam this.articleId, // Get ID via DI
  ) {
    _logger.i("ArticleViewModel initialized for article ID: $articleId");
    fetchArticle(); // Fetch data when ViewModel is created
  }

  // --- State ---
  ArticleModel? _article;
  bool _isLoading = false;
  String? _errorMessage;
  // Removed: bool _isBookmarked = false; // Derive from _article

  // --- Getters ---
  ArticleModel? get article => _article;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBookmarked => _article?.isBookmarked ?? false; // Derive from article
  // Removed: articleImage getter

  // --- Private State Setters ---
  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { if (_errorMessage == message) return; _errorMessage = message; if (message != null) _logger.e("ArticleVM Error ($articleId): $message"); notifyListeners(); }
  void _clearError() => _setError(null);

  // --- Data Fetching ---
  Future<void> fetchArticle() async {
    _logger.d("VM: Fetching article details for ID: $articleId");
    _setLoading(true);
    _clearError();
    try {
      _article = await _articleUseCase.getArticleById(articleId);
      if (_article == null) {
          _logger.w("VM: Article $articleId not found.");
          _setError("Article not found.");
      } else {
          _logger.i("VM: Article $articleId fetched successfully.");
      }
    } on AppException catch(e) {
        _logger.e("VM: Failed to fetch article $articleId", error: e);
        _setError(e.message);
        _article = null;
    } catch (e, s) {
       _logger.e("VM: Unexpected error fetching article $articleId", error: e, stackTrace: s);
       _setError('Failed to load article details.');
       _article = null;
    } finally {
      _setLoading(false);
    }
  }

  // --- Actions ---
  Future<bool> toggleBookmark() async { // Return bool for feedback
    if (_article == null) {
       _logger.w("Cannot toggle bookmark: Article not loaded.");
       _setError("Cannot update bookmark: Article not loaded.");
       return false;
    }
    if (_isLoading) return false; // Prevent multiple taps

    _logger.d("VM: Toggling bookmark for article: $articleId");
    _setLoading(true);
    _clearError();
    try {
      final updatedArticle = await _articleUseCase.toggleBookmark(_article!);
      _article = updatedArticle; // Update local state immediately
      _logger.i("Bookmark toggled successfully for $articleId, new status: ${updatedArticle.isBookmarked}");
      notifyListeners(); // Update UI
      return true;
    } catch (e, s) {
       _logger.e("Failed to toggle bookmark for $articleId", error: e, stackTrace: s);
       _setError(e is AppException ? e.message : 'Failed to update bookmark status.');
       // State (_article) remains optimistic or revert based on preference
       _setLoading(false); // Ensure loading stops on error
       return false;
    } finally {
       // Loading state should be handled by success/error path, but ensure it stops
       if (_isLoading) _setLoading(false);
    }
  }

  Future<void> shareArticle() async {
    if (_article == null) { _setError("Cannot share article details."); return; }
    _clearError();
    _logger.i("Sharing article: ${article!.id} - ${article!.title}");
    try {
      // Basic sharing: Title and first part of content
      final String shareText = 'Check out this article from MamaCare:\n"${article!.title}"\n${article!.content.substring(0, min(article!.content.length, 150))}...';
      // Optional: Add a deep link URL if your app supports it
      //final String articleUrl = "https://yourapp.com/article/${article!.id}";
      await Share.share(shareText /* + '\n$articleUrl' */, subject: article!.title);
    } catch (e, stackTrace) {
      _logger.e("Failed to share article $articleId", error: e, stackTrace: stackTrace);
      _setError('Could not share article at this time.');
    }
  }

  // Add comment (Placeholder - Requires backend/UseCase implementation)
  Future<void> addComment(String comment) async {
    if (_article == null || comment.trim().isEmpty) return;
    _logger.i("VM: Attempting to add comment to article $articleId");
    _setLoading(true); _clearError();
    try {
      // await _articleUseCase.addComment(articleId, comment.trim());
      _logger.w("Add comment functionality is not implemented.");
      _setError("Commenting feature not available yet.");
      // If successful, you might need to refresh the article/comments
      _setLoading(false); // Remove if refresh handles loading
    } catch (e, s) {
       _logger.e("Failed to add comment for article $articleId", error: e, stackTrace: s);
       _setError(e is AppException ? e.message : "Failed to add comment.");
       _setLoading(false);
    }
  }
}