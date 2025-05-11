import 'package:json_annotation/json_annotation.dart';
import 'package:mama_care/domain/entities/place_api/location.dart';

part 'viewport.g.dart';

@JsonSerializable()
class Viewport {
  final Location northeast;
  final Location southwest;

  Viewport({
    required this.northeast,
    required this.southwest,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) =>
      _$ViewportFromJson(json);

  Map<String, dynamic> toJson() => _$ViewportToJson(this);
}