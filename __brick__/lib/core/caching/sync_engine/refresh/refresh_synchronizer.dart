import 'package:{{project_name}}/core/caching/persistence/dao/i_query_meatadata_dao.dart';
import 'package:{{project_name}}/core/caching/sync_engine/refresh/i_refresh_synchronizer.dart';
import 'sync_strategy_executor.dart';
import 'refresh_policy.dart';

class RefreshSynchronizer implements IRefreshSynchronizer {
  const RefreshSynchronizer({
    this.strategyExecutor = const SyncStrategyExecutor(),
    this.policy = const RefreshPolicySettings(),
    this.queryMetadataDao,
  });

  final SyncStrategyExecutor strategyExecutor;
  final RefreshPolicySettings policy;
  final IQueryMeatadataDao? queryMetadataDao;

  @override
  Future<void> refreshEntity(int id) {
    // TODO: implement refreshEntity
    throw UnimplementedError();
  }

  @override
  Future<void> refreshQuery(String queryKey) {
    // TODO: implement refreshQuery
    throw UnimplementedError();
  }
}
