// lib/domain/entities/nurse.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart'; // If using json_serializable

part 'nurse.g.dart'; // If using json_serializable

@JsonSerializable() // If using json_serializable
class Nurse extends Equatable {
  final String id; // Nurse's unique ID (e.g., Firebase Auth UID or Firestore doc ID)
  final String name;
  final String? specialty;
  final String? imageUrl; // URL to profile picture
  final int currentPatientLoad; // Number of patients currently assigned

  const Nurse({
    required this.id,
    required this.name,
    this.specialty,
    this.imageUrl,
    required this.currentPatientLoad,
  });

  @override
  List<Object?> get props => [id, name, specialty, imageUrl, currentPatientLoad];

  // --- Add JSON/Firestore conversion ---

  // Example using json_serializable (run build_runner after adding)
  factory Nurse.fromJson(Map<String, dynamic> json) => _$NurseFromJson(json);
  Map<String, dynamic> toJson() => _$NurseToJson(this);

  // Example manual Firestore conversion (adapt to your Firestore structure)
  factory Nurse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Calculate patientLoad - This might need a separate query or be stored directly
    // For example, if 'patientIds' is an array field on the nurse document:
    final patientLoad = (data['patientIds'] as List?)?.length ?? data['currentPatientLoad'] as int? ?? 0;

    return Nurse(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Nurse',
      specialty: data['specialty'] as String?,
      imageUrl: data['imageUrl'] as String?,
      currentPatientLoad: patientLoad,
    );
  }

   // You might not need a toFirestore here if nurse profiles are managed elsewhere
   Map<String, dynamic> toFirestoreMap() {
     return {
       'name': name,
       'specialty': specialty,
       'imageUrl': imageUrl,
       'currentPatientLoad': currentPatientLoad, // Be careful writing this if derived
       // Don't usually write 'id' back into the document data
     };
   }
}