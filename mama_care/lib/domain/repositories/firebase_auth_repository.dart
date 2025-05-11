import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class FirebaseAuthRepository {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize Firebase Messaging for push notifications
  Future<void> initializePushNotifications() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    print("Firebase Messaging Token: $token");
  }

  // Subscribe to a topic for push notifications
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from a topic for push notifications
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
