import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'place_result.dart';

part 'places_nearby_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PlacesNearbyResponse extends Equatable {
  @JsonKey(name: 'results')
  final List<PlaceResult> results;
  @JsonKey(name: 'status')
  final String status; // e.g., "OK", "ZERO_RESULTS", "INVALID_REQUEST"
  @JsonKey(name: 'error_message')
  final String? errorMessage; // Present if status is not "OK"
  @JsonKey(name: 'next_page_token')
  final String? nextPageToken; // For pagination

  const PlacesNearbyResponse({
    required this.results,
    required this.status,
    this.errorMessage,
    this.nextPageToken,
  });

   factory PlacesNearbyResponse.fromJson(Map<String, dynamic> json) => _$PlacesNearbyResponseFromJson(json);
   Map<String, dynamic> toJson() => _$PlacesNearbyResponseToJson(this);

   @override
   List<Object?> get props => [results, status, errorMessage, nextPageToken];
}