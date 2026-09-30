import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:{{project_name}}/core/errors/failure.dart';
import 'package:{{project_name}}/core/logging/app_logger.dart';
import 'package:{{project_name}}/core/widgets/error_screen.dart';

class ErrorConfig {
  ErrorConfig._();
  static final _log = AppLogger.logger;
  static void initErrorHandling() {
    // 1. UI fallback
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _log.severe(
        'Something went wrong while rendering the screen.',
        details.exception,
        details.stack,
      );

      return ErrorScreen(error: InternalFailure(stackTrace: details.stack));
    };

    // 2. Framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _log.severe('Flutter Framework Error', details.exception, details.stack);
    };

    // 3. Platform/VM errors (Async gaps)
    PlatformDispatcher.instance.onError = (error, stack) {
      _log.severe('Platform Dispatcher Error', error, stack);
      return true; // Mark as handled
    };
  }
}
