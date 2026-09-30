import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/i_mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/state_handler_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

class SyncStateStore implements ISyncStateStore {
  const SyncStateStore({
    required IMutationDao mutationDao,
    required StateHandlerRegistry registry,
    required PersistenceTransaction transaction,
  }) : _mutationDao = mutationDao,
       _registry = registry,
       _transaction = transaction;

  final IMutationDao _mutationDao;
  final StateHandlerRegistry _registry;
  final PersistenceTransaction _transaction;

  @override
  Future<void> applyConflictResolution({
    required MutationData mutation,
    required String etag,
    required Map<String, dynamic> resolvedData,
  }) async {
    // update entity with resolved data
    // remove the mutation from the db
    if (resolvedData['etag'] == null) {
      resolvedData.addAll(<String, dynamic>{
        'etag': etag,
        'syncStatus': MutationStatus.completed.label,
      });
    }

    _transaction.run(() async {
      await _registry
          .get(mutation.entityType)
          .update(mutation.entityId, resolvedData);
      await _mutationDao.deleteOperation(mutation.id);
    });
  }

  // Updates the sync status to completed and sets the server_id
  // with etag fields in the entity then deletes the mutation from db
  @override
  Future<void> commitRemoteCreate({
    required MutationData mutation,
    required int serverId,
    required String etag,
  }) async {
    try {
      final patch = <String, dynamic>{
        'id': serverId,
        'etag': etag,
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityId, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> commitRemoteDelete({required MutationData mutation}) async {
    try {
      final patch = <String, dynamic>{
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityId, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> commitRemoteUpdate({required MutationData mutation}) async {
    try {
      final patch = <String, dynamic>{
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityId, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Throws SqliteException
  @override
  Future<void> markInProgress(MutationData mutation) async {
    await _mutationDao.updateStatus(mutation.id, MutationStatus.inProgress);
  }

  /// Restores an entity to its previous state after a sync
  /// failure and deletes its asssociated operation from the db
  /// in one transaction.
  /// Restoring an entity works as follows:
  /// - If the operation is create the restore should delete it.
  /// - If it's delete the restore should switch the delete flag.
  /// - If it's update the restore should reset the dirty fields to their
  /// previous state.
  ///
  /// Throws PreviousPayloadMissingException and SqliteException
  @override
  Future<void> rollback({
    required MutationStatus syncStatus,
    required MutationData mutation,
  }) async {
    late Future<void> entityRestore = _buildEntityRestoreRequest(mutation);

    _transaction.run(() async {
      await entityRestore;
      await _mutationDao.deleteOperation(mutation.id);
    });
  }

  /// Throws PreviousPayloadMissingException
  Future<void> _buildEntityRestoreRequest(MutationData mutation) {
    return switch (mutation.operationType) {
      // TODO just update sync status do not delete it
      MutationType.create =>
        _registry.get(mutation.entityType).delete(mutation.entityId),
      MutationType.delete =>
        _registry
            .get(mutation.entityType)
            .resetTombstone(
              mutation.entityId,
              MutationStatus.failedFatal.label,
            ),
      // TODO add sync status
      MutationType.update =>
        mutation.previousPayload != null &&
                mutation.previousPayload?.data != null
            ? _registry
                  .get(mutation.entityType)
                  .update(mutation.entityId, mutation.previousPayload!.data!)
            : throw CachingException.previousPayloadMissingOrCorrupted(),
    };
  }
}
