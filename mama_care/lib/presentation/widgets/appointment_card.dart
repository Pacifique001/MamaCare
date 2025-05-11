// lib/presentation/widgets/appointment_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_care/domain/entities/appointment_status.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/doctor_appointments_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/patient_appointments_viewmodel.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/injection.dart';
import 'package:sizer/sizer.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final UserRole userRole;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onAddNotes;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.userRole,
    required this.currentUserId,
    this.onTap,
    this.onApprove,
    this.onDecline,
    this.onComplete,
    this.onCancel,
    this.onAddNotes,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime apptDateTime = appointment.dateTime.toDate();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(appointment.status).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusHeader(context),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time info with icons
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

                  // Show relevant name based on user role
                  _buildDetailRow(
                    Icons.person_outline,
                    userRole == UserRole.doctor
                        ? appointment.patientName
                        : appointment.doctorName,
                    label: userRole == UserRole.doctor ? "Patient" : "Doctor",
                  ),
                  const SizedBox(height: 12),

                  // Reason for appointment
                  _buildDetailRow(
                    Icons.medical_services_outlined,
                    appointment.reason,
                    label: "Reason",
                  ),

                  // Notes (if available)
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
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // Status header with background color and status indicator
  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                appointment.status.name.capitalize(),
                style: TextStyles.bodyBold.copyWith(
                  color: _getStatusColor(appointment.status),
                ),
              ),
            ],
          ),
          _buildStatusChip(appointment.status),
        ],
      ),
    );
  }

  // Build detail row with optional label
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

  // Status chip for visual indicator
  Widget _buildStatusChip(AppointmentStatus status) {
    Color chipColor = _getStatusColor(status);

    return Chip(
      avatar: Icon(_getStatusIcon(status), size: 14, color: chipColor),
      label: Text(status.name.capitalize()),
      labelStyle: TextStyle(
        fontSize: 9.sp,
        color: chipColor,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: chipColor.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      side: BorderSide.none,
    );
  }

  // Action buttons based on role and status
  Widget _buildActionButtons(BuildContext context) {
    // Delegate to appropriate role-based actions
    switch (userRole) {
      case UserRole.doctor:
        return _buildDoctorActionButtons(context);
      case UserRole.patient:
        return _buildPatientActionButtons(context);
      case UserRole.nurse:
        return _buildNurseActionButtons(context);
      default:
        return const SizedBox(height: 16);
    }
  }

  // Doctor-specific actions
  Widget _buildDoctorActionButtons(BuildContext context) {
    final logger = locator<Logger>();

    // Display approval/decline buttons for pending appointments
    if (appointment.status == AppointmentStatus.pending &&
        (onApprove != null && onDecline != null)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  logger.d(
                    "Decline button pressed for appointment ${appointment.id}",
                  );
                  final confirmed = await _showConfirmationDialog(
                    context,
                    title: 'Decline Appointment',
                    content: 'Are you sure you want to decline this request?',
                    confirmText: 'Yes, Decline',
                    confirmColor: Colors.red,
                  );
                  if (confirmed ?? false) {
                    onDecline?.call();
                  }
                },
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
                onPressed: () async {
                  logger.d(
                    "Confirm button pressed for appointment ${appointment.id}",
                  );
                  final confirmed = await _showConfirmationDialog(
                    context,
                    title: 'Confirm Appointment',
                    content: 'Confirm this appointment request?',
                  );
                  if (confirmed ?? false) {
                    onApprove?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Approve"),
              ),
            ),
          ],
        ),
      );
    }
    // Display complete button for confirmed appointments
    else if ((appointment.status == AppointmentStatus.confirmed ||
            appointment.status == AppointmentStatus.scheduled) &&
        onComplete != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (onCancel != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    logger.d(
                      "Cancel button pressed for appointment ${appointment.id}",
                    );
                    final confirmed = await _showConfirmationDialog(
                      context,
                      title: 'Cancel Appointment',
                      content:
                          'Cancel this confirmed appointment? The patient will be notified.',
                      confirmText: 'Yes, Cancel',
                      confirmColor: Colors.red,
                    );
                    if (confirmed ?? false) {
                      onCancel?.call();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
            if (onCancel != null) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  logger.d(
                    "Complete button pressed for appointment ${appointment.id}",
                  );
                  final confirmed = await _showConfirmationDialog(
                    context,
                    title: 'Mark as Completed',
                    content: 'Mark this appointment as completed?',
                  );
                  if (confirmed ?? false) {
                    onComplete?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Mark as Completed"),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 16);
  }

  // Patient-specific actions
  Widget _buildPatientActionButtons(BuildContext context) {
    final logger = locator<Logger>();

    // Patient can cancel if pending, confirmed, or scheduled
    if ((appointment.status == AppointmentStatus.pending ||
            appointment.status == AppointmentStatus.confirmed ||
            appointment.status == AppointmentStatus.scheduled) &&
        onCancel != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: () async {
            logger.d("Patient cancel request for ${appointment.id}");
            final confirmed = await _showConfirmationDialog(
              context,
              title: 'Cancel Appointment',
              content: 'Are you sure you want to cancel this appointment?',
              confirmText: 'Yes, Cancel',
              confirmColor: Colors.red,
            );
            if (confirmed ?? false) {
              onCancel?.call();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text("Cancel Appointment"),
        ),
      );
    }

    return const SizedBox(height: 16);
  }

  // Nurse-specific actions
  Widget _buildNurseActionButtons(BuildContext context) {
    final logger = locator<Logger>();

    // Nurses can add notes to confirmed or scheduled appointments
    if ((appointment.status == AppointmentStatus.confirmed ||
            appointment.status == AppointmentStatus.scheduled) &&
        onAddNotes != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: () {
            logger.d("Nurse add notes for ${appointment.id}");
            onAddNotes?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text("Add Notes"),
        ),
      );
    }

    return const SizedBox(height: 16);
  }

  // Status color based on appointment status
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

  // Status icon based on appointment status
  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty_rounded;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case AppointmentStatus.declined:
        return Icons.do_not_disturb_on_outlined;
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

  // Helper for confirmation dialogs
  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color confirmColor = AppColors.primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text(title, style: TextStyles.title),
            content: Text(content, style: TextStyles.body),
            actions: <Widget>[
              TextButton(
                child: Text(cancelText),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: confirmColor),
                child: Text(confirmText),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );
  }
}
