import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/dashboard_repository.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import '../../domain/entities/pregnancy_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // *** ADD FIRESTORE ***
// No need for FirebaseAuth here if userId is always passed in correctly
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart'; // Assuming you use logging

@Injectable(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  final DatabaseHelper _database;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore; // *** ADD FIRESTORE DEPENDENCY ***
  final Logger _log = Logger('DashboardRepositoryImpl'); // Add Logger

  // *** Update Constructor ***
  DashboardRepositoryImpl(
    this._database,
    this._messaging,
    this._firestore, // Inject Firestore
  );

  @override
  Future<UserModel?> getUserDetails(String id) async {
    // *** FIX: Filter by ID ***
    try {
      _log.fine('Querying local DB for user with id: $id');
      final results = await _database.query(
        DatabaseHelper.usersTable, // Use constant
        where: '${DatabaseHelper.colId} = ?', // Use constant for ID column
        whereArgs: [id],
        limit: 1,
      );
      if (results.isNotEmpty) {
        _log.fine('User found locally: $id');
        return UserModel.fromJson(results.first);
      } else {
        _log.warning('User not found locally: $id');
        // Optional: Add Firestore fallback here if local user might be missing
        return null;
      }
    } catch (e, stackTrace) {
      _log.severe(
        'Error fetching user details locally for id: $id',
        e,
        stackTrace,
      );
      // Re-throw or handle as appropriate
      throw Exception('Failed to get user details: $e');
    }
  }

  // In DashboardRepositoryImpl.dart

  // In DashboardRepositoryImpl.dart

  @override
  Future<PregnancyDetails?> getPregnancyDetails(String userId) async {
    _log.fine(
      'Attempting to get pregnancy details for user: $userId (Firestore-first)',
    );

    // 1. Try Firestore first
    try {
      _log.fine(
        'Querying Firestore top-level "pregnancy_details" collection for userId: $userId',
      ); // Corrected Log
      final querySnapshot = await _firestore
          .collection('pregnancy_details')
          .where('userId', isEqualTo: userId) 
          .limit(
            1,
          ) 
          .get(
            const GetOptions(source: Source.server),
          ); // Force server fetch for "Firestore-first"

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _log.info(
          'Pregnancy details found in Firestore for user: $userId. Document ID: ${doc.id}',
        );
        final data = doc.data() as Map<String, dynamic>;
        // Ensure your PregnancyDetails.fromJson can handle the 'id' if you intend to use it from the doc.
        // And that 'userId' from the query parameter is correctly used if it's not always in the doc.data()
        final details = PregnancyDetails.fromJson({
          ...data,
          'id': doc.id,
          'userId': userId,
        });

        // Asynchronously update local cache with the fresh Firestore data
        _database
            .upsertPregnancyDetail(details.toJson())
            .then(
              (_) => _log.fine(
                'Successfully updated local cache with Firestore data for user: $userId',
              ),
            )
            .catchError(
              (e, s) => _log.severe(
                'Failed to update local cache for user: $userId',
                e,
                s,
              ),
            );

        return details; // Return Firestore data
      } else {
        _log.warning(
          'Pregnancy details NOT found in Firestore for user: $userId in "pregnancy_details" collection. Attempting local DB fallback.',
        ); // Corrected Log
      }
    } catch (e, stackTrace) {
      _log.severe(
        'Error fetching pregnancy details from Firestore for user: $userId',
        e,
        stackTrace,
      );
    }

    // 2. If Firestore fails or returns no data, try local database
    _log.fine(
      'Attempting to load pregnancy details from local DB for user: $userId',
    );
    try {
      final localDetailsMap = await _database.getPregnancyDetails(userId);
      if (localDetailsMap != null) {
        _log.info(
          'Pregnancy details found locally for user: $userId (after Firestore attempt failed or yielded no data)',
        );
        return PregnancyDetails.fromJson(localDetailsMap);
      } else {
        _log.warning(
          'Pregnancy details not found in local DB either for user: $userId.',
        );
        return null;
      }
    } catch (e, stackTrace) {
      _log.severe(
        'Error reading local pregnancy details for user: $userId (after Firestore attempt)',
        e,
        stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> sendNotification(String message) async {
    // This likely needs backend implementation. Log a warning for now.
    _log.warning(
      'Attempted to send notification from client-side (sendNotification). This requires backend implementation.',
    );
    // Remove or comment out the problematic call:
    // await _messaging.sendMessage(
    //   to: '/topics/dashboard', // Use a relevant topic or specific tokens via backend
    //   data: {'message': message},
    // );
    // Instead, you might trigger a Cloud Function or your backend API here.
    // For now, do nothing or throw an UnimplementedError.
    throw UnimplementedError(
      'Client-side notification sending is not supported. Implement via backend.',
    );
  }
}
