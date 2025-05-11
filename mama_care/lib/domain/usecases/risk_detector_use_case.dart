import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/risk_detector_repository.dart';
import 'package:mama_care/domain/entities/risk_data.dart';

@injectable
class RiskDetectorUseCase {
  final RiskDetectorRepository _riskDetectorRepository;

  RiskDetectorUseCase(this._riskDetectorRepository);

  Future<RiskData> fetchRiskData(
    int age,
    int systolicBP,
    int diastolicBP,
    double bs,
    double bodyTemp,
    int heartRate,
  ) async {
    try {
      return await _riskDetectorRepository.fetchData(
        age,
        systolicBP,
        diastolicBP,
        bs,
        bodyTemp,
        heartRate,
      );
    } catch (e) {
      print("Error fetching risk data: $e");
      rethrow;
    }
  }

  Future<RiskData> getRiskData(Map<String, dynamic> inputData) async {
    try {
      // Call the AI API to get risk data
      final result = await _riskDetectorRepository.getRiskData(inputData);
      return result;
    } catch (e) {
      throw Exception('Failed to get risk data: ${e.toString()}');
    }
  }
}
