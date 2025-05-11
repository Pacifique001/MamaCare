import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/data/repositories/timeline_repository.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/domain/entities/timeline_event.dart';

@Injectable(as: TimelineRepository)
class TimelineRepositoryImpl implements TimelineRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;
  final FirebaseMessaging _firebaseMessaging; // Keep if used for notifications

  // Define Firestore paths (makes it easier to change)
  static const String _usersCollection = 'users';
  static const String _pregnancyCollection = 'pregnancy';
  static const String _detailsDocument = 'details';
  static const String _timelineEventsCollection = 'timeline_events';
  static const String _eventsSubcollection = 'events';

  TimelineRepositoryImpl(
    this._firebaseAuth,
    this._firestore,
    this._databaseHelper,
    this._firebaseMessaging, // Keep if needed elsewhere
  );

  @override
  Future<PregnancyDetails?> getPregnancyDetails() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
       debugPrint("[TimelineRepo] getPregnancyDetails: User not logged in");
       // Depending on app flow, you might throw or return null. Null is often safer for UI.
       return null;
       // throw Exception("User not logged in");
    }

    try {
      // --- 1. Attempt to fetch from Firestore (Source of Truth) ---
      debugPrint("[TimelineRepo] getPregnancyDetails: Attempting fetch from Firestore for user $userId");
      final docRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_pregnancyCollection)
          .doc(_detailsDocument); // Adjust path as needed

      final docSnapshot = await docRef.get(const GetOptions(source: Source.serverAndCache)); // Try server first

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint("[TimelineRepo] getPregnancyDetails: Fetched from Firestore.");
        final data = docSnapshot.data()!;
        // Ensure userId is included when creating the object, as it's needed for caching
        final details = PregnancyDetails.fromJson({...data, 'userId': userId}); // Add userId explicitly

        // --- Update Local Cache Asynchronously (don't block return) ---
        _databaseHelper.upsertPregnancyDetail(details.toJson())
            .then((_) => debugPrint("[TimelineRepo] getPregnancyDetails: Updated local cache from Firestore data."))
            .catchError((e) => debugPrint("[TimelineRepo] Error updating local cache: $e")); // Log cache errors but don't fail the fetch

        return details;

      } else {
         debugPrint("[TimelineRepo] getPregnancyDetails: No details found in Firestore for user $userId at path ${docRef.path}");
      }

      // --- 2. Fallback to Local Cache if Firestore fetch yielded no data ---
      // (Could also add fallback if Firestore fetch threw specific errors like network issues)
      debugPrint("[TimelineRepo] getPregnancyDetails: Falling back to local cache.");
      final localDetails = await _databaseHelper.query(
        DatabaseHelper.pregnancyDetailsTable, // Use constant from DatabaseHelper
        where: '${DatabaseHelper.colUserId} = ?', // Use column constant
        whereArgs: [userId],
        limit: 1,
      );

      if (localDetails.isNotEmpty) {
        debugPrint("[TimelineRepo] getPregnancyDetails: Found details in local cache.");
        // The userId should already be in the cached map if saved correctly
        return PregnancyDetails.fromJson(localDetails.first);
      } else {
         debugPrint("[TimelineRepo] getPregnancyDetails: No details found in local cache either.");
         return null; // No data found anywhere
      }

    } catch (e, stackTrace) {
      // Log the error comprehensively
      debugPrint("[TimelineRepo] Error fetching pregnancy details: $e\nStack Trace: $stackTrace");
      // Decide if you want to try cache even on error. For simplicity, return null.
      // You could potentially check the error type (e.g., network error)
      // and still attempt cache lookup.
      return null;
    }
  }

  // --- Timeline Event Methods (Seem okay, but added collection constants) ---

  @override
  Future<void> addTimelineEvent(TimelineEvent event) async {
    // It's generally better practice to assign a unique ID *before* sending to Firestore/DB
    // If event.id is empty, generate one, e.g., using uuid package or Firestore's doc().id

    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Ensure event has a user ID associated if needed for local storage query
    // Map<String, dynamic> eventJson = event.toJson()..['user_id'] = user.uid;
    Map<String, dynamic> eventJson = event.toJson(); // Assuming event class doesn't need userId internally

    try {
      // Consider using Firestore's ID generation if event.id is not pre-assigned
      DocumentReference docRef;
      if (event.id.isEmpty) {
         docRef = _firestore
            .collection(_timelineEventsCollection)
            .doc(user.uid)
            .collection(_eventsSubcollection)
            .doc(); // Firestore generates ID
         eventJson['id'] = docRef.id; // Add the generated ID to the map
      } else {
         docRef = _firestore
            .collection(_timelineEventsCollection)
            .doc(user.uid)
            .collection(_eventsSubcollection)
            .doc(event.id); // Use provided ID
      }

      await docRef.set(eventJson); // Use set instead of add if ID is managed

      // Add 'user_id' specifically for the local database query if needed
      await _databaseHelper.insert(
        DatabaseHelper.timelineEventsTable, // Use constant
        eventJson..['user_id'] = user.uid, // Add user_id for local query
      );
    } catch (e) {
      debugPrint("Error adding timeline event: $e");
      throw Exception('Failed to add timeline event: ${e.toString()}');
    }
  }


  @override
  Future<List<TimelineEvent>> getTimelineEvents() async {
     final user = _firebaseAuth.currentUser;
     if (user == null) {
        debugPrint("[TimelineRepo] getTimelineEvents: User not logged in");
        return []; // Return empty list if not logged in
     }

    try {
      // --- 1. Try local cache first for potentially faster loading ---
      final localEventsData = await _databaseHelper.query(
        DatabaseHelper.timelineEventsTable, // Use constant
        where: '${DatabaseHelper.colUserId} = ?', // Use constant for user_id column
        whereArgs: [user.uid],
        orderBy: '${DatabaseHelper.colCreatedAt} DESC', // Use constant for date column if applicable
      );

      if (localEventsData.isNotEmpty) {
        debugPrint("[TimelineRepo] getTimelineEvents: Found ${localEventsData.length} events in local cache.");
        try {
           return localEventsData
            .map((eventMap) => TimelineEvent.fromJson(eventMap))
            .toList();
        } catch (e) {
           debugPrint("[TimelineRepo] Error parsing local timeline events: $e. Will try Firestore.");
           // If parsing fails, proceed to fetch from Firestore
        }
      }

      // --- 2. Fetch from Firestore if cache is empty or parsing failed ---
      debugPrint("[TimelineRepo] getTimelineEvents: Fetching from Firestore.");
      QuerySnapshot snapshot = await _firestore
          .collection(_timelineEventsCollection)
          .doc(user.uid)
          .collection(_eventsSubcollection)
          // Ensure you have an index in Firestore for this orderBy clause
          .orderBy('date', descending: true) // Assuming 'date' field exists and is Timestamp/DateTime comparable
          .get();

      final firestoreEvents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure 'id' is included from the document ID if not in the data map
          return TimelineEvent.fromJson({...data, 'id': doc.id});
      }).toList();

      // --- 3. Update cache with Firestore data (optional but good practice) ---
      if (firestoreEvents.isNotEmpty) {
         debugPrint("[TimelineRepo] getTimelineEvents: Updating cache with ${firestoreEvents.length} events from Firestore.");
         // Clear old cache for this user and insert fresh data (or implement smarter upsert)
         await _databaseHelper.delete(DatabaseHelper.timelineEventsTable, where: '${DatabaseHelper.colUserId} = ?', whereArgs: [user.uid]);
         for (var event in firestoreEvents) {
           // Add user_id for local querying before inserting
           await _databaseHelper.insert(DatabaseHelper.timelineEventsTable, event.toJson()..['user_id'] = user.uid);
         }
      }

      return firestoreEvents;

    } catch (e, stackTrace) {
      debugPrint("[TimelineRepo] Failed to fetch timeline events: $e\n$stackTrace");
      // Return empty list or throw, depending on desired behavior on error
      return [];
      // throw Exception('Failed to fetch timeline events: ${e.toString()}');
    }
  }


  @override
  Future<void> updateTimelineEvent(TimelineEvent event) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("User not logged in");
    if (event.id.isEmpty) throw Exception("Cannot update event without an ID");

    // Ensure user_id is added for local update if needed by schema
    // final eventJson = event.toJson()..['user_id'] = user.uid;
    final eventJson = event.toJson();


    try {
      await _firestore
          .collection(_timelineEventsCollection)
          .doc(user.uid)
          .collection(_eventsSubcollection)
          .doc(event.id)
          .update(eventJson); // Update Firestore

      await _databaseHelper.update(
        DatabaseHelper.timelineEventsTable, // Use constant
        eventJson..['user_id'] = user.uid, // Ensure user_id for where clause if needed
        where: '${DatabaseHelper.colId} = ? AND ${DatabaseHelper.colUserId} = ?', // Use constants, ensure user owns event
        whereArgs: [event.id, user.uid],
      ); // Update local cache
    } catch (e) {
       debugPrint("Error updating timeline event: $e");
      throw Exception('Failed to update timeline event: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTimelineEvent(String eventId) async {
    final user = _firebaseAuth.currentUser;
     if (user == null) throw Exception("User not logged in");
     if (eventId.isEmpty) throw Exception("Cannot delete event without an ID");

    try {
      await _firestore
          .collection(_timelineEventsCollection)
          .doc(user.uid)
          .collection(_eventsSubcollection)
          .doc(eventId)
          .delete(); // Delete from Firestore

      await _databaseHelper.delete(
        DatabaseHelper.timelineEventsTable, // Use constant
        where: '${DatabaseHelper.colId} = ? AND ${DatabaseHelper.colUserId} = ?', // Use constants, ensure user owns event
        whereArgs: [eventId, user.uid],
      ); // Delete from local cache
    } catch (e) {
      debugPrint("Error deleting timeline event: $e");
      throw Exception('Failed to delete timeline event: ${e.toString()}');
    }
  }

  // --- Notification Method (Placeholder) ---
  @override
  Future<void> sendTimelineUpdateNotification(String message) async {
    // This implementation remains a placeholder as client-side sending is not standard
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint(
          '[TimelineRepo] Would trigger backend to send notification to token: $token with message: $message',
        );
        // Replace with your actual backend API call if you have one
      } else {
         debugPrint('[TimelineRepo] Could not get FCM token to send notification.');
      }
    } catch (e) {
       debugPrint('Failed to send notification (placeholder): ${e.toString()}');
      // Don't throw an exception here usually, as it might break unrelated flows
      // Just log the error.
    }
  }
}

// --- Placeholder for DatabaseHelper constants (Add these to your DatabaseHelper class) ---
/*
class DatabaseHelper {
  // ... other database setup ...

  static const String pregnancyDetailsTable = 'pregnancy_details';
  static const String timelineEventsTable = 'timeline_events';

  // Column names (replace with your actual column names)
  static const String colId = 'id';
  static const String colUserId = 'userId'; // Or 'user_id' - be consistent!
  static const String colDueDate = 'dueDate';
  static const String colCreatedAt = 'createdAt'; // Or 'date' for timeline events

  // ... other methods ...

  // Example Upsert Method (Needs implementation in DatabaseHelper)
  Future<int> upsertPregnancyDetail(Map<String, dynamic> detailJson) async {
    final db = await database; // Get your database instance
    // Assumes 'userId' is the unique key for upserting
    debugPrint("[DBHelper] Upserting pregnancy detail for userId: ${detailJson[colUserId]}");
    return await db.insert(
      pregnancyDetailsTable,
      detailJson,
      conflictAlgorithm: ConflictAlgorithm.replace, // Key feature for upsert
    );
  }

  // Ensure query, insert, update, delete methods exist and handle potential errors
}
*/