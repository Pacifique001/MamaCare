// lib/domain/usecases/admin_usecase.dart

import 'package:firebase_auth/firebase_auth.dart'; // To check admin permissions
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/admin_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/domain/entities/user_role.dart';

import '../../core/error/exceptions.dart';

@injectable
class AdminUseCase {
  final AdminRepository _repository;
  final FirebaseAuth _auth; // To potentially verify admin identity if needed
  final Logger _logger;

  AdminUseCase(this._repository, this._auth, this._logger);

  // Example permission check helper (logic might be more complex)
  Future<bool> _isAdmin() async {
     // In a real app, verify the *logged-in user's* role/permissions,
     // perhaps fetched via AuthViewModel or another UserRepository call.
     // This is a simplified placeholder.
     final currentUser = _auth.currentUser;
     if (currentUser == null) return false;
     // Assume role is fetched elsewhere or stored in custom claims (more secure)
     // For now, just check if email matches a known admin (INSECURE, FOR EXAMPLE ONLY)
     // return currentUser.email == 'admin@mamacare.com';
     _logger.w("Admin permission check is using placeholder logic!");
     return true; // Placeholder: Assume user is admin if they reach here
  }


  Future<List<UserModel>> getUsers({UserRole? filterByRole, String? searchQuery}) async {
    _logger.d("UseCase: Getting users...");
    // Optional: Add permission check
    // if (!await _isAdmin()) throw AuthException("Admin privileges required.");
    try {
      return await _repository.getUsers(filterByRole: filterByRole, searchQuery: searchQuery);
    } catch (e) { rethrow; }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
     _logger.i("UseCase: Updating role for $userId to ${newRole.name}");
      // Optional: Add permission check
     // if (!await _isAdmin()) throw AuthException("Admin privileges required.");
     if (userId.isEmpty || newRole == UserRole.unknown) throw ArgumentError("Valid User ID and Role required.");
     // Add business logic: e.g., prevent self-role change? Prevent making everyone admin?
      try {
         await _repository.updateUserRole(userId, newRole);
      } catch (e) { rethrow; }
  }

   Future<void> updateUserPermissions(String userId, List<String> newPermissions) async {
      _logger.i("UseCase: Updating permissions for $userId");
       // Optional: Add permission check
      // if (!await _isAdmin()) throw AuthException("Admin privileges required.");
       if (userId.isEmpty) throw ArgumentError("User ID required.");
       // Optional: Validate permissions against a known list?
      try {
          await _repository.updateUserPermissions(userId, newPermissions);
      } catch (e) { rethrow; }
   }


  Future<Map<String, dynamic>> getSystemStats() async {
      _logger.d("UseCase: Getting system stats...");
       // Optional: Add permission check
       if (!await _isAdmin()) throw AuthException("Admin privileges required.");
       try {
          return await _repository.getSystemStats();
       } catch (e) { rethrow; }
  }

  // Add UseCase methods for content approval etc. if needed
}