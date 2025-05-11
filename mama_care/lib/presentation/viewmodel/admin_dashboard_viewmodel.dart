// lib/presentation/viewmodel/admin_dashboard_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/domain/usecases/admin_usecase.dart';

@injectable
class AdminDashboardViewModel extends ChangeNotifier {
  final AdminUseCase _adminUseCase;
  final Logger _logger;

  AdminDashboardViewModel(this._adminUseCase, this._logger) {
    _logger.i("AdminDashboardViewModel initialized.");
    // Load initial data for the dashboard
    loadInitialAdminData();
  }

  // --- State ---
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _systemStats = {};
  List<UserModel> _users = []; // Example state for user list
  // Add state for pending content, etc.

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get systemStats => _systemStats;
  List<UserModel> get users => List.unmodifiable(_users);

  // --- Private State Setters ---
  void _setLoading(bool value) { if (_isLoading == value) return; _isLoading = value; notifyListeners(); }
  void _setError(String? message) { if (_error == message) return; _error = message; if (message != null) _logger.e("AdminDashboardVM Error: $message"); notifyListeners(); }
  void _clearError() => _setError(null);

  // --- Data Loading ---
  Future<void> loadInitialAdminData() async {
    _logger.i("VM: Loading initial admin data...");
    _setLoading(true);
    _clearError();
    try {
      // Fetch multiple data points concurrently
      final results = await Future.wait([
          _adminUseCase.getSystemStats(),
          _adminUseCase.getUsers(), // Load initial user list
          // Add other initial fetches (e.g., pending content)
      ]);

      _systemStats = results[0] as Map<String, dynamic>? ?? {};
      _users = results[1] as List<UserModel>? ?? [];
       _logger.i("VM: Initial admin data loaded. Stats: $_systemStats, Users: ${_users.length}");

    } catch (e, s) {
       _logger.e("VM: Failed to load initial admin data", error: e, stackTrace: s);
       _setError(e is AppException ? e.message : "Failed to load dashboard data.");
       _systemStats = {}; // Clear state on error
       _users = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshData() async {
     await loadInitialAdminData(); // Simple refresh reloads all
  }

  Future<void> fetchUsers({UserRole? filterByRole, String? searchQuery}) async {
      _logger.d("VM: Fetching users with filter: $filterByRole, search: $searchQuery");
      _setLoading(true); // Indicate loading for user list specifically?
      _clearError();
       try {
          _users = await _adminUseCase.getUsers(filterByRole: filterByRole, searchQuery: searchQuery);
           _logger.i("VM: Fetched ${_users.length} users.");
       } catch (e, s) {
           _logger.e("VM: Failed to fetch/filter users", error: e, stackTrace: s);
           _setError(e is AppException ? e.message : "Could not load user list.");
           _users = []; // Clear list on error
       } finally {
          _setLoading(false);
       }
  }


  // --- Admin Actions ---
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
     _logger.i("VM: Requesting role update for $userId to ${newRole.name}");
     _setLoading(true); _clearError();
     try {
        await _adminUseCase.updateUserRole(userId, newRole);
         _logger.i("VM: Role update successful for $userId.");
         // Refresh user list to show the change
         await fetchUsers(); // Reload the user list
         return true;
     } catch(e, s) {
         _logger.e("VM: Failed to update role for $userId", error: e, stackTrace: s);
          _setError(e is AppException ? e.message : "Failed to update role.");
          _setLoading(false); // Stop loading on error
         return false;
     }
     // Loading state handled by fetchUsers call or error
  }

   Future<bool> updateUserPermissions(String userId, List<String> newPermissions) async {
      _logger.i("VM: Requesting permission update for $userId");
      _setLoading(true); _clearError();
      try {
         await _adminUseCase.updateUserPermissions(userId, newPermissions);
          _logger.i("VM: Permissions update successful for $userId.");
          // Refresh user list or specific user details if needed
          await fetchUsers();
         return true;
      } catch(e, s) {
          _logger.e("VM: Failed to update permissions for $userId", error: e, stackTrace: s);
           _setError(e is AppException ? e.message : "Failed to update permissions.");
           _setLoading(false);
          return false;
      }
   }

  // Add methods for content approval, etc.
}