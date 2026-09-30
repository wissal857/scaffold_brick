import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:{{project_name}}/core/errors/failure.dart';

class FailureMapper {
  static Failure map(Object exception, StackTrace s) {
    // 1. Handle Dio (Network/API) Exceptions
    if (exception is DioException) {
      return _mapDioException(exception, s);
    }

    // 2. Handle Drift/SQLite Exceptions
    if (exception is SqliteException) {
      return _mapSqliteException(exception, s);
    }

    // 3. Fallback for any other unexpected exceptions
    return InternalFailure(stackTrace: s);
  }

  static Failure _mapDioException(DioException e, StackTrace s) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'The server took too long to respond.',
          stackTrace: s,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'Unable to connect to the server.',
          stackTrace: s,
        );

      case DioExceptionType.badResponse:
        // Handle specific HTTP status codes
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) return UnauthorizedFailure(stackTrace: s);
        if (statusCode == 403) return UnauthorizedFailure(stackTrace: s);
        if (statusCode == 404) return InternalFailure(stackTrace: s);
        if (statusCode == 500) return InternalFailure(stackTrace: s);
        return InternalFailure(stackTrace: s);

      case DioExceptionType.cancel:
        return InternalFailure(stackTrace: s);

      default:
        return InternalFailure(stackTrace: s);
    }
  }

  static Failure _mapSqliteException(SqliteException e, StackTrace s) {
    // SQLite result codes are numbers.
    // You can check e.resultCode or e.message.

    // Example: SQLITE_CONSTRAINT = 19
    if (e.resultCode == 19 || e.message.contains('UNIQUE constraint failed')) {
      return DatabaseFailure(
        message: 'This record already exists in the database.',
        stackTrace: s,
      );
    }

    if (e.message.contains('no such table')) {
      return DatabaseFailure(
        message: 'Database schema is out of date. Please update the app.',
        stackTrace: s,
      );
    }

    return DatabaseFailure(
      message: 'Local storage error: ${e.message}',
      stackTrace: s,
    );
  }
}
