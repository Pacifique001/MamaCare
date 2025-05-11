import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/timeline_repository.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';

@injectable
class TimelineUseCase {
  final TimelineRepository _timelineRepository;

  TimelineUseCase(this._timelineRepository);

  Future<PregnancyDetails?> getPregnancyDetails() async {
    try {
      return await _timelineRepository.getPregnancyDetails();
    } catch (e) {
      print("Error fetching pregnancy details: $e");
      return null;
    }
  }
}
