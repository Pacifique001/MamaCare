// lib/domain/entities/article_model.dart

import 'dart:convert'; // For jsonEncode/Decode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For @immutable

@immutable
class ArticleModel extends Equatable {
  final String id;
  final String title;
  final String content; // Renamed from detail
  final String author;
  final String imageUrl; // Primary image source (network URL)
  final DateTime publishDate;
  final bool isBookmarked;
  final List<String> tags;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.imageUrl,
    required this.publishDate,
    this.isBookmarked = false,
    this.tags = const [],
  });

  // --- Map/JSON Conversion (Manual) ---

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? decodedPayload;
    return ArticleModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'No Title',
      // Check for 'content' first, then fallback to 'detail' if needed for compatibility
      content: map['content'] as String? ?? map['detail'] as String? ?? '',
      author: map['author'] as String? ?? 'Unknown Author',
      // Check for 'imageUrl' first, then fallback to 'image' if needed
      imageUrl: map['imageUrl'] as String? ?? map['image'] as String? ?? '',
      publishDate: _parseDate(map['publishDate']),
      isBookmarked: (map['isBookmarked'] == 1 || map['isBookmarked'] == true),
      tags: _parseTags(map['tags']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'imageUrl': imageUrl, // Use imageUrl key
      'publishDate': publishDate.toIso8601String(),
      'isBookmarked': isBookmarked ? 1 : 0, // Store bool as int for SQLite
      'tags': jsonEncode(tags), // Store tags as JSON string for SQLite
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'imageUrl': imageUrl,
      'publishDate': publishDate.toIso8601String(), // Store date as ISO string
      'isBookmarked':
          isBookmarked ? 1 : 0, // *** Store bool as INTEGER (0 or 1) ***
      'tags': jsonEncode(tags), // *** Store List as JSON STRING ***
    };
  }
  //

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      ArticleModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap(); // Use toMap for consistency

  // --- Helper Methods ---
  static DateTime _parseDate(dynamic dateInput) {
    if (dateInput is String) {
      try {
        return DateTime.parse(dateInput);
      } catch (_) {}
    }
    if (dateInput is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateInput);
    }
    if (dateInput is Timestamp) {
      return dateInput.toDate();
    } // Handle Firestore Timestamp
    return DateTime.now(); // Fallback
  }

  static List<String> _parseTags(dynamic tagsJson) {
    if (tagsJson is List)
      return List<String>.from(tagsJson.map((t) => t.toString()));
    if (tagsJson is String) {
      try {
        final decoded = jsonDecode(tagsJson);
        if (decoded is List)
          return List<String>.from(decoded.map((t) => t.toString()));
      } catch (_) {}
    }
    return const [];
  }

  // --- Equatable ---
  @override
  List<Object?> get props => [
    id,
    title,
    content,
    author,
    imageUrl,
    publishDate,
    isBookmarked,
    tags,
  ];
  @override
  bool get stringify => true;

  // --- CopyWith ---
  ArticleModel copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    String? imageUrl,
    DateTime? publishDate,
    bool? isBookmarked,
    List<String>? tags,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      publishDate: publishDate ?? this.publishDate,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      tags: tags ?? this.tags,
    );
  }
}
