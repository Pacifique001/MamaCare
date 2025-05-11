// lib/domain/entities/doctor.dart

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // If using Firestore
import 'package:json_annotation/json_annotation.dart';

part 'doctor.g.dart'; // If using json_serializable

@JsonSerializable() // If using json_serializable
class Doctor extends Equatable {
  final String id; // Doctor's unique ID
  final String name;
  final String? specialty;
  final String? imageUrl;
  // Add other relevant fields like clinic name, location, etc. if needed

  const Doctor({
    required this.id,
    required this.name,
    this.specialty,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, specialty, imageUrl];

  // --- JSON/Firestore Conversion ---

  // Example using json_serializable (run build_runner after adding)
  factory Doctor.fromJson(Map<String, dynamic> json) => _$DoctorFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorToJson(this);

  // Example manual Firestore conversion (adapt to your structure)
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Doctor(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Doctor',
      specialty: data['specialty'] as String?,
      imageUrl: data['imageUrl'] as String?,
      // Parse other fields
    );
  }
}
