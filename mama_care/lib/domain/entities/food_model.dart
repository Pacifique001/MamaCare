// lib/domain/entities/food_model.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:mama_care/injection.dart'; // Assuming locator is setup for Uuid
import 'dart:convert'; // For JSON encoding/decoding benefits list

class FoodModel extends Equatable {
  final String id; // Unique ID for the food item
  final String name; // Renamed from foodName for consistency
  final String description;
  final String category; // Added category back from AssetsHelper data
  final String? imageUrl; // Made nullable if some foods might not have images
  final List<String> benefits; // Keep as list
  final bool isFavorite; // Keep for user interaction state

  const FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category, // Added category
    this.imageUrl, // Nullable
    this.benefits = const [], // Default to empty list
    this.isFavorite = false, // Default to false
  });

  // Factory constructor to create from a map (e.g., from AssetsHelper or DB)
  factory FoodModel.fromMap(Map<String, dynamic> map) {
    final uuid = locator<Uuid>(); // Get Uuid instance

    // Helper function to safely cast list elements
    List<String> parseBenefits(dynamic benefitsData) {
      if (benefitsData is List) {
        // Filter out nulls and ensure elements are strings
        return benefitsData.whereType<String>().toList();
      } else if (benefitsData is String) {
        // If benefits are stored as a JSON string in DB
        try {
          final decoded = jsonDecode(benefitsData);
          if (decoded is List) {
            return decoded.whereType<String>().toList();
          }
        } catch (e) {
          // Handle potential JSON decoding error
          print("Error decoding benefits JSON: $e"); // Use logger ideally
        }
      }
      return []; // Default to empty list if parsing fails or data is missing/wrong type
    }

    return FoodModel(
      // Generate ID if 'id' field is not present in the map (e.g., from AssetsHelper)
      // If reading from DB where ID exists, use map['id']
      id: map['id'] as String? ?? uuid.v4(),
      // Use 'food_name' from AssetsHelper data, provide default
      name: map['name'] as String? ?? 'Unknown Food',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General', // Get category
      imageUrl: map['imageUrl'] as String?, // Allow null
      // Parse benefits carefully, default to empty list
      benefits: parseBenefits(
        map['benefits'] ?? map['benefitsJson'],
      ), // Check for list or JSON string
      // Default isFavorite to false if missing, handle integer from DB (0/1)
      isFavorite:
          (map['isFavorite'] is bool)
              ? map['isFavorite']
              : (map['isFavorite'] == 1), // Handle integer case from SQLite
    );
  }

  // Method to convert instance to a map suitable for SQLite
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name, // Use 'name' consistently
      'description': description,
      'category': category, // Add category
      'imageUrl': imageUrl, // Store nullable URL
      // Store list as a JSON encoded string in SQLite
      'benefitsJson': jsonEncode(benefits),
      // Store boolean as an integer (0 for false, 1 for true) in SQLite
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Copy with method (Updated to include category)
  FoodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category, // Added category
    String? imageUrl,
    List<String>? benefits,
    bool? isFavorite,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category, // Added category
      imageUrl: imageUrl ?? this.imageUrl,
      benefits: benefits ?? this.benefits,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category, // Added category
    imageUrl,
    benefits,
    isFavorite,
  ];
}
