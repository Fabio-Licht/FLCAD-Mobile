import '../models/adaptive_studio_models.dart';

class NotificationCenter {
  final List<StudioNotification> notifications = [];
  StudioNotification notify(StudioNotificationType type, String message) {
    final value = StudioNotification(type: type, message: message);
    notifications.add(value);
    return value;
  }

  void markRead(String id) =>
      notifications.firstWhere((e) => e.id == id).read = true;
}
