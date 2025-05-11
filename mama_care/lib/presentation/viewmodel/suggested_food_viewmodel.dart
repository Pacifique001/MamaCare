// lib/presentation/viewmodel/suggested_food_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:mama_care/domain/usecases/food_usecase.dart';
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart'; // Import Logger
import 'package:mama_care/injection.dart'; // For locator

@injectable // Ensure this annotation is present if using injectable
class SuggestedFoodViewModel extends ChangeNotifier {
  final FoodUseCase _foodUseCase;
  final Logger _logger; // Inject Logger

  // Constructor with injected dependencies
  SuggestedFoodViewModel(this._foodUseCase, this._logger) {
    _logger.i("SuggestedFoodViewModel initialized.");
    // Load initial data when the ViewModel is created
    loadSuggestedFoods();
  }

  // --- State Variables ---
  List<FoodModel> _allFoods = []; // Holds all fetched foods (for filtering)
  List<FoodModel> _filteredFoods =
      []; // Holds foods displayed in the UI (filtered/searched)
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;
  String? _selectedCategory; // To store the currently selected filter category
  bool _showFavoritesOnly = false; // To filter by favorites

  // --- Getters ---
  // UI should display the filtered list
  List<FoodModel> get displayedFoods => _filteredFoods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get showFavoritesOnly => _showFavoritesOnly;

  // Get unique categories from the loaded food data
  List<String> get availableCategories {
    if (_allFoods.isEmpty) return [];
    // Use a Set to get unique category names, then convert to list and sort
    final categories = _allFoods.map((food) => food.category).toSet().toList();
    categories.sort(); // Sort alphabetically
    return categories;
  }

  // --- State Management Helpers ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    if (message != null) {
      _logger.e("SuggestedFoodViewModel Error: $message");
    }
    // Notify listeners ONLY if the UI needs to react directly (e.g., show a banner)
    // Otherwise, rely on isLoading going false and potentially empty list
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // May need to notify if UI was showing an error message banner
       notifyListeners();
    }
  }

  // --- Data Fetching and Filtering ---

  /// Loads all foods from the use case (typically called once initially).
  Future<void> loadSuggestedFoods() async {
    _logger.d("Loading suggested foods...");
    _setLoading(true);
    _setError(null); // Clear previous errors

    try {
      _allFoods = await _foodUseCase.getSuggestedFoods(); // Fetch all foods
      _logger.i("Loaded ${_allFoods.length} foods.");
      _applyFilters(); // Apply current filters (search, category, favorites) to update displayed list
    } catch (e, stackTrace) {
      _logger.e(
        "Failed to load suggested foods",
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to load suggested foods: ${e.toString()}');
      _allFoods = []; // Clear lists on critical error
      _filteredFoods = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Applies search query, category filter, and favorite filter to _allFoods
  /// and updates _filteredFoods. Notifies listeners.
  void _applyFilters() {
    _logger.d(
      "Applying filters: Query='$_searchQuery', Category='$_selectedCategory', FavoritesOnly='$_showFavoritesOnly'",
    );
    List<FoodModel> tempFiltered = List.from(_allFoods); // Start with all foods

    // 1. Filter by Favorites (if enabled)
    if (_showFavoritesOnly) {
      tempFiltered = tempFiltered.where((food) => food.isFavorite).toList();
    }

    // 2. Filter by Category (if selected)
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      tempFiltered =
          tempFiltered
              .where(
                (food) =>
                    food.category.toLowerCase() ==
                    _selectedCategory!.toLowerCase(),
              )
              .toList();
    }

    // 3. Filter by Search Query (if present)
    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      final queryLower = _searchQuery!.toLowerCase().trim();
      tempFiltered =
          tempFiltered.where((food) {
            // Check name, description, category, and maybe benefits
            return food.name.toLowerCase().contains(queryLower) ||
                food.description.toLowerCase().contains(queryLower) ||
                food.category.toLowerCase().contains(queryLower) ||
                food.benefits.any((b) => b.toLowerCase().contains(queryLower));
          }).toList();
    }

    _filteredFoods = tempFiltered; // Update the list displayed by the UI
    _logger.d("Filtering complete. Displaying ${_filteredFoods.length} foods.");
    notifyListeners(); // Update the UI with the filtered list
  }

  /// Public method to set the search query and trigger filtering.
  void searchFoods(String? query) {
    // Set the query (null or empty string clears the search)
    _searchQuery = (query?.trim().isEmpty ?? true) ? null : query!.trim();
    _applyFilters(); // Re-apply all filters
  }

  /// Public method to set the category filter and trigger filtering.
  void filterByCategory(String? category) {
    // Set the category (null or empty string clears the filter)
    _selectedCategory = (category?.isEmpty ?? true) ? null : category;
    _logger.d("Category filter set to: $_selectedCategory");
    _applyFilters(); // Re-apply all filters
  }

  /// Public method to toggle the favorite filter and trigger filtering.
  void toggleFavoritesFilter(bool showOnlyFavorites) {
    _showFavoritesOnly = showOnlyFavorites;
    _logger.d("Favorites filter set to: $_showFavoritesOnly");
    _applyFilters(); // Re-apply all filters
  }

  /// Refreshes data by reloading all foods and re-applying filters.
  Future<void> refreshFoods() async {
    _logger.d("Refreshing food data...");
    // Set query/filters to null before reload or keep them? Usually keep them.
     _searchQuery = null;
     _selectedCategory = null;
     _showFavoritesOnly = false;
    await loadSuggestedFoods(); // Reloads all data and applies filters
  }

  // --- Actions ---

  /// Toggles the favorite status of a food item.
  Future<void> toggleFavorite(String foodId) async {
    final indexAll = _allFoods.indexWhere((f) => f.id == foodId);
    if (indexAll == -1) {
      _logger.w(
        "Attempted to toggle favorite for non-existent food ID: $foodId",
      );
      _setError("Could not find the food item to update.");
      notifyListeners(); // Notify UI about the error
      return;
    }

    final originalFood = _allFoods[indexAll];
    // Optimistic UI update: Toggle locally first
    final optimisticallyUpdatedFood = originalFood.copyWith(
      isFavorite: !originalFood.isFavorite,
    );
    _allFoods[indexAll] = optimisticallyUpdatedFood;

    // Also update the filtered list if the item is present there
    final indexFiltered = _filteredFoods.indexWhere((f) => f.id == foodId);
    if (indexFiltered != -1) {
      _filteredFoods[indexFiltered] = optimisticallyUpdatedFood;
    }
    // If filtering by favorites, re-apply filters after toggling
    if (_showFavoritesOnly) {
      _applyFilters();
    } else {
      notifyListeners(); // Notify UI immediately of optimistic change
    }

    _setError(null); // Clear previous errors specifically for this action

    try {
      _logger.d("Toggling favorite for food ID: $foodId");
      // Call UseCase to persist the change (UseCase should handle DB interaction)
      // The UseCase *might* return the truly updated model, but it's not strictly necessary
      // if we trust the optimistic update or if the repo/DB handles the toggle internally.
      // For this example, assume toggleFavorite persists the change based on the passed object.
      await _foodUseCase.toggleFavorite(
        optimisticallyUpdatedFood,
      ); // Pass the object with the desired state
      _logger.i("Favorite status updated successfully for food ID: $foodId");
    } catch (e, stackTrace) {
      _logger.e(
        "Failed to toggle favorite status for $foodId",
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to update favorite status: ${e.toString()}');

      // Revert optimistic update on failure
      _allFoods[indexAll] = originalFood; // Put original back
      if (indexFiltered != -1) {
        _filteredFoods[indexFiltered] = originalFood;
      }
      if (_showFavoritesOnly) {
        _applyFilters(); // Re-apply filters to potentially remove reverted item
      } else {
        notifyListeners(); // Notify UI of the revert
      }
    }
    // No finally block needed as loading isn't set for this specific action
  }

  // --- Getters (Less common to fetch single/favorites directly from VM, often done in UI/UseCase) ---

  /// Gets a food item by its ID from the currently loaded list.
  /// Returns null if not found.
  FoodModel? getFoodById(String id) {
    // Search in the _allFoods list for consistency
    try {
      return _allFoods.firstWhere((food) => food.id == id);
    } catch (e) {
      // Use firstWhereOrNull from collection package if imported, or handle exception
      _logger.w("getFoodById: Food with ID $id not found in loaded list.");
      return null;
    }
  }

  /// Fetches favorite foods directly using the UseCase.
  /// Note: This performs a separate fetch. Consider if filtering _allFoods is sufficient.
  Future<List<FoodModel>> getFavoriteFoods() async {
    _logger.d("Fetching favorite foods directly via UseCase...");
    // Setting loading might interfere with main list loading, use cautiously
    // _setLoading(true);
    _setError(null);
    try {
      final favorites = await _foodUseCase.getFavoriteFoods();
      _logger.i("Fetched ${favorites.length} favorite foods.");
      // _setLoading(false); // If loading was set
      return favorites;
    } catch (e, stackTrace) {
      _logger.e(
        "Failed to get favorite foods",
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Failed to get favorite foods: ${e.toString()}');
      // _setLoading(false); // If loading was set
      notifyListeners(); // Notify UI about the error
      return []; // Return empty list on error
    }
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _logger.i("Disposing SuggestedFoodViewModel.");
    super.dispose();
  }
}
