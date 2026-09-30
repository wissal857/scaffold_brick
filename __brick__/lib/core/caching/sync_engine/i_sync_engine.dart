import 'package:{{project_name}}/core/database/app_db.dart';

enum SyncStatus { syncing, synced, failed, ready, paused, stopped }

enum SyncStrategy { full, delta }

abstract interface class ISyncEngine {
  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Stream<SyncStatus> get statusStream;
  bool get isRunning;

  /// Adds a mutation to the queue
  void enqueueMutation(MutationData mutation);

  /// Pulls remote changes then pushes local mutations
  Future<void> reconcile({SyncStrategy strategy = SyncStrategy.full});

  /// Targeted background refresh of a query
  Future<void> requestQueryRefresh({required String queryKey});

  /// Targeted background refresh of an entity by id
  Future<void> requestEntityRefresh({
    required String entityType,
    required String id,
  });
}
