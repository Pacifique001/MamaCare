// lib/domain/usecases/nurse_detail_usecase.dart

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/repositories/nurse_repository.dart'; // Import Repository interface
import 'package:mama_care/domain/entities/nurse.dart';          // Import Entity
import 'package:mama_care/core/error/exceptions.dart';

@injectable
class NurseDetailUseCase {
  final NurseRepository _repository;
  final Logger _logger;

  NurseDetailUseCase(this._repository, this._logger);

  /// Gets a specific nurse's profile by ID.
  Future<Nurse?> getNurseProfile(String nurseId) async {
     _logger.d("UseCase: Getting nurse profile for ID $nurseId...");
     if (nurseId.isEmpty) {
        _logger.w("UseCase: Invalid nurseId provided (empty).");
        return null;
     }
     try {
        final nurse = await _repository.getNurseById(nurseId);
        if (nurse == null) {
           _logger.w("UseCase: Nurse $nurseId not found by repository.");
           throw DataNotFoundException("Nurse profile not found.");
        } else {
            _logger.i("UseCase: Retrieved nurse ${nurse.name}.");
        }
        return nurse;
     } on AppException { // Catch known app exceptions and re-throw
         rethrow;
     } catch (e, s) { // Catch unexpected errors
        _logger.e("UseCase: Unexpected error getting nurse profile $nurseId.", error: e, stackTrace: s);
        throw DataProcessingException("Could not retrieve nurse profile.", cause: e);
     }
  }
}