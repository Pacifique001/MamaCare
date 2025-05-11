import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/risk_detector_repository.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mama_care/domain/entities/risk_assessment_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mama_care/domain/entities/risk_data.dart';

@Injectable(as: RiskDetectorRepository)
class RiskDetectorRepositoryImpl implements RiskDetectorRepository {
  final Dio _dio;
  final DatabaseHelper _databaseHelper;
  final FirebaseMessaging _firebaseMessaging;
  static const String _apiUrl = 'https://your-ai-api-endpoint.com/risk-detection'; // Replace with your AI API endpoint

  RiskDetectorRepositoryImpl(
    this._dio,
    this._databaseHelper,
    this._firebaseMessaging,
  );

  @override
  Future<RiskAssessmentModel> assessRisk(
    int age,
    int systolicBP,
    int diastolicBP,
    double bs,
    double bodyTemp,
    int heartRate,
  ) async {
    try {
      final response = await _dio.post(
        'https://api.example.com/risk-assessment',
        data: {
          'age': age,
          'systolicBP': systolicBP,
          'diastolicBP': diastolicBP,
          'bs': bs,
          'bodyTemp': bodyTemp,
          'heartRate': heartRate,
        },
      );

      if (response.statusCode == 200) {
        final result = RiskAssessmentModel.fromJson(response.data);
        await _databaseHelper.insert('risk_assessments', result.toJson());
        return result;
      } else {
        throw Exception('Failed to assess risk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to assess risk: ${e.toString()}');
    }
  }

  @override
  Future<List<RiskAssessmentModel>> getRiskAssessmentHistory() async {
    try {
      final List<Map<String, dynamic>> results =
          await _databaseHelper.query('risk_assessments');
      return results.map((json) => RiskAssessmentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch risk assessment history: ${e.toString()}');
    }
  }

  @override
  Future<void> sendRiskAlert(String message) async {
    try {
      await _firebaseMessaging.sendMessage(
        to: '/topics/risk_alerts',
        data: {
          'message': message,
        },
      );
    } catch (e) {
      throw Exception('Failed to send risk alert: ${e.toString()}');
    }
  }

  @override
  Future<RiskData> fetchData(int age, int systolicBP, int diastolicBP, double bs, double bodyTemp, int heartRate) async {
    try {
      final response = await _dio.post(
        'https://api.example.com/risk-assessment',
        data: {
          'age': age,
          'systolicBP': systolicBP,
          'diastolicBP': diastolicBP,
          'bs': bs,
          'bodyTemp': bodyTemp,
          'heartRate': heartRate,
        },
      );

      if (response.statusCode == 200) {
        return response.data['riskLevel'] ?? 'Low'; // Default to 'Low' if riskLevel is null
      } else {
        throw Exception('Failed to fetch risk data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch risk data: ${e.toString()}');
    }
  }

  @override
  Future<RiskData> getRiskData(Map<String, dynamic> inputData) async {
    try {
      // Make the API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inputData),
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Parse the response body
        final responseData = jsonDecode(response.body);
        return RiskData.fromJson(responseData);
      } else {
        // Handle API errors
        throw Exception('Failed to fetch risk data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Failed to fetch risk data: ${e.toString()}');
    }
  }

  void _handleDioException(DioException e) {
    if (e.response != null) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.statusMessage}");
    } else {
      print("Dio Error: ${e.message}");
    }
  }
}
