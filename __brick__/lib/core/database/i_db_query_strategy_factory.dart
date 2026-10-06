import 'package:{{project_name}}/core/database/db_paginated_query_params.dart';
import 'i_db_query_strategy.dart';

abstract interface class IDbQueryStrategyFactory {
  IDbQueryStrategy? getStrategy(DbPaginatedQueryParams params);
}
