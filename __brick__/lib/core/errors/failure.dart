/// A user freindly error that can be displayed in the UI
sealed class Failure {
  const Failure({
    required this.code,
    required this.message,
    required this.stackTrace,
  });
  final String code;
  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '$code: $message.\n $stackTrace';
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.stackTrace})
    : super(code: 'UNAUTHORIZED', message: "Unauthorized");
}

final class InternalFailure extends Failure {
  const InternalFailure({required super.stackTrace})
    : super(
        code: 'INTERNAL_ERROR',
        message: 'Something went wrong. Please try again later.',
      );
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'A database error occurred.',
    required super.stackTrace,
  }) : super(code: 'DATABASE_ERROR');
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection.',
    required super.stackTrace,
  }) : super(code: 'NETWORK_ERROR');
}
