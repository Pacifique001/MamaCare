// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceResult _$PlaceResultFromJson(Map<String, dynamic> json) => PlaceResult(
  placeId: json['place_id'] as String,
  geometry:
      json['geometry'] == null
          ? null
          : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
  name: json['name'] as String?,
  vicinity: json['vicinity'] as String?,
  openingHours:
      json['opening_hours'] == null
          ? null
          : OpeningHours.fromJson(
            json['opening_hours'] as Map<String, dynamic>,
          ),
  rating: (json['rating'] as num?)?.toDouble(),
  userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt(),
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList(),
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
  formattedPhoneNumber: json['formatted_phone_number'] as String?,
);

Map<String, dynamic> _$PlaceResultToJson(PlaceResult instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'geometry': instance.geometry?.toJson(),
      'name': instance.name,
      'vicinity': instance.vicinity,
      'opening_hours': instance.openingHours?.toJson(),
      'rating': instance.rating,
      'user_ratings_total': instance.userRatingsTotal,
      'photos': instance.photos?.map((e) => e.toJson()).toList(),
      'types': instance.types,
      'formatted_phone_number': instance.formattedPhoneNumber,
    };
