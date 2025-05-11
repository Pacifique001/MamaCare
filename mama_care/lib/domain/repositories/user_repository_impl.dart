import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/user_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Assuming Firestore for data storage

@Injectable(
  as: UserRepository,
) // Registers this implementation for the abstract class
class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl(this._firestore);

  @override
  Future<UserModel> getUserById(String patientId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(patientId).get();

      if (!userDoc.exists) {
        throw Exception('User with ID $patientId not found');
      }

      // Convert Firestore document to UserModel
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }
}
