import 'package:injectable/injectable.dart';

import '../../domain/entities/pregnancy_details.dart';

@factoryMethod
abstract class PregnancyDetailRepository {
  Future<void> addPregnancyDetail(PregnancyDetails details);
  Future<PregnancyDetails?> getPregnancyDetails(String userId);
  Future<void> updatePregnancyDetail(PregnancyDetails details);
  Future<void> deletePregnancyDetail();
  Future<void> sendPregnancyUpdateNotification(String message);
  Future<void> savePregnancyDetails(PregnancyDetails details);
}