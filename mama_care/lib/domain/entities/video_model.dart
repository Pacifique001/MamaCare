import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For @immutable

@immutable // Mark as immutable
class VideoModel extends Equatable { // Extend Equatable
  final String id;
  final String title;
  final String description;
  final String url; // Assuming this holds the video stream URL
  final String thumbnailUrl;
  // isFavorite status: Kept as per original model, but ideally managed per user.
  final bool isFavorite;
  final String category;
  final int? publishedAt; // Optional: Store publish timestamp (MillisecondsSinceEpoch)
  final int? duration; // Optional: Store duration in seconds

  // Use a const constructor for immutable class
  const VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url, // Use 'url' for the video stream
    required this.thumbnailUrl,
    this.isFavorite = false, // Default to false if kept
    required this.category,
    this.publishedAt, // Optional
    this.duration,    // Optional
    // Removed the redundant 'videoUrl' parameter here
  });

  // Factory constructor for creating from JSON/Map (e.g., from API or DB)
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      // Use null-aware operators and defaults for safety
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '', // Map 'url' from JSON
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      // Convert integer from DB back to boolean
      isFavorite: (json['isFavorite'] as int? ?? 0) == 1, // Convert Int to Bool
      category: json['category'] as String? ?? 'Uncategorized',
      publishedAt: json['publishedAt'] as int?,
      duration: json['duration'] as int?,
    );
  }

  // Alias for consistency if needed elsewhere
  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel.fromJson(map);

  // Method to convert instance to a Map suitable for DB or API JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url, // Map 'url' to JSON
      'thumbnailUrl': thumbnailUrl,
      // Convert boolean to integer (0 or 1) for DB storage
      'isFavorite': isFavorite ? 1 : 0, // Convert Bool to Int
      'category': category,
      'publishedAt': publishedAt,
      'duration': duration,
    };
  }

   // Alias for consistency if needed elsewhere
   Map<String, dynamic> toMap() => toJson();


  // copyWith method for creating modified copies (useful for state updates)
  // Simplified handling of nullable fields
  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? thumbnailUrl,
    bool? isFavorite,
    String? category,
    int? publishedAt, // Directly accept int?
    int? duration,    // Directly accept int?
    // Add flags if you need to explicitly set optional fields to null
    bool setPublishedAtNull = false,
    bool setDurationNull = false,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      // If setPublishedAtNull is true, set to null, otherwise update or keep existing
      publishedAt: setPublishedAtNull ? null : (publishedAt ?? this.publishedAt),
      // If setDurationNull is true, set to null, otherwise update or keep existing
      duration: setDurationNull ? null : (duration ?? this.duration),
    );
  }

  // --- Equatable Implementation ---
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        url, // Include 'url' in props
        thumbnailUrl,
        isFavorite,
        category,
        publishedAt,
        duration,
      ];

  // Optional: Improve toString for debugging (provided by Equatable if stringify=true)
  @override
  bool get stringify => true;
}