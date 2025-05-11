// lib/presentation/screen/reschedule_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/viewmodel/reschedule_viewmodel.dart';
import 'package:mama_care/presentation/widgets/loading_overlay.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class RescheduleAppointmentScreen extends StatelessWidget {
  final String appointmentId;

  const RescheduleAppointmentScreen({super.key, required this.appointmentId});

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
    // Provide the ViewModel scoped to this screen
    return ChangeNotifierProvider<RescheduleViewModel>(
      create: (_) => locator<RescheduleViewModel>()..initialize(appointmentId),
      child: Consumer<RescheduleViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Scaffold(
                appBar: const MamaCareAppBar(title: 'Reschedule Appointment'),
                body: _buildBody(context, viewModel),
              ),
              // Show overlay while loading initial details or confirming reschedule
              if (viewModel.isLoading)
                LoadingOverlay(message: viewModel.loadingMessage),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RescheduleViewModel viewModel) {
    // --- Initial Loading or Critical Error ---
    if (viewModel.isLoading && viewModel.originalAppointment == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (viewModel.error != null && viewModel.originalAppointment == null) {
      // Handle error fetching original appointment details
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
                "Error Loading Appointment",
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
                onPressed:
                    () => context.read<RescheduleViewModel>().initialize(
                      appointmentId,
                    ),
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
    // Should not happen if logic is correct, but fallback
    if (viewModel.originalAppointment == null) {
      return const Center(child: Text("Could not load appointment details."));
    }

    // --- Main Reschedule UI ---
    final originalDateTime = viewModel.originalAppointment!.dateTime.toDate();
    final timeFormatter = DateFormat.jm();
    final dateFormatter = DateFormat.yMMMEd();

    return SingleChildScrollView(
      // Allow scrolling on smaller screens
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rescheduling Appointment For:', style: TextStyles.title),
          const SizedBox(height: 8),
          Text(
            viewModel.originalAppointment!.reason,
            style: TextStyles.bodyBold,
          ),
          const SizedBox(height: 16),
          Text(
            'Original Date: ${dateFormatter.format(originalDateTime)} at ${timeFormatter.format(originalDateTime)}',
            style: TextStyles.bodyGrey,
          ),
          const Divider(height: 30),

          Text('Select New Date & Time:', style: TextStyles.title),
          const SizedBox(height: 16),

          // --- Date Picker ---
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(
              viewModel.selectedDate == null
                  ? 'Select Date'
                  : dateFormatter.format(viewModel.selectedDate!),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                viewModel.isLoading
                    ? null
                    : () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: viewModel.selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ), // Allow today
                        lastDate: DateTime.now().add(
                          const Duration(days: 90),
                        ), // Example limit
                      );
                      if (picked != null) {
                        // Use context.read for actions
                        context.read<RescheduleViewModel>().selectDate(picked);
                      }
                    },
          ),
          const SizedBox(height: 10),

          // --- Time Picker ---
          ListTile(
            leading: const Icon(Icons.access_time, color: AppColors.primary),
            title: Text(
              viewModel.selectedTime == null
                  ? 'Select Time'
                  : viewModel.selectedTime!.format(context),
            ), // Format TimeOfDay
            trailing: const Icon(Icons.chevron_right),
            onTap:
                viewModel.isLoading
                    ? null
                    : () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: viewModel.selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        // Use context.read for actions
                        context.read<RescheduleViewModel>().selectTime(picked);
                      }
                    },
          ),
          const SizedBox(height: 30),

          // --- Display Error Messages from ViewModel ---
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                viewModel.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),

          // --- Confirm Button ---
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: TextStyles.bodyBold,
              ),
              // Disable button if loading or date/time not selected
              onPressed:
                  (viewModel.isLoading ||
                          viewModel.selectedDate == null ||
                          viewModel.selectedTime == null)
                      ? null
                      : () async {
                        final success =
                            await context
                                .read<RescheduleViewModel>()
                                .confirmReschedule();
                        if (success && context.mounted) {
                          _showFeedbackSnackbar(
                            context,
                            "Appointment rescheduled successfully!",
                          );
                          // Optionally pass back a result or just pop
                          Navigator.pop(
                            context,
                            true,
                          ); // Pop and indicate success
                        } else if (context.mounted) {
                          // Error message is already set in ViewModel, could show snackbar too
                          // _showFeedbackSnackbar(context, viewModel.error ?? "Failed to reschedule.", isError: true);
                        }
                      },
              child: const Text('Confirm Reschedule'),
            ),
          ),
        ],
      ),
    );
  }
}
