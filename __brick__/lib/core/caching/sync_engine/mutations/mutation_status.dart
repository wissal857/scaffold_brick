enum MutationStatus {
  pending('PENDING'),
  inProgress('IN PROGRESS'),
  conflict('CONFLICT'),
  failedFatal('FAILED FATAL'),
  failedRetryable('FAILED RETRYABLE'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String label;

  const MutationStatus(this.label);
}
