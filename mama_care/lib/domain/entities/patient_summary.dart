// lib/domain/entities/patient_summary.dart

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore conversion example

/// Represents essential patient information for display in lists.
class PatientSummary extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime? dueDate; 
  final int? weeksPregnant;// Example extra field

  const PatientSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    this.dueDate,
    this.weeksPregnant,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, dueDate , weeksPregnant];

  // Example factory for converting from a full Patient/User entity
   factory PatientSummary.fromPatient(PatientSummary patient) {
     return PatientSummary(
      id: patient.id,
       name: patient.name,
       imageUrl: patient.imageUrl,
       dueDate: patient.dueDate,
       weeksPregnant: patient.weeksPregnant,
      );
    }

  // Example factory from Firestore data (adapt to your patient document structure)
  factory PatientSummary.fromFirestore(DocumentSnapshot doc) {
     final data = doc.data() as Map<String, dynamic>? ?? {};
     return PatientSummary(
       id: doc.id,
       name: data['name'] as String? ?? 'Unknown Patient',
       imageUrl: data['profileImageUrl'] as String?, // Assuming field name in Firestore
       dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
       weeksPregnant:data['weeksPregenant'] as int, // Assuming field name
     );
  }

  factory PatientSummary.fromMap(Map<String, dynamic> map) {
     // Helper to parse date safely (can be reused or defined locally)
     DateTime? parseDate(dynamic dateValue) {
        if (dateValue == null) return null;
        if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
        if (dateValue is String) return DateTime.tryParse(dateValue);
        if (dateValue is DateTime) return dateValue;
        if (dateValue is Timestamp) return dateValue.toDate(); // Handle Timestamp too
        return null;
     }
     return PatientSummary(
       id: map['id'] as String? ?? '', // Assume ID might be in the map too
       name: map['name'] as String? ?? 'Unknown Patient',
       imageUrl: map['profileImageUrl'] as String?,
       dueDate: parseDate(map['dueDate']),
       weeksPregnant: map['weeksPregnant'] as int?,
     );
   }
}