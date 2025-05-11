// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiskData _$RiskDataFromJson(Map<String, dynamic> json) => RiskData(
  riskLevel: json['riskLevel'] as String,
  description: json['description'] as String,
  recommendations:
      (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$RiskDataToJson(RiskData instance) => <String, dynamic>{
  'riskLevel': instance.riskLevel,
  'description': instance.description,
  'recommendations': instance.recommendations,
};
