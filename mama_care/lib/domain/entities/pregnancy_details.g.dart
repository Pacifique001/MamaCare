// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pregnancy_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PregnancyDetails _$PregnancyDetailsFromJson(Map<String, dynamic> json) =>
    PregnancyDetails(
      userId: json['userId'] as String,
      startingDay: _dateTimeFromJsonNullable(json['startingDay']),
      weeksPregnant: (json['weeksPregnant'] as num?)?.toInt(),
      daysPregnant: (json['daysPregnant'] as num?)?.toInt(),
      babyHeight: (json['babyHeight'] as num?)?.toDouble(),
      babyWeight: (json['babyWeight'] as num?)?.toDouble(),
      dueDate: _dueDateFromJson(json['dueDate']),
    );

Map<String, dynamic> _$PregnancyDetailsToJson(PregnancyDetails instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'startingDay': _dateTimeToJsonNullable(instance.startingDay),
      'weeksPregnant': instance.weeksPregnant,
      'daysPregnant': instance.daysPregnant,
      'babyHeight': instance.babyHeight,
      'babyWeight': instance.babyWeight,
      'dueDate': _dueDateToJson(instance.dueDate),
    };
