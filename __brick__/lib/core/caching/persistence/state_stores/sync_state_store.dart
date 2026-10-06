import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/i_mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_sync_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_entity_local_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/models/valid_mutation_data.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';
import 'package:{{project_name}}/core/caching/sync_engine/mutations/mutation_status.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

class SyncStateStore implements ISyncStateStore {
  const SyncStateStore({
    required IMutationDao mutationDao,
    required IEntityLocalDatasourceRegistry registry,
    required PersistenceTransaction transaction,
  }) : _mutationDao = mutationDao,
       _registry = registry,
       _transaction = transaction;

  final IMutationDao _mutationDao;
  final IEntityLocalDatasourceRegistry _registry;
  final PersistenceTransaction _transaction;

  @override
  Future<void> applyConflictResolution({
    required ValidMutationData mutation,
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
    if (mutation.entityLocalId == null) {
      throw CachingException.corruptedMutationTable(
        message: 'Can\'t find entity local id for mutation $mutation',
      );
    }
    _transaction.run(() async {
      await _registry
          .get(mutation.entityType)
          .update(mutation.entityLocalId!, resolvedData);
      await _mutationDao.deleteOperation(mutation.id);
    });
  }

  // Updates the sync status to completed and sets the server_id
  // with etag fields in the entity then deletes the mutation from db
  @override
  Future<void> commitRemoteCreate({
    required ValidMutationData mutation,
    required int serverId,
    required String etag,
  }) async {
    try {
      final patch = <String, dynamic>{
        'serverId': serverId,
        'etag': etag,
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityLocalId!, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> commitRemoteDelete({required ValidMutationData mutation}) async {
    try {
      final patch = <String, dynamic>{
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityLocalId!, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> commitRemoteUpdate({required ValidMutationData mutation}) async {
    try {
      final patch = <String, dynamic>{
        'syncStatus': MutationStatus.completed.label,
      };
      _transaction.run(() async {
        await _registry
            .get(mutation.entityType)
            .update(mutation.entityLocalId!, patch);
        await _mutationDao.deleteOperation(mutation.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Throws SqliteException
  @override
  Future<void> markInProgress(ValidMutationData mutation) async {
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
    required ValidMutationData mutation,
  }) async {
    late Future<void> entityRestore = _buildEntityRestoreRequest(mutation);

    _transaction.run(() async {
      await entityRestore;
      await _mutationDao.deleteOperation(mutation.id);
    });
  }

  /// Throws PreviousPayloadMissingException
  Future<void> _buildEntityRestoreRequest(ValidMutationData mutation) {
    return switch (mutation.operationType) {
      // TODO update sync status
      MutationType.create =>
        _registry.get(mutation.entityType).delete(mutation.entityLocalId!),
      MutationType.delete =>
        _registry
            .get(mutation.entityType)
            .resetTombstone(
              mutation.entityLocalId!,
              MutationStatus.failedFatal.label,
            ),
      // TODO add sync status
      MutationType.update =>
        _registry
            .get(mutation.entityType)
            .update(mutation.entityLocalId!, mutation.previousPayload!),
    };
  }
}
