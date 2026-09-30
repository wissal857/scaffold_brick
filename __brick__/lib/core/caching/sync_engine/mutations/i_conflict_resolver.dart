import 'package:{{project_name}}/core/caching/models/conflict_resolution.dart';

abstract interface class IConflictResolver {
  ConflictResolution resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required ConflictResolutionStrategy strategy,
  });
}
