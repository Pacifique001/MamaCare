import 'package:mama_care/domain/entities/notification_model.dart';
import 'package:mama_care/data/repositories/notification_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationUseCase {
  final NotificationRepository _notificationRepository;

  NotificationUseCase(this._notificationRepository);

  // Combine both initialize methods
  Future<void> initialize() async {
    await _notificationRepository.initialize();
  }

  Future<void> initializeNotifications() async {
    await _notificationRepository.initializeNotifications();
  }

  Future<void> sendNotification(String message) async {
    await _notificationRepository.sendNotification({'message': message});
  }

  Future<void> saveNotification(NotificationModel notification) async {
    await _notificationRepository.saveNotification(notification);
  }

  Future<List<NotificationModel>> getNotifications() async {
    return await _notificationRepository.getNotifications();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _notificationRepository.markNotificationAsRead(id);
  }

  Future<void> deleteNotification(String id) async {
    await _notificationRepository.deleteNotification(id);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _notificationRepository.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationRepository.unsubscribeFromTopic(topic);
  }

  Future<int> getUnreadNotificationCount() async {
    return await _notificationRepository.getUnreadNotificationCount();
  }

  Future<void> markAllNotificationsAsRead() async {
    await _notificationRepository.markAllNotificationsAsRead();
  }

  Future<String?> getDeviceToken() async {
    return await _notificationRepository.getDeviceToken();
  }
  Future<void> scheduleAppointmentNotification({
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String appointmentId,
  String? route,
}) async {
  Map<String, dynamic> payload = {
    'appointmentId': appointmentId,
  };
  
  if (route != null) {
    payload['route'] = route;
  }
  
  await _notificationRepository.scheduleNotification(
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    payload: payload,
  );
}
}