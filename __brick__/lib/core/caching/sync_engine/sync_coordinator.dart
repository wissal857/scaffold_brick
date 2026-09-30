import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_synchronizer.dart';
import 'package:{{project_name}}/core/caching/sync_engine/refresh/i_refresh_synchronizer.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

import 'i_sync_coordinator.dart';
import 'i_sync_engine.dart';

class SyncCoordinator implements ISyncCoordinator {
  const SyncCoordinator({
    required IMutationSynchronizer mutationSynch,
    required IRefreshSynchronizer refreshSync,
  }) : _mutationSynchronizer = mutationSynch,
       _refreshSynchronizer = refreshSync;

  final IMutationSynchronizer _mutationSynchronizer;
  final IRefreshSynchronizer _refreshSynchronizer;

  @override
  Future<void> initialize() {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  /// 1. pull remote changes
  /// 2. push pending mutations
  @override
  Future<void> coordinateSync({SyncStrategy strategy = SyncStrategy.full}) {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  void enqueueMutation(MutationData mutation) {
    return _mutationSynchronizer.enqueue(mutation);
  }

  @override
  Future<void> performEntityRefresh({
    required String entityType,
    required String id,
  }) {
    // TODO: implement performEntityRefresh
    throw UnimplementedError();
  }

  @override
  Future<void> performQueryRefresh(String queryKey) {
    // TODO: implement performQueryRefresh
    throw UnimplementedError();
  }
}
