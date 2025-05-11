import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/risk_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@factoryMethod
abstract class RiskDetectorRepository {
  static const String _apiUrl = 'https://your-ai-api-endpoint.com/risk-detection'; // Replace with your AI API endpoint

  Future<RiskData> fetchData(int age, int systolicBP, int diastolicBP, double bs, double bodyTemp, int heartRate);

  Future<RiskData> getRiskData(Map<String, dynamic> inputData) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return RiskData.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch risk data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch risk data: ${e.toString()}');
    }
  }
}