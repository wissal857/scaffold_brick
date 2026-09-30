import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotificationsListener extends ConsumerWidget {
  final Widget child;
  const AppNotificationsListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the notification state
    ref.listen<AppNotification?>(notificationsProvider, (previous, next) {
      if (next != null) {
        // Trigger the Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: _getColor(next.type),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(notificationsProvider.notifier).clear(),
            ),
          ),
        );
      }
    });

    return child;
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
    }
  }
}
