import 'package:{{project_name}}/core/caching/models/conflict_resolution.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_conflict_resolver.dart';

class ConflictResolver implements IConflictResolver {
  const ConflictResolver();

  @override
  ConflictResolution resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required ConflictResolutionStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return ConflictResolution(
          strategy: strategy,
          resolvedData: Map<String, dynamic>.from(localData),
        );
      case ConflictResolutionStrategy.useRemote:
        return ConflictResolution(
          strategy: strategy,
          resolvedData: Map<String, dynamic>.from(remoteData),
        );
      case ConflictResolutionStrategy.merge:
        return ConflictResolution(
          strategy: strategy,
          resolvedData: <String, dynamic>{...remoteData, ...localData},
        );
      case ConflictResolutionStrategy.manual:
        return ConflictResolution(
          strategy: strategy,
          resolvedData: Map<String, dynamic>.from(remoteData),
        );
    }
  }
}
