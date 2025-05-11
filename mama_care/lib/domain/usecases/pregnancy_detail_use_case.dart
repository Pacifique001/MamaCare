
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/pregnancy_detail_repository.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';

@injectable
class PregnancyDetailUseCase {
  final PregnancyDetailRepository _pregnancyDetailRepository;

  PregnancyDetailUseCase(this._pregnancyDetailRepository);

  Future<PregnancyDetails?> getPregnancyDetails(String userId) async {
    try {
      return await _pregnancyDetailRepository.getPregnancyDetails(userId);
    } catch (e) {
      print("Error fetching pregnancy details: $e");
      return null;
    }
  }

  Future<void> savePregnancyDetails(PregnancyDetails details) async {
    try {
      await _pregnancyDetailRepository.savePregnancyDetails(details);
    } catch (e) {
      print("Error saving pregnancy details: $e");
    }
  }

  Future<void> addPregnancyDetail(PregnancyDetails details) async {
    try {
      await _pregnancyDetailRepository.addPregnancyDetail(details);
    } catch (e) {
      print("Error adding pregnancy details: $e");
    }
  }
}
