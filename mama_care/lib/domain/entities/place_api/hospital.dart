import 'package:json_annotation/json_annotation.dart';

part 'hospital.g.dart';

@JsonSerializable()
class Hospital {
  final String id;
  final String name;
  final String address;
  final Location location;
  final List<Hospital> results;
  final double? rating;
  final bool isOpen;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.results,
    this.rating,
    this.isOpen = false,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      location: Location.fromJson(json['location']),
      results: List<Hospital>.from(json['results'].map((x) => Hospital.fromJson(x))),
      rating: json['rating']?.toDouble(),
      isOpen: json['opening_hours']?['open_now'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': location.toJson(),
      'results': results.map((x) => x.toJson()).toList(),
      'rating': rating,
      'isOpen': isOpen,
    };
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      json['latitude'] as double,
      json['longitude'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
