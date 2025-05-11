// lib/presentation/view/doctor_appointments_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart';
import 'package:mama_care/navigation/router.dart'; // Ensure this contains NavigationRoutes
import 'package:mama_care/presentation/viewmodel/doctor_appointments_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming exists
import 'package:mama_care/utils/app_colors.dart'; // Assuming exists
import 'package:mama_care/utils/text_styles.dart'; // Assuming exists
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mama_care/injection.dart'; // Assuming exists

// Helper extension for capitalizing strings (if not defined elsewhere)

class DoctorAppointmentsView extends StatefulWidget {
  const DoctorAppointmentsView({super.key});

  @override
  State<DoctorAppointmentsView> createState() => _DoctorAppointmentsViewState();
}

class _DoctorAppointmentsViewState extends State<DoctorAppointmentsView> {
  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Load initial data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorAppointmentsViewModel>().loadDoctorAppointments();
      }
    });
  }

  // --- Navigation Helpers ---

  /// Navigates to a new route using pushNamed.
  /// Ensures the drawer is closed before navigating.
  /// Requires the BuildContext from *inside* the drawer/ListTile.
  void _navigateTo(BuildContext navContext, String routeName) {
    // Check if drawer is open using the context provided
    if (Scaffold.of(navContext).isDrawerOpen) {
      Navigator.pop(navContext); // Close drawer first
    }
    // Push the new route using the context from the drawer item
    Navigator.of(navContext).pushNamed(routeName);
    _logger.i("Navigating (push) to: $routeName");
  }

  /// Navigates to the login screen and removes all previous routes.
  /// Ensures the drawer is closed before navigating.
  /// Requires the BuildContext from *inside* the drawer/ListTile.
  void _navigateToLoginAndClearStack(BuildContext navContext) {
    if (Scaffold.of(navContext).isDrawerOpen) {
      Navigator.pop(navContext); // Close drawer first
    }
    // Use pushNamedAndRemoveUntil with the context from the drawer item
    Navigator.of(navContext).pushNamedAndRemoveUntil(
      NavigationRoutes.login,
      (route) => false, // Remove all previous routes
    );
    _logger.i("Navigating to Login and clearing stack.");
  }

  @override
  Widget build(BuildContext context) {
    // Get ViewModels using Provider.watch or context.watch for reactive UI
    final authViewModel = context.watch<AuthViewModel>();
    // Note: appointmentsViewModel is consumed lower down where needed

    return Scaffold(
      // The Scaffold that provides the context
      appBar: const MamaCareAppBar(title: "Manage Appointments"),
      // Pass only the necessary ViewModel to the drawer builder
      drawer: _buildDrawer(authViewModel),
      body: Consumer<DoctorAppointmentsViewModel>(
        // Consume appointments VM for the body
        builder: (context, appointmentsViewModel, child) {
          return Column(
            children: [
              _buildStatusFilter(appointmentsViewModel),
              Expanded(
                child: _buildMainContent(context, appointmentsViewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the Drawer widget.
  /// Requires the AuthViewModel to display user info and permissions.
  Widget _buildDrawer(AuthViewModel authViewModel) {
    final doctorUser = authViewModel.localUser;
    final permissions = authViewModel.userPermissions;

    // Use a Builder here to ensure the context passed to onTap callbacks
    // is a descendant of the Scaffold.
    return Builder(
      builder: (drawerContext) {
        // This context can find the Scaffold
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(
                  doctorUser?.name ?? 'Doctor',
                  style: TextStyles.titleWhite,
                ),
                accountEmail: Text(
                  doctorUser?.email ?? '',
                  style: TextStyles.bodyWhite.copyWith(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.accent.withOpacity(0.8),
                  backgroundImage:
                      (doctorUser?.profileImageUrl != null &&
                              doctorUser!.profileImageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(
                            doctorUser.profileImageUrl!,
                          )
                          : null,
                  child:
                      (doctorUser?.profileImageUrl == null ||
                              doctorUser!.profileImageUrl!.isEmpty)
                          ? Text(
                            doctorUser?.name.isNotEmpty == true
                                ? doctorUser!.name[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
                decoration: const BoxDecoration(color: AppColors.primaryDark),
              ),

              // Standard Navigation Items
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                // Use drawerContext here as it's fine for just popping the drawer itself
                onTap: () => Navigator.pop(drawerContext),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Manage Appointments'),
                selected: true,
                selectedTileColor: AppColors.primaryLight.withOpacity(0.15),
                selectedColor: AppColors.primary,
                onTap: () => Navigator.pop(drawerContext), // Pop drawer
              ),

              // Conditional Items based on Permissions
              if (permissions.contains('view_profile'))
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('My Profile'),
                  // Pass the drawerContext to _navigateTo
                  onTap:
                      () =>
                          _navigateTo(drawerContext, NavigationRoutes.profile),
                ),

              if (permissions.contains('view_all_patients'))
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('View Patients'),
                  onTap: () {
                    Navigator.pop(drawerContext); // Close drawer first
                    _logger.i("Navigate to Patient List (Placeholder)");
                    ScaffoldMessenger.of(drawerContext).showSnackBar(
                      const SnackBar(
                        content: Text("Patient list screen not implemented."),
                      ),
                    );
                  },
                ),

              if (permissions.contains('manage_nurses'))
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Manage Nurses'),
                  onTap:
                      () => _navigateTo(
                        drawerContext,
                        NavigationRoutes.nurseDetail,
                      ), // Pass context
                ),

              if (permissions.contains('view_reports'))
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('View Reports'),
                  onTap: () {
                    Navigator.pop(drawerContext); // Close drawer first
                    _logger.i("Navigate to Reports (Placeholder)");
                    ScaffoldMessenger.of(drawerContext).showSnackBar(
                      const SnackBar(
                        content: Text("Reports screen not implemented."),
                      ),
                    );
                  },
                ),

              // Content Management Section
              if (permissions.contains('edit_articles') ||
                  permissions.contains('edit_videos')) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 5.0),
                  child: Text(
                    "Content Management",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (permissions.contains('edit_articles'))
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Edit Articles'),
                    onTap:
                        () => _navigateTo(
                          drawerContext,
                          NavigationRoutes.articleList,
                        ),
                  ),
                if (permissions.contains('edit_videos'))
                  ListTile(
                    leading: const Icon(Icons.video_library_outlined),
                    title: const Text('Edit Videos'),
                    onTap:
                        () => _navigateTo(
                          drawerContext,
                          NavigationRoutes.video_list,
                        ),
                  ),
              ],

              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  () => _navigateTo(drawerContext, NavigationRoutes.editScreen);
                },
              ),
              // Logout
              ListTile(
                leading: const Icon(
                  Icons.logout_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  // Use read here because we are in a callback
                  await drawerContext.read<AuthViewModel>().logout();
                  // Use mounted check on the State object, not drawerContext
                  if (mounted) {
                    _navigateToLoginAndClearStack(
                      drawerContext,
                    ); // Pass drawerContext
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DoctorAppointmentsViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (viewModel.error != null) {
      return _buildErrorView(
        context,
        viewModel.error!,
        () => viewModel.loadDoctorAppointments(),
      );
    } else if (viewModel.appointments.isEmpty) {
      return _buildEmptyView(viewModel.selectedStatusFilter);
    } else {
      return _buildAppointmentsList(context, viewModel);
    }
  }

  Widget _buildStatusFilter(DoctorAppointmentsViewModel viewModel) {
    final List<AppointmentStatus?> statuses = [
      null,
      AppointmentStatus.pending,
      AppointmentStatus.confirmed,
      AppointmentStatus.scheduled,
      AppointmentStatus.completed,
      AppointmentStatus.cancelled,
      AppointmentStatus.declined,
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children:
              statuses.map((status) {
                final String label = status?.name.capitalize() ?? 'All';
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _filterChip(viewModel, status, label),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _filterChip(
    DoctorAppointmentsViewModel viewModel,
    AppointmentStatus? statusValue,
    String label,
  ) {
    final bool isSelected = viewModel.selectedStatusFilter == statusValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          viewModel.setStatusFilter(statusValue);
        }
      },
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primaryLight.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 11.sp,
        color: isSelected ? AppColors.primary : AppColors.textGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: AppColors.primary,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      showCheckmark: false,
      elevation: isSelected ? 1.0 : 0.0,
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 0.8.h),
    );
  }

  Widget _buildEmptyView(AppointmentStatus? status) {
    String message =
        status != null
            ? "No ${status.name} appointments"
            : "No appointments match the current filter";
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyles.bodyGrey.copyWith(fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ); // Added textAlign
  }

  Widget _buildErrorView(
    BuildContext context,
    String error,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              "Error Loading Appointments",
              style: TextStyles.title.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyles.body.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    DoctorAppointmentsViewModel viewModel,
  ) {
    final Logger logger = locator<Logger>(); // Get logger instance

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = viewModel.appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          // --- ADD onTap Handler ---
          onTap: () {
            if (appointment.id == null) {
              logger.e(
                "Cannot navigate to detail view: Appointment ID is null.",
              );
              // Show a generic error to the user
              _showErrorSnackbar(
                context,
                "Cannot view details for this appointment.",
              );
              return;
            }
            logger.i(
              "Navigating to details for appointment ID: ${appointment.id}",
            );
            // Use the Navigator to push the detail route, passing the ID
            Navigator.pushNamed(
              context,
              NavigationRoutes.appointmentDetail,
              arguments: appointment.id!, // Pass the non-null ID as argument
            );
          },
          // --- Keep Existing Action Handlers ---
          onApprove:
              appointment.status == AppointmentStatus.pending
                  ? () => _handleUpdateStatus(
                    context,
                    viewModel,
                    appointment.id!,
                    AppointmentStatus.confirmed,
                    "approved",
                  )
                  : null, // Only enable if pending
          onDecline:
              appointment.status == AppointmentStatus.pending
                  ? () => _handleUpdateStatus(
                    context,
                    viewModel,
                    appointment.id!,
                    AppointmentStatus.declined,
                    "declined",
                  )
                  : null, // Only enable if pending
          onComplete:
              appointment
                      .status
                      .canBeCompletedByDoctor // Use helper
                  ? () => _handleUpdateStatus(
                    context,
                    viewModel,
                    appointment.id!,
                    AppointmentStatus.completed,
                    "completed",
                  )
                  : null,
          onDelete:
              appointment.status.canBeDeletedByDoctor
                  ? () => _handleDeleteAppointment(
                    context,
                    viewModel,
                    appointment.id!,
                    appointment.patientName,
                  )
                  : null, // Only enable if appropriate status
        );
      },
    );
  }

  Future<void> _handleDeleteAppointment(
    BuildContext context,
    DoctorAppointmentsViewModel viewModel,
    String appointmentId,
    String? patientName, // For confirmation message
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must confirm
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to permanently delete the appointment record for ${patientName ?? 'this patient'}? This action cannot be undone.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete Permanently'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Check mounted again after async dialog
      final success = await viewModel.deleteAppointment(appointmentId);
      if (!mounted) return; // Check mounted again after async delete
      if (success) {
        _showSuccessSnackbar(context, "Appointment record deleted.");
        // List updates automatically via ViewModel's removal and notifyListeners
      } else {
        _showErrorSnackbar(
          context,
          viewModel.error ?? "Failed to delete appointment.",
        );
      }
    }
  }

  Future<void> _handleUpdateStatus(
    BuildContext context,
    DoctorAppointmentsViewModel viewModel,
    String appointmentId,
    AppointmentStatus newStatus,
    String actionVerb,
  ) async {
    final success = await viewModel.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );
    if (!mounted) return;
    if (success) {
      _showSuccessSnackbar(context, "Appointment ${actionVerb} successfully");
    } else {
      _showErrorSnackbar(
        context,
        viewModel.error ?? "Failed to $actionVerb appointment",
      );
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // <-- ADD onTap CALLBACK

  const _AppointmentCard({
    required this.appointment,
    this.onApprove,
    this.onDecline,
    this.onComplete,
    this.onTap, // <-- ADD to constructor
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime apptDateTime = appointment.dateTime.toDate();
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior:
          Clip.antiAlias, // Ensures InkWell splash stays within bounds
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(appointment.status).withOpacity(0.4),
          width: 1,
        ),
      ),
      // Wrap the Column with InkWell
      child: InkWell(
        onTap: onTap, // <-- ASSIGN the onTap callback here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Status Header ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                // Removed border radius here, handled by Card shape + ClipRRect
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(appointment.status),
                        size: 18,
                        color: _getStatusColor(appointment.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        // Use status extension for consistent display name
                        appointment.status.displayName,
                        style: TextStyles.bodyBold.copyWith(
                          color: _getStatusColor(appointment.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Details Padding ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    DateFormat('EEE, MMM dd, yyyy').format(apptDateTime),
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    Icons.access_time_outlined,
                    DateFormat('hh:mm a').format(apptDateTime),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.person_outline,
                    appointment.patientName ?? 'N/A', // Handle null name
                    label: "Patient",
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.medical_services_outlined,
                    appointment.reason,
                    label: "Reason",
                  ),
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.notes_outlined,
                      appointment.notes!,
                      label: "Notes",
                    ),
                  ],
                ],
              ),
            ),
            // --- Action Buttons ---
            // Only show actions if onTap is NOT provided (optional, maybe show both?)
            // if (onTap == null) _buildActionButtons(),
            // Or always show them:
            _buildActionButtons(), // Action buttons can still exist even if card is tappable
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String text, {
    String? label,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment:
          label != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child:
              label != null
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyles.smallGrey.copyWith(fontSize: 10.sp),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: TextStyles.body.copyWith(
                          fontWeight:
                              isBold ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    text,
                    style: TextStyles.body.copyWith(
                      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    List<Widget> buttons = [];

    // Approve/Decline for Pending
    if (appointment.status == AppointmentStatus.pending &&
        onApprove != null &&
        onDecline != null) {
      buttons.addAll([
        Expanded(
          child: OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            child: const Text("Decline"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Approve"),
          ),
        ),
      ]);
    }
    // Complete button
    else if (appointment.status.canBeCompletedByDoctor && onComplete != null) {
      buttons.add(
        Expanded(
          // Use Expanded if it's the only button in a row
          child: ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Mark as Completed"),
          ),
        ),
      );
    }
    // --- ADD DELETE BUTTON ---
    else if (appointment.status.canBeDeletedByDoctor && onDelete != null) {
      buttons.add(
        Expanded(
          // Use Expanded if it's the only button in a row
          child: TextButton.icon(
            // Use TextButton for less emphasis than ElevatedButton
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text("Delete Record"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            onPressed: onDelete,
          ),
        ),
      );
    }
    // -------------------------

    // If there are any buttons, wrap them in padding and a Row
    if (buttons.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ), // Adjust padding slightly
        child: Row(children: buttons),
      );
    }

    // If no actions apply, return minimal padding
    return const SizedBox(height: 16);
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange.shade700;
      case AppointmentStatus.confirmed:
        return Colors.blue.shade700;
      case AppointmentStatus.declined:
        return Colors.redAccent;
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.cancelled:
        return Colors.grey.shade600;
      case AppointmentStatus.scheduled:
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty_rounded;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case AppointmentStatus.declined:
        return Icons.cancel_outlined;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:
        return Icons.highlight_off_rounded;
      case AppointmentStatus.scheduled:
        return Icons.event_available_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}
