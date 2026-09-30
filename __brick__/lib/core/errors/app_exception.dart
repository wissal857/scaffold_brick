part 'package:{{project_name}}/core/caching/errors/caching_exceptions.dart';
part 'package:{{project_name}}/core/network/network_exceptions.dart';

/// Will be used for creating custom exceptions
sealed class AppException implements Exception {
  final String code;
  final String message;
  final StackTrace? stackTrace;

  const AppException({
    required this.code,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => 'Error code : $code -> $message';
}

final class MissingAPIKeyException extends AppException {
  MissingAPIKeyException()
    : super(
        code: 'MISSING_API_KEY',
        message:
            'Missing Api key from .env file. Please check your environment configuration',
      );
}

final class MissingSentryDSNException extends AppException {
  MissingSentryDSNException()
    : super(
        code: 'MISSING_SENTRY_DSN',
        message:
            'Missing Sentry DSN from .env file. Please check your environment configuration',
      );
}
