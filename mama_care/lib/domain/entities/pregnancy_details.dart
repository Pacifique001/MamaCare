import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:flutter/foundation.dart'; // For debugPrint

part 'pregnancy_details.g.dart'; // Ensure this file will be generated

// --- Helper Functions for JSON/DB Serialization ---

// Parses nullable date fields (like startingDay)
DateTime? _dateTimeFromJsonNullable(dynamic jsonValue) {
  if (jsonValue == null) return null;
  if (jsonValue is Timestamp) {
    return jsonValue.toDate();
  }
  if (jsonValue is String) {
    // Try parsing ISO8601 string
    return DateTime.tryParse(jsonValue);
  }
  if (jsonValue is int) {
    // Assume milliseconds since epoch if it's an int
    return DateTime.fromMillisecondsSinceEpoch(jsonValue);
  }
  debugPrint(
    "[PregnancyDetails] Warning: Unexpected type for nullable date parsing: ${jsonValue.runtimeType}, value: $jsonValue",
  );
  return null; // Return null if type is unexpected for a nullable field
}

// Converts nullable DateTime to ISO8601 String? (for JSON/SQLite TEXT)
String? _dateTimeToJsonNullable(DateTime? dateTime) {
  return dateTime?.toIso8601String();
}

// --- Conversion Function For Non-Nullable dueDate ---
DateTime _dueDateFromJson(dynamic json) {
  if (json == null) {
    throw FormatException("dueDate cannot be null");
  }

  if (json is Timestamp) {
    return json.toDate();
  }
  if (json is String) {
    final date = DateTime.tryParse(json);
    if (date == null) {
      throw FormatException("Invalid date string format for dueDate: '$json'");
    }
    return date;
  }
  if (json is int) {
    return DateTime.fromMillisecondsSinceEpoch(json);
  }

  throw FormatException(
    "Unexpected data type (${json.runtimeType}) for dueDate",
  );
}

String _dueDateToJson(DateTime date) {
  return date.toIso8601String();
}

// --- Entity Definition ---

@JsonSerializable(explicitToJson: true)
class PregnancyDetails extends Equatable {
  final String userId; // Assuming this is always required and non-null

  // Nullable starting day
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? startingDay;

  // Keep these nullable if they might not always be present or calculated
  final int? weeksPregnant;
  final int? daysPregnant;
  final double? babyHeight;
  final double? babyWeight;

  // Non-nullable due date
  @JsonKey(fromJson: _dueDateFromJson, toJson: _dueDateToJson)
  final DateTime dueDate;

  const PregnancyDetails({
    required this.userId,
    this.startingDay, // Nullable
    this.weeksPregnant, // Nullable
    this.daysPregnant, // Nullable
    this.babyHeight, // Nullable
    this.babyWeight, // Nullable
    required this.dueDate, // Required
  });

  // --- JSON Serialization ---
  factory PregnancyDetails.fromJson(Map<String, dynamic> json) =>
      _$PregnancyDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PregnancyDetailsToJson(this);

  // --- Calculated properties ---
  int? get calculatedCurrentWeek {
    if (startingDay == null) return null;
    final difference = DateTime.now().difference(startingDay!);
    if (difference.isNegative) return 0;
    return (difference.inDays / 7).floor();
  }

  int? get calculatedDaysIntoWeek {
    if (startingDay == null) return null;
    final difference = DateTime.now().difference(startingDay!);
    if (difference.isNegative) return 0;
    return difference.inDays % 7;
  }

  DateTime get estimatedConceptionDate =>
      dueDate.subtract(const Duration(days: 266));

  int? get daysRemaining {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(now)) {
      return null; // Or negative days past due
    }
    return due.difference(now).inDays;
  }

  // --- Copy With Method ---
  // Allows creating modified copies of the instance
  PregnancyDetails copyWith({
    String? userId,
    ValueGetter<DateTime?>?
    startingDay, // Use ValueGetter for nullable differentiation
    int? weeksPregnant,
    int? daysPregnant,
    double? babyHeight,
    double? babyWeight,
    DateTime?
    dueDate, // Parameter allows null override for flexibility if needed during copy
  }) {
    return PregnancyDetails(
      userId: userId ?? this.userId,
      // Use ValueGetter pattern to explicitly handle setting null
      startingDay: startingDay != null ? startingDay() : this.startingDay,
      weeksPregnant: weeksPregnant ?? this.weeksPregnant,
      daysPregnant: daysPregnant ?? this.daysPregnant,
      babyHeight: babyHeight ?? this.babyHeight,
      babyWeight: babyWeight ?? this.babyWeight,
      // If dueDate parameter is null, keep the existing non-null dueDate
      dueDate: dueDate ?? this.dueDate,
    );
  }

  // --- Equatable Props ---
  // Used for value comparison
  @override
  List<Object?> get props => [
    userId,
    startingDay,
    weeksPregnant,
    daysPregnant,
    babyHeight,
    babyWeight,
    dueDate, // Include non-nullable dueDate
  ];
}
