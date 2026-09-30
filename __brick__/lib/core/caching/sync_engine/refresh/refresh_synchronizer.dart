import 'package:drift/drift.dart';

import 'package:{{project_name}}/core/caching/persistence/dao/i_query_meatadata_dao.dart';
import 'package:{{project_name}}/core/caching/models/sync_result.dart';
import 'sync_strategy_executor.dart';
import 'refresh_policy.dart';

class RefreshSynchronizer {
  const RefreshSynchronizer({
    this.strategyExecutor = const SyncStrategyExecutor(),
    this.policy = const RefreshPolicySettings(),
    this.queryMetadataDao,
  });

  final SyncStrategyExecutor strategyExecutor;
  final RefreshPolicySettings policy;
  final IQueryMeatadataDao? queryMetadataDao;
}
