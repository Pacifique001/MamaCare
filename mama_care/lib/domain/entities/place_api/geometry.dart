// lib/domain/entities/place_api/geometry.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'location.dart'; // Import the corrected Location
// Remove Viewport import if not strictly needed or define it correctly based on JSON
import 'viewport.dart';

part 'geometry.g.dart';

@JsonSerializable(explicitToJson: true) // Use explicitToJson if Location has toJson
class Geometry extends Equatable {
  final Location location;
  // Viewport might be nested differently or optional, adjust as needed
  final Viewport? viewport;

  const Geometry({
    required this.location,
     this.viewport,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) => _$GeometryFromJson(json);
  Map<String, dynamic> toJson() => _$GeometryToJson(this);

  @override
  List<Object?> get props => [location /*, viewport*/];
}