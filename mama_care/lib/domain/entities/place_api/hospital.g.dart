// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hospital.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hospital _$HospitalFromJson(Map<String, dynamic> json) => Hospital(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  location: Location.fromJson(json['location'] as Map<String, dynamic>),
  results:
      (json['results'] as List<dynamic>)
          .map((e) => Hospital.fromJson(e as Map<String, dynamic>))
          .toList(),
  rating: (json['rating'] as num?)?.toDouble(),
  isOpen: json['isOpen'] as bool? ?? false,
);

Map<String, dynamic> _$HospitalToJson(Hospital instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'location': instance.location,
  'results': instance.results,
  'rating': instance.rating,
  'isOpen': instance.isOpen,
};
