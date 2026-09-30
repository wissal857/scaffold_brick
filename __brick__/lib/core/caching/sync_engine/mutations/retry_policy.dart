import 'dart:math';

class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
  });

  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  /// Calculate delay for the nth retry using exponential backoff
  Duration getDelayForAttempt(int attemptNumber) {
    final exponentialDelay =
        initialDelay * (pow(backoffMultiplier, attemptNumber));
    return exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
  }

  bool shouldRetry(int currentAttempts) {
    return currentAttempts < maxRetries;
  }
}
