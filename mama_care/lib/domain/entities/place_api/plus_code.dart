import 'package:json_annotation/json_annotation.dart';

part 'plus_code.g.dart';

@JsonSerializable()
class PlusCode {
  final String compoundCode;
  final String globalCode;

  PlusCode({
    required this.compoundCode,
    required this.globalCode,
  });

  factory PlusCode.fromJson(Map<String, dynamic> json) =>
      _$PlusCodeFromJson(json);

  Map<String, dynamic> toJson() => _$PlusCodeToJson(this);
}