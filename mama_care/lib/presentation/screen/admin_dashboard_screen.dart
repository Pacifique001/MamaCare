// lib/presentation/screen/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // Locator
import 'package:mama_care/presentation/screen/doctor_dashboard_screen.dart';
import 'package:mama_care/presentation/viewmodel/admin_dashboard_viewmodel.dart'; // ViewModel
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // User entity for list
import 'package:mama_care/domain/entities/user_role.dart'; // Role enum
import 'package:provider/provider.dart';
// For potential navigation
import 'package:mama_care/presentation/widgets/user_list_card.dart'; // TODO: Create this widget

// Screen Wrapper
class AdminDashboardScreenWrapper extends StatelessWidget {
  const AdminDashboardScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<AdminDashboardViewModel>(), // Provide VM
      child: const AdminDashboardScreen(),
    );
  }
}

// Screen Content
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Admin Dashboard",
             actions: [
                IconButton(
                   icon: const Icon(Icons.refresh),
                   tooltip: "Refresh Data",
                   onPressed: viewModel.isLoading ? null : viewModel.refreshData,
                ),
             ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminDashboardViewModel viewModel) {
    if (viewModel.isLoading && viewModel.users.isEmpty) { // Initial load
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

     if (viewModel.error != null && viewModel.users.isEmpty) { // Initial error
       return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                SizedBox(height: 16),
                Text("Error Loading Data", style: TextStyles.title.copyWith(color: Colors.redAccent)),
                SizedBox(height: 8),
                Text(viewModel.error!, style: TextStyles.bodyGrey, textAlign: TextAlign.center),
                SizedBox(height: 20),
                ElevatedButton( onPressed: viewModel.refreshData, child: const Text("Retry") )
              ],
            ),
          ),
       );
     }

    // --- Main Admin Content ---
    return RefreshIndicator(
       onRefresh: viewModel.refreshData,
       color: AppColors.primary,
       child: ListView( // Use ListView for different sections
          padding: const EdgeInsets.all(16.0),
          children: [
             // Section 1: System Stats (Example)
             _buildStatsSection(context, viewModel),
             const SizedBox(height: 24),

              // Section 2: User Management Header + List
             _buildSectionHeader(context, "User Management", Icons.manage_accounts_outlined),
             // TODO: Add User Filter/Search controls here
             _buildUserList(context, viewModel),
             const SizedBox(height: 24),

              // Section 3: Content Moderation (Placeholder)
              _buildSectionHeader(context, "Content Approval", Icons.rate_review_outlined),
               Card( elevation: 0, color: Colors.grey.shade100, child: Padding( padding: const EdgeInsets.all(20.0), child: Text("Content moderation queue will appear here.", style: TextStyles.bodyGrey, textAlign: TextAlign.center), ), ),
              const SizedBox(height: 24),

          ],
       ),
    );
  }

   // Helper for section headers
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
       child: Row(
         children: [
           Icon(icon, color: AppColors.primary, size: 22),
           const SizedBox(width: 8),
           Text(title, style: TextStyles.title),
           // Add filter/search buttons here if needed
         ],
       ),
     );
  }

  // Example Stats Section
  Widget _buildStatsSection(BuildContext context, AdminDashboardViewModel viewModel) {
     final stats = viewModel.systemStats;
     return Card(
       elevation: 2,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text("System Statistics", style: TextStyles.titleCard),
              const Divider(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                    _buildStatItem(Icons.group, "Total Users", stats['totalUsers']?.toString() ?? '-'),
                    _buildStatItem(Icons.article_outlined, "Articles", stats['totalArticles']?.toString() ?? '-'), // Assumes stat exists
                    _buildStatItem(Icons.video_library_outlined, "Videos", stats['totalVideos']?.toString() ?? '-'), // Assumes stat exists
                 ],
              )
           ],
         ),
       ),
     );
  }

   Widget _buildStatItem(IconData icon, String label, String value) {
     return Column(
        children: [
           Icon(icon, size: 28, color: AppColors.primaryLight),
           const SizedBox(height: 4),
           Text(value, style: TextStyles.title.copyWith(fontSize: 16)),
           const SizedBox(height: 2),
           Text(label, style: TextStyles.smallGrey),
        ],
     );
   }


  // Builds the user list
  Widget _buildUserList(BuildContext context, AdminDashboardViewModel viewModel) {
     final users = viewModel.users;

      if (viewModel.isLoading && users.isEmpty) { // Loading state specifically for users
         return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
      }
      // Check error specific to user fetching if ViewModel provides it
      // if (viewModel.userFetchError != null) { ... }

      if (users.isEmpty) {
         return Card( elevation: 0, color: Colors.grey.shade100, child: Padding( padding: const EdgeInsets.all(20.0), child: Text("No users found matching criteria.", style: TextStyles.bodyGrey, textAlign: TextAlign.center), ), );
      }

     return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        itemBuilder: (context, index) {
           final user = users[index];
            // TODO: Create UserListCard widget
           return UserListCard(
              user: user,
              onEditRole: () => _showEditRoleDialog(context, viewModel, user),
              onEditPermissions: () => _showEditPermissionsDialog(context, viewModel, user),
              onViewDetails: () {
                 // Navigate to a generic user detail or role-specific one?
                 locator<Logger>().i("View details for user ${user.id}");
                 // Navigator.pushNamed(context, NavigationRoutes.userDetail, arguments: user.id);
              },
           );
        }
     );
  }

  // --- Placeholder Dialogs for Admin Actions ---

  void _showEditRoleDialog(BuildContext context, AdminDashboardViewModel viewModel, UserModel user) {
     UserRole selectedRole = user.role; // Pre-select current role
      final Logger logger = locator<Logger>();

     showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder( // Use StatefulBuilder for dropdown state
           builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text("Edit Role: ${user.name}"),
                content: DropdownButton<UserRole>(
                   value: selectedRole,
                   isExpanded: true,
                   items: UserRole.values.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.name.capitalize())
                   )).toList(),
                   onChanged: (value) {
                      if (value != null) {
                         setStateDialog(() { selectedRole = value; }); // Update dialog state
                      }
                   },
                ),
                actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                   TextButton(
                      onPressed: () async {
                         Navigator.pop(ctx); // Close dialog first
                         logger.i("Updating role for ${user.id} to ${selectedRole.name}");
                         bool success = await viewModel.updateUserRole(user.id, selectedRole);
                         // Show snackbar feedback in the main screen context
                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                               content: Text(success ? "Role updated successfully." : viewModel.error ?? "Failed to update role."),
                               backgroundColor: success ? Colors.green : Colors.redAccent,
                            ));
                         }
                      },
                      child: const Text("Save Role")
                   ),
                ],
              );
           }
        ),
     );
  }

  void _showEditPermissionsDialog(BuildContext context, AdminDashboardViewModel viewModel, UserModel user) {
      final Logger logger = locator<Logger>();
      // Need a way to manage selected permissions state within the dialog
      List<String> currentPermissions = List.from(user.permissions); // Copy list

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
           builder: (context, setStateDialog) {
              // TODO: Build a more sophisticated UI for permission selection (e.g., checkboxes in a list)
              return AlertDialog(
                title: Text("Edit Permissions: ${user.name}"),
                content: SingleChildScrollView( // Allow scrolling if many perms
                   child: Text("Current Permissions:\n${currentPermissions.join(', ')}\n\n(Implement permission selection UI here)"),
                ),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                   TextButton(
                      onPressed: () async {
                          Navigator.pop(ctx);
                          logger.i("Updating permissions for ${user.id}");
                          // Pass the MODIFIED currentPermissions list from the UI state
                          bool success = await viewModel.updateUserPermissions(user.id, currentPermissions);
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success ? "Permissions updated." : viewModel.error ?? "Failed to update permissions."),
                                backgroundColor: success ? Colors.green : Colors.redAccent,
                             ));
                          }
                      },
                      child: const Text("Save Permissions")
                   ),
                 ],
              );
           }
        )
      );
  }

}
