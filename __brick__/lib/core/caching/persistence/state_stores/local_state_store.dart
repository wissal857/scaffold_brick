import 'package:{{project_name}}/core/caching/models/sync_mutation_request.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/i_mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/mappers/sync_operation_mapper.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_local_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/state_handler_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';

class LocalStateStore implements ILocalStateStore {
  final StateHandlerRegistry _registry;
  final PersistenceTransaction _transaction;
  final IMutationDao _mutationDao;

  const LocalStateStore({
    required StateHandlerRegistry registry,
    required PersistenceTransaction transaction,
    required IMutationDao mutationDao,
  }) : _registry = registry,
       _transaction = transaction,
       _mutationDao = mutationDao;

  @override
  Future<void> save({required SyncCreateRequest syncRequest}) async {
    try {
      _transaction.run(() async {
        await _registry.get(syncRequest.entityType).save(syncRequest.payload);
        await _mutationDao.insertIfAbsent(syncRequest.toCompanion());
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
            .delete(syncRequest.entityId);
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
            .update(syncRequest.entityId, syncRequest.payload);
        await _mutationDao.insertIfAbsent(syncRequest.toCompanion());
      });
    } catch (e) {
      rethrow;
    }
  }
}
