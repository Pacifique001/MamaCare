// lib/domain/entities/appointment_status.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/utils/app_colors.dart';

enum AppointmentStatus {
  pending, // Patient requested, Doctor hasn't responded
  confirmed, // Doctor confirmed the time/date
  completed, // The appointment occurred
  cancelled, // Patient cancelled before confirmation/occurrence
  declined, // Doctor declined the request
  scheduled, // Could be used if an admin/system schedules it initially
}

/// Converts an AppointmentStatus enum to its string representation for Firestore.
String appointmentStatusToString(AppointmentStatus status) {
  return status.name; // Uses the enum value name (e.g., 'pending', 'confirmed')
}

/// Converts a string status (from Firestore or filter) to an AppointmentStatus enum.
/// Returns a default (e.g., pending) if the string doesn't match any enum value.
AppointmentStatus appointmentStatusFromString(String? statusString) {
  if (statusString == null) return AppointmentStatus.pending; // Default
  try {
    // Find the enum value matching the string name (case-insensitive safety optional)
    return AppointmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusString.toLowerCase(),
    );
  } catch (e) {
    // Log the error if an unexpected status string is encountered
    locator<Logger>().w(
      "Could not parse appointment status string: '$statusString'. Defaulting to pending.",
    );
    return AppointmentStatus.pending; // Default on error
  }
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending Confirmation';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.cancelled:
        return 'Cancelled by Patient'; // Be specific
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.declined:
        return 'Declined by Doctor'; // Be specific
      default:
        return 'Unknown';
    }
  }

  Color get displayColor {
    // Use theme-aware colors if possible, otherwise fallback
    switch (this) {
      case AppointmentStatus.pending:
        return Colors.orange.shade700;
      case AppointmentStatus.confirmed:
      case AppointmentStatus.scheduled:
        return Colors.green.shade700;
      case AppointmentStatus.completed:
        return Colors.blue.shade700;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.declined:
      default:
        return Colors.grey.shade600;
    }
  }

  /// Determines if a doctor can mark this appointment as completed.
  bool get canBeCompletedByDoctor {
    // Typically, a doctor marks an appointment as completed after it has occurred
    // and was in a 'confirmed' or 'scheduled' state.
    // They might also complete a 'pending' one if they just saw the patient without prior confirmation.
    return this == AppointmentStatus.confirmed ||
        this == AppointmentStatus.scheduled ||
        this ==
            AppointmentStatus
                .pending; // Allow completing a pending if necessary
  }

  bool get canBeDeletedByDoctor {
    return this == AppointmentStatus.completed ||
           this == AppointmentStatus.declined ||
           this == AppointmentStatus.cancelled; // Add cancelled if doctors should clean those up too
          // this == AppointmentStatus.noShow; // Add if implementing no-show
  }

  // Logic to determine if actions are allowed
  bool get canBeCancelled {
    // Example: Only pending or confirmed/scheduled appointments can be cancelled by patient
    return this == AppointmentStatus.pending ||
        this == AppointmentStatus.confirmed ||
        this == AppointmentStatus.scheduled;
  }

  bool get canBeRescheduled {
    // Example: Only pending or confirmed/scheduled appointments can be rescheduled
    return this == AppointmentStatus.pending ||
        this == AppointmentStatus.confirmed ||
        this == AppointmentStatus.scheduled;
  }
}
