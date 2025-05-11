class RiskAssessmentModel {
  final String id;
  final DateTime timestamp;
  final int age;
  final int systolicBP;
  final int diastolicBP;
  final double bs;
  final double bodyTemp;
  final int heartRate;
  final String riskLevel;

  RiskAssessmentModel({
    required this.id,
    required this.timestamp,
    required this.age,
    required this.systolicBP,
    required this.diastolicBP,
    required this.bs,
    required this.bodyTemp,
    required this.heartRate,
    required this.riskLevel,
  });

  factory RiskAssessmentModel.fromJson(Map<String, dynamic> json) {
    return RiskAssessmentModel(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      age: json['age'],
      systolicBP: json['systolicBP'],
      diastolicBP: json['diastolicBP'],
      bs: json['bs'],
      bodyTemp: json['bodyTemp'],
      heartRate: json['heartRate'],
      riskLevel: json['riskLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'age': age,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'bs': bs,
      'bodyTemp': bodyTemp,
      'heartRate': heartRate,
      'riskLevel': riskLevel,
    };
  }
} 