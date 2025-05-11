// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_nearby_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlacesNearbyResponse _$PlacesNearbyResponseFromJson(
  Map<String, dynamic> json,
) => PlacesNearbyResponse(
  results:
      (json['results'] as List<dynamic>)
          .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
          .toList(),
  status: json['status'] as String,
  errorMessage: json['error_message'] as String?,
  nextPageToken: json['next_page_token'] as String?,
);

Map<String, dynamic> _$PlacesNearbyResponseToJson(
  PlacesNearbyResponse instance,
) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
  'status': instance.status,
  'error_message': instance.errorMessage,
  'next_page_token': instance.nextPageToken,
};
