import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_notification.dart';

class AppNotificationsNotifier extends Notifier<AppNotification?> {
  @override
  AppNotification? build() => null; // Initial state is no notification

  void show(String message, {NotificationType type = NotificationType.info}) {
    state = AppNotification(message: message, type: type);
  }

  void clear() {
    state = null;
  }
}

final notificationsProvider = NotifierProvider.autoDispose(
  AppNotificationsNotifier.new,
);
