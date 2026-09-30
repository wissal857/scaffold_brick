import 'package:{{project_name}}/core/database/app_db.dart';

import 'i_sync_engine.dart';

/// Coordinates the tasks of mutation synchronizer
/// and refreshSynchronizer
abstract interface class ISyncCoordinator {
  Future<void> initialize();
  Future<void> dispose();

  /// Adds a mutation to the queue
  void enqueueMutation(MutationData mutation);

  /// pulls remote changes then pushes local mutations
  Future<void> coordinateSync({SyncStrategy strategy = SyncStrategy.full});

  /// fetches remote changes of a query result
  Future<void> performQueryRefresh(String queryKey);

  /// fetches remote changes of an entity by id
  Future<void> performEntityRefresh({
    required String entityType,
    required String id,
  });
}
