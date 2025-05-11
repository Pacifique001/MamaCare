// lib/presentation/view/nurse_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for network images
//import 'package:mama_care/domain/entities/patient_summary.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
//import 'package:mama_care/utils/asset_helper.dart'; // For fallback avatar
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/presentation/viewmodel/nurse_dashboard_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel
import 'package:mama_care/presentation/widgets/patient_summary_card.dart';
import 'package:mama_care/presentation/widgets/appointment_card.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:sizer/sizer.dart'; // Import Sizer

class NurseDashboardView extends StatefulWidget {
  const NurseDashboardView({super.key});

  @override
  State<NurseDashboardView> createState() => _NurseDashboardViewState();
}

class _NurseDashboardViewState extends State<NurseDashboardView> {
  final Logger _logger = locator<Logger>();
  int _drawerIndex = 0; // To highlight the current screen (Dashboard)

  Future<void> _handleRefresh() async {
    if (mounted) {
      _logger.d("NurseDashboardView: Refresh triggered.");
      await context.read<NurseDashboardViewModel>().refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consume both ViewModels
    return Consumer2<NurseDashboardViewModel, AuthViewModel>(
      builder: (context, nurseViewModel, authViewModel, child) {
        final nurseName =
            nurseViewModel.nurseProfile?.name.split(' ').first ?? "Nurse";

        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Welcome, $nurseName!",
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Refresh Data",
                onPressed: nurseViewModel.isLoading ? null : _handleRefresh,
              ),
              // Removed profile icon from AppBar as it's now in the Drawer
            ],
          ),
          // Add the drawer
          drawer: _buildDrawer(context, nurseViewModel, authViewModel),
          body: _buildBody(context, nurseViewModel),
        );
      },
    );
  }

  // Method to build the Navigation Drawer
  Widget _buildDrawer(
    BuildContext context,
    NurseDashboardViewModel nurseViewModel,
    AuthViewModel authViewModel,
  ) {
    final nurseUser = nurseViewModel.nurseProfile; // Get nurse profile from VM
    final userName = nurseUser?.name ?? "Nurse";
    final userEmail = nurseUser?.email ?? "";
    final userPhotoUrl = nurseUser?.profileImageUrl;

    // Define drawer items based on nurse permissions/features
    // Index helps manage selection state
    final List<_DrawerItemData> drawerItems = [
      _DrawerItemData(
        index: 0,
        icon: Icons.dashboard_outlined,
        label: "Dashboard",
      ), // Current screen
      _DrawerItemData(
        index: 1,
        icon: Icons.person_outline,
        label: "My Profile",
        route: NavigationRoutes.profile,
      ),
      _DrawerItemData(
        index: 2,
        icon: Icons.groups_outlined,
        label: "Assigned Patients",
      ), // Action handled below
      _DrawerItemData(
        index: 3,
        icon: Icons.calendar_month_outlined,
        label: "My Schedule",
        route: NavigationRoutes.nurseSchedule,
      ), // TODO: Define this route
      _DrawerItemData(
        index: 4,
        icon: Icons.article_outlined,
        label: "View Articles",
        route: NavigationRoutes.articleList,
      ),
      _DrawerItemData(
        index: 5,
        icon: Icons.video_library_outlined,
        label: "View Videos",
        route: NavigationRoutes.video_list,
      ),
      // Add more items like "Edit Patient Notes" maybe linked to patient list?
      _DrawerItemData(
        index: 6,
        icon: Icons.logout,
        label: "Logout",
        route: NavigationRoutes.login,
      ),
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: TextStyles.titleWhite),
            accountEmail: Text(userEmail, style: TextStyles.bodyWhite),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent.withOpacity(0.8),
              backgroundImage:
                  (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                      ? CachedNetworkImageProvider(userPhotoUrl)
                      : null,
              child:
                  (userPhotoUrl == null || userPhotoUrl.isEmpty)
                      ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'N',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          // Generate list tiles from drawerItems data
          ...drawerItems.map((item) {
            bool isSelected = _drawerIndex == item.index;
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedTileColor: AppColors.primaryLight.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context); // Close drawer

                if (item.label == "Logout") {
                  _logger.i("Logout tapped from nurse drawer.");
                  final authVM =
                      context.read<AuthViewModel>(); // Get VM instance
                  // Perform logout first
                  authVM
                      .logout()
                      .then((_) {
                        // THEN navigate after logout completes (or even without waiting)
                        // Ensure context is still valid if logout is slow
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            NavigationRoutes.login, // Navigate to login
                            (Route<dynamic> route) =>
                                false, // Remove all previous routes
                          );
                        }
                      })
                      .catchError((error) {
                        // Handle potential errors during logout if needed
                        _logger.e("Error during logout process: $error");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Logout failed: $error"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                } else if (item.label == "Assigned Patients") {
                  // Already on the main view, just ensure drawer index is reset if needed
                  if (_drawerIndex != 0) {
                    setState(() => _drawerIndex = 0);
                  }
                  _logger.i("Assigned Patients tapped - staying on dashboard.");
                } else if (item.route != null) {
                  // Navigate if route is defined and index changes
                  if (_drawerIndex != item.index) {
                    setState(
                      () => _drawerIndex = item.index,
                    ); // Update selection visually (optional if navigating away)
                    _logger.i("Navigating to ${item.route} from nurse drawer.");
                    Navigator.pushNamed(context, item.route!);
                  }
                } else if (_drawerIndex != item.index) {
                  // Handle items without routes but need index change (like Dashboard itself)
                  setState(() => _drawerIndex = item.index);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NurseDashboardViewModel viewModel) {
    // Show central loading indicator only on initial load
    if (viewModel.isLoading && viewModel.nurseProfile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Show central error message if initial load failed critically
    if (viewModel.error != null && viewModel.nurseProfile == null) {
      return _buildErrorWidget(context, viewModel.error!, _handleRefresh);
    }

    // Build the main layout with RefreshIndicator
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Optional: Display non-critical errors as a banner
          if (viewModel.error != null && viewModel.nurseProfile != null)
            _buildErrorBanner(context, viewModel),

          // Section 1: Assigned Patients
          _buildSectionHeader(
            context,
            "Assigned Patients",
            Icons.people_alt_outlined,
          ),
          _buildAssignedPatientsList(context, viewModel),
          const SizedBox(height: 24),

          // Section 2: Upcoming Appointments/Tasks for Nurse
          _buildSectionHeader(
            context,
            "Your Schedule",
            Icons.calendar_today_outlined,
          ),
          _buildUpcomingAppointmentsList(context, viewModel),
          const SizedBox(height: 24),

          // Add other sections as needed
        ],
      ),
    );
  }

  // Helper for building section headers
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyles.title),
        ],
      ),
    );
  }

  // Builds the assigned patients list view
  Widget _buildAssignedPatientsList(
    BuildContext context,
    NurseDashboardViewModel viewModel,
  ) {
    final patients = viewModel.assignedPatients;

    if (viewModel.isLoading &&
        viewModel.nurseProfile != null &&
        patients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!viewModel.isLoading && patients.isEmpty) {
      return _buildEmptyListPlaceholder("No patients currently assigned.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patientSummary = patients[index];
        // Ensure PatientSummaryCard widget is implemented
        return PatientSummaryCard(
          patient: patientSummary,
          onTap: () {
            _logger.i("Tapped patient summary: ${patientSummary.id}");
            // TODO: Implement navigation to nurse-specific patient detail view
            // Example: Navigator.pushNamed(context, NavigationRoutes.nursePatientDetail, arguments: patientSummary.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Patient detail view not implemented yet."),
              ),
            );
          },
        );
      },
    );
  }

  // Builds the upcoming appointments list view for the nurse
  Widget _buildUpcomingAppointmentsList(
    BuildContext context,
    NurseDashboardViewModel viewModel,
  ) {
    final appointments = viewModel.upcomingAppointments;

    if (viewModel.isLoading &&
        viewModel.nurseProfile != null &&
        appointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!viewModel.isLoading && appointments.isEmpty) {
      return _buildEmptyListPlaceholder("No upcoming appointments assigned.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: AppointmentCard(
            appointment: appointment,
            userRole: UserRole.nurse,
            currentUserId: viewModel.nurseProfile?.id ?? '', // Safely access ID
            onTap: () {
              _logger.i("Tapped appointment: ${appointment.id}");
              // TODO: Implement navigation to nurse-specific appointment detail view
              // Navigator.pushNamed(context, NavigationRoutes.nurseAppointmentDetail, arguments: appointment.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Appointment detail view not implemented yet."),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Placeholder for empty lists
  Widget _buildEmptyListPlaceholder(String message) {
    return Card(
      elevation: 0,
      color: AppColors.background.withOpacity(0.5), // Use background color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Text(
          message,
          style: TextStyles.bodyGrey,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Widget to display critical loading errors
  Widget _buildErrorWidget(
    BuildContext context,
    String errorMsg,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              "Error Loading Dashboard",
              style: TextStyles.title.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              style: TextStyles.bodyGrey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display non-critical errors as a banner
  Widget _buildErrorBanner(
    BuildContext context,
    NurseDashboardViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: MaterialBanner(
        padding: const EdgeInsets.all(10),
        content: Text(
          viewModel.error!,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade800, // Use a warning color
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        actions: [
          TextButton(
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
            // Call clearError method in the ViewModel
            onPressed:
                () => context.read<NurseDashboardViewModel>().clearError(),
          ),
        ],
      ),
    );
  }
}

// Helper data class for Drawer items
class _DrawerItemData {
  final int index;
  final IconData icon;
  final String label;
  final String? route; // Nullable for action items like Logout/Dashboard link
  const _DrawerItemData({
    required this.index,
    required this.icon,
    required this.label,
    this.route,
  });
}
