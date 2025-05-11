// lib/domain/entities/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'appointment_status.dart'; // Import the enum and helpers

// Helper function (can be here or in a shared utils file)
AppointmentStatus appointmentStatusFromString(String? status) {
  if (status == null) return AppointmentStatus.pending; // Default if null
  return AppointmentStatus.values.firstWhere(
    (e) => e.name == status.toLowerCase(),
    orElse: () => AppointmentStatus.pending, // Default if unknown status string
  );
}

class Appointment extends Equatable {
  final String? id; // Firestore ID, null before creation
  final String patientId;
  final String doctorId;
  final String patientName; // Denormalized for convenience
  final String doctorName; // Denormalized for convenience
  final String? nurseId; // Added nullable nurseId
  final Timestamp dateTime; // Use Timestamp for Firestore consistency
  final String reason;
  final String? notes;
  final AppointmentStatus status; // Use the enum type
  final Timestamp? createdAt; // Use nullable Timestamp (set by server)
  final Timestamp? updatedAt; // Use nullable Timestamp (set by server)

  // Calculated property for easy DateTime access
  DateTime get appointmentDateTime => dateTime.toDate();
  DateTime? get createdDateTime => createdAt?.toDate(); // Handle null
  DateTime? get updatedDateTime => updatedAt?.toDate(); // Handle null

  const Appointment({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    this.nurseId, // Add nurseId
    required this.dateTime,
    required this.reason,
    this.notes,
    this.status = AppointmentStatus.pending,
    this.createdAt, // Nullable
    this.updatedAt, // Nullable
  });

  // Create from Firestore document
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data =
        doc.data() as Map<String, dynamic>? ?? {}; // Handle null data safely
    return Appointment.fromMap(data, id: doc.id); // Delegate to fromMap
  }

  // Create from a plain Map (e.g., from DB or network)
  factory Appointment.fromMap(Map<String, dynamic> map, {String? id}) {
    // Helper to safely convert Timestamps or DateTimes from the map
    Timestamp? parseTimestamp(dynamic value) {
      if (value is Timestamp) return value;
      if (value is DateTime) return Timestamp.fromDate(value);
      // Add other potential types if needed (like int milliseconds)
      if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return Appointment(
      id: id ?? map['id'] as String?, // Use provided ID or map ID
      patientId: map['patientId'] as String? ?? '', // Default if null
      doctorId: map['doctorId'] as String? ?? '', // Default if null
      patientName: map['patientName'] as String? ?? 'Unknown Patient',
      doctorName: map['doctorName'] as String? ?? 'Unknown Doctor',
      nurseId: map['nurseId'] as String?, // Allow null nurseId
      dateTime:
          parseTimestamp(map['dateTime']) ??
          Timestamp.now(), // Default to now if missing/invalid
      reason: map['reason'] as String? ?? '', // Default if null
      notes: map['notes'] as String?,
      status: appointmentStatusFromString(
        map['status'] as String?,
      ), // Use helper
      createdAt: parseTimestamp(map['createdAt']), // Allow null
      updatedAt: parseTimestamp(map['updatedAt']), // Allow null
    );
  }

  // Convert to map for Firestore CREATION
  Map<String, dynamic> toMapForCreation() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'nurseId': nurseId, // Include nurseId (can be null)
      'dateTime': dateTime, // Keep as Timestamp
      'reason': reason,
      'notes': notes,
      'status': appointmentStatusToString(status), // Convert enum to string
      'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
      'updatedAt': FieldValue.serverTimestamp(), // Also set on creation
    };
  }

  // *** ADDED: Convert to map for Firestore UPDATE ***
  Map<String, dynamic> toMapForUpdate() {
    // Only include fields intended to be updatable
    // Exclude fields like patientId, doctorId, createdAt
    return {
      if (nurseId != null)
        'nurseId': nurseId, // Allow updating nurse assignment
      'dateTime': dateTime, // Allow rescheduling
      'reason': reason, // Allow updating reason
      if (notes != null) 'notes': notes, // Allow updating notes
      'status': appointmentStatusToString(status), // Allow updating status
      'updatedAt': FieldValue.serverTimestamp(), // ALWAYS update timestamp
      // Include denormalized names only if they need updating here
      // 'patientName': patientName,
      // 'doctorName': doctorName,
    };
  }

  // Convert to a regular Map (useful for local storage or general use)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'nurseId': nurseId,
      'dateTime':
          dateTime, // Keep as Timestamp for consistency? Or convert to DateTime?
      'reason': reason,
      'notes': notes,
      'status': appointmentStatusToString(status),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      // 'id' is not usually part of the data map itself when writing, it's the document ID.
      // However, if you were, for example, embedding this in another document, you might include it.
      // For top-level document writes, `id` is used as `collection.doc(appointment.id).set(...)`.
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'nurseId': nurseId,
      'dateTime': dateTime, // Stored as Timestamp
      'reason': reason,
      'notes': notes,
      'status': appointmentStatusToString(status), // Convert enum to string
      // For a generic map, you might include these if they are already populated.
      // For new documents, `toMapForCreation` is better as it uses serverTimestamp.
      'createdAt': createdAt, // Stored as Timestamp
      'updatedAt':
          updatedAt, // Stored as Timestamp (or use FieldValue.serverTimestamp() for updates)
    };
  }

  // Create a copy with updated fields
  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? nurseId,
    bool setNurseIdToNull = false, // Flag to explicitly set nurseId null
    Timestamp? dateTime, // Prefer Timestamp for internal consistency
    DateTime? dateTimeAsDateTime, // Allow setting via DateTime
    String? reason,
    String? notes,
    bool setNotesToNull = false,
    AppointmentStatus? status,
    String? statusAsString,
    Timestamp? createdAt, // Usually not copied unless for specific reason
    DateTime? createdAtAsDateTime,
    Timestamp? updatedAt, // Usually set by server on update
    DateTime? updatedAtAsDateTime,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      nurseId:
          setNurseIdToNull
              ? null
              : (nurseId ?? this.nurseId), // Handle null setting
      dateTime:
          dateTimeAsDateTime != null
              ? Timestamp.fromDate(dateTimeAsDateTime)
              : (dateTime ?? this.dateTime),
      reason: reason ?? this.reason,
      notes:
          setNotesToNull ? null : (notes ?? this.notes), // Handle null setting
      status:
          status ??
          (statusAsString != null
              ? appointmentStatusFromString(statusAsString)
              : this.status),
      createdAt:
          createdAtAsDateTime != null
              ? Timestamp.fromDate(createdAtAsDateTime)
              : (createdAt ?? this.createdAt),
      updatedAt:
          updatedAtAsDateTime != null
              ? Timestamp.fromDate(updatedAtAsDateTime)
              : (updatedAt ??
                  this.updatedAt), // Allow explicit setting if needed
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    patientName,
    doctorName,
    nurseId, // Add nurseId
    dateTime,
    reason,
    notes,
    status,
    createdAt,
    updatedAt,
  ];

  @override
  bool get stringify => true; // Enable helpful toString output
}
