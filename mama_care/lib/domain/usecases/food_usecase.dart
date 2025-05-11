import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:mama_care/data/repositories/food_repository.dart';

@injectable
class FoodUseCase {
  final FoodRepository _repository;

  FoodUseCase(this._repository);

  Future<List<FoodModel>> getSuggestedFoods() async {
    return await _repository.getSuggestedFoods();
  }

  Future<List<FoodModel>> searchFoods(String query) async {
    return await _repository.searchFoods(query);
  }

  Future<FoodModel> toggleFavorite(FoodModel food) async {
    return await _repository.toggleFavorite(food);
  }

  Future<List<FoodModel>> getFavoriteFoods() async {
    return await _repository.getFavoriteFoods();
  }
} 