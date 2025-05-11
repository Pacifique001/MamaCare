import 'package:json_annotation/json_annotation.dart';

part 'risk_data.g.dart'; // This part file will be generated for JSON serialization

@JsonSerializable()
class RiskData {
  final String riskLevel; // The level of risk (e.g., low, medium, high)
  final String description; // A description of the risk
  final List<String> recommendations; // Recommendations based on the risk

  // Constructor
  RiskData({
    required this.riskLevel,
    required this.description,
    required this.recommendations,
  });

  // Factory method for creating a RiskData instance from JSON
  factory RiskData.fromJson(Map<String, dynamic> json) => _$RiskDataFromJson(json);

  // Method for converting a RiskData instance to JSON
  Map<String, dynamic> toJson() => _$RiskDataToJson(this);
} 