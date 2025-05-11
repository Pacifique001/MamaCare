// lib/domain/entities/notification_model.dart

import 'dart:convert'; // For jsonEncode/Decode for payload
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For @immutable
// Using manual serialization as it's simpler for this case than setting up converters
// If you prefer json_serializable, uncomment annotations and run build_runner
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

//@immutable
@JsonSerializable() // Uncomment if using json_serializable
class NotificationModel extends Equatable {
  final String id; // Unique local ID (e.g., UUID or generated)
  final String? userId; // Associated user (nullable if global notification)
  final String title;
  final String body;
  final int timestamp; // MillisecondsSinceEpoch UTC
  final bool isRead;
  final bool isScheduled;
  // Store payload as a JSON encoded string in DB for simplicity,
  // but handle as Map<String, dynamic> in the model.
  final Map<String, dynamic>? payload;
  final String? fcmMessageId; // Optional: Original FCM message ID

  const NotificationModel({
    required this.id,
    this.userId, // Now included
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false, // Default to false
    this.payload, // Keep optional
    this.fcmMessageId,
    this.isScheduled=false, // Keep optional
  });

  // --- JSON/Map Serialization (Manual Implementation) ---

  /// Creates a NotificationModel from a Map (e.g., from SQLite).
  /// Handles potential type issues and decodes the payload string.
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? decodedPayload;
    if (map['payload'] is String && (map['payload'] as String).isNotEmpty) {
      try {
        // Ensure the decoded value is treated as a Map
        var decoded = jsonDecode(map['payload'] as String);
        if (decoded is Map) {
          decodedPayload = Map<String, dynamic>.from(decoded);
        } else {
          // Handle cases where payload is not a valid JSON map string
          print(
            "Warning: Notification payload was not a valid JSON map string: ${map['payload']}",
          );
          decodedPayload = {
            '_raw_payload': map['payload'],
          }; // Store raw payload
        }
      } catch (e) {
        print("Error decoding notification payload: $e"); // Log error
        // Store raw payload on error for debugging
        decodedPayload = {'_raw_payload': map['payload']};
      }
    } else if (map['payload'] is Map) {
      // Handle if payload is already a Map (e.g., from Firestore directly)
      decodedPayload = Map<String, dynamic>.from(map['payload']);
    }

    return NotificationModel(
      id: map['id'] as String? ?? '', // Provide default or handle null ID
      userId: map['userId'] as String?, // Handle nullable userId
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isRead: (map['isRead'] as int? ?? 0) == 1, 
      isScheduled: (map['isScheduled'] as int? ?? 0) == 1,// Handle int from DB (0 or 1)
      payload: decodedPayload, // Assign decoded map
      fcmMessageId: map['fcmMessageId'] as String?,
    );
  }

  /// Converts the NotificationModel instance into a map suitable for SQLite.
  /// Encodes the payload map into a JSON string.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // Include userId
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': isRead ? 1 : 0,
      'isScheduled': isScheduled ? 1 : 0, // Store bool as int (0 or 1)
      // Store payload map as JSON string in the map for DB compatibility
      'payload':
          payload != null && payload!.isNotEmpty ? jsonEncode(payload) : null,
      'fcmMessageId': fcmMessageId,
    };
  }

  // --- Convenience Aliases for fromMap/toMap if needed elsewhere ---
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  // --- Equatable ---
  @override
  List<Object?> get props => [
    id,
    userId, // Add userId to props
    title,
    body,
    timestamp,
    isRead,
    payload, // Comparing Maps can be tricky, ensure deep equality if needed
    fcmMessageId,
    isScheduled,
  ];

  // --- CopyWith ---
  NotificationModel copyWith({
    String? id,
    String? userId, // ADDED userId parameter
    ValueGetter<String?>? userIdOrNull, // Helper for setting userId to null
    String? title,
    String? body,
    int? timestamp,
    bool? isRead,
    bool? isScheduled,
    Map<String, dynamic>? payload,
    ValueGetter<Map<String, dynamic>?>?
    payloadOrNull, // Helper for setting payload to null
    String? fcmMessageId,
    ValueGetter<String?>?
    fcmMessageIdOrNull, // Helper for setting fcmMessageId to null
  }) {
    return NotificationModel(
      id: id ?? this.id,
      // Handle setting userId explicitly OR setting it to null
      userId: userIdOrNull != null ? userIdOrNull() : (userId ?? this.userId),
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isScheduled: isScheduled ?? this.isScheduled,
      // Handle setting payload explicitly OR setting it to null
      payload:
          payloadOrNull != null ? payloadOrNull() : (payload ?? this.payload),
      // Handle setting fcmMessageId explicitly OR setting it to null
      fcmMessageId:
          fcmMessageIdOrNull != null
              ? fcmMessageIdOrNull()
              : (fcmMessageId ?? this.fcmMessageId),
    );
  }

  // --- Convenience Getter ---
  bool get hasPayload => payload != null && payload!.isNotEmpty;

  // --- toString (Provided by Equatable if stringify is true) ---
  @override
  bool get stringify => true; // Makes Equatable generate a useful toString
}
