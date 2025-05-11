import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/dashboard_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/data/repositories/appointment_repository.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';

@injectable
class DashboardUseCase {
  final DashboardRepository _repo;
  final AppointmentRepository _appointmentRepo;

  DashboardUseCase(this._repo, this._appointmentRepo);

  Future<UserModel?> getUserDetails(String userId) => _repo.getUserDetails(userId);
  Future<PregnancyDetails?> getPregnancyDetails(String userId) => _repo.getPregnancyDetails(userId);
  
  Future<List<Appointment>?> getAppointments(String userId) async {
    try {
      final user = await getUserDetails(userId);
      if (user == null) return [];
      
      return await _appointmentRepo.getUserAppointments(user.id);
    } catch (e) {
      throw AppointmentException('Failed to fetch appointments', e);
    }
  }

  Future<void> sendNotification(String message) => _repo.sendNotification(message);
}

class AppointmentException implements Exception {
  final String message;
  final dynamic cause;

  AppointmentException(this.message, [this.cause]);

  @override
  String toString() => 'AppointmentException: $message${cause != null ? ' - $cause' : ''}';
}