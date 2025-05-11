import 'package:mama_care/domain/entities/food_model.dart';
import 'package:injectable/injectable.dart';

@factoryMethod
abstract class FoodRepository {
  Future<List<FoodModel>> getSuggestedFoods();
  Future<List<FoodModel>> searchFoods(String query);
  Future<FoodModel> toggleFavorite(FoodModel food);
  Future<List<FoodModel>> getFavoriteFoods();
} 