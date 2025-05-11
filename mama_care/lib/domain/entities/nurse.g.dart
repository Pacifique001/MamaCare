// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nurse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Nurse _$NurseFromJson(Map<String, dynamic> json) => Nurse(
  id: json['id'] as String,
  name: json['name'] as String,
  specialty: json['specialty'] as String?,
  imageUrl: json['imageUrl'] as String?,
  currentPatientLoad: (json['currentPatientLoad'] as num).toInt(),
);

Map<String, dynamic> _$NurseToJson(Nurse instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'specialty': instance.specialty,
  'imageUrl': instance.imageUrl,
  'currentPatientLoad': instance.currentPatientLoad,
};
