enum NotificationType { success, error, info }

class AppNotification {
  final String message;
  final NotificationType type;
  final Duration duration;

  AppNotification({
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
  });
}
