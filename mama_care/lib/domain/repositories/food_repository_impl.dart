// lib/data/repositories/food_repository_impl.dart

import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:mama_care/data/repositories/food_repository.dart';
//import 'package:mama_care/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
//import 'package:sqflite/sqflite.dart';

@Injectable(as: FoodRepository)
class FoodRepositoryImpl implements FoodRepository {
  final DatabaseHelper _databaseHelper;
  final Logger _logger;

  static const String _tableName = 'foods';

  FoodRepositoryImpl(this._databaseHelper, this._logger) {
    _logger.i("FoodRepositoryImpl initialized.");
  }

  @override
  Future<List<FoodModel>> getSuggestedFoods() async {
    _logger.d("Repository: Getting all foods from local DB.");
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'name ASC',
      );

      final foods =
          List.generate(maps.length, (i) {
            try {
              return FoodModel.fromMap(maps[i]);
            } catch (e, s) {
              // --- CORRECTED LOGGING ---
              _logger.e(
                "Repository: Error parsing food map at index $i. Data: ${maps[i]}", // Include map in message
                error: e, // Pass error object
                stackTrace: s, // Pass stack trace
              );
              // -------------------------
              return null;
            }
          }).whereType<FoodModel>().toList();

      _logger.i("Repository: Fetched ${foods.length} foods from local DB.");
      return foods;
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to get suggested foods from DB",
        error: e,
        stackTrace: stackTrace,
      ); // Pass error and stackTrace
      throw ("Could not fetch food list from database.", cause: e);
    }
  }

  @override
  Future<List<FoodModel>> searchFoods(String query) async {
    _logger.d("Repository: Searching foods in local DB for query: '$query'");
    if (query.trim().isEmpty) {
      return getSuggestedFoods();
    }

    final queryLower = '%${query.toLowerCase().trim()}%';

    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '''
          LOWER(name) LIKE ? OR
          LOWER(description) LIKE ? OR
          LOWER(category) LIKE ? OR
          LOWER(benefitsJson) LIKE ?
        ''',
        whereArgs: [queryLower, queryLower, queryLower, queryLower],
        orderBy: 'name ASC',
      );

      final foods =
          List.generate(maps.length, (i) {
            try {
              return FoodModel.fromMap(maps[i]);
            } catch (e, s) {
              // --- CORRECTED LOGGING ---
              _logger.e(
                "Repository: Error parsing searched food map at index $i. Data: ${maps[i]}", // Include map in message
                error: e, // Pass error object
                stackTrace: s, // Pass stack trace
              );
              // -------------------------
              return null;
            }
          }).whereType<FoodModel>().toList();

      _logger.i(
        "Repository: Found ${foods.length} foods matching query '$query'.",
      );
      return foods;
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to search foods in DB",
        error: e,
        stackTrace: stackTrace,
      ); // Pass error and stackTrace
      throw ("Could not perform food search in database.", cause: e);
    }
  }

  // --- toggleFavorite and getFavoriteFoods methods remain the same ---
  // (Assuming they don't use the incorrect context parameter in logger calls)
  @override
  Future<FoodModel> toggleFavorite(FoodModel food) async {
    _logger.d("Repository: Toggling favorite status for food ID: ${food.id}");
    try {
      final db = await _databaseHelper.database;
      final newFavoriteStatus = !food.isFavorite;

      final count = await db.update(
        _tableName,
        {'isFavorite': newFavoriteStatus ? 1 : 0},
        where: 'id = ?',
        whereArgs: [food.id],
      );

      if (count > 0) {
        _logger.i(
          "Repository: Updated favorite status for ${food.id} to $newFavoriteStatus.",
        );
        return food.copyWith(isFavorite: newFavoriteStatus);
      } else {
        _logger.w(
          "Repository: Food with ID ${food.id} not found during favorite toggle update.",
        );
        throw ("Food item not found for update.", itemIdentifier: food.id);
      }
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to toggle favorite status in DB for ${food.id}",
        error: e,
        stackTrace: stackTrace,
      ); // Pass error and stackTrace
      throw ("Could not update favorite status in database.", cause: e);
    }
  }

  @override
  Future<List<FoodModel>> getFavoriteFoods() async {
    _logger.d("Repository: Getting favorite foods from local DB.");
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );

      final foods =
          List.generate(maps.length, (i) {
            try {
              return FoodModel.fromMap(maps[i]);
            } catch (e, s) {
              // --- CORRECTED LOGGING ---
              _logger.e(
                "Repository: Error parsing favorite food map at index $i. Data: ${maps[i]}", // Include map in message
                error: e, // Pass error object
                stackTrace: s, // Pass stack trace
              );
              // -------------------------
              return null;
            }
          }).whereType<FoodModel>().toList();

      _logger.i(
        "Repository: Fetched ${foods.length} favorite foods from local DB.",
      );
      return foods;
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Failed to get favorite foods from DB",
        error: e,
        stackTrace: stackTrace,
      ); // Pass error and stackTrace
      throw ("Could not fetch favorite foods from database.", cause: e);
    }
  }
}
