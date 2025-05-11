// lib/data/repositories/admin_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/data/repositories/admin_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/domain/entities/user_role.dart';
// For permission encoding if needed by UserModel

@Injectable(as: AdminRepository)
class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  late final CollectionReference _usersCollection = _firestore.collection('users');
  // Add references to other collections if needed (e.g., 'articles_pending')

  AdminRepositoryImpl(this._firestore, this._logger);

  @override
  Future<List<UserModel>> getUsers({UserRole? filterByRole, String? searchQuery}) async {
    _logger.d("Repo: Fetching users. Role Filter: ${filterByRole?.name}, Search: '$searchQuery'");
    try {
      Query query = _usersCollection;

      // Apply role filter
      if (filterByRole != null && filterByRole != UserRole.unknown) {
        query = query.where('role', isEqualTo: userRoleToString(filterByRole));
      }

      // Apply search filter (simple prefix match on name or email for example)
      // For robust search, consider Firestore extensions or a dedicated search service.
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          String endSearch = '${searchQuery.trim()}\uf8ff'; // Firestore prefix search trick
          query = query.where('name_lowercase', isGreaterThanOrEqualTo: searchQuery.trim().toLowerCase())
                       .where('name_lowercase', isLessThan: endSearch);
          // Requires a 'name_lowercase' field in Firestore documents
          // Alternatively search email: .where('email', isGreaterThanOrEqualTo: searchQuery.trim().toLowerCase())...
          _logger.d("Applying search filter: $searchQuery");
      }

      query = query.orderBy('name').limit(50); // Add ordering and limit

      final snapshot = await query.get();
      final users = snapshot.docs.map((doc) => UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>, // Cast needed
          'id': doc.id // Ensure ID is included
      })).toList();

      _logger.i("Repo: Fetched ${users.length} users.");
      return users;

    } on FirebaseException catch (e, s) {
      _logger.e("Repo: Firestore error fetching users", error: e, stackTrace: s);
      throw ApiException("Error loading user list.", statusCode: e.code.hashCode, cause: e);
    } catch (e, s) {
      _logger.e("Repo: Unexpected error fetching users", error: e, stackTrace: s);
      throw DataProcessingException("Could not process user list.", cause: e);
    }
  }

  @override
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    _logger.i("Repo: Updating role for user $userId to ${newRole.name}");
     if (userId.isEmpty) throw ArgumentError("User ID cannot be empty.");
    try {
      await _usersCollection.doc(userId).update({
        'role': userRoleToString(newRole),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
       _logger.i("Repo: Role updated successfully for user $userId.");
    } on FirebaseException catch (e, s) {
        _logger.e("Repo: Firestore error updating role for $userId", error: e, stackTrace: s);
        // Handle specific errors like 'not-found' if needed
        throw ApiException("Failed to update user role.", statusCode: e.code.hashCode, cause: e);
    } catch (e, s) {
         _logger.e("Repo: Unexpected error updating role for $userId", error: e, stackTrace: s);
        throw DataProcessingException("Could not update user role.", cause: e);
    }
  }

  @override
  Future<void> updateUserPermissions(String userId, List<String> newPermissions) async {
     _logger.i("Repo: Updating permissions for user $userId");
      if (userId.isEmpty) throw ArgumentError("User ID cannot be empty.");
    try {
      // Store permissions as an array in Firestore
      await _usersCollection.doc(userId).update({
        'permissions': newPermissions,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
       _logger.i("Repo: Permissions updated successfully for user $userId.");
    } on FirebaseException catch (e, s) {
        _logger.e("Repo: Firestore error updating permissions for $userId", error: e, stackTrace: s);
        throw ApiException("Failed to update user permissions.", statusCode: e.code.hashCode, cause: e);
    } catch (e, s) {
         _logger.e("Repo: Unexpected error updating permissions for $userId", error: e, stackTrace: s);
        throw DataProcessingException("Could not update user permissions.", cause: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemStats() async {
    _logger.d("Repo: Fetching system stats...");
    try {
      // Example: Use Firestore aggregate queries (requires server-side implementation or careful client-side counts)
      // This is often better done via a backend Cloud Function for efficiency and security.
      final userCount = await _usersCollection.count().get();
      // final articleCount = await _firestore.collection('articles').count().get();
      // final videoCount = await _firestore.collection('app_videos').count().get();

       _logger.i("Repo: Fetched system stats.");
      return {
        'totalUsers': userCount.count,
        'patientCount': null, // TODO: Add query for specific roles if needed
        'nurseCount': null,
        'doctorCount': null,
        // 'totalArticles': articleCount.count,
        // 'totalVideos': videoCount.count,
      };
    } on FirebaseException catch (e, s) {
        _logger.e("Repo: Firestore error fetching system stats", error: e, stackTrace: s);
        throw ApiException("Error loading system statistics.", statusCode: e.code.hashCode, cause: e);
    } catch (e, s) {
         _logger.e("Repo: Unexpected error fetching system stats", error: e, stackTrace: s);
         throw DataProcessingException("Could not process system statistics.", cause: e);
    }
  }
}