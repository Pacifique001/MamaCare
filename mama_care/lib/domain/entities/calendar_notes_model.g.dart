// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notes_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarNote _$CalendarNoteFromJson(Map<String, dynamic> json) => CalendarNote(
  id: json['id'] as String?,
  date: DateTime.parse(json['date'] as String),
  note: json['note'] as String,
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CalendarNoteToJson(CalendarNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'userId': instance.userId,
    };
