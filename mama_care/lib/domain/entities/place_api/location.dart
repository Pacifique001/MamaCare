// lib/domain/entities/place_api/location.dart (Keep this simple LatLng)
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'location.g.dart';

@JsonSerializable()
class Location extends Equatable {
  @JsonKey(name: 'lat') // Match JSON key
  final double latitude;
  @JsonKey(name: 'lng') // Match JSON key
  final double longitude;

  const Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  @override
  List<Object?> get props => [latitude, longitude];
}