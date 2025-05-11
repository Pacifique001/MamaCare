import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import Appointment entity
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/navigation/navigation_service.dart'; // For navigation
import 'package:mama_care/navigation/router.dart'; // For route names
import 'package:mama_care/presentation/viewmodel/appointment_detail_viewmodel.dart'; // Import ViewModel
import 'package:mama_care/presentation/widgets/loading_overlay.dart'; // Assuming you have a loading overlay
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart'; // For colors if needed
import 'package:mama_care/utils/text_styles.dart'; // For text styles if needed
import 'package:provider/provider.dart'; // Import Provider
import 'package:logger/logger.dart'; // Import Logger

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  // Helper to show confirmation dialog
  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // Helper to show snackbar feedback
  void _showFeedbackSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return; // Check mounted before showing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use ChangeNotifierProvider to create/provide the ViewModel scoped to this screen
    return ChangeNotifierProvider<AppointmentDetailViewModel>(
      create:
          (_) =>
              locator<AppointmentDetailViewModel>()..fetchAppointmentDetails(
                appointmentId,
              ), // Fetch data immediately upon creation
      child: Consumer<AppointmentDetailViewModel>(
        builder: (context, viewModel, child) {
          // Use Stack to potentially show a loading overlay during actions
          return Stack(
            children: [
              Scaffold(
                appBar: MamaCareAppBar(
                  title: viewModel.appointment?.reason ?? 'Appointment Detail',
                ),
                body: _buildBody(context, viewModel),
              ),
              // Show overlay if ViewModel indicates loading (e.g., during cancellation)
              if (viewModel.isLoading)
                LoadingOverlay(message: viewModel.loadingMessage),
            ],
          );
        },
      ),
    );
  }

  // Helper widget to build the main body content based on ViewModel state
  Widget _buildBody(
    BuildContext context,
    AppointmentDetailViewModel viewModel,
  ) {
    // --- Initial Loading State ---
    // Show loading only if appointment is null (initial load)
    // Action loading is handled by the overlay in the parent Stack
    if (viewModel.isLoading && viewModel.appointment == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // --- Error State ---
    if (viewModel.error != null && viewModel.appointment == null) {
      // Show error message with retry if initial loading failed critically
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                "Error Loading Details",
                style: TextStyles.title.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.error!,
                style: TextStyles.bodyGrey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                // Call fetch directly on the viewModel instance from context
                onPressed:
                    () => context
                        .read<AppointmentDetailViewModel>()
                        .fetchAppointmentDetails(appointmentId),
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

    // --- No Appointment Found State ---
    if (viewModel.appointment == null) {
      // This case is reached if loading finished but appointment is still null (and no error)
      return const Center(child: Text("Appointment details not found."));
    }

    // --- Display Appointment Details ---
    final appointment = viewModel.appointment!;
    final appointmentDate = appointment.dateTime.toDate(); // Convert Timestamp
    // Define formats (consider moving to a utility class)
    final dateFormatter = DateFormat.yMMMEd(); // e.g., Wed, Sep 27, 2023
    final timeFormatter = DateFormat.jm(); // e.g., 10:30 AM
    final formattedDate = dateFormatter.format(appointmentDate);
    final formattedTime = timeFormatter.format(appointmentDate);

    return RefreshIndicator(
      onRefresh:
          () =>
              context
                  .read<AppointmentDetailViewModel>()
                  .refreshDetails(), // Use context.read here
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailRow(
            context,
            icon: Icons.person_outline,
            label: 'Patient',
            value: appointment.patientName ?? 'N/A',
          ),
          _buildDetailRow(
            context,
            icon: Icons.medical_services_outlined,
            label: 'Doctor',
            value: appointment.doctorName ?? 'N/A',
          ),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formattedDate,
          ),
          _buildDetailRow(
            context,
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: formattedTime,
          ),
          _buildDetailRow(
            context,
            icon: Icons.medical_information_outlined,
            label: 'Reason for Visit',
            value: appointment.reason,
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.notes_outlined,
              label: 'Patient Notes',
              value: appointment.notes!,
            ),
          _buildDetailRow(
            context,
            icon: Icons.info_outline,
            label: 'Status',
            valueWidget: Text(
              appointment
                  .status
                  .displayName, // Use displayName from enum extension
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    appointment
                        .status
                        .displayColor, // Use color from enum extension
              ),
            ),
          ),

          // --- Action Buttons ---
          const SizedBox(height: 30),
          // Cancel Button
          if (appointment
              .status
              .canBeCancelled) // Use helper from enum extension
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Appointment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                // Disable button while VM is loading (e.g., cancelling)
                onPressed:
                    viewModel.isLoading
                        ? null
                        : () async {
                          final bool? confirmed = await _showConfirmationDialog(
                            context,
                            title: "Confirm Cancellation",
                            content:
                                "Are you sure you want to cancel this appointment? This action cannot be undone.",
                            confirmText: "Yes, Cancel",
                          );

                          if (confirmed == true && context.mounted) {
                            final success =
                                await context
                                    .read<AppointmentDetailViewModel>()
                                    .cancelThisAppointment();
                            if (success && context.mounted) {
                              _showFeedbackSnackbar(
                                context,
                                "Appointment cancelled successfully.",
                              );
                              Navigator.pop(
                                context,
                              ); // Go back after successful cancellation
                            } else if (context.mounted) {
                              // Show error from ViewModel if cancellation failed
                              _showFeedbackSnackbar(
                                context,
                                viewModel.error ??
                                    "Failed to cancel appointment.",
                                isError: true,
                              );
                            }
                          }
                        },
              ),
            ),
          // Reschedule Button
          if (appointment
              .status
              .canBeRescheduled) // Use helper from enum extension
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Reschedule Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                // Disable button while VM is loading
                onPressed:
                    viewModel.isLoading
                        ? null
                        : () {
                          // Navigate using the static service or injected instance
                          context
                              .read<AppointmentDetailViewModel>()
                              .navigateToReschedule();
                        },
              ),
            ),
          // Optional: Add a "Mark as Completed" button for doctors, etc.
        ],
      ),
    );
  }

  // Helper widget to build consistent detail rows
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    final theme = Theme.of(context); // Get theme for consistent styling
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ), // Use theme color
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ??
                        Colors.grey[600], // Use theme color
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ?? // Display valueWidget if provided
                    Text(
                      value ?? 'N/A', // Display value or N/A
                      style: theme.textTheme.bodyLarge, // Use theme text style
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
