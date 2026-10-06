import 'package:drift/drift.dart';
import 'package:{{project_name}}/core/data/models/local/paginated_cache_model.dart';
import 'package:{{project_name}}/core/database/app_db.dart';
import 'package:{{project_name}}/core/database/db_paginated_query_params.dart';
import 'package:{{project_name}}/core/database/i_db_query_strategy_factory.dart';
import 'package:{{project_name}}/core/sorting/sort_direction.dart';

mixin DriftDaoMixin {
  Future<PaginatedCacheModel<TData>>
  executePaginatedQuery<R, TTable extends Table, TData>({
    required AppDatabase db,
    required TableInfo<TTable, TData> table,
    required int Function(TData row) idSelector,
    required DbPaginatedQueryParams params,
    IDbQueryStrategyFactory? queryStrategyFactory,
  }) async {
    final stmt = db.select(table, distinct: true);

    final strategy = queryStrategyFactory?.getStrategy(params);
    if (strategy != null) {
      stmt.where((t) => strategy.buildWhereClause(params, t));
    }

    if (params.sortBy != null) {
      stmt.orderBy(
        params.sortBy!.toOrderingTerms(
          db,
          params.sortDirection == SortDirection.ascending,
        ),
      );
    }

    stmt.limit(params.limit + 1);

    final rows = await stmt.get();
    final hasMore = rows.length > params.limit;
    final data = hasMore ? rows.sublist(0, params.limit) : rows;
    final nextCursor = hasMore ? idSelector(data.last) : null;

    return PaginatedCacheModel<TData>(
      data: data,
      nextCursor: nextCursor,
      total: hasMore ? params.limit : data.length,
      hasNext: hasMore,
    );
  }
}
