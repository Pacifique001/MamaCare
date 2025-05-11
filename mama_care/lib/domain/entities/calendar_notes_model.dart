import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calendar_notes_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CalendarNote extends Equatable {
  final String? id;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  const CalendarNote({
    this.id,
    required this.date,
    required this.note, 
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarNote.withDefaults({
    String? id,
    required DateTime date,
    required String note,
    required String userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarNote(
      id: id,
      date: date,
      note: note,
      userId: userId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory CalendarNote.fromJson(Map<String, dynamic> json) =>
      _$CalendarNoteFromJson(json);

  factory CalendarNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarNote(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  // Add fromMap method for SQLite database
  factory CalendarNote.fromMap(Map<String, dynamic> map) => CalendarNote(
    id: map['id'],
    date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    note: map['note'],
    userId: map['userId'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
  );

  Map<String, dynamic> toJson() => _$CalendarNoteToJson(this);

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(date),
        'not': note,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
      
  // Add toMap method for SQLite database
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'note': note,
    'userId': userId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  CalendarNote copyWith({
    String? id,
    DateTime? date,
    String? note,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarNote(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  

  @override
  List<Object?> get props => [id, date, note, userId, createdAt, updatedAt];

  // Additional utility methods
  factory CalendarNote.empty() => CalendarNote(
        date: DateTime.now(),
        note: '',
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory CalendarNote.create({
  required DateTime date,
  required String note,
  required String userId,
 }) => CalendarNote(
      date: date,
      note: note,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      id: '', // Add empty string as default id
    );

  bool get isEmpty => note.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => 'CalendarNote(id: $id, date: $date, note: $note)';
}