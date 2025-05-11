// lib/data/repositories/admin_repository.dart

import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // To fetch user lists
import 'package:mama_care/domain/entities/user_role.dart'; // For role filtering/updating

/// Interface for administrative data operations.
@factoryMethod
abstract class AdminRepository {

  /// Fetches a list of users, potentially filtered by role or search query.
  Future<List<UserModel>> getUsers({UserRole? filterByRole, String? searchQuery});

  /// Updates the role for a specific user.
  Future<void> updateUserRole(String userId, UserRole newRole);

  /// Updates the permissions for a specific user.
  Future<void> updateUserPermissions(String userId, List<String> newPermissions);

  /// Fetches system statistics (e.g., user counts, content counts).
  Future<Map<String, dynamic>> getSystemStats(); // Example return type

  /// Fetches content (e.g., articles, videos) awaiting approval.
  // Future<List<ContentNeedingApproval>> getContentForApproval(); // Example

  /// Approves or rejects content.
  // Future<void> updateContentStatus(String contentId, bool approved); // Example

  // Add other admin-specific data operations...
}


