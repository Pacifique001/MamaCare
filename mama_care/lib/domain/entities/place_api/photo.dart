// lib/domain/entities/place_api/photo.dart (Keep simple)
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo extends Equatable {
  final int? height;
  @JsonKey(name: 'photo_reference') // Match JSON key
  final String photoReference;
  final int? width;

  const Photo({this.height, required this.photoReference, this.width});

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);

  @override
  List<Object?> get props => [height, photoReference, width];
}
