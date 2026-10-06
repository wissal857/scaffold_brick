import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name}}/app/providers/entity_local_datasource_registers_initialization.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/i_mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/dao/mutation_dao.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_local_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/i_entity_local_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/local_state_store.dart';
import 'package:{{project_name}}/core/caching/persistence/state_stores/entity_local_datasource_registry.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/drift_persistence_transaction.dart';
import 'package:{{project_name}}/core/caching/persistence/transactions/persistence_transaction.dart';
import 'package:{{project_name}}/core/database/database_providers.dart';

final entityLocalDatasourceRegistryProvider =
    Provider<IEntityLocalDatasourceRegistry>((ref) {
      return EntityLocalDatasourceRegistry([]);
    });

final persistenceTransactionProvider =
    Provider.autoDispose<PersistenceTransaction>((ref) {
      return DriftPersistenceTransaction(ref.read(appDatabaseProvider));
    });

final mutationDaoProvider = Provider.autoDispose<IMutationDao>((ref) {
  return MutationDao(ref.read(appDatabaseProvider));
});

final localStateStoreProvider = Provider.autoDispose<ILocalStateStore>((ref) {
  ref.read(entityLocalDatasourceRegistersInitializationProvider);
  return LocalStateStore(
    registry: ref.read(entityLocalDatasourceRegistryProvider),
    transaction: ref.read(persistenceTransactionProvider),
    mutationDao: ref.read(mutationDaoProvider),
  );
});
