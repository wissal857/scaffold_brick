class ConflictResolution {
  const ConflictResolution({
    required this.strategy,
    required this.resolvedData,
    //required this.etag,
  });

  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic> resolvedData;
  //final String etag;
}

enum ConflictResolutionStrategy {
  useLocal,
  useRemote,
  // lastWriteWins,
  merge,
  manual,
}
