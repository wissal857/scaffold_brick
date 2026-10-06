import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/i_mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/mappers/sync_operation_mapper.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_local_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_entity_local_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';
import 'package:{{project_name}}/core/database/app_db.dart';

class LocalStateStore implements ILocalStateStore {
  final IEntityLocalDatasourceRegistry _registry;
  final PersistenceTransaction _transaction;
  final IMutationDao _mutationDao;

  const LocalStateStore({
    required IEntityLocalDatasourceRegistry registry,
    required PersistenceTransaction transaction,
    required IMutationDao mutationDao,
  }) : _registry = registry,
       _transaction = transaction,
       _mutationDao = mutationDao;

  @override
  Future<MutationData> save({required SyncCreateRequest syncRequest}) async {
    try {
      return _transaction.run(() async {
        final entityLocalId = await _registry
            .get(syncRequest.entityType)
            .save(syncRequest.payload);
        return await _mutationDao.insertIfAbsent(
          syncRequest.toCompanion(entityLocalId),
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> delete({required SyncDeleteRequest syncRequest}) async {
    try {
      _transaction.run(() async {
        await _registry
            .get(syncRequest.entityType)
            .delete(syncRequest.entityLocalId);
        await _mutationDao.insertIfAbsent(syncRequest.toCompanion());
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> update({required SyncUpdateRequest syncRequest}) async {
    try {
      _transaction.run(() async {
        await _registry
            .get(syncRequest.entityType)
            .update(syncRequest.entityLocalId, syncRequest.payload);
        await _mutationDao.insertIfAbsent(syncRequest.toCompanion());
      });
    } catch (e) {
      rethrow;
    }
  }
}
