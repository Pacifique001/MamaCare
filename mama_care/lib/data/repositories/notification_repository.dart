import 'package:mama_care/domain/entities/notification_model.dart';
import 'package:injectable/injectable.dart';

@factoryMethod
abstract class NotificationRepository {
  Future<void> initialize();
  Future<void> initializeNotifications();
  Future<void> sendNotification(Map<String, dynamic> data);
  Future<void> saveNotification(NotificationModel notification);
  Future<List<NotificationModel>> getNotifications();
  Future<void> markNotificationAsRead(String id);
  Future<void> deleteNotification(String id);
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<int> getUnreadNotificationCount();
  Future<void> markAllNotificationsAsRead();
  Future<String?> getDeviceToken();
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
    int? notificationId,
  });
}
