// lib/domain/entities/nurse_assignment.dart (Ensure this file exists)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NurseAssignment extends Equatable {
  final String id; // Firestore document ID
  final String nurseId;
  final String nurseName; // Denormalized
  final String patientId;
  final String patientName; // Denormalized
  final String doctorId; // ID of the doctor who made the assignment
  final Timestamp assignedAt;
  final String? notes; // Optional notes about the assignment

  const NurseAssignment({
    required this.id,
    required this.nurseId,
    required this.nurseName,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.assignedAt,
    this.notes,
  });

  // Convert Firestore Timestamp to DateTime for easier use
  DateTime get assignmentDate => assignedAt.toDate();

  // Factory constructor from Firestore
  factory NurseAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NurseAssignment(
      id: doc.id,
      nurseId: data['nurseId'] ?? '',
      nurseName: data['nurseName'] ?? 'Unknown Nurse',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      doctorId: data['doctorId'] ?? '',
      assignedAt: data['assignedAt'] as Timestamp? ?? Timestamp.now(),
      notes: data['notes'] as String?,
    );
  }

  // Convert to Map for Firestore (mainly for creation/update)
  Map<String, dynamic> toMap() {
    return {
      'nurseId': nurseId,
      'nurseName': nurseName,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'assignedAt': assignedAt, // Use existing Timestamp or FieldValue.serverTimestamp() on create
      'notes': notes,
    };
  }

   Map<String, dynamic> toMapForCreation() {
    return {
      'nurseId': nurseId,
      'nurseName': nurseName,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'assignedAt': FieldValue.serverTimestamp(), // Use server timestamp
      'notes': notes,
    };
  }


  @override
  List<Object?> get props => [
        id, nurseId, nurseName, patientId, patientName,
        doctorId, assignedAt, notes
      ];
}