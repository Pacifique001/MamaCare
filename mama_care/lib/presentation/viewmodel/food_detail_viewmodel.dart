// lib/presentation/viewmodel/food_detail_viewmodel.dart (NEW FILE)

import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable // If using injectable
class FoodDetailViewModel extends ChangeNotifier {
  final Logger _logger;
  FoodModel? _foodItem;
  bool _isLoading = false; // In case you fetch more data later
  String? _error;

  FoodModel? get foodItem => _foodItem;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FoodDetailViewModel(this._logger);

  // Method to load the food item (if passed by ID) or set it directly
  // Option A: Set directly if FoodModel is passed as argument
  void setFoodItem(FoodModel food) {
    _logger.i("Displaying details for: ${food.name}");
    _foodItem = food;
    notifyListeners(); // Update UI immediately
  }

  // Option B: Load by ID (if only ID is passed as argument)
  // Requires FoodUseCase to have a getFoodById method
  /*
  final FoodUseCase _foodUseCase;
  FoodDetailViewModel(this._logger, this._foodUseCase); // Inject UseCase

  Future<void> loadFoodById(String foodId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
       _foodItem = await _foodUseCase.getFoodById(foodId); // Assuming this method exists
       if (_foodItem == null) {
          _error = "Food item not found.";
       }
    } catch (e, s) {
       _logger.e("Error loading food item $foodId", error: e, stackTrace: s);
       _error = "Could not load food details.";
    } finally {
       _isLoading = false;
       notifyListeners();
    }
  }
  */

  // Add other methods if needed (e.g., toggle favorite *on this screen*)
}
