// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>?,
      fcmMessageId: json['fcmMessageId'] as String?,
      isScheduled: json['isScheduled'] as bool? ?? false,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'timestamp': instance.timestamp,
      'isRead': instance.isRead,
      'isScheduled': instance.isScheduled,
      'payload': instance.payload,
      'fcmMessageId': instance.fcmMessageId,
    };
