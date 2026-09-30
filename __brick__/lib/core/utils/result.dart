import 'package:{{project_name}}/core/errors/failure.dart';

/// Utility class to wrap result data
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///   case Success(): {
///     print(result.value);
///   }
///   case Error(): {
///     print(result.error);
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result], completed with the specified [value].
  const factory Result.success({required T value}) = Success._;

  /// Creates an error [Result], completed with the specified [error].
  const factory Result.error({required Failure err}) = Error._;
}

/// Subclass of Result for values
final class Success<T> extends Result<T> {
  const Success._({required this.value});

  /// Returned value in result
  final T value;

  @override
  String toString() => 'Result<$T>.success($value)';
}

/// Subclass of Result for errors
final class Error<T> extends Result<T> {
  const Error._({required this.err});

  /// Returned error in result
  final Failure err;

  @override
  String toString() => 'Result<$T>.error($err)';
}
