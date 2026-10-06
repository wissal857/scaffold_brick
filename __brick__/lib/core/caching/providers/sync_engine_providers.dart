import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name}}/app/providers/entity_local_datasource_registers_initialization.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/sync_state_store.dart';
import 'package:{{project_name}}/core/caching/providers/persistence_providers.dart';
import 'package:{{project_name}}/core/caching/sync_engine/i_sync_coordinator.dart';
import 'package:{{project_name}}/core/caching/sync_engine/i_sync_engine.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/conflict_resolver.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_conflict_resolver.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_queue.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_synchronizer.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_remote_mutation_executor.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_queue.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_synchronizer.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/remote_mutation_executor.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/remote_mutation_result_handler.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/retry_policy.dart';
import 'package:{{project_name}}/core/caching/sync_engine/refresh/i_refresh_synchronizer.dart';
import 'package:{{project_name}}/core/caching/sync_engine/refresh/refresh_synchronizer.dart';
import 'package:{{project_name}}/core/caching/sync_engine/sync_coordinator.dart';
import 'package:{{project_name}}/core/caching/sync_engine/sync_engine.dart';

final queueProvider = Provider.autoDispose<IMutationQueue>((ref) {
  return MutationQueue();
});

final retryPolicyProvider = Provider.autoDispose<RetryPolicy>((ref) {
  return RetryPolicy();
});

final syncStateStoreProvider = Provider.autoDispose<ISyncStateStore>((ref) {
  ref.read(entityLocalDatasourceRegistersInitializationProvider);
  return SyncStateStore(
    mutationDao: ref.read(mutationDaoProvider),
    registry: ref.read(entityLocalDatasourceRegistryProvider),
    transaction: ref.read(persistenceTransactionProvider),
  );
});

final mutationExecutorProvider = Provider.autoDispose<IRemoteMutationExecutor>((
  ref,
) {
  return RemoteMutationExecutor(
    httpClient: ref.read(httpClientProvider),
    retryPolicy: ref.read(retryPolicyProvider),
    syncStateStore: ref.read(syncStateStoreProvider),
  );
});

final conflictResolverProvider = Provider.autoDispose<IConflictResolver>((ref) {
  return ConflictResolver();
});

final responsehandlerProvider =
    Provider.autoDispose<RemoteMutationResultHandler>((ref) {
      return RemoteMutationResultHandler(
        syncStateStore: ref.read(syncStateStoreProvider),
        mutationQueue: ref.read(queueProvider),
        conflictResolver: ref.read(conflictResolverProvider),
      );
    });

final mutationSyncProvider = Provider.autoDispose<IMutationSynchronizer>((ref) {
  return MutationSynchronizer(
    queue: ref.read(queueProvider),
    executor: ref.read(mutationExecutorProvider),
    responseHandler: ref.read(responsehandlerProvider),
  );
});

final refreshSyncProvider = Provider.autoDispose<IRefreshSynchronizer>((ref) {
  return RefreshSynchronizer();
});

final syncCoordinatorProvider = Provider.autoDispose<ISyncCoordinator>((ref) {
  return SyncCoordinator(
    mutationSynch: ref.read(mutationSyncProvider),
    refreshSync: ref.read(refreshSyncProvider),
  );
});

final syncEngineProvider = Provider.autoDispose<ISyncEngine>((ref) {
  return SyncEngine(syncCoordinator: ref.read(syncCoordinatorProvider));
});
