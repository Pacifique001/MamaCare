// lib/domain/entities/place_api/opening_hours.dart (Keep simple)
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'opening_hours.g.dart';

@JsonSerializable()
class OpeningHours extends Equatable {
  @JsonKey(name: 'open_now') // Match JSON key
  final bool? openNow; // Make nullable, might not always be present

  const OpeningHours({this.openNow});

  factory OpeningHours.fromJson(Map<String, dynamic> json) =>
      _$OpeningHoursFromJson(json);
  Map<String, dynamic> toJson() => _$OpeningHoursToJson(this);

  @override
  List<Object?> get props => [openNow];
}
