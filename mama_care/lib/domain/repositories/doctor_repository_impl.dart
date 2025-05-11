// lib/data/repositories/doctor_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/data/repositories/doctor_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // Using UserModel instead of Doctor

@Injectable(as: DoctorRepository)
class DoctorRepositoryImpl implements DoctorRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  // Using 'users' collection instead of 'doctors'
  late final CollectionReference _usersCollection = _firestore.collection(
    'users',
  );

  DoctorRepositoryImpl(this._firestore, this._logger) {
    _logger.i("DoctorRepositoryImpl initialized.");
  }

  @override
  Future<List<UserModel>> getAvailableDoctors({String? specialtyFilter}) async {
    _logger.d(
      "Repository: Fetching available doctors${specialtyFilter != null ? ' with specialty: $specialtyFilter' : ''}...",
    );
    try {
      // Start with querying users where role is 'doctor'
      Query query = _usersCollection.where('role', isEqualTo: 'doctor');

      // Add specialty filtering if available (assuming specialty field exists in user document)
      if (specialtyFilter != null && specialtyFilter.isNotEmpty) {
        query = query.where('specialty', isEqualTo: specialtyFilter);
        _logger.d("Applying specialty filter: $specialtyFilter");
      }

      // Order results by name
      query = query.orderBy('name');

      final querySnapshot = await query.get();

      final doctors =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Add the ID to the data map
            data['id'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();

      _logger.i("Repository: Fetched ${doctors.length} available doctors.");
      return doctors;
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error fetching doctors",
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        "Error fetching doctors from database.",
        statusCode: e.code.hashCode,
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error fetching doctors",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException("Could not process doctor data.", cause: e);
    }
  }

  @override
  Future<UserModel?> getDoctorById(String doctorId) async {
    _logger.d("Repository: Fetching doctor by ID: $doctorId");
    if (doctorId.isEmpty) return null;

    try {
      final docSnapshot = await _usersCollection.doc(doctorId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Verify this is actually a doctor
        if (data['role'] != 'doctor') {
          _logger.w("Repository: User $doctorId is not a doctor.");
          return null;
        }

        _logger.i("Repository: Found doctor $doctorId.");

        // Add the ID to the data map
        data['id'] = docSnapshot.id;
        return UserModel.fromMap(data);
      } else {
        _logger.w("Repository: Doctor with ID $doctorId not found.");
        return null;
      }
    } on FirebaseException catch (e, stackTrace) {
      _logger.e(
        "Repository: Firestore error fetching doctor $doctorId",
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        "Error fetching doctor details.",
        statusCode: e.code.hashCode,
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected error fetching doctor $doctorId",
        error: e,
        stackTrace: stackTrace,
      );
      throw DataProcessingException(
        "Could not process doctor details.",
        cause: e,
      );
    }
  }
}
