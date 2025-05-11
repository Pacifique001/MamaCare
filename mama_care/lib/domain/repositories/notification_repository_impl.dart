import 'dart:async';
import 'dart:convert'; // For encoding/decoding payload
import 'dart:io'; // For Platform checks
import 'dart:math'; // For Random fallback ID
import 'package:flutter/foundation.dart'; // For @pragma
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/data/repositories/notification_repository.dart'; // Interface path
import 'package:mama_care/domain/entities/notification_model.dart'; // Your notification entity
import 'package:mama_care/core/error/exceptions.dart'; // Your custom exceptions
import 'package:mama_care/injection.dart';
import 'package:sqflite/sqflite.dart' as sqflite; // Import sqflite with prefix
import 'package:mama_care/navigation/navigation_service.dart'; // Import static navigation service
import 'package:mama_care/navigation/router.dart'; // Import route constants if needed
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:timezone/timezone.dart' as tz; // Import timezone
import 'package:timezone/data/latest_all.dart'
    as tz_data; // Import timezone data
// Use flutter_timezone if flutter_native_timezone is deprecated or causes issues
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

// --- Background Message Handler ---
// Needs to be a top-level function or static method
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // IMPORTANT: This function must be static or top-level.
  // Keep this function simple. Avoid complex logic or UI updates.
  // Primarily used for logging or storing minimal data for later processing.
  final logger = Logger(
    printer: SimplePrinter(printTime: true),
  ); // Create basic logger

  logger.i('Background Notification Tapped (Terminated State)');
  logger.i('  ID: ${notificationResponse.id}');
  logger.i('  Action ID: ${notificationResponse.actionId}');
  logger.i('  Payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    logger.i('  Input: ${notificationResponse.input}');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done (required for background isolate)
  // Note: Ensure Firebase initialization options are available if needed.
  // Often, this requires passing options or ensuring default init works.
  await Firebase.initializeApp();
  // It's hard to use dependency injection reliably in background isolates.
  // Manually instantiate logger and DB helper here.
  final logger = Logger(
    printer: SimplePrinter(printTime: true),
  ); // Simple printer for background
  final dbHelper = DatabaseHelper(); // Assuming default constructor works

  logger.i("Handling a background message: ${message.messageId}");

  try {
    // Ensure database is initialized (may need to call dbHelper.initDb explicitly if needed)
    // await dbHelper.initDb(); // Uncomment if explicit init is required for background
    await dbHelper.database; // Accessing getter might initialize it
    await _saveBackgroundNotification(dbHelper, message, logger);
  } catch (e, stackTrace) {
    logger.e(
      "Error handling background message",
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Helper to save notification in background isolate
Future<void> _saveBackgroundNotification(
  DatabaseHelper dbHelper,
  RemoteMessage message,
  Logger logger,
) async {
  logger.d("Background: Saving notification to DB: ${message.messageId}");
  final notificationData = message.notification;
  final dataPayload = message.data;

  // Determine Title and Body (prefer data payload if available)
  final String title =
      dataPayload['title'] as String? ??
      notificationData?.title ??
      'Notification';
  final String body =
      dataPayload['body'] as String? ?? notificationData?.body ?? '';

  // Skip saving if no meaningful content
  if (title == 'Notification' && body == '') {
    logger.w(
      "Background: Received message without meaningful content. Skipping save.",
    );
    return;
  }

  // Generate a unique ID if FCM doesn't provide one
  String id = message.messageId ?? '';
  if (id.isEmpty) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999).toString().padLeft(5, '0');
    id = '${ts}_$rand';
    logger.w("Background: FCM message ID was null, generated fallback ID: $id");
  }

  final int timestamp =
      message.sentTime?.millisecondsSinceEpoch ??
      DateTime.now().millisecondsSinceEpoch;
  final String? userId =
      FirebaseAuth.instance.currentUser?.uid; // Attempt to get current user

  try {
    final notificationToSave = NotificationModel(
      id: id,
      userId:
          userId, // Might be null if user isn't logged in when background message arrives
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: false,
      payload: dataPayload.isNotEmpty ? dataPayload : null,
      fcmMessageId: message.messageId,
      isScheduled:
          dataPayload['scheduled_time'] !=
          null, // Check if it was scheduled via data payload
    );

    await dbHelper.insert(
      'notifications', // Table name constant might be better
      notificationToSave.toMap(), // Uses model's toMap
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
    logger.i("Background: Notification saved: $id");
  } catch (e, stackTrace) {
    logger.e(
      "Background: Failed to save notification $id to DB",
      error: e,
      stackTrace: stackTrace,
    );
    // Cannot easily throw exceptions here as it's a different isolate
  }
}

// --- Notification Repository Implementation ---
@Injectable(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseMessaging _firebaseMessaging;
  final DatabaseHelper _databaseHelper;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Logger _logger;
  final FirebaseAuth _auth; // Injected FirebaseAuth

  // Define Android Notification Channel
  // Ensure this ID matches what's used in AndroidManifest.xml for high importance if needed
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mama_care_high_importance_channel', // Unique channel ID
    'MamaCare Alerts', // Channel name visible in app settings
    description:
        'Channel for important MamaCare notifications and alerts.', // Channel description
    importance: Importance.high, // High importance for visibility
    playSound: true, // Play sound by default for this channel
    // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional: custom sound
    enableVibration: true,
  );

  bool _isInitialized = false; // Prevent multiple initializations

  NotificationRepositoryImpl(
    this._firebaseMessaging,
    this._databaseHelper,
    this._logger,
    this._auth,
  ) : _localNotifications =
          FlutterLocalNotificationsPlugin(); // Initialize plugin instance

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d("NotificationRepository already initialized. Skipping.");
      return;
    }
    _logger.i("Initializing NotificationRepository...");

    try {
      await _configureLocalTimeZone(); // Configure timezone first
      await _initializeLocalNotifications(); // Setup local notifications plugin
      await _configureFirebaseMessaging(); // Setup FCM listeners
      await _handleInitialMessage(); // Check if app opened from terminated state notification
      _isInitialized = true;
      _logger.i("NotificationRepository initialized successfully.");
    } catch (e, s) {
      _logger.e(
        "NotificationRepository initialization failed!",
        error: e,
        stackTrace: s,
      );
      // Optionally rethrow or handle initialization failure
      throw ConfigurationException(
        "Failed to initialize notifications",
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Configures the local timezone for scheduling.
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      _logger.d("Timezone configuration skipped for this platform.");
      return; // Timezone setup primarily for mobile scheduling
    }
    try {
      tz_data.initializeTimeZones(); // Load timezone database
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _logger.i("Local timezone configured: $timeZoneName");
    } catch (e, s) {
      _logger.e(
        "Could not configure local timezone, using UTC fallback.",
        error: e,
        stackTrace: s,
      );
      try {
        // Fallback to UTC if detection fails
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      } catch (fallbackError) {
        _logger.f(
          "FATAL: Could not set UTC fallback timezone.",
          error: fallbackError,
        );
      }
    }
  }

  /// Initializes FlutterLocalNotifications plugin.
  Future<void> _initializeLocalNotifications() async {
    _logger.d("Initializing FlutterLocalNotifications...");
    // Use a consistent icon name (e.g., 'ic_stat_notification' or 'app_icon')
    // This should match an icon placed in android/app/src/main/res/drawable-*dpi folders
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Request default permissions on iOS/macOS during init
    const DarwinInitializationSettings
    darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // defaultPresentAlert: true, // Defaults handled by requestPermission
      // defaultPresentBadge: true,
      // defaultPresentSound: true,
      //onDidReceiveLocalNotification:
      // _onDidReceiveLocalNotification, // Optional: Handle older iOS foreground notifications
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      // Callback when notification response is received (app in foreground/background)
      onDidReceiveNotificationResponse: _onNotificationTapped,
      // Callback when notification response is received (app terminated) - Use same handler
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      // Handles terminated taps
    );

    // Create the Android notification channel
    if (Platform.isAndroid) {
      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);
        _logger.d("Android Notification Channel '${_channel.id}' ensured.");
      } catch (e, s) {
        _logger.e(
          "Failed to create Android notification channel",
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  // Optional: Callback for older iOS versions when notification received while app is in foreground
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // You could display an alert or update UI here for older iOS
    locator<Logger>().i(
      "Foreground local notification received on older iOS: $id - $title",
    );
    // Maybe trigger the tap logic if payload exists?
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        _onNotificationTappedLogic(data); // Trigger navigation/action
      } catch (e) {
        /* handle error */
      }
    }
  }

  /// Configures Firebase Messaging listeners and token handling.
  Future<void> _configureFirebaseMessaging() async {
    _logger.d("Configuring Firebase Messaging listeners...");
    // Set the background handler (must be top-level or static)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (mainly for iOS, Android Tiramisu+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      // Other options like carPlay, criticalAlert can be added if needed
    );
    _logger.i(
      "FCM Permissions requested. Authorization status: ${settings.authorizationStatus}",
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // Listen for messages opened when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

    // Handle token registration and refresh
    await _registerDeviceToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _logger.i("FCM Token refreshed.");
      await _saveDeviceToken(newToken);
      // Optionally: Send the new token to your backend server
    });
  }

  /// Gets and saves the initial FCM device token.
  Future<void> _registerDeviceToken() async {
    _logger.d("Registering initial FCM device token...");
    try {
      String? token;
      if (kIsWeb) {
        // --- !!! IMPORTANT: Replace with your actual VAPID key !!! ---
        const String? vapidKey =
            "BHFogJ77AksFCZKV3XU7t39fkxm2ZHLCZa-AHbMxpe14ui8Uw9oyn3sxrvQWjnBrfrF44pBEOU1FsDku86KW2-M"; // Example VAPID Key
        // ---------------------------------------------------------------
        if (vapidKey == null ||
            vapidKey.isEmpty ||
            vapidKey ==
                "BHFogJ77AksFCZKV3XU7t39fkxm2ZHLCZa-AHbMxpe14ui8Uw9oyn3sxrvQWjnBrfrF44pBEOU1FsDku86KW2-M") {
          _logger.w(
            "VAPID key is not configured for Web. Skipping web token registration.",
          );
        } else {
          token = await _firebaseMessaging.getToken(vapidKey: vapidKey);
          _logger.d("Web FCM token requested with VAPID key.");
        }
      } else {
        // iOS/Android/macOS
        token = await _firebaseMessaging.getToken();
      }

      if (token != null) {
        _logger.i(
          "Firebase initial token fetched: ${token.substring(0, 10)}...",
        );
        // Save the obtained token using the dedicated method
        await _saveDeviceToken(token);
      } else {
        _logger.w("Firebase initial token was null (or skipped for web).");
      }
    } catch (e, s) {
      _logger.e("Failed to get initial FCM token", error: e, stackTrace: s);
      // Consider if you need to surface this error more prominently
    }
  }

  /// Saves the FCM token locally, associating with user if logged in.
  Future<void> _saveDeviceToken(String token) async {
    final String? userId = _auth.currentUser?.uid;
    _logger.i(
      "Attempting to save FCM token to local DB. UserID: ${userId ?? 'NULL'}, Token: ${token.substring(0, 10)}...",
    );

    try {
      // Call the DatabaseHelper method to save the token
      // This assumes DatabaseHelper.saveFcmToken uses ConflictAlgorithm.replace
      // and handles potential FK constraint errors internally or via the generic insert logging.
      await _databaseHelper.saveFcmToken(token, userId);

      _logger.i(
        "Local FCM token save/update successful ${userId != null ? 'for user $userId' : '(globally)'}.",
      );
    } on DatabaseExceptions catch (dbEx, stackTrace) {
      // Catch the custom exception from DatabaseHelper which should have detailed info
      _logger.e(
        "Database Error saving FCM token locally via Helper: ${dbEx.message}",
        error: dbEx.cause, // Log the original cause (sqflite exception)
        stackTrace: stackTrace,
      );
      // Specific logging based on the error message from the helper (which now checks codes)
      if (dbEx.message.contains("FOREIGN KEY")) {
        _logger.w(
          "-> Suggests the userId '$userId' might not exist in the 'users' table when saving the token.",
        );
      } else if (dbEx.message.contains("UNIQUE") ||
          dbEx.message.contains("PRIMARY KEY")) {
        _logger.w(
          "-> Suggests ConflictAlgorithm.replace might not be working as expected, or another unique constraint failed.",
        );
      }
    } catch (e, s) {
      // Catch any other unexpected errors during the save process
      _logger.e(
        "Unexpected error saving FCM token locally",
        error: e,
        stackTrace: s,
      );
    }
  } // NOTE: We don't re-throw exceptions here to prevent crashes during token refresh/initial load.
  // The error is logged for debugging. If saving fails, the app might receive notifications
  //

  /// Checks if app opened from terminated state via notification.
  Future<void> _handleInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      _logger.i(
        "App opened from terminated state via FCM notification: ${message.messageId}",
      );
      await _processNotificationAndData(
        message,
        markAsRead: true,
      ); // Save and mark read
      _onNotificationTappedLogic(message.data); // Trigger action
    }
  }

  /// Handles foreground FCM: Process, Save, Show Local Notification.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i("Foreground FCM message received: ${message.messageId}");
    // Always save the notification data
    await _processNotificationAndData(
      message,
      markAsRead: false,
    ); // Save as unread
    // Display a local notification to alert the user
    _showLocalNotification(message);
  }

  /// Handles messages tapped when app is in background.
  Future<void> _handleOpenedApp(RemoteMessage message) async {
    _logger.i(
      "App opened from background via FCM notification: ${message.messageId}",
    );
    await _processNotificationAndData(
      message,
      markAsRead: true,
    ); // Save and mark read
    _onNotificationTappedLogic(message.data); // Trigger action
  }

  /// Saves notification to DB and processes data payload.
  Future<void> _processNotificationAndData(
    RemoteMessage message, {
    required bool markAsRead,
  }) async {
    // ... (Implementation from previous answer is generally good) ...
    // Ensure it uses the correct NotificationModel and toMap()
    _logger.d(
      "Processing notification ${message.messageId}. Mark as read: $markAsRead",
    );
    final notificationPayload = message.notification;
    final dataPayload = message.data;

    final String title =
        dataPayload['title'] as String? ??
        notificationPayload?.title ??
        'Notification';
    final String body =
        dataPayload['body'] as String? ?? notificationPayload?.body ?? '';

    if (title == 'Notification' && body == '') {
      _logger.w(
        "Skipping DB save for message ${message.messageId}: No content.",
      );
      return; // Don't save empty notifications
    }

    String id = message.messageId ?? '';
    if (id.isEmpty) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final rand = Random().nextInt(99999).toString().padLeft(5, '0');
      id = '${ts}_$rand';
    }

    final int timestamp =
        message.sentTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final String? userId = _auth.currentUser?.uid;

    final notificationToSave = NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: markAsRead,
      payload: dataPayload.isNotEmpty ? dataPayload : null,
      fcmMessageId: message.messageId,
      isScheduled: dataPayload['scheduled_time'] != null, // Example check
    );

    try {
      await _databaseHelper.insert(
        'notifications',
        notificationToSave.toMap(), // Use model's toMap
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      _logger.d("Notification $id saved to DB for user $userId.");
    } catch (e, stackTrace) {
      _logger.e(
        "Failed to save notification $id to DB",
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow here, just log the failure
    }
  }

  /// Shows a local notification using FlutterLocalNotificationsPlugin.
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final String title =
        message.data['title'] as String? ?? notification?.title ?? 'MamaCare';
    final String body =
        message.data['body'] as String? ?? notification?.body ?? '';

    if (body.isEmpty && title == 'MamaCare') {
      // Avoid showing empty notifications
      _logger.w(
        "Skipping local notification display for message ${message.messageId} due to empty content.",
      );
      return;
    }

    _logger.d("Showing local notification for message ${message.messageId}");
    try {
      _localNotifications.show(
        message
            .hashCode, // Use a unique int ID (message hashcode is okay for transient display)
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, // Use the defined channel ID
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher', // Ensure this icon exists
            importance: Importance.high,
            priority: Priority.high,
            // Add other Android options if needed (e.g., ticker, styleInformation)
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // sound: 'custom_sound.aiff', // Optional custom sound for iOS
          ),
        ),
        // Encode the data payload to pass it when the notification is tapped
        payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
      );
    } catch (e, s) {
      _logger.e("Error showing local notification", error: e, stackTrace: s);
    }
  }

  /// Callback when a local notification is tapped.
  static void _onNotificationTapped(NotificationResponse response) {
    final Logger logger = locator<Logger>(); // Get logger via locator
    logger.i(
      "Local notification tapped. Action: ${response.actionId}, Payload: ${response.payload}",
    );
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _onNotificationTappedLogic(data); // Call central logic handler
      } catch (e, stackTrace) {
        logger.e(
          "Error decoding notification payload",
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    // Handle specific action IDs if needed
    // if (response.actionId == 'your_action_id') { ... }
  }

  /// Central logic for handling navigation/actions from notification tap data.
  static void _onNotificationTappedLogic(Map<String, dynamic> data) {
    final Logger logger = locator<Logger>();
    logger.d("Processing notification tap logic with data: $data");
    final String? route = data['route'] as String?;
    final String? articleId = data['articleId'] as String?;
    final String? appointmentId = data['appointmentId'] as String?;

    // Use static NavigationService for navigation
    if (route != null) {
      logger.i("Navigating to route from notification data: $route");
      // Pass the whole data map as arguments for flexibility
      NavigationService.navigateTo(route, arguments: data);
    } else if (appointmentId != null) {
      // Prioritize specific actions
      logger.i("Navigating to appointment detail: $appointmentId");
      NavigationService.navigateTo(
        NavigationRoutes.appointmentDetail,
        arguments: appointmentId,
      );
    } else if (articleId != null) {
      logger.i("Navigating to article detail: $articleId");
      NavigationService.navigateTo(
        NavigationRoutes.article,
        arguments: articleId,
      );
    }
    // Add more else if blocks for other actions (e.g., opening profile, specific feature)
    else {
      logger.w(
        "Notification tapped, but no recognized action/route found in data.",
      );
      // Optional: Navigate to a default screen like the dashboard
      // NavigationService.navigateTo(NavigationRoutes.mainScreen);
    }
  }

  // --- Repository Interface Method Implementations ---

  @override
  Future<void> saveNotification(NotificationModel notification) async {
    _logger.d("Repo: Saving notification explicitly: ${notification.id}");
    final String? currentUserId = _auth.currentUser?.uid;
    try {
      final finalNotification = notification.copyWith(
        userId: notification.userId ?? currentUserId, // Ensure userId is set
      );
      await _databaseHelper.insert(
        'notifications',
        finalNotification.toMap(), // Use model's toMap
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error saving notification ${notification.id}",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Failed to save notification.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    _logger.d("Repo: Fetching notifications from DB...");
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.w("Repo: User not logged in, returning empty notification list.");
      return [];
    }
    try {
      final results = await _databaseHelper.query(
        'notifications',
        where: 'userId = ?', // Fetch only for the current user
        whereArgs: [userId],
        orderBy: 'timestamp DESC', // Newest first
      );
      // Use NotificationModel.fromMap for data coming from SQLite
      return results
          .map((map) {
            try {
              return NotificationModel.fromMap(map);
            } catch (e, s) {
              _logger.e(
                "Error parsing notification map ${map['id']}",
                error: e,
                stackTrace: s,
              );
              return null;
            }
          })
          .whereType<NotificationModel>()
          .toList(); // Filter out parsing errors
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error fetching notifications",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Failed to load notifications.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    _logger.d("Repo: Marking notification $id as read.");
    if (id.isEmpty) return; // Avoid action on empty ID
    try {
      final count = await _databaseHelper.update(
        'notifications',
        {'isRead': 1}, // 1 for true
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0)
        _logger.w("Repo: Notification $id not found to mark as read.");
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error marking notification $id as read",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Failed to update notification status.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      /* ... handle no user ... */
      return;
    }
    _logger.d("Repo: Marking all notifications as read for user $userId.");
    try {
      final count = await _databaseHelper.update(
        'notifications',
        {'isRead': 1},
        where: 'isRead = ? AND userId = ?',
        whereArgs: [0, userId], // Mark only unread (0) for the specific user
      );
      _logger.d("Repo: Marked $count notifications as read for user $userId.");
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error marking all notifications as read",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Failed to update notifications.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return 0;
    _logger.d("Repo: Getting unread notification count for user $userId...");
    try {
      // Use the specific count method from DatabaseHelper if available
      // final count = await _databaseHelper.count('notifications', where: 'isRead = ? AND userId = ?', whereArgs: [0, userId]);
      // return count;

      // Alternative using rawQuery:
      final countResult = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE isRead = ? AND userId = ?',
        [0, userId],
      );
      final count =
          sqflite.Sqflite.firstIntValue(countResult) ?? 0; // Use sqflite helper
      _logger.d("Repo: Unread count is $count for user $userId.");
      return count;
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error getting unread count",
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _logger.d("Repo: Deleting notification $id.");
    if (id.isEmpty) return;
    try {
      final count = await _databaseHelper.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0)
        _logger.w("Repo: Notification $id not found for deletion.");
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Error deleting notification $id",
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseException(
        "Failed to delete notification.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    _logger.i("Repo: Subscribing to FCM topic: $topic");
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.d("Repo: Subscribed OK to topic: $topic");
    } catch (e, s) {
      _logger.e(
        "Repo: Failed to subscribe to topic $topic",
        error: e,
        stackTrace: s,
      );
      // Optionally rethrow as NetworkException or specific FCMException
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _logger.i("Repo: Unsubscribing from FCM topic: $topic");
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.d("Repo: Unsubscribed OK from topic: $topic");
    } catch (e, s) {
      _logger.e(
        "Repo: Failed to unsubscribe from topic $topic",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    // This should ideally fetch from your local DB where you saved it
    _logger.d("Repo: Getting active device token from FCM...");
    try {
      // Getting token directly from FCM might be simpler if local storage is complex
      String? token = await _firebaseMessaging.getToken();
      _logger.d("Repo: Fetched current FCM token: ${token != null}");
      return token;
    } catch (e, s) {
      _logger.e(
        "Repo: Error getting FCM device token",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Sends a local notification immediately and saves it to the DB.
  @override
  Future<void> sendNotification(Map<String, dynamic> data) async {
    _logger.d("Repo: Sending/scheduling local notification with data: $data");

    String title = data['title'] as String? ?? 'MamaCare Notification';
    String body = data['body'] as String? ?? '';
    Map<String, dynamic>? payload =
        data['payload']
            as Map<String, dynamic>?; // Assume payload is already a map
    int notificationId =
        data['notificationId'] as int? ??
        DateTime.now().millisecondsSinceEpoch %
            2147483647; // Use hash or timestamp modulo max int

    try {
      // Schedule for immediate display
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // Ensure this icon exists
            // styleInformation: BigTextStyleInformation(body), // Optional: Show full body text
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        payload:
            payload != null
                ? jsonEncode(payload)
                : null, // Encode payload for local notif
      );
      _logger.i("Local notification shown with ID: $notificationId");

      // Also save to local database
      final notification = NotificationModel(
        id: notificationId.toString(), // Use the same ID as string
        userId: _auth.currentUser?.uid, // Associate with user if logged in
        title: title,
        body: body,
        timestamp:
            DateTime.now()
                .millisecondsSinceEpoch, // Time it was processed/saved
        isRead: false, // Initially unread
        payload: payload, // Store the map directly
        isScheduled: false, // This is not a scheduled notification
      );
      await saveNotification(notification); // Use the repo's save method
    } catch (e, s) {
      _logger.e(
        "Repo: Failed to send/save local notification",
        error: e,
        stackTrace: s,
      );
      // Decide if this should throw or just log
    }
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
    int? notificationId,
  }) async {
    final id =
        notificationId ?? scheduledDate.millisecondsSinceEpoch % 2147483647;
    _logger.d("Repo: Scheduling notification $id for $scheduledDate");

    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        /* ... handle past date ... */
        return;
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      _logger.d(
        "Repo: Scheduling using TZDateTime: $tzScheduledDate (local zone: ${tz.local.name})",
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        payload: payload != null ? jsonEncode(payload) : null,
        // --- CORRECTED PARAMETERS ---
        androidScheduleMode:
            AndroidScheduleMode
                .exactAllowWhileIdle, // Use this instead of deprecated ones
        // Remove uiLocalNotificationDateInterpretation
        // Use matchDateTimeComponents carefully based on need:
        // matchDateTimeComponents: DateTimeComponents.time, // For daily repeating at specific time
        matchDateTimeComponents: null, // For one-time exact schedule
        // --------------------------
      );

      // Save metadata to database
      final notification = NotificationModel(
        id: id.toString(),
        userId: _auth.currentUser?.uid,
        title: title,
        body: body,
        timestamp: scheduledDate.millisecondsSinceEpoch,
        isRead: false,
        payload: payload,
        isScheduled: true,
      );
      await saveNotification(notification);
      _logger.i(
        "Repo: Notification $id scheduled successfully for $scheduledDate.",
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Repo: Failed to schedule notification $id",
        error: e,
        stackTrace: stackTrace,
      );
      throw DomainException(
        "Failed to schedule notification.",
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  // This method remains mainly for completeness, the View should call initialize()
  @override
  Future<void> initializeNotifications() async {
    _logger.d(
      "Repo: initializeNotifications called (checking if already initialized).",
    );
    if (!_isInitialized) {
      await initialize();
    }
  }
}
