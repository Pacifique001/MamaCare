import 'dart:async';
import 'dart:convert'; // For jsonEncode/Decode
import 'dart:io'; // For HttpException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mama_care/data/local/database_helper.dart'; // Keep for saving history

class RiskDetectorViewModel extends ChangeNotifier {
  // Removed UseCase for direct API call example
  final DatabaseHelper _databaseHelper;

  // --- State Variables ---
  bool _isLoading = false;
  String? _predictedRiskLevel; // Stores the predicted level string
  String? _adviceMessage; // Stores the advice message
  Map<String, double>? _probabilities; // Stores probabilities
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get predictedRiskLevel => _predictedRiskLevel;
  String? get adviceMessage => _adviceMessage;
  Map<String, double>? get probabilities => _probabilities;
  String? get errorMessage => _errorMessage;

  // --- API Configuration ---
  // TODO: Replace with your deployed Render URL in production
  // For local testing, use your machine's IP if testing on a real device,
  // or http://10.0.2.2:8000 for Android emulator, or http://127.0.0.1:8000 for iOS simulator/web/desktop
  // Make sure your FastAPI server is running!
 static const String _baseUrl = "http://10.0.2.2:8000"; // <-- CHANGE FOR LOCAL/PRODUCTION
static const String _predictEndpoint = "/predict";

  RiskDetectorViewModel(this._databaseHelper);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearResults() {
    _predictedRiskLevel = null;
    _adviceMessage = null;
    _probabilities = null;
    _errorMessage = null;
  }

  void _setResults(String riskLevel, String advice, Map<String, double> probs) {
    _predictedRiskLevel = riskLevel;
    _adviceMessage = advice;
    _probabilities = probs;
    _errorMessage = null; // Clear previous errors on success
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    _predictedRiskLevel = null; // Clear results on error
    _adviceMessage = null;
    _probabilities = null;
    notifyListeners();
  }

  // Renamed from getRiskData to better reflect its action
  Future<void> fetchPredictionAndAdvice({
    required int age,
    required int systolicBP,
    required int diastolicBP,
    required double bs,
    required double bodyTemp,
    required int heartRate,
  }) async {
    _setLoading(true);
    _clearResults(); // Clear previous results

    final url = Uri.parse(_baseUrl + _predictEndpoint);
    final headers = {"Content-Type": "application/json"};
    // Prepare data matching FastAPI Pydantic model
    final body = jsonEncode({
      'age': age,
      'systolicBP': systolicBP, // Ensure camelCase matches Pydantic model
      'diastolicBP': diastolicBP,
      'bs': bs,
      'bodyTemp': bodyTemp,
      'heartRate': heartRate,
    });

    try {
      print('Sending request to $url with body: $body'); // Debugging
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20)); // Add timeout

      print('Received response: ${response.statusCode}'); // Debugging
      // print('Response body: ${response.body}'); // Debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final String riskLevel = responseData['predicted_risk_level'] as String;
        final String advice = responseData['advice_message'] as String;
        // Parse probabilities carefully
        final Map<String, dynamic> probsRaw =
            responseData['probabilities'] as Map<String, dynamic>;
        final Map<String, double> probsDouble = probsRaw.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        _setResults(riskLevel, advice, probsDouble);

        // --- Save to local DB after successful API call ---
        await _saveToHistory(
          age: age,
          sbp: systolicBP,
          dbp: diastolicBP,
          bs: bs,
          temp: bodyTemp,
          heartRate: heartRate,
          result: riskLevel, // Save the string result
        );
        // --- End Save ---
      } else {
        // Try to parse error message from FastAPI if available
        String errorMsg = "Error: ${response.statusCode}";
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('detail')) {
            errorMsg += " - ${errorData['detail']}";
          }
        } catch (_) {
          errorMsg += " - Could not parse error details.";
        }
        print(errorMsg); // Log the specific error
        _setErrorMessage("Failed to get prediction. $errorMsg");
      }
    } on SocketException catch (e) {
      print("Network Error: $e");
      _setErrorMessage(
        "Network error. Please check your connection and ensure the server is running.",
      );
    } on FormatException catch (e) {
      print("Format Error (JSON Parsing): $e");
      _setErrorMessage("Error parsing server response.");
    } on TimeoutException catch (e) {
      print("Timeout Error: $e");
      _setErrorMessage(
        "Request timed out. The server might be busy or unreachable.",
      );
    } catch (e) {
      print("Unexpected Error: $e");
      _setErrorMessage("An unexpected error occurred: ${e.toString()}");
    } finally {
      _setLoading(false); // Ensure loading is always set to false
    }
  }

  // Helper to save to DB
  Future<void> _saveToHistory({
    required int age,
    required int sbp,
    required int dbp,
    required double bs,
    required double temp,
    required int heartRate,
    required String result,
  }) async {
    try {
      await _databaseHelper.insertPredictionHistory({
        'age': age,
        'sbp': sbp,
        'dbp': dbp,
        'bs': bs,
        'temp': temp,
        'heartRate': heartRate,
        'result': result, // Save the string prediction
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print("Prediction saved to history.");
    } catch (e) {
      print("Error saving prediction to history: $e");
      // Optionally notify the user or handle this error
    }
  }

  // Optional: Clear results manually if needed
  void clearPredictionData() {
    _clearResults();
    notifyListeners();
  }
}
