import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/pregnancy_detail_repository.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@Injectable(as: PregnancyDetailRepository)
class PregnancyDetailRepositoryImpl implements PregnancyDetailRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;
  final FirebaseMessaging _firebaseMessaging;

  PregnancyDetailRepositoryImpl(
    this._firebaseAuth,
    this._firestore,
    this._databaseHelper,
    this._firebaseMessaging,
  );

  @override
  Future<void> addPregnancyDetail(PregnancyDetails details) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore
            .collection('pregnancy_details')
            .doc(user.uid)
            .set(details.toJson());
        await _databaseHelper.insert('pregnancy_details', details.toJson());
      }
    } catch (e) {
      throw Exception('Failed to add pregnancy details: ${e.toString()}');
    }
  }

  @override
  Future<PregnancyDetails?> getPregnancyDetails(String userId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final doc =
            await _firestore
                .collection('pregnancy_details')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          return PregnancyDetails.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch pregnancy details: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePregnancyDetail(PregnancyDetails details) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore
            .collection('pregnancy_details')
            .doc(user.uid)
            .update(details.toJson());
        await _databaseHelper.update(
          'pregnancy_details',
          details.toJson(),
          where: 'userId = ?',
          whereArgs: [user.uid],
        );
      }
    } catch (e) {
      throw Exception('Failed to update pregnancy details: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePregnancyDetail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('pregnancy_details').doc(user.uid).delete();
        await _databaseHelper.delete(
          'pregnancy_details',
          where: 'userId = ?',
          whereArgs: [user.uid],
        );
      }
    } catch (e) {
      throw Exception('Failed to delete pregnancy details: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPregnancyUpdateNotification(String message) async {
    try {
      await _firebaseMessaging.sendMessage(
        to: '/topics/pregnancy_updates',
        data: {'message': message},
      );
    } catch (e) {
      throw Exception('Failed to send notification: ${e.toString()}');
    }
  }

  @override
  Future<void> savePregnancyDetails(PregnancyDetails details) async {
    await _databaseHelper.insert('pregnancy_details', details.toJson());
  }
}
