// lib/domain/usecases/doctor_usecase.dart

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/doctor_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';

@injectable
class DoctorUseCase {
  final DoctorRepository _repository;
  final Logger _logger;

  DoctorUseCase(this._repository, this._logger);

  /// Gets a list of available doctors, potentially applying filters.
  Future<List<UserModel>> getAvailableDoctors({String? specialtyFilter}) async {
    _logger.d("UseCase: Getting available doctors...");
    try {
      final doctors = await _repository.getAvailableDoctors(
        specialtyFilter: specialtyFilter,
      );
      _logger.i("UseCase: Retrieved ${doctors.length} available doctors.");

      // Sort doctors by name if needed
      doctors.sort((a, b) => a.name.compareTo(b.name));

      return doctors;
    } catch (e) {
      _logger.e("UseCase: Failed to get available doctors.", error: e);
      rethrow;
    }
  }

  /// Gets a specific doctor by ID.
  Future<UserModel?> getDoctorById(String doctorId) async {
    _logger.d("UseCase: Getting doctor by ID $doctorId...");
    try {
      final doctor = await _repository.getDoctorById(doctorId);
      if (doctor == null) {
        _logger.w("UseCase: Doctor $doctorId not found.");
      } else {
        _logger.i("UseCase: Retrieved doctor ${doctor.name}.");
      }
      return doctor;
    } catch (e) {
      _logger.e("UseCase: Failed to get doctor $doctorId.", error: e);
      rethrow;
    }
  }
}
