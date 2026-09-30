import 'package:{{project_name}}/core/caching/models/conflict_resolution.dart';
import 'package:{{project_name}}/core/caching/models/remote_mutation_response.dart';
import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/conflict_resolver.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/i_mutation_queue.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

class RemoteMutationResultHandler {
  const RemoteMutationResultHandler({
    required ISyncStateStore stateStore,
    required IMutationQueue mutationQueue,
    required ConflictResolver conflictResolver,
  }) : _syncStateStore = stateStore,
       _mutationQueue = mutationQueue,
       _conflictResolver = conflictResolver;

  final ISyncStateStore _syncStateStore;
  final IMutationQueue _mutationQueue;
  final ConflictResolver _conflictResolver;

  Future<void> handle(List<RemoteMutationResponse> results) async {
    for (final result in results) {
      switch (result) {
        case RemoteMutationSuccess s:
          _handleSuccess(s);
          break;
        case RemoteMutationConflict e:
          _handleConflict(e);
          break;
        case RemoteMutationError e:
          _handleFailure(e);
          break;
      }
    }
  }

  ConflictResolution resolveConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.useRemote,
  }) {
    return _conflictResolver.resolve(
      localData: localData,
      remoteData: remoteData,
      strategy: strategy,
    );
  }

  Future<void> _handleSuccess(RemoteMutationSuccess response) async {
    try {
      switch (response.mutation.operationType) {
        case MutationType.create:
          final createResponse = response as RemoteMutationCreateSuccess;
          await _syncStateStore.commitRemoteCreate(
            mutation: createResponse.mutation,
            etag: createResponse.etag,
            serverId: createResponse.responseData['id'],
          );
          break;
        case MutationType.update:
          await _syncStateStore.commitRemoteUpdate(mutation: response.mutation);
          break;
        case MutationType.delete:
          await _syncStateStore.commitRemoteDelete(mutation: response.mutation);
          break;
      }

      _mutationQueue.remove(response.mutation.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleConflict(RemoteMutationConflict response) async {
    try {
      if (response.mutation.payload.data == null) {
        throw CachingException.payloadMissingOrCorrupted();
      }
      final resolution = resolveConflict(
        localData: response.mutation.payload.data!,
        remoteData: response.serverRepresentation,
        strategy: ConflictResolutionStrategy.useRemote,
      );
      _syncStateStore.applyConflictResolution(
        etag: response.etag,
        mutation: response.mutation,
        resolvedData: resolution.resolvedData,
      );
      _mutationQueue.remove(response.mutation.id);
    } catch (e) {
      // TODO: handle this error
      rethrow;
    }
  }

  Future<void> _handleFailure(RemoteMutationError error) async {
    // restore the previous state of the entity and remove the
    // pending operation
    _syncStateStore.rollback(
      syncStatus: MutationStatus.failedFatal, // TODO
      mutation: error.mutation,
    );
    _mutationQueue.remove(error.mutation.id);
  }
}
