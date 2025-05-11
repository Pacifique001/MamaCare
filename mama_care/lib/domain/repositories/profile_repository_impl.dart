// lib/domain/repositories/profile_repository_impl.dart (Rename file?)

import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/profile_repository.dart';
// Removed UserModel import
import 'package:mama_care/data/local/database_helper.dart';
// Removed FirebaseMessaging import
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/core/error/exceptions.dart';
import 'package:sqflite/sqflite.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseHelper _databaseHelper;
  final Logger _logger;
  static const String _pdTable = 'pregnancy_details';

  ProfileRepositoryImpl(this._databaseHelper, this._logger){
     _logger.i("ProfileRepositoryImpl (Pregnancy Focus) initialized.");
  }

  @override
  Future<PregnancyDetails?> getPregnancyDetails(String userId) async { // Accept userId
     _logger.d("Repository: Getting pregnancy details for user $userId from DB.");
    if (userId.isEmpty) {
        _logger.w("Cannot get pregnancy details, userId is empty.");
        return null;
    }
    try {
      final db = await _databaseHelper.database;
      // Query specifically for the user's details
      final results = await db.query(
          _pdTable,
          where: 'userId = ?', // Filter by userId
          whereArgs: [userId],
          limit: 1 // Expect only one record per user
      );
      if (results.isNotEmpty) {
        _logger.i("Repository: Found pregnancy details for user $userId.");
        return PregnancyDetails.fromJson(results.first); // Use correct fromJson
      }
      _logger.w("Repository: No pregnancy details found for user $userId.");
      return null;
    } catch (e, s) {
       _logger.e("Repository: Failed to fetch pregnancy details for user $userId", error: e, stackTrace: s);
      throw ('Failed to fetch pregnancy details: ${e.toString()}', cause: e);
    }
  }

  @override
  Future<void> savePregnancyDetails(PregnancyDetails details) async {
     _logger.d("Repository: Saving/Updating pregnancy details for user ${details.userId}.");
    if(details.userId == null || details.userId!.isEmpty) {
        _logger.e("Cannot save pregnancy details: userId is missing from details object.");
        throw ArgumentError("User ID is required to save pregnancy details.");
    }
    try {
      final db = await _databaseHelper.database;
      // Use upsert logic (insert or replace)
      await db.insert(
          _pdTable,
          details.toJson(), // Use correct toJson
          conflictAlgorithm: ConflictAlgorithm.replace // Replace existing entry for the user
      );
       _logger.i("Repository: Saved/Updated pregnancy details for user ${details.userId}.");
    } catch (e, s) {
       _logger.e("Repository: Failed to save pregnancy details for user ${details.userId}", error: e, stackTrace: s);
      throw ('Failed to save pregnancy details: ${e.toString()}', cause: e);
    }
  }

   @override
   Future<void> deletePregnancyDetails(String userId) async {
      _logger.d("Repository: Deleting pregnancy details for user $userId.");
     if (userId.isEmpty) {
         _logger.w("Cannot delete pregnancy details, userId is empty.");
         return;
     }
     try {
       final db = await _databaseHelper.database;
       final count = await db.delete(
         _pdTable,
         where: 'userId = ?',
         whereArgs: [userId],
       );
        _logger.i("Repository: Deleted $count pregnancy detail records for user $userId.");
     } catch (e, s) {
        _logger.e("Repository: Failed to delete pregnancy details for user $userId", error: e, stackTrace: s);
       throw ('Failed to delete pregnancy details: ${e.toString()}', cause: e);
     }
   }
}