import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:{{project_name}}/core/utils/feature_flags.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  AppLogger._();

  static final bool _sentryEnabled = FeatureFlags.isSentryEnabled;

  static final Logger _logger = Logger('app');

  static Future<void> initialize({required bool enableSentry}) async {
    Logger.root.level = Level.ALL;

    Logger.root.onRecord.listen((record) {
      // Console sink.
      if (kDebugMode || !enableSentry) {
        debugPrint(_formatRecord(record));
      }

      // Sentry sink.
      if (_sentryEnabled) {
        _sendToSentry(record);
      }
    });
  }

  static String _formatRecord(LogRecord record) {
    final error = record.error == null ? '' : ' error=${record.error}';

    return '[${record.level.name}] '
        '${record.loggerName}: '
        '${record.message}$error';
  }

  static void _sendToSentry(LogRecord record) {
    final error = record.error;
    final stackTrace = record.stackTrace;

    if (record.level >= Level.SEVERE) {
      if (error != null) {
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            scope.setTag('custom_message', record.message);
          },
        );
      } else {
        Sentry.captureMessage(
          record.message,
          level: _sentryLevel(record.level),
        );
      }
    } else {
      // Normal logs are useful as breadcrumbs, but should not create
      // standalone Sentry issues.
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: record.message,
          category: record.loggerName,
          level: _sentryLevel(record.level),
          data: {'logger': record.loggerName},
        ),
      );
    }
  }

  static SentryLevel _sentryLevel(Level level) {
    if (level >= Level.SEVERE) return SentryLevel.error;
    if (level >= Level.WARNING) return SentryLevel.warning;
    if (level >= Level.INFO) return SentryLevel.info;
    return SentryLevel.debug;
  }

  static Logger get logger => _logger;
}
